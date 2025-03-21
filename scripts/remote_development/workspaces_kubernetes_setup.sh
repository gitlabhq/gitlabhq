#!/usr/bin/env bash

# This script configures an existing local Kubernetes cluster for usage with Workspaces.
# This involves installing an Ingress Controller(Ingress Nginx) and installing GitLab Workspaces Proxy.
#
# It uses the following environment variables
# $INGRESS_NGINX_HELM_CHART_VERSION - Ingress Nginx Helm Chart version.
# $GITLAB_WORKSPACES_PROXY_HELM_CHART_VERSION - GitLab Workspaces Proxy Helm Chart version.
# $GITLAB_WORKSPACES_PROXY_HELM_RELEASE_NAME - GitLab Workspaces Proxy helm release name
# $GITLAB_WORKSPACES_PROXY_HELM_RELEASE_NAMESPACE - GitLab Workspaces Proxy helm release namespace
# $GITLAB_WORKSPACES_PROXY_DOMAIN - GitLab Workspaces Proxy domain
# $GITLAB_WORKSPACES_PROXY_WILDCARD_DOMAIN - GitLab Workspaces Proxy wildcard domain where workspaces will be on
# $GITLAB_WORKSPACES_PROXY_REDIRECT_URI - GitLab Workspaces Proxy redirect uri for OAuth application
# $GITLAB_WORKSPACES_PROXY_SIGNING_KEY - GitLab Workspaces Proxy signing key
# $GITLAB_WORKSPACES_PROXY_SSH_HOST_KEY - GitLab Workspaces Proxy SSH host key
# $GITLAB_WORKSPACES_PROXY_TLS_CERT_FILE - GitLab Workspaces Proxy TLS Certificate file
# $GITLAB_WORKSPACES_PROXY_TLS_KEY_FILE - GitLab Workspaces Proxy TLS Key file
# $GITLAB_WORKSPACES_PROXY_WILDCARD_TLS_CERT_FILE - GitLab Workspaces Proxy TLS Certificate file
# $GITLAB_WORKSPACES_PROXY_WILDCARD_TLS_KEY_FILE - GitLab Workspaces Proxy TLS Key file
# $GITLAB_URL - GitLab URL
# $CLIENT_ID - OAuth Client ID used in GitLab Workspaces Proxy.
# $CLIENT_SECRET - OAuth Client Secret used in GitLab Workspaces Proxy.
#
# If this is the first time this script in being run in the Kubernetes cluster, you need to export the environment
# variables listed above. Use the following command:
#
# CLIENT_ID="UPDATE_ME" CLIENT_SECRET="UPDATE_ME" ./scripts/remote_development/workspaces_kubernetes_setup.sh
#
# If this is the first time this script in being run in an environment which requires non-default GitLab URL or the GitLab Workspaces Proxy domains
#
# GITLAB_WORKSPACES_PROXY_DOMAIN="UPDATE_ME" GITLAB_WORKSPACES_PROXY_WILDCARD_DOMAIN="UPDATE_ME" GITLAB_URL="UPDATE_ME" CLIENT_ID="UPDATE_ME" CLIENT_SECRET="UPDATE_ME" ./scripts/remote_development/workspaces_kubernetes_setup.sh
#
# Any subsequent invocation would fetch the value from the previous helm release and thus there is no need to export
# the environment variables listed above. Use the following command:
#
# ./scripts/remote_development/workspaces_kubernetes_setup.sh

# =====================================
# clean up
# =====================================
ROOT_DIR="${HOME}/.gitlab-workspaces"
rm -rf "${ROOT_DIR}"
mkdir -p "${ROOT_DIR}"

# =====================================
# set defaults
# =====================================
GITLAB_WORKSPACES_PROXY_CONFIG_SECRET="gitlab-workspaces-proxy-config"
GITLAB_WORKSPACES_PROXY_HELM_RELEASE_NAME="gitlab-workspaces-proxy"
GITLAB_WORKSPACES_PROXY_TLS_SECRET="gitlab-workspace-proxy-tls"
GITLAB_WORKSPACES_PROXY_WILDCARD_TLS_SECRET="gitlab-workspace-proxy-wildcard-tls"

# =====================================
# validate user inputs and set defaults
# =====================================
if [ -z "${INGRESS_NGINX_HELM_CHART_VERSION}" ]; then
  echo "INGRESS_NGINX_HELM_CHART_VERSION is not explicitly set. Using default."
  INGRESS_NGINX_HELM_CHART_VERSION="4.12.0"
