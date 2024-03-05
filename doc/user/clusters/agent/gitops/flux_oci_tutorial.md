---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Tutorial: Deploy an OCI artifact using Flux

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

This tutorial teaches you how to package your Kubernetes manifests into an [OCI](https://opencontainers.org/)
artifact and deploy them to your cluster using Flux. You'll set up a sample manifest project, configure it to
store manifests as an artifact in the project's container registry, and configure Flux to sync the artifact. With this
setup, you can run additional steps in GitLab pipelines before Flux picks up the changes
from the OCI image.

This tutorial deploys an application from a public project. If you want to add a non-public project, you should create a [project deploy token](../../../project/deploy_tokens/index.md).

To deploy an OCI artifact using Flux:

1. [Create the Kubernetes manifest repository](#create-the-kubernetes-manifest-repository)
1. [Configure the manifest repository to create an OCI artifact](#configure-the-manifest-repository-to-create-an-oci-artifact)
1. [Configure Flux to sync your artifact](#configure-flux-to-sync-your-artifact)
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
     app: flux-oci-tutorial
   ```

## Configure the manifest repository to create an OCI artifact

Next, configure [GitLab CI/CD](../../../../ci/index.md) to package your manifests into an OCI artifact,
and push the artifact to the [GitLab container registry](../../../packages/container_registry/index.md):

1. In the root of `web-app-manifests`, create and push a [`.gitlab-ci.yml`](../../../../ci/index.md#the-gitlab-ciyml-file) file with the following contents:

   ```yaml
   package:
     stage: deploy
     image:
       name: fluxcd/flux-cli:v2.0.0-rc.1
       entrypoint: [""]
     script:
       - mkdir -p manifests
       - kubectl kustomize ./src --output ./manifests
       - |
         flux push artifact oci://$CI_REGISTRY_IMAGE:latest \
           --path="./manifests" \
           --source="$CI_REPOSITORY_URL" \
           --revision="$CI_COMMIT_SHORT_SHA" \
           --creds="$CI_REGISTRY_USER:$CI_REGISTRY_PASSWORD" \
           --annotations="org.opencontainers.image.url=$CI_PROJECT_URL" \
           --annotations="org.opencontainers.image.title=$CI_PROJECT_NAME" \
           --annotations="com.gitlab.job.id=$CI_JOB_ID" \
           --annotations="com.gitlab.job.url=$CI_JOB_URL"
   ```

   When the file is pushed to GitLab, a CI/CD pipeline with a single `package` job is created. This job:

   - Uses `kustomization.yaml` to render your final Kubernetes manifests.
   - Packages your manifests into an OCI artifact.
   - Pushes the OCI artifact to the container registry.

   After the pipeline has completed, you can check your OCI artifact with the container registry UI.

## Configure Flux to sync your artifact

Next, configure your Flux repository to sync the artifact produced by the `web-app-manifests` repository.

To configure, create an [`OCIRepository`](https://fluxcd.io/flux/components/source/ocirepositories/) resource:

1. In your local clone of your Flux repository, add a file named `clusters/my-cluster/web-app-manifests-source.yaml`
   with the following contents:

   ```yaml
   apiVersion: source.toolkit.fluxcd.io/v1beta2
   kind: OCIRepository
   metadata:
     name: web-app-manifests
     namespace: flux-system
   spec:
     interval: 1m0s
     url: oci://registry.gitlab.com/gitlab-org/configure/examples/flux/web-app-manifests-oci
     ref:
       tag: latest
   ```

   You will need to substitute the `url` with the URL of your `web-app-manifests` project's container registry.

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
     path: ./
     prune: true
     sourceRef:
       kind: OCIRepository
       name: web-app-manifests
     targetNamespace: default
   ```

   This file adds a [Kustomization](https://fluxcd.io/flux/components/kustomize/kustomizations/) resource that tells Flux to sync the manifests in the artifact fetched from the registry.

1. Commit the new files and push.

## Verify your configuration

You should see a newly created `nginx` pod in your cluster.

If you want to see the deployment sync again, try updating the number of replicas in the
`src/nginx-deployment.yaml` file and push to the default branch. If all is working well, the change
should sync to the cluster when the pipeline has finished.

Congratulations! You successfully configured a project to deploy an application and synchronize your changes!
