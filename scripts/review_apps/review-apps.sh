[[ "$TRACE" ]] && set -x

function deploy_exists() {
  local namespace="${1}"
  local release="${2}"
  local deploy_exists

  echoinfo "Checking if ${release} exists in the ${namespace} namespace..." true

  helm status --tiller-namespace "${namespace}" "${release}" >/dev/null 2>&1
  deploy_exists=$?

  echoinfo "Deployment status for ${release} is ${deploy_exists}"
  return $deploy_exists
}

function previous_deploy_failed() {
  local namespace="${1}"
  local release="${2}"

  echoinfo "Checking for previous deployment of ${release}" true

  helm status --tiller-namespace "${namespace}" "${release}" >/dev/null 2>&1
  local status=$?

  # if `status` is `0`, deployment exists, has a status
  if [ $status -eq 0 ]; then
    echoinfo "Previous deployment found, checking status..."
    deployment_status=$(helm status --tiller-namespace "${namespace}" "${release}" | grep ^STATUS | cut -d' ' -f2)
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
  local namespace="${KUBE_NAMESPACE}"
  local release="${CI_ENVIRONMENT_SLUG}"

  if [ -z "${release}" ]; then
    echoerr "No release given, aborting the delete!"
    return
  fi

  helm_delete_release "${namespace}" "${release}"
  kubectl_cleanup_release "${namespace}" "${release}"
}

function helm_delete_release() {
  local namespace="${1}"
  local release="${2}"

  echoinfo "Deleting Helm release '${release}'..." true

  helm delete --tiller-namespace "${namespace}" --purge "${release}"
}

function kubectl_cleanup_release() {
  local namespace="${1}"
  local release="${2}"

  echoinfo "Deleting all K8s resources matching '${release}'..." true
  kubectl --namespace "${namespace}" get ingress,svc,pdb,hpa,deploy,statefulset,job,pod,secret,configmap,pvc,secret,clusterrole,clusterrolebinding,role,rolebinding,sa,crd 2>&1 \
    | grep "${release}" \
    | awk '{print $1}' \
    | xargs kubectl --namespace "${namespace}" delete \
    || true
}

function delete_failed_release() {
  local namespace="${KUBE_NAMESPACE}"
  local release="${CI_ENVIRONMENT_SLUG}"

  if [ -z "${release}" ]; then
    echoerr "No release given, aborting the delete!"
    return
  fi

  if ! deploy_exists "${namespace}" "${release}"; then
    echoinfo "No Review App with ${release} is currently deployed."
  else
    # Cleanup and previous installs, as FAILED and PENDING_UPGRADE will cause errors with `upgrade`
    if previous_deploy_failed "${namespace}" "${release}" ; then
      echoinfo "Review App deployment in bad state, cleaning up ${release}"
      delete_release
    else
      echoinfo "Review App deployment in good state"
    fi
  fi
}


function get_pod() {
  local namespace="${KUBE_NAMESPACE}"
  local release="${CI_ENVIRONMENT_SLUG}"
  local app_name="${1}"
  local status="${2-Running}"

  get_pod_cmd="kubectl get pods --namespace ${namespace} --field-selector=status.phase=${status} -lapp=${app_name},release=${release} --no-headers -o=custom-columns=NAME:.metadata.name | tail -n 1"
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
  local namespace="${KUBE_NAMESPACE}"

  echoinfo "Ensuring the ${namespace} namespace exists..." true

  kubectl describe namespace "${namespace}" || kubectl create namespace "${namespace}"
}

