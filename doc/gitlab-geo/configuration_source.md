# GitLab Geo configuration

>**Note:**
This is the documentation for installations from source. For installations
using the Omnibus GitLab packages, follow the
[**Omnibus GitLab Geo nodes configuration**](configuration.md) guide.

>**Note:**
Stages of the setup process must be completed in the documented order.
Before attempting the steps in this stage, complete all prior stages.

1. [Install GitLab Enterprise Edition][install-ee-source] on the server that
   will serve as the **secondary** Geo node. Do not login or set up anything
   else in the secondary node for the moment.
1. [Upload the GitLab License](../user/admin_area/license.md) you purchased for GitLab Enterprise Edition to unlock GitLab Geo.
1. [Setup the database replication](database_source.md) (`primary (read-write) <-> secondary (read-only)` topology).
1. [Configure SSH authorizations to use the database](ssh.md)
1. **Configure GitLab to set the primary and secondary nodes.**
1. [Follow the after setup steps](after_setup.md).

[install-ee-source]: https://docs.gitlab.com/ee/install/installation.html "GitLab Enterprise Edition installation from source"

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
as a Geo node and set up the [database replication](database_source.md), the
next steps can be summed up to:

1. Replicate some required configurations between the primary and the secondaries
1. Configure a second, tracking database on each secondary
1. Start GitLab on the secondary node's machine

### Prerequisites

This is the last step of configuring a Geo secondary node. Make sure you have
followed the first two steps of the [Setup instructions](README.md#setup-instructions):

1. You have already installed on the secondary server the same version of
   GitLab Enterprise Edition that is present on the primary server.
1. You have set up the database replication.
1. Your secondary node is allowed to communicate via HTTP/HTTPS with
   your primary node (make sure your firewall is not blocking that).
1. Your nodes must have an NTP service running to synchronize the clocks.
   You can use different timezones, but the hour relative to UTC can't be more
   than 60 seconds off from each node.
1. You have set up another PostgreSQL database that can store writes for the secondary.
   Note that this MUST be on another instance, since the primary replicated database
   is read-only.

### Step 1. Copying the database encryption key

GitLab stores a unique encryption key in disk that we use to safely store
sensitive data in the database. Any secondary node must have the
**exact same value** for `db_key_base` as defined in the primary one.

1. SSH into the **primary** node and login as root:

    ```
    sudo -i
    ```

1. Execute the command below to display the current encryption key and copy it:

     ```
     sudo -u git -H bundle exec rake geo:db:show_encryption_key RAILS_ENV=production
     ```

1. SSH into the **secondary** node and login as root:

    ```
    sudo -i
    ```

1. Open the `secrets.yml` file and change the value of `db_key_base` to the
   output of the previous step:

     ```
     sudo -u git -H editor config/secrets.yml
     ```

1. Save and close the file.

1. Restart GitLab for the changes to take effect:

    ```
    service gitlab restart
    ```

The secondary will start automatically replicating missing data from the
primary in a process known as backfill. Meanwhile, the primary node will start
to notify changes to the secondary, which will act on those notifications
immediately. Make sure the secondary instance is running and accessible.

### Step 2. Enabling hashed storage (from GitLab 10.0)

1. Visit the **primary** node's **Admin Area ➔ Settings**
   (`/admin/application_settings`) in your browser
1. In the `Repository Storages` section, check `Create new projects using hashed storage paths`:

    ![](img/hashed-storage.png)

Using hashed storage significantly improves Geo replication - project and group
renames no longer require synchronization between nodes - so we recommend it is
used for all GitLab Geo installations.

### Step 3. (Optional) Configuring the secondary to trust the primary

You can safely skip this step if your primary uses a CA-issued HTTPS certificate.

If your primary is using a self-signed certificate for *HTTPS* support, you will
need to add that certificate to the secondary's trust store. Retrieve the
certificate from the primary and follow your distribution's instructions for
adding it to the secondary's trust store. In Debian/Ubuntu, for example, with a
certificate file of `primary.geo.example.com.crt`, you would follow these steps:

```
sudo -i
cp primary.geo.example.com.crt /usr/local/share/ca-certificates
update-ca-certificates
```

### Step 4. Managing the secondary GitLab node

You can monitor the status of the syncing process on a secondary node
by visiting the primary node's **Admin Area ➔ Geo Nodes** (`/admin/geo_nodes`)
in your browser.

Please note that if `git_data_dirs` is customized on the primary for multiple
repository shards you must duplicate the same configuration on the secondary.

![GitLab Geo dashboard](img/geo-node-dashboard.png)

Disabling a secondary node stops the syncing process.

The two most obvious issues that replication can have here are:

1. Database replication not working well
1. Instance to instance notification not working. In that case, it can be
   something of the following:
     - You are using a custom certificate or custom CA (see the
       [Troubleshooting](configuration.md#troubleshooting) section)
     - Instance is firewalled (check your firewall rules)

Currently, this is what is synced:

* Git repositories
* Wikis
* LFS objects
* Issue, merge request, snippet and comment attachments
* User, group, and project avatars

You can monitor the status of the syncing process on a secondary node
by visiting the primary node's **Admin Area ➔ Geo Nodes** (`/admin/geo_nodes`)
in your browser.

## Next steps

Your nodes should now be ready to use. You can login to the secondary node
with the same credentials as used in the primary. Visit the secondary node's
**Admin Area ➔ Geo Nodes** (`/admin/geo_nodes`) in your browser to check if it's
correctly identified as a secondary Geo node and if Geo is enabled.

If your installation isn't working properly, check the
[troubleshooting](configuration.md#troubleshooting) section.

Point your users to the [after setup steps](after_setup.md).

## Selective replication

Read [Selective replication](configuration.md#selective-replication).

## Replicating wikis and repositories over SSH

Read [Replicating wikis and repositories over SSH](configuration.md#replicating-wikis-and-repositories-over-ssh).

## Troubleshooting

Read the [troubleshooting document](troubleshooting.md).
