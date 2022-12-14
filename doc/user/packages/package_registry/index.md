---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Package Registry **(FREE)**

> [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/221259) from GitLab Premium to GitLab Free in 13.3.

With the GitLab Package Registry, you can use GitLab as a private or public registry for a variety
of [supported package managers](supported_package_managers.md).
You can publish and share packages, which can be consumed as a dependency in downstream projects.

## Package workflows

Learn how to use the GitLab Package Registry to build your own custom package workflow:

- [Use a project as a package registry](../workflows/project_registry.md)
  to publish all of your packages to one project.

- Publish multiple different packages from one [monorepo project](../workflows/working_with_monorepos.md).

## View packages

You can view packages for your project or group.

1. Go to the project or group.
1. Go to **Packages and registries > Package Registry**.

You can search, sort, and filter packages on this page. You can share your search results by copying
and pasting the URL from your browser.

You can also find helpful code snippets for configuring your package manager or installing a given package.

When you view packages in a group:

- All projects published to the group and its projects are displayed.
- Only the projects you can access are displayed.
- If a project is private, or you are not a member of the project, it is not displayed.

For information on how to create and upload a package, view the GitLab documentation for your package type.

## Authenticate with the registry

Authentication depends on the package manager being used. For more information, see the docs on the
specific package format you want to use.

For most package types, the following credential types are valid:

- [Personal access token](../../profile/personal_access_tokens.md):
  authenticates with your user permissions. Good for personal and local use of the package registry.
- [Project deploy token](../../project/deploy_tokens/index.md):
  allows access to all packages in a project. Good for granting and revoking project access to many
  users.
- [Group deploy token](../../project/deploy_tokens/index.md):
  allows access to all packages in a group and its subgroups. Good for granting and revoking access
  to a large number of packages to sets of users.
- [Job token](../../../ci/jobs/ci_job_token.md):
  allows access to packages in the project running the job for the users running the pipeline.
  Access to other external projects can be configured.

NOTE:
If you have not activated the "Packages" feature for your project at **Settings > General > Project features**, you will receive a 403 Forbidden response.
Accessing package registry via deploy token is not available when external authorization is enabled.

## Use GitLab CI/CD to build packages

You can use [GitLab CI/CD](../../../ci/index.md) to build packages.
For Maven, NuGet, npm, Conan, Helm, and PyPI packages, and Composer dependencies, you can
authenticate with GitLab by using the `CI_JOB_TOKEN`.

CI/CD templates, which you can use to get started, are in [this repository](https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/gitlab/ci/templates).

Learn more about using the GitLab Package Registry with CI/CD:

- [Composer](../composer_repository/index.md#publish-a-composer-package-by-using-cicd)
- [Conan](../conan_repository/index.md#publish-a-conan-package-by-using-cicd)
- [Generic](../generic_packages/index.md#publish-a-generic-package-by-using-cicd)
- [Maven](../maven_repository/index.md#create-maven-packages-with-gitlab-cicd)
- [npm](../npm_registry/index.md#publishing-a-package-via-a-cicd-pipeline)
- [NuGet](../nuget_repository/index.md#publish-a-nuget-package-by-using-cicd)
- [PyPI](../pypi_repository/index.md#authenticate-with-a-ci-job-token)
- [RubyGems](../rubygems_registry/index.md#authenticate-with-a-ci-job-token)

If you use CI/CD to build a package, extended activity information is displayed
when you view the package details:

![Package CI/CD activity](img/package_activity_v12_10.png)

You can view which pipeline published the package, and the commit and user who triggered it. However, the history is limited to five updates of a given package.

## Reduce storage usage

For information on reducing your storage use for the Package Registry, see
[Reduce Package Registry storage use](reduce_package_registry_storage.md).

## Disable the Package Registry

The Package Registry is automatically enabled.

If you are using a self-managed instance of GitLab, your administrator can remove
the menu item, **Packages and registries**, from the GitLab sidebar. For more information,
see the [administration documentation](../../../administration/packages/index.md).

You can also remove the Package Registry for your project specifically:

1. In your project, go to **Settings > General**.
1. Expand the **Visibility, project features, permissions** section and disable the
   **Packages** feature.
1. Select **Save changes**.

The **Packages and registries > Package Registry** entry is removed from the sidebar.

## Package Registry visibility permissions

[Project-level permissions](../../permissions.md)
determine actions such as downloading, pushing, or deleting packages.

The visibility of the Package Registry is independent of the repository and can't be controlled from
your project's settings. For example, if you have a public project and set the repository visibility
to **Only Project Members**, the Package Registry is then public. Disabling the Package
Registry disables all Package Registry operations.

| Project visibility | Action                | [Role](../../permissions.md#roles) required             |
|--------------------|-----------------------|---------------------------------------------------------|
| Public             | View Package Registry | `n/a`, everyone on the internet can perform this action |
| Public             | Publish a package     | Developer or higher                                     |
| Public             | Pull a package        | `n/a`, everyone on the internet can perform this action |
| Internal           | View Package Registry | Guest or higher                                         |
| Internal           | Publish a package     | Developer or higher                                     |
| Internal           | Pull a package        | Guest or higher(1)                                      |
| Private            | View Package Registry | Reporter or higher                                      |
| Private            | Publish a package     | Developer or higher                                     |
| Private            | Pull a package        | Reporter or higher(1)                                   |

1. [GitLab-#329253](https://gitlab.com/gitlab-org/gitlab/-/issues/329253) proposes adding a setting to allow anyone (everyone on the internet) to pull from the Package Registry, no matter what the project visibility is.

## Accepting contributions

This table lists unsupported package manager formats that we are accepting contributions for.
Consider contributing to GitLab. This [development documentation](../../../development/packages/index.md)
guides you through the process.

<!-- vale gitlab.Spelling = NO -->

| Format    | Status                                                        |
| --------- | ------------------------------------------------------------- |
| Chef      | [#36889](https://gitlab.com/gitlab-org/gitlab/-/issues/36889) |
| CocoaPods | [#36890](https://gitlab.com/gitlab-org/gitlab/-/issues/36890) |
| Conda     | [#36891](https://gitlab.com/gitlab-org/gitlab/-/issues/36891) |
| CRAN      | [#36892](https://gitlab.com/gitlab-org/gitlab/-/issues/36892) |
| Opkg      | [#36894](https://gitlab.com/gitlab-org/gitlab/-/issues/36894) |
| P2        | [#36895](https://gitlab.com/gitlab-org/gitlab/-/issues/36895) |
| Puppet    | [#36897](https://gitlab.com/gitlab-org/gitlab/-/issues/36897) |
| RPM       | [#5932](https://gitlab.com/groups/gitlab-org/-/epics/5128)    |
| SBT       | [#36898](https://gitlab.com/gitlab-org/gitlab/-/issues/36898) |
| Swift     | [#12233](https://gitlab.com/gitlab-org/gitlab/-/issues/12233) |
| Vagrant   | [#36899](https://gitlab.com/gitlab-org/gitlab/-/issues/36899) |

<!-- vale gitlab.Spelling = YES -->
