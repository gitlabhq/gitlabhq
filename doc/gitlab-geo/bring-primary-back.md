## Bring a demoted primary back online

After a failover, it is possible to fail back to the demoted primary to restore your original configuration.
This process consists of two steps: making old primary a secondary and promoting secondary to a primary.

### Configure the former primary to be a secondary

Since the former primary will be out of sync with the current primary, the first
step is to bring the former primary up to date. There is one downside though, some uploads and repositories
that have been deleted during an idle period of a primary node, will not be deleted from the disk but the overall sync will be much faster. As an alternative, you can set up a [GitLab instance from scratch](https://docs.gitlab.com/ee/gitlab-geo/#setup-instructions) to workaround this downside.

1. SSH into the former primary that has fallen behind.
1. Make sure all the services are up by running the command

    ```bash
    sudo gitlab-ctl start
    ```

Note: If you [disabled primary permanently](https://docs.gitlab.com/ee/gitlab-geo/disaster-recovery.html#step-2-permanently-disable-the-primary), you need to undo those steps now. For Debian/Ubuntu you just need to run `sudo systemctl enable gitlab-runsvdir`. For CentoOS 6, you need to install GitLab instance from scratch and setup it as a secondary node by following [Setup instructions](https://docs.gitlab.com/ee/gitlab-geo/#setup-instructions). In this case you don't need the step below.
1. [Setup the database replication](database.md). In this documentation, primary
   refers to the current primary, and secondary refers to the former primary.

If you have lost your original primary, follow the
[setup instructions](README.md#setup-instructions) to set up a new secondary.

### Promote the secondary to primary

When initial replication is complete and the primary and secondary are closely in sync you can do a [Planned Failover](planned-failover.md)

### Restore the secondary node

If your objective is to have two nodes again, you need to bring your secondary node back online as well by repeating the first step ([Make primary a secondary](#make-primary-a-secondary)) for the secondary node.
