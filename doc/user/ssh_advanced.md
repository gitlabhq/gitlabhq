---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Advanced SSH key configuration
description: Use SSH keys for secure authentication and communication with GitLab repositories.
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Configure advanced SSH key options for specialized workflows.
> [!note]
> For information on basic SSH key usage with your GitLab account,
> see [use SSH keys with GitLab](ssh.md).

## Generate an SSH key pair for a FIDO2 hardware security key

To generate ED25519_SK or ECDSA_SK SSH keys, you must use OpenSSH 8.2 or later:

1. Insert a hardware security key into your computer.
1. Open a terminal.
1. Run `ssh-keygen -t` with the key type and an optional comment to help identify the key later.
   A common option is to use your email address as the comment.
   The comment is included in the `.pub` file.

   For example, for ED25519_SK:

   ```shell
   ssh-keygen -t ed25519-sk -C "<comment>"
   ```

   For ECDSA_SK:

   ```shell
   ssh-keygen -t ecdsa-sk -C "<comment>"
   ```

   If your security key supports FIDO2 resident keys, you can enable this when
   creating your SSH key:

   ```shell
   ssh-keygen -t ed25519-sk -O resident -C "<comment>"
   ```

   `-O resident` indicates that the key should be stored on the FIDO authenticator itself.
   Resident key is easier to import to a new computer because it can be loaded directly
   from the security key by [`ssh-add -K`](https://man.openbsd.org/cgi-bin/man.cgi/OpenBSD-current/man1/ssh-add.1#K)
   or [`ssh-keygen -K`](https://man.openbsd.org/cgi-bin/man.cgi/OpenBSD-current/man1/ssh-keygen#K).

1. Press <kbd>Enter</kbd>. Output similar to the following is displayed:

   ```plaintext
   Generating public/private ed25519-sk key pair.
   You may need to touch your authenticator to authorize key generation.
   ```

1. Touch the button on the hardware security key.

1. Accept the suggested filename and directory:

   ```plaintext
   Enter file in which to save the key (/home/user/.ssh/id_ed25519_sk):
   ```

1. Specify a [passphrase](https://www.ssh.com/academy/ssh/passphrase):

   ```plaintext
   Enter passphrase (empty for no passphrase):
   Enter same passphrase again:
   ```

   A confirmation is displayed, including information about where your files are stored.

A public and private key are generated.
[Add the public SSH key to your GitLab account](ssh.md#add-an-ssh-key-to-your-gitlab-account).

## Generate an SSH key pair with 1Password

You can use [1Password](https://1password.com/) and the [1Password browser extension](https://support.1password.com/getting-started-browser/) to either:

- Automatically generate a new SSH key.
- Use an existing SSH key in your 1Password vault to authenticate with GitLab.

1. Sign in to GitLab.
1. In the upper-right corner, select your avatar.
1. Select **Edit profile**.
1. On the left sidebar, select **SSH Keys**.
1. Select **Add new key**.
1. Select **Key**, and you should see the 1Password helper appear.
1. Select the 1Password icon and unlock 1Password.
1. You can then select **Create SSH Key** or select an existing SSH key to fill in the public key.
1. In the **Title** box, enter a description, like `Work Laptop` or
   `Home Workstation`.
1. Optional. Select the **Usage type** of the key. It can be used either for `Authentication` or `Signing` or both. `Authentication & Signing` is the default value.
1. Optional. Update **Expiration date** to modify the default expiration date.
1. Select **Add key**.

For more information about using 1Password with SSH keys, see the [1Password documentation](https://developer.1password.com/docs/ssh/get-started/).

## Disable SSH keys for enterprise users

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/30343) in GitLab 18.8.

{{< /history >}}

Prerequisites:

- You must have the Owner role for the group that the enterprise users belong to.

Disabling the SSH Keys of a group's [enterprise users](enterprise_user/_index.md):

- Stops the enterprise users from adding new SSH Keys.
- Disables the existing SSH Keys of the enterprise users.

This also applies to enterprise users who are administrators of the group.

To disable the enterprise users' SSH Keys:

1. On the top bar, select **Search or go to** and find your group.
1. Select **Settings** > **General**.
1. Expand **Permissions and group features**.
1. Under **Enterprise users**, select **Disable SSH Keys**.
1. Select **Save changes**.

## Upgrade your RSA key pair to a more secure format

If your version of OpenSSH is between 6.5 and 7.8, you can save your private
RSA SSH keys in a more secure OpenSSH format by opening a terminal and running
this command:

```shell
ssh-keygen -o -f ~/.ssh/id_rsa
```

Alternatively, you can generate a new RSA key with the more secure encryption format with
the following command:

```shell
ssh-keygen -o -t rsa -b 4096 -C "<comment>"
```

## Update your SSH key passphrase

You can update the passphrase for your SSH key:

1. Open a terminal and run this command:

   ```shell
   ssh-keygen -p -f /path/to/ssh_key
   ```

1. At the prompts, enter the passphrase and then press <kbd>Enter</kbd>.

## Use different accounts on a single GitLab instance

You can use multiple accounts to connect to a single instance of GitLab. You
can do this by using the command in the [previous topic](#use-different-keys-for-different-repositories).
However, even if you set `IdentitiesOnly` to `yes`, you cannot sign in if an
`IdentityFile` exists outside of a `Host` block.

Instead, you can assign aliases to hosts in the `~/.ssh/config` file.

- For the `Host`, use an alias like `user_1.gitlab.com` and
  `user_2.gitlab.com`. Advanced configurations
  are more difficult to maintain, and these strings are easier to
  understand when you use tools like `git remote`.
- For the `IdentityFile`, use the path the private key.

```conf
# User1 Account Identity
Host <user_1.gitlab.com>
  Hostname gitlab.com
  PreferredAuthentications publickey
  IdentityFile ~/.ssh/<example_ssh_key1>

# User2 Account Identity
Host <user_2.gitlab.com>
  Hostname gitlab.com
  PreferredAuthentications publickey
  IdentityFile ~/.ssh/<example_ssh_key2>
```

Now, to clone a repository for `user_1`, use `user_1.gitlab.com` in the `git clone` command:

```shell
git clone git@<user_1.gitlab.com>:gitlab-org/gitlab.git
```

To update a previously-cloned repository that is aliased as `origin`:

```shell
git remote set-url origin git@<user_1.gitlab.com>:gitlab-org/gitlab.git
```

> [!note]
> Private and public keys contain sensitive data. Ensure the permissions
> on the files make them readable to you but not accessible to others.

## Use different keys for different repositories

You can use a different key for each repository.

Open a terminal and run this command:

```shell
git config core.sshCommand "ssh -o IdentitiesOnly=yes -i ~/.ssh/private-key-filename-for-this-repository -F /dev/null"
```

This command does not use the SSH Agent and requires Git 2.10 or later. For more information
on `ssh` command options, see the `man` pages for both `ssh` and `ssh_config`.

## Use SSH keys in another directory

If your SSH key pair is not in the default directory, configure your SSH client to point to where you stored the private key.

1. Open a terminal and run this command:

   ```shell
   eval $(ssh-agent -s)
   ssh-add <directory to private SSH key>
   ```

1. Save these settings in the `~/.ssh/config` file. For example:

   ```conf
   # GitLab.com
   Host gitlab.com
     PreferredAuthentications publickey
     IdentityFile ~/.ssh/gitlab_com_rsa

   # Private GitLab instance
   Host gitlab.company.com
     PreferredAuthentications publickey
     IdentityFile ~/.ssh/example_com_rsa
   ```

For more information on these settings, see the [`man ssh_config`](https://man.openbsd.org/ssh_config) page in the SSH configuration manual.

Public SSH keys must be unique to GitLab because they bind to your account.
Your SSH key is the only identifier you have when you push code with SSH.
It must uniquely map to a single user.

## Use SSH with EGit on Eclipse

If you use [EGit](https://projects.eclipse.org/projects/technology.egit), you can [add your SSH key to Eclipse](https://wiki.eclipse.org/EGit/User_Guide/#Eclipse_SSH_Configuration).

## Use SSH on Microsoft Windows

On Windows 10, you can either use the [Windows Subsystem for Linux (WSL)](https://learn.microsoft.com/en-us/windows/wsl/install)
with [WSL 2](https://learn.microsoft.com/en-us/windows/wsl/install#update-to-wsl-2) which
has both `git` and `ssh` preinstalled, or install [Git for Windows](https://gitforwindows.org) to
use SSH through PowerShell.

The SSH key generated in WSL is not directly available for Git for Windows, and vice versa,
as both have a different home directory:

- WSL: `/home/<user>`
- Git for Windows: `C:\Users\<user>`

You can either copy over the `.ssh/` directory to use the same key, or generate a key in each environment.

If you're running Windows 11 and using [OpenSSH for Windows](https://learn.microsoft.com/en-us/windows-server/administration/OpenSSH/openssh-overview), ensure the `HOME`
environment variable is set correctly. Otherwise, your private SSH key might not be found.

Alternative tools include:

- [Cygwin](https://www.cygwin.com)
- [PuTTYgen](https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html) 0.81 and later (earlier versions are [vulnerable to disclosure attacks](https://www.openwall.com/lists/oss-security/2024/04/15/6))

## Use two-factor authentication for Git over SSH

You can use two-factor authentication (2FA) for
[Git over SSH](../security/two_factor_authentication.md#2fa-for-git-over-ssh-operations). You should use
`ED25519_SK` or `ECDSA_SK` SSH keys. For more information, see [supported SSH key types](ssh.md#supported-ssh-key-types).
