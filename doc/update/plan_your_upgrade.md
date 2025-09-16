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

Before you upgrade, review the [GitLab release and maintenance policy](../policy/maintenance.md).

You should then create an upgrade plan that documents:

- The steps to take to upgrade your instance, including your [upgrade path](upgrade_paths.md). Use the
  [upgrade path tool](upgrade_paths.md#upgrade-path-tool) to determine if your upgrade includes required upgrade stops.
  Upgrade stops might require you to perform multiple upgrades. If relevant, check
  [OS compatibility with the target GitLab version](../administration/package_information/supported_os.md).
- The steps to take if the upgrade doesn't go smoothly.

Your upgrade plan should include:

- How to upgrade GitLab including, if possible and required, a [zero-downtime upgrade](zero_downtime.md).
- How to [roll back GitLab](#rollback-plan), if necessary.

## Pre-upgrade steps

Before you upgrade, you should:

1. Check for [background migrations](background_migrations.md). All migrations must finish running before each upgrade.
   You must spread out upgrades between major and minor releases to allow time for background migrations to finish.
1. Test your upgrade in a test environment first, and have a [rollback plan](#rollback-plan)
   to reduce the risk of unplanned outages and extended downtime.
1. Consult the [GitLab upgrade notes](versions/_index.md) for different versions of GitLab to ensure compatibility
   before upgrading.

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
for rolling back, see [Downgrade](package/downgrade.md).

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
