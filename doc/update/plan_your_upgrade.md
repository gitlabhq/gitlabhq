---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Create a GitLab upgrade plan

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** Self-managed

This document serves as a guide to create a strong plan to upgrade a self-managed
GitLab instance.

General notes:

- If possible, you should test out the upgrade in a test environment before
  updating your production instance. Ideally, your test environment should mimic
  your production environment as closely as possible.
- If [working with Support](https://about.gitlab.com/support/scheduling-upgrade-assistance/)
  to create your plan, share details of your architecture, including:
  - How is GitLab installed?
  - What is the operating system of the node?
    (check [OS versions that are no longer supported](../administration/package_information/supported_os.md#os-versions-that-are-no-longer-supported) to confirm that later updates are available).
  - Is it a single-node or a multi-node setup? If multi-node, share any architectural details about each node with us.
  - Are you using [GitLab Geo](../administration/geo/index.md)? If so, share any architectural details about each secondary node.
  - What else might be unique or interesting in your setup that might be important for us to understand?
  - Are you running into any known issues with your current version of GitLab?

## Pre-upgrade and post-upgrade checks

Immediately before and after the upgrade, perform the pre-upgrade and post-upgrade checks
to ensure the major components of GitLab are working:

1. [Check the general configuration](../administration/raketasks/maintenance.md#check-gitlab-configuration):

   ```shell
   sudo gitlab-rake gitlab:check
   ```

1. Confirm that encrypted database values [can be decrypted](../administration/raketasks/check.md#verify-database-values-can-be-decrypted-using-the-current-secrets):

   ```shell
   sudo gitlab-rake gitlab:doctor:secrets
   ```

1. In GitLab UI, check that:
   - Users can sign in.
   - The project list is visible.
   - Project issues and merge requests are accessible.
   - Users can clone repositories from GitLab.
   - Users can push commits to GitLab.

1. For GitLab CI/CD, check that:
   - Runners pick up jobs.
   - Docker images can be pushed and pulled from the registry.

1. If using Geo, run the relevant checks on the primary and each secondary:

   ```shell
   sudo gitlab-rake gitlab:geo:check
   ```

1. If using Elasticsearch, verify that searches are successful.

If in any case something goes wrong, see [how to troubleshoot](#troubleshooting).

## Rollback plan

It's possible that something may go wrong during an upgrade, so it's critical
that a rollback plan be present for that scenario. A proper rollback plan
creates a clear path to bring the instance back to its last working state. It is
comprised of a way to back up the instance and a way to restore it.

### Back up GitLab

Create a backup of GitLab and all its data (database, repositories, uploads, builds,
artifacts, LFS objects, registry, pages). This is vital for making it possible
to roll back GitLab to a working state if there's a problem with the upgrade:

- Create a [GitLab backup](../administration/backup_restore/index.md).
  Make sure to follow the instructions based on your installation method.
  Don't forget to back up the [secrets and configuration files](../administration/backup_restore/backup_gitlab.md#storing-configuration-files).
- Alternatively, create a snapshot of your instance. If this is a multi-node
  installation, you must snapshot every node.
  **This process is out of scope for GitLab Support.**

### Restore GitLab

If you have a test environment that mimics your production one, you should test the restoration to ensure that everything works as you expect.

To restore your GitLab backup:

- Before restoring, make sure to read about the
  [prerequisites](../administration/backup_restore/index.md#restore-gitlab), most importantly,
  the versions of the backed up and the new GitLab instance must be the same.
- [Restore GitLab](../administration/backup_restore/index.md#restore-gitlab).
  Make sure to follow the instructions based on your installation method.
  Confirm that the [secrets and configuration files](../administration/backup_restore/backup_gitlab.md#storing-configuration-files) are also restored.
- If restoring from a snapshot, know the steps to do this.
  **This process is out of scope for GitLab Support.**

## Upgrade plan

For the upgrade plan, start by creating an outline of a plan that best applies
to your instance and then upgrade it for any relevant features you're using.

- Generate an upgrade plan by reading and understanding the relevant documentation:
  - Upgrade based on the [installation method](index.md#upgrade-based-on-installation-method).
  - [Zero-downtime upgrades](zero_downtime.md) (if possible and desired)
  - [Convert from GitLab Community Edition to Enterprise Edition](package/convert_to_ee.md)
- What version should you upgrade to:
  - [Determine what upgrade path](index.md#upgrade-paths) to follow.
  - Account for any [version-specific update instructions](index.md#version-specific-upgrading-instructions) for both the current version and the destination version.
  - Account for any [version-specific changes](package/index.md#version-specific-changes).
  - Check the [OS compatibility with the target GitLab version](../administration/package_information/supported_os.md).
- Due to background migrations, plan to pause before any further upgrades.
  [All migrations must finish running](background_migrations.md)
  before the next upgrade.
- If available in your starting version, consider
  [turning on maintenance mode](../administration/maintenance_mode/index.md) during the
  upgrade.
- About PostgreSQL:
  1. On the left sidebar, at the bottom, select **Admin area**..
  1. Look for the version of PostgreSQL you are using.
     If [a PostgreSQL upgrade is needed](../administration/package_information/postgresql_versions.md),
     account for the relevant
     [packaged](https://docs.gitlab.com/omnibus/settings/database.html#upgrade-packaged-postgresql-server)
     or [non-packaged](https://docs.gitlab.com/omnibus/settings/database.html#upgrade-a-non-packaged-postgresql-database) steps.

### Additional features

Apart from all the generic information above, you may have enabled some features
that require special planning.

Feel free to ignore sections about features that are inapplicable to your setup,
such as Geo, external Gitaly, or Elasticsearch.

#### External Gitaly

If you're using an external Gitaly server, it must be upgraded to the newer
version prior to upgrading the application server.

#### Geo

If you're using Geo:

- Review [Geo upgrade documentation](../administration/geo/replication/upgrading_the_geo_sites.md).
- Read about the [Geo version-specific update instructions](index.md#version-specific-upgrading-instructions).
- Review Geo-specific steps when [upgrading the database](https://docs.gitlab.com/omnibus/settings/database.html#upgrading-a-geo-instance).
- Create an upgrade and rollback plan for _each_ Geo site (primary and each secondary).

#### Runners

After updating GitLab, upgrade your runners to match
[your new GitLab version](https://docs.gitlab.com/runner/#gitlab-runner-versions).

#### GitLab agent for Kubernetes

If you have Kubernetes clusters connected with GitLab, [upgrade your GitLab agents for Kubernetes](../user/clusters/agent/install/index.md#update-the-agent-version) to match your new GitLab version.

#### Elasticsearch

Before updating GitLab, confirm advanced search migrations are complete by
[checking for pending advanced search migrations](index.md#checking-for-pending-advanced-search-migrations).

After updating GitLab, you may have to upgrade
[Elasticsearch if the new version breaks compatibility](../integration/advanced_search/elasticsearch.md#version-requirements).
Updating Elasticsearch is **out of scope for GitLab Support**.

## Troubleshooting

If anything doesn't go as planned:

- If time is of the essence, copy any errors and gather any logs to later analyze,
  and then [roll back to the last working version](#rollback-plan). You can use
  the following tools to help you gather data:
  - [`gitlabsos`](https://gitlab.com/gitlab-com/support/toolbox/gitlabsos) if
    you installed GitLab using the Linux package or Docker.
  - [`kubesos`](https://gitlab.com/gitlab-com/support/toolbox/kubesos/) if
    you installed GitLab using the Helm Charts.
- For support:
  - [Contact GitLab Support](https://support.gitlab.com/hc/en-us) and,
    if you have one, your Customer Success Manager.
  - If [the situation qualifies](https://about.gitlab.com/support/#definitions-of-support-impact)
    and [your plan includes emergency support](https://about.gitlab.com/support/#priority-support),
    create an emergency ticket.