fi

if [ -z "${GITLAB_WORKSPACES_PROXY_HELM_CHART_VERSION}" ]; then
  echo "GITLAB_WORKSPACES_PROXY_HELM_CHART_VERSION is not explicitly set. Using default."
  GITLAB_WORKSPACES_PROXY_HELM_CHART_VERSION="0.1.17"
fi

if [ -z "${GITLAB_WORKSPACES_PROXY_HELM_RELEASE_NAMESPACE}" ]; then
  echo "GITLAB_WORKSPACES_PROXY_HELM_RELEASE_NAMESPACE is not explicitly set. Using default."
  GITLAB_WORKSPACES_PROXY_HELM_RELEASE_NAMESPACE="gitlab-workspaces"
fi

if [ -z "${GITLAB_WORKSPACES_PROXY_DOMAIN}" ]; then
  echo "GITLAB_WORKSPACES_PROXY_DOMAIN is not explicitly set. Fetching the value from existing helm release."
  GITLAB_WORKSPACES_PROXY_DOMAIN=$(
    kubectl get ingress "${GITLAB_WORKSPACES_PROXY_HELM_RELEASE_NAME}" --namespace="${GITLAB_WORKSPACES_PROXY_HELM_RELEASE_NAMESPACE}" \
      --output go-template="{{ range .spec.tls }}{{ if eq .secretName \"${GITLAB_WORKSPACES_PROXY_TLS_SECRET}\" }}{{ index .hosts 0 }}{{ break }}{{ end }}{{ end }}"
  )
  if [ -z "${GITLAB_WORKSPACES_PROXY_DOMAIN}" ]; then
    echo "Unable to fetch the value from existing helm release. Using default."
    GITLAB_WORKSPACES_PROXY_DOMAIN="workspaces.localdev.me"
  fi
fi

if [ -z "${GITLAB_WORKSPACES_PROXY_WILDCARD_DOMAIN}" ]; then
  echo "GITLAB_WORKSPACES_PROXY_WILDCARD_DOMAIN is not explicitly set. Fetching the value from existing helm release."
  GITLAB_WORKSPACES_PROXY_WILDCARD_DOMAIN=$(
    kubectl get ingress "${GITLAB_WORKSPACES_PROXY_HELM_RELEASE_NAME}" --namespace="${GITLAB_WORKSPACES_PROXY_HELM_RELEASE_NAMESPACE}" \
      --output go-template="{{ range .spec.tls }}{{ if eq .secretName \"${GITLAB_WORKSPACES_PROXY_WILDCARD_TLS_SECRET}\" }}{{ index .hosts 0 }}{{ break }}{{ end }}{{ end }}"
  )
  if [ -z "${GITLAB_WORKSPACES_PROXY_WILDCARD_DOMAIN}" ]; then
    echo "Unable to fetch the value from existing helm release. Using default."
    GITLAB_WORKSPACES_PROXY_WILDCARD_DOMAIN="*.workspaces.localdev.me"
  fi
fi

if [ -z "${GITLAB_WORKSPACES_PROXY_REDIRECT_URI}" ]; then
  echo "GITLAB_WORKSPACES_PROXY_REDIRECT_URI is not explicitly set. Using default."
  GITLAB_WORKSPACES_PROXY_REDIRECT_URI="https://${GITLAB_WORKSPACES_PROXY_DOMAIN}/auth/callback"
fi

if [ -z "${GITLAB_WORKSPACES_PROXY_SIGNING_KEY}" ]; then
  echo "GITLAB_WORKSPACES_PROXY_SIGNING_KEY is not explicitly set. Using default."
  GITLAB_WORKSPACES_PROXY_SIGNING_KEY="a_random_key_consisting_of_letters_numbers_and_special_chars"
fi

if [ -z "${GITLAB_WORKSPACES_PROXY_SSH_HOST_KEY}" ]; then
  echo "GITLAB_WORKSPACES_PROXY_SSH_HOST_KEY is not explicitly set. Using default."
  GITLAB_WORKSPACES_PROXY_SSH_HOST_KEY_FILE="${ROOT_DIR}/gitlab-workspaces-proxy-ssh-host-key"
  ssh-keygen -f "${GITLAB_WORKSPACES_PROXY_SSH_HOST_KEY_FILE}" -N '' -t rsa
  GITLAB_WORKSPACES_PROXY_SSH_HOST_KEY=$(cat "${GITLAB_WORKSPACES_PROXY_SSH_HOST_KEY_FILE}")