function install_tiller() {
  local namespace="${KUBE_NAMESPACE}"

  echoinfo "Checking deployment/tiller-deploy status in the ${namespace} namespace..." true

  echoinfo "Initiating the Helm client..."
  helm init --client-only

  # Set toleration for Tiller to be installed on a specific node pool
  helm init \
    --tiller-namespace "${namespace}" \
    --wait \
    --upgrade \
    --force-upgrade \
    --node-selectors "app=helm" \
    --replicas 3 \
    --override "spec.template.spec.tolerations[0].key"="dedicated" \
    --override "spec.template.spec.tolerations[0].operator"="Equal" \
    --override "spec.template.spec.tolerations[0].value"="helm" \
    --override "spec.template.spec.tolerations[0].effect"="NoSchedule"

  kubectl rollout status --namespace "${namespace}" --watch "deployment/tiller-deploy"

  if ! helm version --tiller-namespace "${namespace}" --debug; then
    echo "Failed to init Tiller."
    return 1
  fi
}

function install_external_dns() {
  local namespace="${KUBE_NAMESPACE}"
  local release="dns-gitlab-review-app"
  local domain
  domain=$(echo "${REVIEW_APPS_DOMAIN}" | awk -F. '{printf "%s.%s", $(NF-1), $NF}')
  echoinfo "Installing external DNS for domain ${domain}..." true

  if ! deploy_exists "${namespace}" "${release}" || previous_deploy_failed "${namespace}" "${release}" ; then
    echoinfo "Installing external-dns Helm chart"
    helm repo update --tiller-namespace "${namespace}"

    # Default requested: CPU => 0, memory => 0
    # Chart > 2.6.1 has a problem with AWS so we're pinning it for now.
    # See https://gitlab.com/gitlab-org/gitlab/issues/37269 and https://github.com/kubernetes-sigs/external-dns/issues/1262
    helm install stable/external-dns \
      --tiller-namespace "${namespace}" \
      --namespace "${namespace}" \
      --version '2.6.1' \
      --name "${release}" \
      --set provider="aws" \
      --set aws.credentials.secretKey="${REVIEW_APPS_AWS_SECRET_KEY}" \
      --set aws.credentials.accessKey="${REVIEW_APPS_AWS_ACCESS_KEY}" \
      --set aws.zoneType="public" \
      --set aws.batchChangeSize=400 \
      --set domainFilters[0]="${domain}" \
      --set txtOwnerId="${namespace}" \
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
  local namespace="${KUBE_NAMESPACE}"
  local release="${CI_ENVIRONMENT_SLUG}"
  local initial_root_password_shared_secret
  local gitlab_license_shared_secret

  initial_root_password_shared_secret=$(kubectl get secret --namespace ${namespace} --no-headers -o=custom-columns=NAME:.metadata.name shared-gitlab-initial-root-password | tail -n 1)
  if [[ "${initial_root_password_shared_secret}" == "" ]]; then
    echoinfo "Creating the 'shared-gitlab-initial-root-password' secret in the ${namespace} namespace..." true
    kubectl create secret generic --namespace "${namespace}" \
      "shared-gitlab-initial-root-password" \
      --from-literal="password=${REVIEW_APPS_ROOT_PASSWORD}" \
      --dry-run -o json | kubectl apply -f -
  else
    echoinfo "The 'shared-gitlab-initial-root-password' secret already exists in the ${namespace} namespace."
  fi

  if [ -z "${REVIEW_APPS_EE_LICENSE}" ]; then echo "License not found" && return; fi

  gitlab_license_shared_secret=$(kubectl get secret --namespace ${namespace} --no-headers -o=custom-columns=NAME:.metadata.name shared-gitlab-license | tail -n 1)
  if [[ "${gitlab_license_shared_secret}" == "" ]]; then
    echoinfo "Creating the 'shared-gitlab-license' secret in the ${namespace} namespace..." true
    echo "${REVIEW_APPS_EE_LICENSE}" > /tmp/license.gitlab
    kubectl create secret generic --namespace "${namespace}" \
      "shared-gitlab-license" \
      --from-file=license=/tmp/license.gitlab \
      --dry-run -o json | kubectl apply -f -
  else
    echoinfo "The 'shared-gitlab-license' secret already exists in the ${namespace} namespace."
  fi
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
  if [ -z "${CI_MERGE_REQUEST_IID}" ]; then return; fi

  curl "${CI_API_V4_URL}/projects/${CI_MERGE_REQUEST_PROJECT_ID}/merge_requests/${CI_MERGE_REQUEST_IID}/changes" | jq '.changes | any(.old_path == "scripts/review_apps/base-config.yaml")'
}

