# Disaster Recovery

> **Note:** Disaster Recovery is in **Alpha** development. Do not use this as
> your only Disaster Recovery strategy as you may lose data.

GitLab Geo replicates your database and your Git repositories. We will
support and replicate more data in the future, that will enable you to
fail-over with minimal effort, in a disaster situation.

See [current limitations](README.md#current-limitations) for more information.

## Promoting a secondary node

> **Warning:** Disaster Recovery does not yet support systems with multiple
> secondary nodes (3-node systems or greater).

We don't provide yet an automated way to promote a node and do fail-over,
but you can do it manually if you have `root` access to the machine.

1. Take down your **primary** node.

    If you have SSH access to the primary node, SSH into your **primary**
    node, and stop GitLab.

    ```
    sudo gitlab-ctl stop
    ```

    Make sure the primary node will not come up while promoting the secondary
    node to primary else you may lose data.

1. SSH in to your **secondary** node and login as root:

    ```
    sudo -i
    ```

1. Edit `/etc/gitlab/gitlab.rb` to reflect its new status as primary node.

    Remove the following line:

    ```
    ## DELETE THIS LINE, or update the value to false
    geo_secondary_role['enable'] = true
    ```

    Add the following lines, replacing the IP addresses with addresses
    appropriate to your network configuration:

    ```
    geo_primary_role['enable'] = true

    ##
    ## Primary address
    ## - replace '1.2.3.4' with the primary private address
    ##
    postgresql['listen_address'] = '1.2.3.4'
    postgresql['trust_auth_cidr_addresses'] = ['127.0.0.1/32','1.2.3.4/32']

    ##
    ## Disable automatic database migrations temporarily
    ## (until PostgreSQL is restarted and listening on the private address).
    ##
    gitlab_rails['auto_migrate'] = false
    ```

    A new secondary is not added at this time. You should add a new secondary
    after you have completed the entire process of promoting the secondary to
    the primary node.

    Refer to [Geo Replication database documention](
    database.html#step-1-configure-the-primary-server) for more details.

1. Promote the secondary geo node to primary node. Execute:

    ```
    sudo gitlab-ctl promote-to-primary-node
    ```

1. Verify you can connect to the newly promoted primary using the URL used
   previously for the secondary.
1. Update the DNS records for the primary to reflect the public address of the
   newly promoted primary.
1. After the DNS changes have propagated, edit `/etc/gitlab/gitlab.rb` to
   reflect it's new URL:

    ```
    # Change the existing external_url configuration
    external_url 'https://gitlab.example.com'
    ```

    Reconfigure GitLab to apply the change:

    ```
    gitlab-ctl reconfigure
    ```

1. Success! The secondary node has now been promoted to primary node and is
   accessible from the URL of the previous primary.

To bring your old primary node back into use as a working secondary, you need to
run `gitlab-ctl reconfigure` against the node and then follow the
[setup instructions](README.md) again, as if for a secondary node, from step 3.
