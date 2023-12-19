---
stage: Create
group: IDE
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Workspaces **(PREMIUM ALL)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/112397) in GitLab 15.11 [with a flag](../../administration/feature_flags.md) named `remote_development_feature_flag`. Disabled by default.
> - [Enabled on GitLab.com and self-managed](https://gitlab.com/gitlab-org/gitlab/-/issues/391543) in GitLab 16.0.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/136744) in GitLab 16.7. Feature flag `remote_development_feature_flag` removed.

A workspace is a virtual sandbox environment for your code in GitLab.
You can use workspaces to create and manage isolated development environments for your GitLab projects.
These environments ensure that different projects don't interfere with each other.

Each workspace includes its own set of dependencies, libraries, and tools,
which you can customize to meet the specific needs of each project.
Workspaces use the AMD64 architecture.

## Workspaces and projects

Workspaces are scoped to a project.
When you [create a workspace](configuration.md#set-up-a-workspace), you must:

- Assign the workspace to a specific project.
- Select a project with a [`.devfile.yaml`](#devfile) file.

The workspace can interact with the GitLab API, with the access level defined by current user permissions.
A running workspace remains accessible even if user permissions are later revoked.

### Open and manage workspaces from a project

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/125331) in GitLab 16.2.

To open a workspace from a file or the repository file list:

1. On the left sidebar, select **Search or go to** and find your project.
1. In the upper right, select **Edit**.
1. From the dropdown list, under **Your workspaces**, select the workspace.

From the dropdown list, you can also:

- Restart, stop, or terminate an existing workspace.
- Create a new workspace.

### Deleting data associated with a workspace

When you delete a project, agent, user, or token associated with a workspace:

- The workspace is deleted from the user interface.
- In the Kubernetes cluster, the running workspace resources become orphaned and are not automatically deleted.

To clean up orphaned resources, an administrator must manually delete the workspace in Kubernetes.

[Issue 414384](https://gitlab.com/gitlab-org/gitlab/-/issues/414384) proposes to change this behavior.

## Devfile

A devfile is a file that defines a development environment by specifying the necessary
tools, languages, runtimes, and other components for a GitLab project.

Workspaces have built-in support for devfiles.
You can specify a devfile for your project in the GitLab configuration file.
The devfile is used to automatically configure the development environment with the defined specifications.

This way, you can create consistent and reproducible development environments
regardless of the machine or platform you use.

### Relevant schema properties

GitLab only supports the `container` and `volume` components in [devfile 2.2.0](https://devfile.io/docs/2.2.0/devfile-schema).
Use the `container` component to define a container image as the execution environment for a devfile workspace.
You can specify the base image, dependencies, and other settings.

Only these properties are relevant to the GitLab implementation of the `container` component:

| Properties     | Definition                                                                        |
|----------------| ----------------------------------------------------------------------------------|
| `image`        | Name of the container image to use for the workspace.                             |
| `memoryRequest`| Minimum amount of memory the container can use.                                   |
| `memoryLimit`  | Maximum amount of memory the container can use.                                   |
| `cpuRequest`   | Minimum amount of CPU the container can use.                                      |
| `cpuLimit`     | Maximum amount of CPU the container can use.                                      |
| `env`          | Environment variables to use in the container.                                    |
| `endpoints`    | Port mappings to expose from the container.                                       |
| `volumeMounts` | Storage volume to mount in the container.                                         |

### Using variables in a devfile

You can define variables to use in your devfile.
The `variables` object is a map of name-value pairs that you can use for string replacement in the devfile.

Variables cannot have names that start with `gl-`, `gl_`, `GL-`, or `GL_`.
For more information about how and where to use variables, see the [devfile documentation](https://devfile.io/docs/2.2.0/defining-variables).

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
      image: "{{registry-root}}/gitlab-org/remote-development/gitlab-remote-development-docs/debian-bullseye-ruby-3.2-node-18.12:rubygems-3.4-git-2.33-lfs-2.9-yarn-1.22-graphicsmagick-1.3.36-gitlab-workspaces"
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

## Web IDE

Workspaces are bundled with the Web IDE by default.
The Web IDE is the only code editor available for workspaces.

The Web IDE is powered by the [GitLab VS Code fork](https://gitlab.com/gitlab-org/gitlab-web-ide-vscode-fork).
For more information, see [Web IDE](../project/web_ide/index.md).

## Personal access token

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/129715) in GitLab 16.4.

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
