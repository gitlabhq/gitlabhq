---
stage: Systems
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Bring a demoted primary site back online
---

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab Self-Managed

After a failover, it is possible to fail back to the demoted **primary** site to
restore your original configuration. This process consists of two steps:

1. Making the old **primary** site a **secondary** site.
1. Promoting a **secondary** site to a **primary** site.

WARNING:
If you have any doubts about the consistency of the data on this site, we recommend setting it up from scratch.

## Configure the former **primary** site to be a **secondary** site

Since the former **primary** site is out of sync with the current **primary** site, the first step is to bring the former **primary** site up to date. Note, deletion of data stored on disk like
repositories and uploads is not replayed when bringing the former **primary** site back
into sync, which may result in increased disk usage.
Alternatively, you can [set up a new **secondary** GitLab instance](../setup/_index.md) to avoid this.

To bring the former **primary** site up to date:

1. SSH into the former **primary** site that has fallen behind.
1. Remove `/etc/gitlab/gitlab-cluster.json` if it exists.

   If the site to be re-added as a **secondary** site was promoted with the `gitlab-ctl geo promote` command, then it may contain a `/etc/gitlab/gitlab-cluster.json` file. For example during `gitlab-ctl reconfigure`, you may notice output like:

   ```plaintext
   The 'geo_primary_role' is defined in /etc/gitlab/gitlab-cluster.json as 'true' and overrides the setting in the /etc/gitlab/gitlab.rb
   ```

   If so, then `/etc/gitlab/gitlab-cluster.json` must be deleted from every Sidekiq, PostgreSQL, Gitaly, and Rails node in the site, to make `/etc/gitlab/gitlab.rb` the single source of truth again.

1. Make sure all the services are up:

   ```shell
   sudo gitlab-ctl start
   ```

   NOTE:
   If you [disabled the **primary** site permanently](_index.md#step-2-permanently-disable-the-primary-site),
   you need to undo those steps now. For distributions with systemd, such as Debian/Ubuntu/CentOS7+, you must run
   `sudo systemctl enable gitlab-runsvdir`. For distributions without systemd, such as CentOS 6, you need to install
   the GitLab instance from scratch and set it up as a **secondary** site by
   following [Setup instructions](../setup/_index.md). In this case, you don't need to follow the next step.

   NOTE:
   If you [changed the DNS records](_index.md#step-4-optional-updating-the-primary-domain-dns-record)
   for this site during disaster recovery procedure you may need to
   [block all the writes to this site](planned_failover.md#prevent-updates-to-the-primary-site)
   during this procedure.

1. [Set up Geo](../setup/_index.md). In this case, the **secondary** site
   refers to the former **primary** site.
   1. If [PgBouncer](../../postgresql/pgbouncer.md) was enabled on the **current secondary** site
      (when it was a primary site) disable it by editing `/etc/gitlab/gitlab.rb`
      and running `sudo gitlab-ctl reconfigure`.
   1. You can then set up database replication on the **secondary** site.

If you have lost your original **primary** site, follow the
[setup instructions](../setup/_index.md) to set up a new **secondary** site.

## Promote the **secondary** site to **primary** site

When the initial replication is complete and the **primary** site and **secondary** site are
closely in sync, you can do a [planned failover](planned_failover.md).

## Restore the **secondary** site

If your objective is to have two sites again, you need to bring your **secondary**
site back online as well by repeating the first step
([configure the former **primary** site to be a **secondary** site](#configure-the-former-primary-site-to-be-a-secondary-site))
for the **secondary** site.

### Restoring additional **secondary** sites

If there is more than one **secondary** site, the remaining sites can be brought online now. For each of the remaining sites, [initiate the replication process](../setup/database.md#step-3-initiate-the-replication-process) with the **primary** site.

## Skipping re-transfer of data on a **secondary** site

When a secondary site is added, if it contains data that would otherwise be synced from the primary, then Geo avoids re-transferring the data.

- Git repositories are transferred by `git fetch`, which only transfers missing refs.
- Geo's container registry sync code compares tags and only pulls missing tags.
- [Blobs/files](#skipping-re-transfer-of-blobs-or-files) are skipped if they exist on the first sync.

Use-cases:

- You do a planned failover and demote the old primary site by attaching it as a secondary site without rebuilding it.
- You have multiple secondary Geo sites. You do a planned failover and reattach the other secondary Geo sites without rebuilding them.
- You do a failover test by promoting and demoting a secondary site and reattach it without rebuilding it.
- You restore a backup and attach the site as a secondary site.
- You manually copy data to a secondary site to workaround a sync problem.
- You delete or truncate registry table rows in the Geo tracking database to workaround a problem.
- You reset the Geo tracking database to workaround a problem.

### Skipping re-transfer of blobs or files

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/352530) in GitLab 16.8 [with a flag](../../feature_flags.md) named `geo_skip_download_if_exists`. Disabled by default.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/435788) in GitLab 16.9. Feature flag `geo_skip_download_if_exists` removed.

When you add a secondary site which has preexisting file data, then the secondary Geo site will avoid re-transferring that data. This applies to:

- CI job artifacts
- CI pipeline artifacts
- CI secure files
- LFS objects
- Merge request diffs
- Package files
- Pages deployments
- Terraform state versions
- Uploads
- Dependency proxy manifests
- Dependency proxy blobs

If the secondary site's copy is actually corrupted, then background verification will eventually fail, and the file will be resynced.

Files will only be skipped in this manner if they do not have a corresponding registry record in the Geo tracking database. The conditions are strict because resyncing is almost always intentional, and we cannot risk mistakenly skipping a transfer.
