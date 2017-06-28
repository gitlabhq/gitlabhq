# Gitaly

[Gitaly](https://gitlab.com/gitlab-org/gitaly) (introduced in GitLab
9.0) is a service that provides high-level RPC access to Git
repositories. As of GitLab 9.3 it is still an optional component with
limited scope.

GitLab components that access Git repositories (gitlab-rails,
gitlab-shell, gitlab-workhorse) act as clients to Gitaly. End users do
not have direct access to Gitaly.

## Configuring Gitaly

The Gitaly service itself is configured via a TOML configuration file.
This file is documented [in the gitaly
repository](https://gitlab.com/gitlab-org/gitaly/blob/master/doc/configuration/README.md).

To change a Gitaly setting in Omnibus you can use
`gitaly['my_setting']` in `/etc/gitlab/gitlab.rb`. Changes will be applied
when you run `gitlab-ctl reconfigure`.

```ruby
gitaly['prometheus_listen_addr'] = 'localhost:9236'
```

To change a Gitaly setting in installations from source you can edit
`/home/git/gitaly/config.toml`.

```toml
prometheus_listen_addr = "localhost:9236"
```

Changes to `/home/git/gitaly/config.toml` are applied when you run `service
gitlab restart`.

## Running Gitaly on its own server

> This is an optional way to deploy Gitaly which can benefit GitLab
installations that are larger than a single machine. Most
installations will be better served with the default configuration
used by Omnibus and the GitLab source installation guide.

Starting with GitLab 9.4 it is possible to run Gitaly on a different
server from the rest of the application. This can improve performance
when running GitLab with its repositories stored on an NFS server.

At the moment (GitLab 9.4) Gitaly is not yet a replacement for NFS
because some parts of GitLab still bypass Gitaly when accessing Git
repositories. If you choose to deploy Gitaly on your NFS server you
must still also mount your Git shares on your GitLab application
servers.

Gitaly network traffic is unencrypted so you should use a firewall to
restrict access to your Gitaly server.

Below we describe how to configure a Gitaly server at address
`gitaly.internal:9999` with secret token `abc123secret`. We assume
your GitLab installation has two repository storages, `default` and
`storage1`.

### Client side token configuration

Start by configuring a token on the client side.

Omnibus installations:

```ruby
# /etc/gitlab/gitlab.rb
gitlab_rails['gitaly_token'] = 'abc123secret'
```

Source installations:

```yaml
# /home/git/gitlab/config/gitlab.yml
gitlab:
  gitaly:
    token: 'abc123secret'
```

You need to reconfigure (Omnibus) or restart (source) for these
changes to be picked up.

### Gitaly server configuration

Next, on the Gitaly server, we need to configure storage paths, enable
the network listener and configure the token.

Note: if you want to reduce the risk of downtime when you enable
authentication you can temporarily disable enforcement, see [the
documentation on configuring Gitaly
authentication](https://gitlab.com/gitlab-org/gitaly/blob/master/doc/configuration/README.md#authentication)
.

In most or all cases the storage paths below end in `/repositories`. Check the
directory layout on your Gitaly server to be sure.

Omnibus installations:

```ruby
# /etc/gitlab/gitlab.rb
gitaly['listen_addr'] = '0.0.0.0:9999'
gitaly['auth_token'] = 'abc123secret'
gitaly['storage'] = [
  { 'name' => 'default', 'path' => '/path/to/default/repositories' },
  { 'name' => 'storage1', 'path' => '/path/to/storage1/repositories' },
]
```

Source installations:

```toml
# /home/git/gitaly/config.toml
listen_addr = '0.0.0.0:9999'

[auth]
token = 'abc123secret'

[[storage]
name = 'default'
path = '/path/to/default/repositories'

[[storage]]
name = 'storage1'
path = '/path/to/storage1/repositories'
```

Again, reconfigure (Omnibus) or restart (source).

### Converting clients to use the Gitaly server

Now as the final step update the client machines to switch from using
their local Gitaly service to the new Gitaly server you just
configured. This is a risky step because if there is any sort of
network, firewall, or name resolution problem preventing your GitLab
server from reaching the Gitaly server then all Gitaly requests will
fail.

We assume that your Gitaly server can be reached at
`gitaly.internal:9999` from your GitLab server, and that your GitLab
NFS shares are mounted at `/mnt/gitlab/default` and
`/mnt/gitlab/storage1` respectively.

Omnibus installations:

```ruby
# /etc/gitlab/gitlab.rb
git_data_dirs({
  { 'default' => { 'path' => '/mnt/gitlab/default', 'gitaly_address' => 'tcp://gitlab.internal:9999' } },
  { 'storage1' => { 'path' => '/mnt/gitlab/storage1', 'gitaly_address' => 'tcp://gitlab.internal:9999' } },
})
```

Source installations:

```yaml
# /home/git/gitlab/config/gitlab.yml
gitlab:
  repositories:
    storages:
      default:
        path: /mnt/gitlab/default/repositories
        gitaly_address: tcp://gitlab.internal:9999
      storage1:
        path: /mnt/gitlab/storage1/repositories
        gitaly_address: tcp://gitlab.internal:9999
```

Now reconfigure (Omnibus) or restart (source). When you tail the
Gitaly logs on your Gitaly server (`sudo gitlab-ctl tail gitaly` or
`tail -f /home/git/gitlab/log/gitaly.log`) you should see requests
coming in. One sure way to trigger a Gitaly request is to clone a
repository from your GitLab server over HTTP.

## Configuring GitLab to not use Gitaly

Gitaly is still an optional component in GitLab 9.3. This means you
can choose to not use it.

In Omnibus you can make the following change in
`/etc/gitlab/gitlab.rb` and reconfigure. This will both disable the
Gitaly service and configure the rest of GitLab not to use it.

```ruby
gitaly['enable'] = false
```

In source installations, edit `/home/git/gitlab/config/gitlab.yml` and
make sure `enabled` in the `gitaly` section is set to 'false'. This
does not disable the Gitaly service in your init script; it only
prevents it from being used.

Apply the change with `service gitlab restart`.

```yaml
  gitaly:
    enabled: false
```

## Disabling or enabling the Gitaly service

Be careful: if you disable Gitaly without instructing the rest of your
GitLab installation not to use Gitaly, you may end up with errors
because GitLab tries to access a service that is not running.

To disable the Gitaly service in your Omnibus installation, add the
following line to `/etc/gitlab/gitlab.rb`:

```ruby
gitaly['enable'] = false
```

When you run `gitlab-ctl reconfigure` the Gitaly service will be
disabled.

To disable the Gitaly service in an installation from source, add the
following to `/etc/default/gitlab`:

```shell
gitaly_enabled=false
```

When you run `service gitlab restart` Gitaly will be disabled.