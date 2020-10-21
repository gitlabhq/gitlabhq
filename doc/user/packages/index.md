---
stage: Package
group: Package
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
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

The GitLab [Container Registry](container_registry/index.md) is a secure and private registry for container images.
It's built on open source software and completely integrated within GitLab.
Use GitLab CI/CD to create and publish images. Use the GitLab [API](../../api/container_registry.md) to
manage the registry across groups and projects.

The [Dependency Proxy](dependency_proxy/index.md) is a local proxy for frequently-used upstream images and packages.

## Suggested contributions

Consider contributing to GitLab. This [development documentation](../../development/packages.md) will
guide you through the process. Or check out how other members of the community
are adding support for [PHP](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/17417) or [Terraform](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/18834).

| Format | Use case |
| ------ | ------ |
| [Cargo](https://gitlab.com/gitlab-org/gitlab/-/issues/33060) | Cargo is the Rust package manager. Build, publish and share Rust packages  |
| [Chef](https://gitlab.com/gitlab-org/gitlab/-/issues/36889) | Configuration management with Chef using all the benefits of a repository manager. |
| [CocoaPods](https://gitlab.com/gitlab-org/gitlab/-/issues/36890) | Speed up development with Xcode and CocoaPods. |
| [Conda](https://gitlab.com/gitlab-org/gitlab/-/issues/36891) | Secure and private local Conda repositories. |
| [CRAN](https://gitlab.com/gitlab-org/gitlab/-/issues/36892) | Deploy and resolve CRAN packages for the R language. |
| [Debian](https://gitlab.com/gitlab-org/gitlab/-/issues/5835) | Host and provision Debian packages. |
| [Opkg](https://gitlab.com/gitlab-org/gitlab/-/issues/36894) | Optimize your work with OpenWrt using Opkg repositories. |
| [P2](https://gitlab.com/gitlab-org/gitlab/-/issues/36895) | Host all your Eclipse plugins in your own GitLab P2 repository. |
| [Puppet](https://gitlab.com/gitlab-org/gitlab/-/issues/36897) | Configuration management meets repository management with Puppet repositories. |
| [RPM](https://gitlab.com/gitlab-org/gitlab/-/issues/5932) | Distribute RPMs directly from GitLab. |
| [RubyGems](https://gitlab.com/gitlab-org/gitlab/-/issues/803) | Use GitLab to host your own gems. |
| [SBT](https://gitlab.com/gitlab-org/gitlab/-/issues/36898) | Resolve dependencies from and deploy build output to SBT repositories when running SBT builds. |
| [Vagrant](https://gitlab.com/gitlab-org/gitlab/-/issues/36899) | Securely host your Vagrant boxes in local repositories. |
