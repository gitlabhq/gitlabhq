---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Package Registry reference **(FREE)**

The following sections provide a quick reference to the tools, formats, and data structures supported in the Package Registry.

## Supported package managers

WARNING:
Not all package manager formats are ready for production use.

The Package Registry supports the following package manager types:

| Package type                                     | GitLab version | Status                                                     |
| ------------------------------------------------ | -------------- | ---------------------------------------------------------- |
| [Maven](../maven_repository/index.md)            | 11.3+          | GA                                                         |
| [npm](../npm_registry/index.md)                  | 11.7+          | GA                                                         |
| [NuGet](../nuget_repository/index.md)            | 12.8+          | GA                                                         |
| [PyPI](../pypi_repository/index.md)              | 12.10+         | GA                                                         |
| [Generic packages](../generic_packages/index.md) | 13.5+          | GA                                                         |
| [Composer](../composer_repository/index.md)      | 13.2+          | [Beta](https://gitlab.com/groups/gitlab-org/-/epics/6817)  |
| [Conan](../conan_repository/index.md)            | 12.6+          | [Beta](https://gitlab.com/groups/gitlab-org/-/epics/6816)  |
| [Helm](../helm_repository/index.md)              | 14.1+          | [Beta](https://gitlab.com/groups/gitlab-org/-/epics/6366)  |
| [Debian](../debian_repository/index.md)          | 14.2+          | [Alpha](https://gitlab.com/groups/gitlab-org/-/epics/6057) |
| [Go](../go_proxy/index.md)                       | 13.1+          | [Alpha](https://gitlab.com/groups/gitlab-org/-/epics/3043) |
| [Ruby gems](../rubygems_registry/index.md)       | 13.10+         | [Alpha](https://gitlab.com/groups/gitlab-org/-/epics/3200) |

[Status](../../../policy/alpha-beta-support.md):

- Alpha: behind a feature flag and not officially supported.
- Beta: several known issues that may prevent expected use.
- GA (Generally Available): ready for production use at any scale.

You can also use the [API](../../../api/packages.md) to administer the Package Registry.

## Supported hash types

Hash values are used to ensure you are using the correct package. You can view these values in the user interface or with the [API](../../../api/packages.md).

The Package Registry supports the following hash types:

| Package type                                     | Supported hashes                 |
|--------------------------------------------------|----------------------------------|
| [Maven](../maven_repository/index.md)            | MD5, SHA1                        |
| [npm](../npm_registry/index.md)                  | SHA1                             |
| [NuGet](../nuget_repository/index.md)            | not applicable                   |
| [PyPI](../pypi_repository/index.md)              | MD5, SHA256                      |
| [Generic packages](../generic_packages/index.md) | SHA256                           |
| [Composer](../composer_repository/index.md)      | not applicable                   |
| [Conan](../conan_repository/index.md)            | MD5, SHA1                        |
| [Helm](../helm_repository/index.md)              | not applicable                   |
| [Debian](../debian_repository/index.md)          | MD5, SHA1, SHA256                |
| [Go](../go_proxy/index.md)                       | MD5, SHA1, SHA256                |
| [Ruby gems](../rubygems_registry/index.md)       | MD5, SHA1, SHA256 (gemspec only) |
