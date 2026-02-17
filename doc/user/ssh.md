---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Use SSH keys with GitLab
description: Use SSH keys for secure authentication and communication with GitLab repositories.
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Use SSH keys to securely authenticate with GitLab without entering your username and password
each time you push or pull code.

To use SSH keys with GitLab, you must:

1. Generate an SSH key pair on your local system.
1. Add your SSH key to your GitLab account.
1. Verify your connection to GitLab.

> [!note]
> For information on advanced SSH key configuration,
> see [advanced SSH key configuration](ssh_advanced.md).

## What are SSH keys

SSH uses two keys, a public key and a private key.

- The public key can be distributed.
- The private key should be protected.

It is not possible to reveal confidential data by uploading your public key. When you need to copy or upload your SSH public key, make sure you do not accidentally copy or upload your private key instead.

You can use your private key to [sign commits](project/repository/signed_commits/ssh.md),
which makes your use of GitLab and your data even more secure.
This signature then can be verified by anyone using your public key.

For details, see [Asymmetric cryptography, also known as public-key cryptography](https://en.wikipedia.org/wiki/Public-key_cryptography).

## Prerequisites

To use SSH to communicate with GitLab, you need:

- The OpenSSH client, which comes pre-installed on GNU/Linux, macOS, and Windows 10.
- SSH version 6.5 or later. Earlier versions used an MD5 signature, which is not secure.

> [!note]
> To view the version of SSH installed on your system, run `ssh -V`.

## Supported SSH key types

{{< history >}}

- Maximum RSA key length [changed](https://gitlab.com/groups/gitlab-org/-/epics/11186) in GitLab 16.3.

{{< /history >}}

To communicate with GitLab, you can use the following SSH key types:

| Algorithm           | Notes |
| ------------------- | ----- |
| ED25519 (preferred) | More secure and performant than RSA keys. Introduced in OpenSSH 6.5 (2014) and available on most operating systems. Might not be fully supported by all FIPS systems. For more information, see [issue 367429](https://gitlab.com/gitlab-org/gitlab/-/issues/367429). |
| ED25519_SK          | Requires OpenSSH 8.2 or later on both your local client and the GitLab server. |
| ECDSA_SK            | Requires OpenSSH 8.2 or later on both your local client and the GitLab server. |
| RSA                 | Less secure than ED25519. If used, GitLab recommends a key size of at least 4096 bits. Maximum key length is 8192 bits due to Go limitations. Default key size depends on your `ssh-keygen` version. |
| ECDSA               | [Security issues](https://leanpub.com/gocrypto/read#leanpub-auto-ecdsa) related to DSA also apply to ECDSA keys. |

## Check for existing SSH key pairs

Before you create a key pair, see if a key pair already exists.

1. Go to your home directory.
1. Go to the `.ssh/` subdirectory. If the `.ssh/` subdirectory doesn't exist,
   you are either not in the home directory, or you haven't used `ssh` before.
   In the latter case, you need to [generate an SSH key pair](#generate-an-ssh-key-pair).
1. See if a file with one of the following formats exists:

   | Algorithm             | Public key | Private key |
   |-----------------------|------------|-------------|
   |  ED25519 (preferred)  | `id_ed25519.pub` | `id_ed25519` |
   |  ED25519_SK           | `id_ed25519_sk.pub` | `id_ed25519_sk` |
   |  ECDSA_SK             | `id_ecdsa_sk.pub` | `id_ecdsa_sk` |
   |  RSA (at least 4096-bit key size) | `id_rsa.pub` | `id_rsa` |
   |  DSA (deprecated)     | `id_dsa.pub` | `id_dsa` |
   |  ECDSA                | `id_ecdsa.pub` | `id_ecdsa` |

## Generate an SSH key pair

If you do not have an existing SSH key pair, generate a new one:

1. Open a terminal.
1. Run `ssh-keygen -t` with the key type and an optional comment to help identify the key later.
   A common option is to use your email address as the comment.
   The comment is included in the `.pub` file.

   For example, for ED25519:

   ```shell
   ssh-keygen -t ed25519 -C "<comment>"
   ```

   For 4096-bit RSA:

   ```shell
   ssh-keygen -t rsa -b 4096 -C "<comment>"
   ```

1. Press <kbd>Enter</kbd>. Output similar to the following is displayed:

   ```plaintext
   Generating public/private ed25519 key pair.
   Enter file in which to save the key (/home/user/.ssh/id_ed25519):
   ```

1. Accept the suggested filename and directory, unless you are generating a [deploy key](project/deploy_keys/_index.md)
   or want to save in a specific directory where you store other keys.

   You can also dedicate the SSH key pair to a [specific host](ssh_advanced.md#use-ssh-keys-in-another-directory).

1. Specify a [passphrase](https://www.ssh.com/academy/ssh/passphrase):

   ```plaintext
   Enter passphrase (empty for no passphrase):
   Enter same passphrase again:
   ```

   A confirmation is displayed, including information about where your files are stored.
   A public and private key are generated.

1. Add the private SSH key to `ssh-agent`.

   For example, for ED25519:

   ```shell
   ssh-add ~/.ssh/id_ed25519
   ```

## Add an SSH key to your GitLab account

{{< history >}}

- Suggested default expiration date for keys [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/271239) in GitLab 15.4.
- Usage types for SSH keys [added](https://gitlab.com/gitlab-org/gitlab/-/issues/383046) in GitLab 15.7.

{{< /history >}}

To use SSH with GitLab, copy your public key to your GitLab account. GitLab cannot
access your private key.

When you add an SSH key, GitLab checks it against a list of known compromised keys.
You cannot add compromised keys because the associated private keys are publicly
known and could be used to access accounts. This restriction cannot be configured.

If your key is blocked, [generate a new SSH key pair](#generate-an-ssh-key-pair).

To add an SSH key to your GitLab account:

1. Copy the contents of your public key file. You can do this manually or use a script.

   In these examples, replace `id_ed25519.pub` with your filename. For example, for RSA, use `id_rsa.pub`.

   {{< tabs >}}

   {{< tab title="macOS" >}}

   ```shell
   tr -d '\n' < ~/.ssh/id_ed25519.pub | pbcopy
   ```

   {{< /tab >}}

   {{< tab title="Linux (requires the xclip package)" >}}

   ```shell
   xclip -sel clip < ~/.ssh/id_ed25519.pub
   ```

   {{< /tab >}}

   {{< tab title="Git Bash on Windows" >}}

   ```shell
   cat ~/.ssh/id_ed25519.pub | clip
   ```

   {{< /tab >}}

   {{< /tabs >}}

1. Sign in to GitLab.
1. In the upper-right corner, select your avatar.
1. Select **Edit profile**.
1. On the left sidebar, select **SSH Keys**.
1. Select **Add new key**.
1. In the **Key** box, paste the contents of your public key.
   If you manually copied the key, make sure you copy the entire key,
   which starts with `ssh-rsa`, `ssh-dss`, `ecdsa-sha2-nistp256`, `ecdsa-sha2-nistp384`, `ecdsa-sha2-nistp521`,
   `ssh-ed25519`, `sk-ecdsa-sha2-nistp256@openssh.com`, or `sk-ssh-ed25519@openssh.com`, and may end with a comment.
1. In the **Title** box, type a description, like `Work Laptop` or
   `Home Workstation`.
1. Optional. Select the **Usage type** of the key. It can be used either for `Authentication` or `Signing` or both. `Authentication & Signing` is the default value.
1. Optional. Update **Expiration date** to modify the default expiration date. For more information, see
   [SSH key expiration](#ssh-key-expiration).
1. Select **Add key**.

## Verify your SSH connection

Verify that your SSH key was added correctly, and that you can connect to the GitLab instance:

1. To ensure you connect to the correct server, identify the SSH host key fingerprint:
   - For GitLab.com, see the [SSH host keys fingerprints](gitlab_com/_index.md#ssh-host-keys-fingerprints) documentation.
   - For GitLab Self-Managed or GitLab Dedicated, see `https://gitlab.example.com/help/instance_configuration#ssh-host-keys-fingerprints`
     where `gitlab.example.com` is the GitLab instance URL.
1. Open a terminal and run this command:
   - For GitLab.com, use `ssh -T git@gitlab.com`.
   - For GitLab Self-Managed or GitLab Dedicated, use `ssh -T git@gitlab.example.com`
     where `gitlab.example.com` is the GitLab instance URL.

By default, connections use the `git` username, but GitLab Self-Managed or GitLab Dedicated administrators
can [change the username](https://docs.gitlab.com/omnibus/settings/configuration/#change-the-name-of-the-git-user-or-group).

1. On your first connection, you might need to verify the authenticity of the GitLab host.
   Follow the on-screen prompts if you see a message like:

   ```plaintext
   The authenticity of host 'gitlab.example.com (35.231.145.151)' can't be established.
   ECDSA key fingerprint is SHA256:HbW3g8zUjNSksFbqTiUWPWg2Bq1x8xdGUrliXFzSnUw.
   Are you sure you want to continue connecting (yes/no)?
   ```

   You should receive a welcome message.

   ```plaintext
   Welcome to GitLab, <username>!
   ```

   If the message doesn't appear, you can
   [troubleshoot your SSH connection](ssh_troubleshooting.md#general-ssh-troubleshooting).

## View your SSH keys

To view the SSH keys for your account:

1. In the upper-right corner, select your avatar.
1. Select **Edit profile**.
1. On the left sidebar, select **SSH Keys**.

Your existing SSH keys are listed at the bottom of the page. The information includes:

- The title for the key
- Public fingerprint
- Permitted usage types
- Creation date
- Last used date
- Expiry date

## Remove an SSH key

You can revoke or delete your SSH key to permanently remove it from your account.

Removing your SSH key has additional implications if you sign your commits with the key. For more information, see [Signed commits with removed SSH keys](project/repository/signed_commits/ssh.md#signed-commits-with-removed-ssh-keys).

### Revoke an SSH key

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/108344) in GitLab 15.9.

{{< /history >}}

If your SSH key becomes compromised, revoke the key.

Prerequisites:

- The SSH key must have the `Signing` or `Authentication & Signing` usage type.

To revoke an SSH key:

1. In the upper-right corner, select your avatar.
1. Select **Edit profile**.
1. On the left sidebar, select **SSH Keys**.
1. Next to the SSH key you want to revoke, select **Revoke**.
1. Select **Revoke**.

### Delete an SSH key

To delete an SSH key:

1. In the upper-right corner, select your avatar.
1. Select **Edit profile**.
1. On the left sidebar, select **SSH Keys**.
1. Next to the key you want to delete, select **Remove** ({{< icon name="remove" >}}).
1. Select **Delete**.

## SSH key expiration

You can set an expiration date when you add an SSH key to your account. This optional setting
helps limit the risk of a security breach.

After your SSH key expires, you can no longer use it to authenticate or sign commits. You must
[generate a new SSH key](#generate-an-ssh-key-pair) and
[add it to your account](#add-an-ssh-key-to-your-gitlab-account).

On GitLab Self-Managed and GitLab Dedicated, administrators can view expiration dates and use them
for guidance when [deleting keys](../administration/credentials_inventory.md#delete-ssh-keys).

GitLab checks daily for expiring SSH keys and sends notifications:

- At 01:00 AM UTC, seven days before expiration.
- At 02:00 AM UTC on the expiration date.
