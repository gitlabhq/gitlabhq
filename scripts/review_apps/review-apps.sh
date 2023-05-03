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

function delete_helm_release() {
  local namespace="${CI_ENVIRONMENT_SLUG}"
  local release="${CI_ENVIRONMENT_SLUG}"

  if [ -z "${release}" ]; then
    echoerr "No release given, aborting the delete!"
    return
  fi

  if deploy_exists "${namespace}" "${release}"; then
    helm uninstall --namespace="${namespace}" "${release}"
  fi

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

  run_timed_command "kubectl exec --namespace \"${namespace}\" \"${toolbox_pod}\" -- gitlab-rails runner \"${ruby_cmd}\""
}

function disable_sign_ups() {
  if [ -z ${REVIEW_APPS_ROOT_TOKEN+x} ]; then
    echoerr "In order to protect Review Apps, REVIEW_APPS_ROOT_TOKEN variable must be set"
    false
  else
    true
  fi

# Create the root token + Disable sign-ups
#
# We use this weird syntax because we need to pass a one-liner ruby command to a Kubernetes container via kubectl.
read -r -d '' multiline_ruby_code <<RUBY
user = User.find_by_username('root');
puts 'Error: Could not find root user. Check that the database was properly seeded'; exit(1) unless user;
token = user.personal_access_tokens.create(scopes: [:api], name: 'Token to disable sign-ups');
token.set_token('${REVIEW_APPS_ROOT_TOKEN}');
begin;
token.save!;
rescue(ActiveRecord::RecordNotUnique);
end;
Gitlab::CurrentSettings.current_application_settings.update!(signup_enabled: false);
RUBY

  local disable_signup_rb=$(echo $multiline_ruby_code | tr '\n' ' ')
  if (retry_exponential "run_task \"${disable_signup_rb}\""); then
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
      --dry-run=client -o json | kubectl apply -f -
  else
    echoinfo "The 'shared-gitlab-initial-root-password' secret already exists in the ${namespace} namespace."
  fi

  if [ -z "${REVIEW_APPS_EE_LICENSE_FILE}" ]; then echo "License not found" && return; fi

  gitlab_license_shared_secret=$(kubectl get secret --namespace "${namespace}" --no-headers -o=custom-columns=NAME:.metadata.name shared-gitlab-license 2> /dev/null | tail -n 1)
  if [[ "${gitlab_license_shared_secret}" == "" ]]; then
    echoinfo "Creating the 'shared-gitlab-license' secret in the "${namespace}" namespace..." true
    kubectl create secret generic --namespace "${namespace}" \
      "shared-gitlab-license" \
      --from-file=license="${REVIEW_APPS_EE_LICENSE_FILE}" \
      --dry-run=client -o json | kubectl apply -f -
  else
    echoinfo "The 'shared-gitlab-license' secret already exists in the ${namespace} namespace."
  fi
}

function download_chart() {
  # If the requirements.lock is present, it means we got everything we need from the cache.
  if [[ -f "gitlab-${GITLAB_HELM_CHART_REF}/requirements.lock" ]]; then
    echosuccess "Downloading/Building chart dependencies skipped. Using the chart ${gitlab-${GITLAB_HELM_CHART_REF}} local folder'..."
  else
    echoinfo "Downloading the GitLab chart..." true

    curl --location -o gitlab.tar.bz2 "https://gitlab.com/gitlab-org/charts/gitlab/-/archive/${GITLAB_HELM_CHART_REF}/gitlab-${GITLAB_HELM_CHART_REF}.tar.bz2"
    tar -xjf gitlab.tar.bz2

    echoinfo "Adding the gitlab repo to Helm..."
    helm repo add gitlab https://charts.gitlab.io

    echoinfo "Building the gitlab chart's dependencies..."
    helm dependency build "gitlab-${GITLAB_HELM_CHART_REF}"
  fi
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

  if [ -n "${REVIEW_APPS_SENTRY_DSN}" ]; then
    echo "REVIEW_APPS_SENTRY_DSN detected, enabling Sentry"
    sentry_enabled="true"
  fi

  retry "ensure_namespace \"${namespace}\""
  retry "label_namespace \"${namespace}\" \"tls=review-apps-tls\"" # label namespace for kubed to sync tls

  retry "create_application_secret"

cat > review_apps.values.yml <<EOF
  ci:
    branch: "${CI_COMMIT_REF_NAME}"
    commit:
      sha: "${CI_COMMIT_SHORT_SHA}"
    job:
      url: "${CI_JOB_URL}"
    pipeline:
      url: "${CI_PIPELINE_URL}"

  gitlab:
    gitaly:
      image:
        repository: "${gitlab_gitaly_image_repository}"
        tag: "${gitaly_image_tag}"
    gitlab-shell:
      image:
        repository: "${gitlab_shell_image_repository}"
        tag: "v${GITLAB_SHELL_VERSION}"
    migrations:
      image:
        repository: "${gitlab_toolbox_image_repository}"
        tag: "${CI_COMMIT_SHA}"
    sidekiq:
      annotations:
        commit: "${CI_COMMIT_SHORT_SHA}"
      image:
        repository: "${gitlab_sidekiq_image_repository}"
        tag: "${CI_COMMIT_SHA}"
    toolbox:
      image:
        repository: "${gitlab_toolbox_image_repository}"
        tag: "${CI_COMMIT_SHA}"
    webservice:
      annotations:
        commit: "${CI_COMMIT_SHORT_SHA}"
      extraEnv:
        REVIEW_APPS_ENABLED: "true"
        REVIEW_APPS_MERGE_REQUEST_IID: "${CI_MERGE_REQUEST_IID}"
      image:
        repository: "${gitlab_webservice_image_repository}"
        tag: "${CI_COMMIT_SHA}"
      workhorse:
        image: "${gitlab_workhorse_image_repository}"
        tag: "${CI_COMMIT_SHA}"

  global:
    hosts:
      domain: "${REVIEW_APPS_DOMAIN}"
      hostSuffix: "${HOST_SUFFIX}"
    appConfig:
      sentry:
        dsn: "${REVIEW_APPS_SENTRY_DSN}"
        # Boolean fields should be left without quotes
        enabled: ${sentry_enabled}
        environment: "review"

  releaseOverride: "${release}"
EOF

HELM_CMD=$(cat << EOF
  helm upgrade \
    --namespace="${namespace}" \
    --create-namespace \
    --install \
    --wait \
    --timeout "${HELM_INSTALL_TIMEOUT:-20m}"
EOF
)

if [ -n "${REVIEW_APPS_EE_LICENSE_FILE}" ]; then
HELM_CMD=$(cat << EOF
  ${HELM_CMD} \
    --set global.gitlab.license.secret="shared-gitlab-license"
EOF
)
fi

# Important: the `-f` calls are ordered. They should not be changed.
#
# The `base_config_file` contains the default values for the chart, and the
# `review_apps.values.yml` contains the overrides we want to apply specifically
# for this review app deployment.
HELM_CMD=$(cat << EOF
  ${HELM_CMD} \
    --version="${CI_PIPELINE_ID}-${CI_JOB_ID}" \
    -f "${base_config_file}" \
    -f review_apps.values.yml \
    -v "${HELM_LOG_VERBOSITY:-1}" \
    "${release}" "gitlab-${GITLAB_HELM_CHART_REF}"
EOF
)

  # Pretty-print the command for display
  echoinfo "Deploying with helm command:"
  echo "${HELM_CMD}" | sed 's/    /\n\t/g'

  echoinfo "Content of review_apps.values.yml:"
  cat review_apps.values.yml

  retry "eval \"${HELM_CMD}\""
}

