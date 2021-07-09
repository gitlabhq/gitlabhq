---
stage: Package
group: Package
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Packages and Registries **(FREE)**

The GitLab [Package Registry](package_registry/index.md) acts as a private or public registry
for a variety of common package managers. You can publish and share
packages, which can be easily consumed as a dependency in downstream projects.

The Package Registry supports the following formats:

| Package type | GitLab version |
| ------------ | -------------- |
| [Composer](composer_repository/index.md) | 13.2+ |
| [Conan](conan_repository/index.md) | 12.6+ |
| [Go](go_proxy/index.md) | 13.1+ |
| [Helm](helm_repository/index.md) | 14.1+ |
| [Maven](maven_repository/index.md) | 11.3+ |
| [npm](npm_registry/index.md) | 11.7+ |
| [NuGet](nuget_repository/index.md) | 12.8+ |
| [PyPI](pypi_repository/index.md) | 12.10+ |
| [Generic packages](generic_packages/index.md) | 13.5+ |
| [Ruby gems](rubygems_registry/index.md) | 13.10+ |

You can also use the [API](../../api/packages.md) to administer the Package Registry.

## Accepting contributions

The below table lists formats that are not supported, but are accepting Community contributions for. Consider contributing to GitLab. This [development documentation](../../development/packages.md)
guides you through the process.

<!-- vale gitlab.Spelling = NO -->

| Format | Status |
| ------ | ------ |
| Chef      | [#36889](https://gitlab.com/gitlab-org/gitlab/-/issues/36889) |
| CocoaPods | [#36890](https://gitlab.com/gitlab-org/gitlab/-/issues/36890) |
| Conda     | [#36891](https://gitlab.com/gitlab-org/gitlab/-/issues/36891) |
| CRAN      | [#36892](https://gitlab.com/gitlab-org/gitlab/-/issues/36892) |
| Debian    | [Draft: Merge Request](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/50438) |
| Opkg      | [#36894](https://gitlab.com/gitlab-org/gitlab/-/issues/36894) |
| P2        | [#36895](https://gitlab.com/gitlab-org/gitlab/-/issues/36895) |
| Puppet    | [#36897](https://gitlab.com/gitlab-org/gitlab/-/issues/36897) |
| RPM       | [#5932](https://gitlab.com/gitlab-org/gitlab/-/issues/5932) |
| SBT       | [#36898](https://gitlab.com/gitlab-org/gitlab/-/issues/36898) |
| Vagrant   | [#36899](https://gitlab.com/gitlab-org/gitlab/-/issues/36899) |

<!-- vale gitlab.Spelling = YES -->
## Container Registry

The GitLab [Container Registry](container_registry/index.md) is a secure and private registry for container images. It's built on open source software and completely integrated within GitLab. Use GitLab CI/CD to create and publish images. Use the GitLab [API](../../api/container_registry.md) to manage the registry across groups and projects.

## Infrastructure Registry

The GitLab [Infrastructure Registry](infrastructure_registry/index.md) is a secure and private registry for infrastructure packages. You can use GitLab CI/CD to create and publish infrastructure packages.

The Infrastructure Registry supports the following formats:

| Package type | GitLab version |
| ------------ | -------------- |
| [Terraform Module](terraform_module_registry/index.md) | 14.0+ |

## Dependency Proxy

The [Dependency Proxy](dependency_proxy/index.md) is a local proxy for frequently-used upstream images and packages.
