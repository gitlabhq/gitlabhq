# GitLab Geo configuration

This is the final step you need to follow in order to setup a Geo node.

---

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**

- [Setting up GitLab](#setting-up-gitlab)
  - [Prerequisites](#prerequisites)
  - [Step 1. Adding the primary GitLab node](#step-1-adding-the-primary-gitlab-node)
  - [Step 2. Updating the `known_hosts` file of the secondary nodes](#step-2-updating-the-known_hosts-file-of-the-secondary-nodes)
  - [Step 3. Copying the database encryption key](#step-3-copying-the-database-encryption-key)
  - [Step 4. Enabling the secondary GitLab node](#step-4-enabling-the-secondary-gitlab-node)
  - [Step 5. Replicating the repositories data](#step-5-replicating-the-repositories-data)
  - [Step 6. Regenerating the authorized keys in the secondary node](#step-6-regenerating-the-authorized-keys-in-the-secondary-node)
  - [Next steps](#next-steps)
- [Adding another secondary Geo node](#adding-another-secondary-geo-node)
- [Additional information for the SSH key pairs](#additional-information-for-the-ssh-key-pairs)
- [Troubleshooting](#troubleshooting)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Setting up GitLab

>**Notes:**
- Don't setup any custom authentication in the secondary nodes, this will be
  handled by the primary node.
- Do not add anything in the secondaries Geo nodes admin area
   (**Admin Area ➔ Geo Nodes**). This is handled solely by the primary node.

---

After having installed GitLab Enterprise Edition in the instance that will serve
as a Geo node and set up the [database replication](database.md), the next steps can be summed
up to:

1. Configure the primary node
1. Replicate some required configurations between the primary and the secondaries
1. Start GitLab in the secondary node's machine
1. Configure every secondary node in the primary's Admin screen

### Prerequisites

This is the last step of configuring a Geo node. Make sure you have followed the
first two steps of the [Setup instructions](README.md#setup-instructions):

1. You have already installed on the secondary server the same version of
   GitLab Enterprise Edition that is present on the primary server.
1. You have set up the database replication.
1. Your secondary node is allowed to communicate via HTTP/HTTPS and SSH with
   your primary node (make sure your firewall is not blocking that).

Some of the following steps require to configure the primary and secondary
nodes almost at the same time. For your convenience make sure you have SSH
logins opened on all nodes as we will be moving back and forth.

### Step 1. Adding the primary GitLab node

1. SSH into the **primary** node and login as root:

    ```
    sudo -i
    ```

1. Create a new SSH key pair for the primary node. Choose the default location
   and leave the password blank by hitting 'Enter' three times:

    ```bash
    sudo -u git -H ssh-keygen -b 4096 -C 'Primary GitLab Geo node'
    ```

    Read more in [additional info for SSH key pairs](#additional-information-for-the-ssh-key-pairs).

1. Get the contents of `id_rsa.pub` the was just created:

    ```
    # Omnibus GitLab installations
    sudo -u git cat /var/opt/gitlab/.ssh/id_rsa.pub

    # Installations from source
    sudo -u git cat /home/git/.ssh/id_rsa.pub
    ```

1. Visit the primary node's **Admin Area ➔ Geo Nodes** (`/admin/geo_nodes`) in
   your browser.
1. Add the primary node by providing its full URL and the public SSH key
   you created previously. Make sure to check the box 'This is a primary node'
   when adding it.

    ![Add new primary Geo node](img/geo_nodes_add_new.png)

1. Click the **Add node** button.

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
    # Omnibus GitLab installations
    cat /var/opt/gitlab/.ssh/known_hosts

    # Installations from source
    cat /home/git/.ssh/known_hosts
    ```

### Step 3. Copying the database encryption key

GitLab stores a unique encryption key in disk that we use to safely store
sensitive data in the database. Any secondary node must have the
**exact same value** for `db_key_base` as defined in the primary one.

1. SSH into the **primary** node and login as root:

    ```
    sudo -i
    ```

1. Find the value of `db_key_base` and copy it:

     ```
     # Omnibus GitLab installations
     cat /etc/gitlab/gitlab-secrets.json

     # Installations from source
     cat /home/git/gitlab/config/secrets.yml
     ```

1. SSH into the **secondary** node and login as root:

    ```
    sudo -i
    ```

1. Open the secrets file and paste the value of `db_key_base` you copied in the
   previous step:

     ```
     # Omnibus GitLab installations
     editor /etc/gitlab/gitlab-secrets.json

     # Installations from source
     editor /home/git/gitlab/config/secrets.yml
     ```

1. Save and close the file.

### Step 4. Enabling the secondary GitLab node

1. SSH into the **secondary** node and login as root:

    ```
    sudo -i
    ```

1. Create a new SSH key pair for the secondary node. Choose the default location
   and leave the password blank by hitting 'Enter' three times:

    ```bash
    sudo -u git -H ssh-keygen -b 4096 -C 'Secondary GitLab Geo node'
    ```

    Read more in [additional info for SSH key pairs](#additional-information-for-the-ssh-key-pairs).

1. Get the contents of `id_rsa.pub` the was just created:

    ```
    # Omnibus installations
    sudo -u git cat /var/opt/gitlab/.ssh/id_rsa.pub

    # Installations from source
    sudo -u git cat /home/git/.ssh/id_rsa.pub
    ```

1. Visit the **primary** node's **Admin Area ➔ Geo Nodes** (`/admin/geo_nodes`)
   in your browser.
1. Add the secondary node by providing its full URL and the public SSH key
   you created previously. **Do NOT** check the box 'This is a primary node'.
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

### Step 5. Replicating the repositories data

Getting a new secondary Geo node up and running, will also require the
repositories directory to be synced from the primary node. You can use `rsync`
for that.

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

    # For installations from source
    rsync -guavrP root@1.2.3.4:/home/git/repositories/ /home/git/repositories/
    chmod ug+rwX,o-rwx /home/git/repositories
    ```

If this step is not followed, the secondary node will eventually clone and
fetch every missing repository as they are updated with new commits on the
primary node, so syncing the repositories beforehand will buy you some time.

While active repositories will be eventually replicated, if you don't rsync,
the files, any archived/inactive repositories will not get in the secondary node
as Geo doesn't run any routine task to look for missing repositories.

### Step 6. Regenerating the authorized keys in the secondary node

The final step is to regenerate the keys for `~/.ssh/authorized_keys`
(HTTPS clone will still work without this extra step).

On the **secondary** node where the database is [already replicated](./database.md),
run:

```
# For Omnibus installations
gitlab-rake gitlab:shell:setup

# For source installations
sudo -u git -H bundle exec rake gitlab:shell:setup RAILS_ENV=production
```

This will enable `git` operations to authorize against your existing users.
New users and SSH keys updated after this step, will be replicated automatically.

### Next steps

Your nodes should now be ready to use. You can login to the secondary node
with the same credentials as used in the primary. Visit the secondary node's
**Admin Area ➔ Geo Nodes** (`/admin/geo_nodes`) in your browser to check if it's
correctly identified as a secondary Geo node and if Geo is enabled.

If your installation isn't working properly, check the
[troubleshooting](#troubleshooting) section.

## Adding another secondary Geo node

To add another Geo node in an already Geo configured infrastructure, just follow
[the steps starting form step 2](#step-2-updating-the-known_hosts-file-of-the-secondary-nodes).
Just omit the first step that sets up the primary node.

## Additional information for the SSH key pairs

When adding a new Geo node, you must provide an SSH public key of the user that
your GitLab instance runs on (unless changed, should be the user `git`). This
user will act as a "normal user" who fetches from the primary Geo node.

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

## Troubleshooting

Setting up Geo requires careful attention to details and sometimes it's easy to
miss a step. Here is a checklist of questions you should ask to try to detect
where you have to fix (all commands and path locations are for Omnibus installs):

- Is Postgres replication working?
- Are my nodes pointing to the correct database instance?
    - You should make sure your primary Geo node points to the instance with
      writing permissions.
    - Any secondary nodes should point only to read-only instances.
- Can Geo detect my current node correctly?
    - Geo uses your defined node from `Admin ➔ Geo` screen, and tries to match
      with the value defined in `/etc/gitlab/gitlab.rb` configuration file.
      The relevant line looks like: `external_url "http://gitlab.example.com"`.
    - To check if node on current machine is correctly detected type:

        ```
        sudo gitlab-rails runner "puts Gitlab::Geo.current_node.inspect"
        ```

        and expect something like:

        ```
        #<GeoNode id: 2, schema: "https", host: "gitlab.example.com", port: 443, relative_url_root: "", primary: false, ...>
        ```

    - By running the command above, `primary` should be `true` when executed in
      the primary node, and `false` on any secondary
- Did I define the correct SSH Key for the node?
    - You must create an SSH Key for `git` user
    - This key is the one you have to inform at `Admin > Geo`
- Can I SSH from secondary to primary node using `git` user account?
    - This is the most obvious cause of problems with repository replication issues.
      If you haven't added the primary node's key to `known_hosts`, you will end up with
      a lot of failed sidekiq jobs with an error similar to:

        ```
        Gitlab::Shell::Error: Host key verification failed. fatal: Could not read from remote repository. Please make sure you have the correct access rights and the repository exists.
        ```

        An easy way to fix is by logging in as the `git` user in the secondary node and run:

        ```
        # remove old entries to your primary gitlab in known_hosts
        ssh-keyscan -R your-primary-gitlab.example.com

        # add a new entry in known_hosts
        ssh-keyscan -t rsa your-primary-gitlab.example.com >> ~/.ssh/known_hosts
        ```
- Can primary node communicate with secondary node by HTTP/HTTPS ports?
- Can secondary nodes communicate with primary node by HTTP/HTTPS/SSH ports?
- Can secondary nodes execute a successful git clone using git user's own
  SSH Key to primary node repository?

>**Note:**
This list is an attempt to document all the moving parts that can go wrong.
We are working into getting all this steps verified automatically in a
rake task in the future.

[ssh-pair]: #create-ssh-key-pairs-for-new-geo-nodes
