---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Application Development Platform

The GitLab Application Development Platform refers to the set of GitLab features used to create, configure, and manage
a complete software development environment. It provides development, operations, and security teams with a robust feature set aimed at supporting best practices out of the box.

## Overview

The GitLab Application Development Platform aims to:

- Reduce and even eliminate the time it takes for an Operations team
  to provide a full environment for software developers.
- Get developers up and running fast so they can focus on writing
  great applications with a robust development feature set.
- Provide best-of-breed security features so that applications developed
  with GitLab are not affected by vulnerabilities that may lead to security
  problems and unintended use.

It is comprised of the following high-level elements:

1. Compute
1. Build, test, and deploy a wide range of applications
1. Security
1. Observability

We believe the use of these common building blocks equate to big gains for teams of all sizes, resulting from the adoption
of newer, more efficient, more profitable, and less error-prone techniques for shipping software applications.

### Compute

Because at GitLab we are [cloud-native first](https://about.gitlab.com/handbook/product/#cloud-native-first) our
Application Development Platform initially focuses on providing robust support for Kubernetes, with other platforms
to follow. Teams can bring their own clusters and we additionally make it easy to create new infrastructure
with various cloud providers.

### Build, test, deploy

In order to provide modern DevOps workflows, our Application Development Platform relies on
[Auto DevOps](../autodevops/index.md) to provide those workflows. Auto DevOps works with
any Kubernetes cluster; you're not limited to running on GitLab's infrastructure. Additionally, Auto DevOps offers
an incremental consumption path. Because it is [composable](../autodevops/customize.md#using-components-of-auto-devops),
you can use as much or as little of the default pipeline as you'd like, and deeply customize without having to integrate a completely different platform.

### Security

The Application Development Platform helps you ensure that the applications you create are not affected by vulnerabilities
that may lead to security problems and unintended use. This can be achieved by making use of the embedded security features of Auto DevOps,
which inform security teams and developers if there is something to consider changing in their apps
before it is too late to create a preventative fix. The following features are included:

- [Auto SAST (Static Application Security Testing)](../autodevops/stages.md#auto-sast)
- [Auto Dependency Scanning](../autodevops/stages.md#auto-dependency-scanning)
- [Auto Container Scanning](../autodevops/stages.md#auto-container-scanning)
- [Auto DAST (Dynamic Application Security Testing)](../autodevops/stages.md#auto-dast)

### Observability

Performance is a critical aspect of the user experience, and ensuring your application is responsive and available is everyone's
responsibility. The Application Development Platform integrates key performance analytics and feedback
into GitLab, automatically. The following features are included:

- [Auto Monitoring](../autodevops/stages.md#auto-monitoring)
- [In-app Kubernetes Logs](../../user/project/clusters/kubernetes_pod_logs.md)
