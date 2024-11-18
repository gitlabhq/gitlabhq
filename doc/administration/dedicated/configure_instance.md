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

Any functionality in the GitLab application that is not controlled by the SaaS environment can be configured by using the [**Admin** area](../../administration/admin_area.md).

Examples of SaaS environment settings include `gitlab.rb` configurations and access to shell, Rails console, and PostgreSQL console.
These environment settings cannot be changed by tenants.

GitLab Dedicated Engineers also don't have direct access to tenant environments, except for [break glass situations](../../subscriptions/gitlab_dedicated/index.md#access-controls).

NOTE:
An instance refers to a GitLab Dedicated deployment, whereas a tenant refers to a customer.

## Configure your instance using Switchboard

You can use Switchboard to make limited configuration changes to your GitLab Dedicated instance.

The following configuration settings are available in Switchboard:

- [IP allowlist](#ip-allowlist)
- [SAML settings](#saml)
- [Custom certificates](#custom-certificates)
- [Outbound private links](#outbound-private-link)
- [Private hosted zones](#private-hosted-zones)

Prerequisites:

- You must have the [Admin](#add-users-to-an-instance) role.

To make a configuration change:

1. Sign in to [Switchboard](https://console.gitlab-dedicated.com/).
1. At the top of the page, select **Configuration**.
1. Follow the instructions in the relevant sections below.

For all other instance configurations, submit a support ticket according to the
[configuration change request policy](#configuration-change-request-policy).

### Apply configuration changes in Switchboard

You can apply configuration changes made in Switchboard immediately or defer them until your next scheduled weekly [maintenance window](../../administration/dedicated/maintenance.md#maintenance-windows).

When you apply changes immediately:

- Deployment can take up to 90 minutes.
- Changes are applied in the order they're saved.
- You can save multiple changes and apply them in one batch.

After the deployment job is complete, you receive an email notification. Check your spam folder if you do not see a notification in your main inbox.
All users with access to view or edit your tenant in Switchboard receive a notification for each change. For more information, see [Manage Switchboard notification preferences](#manage-notification-preferences).

NOTE:
You only receive email notifications for changes made by a Switchboard tenant administrator. Changes made by a GitLab Operator (for example, a GitLab version update completed during a maintenance window) do not trigger email notifications.

## Configuration change log

The **Configuration change log** page in Switchboard tracks changes made to your GitLab Dedicated instance.

Each change log entry includes the following details:

| Field                | Description                                                                                                                                   |
|----------------------|-----------------------------------------------------------------------------------------------------------------------------------------------|
| Configuration change | Name of the configuration setting that changed.                                                                                               |
| User                 | Email address of the user that made the configuration change. For changes made by a GitLab Operator, this value appears as `GitLab Operator`. |
| IP                   | IP address of the user that made the configuration change. For changes made by a GitLab Operator, this value appears as `Unavailable`.        |
| Status               | Whether the configuration change is initiated, in progress, completed, or deferred.                                                           |
| Start time           | Start date and time when the configuration change is initiated, in UTC.                                                                       |
| End time             | End date and time when the configuration change is deployed, in UTC.                                                                          |

Each configuration change has a status:

| Status | Description |
|---|---|
| Initiated | Configuration change is made in Switchboard, but not yet deployed to the instance. |
| In progress | Configuration change is actively being deployed to the instance. |
| Complete | Configuration change has been deployed to the instance. |
| Delayed | Initial job to deploy a change has failed and the change has not yet been assigned to a new job. |

### View the configuration change log

To view the configuration change log:

1. Sign in to [Switchboard](https://console.gitlab-dedicated.com/).
1. Select your tenant.
1. At the top of the page, select **Configuration change log**.

Each configuration change appears as an entry in the table. Select **View details** to see more information about each change.

## Configuration change request policy

This policy does not apply to configuration changes made by a GitLab Dedicated instance admin using Switchboard.

Configuration changes requested with a [support ticket](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650) adhere to the following policies:

- Are applied during your environment's weekly four-hour maintenance window.
- Can be requested for options specified during onboarding or for optional features listed on this page.
- May be postponed to the following week if GitLab needs to perform high-priority maintenance tasks.
- Can't be applied outside the weekly maintenance window unless they qualify for [emergency support](https://about.gitlab.com/support/#how-to-engage-emergency-support).

NOTE:
Even if a change request meets the minimum lead time, it might not be applied during the upcoming maintenance window.

## Bring your own domain (BYOD)

You can use a [custom hostname](../../subscriptions/gitlab_dedicated/index.md#bring-your-own-domain) to access your GitLab Dedicated instance. You can also provide a custom hostname for the bundled container registry and Kubernetes Agent Server (KAS) services.

### Let's Encrypt certificates

GitLab Dedicated integrates with [Let's Encrypt](https://letsencrypt.org/), a free, automated, and open source certificate authority. When you use a custom hostname, Let's Encrypt automatically issues and renews SSL/TLS certificates for your domain.

This integration uses the [`http-01` challenge](https://letsencrypt.org/docs/challenge-types/#http-01-challenge) to obtain certificates through Let's Encrypt.

### Set up DNS records

To use a custom hostname with GitLab Dedicated, you must update your domain's DNS records.

Prerequisites:

- Access to your domain host's DNS settings.

To set up DNS records for a custom hostname with GitLab Dedicated:

1. Sign in to your domain host's website.

1. Go to the DNS settings.

1. Add a `CNAME` record that points your custom hostname to your GitLab Dedicated tenant. For example:

   ```plaintext
    gitlab.my-company.com.  CNAME  my-tenant.gitlab-dedicated.com
   ```

1. Optional. If your domain has an existing `CAA` record, update it to include [Let's Encrypt](https://letsencrypt.org/docs/caa/) as a valid certificate authority. If your domain does not have any `CAA` records, you can skip this step. For example:

   ```plaintext
   example.com.  IN  CAA 0 issue "pki.goog"
   example.com.  IN  CAA 0 issue "letsencrypt.org"
   ```

   In this example, the `CAA` record defines Google Trust Services (`pki.goog`) and Let's Encrypt (`letsencrypt.org`) as certificate authorities that are allowed to issue certificates for your domain.

1. Save your changes and wait for the DNS changes to propagate.

### Add your custom hostname

To add a custom hostname to your existing GitLab Dedicated instance, submit a [support ticket](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650).

## SMTP email service

You can configure an [SMTP](../../subscriptions/gitlab_dedicated/index.md#email-service) email service for your GitLab Dedicated instance.

To configure an SMTP email service, submit a [support ticket](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650) with the credentials and settings for your SMTP server.

## Inbound Private Link

[AWS Private Link](https://docs.aws.amazon.com/vpc/latest/privatelink/what-is-privatelink.html) allows users and applications in your VPC on AWS to securely connect to the GitLab Dedicated endpoint without network traffic going over the public internet.

To enable the Inbound Private Link:

1. Open a [support ticket](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650). In the body of your support ticket, include the IAM principals for the AWS users or roles in your AWS organization that are establishing the VPC endpoints in your AWS account. The IAM principals must be [IAM role principals](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_elements_principal.html#principal-roles) or [IAM user principals](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_elements_principal.html#principal-users). GitLab Dedicated uses these IAM Principals for access-control. These IAM principals are the only ones able to set up an endpoint to the service.
1. After your IAM Principals have been allowlisted, GitLab [creates the Endpoint Service](https://docs.aws.amazon.com/vpc/latest/privatelink/create-endpoint-service.html) and communicates the `Service Endpoint Name` on the support ticket. The service name is generated by AWS upon creation of the service endpoint.
   - GitLab handles the domain verification for the Private DNS name, so that DNS resolution of the tenant instance domain name in your VPC resolves to the PrivateLink endpoint.
   - The endpoint service is available in two Availability Zones. These are either the zones you chose during onboarding or two randomly selected zones if you didn't specify any.
1. In your own AWS account, create an [Endpoint Interface](https://docs.aws.amazon.com/vpc/latest/privatelink/create-interface-endpoint.html) in your VPC, with the following settings:
   - Service Endpoint Name: use the name provided by GitLab on the support ticket.
   - Private DNS names enabled: yes.
   - Subnets: choose all matching subnets.

1. After you create the endpoint, use the instance URL provided to you during onboarding to securely connect to your GitLab Dedicated instance from your VPC, without the traffic going over the public internet.

## Outbound Private Link

Outbound private links allow your GitLab Dedicated instance and the hosted runners for GitLab Dedicated to securely communicate with services running in your VPC on AWS without exposing any traffic to the public internet.

This type of connection allows GitLab functionality to access private services:

- For the GitLab Dedicated instance:

  - [webhooks](../../user/project/integrations/webhooks.md)
  - import or mirror projects and repositories

- For hosted runners:

  - custom secrets managers
  - artifacts or job images stored in your infrastructure
  - deployments into your infrastructure

Consider the following:

- You can only establish private links between VPCs in the same region. Therefore, you can only establish a connection in the regions specified for your Dedicated instance.
- The connection requires the [Availability Zone IDs (AZ IDs)](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html#az-ids) for the two Availability Zones (AZs) in the regions that you selected during onboarding.
- If you did not specify any AZs during onboarding to Dedicated, GitLab randomly selects both AZ IDs.

### Add an outbound private link with Switchboard

Prerequisites:

- [Create the endpoint service](https://docs.aws.amazon.com/vpc/latest/privatelink/create-endpoint-service.html) for your internal service to be available to GitLab Dedicated.
- Configure a Network Load Balancer (NLB) for the endpoint service in the Availability Zones (AZs) where your Dedicated instance is deployed. Either:
  - Use the AZs listed in the Outbound private link configuration in Switchboard.
  - Enable the NLB in every AZ in the region.
- Add the ARN of the role that GitLab Dedicated uses to connect to your endpoint service to the Allowed Principals list on the Endpoint Service. You can find this ARN in Switchboard under Outbound private link IAM principal. For more information, see [Manage permissions](https://docs.aws.amazon.com/vpc/latest/privatelink/configure-endpoint-service.html#add-remove-permissions).
- Recommended. Set **Acceptance required** to **No** to enable GitLab Dedicated to connect in a single operation. If set to **Yes**, you must manually accept the connection after it's initiated.

  NOTE:
  If you set **Acceptance required** to **Yes**, Switchboard cannot accurately determine when the link is accepted. After you manually accept the link, the status shows as **Pending** instead of **Active** until next scheduled maintenance. After maintenance, the link status refreshes and shows as connected.

- Once the endpoint service is created, note the Service Name and if you have enabled Private DNS or not.

1. Sign in to [Switchboard](https://console.gitlab-dedicated.com/).
1. At the top of the page, select **Configuration**.
1. Expand **Outbound private link**.
1. Complete the fields.
1. To add endpoint services, select **Add endpoint service**. You can add up to ten endpoint services per region. At least one endpoint service is required to save the region.
1. Select **Save**.
1. Optional. To add an outbound private link for a second region, select **Add outbound connection**, then repeat the previous steps.

### Delete an outbound private link with Switchboard

1. Sign in to [Switchboard](https://console.gitlab-dedicated.com/).
1. At the top of the page, select **Configuration**.
1. Expand **Outbound private link**.
1. Go to the outbound private link you want to delete, then select **Delete** (**{remove}**).
1. Select **Delete**.
1. Optional. To delete all the links in a region, from the region header, select **Delete** (**{remove}**). This also deletes the region configuration.

### Add an outbound private link with a support request

1. [Create the Endpoint service](https://docs.aws.amazon.com/vpc/latest/privatelink/create-endpoint-service.html) through which your internal service
   will be available to GitLab Dedicated. Provide the associated `Service Endpoint Name` on a new
   [support ticket](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650).
1. Make sure you have configured a Network Load Balancer (NLB) for the endpoint service in the two AZs to which your Dedicated instance was deployed. If you did not specify these during onboarding to Dedicated, you must either:
   - Submit a [support ticket](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650) to request the AZ IDs required to enable the connection and ensure the NLB is enabled in those AZs.
   - Ensure the NLB is enabled in every AZ in the region.
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
   - Dedicated can manage a Private Hosted Zone (PHZ) within the Dedicated AWS Account and alias any arbitrary DNS names to the endpoint, directing
     requests for those names to your endpoint service. These aliases are known as PHZ entries. For more information, see [Private hosted zones](#private-hosted-zones).

GitLab then configures the tenant instance to create the necessary Endpoint Interfaces based on the service names you provided. Any matching outbound
connections made from the tenant instance are directed through the PrivateLink into your VPC.

### Private hosted zones

You can use a private hosted zone (PHZ) if:

- You have multiple DNS names or aliases that will be accessed using a single endpoint. For example, if you are running a reverse proxy to connect to more than one service in your environment.
- The domain you want to use is not public and cannot be validated for use by private DNS.

When using your GitLab Dedicated instance's domain as part of an alias, you must include two subdomains before the main domain, where:

- The first subdomain becomes the name of the PHZ.
- The second subdomain becomes the record entry for the alias.

For example:

- Valid PHZ entry: `subdomain2.subdomain1.<your-tenant-id>.gitlab-dedicated.com`.
- Invalid PHZ entry: `subdomain1.<your-tenant-id>.gitlab-dedicated.com`.

When not using your GitLab Dedicated instance domain, you must still provide:

- A Private Hosted Zone (PHZ) name
- A PHZ entry in the format `phz-entry.phz-name.com`

To prevent shadowing of public DNS domains when the domain is created inside the Dedicated tenant, use at least two additional subdomain levels below any public domain for your PHZ entries. For example, if your tenant is hosted at `tenant.gitlab-dedicated.com`, your PHZ entry should be at least `subdomain1.subdomain2.tenant.gitlab-dedicated.com`, or if you own `customer.com` then at least `subdomain1.subdomain2.customer.com`, where `subdomain2` is not a public domain.

#### Add a private hosted zone with Switchboard

To add a private hosted zone:

1. Sign in to [Switchboard](https://console.gitlab-dedicated.com/).
1. At the top of the page, select **Configuration**.
1. Expand **Private hosted zones**.
1. Select **Add private hosted zone entry**.
1. Complete the fields.
   - In the **Hostname** field, enter your Private Hosted Zone (PHZ) entry.
   - For **Link type**, choose one of the following:
     - For an outbound private link PHZ entry, select the endpoint service from the dropdown list.
     Only links with the `Available` or `Pending Acceptance` status are shown.
     - For other PHZ entries, provide a list of DNS aliases.
1. Select **Save**.
Your PHZ entry and any aliases should appear in the list.
1. Scroll to the top of the page, and select whether to apply the changes immediately or during the next maintenance window.

#### Add a private hosted zone with a support request

If you are unable to use Switchboard to add a private hosted zone, you can open a [support ticket](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650) and provide a list of DNS names that should resolve to the endpoint service for the outbound private link. The list can be updated as needed.

## Custom certificates

In some cases, the GitLab Dedicated instance can't reach an internal service you own because it exposes a certificate that can't be validated using a public Certification Authority (CA). In these cases, custom certificates are required.

### Add a custom certificate with Switchboard

1. Sign in to [Switchboard](https://console.gitlab-dedicated.com/).
1. At the top of the page, select **Configuration**.
1. Expand **Custom Certificate Authorities**.
1. Select **+ Add Certificate**.
1. Paste the certificate into the text box.
1. Select **Save**.
1. Scroll up to the top of the page and select whether to apply the changes immediately or during the next maintenance window.

### Add a custom certificate with a Support Request

If you are unable to use Switchboard to add a custom certificate, you can open a [support ticket](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650) and attach your custom public certificate files to request this change..

### Maximum number of reverse PrivateLink connections

GitLab Dedicated limits the number of reverse PrivateLink connections to 10.

## IP allowlist

GitLab Dedicated allows you to control which IP addresses can access your instance through an IP allowlist. Once the IP allowlist has been enabled, when an IP not on the allowlist tries to access your instance an `HTTP 403 Forbidden` response is returned.

IP addresses that have been added to your IP allowlist can be viewed on the Configuration page in Switchboard. You can add or remove IP addresses from your allowlist with Switchboard.

### Add an IP to the allowlist with Switchboard

1. Sign in to [Switchboard](https://console.gitlab-dedicated.com/).
1. At the top of the page, select **Configuration**.
1. Expand **Allowed Source List Config / IP allowlist**.
1. Turn on the **Enable** toggle.
1. Select **Add Item**.
1. Enter the IP address and description. To add another IP address, repeat steps 5 and 6.
1. Select **Save**.
1. Scroll up to the top of the page and select whether to apply the changes immediately or during the next maintenance window. After the changes are applied, the IP addresses are added to the IP allowlist for your instance.

### Add an IP to the allowlist with a Support Request

If you are unable to use Switchboard to update your IP allowlist, you can open a [support ticket](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650) and specify a comma separated list of IP addresses that can access your GitLab Dedicated instance.

### Enable OpenID Connect for your IP allowlist

Using [GitLab as an OpenID Connect identity provider](../../integration/openid_connect_provider.md) requires internet access to the OpenID Connect verification endpoint.

To enable access to the OpenID Connect endpoint while maintaining your IP allowlist:

- In a [support ticket](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650), request to allow access to the OpenID Connect endpoint.

The configuration is applied during the next maintenance window.

### Enable SCIM provisioning for your IP allowlist

You can use SCIM with external identity providers to automatically provision and manage users. To use SCIM, your identity provider must be able to access the [instance SCIM API](../../development/internal_api/index.md#instance-scim-api) endpoints. By default, IP allowlisting blocks communication to these endpoints.

To enable SCIM while maintaining your IP allowlist:

- In a [support ticket](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650), request to enable SCIM endpoints to the internet.

The configuration is applied during the next maintenance window.

### SAML

You can [configure SAML single sign-on (SSO)](../../integration/saml.md#configure-saml-support-in-gitlab) for your GitLab Dedicated instance. Optionally, you can configure more than one SAML identity provider (IdP).

The following SAML SSO options are available:

- [Request signing](../../integration/saml.md#sign-saml-authentication-requests-optional)
- [SAML SSO for groups](../../integration/saml.md#configure-users-based-on-saml-group-membership)
- [Group sync](../../user/group/saml_sso/group_sync.md#configure-saml-group-sync)

Prerequisites:

- You must [set up the identity provider](../../integration/saml.md#set-up-identity-providers) before you can configure SAML for GitLab Dedicated.
- To configure GitLab to sign SAML authentication requests, you must create a private key and public certificate pair for your GitLab Dedicated instance.

NOTE:
You can only configure one SAML IdP with Switchboard. If you configured a SAML IdP on your GitLab Dedicated instance before the introduction of support for multiple IdPs, you can manage that provider through Switchboard. To configure additional SAML IdPs, [submit a support request](#activate-saml-with-a-support-request).

### Activate SAML with Switchboard

To activate SAML for your GitLab Dedicated instance:

1. Sign in to [Switchboard](https://console.gitlab-dedicated.com/).
1. At the top of the page, select **Configuration**.
1. Expand **SAML Config**.
1. Turn on the **Enable** toggle.
1. Complete the required fields:
   - SAML label
   - IdP cert fingerprint
   - IdP SSO target URL
   - Name identifier format
1. To configure users based on [SAML group membership](#saml-groups) or use [group sync](#group-sync), complete the following fields:
   - SAML group attribute
   - Admin groups
   - Auditor groups
   - External groups
   - Required groups
1. To configure [SAML request signing](#request-signing), complete the following fields:
   - Issuer
   - Attribute statements
   - Security
1. Select **Save**.
1. Scroll up to the top of the page and select whether to apply the changes immediately or during the next maintenance window.
1. To use group sync, [configure the SAML group links](../../user/group/saml_sso/group_sync.md#configure-saml-group-links).
1. To verify the SAML configuration is successful:
   - Check that the SSO button description is displayed on your instance's sign-in page.
   - Go to the metadata URL of your instance (`https://INSTANCE-URL/users/auth/saml/metadata`). This page can be used to simplify much of the configuration of the identity provider, and manually validate the settings.

### Activate SAML with a Support Request

If you are unable to use Switchboard to activate or update SAML for your GitLab Dedicated instance, or if you need to configure more than one SAML IdP, then you can open a [support ticket](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650):

1. To make the necessary changes, include the desired [SAML configuration block](../../integration/saml.md#configure-saml-support-in-gitlab) for your GitLab application in your support ticket. At a minimum, GitLab needs the following information to enable SAML for your instance:
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
   - Go to the metadata URL of your instance, which is provided by GitLab in the support ticket. This page can be used to simplify much of the configuration of the identity provider, as well as manually validate the settings.

### Request signing

If [SAML request signing](../../integration/saml.md#sign-saml-authentication-requests-optional) is desired, a certificate must be obtained. This certificate can be self-signed which has the advantage of not having to prove ownership of an arbitrary Common Name (CN) to a public Certificate Authority (CA).

NOTE:
Because SAML request signing requires certificate signing, you must complete these steps to use SAML with this feature enabled.

To enable SAML request signing:

1. Open a [support ticket](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650) and indicate that you want request signing enabled.
1. GitLab will work with you on sending the Certificate Signing Request (CSR) for you to sign. Alternatively, the CSR can be signed with a public CA.
1. After the certificate is signed, you can then use the certificate and its associated private key to complete the `security` section of the [SAML configuration](#activate-saml-with-switchboard) in Switchboard.

Authentication requests from GitLab to your identity provider can now be signed.

### SAML groups

With SAML groups you can configure GitLab users based on SAML group membership.

To enable SAML groups, add the [required elements](../../integration/saml.md#configure-users-based-on-saml-group-membership) to your SAML configuration in [Switchboard](#activate-saml-with-switchboard) or to the SAML block you provide in a [support ticket](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650).

### Group sync

With [group sync](../../user/group/saml_sso/group_sync.md), you can sync users across identity provider groups to mapped groups in GitLab.

To enable group sync:

1. Add the [required elements](../../user/group/saml_sso/group_sync.md#configure-saml-group-sync) to your SAML configuration in [Switchboard](#activate-saml-with-switchboard) or to the SAML configuration block you provide in a [support ticket](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650).
1. Configure the [Group Links](../../user/group/saml_sso/group_sync.md#configure-saml-group-links).

## Add users to an instance

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

### Manage notification preferences

You can specify whether you want to receive email notifications from Switchboard. You will only receive notifications after you:

- Receive an email invitation and first sign in to Switchboard.
- Set up a password and two-factor authentication (2FA) for your user account.

To manage your own email notification preferences:

1. From any page, open the dropdown next to your user name.
1. To stop receiving email notifications, select **Toggle email notifications off**.
1. To resume receiving email notifications, select **Toggle email notifications on**.

You will see an alert confirming that your notification preferences have been updated.

## Application logs

GitLab delivers [application logs](../../administration/logs/index.md) to an Amazon S3 bucket in the GitLab tenant account, which can be shared with you.

Logs stored in the S3 bucket are retained indefinitely, until the one year retention policy is fully enforced. GitLab team members can view more information in confidential issue [483](https://gitlab.com/gitlab-com/gl-infra/gitlab-dedicated/team/-/issues/483).

### Request bucket access

To gain read only access to the S3 bucket with your application logs:

1. Open a [support ticket](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650) with the title `Customer Log Access`.
1. In the body of the ticket, include a list of IAM Principal Amazon Resource Names (users or roles) that require access to the logs from the S3 bucket.

GitLab provides the name of the S3 bucket. Your authorized users or roles can then access all objects in the bucket. To verify access, you can use the [AWS CLI](https://aws.amazon.com/cli/).

### Bucket contents and structure

The Amazon S3 bucket contains a combination of infrastructure logs and application logs from the GitLab [log system](../../administration/logs/index.md).

The logs in the bucket are encrypted using an AWS KMS key managed by GitLab. If you choose to enable [BYOK](../../administration/dedicated/create_instance.md#encrypted-data-at-rest-byok), the application logs are not encrypted with the key you provide.

<!-- vale gitlab_base.Spelling = NO -->

The logs in the S3 bucket are organized by date in `YYYY/MM/DD/HH` format. For example, a directory named `2023/10/12/13` contains logs from October 12, 2023 at 13:00 UTC. The logs are streamed into the bucket with [Amazon Kinesis Data Firehose](https://aws.amazon.com/firehose/).

<!-- vale gitlab_base.Spelling = YES -->

## Troubleshooting

### Outbound Private Link

If you have trouble establishing a connection after the Outbound Private Link has been set up, there are a few things in your AWS infrastructure that could be the cause of the problem. The specific things to check will vary based on the unexpected behavior you're seeking to fix. Things to check include:

- Ensure that cross-zone load balancing is turned on in your Network Load Balancer (NLB).
- Ensure that the Inbound Rules section of the appropriate Security Groups permits traffic from the correct IP ranges.
- Ensure that the inbound traffic is mapped to the correct port on the Endpoint Service.
- In Switchboard, expand **Outbound private link** and confirm that the details appear as you expect.
- Ensure that you have [allowed requests to the local network from webhooks and integrations](../../security/webhooks.md#allow-requests-to-the-local-network-from-webhooks-and-integrations).
