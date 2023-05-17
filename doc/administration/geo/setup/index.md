---
stage: Systems
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
type: howto
---

# Setting up Geo **(PREMIUM SELF)**

## Prerequisites

- Two (or more) independently working GitLab sites:
  - One GitLab site serves as the Geo **primary** site. Use the [GitLab reference architectures documentation](../../reference_architectures/index.md) to set this up. You can use different reference architecture sizes for each Geo site. If you already have a working GitLab instance that is in-use, it can be used as a **primary** site.
  - The second GitLab site serves as the Geo **secondary** site. Use the [GitLab reference architectures documentation](../../reference_architectures/index.md) to set this up. It's a good idea to sign in and test it. However, be aware that **all of the data on the secondary are lost** as part of the process of replicating from the **primary** site.

  NOTE:
  Geo supports multiple secondaries. You can follow the same steps and make any changes accordingly.

- Ensure the **primary** site has a [GitLab Premium or Ultimate](https://about.gitlab.com/pricing/) subscription to unlock Geo. You only need one license for all the sites.
- Confirm the [requirements for running Geo](../index.md#requirements-for-running-geo) are met by all sites. For example, sites must use the same GitLab version, and sites must be able to communicate with each other over certain ports.

## Using Omnibus GitLab

If you installed GitLab using the Omnibus packages (highly recommended):

1. [Set up the database replication](database.md) (`primary (read-write) <-> secondary (read-only)` topology).
1. [Configure GitLab](../replication/configuration.md) to set the **primary** and **secondary** sites.
1. Optional: [Configure Object storage](../../object_storage.md)
1. Optional: [Configure a secondary LDAP server](../../auth/ldap/index.md) for the **secondary** sites. See [notes on LDAP](../index.md#ldap).
1. Optional: [Configure Geo secondary proxying](../secondary_proxy/index.md) to use a single, unified URL for all Geo sites. This step is recommended to accelerate most read requests while transparently proxying writes to the primary Geo site.
1. Follow the [Using a Geo Site](../replication/usage.md) guide.

## Using GitLab Charts

[Configure the GitLab chart with GitLab Geo](https://docs.gitlab.com/charts/advanced/geo/).

## Post-installation documentation

After installing GitLab on the **secondary** sites and performing the initial configuration, see the [following documentation for post-installation information](../index.md#post-installation-documentation).
