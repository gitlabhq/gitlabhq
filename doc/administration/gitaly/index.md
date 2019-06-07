# Gitaly

[Gitaly](https://gitlab.com/gitlab-org/gitaly) is the service that
provides high-level RPC access to Git repositories. Without it, no other
components can read or write Git data.

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
`/home/git/gitaly/config.toml`. Changes will be applied when you run
`service gitlab restart`.

```toml
prometheus_listen_addr = "localhost:9236"
```

## Client-side GRPC logs

Gitaly uses the [gRPC](https://grpc.io/) RPC framework. The Ruby gRPC
client has its own log file which may contain useful information when
you are seeing Gitaly errors. You can control the log level of the
gRPC client with the `GRPC_LOG_LEVEL` environment variable. The
default level is `WARN`.

## Running Gitaly on its own server

> This is an optional way to deploy Gitaly which can benefit GitLab
installations that are larger than a single machine. Most
installations will be better served with the default configuration
used by Omnibus and the GitLab source installation guide.

Starting with GitLab 11.4, Gitaly is able to serve all Git requests without
needed a shared NFS mount for Git repository data.
Between 11.4 and 11.8 the exception was the
[Elastic Search indexer](https://gitlab.com/gitlab-org/gitlab-elasticsearch-indexer).
But since 11.8 the indexer uses Gitaly for data access as well. NFS can still
be leveraged for redudancy on block level of the Git data. But only has to
be mounted on the Gitaly server.

NOTE: **Note:** While Gitaly can be used as a replacement for NFS, we do not recommend
using EFS as it may impact GitLab's performance. Please review the [relevant documentation](../high_availability/nfs.md#avoid-using-awss-elastic-file-system-efs)
for more details.

### Network architecture

-   gitlab-rails shards repositories into "repository storages"
-   `gitlab-rails/config/gitlab.yml` contains a map from storage names to
    (Gitaly address, Gitaly token) pairs
-   the `storage name` -\> `(Gitaly address, Gitaly token)` map in
    `gitlab.yml` is the single source of truth for the Gitaly network
    topology
-   a (Gitaly address, Gitaly token) corresponds to a Gitaly server
-   a Gitaly server hosts one or more storages
-   Gitaly addresses must be specified in such a way that they resolve
    correctly for ALL Gitaly clients
-   Gitaly clients are: unicorn, sidekiq, gitlab-workhorse,
    gitlab-shell, Elasticsearch Indexer, and Gitaly itself
-   special case: a Gitaly server must be able to make RPC calls **to
    itself** via its own (Gitaly address, Gitaly token) pair as
    specified in `gitlab-rails/config/gitlab.yml`
-   Gitaly servers must not be exposed to the public internet

Gitaly network traffic is unencrypted by default, but supports
[TLS](#tls-support). Authentication is done through a static token.

NOTE: **Note:** Gitaly network traffic is unencrypted so we recommend a firewall to
restrict access to your Gitaly server.

Below we describe how to configure a Gitaly server at address
`gitaly.internal:8075` with secret token `abc123secret`. We assume
your GitLab installation has two repository storages, `default` and
`storage1`.

### Installation

First install Gitaly using either Omnibus or from source.

Omnibus: [Download/install](https://about.gitlab.com/installation) the Omnibus GitLab
package you want using **steps 1 and 2** from the GitLab downloads page but
**_do not_** provide the `EXTERNAL_URL=` value.

Source: [Install Gitaly](../../install/installation.md#install-gitaly)

### Client side token configuration

Configure a token on the client side.

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

NOTE: **Note:** if you want to reduce the risk of downtime when you enable
authentication you can temporarily disable enforcement, see [the
documentation on configuring Gitaly
authentication](https://gitlab.com/gitlab-org/gitaly/blob/master/doc/configuration/README.md#authentication)
.

Gitaly must trigger some callbacks to GitLab via GitLab Shell. As a result,
the GitLab Shell secret must be the same between the other GitLab servers and
the Gitaly server. The easiest way to accomplish this is to copy `/etc/gitlab/gitlab-secrets.json`
from an existing GitLab server to the Gitaly server. Without this shared secret,
Git operations in GitLab will result in an API error.

NOTE: **Note:** In most or all cases the storage paths below end in `/repositories` which is
different than `path` in `git_data_dirs` of Omnibus installations. Check the
directory layout on your Gitaly server to be sure.

Omnibus installations:

<!--
updates to following example must also be made at
https://gitlab.com/charts/gitlab/blob/master/doc/advanced/external-gitaly/external-omnibus-gitaly.md#configure-omnibus-gitlab
-->

```ruby
# /etc/gitlab/gitlab.rb

# Avoid running unnecessary services on the Gitaly server
postgresql['enable'] = false
redis['enable'] = false
nginx['enable'] = false
prometheus['enable'] = false
unicorn['enable'] = false
sidekiq['enable'] = false
gitlab_workhorse['enable'] = false

# Prevent database connections during 'gitlab-ctl reconfigure'
gitlab_rails['rake_cache_clear'] = false
gitlab_rails['auto_migrate'] = false

# Configure the gitlab-shell API callback URL. Without this, `git push` will
# fail. This can be your 'front door' GitLab URL or an internal load
# balancer.
# Don't forget to copy `/etc/gitlab/gitlab-secrets.json` from web server to Gitaly server.
gitlab_rails['internal_api_url'] = 'https://gitlab.example.com'

# Make Gitaly accept connections on all network interfaces. You must use
# firewalls to restrict access to this address/port.
gitaly['listen_addr'] = "0.0.0.0:8075"
gitaly['auth_token'] = 'abc123secret'

gitaly['storage'] = [
  { 'name' => 'default', 'path' => '/mnt/gitlab/default/repositories' },
  { 'name' => 'storage1', 'path' => '/mnt/gitlab/storage1/repositories' },
]

# To use TLS for Gitaly you need to add
gitaly['tls_listen_addr'] = "0.0.0.0:9999"
gitaly['certificate_path'] = "path/to/cert.pem"
gitaly['key_path'] = "path/to/key.pem"
```

Source installations:

```toml
# /home/git/gitaly/config.toml
listen_addr = '0.0.0.0:8075'
tls_listen_addr = '0.0.0.0:9999'

[tls]
certificate_path = /path/to/cert.pem
key_path = /path/to/key.pem

[auth]
token = 'abc123secret'

[[storage]]
name = 'default'
path = '/mnt/gitlab/default/repositories'

[[storage]]
name = 'storage1'
path = '/mnt/gitlab/storage1/repositories'
```

Again, reconfigure (Omnibus) or restart (source).

### Converting clients to use the Gitaly server

Now as the final step update the client machines to switch from using
their local Gitaly service to the new Gitaly server you just
configured. This is a risky step because if there is any sort of
network, firewall, or name resolution problem preventing your GitLab
server from reaching the Gitaly server then all Gitaly requests will
fail.

Additionally, you need to 
[disable Rugged if previously manually enabled](../high_availability/nfs.md#improving-nfs-performance-with-gitlab).

We assume that your Gitaly server can be reached at
`gitaly.internal:8075` from your GitLab server, and that Gitaly can read and
write to `/mnt/gitlab/default` and `/mnt/gitlab/storage1` respectively.

Omnibus installations:

```ruby
# /etc/gitlab/gitlab.rb
git_data_dirs({
  'default' => { 'gitaly_address' => 'tcp://gitaly.internal:8075' },
  'storage1' => { 'gitaly_address' => 'tcp://gitaly.internal:8075' },
})

gitlab_rails['gitaly_token'] = 'abc123secret'
```

Source installations:

```yaml
# /home/git/gitlab/config/gitlab.yml
gitlab:
  repositories:
    storages:
      default:
        gitaly_address: tcp://gitaly.internal:8075
      storage1:
        gitaly_address: tcp://gitaly.internal:8075

  gitaly:
    token: 'abc123secret'
```

Now reconfigure (Omnibus) or restart (source). When you tail the
Gitaly logs on your Gitaly server (`sudo gitlab-ctl tail gitaly` or
`tail -f /home/git/gitlab/log/gitaly.log`) you should see requests
coming in. One sure way to trigger a Gitaly request is to clone a
repository from your GitLab server over HTTP.

## TLS support

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/22602) in GitLab 11.8.

Gitaly supports TLS encryption. To be able to communicate
with a Gitaly instance that listens for secure connections you will need to use `tls://` url
scheme in the `gitaly_address` of the corresponding storage entry in the gitlab configuration.

The admin needs to bring their own certificate as we do not provide that automatically.
The certificate to be used needs to be installed on all Gitaly nodes and on all client nodes that communicate with it following procedures described in [GitLab custom certificate configuration](https://docs.gitlab.com/omnibus/settings/ssl.html#install-custom-public-certificates).

Note that it is possible to configure Gitaly servers with both an
unencrypted listening address `listen_addr` and an encrypted listening
address `tls_listen_addr` at the same time. This allows you to do a
gradual transition from unencrypted to encrypted traffic, if necessary.

To observe what type of connections are actually being used in a
production environment you can use the following Prometheus query:

```
sum(rate(gitaly_connections_total[5m])) by (type)
```

### Example TLS configuration

### Omnibus installations:

#### On client nodes:

```ruby
# /etc/gitlab/gitlab.rb
git_data_dirs({
  'default' => { 'path' => '/mnt/gitlab/default', 'gitaly_address' => 'tls://gitaly.internal:9999' },
  'storage1' => { 'path' => '/mnt/gitlab/storage1', 'gitaly_address' => 'tls://gitaly.internal:9999' },
})

gitlab_rails['gitaly_token'] = 'abc123secret'
```

#### On Gitaly server nodes:

```ruby
gitaly['tls_listen_addr'] = "0.0.0.0:9999"
gitaly['certificate_path'] = "path/to/cert.pem"
gitaly['key_path'] = "path/to/key.pem"
```

### Source installations:

#### On client nodes:

```yaml
# /home/git/gitlab/config/gitlab.yml
gitlab:
  repositories:
    storages:
      default:
        path: /mnt/gitlab/default/repositories
        gitaly_address: tls://gitaly.internal:9999
      storage1:
        path: /mnt/gitlab/storage1/repositories
        gitaly_address: tls://gitaly.internal:9999

  gitaly:
    token: 'abc123secret'
```

#### On Gitaly server nodes:

```toml
# /home/git/gitaly/config.toml
tls_listen_addr = '0.0.0.0:9999'

[tls]
certificate_path = '/path/to/cert.pem'
key_path = '/path/to/key.pem'
```

## Gitaly-ruby

Gitaly was developed to replace Ruby application code in gitlab-ce/ee.
In order to save time and/or avoid the risk of rewriting existing
application logic, in some cases we chose to copy some application code
from gitlab-ce into Gitaly almost as-is. To be able to run that code, we
made gitaly-ruby, which is a sidecar process for the main Gitaly Go
process. Some examples of things that are implemented in gitaly-ruby are
RPC's that deal with wiki's, and RPC's that create commits on behalf of
a user, such as merge commits.

### Number of gitaly-ruby workers

Gitaly-ruby has much less capacity than Gitaly itself. If your Gitaly
server has to handle a lot of request, the default setting of having
just 1 active gitaly-ruby sidecar might not be enough. If you see
ResourceExhausted errors from Gitaly it's very likely that you have not
enough gitaly-ruby capacity.

You can increase the number of gitaly-ruby processes on your Gitaly
server with the following settings.

Omnibus:

```ruby
# /etc/gitlab/gitlab.rb
# Default is 2 workers. The minimum is 2; 1 worker is always reserved as
# a passive stand-by.
gitaly['ruby_num_workers'] = 4
```

Source:

```toml
# /home/git/gitaly/config.toml
[gitaly-ruby]
num_workers = 4
```

### Observing gitaly-ruby traffic

Gitaly-ruby is a somewhat hidden, internal implementation detail of
Gitaly. There is not that much visibility into what goes on inside
gitaly-ruby processes.

If you have Prometheus set up to scrape your Gitaly process, you can see
request rates and error codes for individual RPC's in gitaly-ruby by
querying `grpc_client_handled_total`. Strictly speaking this metric does
not differentiate between gitaly-ruby and other RPC's, but in practice
(as of GitLab 11.9), all gRPC calls made by Gitaly itself are internal
calls from the main Gitaly process to one of its gitaly-ruby sidecars.

Assuming your `grpc_client_handled_total` counter only observes Gitaly,
the following query shows you RPC's are (most likely) internally
implemented as calls to gitaly-ruby.

```
sum(rate(grpc_client_handled_total[5m])) by (grpc_method) > 0
```

## Disabling or enabling the Gitaly service in a cluster environment

If you are running Gitaly [as a remote
service](#running-gitaly-on-its-own-server) you may want to disable
the local Gitaly service that runs on your GitLab server by default.

> 'Disabling Gitaly' only makes sense when you run GitLab in a custom
cluster configuration, where different services run on different
machines. Disabling Gitaly on all machines in the cluster is not a
valid configuration.

If you are setting up a GitLab cluster where Gitaly does not need to
run on all machines, you can disable the Gitaly service in your
Omnibus installation, add the following line to `/etc/gitlab/gitlab.rb`:

```ruby
gitaly['enable'] = false
```

When you run `gitlab-ctl reconfigure` the Gitaly service will be
disabled.

To disable the Gitaly service in a GitLab cluster where you installed
GitLab from source, add the following to `/etc/default/gitlab` on the
machine where you want to disable Gitaly.

```shell
gitaly_enabled=false
```

When you run `service gitlab restart` Gitaly will be disabled on this
particular machine.

## Troubleshooting Gitaly in production

Since GitLab 11.6, Gitaly comes with a command-line tool called
`gitaly-debug` that can be run on a Gitaly server to aid in
troubleshooting. In GitLab 11.6 its only sub-command is
`simulate-http-clone` which allows you to measure the maximum possible
Git clone speed for a specific repository on the server.

For an up to date list of sub-commands see [the gitaly-debug
README](https://gitlab.com/gitlab-org/gitaly/blob/master/cmd/gitaly-debug/README.md).
