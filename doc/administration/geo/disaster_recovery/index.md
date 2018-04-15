# Disaster Recovery

Geo replicates your database, your Git repositories, and few other assets.
We will support and replicate more data in the future, that will enable you to
failover with minimal effort, in a disaster situation.

See [Geo current limitations][geo-limitations] for more information.

CAUTION: **Warning:**
Disaster recovery for multi-secondary configurations is in **Alpha**.
For the latest updates, check the multi-secondary [Disaster Recovery epic][gitlab-org&65].

## Promoting secondary Geo replica in single-secondary configurations

We don't currently provide an automated way to promote a Geo replica and do a
failover, but you can do it manually if you have `root` access to the machine.

This process promotes a secondary Geo replica to a primary. To regain
geographical redundancy as quickly as possible, you should add a new secondary
immediately after following these instructions.

### Step 1. Allow replication to finish if possible

If the secondary is still replicating data from the primary, follow
[the planned failover docs][planned-failover] as closely as possible in
order to avoid unnecessary data loss.

### Step 2. Permanently disable the primary

CAUTION: **Warning:**
If a primary goes offline, there may be data saved on the primary
that has not been replicated to the secondary. This data should be treated
as lost if you proceed.

If an outage on your primary happens, you should do everything possible to
avoid a split-brain situation where writes can occur in two different GitLab
instances, complicating recovery efforts. So to prepare for the failover, we
must disable the primary.

1. SSH into your **primary** to stop and disable GitLab, if possible:

    ```bash
    sudo gitlab-ctl stop
    ```

    Prevent GitLab from starting up again if the server unexpectedly reboots:

    ```bash
    sudo systemctl disable gitlab-runsvdir
    ```

    > **CentOS only**: In CentOS 6 or older, there is no easy way to prevent GitLab from being
    started if the machine reboots isn't available (see [gitlab-org/omnibus-gitlab#3058]).
    It may be safest to uninstall the GitLab package completely:

    ```bash
    yum remove gitlab-ee
    ```

    > **Ubuntu 14.04 LTS**: If you are using an older version of Ubuntu
    or any other distro based on the Upstart init system, you can prevent GitLab
    from starting if the machine reboots by doing the following:

    ```bash
    initctl stop gitlab-runsvvdir
    echo 'manual' > /etc/init/gitlab-runsvdir.override
    initctl reload-configuration
    ```

1. If you do not have SSH access to your primary, take the machine offline and
    prevent it from rebooting by any means at your disposal.
    Since there are many ways you may prefer to accomplish this, we will avoid a
    single recommendation. You may need to:
      - Reconfigure the load balancers
      - Change DNS records (e.g., point the primary DNS record to the secondary
        node in order to stop usage of the primary)
      - Stop the virtual servers
      - Block traffic through a firewall
      - Revoke object storage permissions from the primary
      - Physically disconnect a machine

