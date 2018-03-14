## CI/CD for external repositories

>[Introduced][ee-4642] in [GitLab Premium][eep] 10.6.

Instead of importing the repo directly to GitLab, you can connect your
external repository to get GitLab CI/CD benefits.

This will set up [repository mirroring](../../workflow/repository_mirroring.md)
and create a stripped-down version of a project that has issues, merge requests,
container registry, wiki, and snippets disabled but
[can be re-enabled later on](settings/index.md#sharing-and-permissions).

1. From your GitLab dashboard click **New project**
1. Switch to the **CI/CD for external repo** tab
1. Choose **GitHub** or **Repo by URL**
1. The next steps are similar to the [import flow](import/index.md)

![CI/CD for external repository project creation](img/ci_cd_for_external_repo.png)


[ee-4642]: https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/4642
[eep]: https://about.gitlab.com/products/
