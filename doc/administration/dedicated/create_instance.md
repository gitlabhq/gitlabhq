---
stage: GitLab Dedicated
group: Switchboard
description: Create your GitLab Dedicated instance with Switchboard.
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Create your GitLab Dedicated instance
---

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab Dedicated

The instructions on this page guide you through the onboarding and initial setup of your GitLab Dedicated instance using [Switchboard](https://about.gitlab.com/direction/saas-platforms/switchboard/), the GitLab Dedicated portal.

## Step 1: Get access to Switchboard

Your GitLab Dedicated instance will be set up using Switchboard. To gain access to Switchboard,
provide the following information to your account team:

- Expected number of users.
- Initial storage size for your repositories in GB.
- Email addresses of the users who are responsible to complete the onboarding and create your
  GitLab Dedicated instance.
- Whether you want to [bring your own encryption keys (BYOK)](#encrypted-data-at-rest-byok). If so, GitLab provides an AWS account ID, which is necessary to enable BYOK.
- Whether you want to use Geo migration for inbound migration of your Dedicated instance.

If you've been granted access to Switchboard, you will receive an email invitation with temporary
credentials to sign in.

The credentials for Switchboard are separate from any other GitLab credentials you may already have
to sign in to a GitLab Self-Managed instance or GitLab.com.

After you first sign in to Switchboard, you must update your password and set up MFA before you can
complete your onboarding to create a new instance.

### Encrypted Data At Rest (BYOK)

NOTE:
To enable BYOK, you must do it before onboarding. If enabled, it is not possible to later disable BYOK.

You can opt to encrypt your GitLab data at rest with AWS KMS keys, which must be made accessible to GitLab Dedicated infrastructure. Due to key rotation requirements, GitLab Dedicated only supports keys with AWS-managed key material (the [AWS_KMS](https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#key-origin) origin type).

Encryption for data in motion (moving over a network) is performed with TLS using keys generated and managed by GitLab Dedicated components, and is not covered by BYOK.

In GitLab Dedicated, you can use KMS keys in two ways:

- One KMS key for all services
- Per-service KMS keys (Backup, EBS, RDS, S3, Advanced Search)
  - Keys do not need to be unique to each service.
  - All services must be encrypted at rest.
  - Selective enablement of this feature is not supported.
  - Keys do not need to be unique to each service.

#### Create KMS keys in AWS

After you have received the AWS account ID, create your KMS keys using the AWS Console:

1. In `Configure key`, select:
   1. Key type: **Symmetrical**
   1. Key usage: **Encrypt and decrypt**
   1. `Advanced options`:
      1. Key material origin: **KMS**
      1. Regionality: **Multi-Region key**
1. Enter your values for key alias, description, and tags.
1. Select key administrators.
1. Optional. Allow or prevent key administrators from deleting the key.
1. On the **Define key usage permissions** page, under **Other AWS accounts**, add the GitLab AWS account.

The last page asks you to confirm the KMS key policy. It should look similar to the following example, populated with your account IDs and usernames:

```json
{
    "Version": "2012-10-17",
    "Id": "byok-key-policy",
    "Statement": [
        {
            "Sid": "Enable IAM User Permissions",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::<CUSTOMER-ACCOUNT-ID>:root"
            },
            "Action": "kms:*",
            "Resource": "*"
        },
        {
            "Sid": "Allow access for Key Administrators",
            "Effect": "Allow",
            "Principal": {
                "AWS": [
                    "arn:aws:iam::<CUSTOMER-ACCOUNT-ID>:user/<CUSTOMER-USER>"
                ]
            },
            "Action": [
                "kms:Create*",
                "kms:Describe*",
                "kms:Enable*",
                "kms:List*",
                "kms:Put*",
                "kms:Update*",
                "kms:Revoke*",
                "kms:Disable*",
                "kms:Get*",
                "kms:Delete*",
                "kms:TagResource",
                "kms:UntagResource",
                "kms:ScheduleKeyDeletion",
                "kms:CancelKeyDeletion",
                "kms:ReplicateKey",
                "kms:UpdatePrimaryRegion"
            ],
            "Resource": "*"
        },
        {
            "Sid": "Allow use of the key",
            "Effect": "Allow",
            "Principal": {
                "AWS": [
                    "arn:aws:iam::<GITLAB-ACCOUNT-ID>:root"
                ]
            },
            "Action": [
                "kms:Encrypt",
                "kms:Decrypt",
                "kms:ReEncrypt*",
                "kms:GenerateDataKey*",
                "kms:DescribeKey"
            ],
            "Resource": "*"
        },
        {
            "Sid": "Allow attachment of persistent resources",
            "Effect": "Allow",
            "Principal": {
                "AWS": [
                    "arn:aws:iam::<GITLAB-ACCOUNT-ID>:root"
                ]
            },
            "Action": [
                "kms:CreateGrant",
                "kms:ListGrants",
                "kms:RevokeGrant"
            ],
            "Resource": "*"
        }
    ]
}
```

For more information on how to create and manage KMS keys, see the [AWS KMS documentation](https://docs.aws.amazon.com/kms/latest/developerguide/getting-started.html).

After you have created the keys, send GitLab the corresponding ARNs of each key so that GitLab can use to encrypt the data stored in your Dedicated instance.

Make sure the AWS KMS keys are replicated to your desired primary, secondary and backup region specified during [onboarding](#step-2-create-your-gitlab-dedicated-instance).

## Step 2: Create your GitLab Dedicated instance

Once signed in to Switchboard, you will need to go through a series of four steps to provide the
information required to create your GitLab Dedicated instance.

1. Confirm account details: Confirm key attributes of your GitLab Dedicated account:
   - Reference architecture: Corresponds with the number of users you provided to your account team
     when beginning the onboarding process. For more information, see
     [reference architectures](../../subscriptions/gitlab_dedicated/data_residency_and_high_availability.md#availability-and-scalability).
   - Total repository storage size: Corresponds with the storage size you provided to your account
     team when beginning the onboarding process.
   - If you need to make changes to these attributes,
     [submit a support ticket](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650).
1. Tenant configuration: Provides the minimum required information needed to create your GitLab
   Dedicated instance:
   - Desired instance subdomain: The main domain for GitLab Dedicated instances is
     `gitlab-dedicated.com`. You choose the subdomain name where your instance is accessible from.
     For example, `customer_name.gitlab-dedicated.com`. You can add a custom hostname in a later step.
   - Desired primary region: Primary AWS region in which your data is stored. Note the
     [available AWS regions](../../subscriptions/gitlab_dedicated/data_residency_and_high_availability.md#available-aws-regions).
   - Desired secondary region: Secondary AWS region in which your data is stored. This region is
     used to recover your GitLab Dedicated instance in case of a disaster.
   - Desired backup region: An AWS region where the primary backups of your data are replicated.
     This can be the same as the primary or secondary region, or different.
   - Desired maintenance window: A weekly four-hour time slot that GitLab uses to perform routine
     maintenance and upgrade operations on all tenant instances. For more information, see
     [maintenance windows](../dedicated/maintenance.md#maintenance-windows).
1. Optional. Security: You can provide your own [KMS keys](https://docs.aws.amazon.com/kms/latest/developerguide/overview.html)
   for encrypted AWS services. If you choose not to provide KMS keys, encryption keys are generated
   for your instance when it is created. For more information, see [encrypting your data at rest](#encrypted-data-at-rest-byok).
1. Summary: Confirm that the information you've provided in the previous steps is accurate
   before initiating the creation of your instance.

NOTE:
Some configuration settings (like the option to bring your own keys and your tenant name) are permanent and cannot be changed once your instance has been created.

It can take up to 3 hours to create the GitLab Dedicated instance. When the setup is complete, you will receive a confirmation email.

## Step 3: Access and configure your GitLab Dedicated instance

To access and configure your GitLab Dedicated instance:

1. Sign in to [Switchboard](https://console.gitlab-dedicated.com/).
1. In the **Access your GitLab Dedicated instance** banner, select **View credentials**.
1. Copy the tenant URL and temporary root credentials for your instance.

   NOTE:
   For security, you can retrieve the temporary root credentials from Switchboard only once. Be sure to store these credentials securely (for example, in a password manager) before leaving Switchboard.

1. Go to the tenant URL for your GitLab Dedicated instance and sign in with your temporary root credentials.
1. [Change your temporary root password](../../user/profile/user_passwords.md#change-your-password) to a new secure password.
1. Go to the Admin area and [add the license key](../license_file.md#add-license-in-the-admin-area) for your GitLab Dedicated subscription.
1. Return to Switchboard and [add users](../dedicated/configure_instance/users_notifications.md#add-switchboard-users), if needed.
1. Review the [release rollout schedule](../dedicated/maintenance.md#release-rollout-schedule) for upgrades and maintenance.

Also plan ahead if you need the following GitLab Dedicated features:

- [Inbound Private Link](../dedicated/configure_instance/network_security.md#inbound-private-link)
- [Outbound Private Link](../dedicated/configure_instance/network_security.md#outbound-private-link)
- [SAML SSO](../dedicated/configure_instance/saml.md)
- [Bring your own domain](../dedicated/configure_instance/network_security.md#bring-your-own-domain-byod)

To view all available infrastructure configuration options, see [Configure your GitLab Dedicated instance](../dedicated/configure_instance.md).

NOTE:
New GitLab Dedicated instances use the same default settings as GitLab Self-Managed. A GitLab administrator can change these settings from the [Admin Area](../admin_area.md).
