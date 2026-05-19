---
stage: GitLab Dedicated
group: Switchboard
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Configure custom domains, certificate authorities, private network connectivity, IP allowlists, and NAT gateway IPs for GitLab Dedicated.
title: GitLab Dedicated network access and security
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Dedicated

{{< /details >}}

Use these settings to control how your GitLab Dedicated instance connects to the internet
and to your private infrastructure. You can configure custom domains, manage certificate
authorities for external services, set up private network connectivity with AWS PrivateLink,
restrict access with an IP allowlist, and view the outbound IPs your instance uses.

## Custom domains

You can configure a custom domain to access your GitLab Dedicated
instance instead of the default `your-tenant.gitlab-dedicated.com`.

When you add a custom domain:

- The domain is included in the external URL used to access your instance.
- Any connections to your instance using the default `tenant.gitlab-dedicated.com` domain
  are no longer available.

GitLab automatically manages SSL/TLS certificates for your custom domain using
[Let's Encrypt](https://letsencrypt.org/). Let's Encrypt uses the
[HTTP-01 challenge](https://letsencrypt.org/docs/challenge-types/#http-01-challenge)
to verify domain ownership, which requires:

- The CNAME record to be publicly resolvable through DNS.
- The same public validation process for automatic certificate renewal every 90 days.

For instances configured with private networking (such as AWS PrivateLink), public DNS
resolution ensures certificate management works properly, even when all other access is
restricted to private networks.

GitLab Dedicated supports custom domains through two configuration methods:

- Standard configuration: Uses CNAME records and Let's Encrypt certificates.
  You configure your own DNS records and request domain activation through support.
- Cloudflare security configuration: Uses NS records and Let's Encrypt certificates.
  GitLab provides DNS configuration details and you implement them in coordination with
  support.

Contact your Customer Success Manager to determine which configuration method applies to
your instance.

### View your custom domain details

The **Custom domains** section displays the active domain configuration for your GitLab
Dedicated instance, including:

- **GitLab instance domain**: The custom domain for your GitLab instance.
- **Registry domain**: The custom domain for the container registry.
- **KAS domain**: The custom domain for the GitLab agent server for Kubernetes (KAS).

Use this information to:

- Verify your current custom domain configuration.
- Reference domains for external integrations.
- Copy configuration details for DNS management.

To view your custom domain details:

1. Sign in to [Switchboard](https://console.gitlab-dedicated.com/).
1. Select the **Configuration** tab.
1. Expand **Custom domains**.

#### DNSSEC details

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Dedicated for Government

{{< /details >}}

If your custom domain is configured with Cloudflare Web Application Firewall (WAF),
Switchboard displays additional configuration details, including Cloudflare nameservers
and DNSSEC parameters for FedRAMP compliance.

The additional details include:

- Cloudflare nameservers: DNS nameservers for Cloudflare-managed domains.
- Key tag: Numeric identifier for the DNSSEC key.
- Algorithm: Cryptographic algorithm used (typically 13 for ECDSA P-256 with SHA-256).
- Digest type: Hash algorithm used (typically 2 for SHA-256).
- Digest: Cryptographic hash of the public key.

Use these values to configure DNS delegation and DNSSEC validation with your DNS provider.

### Standard configuration

With this configuration, your domain connects directly to your GitLab instance using a
CNAME record. You configure your own DNS records and request domain activation through
support.

> [!note]
> Your custom domain must be accessible from the public internet for SSL certificate
> management, even if you access your instance through private networks.

#### Configure DNS records

Prerequisites:

- Access to your domain host's DNS settings.

To configure DNS records:

1. Sign in to your domain host's website.
1. Go to the DNS settings.
1. Add a `CNAME` record that points your custom domain to your GitLab Dedicated
   instance. For example:

   ```plaintext
   gitlab.my-company.com.  CNAME  my-tenant.gitlab-dedicated.com
   ```

1. Optional. If your domain has an existing `CAA` record, update it to include
   Let's Encrypt as a valid certificate authority. For example:

   ```plaintext
   gitlab.my-company.com.  IN  CAA 0 issue "pki.goog"
   gitlab.my-company.com.  IN  CAA 0 issue "letsencrypt.org"
   ```

   The `CAA` record defines which certificate authorities can issue certificates for
   your domain.

1. Save your changes and wait for DNS changes to take effect.

Keep your DNS records in place as long as you use the custom domain.

#### Enable a custom domain

Prerequisites:

- You have configured the DNS records.

To enable your custom domain:

1. Submit a [support ticket](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650).
1. In your support ticket, specify:
   - Your custom domain name. For example, `gitlab.company.com`.
   - If you need custom domains for the container registry and GitLab agent server for
     Kubernetes, include the domain names you want to use. For example,
     `registry.company.com` and `kas.company.com`.

### Cloudflare security configuration

With this configuration, your domain must be delegated to GitLab using NS records,
which allows traffic to be routed through Cloudflare Web Application Firewall (WAF).
Cloudflare manages all DNS settings for your domain and provides enhanced security
features.

> [!note]
> This approach requires coordination with your Customer Success Manager.
> The configuration is applied during your instance's maintenance period.

#### Request a custom domain

To request a custom domain:

1. Submit a [support ticket](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650).
1. In your support ticket, specify:
   - Your custom domain name. For example, `gitlab.company.com`.
   - If you need custom domains for the container registry and GitLab agent server for
     Kubernetes, include the domain names you want to use. For example,
     `registry.company.com` and `kas.company.com`.
   - Your compliance requirements. For example, FedRAMP.

GitLab configures your domain in Cloudflare and provides:

- Two Cloudflare nameservers, like `name1.ns.cloudflare.com` and
  `name2.ns.cloudflare.com`.
- DNSSEC parameters (FedRAMP customers only), including:
  - Key tag: Numeric identifier (provided by GitLab)
  - Algorithm: Typically 13 (ECDSA P-256 with SHA-256) or 8 (RSA/SHA-256)
  - Digest type: Typically 2 (SHA-256)
  - Digest: Cryptographic hash of the public key (provided by GitLab)

#### Configure DNS records

Configure NS records in your DNS provider to delegate your subdomain to Cloudflare.

Prerequisites:

- Access to your domain host's DNS settings.
- GitLab has provided nameservers and DNSSEC parameters (if applicable).

To configure DNS records:

1. Sign in to your domain host's website.
1. Go to the DNS settings.
1. Create NS records using the nameservers provided by GitLab. For example:

   ```plaintext
   gitlab.company.com.     NS    name1.ns.cloudflare.com.
   gitlab.company.com.     NS    name2.ns.cloudflare.com.
   ```

1. Remove any conflicting A, AAAA, or CNAME records for the same subdomain.
1. FedRAMP customers only. Add a DS record using the values provided by GitLab:

   ```plaintext
   gitlab.company.com.     DS    [Key Tag] [Algorithm] [Digest Type] [Digest]
   ```

   For example:

   ```plaintext
   gitlab.company.com.     DS    12345 13 2 A1B2C3D4E5F6...
   ```

1. Save your changes. DNS changes can take up to 48 hours to take effect.
1. Verify your configuration:

   ```shell
   # Verify nameserver delegation
   dig +short NS gitlab.company.com

   # Verify DNS resolution
   dig gitlab.company.com

   # Verify DNSSEC (if configured)
   dig +dnssec gitlab.company.com
   ```

1. Notify GitLab through your support ticket that DNS configuration is complete.

GitLab then:

- Verifies DNS delegation.
- Configures SSL/TLS certificates.
- Confirms when your custom domain is active.

## Container registry network access

The container registry FQDN (Fully Qualified Domain Name) identifies the S3 bucket that
stores your instance's container registry data.

### View your container registry FQDN

Use the FQDN instead of IP addresses to configure firewall rules and network policies
that reference the registry storage location. IP addresses for S3 buckets can change
over time.

To view your container registry FQDN:

1. Sign in to [Switchboard](https://console.gitlab-dedicated.com/).
1. Select the **Configuration** tab.
1. Expand **Resource access**.
1. Under **Container registry**, select **Copy to clipboard**
   ({{< icon name="copy-to-clipboard" >}}).

## Custom certificate authorities for external services

GitLab Dedicated validates certificates when connecting to external services over HTTPS.
By default, GitLab Dedicated trusts only publicly recognized certificate authorities and
rejects connections to services with certificates from untrusted certificate authorities.

If your external services use certificates from a private or internal certificate
authority, you must add that certificate authority to your GitLab Dedicated instance.

You might need custom certificate authorities to:

- Connect to internal webhook endpoints.
- Pull images from private container registries.
- Integrate with on-premises services behind corporate public key infrastructure.

### Add a custom certificate

Certificate chain blocks (multiple certificates in a single text block) are not
supported. If you have multiple certificates in your chain, add each certificate
separately.

To add a custom certificate:

1. Sign in to [Switchboard](https://console.gitlab-dedicated.com/).
1. At the top of the page, select **Configuration**.
1. Expand **Custom certificate authorities**.
1. Select **+ Add Certificate**.
1. Paste a single certificate into the text box. Include the
   `-----BEGIN CERTIFICATE-----` and `-----END CERTIFICATE-----` lines.
1. Select **Save**.
1. Repeat steps 4-6 for each additional certificate in your chain.
1. Scroll up to the top of the page and select whether to apply the changes immediately
   or during the next maintenance window.

If you cannot use Switchboard to add a custom certificate, open a
[support ticket](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650)
and attach each custom certificate as a separate file.

## AWS PrivateLink connectivity

AWS PrivateLink enables private network connectivity between your AWS infrastructure
and your GitLab Dedicated instance without routing traffic over the public internet.
All traffic stays within the AWS network, which reduces exposure to external threats
and can help meet compliance requirements for private networking.

GitLab Dedicated supports two types of PrivateLink connections:

- Inbound PrivateLink connections: Users and applications in your VPC connect
  privately to your GitLab Dedicated instance. Use this when you want to restrict
  access so your instance is not reachable over the public internet.
- Outbound PrivateLink connections: Your GitLab Dedicated instance and hosted
  runners connect privately to services running in your VPC. Use this for webhooks,
  project mirroring, secrets managers, or deployments into your infrastructure.

PrivateLink connections must be in the same AWS region as your GitLab Dedicated instance,
and you can create endpoint services only in your primary and secondary AWS regions.

For more information about AWS PrivateLink, see
[What is AWS PrivateLink?](https://docs.aws.amazon.com/vpc/latest/privatelink/what-is-privatelink.html).

### Inbound PrivateLink connections

Inbound PrivateLink connections allow users and applications in your VPC to connect
privately to your GitLab Dedicated instance.

When you create an endpoint service, you specify IAM principals that control access.
Only the IAM principals you specify can create VPC endpoints to connect to your instance.

The endpoint service is available in two availability zones that are either chosen
during onboarding or randomly selected.

#### Create an inbound PrivateLink connection

Prerequisites:

- Your VPC must be in the same region as your GitLab Dedicated instance.
- The IAM principal must have permissions to discover the GitLab-provided endpoint
  service, create the interface VPC endpoint, and associate it with the Route 53
  private hosted zone when private DNS is enabled.
- Use IAM principals with role names only. Do not include role paths.
  - Valid: `arn:aws:iam::AWS_ACCOUNT_ID:role/RoleName`
  - Invalid: `arn:aws:iam::AWS_ACCOUNT_ID:role/somepath/AnotherRoleName`

To create an inbound PrivateLink connection:

1. Sign in to [Switchboard](https://console.gitlab-dedicated.com/).
1. At the top of the page, select **Configuration**.
1. Expand **Inbound private connections**.
1. Select **Add endpoint service**. This button is not available if all your available
   regions already have endpoint services.
1. Select a region.
1. Add IAM principals for the AWS users or roles in your AWS organization that are
   establishing the VPC endpoints. The IAM principals must be
   [IAM role principals](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_elements_principal.html#principal-roles)
   or [IAM user principals](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_elements_principal.html#principal-users).
   Attach a policy with the following permissions to the role or user creating the
   VPC endpoint:

   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Sid": "GitLabDedicatedInboundPrivateLink",
         "Effect": "Allow",
         "Action": [
           "ec2:CreateVpcEndpoint",
           "ec2:DescribeVpcEndpointServices",
           "ec2:DescribeVpcEndpoints",
           "ec2:DescribeVpcs",
           "route53:AssociateVPCWithHostedZone"
         ],
         "Resource": "*"
       }
     ]
   }
   ```

1. Select **Save**. GitLab creates the endpoint service and handles domain verification
   for private DNS. The service endpoint name becomes available on the **Configuration**
   page.
1. In your AWS account, create an
   [endpoint interface](https://docs.aws.amazon.com/vpc/latest/privatelink/create-interface-endpoint.html)
   in your VPC.
1. Configure the endpoint interface with these settings:
   - **Service endpoint name**: Use the name from the **Configuration** page in
     Switchboard.
   - **Private DNS names enabled**: Select **Yes**.
   - **Subnets**: Select all matching subnets.
1. Use the instance URL provided during onboarding to connect to your GitLab Dedicated
   instance from your VPC.

You can use the
[`terraform-inbound-privatelink`](https://gitlab.com/gitlab-com/gl-infra/gitlab-dedicated/customer-tools/terraform-inbound-privatelink)
Terraform module to automate the AWS VPC Endpoint setup and output the Route 53 records
required when you switch DNS.

#### Configure DNS for KAS and registry

Create additional DNS configuration in your VPC to access KAS (GitLab agent for
Kubernetes) and the container registry through your private network.

Prerequisites:

- You have configured inbound PrivateLink connections.
- You have permission to create Route 53 private hosted zones in your AWS account.

To configure DNS for KAS and registry:

1. In your AWS console, create a private hosted zone for `gitlab-dedicated.com`
   and associate it with the VPC that contains your inbound PrivateLink connection.
1. After you create the private hosted zone, add the following DNS records
   (replace `example` with your instance name):

   1. Create an `A` record for your GitLab Dedicated instance:
      - Configure your full instance domain (for example, `example.gitlab-dedicated.com`)
        to resolve to your VPC endpoint as an alias.
      - Select the VPC endpoint that does not contain an availability zone reference.

        ![VPC endpoint dropdown list showing the correct endpoint without AZ reference highlighted.](../img/vpc_endpoint_dns_v18_3.png)

   1. Create `CNAME` records for both KAS and the registry to resolve to your GitLab
      Dedicated instance domain (`example.gitlab-dedicated.com`):
      - `kas.example.gitlab-dedicated.com`
      - `registry.example.gitlab-dedicated.com`

1. To verify connectivity, from a resource in your VPC, run these commands:

   ```shell
   nslookup kas.example.gitlab-dedicated.com
   nslookup registry.example.gitlab-dedicated.com
   nslookup example.gitlab-dedicated.com
   ```

   All commands should resolve to private IP addresses within your VPC.

This configuration uses the VPC endpoint interface rather than specific IP addresses,
so it remains stable if IP addresses change.

##### Configure DNS for GitLab Pages

To access GitLab Pages through your private network, create additional DNS configuration
in your VPC.

To configure DNS for GitLab Pages:

1. In your AWS console, create a private hosted zone for `<tenant_name>.gitlab-dedicated.site`
   and associate it with the VPC that contains your inbound PrivateLink connection.
1. After you create the private hosted zone, add the following DNS records:
   1. Create an apex `A` alias record for the VPC endpoint.
   1. Create a wildcard `CNAME` for `*.<tenant_name>.gitlab-dedicated.site` that points
      to `<tenant_name>.gitlab-dedicated.site`.

### Outbound PrivateLink connections

Outbound PrivateLink connections allow your GitLab Dedicated instance and hosted runners
to communicate privately with services running in your VPC, without exposing traffic to
the public internet.

Use outbound PrivateLink connections to send webhooks, import or mirror projects and
repositories, and give hosted runners access to custom secrets managers, artifacts,
job images, and deployments in your infrastructure.

You can create up to 10 outbound PrivateLink connections per region. To consolidate more
than 10 backend services behind a single connection, you can use the
[`terraform-outbound-proxy`](https://gitlab.com/gitlab-com/gl-infra/gitlab-dedicated/customer-tools/terraform-outbound-proxy)
Terraform module to deploy a highly available NGINX reverse proxy with TLS passthrough,
HTTP routing, and SMTP forwarding.

#### Add an outbound PrivateLink connection

Prerequisites:

- [Create the endpoint service](https://docs.aws.amazon.com/vpc/latest/privatelink/create-endpoint-service.html)
  for your internal service and note the service name and whether private DNS is enabled.
- Configure a Network Load Balancer (NLB) in the availability zones (AZs) where your
  instance is deployed. Either use the configured AZs (displayed on the **Overview** page
  in Switchboard) or enable the NLB in every AZ in the region.
- Recommended. Set **Acceptance required** to **No**. If set to **Yes**, you must manually
  accept the connection after it's initiated, and the status shows as **Pending** in
  Switchboard until the next maintenance window.

> [!note]
> If you set **Acceptance required** to **Yes**, Switchboard cannot accurately determine
> when the link is accepted. After you manually accept the link, the status shows as
> **Pending** instead of **Active** until the next scheduled maintenance. After
> maintenance, the link status refreshes and shows as connected.

To add an outbound PrivateLink connection with Switchboard:

1. Sign in to [Switchboard](https://console.gitlab-dedicated.com/).
1. At the top of the page, select **Configuration**.
1. Expand **Outbound private connections**.
1. Copy the ARN from **Outbound private link IAM principal** and add it to the
   **Allowed Principals** list on your endpoint service. For more information, see
   [Manage permissions](https://docs.aws.amazon.com/vpc/latest/privatelink/configure-endpoint-service.html#add-remove-permissions).
1. Complete the fields.
1. To add endpoint services, select **Add endpoint service**. You can add up to ten
   endpoint services for each region. At least one endpoint service is required to save
   the region.
1. Select **Save**.
1. Optional. To add an outbound PrivateLink connection for a second region, select
   **Add outbound connection**, then repeat the previous steps.

To add an outbound PrivateLink connection with a support request:

1. Open a [support ticket](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650)
   and provide the service endpoint name. GitLab provides the ARN of the IAM role that
   initiates the connection to your endpoint service. Add this ARN to the
   **Allowed Principals** list on the endpoint service, as described in the
   [AWS documentation](https://docs.aws.amazon.com/vpc/latest/privatelink/configure-endpoint-service.html#add-remove-permissions).
1. To connect to services using the endpoint, GitLab Dedicated requires a DNS name.
   PrivateLink automatically creates an internal name, but it is machine-generated and
   not useful for most purposes. Choose one of the following options:
   - In your endpoint service, enable
     [Private DNS name](https://docs.aws.amazon.com/vpc/latest/privatelink/manage-dns-names.html),
     perform the required validation, and notify GitLab in the support ticket that you
     are using this option. If **Acceptance required** is set to **Yes**, note this in
     the support ticket so GitLab can initiate the connection without Private DNS, wait
     for your confirmation, and then update the connection to enable Private DNS.
   - GitLab Dedicated can manage a private hosted zone (PHZ) within the Dedicated AWS
     account and alias DNS names to the endpoint. For more information, see
     [Private hosted zones](#private-hosted-zones).

GitLab configures your instance to create the necessary endpoint interfaces based on the
service names you provided. PrivateLink directs matching outbound connections into your VPC.

#### Delete an outbound PrivateLink connection

1. Sign in to [Switchboard](https://console.gitlab-dedicated.com/).
1. At the top of the page, select **Configuration**.
1. Expand **Outbound private connections**.
1. Go to the outbound PrivateLink connection you want to delete, then select
   **Delete** ({{< icon name="remove" >}}).
1. Select **Delete**.
1. Optional. To delete all the links in a region, from the region header, select
   **Delete** ({{< icon name="remove" >}}). This also deletes the region configuration.

## Private hosted zones

A private hosted zone (PHZ) creates custom DNS records (such as A, CNAME, or other
record types) that resolve in your GitLab Dedicated instance's network.

Use a PHZ when you want to:

- Create multiple DNS records (such as A or CNAME records) that use a single endpoint,
  such as when running a reverse proxy to connect to multiple services.
- Use a private domain that cannot be validated by public DNS.

PHZs are commonly used with reverse PrivateLink to create readable domain names instead
of using AWS-generated endpoint names. For example, you can use
`alpha.beta.tenant.gitlab-dedicated.com` instead of
`vpce-0987654321fedcba0-k99y1abc.vpce-svc-0a123bcd4e5f678gh.eu-west-1.vpce.amazonaws.com`.

In some cases, you can also use PHZs to create DNS records that resolve to publicly
accessible DNS names. For example, you can create an internal DNS name that resolves to
a public endpoint when you need internal systems to access a service through its private
name.

> [!note]
> Changes to private hosted zones can disrupt services that use these records for up to
> five minutes.

### PHZ domain structure

PHZ records can point to different types of targets. The most common and recommended
approach is to point to DNS names for AWS VPC endpoints.

When using your GitLab Dedicated instance's domain as part of an alias with a VPC
endpoint, you must include at least one subdomain before the main domain. For example:

- Valid PHZ entry: `subdomain1.<your-tenant-id>.gitlab-dedicated.com`.
- Invalid PHZ entry: `<your-tenant-id>.gitlab-dedicated.com`.

For custom domains, you must provide a PHZ name and a PHZ entry in the format
`phz-entry.phz-name.com`.

If your PHZ record points to a DNS name that is not a VPC endpoint, you must include at
least two subdomains before the main domain. For example:
`subdomain1.subdomain2.tenant.gitlab-dedicated.com`.

### Add a private hosted zone with Switchboard

To add a private hosted zone:

1. Sign in to [Switchboard](https://console.gitlab-dedicated.com/).
1. At the top of the page, select **Configuration**.
1. Expand **Private hosted zones**.
1. Select **Add private hosted zone entry**.
1. Complete the fields.
   - In the **Hostname** field, enter your private hosted zone (PHZ) entry.
   - For **Link type**, choose one of the following:
     - For an outbound PrivateLink connection PHZ entry, select the endpoint service
       from the dropdown list. Only connections with the `Available` or
       `Pending Acceptance` status are shown.
     - For other PHZ entries, provide a list of DNS aliases.
1. Select **Save**.
   Your PHZ entry and any aliases appear in the list.
1. Scroll to the top of the page, and select whether to apply the changes immediately
   or during the next maintenance window.

### Add a private hosted zone with a support request

If you cannot use Switchboard to add a private hosted zone, open a
[support ticket](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650)
and provide a list of DNS names that should resolve to the endpoint service for the
outbound PrivateLink connection. The list can be updated as needed.

## IP allowlist

Control which IP addresses can access your instance with an IP allowlist.
When you enable the IP allowlist, IP addresses not on the allowlist are blocked
and receive an `HTTP 403 Forbidden` response when they try to access your instance.

Use Switchboard to configure and manage your IP allowlist, or submit a support request
if Switchboard is unavailable.

### Add IP addresses to the allowlist with Switchboard

To add IP addresses to the allowlist:

1. Sign in to [Switchboard](https://console.gitlab-dedicated.com/).
1. At the top of the page, select **Configuration**.
1. Expand **IP allowlist**, then select **IP allowlist** to go to the IP allowlist page.
1. To enable the IP allowlist, select the vertical ellipsis
   ({{< icon name="ellipsis_v" >}}), then select **Enabled**.
1. Do one of the following:

   - To add a single IP address:

   1. Select **Add IP address**.
   1. In the **IP address** text box, enter either:
      - A single IPv4 address (for example, `192.168.1.1`).
      - An IPv4 address range in CIDR notation (for example, `192.168.1.0/24`).
   1. In the **Description** text box, enter a description.
   1. Select **Add**.

   - To import multiple IP addresses:

   1. Select **Import**.
   1. Upload a CSV file or paste a list of IP addresses.
   1. Select **Continue**.
   1. Fix any invalid or duplicate entries, then select **Continue**.
   1. Review the changes, then select **Import**.

1. At the top of the page, choose whether to apply the changes immediately or during
   the next maintenance window.

### Delete IP addresses from the allowlist with Switchboard

1. Sign in to [Switchboard](https://console.gitlab-dedicated.com/).
1. At the top of the page, select **Configuration**.
1. Expand **IP allowlist**, then select **IP allowlist** to go to the IP allowlist page.
1. Do one of the following:

   - To delete a single IP address:

   1. Next to the IP address you want to remove, select the trash icon
      ({{< icon name="remove" >}}).
   1. Select **Delete IP address**.

   - To delete multiple IP addresses:

   1. Select the checkboxes for the IP addresses you want to delete.
   1. To select all IP addresses on the current page, select the checkbox in the
      header row.
   1. Above the IP addresses table, select **Delete**.
   1. Select **Delete** to confirm.

1. At the top of the page, choose whether to apply the changes immediately or during
   the next maintenance window.

### Add an IP to the allowlist with a support request

If you cannot use Switchboard to update your IP allowlist, open a
[support ticket](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650)
and specify a comma-separated list of IP addresses that can access your instance.

### Enable OpenID Connect for your IP allowlist

Using [GitLab as an OpenID Connect identity provider](../../../integration/openid_connect_provider.md)
requires internet access to the OpenID Connect verification endpoint.

To enable access to the OpenID Connect endpoint while maintaining your IP allowlist:

- In a [support ticket](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650),
  request to allow access to the OpenID Connect endpoint.

The configuration is applied during the next maintenance window.

### Enable SCIM provisioning for your IP allowlist

You can use SCIM with external identity providers to automatically provision and manage
users. To use SCIM, your identity provider must be able to access the instance SCIM API
endpoints. By default, IP allowlisting blocks communication to these endpoints.

To enable SCIM while maintaining your IP allowlist:

- In a [support ticket](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650),
  request to enable SCIM endpoints to the internet.

The configuration is applied during the next maintenance window.

## NAT gateway IP addresses

NAT gateway IP addresses are the outbound IPs your instance uses when making connections
to external services. These IPs typically remain consistent but can change if GitLab
rebuilds your instance during disaster recovery.

Use these IP addresses to configure webhook receivers and set up allowlists for external
services to accept connections from your instance.

To view your NAT gateway IP addresses:

1. Sign in to [Switchboard](https://console.gitlab-dedicated.com/).
1. Select the **Configuration** tab.
1. Expand **Resource access**.
1. Under **NAT gateways**, select **Copy to clipboard**
   ({{< icon name="copy-to-clipboard" >}}).

## Troubleshooting AWS PrivateLink connectivity

When working with AWS PrivateLink connections, you might encounter the following issues.

### Error: `Service name could not be verified`

When creating a VPC endpoint for an inbound PrivateLink connection,
you might get an error that states `Service name could not be verified`.

This issue occurs when the custom IAM role provided in the support ticket does not have
the required permissions or trust policies configured in your AWS account.

To resolve this issue:

1. Confirm that you can assume the custom IAM role provided to GitLab in the support
   ticket.
1. Verify the custom role has a trust policy that allows you to assume it. For example:

   ```json
   {
       "Version": "2012-10-17",
       "Statement": [
           {
               "Sid": "Statement1",
               "Effect": "Allow",
               "Principal": {
                   "AWS": "arn:aws:iam::CONSUMER_ACCOUNT_ID:user/user-name"
               },
               "Action": "sts:AssumeRole"
           }
       ]
   }
   ```

1. Verify the custom role has a permission policy that allows VPC endpoint and EC2
   actions. For example:

   ```json
   {
      "Version": "2012-10-17",
      "Statement": [
         {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": "vpce:*",
            "Resource": "*"
         },
         {
            "Sid": "Statement1",
            "Effect": "Allow",
            "Action": [
                  "ec2:CreateVpcEndpoint",
                  "ec2:DescribeVpcEndpointServices",
                  "ec2:DescribeVpcEndpoints"
            ],
            "Resource": "*"
         }
      ]
   }
   ```

1. Using the custom role, retry creating the VPC endpoint in your AWS console or CLI.

### Outbound PrivateLink connection fails

If your outbound PrivateLink connection is not working, check the following:

- Ensure that cross-zone load balancing is turned on in your Network Load Balancer (NLB).
- Ensure that the inbound rules section of the appropriate security groups permits traffic
  from the correct IP ranges.
- Ensure that the inbound traffic is mapped to the correct port on the endpoint service.
- In Switchboard, expand **Outbound private connections** and confirm that the details
  appear as you expect.
- Ensure that you have
  [allowed requests to the local network from webhooks and integrations](../../../security/webhooks.md#allow-requests-to-the-local-network-from-webhooks-and-integrations).
