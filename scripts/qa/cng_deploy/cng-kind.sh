#!/bin/bash

#
# General utils
#

function log() {
  echo -e "\033[1;32m$1\033[0m"
}

function warn() {
  echo -e "\033[1;33m$1\033[0m"
}

function log_info() {
  echo -e "\033[1;35m$1\033[0m"
}

function log_with_header() {
  length=$(echo "$1" | awk '{print length}')
  delimiter=$(printf -- "${2:-=}%.0s" $(seq $length))

  log_info "$delimiter"
  log_info "$1"
  log_info "$delimiter"
}

#
# Deploy functions
#
function get_redis_version() {
  # version number is fetched from constant definition in redis_version_check.rb
  local version_type=${1:-RECOMMENDED_REDIS_VERSION}

  awk -F "=" "/${version_type} =/ {print \$2}" $CI_PROJECT_DIR/lib/system_check/app/redis_version_check.rb | sed "s/['\" ]//g"
}

function chart_values() {
  local domain=$1
  local values_file="cng-deploy-values.yml"

  local gitlab_image_repository="registry.gitlab.com/gitlab-org/build/cng-mirror"
  local gitlab_toolbox_image_repository="${gitlab_image_repository}/gitlab-toolbox-ee"
  local gitlab_sidekiq_image_repository="${gitlab_image_repository}/gitlab-sidekiq-ee"
  local gitlab_webservice_image_repository="${gitlab_image_repository}/gitlab-webservice-ee"
  local gitlab_workhorse_image_repository="${gitlab_image_repository}/gitlab-workhorse-ee"
  local gitlab_shell_image_repository="${gitlab_image_repository}/gitlab-shell"
  local gitlab_shell_image_tag="$(cat $CI_PROJECT_DIR/GITLAB_SHELL_VERSION)"
  local gitlab_gitaly_image_repository="${gitlab_image_repository}/gitaly"
  local gitaly_image_tag="$(cat $CI_PROJECT_DIR/GITALY_SERVER_VERSION)"
  local redis_version="$(get_redis_version $REDIS_VERSION_TYPE)"

  cat > $values_file <<EOF
global:
  hosts:
    domain: $domain
    https: false
  ingress:
    configureCertmanager: false
    tls:
      enabled: false
  extraEnv:
    GITLAB_LICENSE_MODE: test
    CUSTOMER_PORTAL_URL: https://customers.staging.gitlab.com
  initialRootPassword:
    secret: gitlab-initial-root-password
  gitlab:
    license:
      secret: gitlab-license
  gitaly:
    hooks:
      preReceive:
        configmap: pre-receive-hook
  appConfig:
    applicationSettingsCacheSeconds: 0

gitlab:
  gitaly:
    image:
      repository: "${gitlab_gitaly_image_repository}"
      tag: "${gitaly_image_tag}"
  gitlab-shell:
    image:
      repository: "${gitlab_shell_image_repository}"
      tag: "v${gitlab_shell_image_tag}"
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
    image:
      repository: "${gitlab_webservice_image_repository}"
      tag: "${CI_COMMIT_SHA}"
    workhorse:
      image: "${gitlab_workhorse_image_repository}"
      tag: "${CI_COMMIT_SHA}"
  gitlab-exporter:
    enabled: false

# Provision specific version of redis (either recommended or minimum supported)
redis:
  metrics:
    enabled: false
  image:
    tag: "${redis_version%.*}"

# Don't use certmanager, we'll self-sign or use http
certmanager:
  install: false

# Specify NodePorts for NGINX and reduce replicas to 1
nginx-ingress:
  controller:
    replicaCount: 1
    minAavailable: 1
    service:
      type: NodePort
      nodePorts:
        # gitlab-shell port value below must match the KinD config file:
        #   nodes[0].extraPortMappings[1].containerPort
        gitlab-shell: 32022
        # http port value below must match the KinD config file:
        #   nodes[0].extraPortMappings[0].containerPort
        http: 32080

# Each test creates it's own runner, skip preinstalling runners
gitlab-runner:
  install: false

# Disable metrics
prometheus:
  install: false
EOF

echo $values_file
}

function add_root_token() {
  cmd=$(
    cat <<EOF
user = User.find_by_username('root');
abort 'Error: Could not find root user. Check that the database was properly seeded' unless user;
token = user.personal_access_tokens.create(scopes: [:api], name: 'Token to disable sign-ups', expires_at: 30.days.from_now);
token.set_token('${GITLAB_QA_ADMIN_ACCESS_TOKEN}');
token.save!;
EOF
  )

  log_info "Add root user PAT"
  local toolbox_pod=$(kubectl get pods --namespace ${NAMESPACE} -lapp=toolbox --no-headers -o=custom-columns=NAME:.metadata.name | tail -n 1)
  kubectl exec --namespace "${NAMESPACE}" --container toolbox "${toolbox_pod}" -- gitlab-rails runner "${cmd}"
  log "success!"
}

function deploy() {
  local domain=$1
  local values=$(chart_values $domain)

  log_with_header "Install GitLab"
  log_info "Using following values.yml"
  cat $values

  log_info "Running helm install"
  helm install gitlab gitlab/gitlab \
    --namespace "$NAMESPACE" \
    --values $values \
    --timeout 5m \
    --wait

  add_root_token
}

function save_install_logs() {
  log_with_header "Events of namespace ${NAMESPACE}"
  kubectl get events --output wide --namespace ${NAMESPACE}

  for pod in $(kubectl get pods --no-headers --namespace ${NAMESPACE} --output jsonpath={.items[*].metadata.name}); do
    log_with_header "Description of pod ${pod}"
    kubectl describe pod ${pod} --namespace ${NAMESPACE}

    for container in $(kubectl get pods ${pod} --no-headers --namespace ${NAMESPACE} --output jsonpath={.spec.initContainers[*].name}); do
      kubectl logs ${pod} --namespace ${NAMESPACE} --container ${container} >"${container}.log"
    done

    for container in $(kubectl get pods ${pod} --no-headers --namespace ${NAMESPACE} --output jsonpath={.spec.containers[*].name}); do
      kubectl logs ${pod} --namespace ${NAMESPACE} --container ${container} >"${container}.log"
    done
  done
}
