#!/usr/bin/env bash

# This script configures an existing local Kubernetes cluster for usage with Workspaces.
# This involves installing an Ingress Controller(Ingress Nginx) and installing GitLab Workspaces Proxy.
#
# It uses the following environment variables
# $CLIENT_ID - OAuth Client ID used in GitLab Workspaces Proxy.
# #CLIENT_SECRET - OAuth Client Secret used in GitLab Workspaces Proxy.

if [ -z "${CLIENT_ID}" ]; then
	echo "\CLIENT_ID is not set"
	exit 1
fi

if [ -z "${CLIENT_SECRET}" ]; then
	echo "\CLIENT_SECRET is not set"
	exit 1
fi

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

# install gitlab-workspaces-proxy
export GITLAB_WORKSPACES_PROXY_DOMAIN="workspaces.localdev.me"
export GITLAB_WORKSPACES_WILDCARD_DOMAIN="*.workspaces.localdev.me"
export WORKSPACES_DOMAIN_CERT="${GDK_ROOT}/workspaces.localdev.me+1.pem"
export WORKSPACES_DOMAIN_KEY="${GDK_ROOT}/workspaces.localdev.me+1-key.pem"
export WILDCARD_DOMAIN_CERT="${GDK_ROOT}/workspaces.localdev.me+1.pem"
export WILDCARD_DOMAIN_KEY="${GDK_ROOT}/workspaces.localdev.me+1-key.pem"
export REDIRECT_URI="https://${GITLAB_WORKSPACES_PROXY_DOMAIN}/auth/callback"
export SSH_HOST_KEY="${GDK_ROOT}/gitlab-workspaces-proxy-ssh-host-key"
export GITLAB_URL="http://gdk.test:3000"
export SIGNING_KEY="a_random_key_consisting_of_letters_numbers_and_special_chars"

# install self-signed certs
mkcert -install
mkcert "${GITLAB_WORKSPACES_PROXY_DOMAIN}" "${GITLAB_WORKSPACES_WILDCARD_DOMAIN}"
rm $SSH_HOST_KEY || true
ssh-keygen -f gitlab-workspaces-proxy-ssh-host-key -N '' -t rsa

helm repo add gitlab-workspaces-proxy \
  https://gitlab.com/api/v4/projects/gitlab-org%2fworkspaces%2fgitlab-workspaces-proxy/packages/helm/devel \
  --force-update
helm repo update

helm --namespace gitlab-workspaces uninstall gitlab-workspaces-proxy --ignore-not-found --timeout=600s --wait

helm upgrade --install gitlab-workspaces-proxy \
  gitlab-workspaces-proxy/gitlab-workspaces-proxy \
  --version 0.1.14 \
  --namespace=gitlab-workspaces \
  --create-namespace \
  --set="auth.client_id=${CLIENT_ID}" \
  --set="auth.client_secret=${CLIENT_SECRET}" \
  --set="auth.host=${GITLAB_URL}" \
  --set="auth.redirect_uri=${REDIRECT_URI}" \
  --set="auth.signing_key=${SIGNING_KEY}" \
  --set="ingress.host.workspaceDomain=${GITLAB_WORKSPACES_PROXY_DOMAIN}" \
  --set="ingress.host.wildcardDomain=${GITLAB_WORKSPACES_WILDCARD_DOMAIN}" \
  --set="ingress.tls.workspaceDomainCert=$(cat ${WORKSPACES_DOMAIN_CERT})" \
  --set="ingress.tls.workspaceDomainKey=$(cat ${WORKSPACES_DOMAIN_KEY})" \
  --set="ingress.tls.wildcardDomainCert=$(cat ${WILDCARD_DOMAIN_CERT})" \
  --set="ingress.tls.wildcardDomainKey=$(cat ${WILDCARD_DOMAIN_KEY})" \
  --set="ssh.host_key=$(cat ${SSH_HOST_KEY})" \
  --set="ingress.className=nginx" \
  --timeout=600s --wait --wait-for-jobs

kubectl wait pod \
  --all \
  --for=condition=Ready \
  --namespace=gitlab-workspaces \
  --timeout=300s

# cleanup
rm "${SSH_HOST_KEY}" \
  "${WORKSPACES_DOMAIN_CERT}" \
  "${WORKSPACES_DOMAIN_KEY}" \
  "${WILDCARD_DOMAIN_CERT}" \
  "${WILDCARD_DOMAIN_KEY}" || true

kubectl -n gitlab-workspaces get secret gitlab-workspaces-proxy  -o=go-template='{{index .data "config.yaml"}}' | base64 -d
