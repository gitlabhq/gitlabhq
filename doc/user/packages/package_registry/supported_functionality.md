---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Supported package functionality

The GitLab Package Registry supports different functionalities for each package type. This support includes publishing
and pulling packages, request forwarding, managing duplicates, and authentication.

## Publishing packages **(FREE)**

Packages can be published to your project, group, or instance.

| Package type                                        | Project | Group | Instance |
|-----------------------------------------------------|---------|-------|----------|
| [Maven](../maven_repository/index.md)               | Y       | N     | N        |
| [npm](../npm_registry/index.md)                     | Y       | N     | N        |
| [NuGet](../nuget_repository/index.md)               | Y       | N     | N        |
| [PyPI](../pypi_repository/index.md)                 | Y       | N     | N        |
| [Generic packages](../generic_packages/index.md)    | Y       | N     | N        |
| [Terraform](../terraform_module_registry/index.md)  | Y       | N     | N        |
| [Composer](../composer_repository/index.md)         | N       | Y     | N        |
| [Conan](../conan_repository/index.md)               | Y       | N     | Y        |
| [Helm](../helm_repository/index.md)                 | Y       | N     | N        |
| [Debian](../debian_repository/index.md)             | Y       | N     | N        |
| [Go](../go_proxy/index.md)                          | Y       | N     | N        |
| [Ruby gems](../rubygems_registry/index.md)          | Y       | N     | N        |

## Pulling packages **(FREE)**

Packages can be pulled from your project, group, or instance.

| Package type                                        | Project | Group | Instance |
|-----------------------------------------------------|---------|-------|----------|
| [Maven](../maven_repository/index.md)               | Y       | Y     | Y        |
| [npm](../npm_registry/index.md)                     | Y       | N     | Y        |
| [NuGet](../nuget_repository/index.md)               | Y       | Y     | N        |
| [PyPI](../pypi_repository/index.md)                 | Y       | Y     | N        |
| [Generic packages](../generic_packages/index.md)    | Y       | N     | N        |
| [Terraform](../terraform_module_registry/index.md)  | N       | Y     | N        |
| [Composer](../composer_repository/index.md)         | Y       | Y     | N        |
| [Conan](../conan_repository/index.md)               | Y       | N     | Y        |
| [Helm](../helm_repository/index.md)                 | Y       | N     | N        |
| [Debian](../debian_repository/index.md)             | Y       | N     | N        |
| [Go](../go_proxy/index.md)                          | Y       | N     | Y        |
| [Ruby gems](../rubygems_registry/index.md)          | Y       | N     | N        |

## Forwarding requests **(PREMIUM)**

Requests for packages not found in your GitLab project are forwarded to the public registry. For example, Maven Central, npmjs, or PyPI.

