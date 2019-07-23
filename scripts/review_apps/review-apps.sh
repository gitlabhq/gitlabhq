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

function delete() {
  if [ -z "$CI_ENVIRONMENT_SLUG" ]; then
    echoerr "No release given, aborting the delete!"
    return
  fi

  local name="$CI_ENVIRONMENT_SLUG"

  echoinfo "Deleting release '$name'..." true

  helm delete --purge "$name"
}

function get_pod() {
  local app_name="${1}"
  local status="${2-Running}"
  get_pod_cmd="kubectl get pods -n ${KUBE_NAMESPACE} --field-selector=status.phase=${status} -lapp=${app_name},release=${CI_ENVIRONMENT_SLUG} --no-headers -o=custom-columns=NAME:.metadata.name"
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
}

function download_chart() {
  echoinfo "Downloading the GitLab chart..." true

  curl -o gitlab.tar.bz2 "https://gitlab.com/charts/gitlab/-/archive/${GITLAB_HELM_CHART_REF}/gitlab-${GITLAB_HELM_CHART_REF}.tar.bz2"
  tar -xjf gitlab.tar.bz2
  cd "gitlab-${GITLAB_HELM_CHART_REF}"

  echoinfo "Adding the gitlab repo to Helm..."
  helm repo add gitlab https://charts.gitlab.io

  echoinfo "Building the gitlab chart's dependencies..."
  helm dependency build .
}

