---
stage: Create
group: Remote Development
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "Create a GitLab workspaces proxy to authenticate and authorize workspaces in your cluster."
---

# Tutorial: Set up the GitLab workspaces proxy

In this tutorial, you'll learn how to set up the GitLab workspaces proxy
to authenticate and authorize [workspaces](index.md) in your cluster.

To set up `gitlab-workspaces-proxy`, you're going to:

1. [Generate TLS certificates](#generate-tls-certificates).
1. [Register an app on your GitLab instance](#register-an-app-on-your-gitlab-instance).
1. [Generate an SSH host key](#generate-an-ssh-host-key).
1. [Create Kubernetes secrets](#create-kubernetes-secrets).
1. [Install the Helm chart for the proxy](#install-the-helm-chart-for-the-proxy).
1. [Verify Kubernetes resources](#verify-kubernetes-resources).
1. [Update your DNS records](#update-your-dns-records).

## Prerequisites

- An installed Ingress controller
- A running Kubernetes cluster
- `helm` 3.11.0 and later and `kubectl` on your local machine

## Generate TLS certificates

You must generate TLS certificates for:

- The domain `gitlab-workspaces-proxy` listens on (`GITLAB_WORKSPACES_PROXY_DOMAIN`).
- The domain workspaces are available on (`GITLAB_WORKSPACES_WILDCARD_DOMAIN`).

You can generate certificates from any certificate authority.
If [`cert-manager`](https://cert-manager.io/docs/) is configured for your Kubernetes cluster,
you can use it to create and renew TLS certificates automatically.
Alternatively, to generate TLS certificates manually:

1. Install [Certbot](https://certbot.eff.org/) to enable HTTPS:

   ```shell
   brew install certbot
   ```

1. Generate Let's Encrypt certificates with ACME DNS and create `TXT` records in your DNS provider:

   ```shell
   export EMAIL="YOUR_EMAIL@example.dev"
   export GITLAB_WORKSPACES_PROXY_DOMAIN="workspaces.example.dev"
   export GITLAB_WORKSPACES_WILDCARD_DOMAIN="*.workspaces.example.dev"

   certbot -d "${GITLAB_WORKSPACES_PROXY_DOMAIN}" \
     -m "${EMAIL}" \
     --config-dir ~/.certbot/config \
     --logs-dir ~/.certbot/logs \
     --work-dir ~/.certbot/work \
     --manual \
     --preferred-challenges dns certonly

   certbot -d "${GITLAB_WORKSPACES_WILDCARD_DOMAIN}" \
     -m "${EMAIL}" \
     --config-dir ~/.certbot/config \
     --logs-dir ~/.certbot/logs \
     --work-dir ~/.certbot/work \
     --manual \
     --preferred-challenges dns certonly
   ```

1. Update the following environment variables with the certificate directories from the output:

   ```shell
   export WORKSPACES_DOMAIN_CERT="${HOME}/.certbot/config/live/${GITLAB_WORKSPACES_PROXY_DOMAIN}/fullchain.pem"
   export WORKSPACES_DOMAIN_KEY="${HOME}/.certbot/config/live/${GITLAB_WORKSPACES_PROXY_DOMAIN}/privkey.pem"
   export WILDCARD_DOMAIN_CERT="${HOME}/.certbot/config/live/${GITLAB_WORKSPACES_PROXY_DOMAIN}-0001/fullchain.pem"
   export WILDCARD_DOMAIN_KEY="${HOME}/.certbot/config/live/${GITLAB_WORKSPACES_PROXY_DOMAIN}-0001/privkey.pem"
   ```

   Depending on your environment, the `certbot` command might save the certificate and key on a different path.
   To get the exact path, check the output of the following command:

   ```shell
   certbot certificates \
     --config-dir ~/.certbot/config \
     --logs-dir ~/.certbot/logs \
     --work-dir ~/.certbot/work
   ```

NOTE:
You must renew your certificates when they expire.
For example, Let's Encrypt certificates are valid for three months by default.
To renew certificates automatically, see [`cert-manager`](https://cert-manager.io/docs/).

Now that you've generated the certificates, it's time to register an app on your GitLab instance.

## Register an app on your GitLab instance

To register an app on your GitLab instance:

1. [Configure GitLab as an OAuth 2.0 identity provider](../../integration/oauth_provider.md).
1. Set the redirect URI to `https://${GITLAB_WORKSPACES_PROXY_DOMAIN}/auth/callback`.
1. Select the **Trusted** checkbox.
1. Set the scopes to `api`, `read_user`, `openid`, and `profile`.
1. Export your `GITLAB_URL`, `CLIENT_ID`, `CLIENT_SECRET`, `REDIRECT_URI`, and `SIGNING_KEY`:

   ```shell
   export GITLAB_URL="https://gitlab.com"
   export CLIENT_ID="your_application_id"
   export CLIENT_SECRET="your_application_secret"
   export REDIRECT_URI="https://${GITLAB_WORKSPACES_PROXY_DOMAIN}/auth/callback"
   export SIGNING_KEY="make_up_a_random_key_consisting_of_letters_numbers_and_special_chars"
   ```

1. Store the client ID and generated secret in a safe place (for example, 1Password).

Next, you'll generate an SSH host key.

## Generate an SSH host key

To generate an RSA key, run this command:

```shell
ssh-keygen -f ssh-host-key -N '' -t rsa
export SSH_HOST_KEY=$(pwd)/ssh-host-key
```

You can also generate an ECDSA key instead.

Next, you'll create Kubernetes secrets for the proxy.

## Create Kubernetes secrets

To create Kubernetes secrets:

```shell
kubectl create namespace gitlab-workspaces

kubectl create secret generic gitlab-workspaces-proxy-config \
  --namespace="gitlab-workspaces" \
  --from-literal="auth.client_id=${CLIENT_ID}" \
  --from-literal="auth.client_secret=${CLIENT_SECRET}" \
  --from-literal="auth.host=${GITLAB_URL}" \
  --from-literal="auth.redirect_uri=${REDIRECT_URI}" \
  --from-literal="auth.signing_key=${SIGNING_KEY}" \
  --from-literal="ssh.host_key=$(cat ${SSH_HOST_KEY})"

kubectl create secret tls gitlab-workspace-proxy-tls \
  --namespace="gitlab-workspaces" \
  --cert="${WORKSPACES_DOMAIN_CERT}" \
  --key="${WORKSPACES_DOMAIN_KEY}"

kubectl create secret tls gitlab-workspace-proxy-wildcard-tls \
  --namespace="gitlab-workspaces" \
  --cert="${WILDCARD_DOMAIN_CERT}" \
  --key="${WILDCARD_DOMAIN_KEY}"
```

Now it's time to install the Helm chart for the proxy.

## Install the Helm chart for the proxy

To install the Helm chart for the proxy:

1. Add the `helm` repository:

   ```shell
   helm repo add gitlab-workspaces-proxy \
     https://gitlab.com/api/v4/projects/gitlab-org%2fworkspaces%2fgitlab-workspaces-proxy/packages/helm/devel
   ```

   For Helm chart 0.1.13 and earlier, use the following command:

   ```shell
   helm repo add gitlab-workspaces-proxy \
     https://gitlab.com/api/v4/projects/gitlab-org%2fremote-development%2fgitlab-workspaces-proxy/packages/helm/devel
   ```

1. Modify the `ingress.className` parameter if you're using a different Ingress class:

   ```shell
   helm repo update

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
     --set="ingress.className=nginx"
   ```

Let's now verify Kubernetes resources.

## Verify Kubernetes resources

1. Verify the following Kubernetes resources:

   - The configuration secret:

     ```shell
     kubectl -n gitlab-workspaces get secret gitlab-workspaces-proxy  -o=go-template='{{index .data "config.yaml"}}' | base64 -d
     ```

   - The Ingress class for the `gitlab-workspaces` namespace:

     ```shell
     kubectl -n gitlab-workspaces get ingress
     ```

     If you deploy the Helm chart for the proxy to any namespace other than `gitlab-workspaces`,
     update the namespace in the [GitLab agent configuration](gitlab_agent_configuration.md):

     ```yaml
     remote_development:
       gitlab_workspaces_proxy:
         namespace: "<custom-gitlab-workspaces-proxy-namespace>"
     ```

1. Verify the pods are running:

   ```shell
   kubectl -n gitlab-workspaces get pods
   ```

You can now start updating your DNS records.

## Update your DNS records

To update your DNS records:

1. Point `${GITLAB_WORKSPACES_PROXY_DOMAIN}` and `${GITLAB_WORKSPACES_WILDCARD_DOMAIN}`
   to the load balancer exposed by the Ingress controller.
1. From a terminal, run this command to check if `gitlab-workspaces-proxy` is accessible:

   ```shell
   curl --verbose --location ${GITLAB_WORKSPACES_PROXY_DOMAIN}
   ```

   This command returns a `400 Bad Request` error until you create a workspace in GitLab.

1. From another terminal, run this command:

   ```shell
   kubectl -n gitlab-workspaces logs -f -l app.kubernetes.io/name=gitlab-workspaces-proxy
   ```

   The logs show a `could not find upstream workspace upstream not found` error.

You're all set! You can now use the GitLab workspaces proxy to
authenticate and authorize [workspaces](index.md) in your cluster.
