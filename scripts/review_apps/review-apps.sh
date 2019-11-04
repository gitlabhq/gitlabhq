[[ "$TRACE" ]] && set -x
export TILLER_NAMESPACE="$KUBE_NAMESPACE"

function deploy_exists() {
  local namespace="${1}"
  local deploy="${2}"
  echoinfo "Checking if ${deploy} exists in the ${namespace} namespace..." true

  helm status --tiller-namespace "${namespace}" "${deploy}" >/dev/null 2>&1
  local deploy_exists=$?

  echoinfo "Deployment status for ${deploy} is ${deploy_exists}"
  return $deploy_exists
}

function previous_deploy_failed() {
  local deploy="${1}"
  echoinfo "Checking for previous deployment of ${deploy}" true

  helm status "${deploy}" >/dev/null 2>&1
  local status=$?

  # if `status` is `0`, deployment exists, has a status
  if [ $status -eq 0 ]; then
    echoinfo "Previous deployment found, checking status..."
    deployment_status=$(helm status "${deploy}" | grep ^STATUS | cut -d' ' -f2)
    echoinfo "Previous deployment state: ${deployment_status}"
    if [[ "$deployment_status" == "FAILED" || "$deployment_status" == "PENDING_UPGRADE" || "$deployment_status" == "PENDING_INSTALL" ]]; then
      status=0;
    else
      status=1;
    fi
  else
    echoerr "Previous deployment NOT found."
  fi
  return $status
}

function delete_release() {
  if [ -z "$CI_ENVIRONMENT_SLUG" ]; then
    echoerr "No release given, aborting the delete!"
    return
  fi

  local name="$CI_ENVIRONMENT_SLUG"

  echoinfo "Deleting release '$name'..." true

  helm delete --purge "$name"
}

function delete_failed_release() {
  if [ -z "$CI_ENVIRONMENT_SLUG" ]; then
    echoerr "No release given, aborting the delete!"
    return
  fi

  if ! deploy_exists "${KUBE_NAMESPACE}" "${CI_ENVIRONMENT_SLUG}"; then
    echoinfo "No Review App with ${CI_ENVIRONMENT_SLUG} is currently deployed."
  else
    # Cleanup and previous installs, as FAILED and PENDING_UPGRADE will cause errors with `upgrade`
    if previous_deploy_failed "$CI_ENVIRONMENT_SLUG" ; then
      echoinfo "Review App deployment in bad state, cleaning up $CI_ENVIRONMENT_SLUG"
      delete_release
    else
      echoinfo "Review App deployment in good state"
    fi
  fi
}


function get_pod() {
  local app_name="${1}"
  local status="${2-Running}"
  get_pod_cmd="kubectl get pods -n ${KUBE_NAMESPACE} --field-selector=status.phase=${status} -lapp=${app_name},release=${CI_ENVIRONMENT_SLUG} --no-headers -o=custom-columns=NAME:.metadata.name | tail -n 1"
  echoinfo "Waiting till '${app_name}' pod is ready" true
  echoinfo "Running '${get_pod_cmd}'"

  local interval=5
  local elapsed_seconds=0
  local max_seconds=$((2 * 60))
  while true; do
    local pod_name
    pod_name="$(eval "${get_pod_cmd}")"
    [[ "${pod_name}" == "" ]] || break

    if [[ "${elapsed_seconds}" -gt "${max_seconds}" ]]; then
      echoerr "The pod name couldn't be found after ${elapsed_seconds} seconds, aborting."
      break
    fi

    let "elapsed_seconds+=interval"
    sleep ${interval}
  done

  echoinfo "The pod name is '${pod_name}'."
  echo "${pod_name}"
}

function check_kube_domain() {
  echoinfo "Checking that Kube domain exists..." true

  if [ -z ${REVIEW_APPS_DOMAIN+x} ]; then
    echo "In order to deploy or use Review Apps, REVIEW_APPS_DOMAIN variable must be set"
    echo "You can do it in Auto DevOps project settings or defining a variable at group or project level"
    echo "You can also manually add it in .gitlab-ci.yml"
    false
  else
    true
  fi
}

function ensure_namespace() {
  echoinfo "Ensuring the ${KUBE_NAMESPACE} namespace exists..." true

  kubectl describe namespace "$KUBE_NAMESPACE" || kubectl create namespace "$KUBE_NAMESPACE"
}

