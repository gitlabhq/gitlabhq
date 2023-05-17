---
stage: Create
group: IDE
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Tutorial: Connect a remote machine to the Web IDE **(FREE)**

This tutorial shows you how to:

- Create a development environment outside of GitLab.
- Connect a remote machine to the [Web IDE](../web_ide/index.md).

To connect a remote machine to the Web IDE, you must:

1. [Generate Let's Encrypt certificates](#generate-lets-encrypt-certificates).
1. [Connect a development environment to the Web IDE](#connect-a-development-environment-to-the-web-ide).

## Prerequisites

- A remote virtual machine with root access
- A domain address resolving to that machine
- Docker installation

## Generate Let's Encrypt certificates

To generate Let's Encrypt certificates:

1. Create an `A` record to point a domain to your remote machine (for example, from `example.remote.gitlab.dev` to `1.2.3.4`).
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

You've done it! Your development environment now runs as a remote host that's connected to the Web IDE.

## Related topics

- [Manage a development environment](index.md#manage-a-development-environment)
