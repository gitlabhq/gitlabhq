---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: 'Learn how to spin up a pre-configured GitLab VM on Microsoft Azure.'
title: Install GitLab on Microsoft Azure
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

For users of the Microsoft Azure business cloud, GitLab has a pre-configured offering in
the [Azure Marketplace](https://azuremarketplace.microsoft.com/en-us/marketplace/).
This tutorial describes installing GitLab
Enterprise Edition in a single Virtual Machine (VM).

## Prerequisite

You need an account on Azure. Use of the following methods to obtain an account:

- If you or your company already have an account with a subscription, use that account.
  If not, you can [create a free account](https://azure.microsoft.com/en-us/free/), which grants you a $200 credit to explore Azure for 30 days. For more information, see [Azure free account](https://azure.microsoft.com/en-us/pricing/offers/ms-azr-0044p/).
- If you have an MSDN subscription, you can activate your Azure subscriber benefits. Your MSDN
  subscription gives you recurring Azure credits every month, so you can use
  those credits and try out GitLab.

## Deploy and configure GitLab

Because GitLab is already installed in a pre-configured image, all you have to do is
create a new VM:

1. [Visit the GitLab offering in the marketplace](https://azuremarketplace.microsoft.com/en-us/marketplace/apps/gitlabinc1586447921813.gitlabee?tab=Overview)
1. Select **Get it now** and the **Create this app in Azure** window opens.
   Select **Continue**.
1. Select one of the following options from the Azure portal:
   - Select **Create** to create a VM from scratch.
   - Select **Start with a pre-set configuration** to get started with some
     pre-configured options. You can modify these configurations at any time.

For the sake of this guide, let's create the VM from scratch, so
select **Create**.

NOTE:
Be aware that Azure incurs compute charges whenever your VM is
active (known as "allocated"), even if you're using free trial
credits.
[how to properly shutdown an Azure VM to save money](https://build5nines.com/properly-shutdown-azure-vm-to-save-money/).
See the [Azure pricing calculator](https://azure.microsoft.com/en-us/pricing/calculator/)
to learn how much resources can cost.

After you create the virtual machine, use the information in the following
sections to configure it.

### Configure the Basics tab

The first items you need to configure are the basic settings of the underlying virtual machine:

1. Select the subscription model and a resource group (create a new one if it
   doesn't exist).
1. Enter a name for the VM, for example `GitLab`.
1. Select a region.
1. In **Availability options**, select **Availability zone** and set it to `1`.
   Read more about the [availability zones](https://learn.microsoft.com/en-us/azure/virtual-machines/availability).
1. Ensure the selected image is set to **GitLab - Gen1**.
1. Select the VM size based on the [hardware requirements](../requirements.md).
   Because the minimum system requirements to run a GitLab environment for up to 500 users
   is covered by the `D4s_v3` size, select that option.
1. Set the authentication type to **SSH public key**.
1. Enter a user name or leave the one that is automatically created. This is
   the user Azure uses to connect to the VM through SSH. By default, the user
   has root access.
1. Determine if you want to provide your own SSH key or let Azure create one for you.
   For more information about how to set up SSH
   public keys, see [SSH](../../user/ssh.md).

Review your entered settings, and then proceed to the Disks tab.

### Configure the Disks tab

For the disks:

1. For the OS disk type, select **Premium SSD**.
1. Select the default encryption.

[Read more about the types of disks](https://learn.microsoft.com/en-us/azure/virtual-machines/managed-disks-overview) that Azure provides.

Review your settings, and then proceed to the Networking tab.

### Configure the Networking tab

Use this tab to define the network connectivity for your
virtual machine, by configuring network interface card (NIC) settings.
You can leave them at their default settings.

Azure creates a security group by default and the VM is assigned to it.
The GitLab image in the marketplace has the following ports open by default:

| Port | Description |
|------|-------------|
| 80   | Enable the VM to respond to HTTP requests, allowing public access. |
| 443  | Enable our VM to respond to HTTPS requests, allowing public access. |
| 22   | Enable our VM to respond to SSH connection requests, allowing public access (with authentication) to remote terminal sessions. |

If you want to change the ports or add any rules, you can do it
after the VM is created by selecting Networking settings in the left sidebar,
while in the VM dashboard.

### Configure the Management tab

Use this tab to configure monitoring and management options
for your VM. You don't need to change the default settings.

### Configure the Advanced tab

Use this tab to add additional configuration, agents, scripts
or applications through virtual machine extensions or `cloud-init`. You don't
need to change the default settings.

### Configure the Tags tab

Use this tab to add name/value pairs that enable you to categorize
resources. You don't need to change the default settings.

### Review and create the VM

The final tab presents you with all of your selected options,
where you can review and modify your choices from the
previous steps. Azure runs validation tests in the background,
and if you provided all of the required settings, you can
create the VM.

After you select **Create**, if you had opted for Azure to create an SSH key pair
for you, a prompt appears to download the private SSH key. Download the key, as it's
needed to SSH into the VM.

After you download the key, the deployment begins.

### Finish deployment

At this point, Azure begins to deploy your new VM. The deployment process
takes a few minutes to complete. After it's complete, the new VM and its
associated resources are displayed on the Azure Dashboard.
Select **Go to resource** to visit the dashboard of the VM.

GitLab is now deployed and ready to be used. Before doing so, however,
you need to set up the domain name and configure GitLab to use it.

### Set up a domain name

The VM has a public IP address (static by default), but Azure allows you
to assign a descriptive DNS name to the VM:

1. From the VM dashboard, select **Configure** under **DNS name**.
1. Enter a descriptive DNS name for your instance in the **DNS name label** field,
   for example `gitlab-prod`. This makes the VM accessible at
   `gitlab-prod.eastus.cloudapp.azure.com`.
1. Select **Save**.

Eventually, most users want to use their own domain name. For you to do this, you need to add a DNS `A` record
with your domain registrar that points to the public IP address of your Azure VM.
You can use the [Azure DNS](https://learn.microsoft.com/en-us/azure/dns/dns-delegate-domain-azure-dns)
or some [other registrar](https://docs.gitlab.com/omnibus/settings/dns.html).

### Change the GitLab external URL

GitLab uses `external_url` in its configuration file to set up the domain name.
If you don't set this up, when you visit the Azure friendly name, the browser will
redirect you to the public IP.

To set up the GitLab external URL:

1. Connect to GitLab through SSH by going to **Settings > Connect** from the VM
   dashboard, and follow the instructions. Remember to sign in with the username
   and SSH key you specified when you [created the VM](#configure-the-basics-tab).
   The Azure VM domain name is the one you
   [set up previously](#set-up-a-domain-name). If you didn't set up a domain name for
   your VM, you can use the IP address in its place.

   In the case of our example:

   ```shell
   ssh -i <private key path> gitlab-azure@gitlab-prod.eastus.cloudapp.azure.com
   ```

   NOTE:
   If you need to reset your credentials, read
   [how to reset SSH credentials for a user on an Azure VM](https://learn.microsoft.com/en-us/troubleshoot/azure/virtual-machines/linux/troubleshoot-ssh-connection#reset-ssh-credentials-for-a-user).

1. Open `/etc/gitlab/gitlab.rb` with your editor.
1. Find `external_url` and replace it with your own domain name. For the sake
   of this example, use the default domain name Azure sets up.
   Using `https` in the URL
   [automatically enables](https://docs.gitlab.com/omnibus/settings/ssl/index.html#lets-encrypt-integration),
   Let's Encrypt, and sets HTTPS by default:

   ```ruby
   external_url 'https://gitlab-prod.eastus.cloudapp.azure.com'
   ```

1. Find the following settings and comment them out, so that GitLab doesn't
   pick up the wrong certificates:

   ```ruby
   # nginx['redirect_http_to_https'] = true
   # nginx['ssl_certificate'] = "/etc/gitlab/ssl/server.crt"
   # nginx['ssl_certificate_key'] = "/etc/gitlab/ssl/server.key"
   ```

1. Reconfigure GitLab for the changes to take effect. Run the
   following command every time you make changes to `/etc/gitlab/gitlab.rb`:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. To prevent the domain name from
   [resetting after a reboot](https://docs.bitnami.com/aws/apps/gitlab/configuration/change-default-address/),
   rename the utility that Bitnami uses:

   ```shell
   sudo mv /opt/bitnami/apps/gitlab/bnconfig /opt/bitnami/apps/gitlab/bnconfig.bak
   ```

You can now visit GitLab with your browser at the new external URL.

### Visit GitLab for the first time

Use the domain name you set up earlier to visit your new GitLab instance
in your browser. In this example, it's `https://gitlab-prod.eastus.cloudapp.azure.com`.

The first thing that appears is the sign-in page. GitLab creates an administrator user by default.
The credentials are:

- Username: `root`
- Password: the password is automatically created, and there are
  [two ways to find it](https://docs.bitnami.com/azure/faq/get-started/find-credentials/).

After signing in, be sure to immediately [change the password](../../user/profile/user_passwords.md#change-your-password).

## Maintain your GitLab instance

It's important to keep your GitLab environment up-to-date. The GitLab team is constantly making
enhancements and occasionally you may need to update for security reasons. Use the information
in this section whenever you need to update GitLab.

### Check the current version

To determine the version of GitLab you're currently running:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Overview > Dashboard**.
1. Find the version under the **Components** table.

If there's a newer available version of GitLab that contains one or more
security fixes, GitLab displays an **Update asap** notification message that
encourages you to [update](#update-gitlab).

### Update GitLab

To update GitLab to the latest version:

1. Connect to the VM through SSH.
1. Update GitLab:

   ```shell
   sudo apt update
   sudo apt install gitlab-ee
   ```

   This command updates GitLab and its associated components to the latest versions,
   and can take time to complete. During this time, the terminal shows various update tasks being
   completed in your terminal.

   NOTE:
   If you get an error like
   `E: The repository 'https://packages.gitlab.com/gitlab/gitlab-ee/debian buster InRelease' is not signed.`,
   see the [troubleshooting section](#update-the-gpg-key-for-the-gitlab-repositories).

1. After the update process is complete, a message like the
   following appears:

   ```plaintext
   Upgrade complete! If your GitLab server is misbehaving try running

      sudo gitlab-ctl restart

   before anything else.
   ```

Refresh your GitLab instance in the browser and go to the **Admin** area. You should now have an
up-to-date GitLab instance.

## Next steps and further configuration

Now that you have a functional GitLab instance, follow the
[next steps](../next_steps.md) to learn what more you can do with your
new installation.

## Troubleshooting

This section describes common errors you can encounter.

### Update the GPG key for the GitLab repositories

NOTE:
This is a temporary fix until the GitLab image is updated with the new
GPG key.

The pre-configured GitLab image in Azure (provided by Bitnami) uses
a GPG key [deprecated in April 2020](https://about.gitlab.com/blog/2020/03/30/gpg-key-for-gitlab-package-repositories-metadata-changing/).

If you try to update the repositories, the system returns the following error:

```plaintext
[   21.023494] apt-setup[1198]: W: GPG error: https://packages.gitlab.com/gitlab/gitlab-ee/debian buster InRelease: The following signatures couldn't be verified because the public key is not available: NO_PUBKEY 3F01618A51312F3F
[   21.024033] apt-setup[1198]: E: The repository 'https://packages.gitlab.com/gitlab/gitlab-ee/debian buster InRelease' is not signed.
```

To fix this, fetch the new GPG key:

```shell
sudo apt install gpg-agent
curl "https://gitlab-org.gitlab.io/omnibus-gitlab/gitlab_new_gpg.key" \
     --output /tmp/omnibus_gitlab_gpg.key
sudo apt-key add /tmp/omnibus_gitlab_gpg.key
```

You can now [update GitLab](#update-gitlab). For more information, read about the
[packages signatures](https://docs.gitlab.com/omnibus/update/package_signatures.html).
