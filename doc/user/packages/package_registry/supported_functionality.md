---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Supported package managers and functionality
---

The GitLab package registry supports different functionalities for each package type. This support includes publishing
and pulling packages, request forwarding, managing duplicates, and authentication.

## Supported package managers

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< alert type="warning" >}}

Not all package manager formats are ready for production use.

{{< /alert >}}

The package registry supports the following package manager types:

| Package type                                      | Status |
|---------------------------------------------------|--------|
| [Composer](../composer_repository/_index.md)      | [Beta](https://gitlab.com/groups/gitlab-org/-/epics/6817) |
| [Conan 1](../conan_1_repository/_index.md)            | [Experiment](https://gitlab.com/groups/gitlab-org/-/epics/6816) |
| [Conan 2](../conan_2_repository/_index.md)            | [Experiment](https://gitlab.com/groups/gitlab-org/-/epics/8258) |
| [Debian](../debian_repository/_index.md)          | [Experiment](https://gitlab.com/groups/gitlab-org/-/epics/6057) |
| [Generic packages](../generic_packages/_index.md) | Generally available     |
| [Go](../go_proxy/_index.md)                       | [Experiment](https://gitlab.com/groups/gitlab-org/-/epics/3043) |
| [Helm](../helm_repository/_index.md)              | [Beta](https://gitlab.com/groups/gitlab-org/-/epics/6366) |
| [Maven](../maven_repository/_index.md)            | Generally available      |
| [npm](../npm_registry/_index.md)                  | Generally available      |
| [NuGet](../nuget_repository/_index.md)            | Generally available      |
| [PyPI](../pypi_repository/_index.md)              | Generally available      |
| [Ruby gems](../rubygems_registry/_index.md)       | [Experiment](https://gitlab.com/groups/gitlab-org/-/epics/3200) |

[View what each status means](../../../policy/development_stages_support.md).

You can also use the [API](../../../api/packages.md) to administer the package registry.

## Publishing packages

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Packages can be published to your project, group, or instance.

| Package type                                           | Project | Group | Instance |
|--------------------------------------------------------|---------|-------|----------|
| [Maven (with `mvn`)](../maven_repository/_index.md)    | Yes       | No     | No        |
| [Maven (with `gradle`)](../maven_repository/_index.md) | Yes       | No     | No        |
| [Maven (with `sbt`)](../maven_repository/_index.md)    | No        | No     | No        |
| [npm](../npm_registry/_index.md)                       | Yes       | No     | No        |
| [NuGet](../nuget_repository/_index.md)                 | Yes       | No     | No        |
| [PyPI](../pypi_repository/_index.md)                   | Yes       | No     | No        |
| [Generic packages](../generic_packages/_index.md)      | Yes       | No     | No        |
| [Terraform](../terraform_module_registry/_index.md)    | Yes       | No     | No        |
| [Composer](../composer_repository/_index.md)           | No        | Yes    | No        |
| [Conan 1](../conan_1_repository/_index.md)             | Yes       | No     | Yes       |
| [Conan 2](../conan_2_repository/_index.md)             | Yes       | No     | No        |
| [Helm](../helm_repository/_index.md)                   | Yes       | No     | No        |
| [Debian](../debian_repository/_index.md)               | Yes       | No     | No        |
| [Go](../go_proxy/_index.md)                            | Yes       | No     | No        |
| [Ruby gems](../rubygems_registry/_index.md)            | Yes       | No     | No        |

## Pulling packages

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Packages can be pulled from your project, group, or instance.

| Package type                                           | Project | Group | Instance |
|--------------------------------------------------------|---------|-------|----------|
| [Maven (with `mvn`)](../maven_repository/_index.md)    | Yes       | Yes     | Yes       |
| [Maven (with `gradle`)](../maven_repository/_index.md) | Yes       | Yes     | Yes       |
| [Maven (with `sbt`)](../maven_repository/_index.md)    | Yes       | Yes     | Yes       |
| [npm](../npm_registry/_index.md)                       | Yes       | Yes     | Yes       |
| [NuGet](../nuget_repository/_index.md)                 | Yes       | Yes     | No        |
| [PyPI](../pypi_repository/_index.md)                   | Yes       | Yes     | No        |
| [Generic packages](../generic_packages/_index.md)      | Yes       | No      | No        |
| [Terraform](../terraform_module_registry/_index.md)    | No        | Yes     | No        |
| [Composer](../composer_repository/_index.md)           | Yes       | Yes     | No        |
| [Conan 1](../conan_1_repository/_index.md)             | Yes       | No      | Yes       |
| [Conan 2](../conan_2_repository/_index.md)             | Yes       | No      | No        |
| [Helm](../helm_repository/_index.md)                   | Yes       | No      | No        |
| [Debian](../debian_repository/_index.md)               | Yes       | No      | No        |
| [Go](../go_proxy/_index.md)                            | Yes       | No      | Yes       |
| [Ruby gems](../rubygems_registry/_index.md)            | Yes       | No      | No        |

## Forwarding requests

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Prerequisites:

- On GitLab.com: You must be the Owner of the group.
- On GitLab Self-Managed: You must be an administrator.

When a package is not found in your project's package registry, requests are forwarded to the corresponding public registry of the package manager.

The default forwarding behavior varies by package type and can introduce a [dependency confusion vulnerability](https://medium.com/@alex.birsan/dependency-confusion-4a5d60fec610). The table below shows which package managers support package forwarding.

To reduce the associated security risks:

- Verify the package is not being actively used.
- Implement a version control tool, like Git, to track changes to packages.
- Turn off request forwarding:
  - Instance administrators can disable forwarding in the **Admin** area. For more information, see [Control package forwarding](../../../administration/settings/continuous_integration.md#control-package-forwarding).
  - Group owners can turn off package forwarding in the group settings.

To turn off request forwarding for a group:

1. On the left sidebar, select **Search or go to** and find your group. If you've [turned on the new navigation](../../../user/interface_redesign.md), this field is on the top bar.
1. On the left sidebar, select **Settings** > **Packages and registries**.
1. Under **Package forwarding**, clear either of the following checkboxes:
   - **Forward npm package requests**
   - **Forward PyPI package requests**
1. Select **Save changes**.

| Package type                                           | Supports request forwarding | Security considerations |
|--------------------------------------------------------|-----------------------------|------------------------|
| [Maven (with `mvn`)](../maven_repository/_index.md)    | [Yes (disabled by default)](../../../administration/settings/continuous_integration.md#control-package-forwarding) | Requires explicit opt-in for security. |
| [Maven (with `gradle`)](../maven_repository/_index.md) | [Yes (disabled by default)](../../../administration/settings/continuous_integration.md#control-package-forwarding) | Requires explicit opt-in for security. |
| [Maven (with `sbt`)](../maven_repository/_index.md)    | [Yes (disabled by default)](../../../administration/settings/continuous_integration.md#control-package-forwarding) | Requires explicit opt-in for security. |
| [npm](../npm_registry/_index.md)                       | [Yes](../../../administration/settings/continuous_integration.md#control-package-forwarding) | Consider disabling for private packages. |
| [PyPI](../pypi_repository/_index.md)                   | [Yes](../../../administration/settings/continuous_integration.md#control-package-forwarding) | Consider disabling for private packages. |
| [NuGet](../nuget_repository/_index.md)                 | No                           | No |
| [Generic packages](../generic_packages/_index.md)      | No                           | No |
| [Terraform](../terraform_module_registry/_index.md)    | No                           | No |
| [Composer](../composer_repository/_index.md)           | No                           | No |
| [Conan 1](../conan_1_repository/_index.md)               | No                           | No |
| [Conan 2](../conan_2_repository/_index.md)               | No                           | No |
| [Helm](../helm_repository/_index.md)                   | No                           | No |
| [Debian](../debian_repository/_index.md)               | No                           | No |
| [Go](../go_proxy/_index.md)                            | No                           | No |
| [Ruby gems](../rubygems_registry/_index.md)            | No                           | No |

## Deleting packages

When package requests are forwarded to a public registry, package deletion can
cause a [dependency confusion vulnerability](https://medium.com/@alex.birsan/dependency-confusion-4a5d60fec610).

If a system tries to pull a deleted package, the request forwards to the public registry.
If a package with the same name and version is in the public registry, that package is
pulled instead. The package pulled from the registry might not be what you expect, and
could be malicious.

To reduce the associated security risks, before you delete a package:

- Verify the package is not being actively used.
- [Disable request forwarding](#forwarding-requests).

To delete packages, you can:

- [Delete packages in the UI](reduce_package_registry_storage.md#delete-a-package).
- [Delete packages with the API](../../../api/packages.md#delete-a-project-package).

## Importing packages from other repositories

You can use GitLab pipelines to import packages from other repositories, such as Maven Central or Artifactory with the [package importer tool](https://gitlab.com/gitlab-org/ci-cd/package-stage/pkgs_importer).

| Package type                                           | Importer available? |
|--------------------------------------------------------|---------------------|
| [Maven (with `mvn`)](../maven_repository/_index.md)    | Yes                  |
| [Maven (with `gradle`)](../maven_repository/_index.md) | Yes                  |
| [Maven (with `sbt`)](../maven_repository/_index.md)    | Yes                  |
| [npm](../npm_registry/_index.md)                       | Yes                  |
| [NuGet](../nuget_repository/_index.md)                 | Yes                  |
| [PyPI](../pypi_repository/_index.md)                   | Yes                  |
| [Generic packages](../generic_packages/_index.md)      | No                   |
| [Terraform](../terraform_module_registry/_index.md)    | No                   |
| [Composer](../composer_repository/_index.md)           | No                   |
| [Conan 1](../conan_1_repository/_index.md)             | No                   |
| [Conan 2](../conan_2_repository/_index.md)             | No                   |
| [Helm](../helm_repository/_index.md)                   | No                   |
| [Debian](../debian_repository/_index.md)               | No                   |
| [Go](../go_proxy/_index.md)                            | No                   |
| [Ruby gems](../rubygems_registry/_index.md)            | No                   |

## Allow or prevent duplicates

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

By default, the GitLab package registry either allows or prevents duplicates based on the default of that specific package manager format.

| Package type                                           | Duplicates allowed? |
|--------------------------------------------------------|---------------------|
| [Maven (with `mvn`)](../maven_repository/_index.md)    | Yes (configurable)   |
| [Maven (with `gradle`)](../maven_repository/_index.md) | Yes (configurable)   |
| [Maven (with `sbt`)](../maven_repository/_index.md)    | Yes (configurable)   |
| [npm](../npm_registry/_index.md)                       | No                   |
| [NuGet](../nuget_repository/_index.md)                 | Yes                  |
| [PyPI](../pypi_repository/_index.md)                   | No                   |
| [Generic packages](../generic_packages/_index.md)      | Yes (configurable)   |
| [Terraform](../terraform_module_registry/_index.md)    | No                   |
| [Composer](../composer_repository/_index.md)           | No                   |
| [Conan 1](../conan_1_repository/_index.md)             | No                   |
| [Conan 2](../conan_2_repository/_index.md)             | No                   |
| [Helm](../helm_repository/_index.md)                   | Yes                  |
| [Debian](../debian_repository/_index.md)               | Yes                  |
| [Go](../go_proxy/_index.md)                            | No                   |
| [Ruby gems](../rubygems_registry/_index.md)            | Yes                  |

## Authenticate with the registry

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Authentication depends on the package manager you're using. To learn what authentication protocols are supported for a specific package type, see [Authentication protocols](#authentication-protocols).

For most package types, the following authentication tokens are valid:

- [Personal access token](../../profile/personal_access_tokens.md)
- [Project deploy token](../../project/deploy_tokens/_index.md)
- [Group deploy token](../../project/deploy_tokens/_index.md)
- [CI/CD job token](../../../ci/jobs/ci_job_token.md)

The following table lists which authentication tokens are supported
for a given package manager:

| Package type                                           | Supported tokens                                                       |
|--------------------------------------------------------|------------------------------------------------------------------------|
| [Maven (with `mvn`)](../maven_repository/_index.md)    | Personal access, job tokens, deploy (project or group), project access |
| [Maven (with `gradle`)](../maven_repository/_index.md) | Personal access, job tokens, deploy (project or group), project access |
| [Maven (with `sbt`)](../maven_repository/_index.md)    | Personal access, job tokens, deploy (project or group), project access |
| [npm](../npm_registry/_index.md)                       | Personal access, job tokens, deploy (project or group), project access |
| [NuGet](../nuget_repository/_index.md)                 | Personal access, job tokens, deploy (project or group), project access |
| [PyPI](../pypi_repository/_index.md)                   | Personal access, job tokens, deploy (project or group), project access |
| [Generic packages](../generic_packages/_index.md)      | Personal access, job tokens, deploy (project or group), project access |
| [Terraform](../terraform_module_registry/_index.md)    | Personal access, job tokens, deploy (project or group), project access |
| [Composer](../composer_repository/_index.md)           | Personal access, job tokens, deploy (project or group), project access |
| [Conan 1](../conan_1_repository/_index.md)                 | Personal access, job tokens, project access                            |
| [Conan 2](../conan_2_repository/_index.md)                 | Personal access, job tokens, project access                            |
| [Helm](../helm_repository/_index.md)                   | Personal access, job tokens, deploy (project or group)                 |
| [Debian](../debian_repository/_index.md)               | Personal access, job tokens, deploy (project or group)                 |
| [Go](../go_proxy/_index.md)                            | Personal access, job tokens, project access                            |
| [Ruby gems](../rubygems_registry/_index.md)            | Personal access, job tokens, deploy (project or group)                 |

{{< alert type="note" >}}

When you configure authentication to the package registry:

- If the **Package registry** project setting is [turned off](_index.md#turn-off-the-package-registry), you receive a `403 Forbidden` error when you interact with the package registry, even if you have the Owner role.
- If [external authorization](../../../administration/settings/external_authorization.md) is turned on, you can't access the package registry with a deploy token.
- If your organization uses two-factor authentication (2FA), you must use a personal access token with the scope set to `api`.
- If you are publishing a package by using CI/CD pipelines, you must use a CI/CD job token.

{{< /alert >}}

### Authentication protocols

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- Basic authentication for Maven packages [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/212854) in GitLab 16.0.

{{< /history >}}

The following authentication protocols are supported:

| Package type                                           | Supported auth protocols                                    |
|--------------------------------------------------------|-------------------------------------------------------------|
| [Maven (with `mvn`)](../maven_repository/_index.md)    | Headers, Basic auth                                         |
| [Maven (with `gradle`)](../maven_repository/_index.md) | Headers, Basic auth                                         |
| [Maven (with `sbt`)](../maven_repository/_index.md)    | Basic auth ([pulling](#pulling-packages) only)          |
| [npm](../npm_registry/_index.md)                       | OAuth                                                       |
| [NuGet](../nuget_repository/_index.md)                 | Basic auth                                                  |
| [PyPI](../pypi_repository/_index.md)                   | Basic auth                                                  |
| [Generic packages](../generic_packages/_index.md)      | Basic auth                                                  |
| [Terraform](../terraform_module_registry/_index.md)    | Token                                                       |
| [Composer](../composer_repository/_index.md)           | OAuth                                                       |
| [Conan 1](../conan_1_repository/_index.md)                 | OAuth, Basic auth                                           |
| [Conan 2](../conan_2_repository/_index.md)                 | OAuth, Basic auth                                           |
| [Helm](../helm_repository/_index.md)                   | Basic auth                                                  |
| [Debian](../debian_repository/_index.md)               | Basic auth                                                  |
| [Go](../go_proxy/_index.md)                            | Basic auth                                                  |
| [Ruby gems](../rubygems_registry/_index.md)            | Token                                                       |

## Supported hash types

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Hash values are used to ensure you are using the correct package. You can view these values in the user interface or with the [API](../../../api/packages.md).

The package registry supports the following hash types:

| Package type                                           | Supported hashes                 |
|--------------------------------------------------------|----------------------------------|
| [Maven (with `mvn`)](../maven_repository/_index.md)    | MD5, SHA1                        |
| [Maven (with `gradle`)](../maven_repository/_index.md) | MD5, SHA1                        |
| [Maven (with `sbt`)](../maven_repository/_index.md)    | MD5, SHA1                        |
| [npm](../npm_registry/_index.md)                       | SHA1                             |
| [NuGet](../nuget_repository/_index.md)                 | not applicable                   |
| [PyPI](../pypi_repository/_index.md)                   | MD5, SHA256                      |
| [Generic packages](../generic_packages/_index.md)      | SHA256                           |
| [Composer](../composer_repository/_index.md)           | not applicable                   |
| [Conan 1](../conan_1_repository/_index.md)             | MD5, SHA1                        |
| [Conan 2](../conan_2_repository/_index.md)             | MD5, SHA1                        |
| [Helm](../helm_repository/_index.md)                   | not applicable                   |
| [Debian](../debian_repository/_index.md)               | MD5, SHA1, SHA256                |
| [Go](../go_proxy/_index.md)                            | MD5, SHA1, SHA256                |
| [Ruby gems](../rubygems_registry/_index.md)            | MD5, SHA1, SHA256 (gemspec only) |
