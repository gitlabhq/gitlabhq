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

Any functionality in the GitLab application that is not controlled by the SaaS environment can be configured by using the [Admin Panel](../../user/admin_area/index.md).

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

When onboarding, you must also specify your preference for the weekly four-hour time slot that GitLab uses to perform maintenance and upgrade operations on the tenant instance.

- APAC (outside working hours): Wednesday 1pm-5pm UTC
- EU (outside working hours): Tuesday 1am-5am UTC
- AMER (outside working hours): Tuesday 7am-11am UTC

NOTE:
Some downtime may be incurred during this window. This downtime is not counting towards [the system SLA](https://about.gitlab.com/handbook/engineering/infrastructure/team/gitlab-dedicated/slas/).

## Configuration changes

To change or update the configuration for your GitLab Dedicated instance, open a [support ticket](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650) with your request. You can request configuration changes for the options originally specified during onboarding, or for any of the optional features below.

The turnaround time for processing configuration change requests is [documented in the GitLab handbook](https://about.gitlab.com/handbook/engineering/infrastructure/team/gitlab-dedicated/#handling-configuration-changes-for-tenant-environments).

### Encrypted Data At Rest (BYOK)

If you want your GitLab data to be encrypted at rest, the KMS keys used must be accessible by GitLab services. KMS keys can be used in two modes for this purpose:

1. Per-service KMS keys (Backup, EBS, RDS, S3), or
1. One KMS key for all services.

If you use a key per service, all services must be encrypted at rest. Selective enablement of this feature is not supported.

The keys provided have to reside in the same primary and secondary region specified during [onboarding](#onboarding).

For instructions on how to create and manage KMS keys, visit [Managing keys](https://docs.aws.amazon.com/kms/latest/developerguide/getting-started.html) in the AWS KMS documentation.

To create a KMS key using the AWS Console:

1. In `Configure key`, select:
    1. Key type: **Symmetrical**
    1. Key usage: **Encrypt and decrypt**
    1. `Advanced options`:
        1. Key material origin: **KMS**
        1. Regionality: **Multi-Region key**
1. Enter your values for key alias, description, and tags.
1. Select Key administrators (optionally allow or deny key administrators to delete the key).
1. For Key usage permissions, add the GitLab AWS account using the **Other AWS accounts** dialog.

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

### Inbound Private Link

[AWS Private Link](https://docs.aws.amazon.com/vpc/latest/privatelink/what-is-privatelink.html) allows users and applications in your VPC on AWS to securely connect to the GitLab Dedicated endpoint without network traffic going over the public internet.

To enable the Inbound Private Link:

1. In the body of your [support ticket](#configuration-changes), include the IAM Principal for the AWS user or role in your own AWS Organization that's establishing the VPC endpoint in your AWS account. GitLab Dedicated uses this IAM Principal for access-control. This IAM principal is the only one able to set up an endpoint to the service.
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

1. In your [support ticket](#configuration-changes), GitLab provides you with an IAM role ARN that connects to your endpoint service. You can then add this ARN to the allowlist on your side to restrict connections to your endpoint service.
1. [Create the Endpoint service](https://docs.aws.amazon.com/vpc/latest/privatelink/create-endpoint-service.html) through which your internal service is available to GitLab Dedicated. Provide the associated `Service Endpoint Name` on the [support ticket](#configuration-changes).
1. When creating the Endpoint service, you must provide GitLab with a [verified Private DNS Name](https://docs.aws.amazon.com/vpc/latest/privatelink/manage-dns-names.html#verify-domain-ownership) for your service. Optionally, if you would like GitLab Dedicated to reach your service via other aliases, you have the ability to specify a list of Private Hosted Zone (PHZ) entries. With this option, GitLab sets up a Private Hosted Zone with DNS names aliased to the verified Private DNS name. To enable this functionality, you must provide GitLab a list of PHZ entries on your support ticket. After the PHZ is created in the tenant environment, DNS resolution of any of the provided records correctly resolves to the PrivateLink endpoint.
1. GitLab then configures the tenant instance to create the necessary Endpoint Interfaces based on the service names you provided. Any outbound calls made from the tenant GitLab instance are directed through the PrivateLink into your VPC.

#### Custom certificates

In some cases, the GitLab Dedicated instance can't reach an internal service you own because it exposes a certificate that can't be validated using a public Certification Authority (CA). In these cases, custom certificates are required.

To request that GitLab add custom certificates when communicating with your services over PrivateLink, attach the custom public certificate files to your [support ticket](#configuration-changes).

#### Maximum number of reverse PrivateLink connections

GitLab Dedicated limits the number of reverse PrivateLink connections to 10.

### IP allowlist

GitLab Dedicated allows you to control which IP addresses can access your instance through an IP allowlist.

Specify a comma separated list of IP addresses that can access your GitLab Dedicated instance in your [support ticket](#configuration-changes). After the configuration has been applied, when an IP not on the allowlist tries to access your instance, the connection is refused.

### SAML

Prerequisites:

- You must configure the identity provider before sending the required data to GitLab.

To activate SAML for your GitLab Dedicated instance:

1. To make the necessary changes, include the desired [SAML configuration block](../../integration/saml.md#configure-saml-support-in-gitlab) for your GitLab application in your [support ticket](#configuration-changes). At a minimum, GitLab needs the following information to enable SAML for your instance:
   - Assertion consumer service URL
   - Certificate fingerprint or certificate
   - NameID format
   - SSO login button description

1. After GitLab deploys the SAML configuration to your instance, you are notified on your support ticket.
1. To verify the SAML configuration is successful:
   - Check that the SSO login button description is displayed on your instance's login page.
   - Go to the metadata URL of your instance (`https://INSTANCE-URL/users/auth/saml/metadata`). This page can be used to simplify much of the configuration of the identity provider, as well as manually validate the settings.

#### Request signing

If [SAML request signing](../../integration/saml.md#sign-saml-authentication-requests-optional) is desired, a certificate must be obtained. This certificate can be self-signed which has the advantage of not having to prove ownership of an arbitrary Common Name (CN) to a public Certificate Authority (CA)).

To enable SAML request signing, indicate on your SAML [support ticket](#configuration-changes) that you want request signing enabled. GitLab works with you on sending the Certificate Signing Request (CSR) for you to sign. Alternatively, the CSR can be signed with a public CA. After the certificate is signed, GitLab adds the certificate and its associated private key to the `security` section of the SAML configuration. Authentication requests from GitLab to your identity provider can then be signed.

#### SAML groups

With SAML groups you can configure GitLab users based on SAML group membership.

To enable SAML groups, add the [required elements](../../integration/saml.md#configure-users-based-on-saml-group-membership) to the SAML configuration block you provide in your [support ticket](#configuration-changes).

#### Group sync

With [group sync](../../user/group/saml_sso/group_sync.md), you can sync users across identity provider groups to mapped groups in GitLab.

To enable group sync:

1. Add the [required elements](../../user/group/saml_sso/group_sync.md#configure-saml-group-sync) to the SAML configuration block you provide in your [support ticket](#configuration-changes).
1. Configure the [Group Links](../../user/group/saml_sso/group_sync.md#configure-saml-group-links).

### Access to application logs

GitLab [application logs](../../administration/logs/index.md) are delivered to an S3 bucket in the GitLab tenant account, which can be shared with you.

To gain read only access to this bucket:

1. Open a [support ticket](#configuration-changes) with the title "Customer Log Access". In the body of the ticket, include a list of IAM Principal ARNs (users or roles) that are fetching the logs from S3.
1. GitLab then informs you of the name of the S3 bucket. Your nominated users/roles can then able to list and get all objects in the S3 bucket.
