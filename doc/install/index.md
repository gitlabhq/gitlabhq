---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
comments: false
description: Read through the GitLab installation methods.
type: index
---

# Installation **(FREE SELF)**

GitLab can be installed in most GNU/Linux distributions, and with several
cloud providers. To get the best experience from GitLab, you must balance
performance, reliability, ease of administration (backups, upgrades, and
troubleshooting), and the cost of hosting.

## Requirements

Before you install GitLab, be sure to review the [system requirements](requirements.md).
The system requirements include details about the minimum hardware, software,
database, and additional requirements to support GitLab.

## Choose the installation method

Depending on your platform, select from the following available methods to
install GitLab:

| Installation method                                            | Description | When to choose |
|----------------------------------------------------------------|-------------|----------------|
| [Linux package](https://docs.gitlab.com/omnibus/installation/) | The official deb/rpm packages (also known as Omnibus GitLab) that contains a bundle of GitLab and the components it depends on, including PostgreSQL, Redis, and Sidekiq. | This is the recommended method for getting started. The Linux packages are mature, scalable, and are used today on GitLab.com. If you need additional flexibility and resilience, we recommend deploying GitLab as described in the [reference architecture documentation](../administration/reference_architectures/index.md). |
| [Helm charts](https://docs.gitlab.com/charts/)                 | The cloud native Helm chart for installing GitLab and all of its components on Kubernetes. | When installing GitLab on Kubernetes, there are some trade-offs that you need to be aware of: <br/>- Administration and troubleshooting requires Kubernetes knowledge.<br/>- It can be more expensive for smaller installations. The default installation requires more resources than a single node Linux package deployment, as most services are deployed in a redundant fashion.<br/>- There are some feature [limitations to be aware of](https://docs.gitlab.com/charts/#limitations).<br/><br/> Use this method if your infrastructure is built on Kubernetes and you're familiar with how it works. The methods for management, observability, and some concepts are different than traditional deployments. |
| [Docker](https://docs.gitlab.com/omnibus/docker/)              | The GitLab packages, Dockerized. | Use this method if you're familiar with Docker. |
| [Source](installation.md)                                      | Install GitLab and all of its components from scratch. | Use this method if none of the previous methods are available for your platform. Useful for unsupported systems like \*BSD.|
| [GitLab Environment Toolkit (GET)](https://gitlab.com/gitlab-org/quality/gitlab-environment-toolkit#documentation) | The GitLab Environment toolkit provides a set of automation tools to deploy a [reference architecture](../administration/reference_architectures/index.md) on most major cloud providers. | Customers are very welcome to trial and evaluate GET today, however be aware of [key limitations](https://gitlab.com/gitlab-org/quality/gitlab-environment-toolkit#missing-features-to-be-aware-of) of the current iteration. For production environments further manual setup will be required based on your specific requirements. |

## Install GitLab on cloud providers

Regardless of the installation method, you can install GitLab on several cloud
providers, assuming the cloud provider supports it. Here are several possible installation
methods, the majority which use the Linux packages:

| Cloud provider                                                | Description |
|---------------------------------------------------------------|-------------|
| [AWS (HA)](aws/index.md)                                      | Install GitLab on AWS using the community AMIs provided by GitLab. |
| [Google Cloud Platform (GCP)](google_cloud_platform/index.md) | Install GitLab on a VM in GCP. |
| [Azure](azure/index.md)                                       | Install GitLab from Azure Marketplace. |
| [DigitalOcean](https://about.gitlab.com/blog/2016/04/27/getting-started-with-gitlab-and-digitalocean/) | Install GitLab on DigitalOcean. You can also [test GitLab on DigitalOcean using Docker Machine](digitaloceandocker.md). |

## Next steps

After you complete the steps for installing GitLab, you can
[configure your instance](next_steps.md).
