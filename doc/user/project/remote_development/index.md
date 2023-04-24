---
stage: Create
group: IDE
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Remote development **(FREE)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/95169) in GitLab 15.4 [with a flag](../../../administration/feature_flags.md) named `vscode_web_ide`. Disabled by default.
> - [Enabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/371084) in GitLab 15.7.
> - [Enabled on self-managed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/115741) in GitLab 15.11.

FLAG:
On self-managed GitLab, by default this feature is available. To hide the feature, ask an administrator to [disable the feature flag](../../../administration/feature_flags.md) named `vscode_web_ide`. On GitLab.com, this feature is available. The feature is not ready for production use.

WARNING:
This feature is an [Experiment](../../../policy/alpha-beta-support.md#experiment) and subject to change without notice.

DISCLAIMER:
This page contains information related to upcoming products, features, and functionality.
It is important to note that the information presented is for informational purposes only.
Please do not rely on this information for purchasing or planning purposes.
As with all projects, the items mentioned on this page are subject to change or delay.
The development, release, and timing of any products, features, or functionality remain at the
sole discretion of GitLab Inc.

## Web IDE as a frontend

You can use the [Web IDE](../web_ide/index.md) to make, commit, and push changes to a project directly from your web browser.
This way, you can update any project without having to install any dependencies or clone any repositories locally.

The Web IDE, however, lacks a native runtime environment where you could compile code, run tests, or generate real-time feedback.
With remote development, you can use:

- The Web IDE as a frontend
- A separate machine as a backend runtime environment

For a complete IDE experience, connect the Web IDE to a [development environment](#workspace) that's configured to run as a remote host.
For more information, see [connect a remote machine to the Web IDE](connect_machine.md).

## Workspace

A workspace is a virtual sandbox environment for your code that includes:

- A runtime environment
- Dependencies
- Configuration files

You can create a workspace from scratch or from a template that you can also customize.

When you configure and connect a workspace to the [Web IDE](../web_ide/index.md), you can:

- Edit files directly from the Web IDE and commit and push changes to GitLab.
- Use the Web IDE to run tests, debug code, and view real-time feedback.

## Manage a development environment

### Create a development environment

To create a development environment, run this command:

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

### Stop a development environment

To stop a running development environment, run this command:

```shell
docker container stop my-environment
```

### Start a development environment

To start a stopped development environment, run this command:

```shell
docker container start my-environment
```

The token changes every time you start the development environment.

### Remove a development environment

To remove a development environment:

1. [Stop the development environment](#stop-a-development-environment).
1. Run this command:

   ```shell
   docker container rm my-environment
   ```
