---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Using GitLab CI/CD with a GitHub repository

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

GitLab CI/CD can be used with **GitHub.com** and **GitHub Enterprise** by
creating a [CI/CD project](index.md) to connect your GitHub repository to
GitLab.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
Watch a video on [Using GitLab CI/CD pipelines with GitHub repositories](https://www.youtube.com/watch?v=qgl3F2j-1cI).

NOTE:
Because of [GitHub limitations](https://gitlab.com/gitlab-org/gitlab/-/issues/9147),
[GitHub OAuth](../../integration/github.md#enable-github-oauth-in-gitlab)
cannot be used to authenticate with GitHub as an external CI/CD repository.

## Connect with Personal Access Token

Personal access tokens can only be used to connect GitHub.com
repositories to GitLab, and the GitHub user must have the [owner role](https://docs.github.com/en/get-started/learning-about-github/access-permissions-on-github).

To perform a one-off authorization with GitHub to grant GitLab access your
repositories:

1. In GitHub, create a token:
   1. Open <https://github.com/settings/tokens/new>.
   1. Create a **Personal Access Token**.
   1. Enter a **Token description** and update the scope to allow
      `repo` and `admin:repo_hook` so that GitLab can access your project,
      update commit statuses, and create a web hook to notify GitLab of new commits.
1. In GitLab, create a project:
   1. On the left sidebar, at the top, select **Create new** (**{plus}**) and **New project/repository**.
   1. Select **Run CI/CD for external repository**.
   1. Select **GitHub**.
   1. For **Personal access token**, paste the token.
   1. Select **List Repositories**.
   1. Select **Connect** to select the repository.
1. In GitHub, add a `.gitlab-ci.yml` to [configure GitLab CI/CD](../quick_start/index.md).

GitLab:

1. Imports the project.
1. Enables [Pull Mirroring](../../user/project/repository/mirror/pull.md).
1. Enables [GitHub project integration](../../user/project/integrations/github.md).
1. Creates a web hook on GitHub to notify GitLab of new commits.

## Connect manually

To use **GitHub Enterprise** with **GitLab.com**, use this method.

To manually enable GitLab CI/CD for your repository:

1. In GitHub, create a token:
   1. Open <https://github.com/settings/tokens/new>.
   1. Create a **Personal Access Token**.
   1. Enter a **Token description** and update the scope to allow
      `repo` so that GitLab can access your project and update commit statuses.
1. In GitLab, create a project:
   1. On the left sidebar, at the top, select **Create new** (**{plus}**) and **New project/repository**.
   1. Select **Run CI/CD for external repository** and **Repository by URL**.
   1. In the **Git repository URL** field, enter the HTTPS URL for your GitHub repository.
      If your project is private, use the personal access token you just created for authentication.
   1. Fill in all the other fields and select **Create project**.
      GitLab automatically configures polling-based pull mirroring.
1. In GitLab, enable [GitHub project integration](../../user/project/integrations/github.md):
   1. On the left sidebar, select **Settings > Integrations**.
   1. Select the **Active** checkbox.
   1. Paste your personal access token and HTTPS repository URL into the form and select **Save**.
1. In GitLab, create a **Personal Access Token** with `API` scope to
   authenticate the GitHub web hook notifying GitLab of new commits.
1. In GitHub, from **Settings > Webhooks**, create a web hook to notify GitLab of
   new commits.

   The web hook URL should be set to the GitLab API to
   [trigger pull mirroring](../../api/projects.md#start-the-pull-mirroring-process-for-a-project),
   using the GitLab personal access token we just created:

   ```plaintext
   https://gitlab.com/api/v4/projects/<NAMESPACE>%2F<PROJECT>/mirror/pull?private_token=<PERSONAL_ACCESS_TOKEN>
   ```

   Select the **Let me select individual events** option, then check the **Pull requests** and **Pushes** checkboxes. These settings are needed for [pipelines for external pull requests](index.md#pipelines-for-external-pull-requests).

1. In GitHub, add a `.gitlab-ci.yml` to configure GitLab CI/CD.

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, for example `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
