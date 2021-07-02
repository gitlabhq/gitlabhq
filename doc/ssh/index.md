---
stage: Manage
group: Access
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments"
type: howto, reference
---

# GitLab and SSH keys

Git is a distributed version control system, which means you can work locally,
then share or "push" your changes to a server. In this case, the server is GitLab.

GitLab uses the SSH protocol to securely communicate with Git.
When you use SSH keys to authenticate to the GitLab remote server,
you don't need to supply your username and password each time.

## Prerequisites

To use SSH to communicate with GitLab, you need:

- The OpenSSH client, which comes pre-installed on GNU/Linux, macOS, and Windows 10.
- SSH version 6.5 or later. Earlier versions used an MD5 signature, which is not secure.

To view the version of SSH installed on your system, run `ssh -V`.

## Supported SSH key types

To communicate with GitLab, you can use the following SSH key types:

- [ED25519](#ed25519-ssh-keys)
- [RSA](#rsa-ssh-keys)
- DSA ([Deprecated](https://about.gitlab.com/releases/2018/06/22/gitlab-11-0-released/#support-for-dsa-ssh-keys) in GitLab 11.0.)
- ECDSA (As noted in [Practical Cryptography With Go](https://leanpub.com/gocrypto/read#leanpub-auto-ecdsa), the security issues related to DSA also apply to ECDSA.)

Administrators can [restrict which keys are permitted and their minimum lengths](../security/ssh_keys_restrictions.md).

### ED25519 SSH keys

The book [Practical Cryptography With Go](https://leanpub.com/gocrypto/read#leanpub-auto-chapter-5-digital-signatures)
suggests that [ED25519](https://ed25519.cr.yp.to/) keys are more secure and performant than RSA keys.

OpenSSH 6.5 introduced ED25519 SSH keys in 2014 and they should be available on most
operating systems.

### RSA SSH keys

Available documentation suggests that ED25519 is more secure than RSA.

If you use an RSA key, the US National Institute of Science and Technology in
[Publication 800-57 Part 3 (PDF)](https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-57Pt3r1.pdf)
recommends a key size of at least 2048 bits. The default key size depends on your version of `ssh-keygen`.
Review the `man` page for your installed `ssh-keygen` command for details.

## See if you have an existing SSH key pair

Before you create a key pair, see if a key pair already exists.

1. On Windows, Linux, or macOS, go to your home directory.
1. Go to the `.ssh/` subdirectory. If the `.ssh/` subdirectory doesn't exist,
   you are either not in the home directory, or you haven't used `ssh` before.
   In the latter case, you need to [generate an SSH key pair](#generate-an-ssh-key-pair).
1. See if a file with one of the following formats exists:

   | Algorithm | Public key | Private key |
   | --------- | ---------- | ----------- |
   |  ED25519 (preferred)  | `id_ed25519.pub` | `id_ed25519` |
   |  RSA (at least 2048-bit key size)     | `id_rsa.pub` | `id_rsa` |
   |  DSA (deprecated)      | `id_dsa.pub` | `id_dsa` |
   |  ECDSA    | `id_ecdsa.pub` | `id_ecdsa` |

## Generate an SSH key pair

If you do not have an existing SSH key pair, generate a new one.

1. Open a terminal.
1. Type `ssh-keygen -t` followed by the key type and an optional comment.
   This comment is included in the `.pub` file that's created.
   You may want to use an email address for the comment.

   For example, for ED25519:

   ```shell
   ssh-keygen -t ed25519 -C "<comment>"
   ```

   For 2048-bit RSA:

   ```shell
   ssh-keygen -t rsa -b 2048 -C "<comment>"
   ```

1. Press Enter. Output similar to the following is displayed:

   ```plaintext
   Generating public/private ed25519 key pair.
   Enter file in which to save the key (/home/user/.ssh/id_ed25519):
   ```

1. Accept the suggested filename and directory, unless you are generating a [deploy key](../user/project/deploy_keys/index.md)
   or want to save in a specific directory where you store other keys.

   You can also dedicate the SSH key pair to a [specific host](#configure-ssh-to-point-to-a-different-directory).

1. Specify a [passphrase](https://www.ssh.com/ssh/passphrase):

   ```plaintext
   Enter passphrase (empty for no passphrase):
   Enter same passphrase again:
   ```

1. A confirmation is displayed, including information about where your files are stored.

A public and private key are generated.
[Add the public SSH key to your GitLab account](#add-an-ssh-key-to-your-gitlab-account) and keep
the private key secure.

### Configure SSH to point to a different directory

If you did not save your SSH key pair in the default directory,
configure your SSH client to point to the directory where the private key is stored.

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

### Update your SSH key passphrase

You can update the passphrase for your SSH key.

1. Open a terminal and run this command:

   ```shell
   ssh-keygen -p -f /path/to/ssh_key
   ```

1. At the prompts, type the passphrase and press Enter.

### Upgrade your RSA key pair to a more secure format

If your version of OpenSSH is between 6.5 and 7.8,
you can save your private RSA SSH keys in a more secure
OpenSSH format.

1. Open a terminal and run this command:

   ```shell
   ssh-keygen -o -f ~/.ssh/id_rsa
   ```

   Alternatively, you can generate a new RSA key with the more secure encryption format with
   the following command:

   ```shell
   ssh-keygen -o -t rsa -b 4096 -C "<comment>"
   ```

## Add an SSH key to your GitLab account

To use SSH with GitLab, copy your public key to your GitLab account.

1. Copy the contents of your public key file. You can do this manually or use a script.
   For example, to copy an ED25519 key to the clipboard:

   **macOS:**

   ```shell
   tr -d '\n' < ~/.ssh/id_ed25519.pub | pbcopy
   ```

   **Linux** (requires the `xclip` package):

   ```shell
   xclip -sel clip < ~/.ssh/id_ed25519.pub
   ```

   **Git Bash on Windows:**

   ```shell
   cat ~/.ssh/id_ed25519.pub | clip
   ```

   Replace `id_ed25519.pub` with your filename. For example, use `id_rsa.pub` for RSA.

1. Sign in to GitLab.
1. In the top right corner, select your avatar.
1. Select **Preferences**.
1. From the left sidebar, select **SSH Keys**.
1. In the **Key** box, paste the contents of your public key.
   If you manually copied the key, make sure you copy the entire key,
   which starts with `ssh-ed25519` or `ssh-rsa`, and may end with a comment.
1. In the **Title** text box, type a description, like _Work Laptop_ or
   _Home Workstation_.
1. Optional. In the **Expires at** box, select an expiration date. (Introduced in [GitLab 12.9](https://gitlab.com/gitlab-org/gitlab/-/issues/36243).)
   The expiration date is informational only, and does not prevent you from using
   the key. However, administrators can view expiration dates and
   use them for guidance when [deleting keys](../user/admin_area/credentials_inventory.md#delete-a-users-ssh-key).
   - GitLab checks all SSH keys at 02:00 AM UTC every day. It emails an expiration notice for all SSH keys that expire on the current date. ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/322637) in GitLab 13.11.)
   - GitLab checks all SSH keys at 01:00 AM UTC every day. It emails an expiration notice for all SSH keys that are scheduled to expire seven days from now. ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/322637) in GitLab 13.11.)
1. Select **Add key**.

## Verify that you can connect

Verify that your SSH key was added correctly.

1. For GitLab.com, to ensure you're connecting to the correct server, confirm the
   [SSH host keys fingerprints](../user/gitlab_com/index.md#ssh-host-keys-fingerprints).
1. Open a terminal and run this command, replacing `gitlab.example.com` with your GitLab instance URL:

   ```shell
   ssh -T git@gitlab.example.com
   ```

1. If this is the first time you connect, you should verify the
   authenticity of the GitLab host. If you see a message like:

   ```plaintext
   The authenticity of host 'gitlab.example.com (35.231.145.151)' can't be established.
   ECDSA key fingerprint is SHA256:HbW3g8zUjNSksFbqTiUWPWg2Bq1x8xdGUrliXFzSnUw.
   Are you sure you want to continue connecting (yes/no)? yes
   Warning: Permanently added 'gitlab.example.com' (ECDSA) to the list of known hosts.
   ```

   Type `yes` and press Enter.

1. Run the `ssh -T git@gitlab.example.com` command again. You should receive a _Welcome to GitLab, `@username`!_ message.

If the welcome message doesn't appear, you can troubleshoot by running `ssh`
in verbose mode:

```shell
ssh -Tvvv git@gitlab.example.com
```

## Use different keys for different repositories

You can use a different key for each repository.

Open a terminal and run this command:

```shell
git config core.sshCommand "ssh -o IdentitiesOnly=yes -i ~/.ssh/private-key-filename-for-this-repository -F /dev/null"
```

This command does not use the SSH Agent and requires Git 2.10 or later. For more information
on `ssh` command options, see the `man` pages for both `ssh` and `ssh_config`.

## Use different accounts on a single GitLab instance

You can use multiple accounts to connect to a single instance of GitLab.
You can do this by using the command in the [previous topic](#use-different-keys-for-different-repositories).
However, even if you set `IdentitiesOnly` to `yes`, you cannot sign in if an `IdentityFile` exists
outside of a `Host` block.

Instead, you can assign aliases to hosts in the `~.ssh/config` file.

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

NOTE:
Private and public keys contain sensitive data. Ensure the permissions
on the files make them readable to you but not accessible to others.

## Configure two-factor authentication (2FA)

You can set up two-factor authentication (2FA) for
[Git over SSH](../security/two_factor_authentication.md#two-factor-authentication-2fa-for-git-over-ssh-operations).

## Use EGit on Eclipse

If you are using [EGit](https://www.eclipse.org/egit/), you can [add your SSH key to Eclipse](https://wiki.eclipse.org/EGit/User_Guide#Eclipse_SSH_Configuration).

## Use SSH on Microsoft Windows

If you're running Windows 10, you can either use the [Windows Subsystem for Linux (WSL)](https://docs.microsoft.com/en-us/windows/wsl/install-win10)
with [WSL 2](https://docs.microsoft.com/en-us/windows/wsl/install-win10#update-to-wsl-2) which
has both `git` and `ssh` preinstalled, or install [Git for Windows](https://gitforwindows.org) to
use SSH through Powershell.

The SSH key generated in WSL is not directly available for Git for Windows, and vice versa,
as both have a different home directory:

- WSL: `/home/<user>`
- Git for Windows: `C:\Users\<user>`

You can either copy over the `.ssh/` directory to use the same key, or generate a key in each environment.

Alternative tools include:

- [Cygwin](https://www.cygwin.com)
- [PuttyGen](https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html)

## Overriding SSH settings on the GitLab server

GitLab integrates with the system-installed SSH daemon and designates a user
(typically named `git`) through which all access requests are handled. Users
who connect to the GitLab server over SSH are identified by their SSH key instead
of their username.

SSH *client* operations performed on the GitLab server are executed as this
user. You can modify this SSH configuration. For example, you can specify
a private SSH key for this user to use for authentication requests. However, this practice
is **not supported** and is strongly discouraged as it presents significant
security risks.

GitLab checks for this condition, and directs you
to this section if your server is configured this way. For example:

```shell
$ gitlab-rake gitlab:check

Git user has default SSH configuration? ... no
  Try fixing it:
  mkdir ~/gitlab-check-backup-1504540051
  sudo mv /var/lib/git/.ssh/id_rsa ~/gitlab-check-backup-1504540051
  sudo mv /var/lib/git/.ssh/id_rsa.pub ~/gitlab-check-backup-1504540051
  For more information see:
  [Overriding SSH settings on the GitLab server](#overriding-ssh-settings-on-the-gitlab-server)
  Please fix the error above and rerun the checks.
```

Remove the custom configuration as soon as you can. These customizations
are **explicitly not supported** and may stop working at any time.

## Troubleshooting SSH connections

When you run `git clone`, you may be prompted for a password, like `git@gitlab.example.com's password:`.
This indicates that something is wrong with your SSH setup.

- Ensure that you generated your SSH key pair correctly and added the public SSH
  key to your GitLab profile.
- Try to manually register your private SSH key by using `ssh-agent`.
- Try to debug the connection by running `ssh -Tv git@example.com`.
  Replace `example.com` with your GitLab URL.
