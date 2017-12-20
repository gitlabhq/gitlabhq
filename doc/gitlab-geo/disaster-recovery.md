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

    SSH into your primary node and stop GitLab.

    ```
    sudo gitlab-ctl stop
    ```

    If you do not have SSH access to your primary node take the machine
    offline. Depending on the nature of your primary node this may mean
    physically disconnecting the machine, stopping a virtual server,
    reconfiguring load balancers, or changing DNS records (see next step).

    Preventing the original primary from coming online during this process is
    necessary to ensure data isn't added to the original primary that will not
    be replicated to the newly promoted primary.

1. SSH in to your **secondary** node and login as root:

    ```
    sudo -i
    ```

1. Optional. Update the DNS records and the `external_url`.
    
    Updating the DNS records for the primary domain to point to the secondary
    node will prevent the need to update all references to the primary domain
    to the secondary domain, like changing Git remotes and API URLs.

    After updating the DNS records, edit `/etc/gitlab/gitlab.rb` to reflect the
    new URL:

    ```
    # Change the existing external_url configuration
    external_url 'https://gitlab.example.com'
    ```

1. Edit `/etc/gitlab/gitlab.rb` to reflect its new status as primary node.

    Remove the following line:

    ```
    ## REMOVE THIS LINE
    geo_secondary_role['enable'] = true
    ```

    Add the following line:

    ```
    ## ADD THIS LINE
    geo_primary_role['enable'] = true
    ```

    A new secondary should not be added at this time. If you want to add a new
    secondary, do this after you have completed the entire process of promoting
    the secondary node to the primary node.

1. Promote the secondary geo node to primary node. Execute:

    ```
    gitlab-ctl promote-to-primary-node
    ```

1. Verify you can connect to the newly promoted primary using the URL used
   previously for the secondary.
1. Success! The secondary node has now been promoted to primary node.

    If you updated the DNS records for the primary domain, these changes may
    not have yet propogated depending on the previous DNS records TTL.

To bring your old primary node back into use as a working secondary, you need to
run `gitlab-ctl reconfigure` against the node and then follow the
[setup instructions](README.md) again, as if for a secondary node, from step 3.
