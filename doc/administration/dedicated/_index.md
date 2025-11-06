---
stage: GitLab Dedicated
group: Switchboard
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Get started with GitLab Dedicated.
title: Administer GitLab Dedicated
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Dedicated

{{< /details >}}

Use GitLab Dedicated to run GitLab on a fully-managed, single-tenant instance hosted on AWS. You maintain control over your instance configuration through Switchboard, the GitLab Dedicated management portal, while GitLab manages the underlying infrastructure.

For more information about this offering, see the [subscription page](../../subscriptions/gitlab_dedicated/_index.md).

## Architecture overview

GitLab Dedicated runs on a secure infrastructure that provides:

- A fully isolated tenant environment in AWS
- High availability with automated failover
- Geo-based disaster recovery
- Regular updates and maintenance
- Enterprise-grade security controls

To learn more, see [GitLab Dedicated architecture](architecture.md).

## Configure infrastructure

| Feature | Description | Set up with |
|------------|-------------|---------------------|
| [Instance sizing](create_instance/data_residency_high_availability.md#availability-and-scalability) | You select an instance size based on your user count. GitLab provisions and maintains the infrastructure. | Onboarding |
| [AWS data regions](create_instance/data_residency_high_availability.md#primary-regions) | You choose regions for primary operations, disaster recovery, and backup. GitLab replicates your data across these regions. | Onboarding |
| [Maintenance windows](maintenance.md#maintenance-windows) | You select a weekly 4-hour maintenance window. GitLab performs updates, configuration changes, and security patches during this time. | Onboarding |
| [Release management](releases.md#release-rollout-schedule) | GitLab updates your instance monthly with new features and security patches. | Available by <br>default |
| [Geo disaster recovery](disaster_recovery.md) | You choose the secondary region during onboarding. GitLab maintains a replicated secondary site in your chosen region using Geo. | Onboarding |
| [Automated backups](disaster_recovery.md#automated-backups) | GitLab backs up your data to your chosen AWS region. | Available by <br>default |

## Secure your instance

| Feature | Description | Set up with |
|------------|-------------|-----------------|
| [Data encryption](encryption.md) | GitLab encrypts your data both at rest and in transit through infrastructure provided by AWS. | Available by <br>default |
| [Bring your own key (BYOK)](encryption.md#bring-your-own-key-byok) | You can provide your own AWS KMS keys for encryption instead of using GitLab-managed AWS KMS keys. GitLab integrates these keys with your instance to encrypt data at rest. | Onboarding |
| [SAML SSO](configure_instance/saml.md) | You configure the connection to your SAML identity providers. GitLab handles the authentication flow. | Switchboard |
| [IP allowlists](configure_instance/network_security.md#ip-allowlist) | You specify approved IP addresses. GitLab blocks unauthorized access attempts. | Switchboard |
| [Custom certificates](configure_instance/network_security.md#custom-certificate-authority) | You import your SSL certificates. GitLab maintains secure connections to your private services. | Switchboard |
| [Compliance frameworks](../../subscriptions/gitlab_dedicated/_index.md#monitoring) | GitLab maintains compliance with SOC 2, ISO 27001, and other frameworks. You can access reports through the [Trust Center](https://trust.gitlab.com/?product=gitlab-dedicated). | Available by <br>default |
| [Emergency access protocols](../../subscriptions/gitlab_dedicated/_index.md#access-controls) | GitLab provides controlled break-glass procedures for urgent situations. | Available by <br>default |

## Set up networking

| Feature | Description | Set up with |
|------------|-------------|-----------------|
| [Custom hostname (BYOD)](configure_instance/network_security.md#bring-your-own-domain-byod) | You provide a domain name and configure DNS records. GitLab manages SSL certificates through Let's Encrypt. | Support ticket |
| [Inbound private link](configure_instance/network_security.md#inbound-private-link) | GitLab creates an endpoint service. You create VPC endpoints in your AWS account to connect to your GitLab instance. | Switchboard |
| [Outbound private link](configure_instance/network_security.md#outbound-private-link) | You create an endpoint service in your AWS account. GitLab creates VPC endpoints to connect to your services. | Switchboard |
| [Private hosted zones](configure_instance/network_security.md#private-hosted-zones) | You define internal DNS requirements. GitLab configures DNS resolution in your instance network. | Switchboard |

## Use platform tools

| Feature | Description | Set up with |
|------------|-------------|-----------------|
| [GitLab Pages](../../subscriptions/gitlab_dedicated/_index.md#gitlab-pages) | GitLab hosts your static websites on a dedicated domain. You can publish sites from your repositories. | Available by <br>default |
| [Advanced search](../../integration/advanced_search/elasticsearch.md) | GitLab maintains the search infrastructure. You can search across your code, issues, and merge requests. | Available by <br>default |
| [Hosted runners (beta)](hosted_runners.md) | You purchase a subscription and configure your hosted runners. GitLab manages the auto-scaling CI/CD infrastructure. | Switchboard |
| [ClickHouse](../../integration/clickhouse.md) | GitLab maintains the ClickHouse infrastructure and integration. You can access all advanced analytical features such as [GitLab Duo and SDLC trends](../../user/analytics/duo_and_sdlc_trends.md) and [CI analytics](../../ci/runners/runner_fleet_dashboard.md#enable-more-ci-analytics-features-with-clickhouse). | Available by <br>default for [eligible customers](../../subscriptions/gitlab_dedicated/_index.md#clickhouse-cloud) |

## Manage daily operations

| Feature | Description | Set up with |
|------------|-------------|-----------------|
| [Application logs](monitor.md) | GitLab delivers logs to your AWS S3 bucket. You can request access to monitor instance activity through these logs. | Support ticket |
| [Email service](configure_instance/users_notifications.md#smtp-email-service) | GitLab provides AWS SES by default to send emails from your GitLab Dedicated instance. You can also configure your own SMTP email service. | Support ticket for <br/>custom service  |
| [Switchboard access and <br>notifications](configure_instance/users_notifications.md) | You manage Switchboard permissions and notification settings. GitLab maintains the Switchboard infrastructure. | Switchboard |
| [Switchboard SSO](configure_instance/authentication/_index.md#configure-switchboard-sso) | You configure your organization's identity provider and supply GitLab with the necessary details. GitLab configures single-sign-on (SSO) for Switchboard. | Support ticket |

## Get started

To get started with GitLab Dedicated:

1. [Create your GitLab Dedicated instance](create_instance/_index.md).
1. [Configure your GitLab Dedicated instance](configure_instance/_index.md).
1. [Create a hosted runner](hosted_runners.md).
