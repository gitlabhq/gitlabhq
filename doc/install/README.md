---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
comments: false
description: Read through the GitLab installation methods.
type: index
---

# Installation **(CORE ONLY)**

GitLab can be installed in most GNU/Linux distributions and with several
cloud providers. To get the best experience from GitLab, you must balance
performance, reliability, ease of administration (backups, upgrades, and
troubleshooting), and the cost of hosting.

Depending on your platform, select from the following available methods to
install GitLab:

- [_Omnibus GitLab_](#installing-gitlab-using-the-omnibus-gitlab-package-recommended):
  The official deb/rpm packages that contain a bundle of GitLab and the
  components it depends on, including PostgreSQL, Redis, and Sidekiq.
- [_GitLab Helm chart_](#installing-gitlab-on-kubernetes-via-the-gitlab-helm-charts):
  The cloud native Helm chart for installing GitLab and all of its components
  on Kubernetes.
- [_Docker_](#installing-gitlab-with-docker): The Omnibus GitLab packages,
  dockerized.
- [_Source_](#installing-gitlab-from-source): Install GitLab and all of its
  components from scratch.
- [_Cloud provider_](#installing-gitlab-on-cloud-providers): Install directly
  from platforms like AWS, Azure, and GCP.

If you're not sure which installation method to use, we recommend you use
Omnibus GitLab. The Omnibus GitLab packages are mature,
[scalable](../administration/reference_architectures/index.md), and are used
today on GitLab.com. The Helm charts are recommended for those who are familiar
with Kubernetes.

## Requirements

Before you install GitLab, be sure to review the [system requirements](requirements.md).
The system requirements include details about the minimum hardware, software,
database, and additional requirements to support GitLab.

## Installing GitLab using the Omnibus GitLab package (recommended)

The Omnibus GitLab package uses our official deb/rpm repositories, and is
recommended for most users.

If you need additional flexibility and resilience, we recommend deploying
GitLab as described in our [reference architecture documentation](../administration/reference_architectures/index.md).

[**> Install GitLab using the Omnibus GitLab package.**](https://about.gitlab.com/install/)

## Installing GitLab on Kubernetes via the GitLab Helm charts

When installing GitLab on Kubernetes, there are some trade-offs that you
need to be aware of:

- Administration and troubleshooting requires Kubernetes knowledge.
- It can be more expensive for smaller installations. The default installation
  requires more resources than a single node Omnibus deployment, as most services
  are deployed in a redundant fashion.
- There are some feature [limitations to be aware of](https://docs.gitlab.com/charts/#limitations).

Due to these trade-offs, having Kubernetes experience is a requirement for
using this method. We recommend being familiar with Kubernetes before using it
to deploy GitLab in production. The methods for management, observability, and
some concepts are different than traditional deployments.

[**> Install GitLab on Kubernetes using the GitLab Helm charts.**](https://docs.gitlab.com/charts/)

## Installing GitLab with Docker

GitLab maintains a set of official Docker images based on the Omnibus GitLab
package.

[**> Install GitLab using the official GitLab Docker images.**](docker.md)

## Installing GitLab from source

If the Omnibus GitLab package is not available in your distribution, you can
install GitLab from source: Useful for unsupported systems like \*BSD. For an
overview of the directory structure, read the [structure documentation](installation.md#gitlab-directory-structure).

[**> Install GitLab from source.**](installation.md)

## Installing GitLab on cloud providers

GitLab can be installed on a variety of cloud providers by using any of
the above methods, provided the cloud provider supports it.

- [Install on AWS](aws/index.md): Install Omnibus GitLab on AWS using the community AMIs that GitLab provides.
- [Install GitLab on Google Cloud Platform](google_cloud_platform/index.md): Install Omnibus GitLab on a VM in GCP.
- [Install GitLab on Azure](azure/index.md): Install Omnibus GitLab from Azure Marketplace.
- [Install GitLab on OpenShift](https://docs.gitlab.com/charts/installation/cloud/openshift.html): Install GitLab on OpenShift by using GitLab's Helm charts.
- [Install GitLab on DC/OS](https://d2iq.com/blog/gitlab-dcos): Install GitLab on Mesosphere DC/OS via the [GitLab-Mesosphere integration](https://about.gitlab.com/blog/2016/09/16/announcing-gitlab-and-mesosphere/).
- [Install GitLab on DigitalOcean](https://about.gitlab.com/blog/2016/04/27/getting-started-with-gitlab-and-digitalocean/): Install Omnibus GitLab on DigitalOcean.
- _Testing only!_ [DigitalOcean and Docker Machine](digitaloceandocker.md):
  Quickly test any version of GitLab on DigitalOcean using Docker Machine.

## Next steps

Here are a few resources you might want to check out after completing the
installation:

- [Upload a license](../user/admin_area/license.md)  or [start a free trial](https://about.gitlab.com/free-trial/):
  Activate all GitLab Enterprise Edition functionality with a license.
- [Set up runners](https://docs.gitlab.com/runner/): Set up one or more GitLab
  Runners, the agents that are responsible for all of GitLab's CI/CD features.
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
- [Upgrade GitLab](../update/README.md): Every 22nd of the month, a new feature-rich GitLab version
  is released. Learn how to upgrade to it, or to an interim release that contains a security fix.
- [Scaling GitLab](../administration/reference_architectures/index.md):
  GitLab supports several different types of clustering.
- [Advanced Search](../integration/elasticsearch.md): Leverage Elasticsearch for
  faster, more advanced code search across your entire GitLab instance.
- [Geo replication](../administration/geo/index.md):
  Geo is the solution for widely distributed development teams.
- [Release and maintenance policy](../policy/maintenance.md): Learn about GitLab's
  policies governing version naming, as well as release pace for major, minor, patch,
  and security releases.
- [Pricing](https://about.gitlab.com/pricing/): Pricing for the different tiers.
