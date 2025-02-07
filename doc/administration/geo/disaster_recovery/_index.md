---
stage: Systems
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Disaster Recovery (Geo)
---

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab Self-Managed

Geo replicates your database, your Git repositories, and other assets.
Some [known issues](../_index.md#known-issues) exist.

WARNING:
Multi-secondary configurations require the complete re-synchronization and re-configuration of all non-promoted secondaries and
causes downtime.

## Promoting a **secondary** Geo site in single-secondary configurations

While you can't automatically promote a Geo replica and do a failover,
you can promote it manually if you have `root` access to the machine.

This process promotes a **secondary** Geo site to a **primary** site. To regain
geographic redundancy as quickly as possible, you should add a new **secondary** site
immediately after following these instructions.

### Step 1. Allow replication to finish if possible

If the **secondary** site is still replicating data from the **primary** site, follow
[the planned failover docs](planned_failover.md) as closely as possible in
order to avoid unnecessary data loss.

### Step 2. Permanently disable the **primary** site

WARNING:
If the **primary** site goes offline, there may be data saved on the **primary** site
that have not been replicated to the **secondary** site. This data should be treated
as lost if you proceed.

If an outage on the **primary** site happens, you should do everything possible to
avoid a split-brain situation where writes can occur in two different GitLab
instances, complicating recovery efforts. So to prepare for the failover, we
must disable the **primary** site.

- If you have SSH access:

  1. SSH into the **primary** site to stop and disable GitLab:

     ```shell
     sudo gitlab-ctl stop
     ```

  1. Prevent GitLab from starting up again if the server unexpectedly reboots:

     ```shell
     sudo systemctl disable gitlab-runsvdir
     ```

- If you do not have SSH access to the **primary** site, take the machine offline and
  prevent it from rebooting by any means at your disposal.
  You might need to:

  - Reconfigure the load balancers.
  - Change DNS records (for example, point the primary DNS record to the
    **secondary** site to stop usage of the **primary** site).
  - Stop the virtual servers.
  - Block traffic through a firewall.
  - Revoke object storage permissions from the **primary** site.
  - Physically disconnect a machine.

  If you plan to [update the primary domain DNS record](#step-4-optional-updating-the-primary-domain-dns-record),
  you may wish to maintain a low TTL to ensure fast propagation of DNS changes.

  NOTE:
  The primary site's `/etc/gitlab/gitlab.rb` file is not copied to the secondary sites automatically during this process. Make sure that you back up the primary's `/etc/gitlab/gitlab.rb` file, so that you can later restore any needed values on your secondary sites.

### Step 3. Promoting a **secondary** site

Note the following when promoting a secondary:

- If the secondary site [has been paused](../replication/pause_resume_replication.md), the promotion
  performs a point-in-time recovery to the last known state.
  Data that was created on the primary while the secondary was paused is lost.
- A new **secondary** should not be added at this time. If you want to add a new
  **secondary**, do this after you have completed the entire process of promoting
  the **secondary** to the **primary**.
- If you encounter an `ActiveRecord::RecordInvalid: Validation failed: Name has already been taken`
  error message during this process, for more information, see this
  [troubleshooting advice](failover_troubleshooting.md#fixing-errors-during-a-failover-or-when-promoting-a-secondary-to-a-primary-site).
- If you are using separate URLs, you should [point the primary domain DNS at the newly promoted site](#step-4-optional-updating-the-primary-domain-dns-record). Otherwise, runners must be registered again with the newly promoted site, and all Git remotes, bookmarks, and external integrations must be updated.
- If you are using [location-aware DNS](../secondary_proxy/_index.md#configure-location-aware-dns), the runners should automatically connect to the new primary after the old primary is removed from the DNS entry.
- If you don't expect the runners connected to the previous primary to come back, you should remove them:
  - Through the UI:
    1. On the left sidebar, at the bottom, select **Admin**.
    1. Select **CI/CD > Runners** and remove them.
  - Using the [Runners API](../../../api/runners.md).

#### Promoting a **secondary** site running on a single node

1. SSH in to your **secondary** site and execute:

   - To promote the secondary site to primary:

     ```shell
     sudo gitlab-ctl geo promote
     ```

   - To promote the secondary site to primary **without any further confirmation**:

     ```shell
     sudo gitlab-ctl geo promote --force
     ```

1. Verify you can connect to the newly-promoted **primary** site using the URL used
   previously for the **secondary** site.
1. If successful, the **secondary** site is now promoted to the **primary** site.

#### Promoting a **secondary** site with multiple nodes

1. SSH to every Sidekiq, PostgreSQL, and Gitaly node in the **secondary** site and run one of the following commands:

   - To promote the node on the secondary site to primary:

     ```shell
     sudo gitlab-ctl geo promote
     ```

   - To promote the secondary site to primary **without any further confirmation**:

     ```shell
     sudo gitlab-ctl geo promote --force
     ```

1. SSH into each Rails node on your **secondary** site and run one of the following commands:

   - To promote the secondary site to primary:

     ```shell
     sudo gitlab-ctl geo promote
     ```

   - To promote the secondary site to primary **without any further confirmation**:

     ```shell
     sudo gitlab-ctl geo promote --force
     ```

1. Verify you can connect to the newly-promoted **primary** site using the URL used
   previously for the **secondary** site.
1. If successful, the **secondary** site is now promoted to the **primary** site.

#### Promoting a **secondary** site with a Patroni standby cluster

1. SSH to every Sidekiq, PostgreSQL, and Gitaly node in the **secondary** site and run one of the following commands:

   - To promote the secondary site to primary:

     ```shell
     sudo gitlab-ctl geo promote
     ```

   - To promote the secondary site to primary **without any further confirmation**:

     ```shell
     sudo gitlab-ctl geo promote --force
     ```

1. SSH into each Rails node on your **secondary** site and run one of the following commands:

   - To promote the secondary site to primary:

     ```shell
     sudo gitlab-ctl geo promote
     ```

   - To promote the secondary site to primary **without any further confirmation**:

     ```shell
     sudo gitlab-ctl geo promote --force
     ```

1. Verify you can connect to the newly-promoted **primary** site using the URL used
   previously for the **secondary** site.
1. If successful, the **secondary** site is now promoted to the **primary** site.

#### Promoting a **secondary** site with an external PostgreSQL database

The `gitlab-ctl geo promote` command can be used in conjunction with an external PostgreSQL database.
In this case, you must first manually promote the replica database associated
with the **secondary** site:

1. Promote the replica database associated with the **secondary** site. This
   sets the database to read-write. The instructions vary depending on where your database is hosted:
   - [Amazon RDS](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_ReadRepl.html#USER_ReadRepl.Promote)
   - [Azure PostgreSQL](https://learn.microsoft.com/en-us/azure/postgresql/single-server/how-to-read-replicas-portal#stop-replication)
   - [Google Cloud SQL](https://cloud.google.com/sql/docs/mysql/replication/manage-replicas#promote-replica)
   - For other external PostgreSQL databases, save the following script in your
     secondary site, for example `/tmp/geo_promote.sh`, and modify the connection
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

1. SSH to every Sidekiq, PostgreSQL, and Gitaly node in the **secondary** site and run one of the following commands:

   - To promote the secondary site to primary:

     ```shell
     sudo gitlab-ctl geo promote
     ```

   - To promote the secondary site to primary **without any further confirmation**:

     ```shell
     sudo gitlab-ctl geo promote --force
     ```

1. SSH into each Rails node on your **secondary** site and run one of the following commands:

   - To promote the secondary site to primary:

     ```shell
     sudo gitlab-ctl geo promote
     ```

   - To promote the secondary site to primary **without any further confirmation**:

     ```shell
     sudo gitlab-ctl geo promote --force
     ```

1. Verify you can connect to the newly-promoted **primary** site using the URL used
   previously for the **secondary** site.
1. If successful, the **secondary** site is now promoted to the **primary** site.

### Step 4. (Optional) Updating the primary domain DNS record

Update DNS records for the primary domain to point to the **secondary** site.
This removes the need to update all references to the primary domain, for example
changing Git remotes and API URLs.

1. SSH into the **secondary** site and login as root:

   ```shell
   sudo -i
   ```

1. Update the primary domain's DNS record. After updating the primary domain's
   DNS records to point to the **secondary** site, edit `/etc/gitlab/gitlab.rb` on the
   **secondary** site to reflect the new URL:

   ```ruby
   # Change the existing external_url configuration
   external_url 'https://<new_external_url>'
   ```

   NOTE:
   Changing `external_url` does not prevent access through the old secondary URL, as
   long as the secondary DNS records are still intact.

1. Update the **secondary**'s SSL certificate:

   - If you use the [Let's Encrypt integration](https://docs.gitlab.com/omnibus/settings/ssl/index.html#enable-the-lets-encrypt-integration),
     the certificate updates automatically.
   - If you had [manually set up](https://docs.gitlab.com/omnibus/settings/ssl/index.html#configure-https-manually),
     the **secondary**'s certificate, copy the certificate from the **primary** to the **secondary**.
     If you don't have access to the **primary**, issue a new certificate and make sure it contains
     both the **primary** and **secondary** URLs in the subject alternative names. You can check with:

     ```shell
     /opt/gitlab/embedded/bin/openssl x509 -noout -dates -subject -issuer \
         -nameopt multiline -ext subjectAltName -in /etc/gitlab/ssl/new-gitlab.new-example.com.crt
     ```

1. Reconfigure the **secondary** site for the change to take effect:

   ```shell
   gitlab-ctl reconfigure
   ```

1. Execute the command below to update the newly promoted **primary** site URL:

   ```shell
   gitlab-rake geo:update_primary_node_url
   ```

   This command uses the changed `external_url` configuration defined
   in `/etc/gitlab/gitlab.rb`.

1. Verify you can connect to the newly promoted **primary** using its URL.
   If you updated the DNS records for the primary domain, these changes may
   not have yet propagated depending on the previous DNS records TTL.

### Step 5. (Optional) Add **secondary** Geo site to a promoted **primary** site

Promoting a **secondary** site to **primary** site using the process above does not enable
Geo on the new **primary** site.

To bring a new **secondary** site online, follow the [Geo setup instructions](../setup/_index.md).

### Step 6. Removing the former secondary's tracking database

Every **secondary** has a special tracking database that is used to save the status of the synchronization of all the items from the **primary**.
Because the **secondary** is already promoted, that data in the tracking database is no longer required.

You can remove the data with the following command:

```shell
sudo rm -rf /var/opt/gitlab/geo-postgresql
```

If you have any `geo_secondary[]` configuration options enabled in your `gitlab.rb`
file, comment them out or remove them, and then [reconfigure GitLab](../../restart_gitlab.md#reconfigure-a-linux-package-installation)
for the changes to take effect.

## Promoting secondary Geo replica in multi-secondary configurations

If you have more than one **secondary** site and you need to promote one of them, we suggest you follow
[Promoting a **secondary** Geo site in single-secondary configurations](#promoting-a-secondary-geo-site-in-single-secondary-configurations)
and after that you also need two extra steps.

### Step 1. Prepare the new **primary** site to serve one or more **secondary** sites

1. SSH into the new **primary** site and login as root:

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
   postgresql['md5_auth_cidr_addresses'] = ['<primary_site_ip>/32', '<secondary_site_ip>/32']

   # Every secondary site needs to have its own slot so specify the number of secondary sites you're going to have
   # postgresql['max_replication_slots'] = 1 # Set this to be the number of Geo secondary nodes if you have more than one

   ##
   ## Disable automatic database migrations temporarily
   ## (until PostgreSQL is restarted and listening on the private address).
   ##
   gitlab_rails['auto_migrate'] = false
   ```

   (For more details about these settings you can read [Configure the primary server](../setup/database.md#step-1-configure-the-primary-site))

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

Now we need to make each **secondary** site listen to changes on the new **primary** site. To do that you need
to [initiate the replication process](../setup/database.md#step-3-initiate-the-replication-process) again but this time
for another **primary** site. All the old replication settings are overwritten.

## Promoting a secondary Geo cluster in the GitLab Helm chart

When updating a cloud-native Geo deployment, the process for updating any node that is external to the secondary Kubernetes cluster does not differ from the non cloud-native approach. As such, you can always defer to [Promoting a secondary Geo site in single-secondary configurations](#promoting-a-secondary-geo-site-in-single-secondary-configurations) for more information.

The following sections assume you are using the `gitlab` namespace. If you used a different namespace when setting up your cluster, you should also replace `--namespace gitlab` with your namespace.

### Step 1. Permanently disable the **primary** cluster

WARNING:
If the **primary** site goes offline, there may be data saved on the **primary** site
that has not been replicated to the **secondary** site. This data should be treated
as lost if you proceed.

If an outage on the **primary** site happens, you should do everything possible to
avoid a split-brain situation where writes can occur in two different GitLab
instances, complicating recovery efforts. So to prepare for the failover, you
must disable the **primary** site:

- If you have access to the **primary** Kubernetes cluster, connect to it and disable the GitLab `webservice` and `Sidekiq` pods:

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

### Step 2. Promote all **secondary** site nodes external to the cluster

WARNING:
If the secondary site [has been paused](../../geo/_index.md#pausing-and-resuming-replication), this performs
a point-in-time recovery to the last known state.
Data that was created on the primary while the secondary was paused is lost.

1. For each node (such as PostgreSQL or Gitaly) outside of the **secondary** Kubernetes cluster using the Linux
   package, SSH into the node and run one of the following commands:

   - To promote the **secondary** site node external to the Kubernetes cluster to primary:

     ```shell
     sudo gitlab-ctl geo promote
     ```

   - To promote the **secondary** site node external to the Kubernetes cluster to primary **without any further confirmation**:

     ```shell
     sudo gitlab-ctl geo promote --force
     ```

1. Find the `toolbox` pod:

   ```shell
   kubectl --namespace gitlab get pods -lapp=toolbox
   ```

1. Promote the secondary:

   ```shell
   kubectl --namespace gitlab exec -ti gitlab-geo-toolbox-XXX -- gitlab-rake geo:set_secondary_as_primary
   ```

   Environment variables can be provided to modify the behavior of the task. The
   available variables are:

   | Name | Default value | Description |
   | ---- | ------------- | ------- |
   | `ENABLE_SILENT_MODE` | `false`  | If `true`, enables [Silent Mode](../../silent_mode/_index.md) before promotion (GitLab 16.4 and later) |

### Step 3. Promote the **secondary** cluster

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

   If the cluster remains as a primary site, you can remove the entire `psql` section; it refers to the tracking database and is ignored while the cluster is acting as a primary site.

   Update the cluster with the new configuration:

   ```shell
   helm upgrade --install --version <current Chart version> gitlab-geo gitlab/gitlab --namespace gitlab -f gitlab.yaml
   ```

1. Verify you can connect to the newly promoted primary using the URL used previously for the secondary.

1. Success! The secondary has now been promoted to primary.

## Troubleshooting

This section was moved to [another location](failover_troubleshooting.md#fixing-errors-during-a-failover-or-when-promoting-a-secondary-to-a-primary-site).
