---
stage: Verify
group: Runner
info: >-
  To determine the technical writer assigned to the Stage/Group associated with
  this page, see
  https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---
# Provisioning runners in Google Cloud

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com
**Status:** Beta

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/438316) in GitLab 16.10 [with a flag](../../administration/feature_flags.md) named `google_cloud_support_feature_flag`. This feature is in [beta](../../policy/experiment-beta-support.md).
> - [Enabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/150472) in GitLab 17.1. Feature flag `google_cloud_support_feature_flag` removed.

This feature is in [beta](../../policy/experiment-beta-support.md).

## Creating a runner provisioned in Google Cloud

Prerequisites:

- You must have [billing enabled](https://cloud.google.com/billing/docs/how-to/verify-billing-enabled#confirm_billing_is_enabled_on_a_project)
  for your Google Cloud project.
- You must have a working [`gcloud` CLI tool](https://cloud.google.com/sdk/docs/install) that is authenticated with the
  [Owner](https://cloud.google.com/iam/docs/understanding-roles#owner) IAM role on the Google Cloud project.
- You must have the [Terraform CLI tool](https://developer.hashicorp.com/terraform/install) installed.

You can create a project or group runner for GitLab.com and provision it on your Google Cloud project.
When you create a runner, the GitLab UI provides on-screen instructions and scripts to automatically provision the runner
in a Google Cloud project that you own.

After you create a runner, it is assigned a runner authentication token that a Terraform script uses to register it.
The runner uses the token to authenticate with GitLab when picking up jobs from the job queue.

After the runners are provisioned, an autoscaling fleet of runners is available to execute your CI/CD jobs
in Google Cloud.
A runner manager automatically creates temporary runners.

### Create a group runner

Prerequisites:

- You must have the Owner role for the group.

To create a group runner and provision it on Google Cloud:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Build > Runners**.
1. Select **New group runner**.
1. In the **Tags** section, in the **Tags** field, enter the job tags to specify jobs the runner can run.
   If there are no job tags for this runner, select **Run untagged**.
1. Optional. In the **Runner description** field, add a runner description
   that displays in GitLab.
1. Optional. In the **Configuration** section, add additional configurations.
1. Select **Create runner**.
1. In the **Platform** section, select **Google Cloud**.
1. To specify the environment in Google Cloud where
   runners execute jobs, in **Step 1: Specify environment**, complete the form.
1. In **Step 2: Set up GitLab Runner**, select **Setup instructions**. In the dialog:

   - **Step 1: Configure Google Cloud project** must be executed once per Google Cloud project,
     to ensure it meets the prerequisites for the required services, service account, and permissions.
   - **Step 2: Install and register GitLab Runner** displays the Terraform script that uses the
     [GitLab Runner Infrastructure Toolkit](https://gitlab.com/gitlab-org/ci-cd/runner-tools/grit/-/blob/main/docs/scenarios/google/linux/docker-autoscaler-default/index.md)
     (GRIT) to provision the infrastructure on the Google Cloud project to execute your runner manager.

After you execute the scripts, a runner manager connects with the runner authentication token. The runner manager might
take up to one minute to show as online and start receiving jobs.

### Create a project runner

Prerequisites:

- You must have the Maintainer role for the project.

To create a project runner and provision it on Google Cloud:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > CI/CD**.
1. Expand the **Runners** section.
1. Select **New project runner**.
1. In the **Tags** section, in the **Tags** field, enter the job tags to specify jobs the runner can run.
   If there are no job tags for this runner, select **Run untagged**.
1. Optional. In the **Runner description** field, add a description for the runner
   that displays in GitLab.
1. Optional. In the **Configuration** section, add additional configurations.
1. Select **Create runner**.
1. In the **Platform** section, select **Google Cloud**.
1. To specify the environment in Google Cloud where
   runners execute jobs, in **Step 1: Specify environment**, complete the form.
1. In **Step 2: Set up GitLab Runner**, select **Setup instructions**. In the dialog:

   - **Step 1: Configure Google Cloud project** must be executed once per Google Cloud project,
     to ensure it meets the prerequisites for the required services, service account, and permissions.
   - **Step 2: Install and register GitLab Runner** displays the Terraform script that uses the
     [GitLab Runner Infrastructure Toolkit](https://gitlab.com/gitlab-org/ci-cd/runner-tools/grit/-/blob/main/docs/scenarios/google/linux/docker-autoscaler-default/index.md) (GRIT)
     to provision the infrastructure on the Google Cloud project to execute your runner manager.

After you execute the scripts, a runner manager connects with the runner authentication token. The runner manager might
take up to one minute to show as online and start receiving jobs.
