# GitLab Package Registry

GitLab Packages allows organizations to utilize GitLab as a private repository
for a variety of common package managers. Users are able to build and publish
packages, which can be easily consumed as a dependency in downstream projects.

The Packages feature allows GitLab to act as a repository for the following:

| Software repository | Description | Available in GitLab version |
| ------------------- | ----------- | --------------------------- |
| [Container Registry](container_registry/index.md)   | The GitLab Container Registry enables every project in GitLab to have its own space to store [Docker](https://www.docker.com/) images. | 8.8+ |
| [Dependency Proxy](dependency_proxy/index.md) **(PREMIUM)** | The GitLab Dependency Proxy sets up a local proxy for frequently used upstream images/packages. | 11.11+ |
| [Conan Repository](conan_repository/index.md) **(PREMIUM)** | The GitLab Conan Repository enables every project in GitLab to have its own space to store [Conan](https://conan.io/) packages. | 12.6+ |
| [Maven Repository](maven_repository/index.md) **(PREMIUM)** | The GitLab Maven Repository enables every project in GitLab to have its own space to store [Maven](https://maven.apache.org/) packages. | 11.3+ |
| [NPM Registry](npm_registry/index.md) **(PREMIUM)**  | The GitLab NPM Registry enables every project in GitLab to have its own space to store [NPM](https://www.npmjs.com/) packages. | 11.7+ |
| [NuGet Repository](nuget_repository/index.md) **(PREMIUM)**  | The GitLab NuGet Repository will enable every project in GitLab to have its own space to store [NuGet](https://www.nuget.org/) packages. | 12.8+ |
| [PyPi Repository](pypi_repository/index.md) **(PREMIUM)**  | The GitLab PyPi Repository will enable every project in GitLab to have its own space to store [PyPi](https://pypi.org/) packages. | 12.10+ |

## Enable the Package Registry for your project

If you cannot find the **{package}** **Packages > List** entry under your
project's sidebar, it is not enabled in your GitLab instance. Ask your
administrator to enable GitLab Package Registry following the administration
documentation.

Once enabled for your GitLab instance, to enable Package Registry for your
project:

1. Go to your project's **Settings > General** page.
1. Expand the **Visibility, project features, permissions** section and enable the
**Packages** feature on your project.
1. Press **Save changes** for the changes to take effect. You should now be able to
see the **Packages > List** link in the sidebar.

### View Packages for your project

Navigating to your project's **{package}** **Packages > List** will show a list
of all packages that have been added to your project.

![Project Packages list](img/project_packages_list_v12_10.png)

On this page, you can:

- View all the packages that have been uploaded to the project.
- Sort the packages list by created date, version or name.
- Filter the list by package name.
- Change tabs to display packages of a certain type.
- Remove a package (if you have suitable [permissions](../permissions.md)).
- Navigate to specific package detail page.

### View Packages for your group

You can view all packages belonging to a group by navigating to **{package}**
**Packages > List** from the group sidebar.

![Group Packages list](img/group_packages_list_v12_10.png)

On this page, you can:

- View all the packages that have been uploaded to each of the groups projects.
- Sort the packages list by created date, version, name or project.
- Filter the list by package name.
- Change tabs to display packages of a certain type.
- Navigate to specific package detail page.

### View additional package information

Additional package information can be viewed by browsing to the package details
page from the either the project or group list.

![Package detail](img/package_detail_v12_10.png)

On this page you can:

- See the extended package information, including metadata. This is unique to
each package type and will display different information for different types.
- View quick installation and registry setup instructions. These are a shortcut
for users who have already set up the Package Registry and just want quick
installation instructions.
- View the package activity, including when and how a package was published.
- View and download the contents of the package. Outside of installing a
package via a manager, you can also download the files individually.
- Delete the package (if you have suitable [permissions](../permissions.md)).

### Build packages via GitLab CI/CD

Some of the supported packages can be built via [GitLab CI/CD](./../../ci/README.md)
using the `CI_JOB_TOKEN`. If a package is built this way, then extended activity
information is displayed on the package details page:

![Package CI/CD activity](img/package_activity_v12_10.png)

You can view which pipeline published the package, as well as the commit and
user who triggered it. To see if a package type supports being built via CI/CD,
check the specific documentation for your package type.

## Suggested contributions

Consider contributing to GitLab. This [development documentation](../../development/packages.md) will
guide you through the process. Or check out how other members of the community
are adding support for [PHP](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/17417) or [Terraform](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/18834).

| Format | Use case |
| ------ | ------ |
| [Cargo](https://gitlab.com/gitlab-org/gitlab/issues/33060) | Cargo is the Rust package manager. Build, publish and share Rust packages  |
| [Chef](https://gitlab.com/gitlab-org/gitlab/issues/36889) | Configuration management with Chef using all the benefits of a repository manager. |
| [CocoaPods](https://gitlab.com/gitlab-org/gitlab/issues/36890) | Speed up development with Xcode and CocoaPods. |
| [Conda](https://gitlab.com/gitlab-org/gitlab/issues/36891) | Secure and private local Conda repositories. |
| [CRAN](https://gitlab.com/gitlab-org/gitlab/issues/36892) | Deploy and resolve CRAN packages for the R language. |
| [Debian](https://gitlab.com/gitlab-org/gitlab/issues/5835) | Host and provision Debian packages. |
| [Go](https://gitlab.com/gitlab-org/gitlab/issues/9773) | Resolve Go dependencies from and publish your Go packages to GitLab.  |
| [Opkg](https://gitlab.com/gitlab-org/gitlab/issues/36894) | Optimize your work with OpenWrt using Opkg repositories. |
| [P2](https://gitlab.com/gitlab-org/gitlab/issues/36895) | Host all your Eclipse plugins in your own GitLab P2 repository. |
| [Puppet](https://gitlab.com/gitlab-org/gitlab/issues/36897) | Configuration management meets repository management with Puppet repositories. |
| [PyPi](https://gitlab.com/gitlab-org/gitlab/issues/10483) | Host PyPi distributions. |
| [RPM](https://gitlab.com/gitlab-org/gitlab/issues/5932) | Distribute RPMs directly from GitLab. |
| [RubyGems](https://gitlab.com/gitlab-org/gitlab/issues/803) | Use GitLab to host your own gems. |
| [SBT](https://gitlab.com/gitlab-org/gitlab/issues/36898) | Resolve dependencies from and deploy build output to SBT repositories when running SBT builds. |
| [Vagrant](https://gitlab.com/gitlab-org/gitlab/issues/36899) | Securely host your Vagrant boxes in local repositories. |

## Package workflows

Learning how to use the GitLab Package Registry will help you build your own custom package workflow.

- [Use a project as a package registry](./workflows/project_registry.md) to publish all of your packages to one project.
- [Working with a monorepo](./workflows/monorepo.md): Learn how to publish multiple different packages from one monorepo project.
