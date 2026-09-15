---
stage: GitLab Dedicated
group: Environment Automation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Prerequisites and decisions to complete before Geo replication starts.
title: Geo migration requirements
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Dedicated

{{< /details >}}

You must meet the following requirements before Geo replication from your GitLab Self-Managed instance to
GitLab Dedicated can start.
Your GitLab migration team confirms each requirement with you during discovery.

Each requirement below covers what must be true and how to satisfy it.
For the order to complete them, and where they sit in the migration, see
[preparation](process.md#preparation).
Some requirements take weeks to complete, so start on them as early as possible.

## Instance decisions

You make the standard instance decisions when you
[create your GitLab Dedicated instance](../create_instance/_index.md), which documents each field and
the values it accepts.
Two of those decisions carry extra weight in a Geo migration:

- AWS regions.
  If your source instance already runs in AWS, place the primary region in the same AWS region as the
  source, which simplifies migration connectivity.
- Ongoing access method.
  If you use AWS PrivateLink for connectivity, select two availability zone IDs that match your existing
  AWS infrastructure.
  An IPsec site-to-site VPN is not supported for ongoing access, although you can use one during the
  migration window.
  For more information, see [network security](../configure_instance/network_security.md).

> [!warning]
> You cannot change AWS regions, availability zone IDs, or customer-managed
> encryption key configuration after GitLab provisions your instance.
> Confirm these decisions before provisioning starts.

## Domain strategy

Decide whether to use a custom domain or a GitLab-provided domain:

- If you use a custom domain, your users keep using the same hostname after migration.
  Existing references to that hostname keep resolving, including issue and merge request descriptions,
  comments, runner configuration, scripts, and the Git remotes your users have configured.
  Endpoints that have their own hostname, such as KAS and GitLab Pages, still change.
- If you use a GitLab-provided domain, the hostname changes, and references to the old hostname do not
  resolve after cutover.
  Plan to update them.
- A custom domain requires your domain to be publicly resolvable so that certificates can be issued.
  You can still restrict access with an IP allowlist.
  A public DNS record does not itself grant access.
- If you use a custom domain for the GitLab instance, use it also for the container registry and the
  GitLab agent server for Kubernetes (KAS), so hostnames stay consistent.
- GitLab Pages does not support custom domains.
  Pages content is served from the GitLab Dedicated Pages domain.

For more information, see
[custom domains](../configure_instance/network_security.md#custom-domains) and the delivery kit
[DNS requirements for custom domains](https://gitlab.com/gitlab-org/professional-services-automation/delivery-kits/migration-delivery-kits/migration-delivery-kit/-/blob/main/Geo/dedicated.md#321-dns-requirements-around-byod).

## Source instance requirements

Configure your instance as a Geo primary site before replication to GitLab Dedicated begins.
Verification generates checksums for your existing data, which surfaces data problems early, so start it
as soon as you can.

For more information, see [Geo](../../geo/_index.md) and the delivery kit
[Geo activation on the customer primary instance](https://gitlab.com/gitlab-org/professional-services-automation/delivery-kits/migration-delivery-kits/migration-delivery-kit/-/blob/main/Geo/dedicated.md#41-geo-activation-on-customer-primary-instance).

## Database read replicas

GitLab Dedicated must reach a PostgreSQL read replica of your source database.
You provide two replicas, one for the production path and one for the pre-production path, because Geo
synchronizes to a GitLab Dedicated pre-production tenant and a production tenant in parallel.

Each replica must be reachable from GitLab Dedicated over the migration connectivity, and must stream
from a healthy source.

How you provide the replicas depends on where your source database runs.
If your source is in AWS, the public
[migration PrivateLink Terraform module](https://gitlab.com/gitlab-com/gl-infra/gitlab-dedicated/customer-tools/terraform-migration-privatelink)
creates both read replicas and provides access to them over PrivateLink, which makes it the most
straightforward option.

For more information, see the delivery kit
[outbound PrivateLinks to RDS read replica and GitLab](https://gitlab.com/gitlab-org/professional-services-automation/delivery-kits/migration-delivery-kits/migration-delivery-kit/-/blob/main/Geo/dedicated.md#451-outbound-privatelinks-to-rds-read-replica-and-gitlab).

### Source already on AWS RDS

Create the two RDS read replicas directly.

### Source running in AWS without RDS

GitLab recommends that you back up the source database and restore it into AWS RDS for PostgreSQL before
the migration, then create the two read replicas there.
RDS-native read replicas are simpler to create and manage.

Moving onto RDS requires a planned maintenance window with downtime while the dump and restore run.
Size that window according to your database volume.

### Source on another cloud or not in AWS

AWS RDS is not required.
Provide two reachable read replicas in your own environment, for example Google Cloud SQL or Azure
Database for PostgreSQL.

## Object storage

All data types in use must be on object storage before Geo replication starts.
GitLab Dedicated uses object storage, and a Geo secondary site must use the same storage
method as its primary, so files left on local storage cannot migrate.
For more information, see [object storage with Geo](../../geo/replication/object_storage.md).

Migration to object storage does not require downtime for most data types.

For the migration procedure for each data type, see
[migrate to object storage](../../object_storage.md#migrate-to-object-storage).
For migration sequencing, see the delivery kit
[object storage migration](https://gitlab.com/gitlab-org/professional-services-automation/delivery-kits/migration-delivery-kits/migration-delivery-kit/-/blob/main/Geo/dedicated.md#48-object-storage-migration).

### Private access to object storage

If your object storage uses proxy download, you can use the public
[object storage private access tooling](https://gitlab.com/gitlab-com/gl-infra/gitlab-dedicated/customer-tools/object-storage-private-access)
to configure a private Amazon S3 interface endpoint.

## Repository storage

GitLab Dedicated supports three Gitaly storage names: `default`, `storage2`, and `storage3`.
If your instance uses any other storage name, move your repositories to a supported name before cutover.

For more information, see
[repository storage](../create_instance/storage_types.md#repository-storage) and the delivery kit
[Gitaly repository storage changes](https://gitlab.com/gitlab-org/professional-services-automation/delivery-kits/migration-delivery-kits/migration-delivery-kit/-/blob/main/Geo/dedicated.md#47-gitaly-repository-storage-changes).

## Migration connectivity

During the migration, GitLab Dedicated must reach your source GitLab instance and the two database read
replicas.

If your source is in AWS, connect over AWS PrivateLink rather than the public internet, and place your
GitLab Dedicated primary region in the same AWS region as the source.
You stand up the PrivateLink path in your own AWS account.
The path comprises a Network Load Balancer and a VPC endpoint service, for both the production path and
the pre-production path.
The public [inbound PrivateLink Terraform module](https://gitlab.com/gitlab-com/gl-infra/gitlab-dedicated/customer-tools/terraform-inbound-privatelink)
creates the inbound PrivateLink, and the migration PrivateLink Terraform module prepares migration
connectivity.

If your source is not in AWS, you can:

- Bridge to an AWS account you own and use AWS PrivateLink from there.
- Use an [IPsec site-to-site VPN](#ipsec-site-to-site-vpn) for the migration window.
- Provide internet access to your source instance and read replicas.

Confirm the design with your migration team.

For more information, see the delivery kit
[Geo sync connectivity](https://gitlab.com/gitlab-org/professional-services-automation/delivery-kits/migration-delivery-kits/migration-delivery-kit/-/blob/main/Geo/dedicated.md#45-geo-sync-connectivity).

### IPsec site-to-site VPN

If PrivateLink is not an option, GitLab can set up an AWS site-to-site VPN between your network and your
GitLab Dedicated tenant for the duration of the migration.
The VPN is not supported for ongoing access after the migration completes.

The VPN uses static routing.
BGP dynamic routing is not supported, so you must know in advance which of your subnets need access, and
provide them along with the public IP addresses of your VPN endpoint.
GitLab creates the AWS side of the connection, which includes two IPsec tunnels for redundancy, then
sends you the configuration to apply on your own VPN device.

To prepare, gather the following:

- The public IP addresses of your VPN endpoint
- The subnets that require access to GitLab Dedicated
- The make and model of your VPN device, so that GitLab can generate configuration for it

GitLab does not apply network address translation (NAT) on the GitLab Dedicated side.
GitLab shares the IP range that GitLab Dedicated connects from, and you can translate it in your own
network if your addressing requires it.
Because the migration needs connections in one direction only, from GitLab Dedicated to your instance
and read replicas, you only translate the incoming source addresses.

For the setup procedure, see the delivery kit
[IPsec VPN access](https://gitlab.com/gitlab-org/professional-services-automation/delivery-kits/migration-delivery-kits/migration-delivery-kit/-/blob/main/Geo/dedicated.md#452-ipsec-vpn-access).

## Outbound connectivity for integrations

Prepare your outbound targets as follows:

- Configure webhooks and integrations to target hostnames, not IP addresses.
- Review your outbound target list before you assume that every private address needs connectivity.
  Loopback addresses, self-references, and cluster-internal addresses are often not real external
  endpoints.

GitLab Dedicated supports at most 10 outbound PrivateLink endpoints.
If more private targets need reachability, consolidate multiple backends behind a single connection with
the public [outbound proxy Terraform module](https://gitlab.com/gitlab-com/gl-infra/gitlab-dedicated/customer-tools/terraform-outbound-proxy),
which deploys a highly available NGINX proxy behind a Network Load Balancer and can consolidate HTTPS,
HTTP, and SMTP backends.

To inventory your outbound targets, use the public
[GitLab discovery toolkit](https://gitlab.com/gitlab-com/gl-infra/gitlab-dedicated/customer-tools/gitlab-discovery-toolkit).

Test every outbound target during the [testing period](process.md#testing-period).
Outbound connectivity problems are among the most common findings, and the testing period is when to
surface them.

For more information, see
[outbound PrivateLink connections](../configure_instance/network_security.md#outbound-privatelink-connections)
and the delivery kit
[webhooks and integrations](https://gitlab.com/gitlab-org/professional-services-automation/delivery-kits/migration-delivery-kits/migration-delivery-kit/-/blob/main/Geo/dedicated.md#316-webhooks-and-integrations).

## Inbound access for SaaS integrations

If you use an IP allowlist, add allowlist exceptions for any external SaaS service that must reach your
GitLab Dedicated instance, for example a ticketing system, a chat integration, or a CI/CD service that
calls the GitLab API.

Inventory these services before cutover.
Requests from a service that is not on the allowlist are blocked.

For more information, see [IP allowlist](../configure_instance/network_security.md#ip-allowlist).

## Features to remediate

Check your instance against the list of
[unavailable features](../../../subscriptions/gitlab_dedicated/_index.md#unavailable-features), and put a
replacement in place for anything you use before cutover.
For guidance on working through the list, see the delivery kit
[remaining unsupported features](https://gitlab.com/gitlab-org/professional-services-automation/delivery-kits/migration-delivery-kits/migration-delivery-kit/-/blob/main/Geo/dedicated.md#3111-remaining-unsupported-features).

Two items need more planning time than the rest, and GitLab provides tooling or a procedure for each:

- Moving from LDAP to a SAML or OpenID Connect (OIDC) identity provider, which is often the longest
  single item of preparation.
  For more information, see [move from LDAP to SAML](#move-from-ldap-to-saml).
- GitLab Pages custom domains, which GitLab Dedicated does not support.
  Pages content is served from the GitLab Dedicated Pages domain.
  For a temporary transition, you can use the public
  [Pages redirect Terraform module](https://gitlab.com/gitlab-com/gl-infra/gitlab-dedicated/customer-tools/terraform-gitlab-pages-redirect),
  which keeps your existing certificate and DNS name and returns a redirect to the new URL.
  The module is a temporary aid, not a permanent solution.

You must re-register your GitLab agents for Kubernetes against the new KAS URL, because the default
`/-/kubernetes-agent` path does not exist on GitLab Dedicated.

### Move from LDAP to SAML

Moving from LDAP is often the longest single item of preparation, so start it early.

To configure your identity provider on GitLab Dedicated, see
[SAML](../configure_instance/authentication/saml.md) or
[OpenID Connect](../configure_instance/authentication/openid_connect.md).

If you use LDAP group sync, you can preserve group membership by converting to
[SAML group sync](../../../user/group/saml_sso/group_sync.md).
For the conversion procedure and the scripts that GitLab Professional Services uses, see the delivery kit
[SSO configuration](https://gitlab.com/gitlab-org/professional-services-automation/delivery-kits/migration-delivery-kits/migration-delivery-kit/-/blob/main/Geo/dedicated.md#44-sso-configuration).

## Related topics

- [Geo migration to GitLab Dedicated](_index.md)
- [Collect Geo migration secrets](secrets.md)
- [Geo migration process](process.md)
- [Post-migration activities](post_cutover.md)
