---
stage: Create
group: Editor
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Remote Development **(FREE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/95169) in GitLab 15.6 [with a flag](../../../administration/feature_flags.md) named `vscode_web_ide`. Disabled by default.

FLAG:
On self-managed GitLab, by default this feature is not available. To make it available, ask an administrator to [enable the feature flag](../../../administration/feature_flags.md) named `vscode_web_ide`. On GitLab.com, this feature is available. The feature is not ready for production use.

WARNING:
This feature is in [Alpha](../../../policy/alpha-beta-support.md#alpha-features) and subject to change without notice.

DISCLAIMER:
This page contains information related to upcoming products, features, and functionality.
It is important to note that the information presented is for informational purposes only.
Please do not rely on this information for purchasing or planning purposes.
As with all projects, the items mentioned on this page are subject to change or delay.
The development, release, and timing of any products, features, or functionality remain at the
sole discretion of GitLab Inc.

You can use the [Web IDE](../web_ide/index.md) to commit changes to a project directly from your web browser without installing any dependencies or cloning any repositories. The Web IDE, however, lacks a native runtime environment on which you would compile code, run tests, or generate real-time feedback in the IDE. For a more complete IDE experience, you can pair the Web IDE with a Remote Development environment that has been properly configured to run as a host.

## Connect a remote machine to the Web IDE

Prerequisites:

- A remote virtual machine with root access
- A domain address resolving to that machine
- Docker installation

To connect a remote machine to the Web IDE, you must:

1. [Generate Let's Encrypt certificates](#generate-lets-encrypt-certificates).
1. [Connect a development environment to the Web IDE](#connect-a-development-environment-to-the-web-ide).

### Generate Let's Encrypt certificates

To generate Let's Encrypt certificates:

1. [Point a domain to your remote machine](#point-a-domain-to-your-remote-machine).
1. [Install Certbot](#install-certbot).
1. [Generate the certificates](#generate-the-certificates).

#### Point a domain to your remote machine

To point a domain to your remote machine, create an `A` record from `example.remote.gitlab.dev` to `1.2.3.4`.

#### Install Certbot

[Certbot](https://certbot.eff.org/) is a free and open-source software tool that automatically uses Let's Encrypt certificates on manually administered websites to enable HTTPS.

To install Certbot, run the following command:

```shell
sudo apt-get update
sudo apt-get install certbot
```

#### Generate the certificates

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

### Connect a development environment to the Web IDE

To connect a development environment to the Web IDE:

1. [Create a development environment](#manage-a-development-environment).
1. [Fetch a token](#fetch-a-token).
1. [Configure a remote connection](#configure-a-remote-connection).

#### Manage a development environment

**Create a development environment**

```shell
export CERTS_DIR="/home/ubuntu/.certbot/config/live/${DOMAIN}"
export PROJECTS_DIR="/home/ubuntu"

docker run -d \
  --name my-environment \
  -p 3443:3443 \
  -v "${CERTS_DIR}/fullchain.pem:/gitlab-rd-web-ide/certs/fullchain.pem" \
  -v "${CERTS_DIR}/privkey.pem:/gitlab-rd-web-ide/certs/privkey.pem" \
  -v "${PROJECTS_DIR}:/projects" \
  registry.gitlab.com/gitlab-com/create-stage/editor-poc/remote-development/gitlab-rd-web-ide-docker:0.1-alpha \
  --log-level warn --domain "${DOMAIN}" --ignore-version-mismatch
```

The new development environment starts automatically.

**Stop a development environment**

```shell
docker container stop my-environment
```

**Start a development environment**

```shell
docker container start my-environment
```

The token changes every time you restart the development environment.

**Remove a development environment**

To remove a development environment:

1. Stop the development environment.
1. Run the following command:

   ```shell
   docker container rm my-environment
   ```

#### Fetch a token

```shell
docker exec my-environment cat TOKEN
```

#### Configure a remote connection

To configure a remote connection from the Web IDE:

1. Open the Web IDE.
1. In the Menu Bar, select **View > Terminal** or press <kbd>Control</kbd>+<kbd>`</kbd>.
1. In the terminal panel, select **Configure a remote connection**.
1. Enter the URL for the remote host including the port (for example, `yourdomain.com:3443`).
1. Enter the project path.
1. Enter the [token you fetched](#fetch-a-token).

Alternatively, you can pass the parameters from a URL and connect directly to the Web IDE:

1. Run the following command:

   ```shell
   echo "https://gitlab-org.gitlab.io/gitlab-web-ide?remoteHost=${DOMAIN}:3443&hostPath=/projects"
   ```

1. Go to that URL and enter the [token you fetched](#fetch-a-token).
