# GitLab Geo configuration

>**Note:**
This is the documentation for the Omnibus GitLab packages. For installations
from source, follow the [**GitLab Geo nodes configuration for installations
from source**](configuration_source.md) guide.

## Configuring a new secondary node

>**Note:**
This is the final step in setting up a secondary Geo node. Stages of the
setup process must be completed in the documented order.
Before attempting the steps in this stage, [complete all prior stages](README.md#using-omnibus-gitlab).

The basic steps of configuring a secondary node are to replicate required
configurations between the primary and the secondaries; to configure a tracking
database on each secondary; and to start GitLab on the secondary node.

You are encouraged to first read through all the steps before executing them
in your testing/production environment.

>**Notes:**
- **Do not** setup any custom authentication in the secondary nodes, this will be
  handled by the primary node.
- **Do not** add anything in the secondaries Geo nodes admin area
  (**Admin Area ➔ Geo Nodes**). This is handled solely by the primary node.

### Step 1. Copying the database encryption key

GitLab stores a unique encryption key on disk that is used to encrypt
sensitive data stored in the database. All secondary nodes must have the
**exact same value** for `db_key_base` as defined on the primary node.

1. SSH into the **primary** node, and execute the command below
to display the current encryption key:

    ```bash
    sudo gitlab-rake geo:db:show_encryption_key
    ```

Copy the encryption key to bring it to the secondary node in the following steps.

1. SSH into the **secondary** node and login as root:

    ```
    sudo -i
    ```

1. Add the following to `/etc/gitlab/gitlab.rb`, replacing `encryption-key` with the output
   of the previous command:

    ```ruby
    gitlab_rails['db_key_base'] = 'encryption-key'
    ```

1. Reconfigure the secondary node for the change to take effect:

    ```
    gitlab-ctl reconfigure
    ```

Once reconfigured, the secondary will automatically start
replicating missing data from the primary in a process known as backfill.
Meanwhile, the primary node will start to notify the secondary of any changes, so
that the secondary can act on those notifications immediately.

Make sure the secondary instance is
running and accessible. You can login to the secondary node
with the same credentials as used in the primary.

### Step 2. (Optional) Enabling hashed storage (from GitLab 10.0)

>**Warning**
Hashed storage is in **Alpha**. It is considered experimental and not
production-ready. See [Hashed Storage](../administration/repository_storage_types.md)
for more detail, and for the latest updates, check
[infrastructure issue #2821](https://gitlab.com/gitlab-com/infrastructure/issues/2821).

Using hashed storage significantly improves Geo replication - project and group
renames no longer require synchronization between nodes.

1. Visit the **primary** node's **Admin Area ➔ Settings**
   (`/admin/application_settings`) in your browser
1. In the `Repository Storages` section, check `Create new projects using hashed storage paths`:

    ![](img/hashed-storage.png)

### Step 3. (Optional) Configuring the secondary to trust the primary

You can safely skip this step if your primary uses a CA-issued HTTPS certificate.

If your primary is using a self-signed certificate for *HTTPS* support, you will
need to add that certificate to the secondary's trust store. Retrieve the
certificate from the primary and follow
[these instructions](https://docs.gitlab.com/omnibus/settings/ssl.html)
on the secondary.

### Step 4. Enable Git access over HTTP/HTTPS

GitLab Geo synchronizes repositories over HTTP/HTTPS, and therefore requires this clone
method to be enabled. Navigate to **Admin Area ➔ Settings**
(`/admin/application_settings`) on the primary node, and set
`Enabled Git access protocols` to `Both SSH and HTTP(S)` or `Only HTTP(S)`.

### Step 5. Verify proper functioning of the secondary node

Congratulations! Your secondary geo node is now configured!

You can login to the secondary node with the same credentials you used on the
primary. Visit the secondary node's **Admin Area ➔ Geo Nodes**
(`/admin/geo_nodes`) in your browser to check if it's correctly identified as a
secondary Geo node and if Geo is enabled.

The initial replication, or 'backfill', will probably still be in progress. You
can monitor the synchronization process on each geo node from the primary
node's Geo Nodes dashboard in your browser.

![GitLab Geo dashboard](img/geo-node-dashboard.png)

If your installation isn't working properly, check the
[troubleshooting document](troubleshooting.md).

The two most obvious issues that can become apparent in the dashboard are:

1. Database replication not working well
1. Instance to instance notification not working. In that case, it can be
   something of the following:
     - You are using a custom certificate or custom CA (see the
       [troubleshooting document](troubleshooting.md))
     - The instance is firewalled (check your firewall rules)

Please note that disabling a secondary node will stop the sync process.

Please note that if `git_data_dirs` is customized on the primary for multiple
repository shards you must duplicate the same configuration on the secondary.

Point your users to the ["Using a Geo Server" guide](using_a_geo_server.md).

Currently, this is what is synced:

* Git repositories
* Wikis
* LFS objects
* Issues, merge requests, snippets, and comment attachments
* Users, groups, and project avatars

## Selective replication

GitLab Geo supports selective replication, which allows admins to choose which
groups should be replicated by secondary nodes.

It is important to note that selective replication:

1. Does not restrict permissions from secondary nodes.
1. Does not hide projects metadata from secondary nodes. Since Geo currently
relies on PostgreSQL replication, all project metadata gets replicated to
secondary nodes, but repositories that have not been selected will be empty.
1. Secondary nodes won't pull repositories that do not belong to the selected
groups to be replicated.

## Upgrading Geo

See the [updating the Geo nodes document](updating_the_geo_nodes.md).

## Troubleshooting

See the [troubleshooting document](troubleshooting.md).
