---
stage: Package
group: Package
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Packages & Registries

The GitLab [Package Registry](package_registry/index.md) acts as a private or public registry
for a variety of common package managers. You can publish and share
packages, which can be easily consumed as a dependency in downstream projects.

The Package Registry supports the following formats:

<div class="row">
<div class="col-md-9">
<table align="left" style="width:50%">
<tr style="background:#dfdfdf"><th>Package type</th><th>GitLab version</th></tr>
<tr><td><a href="https://docs.gitlab.com/ee/user/packages/composer_repository/index.html">Composer</a></td><td>13.2+</td></tr>
<tr><td><a href="https://docs.gitlab.com/ee/user/packages/conan_repository/index.html">Conan</a></td><td>12.6+</td></tr>
<tr><td><a href="https://docs.gitlab.com/ee/user/packages/go_proxy/index.html">Go</a></td><td>13.1+</td></tr>
<tr><td><a href="https://docs.gitlab.com/ee/user/packages/maven_repository/index.html">Maven</a></td><td>11.3+</td></tr>
<tr><td><a href="https://docs.gitlab.com/ee/user/packages/npm_registry/index.html">NPM</a></td><td>11.7+</td></tr>
<tr><td><a href="https://docs.gitlab.com/ee/user/packages/nuget_repository/index.html">NuGet</a></td><td>12.8+</td></tr>
<tr><td><a href="https://docs.gitlab.com/ee/user/packages/pypi_repository/index.html">PyPI</a></td><td>12.10+</td></tr>
<tr><td><a href="https://docs.gitlab.com/ee/user/packages/generic_packages/index.html">Generic packages</a></td><td>13.5+</td></tr>
</table>
</div>
</div>

You can also use the [API](../../api/packages.md) to administer the Package Registry.

## Accepting contributions

The below table lists formats that are not supported, but are accepting Community contributions for. Consider contributing to GitLab. This [development documentation](../../development/packages.md) 
guides you through the process.

| Format | Status |
| ------ | ------ |
| Chef      | [#36889](https://gitlab.com/gitlab-org/gitlab/-/issues/36889) |
| CocoaPods | [#36890](https://gitlab.com/gitlab-org/gitlab/-/issues/36890) |
| Conda     | [#36891](https://gitlab.com/gitlab-org/gitlab/-/issues/36891) |
| CRAN      | [#36892](https://gitlab.com/gitlab-org/gitlab/-/issues/36892) |
| Debian    | [WIP: Merge Request](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/44746) |
| Opkg      | [#36894](https://gitlab.com/gitlab-org/gitlab/-/issues/36894) |
| P2        | [#36895](https://gitlab.com/gitlab-org/gitlab/-/issues/36895) |
| Puppet    | [#36897](https://gitlab.com/gitlab-org/gitlab/-/issues/36897) |
| RPM       | [#5932](https://gitlab.com/gitlab-org/gitlab/-/issues/5932) |
| RubyGems  | [#803](https://gitlab.com/gitlab-org/gitlab/-/issues/803) |
| SBT       | [#36898](https://gitlab.com/gitlab-org/gitlab/-/issues/36898) |
| Terraform | [WIP: Merge Request](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/18834) |
| Vagrant   | [#36899](https://gitlab.com/gitlab-org/gitlab/-/issues/36899) |

## Container Registry

The GitLab [Container Registry](container_registry/index.md) is a secure and private registry for container images. It's built on open source software and completely integrated within GitLab. Use GitLab CI/CD to create and publish images. Use the GitLab [API](../../api/container_registry.md) to manage the registry across groups and projects.

## Dependency Proxy

The [Dependency Proxy](dependency_proxy/index.md) is a local proxy for frequently-used upstream images and packages.
