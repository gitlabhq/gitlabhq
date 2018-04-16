# GitLab CI/CD for external repositories **[PREMIUM]**

>[Introduced][ee-4642] in [GitLab Premium][eep] 10.6.

GitLab CI/CD can be used with GitHub or any other Git server.
Instead of moving your entire project to GitLab, you can connect your
external repository to get the benefits of GitLab CI/CD. 

- [GitHub](github_integration.md)
- [Bitbucket Cloud](bitbucket_integration.md)

Connecting an external repository will set up [repository mirroring][mirroring]
and create a lightweight project where issues, merge requests, container
registry, wiki, and snippets disabled. These features
[can be re-enabled later][settings].

1. From your GitLab dashboard click **New project**
1. Switch to the **CI/CD for external repo** tab
1. Choose **GitHub** or **Repo by URL**
1. The next steps are similar to the [import flow](../../user/project/import/index.md)

![CI/CD for external repository project creation](img/ci_cd_for_external_repo.png)

[ee-4642]: https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/4642
[eep]: https://about.gitlab.com/products/
[mirroring]: ../../workflow/repository_mirroring.md
[settings]: ../../user/project/settings/index.md#sharing-and-permissions
