---
stage: Manage
group: Access
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments"
type: howto, reference
---

# GitLab and SSH keys

Git is a distributed version control system, which means you can work locally.
In addition, you can also share or "push" your changes to other servers.
GitLab supports secure communication between Git and its servers using SSH keys.

The SSH protocol provides this security and allows you to authenticate to the
GitLab remote server without supplying your username or password each time.

This page can help you configure secure SSH keys which you can use to help secure
connections to GitLab repositories.

- If you need information on creating SSH keys, start with our [options for SSH keys](#supported-ssh-key-types).
- If you have SSH keys dedicated for your GitLab account, you may be interested in [Working with non-default SSH key pair paths](#working-with-non-default-ssh-key-pair-paths).
- If you already have an SSH key pair, you can go to how you can [add an SSH key to your GitLab account](#add-an-ssh-key-to-your-gitlab-account).

## Prerequisites

To use SSH to communicate with GitLab, you need:

- The OpenSSH client, which comes pre-installed on GNU/Linux, macOS, and Windows 10.
- SSH version 6.5 or later. Earlier versions used an MD5 signature, which is not secure.

To view the version of SSH installed on your system, run `ssh -V`.

GitLab does [not support installation on Microsoft Windows](../install/requirements.md#microsoft-windows),
but you can set up SSH keys on the Windows [client](#options-for-microsoft-windows).

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

1. On Linux or macOS, go to your home directory.
1. Go to the `.ssh/` subdirectory.
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

1. Accept the suggested filename and directory, unless you are generating a [deploy key](#deploy-keys)
   or want to save in a specific directory where you store other keys.

   You can also dedicate the SSH key pair to a [specific host](#working-with-non-default-ssh-key-pair-paths).

1. Specify a [passphrase](https://www.ssh.com/ssh/passphrase/):

   ```plaintext
   Enter passphrase (empty for no passphrase):
   Enter same passphrase again:
   ```

1. A confirmation is displayed, including information about where your files are stored.

A public and private key are generated. 
[Add the public SSH key to your GitLab account](#add-an-ssh-key-to-your-gitlab-account) and keep
the private key secure.

### Update your SSH key passphrase

You can update the passphrase for your SSH key.

1. Open a terminal and type this command:

   ```shell
   ssh-keygen -p -f /path/to/ssh_key
   ```

1. At the prompts, type the passphrase and press Enter.

### Upgrade your RSA key pair to a more secure format

If your version of OpenSSH is between 6.5 and 7.8,
you can save your private RSA SSH keys in a more secure
OpenSSH format.

1. Open a terminal and type this command:

   ```shell
   ssh-keygen -o -f ~/.ssh/id_rsa
   ```

   Alternatively, you can generate a new RSA key with the more secure encryption format with
   the following command:

   ```shell
   ssh-keygen -o -t rsa -b 4096 -C "<comment>"
   ```

## Add an SSH key to your GitLab account

Now you can copy the SSH key you created to your GitLab account.

1. Copy your **public** SSH key to a location that saves information in text format.
   The following options saves information for ED25519 keys to the clipboard
   for the noted operating system:

   **macOS:**

   ```shell
   pbcopy < ~/.ssh/id_ed25519.pub
   ```

   **Linux (requires the `xclip` package):**

   ```shell
   xclip -sel clip < ~/.ssh/id_ed25519.pub
   ```

   **Git Bash on Windows:**

   ```shell
   cat ~/.ssh/id_ed25519.pub | clip
   ```

   If you're using an RSA key, substitute accordingly.

1. Navigate to `https://gitlab.com` or your local GitLab instance URL and sign in.
1. In the top-right corner, select your avatar.
1. Select **Edit profile**.
1. In the left sidebar, select **SSH Keys**.
1. Paste the public key that you copied into the **Key** text box.
1. Make sure your key includes a descriptive name in the **Title** text box, such as _Work Laptop_ or
   _Home Workstation_.
1. Include an (optional) expiry date for the key under "Expires at" section. (Introduced in [GitLab 12.9](https://gitlab.com/gitlab-org/gitlab/-/issues/36243).)
1. Click the **Add key** button.

SSH keys that have "expired" using this procedure are valid in GitLab workflows.
As the GitLab-configured expiration date is not included in the SSH key itself,
you can still export public SSH keys as needed.

NOTE:
If you manually copied your public SSH key make sure you copied the entire
key starting with `ssh-ed25519` (or `ssh-rsa`) and ending with your email address.

## Two-factor Authentication (2FA)

You can set up two-factor authentication (2FA) for
[Git over SSH](../security/two_factor_authentication.md#two-factor-authentication-2fa-for-git-over-ssh-operations).

## Testing that everything is set up correctly

To test whether your SSH key was added correctly, run the following
command in your terminal (replace `gitlab.com` with the domain of
your GitLab instance):

```shell
ssh -T git@gitlab.com
```

The first time you connect to GitLab via SSH, you should verify the
authenticity of the GitLab host that you're connecting to.
For example, when connecting to GitLab.com, answer `yes` to add GitLab.com to
the list of trusted hosts:

```plaintext
The authenticity of host 'gitlab.com (35.231.145.151)' can't be established.
ECDSA key fingerprint is SHA256:HbW3g8zUjNSksFbqTiUWPWg2Bq1x8xdGUrliXFzSnUw.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added 'gitlab.com' (ECDSA) to the list of known hosts.
```

NOTE:
For GitLab.com, consult the
[SSH host keys fingerprints](../user/gitlab_com/index.md#ssh-host-keys-fingerprints),
section to make sure you're connecting to the correct server. For example, you can see
the ECDSA key fingerprint shown above in the linked section.

Once added to the list of known hosts, you should validate the
authenticity of the GitLab host, once again. Run the above command
again, and you should receive a _Welcome to GitLab, `@username`!_ message.

If the welcome message doesn't appear, you can troubleshoot the problem by running `ssh`
in verbose mode with the following command:

```shell
ssh -Tvvv git@gitlab.com
```

## Working with non-default SSH key pair paths

If you used a non-default file path for your GitLab SSH key pair,
configure your SSH client to point to your GitLab private SSH key.

To make these changes, run the following commands:

```shell
eval $(ssh-agent -s)
ssh-add <path to private SSH key>
```

Now save these settings to the `~/.ssh/config` file. Two examples
for SSH keys dedicated to GitLab are shown here:

```conf
# GitLab.com
Host gitlab.com
  Preferredauthentications publickey
  IdentityFile ~/.ssh/gitlab_com_rsa

# Private GitLab instance
Host gitlab.company.com
  Preferredauthentications publickey
  IdentityFile ~/.ssh/example_com_rsa
```

Public SSH keys need to be unique to GitLab, as they bind to your account.
Your SSH key is the only identifier you have when pushing code via SSH,
that's why it needs to uniquely map to a single user.

## Per-repository SSH keys

If you want to use different keys depending on the repository you are working
on, you can issue the following command while inside your repository:

```shell
git config core.sshCommand "ssh -o IdentitiesOnly=yes -i ~/.ssh/private-key-filename-for-this-repository -F /dev/null"
```

This does not use the SSH Agent and requires at least Git 2.10.

## Multiple accounts on a single GitLab instance

The [per-repository](#per-repository-ssh-keys) method also works for using
multiple accounts within a single GitLab instance.

Alternatively, it is possible to directly assign aliases to hosts in
`~.ssh/config`. SSH and, by extension, Git fails to log in if there is
an `IdentityFile` set outside of a `Host` block in `.ssh/config`. This is
due to how SSH assembles `IdentityFile` entries and is not changed by
setting `IdentitiesOnly` to `yes`. `IdentityFile` entries should point to
the private key of an SSH key pair.

NOTE:
Private and public keys should be readable by the user only. Accomplish this
on Linux and macOS by running: `chmod 0400 ~/.ssh/<example_ssh_key>` and
`chmod 0400 ~/.ssh/<example_sh_key.pub>`.

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

NOTE:
The example `Host` aliases are defined as `user_1.gitlab.com` and
`user_2.gitlab.com` for efficiency and transparency. Advanced configurations
are more difficult to maintain; using this type of alias makes it easier to
understand when using other tools such as `git remote` sub-commands. SSH
would understand any string as a `Host` alias thus `Tanuki1` and `Tanuki2`,
despite giving very little context as to where they point, would also work.

Cloning the `gitlab` repository normally looks like this:

```shell
git clone git@gitlab.com:gitlab-org/gitlab.git
```

To clone it for `user_1`, replace `gitlab.com` with the SSH alias `user_1.gitlab.com`:

```shell
git clone git@<user_1.gitlab.com>:gitlab-org/gitlab.git
```

Fix a previously cloned repository using the `git remote` command.

The example below assumes the remote repository is aliased as `origin`.

```shell
git remote set-url origin git@<user_1.gitlab.com>:gitlab-org/gitlab.git
```

## Deploy keys

Read the [documentation on deploy keys](../user/project/deploy_keys/index.md).

## Applications

### Eclipse

If you are using [EGit](https://www.eclipse.org/egit/), you can [add your SSH key to Eclipse](https://wiki.eclipse.org/EGit/User_Guide#Eclipse_SSH_Configuration).

## SSH on the GitLab server

GitLab integrates with the system-installed SSH daemon, designating a user
(typically named `git`) through which all access requests are handled. Users
connecting to the GitLab server over SSH are identified by their SSH key instead
of their username.

SSH *client* operations performed on the GitLab server are executed as this
user. Although it is possible to modify the SSH configuration for this user to,
e.g., provide a private SSH key to authenticate these requests by, this practice
is **not supported** and is strongly discouraged as it presents significant
security risks.

The GitLab check process includes a check for this condition, and directs you
to this section if your server is configured like this, for example:

```shell
$ gitlab-rake gitlab:check

Git user has default SSH configuration? ... no
  Try fixing it:
  mkdir ~/gitlab-check-backup-1504540051
  sudo mv /var/lib/git/.ssh/id_rsa ~/gitlab-check-backup-1504540051
  sudo mv /var/lib/git/.ssh/id_rsa.pub ~/gitlab-check-backup-1504540051
  For more information see:
  doc/ssh/README.md in section "SSH on the GitLab server"
  Please fix the error above and rerun the checks.
```

Remove the custom configuration as soon as you're able to. These customizations
are *explicitly not supported* and may stop working at any time.

### Options for Microsoft Windows

If you're running Windows 10, the [Windows Subsystem for Linux (WSL)](https://docs.microsoft.com/en-us/windows/wsl/install-win10), and its latest [WSL 2](https://docs.microsoft.com/en-us/windows/wsl/install-win10#update-to-wsl-2) version,
support the installation of different Linux distributions, which include the Git and SSH clients.

For current versions of Windows, you can also install the Git and SSH clients with
[Git for Windows](https://gitforwindows.org).

Alternative tools include:

- [Cygwin](https://www.cygwin.com)
- [PuttyGen](https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html)

## Troubleshooting

If on Git clone you are prompted for a password like `git@gitlab.com's password:`
something is wrong with your SSH setup.

- Ensure that you generated your SSH key pair correctly and added the public SSH
  key to your GitLab profile
- Try manually registering your private SSH key using `ssh-agent` as documented
  earlier in this document
- Try to debug the connection by running `ssh -Tv git@example.com`
  (replacing `example.com` with your GitLab domain)
