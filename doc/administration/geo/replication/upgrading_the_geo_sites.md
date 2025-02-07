---
stage: Systems
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Upgrading the Geo sites
---

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab Self-Managed

WARNING:
Read these sections carefully before updating your Geo sites. Not following
version-specific upgrade steps may result in unexpected downtime. If you have
any specific questions, [contact Support](https://about.gitlab.com/support/#contact-support).
A database major version upgrade requires [re-initializing the PostgreSQL replication](https://docs.gitlab.com/omnibus/settings/database.html#upgrading-a-geo-instance)
to Geo secondaries. This applies to both Linux-packaged and externally-managed databases.
This may result in a larger than expected downtime.

Upgrading Geo sites involves performing:

1. Version-specific upgrade steps, depending on the version being upgraded to or from:
   - [GitLab 17 changes](../../../update/versions/gitlab_17_changes.md)
   - [GitLab 16 changes](../../../update/versions/gitlab_16_changes.md)
   - [GitLab 15 changes](../../../update/versions/gitlab_15_changes.md)
1. [General upgrade steps](#general-upgrade-steps), for all upgrades.

## General upgrade steps

NOTE:
These general upgrade steps require downtime in a multi-node setup.
If you want to avoid downtime, consider using [zero-downtime upgrades](../../../update/zero_downtime.md#multi-node--ha-deployment-with-geo).

To upgrade the Geo sites when a new GitLab version is released, upgrade **primary**
and all **secondary** sites:

1. Optional. [Pause replication on each **secondary** site](../replication/pause_resume_replication.md)
   to protect the disaster recovery (DR) capability of the **secondary** sites.
1. SSH into each node of the **primary** site.
1. [Upgrade GitLab on the **primary** site](../../../update/package/_index.md#by-using-the-official-repositories-recommended).
1. Perform testing on the **primary** site, particularly if you paused replication in step 1 to protect DR.
   [There are some suggestions for post-upgrade testing](../../../update/_index.md#pre-upgrade-and-post-upgrade-checks) in the upgrade documentation.
1. Ensure that the secrets in the `/etc/gitlab/gitlab-secrets.json` file of both the primary site and the secondary site are the same. The file must be the same on all of a site's nodes.
1. SSH into each node of **secondary** sites.
1. [Upgrade GitLab on each **secondary** site](../../../update/package/_index.md#by-using-the-official-repositories-recommended).
1. If you paused replication in step 1, [resume replication on each **secondary**](../_index.md#pausing-and-resuming-replication).
   Then, restart Puma and Sidekiq on each **secondary** site. This is to ensure they
   are initialized against the newer database schema that is now replicated from
   the previously upgraded **primary** site.

   ```shell
   sudo gitlab-ctl restart sidekiq
   sudo gitlab-ctl restart puma
   ```

1. [Test](#check-status-after-upgrading) **primary** and **secondary** sites, and check version in each.

### Check status after upgrading

Now that the upgrade process is complete, you may want to check whether
everything is working correctly:

1. Run the Geo Rake task on an application node for the primary and secondary sites. Everything should be green:

   ```shell
   sudo gitlab-rake gitlab:geo:check
   ```

1. Check the **primary** site's Geo dashboard for any errors.
1. Test the data replication by pushing code to the **primary** site and see if it
   is received by **secondary** sites.

If you encounter any issues, see the [Geo troubleshooting guide](troubleshooting/_index.md).
