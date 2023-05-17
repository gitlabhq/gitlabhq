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

<!--- start_remove The following content will be removed on remove_date: '2023-11-22' -->
WARNING:
[External authorization](../../admin_area/settings/external_authorization.md) will be enabled by default in GitLab 16.0. External authorization prevents personal access tokens and deploy tokens from accessing container and package registries and affects all users who use these tokens to access the registries. You can disable external authorization if you want to use personal access tokens and deploy tokens with the container or package registries.
<!--- end_remove -->

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
- If your organization uses two factor authentication (2FA), you must use a personal access token with the scope set to `api`.
- If you are publishing a package via CI/CD pipelines, you must use a CI job token.

NOTE:
If you have not activated the "Package registry" feature for your project at **Settings > General > Visibility, project features, permissions**, you receive a 403 Forbidden response.
Accessing package registry via deploy token is not available when external authorization is enabled.

## Use GitLab CI/CD

You can use [GitLab CI/CD](../../../ci/index.md) to build or import packages into
a package registry.

### To build packages

For Maven, NuGet, npm, Conan, Helm, and PyPI packages, and Composer dependencies, you can
authenticate with GitLab by using the `CI_JOB_TOKEN`.

CI/CD templates, which you can use to get started, are in [this repository](https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/gitlab/ci/templates).

For more information about using the GitLab Package Registry with CI/CD, see:

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

### To import packages

If you already have packages built in a different registry, you can import them
into your GitLab package registry with the [Packages Importer](https://gitlab.com/gitlab-org/ci-cd/package-stage/pkgs_importer)

The Packages Importer runs a CI/CD pipeline that [can import these package types](https://gitlab.com/gitlab-org/ci-cd/package-stage/pkgs_importer#formats-supported):

- NPM
- NuGet

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

The visibility of the Package Registry is independent of the repository and can be controlled from
your project's settings. For example, if you have a public project and set the repository visibility
to **Only Project Members**, the Package Registry is then public. Disabling the Package
Registry disables all Package Registry operations.

| Project visibility | Action                | Minimum [role](../../permissions.md#roles) required     |
|--------------------|-----------------------|---------------------------------------------------------|
| Public             | View Package Registry | `n/a`, everyone on the internet can perform this action |
| Public             | Publish a package     | Developer                                               |
| Public             | Pull a package        | `n/a`, everyone on the internet can perform this action |
| Internal           | View Package Registry | Guest                                                   |
| Internal           | Publish a package     | Developer                                               |
| Internal           | Pull a package        | Guest (1)                                               |
| Private            | View Package Registry | Reporter                                                |
| Private            | Publish a package     | Developer                                               |
| Private            | Pull a package        | Reporter (1)                                            |

### Allow anyone to pull from Package Registry

> Introduced in GitLab 15.7 [with a flag](../../../administration/feature_flags.md) named `package_registry_access_level`. Enabled by default.

FLAG:
On self-managed GitLab, by default this feature is available. To disable it,
ask an administrator to [disable the feature flag](../../../administration/feature_flags.md) named `package_registry_access_level`.

If you want to allow anyone (everyone on the internet) to pull from the Package Registry, no matter what the project visibility is, you can use the additional toggle `Allow anyone to pull from Package Registry` that appears when the project visibility is Private or Internal.

Several known issues exist when you allow anyone to pull from the Package Registry:

- Project-level endpoints are supported. Group-level and instance-level endpoints are not supported. Support for group-level endpoints is proposed in [issue 383537](https://gitlab.com/gitlab-org/gitlab/-/issues/383537).
- It does not work with the [Composer](../composer_repository/index.md#install-a-composer-package), because Composer only has a group endpoint.
- It works with Conan, but using [`conan search`](../conan_repository/index.md#search-for-conan-packages-in-the-package-registry) does not work.

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
