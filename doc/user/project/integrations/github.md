# GitHub project integration **(PREMIUM)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ee/issues/3836) in GitLab Premium 10.6.

GitLab provides an integration for updating the pipeline statuses on GitHub.
This is especially useful if using GitLab for CI/CD only.

This project integration is separate from the [instance wide GitHub integration](../import/github.md#mirroring-and-pipeline-status-sharing)
and is automatically configured on [GitHub import](../../../integration/github.md).

![Pipeline status update on GitHub](img/github_status_check_pipeline_update.png)

## Configuration

### Complete these steps on GitHub

This integration requires a [GitHub API token](https://help.github.com/articles/creating-a-personal-access-token-for-the-command-line/)
with `repo:status` access granted:

1. Go to your "Personal access tokens" page at <https://github.com/settings/tokens>
1. Click "Generate New Token"
1. Ensure that `repo:status` is checked and click "Generate token"
1. Copy the generated token to use on GitLab

### Complete these steps on GitLab

1. Navigate to the project you want to configure.
1. Navigate to the [Integrations page](project_services.md#accessing-the-project-services)
1. Click "GitHub".
1. Select the "Active" checkbox.
1. Paste the token you've generated on GitHub
1. Enter the path to your project on GitHub, such as `https://github.com/username/repository`
1. Optionally check "Static status check names" checkbox to enable static status check names.
1. Save or optionally click "Test Settings".

#### Static / dynamic status check names

Since GitLab 11.5 it is possible to opt-in to using static status check names.

This makes it possible to mark these status checks as _Required_ on GitHub.
If you check "Static status check names" checkbox on the integration page, your
GitLab instance host name is going to be appended to a status check name,
whereas in case of dynamic status check names, a branch name is going to be
appended.

Dynamic status check name is a default behavior.

![Configure GitHub Project Integration](img/github_configuration.png)
