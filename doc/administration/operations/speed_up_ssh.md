# Speed up SSH operations

## The problem

SSH operations become slow as the number of users grows.

## The reason

By default, all SSH keys are written to one `authorized_keys` file, from oldest to newest. The way OpenSSH searches for a key to authorize a user is by doing a linear search.

This means that a new user (or an old user with a new key) will force OpenSSH to load the whole file and scan through it on every git SSH operation to find its key. On top of this, the file is not cached by the OS if it is being written to frequently, which would result in wasted IOPS.

## The solution

GitLab Shell provides a way to check keys by fingerprint which can be used to efficiently authorize users.

> **Warning:** OpenSSH version 6.9+ is required because `AuthorizedKeysCommand` must be able to accept a fingerprint. These instructions will break installations using older versions of OpenSSH, such as those included with CentOS as of May 2017.

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

Add the following to `/etc/ssh/sshd_config`:

```
AuthorizedKeysCommand /opt/gitlab-shell/authorized_keys %u %k
AuthorizedKeysCommandUser git
```

Reload the SSHD service:

```
sudo service sshd reload
```

Confirm that SSH is working by removing your user's SSH key in the UI, adding a new one, and attempting to pull a repo.

> **Warning:** Do not disable writes until SSH is confirmed to be working perfectly because the file will quickly become out-of-date.

In the case of lookup failures (which are not uncommon), the `authorized_keys` file will still be scanned. So git SSH performance will still be slow for many users as long as a large file exists.

You can disable any more writes to the `authorized_keys` file by unchecking `Write to "authorized_keys" file` in the Application Settings of your GitLab installation.

![Write to authorized keys setting](img/write_to_authorized_keys_setting.png)

Again, confirm that SSH is working by removing your user's SSH key in the UI, adding a new one, and attempting to pull a repo.

Then you can backup and delete your `authorized_keys` file for best performance.

## How to go back to using the `authorized_keys` file

This is a brief overview. Please refer to the above instructions for more context.

1. Rebuild the `authorized_keys` file. See https://docs.gitlab.com/ce/administration/raketasks/maintenance.html#rebuild-authorized_keys-file
1. Enable writes to the `authorized_keys` file
1. Remove the `AuthorizedKeysCommand` lines from `/etc/ssh/sshd_config`
1. Reload the SSHD service
1. Remove the `/opt/gitlab-shell/authorized_keys` file
