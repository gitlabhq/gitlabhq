---
stage: Deploy
group: Environments
info: A tutorial using Flux
---

# Tutorial: Set up Flux for GitOps **(FREE)**

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

You can also use a [project](../../../project/settings/project_access_tokens.md) or [group access token](../../../group/settings/group_access_tokens.md) with the `api` scope.

## Complete a bootstrap installation

In this section, you'll bootstrap Flux into an empty GitLab repository with the
[`flux bootstrap`](https://fluxcd.io/flux/installation/#gitlab-and-gitlab-enterprise)
command.

To bootstrap a Flux installation:

- Run the `flux bootstrap gitlab` command. For example:

  ```shell
  flux bootstrap gitlab \
  --owner=example-org \
  --repository=my-repository \
  --branch=master \
  --path=clusters/testing \
  --deploy-token-auth
  ```

The bootstrap script does the following:

1. Creates a deploy token and saves it as a Kubernetes `secret`.
1. Creates an empty GitLab project, if the project specified by `--repository` doesn't exist.
1. Generates Flux definition files for your project.
1. Commits the definition files to the specified branch.
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

- Complete the steps in [Register the agent with GitLab](../install/index.md#register-the-agent-with-gitlab).
  Be sure to save the agent registration token and `kas` address.

## Install `agentk`

Next, use Flux to create a namespace for `agentk` and install it in your cluster.

This tutorial uses the namespace `gitlab` for `agentk`.

To install `agentk`:

1. Commit and push the following file to `clusters/testing/namespace-gitlab.yaml`:

   ```yaml
   apiVersion: v1
   kind: Namespace
   metadata:
   name: gitlab
   ```

1. Apply the agent registration token as a secret in the cluster:

   ```shell
   kubectl create secret generic gitlab-agent-token -n gitlab --from-literal=token=YOUR-TOKEN-HERE
   ```

   Although this step does not follow GitOps principles, it simplifies configuration for new Flux users.
   For a proper GitOps setup, you should use a secret management solution. See the [Flux documentation](https://fluxcd.io/flux/guides).

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
           namespace: gitlab-agent
     interval: 1h0m0s
     values:
       config:
         kasAddress: "wss://kas.gitlab.example.com"
         secretName: "gitlab-agent-token"
   ```

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
     secretRef:
       name: example-nginx-app
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
