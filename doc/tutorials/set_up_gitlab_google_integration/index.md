---
stage: Verify
group: Tutorials
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 'Tutorial: Set up the Google Cloud integration'
---

This tutorial shows you how to integrate Google Cloud with GitLab,
so that you can deploy directly to Google Cloud.

To set up the Google Cloud integration:

1. [Secure your usage with Google Cloud Identity and Access Management (IAM)](#secure-your-usage-with-google-cloud-identity-and-access-management-iam)
1. [Connect to a Google Artifact Registry repository](#connect-to-a-google-artifact-registry-repository)
1. [Set up GitLab Runner to execute your CI/CD jobs on Google Cloud](#set-up-gitlab-runner-to-execute-your-cicd-jobs-on-google-cloud)
1. [Deploy to Google Cloud with CI/CD components](#deploy-to-google-cloud-with-cicd-components)

## Before you begin

To set up the integration, you must:

- Have a GitLab project where you have at least the Maintainer role.
- Have the [Owner](https://cloud.google.com/iam/docs/understanding-roles#owner) IAM role on the
  Google Cloud projects that you want to use.
- Have [billing enabled for your Google Cloud project](https://cloud.google.com/billing/docs/how-to/verify-billing-enabled#confirm_billing_is_enabled_on_a_project).
- Have a Google Artifact Registry repository with Docker format and Standard mode.
- Install the [Google Cloud CLI](https://cloud.google.com/sdk/docs/install)
  and [Terraform](https://developer.hashicorp.com/terraform/install).

## Secure your usage with Google Cloud Identity and Access Management (IAM)

To secure your usage of Google Cloud, you must set up the Google Cloud IAM integration.
After this step, your GitLab group or project is connected to Google Cloud. You can handle permissions for
Google Cloud resources without the need for service accounts keys and the associated risks using workload identity federation.

1. On the left sidebar, select **Search or go to** and find your group or project. If you configure this on a group, settings apply to all projects within by default.
1. Select **Settings > Integrations**.
1. Select **Google Cloud IAM**.
1. Select **Guided setup** and follow the instructions.

## Connect to a Google Artifact Registry repository

Now that the Google IAM integration is set up, you can connect to a Google Artifact Registry repository.
After this step, you can view your Google Cloud artifacts in GitLab.

1. In your GitLab project, on the left sidebar, select **Settings > Integrations**.
1. Select **Google Artifact Registry**.
1. Under **Enable integration**, select the **Active** checkbox.
1. Complete the fields:
   - **[Google Cloud project ID](https://cloud.google.com/resource-manager/docs/creating-managing-projects#identifying_projects)**:
     The ID of the Google Cloud project where your Artifact Registry repository is located.
   - **Repository name**: The name of your Artifact Registry repository.
   - **Repository location**: The location of your Artifact Registry repository.
1. In **Configure Google Cloud IAM policies**, follow the onscreen instructions
   to set up the IAM policies in Google Cloud. These policies are required to use the
   Artifact Registry repository in your GitLab project.
1. Select **Save changes**.
1. To view your Google Cloud artifacts, on the left sidebar,
   select **Deploy > Google Artifact Registry**.

In a later step, you will push your container images to Google Artifact Registry.

## Set up GitLab Runner to execute your CI/CD jobs on Google Cloud

You can set up GitLab Runner to run CI/CD jobs on Google Cloud.
After this step, your GitLab project has an autoscaling fleet of runners, with
a runner manager that creates temporary runners to execute multiple jobs simultaneously.

1. In your GitLab project, on the left sidebar, select **Settings > CI/CD**.
1. Expand the **Runners** section.
1. Select **New project runner**.
1. Complete the fields.
   - In the **Platform** section, select **Google Cloud**.
   - In the **Tags** section, in the **Tags** field, enter the job tags to specify jobs the runner can run.
     If there are no job tags for this runner, select **Run untagged**.
   - Optional. In the **Runner description** field, add a description for the runner
     that displays in GitLab.
   - Optional. In the **Configuration** section, add additional configurations.
1. Select **Create runner**.
1. Complete the fields in the **Step 1: Specify environment** section to specify the environment in
   Google Cloud where runners execute CI/CD jobs.
1. Under **Step 2: Set up GitLab Runner**, select **Setup instructions**.
1. Follow the instructions in the modal. You only need to do **Step 1** once for the Google Cloud project, so that it's ready to provision the runners.

After you've followed the instructions, it might take one minute for your runner to be online and ready to run jobs.

## Deploy to Google Cloud with CI/CD components

A best practice for development is to reuse syntax, like CI/CD components to keep consistency across your pipelines.

You can use the library of components from GitLab and Google to make your GitLab project
interact with Google Cloud resources.
See the [CI/CD components from Google](https://gitlab.com/google-gitlab-components).

### Copy container images to Google Artifact Registry

Before you begin, you must have a working CI/CD configuration that builds and pushes container
images to your GitLab container registry.

To copy container images from your GitLab container registry to your Google Artifact Registry,
include the [CI/CD component from Google](https://gitlab.com/explore/catalog/google-gitlab-components/artifact-registry)
in your pipeline.
After this step, whenever a new container image is pushed to your GitLab container registry,
it is also pushed to your Google Artifact Registry.

1. In your GitLab project, on the left sidebar, select **Build > Pipeline editor**.
1. In the existing configuration, add the component as follows.
   - Replace `<your_stage>` with the stage where this job runs.
     It must be after the image is built and pushed to the GitLab container registry.

   ```yaml
   include:
     - component: gitlab.com/google-gitlab-components/artifact-registry/upload-artifact-registry@main
       inputs:
         stage: <your_stage>
         source: $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA
         target: $GOOGLE_ARTIFACT_REGISTRY_REPOSITORY_LOCATION-docker.pkg.dev/$GOOGLE_ARTIFACT_REGISTRY_PROJECT_ID/$GOOGLE_ARTIFACT_REGISTRY_REPOSITORY_NAME/$CI_PROJECT_NAME:$CI_COMMIT_SHORT_SHA
   ```

1. Add a descriptive commit message. **Target branch** must be your default branch.
1. Select **Commit changes**.
1. Go to **Build > Pipelines** and make sure a new pipeline runs.
1. After the pipeline finishes successfully, to view the container image that was copied to Google Artifact Registry,
   on the left sidebar, select **Deploy > Google Artifact Registry**.

### Create a Google Cloud Deploy release

To integrate your pipeline with Google Cloud Deploy, include the [CI/CD component from Google](https://gitlab.com/explore/catalog/google-gitlab-components/cloud-deploy) in your pipeline.
After this step, your pipeline creates a Google Cloud Deploy release with your application.

1. In your GitLab project, on the left sidebar, select **Build > Pipeline editor**.
1. In the existing configuration, add the [Google Cloud Deploy component](https://gitlab.com/explore/catalog/google-gitlab-components/cloud-deploy).
1. Edit the component `inputs`.
1. Add a descriptive commit message. **Target branch** must be your default branch.
1. Select **Commit changes**.
1. Go to **Build > Pipelines** and make sure a new pipeline passes.
1. After the pipeline finishes successfully, to view the release,
   see the [Google Cloud documentation](https://cloud.google.com/deploy/docs/view-release).

And that's it! You've now integrated Google Cloud with GitLab, and your GitLab project seamlessly
deploys to Google Cloud.

## Related topics

- [Google Cloud IAM integration](../../integration/google_cloud_iam.md)
- [Google Artifact Management integration](../../user/project/integrations/google_artifact_management.md)
- [Provisioning runners in Google Cloud](../../ci/runners/provision_runners_google_cloud.md)
