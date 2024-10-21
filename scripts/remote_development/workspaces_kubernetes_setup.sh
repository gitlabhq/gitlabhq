#!/usr/bin/env bash

# This script configures an existing local Kubernetes cluster for usage with Workspaces.
# This involves installing an Ingress Controller(Ingress Nginx) and installing GitLab Workspaces Proxy.
#
# It uses the following environment variables
# $CLIENT_ID - OAuth Client ID used in GitLab Workspaces Proxy.
# $CLIENT_SECRET - OAuth Client Secret used in GitLab Workspaces Proxy.
#
# If this is the first time this script in being run in the Kubernetes cluster, you need to export the environment
# variables listed above. Use the following command:
#
# CLIENT_ID="UPDATE_ME" CLIENT_SECRET="UPDATE_ME" ./scripts/remote_development/workspaces_kubernetes_setup.sh
#
# Any subsequent invocation would fetch the value from the previous helm release and thus there is no need to export
# the environment variables listed above. Use the following command:
#
# ./scripts/remote_development/workspaces_kubernetes_setup.sh

if [ -z "${CLIENT_ID}" ]; then
  echo "CLIENT_ID is not explicitly set. Trying to fetch the value from existing helm release"
  CLIENT_ID=$(
    kubectl get secret gitlab-workspaces-proxy-config --namespace="gitlab-workspaces" \
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
      kubectl get secret gitlab-workspaces-proxy-config --namespace="gitlab-workspaces" \
        --output go-template='{{ index .data "auth.client_secret" | base64decode }}'
    )
    if [ -z "${CLIENT_SECRET}" ]; then
      echo "Unable to fetch the value from existing helm release"
      echo "CLIENT_SECRET is required to be set."
      exit 1
    fi
fi

ROOT_DIR="${HOME}/.gitlab-workspaces-proxy"
mkdir -p "${ROOT_DIR}"

# install ingress-nginx
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx --force-update
helm repo update
helm --namespace ingress-nginx uninstall ingress-nginx --ignore-not-found --timeout=600s --wait

helm upgrade --install \
  ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --version 4.11.1 \
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

# install gitlab-workspaces-proxy
export GITLAB_WORKSPACES_PROXY_DOMAIN="workspaces.localdev.me"
export GITLAB_WORKSPACES_WILDCARD_DOMAIN="*.workspaces.localdev.me"
export REDIRECT_URI="https://${GITLAB_WORKSPACES_PROXY_DOMAIN}/auth/callback"
export SSH_HOST_KEY="${ROOT_DIR}/gitlab-workspaces-proxy-ssh-host-key"
export GITLAB_URL="http://gdk.test:3000"
export SIGNING_KEY="a_random_key_consisting_of_letters_numbers_and_special_chars"

# install self-signed certs
rm -f "${ROOT_DIR}/workspaces.localdev.me+1.pem" "${ROOT_DIR}/workspaces.localdev.me+1-key.pem"
mkcert -install
mkcert \
  --cert-file="${ROOT_DIR}/workspaces.localdev.me+1.pem" \
  --key-file="${ROOT_DIR}/workspaces.localdev.me+1-key.pem" \
  "${GITLAB_WORKSPACES_PROXY_DOMAIN}" "${GITLAB_WORKSPACES_WILDCARD_DOMAIN}"

# generate ssh host key
rm -f "${SSH_HOST_KEY}"
ssh-keygen -f "${ROOT_DIR}/gitlab-workspaces-proxy-ssh-host-key" -N '' -t rsa

# create kubernetes secrets required by the gitlab-workspaces-proxy helm chart
if kubectl get namespace gitlab-workspaces;
then
  echo "Namespace 'gitlab-workspaces' already exists."
else
  echo "Namespace 'gitlab-workspaces' does not exists. Creating it."
  kubectl create namespace gitlab-workspaces
fi

kubectl delete secret gitlab-workspaces-proxy-config --namespace="gitlab-workspaces" || true
kubectl create secret generic gitlab-workspaces-proxy-config \
  --namespace="gitlab-workspaces" \
  --from-literal="auth.client_id=${CLIENT_ID}" \
  --from-literal="auth.client_secret=${CLIENT_SECRET}" \
  --from-literal="auth.host=${GITLAB_URL}" \
  --from-literal="auth.redirect_uri=${REDIRECT_URI}" \
  --from-literal="auth.signing_key=${SIGNING_KEY}" \
  --from-literal="ssh.host_key=$(cat "${SSH_HOST_KEY}")"

kubectl delete secret gitlab-workspace-proxy-tls --namespace="gitlab-workspaces" || true
kubectl create secret tls gitlab-workspace-proxy-tls \
  --namespace="gitlab-workspaces" \
  --cert="${ROOT_DIR}/workspaces.localdev.me+1.pem" \
  --key="${ROOT_DIR}/workspaces.localdev.me+1-key.pem"

kubectl delete secret gitlab-workspace-proxy-wildcard-tls --namespace="gitlab-workspaces" || true
kubectl create secret tls gitlab-workspace-proxy-wildcard-tls \
  --namespace="gitlab-workspaces" \
  --cert="${ROOT_DIR}/workspaces.localdev.me+1.pem" \
  --key="${ROOT_DIR}/workspaces.localdev.me+1-key.pem"

# install gitlab-workspaces-proxy helm chart
helm repo add gitlab-workspaces-proxy \
  https://gitlab.com/api/v4/projects/gitlab-org%2fworkspaces%2fgitlab-workspaces-proxy/packages/helm/devel \
  --force-update
helm repo update

helm --namespace gitlab-workspaces uninstall gitlab-workspaces-proxy --ignore-not-found --timeout=600s --wait

helm upgrade --install gitlab-workspaces-proxy \
  gitlab-workspaces-proxy/gitlab-workspaces-proxy \
  --version=0.1.16 \
  --namespace="gitlab-workspaces" \
  --set="ingress.enabled=true" \
  --set="ingress.hosts[0].host=${GITLAB_WORKSPACES_PROXY_DOMAIN}" \
  --set="ingress.hosts[0].paths[0].path=/" \
  --set="ingress.hosts[0].paths[0].pathType=ImplementationSpecific" \
  --set="ingress.hosts[1].host=${GITLAB_WORKSPACES_WILDCARD_DOMAIN}" \
  --set="ingress.hosts[1].paths[0].path=/" \
  --set="ingress.hosts[1].paths[0].pathType=ImplementationSpecific" \
  --set="ingress.tls[0].hosts[0]=${GITLAB_WORKSPACES_PROXY_DOMAIN}" \
  --set="ingress.tls[0].secretName=gitlab-workspace-proxy-tls" \
  --set="ingress.tls[1].hosts[0]=${GITLAB_WORKSPACES_WILDCARD_DOMAIN}" \
  --set="ingress.tls[1].secretName=gitlab-workspace-proxy-wildcard-tls" \
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
kubectl get secret gitlab-workspaces-proxy-config --namespace="gitlab-workspaces" \
  --output go-template='{{range $k, $v := .data}}{{printf "%s: " $k}}{{printf "%s" $v | base64decode}}{{"\n"}}{{end}}'

# cleanup
rm -f "${SSH_HOST_KEY}" \
  "${ROOT_DIR}/workspaces.localdev.me+1.pem" \
  "${ROOT_DIR}/workspaces.localdev.me+1-key.pem"