function deploy() {
  local namespace="${KUBE_NAMESPACE}"
  local release="${CI_ENVIRONMENT_SLUG}"
  local edition="${GITLAB_EDITION-ce}"
  local base_config_file_ref="master"
  if [[ "$(base_config_changed)" == "true" ]]; then base_config_file_ref="${CI_COMMIT_SHA}"; fi
  local base_config_file="https://gitlab.com/gitlab-org/gitlab/raw/${base_config_file_ref}/scripts/review_apps/base-config.yaml"

  echoinfo "Deploying ${release}..." true

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
  helm upgrade \
    --tiller-namespace="${namespace}" \
    --namespace="${namespace}" \
    --install \
    --wait \
    --timeout 900 \
    --set ci.branch="${CI_COMMIT_REF_NAME}" \
    --set ci.commit.sha="${CI_COMMIT_SHORT_SHA}" \
    --set ci.job.url="${CI_JOB_URL}" \
    --set ci.pipeline.url="${CI_PIPELINE_URL}" \
    --set releaseOverride="${release}" \
    --set global.hosts.hostSuffix="${HOST_SUFFIX}" \
    --set global.hosts.domain="${REVIEW_APPS_DOMAIN}" \
    --set gitlab.migrations.image.repository="${gitlab_migrations_image_repository}" \
    --set gitlab.migrations.image.tag="${CI_COMMIT_REF_SLUG}" \
    --set gitlab.gitaly.image.repository="${gitlab_gitaly_image_repository}" \
    --set gitlab.gitaly.image.tag="v${GITALY_VERSION}" \
    --set gitlab.gitlab-shell.image.repository="${gitlab_shell_image_repository}" \
    --set gitlab.gitlab-shell.image.tag="v${GITLAB_SHELL_VERSION}" \
    --set gitlab.sidekiq.image.repository="${gitlab_sidekiq_image_repository}" \
    --set gitlab.sidekiq.image.tag="${CI_COMMIT_REF_SLUG}" \
    --set gitlab.unicorn.image.repository="${gitlab_unicorn_image_repository}" \
    --set gitlab.unicorn.image.tag="${CI_COMMIT_REF_SLUG}" \
    --set gitlab.unicorn.workhorse.image="${gitlab_workhorse_image_repository}" \
    --set gitlab.unicorn.workhorse.tag="${CI_COMMIT_REF_SLUG}" \
    --set gitlab.task-runner.image.repository="${gitlab_task_runner_image_repository}" \
    --set gitlab.task-runner.image.tag="${CI_COMMIT_REF_SLUG}"
EOF
)

if [ -n "${REVIEW_APPS_EE_LICENSE}" ]; then
HELM_CMD=$(cat << EOF
  ${HELM_CMD} \
  --set global.gitlab.license.secret="shared-gitlab-license"
EOF
)
fi

HELM_CMD=$(cat << EOF
  ${HELM_CMD} \
  --version="${CI_PIPELINE_ID}-${CI_JOB_ID}" \
  -f "${base_config_file}" \
  "${release}" .
EOF
)

  echoinfo "Deploying with:"
  echoinfo "${HELM_CMD}"

  eval "${HELM_CMD}"
}

function display_deployment_debug() {
  local namespace="${KUBE_NAMESPACE}"
  local release="${CI_ENVIRONMENT_SLUG}"

  # Get all pods for this release
  echoinfo "Pods for release ${release}"
  kubectl get pods --namespace "${namespace}" -lrelease=${release}

  # Get all non-completed jobs
  echoinfo "Unsuccessful Jobs for release ${release}"
  kubectl get jobs --namespace "${namespace}" -lrelease=${release} --field-selector=status.successful!=1
}
