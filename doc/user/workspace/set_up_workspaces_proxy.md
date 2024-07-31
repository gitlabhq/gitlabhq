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
1. [Export the GitLab URL](#export-the-gitlab-url).
1. [Create a configuration secret](#create-a-configuration-secret).
1. [Verify the Kubernetes resources](#verify-the-kubernetes-resources).
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

To generate TLS certificates:

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
    export WILDCARD_DOMAIN_CERT="${HOME}/.certbot/config/live/${GITLAB_WORKSPACES_WILDCARD_DOMAIN}/fullchain.pem"
    export WILDCARD_DOMAIN_KEY="${HOME}/.certbot/config/live/${GITLAB_WORKSPACES_WILDCARD_DOMAIN}/privkey.pem"
    ```

    The `certbot` command might create a different path for the wildcard domain
    by using the proxy domain and a `-0001` prefix:

    ```shell
    export WORKSPACES_DOMAIN_CERT="${HOME}/.certbot/config/live/${GITLAB_WORKSPACES_PROXY_DOMAIN}/fullchain.pem"
    export WORKSPACES_DOMAIN_KEY="${HOME}/.certbot/config/live/${GITLAB_WORKSPACES_PROXY_DOMAIN}/privkey.pem"
    export WILDCARD_DOMAIN_CERT="${HOME}/.certbot/config/live/${GITLAB_WORKSPACES_PROXY_DOMAIN}-0001/fullchain.pem"
    export WILDCARD_DOMAIN_KEY="${HOME}/.certbot/config/live/${GITLAB_WORKSPACES_PROXY_DOMAIN}-0001/privkey.pem"
    ```

Now that you've generated the certificates, it's time to register an app on your GitLab instance.

## Register an app on your GitLab instance

To register an app on your GitLab instance:

1. [Configure GitLab as an OAuth 2.0 identity provider](../../integration/oauth_provider.md).
1. Set the redirect URI to `https://${GITLAB_WORKSPACES_PROXY_DOMAIN}/auth/callback`.
1. Select the **Trusted** checkbox.
1. Set the scopes to `api`, `read_user`, `openid`, and `profile`.
1. Export your `CLIENT_ID`, `CLIENT_SECRET`, and `REDIRECT_URI`:

   ```shell
   export CLIENT_ID="your_application_id"
   export CLIENT_SECRET="your_application_secret"
   export REDIRECT_URI="https://${GITLAB_WORKSPACES_PROXY_DOMAIN}/auth/callback"
   ```

1. Store the client ID and generated secret in a safe place (for example, 1Password).

Next, you'll generate an SSH host key and export the GitLab URL.

## Generate an SSH host key

To generate an RSA key, run this command:

```shell
ssh-keygen -f ssh-host-key -N '' -t rsa
export SSH_HOST_KEY=$(pwd)/ssh-host-key
```

You can also generate an ECDSA key instead.

## Export the GitLab URL

To export the `GITLAB_URL` environment variable, run this command:

```shell
export GITLAB_URL="https://gitlab.com"
```

Next, you'll create a configuration secret for the proxy.

## Create a configuration secret

To create a configuration secret for the proxy:

1. Create a signing key and store the key in a safe place (for example, 1Password).
1. Export your `SIGNING_KEY`:

   ```shell
   export SIGNING_KEY="make_up_a_random_key_consisting_of_letters_numbers_and_special_chars"
   ```

1. Add the `helm` repository:

   ```shell
   helm repo add gitlab-workspaces-proxy \
     https://gitlab.com/api/v4/projects/gitlab-org%2fremote-development%2fgitlab-workspaces-proxy/packages/helm/devel
   ```

1. Modify the `ingress.className` parameter if you're using a different Ingress class:

   ```shell
   helm repo update

   helm upgrade --install gitlab-workspaces-proxy \
     gitlab-workspaces-proxy/gitlab-workspaces-proxy \
     --version 0.1.13 \
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
     --set="ingress.className=nginx"
   ```

   NOTE:
   You might have to renew your certificates.
   For example, Let's Encrypt certificates are valid for three months by default.
   When you get new certificates, run the previous `helm` command again to update the certificates.

Let's now verify the Kubernetes resources.

## Verify the Kubernetes resources

1. Verify the following Kubernetes resources:

   - The configuration secret:

     ```shell
     kubectl -n gitlab-workspaces get secret gitlab-workspaces-proxy  -o=go-template='{{index .data "config.yaml"}}' | base64 -d
     ```

   - The Ingress class for the `gitlab-workspaces` namespace:

     ```shell
     kubectl -n gitlab-workspaces get ingress
     ```

     If you deploy the GitLab Helm chart to any namespace other than `gitlab-workspaces`,
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
