# GitLab Geo Disaster Recovery

> **Note:**
GitLab Geo Disaster Recovery is in **Alpha** development. Please don't
use as your only Disaster Recovery strategy as you may lose data.

GitLab Geo replicates your database and your Git repositories. We will
support and replicate more data in the future, that will enable you to
fail-over with minimal effort, in a disaster situation.

See [current limitations](README.md#current-limitations)
for more information.


## Promoting a secondary node

We don't provide yet an automated way to promote a node and do fail-over,
but you can do it manually if you have `root` access to the machine.

You must make the changes in the exact specific order:

1. Take down your primary node (or make sure it will not go up during this
   process or you may lose data)
1. Wait for any database replication to finish
1. Promote the Postgres in your secondary node as primary
1. Modify the `gitlab.rb` for both nodes to reflect their new statuses
1. Log-in to your secondary node with a user with `sudo` permission
1. **Remove** the Geo SSH client keys (this is very important!):

    ```bash
    sudo rm ~git/.ssh/id_rsa ~git/.ssh/id_rsa.pub
    ```
1. Run `sudo gitlab-rake geo:set_secondary_as_primary`
1. Rsync everything in `/var/opt/gitlab/gitlab-rails/uploads` and
   `/var/opt/gitlab/gitlab-rails/shared` from your old node to the new one.

To bring your old primary node back into use as a working secondary, you need to
run `gitlab-ctl reconfigure` against the node and then follow the
[setup instructions](README.md) again, as if for a secondary node, from step 3.
