---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Secrets Manager
ignore_in_report: true
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com
- Status: Experiment

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/16319) in GitLab 18.3 [with the flags](../../../development/feature_flags/_index.md) `secrets_manager` and `ci_tanukey_ui`. Disabled by default.
- Feature flag `ci_tanukey_ui` [removed](https://gitlab.com/gitlab-org/gitlab/-/issues/549940) in GitLab 18.4.

{{< /history >}}

{{< alert type="warning" >}}

This feature is an [experiment](../../../policy/development_stages_support.md#experiment) and subject to change without
notice. This feature is not ready for public testing or production use.

{{< /alert >}}

Secrets represent sensitive information your CI/CD jobs need to function. Secrets could be access tokens,
database credentials, private keys, or similar.

Unlike CI/CD variables, which are always available to jobs by default, secrets must be explicitly requested by a job.

Use the GitLab Secrets Manager to securely store and manage your project's secrets and credentials.

## Enable GitLab Secrets Manager

Prerequisites:

- You must have the Owner role for the project.

To enable GitLab Secrets Manager:

1. On the left sidebar, select **Search or go to** and find your project. If you've [turned on the new navigation](../../../user/interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Settings** > **General**.
1. Expand **Visibility, project features, permissions**.
1. Turn on the **Secrets manager** toggle and wait for the secrets manager to be provisioned.

## Define a secret

You can add secrets to the secrets manager so that it can be used for secure CI/CD pipelines
and workflows.

1. On the left sidebar, select **Search or go to** and find your project. If you've [turned on the new navigation](../../../user/interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Secure** > **Secrets manager**.
1. Select **Add secret** and fill in the details:
   - **Name**: Must be unique in the project.
   - **Value**: No limitations.
   - **Description**: Maximum of 200 characters.
   - **Environments**: Can be:
     - **All (default)** (`*`)
     - A specific [environment](../../environments/_index.md#types-of-environments)
     - A [wildcard environment](../../environments/_index.md#limit-the-environment-scope-of-a-cicd-variable).
   - **Branch**: Can be:
     - A specific branch
     - A wildcard branch (must have the `*` character)
   - **Expiration date**: Secrets become unavailable after the expiration date.
   - **Rotation reminder**: Optional. Send an email reminder to rotate the secret after the set number of days.
     Minimum 7 days.

After you create a secret, you can use it in the pipeline configuration or in job scripts.

## Use secrets in job scripts

To access secrets defined with the secret manager, use the [`secrets`](../../yaml/_index.md#secrets) and `gitlab_secrets_manager` keywords:

```yaml
job:
  secrets:
    TEST_SECRET:
      gitlab_secrets_manager:
        name: foo
  script:
   - cat $TEST_SECRET
```
