---
stage: SaaS Platforms
group: GitLab Dedicated
description: Create your GitLab Dedicated instance with Switchboard.
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Create your GitLab Dedicated instance

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
to sign in to a GitLab self-managed or GitLab.com instance.

After you first sign in to Switchboard, you must update your password and set up MFA before you can
complete your onboarding to create a new instance.

### Encrypted Data At Rest (BYOK)

NOTE:
To enable BYOK, you must do it before onboarding.

You can opt to encrypt your GitLab data at rest with AWS KMS keys, which must be made accessible to GitLab Dedicated infrastructure. Due to key rotation requirements, GitLab Dedicated only supports keys with AWS-managed key material (the [AWS_KMS](https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#key-origin) origin type).

In GitLab Dedicated, you can use KMS keys in two ways:

- One KMS key for all services
- Per-service KMS keys (Backup, EBS, RDS, S3)
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
     [reference architectures](../../subscriptions/gitlab_dedicated/index.md#availability-and-scalability).
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
     [available AWS regions](../../subscriptions/gitlab_dedicated/index.md#available-aws-regions).
   - Desired secondary region: Secondary AWS region in which your data is stored. This region is
     used to recover your GitLab Dedicated instance in case of a disaster.
   - Desired backup region: An AWS region where the primary backups of your data are replicated.
     This can be the same as the primary or secondary region, or different.
   - Desired maintenance window: A weekly four-hour time slot that GitLab uses to perform routine
     maintenance and upgrade operations on all tenant instances. For more information, see
     [maintenance windows](../../administration/dedicated/create_instance.md#maintenance-window).
1. Optional. Security: You can provide your own [KMS keys](https://docs.aws.amazon.com/kms/latest/developerguide/overview.html)
   for encrypted AWS services. If you choose not to provide KMS keys, encryption keys are generated
   for your instance when it is created. For more information, see [encrypting your data at rest](#encrypted-data-at-rest-byok).
1. Optional. [Bring Your Own Domain](../../administration/dedicated/configure_instance.md#bring-your-own-domain-byod): You can add a custom hostname for your GitLab Dedicated instance, the bundled container registry, and KAS services.
1. Summary: Confirm that the information you've provided in the previous steps is accurate
   before initiating the creation of your instance.

NOTE:
Some configuration settings (like the option to bring your own keys and your tenant name) are permanent and cannot be changed once your instance has been created.

It can take up to 3 hours to create the GitLab Dedicated instance. When the setup is complete, you will receive a confirmation email with further instructions on how to access your instance.

## Step 3: Configure your GitLab Dedicated instance

Once your GitLab Dedicated instance is created, follow our recommendations on:

- [Steps after installing GitLab](../../install/next_steps.md).
- [Securing your GitLab installation](../../security/index.md).
- [GitLab hardening](../../security/hardening.md).

Also plan ahead if you need the following features:

- [Inbound Private Link](../../administration/dedicated/configure_instance.md#inbound-private-link)
- [Outbound Private Link](../../administration/dedicated/configure_instance.md#outbound-private-link)
- [SAML SSO](../../administration/dedicated/configure_instance.md#saml)
- [Bring your own domain](../../administration/dedicated/configure_instance.md#bring-your-own-domain-byod)

## Things to know

### Maintenance window

Available scheduled maintenance windows, performed outside standard working hours:

- APAC: Wednesday 1 PM - 5 PM UTC
- EMEA: Tuesday 1 AM - 5 AM UTC
- AMER Option 1: Tuesday 7 AM - 11 AM UTC
- AMER Option 2: Sunday 9 PM - Monday 1 AM UTC

Consider the following notes:

- The Dedicated instance is not expected to be down the entire duration of the maintenance window. Occasionally, a small period of downtime (on the order of a few tens of seconds) can occur while compute resources restart after they are upgraded. If it occurs, this small period of downtime typically happens during the first half of the maintenance window. Long-running connections may be interrupted during this period. To mitigate this, clients should implement strategies like automatic recovery and retry. Longer periods of downtime during the maintenance window are rare, and GitLab provides notice if longer downtime is anticipated.
- In case of a performance degradation or downtime during the scheduled maintenance window,
  the impact to [the system SLA](https://handbook.gitlab.com/handbook/engineering/infrastructure/team/gitlab-dedicated/slas/) is not counted.
- The weekly scheduled maintenance window can be postponed into another window within the same week.
  This option needs to be agreed with the assigned Customer Success Manager at least one week in advance.
- The scheduled weekly maintenance window is different from
  [emergency maintenance](#emergency-maintenance).

#### GitLab release rollout schedule

GitLab Dedicated tenant instances are [upgraded](../../subscriptions/gitlab_dedicated/index.md#upgrades) to the minor GitLab release within [the pre-selected window](#maintenance-window) using the schedule described below.

Where **T** is the date of a [minor GitLab release](../../policy/maintenance.md) `N`. GitLab Dedicated instances are upgraded to the `N-1` release as follows:

1. At T+5 calendar days: Tenant instances in the `EMEA` and `AMER Option 1` maintenance window are upgraded.
1. At T+6 calendar days: Tenant instances in the `APAC` maintenance window are upgraded.
1. At T+10 calendar days: Tenant instances in the `AMER Option 2` maintenance window are upgraded.

For example, GitLab 16.9 released on 2024-02-15. Therefore, tenant instances in the `EMEA` and `AMER Option 1` maintenance window are upgraded to 16.8 on 2024-02-20.

#### Emergency maintenance

In an event of a platform outage, degradation or a security event requiring urgent action,
emergency maintenance will be carried out per
[the emergency change processes](https://handbook.gitlab.com/handbook/engineering/infrastructure/emergency-change-processes/).

The emergency maintenance is initiated when urgent actions need to be executed by GitLab on a
Dedicated tenant instance. Communication with the customer will be provided on best effort basis
prior to commencing the maintenance, and full communication will follow after the immediate action
is carried out. The GitLab Support Team will create a new ticket and send a message to the email
addresses of the users listed in Switchboard during [onboarding](../../administration/dedicated/create_instance.md#step-1-get-access-to-switchboard).

For example, when a critical security process is initiated to address an S1 vulnerability in GitLab,
emergency maintenance is carried out to upgrade GitLab to the non-vulnerable version and that
can occur outside of a scheduled maintenance window.
Postponing emergency maintenance is not possible, because the same process must be applied to all
existing Dedicated customers, and the primary concern is to ensure safety and availability of
Dedicated tenant instances.
