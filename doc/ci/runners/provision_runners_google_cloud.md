---
stage: Verify
group: Runner
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Provision runners in Google Cloud Compute Engine
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/438316) in GitLab 16.10 [with a flag](../../administration/feature_flags.md) named `google_cloud_support_feature_flag`. This feature is in [beta](../../policy/development_stages_support.md).
> - [Enabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/150472) in GitLab 17.1. Feature flag `google_cloud_support_feature_flag` removed.

You can create a project or group runner for GitLab.com and provision it on your Google Cloud project.
When you create a runner, the GitLab UI provides on-screen instructions and scripts to automatically provision the runner
in your Google Cloud project.

A runner authentication token is assigned to your runner when you create it. A [GRIT](https://gitlab.com/gitlab-org/ci-cd/runner-tools/grit) Terraform script uses this token to
register the runner. The runner then uses the token to authenticate with GitLab when it picks up jobs
from the job queue.

After provisioning, an autoscaling fleet of runners is ready to run CI/CD jobs in Google Cloud.
The runner manager creates temporary runners automatically.

Prerequisites:

- For group runners: Owner role for the group.
- For project runners: Maintainer role for the project.
- For your Google Cloud Platform project: [Owner](https://cloud.google.com/iam/docs/understanding-roles#owner) IAM role.
- [Billing enabled](https://cloud.google.com/billing/docs/how-to/verify-billing-enabled#confirm_billing_is_enabled_on_a_project)
  for your Google Cloud Platform project.
- A working [`gcloud` CLI tool](https://cloud.google.com/sdk/docs/install) authenticated with the
  IAM role on the Google Cloud project.
- [Terraform v1.5 or later](https://releases.hashicorp.com/terraform/1.5.7/) and [Terraform CLI tool](https://developer.hashicorp.com/terraform/install).
- A terminal with Bash installed.

To create a group or project runner and provision it on Google Cloud:

1. On the left sidebar, select **Search or go to** and find your group.
1. Create a new runner.
   - To create a new group runner, select **Build > Runners > New group runner**.
   - To create a new project runner, select **Settings > CI/CD > Runners > New project runner**.
1. In the **Tags** section, in the **Tags** field, enter the job tags to specify jobs the runner can run.
   To use the runner for jobs without tags in addition to the tagged jobs, select **Run untagged**.
1. Optional. In the **Configuration** section, add runner description and additional configurations.
1. Select **Create runner**.
1. In the **Platform** section, select **Google Cloud**.
1. In **Environment**, enter the following details of the Google Cloud environment:

   - **Google Cloud project ID**
   - **Region**
   - **Zone**
   - **Machine type**

1. In **Set up GitLab Runner**, select **Setup instructions**. In the dialog:

   1. To enable the required services, service account, and permissions, in **Configure Google Cloud project** run the Bash script once for each Google Cloud project.
   1. Create a `main.tf` file with the configuration from **Install and register GitLab Runner**.
      The script uses the [GitLab Runner Infrastructure Toolkit](https://gitlab.com/gitlab-org/ci-cd/runner-tools/grit/-/blob/main/docs/scenarios/google/linux/docker-autoscaler-default/index.md)
      (GRIT) to provision the infrastructure on the Google Cloud project to execute your runner manager.

After you execute the scripts, a runner manager connects with the runner authentication token. The runner manager might
take up to one minute to show as online and start receiving jobs.
