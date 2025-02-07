---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 'Tutorial: Install and secure a single node GitLab instance'
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

In this tutorial you will learn how to install and securely configure a single
node GitLab instance that can accommodate up to
[20 RPS or 1,000 users](../../administration/reference_architectures/1k_users.md).

To install a single node GitLab instance and configure it to be secure:

1. [Secure the server](#secure-the-server)
1. [Install GitLab](#install-gitlab)
1. [Configure GitLab](#configure-gitlab)
1. [Next steps](#next-steps)

## Before you begin

- A domain name, and a correct [setup of DNS](https://docs.gitlab.com/omnibus/settings/dns.html).
- A Debian-based server with the following minimum specs:
  - 8 vCPU
  - 7.2 GB memory
  - Enough hard drive space for all your repositories.
    Read more about the
    [storage requirements](../../install/requirements.md).

## Secure the server

Before installing GitLab, start by configuring your server to be a bit more secure.

### Configure the firewall

You need to open ports 22 (SSH), 80 (HTTP), and 443 (HTTPS). You can do this by
either using your cloud provider's console, or at the server level.

In this example, you'll configure the firewall using [`ufw`](https://wiki.ubuntu.com/UncomplicatedFirewall).
You'll deny access to all ports, allow ports 80 and 443, and finally, rate limit access to port 22.
`ufw` can deny connections from an IP address that has attempted to initiate 6 or more
connections in the last 30 seconds.

1. Install `ufw`:

   ```shell
   sudo apt install ufw
   ```

1. Enable and start the `ufw` service:

   ```shell
   sudo systemctl enable --now ufw
   ```

1. Deny all other ports except the required ones:

   ```shell
   sudo ufw default deny
   sudo ufw allow http
   sudo ufw allow https
   sudo ufw limit ssh/tcp
   ```

1. Finally, activate the settings. The following needs to run only once, the first time
   you install the package. Answer yes (`y`) when prompted:

   ```shell
   sudo ufw enable
   ```

1. Verify that the rules are present:

   ```shell
   $ sudo ufw status

   Status: active

   To                         Action      From
   --                         ------      ----
   80/tcp                     ALLOW       Anywhere
   443                        ALLOW       Anywhere
   22/tcp                     LIMIT       Anywhere
   80/tcp (v6)                ALLOW       Anywhere (v6)
   443 (v6)                   ALLOW       Anywhere (v6)
   22/tcp (v6)                LIMIT       Anywhere (v6)
   ```

### Configure the SSH server

To further secure your server, configure SSH to accept public key authentication,
and disable some features that are potential security risks.

1. Open `/etc/ssh/sshd_config` with your editor and make sure the following are present:

   ```plaintext
   PubkeyAuthentication yes
   PasswordAuthentication yes
   UsePAM yes
   UseDNS no
   AllowTcpForwarding no
   X11Forwarding no
   PrintMotd no
   PermitTunnel no
   # Allow client to pass locale environment variables
   AcceptEnv LANG LC_*
   # override default of no subsystems
   Subsystem       sftp    /usr/lib/openssh/sftp-server
   # Protocol adjustments, these would be needed/recommended in a FIPS or
   # FedRAMP deployment, and use only strong and proven algorithm choices
   Protocol 2
   Ciphers aes128-ctr,aes192-ctr,aes256-ctr
   HostKeyAlgorithms ecdsa-sha2-nistp256,ecdsa-sha2-nistp384,ecdsa-sha2-nistp521
   KexAlgorithms ecdh-sha2-nistp256,ecdh-sha2-nistp384,ecdh-sha2-nistp521
   Macs hmac-sha2-256,hmac-sha2-512
   ```

1. Save the file and restart the SSH server:

   ```shell
   sudo systemctl restart ssh
   ```

   If restarting SSH fails, check that you don't have any
   duplicate entries in `/etc/ssh/sshd_config`.

### Ensure only authorized users are using SSH for Git access

Next, ensure that users cannot pull down projects using SSH unless they have a
valid GitLab account that can perform Git operations over SSH.

To ensure that only authorized users are using SSH for Git access:

1. Add the following to your `/etc/ssh/sshd_config` file:

   ```plaintext
   # Ensure only authorized users are using Git
   AcceptEnv GIT_PROTOCOL
   ```

1. Save the file and restart the SSH server:

   ```shell
   sudo systemctl restart ssh
   ```

### Make some kernel adjustments

Kernel adjustments do not completely eliminate the threat of an attack, but
they add an extra layer of security.

1. Open a new file with your editor under `/etc/sysctl.d`, for example
   `/etc/sysctl.d/99-gitlab-hardening.conf`, and add the following.

   NOTE:
   The naming and source directory decide the order of processing, which is
   important because the last parameter processed might override earlier ones.

   ```plaintext
   ##
   ## The following help mitigate out of bounds, null pointer dereference, heap and
   ## buffer overflow bugs, use-after-free etc from being exploited. It does not 100%
   ## fix the issues, but seriously hampers exploitation.
   ##
   # Default is 65536, 4096 helps mitigate memory issues used in exploitation
   vm.mmap_min_addr=4096
   # Default is 0, randomize virtual address space in memory, makes vuln exploitation
   # harder
   kernel.randomize_va_space=2
   # Restrict kernel pointer access (for example, cat /proc/kallsyms) for exploit assistance
   kernel.kptr_restrict=2
   # Restrict verbose kernel errors in dmesg
   kernel.dmesg_restrict=1
   # Restrict eBPF
   kernel.unprivileged_bpf_disabled=1
   net.core.bpf_jit_harden=2
   # Prevent common use-after-free exploits
   vm.unprivileged_userfaultfd=0

   ## Networking tweaks ##
   ##
   ## Prevent common attacks at the IP stack layer
   ##
   # Prevent SYNFLOOD denial of service attacks
   net.ipv4.tcp_syncookies=1
   # Prevent time wait assassination attacks
   net.ipv4.tcp_rfc1337=1
   # IP spoofing/source routing protection
   net.ipv4.conf.all.rp_filter=1
   net.ipv4.conf.default.rp_filter=1
   net.ipv6.conf.all.accept_ra=0
   net.ipv6.conf.default.accept_ra=0
   net.ipv4.conf.all.accept_source_route=0
   net.ipv4.conf.default.accept_source_route=0
   net.ipv6.conf.all.accept_source_route=0
   net.ipv6.conf.default.accept_source_route=0
   # IP redirection protection
   net.ipv4.conf.all.accept_redirects=0
   net.ipv4.conf.default.accept_redirects=0
   net.ipv4.conf.all.secure_redirects=0
   net.ipv4.conf.default.secure_redirects=0
   net.ipv6.conf.all.accept_redirects=0
   net.ipv6.conf.default.accept_redirects=0
   net.ipv4.conf.all.send_redirects=0
   net.ipv4.conf.default.send_redirects=0
   ```

1. On the next server reboot, the values will be loaded automatically. To load
   them immediately:

   ```shell
   sudo sysctl --system
   ```

Great work, you've completed the steps to secure your server!
Now you're ready to install GitLab.

## Install GitLab

Now that your server is set up, install GitLab:

1. Install and configure the necessary dependencies:

   ```shell
   sudo apt update
   sudo apt install -y curl openssh-server ca-certificates perl locales
   ```

1. Configure the system language:

   1. Edit `/etc/locale.gen` and make sure `en_US.UTF-8` is uncommented.
   1. Regenerate the languages:

      ```shell
      sudo locale-gen
      ```

1. Add the GitLab package repository and install the package:

   ```shell
   curl "https://packages.gitlab.com/install/repositories/gitlab/gitlab-ee/script.deb.sh" | sudo bash
   ```

   To see the contents of the script, visit <https://packages.gitlab.com/gitlab/gitlab-ee/install>.

1. Install the GitLab package. Provide a strong password with
   `GITLAB_ROOT_PASSWORD` and replace the `EXTERNAL_URL`
   with your own. Don't forget to include `https` in the URL, so that a Let's Encrypt
   certificate is issued.

   ```shell
   sudo GITLAB_ROOT_PASSWORD="strong password" EXTERNAL_URL="https://gitlab.example.com" apt install gitlab-ee
   ```

   To learn more about the Let's Encrypt certificate or even
   use your own, read how to [configure GitLab with TLS](https://docs.gitlab.com/omnibus/settings/ssl/).

   If the password you set wasn't picked up, read more about
   [resetting the root account password](../../security/reset_user_password.md#reset-the-root-password).

1. After a few minutes, GitLab is installed. Sign in
   using the URL you set up in `EXTERNAL_URL`. Use `root` as the username and
   the password you set up in `GITLAB_ROOT_PASSWORD`.

Now it's time to configure GitLab!

## Configure GitLab

GitLab comes with some sane default configuration options. In this section,
we will change them to add more functionality, and make GitLab more secure.

For some of the options you'll use the **Admin** area UI, and for some of them you'll
edit `/etc/gitlab/gitlab.rb`, the GitLab configuration file.

### Configure NGINX

NGINX is used to serve up the web interface used to access the GitLab instance.
For more information about configuring NGINX to be more secure, read about
[hardening NGINX](../../security/hardening_configuration_recommendations.md#nginx).

### Configure emails

Next, you'll set up and configure an email service. Emails are important for
verifying new sign ups, resetting passwords, and notifying
you of GitLab activity.

#### Configure SMTP

In this tutorial, you'll set up an [SMTP](https://docs.gitlab.com/omnibus/settings/smtp.html)
server and use the [Mailgun](https://www.mailgun.com/) SMTP provider.

First, start by creating an encrypted file that will contain the login
credentials, and then configure SMTP for the Linux package:

1. Create a YAML file (for example `smtp.yaml`) that contains the credentials
   for the SMTP server.

   Your SMTP password must not contain any string delimiters used in
   Ruby or YAML (for example, `'`) to avoid unexpected behavior during the
   processing of configuration settings.

   ```shell
   user_name: '<SMTP user>'
   password: '<SMTP password>'
   ```

1. Encrypt the file:

   ```shell
   cat smtp.yaml | sudo gitlab-rake gitlab:smtp:secret:write
   ```

   By default, the encrypted file is stored under
   `/var/opt/gitlab/gitlab-rails/shared/encrypted_configuration/smtp.yaml.enc`.

1. Remove the YAML file:

   ```shell
   rm -f smtp.yaml
   ```

1. Edit `/etc/gitlab/gitlab.rb` and set up the rest of the SMTP settings.
   Make sure `gitlab_rails['smtp_user_name']` and `gitlab_rails['smtp_password']`
   are **not** present, as we've already set them up as encrypted.

   ```ruby
   gitlab_rails['smtp_enable'] = true
   gitlab_rails['smtp_address'] = "smtp.mailgun.org" # or smtp.eu.mailgun.org
   gitlab_rails['smtp_port'] = 587
   gitlab_rails['smtp_authentication'] = "plain"
   gitlab_rails['smtp_enable_starttls_auto'] = true
   gitlab_rails['smtp_domain'] = "<mailgun domain>"
   ```

1. Save the file and reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

You should now be able to send emails. To test that the configuration worked:

1. Enter the Rails console:

   ```shell
   sudo gitlab-rails console
   ```

1. Run the following command at the console prompt to make GitLab send a test email:

   ```ruby
   Notify.test_email('<email_address>', 'Message Subject', 'Message Body').deliver_now
   ```

If you're unable to send emails, see the
[SMTP troubleshooting section](https://docs.gitlab.com/omnibus/settings/smtp.html#troubleshooting).

#### Enable the email verification

Account email verification provides an additional layer of GitLab account
security. When some conditions are met, for example, if there are three or more
failed sign-in attempts in 24 hours, an account is locked.

This feature is behind a feature flag. To enable it:

1. Enter the Rails console:

   ```shell
   sudo gitlab-rails console
   ```

1. Enable the feature flag:

   ```ruby
   Feature.enable(:require_email_verification)
   ```

1. Check if it's enabled (should return `true`):

   ```ruby
   Feature.enabled?(:require_email_verification)
   ```

For more information, read about
[account email verification](../../security/email_verification.md).

#### Sign outgoing email with S/MIME

Notification emails sent by GitLab can be signed with
[S/MIME](https://en.wikipedia.org/wiki/S/MIME) for improved security.

A single pair of key and certificate files must be provided:

- Both files must be PEM-encoded.
- The key file must be unencrypted so that GitLab can read it without user intervention.
- Only RSA keys are supported.
- Optional. You can provide a bundle of Certificate Authority (CA) certs
  (PEM-encoded) to include on each signature. This is typically an
  intermediate CA.

1. Buy your certificate from a CA.
1. Edit `/etc/gitlab/gitlab.rb` and adapt the file paths:

   ```ruby
   gitlab_rails['gitlab_email_smime_enabled'] = true
   gitlab_rails['gitlab_email_smime_key_file'] = '/etc/gitlab/ssl/gitlab_smime.key'
   gitlab_rails['gitlab_email_smime_cert_file'] = '/etc/gitlab/ssl/gitlab_smime.crt'
   ```

1. Save the file and reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

For more information, read about
[signing outgoing email with S/MIME](../../administration/smime_signing_email.md).

## Next steps

In this tutorial, you learned how to set up your server to be more secure, how
to install GitLab, and how to configure GitLab to meet some security standards.
Some [other steps](../../security/hardening_application_recommendations.md) you can take to secure GitLab include:

- Disabling sign ups. By default, a new GitLab instance has sign up enabled by default. If you don't
  plan to make your GitLab instance public, you should to disable sign ups.
- Allowing or denying sign ups using specific email domains.
- Setting a minimum password length limit for new users.
- Enforcing two-factor authentication for all users.

There are many other things you can configure apart from hardening your GitLab
instance, like configuring your own runners to leverage the CI/CD features that
GitLab has to offer, or properly backing up your instance.

You can read more about the [steps to take after the installation](../../install/next_steps.md).
