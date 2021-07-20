---
stage: Create
group: Ecosystem
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# GitHub project integration **(PREMIUM)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/3836) in GitLab Premium 10.6.

GitLab provides an integration for updating the pipeline statuses on GitHub.
This is especially useful if using GitLab for CI/CD only.

This project integration is separate from the [instance wide GitHub integration](../import/github.md#mirroring-and-pipeline-status-sharing)
and is automatically configured on [GitHub import](../../../integration/github.md).

![Pipeline status update on GitHub](img/github_status_check_pipeline_update.png)

## Configuration

This integration requires a [GitHub API token](https://docs.github.com/en/github/authenticating-to-github/keeping-your-account-and-data-secure/creating-a-personal-access-token)
with `repo:status` access granted.

Complete these steps on GitHub:

1. Go to your **Personal access tokens** page at <https://github.com/settings/tokens>.
1. Select **Generate new token**.
1. Under **Note**, enter a name for the new token.
1. Ensure that `repo:status` is checked and select **Generate token**.
1. Copy the generated token to use in GitLab.

Complete these steps in GitLab:

1. Go to the project you want to configure.
1. Go to the [Integrations page](overview.md#accessing-integrations)
1. Select **GitHub**.
1. Ensure that the **Active** toggle is enabled.
1. Paste the token you generated on GitHub.
1. Enter the path to your project on GitHub, such as `https://github.com/username/repository`.
1. (Optional) To disable static status check names, clear the **Static status check names** checkbox.
1. Select **Save changes** or optionally select **Test settings**.

After configuring the integration, see [Pipelines for external pull requests](../../../ci/ci_cd_for_external_repos/#pipelines-for-external-pull-requests)
to configure pipelines to run for open pull requests.

### Static / dynamic status check names

> - Introduced in GitLab 11.5: using static status check names as opt-in option.
> - [In GitLab 12.4](https://gitlab.com/gitlab-org/gitlab/-/issues/9931), static status check names is default behavior for new projects.

This makes it possible to mark these status checks as **Required** on GitHub.

When **Static status check names** is enabled on the integration page, your
GitLab instance host name is appended to a status check name.

When disabled, it uses dynamic status check names and appends the branch name.
