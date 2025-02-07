---
stage: SaaS Platforms
group: GitLab Dedicated
description: Get to know the GitLab Dedicated architecture through a series of diagrams.
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Dedicated architecture
---

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab Dedicated

This page provides a set of architectural documents and diagrams for GitLab Dedicated.

## High-level overview

The following diagram shows a high-level overview of the architecture for GitLab Dedicated,
where various AWS accounts managed by GitLab and customers are controlled by the Switchboard application.

![Diagram of a high-level overview of the GitLab Dedicated architecture.](img/high_level_architecture_diagram_v18_0.png)

When managing GitLab Dedicated tenant instances:

- Switchboard is responsible for managing global configuration shared between the AWS cloud providers, accessible by tenants.
- Amp is responsible for the interaction with the customer tenant accounts, such as configuring expected roles and policies, enabling the required services, and provisioning environments.

GitLab team members with edit access can update the [source](https://lucid.app/lucidchart/e0b6661c-6c10-43d9-8afa-1fe0677e060c/edit?page=0_0#) files for the diagram in Lucidchart.

## Tenant network

The customer tenant account is a single AWS cloud provider account. The single account provides full tenancy isolation, in its own VPC, and with its own resource quotas.

The cloud provider account is where a highly resilient GitLab installation resides, in its own isolated VPC. On provisioning, the customer tenant gets access to a High Availability (HA) GitLab primary site and a GitLab Geo secondary site.

![Diagram of GitLab-managed AWS accounts in an isolated VPC containing a highly resilient GitLab installation.](img/tenant_network_diagram_v18_0.png)

GitLab team members with edit access can update the [source](https://lucid.app/lucidchart/0815dd58-b926-454e-8354-c33fe3e7bff0/edit?invitationId=inv_a6b618ff-6c18-4571-806a-bfb3fe97cb12) files for the diagram in Lucidchart.

### Gitaly setup

GitLab Dedicated deploys Gitaly [in a sharded setup](../gitaly/_index.md#before-deploying-gitaly-cluster), not a Gitaly Cluster. In this setup:

- Customer repositories are spread across multiple virtual machines.
- GitLab manages [storage weights](../repository_storage_paths.md#configure-where-new-repositories-are-stored) on behalf of the customer.

### Geo setup

GitLab Dedicated leverages GitLab Geo for [disaster recovery](../../subscriptions/gitlab_dedicated/data_residency_and_high_availability.md#disaster-recovery).

Geo does not use an active-active failover configuration. For more information, see [Geo](../geo/_index.md).

### AWS PrivateLink connection (optional)

Optionally, private connectivity is available for your GitLab Dedicated instance, using [AWS PrivateLink](https://aws.amazon.com/privatelink/) as a connection gateway.

Both [inbound](../dedicated/configure_instance/network_security.md#inbound-private-link) and [outbound](../dedicated/configure_instance/network_security.md#outbound-private-link) private links are supported.

![Diagram of a GitLab-managed AWS VPC using AWS PrivateLink to connect with a customer-managed AWS VPC.](img/privatelink_diagram_v17_1.png)

GitLab team members with edit access can update the [source](https://lucid.app/lucidchart/933b958b-bfad-4898-a8ae-182815f159ca/edit?invitationId=inv_38b9a265-dff2-4db6-abdb-369ea1e92f5f) files for the diagram in Lucidchart.

## Hosted runners for GitLab Dedicated

The following diagram illustrates a GitLab-managed AWS account that contains GitLab runners, which are interconnected to a GitLab Dedicated instance, the public internet, and optionally a customer AWS account that uses AWS PrivateLink.

![Diagram of hosted Runners architecture for GitLab Dedicated.](img/hosted-runners-architecture_v17_3.png)

For more information on how runners authenticate and execute the job payload, see [runner execution flow](https://docs.gitlab.com/runner#runner-execution-flow).

GitLab team members with edit access can update the [source](https://lucid.app/lucidchart/0fb12de8-5236-4d80-9a9c-61c08b714e6f/edit?invitationId=inv_4a12e347-49e8-438e-a28f-3930f936defd) files for the diagram in Lucidchart.
