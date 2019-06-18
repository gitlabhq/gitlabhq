# Application Development Platform

The GitLab Application Development Platform refers to the set of GitLab features that can be used by operations teams to 
provide a full development environment to internal software development teams.

## Overview

The GitLab Application Development Platform aims to reduce and even eliminate the time it takes for an Operations team
to provide a full environment for software developers. It comprises the following high-level elements:

1. Compute
1. Build, test, and deploy a wide range of applications
1. Security
1. Observability

We believe the use of these common building blocks equate to big gains for teams of all sizes, resulting from the adoption
of newer, more efficient, more profitable, and less error-prone techniques for shipping software applications.

### Compute

Because at GitLab we are [cloud-native first](https://about.gitlab.com/handbook/product/#cloud-native-first) our
Application Development Platform initially focuses on providing robust support for Kubernetes, with other platforms
to follow. Teams can bring their own clusters and we will additionally make it easy to create new infrastructure
with various cloud providers.

### Build, test, deploy

In order to provide modern DevOps workflows, our Application Development Platform will rely on
[Auto DevOps](https://docs.gitlab.com/ee/topics/autodevops/) to provide those workflows. Auto DevOps works with 
any Kubernetes cluster; you're not limited to running on GitLab's infrastructure. Additionally, Auto DevOps offers 
an incremental consumption path. Because it is [composable](https://docs.gitlab.com/ee/topics/autodevops/#using-components-of-auto-devops),
you can use as much or as little of the default pipeline as you'd like, and deeply customize without having to integrate a completely different platform.

### Security

The Application Development Platform helps you ensure that the applications you create are not affected by vulnerabilities 
that may lead to security problems and unintended use. This can be achieved by making use of the embedded security features of Auto DevOps,
which inform security teams and developers if there is something to consider changing in their apps 
before it is too late to create a preventative fix. The following features are included:

- [Auto SAST (Static Application Security Testing)](https://docs.gitlab.com/ee/topics/autodevops/#auto-sast-ultimate)
- [Auto Dependency Scanning](https://docs.gitlab.com/ee/topics/autodevops/#auto-dependency-scanning-ultimate)
- [Auto Container Scanning](https://docs.gitlab.com/ee/topics/autodevops/#auto-container-scanning-ultimate)
- [Auto DAST (Dynamic Application Security Testing)](https://docs.gitlab.com/ee/topics/autodevops/#auto-dast-ultimate)

### Observability

Performance is a critical aspect of the user experience, and ensuring your application is responsive and available is everyone's
responsibility. The Application Development Platform integrates key performance analytics and feedback 
into GitLab, automatically. The following features are included:

- [Auto Monitoring](https://docs.gitlab.com/ee/topics/autodevops/#auto-monitoring)
- [In-app Kubernetes Pod Logs](https://docs.gitlab.com/ee/user/project/clusters/kubernetes_pod_logs.html)