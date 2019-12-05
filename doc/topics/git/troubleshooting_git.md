---
type: howto
---

# Troubleshooting Git

Sometimes things don't work the way they should or as you might expect when
you're using Git. Here are some tips on troubleshooting and resolving issues
with Git.

## Broken pipe errors on `git push`

'Broken pipe' errors can occur when attempting to push to a remote repository.
When pushing you will usually see:

```text
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

```sh
git config http.postBuffer 52428800
```

The value is specified in bytes, so in the above case the buffer size has been
set to 50MB. The default is 1MB.

### Check your SSH configuration

**If pushing over SSH**, first check your SSH configuration as 'Broken pipe'
errors can sometimes be caused by underlying issues with SSH (such as
authentication). Make sure that SSH is correctly configured by following the
instructions in the [SSH troubleshooting] docs.

There's another option where you can prevent session timeouts by configuring
SSH 'keep alive' either on the client or on the server (if you are a GitLab
admin and have access to the server).

NOTE: **Note:**
Configuring *both* the client and the server is unnecessary.

**To configure SSH on the client side**:

- On UNIX, edit `~/.ssh/config` (create the file if it doesn’t exist) and
  add or edit:

  ```text
  Host your-gitlab-instance-url.com
    ServerAliveInterval 60
    ServerAliveCountMax 5
  ```

- On Windows, if you are using PuTTY, go to your session properties, then
  navigate to "Connection" and under "Sending of null packets to keep
  session active", set "Seconds between keepalives (0 to turn off)" to `60`.

**To configure SSH on the server side**, edit `/etc/ssh/sshd_config` and add:

```text
ClientAliveInterval 60
ClientAliveCountMax 5
```

### Running a `git repack`

**If 'pack-objects' type errors are also being displayed**, you can try to
run a `git repack` before attempting to push to the remote repository again:

```sh
git repack
git push
```

### Upgrade your Git client

In case you're running an older version of Git (< 2.9), consider upgrading
to >= 2.9 (see [Broken pipe when pushing to Git repository][Broken-Pipe]).

## `ssh_exchange_identification` error

Users may experience the following error when attempting to push or pull
using Git over SSH:

```text
Please make sure you have the correct access rights
and the repository exists.
...
ssh_exchange_identification: read: Connection reset by peer
fatal: Could not read from remote repository.
```

This error usually indicates that SSH daemon's `MaxStartups` value is throttling
SSH connections. This setting specifies the maximum number of unauthenticated
connections to the SSH daemon. This affects users with proper authentication
credentials (SSH keys) because every connection is 'unauthenticated' in the
beginning. The default value is `10`.

Increase `MaxStartups` by adding or modifying the value in `/etc/ssh/sshd_config`:

```text
MaxStartups 100
```

Restart SSHD for the change to take effect.

## Timeout during `git push` / `git pull`

If pulling/pushing from/to your repository ends up taking more than 50 seconds,
a timeout will be issued with a log of the number of operations performed
and their respective timings, like the example below:

```text
remote: Running checks for branch: master
remote: Scanning for LFS objects... (153ms)
remote: Calculating new repository size... (cancelled after 729ms)
```

This could be used to further investigate what operation is performing poorly
and provide GitLab with more information on how to improve the service.

## `git clone` over HTTP fails with `transfer closed with outstanding read data remaining` error

If the buffer size is lower than what is allowed in the request, the action will fail with an error similar to the one below:

```text
error: RPC failed; curl 18 transfer closed with outstanding read data remaining
fatal: The remote end hung up unexpectedly
fatal: early EOF
fatal: index-pack failed
```

This can be fixed by increasing the existing `http.postBuffer` value to one greater than the repository size. For example, if `git clone` fails when cloning a 500M repository, the solution will be to set `http.postBuffer` to `524288000` so that the request only starts buffering after the first 524288000 bytes.

NOTE: **Note:**
The default value of `http.postBuffer`, 1 MiB, is applied if the setting is not configured.

```sh
git config http.postBuffer 524288000
```

[SSH troubleshooting]: ../../ssh/README.md#troubleshooting "SSH Troubleshooting"
[Broken-Pipe]: https://stackoverflow.com/questions/19120120/broken-pipe-when-pushing-to-git-repository/36971469#36971469 "StackOverflow: 'Broken pipe when pushing to Git repository'"
