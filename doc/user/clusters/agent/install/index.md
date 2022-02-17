---
stage: Configure
group: Configure
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Installing the agent for Kubernetes **(FREE)**

> - [Moved](https://gitlab.com/groups/gitlab-org/-/epics/6290) from GitLab Premium to GitLab Free in 14.5.
> - [Introduced](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/merge_requests/594) multi-arch images in GitLab 14.8. The first multi-arch release is `v14.8.1`. It supports AMD64 and ARM64 architectures.

To connect a Kubernetes cluster to GitLab, you must install an agent in your cluster.

## Prerequisites

Before you can install the agent in your cluster, you need:

- An existing Kubernetes cluster. If you don't have a cluster, you can create one on a cloud provider, like:
  - [Google Kubernetes Engine (GKE)](https://cloud.google.com/kubernetes-engine/docs/quickstart)
  - [Amazon Elastic Kubernetes Service (EKS)](https://docs.aws.amazon.com/eks/latest/userguide/getting-started.html)
  - [Digital Ocean](https://docs.digitalocean.com/products/kubernetes/quickstart/)
- On self-managed GitLab instances, a GitLab administrator must set up the [agent server](../../../../administration/clusters/kas.md).

## Installation steps

To install the agent in your cluster:

1. [Create an agent configuration file called `config.yaml`](#create-an-agent-configuration-file).
1. [Register the agent with GitLab](#register-the-agent-with-gitlab).
1. [Install the agent in your cluster](#install-the-agent-in-the-cluster).

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i> Watch a GitLab 14.2 [walk-through of this process](https://www.youtube.com/watch?v=XuBpKtsgGkE).

### Create an agent configuration file

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/259669) in GitLab 13.7, the agent configuration file can be added to multiple directories (or subdirectories) of the repository.
> - Group authorization was [introduced](https://gitlab.com/groups/gitlab-org/-/epics/5784) in GitLab 14.3.

In a GitLab project, in the repository, create a file called `config.yaml` at this path:

```plaintext
.gitlab/agents/<agent-name>/config.yaml
```

- Ensure the agent name follows the [naming convention](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/blob/master/doc/identity_and_auth.md#agent-identity-and-name).
- Ensure the filename has the `.yaml` file extension (`config.yaml`). The `.yml` extension is not accepted.
- Add content to the `config.yaml` file:
  - For a GitOps workflow, view [the configuration reference](../gitops.md#gitops-configuration-reference) for details.
  - For a GitLab CI/CD workflow, you can leave the file blank for now.

The agent bootstraps with the GitLab installation URL and an authentication token,
and you provide the rest of the configuration in your repository, following
Infrastructure as Code (IaaC) best practices.

### Register the agent with GitLab

> [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/5786) in GitLab 14.1, you can create a new agent record directly from the GitLab UI.

Now that you've created your agent configuration file, register it
with GitLab.
When you register the agent, GitLab generates a token that you need to
install the agent in your cluster.

Prerequisite when using a [GitLab CI/CD workflow](../ci_cd_tunnel.md):

- In the project that has the agent configuration file, ensure that [GitLab CI/CD is enabled](../../../../ci/enable_or_disable_ci.md#enable-cicd-in-a-project).

To register the agent with GitLab:

1. On the top bar, select **Menu > Projects** and find the project that has your agent configuration file.
1. From the left sidebar, select **Infrastructure > Kubernetes clusters**.
1. Select **Actions**.
1. From the **Select an agent** dropdown list, select the agent you want to register and select **Register an agent**.
1. GitLab generates a registration token for this agent. Securely store this secret token. You need it to install the agent in your cluster and to [update the agent](#update-the-agent-version) to another version.
1. Copy the command under **Recommended installation method**. You need it when you use the one-liner installation method to install the agent in your cluster.

### Install the agent in the cluster

To connect your cluster to GitLab, install the registered agent
in your cluster. To install it, you can use either:

- [The one-liner installation method](#one-liner-installation).
- [The advanced installation method](#advanced-installation).

You can use the one-liner installation for trying to use the agent for the first time, to do internal setups with
high trust, and to quickly get started. For long-term production usage, you may want to use the advanced installation
method to benefit from more configuration options.

#### One-liner installation

The one-liner installation is the simplest process, but you need
Docker installed locally. If you don't have it, you can either install
it or opt to the [advanced installation method](#advanced-installation).

To install the agent on your cluster using the one-liner installation:

1. In your computer, open a terminal and [connect to your cluster](https://kubernetes.io/docs/tasks/access-application-cluster/access-cluster/).
1. Run the command you copied when registering your cluster in the previous step.

Optionally, you can [customize the one-liner installation command](#customize-the-one-liner-installation).

##### Customize the one-liner installation

By default, the one-liner command generated by GitLab:

- Creates a namespace for the deployment (`gitlab-kubernetes-agent`).
- Sets up a service account with `cluster-admin` rights (see [how to restrict this service account](#customize-the-permissions-for-the-agentk-service-account)).
- Creates a `Secret` resource for the agent's registration token.
- Creates a `Deployment` resource for the `agentk` pod.

You can edit these parameters to customize the one-liner installation command.
To view all available options, open a terminal and run this command:

```shell
docker run --pull=always --rm registry.gitlab.com/gitlab-org/cluster-integration/gitlab-agent/cli:stable generate --help
```

WARNING:
Use `--agent-version stable` to refer to the latest stable
release at the time when the command runs. For production, however,
you should explicitly specify a matching version.

#### Advanced installation

For advanced installation options, use [the `kpt` installation method](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/tree/master/build/deployment/gitlab-agent).

##### Customize the permissions for the `agentk` service account

You own your cluster and can grant GitLab the permissions you want.
By default, however, the generated manifests provide `cluster-admin` rights to the agent.

You can restrict the agent's access rights by using Kustomize overlays. [An example is commented out](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/blob/master/build/deployment/gitlab-agent/cluster/kustomization.yaml) in the `kpt` package you retrieved as part of the installation.

To restrict permissions:

1. Copy the `cluster` directory.
1. Edit the `kustomization.yaml` and `components/*` files based on your requirements.
1. Run `kustomize build <your copied directory> | kubectl apply -f -` to apply your configuration.

#### Update the advanced installation base layer

Now you can update from the upstream package by using `kpt pkg update gitlab-agent --strategy resource-merge`.
When the advanced installation setup changes, you will not need to change your custom overlays.

## Install multiple agents in your cluster

For total separation between teams, you might need to run multiple `agentk` instances in your cluster.
You might want multiple agents so you can restrict RBAC for every `agentk` deployment.

To install multiple agents, follow the
[advanced installation steps](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/tree/master/build/deployment/gitlab-agent)
a second time and:

1. Change the agent name and create a new configuration file.
1. Register the new agent. You receive a new token. Each token should be used only with one agent.
1. Change the namespace or prefix you use for the installation.

You should also change the RBAC for the installed `agentk`.

## Example projects

The following example projects can help you get started with the agent.

- [Configuration repository with minimal manifests](https://gitlab.com/gitlab-examples/ops/gitops-demo/k8s-agents)
- [Distinct application and manifest repository example](https://gitlab.com/gitlab-examples/ops/gitops-demo/hello-world-service-gitops)
- [Auto DevOps setup that uses the CI/CD workflow](https://gitlab.com/gitlab-examples/ops/gitops-demo/hello-world-service)
- [Cluster management project template example that uses the CI/CD workflow](https://gitlab.com/gitlab-examples/ops/gitops-demo/cluster-management)

## Upgrades and version compatibility

The agent has two major components: `agentk` and `kas`.
GitLab provides `kas` installers built into the various GitLab installation methods.
The required `kas` version corresponds to the GitLab `major.minor` (X.Y) versions.

At the same time, `agentk` and `kas` can differ by 1 minor version in either direction. For example,
`agentk` 14.4 supports `kas` 14.3, 14.4, and 14.5 (regardless of the patch).

A feature introduced in a given GitLab minor version might work with other `agentk` or `kas` versions.
To ensure it works, use at least the same `agentk` and `kas` minor version. For example,
if your GitLab version is 14.2, use at least `agentk` 14.2 and `kas` 14.2.

We recommend upgrading your `kas` installations together with GitLab instances' upgrades, and to
[upgrade the `agentk` installations](#update-the-agent-version) after upgrading GitLab.

The available `agentk` and `kas` versions are available in
[the Container Registry](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/container_registry/).

### Update the agent version

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/340882) in GitLab 14.8, GitLab warns you on the agent's list page to update the agent version installed on your cluster.

To update the agent's version, re-run the [installation command](#install-the-agent-in-the-cluster)
with a newer `--agent-version`. Make sure to specify the other required parameters: `--kas-address`, `--namespace`, and `--agent-token`.
The available `agentk` versions are in [the Container Registry](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/container_registry/1223205?sort=desc).

If you don't have access to your agent's token, you can retrieve it from your cluster:

1. Open a terminal and connect to your cluster.
1. To retrieve the namespace, run:

    ```shell
    kubectl get namespaces
    ```

1. To retrieve the secret, run:

    ```shell
    kubectl -n <namespace> get secrets
    ```

1. To retrieve the token, run:

    ```shell
    kubectl -n <namespace> get secret <secret-name> --template={{.data.token}} | base64 --decode
    ```
