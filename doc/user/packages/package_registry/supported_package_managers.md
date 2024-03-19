---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Supported package managers

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

WARNING:
Not all package manager formats are ready for production use.

The package registry supports the following package manager types:

| Package type                                     | GitLab version | Status                                                          |
| ------------------------------------------------ | -------------- | --------------------------------------------------------------- |
| [Maven](../maven_repository/index.md)            | 11.3+          | GA                                                              |
| [npm](../npm_registry/index.md)                  | 11.7+          | GA                                                              |
| [NuGet](../nuget_repository/index.md)            | 12.8+          | GA                                                              |
| [PyPI](../pypi_repository/index.md)              | 12.10+         | GA                                                              |
| [Generic packages](../generic_packages/index.md) | 13.5+          | GA                                                              |
| [Composer](../composer_repository/index.md)      | 13.2+          | [Beta](https://gitlab.com/groups/gitlab-org/-/epics/6817)       |
| [Helm](../helm_repository/index.md)              | 14.1+          | [Beta](https://gitlab.com/groups/gitlab-org/-/epics/6366)       |
| [Conan](../conan_repository/index.md)            | 12.6+          | [Experiment](https://gitlab.com/groups/gitlab-org/-/epics/6816) |
| [Debian](../debian_repository/index.md)          | 14.2+          | [Experiment](https://gitlab.com/groups/gitlab-org/-/epics/6057) |
| [Go](../go_proxy/index.md)                       | 13.1+          | [Experiment](https://gitlab.com/groups/gitlab-org/-/epics/3043) |
| [Ruby gems](../rubygems_registry/index.md)       | 13.10+         | [Experiment](https://gitlab.com/groups/gitlab-org/-/epics/3200) |

[View what each status means](../../../policy/experiment-beta-support.md).

You can also use the [API](../../../api/packages.md) to administer the package registry.
