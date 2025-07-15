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
| [Maven (with `mvn`)](../maven_repository/_index.md)    | Y       | N     | N        |
| [Maven (with `gradle`)](../maven_repository/_index.md) | Y       | N     | N        |
| [Maven (with `sbt`)](../maven_repository/_index.md)    | N       | N     | N        |
| [npm](../npm_registry/_index.md)                       | Y       | N     | N        |
| [NuGet](../nuget_repository/_index.md)                 | Y       | N     | N        |
| [PyPI](../pypi_repository/_index.md)                   | Y       | N     | N        |
| [Generic packages](../generic_packages/_index.md)      | Y       | N     | N        |
| [Terraform](../terraform_module_registry/_index.md)    | Y       | N     | N        |
| [Composer](../composer_repository/_index.md)           | N       | Y     | N        |
| [Conan 1](../conan_1_repository/_index.md)             | Y       | N     | Y        |
| [Conan 2](../conan_2_repository/_index.md)             | Y       | N     | N        |
| [Helm](../helm_repository/_index.md)                   | Y       | N     | N        |
| [Debian](../debian_repository/_index.md)               | Y       | N     | N        |
| [Go](../go_proxy/_index.md)                            | Y       | N     | N        |
| [Ruby gems](../rubygems_registry/_index.md)            | Y       | N     | N        |

## Pulling packages

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Packages can be pulled from your project, group, or instance.

| Package type                                           | Project | Group | Instance |
|--------------------------------------------------------|---------|-------|----------|
| [Maven (with `mvn`)](../maven_repository/_index.md)    | Y       | Y     | Y        |
| [Maven (with `gradle`)](../maven_repository/_index.md) | Y       | Y     | Y        |
| [Maven (with `sbt`)](../maven_repository/_index.md)    | Y       | Y     | Y        |
| [npm](../npm_registry/_index.md)                       | Y       | Y     | Y        |
| [NuGet](../nuget_repository/_index.md)                 | Y       | Y     | N        |
| [PyPI](../pypi_repository/_index.md)                   | Y       | Y     | N        |
| [Generic packages](../generic_packages/_index.md)      | Y       | N     | N        |
| [Terraform](../terraform_module_registry/_index.md)    | N       | Y     | N        |
| [Composer](../composer_repository/_index.md)           | Y       | Y     | N        |
| [Conan 1](../conan_1_repository/_index.md)             | Y       | N     | Y        |
| [Conan 2](../conan_2_repository/_index.md)             | Y       | N     | N        |
| [Helm](../helm_repository/_index.md)                   | Y       | N     | N        |
| [Debian](../debian_repository/_index.md)               | Y       | N     | N        |
| [Go](../go_proxy/_index.md)                            | Y       | N     | Y        |
| [Ruby gems](../rubygems_registry/_index.md)            | Y       | N     | N        |

## Forwarding requests

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

When a package is not found in your project's package registry, GitLab can forward the request to the corresponding public registry. For example, Maven Central, npmjs, or PyPI.

