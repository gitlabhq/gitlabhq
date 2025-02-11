---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments"
description: "Debugging tips for fixing problems in Git."
title: Troubleshooting Git
---

Sometimes things don't work the way they should or as you might expect when
you're using Git. Here are some tips on troubleshooting and resolving issues
with Git.

## Debugging

When troubleshooting problems with Git, try these debugging techniques.

### Use a custom SSH key for a Git command

```shell
GIT_SSH_COMMAND="ssh -i ~/.ssh/gitlabadmin" git <command>
```

### Debug problems with cloning

For Git over SSH:

```shell
GIT_SSH_COMMAND="ssh -vvv" git clone <git@url>
```

For Git over HTTPS:

```shell
GIT_TRACE_PACKET=1 GIT_TRACE=2 GIT_CURL_VERBOSE=1 git clone <url>
```

### Debug Git with traces

Git includes a complete set of [traces for debugging Git commands](https://git-scm.com/book/en/v2/Git-Internals-Environment-Variables#_debugging), for example:

- `GIT_TRACE_PERFORMANCE=1`: enables tracing of performance data, showing how long each particular `git` invocation takes.
- `GIT_TRACE_SETUP=1`: enables tracing of what `git` is discovering about the repository and environment it's interacting with.
- `GIT_TRACE_PACKET=1`: enables packet-level tracing for network operations.
- `GIT_CURL_VERBOSE=1`: enables `curl`'s verbose output, which [may include credentials](https://curl.se/docs/manpage.html#-v).

## Broken pipe errors on `git push`

'Broken pipe' errors can occur when attempting to push to a remote repository.
When pushing you usually see:

```plaintext
Write failed: Broken pipe
fatal: The remote end hung up unexpectedly
```

To fix this issue, here are some possible solutions.

### Increase the POST buffer size in Git

When you attempt to push large repositories with Git over HTTPS, you might get an error message like:

```shell
fatal: pack has bad object at offset XXXXXXXXX: inflate returned -5
```

To resolve this issue:

- Increase the
  [http.postBuffer](https://git-scm.com/docs/git-config#Documentation/git-config.txt-httppostBuffer)
  value in your local Git configuration. The default value is 1 MB. For example, if `git clone`
  fails when cloning a 500 MB repository, execute the following:

  1. Open a terminal or command prompt.
  1. Increase the `http.postBuffer` value:

      ```shell
      # Set the http.postBuffer size in bytes
      git config http.postBuffer 524288000
      ```

If the local configuration doesn't resolve the issue, you may need to modify the server configuration.
This should be done cautiously and only if you have server access.

- Increase the `http.postBuffer` on the server side:

  1. Open a terminal or command prompt.
  1. Modify the GitLab instance's
    [`gitlab.rb`](https://gitlab.com/gitlab-org/omnibus-gitlab/-/blob/13.5.1+ee.0/files/gitlab-config-template/gitlab.rb.template#L1435-1455) file:

      ```ruby
      gitaly['configuration'] = {
        # ...
        git: {
          # ...
          config: [
            # Set the http.postBuffer size, in bytes
            {key: "http.postBuffer", value: "524288000"},
          ],
        },
      }
      ```

  1. Apply the configuration change:

      ```shell
      sudo gitlab-ctl reconfigure
      ```

### Stream 0 was not closed cleanly

If you see this error, it may be caused by a slow internet connection:

```plaintext
RPC failed; curl 92 HTTP/2 stream 0 was not closed cleanly: INTERNAL_ERROR (err 2)
```

If you use Git over HTTP instead of SSH, try one of these fixes:

- Increase the POST buffer size in the Git configuration with `git config http.postBuffer 52428800`.
- Switch to the `HTTP/1.1` protocol with `git config http.version HTTP/1.1`.

If neither approach fixes the error, you may need a different internet service provider.

### Check your SSH configuration

**If pushing over SSH**, first check your SSH configuration as 'Broken pipe'
errors can sometimes be caused by underlying issues with SSH (such as
authentication). Make sure that SSH is correctly configured by following the
instructions in the [SSH troubleshooting](../../user/ssh_troubleshooting.md#password-prompt-with-git-clone) documentation.

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
  go to "Connection" and under "Sending of null packets to keep
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

or

```plaintext
kex_exchange_identification: Connection closed by remote host
Connection closed by x.x.x.x port 22
```

This error usually indicates that SSH daemon's `MaxStartups` value is throttling
SSH connections. This setting specifies the maximum number of concurrent, unauthenticated
connections to the SSH daemon. This affects users with proper authentication
credentials (SSH keys) because every connection is 'unauthenticated' in the
beginning. The [default value](https://man.openbsd.org/sshd_config#MaxStartups) is `10`.

This can be verified by examining the host's [`sshd`](https://en.wikibooks.org/wiki/OpenSSH/Logging_and_Troubleshooting#Server_Logs)
logs. For systems in the Debian family, refer to `/var/log/auth.log`, and for RHEL derivatives,
check `/var/log/secure` for the following errors:

```plaintext
sshd[17242]: error: beginning MaxStartups throttling
sshd[17242]: drop connection #1 from [CLIENT_IP]:52114 on [CLIENT_IP]:22 past MaxStartups
```

The absence of this error suggests that the SSH daemon is not limiting connections,
indicating that the underlying issue may be network-related.

### Increase the number of unauthenticated concurrent SSH connections

Increase `MaxStartups` on the GitLab server
by adding or modifying the value in `/etc/ssh/sshd_config`:

```plaintext
MaxStartups 100:30:200
```

`100:30:200` means up to 100 SSH sessions are allowed without restriction,
after which 30% of connections are dropped until reaching an absolute maximum of 200.

After you modify the value of `MaxStartups`, check for any errors in the configuration.

```shell
sudo sshd -t -f /etc/ssh/sshd_config
```

If the configuration check runs without errors, it should be safe to restart the
SSH daemon for the change to take effect.

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

### Error: Operation timed out

If you encounter an error like this when using Git, it usually indicates a network issue:

```shell
ssh: connect to host gitlab.com port 22: Operation timed out
fatal: Could not read from remote repository
```

To help identify the underlying issue:

- Connect through a different network (for example, switch from Wi-Fi to cellular data) to rule out
  local network or firewall issues.
- Run this bash command to gather `traceroute` and `ping` information: `mtr -T -P 22 <gitlab_server>.com`.
  To learn about MTR and how to read its output, see the Cloudflare article
  [What is My Traceroute (MTR)?](https://www.cloudflare.com/en-gb/learning/network-layer/what-is-mtr/).

## Error: transfer closed with outstanding read data remaining

Sometimes, when cloning old or large repositories, the following error is shown when running `git clone` over HTTP:

```plaintext
error: RPC failed; curl 18 transfer closed with outstanding read data remaining
fatal: The remote end hung up unexpectedly
fatal: early EOF
fatal: index-pack failed
```

This problem is common in Git itself, due to its inability to handle large files or large quantities of files.
[Git LFS](https://about.gitlab.com/blog/2017/01/30/getting-started-with-git-lfs-tutorial/) was created to work around this problem; however, even it has limitations. It's usually due to one of these reasons:

- The number of files in the repository.
- The number of revisions in the history.
- The existence of large files in the repository.

If this error occurs when cloning a large repository, you can
[decrease the cloning depth](../../user/project/repository/monorepos/_index.md#shallow-cloning) to a value of `1`. For example:

This approach doesn't resolve the underlying cause, but you can successfully clone the repository.
To decrease the cloning depth to `1`, run:

  ```shell
  variables:
    GIT_DEPTH: 1
  ```

## Password expired error on Git fetch with SSH for LDAP user

If `git fetch` returns this `HTTP 403 Forbidden` error on GitLab Self-Managed,
the password expiration date (`users.password_expires_at`) for this user in the
GitLab database is a date in the past:

```plaintext
Your password expired. Please access GitLab from a web browser to update your password.
```

Requests made with a SSO account and where `password_expires_at` is not `null`
return this error:

```plaintext
"403 Forbidden - Your password expired. Please access GitLab from a web browser to update your password."
```

To resolve this issue, you can update the password expiration by either:

- Using the [GitLab Rails console](../../administration/operations/rails_console.md)
  to check and update the user data:

  ```ruby
  user = User.find_by_username('<USERNAME>')
  user.password_expired?
  user.password_expires_at
  user.update!(password_expires_at: nil)
  ```

- Using `gitlab-psql`:

  ```sql
  # gitlab-psql
  UPDATE users SET password_expires_at = null WHERE username='<USERNAME>';
  ```

The bug was reported [in this issue](https://gitlab.com/gitlab-org/gitlab/-/issues/332455).

## Error on Git fetch: "HTTP Basic: Access Denied"

If you receive an `HTTP Basic: Access denied` error when using Git over HTTP(S),
refer to the [two-factor authentication troubleshooting guide](../../user/profile/account/two_factor_authentication_troubleshooting.md).

This error may also occur with [Git for Windows](https://gitforwindows.org/)
2.46.0 and later when specifying an empty username.
When authenticating with a token, the username can be any value, but an empty value
could trigger an authentication error. To resolve this, specify a username string.

## `401` errors logged during successful `git clone`

When cloning a repository with HTTP, the
[`production_json.log`](../../administration/logs/_index.md#production_jsonlog) file
may show an initial status of `401` (unauthorized), quickly followed by a `200`.

```json
{
   "method":"GET",
   "path":"/group/project.git/info/refs",
   "format":"*/*",
   "controller":"Repositories::GitHttpController",
   "action":"info_refs",
   "status":401,
   "time":"2023-04-18T22:55:15.371Z",
   "remote_ip":"x.x.x.x",
   "ua":"git/2.39.2",
   "correlation_id":"01GYB98MBM28T981DJDGAD98WZ",
   "duration_s":0.03585
}
{
   "method":"GET",
   "path":"/group/project.git/info/refs",
   "format":"*/*",
   "controller":"Repositories::GitHttpController",
   "action":"info_refs",
   "status":200,
   "time":"2023-04-18T22:55:15.714Z",
   "remote_ip":"x.x.x.x",
   "user_id":1,
   "username":"root",
   "ua":"git/2.39.2",
   "correlation_id":"01GYB98MJ0CA3G9K8WDH7HWMQX",
   "duration_s":0.17111
}
```

You should expect this initial `401` log entry for each Git operation performed over HTTP,
due to how [HTTP Basic authentication](https://en.wikipedia.org/wiki/Basic_access_authentication) works.

When the Git client initiates a clone, the initial request sent to GitLab does not provide
any authentication details. GitLab returns a `401 Unauthorized` result for that request.
A few milliseconds later, the Git client sends a follow-up request containing authentication
details. This second request should succeed, and result in a `200 OK` log entry.

If a `401` log entry lacks a corresponding `200` log entry, the Git client is likely using either:

- An incorrect password.
- An expired or revoked token.

If not rectified, you could encounter
[`403` (Forbidden) errors](#403-error-when-performing-git-operations-over-http)
instead.

## `403` error when performing Git operations over HTTP

When performing Git operations over HTTP, a `403` (Forbidden) error indicates that
your IP address has been blocked by the failed-authentication ban:

```plaintext
fatal: unable to access 'https://gitlab.com/group/project.git/': The requested URL returned error: 403
```

The `403` can be seen in the [`production_json.log`](../../administration/logs/_index.md#production_jsonlog):

```json
{
   "method":"GET",
   "path":"/group/project.git/info/refs",
   "format":"*/*",
   "controller":"Repositories::GitHttpController",
   "action":"info_refs",
   "status":403,
   "time":"2023-04-19T22:14:25.894Z",
   "remote_ip":"x.x.x.x",
   "user_id":1,
   "username":"root",
   "ua":"git/2.39.2",
   "correlation_id":"01GYDSAKAN2SPZPAMJNRWW5H8S",
   "duration_s":0.00875
}
```

If your IP address has been blocked, a corresponding log entry exists in the
[`auth_json.log`](../../administration/logs/_index.md#auth_jsonlog):

```json
{
    "severity":"ERROR",
    "time":"2023-04-19T22:14:25.893Z",
    "correlation_id":"01GYDSAKAN2SPZPAMJNRWW5H8S",
    "message":"Rack_Attack",
    "env":"blocklist",
    "remote_ip":"x.x.x.x",
    "request_method":"GET",
    "path":"/group/project.git/info/refs?service=git-upload-pack"}
```

The failed authentication ban limits differ depending if you are using a
[GitLab Self-Managed](../../security/rate_limits.md#failed-authentication-ban-for-git-and-container-registry)
or [GitLab SaaS](../../user/gitlab_com/_index.md#ip-blocks).
