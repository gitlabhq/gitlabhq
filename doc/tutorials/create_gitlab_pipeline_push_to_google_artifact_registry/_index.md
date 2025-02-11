---
stage: Verify
group: tutorials
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 'Tutorial: Create a GitLab pipeline to push to Google Artifact Registry'
---

Learn how to connect GitLab to Google Cloud and create a GitLab pipeline using runners on Compute Engine to push images to Artifact Registry.

## Before you begin

1. To run the commands on this page, set up the `gcloud` CLI in one of the following development environments:

   - [Cloud Shell](https://cloud.google.com/shell/docs/using-cloud-shell)
   - [Local shell](https://cloud.google.com/sdk/docs/install)

1. Create or select a Google Cloud project.

   NOTE:
   If you don't plan to keep the resources that you create in this procedure, then create a new Google Cloud project instead of selecting an existing project. After you finish these steps, you can delete the project, removing all resources associated with the project.

   To create a Google Cloud project, run the following command:

   ```shell
   gcloud projects create PROJECT_ID
   ```

   Replace `PROJECT_ID` with a name for the Google Cloud project you are creating.

1. Select the Google Cloud project that you created:

   ```shell
   gcloud config set project PROJECT_ID
   ```

   Replace `PROJECT_ID` with your Google Cloud project name.

1. [Make sure that billing is enabled for your Google Cloud project](https://cloud.google.com/billing/docs/how-to/verify-billing-enabled#console).

1. Enable the Compute Engine and Artifact Registry APIs:

   ```shell
   gcloud services enable compute.googleapis.com artifactregistry.googleapis.com
   ```

1. Set up the GitLab on Google Cloud integration by following the
   instructions in [Google Cloud Workload Identity Federation and IAM policies](../../integration/google_cloud_iam.md).

1. [Create a standard mode Docker format Artifact Registry repository](https://cloud.google.com/artifact-registry/docs/repositories/create-repos#create).

1. Connect your Artifact Registry repository to your GitLab project by following the
   instructions in [Set up the Google Artifact Registry in a GitLab project](../../user/project/integrations/google_artifact_management.md).

## Clone your GitLab repository

1. To clone your GitLab repository to your working environment using SSH or
   HTTPS, follow the instructions in
   [Clone a Git repository to your local computer](../../topics/git/clone.md).

1. If you are working in your local shell,
   [install Terraform](https://developer.hashicorp.com/terraform/install?product_intent=terraform). Terraform is already installed in
   Cloud Shell.

## Create a Dockerfile

1. In your cloned repository, create a new file named `Dockerfile`.
1. Copy and paste the following into your `Dockerfile`.

   ```dockerfile
   # Dockerfile for test purposes. Generates a new random image in every build.
   FROM alpine:3.15.11
   RUN dd if=/dev/urandom of=random bs=10 count=1
   ```

1. Add your `Dockerfile` to Git, commit, and push to your GitLab repository.

   ```shell
   git add Dockerfile
   git commit -m "add dockerfile"
   git push
   ```

   You are prompted to enter your username and
   [personal access token](../../user/profile/personal_access_tokens.md).

The Dockerfile generates a new random image for every build, and is only for
test purposes.

## Enable continuous integration (CI) runners on Google Compute Engine

[GitLab Runner](https://docs.gitlab.com/runner/) is an application that works with GitLab CI/CD to
run jobs in a pipeline. The GitLab on Google Cloud integration assists you in setting up an
autoscaling fleet of runners on Compute Engine, with a runner manager that
creates temporary runners to execute multiple jobs simultaneously.

To set up your autoscaling fleet of runners, follow the instructions in
[Set up GitLab Runner to execute your CI/CD jobs on Google Cloud](../set_up_gitlab_google_integration/_index.md#set-up-gitlab-runner-to-execute-your-cicd-jobs-on-google-cloud).
Select Google Cloud as the environment where you want your runners to execute
your CI/CD jobs, and fill out the rest of the configuration details.

After you have entered the details for your runners, you can follow the setup
instructions to configure your Google Cloud project, install and register
GitLab Runner, and apply the provided terraform in your working
environment to apply the configuration.

## Create a pipeline

Create a pipeline that builds your Docker image, pushes it to the GitLab container
registry, and copies the image to Google Artifact Registry.

1. In your GitLab project, create a
   [`.gitlab-ci.yml` file](../../ci/quick_start/_index.md#create-a-gitlab-ciyml-file).

1. To create a pipeline that builds your image, pushes it to the GitLab container
   registry, and copies it to Google Artifact Registry, modify the contents of your
   `.gitlab-ci.yml` file to resemble the following.

   In the example, replace the following:

   - <var><code>LOCATION</code></var>: the
     Google Cloud region where you created your Google Artifact Registry repository.
   - <var><code>PROJECT</code></var>: your
     Google Cloud project ID.
   - <var><code>REPOSITORY</code></var>: the
     repository ID of your Google Artifact Registry repository.

   ```yaml
   stages:
     - build
     - deploy

   variables:
     GITLAB_IMAGE: $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA

   build-sample-image:
     image: docker:24.0.5
     stage: build
     services:
       - docker:24.0.5-dind
     before_script:
       - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
     script:
       - docker build -t $GITLAB_IMAGE .
       - docker push $GITLAB_IMAGE

   include:
     - component: gitlab.com/google-gitlab-components/artifact-registry/upload-artifact-registry@0.1.0
       inputs:
         stage: deploy
         source: $GITLAB_IMAGE
         target: LOCATION-docker.pkg.dev/PROJECT/REPOSITORY/image:v1.0.0
   ```

The pipeline uses Docker in Docker to build the image `docker:24.0.5`, stores it
in the GitLab container registry, and then uses the
[Google Artifact Registry GitLab component](https://gitlab.com/explore/catalog/google-gitlab-components/artifact-registry)
to push it to your Google Artifact Registry
repository with the version `v1.0.0`.

## View your artifacts

To view your artifact in GitLab:

1. In your GitLab project, on the left sidebar, select
   **Build** > **Artifacts**.
1. Select the name of the artifact to view the details of the build.

To view your artifact in Google Artifact Registry:

1. [Open the **Repositories** page in the Google Cloud console](https://console.cloud.google.com/artifacts).
1. Select the name of your linked repository.
1. Select the name of the image to view the version name and tags.
1. Select the name of the image version to view the version's build, pull, and
   manifest information.

## Clean up

To avoid incurring charges to your Google Cloud account for the resources used
on this page, you can delete your Google Cloud project. If you want to keep your
project, you can delete your Google Artifact Registry repository.

For information on GitLab and Google Artifact Registry pricing and project management, see the following
resources:

- [GitLab pricing](https://about.gitlab.com/free-trial/devsecops)
- [Delete a GitLab project](../../user/project/working_with_projects.md#delete-a-project)
- [Google Artifact Registry pricing](https://cloud.google.com/artifact-registry/pricing)

### Delete your Google Artifact Registry repository

If you want to keep your Google Cloud project and only delete the Google Artifact Registry
repository resource, follow the steps in this section. If you want to delete
your entire Google Cloud project, follow the steps in
[Delete your project](#delete-your-google-cloud-project).

Before you remove the repository, ensure that any images you want to keep
are available in another location.

To delete your repository, run the following command:

```shell
gcloud artifacts repositories delete REPOSITORY \
    --location=LOCATION
```

Replace the following:

- `REPOSITORY` with your Google Artifact Registry repository ID
- `LOCATION` with the location of your repository

### Delete your Google Cloud project

**Caution**: Deleting a project has the following effects:

- **Everything in the project is deleted.** If you used an existing project for the tasks in this document, when
  you delete it, you also delete any other work you've done in the project.
- **Custom project IDs are lost.** When you created this project, you might have created a custom project ID that
  you want to use in the future. To preserve the URLs that use the project ID, such as an appspot.com URL, delete selected
  resources inside the project instead of deleting the whole project.

If you plan to explore multiple architectures, tutorials, or quick start tutorials on Google Cloud, reusing projects can help you
avoid exceeding project quota limits.

1. In the Google Cloud console, go to the [**Manage resources** page](https://console.cloud.google.com/iam-admin/projects).
1. In the project list, select the project that you want to delete, and then select **Delete**.
1. In the dialog, type the project ID, and then select **Shut down** to delete the project.

## Related topics

- Learn how to [Optimize GitLab CI/CD configuration files](../../ci/yaml/yaml_optimization.md).
- Read about how the GitLab on Google Cloud integration uses IAM with
  workload identity federation to control access to Google Cloud in [Access control with IAM](https://cloud.google.com/docs/gitlab).
