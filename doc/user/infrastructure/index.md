---
stage: Configure
group: Configure
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Infrastructure management **(FREE)**

With the rise of DevOps and SRE approaches, infrastructure management becomes codified,
automatable, and software development best practices gain their place around infrastructure
management too. On one hand, the daily tasks of classical operations people changed
and are more similar to traditional software development. On the other hand, software engineers
are more likely to control their whole DevOps lifecycle, including deployments and delivery.

GitLab offers various features to speed up and simplify your infrastructure management practices.

## Generic infrastructure management

GitLab has deep integrations with Terraform to run your infrastructure as code pipelines
and support your processes. Terraform is considered the standard in cloud infrastructure provisioning.
The various GitLab integrations help you:

- Get started quickly without any setup.
- Collaborate around infrastructure changes in merge requests the same as you might
  with code changes.
- Scale using a module registry.

Read more about the [Infrastructure as Code features](iac/index.md), including:

- [The GitLab Managed Terraform State](terraform_state.md).
- [The Terraform MR widget](mr_integration.md).
- [The Terraform module registry](../packages/terraform_module_registry/index.md).

## Integrated Kubernetes management

GitLab has special integrations with Kubernetes to help you deploy, manage and troubleshoot
third-party or custom applications in Kubernetes clusters. Auto DevOps provides a full
DevSecOps pipeline by default targeted at Kubernetes based deployments. To support
all the GitLab features, GitLab offers a cluster management project for easy onboarding.
The deploy boards provide quick insights into your cluster, including pod logs tailing.

The recommended approach to connect to a cluster is using [the GitLab Kubernetes Agent](../clusters/agent/index.md).

Read more about [the Kubernetes cluster support and integrations](../project/clusters/index.md), including:

- Certificate-based integration for [projects](../project/clusters/index.md),
  [groups](../group/clusters/index.md), or [instances](../instance/clusters/index.md).
- [Agent-based integration](../clusters/agent/index.md). **(PREMIUM)**
  - The [Kubernetes Agent Server](../../administration/clusters/kas.md) is [available on GitLab.com](../clusters/agent/index.md#set-up-the-kubernetes-agent-server)
    at `wss://kas.gitlab.com`. **(PREMIUM)**
- [Agent-based access from GitLab CI/CD](../clusters/agent/ci_cd_tunnel.md).

## Runbooks in GitLab

Runbooks are a collection of documented procedures that explain how to carry out a task,
such as starting, stopping, debugging, or troubleshooting a system.

Read more about [how executable runbooks work in GitLab](../project/clusters/runbooks/index.md).
