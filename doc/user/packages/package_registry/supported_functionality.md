---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Supported package functionality
---

The GitLab package registry supports different functionalities for each package type. This support includes publishing
and pulling packages, request forwarding, managing duplicates, and authentication.

## Publishing packages

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

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
| [Conan](../conan_repository/_index.md)                 | Y       | N     | Y        |
| [Helm](../helm_repository/_index.md)                   | Y       | N     | N        |
| [Debian](../debian_repository/_index.md)               | Y       | N     | N        |
| [Go](../go_proxy/_index.md)                            | Y       | N     | N        |
| [Ruby gems](../rubygems_registry/_index.md)            | Y       | N     | N        |

## Pulling packages

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

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
| [Conan](../conan_repository/_index.md)                 | Y       | N     | Y        |
| [Helm](../helm_repository/_index.md)                   | Y       | N     | N        |
| [Debian](../debian_repository/_index.md)               | Y       | N     | N        |
| [Go](../go_proxy/_index.md)                            | Y       | N     | Y        |
| [Ruby gems](../rubygems_registry/_index.md)            | Y       | N     | N        |

## Forwarding requests

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Requests for packages not found in your GitLab project are forwarded to the public registry. For example, Maven Central, npmjs, or PyPI.

| Package type                                           | Supports request forwarding |
|--------------------------------------------------------|-----------------------------|
| [Maven (with `mvn`)](../maven_repository/_index.md)    | [Yes (disabled by default)](../../../administration/settings/continuous_integration.md#maven-forwarding) |
| [Maven (with `gradle`)](../maven_repository/_index.md) | [Yes (disabled by default)](../../../administration/settings/continuous_integration.md#maven-forwarding) |
| [Maven (with `sbt`)](../maven_repository/_index.md)    | [Yes (disabled by default)](../../../administration/settings/continuous_integration.md#maven-forwarding) |
| [npm](../npm_registry/_index.md)                       | [Yes](../../../administration/settings/continuous_integration.md#npm-forwarding) |
| [NuGet](../nuget_repository/_index.md)                 | N                           |
| [PyPI](../pypi_repository/_index.md)                   | [Yes](../../../administration/settings/continuous_integration.md#pypi-forwarding) |
| [Generic packages](../generic_packages/_index.md)      | N                           |
| [Terraform](../terraform_module_registry/_index.md)    | N                           |
| [Composer](../composer_repository/_index.md)           | N                           |
| [Conan](../conan_repository/_index.md)                 | N                           |
| [Helm](../helm_repository/_index.md)                   | N                           |
| [Debian](../debian_repository/_index.md)               | N                           |
| [Go](../go_proxy/_index.md)                            | N                           |
| [Ruby gems](../rubygems_registry/_index.md)            | N                           |

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
  - Instance administrators can disable forwarding in the [**Continuous Integration** section](../../../administration/settings/continuous_integration.md#package-registry-configuration) of the **Admin** area.
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
| [Conan](../conan_repository/_index.md)                 | N                   |
| [Helm](../helm_repository/_index.md)                   | N                   |
| [Debian](../debian_repository/_index.md)               | N                   |
| [Go](../go_proxy/_index.md)                            | N                   |
| [Ruby gems](../rubygems_registry/_index.md)            | N                   |

## Allow or prevent duplicates

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

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
| [Conan](../conan_repository/_index.md)                 | N                   |
| [Helm](../helm_repository/_index.md)                   | Y                   |
| [Debian](../debian_repository/_index.md)               | Y                   |
| [Go](../go_proxy/_index.md)                            | N                   |
| [Ruby gems](../rubygems_registry/_index.md)            | Y                   |

## Authentication tokens

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

GitLab tokens are used to authenticate with the GitLab package registry.

The following tokens are supported:

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
| [Conan](../conan_repository/_index.md)                 | Personal access, job tokens, project access                            |
| [Helm](../helm_repository/_index.md)                   | Personal access, job tokens, deploy (project or group)                 |
| [Debian](../debian_repository/_index.md)               | Personal access, job tokens, deploy (project or group)                 |
| [Go](../go_proxy/_index.md)                            | Personal access, job tokens, project access                            |
| [Ruby gems](../rubygems_registry/_index.md)            | Personal access, job tokens, deploy (project or group)                 |

## Authentication protocols

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

The following authentication protocols are supported:

| Package type                                           | Supported auth protocols                                    |
|--------------------------------------------------------|-------------------------------------------------------------|
| [Maven (with `mvn`)](../maven_repository/_index.md)    | Headers, Basic auth                                         |
| [Maven (with `gradle`)](../maven_repository/_index.md) | Headers, Basic auth                                         |
| [Maven (with `sbt`)](../maven_repository/_index.md)    | Basic auth ([pulling](#pulling-packages) only) (1)          |
| [npm](../npm_registry/_index.md)                       | OAuth                                                       |
| [NuGet](../nuget_repository/_index.md)                 | Basic auth                                                  |
| [PyPI](../pypi_repository/_index.md)                   | Basic auth                                                  |
| [Generic packages](../generic_packages/_index.md)      | Basic auth                                                  |
| [Terraform](../terraform_module_registry/_index.md)    | Token                                                       |
| [Composer](../composer_repository/_index.md)           | OAuth                                                       |
| [Conan](../conan_repository/_index.md)                 | OAuth, Basic auth                                           |
| [Helm](../helm_repository/_index.md)                   | Basic auth                                                  |
| [Debian](../debian_repository/_index.md)               | Basic auth                                                  |
| [Go](../go_proxy/_index.md)                            | Basic auth                                                  |
| [Ruby gems](../rubygems_registry/_index.md)            | Token                                                       |

1. Basic authentication for Maven packages [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/212854) in GitLab 16.0.

## Supported hash types

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

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
| [Conan](../conan_repository/_index.md)                 | MD5, SHA1                        |
| [Helm](../helm_repository/_index.md)                   | not applicable                   |
| [Debian](../debian_repository/_index.md)               | MD5, SHA1, SHA256                |
| [Go](../go_proxy/_index.md)                            | MD5, SHA1, SHA256                |
| [Ruby gems](../rubygems_registry/_index.md)            | MD5, SHA1, SHA256 (gemspec only) |
