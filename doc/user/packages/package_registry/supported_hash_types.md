---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Supported hash types **(FREE)**

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
