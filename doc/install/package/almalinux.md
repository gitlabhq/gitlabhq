---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Install the Linux package on AlmaLinux and RHEL-compatible distributions
title: Install the Linux package on AlmaLinux and RHEL-compatible distributions
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

{{< alert type="note" >}}

See [supported platforms](_index.md#supported-platforms) for the full list of
supported distributions and architectures.

{{< /alert >}}

## Prerequisites

- OS requirements:
  - AlmaLinux 8
  - AlmaLinux 9
  - AlmaLinux 10
  - Red Hat Enterprise Linux 8
  - Red Hat Enterprise Linux 9
  - Red Hat Enterprise Linux 10
  - Oracle Linux 8
  - Oracle Linux 9
  - Oracle Linux 10
  - Any distribution compatible with a supported Red Hat Enterprise Linux version
- See the [installation requirements](../requirements.md) to learn about the
  minimum hardware requirements.
- Before you begin, make sure you have correctly
  [set up your DNS](https://docs.gitlab.com/omnibus/settings/dns).
  Replace `https://gitlab.example.com` in the following commands with your
  preferred GitLab URL. GitLab is automatically configured and started at that address.
- For `https://` URLs, GitLab automatically
  [requests a certificate with Let's Encrypt](https://docs.gitlab.com/omnibus/settings/ssl/#enable-the-lets-encrypt-integration),
  which requires inbound HTTP access and a valid hostname. You can also use
  [your own certificate](https://docs.gitlab.com/omnibus/settings/ssl/#configure-https-manually),
  or just use `http://` (without the `s`) for an unencrypted URL.

## Enable SSH and open firewall ports

To open the needed firewall ports (80, 443, 22) and be able to access GitLab:

1. Enable and start the OpenSSH server daemon:

   ```shell
   sudo systemctl enable --now sshd
   ```

1. With `firewalld` installed, open the firewall ports:

   ```shell
   sudo firewall-cmd --permanent --add-service=http
   sudo firewall-cmd --permanent --add-service=https
   sudo firewall-cmd --permanent --add-service=ssh
   sudo systemctl reload firewalld
   ```

## Add the GitLab package repository

To install GitLab, first add the GitLab package repository.

1. Install the needed packages:

   ```shell
   sudo dnf install -y curl
   ```

1. Use the following script to add the GitLab repository (you can paste the
   script's URL to your browser to see what it does before piping it to
   `bash`):

   {{< tabs >}}

   {{< tab title="Enterprise Edition" >}}

   ```shell
   curl "https://packages.gitlab.com/install/repositories/gitlab/gitlab-ee/script.rpm.sh" | sudo bash
   ```

   {{< /tab >}}

   {{< tab title="Community Edition" >}}

   ```shell
   curl "https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.rpm.sh" | sudo bash
   ```

   {{< /tab >}}

   {{< /tabs >}}

## Install the package

Install GitLab using your system's package manager.

{{< alert type="note" >}}

Setting the `EXTERNAL_URL` is optional but recommended.
If you don't set it during the installation, you can
[set it afterwards](https://docs.gitlab.com/omnibus/settings/configuration/#configure-the-external-url-for-gitlab).

{{< /alert >}}

{{< tabs >}}

{{< tab title="Enterprise Edition" >}}

```shell
sudo EXTERNAL_URL="https://gitlab.example.com" dnf install gitlab-ee
```

{{< /tab >}}

{{< tab title="Community Edition" >}}

```shell
sudo EXTERNAL_URL="https://gitlab.example.com" dnf install gitlab-ce
```

{{< /tab >}}

{{< /tabs >}}

GitLab generates a random password and email address for the root
administrator account stored in `/etc/gitlab/initial_root_password` for 24 hours.
After 24 hours, this file is automatically removed for security reasons.

## Initial sign-in

After GitLab is installed, go to the URL you set up
and use the following credentials to sign in:

- Username: `root`
- Password: See `/etc/gitlab/initial_root_password`

After signing in, change your [password](../../user/profile/user_passwords.md#change-your-password)
and [email address](../../user/profile/_index.md#add-emails-to-your-user-profile).

## Advanced configuration

You can customize your GitLab installation by setting the following optional
environment variables before installation. **These variables only work during the first
installation** and have no effect on subsequent reconfigure runs. For existing
installations, use the password from `/etc/gitlab/initial_root_password` or
[reset the root password](../../security/reset_user_password.md).

| Variable | Purpose | Required | Example |
|----------|---------|----------|---------|
| `EXTERNAL_URL` | Sets the external URL for your GitLab instance | Recommended | `EXTERNAL_URL="https://gitlab.example.com"` |
| `GITLAB_ROOT_EMAIL` | Custom email for the root administrator account | Optional | `GITLAB_ROOT_EMAIL="admin@example.com"` |
| `GITLAB_ROOT_PASSWORD` | Custom password (8 characters minimum) for the root administrator account | Optional | `GITLAB_ROOT_PASSWORD="strongpassword"` |

{{< alert type="note" >}}
If GitLab can't detect a valid hostname during installation, reconfigure won't run automatically. In this case, pass any needed environment variables to your first `gitlab-ctl reconfigure` command.
{{< /alert >}}

{{< alert type="warning" >}}

While you can also set the initial password in `/etc/gitlab/gitlab.rb` by setting
`gitlab_rails['initial_root_password']`, it is not recommended.
It's a security risk as the password is in clear text. If you have this configured,
make sure to remove it after installation.

{{< /alert >}}

Choose your GitLab edition and customize with the environment variables above:

{{< tabs >}}

{{< tab title="Enterprise Edition" >}}

```shell
sudo GITLAB_ROOT_EMAIL="admin@example.com" GITLAB_ROOT_PASSWORD="strongpassword" EXTERNAL_URL="https://gitlab.example.com" dnf install gitlab-ee
```

{{< /tab >}}

{{< tab title="Community Edition" >}}

```shell
sudo GITLAB_ROOT_EMAIL="admin@example.com" GITLAB_ROOT_PASSWORD="strongpassword" EXTERNAL_URL="https://gitlab.example.com" dnf install gitlab-ce
```

{{< /tab >}}

{{< /tabs >}}

## Set up your communication preferences

Visit our [email subscription preference center](https://about.gitlab.com/company/preference-center/)
to let us know when to communicate with you. We have an explicit email opt-in
policy so you have complete control over what and how often we send you emails.

Twice a month, we send out the GitLab news you need to know, including new
features, integrations, documentation, and behind the scenes stories from our development teams.
For critical security updates related to bugs and system performance, sign up
for our dedicated security newsletter.

{{< alert type="note" >}}

If you do not opt-in to the security newsletter, you will not receive security alerts.

{{< /alert >}}

## Recommended next steps

After completing your installation, consider the
[recommended next steps, including authentication options and sign-up restrictions](../next_steps.md).
