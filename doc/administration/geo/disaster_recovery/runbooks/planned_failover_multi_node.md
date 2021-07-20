---
stage: Enablement
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: howto
---

WARNING:
This runbook is in **alpha**. For complete, production-ready documentation, see the
[disaster recovery documentation](../index.md).

# Disaster Recovery (Geo) promotion runbooks **(PREMIUM SELF)**

## Geo planned failover for a multi-node configuration

| Component   | Configuration   |
|-------------|-----------------|
| PostgreSQL  | Omnibus-managed |
| Geo site    | Multi-node      |
| Secondaries | One             |

This runbook guides you through a planned failover of a multi-node Geo site
with one secondary. The following [2000 user reference architecture](../../../../administration/reference_architectures/2k_users.md) is assumed:

```mermaid
graph TD
   subgraph main[Geo deployment]
      subgraph Primary[Primary site, multi-node]
         Node_1[Rails node 1]
         Node_2[Rails node 2]
         Node_3[PostgreSQL node]
         Node_4[Gitaly node]
         Node_5[Redis node]
         Node_6[Monitoring node]
      end
      subgraph Secondary[Secondary site, multi-node]
         Node_7[Rails node 1]
         Node_8[Rails node 2]
         Node_9[PostgreSQL node]
         Node_10[Gitaly node]
         Node_11[Redis node]
         Node_12[Monitoring node]
      end
   end
```

The load balancer node and optional NFS server are omitted for clarity.

This guide results in the following:

1. An offline primary.
1. A promoted secondary that is now the new primary.

What is not covered:

1. Re-adding the old **primary** as a secondary.
1. Adding a new secondary.

### Preparation

NOTE:
Before following any of those steps, make sure you have `root` access to the
**secondary** to promote it, since there isn't provided an automated way to
promote a Geo replica and perform a failover.

On the **secondary** node:

1. On the top bar, select **Menu >** **{admin}** **Admin**.
1. On the left sidebar, select **Geo > Nodes** to see its status.
   Replicated objects (shown in green) should be close to 100%,
   and there should be no failures (shown in red). If a large proportion of
   objects aren't yet replicated (shown in gray), consider giving the node more
   time to complete.

   ![Replication status](../../replication/img/geo_node_dashboard_v14_0.png)

If any objects are failing to replicate, this should be investigated before
scheduling the maintenance window. After a planned failover, anything that
failed to replicate is **lost**.

