---
type: index, howto
---

# GitLab CI/CD for external repositories **(PREMIUM)**

>[Introduced][ee-4642] in [GitLab Premium][eep] 10.6.

NOTE: **Note:**
This feature [is available for free](https://about.gitlab.com/2019/03/21/six-more-months-ci-cd-github/) to
GitLab.com users until September 22nd, 2019.

GitLab CI/CD can be used with:

- [GitHub](github_integration.md).
- [Bitbucket Cloud](bitbucket_integration.md).
- Any other Git server.

Instead of moving your entire project to GitLab, you can connect your
external repository to get the benefits of GitLab CI/CD.

Connecting an external repository will set up [repository mirroring][mirroring]
and create a lightweight project where issues, merge requests, wiki, and
snippets disabled. These features
[can be re-enabled later][settings].

To connect to an external repository:

1. From your GitLab dashboard, click **New project**.
1. Switch to the **CI/CD for external repo** tab.
1. Choose **GitHub** or **Repo by URL**.
1. The next steps are similar to the [import flow](../../user/project/import/index.md).

![CI/CD for external repository project creation](img/ci_cd_for_external_repo.png)

[ee-4642]: https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/4642
[eep]: https://about.gitlab.com/pricing/
[mirroring]: ../../workflow/repository_mirroring.md
[settings]: ../../user/project/settings/index.md#sharing-and-permissions
