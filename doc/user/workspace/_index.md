---
stage: Create
group: Remote Development
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Workspaces are virtual sandbox environments for creating and managing your GitLab development environments.
title: Workspaces
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- Feature flag `remote_development_feature_flag` [enabled on GitLab.com and GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/issues/391543) in GitLab 16.0.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/136744) in GitLab 16.7. Feature flag `remote_development_feature_flag` removed.

{{< /history >}}

A workspace is a virtual sandbox environment for your code in GitLab.
You can use workspaces to create and manage isolated development environments for your GitLab projects.
These environments ensure that different projects don't interfere with each other.

Each workspace includes its own set of dependencies, libraries, and tools,
which you can customize to meet the specific needs of each project.

A workspace can exist for a maximum of approximately one calendar year, `8760` hours. After this, it is automatically terminated.

For a click-through demo, see [GitLab workspaces](https://tech-marketing.gitlab.io/static-demos/workspaces/ws_html.html).

{{< alert type="note" >}}

A workspace runs on any `linux/amd64` Kubernetes cluster that supports the GitLab agent for Kubernetes (`agentk`). If you need to run sudo commands, or
build and run containers in your workspace, there might be platform-specific requirements.

For more information, see [Platform compatibility](configuration.md#platform-compatibility).

{{< /alert >}}

## Workspaces and projects

Workspaces are scoped to a project.
When you create a workspace, you must:

- Assign the workspace to a specific project.
- Select a project with a [devfile](#devfile).

The workspace can interact with the GitLab API, with the access level defined by current user permissions.
A running workspace remains accessible to the user even if user permissions are later revoked.

### Manage workspaces from a project

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/125331) in GitLab 16.2.

{{< /history >}}

To manage workspaces from a project:

1. On the left sidebar, select **Search or go to** and find your project. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. In the upper right, select **Code**.
1. From the dropdown list, under **Your workspaces**, you can:
   - Restart, stop, or terminate an existing workspace.
   - Create a new workspace.

{{< alert type="warning" >}}

When you terminate a workspace, GitLab deletes any unsaved or uncommitted data
in that workspace. The data cannot be recovered.

{{< /alert >}}

### Deleting resources associated with a workspace

When you terminate a workspace, you delete all resources associated with the workspace.
When you delete a project, `agentk`, user, or token associated with a running workspace:

- The workspace is deleted from the user interface.
- In the Kubernetes cluster, the running workspace resources become orphaned and are not automatically deleted.

To clean up orphaned resources, an administrator must manually delete the workspace in Kubernetes.

[Issue 414384](https://gitlab.com/gitlab-org/gitlab/-/issues/414384) proposes to change this behavior.

## Manage workspaces at the agent level

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/419281) in GitLab 16.8.

{{< /history >}}

To manage all workspaces associated with `agentk`:

1. On the left sidebar, select **Search or go to** and find your project. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Operate** > **Kubernetes clusters**.
1. Select the agent configured for remote development.
1. Select the **Workspaces** tab.
1. From the list, you can restart, stop, or terminate an existing workspace.

{{< alert type="warning" >}}

When you terminate a workspace, GitLab deletes any unsaved or uncommitted data
in that workspace. The data cannot be recovered.

{{< /alert >}}

### Identify an agent from a running workspace

In deployments that contain multiple `agentk` installations, you might want to identify an agent from a running workspace.

To identify an agent associated with a running workspace, use one of the following GraphQL endpoints:

- `agent-id` to return the project the agent belongs to.
- `Query.workspaces` to return:
  - The cluster agent associated with the workspace.
  - The project the agent belongs to.

## Devfile

Workspaces have built-in support for devfiles. Devfiles are files that define a development environment
by specifying the necessary tools, languages, runtimes, and other components for a GitLab project.
Use them to automatically configure your development environment with your defined specifications.
They create consistent and reproducible development environments, regardless of the machine or platform you use.

Workspaces support both GitLab default devfile and custom devfiles.

### GitLab default devfile

{{< history >}}

- [Introduced with Go](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/171230) in GitLab 17.8.
- [Added support for Node, Ruby, and Rust](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/185393) in GitLab 17.9.
- [Added support for Python, PHP, Java, and GCC](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/188199) in GitLab 18.0.

{{< /history >}}

A GitLab default devfile is available for all projects when you create a workspace.
This devfile contains:

```yaml
schemaVersion: 2.2.0
components:
  - name: development-environment
    attributes:
      gl/inject-editor: true
    container:
      image: "registry.gitlab.com/gitlab-org/gitlab-build-images/workspaces/ubuntu-24.04:[VERSION_TAG]"
```

{{< alert type="note" >}}

This container `image` is updated regularly. `[VERSION_TAG]` is a placeholder only. For the latest version, see the
[default `default_devfile.yaml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/remote_development/settings/default_devfile.yaml).

{{< /alert >}}

The workspace default image includes development tools such as Ruby, Node.js, Rust, Go, Python,
Java, PHP, GCC, and their corresponding package managers. These tools are updated regularly.

A GitLab default devfile might not be suitable for all development environments configurations.
In these cases, you can create a [custom devfile](#custom-devfile).

### Custom devfile

If you need a specific development environment configuration, create a custom devfile.
You can define a devfile in the following locations, relative to your project's root directory:

```plaintext
- /.devfile.yaml
- /.devfile.yml
- /.devfile/{devfile_name}.yaml
- /.devfile/{devfile_name}.yml
```

{{< alert type="note" >}}

Devfiles must be placed directly in the `.devfile` folder. Nested subfolders are not supported.
For example, `.devfile/subfolder/devfile.yaml` is not recognized.

{{< /alert >}}

### Validation rules

- `schemaVersion` must be [`2.2.0`](https://devfile.io/docs/2.2.0/devfile-schema).
- The devfile must have at least one component.
- The devfile size must not exceed 3 MB.
- For `components`:
  - Names must not start with `gl-`.
  - Only `container` and `volume` are supported.
- For `commands`:
  - IDs must not start with `gl-`.
  - Only `exec` and `apply` command types are supported.
  - For `exec` commands, only the following options are supported: `commandLine`, `component`, `label`, and `hotReloadCapable`.
  - When `hotReloadCapable` is specified for `exec` commands, it must be set to `false`.
- For `events`:
  - Names must not start with `gl-`.
  - Only `preStart` and `postStart` are supported.
  - The Devfile standard only allows exec commands to be linked to `postStart` events. If you want an apply command, you must use a `preStart` event.
- `parent`, `projects`, and `starterProjects` are not supported.
- For `variables`, keys must not start with `gl-`, `gl_`, `GL-`, or `GL_`.
- For `attributes`:
  - `pod-overrides` must not be set at the root level or in `components`.
  - `container-overrides` must not be set in `components`.

### `container` component type

Use the `container` component type to define a container image as the execution environment for a workspace.
You can specify the base image, dependencies, and other settings.

The `container` component type supports the following schema properties only:

| Property             | Description |
|----------------------|-------------|
| `image` <sup>1</sup> | Name of the container image to use for the workspace. |
| `memoryRequest`      | Minimum amount of memory the container can use. |
| `memoryLimit`        | Maximum amount of memory the container can use. |
| `cpuRequest`         | Minimum amount of CPU the container can use. |
| `cpuLimit`           | Maximum amount of CPU the container can use. |
| `env`                | Environment variables to use in the container. Names must not start with `gl-`. |
| `endpoints`          | Port mappings to expose from the container. Names must not start with `gl-`. |
| `volumeMounts`       | Storage volume to mount in the container. |
| `command`            | The command to override the container entrypoint. See [`overrideCommand` attribute](#overridecommand-attribute). |
| `args`               | The arguments for the command of the container. See [`overrideCommand` attribute](#overridecommand-attribute). |

**Footnotes**:

1. When you create custom container images for the `image` property, you can use the
   [workspace base image](#workspace-base-image) as your foundation.
   It includes critical configurations for SSH access, user permissions, and workspace
   compatibility. If you choose not to use the base image, ensure your custom image meets
   all workspace requirements.

#### `overrideCommand` attribute

The `overrideCommand` attribute is a boolean that controls how Workspaces handle container entrypoints.
This attribute determines whether the container's original entrypoint is preserved or replaced
with a keep-alive command.

The default value for `overrideCommand` depends on the component type:

- Main component with attribute `gl/inject-editor: true`: Defaults to `true` when not specified.
- All other components: Defaults to `false` when not specified.

When `true`, the container entrypoint is replaced with `tail -f /dev/null` to keep the
container running.
When `false`, the container uses either the devfile component `command`/`args` or the built container
image's `Entrypoint`/`Cmd`.

The following table shows how `overrideCommand` affects container behavior. For clarity, these terms
are used in the table:

- Devfile component: The `command` and `args` properties in the devfile component entry.
- Container image: The `Entrypoint` and `Cmd` fields in the OCI container image.

| `overrideCommand` | Devfile component | Container image | Result |
|-------------------|-------------------|-----------------|--------|
| `true`            | Specified         | Specified       | Validation error: Devfile component `command`/`args` cannot be specified when `overrideCommand` is `true`. |
| `true`            | Specified         | Not specified   | Validation error: Devfile component `command`/`args` cannot be specified when `overrideCommand` is `true`. |
| `true`            | Not specified     | Specified       | Container entrypoint replaced with `tail -f /dev/null`. |
| `true`            | Not specified     | Not specified   | Container entrypoint replaced with `tail -f /dev/null`. |
| `false`           | Specified         | Specified       | Devfile component `command`/`args` used as entrypoint. |
| `false`           | Specified         | Not specified   | Devfile component `command`/`args` used as entrypoint. |
| `false`           | Not specified     | Specified       | Container image `Entrypoint`/`Cmd` used. |
| `false`           | Not specified     | Not specified   | Container exits prematurely (`CrashLoopBackOff`). <sup>1</sup> |

**Footnotes**:

1. When you create a workspace, it cannot access container image details, for example, from private
or internal registries. When `overrideCommand` is `false` and the Devfile doesn't specify `command`
or `args`, GitLab does not validate container images or check for required `Entrypoint` or `Cmd` fields.
You must ensure that either the Devfile or container specifies these fields, or the container exits
prematurely and the workspace fails to start.

### User-defined `postStart` events

You can define custom `postStart` events in your devfile to run commands after the workspace starts.
These `postStart` events do not block workspace accessibility. The workspace becomes available as
soon as internal initialization is complete, even if your custom `postStart` commands are still
running or waiting to run.

Use this type of event to:

- Set up development dependencies.
- Configure the workspace environment.
- Run initialization scripts.

`postStart` event names must not start with `gl-` and can only reference `exec` type commands.

For an example that shows how to configure `postStart` events,
see the [example configurations](#example-configurations).

#### Working directory for `postStart` commands

By default, `postStart` commands run in different working directories depending on the component:

- Main component with attribute `gl/inject-editor: true`: Commands run in the project directory (`/projects/<project-path>`).
- Other components: Commands run in the container's default working directory.

You can override the default behavior by specifying a `workingDir` in your command definition:

```yaml
commands:
  - id: install-dependencies
    exec:
      component: tooling-container
      commandLine: "npm install"
      workingDir: "/custom/path"
  - id: setup-project
    exec:
      component: tooling-container
      commandLine: "echo 'Setting up in project directory'"
      # Runs in project directory by default
```

#### Monitor `postStart` event progress

When your workspace runs `postStart` events, you can monitor their progress and check the workspace logs. To check the progress of your `postStart` scripts:

1. Open a terminal in your workspace.
1. Go to the workspace logs directory:

   ```shell
   cd /tmp/workspace-logs/
   ```

1. View the output logs to see command results:

   ```shell
   tail -f poststart-stdout.log
   ```

All `postStart` command output is captured in log files located in the [workspace logs directory](#workspace-logs-directory).

### Example configurations

The following is an example devfile configuration:

```yaml
schemaVersion: 2.2.0
variables:
  registry-root: registry.gitlab.com
components:
  - name: tooling-container
    attributes:
      gl/inject-editor: true
    container:
      image: "{{registry-root}}/gitlab-org/remote-development/gitlab-remote-development-docs/ubuntu:22.04"
      env:
        - name: KEY
          value: VALUE
      endpoints:
        - name: http-3000
          targetPort: 3000
  - name: database-container
    attributes:
      overrideCommand: false
    container:
      image: mysql
      command: ["echo"]
      args: ["-n", "user-defined entrypoint command"]
      env:
        - name: MYSQL_ROOT_PASSWORD
          value: "my-secret-pw"
commands:
  # Command 1: Container 1, no working directory (uses project directory)
  - id: install-dependencies
    exec:
      component: tooling-container
      commandLine: "npm install"

  # Command 2: Container 1, with working directory
  - id: setup-environment
    exec:
      component: tooling-container
      commandLine: "echo 'Setting up development environment'"
      workingDir: "/home/gitlab-workspaces"

  # Command 3: Container 2, no working directory (uses container default)
  - id: init-database
    exec:
      component: database-container
      commandLine: "echo 'Database initialized' > db-init.log"

  # Command 4: Container 2, with working directory
  - id: setup-database
    exec:
      component: database-container
      commandLine: "mkdir -p /var/lib/mysql/logs && echo 'DB setup complete' > setup.log"
      workingDir: "/var/lib/mysql"

events:
  postStart:
    - install-dependencies
    - setup-environment
    - init-database
    - setup-database
```

{{< alert type="note" >}}

This container `image` is for demonstration purposes only.

{{< /alert >}}

For other examples, see the [`examples` projects](https://gitlab.com/gitlab-org/remote-development/examples).

## Workspace container requirements

By default, workspaces inject and start the [GitLab VS Code fork](https://gitlab.com/gitlab-org/gitlab-web-ide-vscode-fork)
in the container that has a defined `gl/inject-editor` attribute in the devfile.
The workspace container where the GitLab VS Code fork is injected
must meet the following system requirements:

- System architecture: AMD64
- System libraries:
  - `glibc` 2.28 and later
  - `glibcxx` 3.4.25 and later

These requirements have been tested on Debian 10.13 and Ubuntu 20.04.

{{< alert type="note" >}}

GitLab always pulls the workspace tools injector image from the GitLab registry (`registry.gitlab.com`).
This image cannot be overridden.

If you use a private container registry for your other images, GitLab fetches these
specific images from the GitLab registry. This requirement may impact environments with strict network
controls, such as offline environments.

{{< /alert >}}

## Workspace base image

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab-build-images/-/merge_requests/983) in GitLab 18.3.

{{< /history >}}

GitLab provides a workspace base image
(`registry.gitlab.com/gitlab-org/gitlab-build-images:workspaces-base`)
that serves as the foundation for all workspace environments.

The base image includes:

- A stable Linux operating system foundation.
- Pre-configured user with appropriate permissions for workspace operations.
- Essential development tools and system libraries.
- Version management for programming languages and tools.
- SSH server configuration for remote access.
- Security configurations for arbitrary user ID support.

If you prefer not to use the workspace base image, you can create a custom workspace
image. To ensure GitLab can properly initialize and connect to your custom image, copy the
necessary configuration commands from the [base image Dockerfile](https://gitlab.com/gitlab-org/gitlab-build-images/-/blob/master/Dockerfile.workspaces-base)
into your own Dockerfile.

### Extend the base image

You can create custom workspace images based on the workspace base image. For example:

```dockerfile
FROM registry.gitlab.com/gitlab-org/gitlab-build-images:workspaces-base

# Install additional tools
RUN sudo apt-get update && sudo apt-get install -y \
    your-additional-package \
    && sudo rm -rf /var/lib/apt/lists/*

# Install specific language versions
RUN mise install python@3.11 && mise use python@3.11
```

## Workspace add-ons

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/385157) in GitLab 17.2.

{{< /history >}}

The GitLab Workflow extension for VS Code is configured by default in workspaces.

With this extension, you can view issues, create merge requests, and manage CI/CD pipelines.
This extension also powers AI features like GitLab Duo Code Suggestions and GitLab Duo Chat.

## Extension Marketplace

{{< details >}}

- Status: Beta

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/438491) as a [beta](../../policy/development_stages_support.md#beta) in GitLab 16.9 [with a flag](../../administration/feature_flags/_index.md) named `allow_extensions_marketplace_in_workspace`. Disabled by default.
- Feature flag `allow_extensions_marketplace_in_workspace` [removed](https://gitlab.com/gitlab-org/gitlab/-/issues/454669) in GitLab 17.6.

{{< /history >}}

The VS Code Extension Marketplace provides access to extensions that enhance the functionality of the
Web IDE. By default, the GitLab Web IDE connects to the [Open VSX Registry](https://open-vsx.org/).

For more information, see [configure VS Code Extension Marketplace](../../administration/settings/vscode_extension_marketplace.md).

## Personal access token

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/129715) in GitLab 16.4.
- `api` permission [added](https://gitlab.com/gitlab-org/gitlab/-/issues/385157) in GitLab 17.2.

{{< /history >}}

When you create a workspace, you get a personal access token
with `write_repository` and `api` permissions.
Use this token to clone the project initially, while starting the workspace,
and to configure the GitLab Workflow extension for VS Code.

Any Git operation you perform in the workspace uses this token for authentication and authorization.
Terminating the workspace revokes the token.

Use the `GIT_CONFIG_COUNT`, `GIT_CONFIG_KEY_n`, and `GIT_CONFIG_VALUE_n`
[environment variables](https://git-scm.com/docs/git-config/#Documentation/git-config.txt-GITCONFIGCOUNT)
for Git authentication in the workspace. These variables require Git 2.31 or later in the workspace container.

## Pod interaction in a cluster

Workspaces run as pods in a Kubernetes cluster.
GitLab does not impose any restrictions on the manner in which pods interact with each other.

Consider isolating this feature from other containers in your cluster, because of this requirement.

## Network access and workspace authorization

It's the client's responsibility to restrict network access to the Kubernetes control plane
because GitLab does not have control over the API.

Only the workspace creator can access the workspace and any endpoints exposed in that workspace.
The workspace creator is only authorized to access the workspace after user authentication with OAuth.

## Compute resources and volume storage

When you stop a workspace, GitLab scales the compute resources for that workspace down to zero.
However, the volume provisioned for the workspace still exists.

To delete the provisioned volume, you must terminate the workspace.

## Automatic workspace stop and termination

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/14910) in GitLab 17.6.

{{< /history >}}

By default, a workspace automatically:

- Stops 36 hours after the workspace was last started or restarted.
- Terminates 722 hours after the workspace was last stopped.

## Arbitrary user IDs

You can provide your own container image, which can run as any Linux user ID.

It's not possible for GitLab to predict the Linux user ID for a container image.
GitLab uses the Linux `root` group ID permission to create, update, or delete files in a container.
The container runtime used by the Kubernetes cluster must ensure all containers have a default Linux group ID of `0`.

If you have a container image that does not support arbitrary user IDs,
you cannot create, update, or delete files in a workspace.
To create a container image that supports arbitrary user IDs,
see [Create a custom workspace image that supports arbitrary user IDs](create_image.md).

## Workspace logs directory

When a workspace starts, GitLab creates a logs directory to capture output
from various initialization and startup processes.

The workspace logs are stored in `/tmp/workspace-logs/`.

This directory helps you monitor workspace startup progress and troubleshoot
issues with `postStart` events, development tools, and other workspace components.
For more information, see [Debug `postStart` events](workspaces_troubleshooting.md#debug-poststart-events).

### Available log files

The logs directory contains the following log files:

| Log file               | Purpose                    | Content |
|------------------------|----------------------------|---------|
| `poststart-stdout.log` | `postStart` command output | Standard output from all `postStart` commands, including user-defined commands and internal GitLab startup tasks. |
| `poststart-stderr.log` | `postStart` command errors | Error output and `stderr` from `postStart` commands. You can use these logs to troubleshoot failed startup scripts. |
| `start-vscode.log`     | VS Code server startup     | Logs from the GitLab VS Code fork server initialization. |
| `start-sshd.log`       | SSH daemon startup         | Output from SSH daemon initialization, including server startup and configuration details. |
| `clone-unshallow.log`  | Git repository conversion  | Logs from the background process that converts the shallow clone to a full clone and retrieves the complete Git history for the project. |

{{< alert type="note" >}}

Log files are recreated each time you restart a workspace. Previous log files are not preserved
when you stop and restart a workspace.

{{< /alert >}}

## Shallow cloning

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/543982) in GitLab 18.2 [with a flag](../../administration/feature_flags/_index.md) named `workspaces_shallow_clone_project`. Disabled by default.
- [Enabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/550330) in GitLab 18.3.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/558154) in GitLab 18.4. Feature flag `workspaces_shallow_clone_project` removed.

{{< /history >}}

When you create a workspace, GitLab uses shallow cloning to improve performance.
A shallow clone downloads only the latest commit history instead of the complete Git history,
which significantly reduces the initial clone time for large repositories.

After the workspace starts, Git converts the shallow clone to a full clone in the background.
This process is transparent and doesn't affect your development workflow.

## Related topics

- [Create a workspace](configuration.md#create-a-workspace)
- [Workspace settings](settings.md)
- [Troubleshooting Workspaces](workspaces_troubleshooting.md)
- [GitLab Duo Code Suggestions](../project/repository/code_suggestions/_index.md)
- [GitLab Duo Chat](../gitlab_duo_chat/_index.md)
- [GraphQL API reference](../../api/graphql/reference/_index.md)
- [Devfile documentation](https://devfile.io/docs/2.2.0/devfile-schema)
- [OpenShift documentation on arbitrary user IDs](https://docs.openshift.com/container-platform/4.12/openshift_images/create-images.html#use-uid_create-images)