function install_tiller() {
  echoinfo "Checking deployment/tiller-deploy status in the ${TILLER_NAMESPACE} namespace..." true

  echoinfo "Initiating the Helm client..."
  helm init --client-only

  # Set toleration for Tiller to be installed on a specific node pool
  helm init \
    --wait \
    --upgrade \
    --node-selectors "app=helm" \
    --replicas 3 \
    --override "spec.template.spec.tolerations[0].key"="dedicated" \
    --override "spec.template.spec.tolerations[0].operator"="Equal" \
    --override "spec.template.spec.tolerations[0].value"="helm" \
    --override "spec.template.spec.tolerations[0].effect"="NoSchedule"

  kubectl rollout status -n "$TILLER_NAMESPACE" -w "deployment/tiller-deploy"

  if ! helm version --debug; then
    echo "Failed to init Tiller."
    return 1
  fi
}

function install_external_dns() {
  local release_name="dns-gitlab-review-app"
  local domain
  domain=$(echo "${REVIEW_APPS_DOMAIN}" | awk -F. '{printf "%s.%s", $(NF-1), $NF}')
  echoinfo "Installing external DNS for domain ${domain}..." true

  if ! deploy_exists "${KUBE_NAMESPACE}" "${release_name}" || previous_deploy_failed "${release_name}" ; then
    echoinfo "Installing external-dns Helm chart"
    helm repo update
    # Default requested: CPU => 0, memory => 0
    helm install stable/external-dns --version '^2.2.1' \
      -n "${release_name}" \
      --namespace "${KUBE_NAMESPACE}" \
      --set provider="aws" \
      --set aws.credentials.secretKey="${REVIEW_APPS_AWS_SECRET_KEY}" \
      --set aws.credentials.accessKey="${REVIEW_APPS_AWS_ACCESS_KEY}" \
      --set aws.zoneType="public" \
      --set aws.batchChangeSize=400 \
      --set domainFilters[0]="${domain}" \
      --set txtOwnerId="${KUBE_NAMESPACE}" \
      --set rbac.create="true" \
      --set policy="sync" \
      --set resources.requests.cpu=50m \
      --set resources.limits.cpu=100m \
      --set resources.requests.memory=100M \
      --set resources.limits.memory=200M
  else
    echoinfo "The external-dns Helm chart is already successfully deployed."
  fi
}

function create_application_secret() {
  echoinfo "Creating the ${CI_ENVIRONMENT_SLUG}-gitlab-initial-root-password secret in the ${KUBE_NAMESPACE} namespace..." true

  kubectl create secret generic -n "$KUBE_NAMESPACE" \
    "${CI_ENVIRONMENT_SLUG}-gitlab-initial-root-password" \
    --from-literal="password=${REVIEW_APPS_ROOT_PASSWORD}" \
    --dry-run -o json | kubectl apply -f -

  if [ -z "${REVIEW_APPS_EE_LICENSE}" ]; then echo "License not found" && return; fi

  echoinfo "Creating the ${CI_ENVIRONMENT_SLUG}-gitlab-license secret in the ${KUBE_NAMESPACE} namespace..." true

  echo "${REVIEW_APPS_EE_LICENSE}" > /tmp/license.gitlab

  kubectl create secret generic -n "$KUBE_NAMESPACE" \
    "${CI_ENVIRONMENT_SLUG}-gitlab-license" \
    --from-file=license=/tmp/license.gitlab \
    --dry-run -o json | kubectl apply -f -
}

function download_chart() {
  echoinfo "Downloading the GitLab chart..." true

  curl --location -o gitlab.tar.bz2 "https://gitlab.com/gitlab-org/charts/gitlab/-/archive/${GITLAB_HELM_CHART_REF}/gitlab-${GITLAB_HELM_CHART_REF}.tar.bz2"
  tar -xjf gitlab.tar.bz2
  cd "gitlab-${GITLAB_HELM_CHART_REF}"

  echoinfo "Adding the gitlab repo to Helm..."
  helm repo add gitlab https://charts.gitlab.io

  echoinfo "Building the gitlab chart's dependencies..."
  helm dependency build .
}

function base_config_changed() {
  git fetch origin master --depth=50

  [ -n "$(git diff origin/master... --name-only -- scripts/review_apps/base-config.yaml)" ]
}

