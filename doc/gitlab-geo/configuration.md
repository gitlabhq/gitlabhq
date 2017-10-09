# GitLab Geo configuration

>**Note:**
This is the documentation for the Omnibus GitLab packages. For installations
from source, follow the [**GitLab Geo nodes configuration for installations
from source**](configuration_source.md) guide.

1. [Install GitLab Enterprise Edition][install-ee] on the server that will serve
   as the secondary Geo node. Do not login or set up anything else in the
   secondary node for the moment.
1. [Setup the database replication](database.md)  (`primary (read-write) <-> secondary (read-only)` topology).
1. **Configure GitLab to set the primary and secondary nodes.**
1. [Follow the after setup steps](after_setup.md).

[install-ee]: https://about.gitlab.com/downloads-ee/ "GitLab Enterprise Edition Omnibus packages downloads page"

This is the final step you need to follow in order to setup a Geo node.

You are encouraged to first read through all the steps before executing them
in your testing/production environment.

## Setting up GitLab

>**Notes:**
- **Do not** setup any custom authentication in the secondary nodes, this will be
  handled by the primary node.
- **Do not** add anything in the secondaries Geo nodes admin area
  (**Admin Area ➔ Geo Nodes**). This is handled solely by the primary node.

After having installed GitLab Enterprise Edition in the instance that will serve
as a Geo node and set up the [database replication](database.md), the next steps
can be summed up to:

1. Configure the primary node
1. Replicate some required configurations between the primary and the secondaries
1. Configure a second, tracking database on each secondary
1. Configure every secondary node in the primary's Admin screen
1. Start GitLab on the secondary node's machine

### Prerequisites

