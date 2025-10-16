---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Before you upgrade
description: Steps to take before you upgrade.
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

Before you upgrade, you should:

1. Gather pre-upgrade information.
1. Perform pre-upgrade steps.

## Gather pre-upgrade information

When planning the upgrade, you should:

1. Review the [GitLab release and maintenance policy](../policy/maintenance.md).
1. Consult the [GitLab upgrade notes](versions/_index.md) for different versions of GitLab to ensure compatibility.
1. If relevant, check [OS compatibility with the target GitLab version](../install/package/_index.md).
1. If you're using Geo:
   - Review [Geo upgrade documentation](../administration/geo/replication/upgrading_the_geo_sites.md).
   - Review Geo-specific information in the [GitLab upgrade notes](versions/_index.md).
   - Review Geo-specific steps when [upgrading the database](https://docs.gitlab.com/omnibus/settings/database.html#upgrading-a-geo-instance).
   - Create an upgrade and rollback plan for each Geo site (primary and each secondary).
1. Determine the appropriate [upgrade path](upgrade_paths.md) for your instance, including any required upgrade stops.
   Upgrade stops might require you to perform multiple upgrades.
1. Create an upgrade plan that documents:

   - The steps to take to upgrade your instance including, if possible and required, a
     [zero-downtime upgrade](zero_downtime.md).
   - The steps to take if the upgrade doesn't go smoothly including how to [roll back GitLab](#rollback-plan) if
     necessary.

With all pre-upgrade information gathered, you can move on to performing pre-upgrade steps.

## Perform pre-upgrade steps

Soon before you perform the upgrade, you should:

1. Test your upgrade in a test environment first to reduce the risk of unplanned outages and extended downtime.
1. Run [upgrade health checks](#run-upgrade-health-checks).
1. Perform [upgrades for any optional features](#upgrades-for-optional-features) that you use.

### Run upgrade health checks

Immediately before and after the upgrade, run upgrade health checks to ensure the major components of GitLab are
working:

1. [Check the general configuration](../administration/raketasks/maintenance.md#check-gitlab-configuration):

   ```shell
   sudo gitlab-rake gitlab:check
   ```

1. Check the status of all [background database migrations](background_migrations.md). All migrations must finish
   running before each upgrade. You must spread out upgrades between major and minor releases to allow time for
   background migrations to finish.
1. Confirm that encrypted database values [can be decrypted](../administration/raketasks/check.md#verify-database-values-can-be-decrypted-using-the-current-secrets):

   ```shell
   sudo gitlab-rake gitlab:doctor:secrets
   ```

1. In the GitLab UI, check that:
   - Users can sign in.
   - The project list is visible.
   - Project issues and merge requests are accessible.
   - Users can clone repositories from GitLab.
   - Users can push commits to GitLab.

1. For GitLab CI/CD, check that:
   - Runners pick up jobs.
   - Docker images can be pushed and pulled from the registry.

1. If using Geo, run the relevant checks on the primary site and each secondary site:

   ```shell
   sudo gitlab-rake gitlab:geo:check
   ```

1. If using Elasticsearch, verify that searches are successful.

If something goes wrong, [get support](upgrade.md#getting-support).

### Upgrades for optional features

Depending on how your GitLab instance is configured, you might be required to perform these additional steps before
upgrading GitLab:

1. If using external Gitaly servers, upgrade the Gitaly servers to the newer version before upgrading GitLab itself.
   This prevents the gRPC client on the application server from sending RPCs that the old Gitaly version does not support.
1. If you have Kubernetes clusters connected with GitLab,
   [upgrade your GitLab agents for Kubernetes](../user/clusters/agent/install/_index.md#update-the-agent-version) to
   match your new GitLab version.
1. If you use advanced search (Elasticsearch), confirm advanced search migrations are complete
   by [checking for pending migrations](background_migrations.md#check-for-pending-advanced-search-migrations).

   After upgrading GitLab, you might have to upgrade
   [Elasticsearch if the new version breaks compatibility](../integration/advanced_search/elasticsearch.md#version-requirements).
   Updating Elasticsearch is **out of scope for GitLab Support**.

## Working with Support

If you are [working with Support](https://about.gitlab.com/support/scheduling-upgrade-assistance/) to review your
upgrade plan, document and share it with the answers to the following questions:

- How is GitLab installed?
- What is the operating system of the node? Check the [supported platforms](../install/package/_index.md#supported-platforms)
  to confirm that later updates are available.
- Is it a single-node or a multi-node setup? If multi-node, document and share any architectural details about each node.
  Which external components are used? For example, Gitaly, PostgreSQL, or Redis?
- Are you using [Geo](../administration/geo/_index.md)? If so, document and share any architectural details about
  each secondary node.
- What else might be unique or interesting in your setup that might be important?
- Are you running into any known issues with your current version of GitLab?

## Rollback plan

It's possible that something may go wrong during an upgrade, so it's critical
that a rollback plan be present for that scenario. A proper rollback plan
creates a clear path to bring the instance back to its last working state. It is
comprised of a way to back up the instance and a way to restore it. You should
test the rollback plan before you need it. For an overview of the steps required
for rolling back, see [roll back to earlier GitLab versions](package/downgrade.md).

### Back up GitLab

Create a backup of GitLab and all its data (database, repositories, uploads, builds,
artifacts, LFS objects, registry, pages). This is vital for making it possible
to roll back GitLab to a working state if there's a problem with the upgrade:

- Create a [GitLab backup](../administration/backup_restore/_index.md).
  Make sure to follow the instructions based on your installation method.
  Don't forget to back up the [secrets and configuration files](../administration/backup_restore/backup_gitlab.md#storing-configuration-files).
- Alternatively, create a snapshot of your instance. If this is a multi-node
  installation, you must snapshot every node.
  **This process is out of scope for GitLab Support**.

### Restore GitLab

If you have a test environment that mimics your production one, you should test the restoration to ensure that everything works as you expect.

To restore your GitLab backup:

- Before restoring, make sure to read about the
  [prerequisites](../administration/backup_restore/_index.md#restore-gitlab), most importantly,
  the versions of the backed up and the new GitLab instance must be the same.
- [Restore GitLab](../administration/backup_restore/_index.md#restore-gitlab).
  Make sure to follow the instructions based on your installation method.
  Confirm that the [secrets and configuration files](../administration/backup_restore/backup_gitlab.md#storing-configuration-files) are also restored.
- If restoring from a snapshot, know the steps to do this.
  **This process is out of scope for GitLab Support**.
