---
stage: Create
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference
---

# Gitaly

[Gitaly](https://gitlab.com/gitlab-org/gitaly) is the service that provides high-level RPC access to
Git repositories. Without it, no GitLab components can read or write Git data.

In the Gitaly documentation:

- **Gitaly server** refers to any node that runs Gitaly itself.
- **Gitaly client** refers to any node that runs a process that makes requests of the
  Gitaly server. Processes include, but are not limited to:
  - [GitLab Rails application](https://gitlab.com/gitlab-org/gitlab).
  - [GitLab Shell](https://gitlab.com/gitlab-org/gitlab-shell).
  - [GitLab Workhorse](https://gitlab.com/gitlab-org/gitlab-workhorse).

GitLab end users do not have direct access to Gitaly. Gitaly only manages Git
repository access for GitLab. Other types of GitLab data aren't accessed using Gitaly.

CAUTION: **Caution:**
From GitLab 13.0, Gitaly support for NFS is deprecated. In GitLab 14.0, Gitaly support
for NFS is scheduled to be removed. Upgrade to [Gitaly Cluster](praefect.md) as soon as
possible.

## Architecture

The following is a high-level architecture overview of how Gitaly is used.

![Gitaly architecture diagram](img/architecture_v12_4.png)

## Configure Gitaly

The Gitaly service itself is configured via a [TOML configuration file](reference.md).

To change Gitaly settings:

**For Omnibus GitLab**

1. Edit `/etc/gitlab/gitlab.rb` and add or change the
   [Gitaly settings](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/1dd07197c7e5ae23626aad5a4a070a800b670380/files/gitlab-config-template/gitlab.rb.template#L1622-1676).
1. Save the file and [reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure).

**For installations from source**

1. Edit `/home/git/gitaly/config.toml` and add or change the [Gitaly settings](https://gitlab.com/gitlab-org/gitaly/blob/master/config.toml.example).
1. Save the file and [restart GitLab](../restart_gitlab.md#installations-from-source).

The following configuration options are also available:

- Enabling [TLS support](#enable-tls-support).
- Configuring the [number of `gitaly-ruby` workers](#configure-number-of-gitaly-ruby-workers).
- Limiting [RPC concurrency](#limit-rpc-concurrency).

## Run Gitaly on its own server

By default, Gitaly is run on the same server as Gitaly clients and is
[configured as above](#configure-gitaly). Single-server installations are best served by
this default configuration used by:

- [Omnibus GitLab](https://docs.gitlab.com/omnibus/).
- The GitLab [source installation guide](../../install/installation.md).

However, Gitaly can be deployed to its own server, which can benefit GitLab installations that span
multiple machines.

NOTE: **Note:**
When configured to run on their own servers, Gitaly servers
[must be upgraded](https://docs.gitlab.com/omnibus/update/#upgrading-gitaly-servers) before Gitaly
clients in your cluster.

The process for setting up Gitaly on its own server is:

1. [Install Gitaly](#install-gitaly).
1. [Configure authentication](#configure-authentication).
1. [Configure Gitaly servers](#configure-gitaly-servers).
1. [Configure Gitaly clients](#configure-gitaly-clients).
1. [Disable Gitaly where not required](#disable-gitaly-where-not-required-optional) (optional).

When running Gitaly on its own server, note the following regarding GitLab versions:

- From GitLab 11.4, Gitaly was able to serve all Git requests without requiring a shared NFS mount
  for Git repository data, except for the
  [Elasticsearch indexer](https://gitlab.com/gitlab-org/gitlab-elasticsearch-indexer).
- From GitLab 11.8, the Elasticsearch indexer uses Gitaly for data access as well. NFS can still be
  leveraged for redundancy on block-level Git data, but only has to be mounted on the Gitaly
  servers.
- From GitLab 11.8 to 12.2, it is possible to use Elasticsearch in a Gitaly setup that doesn't use
  NFS. To use Elasticsearch in these versions, the
  [repository indexer](../../integration/elasticsearch.md#elasticsearch-repository-indexer)
  must be enabled in your GitLab configuration.
- [In GitLab 12.3 and later](https://gitlab.com/gitlab-org/gitlab/-/issues/6481), the new indexer is
  the default and no configuration is required.

### Network architecture

The following list depicts the network architecture of Gitaly:

- GitLab Rails shards repositories into [repository storages](../repository_storage_paths.md).
- `/config/gitlab.yml` contains a map from storage names to `(Gitaly address, Gitaly token)` pairs.
- The `storage name` -\> `(Gitaly address, Gitaly token)` map in `/config/gitlab.yml` is the single
  source of truth for the Gitaly network topology.
- A `(Gitaly address, Gitaly token)` corresponds to a Gitaly server.
- A Gitaly server hosts one or more storages.
- A Gitaly client can use one or more Gitaly servers.
- Gitaly addresses must be specified in such a way that they resolve correctly for **all** Gitaly
  clients.
- Gitaly clients are:
  - Puma or Unicorn.
  - Sidekiq.
  - GitLab Workhorse.
  - GitLab Shell.
  - Elasticsearch indexer.
  - Gitaly itself.
- A Gitaly server must be able to make RPC calls **to itself** via its own
  `(Gitaly address, Gitaly token)` pair as specified in `/config/gitlab.yml`.
- Authentication is done through a static token which is shared among the Gitaly and GitLab Rails
  nodes.

DANGER: **Warning:**
Gitaly servers must not be exposed to the public internet as Gitaly's network traffic is unencrypted
by default. The use of firewall is highly recommended to restrict access to the Gitaly server.
Another option is to [use TLS](#enable-tls-support).

In the following sections, we describe how to configure two Gitaly servers with secret token
`abc123secret`:

- `gitaly1.internal`.
- `gitaly2.internal`.

We assume your GitLab installation has three repository storages:

- `default`.
- `storage1`.
- `storage2`.

You can use as few as one server with one repository storage if desired.

NOTE: **Note:**
The token referred to throughout the Gitaly documentation is just an arbitrary password selected by
the administrator. It is unrelated to tokens created for the GitLab API or other similar web API
tokens.

### Install Gitaly

Install Gitaly on each Gitaly server using either Omnibus GitLab or install it from source:

- For Omnibus GitLab, [download and install](https://about.gitlab.com/install/) the Omnibus GitLab
  package you want but **do not** provide the `EXTERNAL_URL=` value.
- To install from source, follow the steps at
  [Install Gitaly](../../install/installation.md#install-gitaly).

### Configure authentication

Gitaly and GitLab use two shared secrets for authentication:

- One to authenticate gRPC requests to Gitaly.
- A second for authentication callbacks from GitLab Shell to the GitLab internal API.

**For Omnibus GitLab**

To configure the Gitaly token:

1. On the Gitaly clients, edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['gitaly_token'] = 'abc123secret'
   ```

1. Save the file and [reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure).
1. On the Gitaly server, edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitaly['auth_token'] = 'abc123secret'
   ```

1. [Reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure).

There are two ways to configure the GitLab Shell token.

Method 1:

1. Copy `/etc/gitlab/gitlab-secrets.json` from the Gitaly client to same path on the Gitaly servers
   (and any other Gitaly clients).
1. [Reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure) on Gitaly servers.

Method 2:

1. On the Gitaly clients, edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_shell['secret_token'] = 'shellsecret'
   ```

1. Save the file and [reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure).
1. On the Gitaly servers, edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_shell['secret_token'] = 'shellsecret'
   ```

1. [Reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure).

**For installations from source**

1. Copy `/home/git/gitlab/.gitlab_shell_secret` from the Gitaly client to the same path on the
   Gitaly servers (and any other Gitaly clients).
1. On the Gitaly clients, edit `/home/git/gitlab/config/gitlab.yml`:

   ```yaml
   gitlab:
     gitaly:
       token: 'abc123secret'
   ```

1. Save the file and [restart GitLab](../restart_gitlab.md#installations-from-source).
1. On the Gitaly servers, edit `/home/git/gitaly/config.toml`:

   ```toml
   [auth]
   token = 'abc123secret'
   ```

1. Save the file and [restart GitLab](../restart_gitlab.md#installations-from-source).

### Configure Gitaly servers

On the Gitaly servers, you must configure storage paths and enable the network listener.

If you want to reduce the risk of downtime when you enable authentication, you can temporarily
disable enforcement. For more information, see the documentation on configuring
[Gitaly authentication](https://gitlab.com/gitlab-org/gitaly/blob/master/doc/configuration/README.md#authentication).

**For Omnibus GitLab**

1. Edit `/etc/gitlab/gitlab.rb`:

   <!--
   updates to following example must also be made at
   https://gitlab.com/gitlab-org/charts/gitlab/blob/master/doc/advanced/external-gitaly/external-omnibus-gitaly.md#configure-omnibus-gitlab
   -->

   ```ruby
   # /etc/gitlab/gitlab.rb

   # Avoid running unnecessary services on the Gitaly server
   postgresql['enable'] = false
   redis['enable'] = false
   nginx['enable'] = false
   puma['enable'] = false
   sidekiq['enable'] = false
   gitlab_workhorse['enable'] = false
   grafana['enable'] = false
   gitlab_exporter['enable'] = false

   # If you run a separate monitoring node you can disable these services
   alertmanager['enable'] = false
   prometheus['enable'] = false

   # If you don't run a separate monitoring node you can
   # enable Prometheus access & disable these extra services.
   # This makes Prometheus listen on all interfaces. You must use firewalls to restrict access to this address/port.
   # prometheus['listen_address'] = '0.0.0.0:9090'
   # prometheus['monitor_kubernetes'] = false

   # If you don't want to run monitoring services uncomment the following (not recommended)
   # node_exporter['enable'] = false

   # Prevent database connections during 'gitlab-ctl reconfigure'
   gitlab_rails['rake_cache_clear'] = false
   gitlab_rails['auto_migrate'] = false

   # Configure the gitlab-shell API callback URL. Without this, `git push` will
   # fail. This can be your 'front door' GitLab URL or an internal load
   # balancer.
   # Don't forget to copy `/etc/gitlab/gitlab-secrets.json` from Gitaly client to Gitaly server.
   gitlab_rails['internal_api_url'] = 'https://gitlab.example.com'

   # Make Gitaly accept connections on all network interfaces. You must use
   # firewalls to restrict access to this address/port.
   # Comment out following line if you only want to support TLS connections
   gitaly['listen_addr'] = "0.0.0.0:8075"
   ```

1. Append the following to `/etc/gitlab/gitlab.rb` for each respective Gitaly server:

   <!--
   updates to following example must also be made at
   https://gitlab.com/gitlab-org/charts/gitlab/blob/master/doc/advanced/external-gitaly/external-omnibus-gitaly.md#configure-omnibus-gitlab
   -->

   On `gitaly1.internal`:

   ```ruby
   git_data_dirs({
     'default' => {
       'path' => '/var/opt/gitlab/git-data'
     },
     'storage1' => {
       'path' => '/mnt/gitlab/git-data'
     },
   })
   ```

   On `gitaly2.internal`:

   ```ruby
   git_data_dirs({
     'storage2' => {
       'path' => '/srv/gitlab/git-data'
     },
   })
   ```

1. Save the file and [reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure).
1. Run `sudo /opt/gitlab/embedded/bin/gitaly-hooks check /var/opt/gitlab/gitaly/config.toml`
   to confirm that Gitaly can perform callbacks to the GitLab internal API.

**For installations from source**

1. Edit `/home/git/gitaly/config.toml`:

   ```toml
   listen_addr = '0.0.0.0:8075'

   internal_socket_dir = '/var/opt/gitlab/gitaly'

   [logging]
   format = 'json'
   level = 'info'
   dir = '/var/log/gitaly'
   ```

1. Append the following to `/home/git/gitaly/config.toml` for each respective Gitaly server:

   On `gitaly1.internal`:

   ```toml
   [[storage]]
   name = 'default'
   path = '/var/opt/gitlab/git-data/repositories'

   [[storage]]
   name = 'storage1'
   path = '/mnt/gitlab/git-data/repositories'
   ```

   On `gitaly2.internal`:

   ```toml
   [[storage]]
   name = 'storage2'
   path = '/srv/gitlab/git-data/repositories'
   ```

1. Edit `/home/git/gitlab-shell/config.yml`:

   ```yaml
   gitlab_url: https://gitlab.example.com
   ```

1. Save the files and [restart GitLab](../restart_gitlab.md#installations-from-source).
1. Run `sudo -u git /home/git/gitaly/gitaly-hooks check /home/git/gitaly/config.toml`
   to confirm that Gitaly can perform callbacks to the GitLab internal API.

### Configure Gitaly clients

As the final step, you must update Gitaly clients to switch from using local Gitaly service to use
the Gitaly servers you just configured.

This can be risky because anything that prevents your Gitaly clients from reaching the Gitaly
servers causes all Gitaly requests to fail. For example, any sort of network, firewall, or name
resolution problems.

Additionally, you must [disable Rugged](../nfs.md#improving-nfs-performance-with-gitlab)
if previously enabled manually.

Gitaly makes the following assumptions:

- Your `gitaly1.internal` Gitaly server can be reached at `gitaly1.internal:8075` from your Gitaly
  clients, and that Gitaly server can read, write, and set permissions on `/mnt/gitlab/default` and
  `/mnt/gitlab/storage1`.
- Your `gitaly2.internal` Gitaly server can be reached at `gitaly2.internal:8075` from your Gitaly
  clients, and that Gitaly server can read, write, and set permissions on `/mnt/gitlab/storage2`.
- Your `gitaly1.internal` and `gitaly2.internal` Gitaly servers can reach each other.

You can't define Gitaly servers with some as a local Gitaly server
(without `gitaly_address`) and some as remote
server (with `gitaly_address`) unless you setup with special
[mixed configuration](#mixed-configuration).

**For Omnibus GitLab**

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   git_data_dirs({
     'default' => { 'gitaly_address' => 'tcp://gitaly1.internal:8075' },
     'storage1' => { 'gitaly_address' => 'tcp://gitaly1.internal:8075' },
     'storage2' => { 'gitaly_address' => 'tcp://gitaly2.internal:8075' },
   })
   ```

1. Save the file and [reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure).
1. Run `sudo gitlab-rake gitlab:gitaly:check` on the Gitaly client (for example, the
   Rails application) to confirm it can connect to Gitaly servers.
1. Tail the logs to see the requests:

   ```shell
   sudo gitlab-ctl tail gitaly
   ```

**For installations from source**

1. Edit `/home/git/gitlab/config/gitlab.yml`:

   ```yaml
   gitlab:
     repositories:
       storages:
         default:
           gitaly_address: tcp://gitaly1.internal:8075
           path: /some/local/path
         storage1:
           gitaly_address: tcp://gitaly1.internal:8075
           path: /some/local/path
         storage2:
           gitaly_address: tcp://gitaly2.internal:8075
           path: /some/local/path
   ```

   NOTE: **Note:**
   `/some/local/path` should be set to a local folder that exists, however no data is stored in
   this folder. This requirement is scheduled to be removed when
   [this issue](https://gitlab.com/gitlab-org/gitaly/-/issues/1282) is resolved.

1. Save the file and [restart GitLab](../restart_gitlab.md#installations-from-source).
1. Run `sudo -u git -H bundle exec rake gitlab:gitaly:check RAILS_ENV=production` to confirm the
   Gitaly client can connect to Gitaly servers.
1. Tail the logs to see the requests:

   ```shell
   tail -f /home/git/gitlab/log/gitaly.log
   ```

When you tail the Gitaly logs on your Gitaly server, you should see requests coming in. One sure way
to trigger a Gitaly request is to clone a repository from GitLab over HTTP or HTTPS.

DANGER: **Warning:**
If you have [server hooks](../server_hooks.md) configured, either per repository or globally, you
must move these to the Gitaly servers. If you have multiple Gitaly servers, copy your server hooks
to all Gitaly servers.

#### Mixed configuration

GitLab can reside on the same server as one of many Gitaly servers, but doesn't support
configuration that mixes local and remote configuration. The following setup is incorrect, because:

- All addresses must be reachable from the other Gitaly servers.
- `storage1` is assigned a Unix socket for `gitaly_address` which is
  invalid for some of the Gitaly servers.

```ruby
git_data_dirs({
  'default' => { 'gitaly_address' => 'tcp://gitaly1.internal:8075' },
  'storage1' => { 'path' => '/mnt/gitlab/git-data' },
  'storage2' => { 'gitaly_address' => 'tcp://gitaly2.internal:8075' },
})
```

To combine local and remote Gitaly servers, use an external address for the local Gitaly server. For
example:

```ruby
git_data_dirs({
  'default' => { 'gitaly_address' => 'tcp://gitaly1.internal:8075' },
  # Address of the GitLab server that has Gitaly running on it
  'storage1' => { 'gitaly_address' => 'tcp://gitlab.internal:8075', 'path' => '/mnt/gitlab/git-data' },
  'storage2' => { 'gitaly_address' => 'tcp://gitaly2.internal:8075' },
})

# Make Gitaly accept connections on all network interfaces
gitaly['listen_addr'] = "0.0.0.0:8075"

# Or for TLS
gitaly['tls_listen_addr'] = "0.0.0.0:9999"
gitaly['certificate_path'] = "/etc/gitlab/ssl/cert.pem"
gitaly['key_path'] = "/etc/gitlab/ssl/key.pem"
```

`path` can only be included for storage shards on the local Gitaly server.
If it's excluded, default Git storage directory is used for that storage shard.

### Disable Gitaly where not required (optional)

If you are running Gitaly [as a remote service](#run-gitaly-on-its-own-server) you may want to
disable the local Gitaly service that runs on your GitLab server by default, leaving it only running
where required.

Disabling Gitaly on the GitLab instance only makes sense when you run GitLab in a custom cluster configuration, where
Gitaly runs on a separate machine from the GitLab instance. Disabling Gitaly on all machines in the cluster is not
a valid configuration (some machines much act as Gitaly servers).

To disable Gitaly on a GitLab server:

**For Omnibus GitLab**

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitaly['enable'] = false
   ```

1. Save the file and [reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure).

**For installations from source**

1. Edit `/etc/default/gitlab`:

   ```shell
   gitaly_enabled=false
   ```

1. Save the file and [restart GitLab](../restart_gitlab.md#installations-from-source).

## Enable TLS support

> - [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/22602) in GitLab 11.8.
> - [Introduced](https://gitlab.com/gitlab-org/gitaly/-/issues/3160) in GitLab 13.6, outgoing TLS connections to GitLab provide client certificates if configured.

Gitaly supports TLS encryption. To communicate with a Gitaly instance that listens for secure
connections, you must use `tls://` URL scheme in the `gitaly_address` of the corresponding
storage entry in the GitLab configuration.

Gitaly provides the same server certificates as client certificates in TLS
connections to GitLab. This can be used as part of a mutual TLS authentication strategy
when combined with reverse proxies (for example, NGINX) that validate client certificate
to grant access to GitLab.

You must supply your own certificates as this isn't provided automatically. The certificate
corresponding to each Gitaly server must be installed on that Gitaly server.

Additionally, the certificate (or its certificate authority) must be installed on all:

- Gitaly servers.
- Gitaly clients that communicate with it.

Note the following:

- The certificate must specify the address you use to access the Gitaly server. You must add the hostname or IP address as a Subject Alternative Name to the certificate.
- You can configure Gitaly servers with both an unencrypted listening address `listen_addr` and an
  encrypted listening address `tls_listen_addr` at the same time. This allows you to gradually
  transition from unencrypted to encrypted traffic if necessary.

To configure Gitaly with TLS:

**For Omnibus GitLab**

1. Create certificates for Gitaly servers.
1. On the Gitaly clients, copy the certificates (or their certificate authority) into
   `/etc/gitlab/trusted-certs`:

   ```shell
   sudo cp cert.pem /etc/gitlab/trusted-certs/
   ```

1. On the Gitaly clients, edit `git_data_dirs` in `/etc/gitlab/gitlab.rb` as follows:

   ```ruby
   git_data_dirs({
     'default' => { 'gitaly_address' => 'tls://gitaly1.internal:9999' },
     'storage1' => { 'gitaly_address' => 'tls://gitaly1.internal:9999' },
     'storage2' => { 'gitaly_address' => 'tls://gitaly2.internal:9999' },
   })
   ```

1. Save the file and [reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure).
1. On the Gitaly servers, create the `/etc/gitlab/ssl` directory and copy your key and certificate
   there:

   ```shell
   sudo mkdir -p /etc/gitlab/ssl
   sudo chmod 755 /etc/gitlab/ssl
   sudo cp key.pem cert.pem /etc/gitlab/ssl/
   sudo chmod 644 key.pem cert.pem
   ```

1. Copy all Gitaly server certificates (or their certificate authority) to
   `/etc/gitlab/trusted-certs` so that Gitaly servers trust the certificate when calling into themselves
   or other Gitaly servers:

   ```shell
   sudo cp cert1.pem cert2.pem /etc/gitlab/trusted-certs/
   ```

1. Edit `/etc/gitlab/gitlab.rb` and add:

   <!--
   updates to following example must also be made at
   https://gitlab.com/gitlab-org/charts/gitlab/blob/master/doc/advanced/external-gitaly/external-omnibus-gitaly.md#configure-omnibus-gitlab
   -->

   ```ruby
   gitaly['tls_listen_addr'] = "0.0.0.0:9999"
   gitaly['certificate_path'] = "/etc/gitlab/ssl/cert.pem"
   gitaly['key_path'] = "/etc/gitlab/ssl/key.pem"
   ```

1. Save the file and [reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure).
1. Verify Gitaly traffic is being served over TLS by
   [observing the types of Gitaly connections](#observe-type-of-gitaly-connections).
1. (Optional) Improve security by:
   1. Disabling non-TLS connections by commenting out or deleting `gitaly['listen_addr']` in
      `/etc/gitlab/gitlab.rb`.
   1. Saving the file.
   1. [Reconfiguring GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure).

**For installations from source**

1. Create certificates for Gitaly servers.
1. On the Gitaly clients, copy the certificates into the system trusted certificates:

   ```shell
   sudo cp cert.pem /usr/local/share/ca-certificates/gitaly.crt
   sudo update-ca-certificates
   ```

1. On the Gitaly clients, edit `storages` in `/home/git/gitlab/config/gitlab.yml` as follows:

   ```yaml
   gitlab:
     repositories:
       storages:
         default:
           gitaly_address: tls://gitaly1.internal:9999
           path: /some/local/path
         storage1:
           gitaly_address: tls://gitaly1.internal:9999
           path: /some/local/path
         storage2:
           gitaly_address: tls://gitaly2.internal:9999
           path: /some/local/path
   ```

   NOTE: **Note:**
   `/some/local/path` should be set to a local folder that exists, however no data is stored
   in this folder. This requirement is scheduled to be removed when
   [Gitaly issue #1282](https://gitlab.com/gitlab-org/gitaly/-/issues/1282) is resolved.

1. Save the file and [restart GitLab](../restart_gitlab.md#installations-from-source).
1. On the Gitaly servers, create or edit `/etc/default/gitlab` and add:

   ```shell
   export SSL_CERT_DIR=/etc/gitlab/ssl
   ```

1. On the Gitaly servers, create the `/etc/gitlab/ssl` directory and copy your key and certificate there:

   ```shell
   sudo mkdir -p /etc/gitlab/ssl
   sudo chmod 755 /etc/gitlab/ssl
   sudo cp key.pem cert.pem /etc/gitlab/ssl/
   sudo chmod 644 key.pem cert.pem
   ```

1. Copy all Gitaly server certificates (or their certificate authority) to the system trusted
   certificates folder so Gitaly server trusts the certificate when calling into itself or other Gitaly
   servers.

   ```shell
   sudo cp cert.pem /usr/local/share/ca-certificates/gitaly.crt
   sudo update-ca-certificates
   ```

1. Edit `/home/git/gitaly/config.toml` and add:

   ```toml
   tls_listen_addr = '0.0.0.0:9999'

   [tls]
   certificate_path = '/etc/gitlab/ssl/cert.pem'
   key_path = '/etc/gitlab/ssl/key.pem'
   ```

1. Save the file and [restart GitLab](../restart_gitlab.md#installations-from-source).
1. Verify Gitaly traffic is being served over TLS by
   [observing the types of Gitaly connections](#observe-type-of-gitaly-connections).
1. (Optional) Improve security by:
   1. Disabling non-TLS connections by commenting out or deleting `listen_addr` in
      `/home/git/gitaly/config.toml`.
   1. Saving the file.
   1. [Restarting GitLab](../restart_gitlab.md#installations-from-source).

### Observe type of Gitaly connections

[Prometheus](../monitoring/prometheus/index.md) can be used observe what type of connections Gitaly
is serving a production environment. Use the following Prometheus query:

```prometheus
sum(rate(gitaly_connections_total[5m])) by (type)
```

## `gitaly-ruby`

Gitaly was developed to replace the Ruby application code in GitLab.

To save time and avoid the risk of rewriting existing application logic, we chose to copy some
application code from GitLab into Gitaly.

To be able to run that code, `gitaly-ruby` was created, which is a "sidecar" process for the main
Gitaly Go process. Some examples of things that are implemented in `gitaly-ruby` are:

- RPCs that deal with wikis.
- RPCs that create commits on behalf of a user, such as merge commits.

We recommend:

- At least 300MB memory per worker.
- No more than one worker per core.

NOTE: **Note:**
`gitaly-ruby` is planned to be eventually removed. To track progress, see the
[Remove the Gitaly-Ruby sidecar](https://gitlab.com/groups/gitlab-org/-/epics/2862) epic.

### Configure number of `gitaly-ruby` workers

`gitaly-ruby` has much less capacity than Gitaly implemented in Go. If your Gitaly server has to handle lots of
requests, the default setting of having just one active `gitaly-ruby` sidecar might not be enough.

If you see `ResourceExhausted` errors from Gitaly, it's very likely that you have not enough
`gitaly-ruby` capacity.

You can increase the number of `gitaly-ruby` processes on your Gitaly server with the following
settings:

**For Omnibus GitLab**

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   # Default is 2 workers. The minimum is 2; 1 worker is always reserved as
   # a passive stand-by.
   gitaly['ruby_num_workers'] = 4
   ```

1. Save the file and [reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure).

**For installations from source**

1. Edit `/home/git/gitaly/config.toml`:

   ```toml
   [gitaly-ruby]
   num_workers = 4
   ```

1. Save the file and [restart GitLab](../restart_gitlab.md#installations-from-source).

## Limit RPC concurrency

Clone traffic can put a large strain on your Gitaly service. The bulk of the work gets done in the
either of the following RPCs:

- `SSHUploadPack` (for Git SSH).
- `PostUploadPack` (for Git HTTP).

To prevent such workloads from overwhelming your Gitaly server, you can set concurrency limits in
Gitaly's configuration file. For example:

```ruby
# in /etc/gitlab/gitlab.rb

gitaly['concurrency'] = [
  {
    'rpc' => "/gitaly.SmartHTTPService/PostUploadPack",
    'max_per_repo' => 20
  },
  {
    'rpc' => "/gitaly.SSHService/SSHUploadPack",
    'max_per_repo' => 20
  }
]
```

This limits the number of in-flight RPC calls for the given RPCs. The limit is applied per
repository. In the example above:

- Each repository served by the Gitaly server can have at most 20 simultaneous `PostUploadPack` RPC
  calls in flight, and the same for `SSHUploadPack`.
- If another request comes in for a repository that has used up its 20 slots, that request gets
  queued.

You can observe the behavior of this queue using the Gitaly logs and Prometheus:

- In the Gitaly logs, look for the string (or structured log field) `acquire_ms`. Messages that have
  this field are reporting about the concurrency limiter.
- In Prometheus, look for the following metrics:

  - `gitaly_rate_limiting_in_progress`.
  - `gitaly_rate_limiting_queued`.
  - `gitaly_rate_limiting_seconds`.

NOTE: **Note:**
Though the name of the Prometheus metric contains `rate_limiting`, it is a concurrency limiter, not
a rate limiter. If a Gitaly client makes 1000 requests in a row very quickly, concurrency does not
exceed 1 and the concurrency limiter has no effect.

## Rotate Gitaly authentication token

Rotating credentials in a production environment often requires downtime, causes outages, or both.

However, you can rotate Gitaly credentials without a service interruption. Rotating a Gitaly
authentication token involves:

- [Verifying authentication monitoring](#verify-authentication-monitoring).
- [Enabling "auth transitioning" mode](#enable-auth-transitioning-mode).
- [Updating Gitaly authentication tokens](#update-gitaly-authentication-token).
- [Ensuring there are no authentication failures](#ensure-there-are-no-authentication-failures).
- [Disabling "auth transitioning" mode](#disable-auth-transitioning-mode).
- [Verifying authentication is enforced](#verify-authentication-is-enforced).

This procedure also works if you are running GitLab on a single server. In that case, "Gitaly
server" and "Gitaly client" refers to the same machine.

### Verify authentication monitoring

Before rotating a Gitaly authentication token, verify that you can monitor the authentication
behavior of your GitLab installation using Prometheus. Use the following Prometheus query:

```prometheus
sum(rate(gitaly_authentications_total[5m])) by (enforced, status)
```

In a system where authentication is configured correctly and where you have live traffic, you
see something like this:

```prometheus
{enforced="true",status="ok"}  4424.985419441742
```

There may also be other numbers with rate 0. We only care about the non-zero numbers.

The only non-zero number should have `enforced="true",status="ok"`. If you have other non-zero
numbers, something is wrong in your configuration.

The `status="ok"` number reflects your current request rate. In the example above, Gitaly is
handling about 4000 requests per second.

Now that you have established that you can monitor the Gitaly authentication behavior of your GitLab
installation, you can begin the rest of the procedure.

### Enable "auth transitioning" mode

Temporarily disable Gitaly authentication on the Gitaly servers by putting them into "auth
transitioning" mode as follows:

```ruby
# in /etc/gitlab/gitlab.rb
gitaly['auth_transitioning'] = true
```

After you have made this change, your [Prometheus query](#verify-authentication-monitoring)
should return something like:

```prometheus
{enforced="false",status="would be ok"}  4424.985419441742
```

Because `enforced="false"`, it is safe to start rolling out the new token.

### Update Gitaly authentication token

To update to a new Gitaly authentication token, on each Gitaly client **and** Gitaly server:

1. Update the configuration:

   ```ruby
   # in /etc/gitlab/gitlab.rb

   gitaly['auth_token'] = '<new secret token>'
   ```

1. Restart Gitaly:

   ```shell
   gitlab-ctl restart gitaly
   ```

If you run your [Prometheus query](#verify-authentication-monitoring) while this change is
being rolled out, you see non-zero values for the `enforced="false",status="denied"` counter.

### Ensure there are no authentication failures

After the new token is set, and all services involved have been restarted, you will
[temporarily see](#verify-authentication-monitoring) a mix of:

- `status="would be ok"`.
- `status="denied"`.

After the new token has been picked up by all Gitaly clients and Gitaly servers, the
**only non-zero rate** should be `enforced="false",status="would be ok"`.

### Disable "auth transitioning" mode

To re-enable Gitaly authentication, disable "auth transitioning" mode. Update the configuration on
your Gitaly servers as follows:

```ruby
# in /etc/gitlab/gitlab.rb
gitaly['auth_transitioning'] = false
```

CAUTION: **Caution:**
Without completing this step, you have **no Gitaly authentication**.

### Verify authentication is enforced

Refresh your [Prometheus query](#verify-authentication-monitoring). You should now see a similar
result as you did at the start. For example:

```prometheus
{enforced="true",status="ok"}  4424.985419441742
```

Note that `enforced="true"` means that authentication is being enforced.

## Direct Git access bypassing Gitaly

While it is possible to access Gitaly repositories stored on disk directly with a Git client,
it is not advisable because Gitaly is being continuously improved and changed. Theses improvements may invalidate assumptions, resulting in performance degradation, instability, and even data loss.

Gitaly has optimizations, such as the
[`info/refs` advertisement cache](https://gitlab.com/gitlab-org/gitaly/blob/master/doc/design_diskcache.md),
that rely on Gitaly controlling and monitoring access to repositories via the
official gRPC interface. Likewise, Praefect has optimizations, such as fault
tolerance and distributed reads, that depend on the gRPC interface and
database to determine repository state.

For these reasons, **accessing repositories directly is done at your own risk
and is not supported**.

## Direct access to Git in GitLab

Direct access to Git uses code in GitLab known as the "Rugged patches".

### History

Before Gitaly existed, what are now Gitaly clients used to access Git repositories directly, either:

- On a local disk in the case of a single-machine Omnibus GitLab installation
- Using NFS in the case of a horizontally-scaled GitLab installation.

Besides running plain `git` commands, GitLab used to use a Ruby library called
[Rugged](https://github.com/libgit2/rugged). Rugged is a wrapper around
[libgit2](https://libgit2.org/), a stand-alone implementation of Git in the form of a C library.

Over time it became clear that Rugged, particularly in combination with
[Unicorn](https://yhbt.net/unicorn/), is extremely efficient. Because `libgit2` is a library and
not an external process, there was very little overhead between:

- GitLab application code that tried to look up data in Git repositories.
- The Git implementation itself.

Because the combination of Rugged and Unicorn was so efficient, GitLab's application code ended up with lots of
duplicate Git object lookups. For example, looking up the `master` commit a dozen times in one
request. We could write inefficient code without poor performance.

When we migrated these Git lookups to Gitaly calls, we suddenly had a much higher fixed cost per Git
lookup. Even when Gitaly is able to re-use an already-running `git` process (for example, to look up
a commit), you still have:

- The cost of a network roundtrip to Gitaly.
- Within Gitaly, a write/read roundtrip on the Unix pipes that connect Gitaly to the `git` process.

Using GitLab.com to measure, we reduced the number of Gitaly calls per request until the loss of
Rugged's efficiency was no longer felt. It also helped that we run Gitaly itself directly on the Git
file severs, rather than via NFS mounts. This gave us a speed boost that counteracted the negative
effect of not using Rugged anymore.

Unfortunately, other deployments of GitLab could not remove NFS like we did on GitLab.com, and they
got the worst of both worlds:

- The slowness of NFS.
- The increased inherent overhead of Gitaly.

The code removed from GitLab during the Gitaly migration project affected these deployments. As a
performance workaround for these NFS-based deployments, we re-introduced some of the old Rugged
code. This re-introduced code is informally referred to as the "Rugged patches".

### How it works

The Ruby methods that perform direct Git access are behind
[feature flags](../../development/gitaly.md#legacy-rugged-code), disabled by default. It wasn't
convenient to set feature flags to get the best performance, so we added an automatic mechanism that
enables direct Git access.

When GitLab calls a function that has a "Rugged patch", it performs two checks:

- Is the feature flag for this patch set in the database? If so, the feature flag setting controls
  GitLab's use of "Rugged patch" code.
- If the feature flag is not set, GitLab tries accessing the filesystem underneath the
  Gitaly server directly. If it can, it uses the "Rugged patch":
  - If using Unicorn.
  - If using Puma and [thread count](../../install/requirements.md#puma-threads) is set
    to `1`.

The result of these checks is cached.

To see if GitLab can access the repository filesystem directly, we use the following heuristic:

- Gitaly ensures that the filesystem has a metadata file in its root with a UUID in it.
- Gitaly reports this UUID to GitLab via the `ServerInfo` RPC.
- GitLab Rails tries to read the metadata file directly. If it exists, and if the UUID's match,
  assume we have direct access.

Direct Git access is enable by default in Omnibus GitLab because it fills in the correct repository
paths in the GitLab configuration file `config/gitlab.yml`. This satisfies the UUID check.

### Transition to Gitaly Cluster

For the sake of removing complexity, we must remove direct Git access in GitLab. However, we can't
remove it as long some GitLab installations require Git repositories on NFS.

There are two facets to our efforts to remove direct Git access in GitLab:

- Reduce the number of inefficient Gitaly queries made by GitLab.
- Persuade administrators of fault-tolerant or horizontally-scaled GitLab instances to migrate off
  NFS.

The second facet presents the only real solution. For this, we developed
[Gitaly Cluster](praefect.md).

## Troubleshooting Gitaly

Check [Gitaly timeouts](../../user/admin_area/settings/gitaly_timeouts.md) when troubleshooting
Gitaly.

### Checking versions when using standalone Gitaly servers

When using standalone Gitaly servers, you must make sure they are the same version
as GitLab to ensure full compatibility. Check **Admin Area > Gitaly Servers** on
your GitLab instance and confirm all Gitaly Servers are `Up to date`.

![Gitaly standalone software versions diagram](img/gitlab_gitaly_version_mismatch_v12_4.png)

### `gitaly-debug`

The `gitaly-debug` command provides "production debugging" tools for Gitaly and Git
performance. It is intended to help production engineers and support
engineers investigate Gitaly performance problems.

If you're using GitLab 11.6 or newer, this tool should be installed on
your GitLab / Gitaly server already at `/opt/gitlab/embedded/bin/gitaly-debug`.
If you're investigating an older GitLab version you can compile this
tool offline and copy the executable to your server:

```shell
git clone https://gitlab.com/gitlab-org/gitaly.git
cd cmd/gitaly-debug
GOOS=linux GOARCH=amd64 go build -o gitaly-debug
```

To see the help page of `gitaly-debug` for a list of supported sub-commands, run:

```shell
gitaly-debug -h
```

### Commits, pushes, and clones return a 401

```plaintext
remote: GitLab: 401 Unauthorized
```

You need to sync your `gitlab-secrets.json` file with your Gitaly clients (GitLab
app nodes).

### Client side gRPC logs

Gitaly uses the [gRPC](https://grpc.io/) RPC framework. The Ruby gRPC
client has its own log file which may contain useful information when
you are seeing Gitaly errors. You can control the log level of the
gRPC client with the `GRPC_LOG_LEVEL` environment variable. The
default level is `WARN`.

You can run a gRPC trace with:

```shell
sudo GRPC_TRACE=all GRPC_VERBOSITY=DEBUG gitlab-rake gitlab:gitaly:check
```

### Correlating Git processes with RPCs

Sometimes you need to find out which Gitaly RPC created a particular Git process.

One method for doing this is via `DEBUG` logging. However, this needs to be enabled
ahead of time and the logs produced are quite verbose.

A lightweight method for doing this correlation is by inspecting the environment
of the Git process (using its `PID`) and looking at the `CORRELATION_ID` variable:

```shell
PID=<Git process ID>
sudo cat /proc/$PID/environ | tr '\0' '\n' | grep ^CORRELATION_ID=
```

Please note that this method is not reliable for `git cat-file` processes because Gitaly
internally pools and re-uses those across RPCs.

### Observing `gitaly-ruby` traffic

[`gitaly-ruby`](#gitaly-ruby) is an internal implementation detail of Gitaly,
so, there's not that much visibility into what goes on inside
`gitaly-ruby` processes.

If you have Prometheus set up to scrape your Gitaly process, you can see
request rates and error codes for individual RPCs in `gitaly-ruby` by
querying `grpc_client_handled_total`. Strictly speaking, this metric does
not differentiate between `gitaly-ruby` and other RPCs, but in practice
(as of GitLab 11.9), all gRPC calls made by Gitaly itself are internal
calls from the main Gitaly process to one of its `gitaly-ruby` sidecars.

Assuming your `grpc_client_handled_total` counter only observes Gitaly,
the following query shows you RPCs are (most likely) internally
implemented as calls to `gitaly-ruby`:

```prometheus
sum(rate(grpc_client_handled_total[5m])) by (grpc_method) > 0
```

### Repository changes fail with a `401 Unauthorized` error

If you're running Gitaly on its own server and notice that users can
successfully clone and fetch repositories (via both SSH and HTTPS), but can't
push to them or make changes to the repository in the web UI without getting a
`401 Unauthorized` message, then it's possible Gitaly is failing to authenticate
with the Gitaly client due to having the [wrong secrets file](#configure-gitaly-servers).

Confirm the following are all true:

- When any user performs a `git push` to any repository on this Gitaly server, it
  fails with the following error (note the `401 Unauthorized`):

  ```shell
  remote: GitLab: 401 Unauthorized
  To <REMOTE_URL>
  ! [remote rejected] branch-name -> branch-name (pre-receive hook declined)
  error: failed to push some refs to '<REMOTE_URL>'
  ```

- When any user adds or modifies a file from the repository using the GitLab
  UI, it immediately fails with a red `401 Unauthorized` banner.
- Creating a new project and [initializing it with a README](../../gitlab-basics/create-project.md#blank-projects)
  successfully creates the project but doesn't create the README.
- When [tailing the logs](https://docs.gitlab.com/omnibus/settings/logs.html#tail-logs-in-a-console-on-the-server)
  on a Gitaly client and reproducing the error, you get `401` errors
  when reaching the `/api/v4/internal/allowed` endpoint:

  ```shell
  # api_json.log
  {
    "time": "2019-07-18T00:30:14.967Z",
    "severity": "INFO",
    "duration": 0.57,
    "db": 0,
    "view": 0.57,
    "status": 401,
    "method": "POST",
    "path": "\/api\/v4\/internal\/allowed",
    "params": [
      {
        "key": "action",
        "value": "git-receive-pack"
      },
      {
        "key": "changes",
        "value": "REDACTED"
      },
      {
        "key": "gl_repository",
        "value": "REDACTED"
      },
      {
        "key": "project",
        "value": "\/path\/to\/project.git"
      },
      {
        "key": "protocol",
        "value": "web"
      },
      {
        "key": "env",
        "value": "{\"GIT_ALTERNATE_OBJECT_DIRECTORIES\":[],\"GIT_ALTERNATE_OBJECT_DIRECTORIES_RELATIVE\":[],\"GIT_OBJECT_DIRECTORY\":null,\"GIT_OBJECT_DIRECTORY_RELATIVE\":null}"
      },
      {
        "key": "user_id",
        "value": "2"
      },
      {
        "key": "secret_token",
        "value": "[FILTERED]"
      }
    ],
    "host": "gitlab.example.com",
    "ip": "REDACTED",
    "ua": "Ruby",
    "route": "\/api\/:version\/internal\/allowed",
    "queue_duration": 4.24,
    "gitaly_calls": 0,
    "gitaly_duration": 0,
    "correlation_id": "XPUZqTukaP3"
  }

  # nginx_access.log
  [IP] - - [18/Jul/2019:00:30:14 +0000] "POST /api/v4/internal/allowed HTTP/1.1" 401 30 "" "Ruby"
  ```

To fix this problem, confirm that your [`gitlab-secrets.json` file](#configure-gitaly-servers)
on the Gitaly server matches the one on Gitaly client. If it doesn't match,
update the secrets file on the Gitaly server to match the Gitaly client, then
[reconfigure](../restart_gitlab.md#omnibus-gitlab-reconfigure).

### Command line tools cannot connect to Gitaly

If you are having trouble connecting to a Gitaly server with command line (CLI) tools,
and certain actions result in a `14: Connect Failed` error message,
it means that gRPC cannot reach your Gitaly server.

Verify that you can reach Gitaly via TCP:

```shell
sudo gitlab-rake gitlab:tcp_check[GITALY_SERVER_IP,GITALY_LISTEN_PORT]
```

If the TCP connection fails, check your network settings and your firewall rules.
If the TCP connection succeeds, your networking and firewall rules are correct.

If you use proxy servers in your command line environment, such as Bash, these
can interfere with your gRPC traffic.

If you use Bash or a compatible command line environment, run the following commands
to determine whether you have proxy servers configured:

```shell
echo $http_proxy
echo $https_proxy
```

If either of these variables have a value, your Gitaly CLI connections may be
getting routed through a proxy which cannot connect to Gitaly.

To remove the proxy setting, run the following commands (depending on which variables had values):

```shell
unset http_proxy
unset https_proxy
```

### Permission denied errors appearing in Gitaly logs when accessing repositories from a standalone Gitaly server

If this error occurs even though file permissions are correct, it's likely that
the Gitaly server is experiencing
[clock drift](https://en.wikipedia.org/wiki/Clock_drift).

Please ensure that the Gitaly clients and servers are synchronized and use an NTP time
server to keep them synchronized if possible.

### Praefect

Praefect is a router and transaction manager for Gitaly, and a required
component for running a Gitaly Cluster. For more information see [Gitaly Cluster](praefect.md).
