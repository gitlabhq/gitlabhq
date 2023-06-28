---
stage: Create
group: IDE
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Workspaces (Beta) **(PREMIUM)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/112397) in GitLab 15.11 [with a flag](../../administration/feature_flags.md) named `remote_development_feature_flag`. Disabled by default.
> - [Enabled on GitLab.com and self-managed](https://gitlab.com/gitlab-org/gitlab/-/issues/391543) in GitLab 16.0.

FLAG:
On self-managed GitLab, by default this feature is available. To hide the feature, ask an administrator to [disable the feature flag](../../administration/feature_flags.md) named `remote_development_feature_flag`. On GitLab.com, this feature is available. The feature is not ready for production use.

WARNING:
This feature is in [Beta](../../policy/experiment-beta-support.md#beta) and subject to change without notice. To leave feedback, see the [feedback issue](https://gitlab.com/gitlab-org/gitlab/-/issues/410031).

A workspace is a virtual sandbox environment for your code in GitLab. You can use workspaces to create and manage isolated development environments for your GitLab projects. These environments ensure that different projects don't interfere with each other.

Each workspace includes its own set of dependencies, libraries, and tools, which you can customize to meet the specific needs of each project. Workspaces use the AMD64 architecture.

For a demo of this feature, see [GitLab Workspaces Demo](https://tech-marketing.gitlab.io/static-demos/workspaces/ws_public.html).

## Set up a workspace

### Prerequisites

- Set up a Kubernetes cluster that the GitLab agent for Kubernetes supports. See the [supported Kubernetes versions](../clusters/agent/index.md#supported-kubernetes-versions-for-gitlab-features).
- Ensure autoscaling for the Kubernetes cluster is enabled.
- In the Kubernetes cluster, verify that a [default storage class](https://kubernetes.io/docs/concepts/storage/storage-classes/) is defined so that volumes can be dynamically provisioned for each workspace.
- In the Kubernetes cluster, install an Ingress controller of your choice (for example, `ingress-nginx`), and make that controller accessible over a domain. For example, point `*.workspaces.example.dev` and `workspaces.example.dev` to the load balancer exposed by the Ingress controller.
- In the Kubernetes cluster, [install `gitlab-workspaces-proxy`](https://gitlab.com/gitlab-org/remote-development/gitlab-workspaces-proxy#installation-instructions).
- In the Kubernetes cluster, [install the GitLab agent for Kubernetes](../clusters/agent/install/index.md).
- Configure remote development settings for the GitLab agent with this snippet, and update `dns_zone` as needed:

  ```yaml
  remote_development:
    enabled: true
    dns_zone: "workspaces.example.dev"
  ```

  You can use any agent defined under the root group of your project, provided that remote development is properly configured for that agent.
- You must have at least the Developer role in the root group.
- In each public project you want to use this feature for, create a [devfile](#devfile):
  1. On the left sidebar, at the top, select **Search GitLab** (**{search}**) to find your project
  1. In the root directory of your project, create a file named `.devfile.yaml`. You can use one of the [example configurations](#example-configurations).
- Ensure the container images used in the devfile support [arbitrary user IDs](#arbitrary-user-ids).

### Create a workspace

To create a workspace:

1. On the left sidebar, expand the top-most chevron (**{chevron-down}**).
1. Select **Your work**.
1. Select **Workspaces**.
1. Select **New workspace**.
1. From the **Select project** dropdown list, [select a project with a `.devfile.yaml` file](#prerequisites). You can only create workspaces for public projects.
1. From the **Select cluster agent** dropdown list, select a cluster agent owned by the group the project belongs to.
1. In **Time before automatic termination**, enter the number of hours until the workspace automatically terminates. This timeout is a safety measure to prevent a workspace from consuming excessive resources or running indefinitely.
1. Select **Create workspace**.

The workspace might take a few minutes to start. To access the workspace, under **Preview**, select the workspace link.
You also have access to the terminal and can install any necessary dependencies.

## Deleting data associated with a workspace

When you delete a project, agent, user, or token associated with a workspace:

- The workspace is deleted from both the user interface and the Kubernetes cluster.
- In the Kubernetes cluster, the running workspace resources become orphaned.

To clean up orphaned resources, a cluster administrator must manually delete the namespace.

For more information about our plans to change the current behavior, see [issue 414384](https://gitlab.com/gitlab-org/gitlab/-/issues/414384).

## Devfile

A devfile is a file that defines a development environment by specifying the necessary tools, languages, runtimes, and other components for a GitLab project.

Workspaces have built-in support for devfiles. You can specify a devfile for your project in the GitLab configuration file. The devfile is used to automatically configure the development environment with the defined specifications.

This way, you can create consistent and reproducible development environments regardless of the machine or platform you use.

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

### Example configurations

The following is an example devfile configuration:

```yaml
schemaVersion: 2.2.0
components:
  - name: tooling-container
    attributes:
      gl/inject-editor: true
    container:
      image: registry.gitlab.com/gitlab-org/remote-development/gitlab-remote-development-docs/debian-bullseye-ruby-3.2-node-18.12:rubygems-3.4-git-2.33-lfs-2.9-yarn-1.22-graphicsmagick-1.3.36-gitlab-workspaces
      env:
        - name: KEY
          value: VALUE
      endpoints:
      - name: http-3000
        targetPort: 3000
```

For more information, see the [devfile documentation](https://devfile.io/docs/2.2.0/devfile-schema).
For other examples, see the [`examples` projects](https://gitlab.com/gitlab-org/remote-development/examples).

This container image is for demonstration purposes only. To use your own container image, see [Arbitrary user IDs](#arbitrary-user-ids).

## Web IDE

Workspaces are bundled with the Web IDE by default. The Web IDE is the only code editor available for workspaces.

The Web IDE is powered by the [GitLab VS Code fork](https://gitlab.com/gitlab-org/gitlab-web-ide-vscode-fork). For more information, see [Web IDE](../project/web_ide/index.md).

## Private repositories

You cannot create a workspace for a private repository because GitLab does not inject any credentials into the workspace. You can only create a workspace for public repositories that have a devfile.

From a workspace, you can clone any repository manually.

## Pod interaction in a cluster

Workspaces run as pods in a Kubernetes cluster. GitLab does not impose any restrictions on the manner in which pods interact with each other.

Because of this requirement, you might want to isolate this feature from other containers in your cluster.

## Network access and workspace authorization

It's the client's responsibility to restrict network access to the Kubernetes control plane as GitLab does not have control over the API.

Only the workspace creator can access the workspace and any endpoints exposed in that workspace. The workspace creator is only authorized to access the workspace after user authentication with OAuth.

## Compute resources and volume storage

When you stop a workspace, the compute resources for that workspace are scaled down to zero. However, the volume provisioned for the workspace still exists.

To delete the provisioned volume, you must terminate the workspace.

## Disable remote development in the GitLab agent for Kubernetes

You can stop the `remote_development` module of the GitLab agent for Kubernetes from communicating with GitLab. To disable remote development in the GitLab agent configuration, set this property:

```yaml
remote_development:
  enabled: false
```

If you already have running workspaces, an administrator must manually delete these workspaces in Kubernetes.

## Arbitrary user IDs

You can provide your own container image, which can run as any Linux user ID. It's not possible for GitLab to predict the Linux user ID for a container image.
GitLab uses the Linux root group ID permission to create, update, or delete files in a container. The container runtime used by the Kubernetes cluster must ensure all containers have a default Linux group ID of `0`.

If you have a container image that does not support arbitrary user IDs, you cannot create, update, or delete files in a workspace. To create a container image that supports arbitrary user IDs, see the [OpenShift documentation](https://docs.openshift.com/container-platform/4.12/openshift_images/create-images.html#use-uid_create-images).

## Troubleshooting

When working with workspaces, you might encounter the following issues.

### `Failed to renew lease` when creating a workspace

You might not be able to create a workspace due to a known issue in the GitLab agent for Kubernetes. The following error message might appear in the agent's log:

```plaintext
{"level":"info","time":"2023-01-01T00:00:00.000Z","msg":"failed to renew lease gitlab-agent-remote-dev-dev/agent-123XX-lock: timed out waiting for the condition\n","agent_id":XXXX}
```

This issue occurs when an agent instance cannot renew its leadership lease, which results in the shutdown of leader-only modules including the `remote_development` module. The workaround is to restart the agent instance.
