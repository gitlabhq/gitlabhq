# Gitaly

[Gitaly](https://gitlab.com/gitlab-org/gitlay) (introduced in GitLab
9.0) is a service that provides high-level RPC access to Git
repositories. As of GitLab 9.0 it is still an optional component with
limited scope.

GitLab components that access Git repositories (gitlab-rails,
gitlab-shell, gitlab-workhorse) act as clients to Gitaly. End users do
not have direct access to Gitaly.

## Configuring Gitaly

The Gitaly service itself is configured via environment variables.
These variables are documented [in the gitaly
repository](https://gitlab.com/gitlab-org/gitaly/blob/master/doc/configuration/README.md).

To change a Gitaly environment variable in Omnibus you can use
`gitaly['env']` in `/etc/gitlab/gitlab.rb`. Changes will be applied
when you run `gitlab-ctl reconfigure`.

```ruby
gitaly['env'] = {
  'GITALY_MY_VARIABLE' => 'value'
}
```

To change a Gitaly environment variable in installations from source
you can edit `/home/git/gitaly/env`.

```shell
GITALY_MY_VARIABLE='value'
```

Changes to `/home/git/gitaly/env` are applied when you run `service
gitlab restart`.

## Configuring GitLab to not use Gitaly

Gitaly is still an optional component in GitLab 9.0. This means you
can choose to not use it.

In Omnibus you can make the following change in
`/etc/gitlab/gitlab.rb` and reconfigure. This will both disable the
Gitaly service and configure the rest of GitLab not to use it.

```ruby
gitaly['enable'] = false
```

In source installations, edit `/home/git/gitlab/config/gitlab.yml` and
make sure `socket_path` in the `gitaly` section is commented out. This
does not disable the Gitaly service; it only prevents it from being
used.

Apply the change with `service gitlab restart`.

```yaml
  gitaly:
    # socket_path: tmp/sockets/private/gitlay.socket
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