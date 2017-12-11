# GitLab Geo configuration

>**Note:**
This is the documentation for installations from source. For installations
using the Omnibus GitLab packages, follow the
[**Omnibus GitLab Geo nodes configuration**](configuration.md) guide.

## Configuring a new secondary node

>**Note:**
This is the final step in setting up a secondary Geo node. Stages of the setup
process must be completed in the documented order. Before attempting the steps
in this stage, [complete all prior stages](README.md#using-gitlab-installed-from-source).

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

1. SSH into the **primary** node,  and execute the command below to display the
current encryption key:

    ```bash
    sudo -u git -H bundle exec rake geo:db:show_encryption_key RAILS_ENV=production
    ```

Copy the encryption key to bring it to the secondary node in the following steps.

1. SSH into the **secondary**, and execute the command below to open the
`secrets.yml` file:

    ```bash
    sudo -u git -H editor config/secrets.yml
    ```

1. Change the value of `db_key_base` to the output from the primary node.
Then save and close the file.

1. Restart GitLab for the changes to take effect:

    ```bash
    service gitlab restart
    ```

The secondary will start automatically replicating missing data from the
primary in a process known as backfill. Meanwhile, the primary node will start
to notify changes to the secondary, which will act on those notifications
immediately. Make sure the secondary instance is running and accessible.

### Step 2. (Optional) Enabling hashed storage

Once restarted, the secondary will automatically start replicating missing data
from the primary in a process known as backfill. Meanwhile, the primary node
will start to notify the secondary of any changes, so that the secondary can
act on those notifications immediately.

Make sure the secondary instance is running and accessible. You can login to
the secondary node with the same credentials as used in the primary.

### Step 2. (Optional) Enabling hashed storage (from GitLab 10.0)

Read [Enabling Hashed Storage](configuration.md#step-2-optional-enabling-hashed-storage-from-gitlab-10-0)

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

### Step 4. Enable Git access over HTTP/HTTPS

GitLab Geo synchronizes repositories over HTTP/HTTPS, and therefore requires this clone
method to be enabled. Navigate to **Admin Area ➔ Settings**
(`/admin/application_settings`) on the primary node, and set
`Enabled Git access protocols` to `Both SSH and HTTP(S)` or `Only HTTP(S)`.

### Step 5. Verify proper functioning of the secondary node

Read [Verify proper functioning of the secondary node](configuration.md#step-5-verify-proper-functioning-of-the-secondary-node).


## Selective replication

Read [Selective replication](configuration.md#selective-replication).

## Troubleshooting

Read the [troubleshooting document](troubleshooting.md).
