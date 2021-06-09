---
stage: Protect
group: Container Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Container Host Security **(FREE)**

Container Host Security in GitLab provides Intrusion Detection and Prevention capabilities that can
monitor and (optionally) block activity inside the containers themselves. This is done by leveraging
an integration with Falco to provide the monitoring capabilities and an integration with Pod
Security Policies and AppArmor to provide blocking capabilities.

## Overview

Container Host Security can be used to monitor and block activity inside a container as well as to
enforce security policies across the entire Kubernetes cluster. Falco profiles allow for users to
define the activity they want to monitor for and detect. Among other things, this can include system
log entries, process starts, file activity, and network ports opened. AppArmor is used to block any
undesired activity via AppArmor profiles. These profiles are loaded into the cluster when
referenced by Pod Security Policies.

By default, Container Host Security is deployed into the cluster in monitor mode only, with no
default profiles or rules running out-of-the-box. Activity monitoring and blocking begins only when
users define profiles for these technologies.

## Installation

See the [installation guide](quick_start_guide.md) for the recommended steps to install the
Container Host Security capabilities. This guide shows the recommended way of installing Container
Host Security through the Cluster Management Project. However, it's also possible to do a manual
installation through our Helm chart.

## Features

- Prevent containers from starting as root.
- Limit the privileges and system calls available to containers.
- Monitor system logs, process starts, files read/written/deleted, and network ports opened.
- Optionally block processes from starting or files from being read/written/deleted.

## Supported container orchestrators

Kubernetes v1.14+ is the only supported container orchestrator. OpenShift and other container
orchestrators aren't supported.

## Supported Kubernetes providers

The following cloud providers are supported:

- Amazon EKS
- Google GKE

Although Container Host Security may function on Azure or self-managed Kubernetes instances, it isn't
officially tested and supported on those providers.

## Roadmap

See the [Category Direction page](https://about.gitlab.com/direction/protect/container_host_security/)
for more information on the product direction of Container Host Security.
