---
description: 'Read through the different methods to deploy GitLab on Kubernetes.'
---

# Installing GitLab on Kubernetes

NOTE: **Kubernetes experience required:**
Our Helm charts are recommended for those who are familiar with Kubernetes.
If you're not sure if Kubernetes is for you, our
[Omnibus GitLab packages](../README.md#installing-gitlab-using-the-omnibus-gitlab-package-recommended)
are mature, scalable, support [high availability](../../administration/high_availability/README.md)
and are used today on GitLab.com.
It is not necessary to have GitLab installed on Kubernetes in order to use [GitLab Kubernetes integration](https://docs.gitlab.com/ee/user/project/clusters/index.html). 

The easiest method to deploy GitLab on [Kubernetes](https://kubernetes.io/) is
to take advantage of GitLab's Helm charts. [Helm](https://github.com/kubernetes/helm/blob/master/README.md)
is a package management tool for Kubernetes, allowing apps to be easily managed via their
Charts. A [Chart](https://github.com/kubernetes/charts) is a detailed description
of the application including how it should be deployed, upgraded, and configured.

## GitLab Chart

This chart contains all the required components to get started, and can scale to
large deployments. It offers a number of benefits, among others:

- Horizontal scaling of individual components.
- No requirement for shared storage to scale.
- Containers do not need `root` permissions.
- Automatic SSL with Let's Encrypt.
- An unprivileged GitLab Runner.

Learn more about the [GitLab chart](https://docs.gitlab.com/charts/).

## GitLab Runner Chart

If you already have a GitLab instance running, inside or outside of Kubernetes,
and you'd like to leverage the Runner's
[Kubernetes capabilities](https://docs.gitlab.com/runner/executors/kubernetes.html),
it can be deployed with the GitLab Runner chart.

Learn more about the [GitLab Runner chart](https://docs.gitlab.com/runner/install/kubernetes.html).
