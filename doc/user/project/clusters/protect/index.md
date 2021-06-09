---
stage: Protect
group: Container Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Protecting your deployed applications **(FREE)**

GitLab makes it straightforward to protect applications deployed in [connected Kubernetes clusters](index.md).
These protections are available in the Kubernetes network layer and in the container itself. At
the network layer, the Container Network Security capabilities in GitLab provide basic firewall
functionality by leveraging Cilium NetworkPolicies to filter traffic going in and out of the cluster
and traffic between pods inside the cluster. Inside the container, Container Host Security provides
Intrusion Detection and Prevention capabilities that can monitor and block activity inside the
containers themselves.

## Capabilities

The following capabilities are available to protect deployed applications in Kubernetes:

- Container Network Security
  - [Overview](container_network_security/index.md)
  - [Installation guide](container_network_security/quick_start_guide.md)
- Container Host Security
  - [Overview](container_host_security/index.md)
  - [Installation guide](container_host_security/quick_start_guide.md)
