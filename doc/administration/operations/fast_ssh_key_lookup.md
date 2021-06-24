---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Fast lookup of authorized SSH keys in the database **(FREE SELF)**

NOTE:
This document describes a drop-in replacement for the
`authorized_keys` file. For normal (non-deploy key) users, consider using
[SSH certificates](ssh_certificates.md). They are even faster, but are not a
drop-in replacement.

Regular SSH operations become slow as the number of users grows because OpenSSH
searches for a key to authorize a user via a linear search. In the worst case,
such as when the user is not authorized to access GitLab, OpenSSH will scan the
entire file to search for a key. This can take significant time and disk I/O,
which delays users attempting to push or pull to a repository. Making
matters worse, if users add or remove keys frequently, the operating system may
not be able to cache the `authorized_keys` file, which causes the disk to be
accessed repeatedly.

GitLab Shell solves this by providing a way to authorize SSH users via a fast,
indexed lookup in the GitLab database. This page describes how to enable the fast
lookup of authorized SSH keys.

WARNING:
OpenSSH version 6.9+ is required because
`AuthorizedKeysCommand` must be able to accept a fingerprint. These
instructions break installations that use older versions of OpenSSH, such as
those included with CentOS 6 as of September 2017. If you want to use this
feature for CentOS 6, follow [the instructions on how to build and install a custom OpenSSH package](#compiling-a-custom-version-of-openssh-for-centos-6) before continuing.

## Fast lookup is required for Geo **(PREMIUM)**

By default, GitLab manages an `authorized_keys` file that is located in the
`git` user's home directory. For most installations, this will be located under
`/var/opt/gitlab/.ssh/authorized_keys`, but you can use the following command to locate the `authorized_keys` on your system.:

```shell
getent passwd git | cut -d: -f6 | awk '{print $1"/.ssh/authorized_keys"}'
```

The `authorized_keys` file contains all the public SSH keys for users allowed to access GitLab. However, to maintain a
single source of truth, [Geo](../geo/index.md) needs to be configured to perform SSH fingerprint
lookups via database lookup.

As part of [setting up Geo](../geo/index.md#setup-instructions),
you are required to follow the steps outlined below for both the primary and
secondary nodes, but note that the `Write to "authorized keys" file` checkbox
only needs to be unchecked on the primary node since it is reflected
automatically on the secondary if database replication is working.

## Setting up fast lookup via GitLab Shell

GitLab Shell provides a way to authorize SSH users via a fast, indexed lookup
to the GitLab database. GitLab Shell uses the fingerprint of the SSH key to
check whether the user is authorized to access GitLab.

Add the following to your `sshd_config` file. This is usually located at
`/etc/ssh/sshd_config`, but it will be `/assets/sshd_config` if you're using
Omnibus Docker:

```plaintext
Match User git    # Apply the AuthorizedKeysCommands to the git user only
  AuthorizedKeysCommand /opt/gitlab/embedded/service/gitlab-shell/bin/gitlab-shell-authorized-keys-check git %u %k
  AuthorizedKeysCommandUser git
Match all    # End match, settings apply to all users again
```

Reload OpenSSH:

```shell
# Debian or Ubuntu installations
sudo service ssh reload

# CentOS installations
sudo service sshd reload
```

Confirm that SSH is working by commenting out your user's key in the `authorized_keys`
file (start the line with a `#` to comment it), and attempting to pull a repository.

A successful pull would mean that GitLab was able to find the key in the database,
since it is not present in the file anymore.

NOTE:
For Omnibus Docker, `AuthorizedKeysCommand` is setup by default in
GitLab 11.11 and later.

NOTE:
For Installations from source, the command would be located at
`/home/git/gitlab-shell/bin/gitlab-shell-authorized-keys-check` if [the install from source](../../install/installation.md#install-gitlab-shell) instructions were followed.
You might want to consider creating a wrapper script somewhere else since this command needs to be
owned by `root` and not be writable by group or others. You could also consider changing the ownership of this command
as required, but that might require temporary ownership changes during `gitlab-shell` upgrades.

WARNING:
Do not disable writes until SSH is confirmed to be working
perfectly; otherwise, the file quickly becomes out-of-date.

In the case of lookup failures (which are common), the `authorized_keys`
file is still scanned. So Git SSH performance would still be slow for many
users as long as a large file exists.

To disable any more writes to the `authorized_keys` file:

1. On the top bar, select **Menu >** **{admin}** **Admin**.
1. On the left sidebar, select **Settings > Network**.
1. Expand **Performance optimization**.
1. Clear the **Write to "authorized_keys" file** checkbox.
1. Select **Save changes**.

Again, confirm that SSH is working by removing your user's SSH key in the UI,
adding a new one, and attempting to pull a repository.

Then you can backup and delete your `authorized_keys` file for best performance.
The current users' keys are already present in the database, so there is no need for migration
or for asking users to re-add their keys.

## How to go back to using the `authorized_keys` file

This is a brief overview. Please refer to the above instructions for more context.

1. [Rebuild the `authorized_keys` file](../raketasks/maintenance.md#rebuild-authorized_keys-file)
1. Enable writes to the `authorized_keys` file in Application Settings
1. Remove the `AuthorizedKeysCommand` lines from `/etc/ssh/sshd_config` or from `/assets/sshd_config` if you are using Omnibus Docker.
1. Reload `sshd`: `sudo service sshd reload`

## Compiling a custom version of OpenSSH for CentOS 6

Building a custom version of OpenSSH is not necessary for Ubuntu 16.04 users,
since Ubuntu 16.04 ships with OpenSSH 7.2.

It is also unnecessary for CentOS 7.4 users, as that version ships with
OpenSSH 7.4. If you are using CentOS 7.0 - 7.3, we strongly recommend that you
upgrade to CentOS 7.4 instead of following this procedure. This should be as
simple as running `yum update`.

CentOS 6 users must build their own OpenSSH package to enable SSH lookups via
the database. The following instructions can be used to build OpenSSH 7.5:

1. First, download the package and install the required packages:

   ```shell
   sudo su -
   cd /tmp
   curl --remote-name "https://cdn.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-7.5p1.tar.gz"
   tar xzvf openssh-7.5p1.tar.gz
   yum install rpm-build gcc make wget openssl-devel krb5-devel pam-devel libX11-devel xmkmf libXt-devel
   ```

1. Prepare the build by copying files to the right place:

   ```shell
   mkdir -p /root/rpmbuild/{SOURCES,SPECS}
   cp ./openssh-7.5p1/contrib/redhat/openssh.spec /root/rpmbuild/SPECS/
   cp openssh-7.5p1.tar.gz /root/rpmbuild/SOURCES/
   cd /root/rpmbuild/SPECS
   ```

1. Next, set the spec settings properly:

   ```shell
   sed -i -e "s/%define no_gnome_askpass 0/%define no_gnome_askpass 1/g" openssh.spec
   sed -i -e "s/%define no_x11_askpass 0/%define no_x11_askpass 1/g" openssh.spec
   sed -i -e "s/BuildPreReq/BuildRequires/g" openssh.spec
   ```

1. Build the RPMs:

   ```shell
   rpmbuild -bb openssh.spec
   ```

1. Ensure the RPMs were built:

   ```shell
   ls -al /root/rpmbuild/RPMS/x86_64/
   ```

   You should see something as the following:

   ```plaintext
   total 1324
   drwxr-xr-x. 2 root root   4096 Jun 20 19:37 .
   drwxr-xr-x. 3 root root     19 Jun 20 19:37 ..
   -rw-r--r--. 1 root root 470828 Jun 20 19:37 openssh-7.5p1-1.x86_64.rpm
   -rw-r--r--. 1 root root 490716 Jun 20 19:37 openssh-clients-7.5p1-1.x86_64.rpm
   -rw-r--r--. 1 root root  17020 Jun 20 19:37 openssh-debuginfo-7.5p1-1.x86_64.rpm
   -rw-r--r--. 1 root root 367516 Jun 20 19:37 openssh-server-7.5p1-1.x86_64.rpm
   ```

1. Install the packages. OpenSSH packages replace `/etc/pam.d/sshd`
   with their own versions, which may prevent users from logging in, so be sure
   that the file is backed up and restored after installation:

   ```shell
   timestamp=$(date +%s)
   cp /etc/pam.d/sshd pam-ssh-conf-$timestamp
   rpm -Uvh /root/rpmbuild/RPMS/x86_64/*.rpm
   yes | cp pam-ssh-conf-$timestamp /etc/pam.d/sshd
   ```

1. Verify the installed version. In another window, attempt to sign in to the
   server:

   ```shell
   ssh -v <your-centos-machine>
   ```

   You should see a line that reads: "debug1: Remote protocol version 2.0, remote software version OpenSSH_7.5"

   If not, you may need to restart `sshd` (for example, `systemctl restart sshd.service`).

1. *IMPORTANT!* Open a new SSH session to your server before exiting to make
   sure everything is working! If you need to downgrade, simple install the
   older package:

   ```shell
   # Only run this if you run into a problem logging in
   yum downgrade openssh-server openssh openssh-clients
   ```

## SELinux support and limitations

GitLab supports `authorized_keys` database lookups with [SELinux](https://en.wikipedia.org/wiki/Security-Enhanced_Linux).

Because the SELinux policy is static, GitLab doesn't support the ability to change
internal webserver ports at the moment. Administrators would have to create a special `.te`
file for the environment, since it isn't generated dynamically.