fi

if [ -z "${GITLAB_WORKSPACES_PROXY_TLS_CERT_FILE}" ]; then
  echo "GITLAB_WORKSPACES_PROXY_TLS_CERT_FILE is not explicitly set. Using default."
  GITLAB_WORKSPACES_PROXY_TLS_CERT_FILE="${ROOT_DIR}/gitlab_workspaces_proxy_tls_cert"

  if [ "${GITLAB_WORKSPACES_PROXY_DOMAIN}" != "workspaces.localdev.me" ]; then
    echo "GITLAB_WORKSPACES_PROXY_DOMAIN is non-default. Trying to fetch the value from existing helm release"
    kubectl get secret "${GITLAB_WORKSPACES_PROXY_TLS_SECRET}" \
      --namespace="${GITLAB_WORKSPACES_PROXY_HELM_RELEASE_NAMESPACE}" \
      --output go-template='{{ index .data "tls.crt" | base64decode }}' \
      > "${GITLAB_WORKSPACES_PROXY_TLS_CERT_FILE}" \
      || echo "Unable to fetch the value from existing helm release"
  else
    GITLAB_WORKSPACES_PROXY_TLS_GENERATE=true
  fi
fi

if [ -z "${GITLAB_WORKSPACES_PROXY_TLS_KEY_FILE}" ]; then
  echo "GITLAB_WORKSPACES_PROXY_TLS_KEY_FILE is not explicitly set. Using default."
  GITLAB_WORKSPACES_PROXY_TLS_KEY_FILE="${ROOT_DIR}/gitlab_workspaces_proxy_tls_key"

  if [ "${GITLAB_WORKSPACES_PROXY_DOMAIN}" != "workspaces.localdev.me" ]; then
    echo "GITLAB_WORKSPACES_PROXY_DOMAIN is non-default. Trying to fetch the value from existing helm release"
    kubectl get secret "${GITLAB_WORKSPACES_PROXY_TLS_SECRET}" \
      --namespace="${GITLAB_WORKSPACES_PROXY_HELM_RELEASE_NAMESPACE}" \
      --output go-template='{{ index .data "tls.key" | base64decode }}' \
      > "${GITLAB_WORKSPACES_PROXY_TLS_KEY_FILE}" \
      || echo "Unable to fetch the value from existing helm release"
  else
    GITLAB_WORKSPACES_PROXY_TLS_GENERATE=true
  fi
fi

if [ "${GITLAB_WORKSPACES_PROXY_TLS_GENERATE}" == true ]; then
  mkcert -install
  mkcert \
    --cert-file="${GITLAB_WORKSPACES_PROXY_TLS_CERT_FILE}" \
    --key-file="${GITLAB_WORKSPACES_PROXY_TLS_KEY_FILE}" \
    "${GITLAB_WORKSPACES_PROXY_DOMAIN}"
fi

if [ ! -f "${GITLAB_WORKSPACES_PROXY_TLS_CERT_FILE}" ]; then
  echo "GITLAB_WORKSPACES_PROXY_TLS_CERT_FILE is not found."
  exit 1
fi

if [ ! -f "${GITLAB_WORKSPACES_PROXY_TLS_KEY_FILE}" ]; then
  echo "GITLAB_WORKSPACES_PROXY_TLS_KEY_FILE is not found."
  exit 1
fi

if [ -z "${GITLAB_WORKSPACES_PROXY_WILDCARD_TLS_CERT_FILE}" ]; then
  echo "GITLAB_WORKSPACES_PROXY_WILDCARD_TLS_CERT_FILE is not explicitly set. Using default."
  GITLAB_WORKSPACES_PROXY_WILDCARD_TLS_CERT_FILE="${ROOT_DIR}/gitlab_workspaces_proxy_wildcard_tls_cert"

  if [ "${GITLAB_WORKSPACES_PROXY_WILDCARD_DOMAIN}" != "*.workspaces.localdev.me" ]; then
    echo "GITLAB_WORKSPACES_PROXY_WILDCARD_DOMAIN is non-default. Trying to fetch the value from existing helm release"
    kubectl get secret "${GITLAB_WORKSPACES_PROXY_WILDCARD_TLS_SECRET}" \
    --namespace="${GITLAB_WORKSPACES_PROXY_HELM_RELEASE_NAMESPACE}" \
    --output go-template='{{ index .data "tls.crt" | base64decode }}' \
    > "${GITLAB_WORKSPACES_PROXY_WILDCARD_TLS_CERT_FILE}" \
    || echo "Unable to fetch the value from existing helm release"
  else
    GITLAB_WORKSPACES_PROXY_WILDCARD_TLS_GENERATE=true
  fi
