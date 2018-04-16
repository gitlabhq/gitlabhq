# Using GitLab CI/CD with a GitHub repository **[PREMIUM]**

GitLab CI/CD can be used with **GitHub.com** and **GitHub Enterprise** by
creating a [CI/CD project][cicd-projects] to connect your GitHub repository to
GitLab.

> Note: to use **GitHub Enterprise** with **GitLab.com** you should use the
> manual method.

## Connect with GitHub integration

If the [GitHub integration][github-integration] has been enabled by your GitLab
administrator:

1. In GitLab create a **CI/CD for external repo** project and select
   **GitHub**.

    ![Create project](img/github_omniauth.png)

1. Once authenticated, you will be redirected to a list of your repositories to
   connect. Click **Connect** to select the repository.

    ![Create project](img/github_repo_list.png)

1. In GitHub, add a `.gitlab-ci.yml` to [configure GitLab CI/CD][ci-quickstart].

GitLab will import the project, enable [Pull Mirroring][pull-mirroring], enable
[GitHub project integration][github-project-integration], and create a web hook
on GitHub to notify GitLab of new commits.

## Connect with Personal Access Token

> Note: Personal Access Tokens can only be used to connect GitHub.com
repositories to GitLab.

If you are not using the [GitHub integration][github-integration], you can
still perform a one-off authorization with GitHub to grant GitLab access your
repositories:

1. Open https://github.com/settings/tokens/new to create a **Personal Access
   Token**. This token with be used to access your repository and push commit
   statuses to GitHub.
   
    The `repo` and `admin:repo_hook` should be enable to allow GitLab access to
    your project, update commit statuses, and create a web hook to notify
    GitLab of new commits.

1. In GitLab create a **CI/CD for external repo** project and select
   **GitHub**.

    ![Create project](img/github_omniauth.png)

1. Paste the token into the **Personal access token** field and click **List
   Repositories**. Click **Connect** to select the repository.

1. In GitHub, add a `.gitlab-ci.yml` to [configure GitLab CI/CD][ci-quickstart].

GitLab will import the project, enable [Pull Mirroring][pull-mirroring], enable
[GitHub project integration][github-project-integration], and create a web hook
on GitHub to notify GitLab of new commits.

## Connect manually

If the [GitHub integration][github-integration] is not enabled, or is enabled
for a different GitHub instance, you GitLab CI/CD can be manually enabled for
your repository.

1. In GitHub open https://github.com/settings/tokens/new create a **Personal
   Access Token.** GitLab will use this token to access your repository and
   push commit statuses.
   
    Enter a **Token description** and update the scope to allow:

    `repo` so that GitLab can access your project and update commit statuses

1. In GitLab create a **CI/CD project** using the Git URL option and the HTTPS
   URL for your GitHub repository. If your project if private, use the personal
   access token you just created for authentication.

    GitLab will automatically configure polling-based pull mirroring.

1. Still in GitLab, enable the [GitHub project integration][github-project-integration]
   from **Settings > Integrations.**

    Check the **Active** checkbox to enable the integration, paste your
    personal access token and HTTPS repository URL into the form, and **Save.**

1. Still in GitLab create a **Personal Access Token** with `API` scope to
   authenticate the GitHub web hook notifying GitLab of new commits.

1. In GitHub from **Settings > Webhooks** create a web hook to notify GitLab of
   new commits.

    The web hook URL should be set to the GitLab API to
    [trigger pull mirroring][pull-mirroring-trigger],
    using the GitLab personal access token we just created.

    ```
    https://gitlab.com/api/v4/projects/<NAMESPACE>%2F<PROJECT>/mirror/pull?private_token=<PERSONAL_ACCESS_TOKEN>
    ```

    ![Create web hook](img/github_push_webhook.png)

1. In GitHub add a `.gitlab-ci.yml` to configure GitLab CI/CD.

[ci-quickstart]: ../quick_start/README.md
[cicd-projects]: ../../user/project/ci_cd_for_external_repo.md
[github-integration]: ../../integration/github.md
[github-project-integration]: ../../user/project/integrations/github.md
[pull-mirroring]: ../../workflow/repository_mirroring.md#pulling-from-a-remote-repository
[pull-mirroring-trigger]: ../../api/projects.md#start-the-pull-mirroring-process-for-a-project
