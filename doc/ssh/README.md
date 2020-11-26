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

- If you need information on creating SSH keys, start with our [options for SSH keys](#options-for-ssh-keys).
- If you have SSH keys dedicated for your GitLab account, you may be interested in [Working with non-default SSH key pair paths](#working-with-non-default-ssh-key-pair-paths).
- If you already have an SSH key pair, you can go to how you can [add an SSH key to your GitLab account](#adding-an-ssh-key-to-your-gitlab-account).

## Requirements

To support SSH, GitLab requires the installation of the OpenSSH client, which
comes pre-installed on GNU/Linux and macOS, as well as on Windows 10.

Make sure that your system includes SSH version 6.5 or newer, as that excludes
the now insecure MD5 signature scheme. The following command returns the version of
SSH installed on your system:

```shell
ssh -V
```

While GitLab does [not support installation on Microsoft Windows](../install/requirements.md#microsoft-windows),
you can set up SSH keys to set up Windows [as a client](#options-for-microsoft-windows).

## Options for SSH keys

GitLab supports the use of RSA, DSA, ECDSA, and ED25519 keys.

- GitLab has [deprecated](https://about.gitlab.com/releases/2018/06/22/gitlab-11-0-released/#support-for-dsa-ssh-keys) DSA keys in GitLab 11.0.
- As noted in [Practical Cryptography With Go](https://leanpub.com/gocrypto/read#leanpub-auto-ecdsa), the security issues related to DSA also apply to ECDSA.

TIP: **Tip:**
Available documentation suggests that ED25519 is more secure. If you use an RSA key, the US National Institute of Science and Technology in [Publication 800-57 Part 3 (PDF)](https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-57Pt3r1.pdf) recommends a key size of at least 2048 bits.

Therefore, our documentation focuses on the use of ED25519 and RSA keys.

Administrators can [restrict which keys should be permitted and their minimum lengths](../security/ssh_keys_restrictions.md).

## Review existing SSH keys

If you have existing SSH keys, you may be able to use them to help secure connections with GitLab
repositories. By default, SSH keys on Linux and macOS systems are stored in the user's home directory,
in the `.ssh/` subdirectory. The following table includes default filenames for each SSH key algorithm:

| Algorithm | Public key | Private key |
| --------- | ---------- | ----------- |
|  ED25519 (preferred)  | `id_ed25519.pub` | `id_ed25519` |
|  RSA (at least 2048-bit key size)     | `id_rsa.pub` | `id_rsa` |
|  DSA (deprecated)      | `id_dsa.pub` | `id_dsa` |
|  ECDSA    | `id_ecdsa.pub` | `id_ecdsa` |

For recommendations, see [options for SSH keys](#options-for-ssh-keys).

## Generating a new SSH key pair

If you want to create:

- An ED25519 key, read [ED25519 SSH keys](#ed25519-ssh-keys).
- An RSA key, read [RSA SSH keys](#rsa-ssh-keys).

### ED25519 SSH keys

The book [Practical Cryptography With Go](https://leanpub.com/gocrypto/read#leanpub-auto-chapter-5-digital-signatures)
suggests that [ED25519](https://ed25519.cr.yp.to/) keys are more secure and performant than RSA keys.

As OpenSSH 6.5 introduced ED25519 SSH keys in 2014, they should be available on any current
operating system.

You can create and configure an ED25519 key with the following command:

```shell
ssh-keygen -t ed25519 -C "<comment>"
```

The `-C` flag, with a quoted comment such as an email address, is an optional way to label your SSH keys.

You'll see a response similar to:

```plaintext
Generating public/private ed25519 key pair.
Enter file in which to save the key (/home/user/.ssh/id_ed25519):
```

For guidance, proceed to the [common steps](#common-steps-for-generating-an-ssh-key-pair).

### RSA SSH keys

If you use RSA keys for SSH, the US National Institute of Standards and Technology recommends
that you use a key size of [at least 2048 bits](https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-57Pt3r1.pdf).
By default, the `ssh-keygen` command creates an 1024-bit RSA key.

You can create and configure an RSA key with the following command, substituting if desired for the minimum recommended key size of `2048`:

```shell
ssh-keygen -t rsa -b 2048 -C "email@example.com"
```

The `-C` flag, with a quoted comment such as an email address, is an optional way to label your SSH keys.

You'll see a response similar to:

```plaintext
Generating public/private rsa key pair.
Enter file in which to save the key (/home/user/.ssh/id_rsa):
```

For guidance, proceed to the [common steps](#common-steps-for-generating-an-ssh-key-pair).

NOTE: **Note:**
If you have OpenSSH version 7.8 or below, consider the problems associated
with [encoding](#rsa-keys-and-openssh-from-versions-65-to-78).

### Common steps for generating an SSH key pair

Whether you're creating a [ED25519](#ed25519-ssh-keys) or an [RSA](#rsa-ssh-keys) key, you've started with the `ssh-keygen` command.
At this point, you'll see the following message in the command line (for ED25519 keys):

```plaintext
Generating public/private ed25519 key pair.
Enter file in which to save the key (/home/user/.ssh/id_ed25519):
```

If you don't already have an SSH key pair and are not generating a [deploy key](#deploy-keys),
accept the suggested file and directory. Your SSH client uses
the resulting SSH key pair with no additional configuration.

Alternatively, you can save the new SSH key pair in a different location.
You can assign the directory and filename of your choice.
You can also dedicate that SSH key pair to a [specific host](#working-with-non-default-ssh-key-pair-paths).

After assigning a file to save your SSH key, you can set up
a [passphrase](https://www.ssh.com/ssh/passphrase/) for your SSH key:

```plaintext
Enter passphrase (empty for no passphrase):
Enter same passphrase again:
```

If successful, you'll see confirmation of where the `ssh-keygen` command
saved your identification and private key.

When needed, you can update the passphrase with the following command:

```shell
ssh-keygen -p -f /path/to/ssh_key
```

### RSA keys and OpenSSH from versions 6.5 to 7.8

Before OpenSSH 7.8, the default public key fingerprint for RSA keys was based on MD5,
and is therefore insecure.

If your version of OpenSSH lies between version 6.5 to version 7.8 (inclusive),
run `ssh-keygen` with the `-o` option to save your private SSH keys in the more secure
OpenSSH format.

If you already have an RSA SSH key pair to use with GitLab, consider upgrading it
to use the more secure password encryption format. You can do so with the following command:

```shell
ssh-keygen -o -f ~/.ssh/id_rsa
```

Alternatively, you can generate a new RSA key with the more secure encryption format with
the following command:

```shell
ssh-keygen -o -t rsa -b 4096 -C "email@example.com"
```

NOTE: **Note:**
As noted in the `ssh-keygen` man page, ED25519 already encrypts keys to the more secure
OpenSSH format.

## Adding an SSH key to your GitLab account

Now you can copy the SSH key you created to your GitLab account. To do so, follow these steps:

1. Copy your **public** SSH key to a location that saves information in text format.
   The following options saves information for ED25519 keys to the clipboard
   for the noted operating system:

   **macOS:**

   ```shell
   pbcopy < ~/.ssh/id_ed25519.pub
   ```

   **Linux (requires the xclip package):**

   ```shell
   xclip -sel clip < ~/.ssh/id_ed25519.pub
   ```

   **Git Bash on Windows:**

   ```shell
   cat ~/.ssh/id_ed25519.pub | clip
   ```

   If you're using an RSA key, substitute accordingly.

1. Navigate to `https://gitlab.com` and sign in.
1. Select your avatar in the upper right corner, and click **Settings**
1. Click **SSH Keys**.
1. Paste the public key that you copied into the **Key** text box.
1. Make sure your key includes a descriptive name in the **Title** text box, such as _Work Laptop_ or
   _Home Workstation_.
1. Include an (optional) expiry date for the key under "Expires at" section. (Introduced in [GitLab 12.9](https://gitlab.com/gitlab-org/gitlab/-/issues/36243).)
1. Click the **Add key** button.

SSH keys that have "expired" using this procedure are valid in GitLab workflows.
As the GitLab-configured expiration date is not included in the SSH key itself,
you can still export public SSH keys as needed.

NOTE: **Note:**
If you manually copied your public SSH key make sure you copied the entire
key starting with `ssh-ed25519` (or `ssh-rsa`) and ending with your email address.

## Testing that everything is set up correctly

To test whether your SSH key was added correctly, run the following command in
your terminal (replacing `gitlab.com` with your GitLab's instance domain):

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

NOTE: **Note:**
For GitLab.com, consult the
[SSH host keys fingerprints](../user/gitlab_com/index.md#ssh-host-keys-fingerprints),
section to make sure you're connecting to the correct server. For example, you can see
the ECDSA key fingerprint shown above in the linked section.

Once added to the list of known hosts, you should validate the
authenticity of GitLab's host again. Run the above command once more, and
you should only receive a _Welcome to GitLab, `@username`!_ message.

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

NOTE: **Note:**
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

NOTE: **Note:**
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

Read the [documentation on Deploy Keys](../user/project/deploy_keys/index.md).

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