function deploy() {
  local name="$CI_ENVIRONMENT_SLUG"
  local edition="${GITLAB_EDITION-ce}"
  local base_config_file_ref="master"
  echo "REVIEW_APP_CONFIG_CHANGED: ${REVIEW_APP_CONFIG_CHANGED}"
  if [ -n "${REVIEW_APP_CONFIG_CHANGED}" ]; then
    base_config_file_ref="$CI_COMMIT_SHA"
  fi
  local base_config_file="https://gitlab.com/gitlab-org/gitlab/raw/${base_config_file_ref}/scripts/review_apps/base-config.yaml"

  echoinfo "Deploying ${name}..." true

  IMAGE_REPOSITORY="registry.gitlab.com/gitlab-org/build/cng-mirror"
  gitlab_migrations_image_repository="${IMAGE_REPOSITORY}/gitlab-rails-${edition}"
  gitlab_sidekiq_image_repository="${IMAGE_REPOSITORY}/gitlab-sidekiq-${edition}"
  gitlab_unicorn_image_repository="${IMAGE_REPOSITORY}/gitlab-unicorn-${edition}"
  gitlab_task_runner_image_repository="${IMAGE_REPOSITORY}/gitlab-task-runner-${edition}"
  gitlab_gitaly_image_repository="${IMAGE_REPOSITORY}/gitaly"
  gitlab_shell_image_repository="${IMAGE_REPOSITORY}/gitlab-shell"
  gitlab_workhorse_image_repository="${IMAGE_REPOSITORY}/gitlab-workhorse-${edition}"

  create_application_secret

HELM_CMD=$(cat << EOF
  helm upgrade --install \
    --wait \
    --timeout 900 \
    --set ci.branch="$CI_COMMIT_REF_NAME" \
    --set ci.commit.sha="$CI_COMMIT_SHORT_SHA" \
    --set ci.job.url="$CI_JOB_URL" \
    --set ci.pipeline.url="$CI_PIPELINE_URL" \
    --set releaseOverride="$CI_ENVIRONMENT_SLUG" \
    --set global.hosts.hostSuffix="$HOST_SUFFIX" \
    --set global.hosts.domain="$REVIEW_APPS_DOMAIN" \
    --set gitlab.migrations.image.repository="$gitlab_migrations_image_repository" \
    --set gitlab.migrations.image.tag="$CI_COMMIT_REF_SLUG" \
    --set gitlab.gitaly.image.repository="$gitlab_gitaly_image_repository" \
    --set gitlab.gitaly.image.tag="v$GITALY_VERSION" \
    --set gitlab.gitlab-shell.image.repository="$gitlab_shell_image_repository" \
    --set gitlab.gitlab-shell.image.tag="v$GITLAB_SHELL_VERSION" \
    --set gitlab.sidekiq.image.repository="$gitlab_sidekiq_image_repository" \
    --set gitlab.sidekiq.image.tag="$CI_COMMIT_REF_SLUG" \
    --set gitlab.unicorn.image.repository="$gitlab_unicorn_image_repository" \
    --set gitlab.unicorn.image.tag="$CI_COMMIT_REF_SLUG" \
    --set gitlab.unicorn.workhorse.image="$gitlab_workhorse_image_repository" \
    --set gitlab.unicorn.workhorse.tag="$CI_COMMIT_REF_SLUG" \
    --set gitlab.task-runner.image.repository="$gitlab_task_runner_image_repository" \
    --set gitlab.task-runner.image.tag="$CI_COMMIT_REF_SLUG"
EOF
)

if [ -n "${REVIEW_APPS_EE_LICENSE}" ]; then
HELM_CMD=$(cat << EOF
  ${HELM_CMD} \
  --set global.gitlab.license.secret="${CI_ENVIRONMENT_SLUG}-gitlab-license"
EOF
)
fi

HELM_CMD=$(cat << EOF
  ${HELM_CMD} \
  --namespace="$KUBE_NAMESPACE" \
  --version="${CI_PIPELINE_ID}-${CI_JOB_ID}" \
  -f "${base_config_file}" \
  "${name}" .
EOF
)

  echoinfo "Deploying with:"
  echoinfo "${HELM_CMD}"

  eval "${HELM_CMD}"
}

function display_deployment_debug() {
  # Get all pods for this release
  echoinfo "Pods for release ${CI_ENVIRONMENT_SLUG}"
  kubectl get pods -n "$KUBE_NAMESPACE" -lrelease=${CI_ENVIRONMENT_SLUG}

  # Get all non-completed jobs
  echoinfo "Unsuccessful Jobs for release ${CI_ENVIRONMENT_SLUG}"
  kubectl get jobs -n "$KUBE_NAMESPACE" -lrelease=${CI_ENVIRONMENT_SLUG} --field-selector=status.successful!=1
}
