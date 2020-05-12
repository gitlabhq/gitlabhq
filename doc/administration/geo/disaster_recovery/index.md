# Disaster Recovery (Geo) **(PREMIUM ONLY)**

Geo replicates your database, your Git repositories, and few other assets.
We will support and replicate more data in the future, that will enable you to
failover with minimal effort, in a disaster situation.

See [Geo current limitations](../replication/index.md#current-limitations) for more information.

CAUTION: **Warning:**
Disaster recovery for multi-secondary configurations is in **Alpha**.
For the latest updates, check the multi-secondary [Disaster Recovery epic](https://gitlab.com/groups/gitlab-org/-/epics/65).

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

CAUTION: **Warning:**
If the **primary** node goes offline, there may be data saved on the **primary** node
that has not been replicated to the **secondary** node. This data should be treated
as lost if you proceed.

If an outage on the **primary** node happens, you should do everything possible to
avoid a split-brain situation where writes can occur in two different GitLab
instances, complicating recovery efforts. So to prepare for the failover, we
must disable the **primary** node.

1. SSH into the **primary** node to stop and disable GitLab, if possible:

   ```shell
   sudo gitlab-ctl stop
   ```

   Prevent GitLab from starting up again if the server unexpectedly reboots:

   ```shell
   sudo systemctl disable gitlab-runsvdir
   ```

   NOTE: **Note:**
   (**CentOS only**) In CentOS 6 or older, there is no easy way to prevent GitLab from being
   started if the machine reboots isn't available (see [Omnibus GitLab issue #3058](https://gitlab.com/gitlab-org/omnibus-gitlab/issues/3058)).
   It may be safest to uninstall the GitLab package completely:

   ```shell
   yum remove gitlab-ee
   ```

   NOTE: **Note:**
   (**Ubuntu 14.04 LTS**) If you are using an older version of Ubuntu
   or any other distro based on the Upstart init system, you can prevent GitLab
   from starting if the machine reboots by doing the following:

   ```shell
   initctl stop gitlab-runsvvdir
   echo 'manual' > /etc/init/gitlab-runsvdir.override
   initctl reload-configuration
   ```

1. If you do not have SSH access to the **primary** node, take the machine offline and
   prevent it from rebooting by any means at your disposal.
   Since there are many ways you may prefer to accomplish this, we will avoid a
   single recommendation. You may need to:

   - Reconfigure the load balancers.
   - Change DNS records (for example, point the primary DNS record to the **secondary**
     node in order to stop usage of the **primary** node).
   - Stop the virtual servers.
   - Block traffic through a firewall.
   - Revoke object storage permissions from the **primary** node.
   - Physically disconnect a machine.

1. If you plan to [update the primary domain DNS record](#step-4-optional-updating-the-primary-domain-dns-record),
   you may wish to lower the TTL now to speed up propagation.

### Step 3. Promoting a **secondary** node

Note the following when promoting a secondary:

- A new **secondary** should not be added at this time. If you want to add a new
  **secondary**, do this after you have completed the entire process of promoting
  the **secondary** to the **primary**.
- If you encounter an `ActiveRecord::RecordInvalid: Validation failed: Name has already been taken`
  error during this process, please read
  [the troubleshooting advice](../replication/troubleshooting.md#fixing-errors-during-a-failover-or-when-promoting-a-secondary-to-a-primary-node).

#### Promoting a **secondary** node running on a single machine

1. SSH in to your **secondary** node and login as root:

   ```shell
   sudo -i
   ```

1. Edit `/etc/gitlab/gitlab.rb` to reflect its new status as **primary** by
   removing any lines that enabled the `geo_secondary_role`:

   ```ruby
   ## In pre-11.5 documentation, the role was enabled as follows. Remove this line.
   geo_secondary_role['enable'] = true

   ## In 11.5+ documentation, the role was enabled as follows. Remove this line.
   roles ['geo_secondary_role']
   ```

1. Promote the **secondary** node to the **primary** node. Execute:

   ```shell
   gitlab-ctl promote-to-primary-node
   ```

1. Verify you can connect to the newly promoted **primary** node using the URL used
   previously for the **secondary** node.
1. If successful, the **secondary** node has now been promoted to the **primary** node.

#### Promoting a **secondary** node with HA

The `gitlab-ctl promote-to-primary-node` command cannot be used yet in
conjunction with High Availability or with multiple machines, as it can only
perform changes on a **secondary** with only a single machine. Instead, you must
do this manually.

1. SSH in to the database node in the **secondary** and trigger PostgreSQL to
   promote to read-write:

   ```shell
   sudo gitlab-pg-ctl promote
   ```

   In GitLab 12.8 and earlier, see [Message: `sudo: gitlab-pg-ctl: command not found`](../replication/troubleshooting.md#message-sudo-gitlab-pg-ctl-command-not-found).

1. Edit `/etc/gitlab/gitlab.rb` on every machine in the **secondary** to
   reflect its new status as **primary** by removing any lines that enabled the
   `geo_secondary_role`:

   ```ruby
   ## In pre-11.5 documentation, the role was enabled as follows. Remove this line.
   geo_secondary_role['enable'] = true

   ## In 11.5+ documentation, the role was enabled as follows. Remove this line.
   roles ['geo_secondary_role']
   ```

   After making these changes [Reconfigure GitLab](../../restart_gitlab.md#omnibus-gitlab-reconfigure) each
   machine so the changes take effect.

1. Promote the **secondary** to **primary**. SSH into a single application
   server and execute:

   ```shell
   sudo gitlab-rake geo:set_secondary_as_primary
   ```

1. Verify you can connect to the newly promoted **primary** using the URL used
   previously for the **secondary**.
1. Success! The **secondary** has now been promoted to **primary**.

#### Promoting a **secondary** node with an external PostgreSQL database

The `gitlab-ctl promote-to-primary-node` command cannot be used in conjunction with
an external PostgreSQL database, as it can only perform changes on a **secondary**
node with GitLab and the database on the same machine. As a result, a manual process is
required. For example, PostgreSQL databases hosted on Amazon RDS:

1. Promote the replica database associated with the **secondary** site. This will
   set the database to read-write:
   - Amazon RDS - [Promoting a Read Replica to Be a Standalone DB Instance](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_ReadRepl.html#USER_ReadRepl.Promote)

1. Edit `/etc/gitlab/gitlab.rb` on every node in the **secondary** site to
   reflect its new status as **primary** by removing any lines that enabled the
   `geo_secondary_role`:

   ```ruby
   ## In GitLab 11.4 and earlier, remove this line.
   geo_secondary_role['enable'] = true

   ## In GitLab 11.5 and later, remove this line.
   roles ['geo_secondary_role']
   ```

   After making these changes [Reconfigure GitLab](../../restart_gitlab.md#omnibus-gitlab-reconfigure)
   on each node so the changes take effect.

1. Promote the **secondary** to **primary**. SSH into a single secondary application
   node and execute:

   ```shell
   sudo gitlab-rake geo:set_secondary_as_primary
   ```

1. Verify you can connect to the newly promoted **primary** site using the URL used
   previously for the **secondary** site.

Success! The **secondary** site has now been promoted to **primary**.

### Step 4. (Optional) Updating the primary domain DNS record

Updating the DNS records for the primary domain to point to the **secondary** node
will prevent the need to update all references to the primary domain to the
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

   NOTE: **Note**
   Changing `external_url` won't prevent access via the old secondary URL, as
   long as the secondary DNS records are still intact.

1. Reconfigure the **secondary** node for the change to take effect:

   ```shell
   gitlab-ctl reconfigure
   ```

1. Execute the command below to update the newly promoted **primary** node URL:

   ```shell
   gitlab-rake geo:update_primary_node_url
   ```

   This command will use the changed `external_url` configuration defined
   in `/etc/gitlab/gitlab.rb`.

1. For GitLab 11.11 through 12.7 only, you may need to update the **primary**
   node's name in the database. This bug has been fixed in GitLab 12.8.

   To determine if you need to do this, search for the
   `gitlab_rails["geo_node_name"]` setting in your `/etc/gitlab/gitlab.rb`
   file. If it is commented out with `#` or not found at all, then you will
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

To bring a new **secondary** node online, follow the [Geo setup instructions](../replication/index.md#setup-instructions).

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

1. Edit `/etc/gitlab/gitlab.rb`

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

   (For more details about these settings you can read [Configure the primary server](../replication/database.md#step-1-configure-the-primary-server))

1. Save the file and reconfigure GitLab for the database listen changes and
   the replication slot changes to be applied.

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
to [initiate the replication process](../replication/database.md#step-3-initiate-the-replication-process) again but this time
for another **primary** node. All the old replication settings will be overwritten.

## Troubleshooting

### I followed the disaster recovery instructions and now two-factor auth is broken

The setup instructions for Geo prior to 10.5 failed to replicate the
`otp_key_base` secret, which is used to encrypt the two-factor authentication
secrets stored in the database. If it differs between **primary** and **secondary**
nodes, users with two-factor authentication enabled won't be able to log in
after a failover.

If you still have access to the old **primary** node, you can follow the
instructions in the
[Upgrading to GitLab 10.5](../replication/version_specific_updates.md#updating-to-gitlab-105)
section to resolve the error. Otherwise, the secret is lost and you'll need to
[reset two-factor authentication for all users](../../../security/two_factor_authentication.md#disabling-2fa-for-everyone).
