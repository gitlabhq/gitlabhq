---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Package and container registry development guidelines

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
  - [Generic](../../user/packages/generic_packages/index.md)
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
