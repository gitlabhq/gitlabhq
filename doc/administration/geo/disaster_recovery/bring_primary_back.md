# Bring a demoted primary node back online

After a failover, it is possible to fail back to the demoted primary to
restore your original configuration. This process consists of two steps:

1. Making the old primary a secondary
1. Promoting a secondary to a primary

## Configure the former primary to be a secondary

Since the former primary will be out of sync with the current primary, the first
step is to bring the former primary up to date. There is one downside though,
some uploads and repositories that have been deleted during an idle period of a
primary node, will not be deleted from the disk but the overall sync will be
much faster. As an alternative, you can set up a
[GitLab instance from scratch](../replication/index.md#setup-instructions) to
workaround this downside.

To bring the former primary up to date:

1. SSH into the former primary that has fallen behind
1. Make sure all the services are up:

    ```bash
    sudo gitlab-ctl start
    ```

    NOTE: **Note:** If you [disabled the primary permanently](index.md#step-2-permanently-disable-the-primary),
    you need to undo those steps now. For Debian/Ubuntu you just need to run
    `sudo systemctl enable gitlab-runsvdir`. For CentOS 6, you need to install
    the GitLab instance from scratch and setup it as a secondary node by
    following the [setup instructions](../replication/index.md#setup-instructions).
    In this case you don't need to follow the next step.

1. [Setup database replication](../replication/database.md). Note that in this
   case, primary refers to the current primary, and secondary refers to the
   former primary.

If you have lost your original primary, follow the
[setup instructions](../replication/index.md#setup-instructions) to set up a new secondary.

## Promote the secondary to primary

When the initial replication is complete and the primary and secondary are
closely in sync, you can do a [planned failover](planned_failover.md).

## Restore the secondary node

If your objective is to have two nodes again, you need to bring your secondary
node back online as well by repeating the first step
([configure the former primary to be a secondary](#configure-the-former-primary-to-be-a-secondary))
for the secondary node.
