---
stage: Create
group: Remote Development
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "Workspaces are virtual sandbox environments for creating and managing your GitLab development environments."
title: Workspaces
---

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/112397) in GitLab 15.11 [with a flag](../../administration/feature_flags.md) named `remote_development_feature_flag`. Disabled by default.
> - [Enabled on GitLab.com and GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/issues/391543) in GitLab 16.0.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/136744) in GitLab 16.7. Feature flag `remote_development_feature_flag` removed.

A workspace is a virtual sandbox environment for your code in GitLab.
You can use workspaces to create and manage isolated development environments for your GitLab projects.
These environments ensure that different projects don't interfere with each other.

Each workspace includes its own set of dependencies, libraries, and tools,
which you can customize to meet the specific needs of each project.

A Workspace can exist for a maximum of approximately one calendar year, `8760` hours. After this, it is automatically terminated.

For a click-through demo, see [GitLab workspaces](https://tech-marketing.gitlab.io/static-demos/workspaces/ws_html.html).

## Workspaces and projects

Workspaces are scoped to a project.
When you [create a workspace](configuration.md#create-a-workspace), you must:

- Assign the workspace to a specific project.
- Select a project with a [devfile](#devfile).

The workspace can interact with the GitLab API, with the access level defined by current user permissions.
A running workspace remains accessible to the user even if user permissions are later revoked.

### Manage workspaces from a project

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/125331) in GitLab 16.2.

To manage workspaces from a project:

1. On the left sidebar, select **Search or go to** and find your project.
1. In the upper right, select **Edit**.
1. From the dropdown list, under **Your workspaces**, you can:
   - Restart, stop, or terminate an existing workspace.
   - Create a new workspace.

WARNING:
When you terminate a workspace, GitLab deletes any unsaved or uncommitted data
in that workspace. The data cannot be recovered.

### Deleting resources associated with a workspace

When you terminate a workspace, you delete all resources associated with the workspace.
When you delete a project, agent, user, or token associated with a running workspace:

- The workspace is deleted from the user interface.
- In the Kubernetes cluster, the running workspace resources become orphaned and are not automatically deleted.

To clean up orphaned resources, an administrator must manually delete the workspace in Kubernetes.

[Issue 414384](https://gitlab.com/gitlab-org/gitlab/-/issues/414384) proposes to change this behavior.

## Manage workspaces at the agent level

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/419281) in GitLab 16.8.

To manage all workspaces associated with an agent:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Operate > Kubernetes clusters**.
1. Select the agent configured for remote development.
1. Select the **Workspaces** tab.
1. From the list, you can restart, stop, or terminate an existing workspace.

WARNING:
When you terminate a workspace, GitLab deletes any unsaved or uncommitted data
in that workspace. The data cannot be recovered.

### Identify an agent from a running workspace

In deployments that contain multiple agents, you might want to identify an agent from a running workspace.

To identify an agent associated with a running workspace, use one of the following GraphQL endpoints:

- `agent-id` to return the project the agent belongs to.
- [`Query.workspaces`](../../api/graphql/reference/_index.md#queryworkspaces) to return:
  - The [cluster agent](../../api/graphql/reference/_index.md#clusteragent) associated with the workspace.
  - The project the agent belongs to.

## Devfile

Workspaces have built-in support for devfiles. Devfiles are files that define a development environment
by specifying the necessary tools, languages, runtimes, and other components for a GitLab project.
Use them to automatically configure your development environment with your defined specifications.
They create consistent and reproducible development environments, regardless of the machine or platform you use.

Workspaces support both GitLab default devfile and custom devfiles.

### GitLab default devfile

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/171230) in GitLab 17.8.

A GitLab default devfile is available for all projects when you create a workspace.
This devfile contains:

```yaml
schemaVersion: 2.2.0
components:
  - name: development-environment
    attributes:
      gl/inject-editor: true
    container:
      image: "registry.gitlab.com/gitlab-org/gitlab-build-images/workspaces/ubuntu-24.04:20250109224147-golang-1.23@sha256:c3d5527641bc0c6f4fbbea4bb36fe225b8e9f1df69f682c927941327312bc676"
```

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

### Validation rules

- `schemaVersion` must be [`2.2.0`](https://devfile.io/docs/2.2.0/devfile-schema).
- The devfile must have at least one component.
- For `components`:
  - Names must not start with `gl-`.
  - Only [`container`](#container-component-type) and `volume` are supported.
- For `commands`, IDs must not start with `gl-`.
- For `events`:
  - Names must not start with `gl-`.
  - Only `preStart` is supported.
- `parent`, `projects`, and `starterProjects` are not supported.
- For `variables`, keys must not start with `gl-`, `gl_`, `GL-`, or `GL_`.
- For `attributes`:
  - `pod-overrides` must not be set at the root level or in `components`.
  - `container-overrides` must not be set in `components`.

### `container` component type

Use the `container` component type to define a container image as the execution environment for a workspace.
You can specify the base image, dependencies, and other settings.

The `container` component type supports the following schema properties only:

| Property       | Description                                                                                                                    |
|----------------| -------------------------------------------------------------------------------------------------------------------------------|
| `image`        | Name of the container image to use for the workspace.                                                                          |
| `memoryRequest`| Minimum amount of memory the container can use.                                                                                |
| `memoryLimit`  | Maximum amount of memory the container can use.                                                                                |
| `cpuRequest`   | Minimum amount of CPU the container can use.                                                                                   |
| `cpuLimit`     | Maximum amount of CPU the container can use.                                                                                   |
| `env`          | Environment variables to use in the container. Names must not start with `gl-`.                                                |
| `endpoints`    | Port mappings to expose from the container. Names must not start with `gl-`.                                                   |
| `volumeMounts` | Storage volume to mount in the container.                                                                                      |

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
```

For more information, see the [devfile documentation](https://devfile.io/docs/2.2.0/devfile-schema).
For other examples, see the [`examples` projects](https://gitlab.com/gitlab-org/remote-development/examples).

This container image is for demonstration purposes only.
To use your own container image, see [Arbitrary user IDs](#arbitrary-user-ids).

## Workspace container requirements

By default, workspaces inject and start the [GitLab VS Code fork](https://gitlab.com/gitlab-org/gitlab-web-ide-vscode-fork)
in the container that has a defined `gl/inject-editor` attribute in the devfile.
The workspace container where the GitLab VS Code fork is injected
must meet the following system requirements:

- **System architecture:** AMD64
- **System libraries:**
  - `glibc` 2.28 and later
  - `glibcxx` 3.4.25 and later

These requirements have been tested on Debian 10.13 and Ubuntu 20.04.
For more information, see the [VS Code documentation](https://code.visualstudio.com/docs/remote/linux).

## Workspace add-ons

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/385157) in GitLab 17.2.

The GitLab Workflow extension for VS Code is configured by default in workspaces.

With this extension, you can view issues, create merge requests, and manage CI/CD pipelines.
This extension also powers AI features like [GitLab Duo Code Suggestions](../project/repository/code_suggestions/_index.md)
and [GitLab Duo Chat](../gitlab_duo_chat/_index.md).

For more information, see [GitLab Workflow extension for VS Code](https://gitlab.com/gitlab-org/gitlab-vscode-extension).

## Extension marketplace

DETAILS:
**Status:** Beta

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/438491) as a [beta](../../policy/development_stages_support.md#beta) in GitLab 16.9 [with a flag](../../administration/feature_flags.md) named `allow_extensions_marketplace_in_workspace`. Disabled by default.
> - Feature flag `allow_extensions_marketplace_in_workspace` [removed](https://gitlab.com/gitlab-org/gitlab/-/issues/454669) in GitLab 17.6.

You can use the
[extension marketplace](../project/web_ide/_index.md#extension-marketplace) in workspaces
when it is [enabled](../profile/preferences.md#integrate-with-the-extension-marketplace).

The extension marketplace connects to the [Open VSX Registry](https://open-vsx.org/).

## Personal access token

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/129715) in GitLab 16.4.
> - `api` permission [added](https://gitlab.com/gitlab-org/gitlab/-/issues/385157) in GitLab 17.2.

When you [create a workspace](configuration.md#create-a-workspace), you get a personal access token
with `write_repository` and `api` permissions.
Use this token to clone the project initially, while starting the workspace,
and to configure the GitLab Workflow extension for VS Code.

Any Git operation you perform in the workspace uses this token for authentication and authorization.
Terminating the workspace revokes the token.

Use the `GIT_CONFIG_COUNT`, `GIT_CONFIG_KEY_n`, and `GIT_CONFIG_VALUE_n`
[environment variables](https://git-scm.com/docs/git-config/#Documentation/git-config.txt-GITCONFIGCOUNT)
for Git authentication in the workspace. Git added support for these variables in Git 2.31, so the Git version
you use in the workspace container must be 2.31 or later.

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

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/14910) in GitLab 17.6.

By default, a workspace automatically:

- Stops 36 hours after the workspace was last started or restarted.
  For more information, see [`max_active_hours_before_stop`](settings.md#max_active_hours_before_stop).
- Terminates 722 hours after the workspace was last stopped.
  For more information, see [`max_stopped_hours_before_termination`](settings.md#max_stopped_hours_before_termination).

## Arbitrary user IDs

You can provide your own container image, which can run as any Linux user ID.

It's not possible for GitLab to predict the Linux user ID for a container image.
GitLab uses the Linux `root` group ID permission to create, update, or delete files in a container.
The container runtime used by the Kubernetes cluster must ensure all containers have a default Linux group ID of `0`.

If you have a container image that does not support arbitrary user IDs,
you cannot create, update, or delete files in a workspace.
To create a container image that supports arbitrary user IDs,
see [Create a custom workspace image that supports arbitrary user IDs](../workspace/create_image.md).

For more information, see the
[OpenShift documentation](https://docs.openshift.com/container-platform/4.12/openshift_images/create-images.html#use-uid_create-images).

## Related topics

- [Troubleshooting Workspaces](workspaces_troubleshooting.md)
