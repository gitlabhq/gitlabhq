---
stage: GitLab Dedicated
group: Switchboard
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Configure network access and security settings for GitLab Dedicated.
title: GitLab Dedicated network access and security
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Dedicated

{{< /details >}}

## Bring your own domain (BYOD)

You can use a [custom hostname](../../../subscriptions/gitlab_dedicated/_index.md#bring-your-own-domain) to access your GitLab Dedicated instance. You can also provide a custom hostname for the bundled container registry and Kubernetes Agent Server (KAS) services.

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

{{< alert type="note" >}}

DNS records must stay in place as long as you use the BYOD feature.

{{< /alert >}}

### DNS requirements for Let's Encrypt certificates

When using custom hostnames with GitLab Dedicated, your domain must be publicly resolvable
through DNS, even if you plan to access your instance through private networks only.

This public DNS requirement exists because:

- Let's Encrypt uses the HTTP-01 challenge, which requires public internet access to verify
  domain ownership.
- The validation process must reach your custom hostname from the public internet through
  the CNAME record that points to your GitLab Dedicated tenant.
- Certificate renewal happens automatically every 90 days and uses the same public
  validation process as the initial issuance.

For instances configured with private networking (such as AWS PrivateLink), maintaining public
DNS resolution ensures certificate renewal works properly, even when all other access is
restricted to private networks.

### Add your custom hostname

To add a custom hostname to your existing GitLab Dedicated instance, submit a [support ticket](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650).

## Custom certificates

Custom certificates establish trust between your GitLab Dedicated instance and certificates signed by non-public Certificate Authorities (CA). If you want to connect to a service that uses a certificate signed by a private or internal CA, you must first add that certificate to your GitLab Dedicated instance.

### Add a custom certificate with Switchboard

1. Sign in to [Switchboard](https://console.gitlab-dedicated.com/).
1. At the top of the page, select **Configuration**.
1. Expand **Custom Certificate Authorities**.
1. Select **+ Add Certificate**.
1. Paste the certificate into the text box.
1. Select **Save**.
1. Scroll up to the top of the page and select whether to apply the changes immediately or during the next maintenance window.

### Add a custom certificate with a Support Request

If you are unable to use Switchboard to add a custom certificate, you can open a [support ticket](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650) and attach your custom public certificate files to request this change.

## AWS Private Link connectivity

### Inbound Private Link

[AWS Private Link](https://docs.aws.amazon.com/vpc/latest/privatelink/what-is-privatelink.html) allows users and applications in your VPC on AWS to securely connect to the GitLab Dedicated endpoint without network traffic going over the public internet.

To enable the Inbound Private Link:

1. Open a [support ticket](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650). In the body of your support ticket, include the IAM principals for the AWS users or roles in your AWS organization that are establishing the VPC endpoints in your AWS account. The IAM principals must be [IAM role principals](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_elements_principal.html#principal-roles) or [IAM user principals](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_elements_principal.html#principal-users). GitLab Dedicated uses these IAM Principals for access-control. These IAM principals are the only ones able to set up an endpoint to the service.
1. After your IAM Principals have been allowlisted, GitLab [creates the Endpoint Service](https://docs.aws.amazon.com/vpc/latest/privatelink/create-endpoint-service.html) and communicates the `Service Endpoint Name` on the support ticket. The service name is generated by AWS upon creation of the service endpoint.
   - GitLab handles the domain verification for the Private DNS name, so that DNS resolution of the tenant instance domain name in your VPC resolves to the PrivateLink endpoint.
   - The endpoint service is available in two Availability Zones. These Availability Zones are either the zones you chose during onboarding, or if you did not specify any, two randomly selected zones.
1. In your own AWS account, create an [Endpoint Interface](https://docs.aws.amazon.com/vpc/latest/privatelink/create-interface-endpoint.html) in your VPC, with the following settings:
   - Service Endpoint Name: use the name provided by GitLab on the support ticket.
   - Private DNS names enabled: yes.
   - Subnets: choose all matching subnets.

1. After you create the endpoint, use the instance URL provided to you during onboarding to securely connect to your GitLab Dedicated instance from your VPC, without the traffic going over the public internet.

### Outbound Private Link

Outbound private links allow your GitLab Dedicated instance and the hosted runners for GitLab Dedicated to securely communicate with services running in your VPC on AWS without exposing any traffic to the public internet.

This type of connection allows GitLab functionality to access private services:

- For the GitLab Dedicated instance:

  - [webhooks](../../../user/project/integrations/webhooks.md)
  - import or mirror projects and repositories

- For hosted runners:

  - custom secrets managers
  - artifacts or job images stored in your infrastructure
  - deployments into your infrastructure

Consider the following:

- You can only establish private links between VPCs in the same region. Therefore, you can only establish a connection in the regions specified for your Dedicated instance.
- The connection requires the [Availability Zone IDs (AZ IDs)](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html#az-ids) for the two Availability Zones (AZs) in the regions that you selected during onboarding.
- If you did not specify any AZs during onboarding to Dedicated, GitLab randomly selects both AZ IDs. AZ IDs are displayed in Switchboard on the Overview page for both the Primary and Secondary regions.
- GitLab Dedicated limits the number of outbound private link connections to 10.

#### Add an outbound private link with Switchboard

Prerequisites:

- [Create the endpoint service](https://docs.aws.amazon.com/vpc/latest/privatelink/create-endpoint-service.html) for your internal service to be available to GitLab Dedicated.
- Configure a Network Load Balancer (NLB) for the endpoint service in the Availability Zones (AZs) where your Dedicated instance is deployed. Either:
  - Use the configured AZs. AZ IDs are displayed on the Overview page in Switchboard.
  - Enable the NLB in every AZ in the region.
- Add the ARN of the role that GitLab Dedicated uses to connect to your endpoint service to the Allowed Principals list on the Endpoint Service. You can find this ARN in Switchboard under Outbound private link IAM principal. For more information, see [Manage permissions](https://docs.aws.amazon.com/vpc/latest/privatelink/configure-endpoint-service.html#add-remove-permissions).
- Recommended. Set **Acceptance required** to **No** to enable GitLab Dedicated to connect in a single operation. If set to **Yes**, you must manually accept the connection after it's initiated.

  {{< alert type="note" >}}

  If you set **Acceptance required** to **Yes**, Switchboard cannot accurately determine when the link is accepted. After you manually accept the link, the status shows as **Pending** instead of **Active** until next scheduled maintenance. After maintenance, the link status refreshes and shows as connected.

  {{< /alert >}}

- Once the endpoint service is created, note the Service Name and if you have enabled Private DNS or not.

1. Sign in to [Switchboard](https://console.gitlab-dedicated.com/).
1. At the top of the page, select **Configuration**.
1. Expand **Outbound private link**.
1. Complete the fields.
1. To add endpoint services, select **Add endpoint service**. You can add up to ten endpoint services for each region. At least one endpoint service is required to save the region.
1. Select **Save**.
1. Optional. To add an outbound private link for a second region, select **Add outbound connection**, then repeat the previous steps.

#### Delete an outbound private link with Switchboard

1. Sign in to [Switchboard](https://console.gitlab-dedicated.com/).
1. At the top of the page, select **Configuration**.
1. Expand **Outbound private link**.
1. Go to the outbound private link you want to delete, then select **Delete** ({{< icon name="remove" >}}).
1. Select **Delete**.
1. Optional. To delete all the links in a region, from the region header, select **Delete** ({{< icon name="remove" >}}). This also deletes the region configuration.

#### Add an outbound private link with a support request

1. [Create the Endpoint service](https://docs.aws.amazon.com/vpc/latest/privatelink/create-endpoint-service.html) through which your internal service
   will be available to GitLab Dedicated. Provide the associated `Service Endpoint Name` on a new
   [support ticket](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650).
1. Configure a Network Load Balancer (NLB) for the endpoint service in the Availability Zones (AZs) where your Dedicated instance is deployed. Either:
   - Use the configured AZs. AZ IDs are displayed on the Overview page in Switchboard.
   - Enable the NLB in every AZ in the region.
1. In your [support ticket](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650), GitLab will provide you with the ARN of an
   IAM role that will be initiating the connection to your endpoint service. You must ensure this ARN is included, or otherwise covered by other
   entries, in the list of "Allowed Principals" on the Endpoint Service, as described by the [AWS documentation](https://docs.aws.amazon.com/vpc/latest/privatelink/configure-endpoint-service.html#add-remove-permissions).
   Though it's optional, you should you add it explicitly, allowing you to set `Acceptance required` to No so that Dedicated can connect in a single operation.
   If you leave `Acceptance required` as Yes, then you must manually accept the connection after Dedicated has initiated it.
1. To connect to services using the Endpoint, the Dedicated services require a DNS name. Private Link automatically creates an internal name, but
   it is machine-generated and not generally directly useful. Two options are available:
   - In your Endpoint Service, enable [Private DNS name](https://docs.aws.amazon.com/vpc/latest/privatelink/manage-dns-names.html), perform the
     required validation, and let GitLab know in the support ticket that you are using this option. If `Acceptance Required` is set to Yes on your
     Endpoint Service, also note this on the support ticket because Dedicated will have to initiate the connection without Private DNS, wait for you
     to confirm it has been accepted, and then update the connection to enable the use of Private DNS.
   - Dedicated can manage a Private Hosted Zone (PHZ) within the Dedicated AWS Account and alias any arbitrary DNS names to the endpoint, directing
     requests for those names to your endpoint service. These aliases are known as PHZ entries. For more information, see [Private hosted zones](#private-hosted-zones).

GitLab then configures the tenant instance to create the necessary Endpoint Interfaces based on the service names you provided. Any matching outbound
connections made from the tenant instance are directed through the PrivateLink into your VPC.

#### Troubleshooting

If you have trouble establishing a connection after the Outbound Private Link has been set up, a few things in your AWS infrastructure could be the cause of the problem. The specific things to check vary based on the unexpected behavior you're seeking to fix. Things to check include:

- Ensure that cross-zone load balancing is turned on in your Network Load Balancer (NLB).
- Ensure that the Inbound Rules section of the appropriate Security Groups permits traffic from the correct IP ranges.
- Ensure that the inbound traffic is mapped to the correct port on the Endpoint Service.
- In Switchboard, expand **Outbound private link** and confirm that the details appear as you expect.
- Ensure that you have [allowed requests to the local network from webhooks and integrations](../../../security/webhooks.md#allow-requests-to-the-local-network-from-webhooks-and-integrations).

## Private hosted zones

A private hosted zone (PHZ) creates custom DNS aliases (CNAMEs) that resolve in your GitLab Dedicated instance's network.

Use a PHZ when you want to:

- Create multiple DNS names or aliases that use a single endpoint, such as when running a reverse proxy to connect to multiple services.
- Use a private domain that cannot be validated by public DNS.

PHZs are commonly used with reverse PrivateLink to create readable domain names instead of using AWS-generated endpoint names. For example, you can use `alpha.beta.tenant.gitlab-dedicated.com` instead of `vpce-0987654321fedcba0-k99y1abc.vpce-svc-0a123bcd4e5f678gh.eu-west-1.vpce.amazonaws.com`.

In some cases, you can also use PHZs to create aliases that resolve to publicly accessible DNS names. For example, you can create an internal DNS name that resolves to a public endpoint when you need internal systems to access a service through its private name.

{{< alert type="note" >}}

Changes to private hosted zones can disrupt services that use these records for up to five minutes.

{{< /alert >}}

### PHZ domain structure

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

### Add a private hosted zone with Switchboard

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

### Add a private hosted zone with a support request

If you are unable to use Switchboard to add a private hosted zone, you can open a [support ticket](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650) and provide a list of DNS names that should resolve to the endpoint service for the outbound private link. The list can be updated as needed.

## IP allowlist

GitLab Dedicated allows you to control which IP addresses can access your instance through an IP allowlist. Once the IP allowlist has been enabled, when an IP not on the allowlist tries to access your instance an `HTTP 403 Forbidden` response is returned.

IP addresses that have been added to your IP allowlist can be viewed on the Configuration page in Switchboard. You can add or remove IP addresses from your allowlist with Switchboard.

### Add an IP to the allowlist with Switchboard

1. Sign in to [Switchboard](https://console.gitlab-dedicated.com/).
1. At the top of the page, select **Configuration**.
1. Expand **Allowed Source List Config / IP allowlist**.
1. Turn on the **Enable** toggle.
1. To add an IP address:

   1. Select **Add Item**.
   1. In the **Address** text box, enter either:
      - A single IPv4 address (for example, `192.168.1.1`).
      - An IPv4 address range in CIDR notation (for example, `192.168.1.0/24`).
   1. In the **Description** text box, enter a description.

   To add another address or range, repeat this step. IPv6 addresses are not supported.

1. Select **Save**.
1. Scroll up to the top of the page and select whether to apply the changes immediately or during the next maintenance window. After the changes are applied, the IP addresses are added to the IP allowlist for your instance.

### Add an IP to the allowlist with a Support Request

If you are unable to use Switchboard to update your IP allowlist, you can open a [support ticket](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650) and specify a comma separated list of IP addresses that can access your GitLab Dedicated instance.

### Enable OpenID Connect for your IP allowlist

Using [GitLab as an OpenID Connect identity provider](../../../integration/openid_connect_provider.md) requires internet access to the OpenID Connect verification endpoint.

To enable access to the OpenID Connect endpoint while maintaining your IP allowlist:

- In a [support ticket](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650), request to allow access to the OpenID Connect endpoint.

The configuration is applied during the next maintenance window.

### Enable SCIM provisioning for your IP allowlist

You can use SCIM with external identity providers to automatically provision and manage users. To use SCIM, your identity provider must be able to access the instance SCIM API endpoints. By default, IP allowlisting blocks communication to these endpoints.

To enable SCIM while maintaining your IP allowlist:

- In a [support ticket](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650), request to enable SCIM endpoints to the internet.

The configuration is applied during the next maintenance window.
