---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Install the Linux package on Amazon Linux 2
title: Install the Linux package on Amazon Linux 2
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

{{< alert type="note" >}}

See [supported platforms](_index.md#supported-platforms) for a full list of
supported distributions and architectures.

{{< /alert >}}

## Prerequisites

- OS requirements:
  - Amazon Linux 2
- See the [installation requirements](../requirements.md) to learn about the
  minimum hardware requirements.
- Before you begin, make sure you have correctly
  [set up your DNS](https://docs.gitlab.com/omnibus/settings/dns),
  and change `https://gitlab.example.com` to the URL at which you want to access
  your GitLab instance. The installation automatically configures and starts
  GitLab at that URL.
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
   sudo yum install -y curl
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

Install GitLab using your system's package manager. You can customize the
initial setup by configuring environment variables before installation.

If you don't customize the root credentials during installation:

- GitLab generates a random password and email address for the root
  administrator account.
- The password is stored in `/etc/gitlab/initial_root_password` for 24 hours.
- After 24 hours, this file is automatically removed for security reasons.

{{< alert type="note" >}}
While you can also set the initial password in `/etc/gitlab/gitlab.rb` by setting
`gitlab_rails['initial_root_password'] = "password"`, it is not recommended. If
you do set the password with this method, be sure to remove the password from
`/etc/gitlab/gitlab.rb` as it only gets read with the first reconfigure after
the package is installed.
{{< /alert >}}

### Available environment variables

You can customize your GitLab installation by setting the following optional
environment variables. **These variables only work during the first
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

### Installation commands

Choose your GitLab edition and customize with the environment variables above:

{{< tabs >}}

{{< tab title="Enterprise Edition" >}}

**Basic installation:**

```shell
sudo EXTERNAL_URL="https://gitlab.example.com" yum install gitlab-ee
```

**With custom root credentials:**

```shell
sudo GITLAB_ROOT_EMAIL="admin@example.com" GITLAB_ROOT_PASSWORD="strongpassword" EXTERNAL_URL="https://gitlab.example.com" yum install gitlab-ee
```

{{< /tab >}}

{{< tab title="Community Edition" >}}

**Basic installation:**

```shell
sudo EXTERNAL_URL="https://gitlab.example.com" yum install gitlab-ce
```

**With custom root credentials:**

```shell
sudo GITLAB_ROOT_EMAIL="admin@example.com" GITLAB_ROOT_PASSWORD="strongpassword" EXTERNAL_URL="https://gitlab.example.com" yum install gitlab-ce
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
