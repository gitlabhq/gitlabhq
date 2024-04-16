---
stage: SaaS Platforms
group: GitLab Dedicated
description: Configure your GitLab Dedicated instance with Switchboard.
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Configure your GitLab Dedicated instance

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab Dedicated

The instructions on this page guide you through configuring your GitLab Dedicated instance, including enabling and updating the settings for [available functionality](../../subscriptions/gitlab_dedicated/index.md#available-features).

Any functionality in the GitLab application that is not controlled by the SaaS environment can be configured by using the [Admin Area](../../administration/admin_area.md).

Examples of SaaS environment settings include `gitlab.rb` configurations and access to shell, Rails console, and PostgreSQL console.
These environment settings cannot be changed by tenants.

GitLab Dedicated Engineers also don't have direct access to tenant environments, except for [break glass situations](../../subscriptions/gitlab_dedicated/index.md#access-controls).

NOTE:
An instance refers to a GitLab Dedicated deployment, whereas a tenant refers to a customer.

## Configuration changes

### Configuration change policy

Configuration changes requested with a [support ticket](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650) are batched up and applied during your environment's weekly four-hour maintenance window.

This policy does not apply to configuration changes made by a GitLab Dedicated instance admin [using Switchboard](#configuration-changes-in-switchboard).

To have a change considered for an upcoming weekly maintenance window, all required information
must be submitted in full two business days before the start of the window.

A configuration change might not be applied during an upcoming weekly maintenance window, even if
it meets the minimum lead time. If GitLab needs to perform high-priority maintenance tasks that
run beyond the maintenance window, configuration changes will be postponed to the following week.

Changes requested with a support ticket cannot be applied outside of a weekly maintenance window unless it qualifies for
[emergency support](https://about.gitlab.com/support/#how-to-engage-emergency-support).

### Configuration changes in Switchboard

Switchboard empowers the user to make limited configuration changes to their GitLab Dedicated instance. As Switchboard matures further configuration changes will be made available.

To change or update the configuration of your GitLab Dedicated instance, use Switchboard following the instructions in the relevant section or open a [support ticket](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650) with your request.

You can request configuration changes for some of the options originally specified during onboarding, or for any of the following optional features.

Configuration changes made with Switchboard can be applied immediately or deferred until your next scheduled weekly [maintenance window](../../administration/dedicated/create_instance.md#maintenance-window).

When applied immediately, changes may take up to 90 minutes to be deployed to your environment. Individual changes are applied in the order they are saved, or you may choose to save several changes at once before applying them in one batch. After your change is deployed, you will receive an email notification. You might have to check your spam folder if it does not show up in your main email folder.

All users with access to view or edit your tenant in Switchboard will receive a notification for each change made. See how to [manage Switchboard notification preferences](#manage-notification-preferences).

NOTE:
You will only receive email notifications for changes made by a Switchboard tenant admin. Changes made by a GitLab Operator (e.g. a GitLab version update completed during a maintenance window) will not result in an email notification.

### Inbound Private Link

[AWS Private Link](https://docs.aws.amazon.com/vpc/latest/privatelink/what-is-privatelink.html) allows users and applications in your VPC on AWS to securely connect to the GitLab Dedicated endpoint without network traffic going over the public internet.

To enable the Inbound Private Link:

1. Open a [support ticket](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650). In the body of your support ticket, include the IAM principal for the AWS user or role in your AWS organization that's establishing the VPC endpoint in your AWS account. The IAM principal must be an [IAM role principal](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_elements_principal.html#principal-roles) or [IAM user principal](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_elements_principal.html#principal-users). GitLab Dedicated uses this IAM Principal for access-control. This IAM principal is the only one able to set up an endpoint to the service.
1. After your IAM Principal has been allowlisted, GitLab [creates the Endpoint Service](https://docs.aws.amazon.com/vpc/latest/privatelink/create-endpoint-service.html) and communicates the `Service Endpoint Name` on the support ticket. The service name is generated by AWS upon creation of the service endpoint.
   - GitLab handles the domain verification for the Private DNS name, so that DNS resolution of the tenant instance domain name in your VPC resolves to the PrivateLink endpoint.
   - GitLab makes the Endpoint Service available in the Availability Zones you specified during the initial onboarding. If you did not specify any Availability Zones, GitLab randomly selects the Availability Zones IDs.
1. In your own AWS account, create an [Endpoint Interface](https://docs.aws.amazon.com/vpc/latest/privatelink/create-interface-endpoint.html) in your VPC, with the following settings:
   - Service Endpoint Name: use the name provided by GitLab on the support ticket.
   - Private DNS names enabled: yes.
   - Subnets: choose all matching subnets.

1. After you create the endpoint, use the instance URL provided to you during onboarding to securely connect to your GitLab Dedicated instance from your VPC, without the traffic going over the public internet.

### Outbound Private Link

NOTE:
If you plan to add a PrivateLink connection (either [inbound](#inbound-private-link) or [outbound](#outbound-private-link)) to your environment, and you require the connections to be available in specific Availability Zones, you must provide up to two [Availability Zone IDs](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html#az-ids) to your account team during onboarding. If not specified, GitLab selects two random Availability Zone IDs where the connections are available.

Consider the following when using Outbound Private Links:

- Outbound Private Links allow the GitLab Dedicated instance to securely communicate with services running in your VPC on AWS. This type of connection
  can execute [webhooks](../../user/project/integrations/webhooks.md) where the targeted services are running in your VPC, import or mirror projects
  and repositories, or use any other GitLab functionality to access private services.
- You can only establish Private Links between VPCs in the same region. Therefore, you can only establish a connection in the regions you selected for
  your Dedicated instance.
- The Network Load Balancer (NLB) that backs the Endpoint Service at your end must be enabled in at least one of the Availability Zones to which your Dedicated instance was
  deployed. This is not the user-facing name such as `us-east-1a`, but the underlying [Availability Zone ID](https://docs.aws.amazon.com/ram/latest/userguide/working-with-az-ids.html).
  If you did not specify these during onboarding to Dedicated, you must either:
  - Ask for the Availability Zone IDs in the ticket you raise to enable the link and ensure the NLB is enabled in those AZs, or
  - Ensure the NLB has is enabled in every Availability Zone in the region.

You can view the `Reverse Private Link IAM Principal` attribute in the **Tenant Details** section of Switchboard.

To enable an Outbound Private Link:

1. [Create the Endpoint service](https://docs.aws.amazon.com/vpc/latest/privatelink/create-endpoint-service.html) through which your internal service
   will be available to GitLab Dedicated. Provide the associated `Service Endpoint Name` on a new
   [support ticket](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650).
1. In your [support ticket](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650), GitLab will provide you with the ARN of an
   IAM role that will be initiating the connection to your endpoint service. You must ensure this ARN is included, or otherwise covered by other
   entries, in the list of "Allowed Principals" on the Endpoint Service, as described by the [AWS documentation](https://docs.aws.amazon.com/vpc/latest/privatelink/configure-endpoint-service.html#add-remove-permissions).
   Though it's optional, you should you add it explicitly, allowing you to set `Acceptance required` to No so that Dedicated can connect in a single operation.
   If you leave `Acceptance required` as Yes, then you must manually accept the connection after Dedicated has initiated it.
1. To connect to services using the Endpoint, the Dedicated services require a DNS name. Private Link automatically creates an internal name, but
   it is machine-generated and not generally directly useful. There are two options available:
   - In your Endpoint Service, enable [Private DNS name](https://docs.aws.amazon.com/vpc/latest/privatelink/manage-dns-names.html), perform the
     required validation, and let GitLab know in the support ticket that you are using this option. If `Acceptance Required` is set to Yes on your
     Endpoint Service, also note this on the support ticket because Dedicated will need to initiate the connection without Private DNS, wait for you
     to confirm it has been accepted, and then update the connection to enable the use of Private DNS.
   - Dedicated can manage a Private Hosted Zone (PHZ) within the Dedicated AWS Account and alias any arbitrary DNS names to the Endpoint, directing
     requests for those names to your Endpoint Service. This may be useful if you have multiple DNS names/aliases that will be accessed using a
     single Endpoint (for example, if you are running a reverse proxy to connect to more than one service in your environment), or if the domain you
     want to use is not public and cannot be validated for use by Private DNS. Let GitLab know on the support ticket if you are using this option and
     provide a list of DNS names that should resolve to the Private Link Endpoint. This list can be updated as needed in future.

GitLab then configures the tenant instance to create the necessary Endpoint Interfaces based on the service names you provided. Any matching outbound
connections made from the tenant instance are directed through the PrivateLink into your VPC.

### Custom certificates

In some cases, the GitLab Dedicated instance can't reach an internal service you own because it exposes a certificate that can't be validated using a public Certification Authority (CA). In these cases, custom certificates are required.

#### Add a custom certificate with Switchboard

1. Log in to [Switchboard](https://console.gitlab-dedicated.com/).
1. At the top of the page, select **Configuration**.
1. Expand **Custom Certificate Authorities**.
1. Select **+ Add Certificate**.
1. Paste the certificate into the text box.
1. Select **Save**.
1. Scroll up to the top of the page and select whether to apply the changes immediately or during the next maintenance window.

#### Add a custom certificate with a Support Request

To request that GitLab add custom certificates when communicating with your services over PrivateLink, attach the custom public certificate files to your [support ticket](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650).

#### Maximum number of reverse PrivateLink connections

GitLab Dedicated limits the number of reverse PrivateLink connections to 10.

### IP allowlist

GitLab Dedicated allows you to control which IP addresses can access your instance through an IP allowlist. Once the IP allowlist has been enabled, when an IP not on the allowlist tries to access your instance an `HTTP 403 Forbidden` response is returned.

IP addresses that have been added to your IP allowlist can be viewed on the Configuration page in Switchboard. You can add or remove IP addresses from your allowlist with Switchboard or a support request.

#### Add an IP to the allowlist with Switchboard

1. Log in to [Switchboard](https://console.gitlab-dedicated.com/).
1. At the top of the page, select **Configuration**.
1. Expand **Allowed Source List Config / IP allowlist**.
1. Turn on the **Enable** toggle.
1. Select **Add Item**.
1. Enter the IP address and description. To add another IP address, repeat steps 5 and 6.
1. Select **Save**.
1. Scroll up to the top of the page and select whether to apply the changes immediately or during the next maintenance window. After the changes are applied, the IP addresses are added to the IP allowlist for your instance.

#### Add an IP to the allowlist with a Support Request

Specify a comma separated list of IP addresses that can access your GitLab Dedicated instance in your [support ticket](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650). The IP addresses are then added to the IP allowlist for your instance.

### SAML

NOTE:
GitLab Dedicated supports a limited number of SAML parameters. Parameters not shown in the configuration below are unavailable for GitLab Dedicated instances.

Prerequisites:

- You must configure the identity provider before sending the required data to GitLab.

#### Activate SAML with Switchboard

To activate SAML for your GitLab Dedicated instance:

1. Log in to [Switchboard](https://console.gitlab-dedicated.com/).
1. At the top of the page, select **Configuration**.
1. Expand **SAML Config**.
1. Turn on the **Enable** toggle.
1. Complete the fields.
1. Select **Save**.
1. Scroll up to the top of the page and select whether to apply the changes immediately or during the next maintenance window.
1. To verify the SAML configuration is successful:
    - Check that the SSO button description is displayed on your instance's sign-in page.
    - Go to the metadata URL of your instance (`https://INSTANCE-URL/users/auth/saml/metadata`). This page can be used to simplify much of the configuration of the identity provider, and manually validate the settings.

#### Activate SAML with a Support Request

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

If [SAML request signing](../../integration/saml.md#sign-saml-authentication-requests-optional) is desired, a certificate must be obtained. This certificate can be self-signed which has the advantage of not having to prove ownership of an arbitrary Common Name (CN) to a public Certificate Authority (CA).
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

### Add users to an instance

Administrators can add Switchboard users to their GitLab Dedicated instance. There are two types of users:

- **Read only**: Users can only view instance data.
- **Admin**: Users can edit the instance configuration and manage users.

To add a new user to your GitLab Dedicated instance:

1. From the **Tenants** page, select **Manage** next to the tenant instance.
1. From the top of the page, select **Users**.
1. Select **New user**.
1. Enter the **Email** and select a **Role** for the user.
1. Select **Create**.

An invitation to use Switchboard is sent to the user.

#### Manage notification preferences

You can specify whether or not you want to receive email notifications from Switchboard.

To manage your own email notification preferences:

1. From any page, open the dropdown next to your user name.
1. To stop receiving email notifications, select **Toggle email notifications off**.
1. To resume receiving email notifications, select **Toggle email notifications on**.

You will see an alert confirming that your notification preferences have been updated.

Switchboard Tenant Admins can also manage email notifications for other users with access to their organization's tenant:

1. From the **Users** page, open the dropdown in the **Email notifications** column next to the user's email.
1. To turn off email notifications for that user, select **No**.
1. To turn on email notifications for that user, select **Yes**.

You will see an alert confirming that your notification preferences have been updated.

### Access to application logs

GitLab [application logs](../../administration/logs/index.md) are delivered to an S3 bucket in the GitLab tenant account, which can be shared with you. Logs stored in the S3 bucket are retained indefinitely, until the 1 year retention policy is fully enforced. GitLab team members can view more information in this confidential issue:
`https://gitlab.com/gitlab-com/gl-infra/gitlab-dedicated/team/-/issues/483`.

To gain read only access to this bucket:

1. Open a [support ticket](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650) with the title "Customer Log Access". In the body of the ticket, include a list of IAM Principal ARNs (users or roles) that are fetching the logs from S3.
1. GitLab then informs you of the name of the S3 bucket. Your nominated users/roles are then able to list and get all objects in the S3 bucket.

You can use the [AWS CLI](https://aws.amazon.com/cli/) to verify that access to the S3 bucket works as expected.

#### Bucket contents and structure

The S3 bucket contains a combination of **infrastructure logs** and **application logs** from the GitLab [log system](../../administration/logs/index.md). The logs in the bucket are encrypted using an AWS KMS key that is managed by GitLab. If you choose to enable [BYOK](../../administration/dedicated/create_instance.md#encrypted-data-at-rest-byok), the application logs are not encrypted with the key you provide.

The logs in the S3 bucket are organized by date in `YYYY/MM/DD/HH` format. For example, there would be a directory like `2023/10/12/13`. That directory would contain the logs from October 12, 2023 at 1300 UTC. The logs are streamed into the bucket with [Amazon Kinesis Data Firehose](https://aws.amazon.com/firehose/).
