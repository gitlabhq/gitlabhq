# GitLab Geo configuration

By now, you should have an [idea of GitLab Geo](README.md) and already set up
the [database replication](./database.md). There are a few more steps needed to
complete the process.

---

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Repositories data replication](#repositories-data-replication)
- [Create SSH key pairs for Geo nodes](#create-ssh-key-pairs-for-geo-nodes)
- [Primary Node GitLab setup](#primary-node-gitlab-setup)
- [Secondary Node GitLab setup](#secondary-node-gitlab-setup)
  - [Database Encryptation Key](#database-encryptation-key)
  - [Authorized keys regeneration](#authorized-keys-regeneration)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Repositories data replication

Getting a new secondary Geo node up and running, will also require the
repositories directory to be synced from the primary node. You can use `rsync`
for that. From the secondary node run:

```bash
# For Omnibus installations
rsync -avrP root@1.2.3.4:/var/opt/gitlab/git-data/repositories/ /var/opt/gitlab/git-data/repositories/
gitlab-ctl reconfigure # to fix directory permissions

# For installations from source
rsync -avrP root@1.2.3.4:/home/git/repositories/ /home/git/repositories/
chown -R git:git /home/git/repositories
chmod ug+rwX,o-rwx /home/git/repositories
```

where `1.2.3.4` is the IP of the primary node.

If this step is not followed, the secondary node will eventually clone and
fetch every missing repository as they are updated with new commits on the
primary node, so syncing the repositories beforehand will buy you some time.

## Create SSH key pairs for Geo nodes

When adding a Geo node you must provide an SSH public key of the user that your
GitLab instance runs on (unless changed, should be the user `git`). This user
will act as a "normal user" who fetches from the primary Geo node.

Run the command below on each server that will be a Geo node (primary or
secondary), and paste the contents of `id_rsa.pub` to the admin area of the
primary node (**Admin Area > Geo Nodes**) when adding a new one:

```bash
sudo -u git -H ssh-keygen
```

The public key for Omnibus installations will be at `/var/opt/gitlab/.ssh/id_rsa.pub`,
whereas for installation from source it will be at `/home/git/.ssh/id_rsa.pub`.

If for any reason you generate the key using a different name from the default
`id_rsa`, or you want to generate an extra key only for the repository
synchronization feature, you can do so, but you have to create/modify your
`~/.ssh/config` (for the `git` user).

This is an example on how to change the default key for all remote hosts:

```bash
Host *                              # Match all remote hosts
  IdentityFile ~/.ssh/mycustom.key  # The location of your private key
```

This is how to change it for an specific host:

```bash
Host example.com                    # The FQDN of the primary Geo node
  HostName example.com              # The FQDN of the primary Geo node
  IdentityFile ~/.ssh/mycustom.key  # The location of your private key
```

## Primary Node GitLab setup

>**Note:**
You will need to setup your database into a **Primary <-> Secondary (read-only)** replication
topology, and your Primary node should always point to a database's Primary
instance. If you haven't done that already, read [database replication](./database.md).

Go to the server that you chose to be your primary, and visit
**Admin Area > Geo Nodes** (`/admin/geo_nodes`) in order to add the Geo nodes.
Although we are looking at the primary Geo node setup, **this is where you also
add any secondary servers as well**.

In the following table you can see what all these settings mean:

| Setting | Description |
| ------- | ----------- |
| Primary | This marks a Geo Node as primary. There can be only one primary, make sure that you first add the primary node and then all the others.
| URL | Your instance's full URL, in the same way it is configured in `gitlab.yml` (source based installations) or `/etc/gitlab/gitlab.rb` (omnibus installations). |
|Public Key | The SSH public key of the user that your GitLab instance runs on (unless changed, should be the user `git`). That means that you have to go in each Geo Node separately and create an SSH key pair. See the [SSH key creation](#create-ssh-key-pairs-for-geo-nodes) section.

First, add your primary node by providing its full URL and the public SSH key
you created previously. Make sure to check the box 'This is a primary node'
when adding it. Continue with all secondaries.

![Geo Nodes Screen](img/geo-nodes-screen.png)

---

## Secondary Node GitLab setup

>**Note:**
The Geo nodes admin area (**Admin Area > Geo Nodes**) is not used when setting
up the secondary servers. This is handled by the primary server setup.

To install a secondary node, you must follow the normal GitLab Enterprise
Edition installation, with some extra requirements:

- You should point your database connection to a [replicated instance](./database.md).
- Your secondary node should be allowed to communicate via HTTP/HTTPS and
  SSH with your primary node (make sure your firewall is not blocking that).

### Database Encryption Key

GitLab stores a unique encryption key in disk that we use to safely store sensitive
data in the database.

Any secondary node must have the exact same value for `db_key_base` as defined in the primary one.

For Omnibus installations it is stored at `/etc/gitlab/gitlab-secrets.json`.

For Source installations it is stored at `/home/git/gitlab/config/secrets.yml`.


### Authorized keys regeneration

The final step will be to regenerate the keys for `.ssh/authorized_keys` using
the following command (HTTPS clone will still work without this extra step).

On the secondary node where the database is [already replicated](./database.md),
run the following:

```
# For Omnibus installations
gitlab-rake gitlab:shell:setup

# For source installations
sudo -u git -H bundle exec rake gitlab:shell:setup RAILS_ENV=production
```
