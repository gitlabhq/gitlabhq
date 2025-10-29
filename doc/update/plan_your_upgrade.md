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

Before you upgrade a GitLab instance, you must:

1. Gather pre-upgrade information to prepare yourself for the upgrade.
1. Perform pre-upgrade steps before you upgrade GitLab itself.

## Gather pre-upgrade information

When planning the upgrade:

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
   - The steps to take if the upgrade doesn't go smoothly including how to
     [roll back GitLab if necessary](#create-a-rollback-plan-and-backup).

With all pre-upgrade information gathered, you can move on to performing pre-upgrade steps.

### Create a rollback plan and backup

Something might go wrong during an upgrade, so it's critical that you have a rollback plan. A proper rollback plan
creates a clear path to bring a GitLab instance back to its last working state and comprises:

- The process to back up the instance.
- The process to restore the instance.

You should test the rollback plan before you need it. For an overview of the steps required for rolling back, see
[roll back to earlier GitLab versions](package/downgrade.md).

#### Create a GitLab backup

To make it possible to roll back GitLab if there's a problem with the upgrade, either:

- Create a [GitLab backup](../administration/backup_restore/_index.md). You must follow the instructions based on your
  installation method and make sure to back up the
  [secrets and configuration files](../administration/backup_restore/backup_gitlab.md#storing-configuration-files).
- Create a snapshot of your instance. If you instance is multi-node installation, you must snapshot every node.
  **This process is out of scope for GitLab Support**.

#### Roll back GitLab

If you have a test environment that mimics production, test the restoration to ensure that everything works as you expect.

To restore your GitLab backup:

1. Refer to [restore prerequisites](../administration/backup_restore/restore_gitlab.md#restore-prerequisites). Most
   importantly, the versions of the backed up and the new GitLab instance must be the same.
1. [Restore GitLab](../administration/backup_restore/_index.md#restore-gitlab) by following the instructions based on
   your installation method.
1. Confirm that the [secrets and configuration files](../administration/backup_restore/backup_gitlab.md#storing-configuration-files)
   are also restored.

If restoring from a snapshot, you must already know how to do this. **This process is out of scope for GitLab Support**.

## Perform pre-upgrade steps

Shortly before you perform the upgrade:

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

If something goes wrong, [get support](#get-support).

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

## Pause CI/CD pipelines and jobs

During upgrades for most types of GitLab instances, you should pause CI/CD pipelines and jobs.

If you upgrade your GitLab instance while GitLab Runner is processing jobs, the trace updates fail. When GitLab is
back online, the trace updates should self-heal. If a trace update does not self-heal, depending on the error, GitLab Runner either retries or
terminates job handling.

GitLab Runner attempts to upload job artifacts three times, after which the job fails.

To pause CI/CD pipelines and jobs:

1. Pause the runners.
1. Block new jobs from starting by adding the following to your `/etc/gitlab/gitlab.rb` file:

   ```ruby
   nginx['custom_gitlab_server_config'] = "location = /api/v4/jobs/request {\n deny all;\n return 503;\n}\n"
   ```

1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. Wait until all jobs are finished.

When you've completed your GitLab upgrade:

1. Unpause your runners.
1. Unblock new jobs from starting by reverting the previous `/etc/gitlab/gitlab.rb` change.

## Working with Support

If you are [working with Support](https://about.gitlab.com/support/scheduling-upgrade-assistance/) to review your
upgrade plan, document and share it with the answers to the following questions:

- How is GitLab installed?
- What is the operating system of the node? Check the [supported platforms](../install/package/_index.md#supported-platforms)
  to confirm that later updates are available.
- Is it a single-node or a multi-node setup? If multi-node, document and share any architectural details about each node.
  Which external components are used? For example, Gitaly, PostgreSQL, or Redis?
- Are you using [Geo](../administration/geo/_index.md)? If so, document and share any architectural details about
  each secondary site.
- What else might be unique or interesting in your setup that might be important?
- Are you running into any known issues with your current version of GitLab?

## Get support

If something goes wrong during your upgrade:

1. Copy any errors and gather any logs to analyze later. Use the following tools to help you gather data:
   - [`gitlabsos`](https://gitlab.com/gitlab-com/support/toolbox/gitlabsos) if you installed GitLab with the Linux
     package or Docker.
   - [`kubesos`](https://gitlab.com/gitlab-com/support/toolbox/kubesos/) if you installed GitLab using the Helm Charts.
1. Roll back to the last working version.

For support:

- [Contact GitLab Support](https://support.gitlab.com/hc/en-us) and your Customer Success Manager, if you have one.
- If [the situation qualifies](https://about.gitlab.com/support/#definitions-of-support-impact) and
  [your plan includes emergency support](https://about.gitlab.com/support/#priority-support),
  create an emergency ticket.
