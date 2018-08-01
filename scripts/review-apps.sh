[[ "$TRACE" ]] && set -x
export TILLER_NAMESPACE="$KUBE_NAMESPACE"

function check_kube_domain() {
  if [ -z ${REVIEW_APPS_DOMAIN+x} ]; then
    echo "In order to deploy or use Review Apps, REVIEW_APPS_DOMAIN variable must be set"
    echo "You can do it in Auto DevOps project settings or defining a variable at group or project level"
    echo "You can also manually add it in .gitlab-ci.yml"
    false
  else
    true
  fi
}

function download_gitlab_chart() {
  curl -o gitlab.tar.bz2 https://gitlab.com/charts/gitlab/-/archive/$GITLAB_HELM_CHART_REF/gitlab-$GITLAB_HELM_CHART_REF.tar.bz2
  tar -xjf gitlab.tar.bz2
  cd gitlab-$GITLAB_HELM_CHART_REF

  helm init --client-only
  helm repo add gitlab https://charts.gitlab.io
  helm dependency update
  helm dependency build
}

function ensure_namespace() {
  kubectl describe namespace "$KUBE_NAMESPACE" || kubectl create namespace "$KUBE_NAMESPACE"
}

function install_tiller() {
  echo "Checking Tiller..."
  helm init --upgrade
  kubectl rollout status -n "$TILLER_NAMESPACE" -w "deployment/tiller-deploy"
  if ! helm version --debug; then
    echo "Failed to init Tiller."
    return 1
  fi
  echo ""
}

function create_secret() {
  echo "Create secret..."

  kubectl create secret generic -n "$KUBE_NAMESPACE" \
    $CI_ENVIRONMENT_SLUG-gitlab-initial-root-password \
    --from-literal=password=$REVIEW_APPS_ROOT_PASSWORD \
    --dry-run -o json | kubectl apply -f -
}

function previousDeployFailed() {
  set +e
  echo "Checking for previous deployment of $CI_ENVIRONMENT_SLUG"
  deployment_status=$(helm status $CI_ENVIRONMENT_SLUG >/dev/null 2>&1)
  status=$?
  # if `status` is `0`, deployment exists, has a status
  if [ $status -eq 0 ]; then
    echo "Previous deployment found, checking status"
    deployment_status=$(helm status $CI_ENVIRONMENT_SLUG | grep ^STATUS | cut -d' ' -f2)
    echo "Previous deployment state: $deployment_status"
    if [[ "$deployment_status" == "FAILED" || "$deployment_status" == "PENDING_UPGRADE" || "$deployment_status" == "PENDING_INSTALL" ]]; then
      status=0;
    else
      status=1;
    fi
  else
    echo "Previous deployment NOT found."
  fi
  set -e
  return $status
}

