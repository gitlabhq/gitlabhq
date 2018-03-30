---
comments: false
---

# Installation

GitLab can be installed via various ways. Check the [installation methods][methods]
for an overview.

## Requirements

Before installing GitLab, make sure to check the [requirements documentation](requirements.md)
which includes useful information on the supported Operating Systems as well as
the hardware requirements.

## Installation methods

- [Installation using the Omnibus packages](https://about.gitlab.com/downloads/) -
  Install GitLab using our official deb/rpm repositories. This is the
  recommended way.
- [Installation from source](installation.md) - Install GitLab from source.
  Useful for unsupported systems like *BSD. For an overview of the directory
  structure, read the [structure documentation](structure.md).
- [Docker](docker.md) - Install GitLab using Docker.

## Install GitLab on cloud providers

- [Installing in Kubernetes](kubernetes/index.md): Install GitLab into a Kubernetes
  Cluster using our official Helm Chart Repository.
- [Install GitLab on OpenShift](openshift_and_gitlab/index.md)
- [Install GitLab on DC/OS](https://mesosphere.com/blog/gitlab-dcos/) via [GitLab-Mesosphere integration](https://about.gitlab.com/2016/09/16/announcing-gitlab-and-mesosphere/)
- [Install GitLab on Azure](azure/index.md)
- [Install GitLab on Google Cloud Platform](google_cloud_platform/index.md)
- [Install GitLab on Google Container Engine (GKE)](https://about.gitlab.com/2017/01/23/video-tutorial-idea-to-production-on-google-container-engine-gke/): video tutorial on
the full process of installing GitLab on Google Container Engine (GKE), pushing an application to GitLab, building the app with GitLab CI/CD, and deploying to production.
- [Install on AWS](https://about.gitlab.com/aws/)
- _Testing only!_ [DigitalOcean and Docker Machine](digitaloceandocker.md) -
  Quickly test any version of GitLab on DigitalOcean using Docker Machine.
- [GitLab Pivotal Tile](pivotal/index.md) - Install and configure GitLab
  Premium on Pivotal Cloud Foundry.
- [Getting started with GitLab and DigitalOcean](https://about.gitlab.com/2016/04/27/getting-started-with-gitlab-and-digitalocean/): requirements, installation process, updates.
- [Demo: Cloud Native Development with GitLab](https://about.gitlab.com/2017/04/18/cloud-native-demo/): video demonstration on how to install GitLab on Kubernetes, build a project, create Review Apps, store Docker images in Container Registry, deploy to production on Kubernetes, and monitor with Prometheus.

## Database

While the recommended database is PostgreSQL, we provide information to install
GitLab using MySQL. Check the [MySQL documentation](database_mysql.md) for more
information.

[methods]: https://about.gitlab.com/installation/
