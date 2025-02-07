---
stage: Systems
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Setting up Geo
---

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab Self-Managed

## Prerequisites

- Two (or more) independently working GitLab sites:
  - One GitLab site serves as the Geo **primary** site. Use the [GitLab reference architectures documentation](../../reference_architectures/_index.md) to set this up. You can use different reference architecture sizes for each Geo site. If you already have a working GitLab instance that is in-use, it can be used as a **primary** site.
  - The second GitLab site serves as the Geo **secondary** site. Use the [GitLab reference architectures documentation](../../reference_architectures/_index.md) to set this up. It's a good idea to sign in and test it. However, be aware that **all of the data on the secondary are lost** as part of the process of replicating from the **primary** site.

  NOTE:
  Geo supports multiple secondaries. You can follow the same steps and make any changes accordingly.

- Ensure the **primary** site has a [GitLab Premium or Ultimate](https://about.gitlab.com/pricing/) subscription to unlock Geo. You only need one license for all the sites.
- Confirm the [requirements for running Geo](../_index.md#requirements-for-running-geo) are met by all sites. For example, sites must use the same GitLab version, and sites must be able to communicate with each other over certain ports.
- Confirm the **primary** and **secondary** site storage configurations match. If the primary Geo site uses object storage, the secondary Geo site must use it too. For more information, see [Geo with Object storage](../replication/object_storage.md).
- Ensure clocks are synchronized between the **primary** site and the **secondary** site. Synchronized clocks are required for Geo to function correctly. For example, if the clock drift between the **primary** and **secondary** sites exceeds 1 minute, replication fails.

## Using Linux package installations

If you installed GitLab using the Linux package (highly recommended), the process for setting up Geo depends on whether you need to set up
a single-node Geo site or a multi-node Geo site.

### Single-node Geo sites

If both Geo sites are based on the [1K reference architecture](../../reference_architectures/1k_users.md), follow
[Set up Geo for two single-node sites](two_single_node_sites.md).

If using external PostgreSQL services, for example Amazon RDS, follow [Set up Geo for two single-node sites (with external PostgreSQL services)](two_single_node_external_services.md).

Depending on your GitLab deployment, [additional configuration](#additional-configuration) for LDAP, object storage, and the container registry might be required.

### Multi-node Geo sites

If one or more of your sites is using the [40 RPS / 2,000 user reference architecture](../../reference_architectures/2k_users.md) or larger, see
[Configure Geo for multiple nodes](../replication/multiple_servers.md).

Depending on your GitLab deployment, [additional configuration](#additional-configuration) for LDAP, object storage, and the container registry might be required.

### General steps for reference

1. Set up the database replication based on your choice of PostgreSQL instances (`primary (read-write) <-> secondary (read-only)` topology):
   - [Using Linux package PostgreSQL instances](database.md) .
   - [Using external PostgreSQL instances](external_database.md)
1. [Configure GitLab](../replication/configuration.md) to set the **primary** and **secondary** sites.
1. Follow the [Using a Geo Site](../replication/usage.md) guide.

Depending on your GitLab deployment, [additional configuration](#additional-configuration) for LDAP, object storage, and the container registry might be required.

### Additional configuration

Depending on how you use GitLab, the following configuration might be required:

- If the **primary** site uses object storage, [configure object storage replication](../replication/object_storage.md) for the **secondary** sites.
- If you use LDAP, [configure a secondary LDAP server](../../auth/ldap/_index.md) for the **secondary** sites.
  For more information, see [LDAP with Geo](../replication/single_sign_on.md#ldap).
- If you use the container registry, [configure the container registry for replication](../replication/container_registry.md) on the **primary** and **secondary** sites.

You should [configure unified URLs](../secondary_proxy/_index.md#set-up-a-unified-url-for-geo-sites) to use a single, unified URL for all Geo sites.

## Using GitLab Charts

[Configure the GitLab chart with GitLab Geo](https://docs.gitlab.com/charts/advanced/geo/).

## Geo and self-compiled installations

Geo is not supported when you use a [self-compiled GitLab installation](../../../install/installation.md).

## Post-installation documentation

After installing GitLab on the **secondary** sites and performing the initial configuration, see the [following documentation for post-installation information](../_index.md#post-installation-documentation).
