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
| [GitLab Environment Toolkit (GET)](https://gitlab.com/gitlab-org/quality/gitlab-environment-toolkit#documentation) | The GitLab Environment toolkit provides a set of automation tools to deploy a [reference architecture](../administration/reference_architectures/index.md) on most major cloud providers. | Since GET is in beta and not yet recommended for production use, use this method if you want to test deploying GitLab in scalable environment. |

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

Here are a few resources you might want to check out after completing the
installation:

- [Upload a license](../user/admin_area/license.md) or [start a free trial](https://about.gitlab.com/free-trial/):
  Activate all GitLab Enterprise Edition functionality with a license.
- [Set up runners](https://docs.gitlab.com/runner/): Set up one or more GitLab
  Runners, the agents that are responsible for all of the GitLab CI/CD features.
- [GitLab Pages](../administration/pages/index.md): Configure GitLab Pages to
  allow hosting of static sites.
- [GitLab Registry](../administration/packages/container_registry.md): With the
  GitLab Container Registry, every project can have its own space to store Docker
  images.
- [Secure GitLab](../security/README.md#securing-your-gitlab-installation):
  Recommended practices to secure your GitLab instance.
- [SMTP](https://docs.gitlab.com/omnibus/settings/smtp.html): Configure SMTP
  for proper email notifications support.
- [LDAP](../administration/auth/ldap/index.md): Configure LDAP to be used as
  an authentication mechanism for GitLab.
- [Back up and restore GitLab](../raketasks/backup_restore.md): Learn the different
  ways you can back up or restore GitLab.
- [Upgrade GitLab](../update/index.md): Every 22nd of the month, a new feature-rich GitLab version
  is released. Learn how to upgrade to it, or to an interim release that contains a security fix.
- [Scaling GitLab](../administration/reference_architectures/index.md):
  GitLab supports several different types of clustering.
- [Advanced Search](../integration/elasticsearch.md): Leverage Elasticsearch for
  faster, more advanced code search across your entire GitLab instance.
- [Geo replication](../administration/geo/index.md):
  Geo is the solution for widely distributed development teams.
- [Release and maintenance policy](../policy/maintenance.md): Learn about GitLab
  policies governing version naming, as well as release pace for major, minor, patch,
  and security releases.
- [Pricing](https://about.gitlab.com/pricing/): Pricing for the different tiers.
