---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Package registry
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/221259) from GitLab Premium to GitLab Free in 13.3.

{{< /history >}}

With the GitLab package registry, you can use GitLab as a private or public registry for a variety
of [supported package managers](supported_functionality.md).
You can publish and share packages, which can be consumed as a dependency in downstream projects.

## Package workflows

Learn how to use the GitLab package registry to build your own custom package workflow:

- [Use a project as a package registry](../workflows/project_registry.md)
  to publish all of your packages to one project.

- Publish multiple different packages from one [monorepo project](../workflows/working_with_monorepos.md).

## View packages

You can view packages for your project or group:

1. Go to the project or group.
1. Go to **Deploy > Package registry**.

You can search, sort, and filter packages on this page. You can share your search results by copying
and pasting the URL from your browser.

You can also find helpful code snippets for configuring your package manager or installing a given package.

When you view packages in a group:

- All packages published to the group and its projects are displayed.
- Only the projects you can access are displayed.
- If a project is private, or you are not a member of the project, the packages from that project are not displayed.

To learn how to create and upload a package, follow the instructions for your [package type](supported_functionality.md).

## Use GitLab CI/CD

You can use [GitLab CI/CD](../../../ci/_index.md) to build or import packages into
a package registry.

### To build packages

You can authenticate with GitLab by using the `CI_JOB_TOKEN`.

To get started, you can use the available [CI/CD templates](https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/gitlab/ci/templates).

For more information about using the GitLab package registry with CI/CD, see:

- [Generic](../generic_packages/_index.md#publish-a-package)
- [Maven](../maven_repository/_index.md#create-maven-packages-with-gitlab-cicd)
- [npm](../npm_registry/_index.md#publish-a-package-with-a-cicd-pipeline)
- [NuGet](../nuget_repository/_index.md#with-a-cicd-pipeline)
- [PyPI](../pypi_repository/_index.md#authenticate-with-the-gitlab-package-registry)
- [Terraform](../terraform_module_registry/_index.md#authenticate-to-the-terraform-module-registry)

If you use CI/CD to build a package, extended activity information is displayed
when you view the package details:

![Package CI/CD activity](img/package_activity_v12_10.png)

You can view which pipeline published the package, and the commit and user who triggered it. However, the history is limited to five updates of a given package.

### To import packages

If you already have packages built in a different registry, you can import them
into your GitLab package registry with the [package importer](https://gitlab.com/gitlab-org/ci-cd/package-stage/pkgs_importer).

For a list of supported packages, see [Importing packages from other repositories](supported_functionality.md#importing-packages-from-other-repositories).

## Reduce storage usage

For information on reducing your storage use for the package registry, see
[Reduce package registry storage use](reduce_package_registry_storage.md).

## Turn off the package registry

The package registry is automatically turned on.

On a GitLab Self-Managed instance, your administrator can remove
the **Packages and registries** menu item from the GitLab sidebar.
For more information,
see [GitLab package registry administration](../../../administration/packages/_index.md).

You can also remove the package registry for your project specifically:

1. In your project, go to **Settings > General**.
1. Expand the **Visibility, project features, permissions** section and disable the
   **Packages** feature.
1. Select **Save changes**.

The **Deploy > Package registry** entry is removed from the sidebar.

## Package registry visibility permissions

[Project permissions](../../permissions.md)
determine which members and users can download, push, or delete packages.

The visibility of the package registry is independent of the repository and can be controlled from
your project's settings. For example, if you have a public project and set the repository visibility
to **Only Project Members**, the package registry is then public. Turning off the **Package
registry** toggle turns off all package registry operations.

| Project visibility | Action                | Minimum [role](../../permissions.md#roles) required     |
|--------------------|-----------------------|---------------------------------------------------------|
| Public             | View package registry | N/A. Anyone on the internet can perform this action.    |
| Public             | Publish a package     | Developer                                               |
| Public             | Pull a package        | N/A. Anyone on the internet can perform this action.    |
| Internal           | View package registry | Guest                                                   |
| Internal           | Publish a package     | Developer                                               |
| Internal           | Pull a package        | Guest (1)                                               |
| Private            | View package registry | Reporter                                                |
| Private            | Publish a package     | Developer                                               |
| Private            | Pull a package        | Reporter (1)                                            |

### Allow anyone to pull from package registry

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/385994) in GitLab 15.7.
- [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/468058) in GitLab 17.4 to support NuGet group endpoints.
- [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/468059) in GitLab 17.5 to support Maven group endpoint.
- [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/468062) in GitLab 17.5 to support Terraform module namespace endpoints.

{{< /history >}}

To allow anyone to pull from the package registry, regardless of project visibility:

1. On the left sidebar, select **Search or go to** and find your private or internal project.
1. Select **Settings > General**.
1. Expand **Visibility, project features, permissions**.
1. Turn on the **Allow anyone to pull from package registry** toggle.
1. Select **Save changes**.

Anyone on the internet can access the package registry for the project.

#### Disable allowing anyone to pull

Prerequisites:

- You must be an administrator.

To hide the **Allow anyone to pull from package registry** toggle globally:

- [Update the application setting](../../../api/settings.md#update-application-settings) `package_registry_allow_anyone_to_pull_option` to `false`.

Anonymous downloads are turned off, even for projects that turned on the **Allow anyone to pull from Package Registry** toggle.

Several known issues exist when you allow anyone to pull from the package registry:

- Endpoints for projects are supported.
- NuGet registry endpoints for groups are supported. However, because of how NuGet clients send the authentication credentials, anonymous downloads are not allowed. Only GitLab users can pull from the package registry, even if this setting is turned on.
- Maven registry endpoints for groups are supported.
- Terraform module registry endpoints for namespaces are supported.
- Other group and instance endpoints are not fully supported. Support for group endpoints is proposed in [epic 14234](https://gitlab.com/groups/gitlab-org/-/epics/14234).
- It does not work with the [Composer](../composer_repository/_index.md#install-a-composer-package), because Composer only has a group endpoint.
- It works with Conan, but using [`conan search`](../conan_repository/_index.md#search-for-conan-packages-in-the-package-registry) does not work.

## Audit events

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/329588) in GitLab 17.10 [with a flag](../../../administration/feature_flags.md) named `package_registry_audit_events`. Disabled by default.

{{< /history >}}

Create audit events when a package is published or deleted. Namespace Owners can turn on the `audit_events_enabled` setting through the [GraphQL API](../../../api/graphql/reference/_index.md#packagesettings).

You can view audit events:

- On the [**Group audit events**](../../compliance/audit_events.md#group-audit-events) page if the package's project is in a group.
- On the [**Project audit events**](../../compliance/audit_events.md#project-audit-events) page if the package's project is in a user namespace.

## Accepting contributions

The following table lists package formats that are not supported.
Consider contributing to GitLab to add support for these formats.

<!-- vale gitlab_base.Spelling = NO -->

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

<!-- vale gitlab_base.Spelling = YES -->