This is the last step of configuring a Geo node. Make sure you have followed the
first two steps of the [Setup instructions](README.md#setup-instructions):

1. You have already installed on the secondary server the same version of
   GitLab Enterprise Edition that is present on the primary server.
1. You have set up the database replication.
1. Your secondary node is allowed to communicate via HTTP/HTTPS and SSH with
   your primary node (make sure your firewall is not blocking that).
1. Your nodes must have an NTP service running to synchronize the clocks.
   You can use different timezones, but the hour relative to UTC can't be more
   than 60 seconds off from each node.
1. You have set up another PostgreSQL database that can store writes for the secondary.
   Note that this MUST be on another instance, since the primary replicated database
   is read-only.

Some of the following steps require to configure the primary and secondary
nodes almost at the same time. For your convenience make sure you have SSH
logins opened on all nodes as we will be moving back and forth.

### Step 1. Adding the primary GitLab node

1. SSH into the **primary** node and login as root:

    ```
    sudo -i
    ```

1. Execute the command below to define the node as primary Geo node:

    ```
    gitlab-ctl set-geo-primary-node
    ```

    This command will use your defined `external_url` in `gitlab.rb`

### Step 2. Updating the `known_hosts` file of the secondary nodes

1. SSH into the **secondary** node and login as root:

    ```
    sudo -i
    ```

1. The secondary nodes need to know the SSH fingerprint of the primary node that
   will be used for the Git clone/fetch operations. In order to add it to the
   `known_hosts` file, run the following command and type `yes` when asked:

    ```
    sudo -u git -H ssh git@<primary-node-url>
    ```

    Replace `<primary-node-url>` with the FQDN of the primary node.

1. Verify that the fingerprint was added by checking `known_hosts`:

    ```
    cat /var/opt/gitlab/.ssh/known_hosts
    ```

### Step 3. Copying the database encryption key

GitLab stores a unique encryption key in disk that we use to safely store
sensitive data in the database. Any secondary node must have the
**exact same value** for `db_key_base` as defined in the primary one.

1. SSH into the **primary** node and login as root:

    ```
    sudo -i
    ```

1. Execute the command below to display the current encryption key and copy it:

     ```
     gitlab-rake geo:db:show_encryption_key
     ```

1. SSH into the **secondary** node and login as root:

    ```
    sudo -i
    ```

1. Open the secrets file and paste the value of `db_key_base` you copied in the
   previous step:

     ```
     editor /etc/gitlab/gitlab-secrets.json
     ```

1. Save and close the file.

1. Reconfigure for the change to take effect.
    ```
    gitlab-ctl reconfigure
    ```

### Step 4. Regenerating the authorized keys in the secondary node

> **IMPORTANT:** Since GitLab 10.0 `~/.ssh/authorized_keys` no longer
> can be used, and this step is deprecated. Instead, follow the
> instructions on [configuring SSH authorization via database lookups](../administration/operations/speed_up_ssh.html)
> (for both primary AND secondary nodes).

Regenerate the keys for `~/.ssh/authorized_keys`
(HTTPS clone will still work without this extra step).

1. On the **secondary** node where the database is [already replicated](./database.md),
   run:

     ```
     # For Omnibus installations
     gitlab-rake gitlab:shell:setup
     ```

This will enable `git` operations to authorize against your existing users.
New users and SSH keys updated after this step, will be replicated automatically.

### Step 5. Enabling hashed storage (from GitLab 10.0)

1. Visit the **primary** node's **Admin Area ➔ Settings**
   (`/admin/application_settings`) in your browser
1. In the `Repository Storages` section, check `Create new projects using hashed storage paths`:

    ![](img/hashed-storage.png)

Using hashed storage significantly improves Geo replication - project and group
renames no longer require synchronization between nodes - so we recommend it is
used for all GitLab Geo installations.

### Step 6. Enabling the secondary GitLab node

1. SSH into the **secondary** node and login as root:

    ```
    sudo -i
    ```

1. Get the contents of `id_rsa.pub` key that was pre-generated by Omnibus GitLab
   and copy them:

    ```
    sudo -u git cat /var/opt/gitlab/.ssh/id_rsa.pub
    ```

1. Visit the **primary** node's **Admin Area ➔ Geo Nodes** (`/admin/geo_nodes`)
   in your browser.
1. Add the secondary node by providing its full URL and the public SSH key
   you created previously. **Do NOT** check the box 'This is a primary node'.
1. Added in GitLab 9.5: Choose which namespaces should be replicated by the secondary node. Leave blank to replicate all. Read more in [selective replication](#selective-replication).
1. Click the **Add node** button.

---

After the **Add Node** button is pressed, the primary node will start to notify
changes to the secondary. Make sure the secondary instance is running and
accessible.

The two most obvious issues that replication can have here are:

1. Database replication not working well
1. Instance to instance notification not working. In that case, it can be
   something of the following:
     - You are using a custom certificate or custom CA (see the
       [Troubleshooting](#troubleshooting) section)
     - Instance is firewalled (check your firewall rules)

### Step 7. Replicating the repositories data

Getting a new secondary Geo node up and running, will also require the
repositories data to be synced.

With GitLab 9.0 the syncing process starts automatically from the
secondary node after the **Add Node** button is pressed.

Currently, this is what is synced:

* Git repositories
* Wikis
* LFS objects
* Issue, merge request, and comment attachments
* User, group, and project avatars

You can monitor the status of the syncing process on a secondary node
by visiting the primary node's **Admin Area ➔ Geo Nodes** (`/admin/geo_nodes`)
in your browser.

Please note that if `git_data_dirs` is customized on the primary for multiple
repository shards you must duplicate the same configuration on the secondary.

![GitLab Geo dashboard](img/geo-node-dashboard.png)

Disabling a secondary node stops the syncing process.

With GitLab 8.14 this process is started manually from the primary node.
You can start the syncing process by clicking the "Backfill all repositories"
button on `Admin > Geo Nodes` screen.

On previous versions, you can use `rsync` for that:

Make sure `rsync` is installed in both primary and secondary servers and root
SSH access with a password is enabled. Otherwise, you can set up an SSH key-based
connection between the servers.

1. SSH into the **secondary** node and login as root:

    ```
    sudo -i
    ```

1. Assuming `1.2.3.4` is the IP of the primary node, run the following command
   to start the sync:

    ```bash
    # For Omnibus installations
    rsync -guavrP root@1.2.3.4:/var/opt/gitlab/git-data/repositories/ /var/opt/gitlab/git-data/repositories/
    gitlab-ctl reconfigure # to fix directory permissions
    ```

If this step is not followed, the secondary node will eventually clone and
fetch every missing repository as they are updated with new commits on the
primary node, so syncing the repositories beforehand will buy you some time.

While active repositories will be eventually replicated, if you don't rsync,
the files, any archived/inactive repositories will not get in the secondary node
as Geo doesn't run any routine task to look for missing repositories.

## Next steps

Your nodes should now be ready to use. You can login to the secondary node
with the same credentials as used in the primary. Visit the secondary node's
**Admin Area ➔ Geo Nodes** (`/admin/geo_nodes`) in your browser to check if it's
correctly identified as a secondary Geo node and if Geo is enabled.

If your installation isn't working properly, check the
[troubleshooting](#troubleshooting) section.

Point your users to the [after setup steps](after_setup.md).

## Selective replication

With GitLab 9.5, GitLab Geo now supports the first iteration of selective
replication, which allows admins to choose which groups should be
replicated by secondary nodes.

It is important to notice that selective replication:

1. Does not restrict permissions from secondary nodes.
1. Does not hide projects metadata from secondary nodes. Since Geo currently
relies on PostgreSQL replication, all project metadata gets replicated to
secondary nodes, but repositories that have not been selected will be empty.
1. Secondary nodes won't pull repositories that do not belong to the selected
groups to be replicated.

## Adding another secondary Geo node

To add another Geo node in an already Geo configured infrastructure, just follow
[the steps starting from step 2](#step-2-updating-the-known_hosts-file-of-the-secondary-nodes).
Just omit the first step that sets up the primary node.

## Additional information for the SSH key pairs

When adding a new **secondary** Geo node, you must provide an SSH public key for
the system user that your GitLab instance runs as (unless changed, should be the
user `git`). This user will act as a "normal user" who fetches from the primary
Geo node.

Omnibus automatically generates `~git/.ssh/id_rsa` and `~git/.ssh/id_rsa.pub`
files on secondary Geo nodes. Primaries do not need these files, and you should
not create them manually.

### Upgrading Geo

See the [updating the Geo nodes document](updating_the_geo_nodes.md).

## Troubleshooting

See the [troubleshooting document](troubleshooting.md).
