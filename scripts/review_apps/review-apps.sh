[[ "$TRACE" ]] && set -x

function namespace_exists() {
  local namespace="${1}"
  local namespace_exists

  echoinfo "Checking if ${namespace} exists..." true

  kubectl describe namespace "${namespace}" >/dev/null 2>&1
  namespace_exists=$?

  if [ $namespace_exists -eq 0 ]; then
    echoinfo "Namespace ${namespace} found."
  else
    echoerr "Namespace ${namespace} NOT found."
  fi

  return $namespace_exists
}

function deploy_exists() {
  local namespace="${1}"
  local release="${2}"
  local deploy_exists

  echoinfo "Checking if ${release} exists in the ${namespace} namespace..." true

  helm status --namespace "${namespace}" "${release}" >/dev/null 2>&1
  deploy_exists=$?

  if [ $deploy_exists -eq 0 ]; then
    echoinfo "Previous deployment for ${release} found."
  else
    echoerr "Previous deployment for ${release} NOT found."
  fi

  return $deploy_exists
}

function previous_deploy_failed() {
  local namespace="${1}"
  local release="${2}"

  echoinfo "Checking for previous deployment of ${release}" true

  helm status --namespace "${namespace}" "${release}" >/dev/null 2>&1
  local status=$?

  # if `status` is `0`, deployment exists, has a status
  if [ $status -eq 0 ]; then
    echoinfo "Previous deployment found, checking status..."
    deployment_status=$(helm status --namespace "${namespace}" "${release}" | grep ^STATUS | cut -d' ' -f2)
    echoinfo "Previous deployment state: ${deployment_status}"
    if [[ "$deployment_status" == "failed" || "$deployment_status" == "pending-upgrade" || "$deployment_status" == "pending-install" ]]; then
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
  local namespace="${CI_ENVIRONMENT_SLUG}"
  local release="${CI_ENVIRONMENT_SLUG}"

  if [ -z "${release}" ]; then
    echoerr "No release given, aborting the delete!"
    return
  fi

  if deploy_exists "${namespace}" "${release}"; then
    helm uninstall --namespace="${namespace}" "${release}"
  fi
}

function delete_failed_release() {
  local namespace="${CI_ENVIRONMENT_SLUG}"
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
      echoinfo "Review App deployment in bad state, cleaning up namespace ${release}"
      delete_namespace
    else
      echoinfo "Review App deployment in good state"
    fi
  fi
}

function delete_namespace() {
  local namespace="${CI_ENVIRONMENT_SLUG}"

  if namespace_exists "${namespace}"; then
    echoinfo "Deleting namespace ${namespace}..." true
    kubectl delete namespace "${namespace}" --wait
  fi
}

