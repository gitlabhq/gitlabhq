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

For system with only one secondary and one primary node (2-node system):

1. Take down your primary node (or make sure it will not go up during this
   process or you may lose data)
1. Log-in to your secondary node with a user with `sudo` permission
1. Modify the `gitlab.rb` to reflect its new status
1. Run `sudo gitlab-ctl promote-to-primary-node`

To bring your old primary node back into use as a working secondary, you need to
run `gitlab-ctl reconfigure` against the node and then follow the
[setup instructions](README.md) again, as if for a secondary node, from step 3.