fi

if [ -z "${GITLAB_WORKSPACES_PROXY_WILDCARD_TLS_KEY_FILE}" ]; then
  echo "GITLAB_WORKSPACES_PROXY_WILDCARD_TLS_KEY_FILE is not explicitly set. Using default."
  GITLAB_WORKSPACES_PROXY_WILDCARD_TLS_KEY_FILE="${ROOT_DIR}/gitlab_workspaces_proxy_wildcard_tls_key"

  if [ "${GITLAB_WORKSPACES_PROXY_WILDCARD_DOMAIN}" != "*.workspaces.localdev.me" ]; then
    echo "GITLAB_WORKSPACES_PROXY_WILDCARD_DOMAIN is non-default. Trying to fetch the value from existing helm release"
    kubectl get secret "${GITLAB_WORKSPACES_PROXY_WILDCARD_TLS_SECRET}" \
    --namespace="${GITLAB_WORKSPACES_PROXY_HELM_RELEASE_NAMESPACE}" \
    --output go-template='{{ index .data "tls.key" | base64decode }}' \
    > "${GITLAB_WORKSPACES_PROXY_WILDCARD_TLS_KEY_FILE}" \
    || echo "Unable to fetch the value from existing helm release"
  else
      GITLAB_WORKSPACES_PROXY_WILDCARD_TLS_GENERATE=true
  fi
fi

if [ "${GITLAB_WORKSPACES_PROXY_WILDCARD_TLS_GENERATE}" == true ]; then
  mkcert -install
  mkcert \
    --cert-file="${GITLAB_WORKSPACES_PROXY_WILDCARD_TLS_CERT_FILE}" \
    --key-file="${GITLAB_WORKSPACES_PROXY_WILDCARD_TLS_KEY_FILE}" \
    "${GITLAB_WORKSPACES_PROXY_WILDCARD_DOMAIN}"
fi

if [ ! -f "${GITLAB_WORKSPACES_PROXY_WILDCARD_TLS_CERT_FILE}" ]; then
  echo "GITLAB_WORKSPACES_PROXY_WILDCARD_TLS_CERT_FILE is not found."
  exit 1
fi

if [ ! -f "${GITLAB_WORKSPACES_PROXY_WILDCARD_TLS_KEY_FILE}" ]; then
  echo "GITLAB_WORKSPACES_PROXY_WILDCARD_TLS_KEY_FILE is not found."
  exit 1
fi

if [ -z "${GITLAB_URL}" ]; then
  echo "GITLAB_URL is not explicitly set. Trying to fetch the value from existing helm release"
  GITLAB_URL=$(
    kubectl get secret "${GITLAB_WORKSPACES_PROXY_CONFIG_SECRET}" --namespace="${GITLAB_WORKSPACES_PROXY_HELM_RELEASE_NAMESPACE}" \
      --output go-template='{{ index .data "auth.host" | base64decode }}'
  )
  if [ -z "${GITLAB_URL}" ]; then
    echo "Unable to fetch the value from existing helm release. Using default."
    GITLAB_URL="http://gdk.test:3000"
  fi
fi

if [ -z "${CLIENT_ID}" ]; then
  echo "CLIENT_ID is not explicitly set. Trying to fetch the value from existing helm release"
  CLIENT_ID=$(
    kubectl get secret "${GITLAB_WORKSPACES_PROXY_CONFIG_SECRET}" --namespace="${GITLAB_WORKSPACES_PROXY_HELM_RELEASE_NAMESPACE}" \
      --output go-template='{{ index .data "auth.client_id" | base64decode }}'
  )
  if [ -z "${CLIENT_ID}" ]; then
    echo "Unable to fetch the value from existing helm release"
    echo "CLIENT_ID is required to be set."
    exit 1
  fi
fi

