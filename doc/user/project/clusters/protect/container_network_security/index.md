---
stage: Protect
group: Container Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Container Network Security **(FREE)**

Container Network Security in GitLab provides basic firewall functionality by leveraging Cilium
NetworkPolicies to filter traffic going in and out of the cluster as well as traffic between pods
inside the cluster. Container Network Security can be used to enforce L3, L4, and L7 policies and
can prevent an attacker with control over one pod from spreading laterally to access other pods in
the same cluster. Both Ingress and Egress rules are supported.

By default, Cilium is deployed in Detection-only mode and only logs attack attempts. GitLab provides
a set of out-of-the-box policies as examples and to help users get started. These policies are
disabled by default, as they must usually be customized to match application-specific needs.

## Installation

See the [installation guide](quick_start_guide.md) for the recommended steps to install GitLab
Container Network Security. This guide shows the recommended way of installing Container Network
Security through the Cluster Management Project. However, it's also possible to install Cilium
manually through our Helm chart.

## Features

- GitLab managed installation of Cilium.
- Support for L3, L4, and L7 policies.
- Ability to export logs to a SIEM.
- Statistics page showing volume of packets processed and dropped over time (Ultimate users only).
- Management of NetworkPolicies through code in a project (Available for auto DevOps users only).
- Management of CiliumNetworkPolicies through a UI policy manager (Ultimate users only).

## Supported container orchestrators

Kubernetes v1.14+ is the only supported container orchestrator. OpenShift and other container
orchestrators aren't supported.

## Supported Kubernetes providers

The following cloud providers are supported:

- Amazon EKS
- Google GKE

Although Container Network Security may function on Azure or self-managed Kubernetes instances, it
isn't officially tested and supported on those providers.

## Supported NetworkPolicies

GitLab only supports the use of CiliumNetworkPolicies. Although generic Kubernetes NetworkPolicies
or other kinds of NetworkPolicies may work, GitLab doesn't test or support them.

## Managing NetworkPolicies through GitLab vs your cloud provider

Some cloud providers offer integrations with Cilium or offer other ways to manage NetworkPolicies in
Kubernetes. GitLab Container Network Security doesn't support deployments that have NetworkPolicies
managed by an external provider. By choosing to manage NetworkPolicies through GitLab, you can take
advantage of the following benefits:

- Support for handling NetworkPolicy infrastructure as code.
- Full revision history and audit log of all changes made.
- Ability to revert back to a previous version at any time.

## Roadmap

See the [Category Direction page](https://about.gitlab.com/direction/protect/container_network_security/)
for more information on the product direction of Container Network Security.
