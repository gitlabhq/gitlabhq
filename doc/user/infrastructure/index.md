---
stage: Deploy
group: Environments
description: Terraform and Kubernetes deployments.
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Manage your infrastructure

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

With the rise of DevOps and SRE approaches, infrastructure management becomes codified,
automatable, and software development best practices gain their place around infrastructure
management too. On one hand, the daily tasks of classical operations people changed
and are more similar to traditional software development. On the other hand, software engineers
are more likely to control their whole DevOps lifecycle, including deployments and delivery.

GitLab offers various features to speed up and simplify your infrastructure management practices.

## Infrastructure as Code

GitLab has deep integrations with Terraform to run Infrastructure as Code pipelines
and support various processes. Terraform is considered the standard in cloud infrastructure provisioning.
The various GitLab integrations help you:

- Get started quickly without any setup.
- Collaborate around infrastructure changes in merge requests the same as you might
  with code changes.
- Scale using a module registry.

For more information, see how GitLab can help you run [Infrastructure as Code](iac/index.md).

## Integrated Kubernetes management

The GitLab integration with Kubernetes helps you to install, configure, manage, deploy, and troubleshoot
cluster applications. With the GitLab agent, you can connect clusters behind a firewall,
have real-time access to API endpoints, perform pull-based or push-based deployments for production
and non-production environments, and much more.

For more information, see the [GitLab agent](../clusters/agent/index.md).

## Runbooks in GitLab

Runbooks are a collection of documented procedures that explain how to carry out a task,
such as starting, stopping, debugging, or troubleshooting a system.

Read more about [how executable runbooks work in GitLab](../project/clusters/runbooks/index.md).
