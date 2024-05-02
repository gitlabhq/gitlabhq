---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Tutorial: Set up Flux for GitOps

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

This tutorial teaches you how to set up Flux for GitOps. You'll complete a bootstrap installation,
install `agentk` in your cluster, and deploy a simple `nginx` application.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i> For an overview of an example Flux
configuration, see [Flux bootstrap and manifest synchronization with GitLab](https://www.youtube.com/watch?v=EjPVRM-N_PQ).

To set up Flux for GitOps:

1. [Create a personal access token](#create-a-personal-access-token)
1. [Complete a bootstrap installation](#complete-a-bootstrap-installation)
1. [Register `agentk`](#register-agentk)
1. [Install `agentk`](#install-agentk)
1. [Deploy an example project](#deploy-an-example-project)

Prerequisites:

- You must have a Kubernetes cluster you can access locally with `kubectl`.
- You must [install the Flux CLI](https://fluxcd.io/flux/installation/#install-the-flux-cli). Be sure to install Flux v2 or higher.

## Create a personal access token

To authenticate with the Flux CLI, create a personal access token with
the `api` scope:

1. On the left sidebar, select your avatar.
1. Select **Edit profile**.
1. On the left sidebar, select **Access Tokens**.
1. Enter a name and optional expiry date for the token.
1. Select the `api` scope.
1. Select **Create personal access token**.

You can also use a [project](../../../project/settings/project_access_tokens.md) or [group access token](../../../group/settings/group_access_tokens.md) with the `api` scope and the `developer` role.

## Complete a bootstrap installation

In this section, you'll bootstrap Flux into an empty GitLab repository with the
[`flux bootstrap`](https://fluxcd.io/flux/installation/bootstrap/gitlab/) command.

To bootstrap a Flux installation:

- Run the `flux bootstrap gitlab` command. For example:

  ```shell
  flux bootstrap gitlab \
  --hostname=gitlab.example.org \
  --owner=example-org \
  --repository=my-repository \
  --branch=master \
  --path=clusters/testing \
  --deploy-token-auth
  ```

The arguments of `bootstrap` are:

| Argument | Description |
|--------------|-------------|
|`hostname` | Hostname of your GitLab instance. |
|`owner` | GitLab group containing the Flux repository. |
|`repository` | GitLab project containing the Flux repository. |
|`branch` | Git branch the changes are committed to. |
|`path` | File path to a folder where the Flux configuration is stored. |

The bootstrap script does the following:

1. Creates a deploy token and saves it as a Kubernetes `secret`.
1. Creates an empty GitLab project, if the project specified by the `--repository` argument doesn't exist.
1. Generates Flux definition files for your project in a folder specified by the `--path` argument.
1. Commits the definition files to the branch specified by the `--branch` argument.
1. Applies the definition files to your cluster.

After you run the script, Flux will be ready to manage itself and any other resources
you add to the GitLab project and path.

The rest of this tutorial assumes your path is `clusters/testing`.

### Upgrade Flux

You might need to upgrade Flux some time after you install it. To do so:

- Rerun the `flux bootstrap gitlab` command.

## Register `agentk`

You must register `agentk` before you install it in your cluster.

To register `agentk`:

1. On the left sidebar, select **Search or go to** and find your project.
   If you have an [agent configuration file](../install/index.md#create-an-agent-configuration-file),
   it must be in this project. Your cluster manifest files should also be in this project.
1. Select **Operate > Kubernetes clusters**.
1. Select **Connect a cluster (agent)**.
   - If you want to create a configuration with CI/CD defaults, type a name.
   - If you already have an agent configuration file, select it from the list.
1. Select **Register an agent**.
1. Securely store the agent access token and `kasAddress` for later.

The agent is registered for your project. You don't need to run any commands yet.

In the next step, you'll use Flux to install `agentk` in your cluster.

## Install `agentk`

Next, use Flux to create a namespace for `agentk` and install it in your cluster.
Keep in mind it takes a few minutes for Flux to pick up and apply configuration changes defined in the repository.

This tutorial uses the namespace `gitlab` for `agentk`.

To install `agentk`:

1. Commit and push the following file to `clusters/testing/namespace-gitlab.yaml`:

   ```yaml
   apiVersion: v1
   kind: Namespace
   metadata:
     name: gitlab
   ```

1. Create a file called `secret.yaml` that contains your agent access token as a secret:

   ```yaml
   apiVersion: v1
   kind: Secret
   metadata:
     name: gitlab-agent-token
     namespace: gitlab
   type: Opaque
   stringData:
      token: "<your-token-here>"
   ```

1. Apply `secret.yaml` to your cluster:

   ```shell
   kubectl apply -f secret.yaml -n gitlab
   ```

   Although this step does not follow GitOps principles, it simplifies configuration for new Flux users.
   For a proper GitOps setup, you should use a secret management solution. See the [Flux documentation](https://fluxcd.io/flux/guides/).

1. Commit and push the following file to `clusters/testing/agentk.yaml`, replacing the values of
   `.spec.values.config.kasAddress` and `.spec.values.config.secretName` with your saved `kas` address and secret `name`:

   ```yaml
   ---
   apiVersion: source.toolkit.fluxcd.io/v1beta2
   kind: HelmRepository
   metadata:
     labels:
       app.kubernetes.io/component: agentk
       app.kubernetes.io/created-by: gitlab
       app.kubernetes.io/name: agentk
       app.kubernetes.io/part-of: gitlab
     name: gitlab-agent
     namespace: gitlab
   spec:
     interval: 1h0m0s
     url: https://charts.gitlab.io
   ---
   apiVersion: helm.toolkit.fluxcd.io/v2beta1
   kind: HelmRelease
   metadata:
     name: gitlab-agent
     namespace: gitlab
   spec:
     chart:
       spec:
         chart: gitlab-agent
         sourceRef:
           kind: HelmRepository
           name: gitlab-agent
           namespace: gitlab
     interval: 1h0m0s
     values:
       config:
         kasAddress: "wss://kas.gitlab.com"
         secretName: gitlab-agent-token
   ```

   The Helm release uses the secret from the previous step.

1. To verify that `agentk` is installed and running in the cluster, run the following command:

   ```shell
   kubectl -n gitlab get pods
   ```

Great work! You've successfully set up Flux with `agentk`. You can repeat the steps from this section
to deploy more applications from this project. In the next section, we'll discuss how to scale Flux across projects.

## Deploy an example project

You can scale Flux deployments across multiple GitLab projects by adding a Flux `GitRepository` and `Kustomization` that points to another project.
You can use this feature to store manifests related to a particular GitLab group in that group.

To demonstrate, deploy an `nginx` application and point Flux at it:

1. Commit and push the following file to `clusters/testing/example-nginx-app.yaml`:

   ```yaml
   ---
   apiVersion: source.toolkit.fluxcd.io/v1
   kind: GitRepository
   metadata:
     name: example-nginx-app
     namespace: flux-system
   spec:
     interval: 1m0s
     ref:
       branch: main
     url: https://gitlab.com/gitlab-examples/ops/gitops-demo/example-mini-flux-deployment.git
   ---
   apiVersion: kustomize.toolkit.fluxcd.io/v1
   kind: Kustomization
   metadata:
     name: example-nginx-app
     namespace: flux-system
   spec:
     interval: 10m0s
     path: ./manifests
     prune: true
     sourceRef:
       kind: GitRepository
       name: example-nginx-app
   ```

1. To verify that the application was deployed correctly and `agentk` is running, run the following command:

   ```shell
   kubectl -n example-nginx get pods
   ```

This tutorial deploys an application from a public project. If you want to add a non-public project, you should create a [project deploy token](../../../project/deploy_tokens/index.md)
and save it as a Flux secret. Be sure to save the namespace and secret name.

Congratulations! You have successfully scaled Flux to multiple groups and projects.