if [ -z "${CLIENT_SECRET}" ]; then
  echo "CLIENT_SECRET is not explicitly set. Trying to fetch the value from existing helm release"
  CLIENT_SECRET=$(
    kubectl get secret "${GITLAB_WORKSPACES_PROXY_CONFIG_SECRET}" --namespace="${GITLAB_WORKSPACES_PROXY_HELM_RELEASE_NAMESPACE}" \
      --output go-template='{{ index .data "auth.client_secret" | base64decode }}'
  )
  if [ -z "${CLIENT_SECRET}" ]; then
    echo "Unable to fetch the value from existing helm release"
    echo "CLIENT_SECRET is required to be set."
    exit 1
  fi
fi

if [ "${GITLAB_WORKSPACES_PROXY_TLS_GENERATE}" == true ]; then
  mkcert -install
  mkcert \
    --cert-file="${GITLAB_WORKSPACES_PROXY_TLS_CERT_FILE}" \
    --key-file="${GITLAB_WORKSPACES_PROXY_TLS_KEY_FILE}" \
    "${GITLAB_WORKSPACES_PROXY_DOMAIN}"
fi

if [ "${GITLAB_WORKSPACES_PROXY_WILDCARD_TLS_GENERATE}" == true ]; then
  mkcert -install
  mkcert \
    --cert-file="${GITLAB_WORKSPACES_PROXY_WILDCARD_TLS_CERT_FILE}" \
    --key-file="${GITLAB_WORKSPACES_PROXY_WILDCARD_TLS_KEY_FILE}" \
    "${GITLAB_WORKSPACES_PROXY_WILDCARD_DOMAIN}"
fi

# =====================================
# install ingress-nginx
# =====================================
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx --force-update
helm repo update

helm --namespace ingress-nginx uninstall ingress-nginx --ignore-not-found --timeout=600s --wait

helm upgrade --install \
  ingress-nginx ingress-nginx/ingress-nginx \
  --namespace="ingress-nginx" \
  --create-namespace \
  --version="${INGRESS_NGINX_HELM_CHART_VERSION}" \
  --timeout=600s --wait --wait-for-jobs

kubectl wait pod \
  --all \
  --for=condition=Ready \
  --namespace=ingress-nginx \
  --timeout=300s

# shellcheck disable=SC2181 # Better readability by checking exit code indirectly.
if [ $? -eq 0 ]; then
  echo "Ingress Nginx helm chart upgrade successfully"
else
  echo "Ingress Nginx helm chart upgrade failed. Check pod logs for more details."
  exit 1
fi

# =====================================
# install gitlab-workspaces-proxy
# =====================================
# create the kubernetes namespace if it does not exists
if kubectl get namespace "${GITLAB_WORKSPACES_PROXY_HELM_RELEASE_NAMESPACE}";
then
  echo "Namespace '${GITLAB_WORKSPACES_PROXY_HELM_RELEASE_NAMESPACE}' already exists."
else
  echo "Namespace '${GITLAB_WORKSPACES_PROXY_HELM_RELEASE_NAMESPACE}' does not exists. Creating it."
  kubectl create namespace "${GITLAB_WORKSPACES_PROXY_HELM_RELEASE_NAMESPACE}"
fi

# create the kubernetes config secret
kubectl delete secret "${GITLAB_WORKSPACES_PROXY_CONFIG_SECRET}" --namespace="${GITLAB_WORKSPACES_PROXY_HELM_RELEASE_NAMESPACE}" || true
kubectl create secret generic "${GITLAB_WORKSPACES_PROXY_CONFIG_SECRET}" \
  --namespace="${GITLAB_WORKSPACES_PROXY_HELM_RELEASE_NAMESPACE}" \
  --from-literal="auth.client_id=${CLIENT_ID}" \
  --from-literal="auth.client_secret=${CLIENT_SECRET}" \
  --from-literal="auth.host=${GITLAB_URL}" \
  --from-literal="auth.redirect_uri=${GITLAB_WORKSPACES_PROXY_REDIRECT_URI}" \
  --from-literal="auth.signing_key=${GITLAB_WORKSPACES_PROXY_SIGNING_KEY}" \
  --from-literal="ssh.host_key=${GITLAB_WORKSPACES_PROXY_SSH_HOST_KEY}"

