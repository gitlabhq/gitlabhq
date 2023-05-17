---
stage: Deploy
group: Environments
info: A tutorial using Flux
---

# Tutorial: Set up Flux for GitOps **(FREE)**

This tutorial teaches you how to set up Flux for GitOps. You'll set up a sample project,
complete a bootstrap Flux installation, and authenticate your installation with a
[project deploy token](../../../project/deploy_tokens/index.md).

You can find the fully configured tutorial project [in this GitLab repository](https://gitlab.com/gitlab-org/configure/examples/flux/flux-config).
It works in conjunction with [this repository](https://gitlab.com/gitlab-org/configure/examples/flux/web-app-manifests/-/tree/main), which contains the example Kubernetes manifests.

To set up Flux for GitOps:

1. [Create a personal access token](#create-a-personal-access-token)
1. [Create the Flux repository](#create-the-flux-repository)
1. [Create the Kubernetes manifest repository](#create-the-kubernetes-manifest-repository)
1. [Configure Flux to sync your manifests](#configure-flux-to-sync-your-manifests)
1. [Verify your configuration](#verify-your-configuration)

Prerequisites:

- You must have a Kubernetes cluster running.

## Create a personal access token

To authenticate with the Flux CLI, you must create a personal access token
with the `api` scope:

1. In the upper-right corner, select your avatar.
1. Select **Edit profile**.
1. On the left sidebar, select **Access Tokens**.
1. Enter a name and optional expiry date for the token.
1. Select the `api` scope.
1. Select **Create personal access token**.

You can also use a [project](../../../project/settings/project_access_tokens.md) or [group access token](../../../group/settings/group_access_tokens.md) with the `api` scope.

## Create the Flux repository

Create a Git repository, install Flux, and authenticate Flux with your repo:

1. Make sure your `kubectl` is configured to access your cluster.
1. [Install the Flux CLI](https://fluxcd.io/flux/installation/#install-the-flux-cli). You must install Flux v2 or higher.
1. In GitLab, create a new empty project called `flux-config`.
1. From your shell, export a `GITLAB_TOKEN` environment variable with the value of your personal access token.
   For example, `export GITLAB_TOKEN=<personal-access-token>`.
1. Run the `bootstrap` command. The exact command depends on whether you are
   creating the Flux repository under a GitLab user, group, or subgroup. For more information,
   see the [Flux bootstrap documentation](https://fluxcd.io/flux/installation/#gitlab-and-gitlab-enterprise).

   In this tutorial, you're working with a public project in a subgroup. The bootstrap command looks like this:

   ```shell
   flux bootstrap gitlab \
     --owner=gitlab-org/configure/examples/flux \
     --repository=flux-config \
     --branch=main \
     --path=clusters/my-cluster \
     --deploy-token-auth
   ```

   This command installs Flux on the Kubernetes cluster and configures it to manage itself from the repository `flux-config`.
   The command also automatically creates the project deploy token required to access the `flux-config` repository.

Great work! You now have a repository bootstrapped with a Flux configuration. Any updates to your repository are automatically synced to the cluster.

## Create the Kubernetes manifest repository

Next, create a repository for your Kubernetes manifests:

1. In GitLab, create a new repository called `web-app-manifests`.
1. Add a file to `web-app-manifests` named `nginx-deployment.yaml` with the following contents:

   ```yaml
   apiVersion: apps/v1

   kind: Deployment

   metadata:
     name: nginx-deployment
     labels:
       app: nginx
   spec:
     replicas: 3
     selector:
       matchLabels:
         app: nginx
     template:
       metadata:
         labels:
           app: nginx
       spec:
         containers:
         - name: nginx
           image: nginx:1.14.2
           ports:
           - containerPort: 80
   ```

1. In the new repository, [create a deploy token](../../../project/deploy_tokens/index.md#create-a-deploy-token) with only the `read_repository` scope.
1. Store your deploy token username and password somewhere safe.
1. In Flux CLI, create a secret with your deploy token and point the secret to the new repository. For example:

   ```shell
   flux create secret git flux-deploy-authentication \
            --url=https://gitlab.com/gitlab-org/configure/examples/flux/web-app-manifests \
            --namespace=default \
            --username=<token-user-name> \
            --password=<token-password>
   ```

1. To check if your secret was generated successfully, run:

   ```shell
   kubectl -n default get secrets flux-deploy-authentication -o yaml
   ```

   Under `data`, you should see base64-encoded values associated with your token username and password.

Congratulations! You now have a manifest repository, a deploy token, and a secret generated directly on your cluster.

## Configure Flux to sync your manifests

Next, tell `flux-config` to sync with the `web-app-manifests` repository.

To do so, create a [`GitRepository`](https://fluxcd.io/flux/components/source/gitrepositories/) resource:

1. Clone the `flux-config` repo to your machine.
1. In your local clone of `flux-config`, add the `GitRepository` file `clusters/my-cluster/web-app-manifests-source.yaml`:

   ```yaml
   ---
   apiVersion: source.toolkit.fluxcd.io/v1beta2
   kind: GitRepository
   metadata:
     name: web-app-manifests
     namespace: default
   spec:
     interval: 1m0s
     ref:
       branch: main
     secretRef:
       name: flux-deploy-authentication
     url: https://gitlab.com/gitlab-org/configure/examples/flux/web-app-manifests
   ```

   This file uses `secretRef` to refer back to the deploy token secret you created in the last step.

1. In your local clone of `flux-config`, add the `GitRepository` file `clusters/my-cluster/web-app-manifests-kustomization.yaml`:

   ```yaml
   ---
   apiVersion: kustomize.toolkit.fluxcd.io/v1beta2
   kind: Kustomization
   metadata:
     name: nginx-source-kustomization
     namespace: default
   spec:
     interval: 1m0s
     path: ./
     prune: true
     sourceRef:
       kind: GitRepository
       name: web-app-manifests
       namespace: default
     targetNamespace: default
   ```

   This file adds a [`Kustomization`](https://fluxcd.io/flux/components/kustomize/kustomization/) resource that tells Flux to sync the manifests from
   `web-app-manifests` with `kustomize`.

1. Commit the new files and push.

## Verify your configuration

You should see a newly created `nginx-deployment` pod in your cluster.

To check whether the `nginx-deployment` pod is running in the default namespace, run the following:

```shell
kubectl -n default get pods -n default
```

If you want to see the deployment sync again, try updating the number of replicas in the
`nginx-deployment.yaml` file and push to your `main` branch. If all is working well, it
should sync to the cluster.

Excellent work! You've successfully set up a complete Flux project.
