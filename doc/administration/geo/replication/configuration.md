---
stage: Systems
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Configure a new **secondary** site
---

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab Self-Managed

NOTE:
This is the final step in setting up a **secondary** Geo site. Stages of the
setup process must be completed in the documented order.
If not, [complete all prior stages](../setup/_index.md#using-linux-package-installations) before proceeding.

The basic steps of configuring a **secondary** site are to:

1. Replicate required configurations between the **primary** and the **secondary** site.
1. Configure a tracking database on each **secondary** site.
1. Start GitLab on each **secondary** site.

This document focuses on the first item. You are encouraged to first read
through all the steps before executing them in your testing/production
environment.

Prerequisites for **both primary and secondary sites**:

- [Set up the database replication](../setup/database.md)
- [Configure fast lookup of authorized SSH keys](../../operations/fast_ssh_key_lookup.md)

NOTE:
**Do not** set up any custom authentication for the **secondary** site. This is handled by the **primary** site.
Any change that requires access to the **Admin area** needs to be done in the
**primary** site because the **secondary** site is a read-only replica.

## Step 1. Manually replicate secret GitLab values

GitLab stores a number of secret values in the `/etc/gitlab/gitlab-secrets.json`
file which *must* be the same on all of a site's nodes. Until there is
a means of automatically replicating these between sites (see [issue #3789](https://gitlab.com/gitlab-org/gitlab/-/issues/3789)),
they must be manually replicated to **all nodes of the secondary site**.

1. SSH into a **Rails node on your primary** site, and execute the command below:

   ```shell
   sudo cat /etc/gitlab/gitlab-secrets.json
   ```

   This displays the secrets that need to be replicated, in JSON format.

1. SSH **into each node on your secondary Geo site** and login as the `root` user:

   ```shell
   sudo -i
   ```

1. Make a backup of any existing secrets:

   ```shell
   mv /etc/gitlab/gitlab-secrets.json /etc/gitlab/gitlab-secrets.json.`date +%F`
   ```

1. Copy `/etc/gitlab/gitlab-secrets.json` from the **Rails node on your primary** site to **each node on your secondary** site, or
   copy-and-paste the file contents between nodes:

   ```shell
   sudo editor /etc/gitlab/gitlab-secrets.json

   # paste the output of the `cat` command you ran on the primary
   # save and exit
   ```

1. Ensure the file permissions are correct:

   ```shell
   chown root:root /etc/gitlab/gitlab-secrets.json
   chmod 0600 /etc/gitlab/gitlab-secrets.json
   ```

1. Reconfigure **each Rails, Sidekiq and Gitaly nodes on your secondary** site for the change to take effect:

   ```shell
   gitlab-ctl reconfigure
   gitlab-ctl restart
   ```

## Step 2. Manually replicate the **primary** site's SSH host keys

GitLab integrates with the system-installed SSH daemon, designating a user
(typically named `git`) through which all access requests are handled.

In a [Disaster Recovery](../disaster_recovery/_index.md) situation, GitLab system
administrators promote a **secondary** site to the **primary** site. DNS records for the
**primary** domain should also be updated to point to the new **primary** site
(previously a **secondary** site). Doing so avoids the need to update Git remotes and API URLs.

This causes all SSH requests to the newly promoted **primary** site to
fail due to SSH host key mismatch. To prevent this, the primary SSH host
keys must be manually replicated to the **secondary** site.

The SSH host key path depends on the used software:

- If you use OpenSSH, the path is `/etc/ssh`.
- If you use [`gitlab-sshd`](../../operations/gitlab_sshd.md), the path is `/var/opt/gitlab/gitlab-sshd`.

In the following steps, replace `<ssh_host_key_path>` with the one you're using:

1. SSH into **each Rails node on your secondary** site and sign in as the `root` user:

   ```shell
   sudo -i
   ```

1. Make a backup of any existing SSH host keys:

   ```shell
   find <ssh_host_key_path> -iname 'ssh_host_*' -exec cp {} {}.backup.`date +%F` \;
   ```

1. Copy the SSH host keys from the **primary** site:

   If you can access one of the **nodes on your primary** site serving SSH traffic (usually, the main GitLab Rails application nodes) using the **root** user:

   ```shell
   # Run this from the secondary site, change `<primary_site_fqdn>` for the IP or FQDN of the server
   scp root@<primary_node_fqdn>:<ssh_host_key_path>/ssh_host_*_key* <ssh_host_key_path>
   ```

   If you only have access through a user with `sudo` privileges:

   ```shell
   # Run this from the node on your primary site:
   sudo tar --transform 's/.*\///g' -zcvf ~/geo-host-key.tar.gz <ssh_host_key_path>/ssh_host_*_key*

   # Run this on each node on your secondary site:
   scp <user_with_sudo>@<primary_site_fqdn>:geo-host-key.tar.gz .
   tar zxvf ~/geo-host-key.tar.gz -C <ssh_host_key_path>
   ```

1. On **each Rails node on your secondary** site, ensure the file permissions are correct:

   ```shell
   chown root:root <ssh_host_key_path>/ssh_host_*_key*
   chmod 0600 <ssh_host_key_path>/ssh_host_*_key
   ```

1. To verify key fingerprint matches, execute the following command on both primary and secondary nodes on each site:

   ```shell
   for file in <ssh_host_key_path>/ssh_host_*_key; do ssh-keygen -lf $file; done
   ```

   You should get an output similar to this one and they should be identical on both nodes:

   ```shell
   1024 SHA256:FEZX2jQa2bcsd/fn/uxBzxhKdx4Imc4raXrHwsbtP0M root@serverhostname (DSA)
   256 SHA256:uw98R35Uf+fYEQ/UnJD9Br4NXUFPv7JAUln5uHlgSeY root@serverhostname (ECDSA)
   256 SHA256:sqOUWcraZQKd89y/QQv/iynPTOGQxcOTIXU/LsoPmnM root@serverhostname (ED25519)
   2048 SHA256:qwa+rgir2Oy86QI+PZi/QVR+MSmrdrpsuH7YyKknC+s root@serverhostname (RSA)
   ```

1. Verify that you have the correct public keys for the existing private keys:

   ```shell
   # This will print the fingerprint for private keys:
   for file in <ssh_host_key_path>/ssh_host_*_key; do ssh-keygen -lf $file; done

   # This will print the fingerprint for public keys:
   for file in <ssh_host_key_path>/ssh_host_*_key.pub; do ssh-keygen -lf $file; done
   ```

   NOTE:
   The output for private keys and public keys command should generate the same fingerprint.

1. Restart either `sshd` for OpenSSH or the `gitlab-sshd` service on **each Rails node on your secondary** site:

   - For OpenSSH:

     ```shell
     # Debian or Ubuntu installations
     sudo service ssh reload

     # CentOS installations
     sudo service sshd reload
     ```

   - For `gitlab-sshd`:

     ```shell
     sudo gitlab-ctl restart gitlab-sshd
     ```

1. Verify SSH is still functional.

   SSH into your GitLab **secondary** server in a new terminal. If you are unable to connect,
   verify the permissions are correct according to the previous steps.

## Step 3. Add the **secondary** site

1. SSH into **each Rails and Sidekiq node on your secondary** site and login as root:

   ```shell
   sudo -i
   ```

1. Edit `/etc/gitlab/gitlab.rb` and add a **unique** name for your site. You need this in the next steps:

   ```ruby
   ##
   ## The unique identifier for the Geo site. See
   ## https://docs.gitlab.com/ee/administration/geo_sites.html#common-settings
   ##
   gitlab_rails['geo_node_name'] = '<site_name_here>'
   ```

1. Reconfigure **each Rails and Sidekiq node on your secondary** site for the change to take effect:

   ```shell
   gitlab-ctl reconfigure
   ```

1. Go to the primary node GitLab instance:
   1. On the left sidebar, at the bottom, select **Admin**.
   1. On the left sidebar, select **Geo > Sites**.
   1. Select **Add site**.
      ![Adding a secondary site in Geo configuration interface](img/adding_a_secondary_v15_8.png)
   1. In **Name**, enter the value for `gitlab_rails['geo_node_name']` in
      `/etc/gitlab/gitlab.rb`. These values must always match **exactly**, character
      for character.
   1. In **External URL**, enter the value for `external_url` in `/etc/gitlab/gitlab.rb`. These
      values must always match, but it doesn't matter if one ends with a `/` and
      the other doesn't.
   1. Optional. In **Internal URL (optional)**, enter an internal URL for the secondary site.
   1. Optional. Select which groups or storage shards should be replicated by the
      **secondary** site. Leave blank to replicate all. For more information, see
      [selective synchronization](selective_synchronization.md).
   1. Select **Save changes** to add the **secondary** site.
1. SSH into **each Rails, and Sidekiq node on your secondary** site and restart the services:

   ```shell
   gitlab-ctl restart
   ```

   Check if there are any common issues with your Geo setup by running:

   ```shell
   gitlab-rake gitlab:geo:check
   ```

   If any of the checks fail, check the [troubleshooting documentation](troubleshooting/_index.md).

1. SSH into a **Rails or Sidekiq server on your primary** site and login as root to verify the
   **secondary** site is reachable or there are any common issues with your Geo setup:

   ```shell
   gitlab-rake gitlab:geo:check
   ```

   If any of the checks fail, check the [troubleshooting documentation](troubleshooting/_index.md).

After the **secondary** site is added to the Geo administration page and restarted,
the site automatically starts replicating missing data from the **primary** site
in a process known as **backfill**.
Meanwhile, the **primary** site starts to notify each **secondary** site of any changes, so
that the **secondary** site can act on those notifications immediately.

Be sure the _secondary_ site is running and accessible. You can sign in to the
_secondary_ site with the same credentials as were used with the _primary_ site.

## Step 4. (Optional) Using custom certificates

You can safely skip this step if:

- Your **primary** site uses a public CA-issued HTTPS certificate.
- Your **primary** site only connects to external services with CA-issued (not self-signed) HTTPS certificates.

### Custom or self-signed certificate for inbound connections

If your GitLab Geo **primary** site uses a custom or [self-signed certificate to secure inbound HTTPS connections](https://docs.gitlab.com/omnibus/settings/ssl/index.html#install-custom-public-certificates), this can be either a single-domain or multi-domain certificate.

Install the correct certificate based on your certificate type:

- **Multi-domain certificate** that includes both primary and secondary site domains: Install the certificate at `/etc/gitlab/ssl` on all **Rails, Sidekiq, and Gitaly** nodes in the **secondary** site.
- **Single-domain certificate** where the certificates are specific to each Geo site domain: Generate a valid certificate for your **secondary** site's domain and install it at `/etc/gitlab/ssl` following [these instructions](https://docs.gitlab.com/omnibus/settings/ssl/index.html#install-custom-public-certificates) on all **Rails, Sidekiq, and Gitaly** nodes in the **secondary** site.

### Connecting to external services that use custom certificates

A copy of the self-signed certificate for the external service needs to be added to the trust store on all the **primary** site's nodes that require access to the service.

For the **secondary** site to be able to access the same external services, these certificates *must* be added to the **secondary** site's trust store.

If your **primary** site is using a [custom or self-signed certificate for inbound HTTPS connections](#custom-or-self-signed-certificate-for-inbound-connections), the **primary** site's certificate needs to be added to the **secondary** site's trust store:

1. SSH into each **Rails, Sidekiq, and Gitaly node on your secondary** site and login as root:

   ```shell
   sudo -i
   ```

1. Copy the trusted certs from the **primary** site:

   If you can access one of the nodes on your **primary** site serving SSH traffic using the root user:

   ```shell
   scp root@<primary_site_node_fqdn>:/etc/gitlab/trusted-certs/* /etc/gitlab/trusted-certs
   ```

   If you only have access through a user with sudo privileges:

   ```shell
   # Run this from the node on your primary site:
   sudo tar --transform 's/.*\///g' -zcvf ~/geo-trusted-certs.tar.gz /etc/gitlab/trusted-certs/*

   # Run this on each node on your secondary site:
   scp <user_with_sudo>@<primary_site_node_fqdn>:geo-trusted-certs.tar.gz .
   tar zxvf ~/geo-trusted-certs.tar.gz -C /etc/gitlab/trusted-certs
   ```

1. Reconfigure each updated **Rails, Sidekiq, and Gitaly node in your secondary** site:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## Step 5. Enable Git access over HTTP/HTTPS and SSH

Geo synchronizes repositories over HTTP/HTTPS, and therefore requires this clone
method to be enabled. This is enabled by default, but if converting an existing site to Geo it should be checked:

On the **primary** site:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > General**.
1. Expand **Visibility and access controls**.
1. If using Git over SSH, then:
   1. Ensure "Enabled Git access protocols" is set to "Both SSH and HTTP(S)".
   1. Follow the steps to configure
      [fast lookup of authorized SSH keys in the database](../../operations/fast_ssh_key_lookup.md) on
      **all primary and secondary** sites.
1. If not using Git over SSH, then set "Enabled Git access protocols" to "Only HTTP(S)".

## Step 6. Verify proper functioning of the **secondary** site

You can sign in to the **secondary** site with the same credentials you used with
the **primary** site. After you sign in:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Geo > Sites**.
1. Verify that it's correctly identified as a **secondary** Geo site, and that
   Geo is enabled.

The initial replication may take some time. The status of the site or the 'backfill' may still in progress. You
can monitor the synchronization process on each Geo site from the **primary**
site's **Geo Sites** dashboard in your browser.

![Geo dashboard of secondary site](img/geo_dashboard_v14_0.png)

If your installation isn't working properly, check the
[troubleshooting document](troubleshooting/_index.md).

The two most obvious issues that can become apparent in the dashboard are:

1. Database replication not working well.
1. Instance to instance notification not working. In that case, it can be
   something of the following:
   - You are using a custom certificate or custom CA (see the [troubleshooting document](troubleshooting/_index.md)).
   - The instance is firewalled (check your firewall rules).

Disabling a **secondary** site stops the synchronization process.

If repository storages are customized on the **primary** site for multiple
repository shards you must duplicate the same configuration on each **secondary** site.

Point your users to the [Using a Geo Site guide](usage.md).

Currently, this is what is synced:

- Git repositories.
- Wikis.
- LFS objects.
- Issues, merge requests, snippets, and comment attachments.
- Users, groups, and project avatars.

## Troubleshooting

See the [troubleshooting document](troubleshooting/_index.md).