function deploy() {
  track="${1-stable}"
  name="$CI_ENVIRONMENT_SLUG"

  if [[ "$track" != "stable" ]]; then
    name="$name-$track"
  fi

  replicas="1"
  service_enabled="false"
  postgres_enabled="$POSTGRES_ENABLED"
  gitlab_migrations_image_repository="registry.gitlab.com/gitlab-org/build/cng-mirror/gitlab-rails-ce"
  gitlab_sidekiq_image_repository="registry.gitlab.com/gitlab-org/build/cng-mirror/gitlab-sidekiq-ce"
  gitlab_unicorn_image_repository="registry.gitlab.com/gitlab-org/build/cng-mirror/gitlab-unicorn-ce"

  if [[ "$CI_PROJECT_NAME" == "gitlab-ee" ]]; then
    gitlab_migrations_image_repository="registry.gitlab.com/gitlab-org/build/cng-mirror/gitlab-rails-ee"
    gitlab_sidekiq_image_repository="registry.gitlab.com/gitlab-org/build/cng-mirror/gitlab-sidekiq-ee"
    gitlab_unicorn_image_repository="registry.gitlab.com/gitlab-org/build/cng-mirror/gitlab-unicorn-ee"
  fi

  # canary uses stable db
  [[ "$track" == "canary" ]] && postgres_enabled="false"

  env_track=$( echo $track | tr -s  '[:lower:]'  '[:upper:]' )
  env_slug=$( echo ${CI_ENVIRONMENT_SLUG//-/_} | tr -s  '[:lower:]'  '[:upper:]' )

  if [[ "$track" == "stable" ]]; then
    # for stable track get number of replicas from `PRODUCTION_REPLICAS`
    eval new_replicas=\$${env_slug}_REPLICAS
    service_enabled="true"
  else
    # for all tracks get number of replicas from `CANARY_PRODUCTION_REPLICAS`
    eval new_replicas=\$${env_track}_${env_slug}_REPLICAS
  fi
  if [[ -n "$new_replicas" ]]; then
    replicas="$new_replicas"
  fi

  # Cleanup and previous installs, as FAILED and PENDING_UPGRADE will cause errors with `upgrade`
  if [ "$CI_ENVIRONMENT_SLUG" != "production" ] && previousDeployFailed ; then
    echo "Deployment in bad state, cleaning up $CI_ENVIRONMENT_SLUG"
    delete
    cleanup
  fi
  helm repo add gitlab https://charts.gitlab.io/
  helm dep update .

  helm upgrade --install \
    --wait \
    --timeout 600 \
    --set releaseOverride="$CI_ENVIRONMENT_SLUG" \
    --set global.hosts.hostSuffix="$HOST_SUFFIX" \
    --set global.hosts.domain="$REVIEW_APPS_DOMAIN" \
    --set global.hosts.externalIP="$REVIEW_APPS_DOMAIN_IP" \
    --set certmanager.install=false \
    --set global.ingress.configureCertmanager=false \
    --set global.ingress.tls.secretName=tls-cert \
    --set gitlab.unicorn.resources.requests.cpu=200m \
    --set gitlab.sidekiq.resources.requests.cpu=100m \
    --set gitlab.gitlab-shell.resources.requests.cpu=100m \
    --set redis.resources.requests.cpu=100m \
    --set minio.resources.requests.cpu=100m \
    --set gitlab.migrations.image.repository="$gitlab_migrations_image_repository" \
    --set gitlab.migrations.image.tag="$CI_COMMIT_REF_NAME" \
    --set gitlab.sidekiq.image.repository="$gitlab_sidekiq_image_repository" \
    --set gitlab.sidekiq.image.tag="$CI_COMMIT_REF_NAME" \
    --set gitlab.unicorn.image.repository="$gitlab_unicorn_image_repository" \
    --set gitlab.unicorn.image.tag="$CI_COMMIT_REF_NAME" \
    --set gitlab.gitaly.image.repository="registry.gitlab.com/gitlab-org/build/cng-mirror/gitaly" \
    --set gitlab.gitaly.image.tag="v$GITALY_VERSION" \
    --set gitlab.gitlab-shell.image.repository="registry.gitlab.com/gitlab-org/build/cng-mirror/gitlab-shell" \
    --set gitlab.gitlab-shell.image.tag="v$GITLAB_SHELL_VERSION" \
    --namespace="$KUBE_NAMESPACE" \
    --version="$CI_PIPELINE_ID-$CI_JOB_ID" \
    "$name" \
    .
}

function delete() {
  track="${1-stable}"
  name="$CI_ENVIRONMENT_SLUG"

  if [[ "$track" != "stable" ]]; then
    name="$name-$track"
  fi
  helm delete --purge "$name" || true
}

function cleanup() {
  kubectl -n "$KUBE_NAMESPACE" get ingress,svc,pdb,hpa,deploy,statefulset,job,pod,secret,configmap,pvc,secret,clusterrole,clusterrolebinding,role,rolebinding,sa 2>&1 \
    | grep "$CI_ENVIRONMENT_SLUG" \
    | awk '{print $1}' \
    | xargs kubectl -n "$KUBE_NAMESPACE" delete \
    || true
}
