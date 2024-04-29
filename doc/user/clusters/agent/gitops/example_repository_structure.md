---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Tutorial: Deploy a Git repository using Flux

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

In this tutorial, you'll create a GitLab project that builds and deploys an application
to a Kubernetes cluster using Flux. You'll set up a sample manifest project, configure it to
push manifests to a deployment branch, and configure Flux to sync the deployment branch. With this
setup, you can run additional steps in GitLab pipelines before Flux picks up the changes
from the repository.

This tutorial deploys an application from a public project. If you want to add a non-public project, you should create a [project deploy token](../../../project/deploy_tokens/index.md).

To set up a repository for GitOps deployments:

1. [Create the Kubernetes manifest repository](#create-the-kubernetes-manifest-repository)
1. [Create a deployment branch](#create-a-deployment-branch)
1. [Configure GitLab CI/CD to push to your branch](#configure-gitlab-cicd-to-push-to-your-branch)
1. [Configure Flux to sync your manifests](#configure-flux-to-sync-your-manifests)
1. [Verify your configuration](#verify-your-configuration)

Prerequisites:

- You have a Flux repository connected to a Kubernetes cluster.
  If you're starting from scratch, see [Set up Flux for GitOps](flux_tutorial.md).

## Create the Kubernetes manifest repository

First, create a repository for your Kubernetes manifests:

1. In GitLab, create a new repository called `web-app-manifests`.
1. In `web-app-manifests`, add a file named `src/nginx-deployment.yaml` with the following contents:

   ```yaml
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: nginx
   spec:
     replicas: 1
     template:
       spec:
         containers:
         - name: nginx
           image: nginx:1.14.2
           ports:
           - containerPort: 80
   ```

1. In `web-app-manifests`, add a file named `src/kustomization.yaml` with the following contents:

   ```yaml
   apiVersion: kustomize.config.k8s.io/v1beta1
   kind: Kustomization
   resources:
     - nginx-deployment.yaml
   commonLabels:
     app: flux-branches-tutorial
   ```

## Create a deployment branch

Next, create a branch to reflect the current state of your cluster.

In this workflow, the default branch is the single source of truth for your application.
To be reflected in a Kubernetes cluster, a code or configuration change must exist in the default branch.
In a later step, you'll configure CI/CD to merge changes from the default branch into the deployment branch.

To create a deployment branch:

1. In `web-app-manifests`, create a branch named `_gitlab/deploy/example` from the default branch. The branch name in this example is chosen to
   differentiate the deployment branch from feature branches, but this is not required. You can name the deployment branch whatever you like.
1. Create a [project](../../../../user/project/settings/project_access_tokens.md),
   [group](../../../../user/group/settings/group_access_tokens.md) or
   [personal access token](../../../../user/profile/personal_access_tokens.md) with the `write_repository` scope.
1. Create a [CI/CD variable](../../../../ci/variables/index.md) with a token value named `DEPLOYMENT_TOKEN`.
   Remember to [mask](../../../../ci/variables/index.md#mask-a-cicd-variable) the value so that it won't show in
   job logs.
1. Add a rule to [protect](../../../../user/project/protected_branches.md)
   your deployment branch with the following values:

   - Allowed to merge: No one.
   - Allowed to push and merge: Select the token you created in the previous step, or your user if you created
     a personal access token.
   - Allowed to force push: Turn off the toggle.
   - Require approval from code owners: Turn off the toggle.

This configuration ensures that only the corresponding token can push to the branch.

You've successfully created a repository with a protected deployment branch!

## Configure GitLab CI/CD to push to your branch

Next, you'll configure CI/CD to merge changes from the default branch to your deployment branch.

In the root of `web-app-manifests`, create and push a `.gitlab-ci.yml` file with the following contents:

   ```yaml
   deploy:
     stage: deploy
     environment: production
     variables:
       DEPLOYMENT_BRANCH: _gitlab/deploy/example
     script:
       - |
         git config user.name "Deploy Example Bot"
         git config user.email "test@example.com"
         git fetch origin $DEPLOYMENT_BRANCH
         git checkout $DEPLOYMENT_BRANCH
         git merge $CI_COMMIT_SHA --ff-only
         git push https://deploy:$DEPLOYMENT_TOKEN@$CI_SERVER_HOST/$CI_PROJECT_PATH.git HEAD:$DEPLOYMENT_BRANCH
     resource_group: $CI_ENVIRONMENT_SLUG
   ```

This creates a CI/CD pipeline with a single `deploy` job that:

1. Checks out your deployment branch.
1. Merges new changes from the default branch into the deployment branch.
1. Pushes the changes to your repository with the configured token.

## Configure Flux to sync your manifests

Next, configure your Flux repository to sync the deployment branch in by the `web-app-manifests` repository.

To configure, create a [`GitRepository`](https://fluxcd.io/flux/components/source/gitrepositories/) resource:

1. In your local clone of your Flux repository, add a file named `clusters/my-cluster/web-app-manifests-source.yaml`
   with the following contents:

   ```yaml
   apiVersion: source.toolkit.fluxcd.io/v1
   kind: GitRepository
   metadata:
     name: web-app-manifests
     namespace: flux-system
   spec:
     interval: 5m0s
     url: https://gitlab.com/gitlab-org/configure/examples/flux/web-app-manifests-branches
     ref:
       branch: _gitlab/deploy/example
   ```

   You will need to substitute the `url` with the URL of your `web-app-manifests` project.

1. In your local clone of your Flux repository, add a file named `clusters/my-cluster/web-app-manifests-kustomization.yaml`
   with the following contents:

   ```yaml
   apiVersion: kustomize.toolkit.fluxcd.io/v1
   kind: Kustomization
   metadata:
     name: nginx-source-kustomization
     namespace: flux-system
   spec:
     interval: 1m0s
     path: ./src
     prune: true
     sourceRef:
       kind: GitRepository
       name: web-app-manifests
     targetNamespace: default
   ```

   This file adds a [Kustomization](https://fluxcd.io/flux/components/kustomize/kustomizations/) resource that tells Flux to sync the manifests in the artifact fetched from the registry.

1. Commit the new files and push.

## Verify your configuration

After the pipeline completes, you should see a newly created `nginx` pod in your cluster.

If you want to see the deployment sync again, try updating the number of replicas in the
`src/nginx-deployment.yaml` file and push to the default branch. If all is working well, the change
will sync to the cluster when the pipeline has finished.

Congratulations! You successfully configured a project to deploy an application and synchronize your changes!