function deploy() {
  local name="$CI_ENVIRONMENT_SLUG"
  echoinfo "Deploying ${name}..." true

  IMAGE_REPOSITORY="registry.gitlab.com/gitlab-org/build/cng-mirror"
  IMAGE_VERSION="${CI_PROJECT_NAME#gitlab-}"
  gitlab_migrations_image_repository="${IMAGE_REPOSITORY}/gitlab-rails-${IMAGE_VERSION}"
  gitlab_sidekiq_image_repository="${IMAGE_REPOSITORY}/gitlab-sidekiq-${IMAGE_VERSION}"
  gitlab_unicorn_image_repository="${IMAGE_REPOSITORY}/gitlab-unicorn-${IMAGE_VERSION}"
  gitlab_task_runner_image_repository="${IMAGE_REPOSITORY}/gitlab-task-runner-${IMAGE_VERSION}"
  gitlab_gitaly_image_repository="${IMAGE_REPOSITORY}/gitaly"
  gitlab_shell_image_repository="${IMAGE_REPOSITORY}/gitlab-shell"
  gitlab_workhorse_image_repository="${IMAGE_REPOSITORY}/gitlab-workhorse-${IMAGE_VERSION}"

  # Cleanup and previous installs, as FAILED and PENDING_UPGRADE will cause errors with `upgrade`
  if [ "$CI_ENVIRONMENT_SLUG" != "production" ] && previous_deploy_failed "$CI_ENVIRONMENT_SLUG" ; then
    echo "Deployment in bad state, cleaning up $CI_ENVIRONMENT_SLUG"
    delete
  fi

  create_application_secret

HELM_CMD=$(cat << EOF
  helm upgrade --install \
    --wait \
    --timeout 600 \
    --set releaseOverride="$CI_ENVIRONMENT_SLUG" \
    --set global.appConfig.enableUsagePing=false \
    --set global.imagePullPolicy=Always \
    --set global.hosts.hostSuffix="$HOST_SUFFIX" \
    --set global.hosts.domain="$REVIEW_APPS_DOMAIN" \
    --set global.ingress.configureCertmanager=false \
    --set global.ingress.tls.secretName=tls-cert \
    --set global.ingress.annotations."external-dns\.alpha\.kubernetes\.io/ttl"="10" \
    --set certmanager.install=false \
    --set prometheus.install=false \
    --set nginx-ingress.controller.service.enableHttp=false \
    --set nginx-ingress.controller.replicaCount=2 \
    --set nginx-ingress.controller.config.ssl-ciphers="ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA:ECDHE-RSA-AES128-SHA:AES256-GCM-SHA384:AES128-GCM-SHA256:AES256-SHA256:AES128-SHA256:AES256-SHA:AES128-SHA:!aNULL:!eNULL:!EXPORT:!DES:!MD5:!PSK:!RC4" \
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

# Default requested: CPU => 100m, memory => 100Mi
HELM_CMD=$(cat << EOF
  $HELM_CMD \
  --set nginx-ingress.controller.resources.limits.cpu=200m \
  --set nginx-ingress.controller.resources.requests.memory=210M \
  --set nginx-ingress.controller.resources.limits.memory=420M
EOF
)

# Default requested: CPU => 5m, memory => 5Mi
HELM_CMD=$(cat << EOF
  $HELM_CMD \
  --set nginx-ingress.defaultBackend.resources.limits.cpu=10m \
  --set nginx-ingress.defaultBackend.resources.requests.memory=12M \
  --set nginx-ingress.defaultBackend.resources.limits.memory=24M
EOF
)

# Default requested: CPU => 100m, memory => 200Mi
HELM_CMD=$(cat << EOF
  $HELM_CMD \
  --set gitlab.gitaly.resources.requests.cpu=150m \
  --set gitlab.gitaly.resources.limits.cpu=300m \
  --set gitlab.gitaly.resources.limits.memory=420M
EOF
)

# Default requested: CPU => 0, memory => 6M
HELM_CMD=$(cat << EOF
  $HELM_CMD \
  --set gitlab.gitlab-shell.resources.requests.cpu=70m \
  --set gitlab.gitlab-shell.resources.limits.cpu=140m \
  --set gitlab.gitlab-shell.resources.requests.memory=20M \
  --set gitlab.gitlab-shell.resources.limits.memory=40M
EOF
)

# Default requested: CPU => 50m, memory => 650M
HELM_CMD=$(cat << EOF
  $HELM_CMD \
  --set gitlab.sidekiq.resources.requests.cpu=200m \
  --set gitlab.sidekiq.resources.limits.cpu=300m \
  --set gitlab.sidekiq.resources.requests.memory=800M \
  --set gitlab.sidekiq.resources.limits.memory=1.2G
EOF
)

# Default requested: CPU => 300m + 100m (workhorse), memory => 1.2G + 100M (workhorse)
HELM_CMD=$(cat << EOF
  $HELM_CMD \
  --set gitlab.unicorn.resources.limits.cpu=800m \
  --set gitlab.unicorn.resources.limits.memory=2.6G
EOF
)

# Default requested: CPU => 100m, memory => 64Mi
HELM_CMD=$(cat << EOF
  $HELM_CMD \
  --set redis.resources.limits.cpu=200m \
  --set redis.resources.limits.memory=130M
EOF
)

# Default requested: CPU => 100m, memory => 128Mi
HELM_CMD=$(cat << EOF
  $HELM_CMD \
  --set minio.resources.limits.cpu=200m \
  --set minio.resources.limits.memory=280M
EOF
)

# Default requested: CPU => 0, memory => 0
HELM_CMD=$(cat << EOF
  $HELM_CMD \
  --set gitlab-runner.resources.requests.cpu=300m \
  --set gitlab-runner.resources.limits.cpu=600m \
  --set gitlab-runner.resources.requests.memory=300M \
  --set gitlab-runner.resources.limits.memory=600M
EOF
)

HELM_CMD=$(cat << EOF
  $HELM_CMD \
  --namespace="$KUBE_NAMESPACE" \
  --version="$CI_PIPELINE_ID-$CI_JOB_ID" \
  "$name" .
EOF
)

  echoinfo "Deploying with:"
  echoinfo "${HELM_CMD}"

  eval "${HELM_CMD}"
}

function display_deployment_debug() {
  migrations_pod=$(get_pod "migrations");
  if [ -z "${migrations_pod}" ]; then
    echoerr "Migrations pod not found."
  else
    echoinfo "Logs tail of the ${migrations_pod} pod..."

    kubectl logs -n "$KUBE_NAMESPACE" "${migrations_pod}" | sed "s/${REVIEW_APPS_ROOT_PASSWORD}/[REDACTED]/g"
  fi

  unicorn_pod=$(get_pod "unicorn");
  if [ -z "${unicorn_pod}" ]; then
    echoerr "Unicorn pod not found."
  else
    echoinfo "Logs tail of the ${unicorn_pod} pod..."

    kubectl logs -n "$KUBE_NAMESPACE" -c unicorn "${unicorn_pod}" | sed "s/${REVIEW_APPS_ROOT_PASSWORD}/[REDACTED]/g"
  fi
}

function wait_for_review_app_to_be_accessible() {
  echoinfo "Waiting for the Review App at ${CI_ENVIRONMENT_URL} to be accessible..." true

  local interval=5
  local elapsed_seconds=0
  local max_seconds=$((2 * 60))
  while true; do
    local review_app_http_code
    review_app_http_code=$(curl --silent --output /dev/null --max-time 5 --write-out "%{http_code}" "${CI_ENVIRONMENT_URL}/users/sign_in")
    if [[ "${review_app_http_code}" -eq "200" ]] || [[ "${elapsed_seconds}" -gt "${max_seconds}" ]]; then
      break
    fi

    let "elapsed_seconds+=interval"
    sleep ${interval}
  done

  if [[ "${review_app_http_code}" -eq "200" ]]; then
    echoinfo "The Review App at ${CI_ENVIRONMENT_URL} is ready after ${elapsed_seconds} seconds!"
  else
    echoerr "The Review App at ${CI_ENVIRONMENT_URL} isn't ready after ${max_seconds} seconds of polling..."
    exit 1
  fi
}

function add_license() {
  if [ -z "${REVIEW_APPS_EE_LICENSE}" ]; then echo "License not found" && return; fi

  task_runner_pod=$(get_pod "task-runner");
  if [ -z "${task_runner_pod}" ]; then echo "Task runner pod not found" && return; fi

  echoinfo "Installing license..." true

  echo "${REVIEW_APPS_EE_LICENSE}" > /tmp/license.gitlab
  kubectl -n "$KUBE_NAMESPACE" cp /tmp/license.gitlab "${task_runner_pod}":/tmp/license.gitlab
  rm /tmp/license.gitlab

  kubectl -n "$KUBE_NAMESPACE" exec -it "${task_runner_pod}" -- /srv/gitlab/bin/rails runner -e production \
    '
    content = File.read("/tmp/license.gitlab").strip;
    FileUtils.rm_f("/tmp/license.gitlab");

    unless License.where(data:content).empty?
      puts "License already exists";
      Kernel.exit 0;
    end

    unless License.new(data: content).save
      puts "Could not add license";
      Kernel.exit 0;
    end

    puts "License added";
    '
}
