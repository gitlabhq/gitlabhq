---
stage: GitLab Dedicated
group: Switchboard
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Complete the Switchboard onboarding process to create and access your GitLab Dedicated instance.
title: Create your GitLab Dedicated instance
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Dedicated

{{< /details >}}

Use Switchboard, the GitLab Dedicated management portal, to create your GitLab Dedicated instance.

This process involves the following steps:

- Get access to Switchboard.
- Create your instance.
- Access your new instance.

## Get access to Switchboard

To get access to Switchboard:

1. Provide your account team with the following:

   - Expected number of users
   - [Total purchased storage](storage_types.md#total-purchased-storage)
   - Initial storage size for your repositories in GiB
   - Email addresses of users who need Switchboard access to create your GitLab Dedicated instance
   - Whether you want to use Geo migration
   - Whether you want to use your own encryption keys to secure your data instead of letting
     GitLab manage encryption for you

   If you want to use your own encryption keys, GitLab provides an AWS account ID for key configuration.

1. Check your email for an invitation with temporary Switchboard credentials.

   > [!note]
   > Switchboard credentials are separate from any existing GitLab.com or GitLab Self-Managed credentials.

1. Sign in to Switchboard using the temporary credentials.
1. Update your password and set up multi-factor authentication (MFA).

## Create your instance

To create your GitLab Dedicated instance:

1. Sign in to [Switchboard](https://console.gitlab-dedicated.com/).
1. On the **Account details** page, review and confirm your subscription settings:

   - **Reference architecture**: The infrastructure sizing tier for your instance, based on expected load and usage patterns.
     Named by maximum recommended user count (for example, "Up to 3,000 users").
     Determined by your account team based on your contract requirements.
     For more information, see [expected load](../../reference_architectures/_index.md#expected-load).
   - **Total purchased storage**: The total purchased storage space (repository and object storage) purchased with your contract.
     Predetermined by your account team.
   - **Repository storage**: The total storage space available for all repositories (for example, 16 GiB).
     Based on initial capacity planning discussions using the [Evaluate tool](https://gitlab.com/gitlab-org/professional-services-automation/tools/utilities/evaluate).
     Can be increased but not decreased after provisioning.

   These settings are predetermined by your contract and account team discussions.

1. On the **Configuration** page, complete the fields:

   - **Tenant name**: Enter a name for your instance URL (`<tenant_name>.gitlab-dedicated.com`).
     Cannot be changed after provisioning, unless you configure a custom domain.
   - **Primary region**: Select your AWS region for operations and data storage.
     Cannot be changed after provisioning because all infrastructure (compute, storage, databases) is provisioned in this region.
   - **Primary region Availability Zone IDs (AZ IDs)**: Choose how GitLab selects availability zones:
     - **Default AZ IDs** (recommended): GitLab selects availability zones for your instance.
     - **Custom AZ IDs**: Select two AZ IDs that match your existing AWS infrastructure.
       Required to connect your own AWS infrastructure to your GitLab Dedicated instance within
       specific availability zones, including PrivateLink connections.
     Cannot be changed after provisioning.
   - **Secondary region**: Optional. Select your AWS region for Geo-based disaster recovery.
     Some regions have limited support.
     Cannot be changed after provisioning. Not required if you are using a Geo migration method.
   - **Secondary region Availability Zone IDs (AZ IDs)**: Only available if you configure a secondary region.
     Choose how GitLab selects availability zones:
     - **Default AZ IDs** (recommended): GitLab selects availability zones for your instance.
     - **Custom AZ IDs**: Select two AZ IDs that match your existing AWS infrastructure.
     Cannot be changed after provisioning.
   - **Backup region**: Select your AWS region for backup replication. Can be the same as primary and secondary or different for increased redundancy.
     Cannot be changed after provisioning because backup vaults and replication are configured during provisioning.
   - **Maintenance window**: Select your preferred weekly 4-hour window for updates and [maintenance](../maintenance.md).
     Options align with time zones (APAC, EU, US).
     For more information, see the [GitLab Dedicated info portal](https://gitlab-com.gitlab.io/cs-tools/gitlab-cs-tools/dedicated-info-portal/).

1. On the **Security** page, configure encryption for your instance.

   GitLab manages encryption keys automatically (recommended), or you can manage your own keys
   for compliance requirements.

   > [!warning]
   > Customer-managed encryption keys require additional setup and ongoing management in your own
   > AWS account. You must create and configure AWS KMS keys before provisioning your instance.
   > Once configured, these settings cannot be changed after provisioning.

   For GitLab-managed encryption (recommended):

   - Leave all AWS Key Management Service (KMS) fields empty.
     GitLab automatically configures encryption across all services (backup, EBS disks, RDS database,
     S3 object storage, and advanced search).

   For customer-managed encryption:

   1. [Create encryption keys](../encryption.md#create-encryption-keys).
   1. Optional. Create [replica keys](../encryption.md#create-replica-keys) only if you selected a secondary region for Geo-based disaster recovery.
   1. Collect the Amazon Resource Name (ARN) for each key or replica key. The ARN format is: `arn:aws:kms:<REGION>:<ACCOUNT-ID>:key/<KEY-ID>`.

      For example: `arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012`

   1. For each AWS region you selected (primary, secondary, backup), complete the key fields using this mapping:

      - **Primary region Default**: Use the primary region's key ARN.
      - **Secondary region Default**: Use the replica key ARN (only if you configured a secondary region for Geo).
      - **Backup region Default**: Use the backup region's key ARN. If your backup region is the same as your primary region, use the same key ARN.

   1. For each service (**Backup**, **EBS (disks)**, **RDS (database)**, **S3 (object storage)**, **Advanced search**):
      Either leave empty to use the default key for that region, or enter a specific KMS key ARN for that service.
      Service-specific keys must be from the same AWS region as the corresponding default key.
   1. Leave fields blank for regions you don't use. For example, if you only have a primary region, leave the secondary and backup region fields empty.
   1. Verify all ARNs are correct before proceeding.

1. Optional. On the **Geo migration secrets** page, collect and upload encrypted secrets from your GitLab Self-Managed instance:

   > [!note]
   > This step is only required if you select Geo migration during account setup.

   1. Download the script for your installation type and run it on your GitLab Self-Managed instance.
   1. Upload your `migration_secrets.json.age` file.
   1. Optional. Upload your `ssh_host_keys.json.age` file (recommended if you plan to use a
      custom domain).

   For detailed instructions and troubleshooting, see [migrate to GitLab Dedicated with Geo](../geo_migration.md).

1. On the **Tenant summary** page, review all configuration details.

   > [!warning]
   > You cannot change these settings after provisioning:
   > - AWS KMS keys (BYOK) configuration
   > - AWS regions (primary, secondary, and backup regions)
   > - AWS availability zone IDs (primary and secondary regions)
   > - Repository capacity (can only increase)
   > - Tenant name and URL

1. Select **Create tenant**.

Your instance takes up to three hours to provision. You receive a confirmation email when setup is complete.

## Access your instance

To access your GitLab Dedicated instance:

1. Sign in to [Switchboard](https://console.gitlab-dedicated.com/).
1. In the **Access your GitLab Dedicated instance** banner, select **View credentials**.
1. Copy the tenant URL and temporary root credentials.

   > [!note]
   > You can retrieve temporary root credentials only once. Store them securely before leaving Switchboard.

1. Go to your tenant URL and sign in with the temporary root credentials.
1. [Change your temporary root password](../../../user/profile/user_passwords.md#change-your-password).
1. In the **Admin** area, [add the license key](../../license_file.md#add-license-in-the-admin-area).
1. Return to Switchboard and [add users](../configure_instance/users_notifications.md#add-switchboard-users) as needed.

## Next steps

Review the [release rollout schedule](../releases.md#release-rollout-schedule) for upgrades and maintenance.

Plan ahead if you need any of the following features:

- [Inbound Private Link](../configure_instance/network_security.md#inbound-private-link)
- [Outbound Private Link](../configure_instance/network_security.md#outbound-private-link)
- [SAML SSO](../configure_instance/authentication/saml.md)
- [Custom domains](../configure_instance/network_security.md#custom-domains)

For all configuration options, see [configure your GitLab Dedicated instance](../configure_instance/_index.md).

> [!note]
> GitLab Dedicated instances use the same default settings as GitLab Self-Managed instances.
>
> Starting with GitLab 18.0, [GitLab Duo Core](../../../subscriptions/subscription-add-ons.md#gitlab-duo-core)
> features are turned on by default for new instances. To comply with data residency requirements or AI usage policies,
> you can [turn off GitLab Duo Core](../../../user/gitlab_duo/turn_on_off.md#for-an-instance).
