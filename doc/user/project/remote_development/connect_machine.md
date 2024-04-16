---
stage: Create
group: IDE
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Tutorial: Connect a remote machine to the Web IDE

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/95169) in GitLab 15.4 [with a flag](../../../administration/feature_flags.md) named `vscode_web_ide`. Disabled by default.
> - [Enabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/371084) in GitLab 15.7.
> - [Enabled on self-managed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/115741) in GitLab 15.11.

FLAG:
On self-managed GitLab, by default this feature is available. To hide the feature, an administrator can [disable the feature flag](../../../administration/feature_flags.md) named `vscode_web_ide`. On GitLab.com and GitLab Dedicated, this feature is available. This feature is not ready for production use.

This tutorial shows you how to:

- Create a development environment outside of GitLab.
- Connect a remote machine to the [Web IDE](../web_ide/index.md).

To connect a remote machine to the Web IDE, you'll:

1. [Generate Let's Encrypt certificates](#generate-lets-encrypt-certificates).
1. [Connect a development environment to the Web IDE](#connect-a-development-environment-to-the-web-ide).

## Prerequisites

- A remote virtual machine with root access
- A domain address resolving to that machine
- Docker installation

## Generate Let's Encrypt certificates

To generate Let's Encrypt certificates:

1. Create an `A` record to point a domain to your remote machine (for example, from `example.remote.gitlab.dev` to `10.0.2.2`).

   NOTE:
   If you do not have access to a domain, you can use a service like [DuckDNS](https://www.duckdns.org/).

1. Install [Certbot](https://certbot.eff.org/) to enable HTTPS:

   ```shell
   sudo apt-get update
   sudo apt-get install certbot
   ```

1. Generate the certificates:

   ```shell
   export EMAIL="YOUR_EMAIL@example.com"
   export DOMAIN="example.remote.gitlab.dev"

   certbot -d "${DOMAIN}" \
     -m "${EMAIL}" \
     --config-dir ~/.certbot/config \
     --logs-dir ~/.certbot/logs \
     --work-dir ~/.certbot/work \
     --manual \
     --preferred-challenges dns certonly
   ```

   NOTE:
   With [DuckDNS](https://www.duckdns.org/), you must use the
   [Certbot DNS DuckDNS](https://github.com/infinityofspace/certbot_dns_duckdns) plugin.

Now that you've generated the certificates, it's time to create and connect a development environment.

## Connect a development environment to the Web IDE

To connect a development environment to the Web IDE:

1. Create a development environment:

   ```shell
   export CERTS_DIR="/home/ubuntu/.certbot/config/live/${DOMAIN}"
   export PROJECTS_DIR="/home/ubuntu"

   docker run -d \
     --name my-environment \
     -p 3443:3443 \
     -v "${CERTS_DIR}/fullchain.pem:/gitlab-rd-web-ide/certs/fullchain.pem" \
     -v "${CERTS_DIR}/privkey.pem:/gitlab-rd-web-ide/certs/privkey.pem" \
     -v "${PROJECTS_DIR}:/projects" \
     registry.gitlab.com/gitlab-org/remote-development/gitlab-rd-web-ide-docker:0.2-alpha \
     --log-level warn --domain "${DOMAIN}" --ignore-version-mismatch
   ```

   The new development environment starts automatically.

1. Fetch a token:

   ```shell
   docker exec my-environment cat TOKEN
   ```

1. [Configure a remote connection](#configure-a-remote-connection).

### Configure a remote connection

To configure a remote connection from the Web IDE:

1. Open the Web IDE.
1. On the menu bar, select **View > Terminal** or press <kbd>Control</kbd>+<kbd>`</kbd>.
1. In the terminal panel, select **Configure a remote connection**.
1. Enter the URL for the remote host including the port (for example, `yourdomain.com:3443`).
1. Enter the project path.
1. Enter the token you've fetched.

Alternatively, you can pass the parameters from a URL and connect directly to the Web IDE:

1. Run this command:

   ```shell
   echo "https://gitlab-org.gitlab.io/gitlab-web-ide?remoteHost=${DOMAIN}:3443&hostPath=/projects"
   ```

1. Go to that URL and enter the token you've fetched.

You've done it! Your development environment now runs as a remote host that's connected to the [Web IDE](../web_ide/index.md).

## Related topics

- [Manage a development environment](index.md#manage-a-development-environment)