You can use the
[Geo status API](../../../../api/geo_nodes.md#retrieve-project-sync-or-verification-failures-that-occurred-on-the-current-node)
to review failed objects and the reasons for failure.
A common cause of replication failures is the data being missing on the
**primary** node - you can resolve these failures by restoring the data from backup,
or removing references to the missing data.

The maintenance window won't end until Geo replication and verification is
completely finished. To keep the window as short as possible, you should
ensure these processes are close to 100% as possible during active use.

If the **secondary** node is still replicating data from the **primary** node,
follow these steps to avoid unnecessary data loss:

1. Until a [read-only mode](https://gitlab.com/gitlab-org/gitlab/-/issues/14609)
   is implemented, updates must be prevented from happening manually to the
   **primary**. Note that your **secondary** node still needs read-only
   access to the **primary** node during the maintenance window:

   1. At the scheduled time, using your cloud provider or your node's firewall, block
      all HTTP, HTTPS and SSH traffic to/from the **primary** node, **except** for your IP and
      the **secondary** node's IP.

      For instance, you can run the following commands on the **primary** node:

      ```shell
      sudo iptables -A INPUT -p tcp -s <secondary_node_ip> --destination-port 22 -j ACCEPT
      sudo iptables -A INPUT -p tcp -s <your_ip> --destination-port 22 -j ACCEPT
      sudo iptables -A INPUT --destination-port 22 -j REJECT

      sudo iptables -A INPUT -p tcp -s <secondary_node_ip> --destination-port 80 -j ACCEPT
      sudo iptables -A INPUT -p tcp -s <your_ip> --destination-port 80 -j ACCEPT
      sudo iptables -A INPUT --tcp-dport 80 -j REJECT

      sudo iptables -A INPUT -p tcp -s <secondary_node_ip> --destination-port 443 -j ACCEPT
      sudo iptables -A INPUT -p tcp -s <your_ip> --destination-port 443 -j ACCEPT
      sudo iptables -A INPUT --tcp-dport 443 -j REJECT
      ```

      From this point, users are unable to view their data or make changes on the
      **primary** node. They are also unable to log in to the **secondary** node.
      However, existing sessions need to work for the remainder of the maintenance period, and
      so public data is accessible throughout.

   1. Verify the **primary** node is blocked to HTTP traffic by visiting it in browser via
      another IP. The server should refuse connection.

   1. Verify the **primary** node is blocked to Git over SSH traffic by attempting to pull an
      existing Git repository with an SSH remote URL. The server should refuse
      connection.

   1. On the **primary** node:
      1. On the top bar, select **Menu >** **{admin}** **Admin**.
      1. On the left sidebar, select **Monitoring > Background Jobs**.
      1. On the Sidekiq dhasboard, select **Cron**.
      1. Select `Disable All` to disable any non-Geo periodic background jobs.
      1. Select `Enable` for the `geo_sidekiq_cron_config_worker` cron job.
         This job will re-enable several other cron jobs that are essential for planned
         failover to complete successfully.

1. Finish replicating and verifying all data:

   WARNING:
   Not all data is automatically replicated. Read more about
   [what is excluded](../planned_failover.md#not-all-data-is-automatically-replicated).

   1. If you are manually replicating any
      [data not managed by Geo](../../replication/datatypes.md#limitations-on-replicationverification),
      trigger the final replication process now.
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
      1. [Run an integrity check](../../../raketasks/check.md) to verify the integrity
         of CI artifacts, LFS objects, and uploads in file storage.

   At this point, your **secondary** node contains an up-to-date copy of everything the
   **primary** node has, meaning nothing is lost when you fail over.

1. In this final step, you need to permanently disable the **primary** node.

   WARNING:
   When the **primary** node goes offline, there may be data saved on the **primary** node
   that has not been replicated to the **secondary** node. This data should be treated
   as lost if you proceed.

   NOTE:
   If you plan to [update the **primary** domain DNS record](../index.md#step-4-optional-updating-the-primary-domain-dns-record),
   you may wish to lower the TTL now to speed up propagation.

   When performing a failover, we want to avoid a split-brain situation where
   writes can occur in two different GitLab instances. So to prepare for the
   failover, you must disable the **primary** node:

   - If you have SSH access to the **primary** node, stop and disable GitLab:

     ```shell
     sudo gitlab-ctl stop
     ```

     Prevent GitLab from starting up again if the server unexpectedly reboots:

     ```shell
     sudo systemctl disable gitlab-runsvdir
     ```

     NOTE:
     (**CentOS only**) In CentOS 6 or older, there is no easy way to prevent GitLab from being
     started if the machine reboots isn't available (see [Omnibus GitLab issue #3058](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/3058)).
     It may be safest to uninstall the GitLab package completely with `sudo yum remove gitlab-ee`.

     NOTE:
     (**Ubuntu 14.04 LTS**) If you are using an older version of Ubuntu
     or any other distribution based on the Upstart init system, you can prevent GitLab
     from starting if the machine reboots as `root` with
     `initctl stop gitlab-runsvvdir && echo 'manual' > /etc/init/gitlab-runsvdir.override && initctl reload-configuration`.

   - If you do not have SSH access to the **primary** node, take the machine offline and
     prevent it from rebooting. Since there are many ways you may prefer to accomplish
     this, we avoid a single recommendation. You may need to:

     - Reconfigure the load balancers.
     - Change DNS records (for example, point the **primary** DNS record to the
       **secondary** node to stop using the **primary** node).
     - Stop the virtual servers.
     - Block traffic through a firewall.
     - Revoke object storage permissions from the **primary** node.
     - Physically disconnect a machine.

### Promoting the **secondary** node

NOTE:
A new **secondary** should not be added at this time. If you want to add a new
**secondary**, do this after you have completed the entire process of promoting
the **secondary** to the **primary**.

WARNING:
If you encounter an `ActiveRecord::RecordInvalid: Validation failed: Name has already been taken` error during this process, read
[the troubleshooting advice](../../replication/troubleshooting.md#fixing-errors-during-a-failover-or-when-promoting-a-secondary-to-a-primary-node).

The `gitlab-ctl promote-to-primary-node` command cannot be used yet in
conjunction with multiple servers, as it can only
perform changes on a **secondary** with only a single machine. Instead, you must
do this manually.

WARNING:
In GitLab 13.2 and 13.3, promoting a secondary node to a primary while the
secondary is paused fails. Do not pause replication before promoting a
secondary. If the node is paused, be sure to resume before promoting. This
issue has been fixed in GitLab 13.4 and later.

WARNING:
   If the secondary node [has been paused](../../../geo/index.md#pausing-and-resuming-replication), this performs
a point-in-time recovery to the last known state.
Data that was created on the primary while the secondary was paused is lost.

1. SSH in to the PostgreSQL node in the **secondary** and promote PostgreSQL separately:

   ```shell
   sudo gitlab-ctl promote-db
   ```

   In GitLab 12.8 and earlier, see [Message: `sudo: gitlab-pg-ctl: command not found`](../../replication/troubleshooting.md#message-sudo-gitlab-pg-ctl-command-not-found).

1. Edit `/etc/gitlab/gitlab.rb` on every machine in the **secondary** to
   reflect its new status as **primary** by removing any lines that enabled the
   `geo_secondary_role`:

   ```ruby
   ## In pre-11.5 documentation, the role was enabled as follows. Remove this line.
   geo_secondary_role['enable'] = true

   ## In 11.5+ documentation, the role was enabled as follows. Remove this line.
   roles ['geo_secondary_role']
   ```

   After making these changes [Reconfigure GitLab](../../../restart_gitlab.md#omnibus-gitlab-reconfigure) each
   machine so the changes take effect.

1. Promote the **secondary** to **primary**. SSH into a single Rails node
   server and execute:

   ```shell
   sudo gitlab-rake geo:set_secondary_as_primary
   ```

1. Verify you can connect to the newly promoted **primary** using the URL used
   previously for the **secondary**.

1. Success! The **secondary** has now been promoted to **primary**.

### Next steps

To regain geographic redundancy as quickly as possible, you should
[add a new **secondary** node](../../setup/index.md). To
do that, you can re-add the old **primary** as a new secondary and bring it back
online.