The default forwarding behavior varies by package type and can introduce a [dependency confusion vulnerability](https://medium.com/@alex.birsan/dependency-confusion-4a5d60fec610).

To reduce the associated security risks:

- Verify the package is not being actively used.
- Disable request forwarding:
  - Instance administrators can disable forwarding in the [**Continuous Integration** section](../../../administration/settings/continuous_integration.md#control-package-forwarding) of the **Admin** area.
  - Group owners can disable forwarding in the **Packages and Registries** section of the group settings.
- Implement a version control tool, like Git, to track changes to packages.

| Package type                                           | Supports request forwarding | Security considerations |
|--------------------------------------------------------|-----------------------------|------------------------|
| [Maven (with `mvn`)](../maven_repository/_index.md)    | [Yes (disabled by default)](../../../administration/settings/continuous_integration.md#control-package-forwarding) | Requires explicit opt-in for security. |
| [Maven (with `gradle`)](../maven_repository/_index.md) | [Yes (disabled by default)](../../../administration/settings/continuous_integration.md#control-package-forwarding) | Requires explicit opt-in for security. |
| [Maven (with `sbt`)](../maven_repository/_index.md)    | [Yes (disabled by default)](../../../administration/settings/continuous_integration.md#control-package-forwarding) | Requires explicit opt-in for security. |
| [npm](../npm_registry/_index.md)                       | [Yes](../../../administration/settings/continuous_integration.md#control-package-forwarding) | Consider disabling for private packages. |
| [NuGet](../nuget_repository/_index.md)                 | N                           | N |
| [PyPI](../pypi_repository/_index.md)                   | [Yes](../../../administration/settings/continuous_integration.md#control-package-forwarding) | Consider disabling for private packages. |
| [Generic packages](../generic_packages/_index.md)      | N                           | N |
| [Terraform](../terraform_module_registry/_index.md)    | N                           | N |
| [Composer](../composer_repository/_index.md)           | N                           | N |
| [Conan 1](../conan_1_repository/_index.md)               | N                           | N |
| [Conan 2](../conan_2_repository/_index.md)               | N                           | N |
| [Helm](../helm_repository/_index.md)                   | N                           | N |
| [Debian](../debian_repository/_index.md)               | N                           | N |
| [Go](../go_proxy/_index.md)                            | N                           | N |
| [Ruby gems](../rubygems_registry/_index.md)            | N                           | N |

## Deleting packages

When package requests are forwarded to a public registry, deleting packages can
be a [dependency confusion vulnerability](https://medium.com/@alex.birsan/dependency-confusion-4a5d60fec610).

If a system tries to pull a deleted package, the request is forwarded to the public
registry. If a package with the same name and version is found in the public registry, that package
is pulled instead. There is a risk that the package pulled from the registry might not be
what is expected, and could even be malicious.

To reduce the associated security risks, before deleting a package you can:

- Verify the package is not being actively used.
- Disable request forwarding:
  - Instance administrators can disable forwarding in the [**Continuous Integration** section](../../../administration/settings/continuous_integration.md#control-package-forwarding) of the **Admin** area.
  - Group owners can disable forwarding in the **Packages and Registries** section of the group settings.

## Importing packages from other repositories

You can use GitLab pipelines to import packages from other repositories, such as Maven Central or Artifactory with the [package importer tool](https://gitlab.com/gitlab-org/ci-cd/package-stage/pkgs_importer).

| Package type                                           | Importer available? |
|--------------------------------------------------------|---------------------|
| [Maven (with `mvn`)](../maven_repository/_index.md)    | Y                   |
| [Maven (with `gradle`)](../maven_repository/_index.md) | Y                   |
| [Maven (with `sbt`)](../maven_repository/_index.md)    | Y                   |
| [npm](../npm_registry/_index.md)                       | Y                   |
| [NuGet](../nuget_repository/_index.md)                 | Y                   |
| [PyPI](../pypi_repository/_index.md)                   | Y                   |
| [Generic packages](../generic_packages/_index.md)      | N                   |
| [Terraform](../terraform_module_registry/_index.md)    | N                   |
| [Composer](../composer_repository/_index.md)           | N                   |
| [Conan 1](../conan_1_repository/_index.md)             | N                   |
| [Conan 2](../conan_2_repository/_index.md)             | N                   |
| [Helm](../helm_repository/_index.md)                   | N                   |
| [Debian](../debian_repository/_index.md)               | N                   |
| [Go](../go_proxy/_index.md)                            | N                   |
| [Ruby gems](../rubygems_registry/_index.md)            | N                   |

## Allow or prevent duplicates

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

By default, the GitLab package registry either allows or prevents duplicates based on the default of that specific package manager format.

| Package type                                           | Duplicates allowed? |
|--------------------------------------------------------|---------------------|
| [Maven (with `mvn`)](../maven_repository/_index.md)    | Y (configurable)    |
| [Maven (with `gradle`)](../maven_repository/_index.md) | Y (configurable)    |
| [Maven (with `sbt`)](../maven_repository/_index.md)    | Y (configurable)    |
| [npm](../npm_registry/_index.md)                       | N                   |
| [NuGet](../nuget_repository/_index.md)                 | Y                   |
| [PyPI](../pypi_repository/_index.md)                   | N                   |
| [Generic packages](../generic_packages/_index.md)      | Y (configurable)    |
| [Terraform](../terraform_module_registry/_index.md)    | N                   |
| [Composer](../composer_repository/_index.md)           | N                   |
| [Conan 1](../conan_1_repository/_index.md)             | N                   |
| [Conan 2](../conan_2_repository/_index.md)             | N                   |
| [Helm](../helm_repository/_index.md)                   | Y                   |
| [Debian](../debian_repository/_index.md)               | Y                   |
| [Go](../go_proxy/_index.md)                            | N                   |
| [Ruby gems](../rubygems_registry/_index.md)            | Y                   |

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
