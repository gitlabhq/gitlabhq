---
stage: Enablement
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: howto
---

# Disaster Recovery (Geo) **(PREMIUM SELF)**

Geo replicates your database, your Git repositories, and few other assets,
but there are some [limitations](../index.md#limitations).

WARNING:
Disaster recovery for multi-secondary configurations is in **Alpha**.
For the latest updates, check the [Disaster Recovery epic for complete maturity](https://gitlab.com/groups/gitlab-org/-/epics/3574).
Multi-secondary configurations require the complete re-synchronization and re-configuration of all non-promoted secondaries and
causes downtime.

## Promoting a **secondary** Geo node in single-secondary configurations

We don't currently provide an automated way to promote a Geo replica and do a
failover, but you can do it manually if you have `root` access to the machine.

This process promotes a **secondary** Geo node to a **primary** node. To regain
geographic redundancy as quickly as possible, you should add a new **secondary** node
immediately after following these instructions.

### Step 1. Allow replication to finish if possible

If the **secondary** node is still replicating data from the **primary** node, follow
[the planned failover docs](planned_failover.md) as closely as possible in
order to avoid unnecessary data loss.

### Step 2. Permanently disable the **primary** node

WARNING:
If the **primary** node goes offline, there may be data saved on the **primary** node
that have not been replicated to the **secondary** node. This data should be treated
as lost if you proceed.

If an outage on the **primary** node happens, you should do everything possible to
avoid a split-brain situation where writes can occur in two different GitLab
instances, complicating recovery efforts. So to prepare for the failover, we
must disable the **primary** node.

- If you have SSH access:

  1. SSH into the **primary** node to stop and disable GitLab:

     ```shell
     sudo gitlab-ctl stop
     ```

  1. Prevent GitLab from starting up again if the server unexpectedly reboots:

     ```shell
     sudo systemctl disable gitlab-runsvdir
     ```

- If you do not have SSH access to the **primary** node, take the machine offline and
  prevent it from rebooting by any means at your disposal.
  You might need to:

  - Reconfigure the load balancers.
  - Change DNS records (for example, point the primary DNS record to the
    **secondary** node to stop usage of the **primary** node).
  - Stop the virtual servers.
  - Block traffic through a firewall.
  - Revoke object storage permissions from the **primary** node.
  - Physically disconnect a machine.

  If you plan to [update the primary domain DNS record](#step-4-optional-updating-the-primary-domain-dns-record),
  you may wish to lower the TTL now to speed up propagation.

### Step 3. Promoting a **secondary** node

WARNING:
In GitLab 13.2 and 13.3, promoting a secondary node to a primary while the
secondary is paused fails. Do not pause replication before promoting a
secondary. If the node is paused, be sure to resume before promoting.
This issue has been fixed in GitLab 13.4 and later.

Note the following when promoting a secondary:

- If replication was paused on the secondary node (for example as a part of
  upgrading, while you were running a version of GitLab earlier than 13.4), you
  _must_ [enable the node by using the database](../replication/troubleshooting.md#message-activerecordrecordinvalid-validation-failed-enabled-geo-primary-node-cannot-be-disabled)
  before proceeding. If the secondary node
  [has been paused](../../geo/index.md#pausing-and-resuming-replication), the promotion
  performs a point-in-time recovery to the last known state.
  Data that was created on the primary while the secondary was paused is lost.
- A new **secondary** should not be added at this time. If you want to add a new
  **secondary**, do this after you have completed the entire process of promoting
  the **secondary** to the **primary**.
- If you encounter an `ActiveRecord::RecordInvalid: Validation failed: Name has already been taken`
  error message during this process, for more information, see this
  [troubleshooting advice](../replication/troubleshooting.md#fixing-errors-during-a-failover-or-when-promoting-a-secondary-to-a-primary-node).
- If you run into errors when using `--force` or `--skip-preflight-checks` before 13.5 during this process,
  for more information, see this
  [troubleshooting advice](../replication/troubleshooting.md#errors-when-using---skip-preflight-checks-or---force).

#### Promoting a **secondary** node running on a single machine

1. SSH in to your **secondary** node and login as root:

   ```shell
   sudo -i
   ```

1. If you're using GitLab 13.5 and later, skip this step. If not, edit
   `/etc/gitlab/gitlab.rb` and remove any of the following lines that
   might be present:

   ```ruby
   geo_secondary_role['enable'] = true
   roles ['geo_secondary_role']
   ```

1. Promote the **secondary** node to the **primary** node:

   - To promote the secondary node to primary along with [preflight checks](planned_failover.md#preflight-checks):

     ```shell
     gitlab-ctl promote-to-primary-node
     ```

   - If you have already run the preflight checks separately or don't want to run them,
     you can skip them with:

     ```shell
     gitlab-ctl promote-to-primary-node --skip-preflight-checks
     ```

     NOTE:
     In GitLab 13.7 and earlier, if you have a data type with zero items to sync
     and don't skip the preflight checks, promoting the secondary reports
     `ERROR - Replication is not up-to-date` even if replication is actually
     up-to-date. If replication and verification output
     shows that it is complete, you can skip the preflight checks to make the
     command complete promotion. This bug was fixed in GitLab 13.8 and later.

   - To promote the secondary node to primary **without any further confirmation**,
     even when preflight checks fail:

     ```shell
     gitlab-ctl promote-to-primary-node --force
     ```

1. Verify you can connect to the newly-promoted **primary** node using the URL used
   previously for the **secondary** node.
1. If successful, the **secondary** node is now promoted to the **primary** node.

#### Promoting a **secondary** node with multiple servers

The `gitlab-ctl promote-to-primary-node` command cannot be used yet in
conjunction with multiple servers, as it can only
perform changes on a **secondary** with only a single machine. Instead, you must
do this manually.

1. SSH in to the database node in the **secondary** and trigger PostgreSQL to
   promote to read-write:

   ```shell
   sudo gitlab-ctl promote-db
   ```

   In GitLab 12.8 and earlier, see [Message: `sudo: gitlab-pg-ctl: command not found`](../replication/troubleshooting.md#message-sudo-gitlab-pg-ctl-command-not-found).

1. Edit `/etc/gitlab/gitlab.rb` on every node in the **secondary** site to
   reflect its new status as **primary** by removing any of the following
   lines that might be present:

   ```ruby
   geo_secondary_role['enable'] = true
   roles ['geo_secondary_role']
   ```

   After making these changes, [reconfigure GitLab](../../restart_gitlab.md#omnibus-gitlab-reconfigure)
   on each machine so the changes take effect.

1. Promote the **secondary** to **primary**. SSH into a single application
   server and execute:

   ```shell
   sudo gitlab-rake geo:set_secondary_as_primary
   ```

1. Verify you can connect to the newly-promoted **primary** using the URL used
   previously for the **secondary**.
1. If successful, the **secondary** node is now promoted to the **primary** node.

#### Promoting a **secondary** node with a Patroni standby cluster

The `gitlab-ctl promote-to-primary-node` command cannot be used yet in
conjunction with a Patroni standby cluster, as it can only
perform changes on a **secondary** with only a single machine. Instead, you must
do this manually.

1. SSH in to the Standby Leader database node in the **secondary** and trigger PostgreSQL to
   promote to read-write:

   ```shell
   sudo gitlab-ctl promote-db
   ```

1. Edit `/etc/gitlab/gitlab.rb` on every application and Sidekiq nodes in the secondary to reflect its new status as primary by removing any of the following lines that might be present:

   ```ruby
   geo_secondary_role['enable'] = true
   roles ['geo_secondary_role']
   ```

1. Edit `/etc/gitlab/gitlab.rb` on every Patroni node in the secondary to disable the standby cluster:

   ```ruby
   patroni['standby_cluster']['enable'] = false
   ```

1. Reconfigure GitLab on each machine for the changes to take effect:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. Promote the **secondary** to **primary**. SSH into a single application server and execute:

   ```shell
   sudo gitlab-rake geo:set_secondary_as_primary
   ```

1. Verify you can connect to the newly-promoted **primary** using the URL used
   previously for the **secondary**.
1. If successful, the **secondary** node is now promoted to the **primary** node.

#### Promoting a **secondary** node with an external PostgreSQL database

The `gitlab-ctl promote-to-primary-node` command cannot be used in conjunction with
an external PostgreSQL database, as it can only perform changes on a **secondary**
node with GitLab and the database on the same machine. As a result, a manual process is
required:

1. Promote the replica database associated with the **secondary** site. This
   sets the database to read-write. The instructions vary depending on where your database is hosted:
   - [Amazon RDS](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_ReadRepl.html#USER_ReadRepl.Promote)
   - [Azure PostgreSQL](https://docs.microsoft.com/en-us/azure/postgresql/howto-read-replicas-portal#stop-replication)
   - [Google Cloud SQL](https://cloud.google.com/sql/docs/mysql/replication/manage-replicas#promote-replica)
   - For other external PostgreSQL databases, save the following script in your
     secondary node, for example `/tmp/geo_promote.sh`, and modify the connection
     parameters to match your environment. Then, execute it to promote the replica:

     ```shell
     #!/bin/bash

     PG_SUPERUSER=postgres

     # The path to your pg_ctl binary. You may need to adjust this path to match
     # your PostgreSQL installation
     PG_CTL_BINARY=/usr/lib/postgresql/10/bin/pg_ctl

     # The path to your PostgreSQL data directory. You may need to adjust this
     # path to match your PostgreSQL installation. You can also run
     # `SHOW data_directory;` from PostgreSQL to find your data directory
     PG_DATA_DIRECTORY=/etc/postgresql/10/main

     # Promote the PostgreSQL database and allow read/write operations
     sudo -u $PG_SUPERUSER $PG_CTL_BINARY -D $PG_DATA_DIRECTORY promote
     ```

1. Edit `/etc/gitlab/gitlab.rb` on every node in the **secondary** site to
   reflect its new status as **primary** by removing any of the following
   lines that might be present:

   ```ruby
   geo_secondary_role['enable'] = true
   roles ['geo_secondary_role']
   ```

   After making these changes [Reconfigure GitLab](../../restart_gitlab.md#omnibus-gitlab-reconfigure)
   on each node so the changes take effect.

1. Promote the **secondary** to **primary**. SSH into a single secondary application
   node and execute:

   ```shell
   sudo gitlab-rake geo:set_secondary_as_primary
   ```

1. Verify you can connect to the newly-promoted **primary** using the URL used
   previously for the **secondary**.
1. If successful, the **secondary** node is now promoted to the **primary** node.

### Step 4. (Optional) Updating the primary domain DNS record

Updating the DNS records for the primary domain to point to the **secondary** node
to prevent the need to update all references to the primary domain to the
secondary domain, like changing Git remotes and API URLs.

1. SSH into the **secondary** node and login as root:

   ```shell
   sudo -i
   ```

1. Update the primary domain's DNS record. After updating the primary domain's
   DNS records to point to the **secondary** node, edit `/etc/gitlab/gitlab.rb` on the
   **secondary** node to reflect the new URL:

   ```ruby
   # Change the existing external_url configuration
   external_url 'https://<new_external_url>'
   ```

   NOTE:
   Changing `external_url` does not prevent access via the old secondary URL, as
   long as the secondary DNS records are still intact.

1. Reconfigure the **secondary** node for the change to take effect:

   ```shell
   gitlab-ctl reconfigure
   ```

1. Execute the command below to update the newly promoted **primary** node URL:

   ```shell
   gitlab-rake geo:update_primary_node_url
   ```

   This command uses the changed `external_url` configuration defined
   in `/etc/gitlab/gitlab.rb`.

1. For GitLab 11.11 through 12.7 only, you may need to update the **primary**
   node's name in the database. This bug has been fixed in GitLab 12.8.

   To determine if you need to do this, search for the
   `gitlab_rails["geo_node_name"]` setting in your `/etc/gitlab/gitlab.rb`
   file. If it is commented out with `#` or not found at all, then you
   need to update the **primary** node's name in the database. You can search for it
   like so:

   ```shell
   grep "geo_node_name" /etc/gitlab/gitlab.rb
   ```

   To update the **primary** node's name in the database:

   ```shell
   gitlab-rails runner 'Gitlab::Geo.primary_node.update!(name: GeoNode.current_node_name)'
   ```

1. Verify you can connect to the newly promoted **primary** using its URL.
   If you updated the DNS records for the primary domain, these changes may
   not have yet propagated depending on the previous DNS records TTL.

### Step 5. (Optional) Add **secondary** Geo node to a promoted **primary** node

Promoting a **secondary** node to **primary** node using the process above does not enable
Geo on the new **primary** node.

To bring a new **secondary** node online, follow the [Geo setup instructions](../index.md#setup-instructions).

### Step 6. (Optional) Removing the secondary's tracking database

Every **secondary** has a special tracking database that is used to save the status of the synchronization of all the items from the **primary**.
Because the **secondary** is already promoted, that data in the tracking database is no longer required.

The data can be removed with the following command:

```shell
sudo rm -rf /var/opt/gitlab/geo-postgresql
```

If you have any `geo_secondary[]` configuration options enabled in your `gitlab.rb`
file, these can be safely commented out or removed, and then [reconfigure GitLab](../../restart_gitlab.md#omnibus-gitlab-reconfigure)
for the changes to take effect.

## Promoting secondary Geo replica in multi-secondary configurations

If you have more than one **secondary** node and you need to promote one of them, we suggest you follow
[Promoting a **secondary** Geo node in single-secondary configurations](#promoting-a-secondary-geo-node-in-single-secondary-configurations)
and after that you also need two extra steps.

### Step 1. Prepare the new **primary** node to serve one or more **secondary** nodes

1. SSH into the new **primary** node and login as root:

   ```shell
   sudo -i
   ```

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   ## Enable a Geo Primary role (if you haven't yet)
   roles ['geo_primary_role']

   ##
   # Allow PostgreSQL client authentication from the primary and secondary IPs. These IPs may be
   # public or VPC addresses in CIDR format, for example ['198.51.100.1/32', '198.51.100.2/32']
   ##
   postgresql['md5_auth_cidr_addresses'] = ['<primary_node_ip>/32', '<secondary_node_ip>/32']

   # Every secondary server needs to have its own slot so specify the number of secondary nodes you're going to have
   postgresql['max_replication_slots'] = 1

   ##
   ## Disable automatic database migrations temporarily
   ## (until PostgreSQL is restarted and listening on the private address).
   ##
   gitlab_rails['auto_migrate'] = false
   ```

   (For more details about these settings you can read [Configure the primary server](../setup/database.md#step-1-configure-the-primary-server))

1. Save the file and reconfigure GitLab for the database listen changes and
   the replication slot changes to be applied:

   ```shell
   gitlab-ctl reconfigure
   ```

   Restart PostgreSQL for its changes to take effect:

   ```shell
   gitlab-ctl restart postgresql
   ```

1. Re-enable migrations now that PostgreSQL is restarted and listening on the
   private address.

   Edit `/etc/gitlab/gitlab.rb` and **change** the configuration to `true`:

   ```ruby
   gitlab_rails['auto_migrate'] = true
   ```

   Save the file and reconfigure GitLab:

   ```shell
   gitlab-ctl reconfigure
   ```

### Step 2. Initiate the replication process

Now we need to make each **secondary** node listen to changes on the new **primary** node. To do that you need
to [initiate the replication process](../setup/database.md#step-3-initiate-the-replication-process) again but this time
for another **primary** node. All the old replication settings are overwritten.

## Promoting a secondary Geo cluster in GitLab Cloud Native Helm Charts

When updating a Cloud Native Geo deployment, the process for updating any node that is external to the secondary Kubernetes cluster does not differ from the non Cloud Native approach. As such, you can always defer to [Promoting a secondary Geo node in single-secondary configurations](#promoting-a-secondary-geo-node-in-single-secondary-configurations) for more information.

The following sections assume you are using the `gitlab` namespace. If you used a different namespace when setting up your cluster, you should also replace `--namespace gitlab` with your namespace.

WARNING:
In GitLab 13.2 and 13.3, promoting a secondary site to a primary while the
secondary is paused fails. Do not pause replication before promoting a
secondary. If the site is paused, be sure to resume before promoting. This
issue has been fixed in GitLab 13.4 and later.

### Step 1. Permanently disable the **primary** cluster

WARNING:
If the **primary** site goes offline, there may be data saved on the **primary** site
that has not been replicated to the **secondary** site. This data should be treated
as lost if you proceed.

If an outage on the **primary** site happens, you should do everything possible to
avoid a split-brain situation where writes can occur in two different GitLab
instances, complicating recovery efforts. So to prepare for the failover, you
must disable the **primary** site:

- If you have access to the **primary** Kubernetes cluster, connect to it and disable the GitLab webservice and Sidekiq pods:

  ```shell
  kubectl --namespace gitlab scale deploy gitlab-geo-webservice-default --replicas=0
  kubectl --namespace gitlab scale deploy gitlab-geo-sidekiq-all-in-1-v1 --replicas=0
  ```

- If you do not have access to the **primary** Kubernetes cluster, take the cluster offline and
  prevent it from coming back online by any means at your disposal.
  You might need to:

  - Reconfigure the load balancers.
  - Change DNS records (for example, point the primary DNS record to the
    **secondary** site to stop usage of the **primary** site).
  - Stop the virtual servers.
  - Block traffic through a firewall.
  - Revoke object storage permissions from the **primary** site.
  - Physically disconnect a machine.

### Step 2. Promote all **secondary** nodes external to the cluster

WARNING:
If the secondary site [has been paused](../../geo/index.md#pausing-and-resuming-replication), this performs
a point-in-time recovery to the last known state.
Data that was created on the primary while the secondary was paused is lost.

1. SSH in to the database node in the **secondary** and trigger PostgreSQL to
   promote to read-write:

   ```shell
   sudo gitlab-ctl promote-db
   ```

   In GitLab 12.8 and earlier, see [Message: `sudo: gitlab-pg-ctl: command not found`](../replication/troubleshooting.md#message-sudo-gitlab-pg-ctl-command-not-found).

1. Edit `/etc/gitlab/gitlab.rb` on the database node in the **secondary** site to
   reflect its new status as **primary** by removing any lines that enabled the
   `geo_secondary_role`:

   NOTE:
   Depending on your architecture, these steps need to run on any GitLab node that is external to the **secondary** Kubernetes cluster.

   ```ruby
   ## In pre-11.5 documentation, the role was enabled as follows. Remove this line.
   geo_secondary_role['enable'] = true

   ## In 11.5+ documentation, the role was enabled as follows. Remove this line.
   roles ['geo_secondary_role']
   ```

   After making these changes, [reconfigure GitLab](../../restart_gitlab.md#omnibus-gitlab-reconfigure) on the database node.

### Step 3. Promote the **secondary** cluster

1. Find the task runner pod:

   ```shell
   kubectl --namespace gitlab get pods -lapp=task-runner
   ```

1. Promote the secondary:

   ```shell
   kubectl --namespace gitlab exec -ti gitlab-geo-task-runner-XXX -- gitlab-rake geo:set_secondary_as_primary
   ```

1. Update the existing cluster configuration.

   You can retrieve the existing configuration with Helm:

   ```shell
   helm --namespace gitlab get values gitlab-geo > gitlab.yaml
   ```

   The existing configuration contains a section for Geo that should resemble:

   ```yaml
   geo:
      enabled: true
      role: secondary
      nodeName: secondary.example.com
      psql:
         host: geo-2.db.example.com
         port: 5431
         password:
            secret: geo
            key: geo-postgresql-password
   ```

   To promote the **secondary** cluster to a **primary** cluster, update `role: secondary` to `role: primary`.

   If the cluster remains as a primary site, you can remove the entire `psql` section; it refers to the tracking database and is ignored whilst the cluster is acting as a primary site.

   Update the cluster with the new configuration:

   ```shell
   helm upgrade --install --version <current Chart version> gitlab-geo gitlab/gitlab --namespace gitlab -f gitlab.yaml
   ```

1. Verify you can connect to the newly promoted primary using the URL used previously for the secondary.

1. Success! The secondary has now been promoted to primary.

## Troubleshooting

This section was moved to [another location](../replication/troubleshooting.md#fixing-errors-during-a-failover-or-when-promoting-a-secondary-to-a-primary-node).