function get_pod() {
  local namespace="${CI_ENVIRONMENT_SLUG}"
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

function run_task() {
  local namespace="${CI_ENVIRONMENT_SLUG}"
  local ruby_cmd="${1}"
  local toolbox_pod=$(get_pod "toolbox")

  kubectl exec --namespace "${namespace}" "${toolbox_pod}" -- gitlab-rails runner "${ruby_cmd}"
}

function disable_sign_ups() {
  if [ -z ${REVIEW_APPS_ROOT_TOKEN+x} ]; then
    echoerr "In order to protect Review Apps, REVIEW_APPS_ROOT_TOKEN variable must be set"
    false
  else
    true
  fi

  # Create the root token
  local set_token_rb="token = User.find_by_username('root').personal_access_tokens.create(scopes: [:api], name: 'Token to disable sign-ups'); token.set_token('${REVIEW_APPS_ROOT_TOKEN}'); begin; token.save!; rescue(ActiveRecord::RecordNotUnique); end"
  retry "run_task \"${set_token_rb}\""

  # Disable sign-ups
  local disable_signup_rb="Gitlab::CurrentSettings.current_application_settings.update!(signup_enabled: false)"
  if (retry "run_task \"${disable_signup_rb}\""); then
    echoinfo "Sign-ups have been disabled successfully."
  else
    echoerr "Sign-ups are still enabled!"
    false
  fi
}

function create_sample_projects() {
  local create_sample_projects_rb="root_user = User.find_by_username('root'); 1.times { |i| params = { namespace_id: root_user.namespace.id, name: 'sample-project' + i.to_s, path: 'sample-project' + i.to_s, template_name: 'sample' }; ::Projects::CreateFromTemplateService.new(root_user, params).execute }"

  # Queue jobs to create sample projects for root user namespace from sample data project template
  retry "run_task \"${create_sample_projects_rb}\""
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
  local namespace="${1}"

  if ! namespace_exists "${namespace}"; then
    echoinfo "Creating namespace ${namespace}..." true
    kubectl create namespace "${namespace}"
  fi
}

function label_namespace() {
  local namespace="${1}"
  local label="${2}"

  echoinfo "Labeling the ${namespace} namespace with ${label}" true
  echoinfo "We should pass the --overwrite option!"

  kubectl label --overwrite namespace "${namespace}" "${label}"
}

function create_application_secret() {
  local namespace="${CI_ENVIRONMENT_SLUG}"
  local release="${CI_ENVIRONMENT_SLUG}"
  local initial_root_password_shared_secret
  local gitlab_license_shared_secret

  initial_root_password_shared_secret=$(kubectl get secret --namespace ${namespace} --no-headers -o=custom-columns=NAME:.metadata.name shared-gitlab-initial-root-password 2> /dev/null | tail -n 1)
  if [[ "${initial_root_password_shared_secret}" == "" ]]; then
    echoinfo "Creating the 'shared-gitlab-initial-root-password' secret in the ${namespace} namespace..." true
    kubectl create secret generic --namespace "${namespace}" \
      "shared-gitlab-initial-root-password" \
      --from-literal="password=${REVIEW_APPS_ROOT_PASSWORD}" \
      --dry-run -o json | kubectl apply -f -
  else
    echoinfo "The 'shared-gitlab-initial-root-password' secret already exists in the ${namespace} namespace."
  fi

  if [ -z "${REVIEW_APPS_EE_LICENSE_FILE}" ]; then echo "License not found" && return; fi

  gitlab_license_shared_secret=$(kubectl get secret --namespace ${namespace} --no-headers -o=custom-columns=NAME:.metadata.name shared-gitlab-license 2> /dev/null | tail -n 1)
  if [[ "${gitlab_license_shared_secret}" == "" ]]; then
    echoinfo "Creating the 'shared-gitlab-license' secret in the ${namespace} namespace..." true
    kubectl create secret generic --namespace "${namespace}" \
      "shared-gitlab-license" \
      --from-file=license="${REVIEW_APPS_EE_LICENSE_FILE}" \
      --dry-run -o json | kubectl apply -f -
  else
    echoinfo "The 'shared-gitlab-license' secret already exists in the ${namespace} namespace."
  fi
}

function download_chart() {
  echoinfo "Downloading the GitLab chart..." true

  curl --location -o gitlab.tar.bz2 "https://gitlab.com/gitlab-org/charts/gitlab/-/archive/${GITLAB_HELM_CHART_REF}/gitlab-${GITLAB_HELM_CHART_REF}.tar.bz2"
  tar -xjf gitlab.tar.bz2

  echoinfo "Adding the gitlab repo to Helm..."
  helm repo add gitlab https://charts.gitlab.io

  echoinfo "Building the gitlab chart's dependencies..."
}

function base_config_changed() {
  if [ -z "${CI_MERGE_REQUEST_IID}" ]; then return; fi

  curl "${CI_API_V4_URL}/projects/${CI_MERGE_REQUEST_PROJECT_ID}/merge_requests/${CI_MERGE_REQUEST_IID}/changes" | jq '.changes | any(.old_path == "scripts/review_apps/base-config.yaml")'
}

function parse_gitaly_image_tag() {
  local gitaly_version="${GITALY_VERSION}"

  # prepend semver version with `v`
  if [[ $gitaly_version =~  ^[0-9]+\.[0-9]+\.[0-9]+(-rc[0-9]+)?(-ee)?$ ]]; then
    echo "v${gitaly_version}"
  else
    echo "${gitaly_version}"
  fi
}

function deploy() {
  local namespace="${CI_ENVIRONMENT_SLUG}"
  local release="${CI_ENVIRONMENT_SLUG}"
  local base_config_file_ref="${CI_DEFAULT_BRANCH}"
  if [[ "$(base_config_changed)" == "true" ]]; then base_config_file_ref="${CI_COMMIT_SHA}"; fi
  local base_config_file="https://gitlab.com/gitlab-org/gitlab/raw/${base_config_file_ref}/scripts/review_apps/base-config.yaml"

  echoinfo "Deploying ${release} to ${CI_ENVIRONMENT_URL} ..." true

  IMAGE_REPOSITORY="registry.gitlab.com/gitlab-org/build/cng-mirror"
  gitlab_toolbox_image_repository="${IMAGE_REPOSITORY}/gitlab-toolbox-ee"
  gitlab_sidekiq_image_repository="${IMAGE_REPOSITORY}/gitlab-sidekiq-ee"
  gitlab_webservice_image_repository="${IMAGE_REPOSITORY}/gitlab-webservice-ee"
  gitlab_gitaly_image_repository="${IMAGE_REPOSITORY}/gitaly"
  gitaly_image_tag=$(parse_gitaly_image_tag)
  gitlab_shell_image_repository="${IMAGE_REPOSITORY}/gitlab-shell"
  gitlab_workhorse_image_repository="${IMAGE_REPOSITORY}/gitlab-workhorse-ee"
  sentry_enabled="false"

  if [ -n ${REVIEW_APPS_SENTRY_DSN} ]; then
    echo "REVIEW_APPS_SENTRY_DSN detected, enabling Sentry"
    sentry_enabled="true"
  fi

  ensure_namespace "${namespace}"
  label_namespace "${namespace}" "tls=review-apps-tls" # label namespace for kubed to sync tls

  create_application_secret

HELM_CMD=$(cat << EOF
  helm upgrade \
    --namespace="${namespace}" \
    --create-namespace \
    --install \
    --wait \
    --timeout "${HELM_INSTALL_TIMEOUT:-20m}" \
    --set ci.branch="${CI_COMMIT_REF_NAME}" \
    --set ci.commit.sha="${CI_COMMIT_SHORT_SHA}" \
    --set ci.job.url="${CI_JOB_URL}" \
    --set ci.pipeline.url="${CI_PIPELINE_URL}" \
    --set releaseOverride="${release}" \
    --set global.hosts.hostSuffix="${HOST_SUFFIX}" \
    --set global.hosts.domain="${REVIEW_APPS_DOMAIN}" \
    --set global.appConfig.sentry.enabled="${sentry_enabled}" \
    --set global.appConfig.sentry.dsn="${REVIEW_APPS_SENTRY_DSN}" \
    --set global.appConfig.sentry.environment="review" \
    --set gitlab.migrations.image.repository="${gitlab_toolbox_image_repository}" \
    --set gitlab.migrations.image.tag="${CI_COMMIT_REF_SLUG}" \
    --set gitlab.gitaly.image.repository="${gitlab_gitaly_image_repository}" \
    --set gitlab.gitaly.image.tag="${gitaly_image_tag}" \
    --set gitlab.gitlab-shell.image.repository="${gitlab_shell_image_repository}" \
    --set gitlab.gitlab-shell.image.tag="v${GITLAB_SHELL_VERSION}" \
    --set gitlab.sidekiq.annotations.commit="${CI_COMMIT_SHORT_SHA}" \
    --set gitlab.sidekiq.image.repository="${gitlab_sidekiq_image_repository}" \
    --set gitlab.sidekiq.image.tag="${CI_COMMIT_REF_SLUG}" \
    --set gitlab.webservice.annotations.commit="${CI_COMMIT_SHORT_SHA}" \
    --set gitlab.webservice.image.repository="${gitlab_webservice_image_repository}" \
    --set gitlab.webservice.image.tag="${CI_COMMIT_REF_SLUG}" \
    --set gitlab.webservice.workhorse.image="${gitlab_workhorse_image_repository}" \
    --set gitlab.webservice.workhorse.tag="${CI_COMMIT_REF_SLUG}" \
    --set gitlab.toolbox.image.repository="${gitlab_toolbox_image_repository}" \
    --set gitlab.toolbox.image.tag="${CI_COMMIT_REF_SLUG}"
EOF
)

if [ -n "${REVIEW_APPS_EE_LICENSE_FILE}" ]; then
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
  -v "${HELM_LOG_VERBOSITY:-1}" \
  "${release}" "gitlab-${GITLAB_HELM_CHART_REF}"
EOF
)

  echoinfo "Deploying with:"
  echoinfo "${HELM_CMD}"

  eval "${HELM_CMD}"
}

function verify_deploy() {
  echoinfo "Verifying deployment at ${CI_ENVIRONMENT_URL}"

  if retry "test_url \"${CI_ENVIRONMENT_URL}\""; then
    echoinfo "Review app is deployed to ${CI_ENVIRONMENT_URL}"
    return 0
  else
    echoerr "Review app is not available at ${CI_ENVIRONMENT_URL}: see the logs from cURL above for more details"
    return 1
  fi
}

function display_deployment_debug() {
  local namespace="${CI_ENVIRONMENT_SLUG}"
  local release="${CI_ENVIRONMENT_SLUG}"

  # Get all pods for this release
  echoinfo "Pods for release ${release}"
  kubectl get pods --namespace "${namespace}" -lrelease=${release}

  # Get all non-completed jobs
  echoinfo "Unsuccessful Jobs for release ${release}"
  kubectl get jobs --namespace "${namespace}" -lrelease=${release} --field-selector=status.successful!=1
}
