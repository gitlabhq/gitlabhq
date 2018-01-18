# Fast lookup of authorized SSH keys in the database

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ee/issues/1631) in 
> [GitLab Enterprise Edition Standard](https://about.gitlab.com/gitlab-ee) 9.3.
>
> [Available in](https://gitlab.com/gitlab-org/gitlab-ee/issues/3953) GitLab
> Community Edition 10.4.

Regular SSH operations become slow as the number of users grows because OpenSSH
searches for a key to authorize a user via a linear search. In the worst case,
such as when the user is not authorized to access GitLab, OpenSSH will scan the
entire file to search for a key. This can take significant time and disk I/O,
which will delay users attempting to push or pull to a repository. Making
matters worse, if users add or remove keys frequently, the operating system may
not be able to cache the `authorized_keys` file, which causes the disk to be
accessed repeatedly.

GitLab Shell solves this by providing a way to authorize SSH users via a fast,
indexed lookup in the GitLab database. This page describes how to enable the fast
lookup of authorized SSH keys.

> **Warning:** OpenSSH version 6.9+ is required because
`AuthorizedKeysCommand` must be able to accept a fingerprint. These
instructions will break installations using older versions of OpenSSH, such as
those included with CentOS 6 as of September 2017. If you want to use this
feature for CentOS 6, follow [the instructions on how to build and install a custom OpenSSH package](#compiling-a-custom-version-of-openssh-for-centos-6) before continuing.

## Setting up fast lookup via GitLab Shell

GitLab Shell provides a way to authorize SSH users via a fast, indexed lookup
to the GitLab database. GitLab Shell uses the fingerprint of the SSH key to
check whether the user is authorized to access GitLab.

Create the directory `/opt/gitlab-shell` first:

```bash
sudo mkdir -p /opt/gitlab-shell
```

Create this file at `/opt/gitlab-shell/authorized_keys`:

```
#!/bin/bash

if [[ "$1" == "git" ]]; then
  /opt/gitlab/embedded/service/gitlab-shell/bin/authorized_keys $2
fi
```

Set appropriate ownership and permissions:

```
sudo chown root:git /opt/gitlab-shell/authorized_keys
sudo chmod 0650 /opt/gitlab-shell/authorized_keys
```

Add the following to `/etc/ssh/sshd_config` or to `/assets/sshd_config` if you
are using Omnibus Docker:

```
AuthorizedKeysCommand /opt/gitlab-shell/authorized_keys %u %k
AuthorizedKeysCommandUser git
```

Reload OpenSSH:

```bash
# Debian or Ubuntu installations
sudo service ssh reload

# CentOS installations
sudo service sshd reload
```

Confirm that SSH is working by removing your user's SSH key in the UI, adding a
new one, and attempting to pull a repo.

> **Warning:** Do not disable writes until SSH is confirmed to be working
perfectly because the file will quickly become out-of-date.

In the case of lookup failures (which are not uncommon), the `authorized_keys`
file will still be scanned. So git SSH performance will still be slow for many
users as long as a large file exists.

You can disable any more writes to the `authorized_keys` file by unchecking
`Write to "authorized_keys" file` in the Application Settings of your GitLab
installation.

![Write to authorized keys setting](img/write_to_authorized_keys_setting.png)

Again, confirm that SSH is working by removing your user's SSH key in the UI,
adding a new one, and attempting to pull a repo.

Then you can backup and delete your `authorized_keys` file for best performance.

## How to go back to using the `authorized_keys` file

This is a brief overview. Please refer to the above instructions for more context.

1. [Rebuild the `authorized_keys` file](../raketasks/maintenance.md#rebuild-authorized_keys-file)
1. Enable writes to the `authorized_keys` file in Application Settings
1. Remove the `AuthorizedKeysCommand` lines from `/etc/ssh/sshd_config` or from `/assets/sshd_config` if you are using Omnibus Docker.
1. Reload sshd: `sudo service sshd reload`
1. Remove the `/opt/gitlab-shell/authorized_keys` file

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

    ```
    sudo su -
    cd /tmp
    curl --remote-name https://mirrors.evowise.com/pub/OpenBSD/OpenSSH/portable/openssh-7.5p1.tar.gz
    tar xzvf openssh-7.5p1.tar.gz
    yum install rpm-build gcc make wget openssl-devel krb5-devel pam-devel libX11-devel xmkmf libXt-devel
    ```

3. Prepare the build by copying files to the right place:

    ```
    mkdir -p /root/rpmbuild/{SOURCES,SPECS}
    cp ./openssh-7.5p1/contrib/redhat/openssh.spec /root/rpmbuild/SPECS/
    cp openssh-7.5p1.tar.gz /root/rpmbuild/SOURCES/
    cd /root/rpmbuild/SPECS
    ```

3. Next, set the spec settings properly:

    ```
    sed -i -e "s/%define no_gnome_askpass 0/%define no_gnome_askpass 1/g" openssh.spec
    sed -i -e "s/%define no_x11_askpass 0/%define no_x11_askpass 1/g" openssh.spec
    sed -i -e "s/BuildPreReq/BuildRequires/g" openssh.spec
    ```

3. Build the RPMs:

    ```
    rpmbuild -bb openssh.spec
    ```

4. Ensure the RPMs were built:

    ```
    ls -al /root/rpmbuild/RPMS/x86_64/
    ```

    You should see something as the following:

    ```
    total 1324
    drwxr-xr-x. 2 root root   4096 Jun 20 19:37 .
    drwxr-xr-x. 3 root root     19 Jun 20 19:37 ..
    -rw-r--r--. 1 root root 470828 Jun 20 19:37 openssh-7.5p1-1.x86_64.rpm
    -rw-r--r--. 1 root root 490716 Jun 20 19:37 openssh-clients-7.5p1-1.x86_64.rpm
    -rw-r--r--. 1 root root  17020 Jun 20 19:37 openssh-debuginfo-7.5p1-1.x86_64.rpm
    -rw-r--r--. 1 root root 367516 Jun 20 19:37 openssh-server-7.5p1-1.x86_64.rpm
    ```

5. Install the packages. OpenSSH packages will replace `/etc/pam.d/sshd`
   with its own version, which may prevent users from logging in, so be sure
   that the file is backed up and restored after installation:

    ```
    timestamp=$(date +%s)
    cp /etc/pam.d/sshd pam-ssh-conf-$timestamp
    rpm -Uvh /root/rpmbuild/RPMS/x86_64/*.rpm
    yes | cp pam-ssh-conf-$timestamp /etc/pam.d/sshd
    ```

6. Verify the installed version. In another window, attempt to login to the server:

    ```
    ssh -v <your-centos-machine>
    ```

    You should see a line that reads: "debug1: Remote protocol version 2.0, remote software version OpenSSH_7.5"

    If not, you may need to restart sshd (e.g. `systemctl restart sshd.service`).

7.  *IMPORTANT!* Open a new SSH session to your server before exiting to make
    sure everything is working! If you need to downgrade, simple install the
    older package:

    ```
    # Only run this if you run into a problem logging in
    yum downgrade openssh-server openssh openssh-clients
    ```
