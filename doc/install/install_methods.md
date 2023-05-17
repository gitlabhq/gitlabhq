---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Read through the GitLab installation methods.
type: index
---

# Installation methods **(FREE SELF)**

You can install GitLab on several [cloud providers](cloud_providers.md),
or use one of the following methods.

| Installation method                                            | Description | When to choose |
|----------------------------------------------------------------|-------------|----------------|
| [Linux package](https://docs.gitlab.com/omnibus/installation/) | The official deb/rpm packages (also known as Omnibus GitLab). The package has GitLab and dependent components, including PostgreSQL, Redis, and Sidekiq. | Use if you want the most mature, scalable method. This version is also used on GitLab.com. <br>- For additional flexibility and resilience, see the [reference architecture documentation](../administration/reference_architectures/index.md).<br>- Review the [system requirements](requirements.md).<br>- View the [list of supported Linux operating systems](../administration/package_information/supported_os.md#supported-operating-systems). |
| [Helm chart](https://docs.gitlab.com/charts/)                 | A chart for installing a cloud-native version of GitLab and its components on Kubernetes. | Use if your infrastructure is on Kubernetes and you're familiar with how it works. Management, observability, and some concepts are different than traditional deployments.<br/>- Administration and troubleshooting requires Kubernetes knowledge.<br/>- It can be more expensive for smaller installations. The default installation requires more resources than a single node Linux package deployment, because most services are deployed in a redundant fashion.<br/><br/>  |
| [Docker](docker.md)              | The GitLab packages in a Docker container. | Use if you're familiar with Docker. |
| [Source](installation.md)                                      | GitLab and its components from scratch. | Use if none of the previous methods are available for your platform. Can use for unsupported systems like \*BSD.|
| [GitLab Environment Toolkit (GET)](https://gitlab.com/gitlab-org/gitlab-environment-toolkit#documentation) | A set of automation tools. | Use to deploy a [reference architecture](../administration/reference_architectures/index.md) on most major cloud providers. Has some [limitations](https://gitlab.com/gitlab-org/gitlab-environment-toolkit#missing-features-to-be-aware-of) and manual setup for production environments. |
| [GitLab Operator](https://docs.gitlab.com/operator/)   | An installation and management method that follows the [Kubernetes Operator pattern](https://kubernetes.io/docs/concepts/extend-kubernetes/operator/). | Use to run GitLab in an [OpenShift](openshift_and_gitlab/index.md) environment. |

## Unsupported Linux distributions and Unix-like operating systems

- Arch Linux
- Fedora
- FreeBSD
- Gentoo
- macOS

Installation of GitLab on these operating systems is possible, but not supported.
See the [installation from source guide](installation.md) and the [installation guides](https://about.gitlab.com/install/) for more information.

See [OS versions that are no longer supported](../administration/package_information/supported_os.md#os-versions-that-are-no-longer-supported) for Omnibus installs page
for a list of supported and unsupported OS versions as well as the last support GitLab version for that OS.

## Microsoft Windows

GitLab is developed for Linux-based operating systems.
It does **not** run on Microsoft Windows, and we have no plans to support it in the near future. For the latest development status, view this [issue](https://gitlab.com/gitlab-org/gitlab/-/issues/22337).
Consider using a virtual machine to run GitLab.
