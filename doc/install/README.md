---
comments: false
description: Read through the GitLab installation methods.
type: index
---

# Installation **(CORE ONLY)**

GitLab can be installed in most GNU/Linux distributions and in a number
of cloud providers. To get the best experience from GitLab, you need to balance
performance, reliability, ease of administration (backups, upgrades and troubleshooting),
and cost of hosting.

There are many ways you can install GitLab depending on your platform:

1. **Omnibus GitLab**: The official deb/rpm packages that contain a bundle of GitLab
   and the various components it depends on like PostgreSQL, Redis, Sidekiq, etc.
1. **GitLab Helm chart**: The cloud native Helm chart for installing GitLab and all
   its components on Kubernetes.
1. **Docker**: The Omnibus GitLab packages dockerized.
1. **Source**: Install GitLab and all its components from scratch.

TIP: **If in doubt, choose Omnibus:**
The Omnibus GitLab packages are mature, scalable, support
[high availability](../administration/high_availability/README.md) and are used
today on GitLab.com. The Helm charts are recommended for those who are familiar
with Kubernetes.

## Requirements

Before installing GitLab, make sure to check the [requirements documentation](requirements.md)
which includes useful information on the supported Operating Systems as well as
the hardware requirements.

## Installing GitLab using the Omnibus GitLab package (recommended)

The Omnibus GitLab package uses our official deb/rpm repositories. This is
recommended for most users.

If you need additional flexibility and resilience, we recommend deploying
GitLab as described in our [High Availability documentation](../administration/high_availability/README.md).

[**> Install GitLab using the Omnibus GitLab package.**](https://about.gitlab.com/install/)

## Installing GitLab on Kubernetes via the GitLab Helm charts

NOTE: **Kubernetes experience required:**
We recommend being familiar with Kubernetes before using it to deploy GitLab in
production. The methods for management, observability, and some concepts are
different than traditional deployments.

When installing GitLab on Kubernetes, there are some trade-offs that you
need to be aware of:

- Administration and troubleshooting requires Kubernetes knowledge.
- It can be more expensive for smaller installations. The default installation
  requires more resources than a single node Omnibus deployment, as most services
  are deployed in a redundant fashion.
- There are some feature [limitations to be aware of](https://docs.gitlab.com/charts/#limitations).

[**> Install GitLab on Kubernetes using the GitLab Helm charts.**](https://docs.gitlab.com/charts/)

## Installing GitLab with Docker

GitLab maintains a set of official Docker images based on the Omnibus GitLab package.

[**> Install GitLab using the official GitLab Docker images.**](docker.md)

## Installing GitLab from source

If the GitLab Omnibus package is not available in your distribution, you can
install GitLab from source: Useful for unsupported systems like *BSD. For an
overview of the directory structure, read the [structure documentation](structure.md).

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

## Securing your GitLab installation

After completing your installation, check out our [recommended practices to secure your GitLab instance](../security/README.md#securing-your-gitlab-installation).
