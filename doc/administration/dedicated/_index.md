---
stage: GitLab Dedicated
group: Switchboard
description: Get started with GitLab Dedicated.
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Administer GitLab Dedicated
---

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab Dedicated

Use GitLab Dedicated to run GitLab on a fully-managed, single-tenant instance hosted on AWS. You maintain control over your instance configuration through Switchboard, the GitLab Dedicated management portal, while GitLab manages the underlying infrastructure.

For more information about this offering, see the [subscription page](../../subscriptions/gitlab_dedicated/_index.md).

## Architecture overview

GitLab Dedicated runs on a secure infrastructure that provides:

- A fully isolated tenant environment in AWS
- High availability with automated failover
- Geo-based disaster recovery
- Regular updates and maintenance
- Enterprise-grade security controls

To learn more, see [GitLab Dedicated Architecture](architecture.md).

## Configure infrastructure

| Feature | How it works | Set up with |
|------------|-------------|---------------------|
| [Instance sizing](../../subscriptions/gitlab_dedicated/data_residency_and_high_availability.md#availability-and-scalability) | You select an instance size based on your user count. GitLab provisions and maintains the infrastructure. | Onboarding |
| [AWS data regions](../../subscriptions/gitlab_dedicated/data_residency_and_high_availability.md#available-aws-regions) | You choose regions for primary operations, disaster recovery, and backup. GitLab replicates your data across these regions. | Onboarding |
| [Maintenance windows](maintenance.md#maintenance-windows) | You select a weekly 4-hour maintenance window. GitLab performs updates, configuration changes, and security patches during this time. | Onboarding |
| [Release management](maintenance.md#release-rollout-schedule) | GitLab updates your instance monthly with new features and security patches. | Available by <br>default |
| [Geo disaster recovery](create_instance.md#step-2-create-your-gitlab-dedicated-instance) | You choose the secondary region during onboarding. GitLab maintains a replicated secondary site in your chosen region using Geo. | Onboarding |
| [Backup and recovery](../../subscriptions/gitlab_dedicated/data_residency_and_high_availability.md#disaster-recovery) | GitLab backs up your data to your chosen AWS region. | Available by <br>default |

## Secure your instance

| Feature | How it works | Set up with |
|------------|-------------|-----------------|
| [Encryption (BYOK)](create_instance.md#encrypted-data-at-rest-byok) | You provide AWS KMS keys for data encryption. GitLab integrates these keys with your instance. | Onboarding |
| [SAML SSO](configure_instance/saml.md) | You configure the connection to your identity provider. GitLab handles the authentication flow. | Switchboard |
| [IP allowlists](configure_instance/network_security.md#ip-allowlist) | You specify approved IP addresses. GitLab blocks unauthorized access attempts. | Switchboard |
| [Custom certificates](configure_instance/network_security.md#custom-certificates) | You import your SSL certificates. GitLab maintains secure connections to your private services. | Switchboard |
| [Compliance frameworks](../../subscriptions/gitlab_dedicated/_index.md#monitoring) | GitLab maintains compliance with SOC 2, ISO 27001, and other frameworks. You can access reports through the [Trust Center](https://trust.gitlab.com/?product=gitlab-dedicated). | Available by <br>default |
| [Emergency access protocols](../../subscriptions/gitlab_dedicated/_index.md#access-controls) | GitLab provides controlled break-glass procedures for urgent situations. | Available by <br>default |

## Set up networking

| Feature | How it works | Set up with |
|------------|-------------|-----------------|
| [Custom hostname (BYOD)](configure_instance/network_security.md#bring-your-own-domain-byod) | You provide a domain name and configure DNS records. GitLab manages SSL certificates through Let's Encrypt. | Support ticket |
| [Inbound Private Link](configure_instance/network_security.md#inbound-private-link) | You request secure AWS VPC connections. GitLab configures PrivateLink endpoints in your VPC. | Support ticket |
| [Outbound Private Link](configure_instance/network_security.md#outbound-private-link) | You create the endpoint service in your AWS account. GitLab establishes connections using your service endpoints. | Switchboard |
| [Private hosted zones](configure_instance/network_security.md#private-hosted-zones) | You define internal DNS requirements. GitLab configures DNS resolution in your instance network. | Switchboard |

## Use platform tools

| Feature | How it works | Set up with |
|------------|-------------|-----------------|
| [GitLab Pages](../../subscriptions/gitlab_dedicated/_index.md#gitlab-pages) | GitLab hosts your static websites on a dedicated domain. You can publish sites from your repositories. | Available by <br>default |
| [Advanced search](../../integration/advanced_search/elasticsearch.md) | GitLab maintains the search infrastructure. You can search across your code, issues, and merge requests. | Available by <br>default |
| [Hosted runners (beta)](hosted_runners.md) | You purchase a subscription and configure your hosted runners. GitLab manages the auto-scaling CI/CD infrastructure. | Switchboard |

## Manage daily operations

| Feature | How it works | Set up with |
|------------|-------------|-----------------|
| [Application logs](monitor.md) | GitLab delivers logs to your AWS S3 bucket. You can request access to monitor instance activity through these logs. | Support ticket |
| [Email service](configure_instance/users_notifications.md#smtp-email-service) | GitLab provides AWS SES by default to send emails from your GitLab Dedicated instance. You can also configure your own SMTP email service. | Support ticket for <br/>custom service  |
| [Switchboard access and <br>notifications](configure_instance/users_notifications.md) | You manage Switchboard permissions and notification settings. GitLab maintains the Switchboard infrastructure. | Switchboard |

## Get started

To get started with GitLab Dedicated:

1. [Create your GitLab Dedicated instance](create_instance.md).
1. [Configure your GitLab Dedicated instance](configure_instance/_index.md).
1. [Create a hosted runner](hosted_runners.md).