function verify_deploy() {
  local deployed="false"

  mkdir -p curl-logs/

  for i in {1..60}; do # try for 5 minutes
    local now=$(date '+%H:%M:%S')
    echo "[${now}] Verifying deployment at ${CI_ENVIRONMENT_URL}/users/sign_in"
    log_name="curl-logs/${now}.log"
    curl --connect-timeout 3 -o "${log_name}" -s "${CI_ENVIRONMENT_URL}/users/sign_in"

    if grep "Remember me" "${log_name}" &> /dev/null; then
      deployed="true"
      break
    fi

    sleep 5
  done

  if [[ "${deployed}" == "true" ]]; then
    echoinfo "[$(date '+%H:%M:%S')] Review app is deployed to ${CI_ENVIRONMENT_URL}"
  else
    echoerr "[$(date '+%H:%M:%S')] Review app is not available at ${CI_ENVIRONMENT_URL}: see the logs from cURL above for more details"
    return 1
  fi
}

# We need to be able to access the GitLab API to run this method.
# Since we are creating a personal access token in `disable_sign_ups`,
# This method should be executed after it.
function verify_commit_sha() {
  local verify_success="false"

  for i in {1..60}; do # try for 2 minutes in case review-apps containers are restarting
    echoinfo "[$(date '+%H:%M:%S')] Checking the correct commit is deployed in the review-app:"
    echo "Expected commit sha: ${CI_COMMIT_SHA}"

    review_app_revision=$(curl --header "PRIVATE-TOKEN: ${REVIEW_APPS_ROOT_TOKEN}" "${CI_ENVIRONMENT_URL}/api/v4/metadata" | jq -r .revision)
    echo "review-app revision: ${review_app_revision}"

    if [[ "${CI_COMMIT_SHA}" == "${review_app_revision}"* ]]; then
      verify_success="true"
      break
    fi

    sleep 2
  done

  if [[ "${verify_success}" != "true" ]]; then
    echoerr "[$(date '+%H:%M:%S')] Review app revision is not the same as the current commit!"
    return 1
  fi

  return 0
}

function display_deployment_debug() {
  local namespace="${CI_ENVIRONMENT_SLUG}"

  # Install dig to inspect DNS entries
  apk add -q bind-tools

  echoinfo "[debugging data] Check review-app webservice DNS entry:"
  dig +short $(echo "${CI_ENVIRONMENT_URL}" | sed 's~http[s]*://~~g')

  echoinfo "[debugging data] Check external IP for nginx-ingress-controller service (should be THE SAME AS the DNS entry IP above):"
  kubectl -n "${namespace}" get svc "${namespace}-nginx-ingress-controller" -o jsonpath='{.status.loadBalancer.ingress[].ip}'

  echoinfo "[debugging data] k8s resources:"
  kubectl -n "${namespace}" get pods

  echoinfo "[debugging data] PostgreSQL logs:"
  kubectl -n "${namespace}" logs -l app=postgresql --all-containers

  echoinfo "[debugging data] DB migrations logs:"
  kubectl -n "${namespace}" logs -l app=migrations --all-containers

  echoinfo "[debugging data] Webservice logs:"
  kubectl -n "${namespace}" logs -l app=webservice -c webservice
}
