# Troubleshooting Git

Sometimes things don't work the way they should or as you might expect when
you're using Git. Here are some tips on troubleshooting and resolving issues
with Git.

## Broken pipe errors on git push

'Broken pipe' errors can occur when attempting to push to a remote repository.
When pushing you will usually see:

```
Write failed: Broken pipe
fatal: The remote end hung up unexpectedly
```

To fix this issue, here are some possible solutions.

### Increase the POST buffer size in Git

**If pushing over HTTP**, you can try increasing the POST buffer size in Git's
configuration. Open a terminal and enter:

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

NOTE: **Note:** configuring *both* the client and the server is unnecessary.

**To configure SSH on the client side**:

-  On UNIX, edit `~/.ssh/config` (create the file if it doesn’t exist) and
   add or edit:

    ```
    Host your-gitlab-instance-url.com
      ServerAliveInterval 60
      ServerAliveCountMax 5
    ```

- On Windows, if you are using PuTTY, go to your session properties, then
  navigate to "Connection" and under "Sending of null packets to keep
  session active", set "Seconds between keepalives (0 to turn off)" to `60`.

**To configure SSH on the server side**, edit `/etc/ssh/sshd_config` and add:

```
ClientAliveInterval 60
ClientAliveCountMax 5
```

### Running a git repack

**If 'pack-objects' type errors are also being displayed**, you can try to
run a `git repack` before attempting to push to the remote repository again:

```sh
git repack
git push
```

### Upgrade your Git client

In case you're running an older version of Git (< 2.9), consider upgrading
to >= 2.9 (see [Broken pipe when pushing to Git repository][Broken-Pipe]).

[SSH troubleshooting]: ../../ssh/README.md#troubleshooting "SSH Troubleshooting"
[Broken-Pipe]: https://stackoverflow.com/questions/19120120/broken-pipe-when-pushing-to-git-repository/36971469#36971469 "StackOverflow: 'Broken pipe when pushing to Git repository'"
