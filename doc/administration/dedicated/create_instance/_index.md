---
stage: GitLab Dedicated
group: Switchboard
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Create your GitLab Dedicated instance with Switchboard.
title: Create your GitLab Dedicated instance
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Dedicated

{{< /details >}}

The instructions on this page guide you through the onboarding and initial setup of your GitLab Dedicated instance using [Switchboard](https://about.gitlab.com/direction/platforms/switchboard/), the GitLab Dedicated portal.

## Step 1: Get access to Switchboard

Your GitLab Dedicated instance will be set up using Switchboard. To gain access to Switchboard,
provide the following information to your account team:

- Expected number of users.
- [Total purchased storage](storage_types.md#total-purchased-storage).
- Initial storage size for your repositories in GiB.
- Email addresses of any users that need to complete the onboarding and create your GitLab Dedicated instance.
- Whether you want to [bring your own encryption keys (BYOK)](../encryption.md#bring-your-own-key-byok). If so, GitLab provides an AWS account ID, which is necessary to enable BYOK.
- Whether you want to use Geo migration for inbound migration of your Dedicated instance.

If you've been granted access to Switchboard, you will receive an email invitation with temporary
credentials to sign in.

The credentials for Switchboard are separate from any other GitLab credentials you may already have
to sign in to a GitLab Self-Managed instance or GitLab.com.

After you first sign in to Switchboard, you must update your password and set up MFA before you can
complete your onboarding to create a new instance.

## Step 2: Create your GitLab Dedicated instance

After you sign in to Switchboard, follow these steps to create your instance:

1. On the **Account details** page, review and confirm your subscription settings:

   | Field | Predetermined by | Description |
   | :---- | :---- | :---- |
   | **Reference architecture** | Account team (from contract) | The infrastructure sizing tier for your instance, based on expected load and usage patterns. Named by maximum recommended user count (e.g., "Up to 3,000 users"). See [Expected load](../../reference_architectures/_index.md#expected-load) for more information |
   | **Total purchased storage** | Account team (from contract) | The total purchased storage space (repository and object storage) purchased with your contract. |
   | **Repository storage** | Initial capacity planning discussions ([Evaluate](https://gitlab.com/gitlab-org/professional-services-automation/tools/utilities/evaluate) tool) | The total storage space available for all repositories in your instance (for example, 16 GiB). Can be increased but not decreased after provisioning. |

   These settings are based on information provided to your account team. If you need to change any of these values, [submit a support ticket](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650).

   For more information, see [storage types](storage_types.md).

1. On the **Configuration** page, choose your tenant, location, and maintenance window settings:

   | Field | Determined by | Description |
   | :---- | :---- | :---- |
   | **Tenant name** | Your choice | Displayed name for your instance. Forms part of your URL as `<tenant_name>.gitlab-dedicated.com`. The tenant name cannot be changed once configured. |
   | **Primary region** | Infrastructure/compliance requirements | AWS region for primary operations and data storage. Can't be changed after creation because all infrastructure (compute, storage, databases) is provisioned in this region. |
   | **Secondary region** | Infrastructure/DR requirements | AWS region for Geo-based disaster recovery. Some regions have limited support. Can't be changed after creation. If you are using a Geo migration method, this field is not required. |
   | **Backup region** | Compliance/redundancy requirements | AWS region for backup replication. Can be the same as primary/secondary or different for increased redundancy. Can't be changed after creation because backup vaults and replication are configured during provisioning. |
   | **Maintenance window** | Operational preferences | Weekly 4-hour window for updates and [maintenance](../maintenance.md). Options align with time zones (APAC, EU, US). See the [Dedicated Info Portal](https://gitlab-com.gitlab.io/cs-tools/gitlab-cs-tools/dedicated-info-portal/) for more information.|

   For more information, see [data residency and high availability](data_residency_high_availability.md).

1. Optional. On the **Security** page, add your [AWS KMS keys](https://docs.aws.amazon.com/kms/latest/developerguide/overview.html) for encrypted AWS services. If you don't add keys, GitLab generates encryption keys for your instance.

   If enabling BYOK:

   - Use symmetric keys for encrypt/decrypt with AWS-managed key material (AWS\_KMS origin).
   - Use multi-region keys with replicas in each region.
   - Grant key policy access to your GitLab Dedicated AWS account (provided during sales).
   - Configure keys during onboarding - they can't be added later.
   - Provide one key (or key replica) per region.
   - Encrypted services include EBS volumes, RDS databases, S3 buckets, and backup vaults.

   For more information, see [encrypting your data at rest](../encryption.md#encrypted-data-at-rest).

1. On the **Tenant summary** page, review the tenant configuration details.

   > [!note]
   > Review these settings carefully. You can't change them later:
   >
   > - Security keys and AWS KMS keys (BYOK) configuration
   > - AWS regions (primary, secondary, backup)
   > - Total repository capacity (you can increase storage but cannot reduce it)
   > - Tenant name and URL (unless you [configure a custom domain](../configure_instance/network_security.md#custom-domains))

   After you confirm that the information you've provided in the previous steps is accurate, select **Create tenant**.

Your GitLab Dedicated instance can take up to three hours to provision. You receive a confirmation email when setup is complete.

## Step 3: Access and configure your GitLab Dedicated instance

To access and configure your GitLab Dedicated instance:

1. Sign in to [Switchboard](https://console.gitlab-dedicated.com/).
1. In the **Access your GitLab Dedicated instance** banner, select **View credentials**.
1. Copy the tenant URL and temporary root credentials for your instance.

   > [!note]
   > For security, you can retrieve the temporary root credentials from Switchboard only once. Be sure to store these credentials securely (for example, in a password manager) before leaving Switchboard.

1. Go to the tenant URL for your GitLab Dedicated instance and sign in with your temporary root credentials.
1. [Change your temporary root password](../../../user/profile/user_passwords.md#change-your-password) to a new secure password.
1. Go to the Admin area and [add the license key](../../license_file.md#add-license-in-the-admin-area) for your GitLab Dedicated subscription.
1. Return to Switchboard and [add users](../configure_instance/users_notifications.md#add-switchboard-users), if needed.
1. Review the [release rollout schedule](../releases.md#release-rollout-schedule) for upgrades and maintenance.

Also plan ahead if you need the following GitLab Dedicated features:

- [Inbound Private Link](../configure_instance/network_security.md#inbound-private-link)
- [Outbound Private Link](../configure_instance/network_security.md#outbound-private-link)
- [SAML SSO](../configure_instance/authentication/saml.md)
- [Custom domains](../configure_instance/network_security.md#custom-domains)

To view all available infrastructure configuration options, see [Configure your GitLab Dedicated instance](../configure_instance/_index.md).

> [!note]
> New GitLab Dedicated instances use the same default settings as GitLab Self-Managed. A GitLab administrator can change these settings from the [Admin Area](../../admin_area.md).
> 
> For instances created in GitLab 18.0 and later, [GitLab Duo Core](../../../subscriptions/subscription-add-ons.md#gitlab-duo-core) features are turned on by default for all users.
> 
> If your organization requires data to remain within your specified regions or has restrictions on AI feature usage,
> you can [turn off GitLab Duo Core](../../../user/gitlab_duo/turn_on_off.md#for-an-instance).
