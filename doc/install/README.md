---
comments: false
description: Read through the GitLab installation methods.
---

# Installation

GitLab can be installed in most GNU/Linux distributions and in a number
of cloud providers.

## Requirements

Before installing GitLab, make sure to check the [requirements documentation](requirements.md)
which includes useful information on the supported Operating Systems as well as
the hardware requirements.

## Installation methods

To get the best experience from GitLab you need to balance:

1. Performance
1. Reliability
1. Ease of administration (backups, upgrades and troubleshooting)
1. Cost of hosting

TIP: **If in doubt, choose Omnibus:**
Our Omnibus GitLab packages are mature, scalable, support
[high availability](../administration/high_availability/README.md) and are used
today on GitLab.com. Our Helm charts are recommended for those who are familiar
with Kubernetes.

### Install GitLab using the Omnibus GitLab package (recommended)

This installation method [uses the Omnibus GitLab package](https://about.gitlab.com/install/),
using our official deb/rpm repositories. This is the recommended way.

If you need additional flexibility and resilience, we recommend deploying
GitLab as described in our [High Availability documentation](../administration/high_availability/README.md).

### Alternative to Omnibus GitLab

If the GitLab Omnibus package is not available in your distribution, you can
choose between:

- [Installation from source](installation.md): Install GitLab from source.
  Useful for unsupported systems like *BSD. For an overview of the directory
  structure, read the [structure documentation](structure.md).
  While the recommended database is PostgreSQL, we provide information to install
  GitLab [using MySQL](database_mysql.md).
- [Docker](docker.md): Install Omnibus GitLab using Docker.

### Install GitLab on Kubernetes via the GitLab Helm charts

NOTE: **If in doubt, choose Omnibus:**
We recommend being familiar with Kubernetes before using it to deploy GitLab in
production. The methods for management, observability, and some concepts are
different than traditional deployments.

GitLab is committed to Kubernetes as a foundational technology. There are three
areas where Kubernetes intersects with GitLab:

1. Deploying your applications from GitLab projects to Kubernetes (e.g., see [Auto DevOps](../topics/autodevops/index.md)).
1. [Running GitLab CI/CD Runners in a Kubernetes Cluster](https://docs.gitlab.com/runner/install/kubernetes.html).
1. Installing GitLab in Kubernetes.

While we recommend using GitLab for the first two points above, for most scenarios
we do not currently recommend installing GitLab in Kubernetes. There are a number
of trade-offs that you need to be aware of that may not be immediately obvious
and could prevent you getting the best experience from GitLab:

- Configuration of features such as object storage and backups can be more challenging.
- Administration and troubleshooting requires Kubernetes knowledge.
- It can be more expensive for smaller installations. The default installation
  requires more resources than a single node Omnibus deployment, as most services
  are deployed in a redundant fashion.
- There are some feature [limitations to be aware of](kubernetes/gitlab_chart.md#limitations).

If you're happy with the trade-offs, you can use our official Helm charts to get
started and [install GitLab in Kubernetes](kubernetes/index.md).

### Install GitLab on cloud providers

GitLab can be installed on a variety of cloud providers:

- [Install on AWS](aws/index.md): Install GitLab on AWS using the community AMIs that GitLab provides.
- [Install GitLab on Google Cloud Platform](google_cloud_platform/index.md)
- [Install GitLab on Azure](azure/index.md)
- [Install GitLab on OpenShift](openshift_and_gitlab/index.md)
- [Install GitLab on DC/OS](https://mesosphere.com/blog/gitlab-dcos/) via [GitLab-Mesosphere integration](https://about.gitlab.com/2016/09/16/announcing-gitlab-and-mesosphere/)
- [Install GitLab on Google Kubernetes Engine (GKE)](https://about.gitlab.com/2017/01/23/video-tutorial-idea-to-production-on-google-container-engine-gke/): video tutorial on
the full process of installing GitLab on Google Kubernetes Engine (GKE), pushing an application to GitLab, building the app with GitLab CI/CD, and deploying to production.
- [Getting started with GitLab and DigitalOcean](https://about.gitlab.com/2016/04/27/getting-started-with-gitlab-and-digitalocean/): requirements, installation process, updates.
- [Demo: Cloud Native Development with GitLab](https://about.gitlab.com/2017/04/18/cloud-native-demo/): video demonstration on how to install GitLab on Kubernetes, build a project, create Review Apps, store Docker images in Container Registry, deploy to production on Kubernetes, and monitor with Prometheus.
- _Testing only!_ [DigitalOcean and Docker Machine](digitaloceandocker.md):
  Quickly test any version of GitLab on DigitalOcean using Docker Machine.
