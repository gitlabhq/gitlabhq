---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: howto
---

# Using GitLab CI/CD with a GitHub repository **(PREMIUM)**

GitLab CI/CD can be used with **GitHub.com** and **GitHub Enterprise** by
creating a [CI/CD project](index.md) to connect your GitHub repository to
GitLab.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
Watch a video on [Using GitLab CI/CD pipelines with GitHub repositories](https://www.youtube.com/watch?v=qgl3F2j-1cI).

NOTE:
Because of [GitHub limitations](https://gitlab.com/gitlab-org/gitlab/-/issues/9147),
[GitHub OAuth](../../integration/github.md#enabling-github-oauth)
cannot be used to authenticate with GitHub as an external CI/CD repository.

## Connect with Personal Access Token

Personal access tokens can only be used to connect GitHub.com
repositories to GitLab, and the GitHub user must have the [owner role](https://docs.github.com/en/get-started/learning-about-github/access-permissions-on-github).

To perform a one-off authorization with GitHub to grant GitLab access your
repositories:

1. Open <https://github.com/settings/tokens/new> to create a **Personal Access
   Token**. This token is used to access your repository and push commit
   statuses to GitHub.

   The `repo` and `admin:repo_hook` should be enable to allow GitLab access to
   your project, update commit statuses, and create a web hook to notify
   GitLab of new commits.

1. In GitLab, go to the [new project page](../../user/project/working_with_projects.md#create-a-project), select the **CI/CD for external repository** tab, and then click
   **GitHub**.

1. Paste the token into the **Personal access token** field and click **List
   Repositories**. Click **Connect** to select the repository.

1. In GitHub, add a `.gitlab-ci.yml` to [configure GitLab CI/CD](../quick_start/index.md).

GitLab:

1. Imports the project.
1. Enables [Pull Mirroring](../../user/project/repository/repository_mirroring.md#pulling-from-a-remote-repository)
1. Enables [GitHub project integration](../../user/project/integrations/github.md)
1. Creates a web hook on GitHub to notify GitLab of new commits.

## Connect manually

To use **GitHub Enterprise** with **GitLab.com**, use this method.

To manually enable GitLab CI/CD for your repository:

1. In GitHub open <https://github.com/settings/tokens/new> create a **Personal
   Access Token.** GitLab uses this token to access your repository and
   push commit statuses.

   Enter a **Token description** and update the scope to allow:

   `repo` so that GitLab can access your project and update commit statuses

1. In GitLab create a **CI/CD project** using the Git URL option and the HTTPS
   URL for your GitHub repository. If your project is private, use the personal
   access token you just created for authentication.

   GitLab automatically configures polling-based pull mirroring.

1. Still in GitLab, enable the [GitHub project integration](../../user/project/integrations/github.md)
   from **Settings > Integrations.**

   Check the **Active** checkbox to enable the integration, paste your
   personal access token and HTTPS repository URL into the form, and **Save.**

1. Still in GitLab create a **Personal Access Token** with `API` scope to
   authenticate the GitHub web hook notifying GitLab of new commits.

1. In GitHub from **Settings > Webhooks** create a web hook to notify GitLab of
   new commits.

   The web hook URL should be set to the GitLab API to
   [trigger pull mirroring](../../api/projects.md#start-the-pull-mirroring-process-for-a-project),
   using the GitLab personal access token we just created:

   ```plaintext
   https://gitlab.com/api/v4/projects/<NAMESPACE>%2F<PROJECT>/mirror/pull?private_token=<PERSONAL_ACCESS_TOKEN>
   ```

   Select the **Let me select individual events** option, then check the **Pull requests** and **Pushes** checkboxes. These settings are needed for [pipelines for external pull requests](index.md#pipelines-for-external-pull-requests).

1. In GitHub add a `.gitlab-ci.yml` to configure GitLab CI/CD.

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
