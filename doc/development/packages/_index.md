---
stage: Package
group: Package Registry
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Package and container registry development guidelines
---

The documentation for package and container registry development is split into two groups.

## Package registry development

Development and architectural documentation for the package registry:

- [Debian repository structure](debian_repository.md)
- [Developing a new format](new_format_development.md)
- [Settings](settings.md)
- [Structure / Schema](structure.md)
- API documentation
  - [Composer](../../api/packages/composer.md)
  - [Conan](../../api/packages/conan.md)
  - [Debian](../../api/packages/debian.md)
  - [Generic](../../user/packages/generic_packages/_index.md)
  - [Go Proxy](../../api/packages/go_proxy.md)
  - [Helm](../../api/packages/helm.md)
  - [Maven](../../api/packages/maven.md)
  - [npm](../../api/packages/npm.md)
  - [NuGet](../../api/packages/nuget.md)
  - [PyPI](../../api/packages/pypi.md)
  - [Ruby Gems](../../api/packages/rubygems.md)

## Container registry development

Development and architectural documentation for the container registry

- [Dependency proxy structure](dependency_proxy.md)
- [Settings](settings.md)
- [Structure / Schema](structure.md)
- [Cleanup policies](cleanup_policies.md)

## Harbor registry development

Development and architectural documentation for the harbor registry

- [Development documentation](harbor_registry_development.md)