1. If you plan to
   [update the primary domain DNS record](#step-4-optional-updating-the-primary-domain-dns-record),
   you may wish to lower the TTL now to speed up propagation.

### Step 3. Promoting a secondary Geo replica

1. SSH in to your **secondary** and login as root:

    ```bash
    sudo -i
    ```

1. Edit `/etc/gitlab/gitlab.rb` to reflect its new status as primary by
   removing the following line:

    ```ruby
    ## REMOVE THIS LINE
    geo_secondary_role['enable'] = true
    ```

    A new secondary should not be added at this time. If you want to add a new
    secondary, do this after you have completed the entire process of promoting
    the secondary to the primary.

1. Promote the secondary to primary. Execute:

    ```bash
    gitlab-ctl promote-to-primary-node
    ```

1. Verify you can connect to the newly promoted primary using the URL used
   previously for the secondary.
1. Success! The secondary has now been promoted to primary.

#### Promoting a node with HA

The `gitlab-ctl promote-to-primary-node` command cannot be used yet in conjunction with
High Availability or with multiple machines, as it can only perform changes on
a single one.

The command above does the following changes:

- Promotes the PostgreSQL secondary to primary
- Executes `gitlab-ctl reconfigure` to apply the changes in `/etc/gitlab/gitlab.rb`
- Runs `gitlab-rake geo:set_secondary_as_primary`

You need to make sure all the affected machines no longer have `geo_secondary_role['enable'] = true` in
`/etc/gitlab/gitlab.rb`, that you execute the database promotion on the required database nodes
and you execute the `gitlab-rake geo:set_secondary_as_primary` in a machine running the application server.

### Step 4. (Optional) Updating the primary domain DNS record

Updating the DNS records for the primary domain to point to the secondary
will prevent the need to update all references to the primary domain to the
secondary domain, like changing Git remotes and API URLs.

1. SSH into your **secondary** and login as root:

    ```bash
    sudo -i
    ```

1. Update the primary domain's DNS record. After updating the primary domain's
   DNS records to point to the secondary, edit `/etc/gitlab/gitlab.rb` on the
   secondary to reflect the new URL:

    ```ruby
    # Change the existing external_url configuration
    external_url 'https://gitlab.example.com'
    ```

    NOTE: **Note**
    Changing `external_url` won't prevent access via the old secondary URL, as
    long as the secondary DNS records are still intact.

1. Reconfigure the secondary node for the change to take effect:

    ```bash
    gitlab-ctl reconfigure
    ```

1. Execute the command below to update the newly promoted primary node URL:

    ```bash
    gitlab-rake geo:update_primary_node_url
    ```

    This command will use the changed `external_url` configuration defined
    in `/etc/gitlab/gitlab.rb`.

1. Verify you can connect to the newly promoted primary using the primary URL.
   If you updated the DNS records for the primary domain, these changes may
   not have yet propagated depending on the previous DNS records TTL.

### Step 5. (Optional) Add secondary Geo replicas to a promoted primary

Promoting a secondary to primary using the process above does not enable
Geo on the new primary.

To bring a new secondary online, follow the [Geo setup instructions][setup-geo].

## Promoting secondary Geo replica in multi-secondary configurations

If you have more than one secondary and you need to promote one of them we suggest you to follow
[Promoting secondary Geo replica in single-secondary configurations](#promoting-secondary-geo-replica-in-single-secondary-configurations)
and after that you also need two extra steps.

### Step 1. Prepare the new primary to serve one or more secondaries

1. SSH into your **secondary** and login as root:

    ```bash
    sudo -i
    ```

1. Edit `/etc/gitlab/gitlab.rb`

    ```ruby
    ##
    # Primary and Secondary addresses
    # - replace '1.2.3.4' with the primary public or VPC address
    # - replace '5.6.7.8' with the secondary public or VPC address
    ##
    postgresql['md5_auth_cidr_addresses'] = ['1.2.3.4/32', '5.6.7.8/32']

    # Every secondary server needs to have its own slot so specify the number of secondary nodes you're going to have
    postgresql['max_replication_slots'] = 1

    ##
    ## Disable automatic database migrations temporarily
    ## (until PostgreSQL is restarted and listening on the private address).
    ##
    gitlab_rails['auto_migrate'] = false

    ```

    For more details about these settings you can read [Configure the primary server][configure-the-primary-server]

1. Save the file and reconfigure GitLab for the database listen changes and
   the replication slot changes to be applied.

    ```bash
    gitlab-ctl reconfigure
    ```

    Restart PostgreSQL for its changes to take effect:

    ```bash
    gitlab-ctl restart postgresql
    ```

1. Re-enable migrations now that PostgreSQL is restarted and listening on the
   private address.

    Edit `/etc/gitlab/gitlab.rb` and **change** the configuration to `true`:

    ```ruby
    gitlab_rails['auto_migrate'] = true
    ```

    Save the file and reconfigure GitLab:

    ```bash
    gitlab-ctl reconfigure
    ```

### Step 2. Initiate the replication process

Now we need to make each secondary listen to changes on the new primary. To do that you need
to [initiate the replication process][initiate-the-replication-process] again but this time
for another primary. All the old replication settings will be overwritten.


## Troubleshooting

### I followed the disaster recovery instructions and now two-factor auth is broken!

The setup instructions for Geo prior to 10.5 failed to replicate the
`otp_key_base` secret, which is used to encrypt the two-factor authentication
secrets stored in the database. If it differs between primary and secondary
nodes, users with two-factor authentication enabled won't be able to log in
after a failover.

If you still have access to the old primary node, you can follow the
instructions in the
[Upgrading to GitLab 10.5][updating-geo]
section to resolve the error. Otherwise, the secret is lost and you'll need to
[reset two-factor authentication for all users][sec-tfa].

[gitlab-org&65]: https://gitlab.com/groups/gitlab-org/-/epics/65
[geo-limitations]: ../replication/index.md#current-limitations
[planned-failover]: planned_failover.md
[setup-geo]: ../replication/index.md#setup-instructions
[updating-geo]: ../replication/updating_the_geo_nodes.md#upgrading-to-gitlab-105
[sec-tfa]: ../../../security/two_factor_authentication.md#disabling-2fa-for-everyone
[gitlab-org/omnibus-gitlab#3058]: https://gitlab.com/gitlab-org/omnibus-gitlab/issues/3058
[gitlab-org/gitlab-ee#4284]: https://gitlab.com/gitlab-org/gitlab-ee/issues/4284
[initiate-the-replication-process]: ../replication/database.html#step-3-initiate-the-replication-process
[configure-the-primary-server]: ../replication/database.html#step-1-configure-the-primary-server
