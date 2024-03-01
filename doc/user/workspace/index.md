---
stage: Create
group: IDE
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Workspaces

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/112397) in GitLab 15.11 [with a flag](../../administration/feature_flags.md) named `remote_development_feature_flag`. Disabled by default.
> - [Enabled on GitLab.com and self-managed](https://gitlab.com/gitlab-org/gitlab/-/issues/391543) in GitLab 16.0.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/136744) in GitLab 16.7. Feature flag `remote_development_feature_flag` removed.

A workspace is a virtual sandbox environment for your code in GitLab.
You can use workspaces to create and manage isolated development environments for your GitLab projects.
These environments ensure that different projects don't interfere with each other.

Each workspace includes its own set of dependencies, libraries, and tools,
which you can customize to meet the specific needs of each project.

## Workspaces and projects

Workspaces are scoped to a project.
When you [create a workspace](configuration.md#set-up-a-workspace), you must:

- Assign the workspace to a specific project.
- Select a project with a [`.devfile.yaml`](#devfile) file.

The workspace can interact with the GitLab API, with the access level defined by current user permissions.
A running workspace remains accessible even if user permissions are later revoked.

### Manage workspaces from a project

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/125331) in GitLab 16.2.

To manage workspaces from a project:

1. On the left sidebar, select **Search or go to** and find your project.
1. In the upper right, select **Edit**.
1. From the dropdown list, under **Your workspaces**, you can:
   - Restart, stop, or terminate an existing workspace.
   - Create a new workspace.

WARNING:
When you terminate a workspace, any unsaved or uncommitted data
in that workspace is deleted and cannot be recovered.

### Deleting data associated with a workspace

When you delete a project, agent, user, or token associated with a workspace:

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
When you terminate a workspace, any unsaved or uncommitted data
in that workspace is deleted and cannot be recovered.

### Identify an agent from a running workspace

In deployments that contain multiple agents, you might want to identify an agent from a running workspace.

To identify an agent associated with a running workspace, use one of the following GraphQL endpoints:

- `agent-id` to return the project the agent belongs to.
- [`Query.workspaces`](../../api/graphql/reference/index.md#queryworkspaces) to return:
  - The [cluster agent](../../api/graphql/reference/index.md#clusteragent) associated with the workspace.
  - The project the agent belongs to.

## Devfile

A devfile is a file that defines a development environment by specifying the necessary
tools, languages, runtimes, and other components for a GitLab project.

Workspaces have built-in support for devfiles.
You can specify a devfile for your project in the GitLab configuration file.
The devfile is used to automatically configure the development environment with the defined specifications.

This way, you can create consistent and reproducible development environments
regardless of the machine or platform you use.

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

## GitLab VS Code fork

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

## Personal access token

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/129715) in GitLab 16.4.

When you [create a workspace](configuration.md#set-up-a-workspace), you get a personal access token with `write_repository` permission.
This token is used to initially clone the project while starting the workspace.

Any Git operation you perform in the workspace uses this token for authentication and authorization.
When you terminate the workspace, the token is revoked.

## Pod interaction in a cluster

Workspaces run as pods in a Kubernetes cluster.
GitLab does not impose any restrictions on the manner in which pods interact with each other.

Because of this requirement, you might want to isolate this feature from other containers in your cluster.

## Network access and workspace authorization

It's the client's responsibility to restrict network access to the Kubernetes control plane
because GitLab does not have control over the API.

Only the workspace creator can access the workspace and any endpoints exposed in that workspace.
The workspace creator is only authorized to access the workspace after user authentication with OAuth.

## Compute resources and volume storage

When you stop a workspace, the compute resources for that workspace are scaled down to zero.
However, the volume provisioned for the workspace still exists.

To delete the provisioned volume, you must terminate the workspace.

## Arbitrary user IDs

You can provide your own container image, which can run as any Linux user ID.

It's not possible for GitLab to predict the Linux user ID for a container image.
GitLab uses the Linux root group ID permission to create, update, or delete files in a container.
The container runtime used by the Kubernetes cluster must ensure all containers have a default Linux group ID of `0`.

If you have a container image that does not support arbitrary user IDs,
you cannot create, update, or delete files in a workspace.
To create a container image that supports arbitrary user IDs,
see [Create a custom workspace image that supports arbitrary user IDs](../workspace/create_image.md).

For more information, see the
[OpenShift documentation](https://docs.openshift.com/container-platform/4.12/openshift_images/create-images.html#use-uid_create-images).

## Related topics

- [GitLab workspaces demo](https://go.gitlab.com/qtu66q)
