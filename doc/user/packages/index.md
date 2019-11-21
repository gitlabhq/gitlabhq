# GitLab Package Registry

GitLab Packages allows organizations to utilize GitLab as a private repository
for a variety of common package managers. Users are able to build and publish
packages, which can be easily consumed as a dependency in downstream projects.

The Packages feature allows GitLab to act as a repository for the following:

| Software repository | Description | Available in GitLab version |
| ------------------- | ----------- | --------------------------- |
| [Container Registry](container_registry/index.md)   | The GitLab Container Registry enables every project in GitLab to have its own space to store [Docker](https://www.docker.com/) images. | 8.8+ |
| [Dependency Proxy](dependency_proxy/index.md) **(PREMIUM)** | The GitLab Dependency Proxy sets up a local proxy for frequently used upstream images/packages. | 11.11+ |
| [Conan Repository](conan_repository/index.md) **(PREMIUM)** | The GitLab Conan Repository enables every project in GitLab to have its own space to store [Conan](https://conan.io/) packages. | 12.4+ |
| [Maven Repository](maven_repository/index.md) **(PREMIUM)** | The GitLab Maven Repository enables every project in GitLab to have its own space to store [Maven](https://maven.apache.org/) packages. | 11.3+ |
| [NPM Registry](npm_registry/index.md) **(PREMIUM)**  | The GitLab NPM Registry enables every project in GitLab to have its own space to store [NPM](https://www.npmjs.com/) packages. | 11.7+ |
| [NuGet Repository](https://gitlab.com/gitlab-org/gitlab/issues/20050) **(PREMIUM)**  | *COMING SOON* The GitLab NuGet Repository will enable every project in GitLab to have its own space to store [NuGet](https://www.nuget.org/) packages. | 12.7 (planned) |

TIP: **Tip:**
Don't you see your package management system supported yet? Consider contributing
to GitLab. This [development documentation](../../development/packages.md) will
guide you through the process. Or check out how other members of the commmunity
are adding support for [PHP](https://gitlab.com/gitlab-org/gitlab/merge_requests/17417) or [Terraform](https://gitlab.com/gitlab-org/gitlab/merge_requests/18834).

NOTE: **Note** We are especially interested in adding support for [PyPi](https://gitlab.com/gitlab-org/gitlab/issues/10483), [RubyGems](https://gitlab.com/gitlab-org/gitlab/issues/803), [Debian](https://gitlab.com/gitlab-org/gitlab/issues/5835), and [RPM](https://gitlab.com/gitlab-org/gitlab/issues/5932).