# create the kubernetes tls secret
kubectl delete secret "${GITLAB_WORKSPACES_PROXY_TLS_SECRET}" --namespace="${GITLAB_WORKSPACES_PROXY_HELM_RELEASE_NAMESPACE}" || true
kubectl create secret tls "${GITLAB_WORKSPACES_PROXY_TLS_SECRET}" \
  --namespace="${GITLAB_WORKSPACES_PROXY_HELM_RELEASE_NAMESPACE}" \
  --cert="${GITLAB_WORKSPACES_PROXY_TLS_CERT_FILE}" \
  --key="${GITLAB_WORKSPACES_PROXY_TLS_KEY_FILE}"

# create the kubernetes wildcard tls secret
kubectl delete secret "${GITLAB_WORKSPACES_PROXY_WILDCARD_TLS_SECRET}" --namespace="${GITLAB_WORKSPACES_PROXY_HELM_RELEASE_NAMESPACE}" || true
kubectl create secret tls "${GITLAB_WORKSPACES_PROXY_WILDCARD_TLS_SECRET}" \
  --namespace="${GITLAB_WORKSPACES_PROXY_HELM_RELEASE_NAMESPACE}" \
  --cert="${GITLAB_WORKSPACES_PROXY_WILDCARD_TLS_CERT_FILE}" \
  --key="${GITLAB_WORKSPACES_PROXY_WILDCARD_TLS_KEY_FILE}"

# install the helm chart
helm repo add gitlab-workspaces-proxy \
  https://gitlab.com/api/v4/projects/gitlab-org%2fworkspaces%2fgitlab-workspaces-proxy/packages/helm/devel \
  --force-update
helm repo update

helm --namespace "${GITLAB_WORKSPACES_PROXY_HELM_RELEASE_NAMESPACE}" uninstall "${GITLAB_WORKSPACES_PROXY_HELM_RELEASE_NAME}" --ignore-not-found --timeout=600s --wait

helm upgrade --install "${GITLAB_WORKSPACES_PROXY_HELM_RELEASE_NAME}" \
  gitlab-workspaces-proxy/gitlab-workspaces-proxy \
  --version="${GITLAB_WORKSPACES_PROXY_HELM_CHART_VERSION}" \
  --namespace="${GITLAB_WORKSPACES_PROXY_HELM_RELEASE_NAMESPACE}" \
  --set="ingress.enabled=true" \
  --set="ingress.hosts[0].host=${GITLAB_WORKSPACES_PROXY_DOMAIN}" \
  --set="ingress.hosts[0].paths[0].path=/" \
  --set="ingress.hosts[0].paths[0].pathType=ImplementationSpecific" \
  --set="ingress.hosts[1].host=${GITLAB_WORKSPACES_PROXY_WILDCARD_DOMAIN}" \
  --set="ingress.hosts[1].paths[0].path=/" \
  --set="ingress.hosts[1].paths[0].pathType=ImplementationSpecific" \
  --set="ingress.tls[0].hosts[0]=${GITLAB_WORKSPACES_PROXY_DOMAIN}" \
  --set="ingress.tls[0].secretName=${GITLAB_WORKSPACES_PROXY_TLS_SECRET}" \
  --set="ingress.tls[1].hosts[0]=${GITLAB_WORKSPACES_PROXY_WILDCARD_DOMAIN}" \
  --set="ingress.tls[1].secretName=${GITLAB_WORKSPACES_PROXY_WILDCARD_TLS_SECRET}" \
  --set="ingress.className=nginx" \
  --timeout=600s --wait --wait-for-jobs

kubectl wait pod \
  --all \
  --for=condition=Ready \
  --namespace=gitlab-workspaces \
  --timeout=300s

# shellcheck disable=SC2181 # Better readability by checking exit code indirectly.
if [ $? -eq 0 ]; then
  echo "GitLab Workspaces Proxy helm chart upgrade successfully"
else
  echo "GitLab Workspaces Proxy helm chart upgrade failed. Check pod logs for more details."
  exit 1
fi

# print the configuration secret to verify
echo "Printing the contents of the configuration secret to verify"
# shellcheck disable=SC2016 # The expression in the go template do not have to be expanded.
kubectl get secret "${GITLAB_WORKSPACES_PROXY_CONFIG_SECRET}" --namespace="${GITLAB_WORKSPACES_PROXY_HELM_RELEASE_NAMESPACE}" \
  --output go-template='{{range $k, $v := .data}}{{printf "%s: " $k}}{{printf "%s" $v | base64decode}}{{"\n"}}{{end}}'