| Package type                                        | Supports request forwarding |
|-----------------------------------------------------|-----------------------------|
| [Maven](../maven_repository/index.md)               | [Yes (disabled by default)](../../admin_area/settings/continuous_integration.md#maven-forwarding) |
| [npm](../npm_registry/index.md)                     | [Yes](../../admin_area/settings/continuous_integration.md#npm-forwarding) |
| [NuGet](../nuget_repository/index.md)               | N                           |
| [PyPI](../pypi_repository/index.md)                 | [Yes](../../admin_area/settings/continuous_integration.md#pypi-forwarding) |
| [Generic packages](../generic_packages/index.md)    | N                           |
| [Terraform](../terraform_module_registry/index.md)  | N                           |
| [Composer](../composer_repository/index.md)         | N                           |
| [Conan](../conan_repository/index.md)               | N                           |
| [Helm](../helm_repository/index.md)                 | N                           |
| [Debian](../debian_repository/index.md)             | N                           |
| [Go](../go_proxy/index.md)                          | N                           |
| [Ruby gems](../rubygems_registry/index.md)          | N                           |

### Deleting packages

When package requests are forwarded to a public registry, deleting packages can
be a [dependency confusion vulnerability](https://medium.com/@alex.birsan/dependency-confusion-4a5d60fec610).

If a system tries to pull a deleted package, the request is forwarded to the public
registry. If a package with the same name and version is found in the public registry, that package
is pulled instead. There is a risk that the package pulled from the registry might not be
what is expected, and could even be malicious.

To reduce the associated security risks, before deleting a package you can:

- Verify the package is not being actively used.
- Disable request forwarding:
  - Instance administrators can disable forwarding in the [**Continuous Integration** section](../../admin_area/settings/continuous_integration.md#package-registry-configuration) of the Admin Area.
  - Group owners can disable forwarding in the **Packages and Registries** section of the group settings.

## Allow or prevent duplicates **(FREE)**

By default, the GitLab package registry either allows or prevents duplicates based on the default of that specific package manager format.

| Package type                                        | Duplicates allowed? |
|-----------------------------------------------------|---------------------|
| [Maven](../maven_repository/index.md)               | Y (configurable)    |
| [npm](../npm_registry/index.md)                     | N                   |
| [NuGet](../nuget_repository/index.md)               | Y                   |
| [PyPI](../pypi_repository/index.md)                 | N                   |
| [Generic packages](../generic_packages/index.md)    | Y (configurable)    |
| [Terraform](../terraform_module_registry/index.md)  | N                   |
| [Composer](../composer_repository/index.md)         | N                   |
| [Conan](../conan_repository/index.md)               | N                   |
| [Helm](../helm_repository/index.md)                 | Y                   |
| [Debian](../debian_repository/index.md)             | Y                   |
| [Go](../go_proxy/index.md)                          | N                   |
| [Ruby gems](../rubygems_registry/index.md)          | Y                   |

## Authentication tokens **(FREE)**

GitLab tokens are used to authenticate with the GitLab Package Registry.

The following tokens are supported:

| Package type                                        | Supported tokens                                                       |
|-----------------------------------------------------|------------------------------------------------------------------------|
| [Maven](../maven_repository/index.md)               | Personal access, job tokens, deploy (project or group), project access |
| [npm](../npm_registry/index.md)                     | Personal access, job tokens, deploy (project or group), project access |
| [NuGet](../nuget_repository/index.md)               | Personal access, job tokens, deploy (project or group), project access |
| [PyPI](../pypi_repository/index.md)                 | Personal access, job tokens, deploy (project or group), project access |
| [Generic packages](../generic_packages/index.md)    | Personal access, job tokens, deploy (project or group), project access |
| [Terraform](../terraform_module_registry/index.md)  | Personal access, job tokens, deploy (project or group), project access |
| [Composer](../composer_repository/index.md)         | Personal access, job tokens, deploy (project or group), project access |
| [Conan](../conan_repository/index.md)               | Personal access, job tokens, project access                            |
| [Helm](../helm_repository/index.md)                 | Personal access, job tokens, deploy (project or group)                 |
| [Debian](../debian_repository/index.md)             | Personal access, job tokens, deploy (project or group)                 |
| [Go](../go_proxy/index.md)                          | Personal access, job tokens, project access                            |
| [Ruby gems](../rubygems_registry/index.md)          | Personal access, job tokens, deploy (project or group)                 |

## Authentication protocols **(FREE)**

The following authentication protocols are supported:

| Package type                                        | Supported auth protocols |
|-----------------------------------------------------|--------------------------|
| [Maven](../maven_repository/index.md)               | Headers                  |
| [npm](../npm_registry/index.md)                     | OAuth                    |
| [NuGet](../nuget_repository/index.md)               | Basic auth               |
| [PyPI](../pypi_repository/index.md)                 | Basic auth               |
| [Generic packages](../generic_packages/index.md)    | Basic auth               |
| [Terraform](../terraform_module_registry/index.md)  | Token                    |
| [Composer](../composer_repository/index.md)         | OAuth                    |
| [Conan](../conan_repository/index.md)               | OAuth, Basic auth        |
| [Helm](../helm_repository/index.md)                 | Basic auth               |
| [Debian](../debian_repository/index.md)             | Basic auth               |
| [Go](../go_proxy/index.md)                          | Basic auth               |
| [Ruby gems](../rubygems_registry/index.md)          | Token                    |

## Supported hash types **(FREE)**

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
