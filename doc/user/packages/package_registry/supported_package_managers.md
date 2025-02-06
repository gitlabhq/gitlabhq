---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Supported package managers
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

WARNING:
Not all package manager formats are ready for production use.

The package registry supports the following package manager types:

| Package type                                     | Status |
|--------------------------------------------------|--------|
| [Composer](../composer_repository/index.md)      | [Beta](https://gitlab.com/groups/gitlab-org/-/epics/6817) |
| [Conan](../conan_repository/index.md)            | [Experiment](https://gitlab.com/groups/gitlab-org/-/epics/6816) |
| [Debian](../debian_repository/index.md)          | [Experiment](https://gitlab.com/groups/gitlab-org/-/epics/6057) |
| [Generic packages](../generic_packages/index.md) | Generally available     |
| [Go](../go_proxy/index.md)                       | [Experiment](https://gitlab.com/groups/gitlab-org/-/epics/3043) |
| [Helm](../helm_repository/index.md)              | [Beta](https://gitlab.com/groups/gitlab-org/-/epics/6366) |
| [Maven](../maven_repository/index.md)            | Generally available      |
| [npm](../npm_registry/index.md)                  | Generally available      |
| [NuGet](../nuget_repository/index.md)            | Generally available      |
| [PyPI](../pypi_repository/index.md)              | Generally available      |
| [Ruby gems](../rubygems_registry/index.md)       | [Experiment](https://gitlab.com/groups/gitlab-org/-/epics/3200) |

[View what each status means](../../../policy/development_stages_support.md).

You can also use the [API](../../../api/packages.md) to administer the package registry.
