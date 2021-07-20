---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments"
type: howto
---

# Troubleshooting Git **(FREE)**

Sometimes things don't work the way they should or as you might expect when
you're using Git. Here are some tips on troubleshooting and resolving issues
with Git.

## Broken pipe errors on `git push`

'Broken pipe' errors can occur when attempting to push to a remote repository.
When pushing you usually see:

```plaintext
Write failed: Broken pipe
fatal: The remote end hung up unexpectedly
```

To fix this issue, here are some possible solutions.

### Increase the POST buffer size in Git

**If you're using Git over HTTP instead of SSH**, you can try increasing the POST buffer size in Git's
configuration.

Example of an error during a clone:
`fatal: pack has bad object at offset XXXXXXXXX: inflate returned -5`

Open a terminal and enter:

```shell
git config http.postBuffer 52428800
```

The value is specified in bytes, so in the above case the buffer size has been
set to 50MB. The default is 1MB.

### Check your SSH configuration

**If pushing over SSH**, first check your SSH configuration as 'Broken pipe'
errors can sometimes be caused by underlying issues with SSH (such as
authentication). Make sure that SSH is correctly configured by following the
instructions in the [SSH troubleshooting](../../ssh/index.md#troubleshooting-ssh-connections) documentation.

If you're a GitLab administrator with server access, you can also prevent
session timeouts by configuring SSH `keep-alive` on the client or the server.

NOTE:
Configuring both the client and the server is unnecessary.

**To configure SSH on the client side**:

- On UNIX, edit `~/.ssh/config` (create the file if it doesn't exist) and
  add or edit:

  ```plaintext
  Host your-gitlab-instance-url.com
    ServerAliveInterval 60
    ServerAliveCountMax 5
  ```

- On Windows, if you are using PuTTY, go to your session properties, then
  navigate to "Connection" and under "Sending of null packets to keep
  session active", set `Seconds between keepalives (0 to turn off)` to `60`.

**To configure SSH on the server side**, edit `/etc/ssh/sshd_config` and add:

```plaintext
ClientAliveInterval 60
ClientAliveCountMax 5
```

### Running a `git repack`

**If 'pack-objects' type errors are also being displayed**, you can try to
run a `git repack` before attempting to push to the remote repository again:

```shell
git repack
git push
```

### Upgrade your Git client

In case you're running an older version of Git (< 2.9), consider upgrading
to >= 2.9 (see [Broken pipe when pushing to Git repository](https://stackoverflow.com/questions/19120120/broken-pipe-when-pushing-to-git-repository/36971469#36971469)).

## `ssh_exchange_identification` error

Users may experience the following error when attempting to push or pull
using Git over SSH:

```plaintext
Please make sure you have the correct access rights
and the repository exists.
...
ssh_exchange_identification: read: Connection reset by peer
fatal: Could not read from remote repository.
```

or

```plaintext
ssh_exchange_identification: Connection closed by remote host
fatal: The remote end hung up unexpectedly
```

This error usually indicates that SSH daemon's `MaxStartups` value is throttling
SSH connections. This setting specifies the maximum number of concurrent, unauthenticated
connections to the SSH daemon. This affects users with proper authentication
credentials (SSH keys) because every connection is 'unauthenticated' in the
beginning. The default value is `10`.

Increase `MaxStartups` on the GitLab server
by adding or modifying the value in `/etc/ssh/sshd_config`:

```plaintext
MaxStartups 100:30:200
```

`100:30:200` means up to 100 SSH sessions are allowed without restriction,
after which 30% of connections are dropped until reaching an absolute maximum of 200.

Once configured, restart the SSH daemon for the change to take effect.

```shell
# Debian/Ubuntu
sudo systemctl restart ssh

# CentOS/RHEL
sudo service sshd restart
```

## Timeout during `git push` / `git pull`

If pulling/pushing from/to your repository ends up taking more than 50 seconds,
a timeout is issued. It contains a log of the number of operations performed
and their respective timings, like the example below:

```plaintext
remote: Running checks for branch: master
remote: Scanning for LFS objects... (153ms)
remote: Calculating new repository size... (cancelled after 729ms)
```

This could be used to further investigate what operation is performing poorly
and provide GitLab with more information on how to improve the service.

## `git clone` over HTTP fails with `transfer closed with outstanding read data remaining` error

Sometimes, when cloning old or large repositories, the following error is thrown:

```plaintext
error: RPC failed; curl 18 transfer closed with outstanding read data remaining
fatal: The remote end hung up unexpectedly
fatal: early EOF
fatal: index-pack failed
```

This is a common problem with Git itself, due to its inability to handle large files or large quantities of files.
[Git LFS](https://about.gitlab.com/blog/2017/01/30/getting-started-with-git-lfs-tutorial/) was created to work around this problem; however, even it has limitations. It's usually due to one of these reasons:

- The number of files in the repository.
- The number of revisions in the history.
- The existence of large files in the repository.

The root causes vary, so multiple potential solutions exist, and you may need to
apply more than one:

- If this error occurs when cloning a large repository, you can
  [decrease the cloning depth](../../ci/large_repositories/index.md#shallow-cloning)
  to a value of `1`. For example:

  ```shell
  variables:
    GIT_DEPTH: 1
  ```

- You can increase the
  [http.postBuffer](https://git-scm.com/docs/git-config#Documentation/git-config.txt-httppostBuffer)
  value in your local Git configuration from the default 1 MB value to a value greater
  than the repository size. For example, if `git clone` fails when cloning a 500 MB
  repository, you should set `http.postBuffer` to `524288000`:

  ```shell
  # Set the http.postBuffer size, in bytes
  git config http.postBuffer 524288000
  ```

- You can increase the `http.postBuffer` on the server side:

  1. Modify the GitLab instance's
     [`gitlab.rb`](https://gitlab.com/gitlab-org/omnibus-gitlab/-/blob/13.5.1+ee.0/files/gitlab-config-template/gitlab.rb.template#L1435-1455) file:

     ```shell
     omnibus_gitconfig['system'] = {
       # Set the http.postBuffer size, in bytes
       "http" => ["postBuffer" => 524288000]
     }
     ```

  1. After applying this change, apply the configuration change:

     ```shell
     sudo gitlab-ctl reconfigure
     ```

For example, if a repository has a very long history and no large files, changing
the depth should fix the problem. However, if a repository has very large files,
even a depth of 1 may be too large, thus requiring the `postBuffer` change.
If you increase your local `postBuffer` but the NGINX value on the backend is still
too small, the error persists.

Modifying the server is not always an option, and introduces more potential risk.
Attempt local changes first.
