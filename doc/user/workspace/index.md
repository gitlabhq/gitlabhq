---
stage: Create
group: IDE
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Workspaces (Beta) **(PREMIUM)**

> [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/10122) in GitLab 16.0 [with a flag](../../administration/feature_flags.md) named `remote_development_feature_flag`. Disabled by default.

FLAG:
On self-managed GitLab, by default this feature is not available. To make it available, ask an administrator to [enable the feature flag](../../administration/feature_flags.md) named `remote_development_feature_flag`. On GitLab.com, this feature is not available. The feature is not ready for production use.

WARNING:
This feature is in [Beta](../../policy/alpha-beta-support.md#beta) and subject to change without notice. To leave your feedback, see the [feedback issue](https://gitlab.com/gitlab-org/gitlab/-/issues/410031).

A workspace is a virtual sandbox environment for your code in GitLab. You can use workspaces to create and manage isolated development environments for your GitLab projects. These environments ensure that different projects don't interfere with each other.

You can create a workspace on its own or as part of a project. Each workspace includes its own set of dependencies, libraries, and tools, which you can customize to meet the specific needs of each project.

## Run a workspace

To run a workspace:

1. Set up a Kubernetes cluster that supports the GitLab agent for Kubernetes. See the [supported Kubernetes versions](../clusters/agent/index.md#gitlab-agent-for-kubernetes-supported-cluster-versions).
1. Ensure autoscaling for Kubernetes cluster is enabled.
1. In the Kubernetes cluster, verify that a [default storage class](https://kubernetes.io/docs/concepts/storage/storage-classes/) is defined so that volumes can be dynamically provisioned for each workspace.
1. [Install the GitLab agent for Kubernetes](../clusters/agent/install/index.md).
1. Configure remote development settings for the GitLab agent with the provided snippet.
1. Install an Ingress controller of your choice (for example, `ingress-nginx`), and make it accessible over a domain.
1. [Install `gitlab-workspaces-proxy`](https://gitlab.com/gitlab-org/remote-development/gitlab-workspaces-proxy#installation-instructions).
1. In each public project you want to use this feature for, define a [devfile](#devfile). Ensure the container images used in the devfile support [arbitrary user IDs](https://docs.openshift.com/container-platform/4.12/openshift_images/create-images.html#use-uid_create-images).

## Configure the GitLab agent for Kubernetes

To provision and communicate with the workspace, the GitLab agent for Kubernetes must be running on your cluster. To configure the GitLab agent for Kubernetes:

1. [Install GitLab Runner on the machine where you want to configure the agent](https://docs.gitlab.com/runner/install/).
1. Deploy the GitLab agent with the provided [YAML manifests](https://gitlab.com/gitlab-examples/ops/gitops-demo/k8s-agents/-/tree/main/manifests). The system does not impose any restrictions on the manner in which pods interact with each other. See [Pod interaction in a cluster](#pod-interaction-in-a-cluster).
1. Customize the GitLab agent configuration by editing the agent `ConfigMap`. `ConfigMap` is used to configure settings such as the GitLab URL and the registration token. For more information about the available configuration options, see [Connecting a Kubernetes cluster with GitLab](../clusters/agent/index.md).
1. Deploy the updated `ConfigMap` by running this command:

   ```plaintext
   kubectl apply -f <path-to-configmap.yaml>
   ```

1. Configure the agent to run on specific Kubernetes nodes by using labels:

   1. To assign labels to nodes, use the `kubectl label` command.
   1. To configure the agent to only run on nodes with a specific label, use the `nodeSelector` field in the GitLab agent deployment YAML.

You can remove an agent by using the GitLab UI or the GraphQL API. The agent and any associated tokens are removed from GitLab, but no changes are made in your Kubernetes cluster. You must clean up those resources manually. See [Remove an agent](../clusters/agent/work_with_agent.md#remove-an-agent).

## Devfile

A devfile is a file that defines a development environment by specifying the necessary tools, languages, runtimes, and other components for a GitLab project.

Workspaces have built-in support for devfiles. You can specify a devfile for your project in the GitLab configuration file. The devfile is used to automatically configure the development environment with the defined specifications.

This way, you can create consistent and reproducible development environments regardless of the machine or platform you use.

### Relevant schema properties

GitLab only supports the `container` component in [devfile 2.2.0](https://devfile.io/docs/2.2.0/devfile-schema).
Use this component to define a container image as the execution environment for a devfile workspace.
You can specify the base image, dependencies, and other settings.

Only these properties are relevant to the GitLab implementation of devfile:

| Properties     | Definition                                                                        |
|----------------| ----------------------------------------------------------------------------------|
| `image`        | Name of the container image to use for the workspace.                             |
| `memoryLimit`  | Maximum amount of memory the container can use.                                   |
| `cpuLimit`     | Maximum amount of CPU the container can use.                                      |
| `mountSources` | Whether to mount the source code directory from the workspace into the container. |
| `workingDir`   | Working directory to use in the container.                                        |
| `commands`     | Commands to run in the container.                                                 |
| `args`         | Arguments to pass to the commands.                                                |
| `ports`        | Port mappings to expose from the container.                                       |

### Example definition

The following is an example devfile:

```yaml
schemaVersion: 2.2.0
components:
  - name: tooling-container
    attributes:
      gl/inject-editor: true
    container:
      image: registry.gitlab.com/gitlab-org/remote-development/gitlab-remote-development-docs/debian-bullseye-ruby-3.2-node-18.12:rubygems-3.4-git-2.33-lfs-2.9-yarn-1.22-graphicsmagick-1.3.36-gitlab-workspaces
      endpoints:
      - name: http-3000
        targetPort: 3000
```

For other syntax examples, see the [`demos` projects](https://gitlab.com/gitlab-org/remote-development/demos).

## Create a workspace

Prerequisite:

- You must have [configured the GitLab agent for Kubernetes](#configure-the-gitlab-agent-for-kubernetes).

To create a workspace in GitLab:

1. On the top bar, select **Main menu > Projects** and find your project.
1. In the root directory of your project, create a file named `.devfile.yaml`.
1. On the left sidebar, select **Workspaces**.
1. In the upper right, select **New workspace**.
1. From the **Select project** dropdown list, select a project with a `.devfile.yaml` file. You can only create workspaces for public projects.
1. From the **Select cluster agent** dropdown list, select a cluster agent owned by the group the project belongs to.
1. In **Time before automatic termination**, enter the number of hours until the workspace automatically terminates. This timeout is a safety measure to prevent a workspace from consuming excessive resources or running indefinitely.
1. Select **Create workspace**.

The workspace might take a few minutes to start. When the workspace is ready, use the [Web IDE](../project/web_ide/index.md) to access your development environment.
You also have access to the terminal and can install any necessary dependencies.

## Web IDE

Workspaces are bundled with the Web IDE by default. The Web IDE is the only code editor available for workspaces.

The Web IDE is powered by the [GitLab VS Code fork](https://gitlab.com/gitlab-org/gitlab-web-ide-vscode-fork). For more information, see [Web IDE](../project/web_ide/index.md).

## Private repositories

You cannot create a workspace for a private repository because you cannot verify your identity. You can only clone or access public repositories.

You can clone a public repository over:

- **HTTPS**: You must provide a personal access token every time you access a public repository or create a workspace. This token acts as a password and grants access to a specific resource.
- **SSH**: You don't have to enter your password or personal access token when you access a public repository. However, you must provide your SSH key or personal access token every time you create a workspace.

## Pod interaction in a cluster

The system does not impose any restrictions on the manner in which pods interact with each other. It's the client's responsibility to restrict network access to the Kubernetes control plane as GitLab cannot determine the location of the API.

Because of this requirement, you might want to isolate this feature from other containers in your cluster.

## Networking and security

Workspaces are isolated environments that are only provisioned when you start a new instance. These environments are isolated from the host machine.

Workspaces use virtual network interfaces to connect to the internet and other resources, which helps prevent conflicts with the host machine's network settings.

### SSL, TLS, and HTTPS

Workspaces use SSL and TLS to provide secure and isolated development environments that you can access from anywhere.

Workspaces support HTTPS, which uses Transport Layer Security (TLS) to encrypt data sent between your machine and the workspace. Workspaces generate and manage their own SSL certificates for HTTPS connections. These SSL certificates are automatically renewed.

Workspaces also support Let's Encrypt SSL certificates, which you can use to enable HTTPS connections with a custom domain name.

### Workspace authorization

To use workspaces, you must have a GitLab account with the necessary permissions to create or access a repository. GitLab authentication is used to control access to workspaces. Only users who have been granted access to a repository can create or access workspaces associated with that repository.

GitLab also provides administrators with the ability to:

- Limit who can create workspaces.
- Set resource limits for workspaces.
- Configure the default environment for workspaces.

## Workspace lifecycle

The lifecycle of a workspace is divided into the following stages:

- **Creation**: A workspace is created when you open a new workspace session from a GitLab repository. GitLab creates a virtual machine instance in the cloud with the necessary software and tools for your specific project.
- **Initialization**: The instance is initialized with the project files and dependencies when you clone the repository or pull from a container registry.
- **Usage**: The workspace is ready to use. You can use the IDE and command-line tools that come with the workspace or install any other tools.
- **Persistence**: Any changes made to the project files and dependencies in the workspace persist to the GitLab repository in real-time. This way, these changes can be synced and shared with other collaborators.
- **Deletion**: When you're finished with the workspace session, you can suspend or delete the workspace. Suspending the workspace pauses billing but keeps the instance running. Deleting the workspace removes the instance and all associated data permanently.

## Container best practices

### Set a user to run a container in Kubernetes

GitLab cannot predict which user is the best fit to run a container in Kubernetes. You must set the user yourself to ensure the container runs correctly.

To set a user to run a container in Kubernetes, follow these best practices:

- When you create a [devfile](#devfile) for the container, ensure the container images used in the devfile support [arbitrary user IDs](https://docs.openshift.com/container-platform/4.12/openshift_images/create-images.html#use-uid_create-images).
- For each container in your project, you must explicitly set the Linux user ID to a random value. The default value for GitLab is `5001`.
- You must set the fields to prevent any privilege escalation for the Linux user.

CRI-O, the container runtime interface used by OpenShift, has a default group ID of `0` for all containers. If the container images support arbitrary user IDs, all files become editable as a Linux root group member. To solve this issue, GitLab sets arbitrary user IDs for all containers.

### Architectural support

Workspaces use the AMD64 architecture because modern software is generally compatible with this architecture. If you're using other architectures (such as ARM), you can cross-compile your code to run on AMD64 systems.

### Namespace deletion

To delete a namespace, Kubernetes administrators must manually delete the namespace. If you're running a workspace on your own environment, it's your responsibility to manage and delete namespaces.
