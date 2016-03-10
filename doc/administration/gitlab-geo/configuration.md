# GitLab Geo configuration

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Repositories data replication](#repositories-data-replication)
- [Primary Node setup](#primary-node-setup)
- [Secondary Node](#secondary-node)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Repositories data replication

Getting a new secondary Geo node up and running, will also require the
repositories directory to be rsynced from the primary node.

If this step is not followed, the secondary node will eventually clone and
fetch every missing repository as they are updated on the primary node.

The final step will be to regenerate the keys for `.ssh/authorized_keys` using
the following commands (https clone will work without this extra step):

```
# For source installations
sudo -u git -H bundle exec rake gitlab:shell:setup

# For Omnibus installations
gitlab-rake gitlab:shell:setup
```

## Primary Node setup

To turn your GitLab instance into a primary Geo node, go to
**Admin Area > Geo Nodes** (`/admin/geo_nodes`).

In **Geo Nodes** screen, fill in the required fields and make sure you
check `This is a primary node` before hitting Add Node.

Fill **URL** field with your instance full URL, in the same way it is
configure in your `gitlab.yml` (source based install) or
`/etc/gitlab/gitlab.rb` (omnibus install).

The **Public Key** field must contain the SSH public key of the user that
your GitLab instance runs on (unless changed, should be the user `git`).

![Geo Nodes Screen](img/geo-nodes-screen.png)

---

Repeat the same instructions to add your secondaries instances remembering not
to check `This is a primary node`, and to use the correct Public Key.

You will need to setup your database into a **Master <-> Slave** replication
topology, and your Primary node should always point to a database's
Master instance.

## Secondary Node

To install a secondary node, you must follow your a normal GitLab install
instructions with some extra requirements:

- You should point your database connection to a Slave replicated instance.
- Your secondary node should be allowed to communicate by HTTP/HTTPS and
  SSH with your primary node (make sure your firewall is not blocking that).
