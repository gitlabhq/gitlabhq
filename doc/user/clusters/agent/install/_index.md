---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Installing the agent for Kubernetes
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

To connect a Kubernetes cluster to GitLab, you must install an agent in your cluster.

## Prerequisites

Before you can install the agent in your cluster, you need:

- An existing [Kubernetes cluster that you can connect to from your local terminal](https://kubernetes.io/docs/tasks/access-application-cluster/access-cluster/). If you don't have a cluster, you can create one on a cloud provider, like:
  - [Amazon Elastic Kubernetes Service (EKS)](https://docs.aws.amazon.com/eks/latest/userguide/getting-started.html)
  - [Azure Kubernetes Service (AKS)](https://learn.microsoft.com/en-us/azure/aks/what-is-aks)
  - [Digital Ocean](https://docs.digitalocean.com/products/kubernetes/getting-started/quickstart/)
  - [Google Kubernetes Engine (GKE)](https://cloud.google.com/kubernetes-engine/docs/deploy-app-cluster)
  - You should use [Infrastructure as Code techniques](../../../infrastructure/iac/_index.md) for managing infrastructure resources at scale.
- On GitLab Self-Managed, a GitLab administrator must set up the
  [agent server](../../../../administration/clusters/kas.md).
  Then it is available by default at `wss://gitlab.example.com/-/kubernetes-agent/`.
  On GitLab.com, the agent server is available at `wss://kas.gitlab.com`.

## Bootstrap the agent with Flux support (recommended)

You can install the agent by bootstrapping it with the [GitLab CLI (`glab`)](../../../../editor_extensions/gitlab_cli/_index.md) and Flux.

Prerequisites:

- You have the following command-line tools installed:
  - `glab`
  - `kubectl`
  - `flux`
- You have a local cluster connection that works with `kubectl` and `flux`.
- You [bootstrapped Flux](https://fluxcd.io/flux/installation/bootstrap/gitlab/) into the cluster with `flux bootstrap`.
  - Make sure to bootstrap Flux and the agent in compatible directories. If you bootstrapped Flux
    with the `--path` option, you must pass the same value to the `--manifest-path` option of the
    `glab cluster agent bootstrap` command.

To install the agent:

- Run `glab cluster agent bootstrap`:

  ```shell
  glab cluster agent bootstrap <agent-name> --manifest-path <same as --path used in flux bootstrap>
  ```

By default, the command:

1. Registers the agent.
1. Configures the agent.
1. Configures an environment with a dashboard for the agent.
1. Creates an agent token.
1. In the cluster, creates a Kubernetes secret with the agent token.
1. Commits the Flux Helm resources to the Git repository.
1. Triggers a Flux reconciliation.

For customization options, run `glab cluster agent bootstrap --help`. You probably want to use at least the `--path <flux_manifests_directory>` option.

## Install the agent manually

It takes three steps to install the agent in your cluster:

1. Optional. [Create an agent configuration file](#create-an-agent-configuration-file).
1. [Register the agent with GitLab](#register-the-agent-with-gitlab).
1. [Install the agent in your cluster](#install-the-agent-in-the-cluster).

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i> Watch a [walk-through of this process](https://www.youtube.com/watch?v=XuBpKtsgGkE).
<!-- Video published on 2021-09-02 -->

### Create an agent configuration file

For configuration settings, the agent uses a YAML file in the GitLab project. Adding an agent configuration file is optional. You must create this file if:

- You use [a GitLab CI/CD workflow](../ci_cd_workflow.md#use-gitlab-cicd-with-your-cluster) and want to authorize a different project or group to access the agent.
- You [allow specific project or group members to access Kubernetes](../user_access.md).

To create an agent configuration file:

1. Choose a name for your agent. The agent name follows the
   [DNS label standard from RFC 1123](https://www.rfc-editor.org/rfc/rfc1123). The name must:

   - Be unique in the project.
   - Contain at most 63 characters.
   - Contain only lowercase alphanumeric characters or `-`.
   - Start with an alphanumeric character.
   - End with an alphanumeric character.

1. In the repository, in the default branch, create an agent configuration file at:

   ```plaintext
   .gitlab/agents/<agent-name>/config.yaml
   ```

You can leave the file blank for now, and [configure it](../work_with_agent.md#configure-your-agent) later.

### Register the agent with GitLab

#### Option 1: Agent connects to GitLab

You can create a new agent record directly from the GitLab UI.
The agent can be registered without creating an agent configuration file.

You must register an agent before you can install the agent in your cluster. To register an agent:

1. On the left sidebar, select **Search or go to** and find your project.
   If you have an [agent configuration file](#create-an-agent-configuration-file),
   it must be in this project. Your cluster manifest files should also be in this project.
1. Select **Operate > Kubernetes clusters**.
1. Select **Connect a cluster (agent)**.
1. In the **Name of new agent** field, enter a unique name for your agent.
   - If an [agent configuration file](#create-an-agent-configuration-file) with this name already exists, it is used.
   - If no configuration exists for this name, a new agent is created with the default configuration.
1. Select **Create and register**.
1. GitLab generates an access token for the agent. You need this token to install the agent
   in your cluster.

   WARNING:
   Securely store the agent access token. A bad actor can use this token to access source code in the agent's configuration project, access source code in any public project on the GitLab instance, or even, under very specific conditions, obtain a Kubernetes manifest.

1. Copy the command under **Recommended installation method**. You need it when you use
   the one-liner installation method to install the agent in your cluster.

#### Option 2: GitLab connects to agent (receptive agent)

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab Self-Managed

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/12180) in GitLab 17.4.

NOTE:
The GitLab Agent Helm Chart release does not fully support mTLS authentication.
You should authenticate with the JWT method instead.
Support for mTLS is tracked in
[issue 64](https://gitlab.com/gitlab-org/charts/gitlab-agent/-/issues/64).

[Receptive agents](../_index.md#receptive-agents) allow GitLab to integrate with Kubernetes clusters that
cannot establish a network connection to the GitLab instance, but can be connected to by GitLab.

1. Follow the steps in option 1 to register an agent in your cluster.
   Save the agent token and install command for later, but don't install the agent yet.
1. Prepare an authentication method.

   The GitLab-to-agent connection can be cleartext gRPC (`grpc://`) or encrypted gRPC (`grpcs://`, recommended).
   GitLab can authenticate to the agent in your cluster using:
   - A JWT token. Available in both `grpc://` and `grpcs://` configurations. You don't need to generate client certificates with this method.
1. Add a URL configuration to the agent with the [cluster agents API](../../../../api/cluster_agents.md#create-an-agent-url-configuration). If you delete the URL configuration, the receptive agent becomes an ordinary agent. You can associate a receptive agent with only one URL configuration at a time.

1. Install the agent into the cluster. Use the command you copied when you registered the agent, but remove the `--set config.kasAddress=...` parameter.

   JWT token authentication example. Note the added `config.receptive.enabled=true` and `config.api.jwt` settings:

   ```shell
   helm repo add gitlab https://charts.gitlab.io
   helm repo update
   helm upgrade --install my-agent gitlab/gitlab-agent \
    --namespace ns \
    --create-namespace \
    --set config.token=.... \
    --set config.receptive.enabled=true \
    --set config.api.jwtPublicKey=<public_key from the response>
   ```

It might take up to 10 minutes for GitLab to start trying to establish a connection to the new agent.

### Install the agent in the cluster

GitLab recommends using Helm to install the agent.

To connect your cluster to GitLab, install the registered agent
in your cluster. You can either:

- [Install the agent with Helm](#install-the-agent-with-helm).
- Or, follow the [advanced installation method](#advanced-installation-method).

If you do not know which one to choose, we recommend starting with Helm.

To install a receptive agent, follow the steps in [GitLab connects to agent (receptive agent)](#option-2-gitlab-connects-to-agent-receptive-agent).

NOTE:
To connect to multiple clusters, you must configure, register, and install an agent in each cluster. Make sure to give each agent a unique name.

#### Install the agent with Helm

WARNING:
For simplicity, the default Helm chart configuration sets up a service account for the agent with `cluster-admin` rights. You should not use this on production systems. To deploy to a production system, follow the instructions in [Customize the Helm installation](#customize-the-helm-installation) to create a service account with the minimum permissions required for your deployment and specify that during installation.

To install the agent on your cluster using Helm:

1. [Install the Helm CLI](https://helm.sh/docs/intro/install/).
1. In your computer, open a terminal and [connect to your cluster](https://kubernetes.io/docs/tasks/access-application-cluster/access-cluster/).
1. Run the command you copied when you [registered your agent with GitLab](#register-the-agent-with-gitlab). The command should look like:

   ```shell
   helm repo add gitlab https://charts.gitlab.io
   helm repo update
   helm upgrade --install test gitlab/gitlab-agent \
       --namespace gitlab-agent-test \
       --create-namespace \
       --set image.tag=<current agentk version> \
       --set config.token=<your_token> \
       --set config.kasAddress=<address_to_GitLab_KAS_instance>
   ```

1. Optional. [Customize the Helm installation](#customize-the-helm-installation).
   If you install the agent on a production system, you should customize the Helm installation to restrict the permissions of the service account. Related customization options are described below.

##### Customize the Helm installation

By default, the Helm installation command generated by GitLab:

- Creates a namespace `gitlab-agent` for the deployment (`--namespace gitlab-agent`). You can skip creating the namespace by omitting the `--create-namespace` flag.
- Sets up a service account for the agent and assigns it the `cluster-admin` role. You can:
  - Skip creating the service account by adding `--set serviceAccount.create=false` to the `helm install` command. In this case, you must set `serviceAccount.name` to a pre-existing service account.
  - Customise the role assigned to the service account by adding `--set rbac.useExistingRole <your role name>` to the `helm install` command. In this case, you should have a pre-created role with restricted permissions that can be used by the service account.
  - Skip role assignment altogether by adding `--set rbac.create=false` to your `helm install` command. In this case, you must create `ClusterRoleBinding` manually.
- Creates a `Secret` resource for the agent's access token. To instead bring your own secret with a token, omit the token (`--set token=...`) and instead use `--set config.secretName=<your secret name>`.
- Creates a `Deployment` resource for the `agentk` pod.

To see the full list of customizations available, see the Helm chart's [README](https://gitlab.com/gitlab-org/charts/gitlab-agent/-/blob/main/README.md#values).

##### Use the agent when KAS is behind a self-signed certificate

When [KAS](../../../../administration/clusters/kas.md) is behind a self-signed certificate,
you can set the value of `config.kasCaCert` to the certificate. For example:

```shell
helm upgrade --install gitlab-agent gitlab/gitlab-agent \
  --set-file config.kasCaCert=my-custom-ca.pem
```

In this example, `my-custom-ca.pem` is the path to a local file that contains
the CA certificate used by KAS. The certificate is automatically stored in a
config map and mounted in the `agentk` pod.

If KAS is installed with the GitLab chart, and the chart is configured to provide
an [auto-generated self-signed wildcard certificate](https://docs.gitlab.com/charts/installation/tls.html#option-4-use-auto-generated-self-signed-wildcard-certificate), you can extract the CA certificate from the `RELEASE-wildcard-tls-ca` secret.

##### Use the agent behind an HTTP proxy

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/351867) in GitLab 15.0, the GitLab agent Helm chart supports setting environment variables.

To configure an HTTP proxy when using the Helm chart, you can use the environment variables `HTTP_PROXY`, `HTTPS_PROXY`,
and `NO_PROXY`. Upper and lowercase are both acceptable.

You can set these variables by using the `extraEnv` value, as a list of objects with keys `name` and `value`.
For example, to set only the environment variable `HTTPS_PROXY` to the value `https://example.com/proxy`, you can run:

```shell
helm upgrade --install gitlab-agent gitlab/gitlab-agent \
  --set extraEnv[0].name=HTTPS_PROXY \
  --set extraEnv[0].value=https://example.com/proxy \
  ...
```

NOTE:
DNS rebind protection is disabled when either the `HTTP_PROXY` or the `HTTPS_PROXY` environment variable is set,
and the domain DNS can't be resolved.

#### Advanced installation method

GitLab also provides a [KPT package for the agent](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/tree/master/build/deployment/gitlab-agent). This method provides greater flexibility, but is only recommended for advanced users.

## Install multiple agents in your cluster

NOTE:
In most cases, you should run one agent per cluster and use the agent impersonation features (Premium and Ultimate only) to support multi-tenancy. If you must run multiple agents, we would love to hear from you about any issues you encounter. You can provide your feedback in [issue 454110](https://gitlab.com/gitlab-org/gitlab/-/issues/454110).

To install a second agent in your cluster, you can follow the [previous steps](#register-the-agent-with-gitlab) a second time. To avoid resource name collisions within the cluster, you must either:

- Use a different release name for the agent, for example, `second-gitlab-agent`:

  ```shell
  helm upgrade --install second-gitlab-agent gitlab/gitlab-agent ...
  ```

- Or, install the agent in a different namespace, for example, `different-namespace`:

  ```shell
  helm upgrade --install gitlab-agent gitlab/gitlab-agent \
    --namespace different-namespace \
    ...
  ```

Because each agent in a cluster runs independently, reconciliations are triggered
by every agent with the Flux module enabled.
[Issue 357516](https://gitlab.com/gitlab-org/gitlab/-/issues/357516) proposes to change this behavior.

As a workaround, you can:

- Configure RBAC with the agent so that it only accesses the Flux resources it needs.
- Disable the Flux module on the agents that don't use it.

## Example projects

The following example projects can help you get started with the agent.

- [Distinct application and manifest repository example](https://gitlab.com/gitlab-examples/ops/gitops-demo/hello-world-service-gitops)
- [Auto DevOps setup that uses the CI/CD workflow](https://gitlab.com/gitlab-examples/ops/gitops-demo/hello-world-service)
- [Cluster management project template example that uses the CI/CD workflow](https://gitlab.com/gitlab-examples/ops/gitops-demo/cluster-management)

## Updates and version compatibility

GitLab warns you on the agent's list page to update the agent version installed on your cluster.

For the best experience, the version of the agent installed in your cluster should match the GitLab major and minor version. The previous and next minor versions are also supported. For example, if your GitLab version is v14.9.4 (major version 14, minor version 9), then versions v14.9.0 and v14.9.1 of the agent are ideal, but any v14.8.x or v14.10.x version of the agent is also supported. See [the release page](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/releases) of the GitLab agent.

### Update the agent version

NOTE:
Instead of using `--reuse-values`, you should specify all needed values.
If you use `--reuse-values`, you might miss new defaults or use deprecated values.
To retrieve previous `--set` arguments, use `helm get values <release name>`.
You can save the values to a file with `helm get values gitlab-agent > agent.yaml`, and pass the file to Helm with `-f`:
`helm upgrade gitlab-agent gitlab/gitlab-agent -f agent.yaml`. This safely replaces the behavior of `--reuse-values`.

To update the agent to the latest version, you can run:

```shell
helm repo update
helm upgrade --install gitlab-agent gitlab/gitlab-agent \
  --namespace gitlab-agent
```

To set a specific version, you can override the `image.tag` value. For example, to install version `v14.9.1`, run:

```shell
helm upgrade gitlab-agent gitlab/gitlab-agent \
  --namespace gitlab-agent \
  --set image.tag=v14.9.1
```

The Helm chart is updated separately from the agent for Kubernetes, and might occasionally lag behind the latest version of the agent. If you run `helm repo update` and don't specify an image tag, your agent runs the version specified in the chart.

To use the latest release of the agent for Kubernetes, set the image tag to match the most recent agent image.

## Uninstall the agent

If you [installed the agent with Helm](#install-the-agent-with-helm), then you can also uninstall with Helm. For example, if the release and namespace are both called `gitlab-agent`, then you can uninstall the agent using the following command:

```shell
helm uninstall gitlab-agent \
    --namespace gitlab-agent
```

## Troubleshooting

When you install the agent for Kubernetes, you might encounter the following issues.

### Error: `failed to reconcile the GitLab Agent`

If the `glab cluster agent bootstrap` command fails with the message `failed to reconcile the GitLab Agent`,
it means `glab` couldn't reconcile the agent with Flux.

This error might be because:

- The Flux setup doesn't point to the directory where `glab` put the Flux manifests for the agent.
  If you bootstrapped Flux with the `--path` option, you must pass the same value to the `--manifest-path` option of the
  `glab cluster agent bootstrap` command.
- Flux points to the root directory of a project without a `kustomization.yaml`, which causes Flux to traverse subdirectories looking for YAML files.
  To use the agent, you must have an agent configuration file at `.gitlab/agents/<agent-name>/config.yaml`,
  which is not a valid Kubernetes manifest. Flux fails to apply this file, which causes an error.
  To resolve, you should point Flux at a subdirectory instead of the root.
