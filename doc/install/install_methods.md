---
stage: Systems
group: Distribution
description: Linux, Helm, Docker, Operator, source, or scripts.
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Installation methods
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

You can install GitLab on several [cloud providers](cloud_providers.md),
or use one of the following methods.

## Linux package

The Linux package includes the official `deb` and `rpm` packages. The package has GitLab and dependent components, including PostgreSQL, Redis, and Sidekiq.

Use if you want the most mature, scalable method. This version is also used on GitLab.com.

For more information, see:

- [Linux package](https://docs.gitlab.com/omnibus/installation/)
- [Reference architectures](../administration/reference_architectures/_index.md)
- [System requirements](requirements.md)
- [Supported Linux operating systems](../administration/package_information/supported_os.md)

## Helm chart

Use a chart to install a cloud-native version of GitLab and its components on Kubernetes.

Use if your infrastructure is on Kubernetes and you're familiar with how it works.

Before you use this installation method, consider that:

- Management, observability, and some other concepts are different than traditional deployments.
- Administration and troubleshooting requires Kubernetes knowledge.
- It can be more expensive for smaller installations.
- The default installation requires more resources than a single node Linux package deployment, because most services are deployed in a redundant fashion.

For more information, see [Helm charts](https://docs.gitlab.com/charts/).

## GitLab Operator

To install a cloud-native version of GitLab and its components in Kubernetes, use GitLab Operator.
This installation and management method follows the [Kubernetes Operator pattern](https://kubernetes.io/docs/concepts/extend-kubernetes/operator/).

Use if your infrastructure is on Kubernetes or [OpenShift](openshift_and_gitlab/_index.md), and you're familiar with how Operators work.

This installation method provides additional functionality beyond the Helm chart installation method, including automation of the [GitLab upgrade steps](https://docs.gitlab.com/operator/gitlab_upgrades.html). The considerations for the Helm chart also apply here.

Consider the Helm chart installation method if you are limited by [GitLab Operator known issues](https://docs.gitlab.com/operator/#known-issues).

For more information, see [GitLab Operator](https://docs.gitlab.com/operator/).

## Docker

Installs the GitLab packages in a Docker container.

Use if you're familiar with Docker.

For more information, see [Docker](docker/_index.md).

## Source

Installs GitLab and its components from scratch.

Use if none of the previous methods are available for your platform. Can use for unsupported systems like \*BSD.

For more information, see [Source](installation.md).

## GitLab Environment Toolkit (GET)

[GitLab Environment Toolkit (GET)](https://gitlab.com/gitlab-org/gitlab-environment-toolkit#documentation) is a set of opinionated Terraform and Ansible scripts.

Use to deploy a [reference architecture](../administration/reference_architectures/_index.md) on selected major cloud providers.

This installation methods has some [limitations](https://gitlab.com/gitlab-org/gitlab-environment-toolkit#missing-features-to-be-aware-of), and requires manual setup for production environments.

## Unsupported Linux distributions and Unix-like operating systems

- Arch Linux
- Fedora
- FreeBSD
- Gentoo
- macOS

Installation of GitLab on these operating systems is possible, but not supported.

For more information, see:

- [Installation guides](https://about.gitlab.com/install/)
- [Supported and unsupported OS versions for Linux package installations](../administration/package_information/supported_os.md#os-versions-that-are-no-longer-supported)

## Microsoft Windows

GitLab is developed for Linux-based operating systems.
It does **not** run on Microsoft Windows, and we have no plans to support it in the near future. For the latest development status, view this [issue](https://gitlab.com/gitlab-org/gitlab/-/issues/22337).
Consider using a virtual machine to run GitLab.
