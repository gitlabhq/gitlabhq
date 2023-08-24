---
stage: SaaS Platforms
group: GitLab Dedicated
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments"
description: 'Learn how to configure your GitLab Dedicated instance.'
---

# Configure GitLab Dedicated **(ULTIMATE)**

GitLab Dedicated is a single-tenant SaaS solution, fully managed and hosted by GitLab. For more information about this offering, see the [subscription page](../../subscriptions/gitlab_dedicated/index.md).

The instructions on this page guide you through:

1. Onboarding and initial setup of your GitLab Dedicated instance.
1. Configuring your GitLab Dedicated instance including enabling and updating the settings for [available functionality](../../subscriptions/gitlab_dedicated/index.md#available-features).

Any functionality in the GitLab application that is not controlled by the SaaS environment can be configured by using the [Admin Panel](../../administration/admin_area.md).

Examples of SaaS environment settings include `gitlab.rb` configurations and access to shell, Rails console, and PostgreSQL console.
These environment settings cannot be changed by tenants.
GitLab Dedicated Engineers also don't have direct access to tenant environments, except for [break glass situations](../../subscriptions/gitlab_dedicated/index.md#access-controls).

## Onboarding

To request the creation of a new GitLab Dedicated environment for your organization, you must provide the following information to your account team:

- Expected number of users.
- Desired primary region: Primary AWS region in which your data is stored (do note the [list of unsupported regions](../../subscriptions/gitlab_dedicated/index.md#aws-regions-not-supported)).
- Desired secondary region: Secondary AWS region in which your data is stored. This region is used to recover your GitLab Dedicated instance in case of a disaster.
- Desired backup region: An AWS region where the primary backups of your data are replicated. This can be the same as the primary or secondary region or different.
- Desired instance subdomain: The main domain for GitLab Dedicated instances is `gitlab-dedicated.com`. You get to choose the subdomain name where your instance is accessible from (for example, `customer_name.gitlab-dedicated.com`).
- Initial storage: Initial storage size for your repositories in GB.
- Availability Zone IDs for PrivateLink: If you plan to later add a PrivateLink connection (either [inbound](#inbound-private-link) or [outbound](#outbound-private-link)) to your environment, and you require the connections to be available in specific Availability Zones, you must provide up to two [Availability Zone IDs](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html#az-ids) during onboarding. If not specified, GitLab selects two random Availability Zone IDs where the connections are available.
- [KMS keys](https://docs.aws.amazon.com/kms/latest/developerguide/overview.html) for encrypted AWS services (if you are using that functionality).

### Maintenance window

When onboarding, you must also specify your preference for the weekly four-hour time slot that GitLab uses to perform routine maintenance and upgrade operations on all tenant instances.

Available scheduled maintenance windows, performed outside standard working hours:

- APAC: Wednesday 1 PM - 5 PM UTC
- EU: Tuesday 1 AM - 5 AM UTC
- AMER Option 1: Tuesday 7 AM - 11 AM UTC
- AMER Option 2: Sunday 9 PM - Monday 1 AM UTC

Consider the following notes:

- The Dedicated instance is not expected to be down the entire duration of the maintenance window. Occasionally, a small period of downtime (on the order of a few tens of seconds) can occur while compute resources restart after they are upgraded. If it occurs, this small period of downtime typically happens during the first half of the maintenance window. Long-running connections may be interrupted during this period. To mitigate this, clients should implement strategies like automatic recovery and retry. Longer periods of downtime during the maintenance window are rare, and GitLab provides notice if longer downtime is anticipated.
- In case of a performance degradation or downtime during the scheduled maintenance window,
  the impact to [the system SLA](https://about.gitlab.com/handbook/engineering/infrastructure/team/gitlab-dedicated/slas/) is not counted.
- The weekly scheduled maintenance window can be postponed into another window within the same week.
  This option needs to be agreed with the assigned Customer Success Manager at least one week in advance.
- The scheduled weekly maintenance window is different from
  [emergency maintenance](#emergency-maintenance).

#### Emergency maintenance

In an event of a platform outage, degradation or a security event requiring urgent action,
emergency maintenance will be carried out per
[the emergency change processes](https://about.gitlab.com/handbook/engineering/infrastructure/emergency-change-processes/).

The emergency maintenance is initiated urgently when urgent actions need to be executed by GitLab
on a Dedicated tenant instance.
Communication with the customer will be provided on best effort basis prior to commencing the
maintenance, and full communication will follow after the immediate action is carried out.

For example, when a critical security process is initiated to address an S1 vulnerability in GitLab,
emergency maintenance is carried out to upgrade GitLab to the non-vulnerable version and that
can occur outside of a scheduled maintenance window.
Postponing emergency maintenance is not possible, because the same process must be applied to all
existing Dedicated customers, and the primary concern is to ensure safety and availability of
Dedicated tenant instances.

## Configuration changes

To change or update the configuration for your GitLab Dedicated instance, open a [support ticket](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650) with your request. You can request configuration changes for the options originally specified during onboarding, or for any of the optional features below.

The turnaround time for processing configuration change requests is [documented in the GitLab handbook](https://about.gitlab.com/handbook/engineering/infrastructure/team/gitlab-dedicated/#handling-configuration-changes-for-tenant-environments).

### Encrypted Data At Rest (BYOK)

NOTE:
To enable BYOK, you must do it during onboarding.

You can opt to encrypt your GitLab data at rest with AWS KMS keys, which must be made accessible to GitLab Dedicated infrastructure. GitLab Dedicated only supports keys with AWS-managed key material (the [AWS_KMS](https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#key-origin) origin type).

For instructions on how to create and manage KMS keys, see the [AWS KMS documentation](https://docs.aws.amazon.com/kms/latest/developerguide/getting-started.html).

In GitLab Dedicated, you can use KMS keys in two ways:

- One KMS key for all services
- Per-service KMS keys (Backup, EBS, RDS, S3)
  - Keys do not need to be unique to each service.
  - All services must be encrypted at rest.
  - Selective enablement of this feature is not supported.
  - Keys do not need to be unique to each service.

Make sure the AWS KMS keys are replicated to your desired primary, secondary, and backup region specified during [onboarding](#onboarding).

#### Create KMS keys in AWS

To enable BYOK, indicate on your onboarding ticket that you'd like to use this functionality.
GitLab will provide you with your AWS account ID which is necessary to enable BYOK.

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

Make sure the AWS KMS keys are replicated to your desired primary, secondary and backup region specified during [onboarding](#onboarding). After you have created the keys, send GitLab the corresponding ARNs of each key so that GitLab can use to encrypt the data stored in your Dedicated instance.

### Inbound Private Link

[AWS Private Link](https://docs.aws.amazon.com/vpc/latest/privatelink/what-is-privatelink.html) allows users and applications in your VPC on AWS to securely connect to the GitLab Dedicated endpoint without network traffic going over the public internet.

To enable the Inbound Private Link:

1. In the body of your [support ticket](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650), include the IAM Principal for the AWS user or role in your own AWS Organization that's establishing the VPC endpoint in your AWS account. GitLab Dedicated uses this IAM Principal for access-control. This IAM principal is the only one able to set up an endpoint to the service.
1. After your IAM Principal has been allowlisted, GitLab [creates the Endpoint Service](https://docs.aws.amazon.com/vpc/latest/privatelink/create-endpoint-service.html) and communicates the `Service Endpoint Name` on the support ticket. The service name is generated by AWS upon creation of the service endpoint.
   - GitLab handles the domain verification for the Private DNS name, so that DNS resolution of the tenant instance domain name in your VPC resolves to the PrivateLink endpoint.
   - GitLab makes the Endpoint Service available in the Availability Zones you specified during the initial onboarding. If you did not specify any Availability Zones, GitLab randomly selects the Availability Zones IDs.
1. In your own AWS account, create an [Endpoint Interface](https://docs.aws.amazon.com/vpc/latest/privatelink/create-interface-endpoint.html) in your VPC, with the following settings:
   - Service Endpoint Name: use the name provided by GitLab on the support ticket.
   - Private DNS names enabled: yes.
   - Subnets: choose all matching subnets.

1. After you create the endpoint, use the instance URL provided to you during onboarding to securely connect to your GitLab Dedicated instance from your VPC, without the traffic going over the public internet.

### Outbound Private Link

Outbound Private Links allow the GitLab Dedicated instance to securely communicate with services running in your VPC on AWS. This type of connection can execute [webhooks](../../user/project/integrations/webhooks.md) where the targeted services are running in your VPC, import or mirror projects and repositories, or use any other GitLab functionality to access private services.

To enable an Outbound Private Link:

1. In your [support ticket](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650), GitLab provides you with an IAM role ARN that connects to your endpoint service. You can then add this ARN to the allowlist on your side to restrict connections to your endpoint service.
1. [Create the Endpoint service](https://docs.aws.amazon.com/vpc/latest/privatelink/create-endpoint-service.html) through which your internal service is available to GitLab Dedicated. Provide the associated `Service Endpoint Name` on the [support ticket](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650).
1. When creating the Endpoint service, you must provide GitLab with a [verified Private DNS Name](https://docs.aws.amazon.com/vpc/latest/privatelink/manage-dns-names.html#verify-domain-ownership) for your service. Optionally, if you would like GitLab Dedicated to reach your service via other aliases, you have the ability to specify a list of Private Hosted Zone (PHZ) entries. With this option, GitLab sets up a Private Hosted Zone with DNS names aliased to the verified Private DNS name. To enable this functionality, you must provide GitLab a list of PHZ entries on your support ticket. After the PHZ is created in the tenant environment, DNS resolution of any of the provided records correctly resolves to the PrivateLink endpoint.
1. GitLab then configures the tenant instance to create the necessary Endpoint Interfaces based on the service names you provided. Any outbound calls made from the tenant GitLab instance are directed through the PrivateLink into your VPC.

#### Custom certificates

In some cases, the GitLab Dedicated instance can't reach an internal service you own because it exposes a certificate that can't be validated using a public Certification Authority (CA). In these cases, custom certificates are required.

To request that GitLab add custom certificates when communicating with your services over PrivateLink, attach the custom public certificate files to your [support ticket](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650).

#### Maximum number of reverse PrivateLink connections

GitLab Dedicated limits the number of reverse PrivateLink connections to 10.

### IP allowlist

GitLab Dedicated allows you to control which IP addresses can access your instance through an IP allowlist.

Specify a comma separated list of IP addresses that can access your GitLab Dedicated instance in your [support ticket](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650). After the configuration has been applied, when an IP not on the allowlist tries to access your instance, the connection is refused.

### SAML

NOTE:
GitLab Dedicated supports a limited number of SAML parameters. Parameters not shown in the configuration below are unavailable for GitLab Dedicated tenant instances.

Prerequisites:

- You must configure the identity provider before sending the required data to GitLab.

To activate SAML for your GitLab Dedicated instance:

1. To make the necessary changes, include the desired [SAML configuration block](../../integration/saml.md#configure-saml-support-in-gitlab) for your GitLab application in your [support ticket](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650). At a minimum, GitLab needs the following information to enable SAML for your instance:
   - IDP SSO Target URL
   - Certificate fingerprint or certificate
   - NameID format
   - SSO login button description

   ```json
   "saml": {
     "attribute_statements": {
         //optional
     },
     "enabled": true,
     "groups_attribute": "",
     "admin_groups": [
       // optional
     ],
     "idp_cert_fingerprint": "43:51:43:a1:b5:fc:8b:b7:0a:3a:a9:b1:0f:66:73:a8",
     "idp_sso_target_url": "https://login.example.com/idp",
     "label": "IDP Name",
     "name_identifier_format": "urn:oasis:names:tc:SAML:2.0:nameid-format:persistent",
     "security": {
       // optional
     },
     "auditor_groups": [
       // optional
     ],
     "external_groups": [
       // optional
     ],
     "required_groups": [
       // optional
     ],
   }
   ```

1. After GitLab deploys the SAML configuration to your instance, you are notified on your support ticket.
1. To verify the SAML configuration is successful:
   - Check that the SSO login button description is displayed on your instance's login page.
   - Go to the metadata URL of your instance (`https://INSTANCE-URL/users/auth/saml/metadata`). This page can be used to simplify much of the configuration of the identity provider, as well as manually validate the settings.

#### Request signing

If [SAML request signing](../../integration/saml.md#sign-saml-authentication-requests-optional) is desired, a certificate must be obtained. This certificate can be self-signed which has the advantage of not having to prove ownership of an arbitrary Common Name (CN) to a public Certificate Authority (CA)).
If you choose to enable SAML request signing, the manual steps below will need to be completed before you are able to use SAML, since it requires certificate signing to happen.
To enable SAML request signing, indicate on your SAML [support ticket](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650) that you want request signing enabled. GitLab works with you on sending the Certificate Signing Request (CSR) for you to sign. Alternatively, the CSR can be signed with a public CA. After the certificate is signed, GitLab adds the certificate and its associated private key to the `security` section of the SAML configuration. Authentication requests from GitLab to your identity provider can then be signed.

#### SAML groups

With SAML groups you can configure GitLab users based on SAML group membership.

To enable SAML groups, add the [required elements](../../integration/saml.md#configure-users-based-on-saml-group-membership) to the SAML configuration block you provide in your [support ticket](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650).

#### Group sync

With [group sync](../../user/group/saml_sso/group_sync.md), you can sync users across identity provider groups to mapped groups in GitLab.

To enable group sync:

1. Add the [required elements](../../user/group/saml_sso/group_sync.md#configure-saml-group-sync) to the SAML configuration block you provide in your [support ticket](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650).
1. Configure the [Group Links](../../user/group/saml_sso/group_sync.md#configure-saml-group-links).

### Access to application logs

GitLab [application logs](../../administration/logs/index.md) are delivered to an S3 bucket in the GitLab tenant account, which can be shared with you. Logs stored in the S3 bucket are retained indefinitely, until the 1 year retention policy is fully enforced. GitLab team members can view more information in this confidential issue:
`https://gitlab.com/gitlab-com/gl-infra/gitlab-dedicated/team/-/issues/483`.

To gain read only access to this bucket:

1. Open a [support ticket](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650) with the title "Customer Log Access". In the body of the ticket, include a list of IAM Principal ARNs (users or roles) that are fetching the logs from S3.
1. GitLab then informs you of the name of the S3 bucket. Your nominated users/roles can then able to list and get all objects in the S3 bucket.
