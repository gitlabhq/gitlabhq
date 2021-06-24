---
stage: Enablement
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: howto
---

# Disaster recovery for planned failover **(PREMIUM SELF)**

The primary use-case of Disaster Recovery is to ensure business continuity in
the event of unplanned outage, but it can be used in conjunction with a planned
failover to migrate your GitLab instance between regions without extended
downtime.

As replication between Geo nodes is asynchronous, a planned failover requires
a maintenance window in which updates to the **primary** node are blocked. The
length of this window is determined by your replication capacity - once the
**secondary** node is completely synchronized with the **primary** node, the failover can occur without
data loss.

This document assumes you already have a fully configured, working Geo setup.
Please read it and the [Disaster Recovery](index.md) failover
documentation in full before proceeding. Planned failover is a major operation,
and if performed incorrectly, there is a high risk of data loss. Consider
rehearsing the procedure until you are comfortable with the necessary steps and
have a high degree of confidence in being able to perform them accurately.

## Not all data is automatically replicated

If you are using any GitLab features that Geo [doesn't support](../replication/datatypes.md#limitations-on-replicationverification),
you must make separate provisions to ensure that the **secondary** node has an
up-to-date copy of any data associated with that feature. This may extend the
required scheduled maintenance period significantly.

A common strategy for keeping this period as short as possible for data stored
in files is to use `rsync` to transfer the data. An initial `rsync` can be
performed ahead of the maintenance window; subsequent `rsync`s (including a
final transfer inside the maintenance window) then transfers only the
*changes* between the **primary** node and the **secondary** nodes.

Repository-centric strategies for using `rsync` effectively can be found in the
[moving repositories](../../operations/moving_repositories.md) documentation; these strategies can
be adapted for use with any other file-based data, such as [GitLab Pages](../../pages/index.md#change-storage-path).

## Preflight checks

NOTE:
In GitLab 13.7 and earlier, if you have a data type with zero items to sync,
this command reports `ERROR - Replication is not up-to-date` even if
replication is actually up-to-date. This bug was fixed in GitLab 13.8 and
later.

Run this command to list out all preflight checks and automatically check if replication and verification are complete before scheduling a planned failover to ensure the process goes smoothly:

```shell
gitlab-ctl promotion-preflight-checks
```

Each step is described in more detail below.

### Object storage

If you have a large GitLab installation or cannot tolerate downtime, consider
[migrating to Object Storage](../replication/object_storage.md) **before** scheduling a planned failover.
Doing so reduces both the length of the maintenance window, and the risk of data
loss as a result of a poorly executed planned failover.

In GitLab 12.4, you can optionally allow GitLab to manage replication of Object Storage for
**secondary** nodes. For more information, see [Object Storage replication](../replication/object_storage.md).

### Review the configuration of each **secondary** node

Database settings are automatically replicated to the **secondary**  node, but the
`/etc/gitlab/gitlab.rb` file must be set up manually, and differs between
nodes. If features such as Mattermost, OAuth or LDAP integration are enabled
on the **primary** node but not the **secondary** node, they are lost during failover.

Review the `/etc/gitlab/gitlab.rb` file for both nodes and ensure the **secondary** node
supports everything the **primary** node does **before** scheduling a planned failover.

### Run system checks

Run the following on both **primary** and **secondary** nodes:

```shell
gitlab-rake gitlab:check
gitlab-rake gitlab:geo:check
```

If any failures are reported on either node, they should be resolved **before**
scheduling a planned failover.

### Check that secrets match between nodes

The SSH host keys and `/etc/gitlab/gitlab-secrets.json` files should be
identical on all nodes. Check this by running the following on all nodes and
comparing the output:

```shell
sudo sha256sum /etc/ssh/ssh_host* /etc/gitlab/gitlab-secrets.json
```

If any files differ, replace the content on the **secondary** node with the
content from the **primary** node.

### Ensure Geo replication is up-to-date

The maintenance window won't end until Geo replication and verification is
completely finished. To keep the window as short as possible, you should
ensure these processes are close to 100% as possible during active use.

On the **secondary** node:

1. On the top bar, select **Menu >** **{admin}** **Admin**.
1. On the left sidebar, select **Geo > Nodes**.
   Replicated objects (shown in green) should be close to 100%,
   and there should be no failures (shown in red). If a large proportion of
   objects aren't yet replicated (shown in gray), consider giving the node more
   time to complete

   ![Replication status](../replication/img/geo_node_dashboard_v14_0.png)

If any objects are failing to replicate, this should be investigated before
scheduling the maintenance window. Following a planned failover, anything that
failed to replicate is **lost**.

You can use the [Geo status API](../../../api/geo_nodes.md#retrieve-project-sync-or-verification-failures-that-occurred-on-the-current-node) to review failed objects and
the reasons for failure.

A common cause of replication failures is the data being missing on the
**primary** node - you can resolve these failures by restoring the data from backup,
or removing references to the missing data.

### Verify the integrity of replicated data

This [content was moved to another location](background_verification.md).

### Notify users of scheduled maintenance

On the **primary** node:

1. On the top bar, select **Menu >** **{admin}** **Admin**.
1. On the left sidebar, select **Messages**.
1. Add a message notifying users on the maintenance window.
   You can check under **Geo > Nodes** to estimate how long it
   takes to finish syncing.
1. Select **Add broadcast message**.

## Prevent updates to the **primary** node

To ensure that all data is replicated to a secondary site, updates (write requests) need to
be disabled on the **primary** site:

1. Enable [maintenance mode](../../maintenance_mode/index.md) on the **primary** node.
1. On the top bar, select **Menu >** **{admin}** **Admin**.
1. On the left sidebar, select **Monitoring > Background Jobs**.
1. On the Sidekiq dashboard, select **Cron**.
1. Select `Disable All` to disable non-Geo periodic background jobs.
1. Select `Enable` for the `geo_sidekiq_cron_config_worker` cron job.
   This job re-enables several other cron jobs that are essential for planned
   failover to complete successfully.

## Finish replicating and verifying all data

1. If you are manually replicating any data not managed by Geo, trigger the
   final replication process now.
1. On the **primary** node:
   1. On the top bar, select **Menu >** **{admin}** **Admin**.
   1. On the left sidebar, select **Monitoring > Background Jobs**.
   1. On the Sidekiq dashboard, select **Queues**, and wait for all queues except
      those with `geo` in the name to drop to 0.
      These queues contain work that has been submitted by your users; failing over
      before it is completed, causes the work to be lost.
   1. On the left sidebar, select **Geo > Nodes** and wait for the
      following conditions to be true of the **secondary** node you are failing over to:

      - All replication meters reach 100% replicated, 0% failures.
      - All verification meters reach 100% verified, 0% failures.
      - Database replication lag is 0ms.
      - The Geo log cursor is up to date (0 events behind).

1. On the **secondary** node:
   1. On the top bar, select **Menu >** **{admin}** **Admin**.
   1. On the left sidebar, select **Monitoring > Background Jobs**.
   1. On the Sidekiq dashboard, select **Queues**, and wait for all the `geo`
      queues to drop to 0 queued and 0 running jobs.
   1. [Run an integrity check](../../raketasks/check.md) to verify the integrity
      of CI artifacts, LFS objects, and uploads in file storage.

At this point, your **secondary** node contains an up-to-date copy of everything the
**primary** node has, meaning nothing was lost when you fail over.

## Promote the **secondary** node

Finally, follow the [Disaster Recovery docs](index.md) to promote the
**secondary** node to a **primary** node. This process causes a brief outage on the **secondary** node, and users may need to log in again.

Once it is completed, the maintenance window is over! Your new **primary** node, now
begin to diverge from the old one. If problems do arise at this point, failing
back to the old **primary** node [is possible](bring_primary_back.md), but likely to result
in the loss of any data uploaded to the new **primary** in the meantime.

Don't forget to remove the broadcast message after failover is complete.
