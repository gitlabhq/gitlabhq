---
stage: Systems
group: Distribution
description: Linux, Helm, Docker, Operator, source, or scripts.
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Installation methods

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** Self-managed

You can install GitLab on several [cloud providers](cloud_providers.md),
or use one of the following methods.

| Installation method                                            | Description | When to choose |
|----------------------------------------------------------------|-------------|----------------|
| [Linux package](https://docs.gitlab.com/omnibus/installation/) (previously known as Omnibus GitLab) | The official `deb` and `rpm` packages. The Linux package has GitLab and dependent components, including PostgreSQL, Redis, and Sidekiq. | Use if you want the most mature, scalable method. This version is also used on GitLab.com. <br>- For additional flexibility and resilience, see the [reference architecture documentation](../administration/reference_architectures/index.md).<br>- Review the [system requirements](requirements.md).<br>- View the [list of supported Linux operating systems](../administration/package_information/supported_os.md#supported-operating-systems). |
| [Helm chart](https://docs.gitlab.com/charts/)                 | A chart for installing a cloud-native version of GitLab and its components on Kubernetes. | Use if your infrastructure is on Kubernetes and you're familiar with how it works. Management, observability, and some concepts are different than traditional deployments.<br/>- Administration and troubleshooting requires Kubernetes knowledge.<br/>- It can be more expensive for smaller installations. The default installation requires more resources than a single node Linux package deployment, because most services are deployed in a redundant fashion.<br/><br/>  |
| [GitLab Operator](https://docs.gitlab.com/operator/)   | An installation and management method that follows the [Kubernetes Operator pattern](https://kubernetes.io/docs/concepts/extend-kubernetes/operator/) for installing a cloud-native version of GitLab and its components in Kubernetes. | Use if your infrastructure is on Kubernetes or [OpenShift](openshift_and_gitlab/index.md) and you're familiar with how Operators work. Provides additional functionality beyond the Helm chart installation method, including automation of the [GitLab upgrade steps](https://docs.gitlab.com/operator/gitlab_upgrades.html).<br/>- The considerations for the Helm chart also apply here.<br/>- Consider the Helm chart instead if you are limited by the [GitLab Operator's known issues](https://docs.gitlab.com/operator#known-issues). |
| [Docker](docker.md)              | The GitLab packages in a Docker container. | Use if you're familiar with Docker. |
| [Source](installation.md)                                      | GitLab and its components from scratch. | Use if none of the previous methods are available for your platform. Can use for unsupported systems like \*BSD.|
| [GitLab Environment Toolkit (GET)](https://gitlab.com/gitlab-org/gitlab-environment-toolkit#documentation) | A set of opinionated Terraform and Ansible scripts. | Use to deploy a [reference architecture](../administration/reference_architectures/index.md) on selected major cloud providers. Has some [limitations](https://gitlab.com/gitlab-org/gitlab-environment-toolkit#missing-features-to-be-aware-of) and manual setup for production environments. |

## Unsupported Linux distributions and Unix-like operating systems

- Arch Linux
- Fedora
- FreeBSD
- Gentoo
- macOS

Installation of GitLab on these operating systems is possible, but not supported.
See the [installation guides](https://about.gitlab.com/install/) for more information.

See [OS versions that are no longer supported](../administration/package_information/supported_os.md#os-versions-that-are-no-longer-supported)
for a list of supported and unsupported OS versions for Linux package installations as well as the last support GitLab version for that OS.

## Microsoft Windows

GitLab is developed for Linux-based operating systems.
It does **not** run on Microsoft Windows, and we have no plans to support it in the near future. For the latest development status, view this [issue](https://gitlab.com/gitlab-org/gitlab/-/issues/22337).
Consider using a virtual machine to run GitLab.
