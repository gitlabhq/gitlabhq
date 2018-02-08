# GitLab Geo Disaster Recovery

> **Note:** Disaster Recovery is in **Alpha** development. Do not use this as
> your only Disaster Recovery strategy as you may lose data.

GitLab Geo replicates your database and your Git repositories. We will
support and replicate more data in the future, that will enable you to
fail-over with minimal effort, in a disaster situation.

See [current limitations](README.md#current-limitations) for more information.

## Promoting secondary Geo replica in single-secondary configuration

We don't currently provide an automated way to promote a Geo replica and do a
fail-over, but you can do it manually if you have `root` access to the machine.

This process promotes a secondary Geo replica to a primary. To regain
geographical redundancy as quickly as possible, you should add a new secondary
immediately after following these instructions.

### Step 1. Allow replication to finish if possible

If the secondary is still replicating data from the primary, follow
[the Planned Failover doc](planned-failover.md) as closely as possible in
order to avoid unnecessary data loss.

### Step 2. Permanently disable the primary

**Warning: If a primary goes offline, there may be data saved on the primary
  that has not been replicated to the secondary. This data should be treated
  as lost if you proceed.**

If an outage on your primary happens, you should do everything possible to
avoid a split-brain situation where writes can occur to two different GitLab
instances, complicating recovery efforts. So to prepare for the failover, we
must disable the primary.

1. SSH into your **primary** to stop and disable GitLab, if possible.

    ```bash
    sudo gitlab-ctl stop
    ```

    Prevent GitLab from starting up again if the server unexpectedly reboots:

    ```bash
    sudo systemctl disable gitlab-runsvdir
    ```

    On some operating systems such as CentOS 6, an easy way to prevent GitLab
    from being started if the machine reboots isn't available
    (see [Omnibus issue #3058](https://gitlab.com/gitlab-org/omnibus-gitlab/issues/3058)).
    It may be safest to uninstall the GitLab package completely:

    ```bash
    yum remove gitlab-ee
    ```

1. If you do not have SSH access to your primary, take the machine offline and
    prevent it from rebooting by any means at your disposal.

    Since there are many ways you may prefer to accomplish this, we will avoid a
    single recommendation. You may need to:

    * Reconfigure load balancers
    * Change DNS records (e.g. point the primary DNS record to the secondary node in order to stop usage of the primary)
    * Stop virtual servers
    * Block traffic through a firewall
    * Revoke object storage permissions from the primary
    * Physically disconnect a machine

### Step 3. Promoting a secondary Geo replica

1. SSH in to your **secondary** and login as root:

    ```bash
    sudo -i
    ```

1. Edit `/etc/gitlab/gitlab.rb` to reflect its new status as primary.

    Remove the following line:

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

### Step 4. (Optional) Updating the primary domain's DNS record

Updating the DNS records for the primary domain to point to the secondary
will prevent the need to update all references to the primary domain to the
secondary domain, like changing Git remotes and API URLs.

1. SSH in to your **secondary** and login as root:

    ```bash
    sudo -i
    ```

1. Update the primary domain's DNS record.

    After updating the primary domain's DNS records to point to the secondary,
    edit `/etc/gitlab/gitlab.rb` on the the secondary to reflect the new URL:

    ```ruby
    # Change the existing external_url configuration
    external_url 'https://gitlab.example.com'
    ```

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
GitLab Geo on the new primary.

To bring a new secondary online, follow the [GitLab Geo setup instructions](
README.md#setup-instructions).

## Promoting secondary Geo replica in multi-secondary configurations

Disaster Recovery does not yet support systems with multiple
secondary Geo replicas (e.g. one primary and two or more secondaries). We are
working on it, see [#4284](https://gitlab.com/gitlab-org/gitlab-ee/issues/4284)
for details.
