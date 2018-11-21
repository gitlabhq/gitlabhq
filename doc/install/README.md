---
comments: false
description: Read through the GitLab installation methods.
---

# Installation

## Requirements

Before installing GitLab, make sure to check the [requirements documentation](install/requirements.md)
which includes useful information on the supported Operating Systems as well as
the hardware requirements.

## Installation methods

### Choose the best installation method for your needs

To get the best experience from GitLab you need to balance:

1. performance
1. reliability
1. ease of administration (backups, upgrades and troubleshooting)
1. cost of hosting

TIP: **If in doubt, choose Omnibus:**
For nearly all GitLab installations we recommend using an Omnibus package **GitLab can support up to 40,000 users on a single box Omnibus installation** with enough CPU and RAM. (See [requirements documentation](install/requirements.md))

### Omnibus (recommended)

- [Installation using the Omnibus packages](https://about.gitlab.com/downloads/) -
  Install GitLab using our official deb/rpm repositories. This is the
  recommended way.

If you need additional flexibility and resilience you can scale GitLab Omnibus as described in our [Scaling and High Availability docs](administration/high_availability/README.md).

### Alternative Omnibus 

- [Installation from source](installation.md) - Install GitLab from source.
  Useful for unsupported systems like *BSD. For an overview of the directory
  structure, read the [structure documentation](structure.md).
- [Docker](docker.md) - Install GitLab Omnibus using Docker.

### Kubernetes via GitLab Helm charts

CAUTION: **If in doubt, choose Omnibus:**
Installing GitLab in Kubernetes is not currently recommended unless you're experienced with Kubernetes and you know why you need GitLab to be installed in Kubernetes.

GitLab is committed to Kubernetes as a foundational technology. There are three areas where Kubernetes intersects with GitLab:

1. Deploying your applications from GitLab projects to Kubernetes (e.g. see [Auto DevOps](autodevops/index.md))
1. [Running GitLab CI Runners in a Kubernetes Cluster](runner/install/kubernetes.md)
1. Installing GitLab in Kubernetes

While we recommend using GitLab for the first two points above, for most scenarios we do not currently recommend installing GitLab in Kubernetes. There are a number of trade-offs that you need to be aware of that may not be immediately obvious and could prevent you getting the best experience from GitLab:

1. Configuration of features such as object storage, backups and certificates can be more challenging
1. Administration and troubleshooting requires Kubernetes knowledge
1. It can be more expensive for smaller installations. You need multiple nodes for a basic installation when a single box Omnibus installation would work well
1. There are some feature [limitations to be aware of](install/kubernetes/gitlab_chart.md#limitations)

 Unless you are experienced with Kubernetes and have a very large user-base (thousands of users) we recommend an Omnibus installation at this time.

 Over time Kubernetes will mature, hosting options will improve, and GitLab Helm charts and documentation will be refined in production environments.  We'll update our recommendations as conditions change.

If you're happy with the trade-offs, you can use our official Helm charts to get started with GitLab on Kubernetes:

- [Install in Kubernetes](kubernetes/index.md): Install GitLab into a Kubernetes
  Cluster using our official Helm Chart Repository.

### Guides to install GitLab on cloud providers

- [Install on AWS](aws/index.md): Install GitLab on AWS using the community AMIs that GitLab provides.
- [Install GitLab on Google Cloud Platform](google_cloud_platform/index.md)
- [Install GitLab on Azure](azure/index.md)
- [Install GitLab on OpenShift](openshift_and_gitlab/index.md)
- [Install GitLab on DC/OS](https://mesosphere.com/blog/gitlab-dcos/) via [GitLab-Mesosphere integration](https://about.gitlab.com/2016/09/16/announcing-gitlab-and-mesosphere/)
- [Install GitLab on Google Kubernetes Engine (GKE)](https://about.gitlab.com/2017/01/23/video-tutorial-idea-to-production-on-google-container-engine-gke/): video tutorial on
the full process of installing GitLab on Google Kubernetes Engine (GKE), pushing an application to GitLab, building the app with GitLab CI/CD, and deploying to production.
- [Getting started with GitLab and DigitalOcean](https://about.gitlab.com/2016/04/27/getting-started-with-gitlab-and-digitalocean/): requirements, installation process, updates.
- [Demo: Cloud Native Development with GitLab](https://about.gitlab.com/2017/04/18/cloud-native-demo/): video demonstration on how to install GitLab on Kubernetes, build a project, create Review Apps, store Docker images in Container Registry, deploy to production on Kubernetes, and monitor with Prometheus.
- _Testing only!_ [DigitalOcean and Docker Machine](digitaloceandocker.md) -
  Quickly test any version of GitLab on DigitalOcean using Docker Machine.

## Database

While the recommended database is PostgreSQL, we provide information to install
GitLab using MySQL. Check the [MySQL documentation](database_mysql.md) for more
information.

[methods]: https://about.gitlab.com/installation/
