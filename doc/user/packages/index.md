---
stage: Package
group: Package
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# GitLab Package Registry

> [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/221259) to GitLab Core in 13.3.

With the GitLab Package Registry, you can use GitLab as a private or public repository
for a variety of common package managers. You can build and publish
packages, which can be easily consumed as a dependency in downstream projects.

GitLab acts as a repository for the following:

| Software repository | Description | Available in GitLab version |
| ------------------- | ----------- | --------------------------- |
| [Container Registry](container_registry/index.md)   | The GitLab Container Registry enables every project in GitLab to have its own space to store [Docker](https://www.docker.com/) images. | 8.8+ |
| [Dependency Proxy](dependency_proxy/index.md) **(PREMIUM)** | The GitLab Dependency Proxy sets up a local proxy for frequently used upstream images/packages. | 11.11+ |
| [Conan Repository](conan_repository/index.md) | The GitLab Conan Repository enables every project in GitLab to have its own space to store [Conan](https://conan.io/) packages. | 12.6+ |
| [Maven Repository](maven_repository/index.md) | The GitLab Maven Repository enables every project in GitLab to have its own space to store [Maven](https://maven.apache.org/) packages. | 11.3+ |
| [NPM Registry](npm_registry/index.md)  | The GitLab NPM Registry enables every project in GitLab to have its own space to store [NPM](https://www.npmjs.com/) packages. | 11.7+ |
| [NuGet Repository](nuget_repository/index.md)  | The GitLab NuGet Repository will enable every project in GitLab to have its own space to store [NuGet](https://www.nuget.org/) packages. | 12.8+ |
| [PyPi Repository](pypi_repository/index.md)  | The GitLab PyPi Repository will enable every project in GitLab to have its own space to store [PyPi](https://pypi.org/) packages. | 12.10+ |
| [Go Proxy](go_proxy/index.md) | The Go proxy for GitLab enables every project in GitLab to be fetched with the [Go proxy protocol](https://proxy.golang.org/). | 13.1+ |
| [Composer Repository](composer_repository/index.md)  | The GitLab Composer Repository will enable every project in GitLab to have its own space to store [Composer](https://getcomposer.org/) packages. | 13.2+ |

## View packages

You can view packages for your project or group.

1. Go to the project or group.
1. Go to **{package}** **Packages & Registries > Package Registry**.

You can search, sort, and filter packages on this page.

For information on how to create and upload a package, view the GitLab documentation for your package type.

## Use GitLab CI/CD to build packages

You can use [GitLab CI/CD](./../../ci/README.md) to build packages.
For Maven and NPM packages, and Composer dependencies, you can
authenticate with GitLab by using the `CI_JOB_TOKEN`.

CI/CD templates, which you can use to get started, are in [this repo](https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/gitlab/ci/templates).

Learn more about [using CI/CD to build Maven packages](maven_repository/index.md#creating-maven-packages-with-gitlab-cicd)
and [NPM packages](npm_registry/index.md#publishing-a-package-with-cicd).

If you use CI/CD to build a package, extended activity
information is displayed when you view the package details:

![Package CI/CD activity](img/package_activity_v12_10.png)

You can view which pipeline published the package, as well as the commit and
user who triggered it.

## Download a package

To download a package:

1. Go to **{package}** **Packages & Registries > Package Registry**.
1. Click the name of the package you want to download.
1. In the **Activity** section, click the name of the package you want to download.

## Delete a package

You cannot edit a package after you publish it in the Package Registry. Instead, you
must delete and recreate it.

- You cannot delete packages from the group view. You must delete them from the project view instead.
  See [this issue](https://gitlab.com/gitlab-org/gitlab/-/issues/227714) for details.
- You must have suitable [permissions](../permissions.md).

You can delete packages by using [the API](../../api/packages.md#delete-a-project-package) or the UI.

To delete a package in the UI:

1. Go to **{package}** **Packages & Registries > Package Registry**.
1. Find the name of the package you want to delete.
1. Click **Delete**.

The package is permanently deleted.

## Disable the Package Registry

The Package Registry is automatically enabled.

If you are using a self-managed instance of GitLab, your administrator can remove
the menu item, **{package}** **Packages & Registries**, from the GitLab sidebar. For more information,
see the [administration documentation](../../administration/packages/index.md).

You can also remove the Package Registry for your project specifically:

1. In your project, go to **{settings}** **Settings > General**.
1. Expand the **Visibility, project features, permissions** section and disable the
   **Packages** feature.
1. Click **Save changes**.

The **{package}** **Packages & Registries > Package Registry** entry is removed from the sidebar.

## Package workflows

Learn how to use the GitLab Package Registry to build your own custom package workflow.

- [Use a project as a package registry](./workflows/project_registry.md) to publish all of your packages to one project.
- Publish multiple different packages from one [monorepo project](./workflows/monorepo.md).

## Suggested contributions

Consider contributing to GitLab. This [development documentation](../../development/packages.md) will
guide you through the process. Or check out how other members of the community
are adding support for [PHP](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/17417) or [Terraform](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/18834).

| Format | Use case |
| ------ | ------ |
| [Cargo](https://gitlab.com/gitlab-org/gitlab/-/issues/33060) | Cargo is the Rust package manager. Build, publish and share Rust packages  |
| [Chef](https://gitlab.com/gitlab-org/gitlab/-/issues/36889) | Configuration management with Chef using all the benefits of a repository manager. |
| [CocoaPods](https://gitlab.com/gitlab-org/gitlab/-/issues/36890) | Speed up development with Xcode and CocoaPods. |
| [Conda](https://gitlab.com/gitlab-org/gitlab/-/issues/36891) | Secure and private local Conda repositories. |
| [CRAN](https://gitlab.com/gitlab-org/gitlab/-/issues/36892) | Deploy and resolve CRAN packages for the R language. |
| [Debian](https://gitlab.com/gitlab-org/gitlab/-/issues/5835) | Host and provision Debian packages. |
| [Opkg](https://gitlab.com/gitlab-org/gitlab/-/issues/36894) | Optimize your work with OpenWrt using Opkg repositories. |
| [P2](https://gitlab.com/gitlab-org/gitlab/-/issues/36895) | Host all your Eclipse plugins in your own GitLab P2 repository. |
| [Puppet](https://gitlab.com/gitlab-org/gitlab/-/issues/36897) | Configuration management meets repository management with Puppet repositories. |
| [RPM](https://gitlab.com/gitlab-org/gitlab/-/issues/5932) | Distribute RPMs directly from GitLab. |
| [RubyGems](https://gitlab.com/gitlab-org/gitlab/-/issues/803) | Use GitLab to host your own gems. |
| [SBT](https://gitlab.com/gitlab-org/gitlab/-/issues/36898) | Resolve dependencies from and deploy build output to SBT repositories when running SBT builds. |
| [Vagrant](https://gitlab.com/gitlab-org/gitlab/-/issues/36899) | Securely host your Vagrant boxes in local repositories. |
