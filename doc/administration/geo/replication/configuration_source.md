# Geo configuration (source) **[PREMIUM ONLY]**

NOTE: **Note:**
This documentation applies to GitLab source installations. In GitLab 11.5, this documentation was deprecated and will be removed in a future release.
Please consider [migrating to GitLab Omnibus install](https://docs.gitlab.com/omnibus/update/convert_to_omnibus.html). For installations
using the Omnibus GitLab packages, follow the
[**Omnibus Geo nodes configuration**][configuration] guide.

## Configuring a new **secondary** node

NOTE: **Note:**
This is the final step in setting up a **secondary** node. Stages of the setup
process must be completed in the documented order. Before attempting the steps
in this stage, [complete all prior stages](index.md#using-gitlab-installed-from-source-deprecated).

The basic steps of configuring a **secondary** node are to:

- Replicate required configurations between the **primary** and **secondary** nodes.
- Configure a tracking database on each **secondary** node.
- Start GitLab on the **secondary** node.

You are encouraged to first read through all the steps before executing them
in your testing/production environment.

NOTE: **Note:**
**Do not** set up any custom authentication on **secondary** nodes, this will be handled by the **primary** node.

NOTE: **Note:**
**Do not** add anything in the **secondary** node's admin area (**Admin Area > Geo**). This is handled solely by the **primary** node.

### Step 1. Manually replicate secret GitLab values

GitLab stores a number of secret values in the `/home/git/gitlab/config/secrets.yml`
file which *must* match between the **primary** and **secondary** nodes. Until there is
a means of automatically replicating these between nodes (see [gitlab-org/gitlab-ee#3789]), they must
be manually replicated to **secondary** nodes.

1. SSH into the **primary** node, and execute the command below:

    ```sh
    sudo cat /home/git/gitlab/config/secrets.yml
    ```

    This will display the secrets that need to be replicated, in YAML format.

1. SSH into the **secondary** node and login as the `git` user:

    ```sh
    sudo -i -u git
    ```

1. Make a backup of any existing secrets:

    ```sh
    mv /home/git/gitlab/config/secrets.yml /home/git/gitlab/config/secrets.yml.`date +%F`
    ```

1. Copy `/home/git/gitlab/config/secrets.yml` from the **primary** node to the **secondary** node, or
   copy-and-paste the file contents between nodes:

    ```sh
    sudo editor /home/git/gitlab/config/secrets.yml

    # paste the output of the `cat` command you ran on the primary
    # save and exit
    ```

1. Ensure the file permissions are correct:

    ```sh
    chown git:git /home/git/gitlab/config/secrets.yml
    chmod 0600 /home/git/gitlab/config/secrets.yml
    ```

1. Restart GitLab

    ```sh
    service gitlab restart
    ```

Once restarted, the **secondary** node will automatically start replicating missing data
from the **primary** node in a process known as backfill. Meanwhile, the **primary** node
will start to notify the **secondary** node of any changes, so that the **secondary** node can
act on those notifications immediately.

Make sure the **secondary** node is running and accessible. You can login to
the **secondary** node with the same credentials as used for the **primary** node.

### Step 2. Manually replicate the **primary** node's SSH host keys

Read [Manually replicate the **primary** node's SSH host keys](configuration.md#step-2-manually-replicate-the-primary-nodes-ssh-host-keys)

### Step 3. Add the **secondary** GitLab node

1. Navigate to the **primary** node's **Admin Area > Geo**
   (`/admin/geo/nodes`) in your browser.
1. Add the **secondary** node by providing its full URL. **Do NOT** check the
   **This is a primary node** checkbox.
1. Optionally, choose which namespaces should be replicated by the
   **secondary** node. Leave blank to replicate all. Read more in
   [selective synchronization](#selective-synchronization).
1. Click the **Add node** button.
1. SSH into your GitLab **secondary** server and restart the services:

    ```sh
    service gitlab restart
    ```

    Check if there are any common issue with your Geo setup by running:

    ```sh
    bundle exec rake gitlab:geo:check
    ```

1. SSH into your GitLab **primary** server and login as root to verify the
   **secondary** node is reachable or there are any common issue with your Geo setup:

    ```sh
    bundle exec rake gitlab:geo:check
    ```

Once reconfigured, the **secondary** node will automatically start
replicating missing data from the **primary** node in a process known as backfill.
Meanwhile, the **primary** node will start to notify the **secondary** node of any changes, so
that the **secondary** node can act on those notifications immediately.

Make sure the **secondary** node is running and accessible.
You can log in to the **secondary** node with the same credentials as used for the **primary** node.

### Step 4. Enabling Hashed Storage

Read [Enabling Hashed Storage](configuration.md#step-4-enabling-hashed-storage).

### Step 5. (Optional) Configuring the secondary to trust the primary

You can safely skip this step if your **primary** node uses a CA-issued HTTPS certificate.

If your **primary** node is using a self-signed certificate for *HTTPS* support, you will
need to add that certificate to the **secondary** node's trust store. Retrieve the
certificate from the **primary** node and follow your distribution's instructions for
adding it to the **secondary** node's trust store. In Debian/Ubuntu, you would follow these steps:

```sh
sudo -i
cp <primary_node_certification_file> /usr/local/share/ca-certificates
update-ca-certificates
```

### Step 6. Enable Git access over HTTP/HTTPS

Geo synchronizes repositories over HTTP/HTTPS, and therefore requires this clone
method to be enabled. Navigate to **Admin Area > Settings**
(`/admin/application_settings`) on the **primary** node, and set
`Enabled Git access protocols` to `Both SSH and HTTP(S)` or `Only HTTP(S)`.

### Step 7. Verify proper functioning of the secondary node

Read [Verify proper functioning of the secondary node][configuration-verify-node].

## Selective synchronization

Read [Selective synchronization][configuration-selective-replication].

## Troubleshooting

Read the [troubleshooting document][troubleshooting].

[gitlab-org/gitlab-ee#3789]: https://gitlab.com/gitlab-org/gitlab-ee/issues/3789
[configuration]: configuration.md
[configuration-selective-replication]: configuration.md#selective-synchronization
[configuration-verify-node]: configuration.md#step-7-verify-proper-functioning-of-the-secondary-node
[troubleshooting]: troubleshooting.md
