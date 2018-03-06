# Bring a demoted primary node back online

After a failover, it is possible to fail back to the demoted primary to
restore your original configuration. This process consists of two steps:

1. Making the old primary a secondary
1. Promoting a secondary to a primary

> *Warning:* If you have any doubts about the consistency of the data on this node, we recommend to set up it from scratch.

## Configure the former primary to be a secondary

Since the former primary will be out of sync with the current primary, the first step is
to bring the former primary up to date. Note, deletion of data stored on disk like
repositories and uploads will not be replayed when bringing the former primary in back
into sync, which may result in increased disk usage.
Alternatively, you can [setup a new secondary GitLab instance][setup-geo] to avoid this.

To bring the former primary up to date:

1. SSH into the former primary that has fallen behind
1. Make sure all the services are up:

    ```bash
    sudo gitlab-ctl start
    ```

    >**Note 1:** If you [disabled primary permanently][disaster-recovery-disable-primary],
    you need to undo those steps now. For Debian/Ubuntu you just need to run
    `sudo systemctl enable gitlab-runsvdir`. For CentOS 6, you need to install
    the GitLab instance from scratch and setup it as a secondary node by
    following [Setup instructions][setup-geo].  In this case you don't need to follow the next step.

    >**Note 2:** If you [changed the DNS records](index.md#step-4-optional-updating-the-primary-domains-dns-record)
    for this node during disaster recovery procedure you may need to [block
    all the writes to this node](https://gitlab.com/gitlab-org/gitlab-ee/blob/master/doc/gitlab-geo/planned-failover.md#block-primary-traffic)
    during this procedure.

1. [Setup database replication][database-replication]. Note that in this
   case, primary refers to the current primary, and secondary refers to the
   former primary.

If you have lost your original primary, follow the
[setup instructions][setup-geo] to set up a new secondary.

## Promote the secondary to primary

When the initial replication is complete and the primary and secondary are
closely in sync, you can do a [planned failover].

## Restore the secondary node

If your objective is to have two nodes again, you need to bring your secondary
node back online as well by repeating the first step
([configure the former primary to be a secondary](#configure-the-former-primary-to-be-a-secondary))
for the secondary node.

[setup-geo]: ../replication/index.md#setup-instructions
[database-replication]: ../replication/database.md
[disaster-recovery-disable-primary]: index.md#step-2-permanently-disable-the-primary
[planned failover]: planned_failover.md
