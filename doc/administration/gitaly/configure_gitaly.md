---
stage: Systems
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Configure Gitaly **(FREE SELF)**

Configure Gitaly in one of two ways:

::Tabs

:::TabTitle Linux package (Omnibus)

1. Edit `/etc/gitlab/gitlab.rb` and add or change the
   [Gitaly settings](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/1dd07197c7e5ae23626aad5a4a070a800b670380/files/gitlab-config-template/gitlab.rb.template#L1622-1676).
1. Save the file and [reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure).

:::TabTitle Self-compiled (source)

1. Edit `/home/git/gitaly/config.toml` and add or change the [Gitaly settings](https://gitlab.com/gitlab-org/gitaly/blob/master/config.toml.example).
1. Save the file and [restart GitLab](../restart_gitlab.md#installations-from-source).

::EndTabs

The following configuration options are also available:

- Enabling [TLS support](#enable-tls-support).
- Limiting [RPC concurrency](#limit-rpc-concurrency).

## About the Gitaly token

The token referred to throughout the Gitaly documentation is just an arbitrary password selected by
the administrator. It is unrelated to tokens created for the GitLab API or other similar web API
tokens.

## Run Gitaly on its own server

By default, Gitaly is run on the same server as Gitaly clients and is
[configured as above](#configure-gitaly). Single-server installations are best served by
this default configuration used by:

- [Omnibus GitLab](https://docs.gitlab.com/omnibus/).
- The GitLab [source installation guide](../../install/installation.md).

However, Gitaly can be deployed to its own server, which can benefit GitLab installations that span
multiple machines.

NOTE:
When configured to run on their own servers, Gitaly servers must be
[upgraded](../../update/package/index.md) before Gitaly clients in your cluster.

NOTE:
[Disk requirements](index.md#disk-requirements) apply to Gitaly nodes.

The process for setting up Gitaly on its own server is:

1. [Install Gitaly](#install-gitaly).
1. [Configure authentication](#configure-authentication).
1. [Configure Gitaly servers](#configure-gitaly-servers).
1. [Configure Gitaly clients](#configure-gitaly-clients).
1. [Disable Gitaly where not required](#disable-gitaly-where-not-required-optional) (optional).

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
  - Puma.
  - Sidekiq.
  - GitLab Workhorse.
  - GitLab Shell.
  - Elasticsearch indexer.
  - Gitaly itself.
- A Gitaly server must be able to make RPC calls **to itself** by using its own
  `(Gitaly address, Gitaly token)` pair as specified in `/config/gitlab.yml`.
- Authentication is done through a static token which is shared among the Gitaly and GitLab Rails
  nodes.

The following digraph illustrates communication between Gitaly servers and GitLab Rails showing
the default ports for HTTP and HTTPs communication.

![Gitaly network architecture diagram](img/gitaly_network_13_9.png)

WARNING:
Gitaly servers must not be exposed to the public internet as Gitaly network traffic is unencrypted
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

### Install Gitaly

Install Gitaly on each Gitaly server using either Omnibus GitLab or install it from source:

- For Omnibus GitLab, [download and install](https://about.gitlab.com/install/) the Omnibus GitLab
  package you want but **do not** provide the `EXTERNAL_URL=` value.
- To install from source, follow the steps at
  [Install Gitaly](../../install/installation.md#install-gitaly).

### Configure Gitaly servers

To configure Gitaly servers, you must:

- Configure authentication.
- Configure storage paths.
- Enable the network listener.

The `git` user must be able to read, write, and set permissions on the configured storage path.

To avoid downtime while rotating the Gitaly token, you can temporarily disable authentication using the `gitaly['auth_transitioning']` setting. For more information, see the documentation on
[enabling "auth transitioning mode"](#enable-auth-transitioning-mode).

#### Configure authentication

Gitaly and GitLab use two shared secrets for authentication:

- _Gitaly token_: used to authenticate gRPC requests to Gitaly
- _GitLab Shell token_: used for authentication callbacks from GitLab Shell to the GitLab internal API

Configure authentication in one of two ways:

::Tabs

:::TabTitle Linux package (Omnibus)

To configure the _Gitaly token_, edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitaly['configuration'] = {
      # ...
      auth: {
        # ...
        token: 'abc123secret',
      },
   }
   ```

Configure the _GitLab Shell token_ in one of two ways.

Method 1 (recommended):

Copy `/etc/gitlab/gitlab-secrets.json` from the Gitaly client to same path on the Gitaly servers
   (and any other Gitaly clients).

Method 2:

Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_shell['secret_token'] = 'shellsecret'
   ```

:::TabTitle Self-compiled (source)

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

::EndTabs

#### Configure Gitaly server

<!--
Updates to example must be made at:

- https://gitlab.com/gitlab-org/charts/gitlab/blob/master/doc/advanced/external-gitaly/external-omnibus-gitaly.md#configure-omnibus-gitlab
- https://gitlab.com/gitlab-org/gitlab/blob/master/doc/administration/gitaly/index.md#gitaly-server-configuration
- All reference architecture pages
-->

Configure Gitaly server in one of two ways:

::Tabs

:::TabTitle Linux package (Omnibus)

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   # Avoid running unnecessary services on the Gitaly server
   postgresql['enable'] = false
   redis['enable'] = false
   nginx['enable'] = false
   puma['enable'] = false
   sidekiq['enable'] = false
   gitlab_workhorse['enable'] = false
   grafana['enable'] = false
   gitlab_exporter['enable'] = false
   gitlab_kas['enable'] = false

   # If you run a separate monitoring node you can disable these services
   prometheus['enable'] = false
   alertmanager['enable'] = false

   # If you don't run a separate monitoring node you can
   # enable Prometheus access & disable these extra services.
   # This makes Prometheus listen on all interfaces. You must use firewalls to restrict access to this address/port.
   # prometheus['listen_address'] = '0.0.0.0:9090'
   # prometheus['monitor_kubernetes'] = false

   # If you don't want to run monitoring services uncomment the following (not recommended)
   # node_exporter['enable'] = false

   # Prevent database connections during 'gitlab-ctl reconfigure'
   gitlab_rails['auto_migrate'] = false

   # Configure the gitlab-shell API callback URL. Without this, `git push` will
   # fail. This can be your 'front door' GitLab URL or an internal load
   # balancer.
   # Don't forget to copy `/etc/gitlab/gitlab-secrets.json` from Gitaly client to Gitaly server.
   gitlab_rails['internal_api_url'] = 'https://gitlab.example.com'

   gitaly['configuration'] = {
      # ...
      #
      # Make Gitaly accept connections on all network interfaces. You must use
      # firewalls to restrict access to this address/port.
      # Comment out following line if you only want to support TLS connections
      listen_addr: '0.0.0.0:8075',
      auth: {
        # ...
        #
        # Authentication token to ensure only authorized servers can communicate with
        # Gitaly server
        token: 'AUTH_TOKEN',
      },
   }
   ```

1. Append the following to `/etc/gitlab/gitlab.rb` for each respective Gitaly server:

   <!-- Updates to following example must also be made at https://gitlab.com/gitlab-org/charts/gitlab/blob/master/doc/advanced/external-gitaly/external-omnibus-gitaly.md#configure-omnibus-gitlab -->

   On `gitaly1.internal`:

   ```ruby
   gitaly['configuration'] = {
      # ...
      storage: [
         {
            name: 'default',
            path: '/var/opt/gitlab/git-data',
         },
         {
            name: 'storage1',
            path: '/mnt/gitlab/git-data',
         },
      ],
   }
   ```

   On `gitaly2.internal`:

   ```ruby
   gitaly['configuration'] = {
      # ...
      storage: [
         {
            name: 'storage2',
            path: '/srv/gitlab/git-data',
         },
      ],
   }
   ```

1. Save the file and [reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure).
1. Confirm that Gitaly can perform callbacks to the GitLab internal API:
   - For GitLab 15.3 and later, run `sudo /opt/gitlab/embedded/bin/gitaly check /var/opt/gitlab/gitaly/config.toml`.
   - For GitLab 15.2 and earlier, run `sudo /opt/gitlab/embedded/bin/gitaly-hooks check /var/opt/gitlab/gitaly/config.toml`.

:::TabTitle Self-compiled (source)

1. Edit `/home/git/gitaly/config.toml`:

   ```toml
   listen_addr = '0.0.0.0:8075'

   runtime_dir = '/var/opt/gitlab/gitaly'

   [logging]
   format = 'json'
   level = 'info'
   dir = '/var/log/gitaly'
   ```

    For GitLab 14.9 and earlier, set `internal_socket_dir = '/var/opt/gitlab/gitaly'` instead
    of `runtime_dir`.

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
1. Confirm that Gitaly can perform callbacks to the GitLab internal API:
   - For GitLab 15.3 and later, run `sudo /opt/gitlab/embedded/bin/gitaly check /var/opt/gitlab/gitaly/config.toml`.
   - For GitLab 15.2 and earlier, run `sudo /opt/gitlab/embedded/bin/gitaly-hooks check /var/opt/gitlab/gitaly/config.toml`.

::EndTabs

WARNING:
If directly copying repository data from a GitLab server to Gitaly, ensure that the metadata file,
default path `/var/opt/gitlab/git-data/repositories/.gitaly-metadata`, is not included in the transfer.
Copying this file causes GitLab to use the [Rugged patches](index.md#direct-access-to-git-in-gitlab) for repositories hosted on the Gitaly server,
leading to `Error creating pipeline` and `Commit not found` errors, or stale data.

### Configure Gitaly clients

As the final step, you must update Gitaly clients to switch from using local Gitaly service to use
the Gitaly servers you just configured.

NOTE:
GitLab requires a `default` repository storage to be configured.
[Read more about this limitation](#gitlab-requires-a-default-repository-storage).

This can be risky because anything that prevents your Gitaly clients from reaching the Gitaly
servers causes all Gitaly requests to fail. For example, any sort of network, firewall, or name
resolution problems.

Additionally, you must [disable Rugged](../nfs.md#improving-nfs-performance-with-gitlab)
if previously enabled manually.

Gitaly makes the following assumptions:

- Your `gitaly1.internal` Gitaly server can be reached at `gitaly1.internal:8075` from your Gitaly
  clients, and that Gitaly server can read, write, and set permissions on `/var/opt/gitlab/git-data` and
  `/mnt/gitlab/git-data`.
- Your `gitaly2.internal` Gitaly server can be reached at `gitaly2.internal:8075` from your Gitaly
  clients, and that Gitaly server can read, write, and set permissions on `/srv/gitlab/git-data`.
- Your `gitaly1.internal` and `gitaly2.internal` Gitaly servers can reach each other.

You can't define Gitaly servers with some as a local Gitaly server
(without `gitaly_address`) and some as remote
server (with `gitaly_address`) unless you use
[mixed configuration](#mixed-configuration).

Configure Gitaly clients in one of two ways:

::Tabs

:::TabTitle Linux package (Omnibus)

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   # Use the same token value configured on all Gitaly servers
   gitlab_rails['gitaly_token'] = '<AUTH_TOKEN>'

   git_data_dirs({
     'default'  => { 'gitaly_address' => 'tcp://gitaly1.internal:8075' },
     'storage1' => { 'gitaly_address' => 'tcp://gitaly1.internal:8075' },
     'storage2' => { 'gitaly_address' => 'tcp://gitaly2.internal:8075' },
   })
   ```

   Alternatively, if each Gitaly server is configured to use a different authentication token:

   ```ruby
   git_data_dirs({
     'default'  => { 'gitaly_address' => 'tcp://gitaly1.internal:8075', 'gitaly_token' => '<AUTH_TOKEN_1>' },
     'storage1' => { 'gitaly_address' => 'tcp://gitaly1.internal:8075', 'gitaly_token' => '<AUTH_TOKEN_1>' },
     'storage2' => { 'gitaly_address' => 'tcp://gitaly2.internal:8075', 'gitaly_token' => '<AUTH_TOKEN_2>' },
   })
   ```

1. Save the file and [reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure).
1. Run `sudo gitlab-rake gitlab:gitaly:check` on the Gitaly client (for example, the
   Rails application) to confirm it can connect to Gitaly servers.
1. Tail the logs to see the requests:

   ```shell
   sudo gitlab-ctl tail gitaly
   ```

:::TabTitle Self-compiled (source)

1. Edit `/home/git/gitlab/config/gitlab.yml`:

   ```yaml
   gitlab:
     repositories:
       storages:
         default:
           gitaly_address: tcp://gitaly1.internal:8075
           gitaly_token: AUTH_TOKEN_1
           path: /some/local/path
         storage1:
           gitaly_address: tcp://gitaly1.internal:8075
           gitaly_token: AUTH_TOKEN_1
           path: /some/local/path
         storage2:
           gitaly_address: tcp://gitaly2.internal:8075
           gitaly_token: AUTH_TOKEN_2
           path: /some/local/path
   ```

   NOTE:
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

::EndTabs

When you tail the Gitaly logs on your Gitaly server, you should see requests coming in. One sure way
to trigger a Gitaly request is to clone a repository from GitLab over HTTP or HTTPS.

WARNING:
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
  # Address of the GitLab server that also has Gitaly running on it
  'storage1' => { 'gitaly_address' => 'tcp://gitlab.internal:8075' },
  'storage2' => { 'gitaly_address' => 'tcp://gitaly2.internal:8075' },
})

gitaly['configuration'] = {
  # ...
  #
  # Make Gitaly accept connections on all network interfaces
  listen_addr: '0.0.0.0:8075',
  # Or for TLS
  tls_listen_addr: '0.0.0.0:9999',
  tls: {
    certificate_path:  '/etc/gitlab/ssl/cert.pem',
    key_path: '/etc/gitlab/ssl/key.pem',
  },
  storage: [
    {
      name: 'storage1',
      path: '/mnt/gitlab/git-data',
    },
  ],
}
```

`path` can be included only for storage shards on the local Gitaly server.
If it's excluded, default Git storage directory is used for that storage shard.

### GitLab requires a default repository storage

When adding Gitaly servers to an environment, you might want to replace the original `default` Gitaly service. However, you can't
reconfigure the GitLab application servers to remove the `default` entry from `git_data_dirs` because GitLab requires a
`git_data_dirs` entry called `default`. [Read more](https://gitlab.com/gitlab-org/gitlab/-/issues/36175) about this limitation.

To work around the limitation:

1. Define an additional storage location on the new Gitaly service and configure the additional storage to be `default`.
1. In the [Admin Area](../repository_storage_paths.md#configure-where-new-repositories-are-stored), set `default` to a weight of zero
   to prevent repositories being stored there.

### Disable Gitaly where not required (optional)

If you run Gitaly [as a remote service](#run-gitaly-on-its-own-server), consider
disabling the local Gitaly service that runs on your GitLab server by default, and run it
only where required.

Disabling Gitaly on the GitLab instance makes sense only when you run GitLab in a custom cluster configuration, where
Gitaly runs on a separate machine from the GitLab instance. Disabling Gitaly on all machines in the cluster is not
a valid configuration (some machines much act as Gitaly servers).

Disable Gitaly on a GitLab server in one of two ways:

::Tabs

:::TabTitle Linux package (Omnibus)

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitaly['enable'] = false
   ```

1. Save the file and [reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure).

:::TabTitle Self-compiled (source)

1. Edit `/etc/default/gitlab`:

   ```shell
   gitaly_enabled=false
   ```

1. Save the file and [restart GitLab](../restart_gitlab.md#installations-from-source).

::EndTabs

## Enable TLS support

Gitaly supports TLS encryption. To communicate with a Gitaly instance that listens for secure
connections, use the `tls://` URL scheme in the `gitaly_address` of the corresponding
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

If you use a load balancer, it must be able to negotiate HTTP/2 using the ALPN TLS extension.

### Certificate requirements

- The certificate must specify the address you use to access the Gitaly server. You must add the hostname or IP address as a Subject Alternative Name to the certificate.
- You can configure Gitaly servers with both an unencrypted listening address `listen_addr` and an
  encrypted listening address `tls_listen_addr` at the same time. This allows you to gradually
  transition from unencrypted to encrypted traffic if necessary.
- The certificate's Common Name field is ignored.

### Configure Gitaly with TLS

Configure Gitaly with TLS in one of two ways:

::Tabs

:::TabTitle Linux package (Omnibus)

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
   `/etc/gitlab/trusted-certs` on all Gitaly servers and clients
   so that Gitaly servers and clients trust the certificate when calling into themselves
   or other Gitaly servers:

   ```shell
   sudo cp cert1.pem cert2.pem /etc/gitlab/trusted-certs/
   ```

1. Edit `/etc/gitlab/gitlab.rb` and add:

   <!-- Updates to following example must also be made at https://gitlab.com/gitlab-org/charts/gitlab/blob/master/doc/advanced/external-gitaly/external-omnibus-gitaly.md#configure-omnibus-gitlab -->

   ```ruby
   gitaly['configuration'] = {
      # ...
      tls_listen_addr: '0.0.0.0:9999',
      tls: {
        certificate_path: '/etc/gitlab/ssl/cert.pem',
        key_path: '/etc/gitlab/ssl/key.pem',
      },
   }
   ```

1. Save the file and [reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure).
1. Verify Gitaly traffic is being served over TLS by
   [observing the types of Gitaly connections](#observe-type-of-gitaly-connections).
1. Optional. Improve security by:
   1. Disabling non-TLS connections by commenting out or deleting `gitaly['configuration'][:listen_addr]` in
      `/etc/gitlab/gitlab.rb`.
   1. Saving the file.
   1. [Reconfiguring GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure).

:::TabTitle Self-compiled (source)

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

   NOTE:
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
1. Optional. Improve security by:
   1. Disabling non-TLS connections by commenting out or deleting `listen_addr` in
      `/home/git/gitaly/config.toml`.
   1. Saving the file.
   1. [Restarting GitLab](../restart_gitlab.md#installations-from-source).

::EndTabs

### Observe type of Gitaly connections

For information on observing the type of Gitaly connections being served, see the
[relevant documentation](monitoring.md#queries).

## Limit RPC concurrency

WARNING:
Enabling limits on your environment should be done with caution and only
in select circumstances, such as to protect against unexpected traffic.
When reached, limits _do_ result in disconnects that negatively impact users.
For consistent and stable performance, you should first explore other options such as
adjusting node specifications, and [reviewing large repositories](../../user/project/repository/managing_large_repositories.md) or workloads.

When cloning or pulling repositories, various RPCs run in the background. In particular, the Git pack RPCs:

- `SSHUploadPackWithSidechannel` (for Git SSH).
- `PostUploadPackWithSidechannel` (for Git HTTP).

These RPCs can consume a large amount of resources, which can have a significant impact in situations such as:

- Unexpectedly high traffic.
- Running against [large repositories](../../user/project/repository/managing_large_repositories.md) that don't follow best practices.

You can limit these processes from overwhelming your Gitaly server in these scenarios using the concurrency limits in the Gitaly configuration file. For
example:

```ruby
# in /etc/gitlab/gitlab.rb
gitaly['configuration'] = {
   # ...
   concurrency: [
      {
         rpc: '/gitaly.SmartHTTPService/PostUploadPackWithSidechannel',
         max_per_repo: 20,
         max_queue_time: '1s',
         max_queue_size: 10,
      },
      {
         rpc: '/gitaly.SSHService/SSHUploadPackWithSidechannel',
         max_per_repo: 20,
         max_queue_time: '1s',
         max_queue_size: 10,
      },
   ],
}
```

- `rpc` is the name of the RPC to set a concurrency limit for per repository.
- `max_per_repo` is the maximum number of in-flight RPC calls for the given RPC per repository.
- `max_queue_time` is the maximum amount of time a request can wait in the concurrency queue to
  be picked up by Gitaly.
- `max_queue_size` is the maximum size the concurrency queue (per RPC method) can grow to before requests are rejected by
  Gitaly.

This limits the number of in-flight RPC calls for the given RPCs. The limit is applied per
repository. In the example above:

- Each repository served by the Gitaly server can have at most 20 simultaneous `PostUploadPackWithSidechannel` and
  `SSHUploadPackWithSidechannel` RPC calls in flight.
- If another request comes in for a repository that has used up its 20 slots, that request gets
  queued.
- If a request waits in the queue for more than 1 second, it is rejected with an error.
- If the queue grows beyond 10, subsequent requests are rejected with an error.

NOTE:
When these limits are reached, users are disconnected.

You can observe the behavior of this queue using the Gitaly logs and Prometheus. For more
information, see the [relevant documentation](monitoring.md#monitor-gitaly-concurrency-limiting).

## Control groups

WARNING:
Enabling limits on your environment should be done with caution and only
in select circumstances, such as to protect against unexpected traffic.
When reached, limits _do_ result in disconnects that negatively impact users.
For consistent and stable performance, you should first explore other options such as
adjusting node specifications, and [reviewing large repositories](../../user/project/repository/managing_large_repositories.md) or workloads.

FLAG:
On self-managed GitLab, by default repository cgroups are not available. To make it available, ask an administrator to
[enable the feature flag](../feature_flags.md) named `gitaly_run_cmds_in_cgroup`.

When enabling cgroups for memory, you should ensure that no swap is configured on the Gitaly nodes as
processes may switch to using that instead of being terminated. This situation could lead to notably compromised
performance.

You can use control groups (cgroups) in Linux to impose limits on how much memory and CPU can be consumed by Gitaly processes.
See the [`cgroups` Linux man page](https://man7.org/linux/man-pages/man7/cgroups.7.html) for more information.
cgroups can help protect the system against unexpected resource exhaustion because of over consumption of memory and CPU.

Some Git operations can consume notable resources up to the point of exhaustion in situations such as:

- Unexpectedly high traffic.
- Operations running against large repositories that don't follow best practices.

As a hard protection, it's possible to use cgroups that configure the kernel to terminate these operations before they hog up all system resources
and cause instability.

Gitaly has built-in cgroups control. When configured, Gitaly assigns Git processes to a cgroup based on the repository
the Git command is operating in. These cgroups are called repository cgroups. Each repository cgroup:

- Has a memory and CPU limit.
- Contains the Git processes for a single repository.
- Uses a consistent hash to ensure a Git process for a given repository always ends up in the same cgroup.

When a repository cgroup reaches its:

- Memory limit, the kernel looks through the processes for a candidate to kill.
- CPU limit, processes are not killed, but the processes are prevented from consuming more CPU than allowed.

NOTE:
When these limits are reached, performance may be reduced and users may be disconnected.

### Configure repository cgroups (new method)

> - This method of configuring repository cgroups was introduced in GitLab 15.1.
> - `cpu_quota_us`[introduced](https://gitlab.com/gitlab-org/gitaly/-/merge_requests/5422) in GitLab 15.10.

To configure repository cgroups in Gitaly using the new method, use the following settings for the new configuration method
to `gitaly['configuration'][:cgroups]` in `/etc/gitlab/gitlab.rb`:

- `mountpoint` is where the parent cgroup directory is mounted. Defaults to `/sys/fs/cgroup`.
- `hierarchy_root` is the parent cgroup under which Gitaly creates groups, and
   is expected to be owned by the user and group Gitaly runs as. Omnibus GitLab
   creates the set of directories `mountpoint/<cpu|memory>/hierarchy_root`
   when Gitaly starts.
- `memory_bytes` is the total memory limit that is imposed collectively on all
   Git processes that Gitaly spawns. 0 implies no limit.
- `cpu_shares` is the CPU limit that is imposed collectively on all Git
   processes that Gitaly spawns. 0 implies no limit. The maximum is 1024 shares,
   which represents 100% of CPU.
- `cpu_quota_us` is the [`cfs_quota_us`](https://docs.kernel.org/scheduler/sched-bwc.html#management)
  to throttle the cgroups' processes if they exceed this quota value. We set
  `cfs_period_us` to `100ms` so 1 core is `100000`. 0 implies no limit.
- `repositories.count` is the number of cgroups in the cgroups pool. Each time a new Git
  command is spawned, Gitaly assigns it to one of these cgroups based
  on the repository the command is for. A circular hashing algorithm assigns
  Git commands to these cgroups, so a Git command for a repository is
  always assigned to the same cgroup.
- `repositories.memory_bytes` is the total memory limit imposed on all Git processes contained in a repository cgroup.
  0 implies no limit. This value cannot exceed that of the top level `memory_bytes`.
- `repositories.cpu_shares` is the CPU limit that is imposed on all Git processes contained in a repository cgroup.
  0 implies no limit. The maximum is 1024 shares, which represents 100% of CPU.
  This value cannot exceed that of the top level`cpu_shares`.
- `repositories.cpu_quota_us` is the [`cfs_quota_us`](https://docs.kernel.org/scheduler/sched-bwc.html#management)
  that is imposed on all Git processes contained in a repository cgroup. A Git
  process can't use more then the given quota. We set
  `cfs_period_us` to `100ms` so 1 core is `100000`. 0 implies no limit.

For example:

```ruby
# in /etc/gitlab/gitlab.rb
gitaly['configuration'] = {
  # ...
  cgroups: {
    mountpoint: '/sys/fs/cgroup',
    hierarchy_root: 'gitaly',
    memory_bytes: 64424509440, # 60gb
    cpu_shares: 1024,
    cpu_quota_us: 400000 # 4 cores
    repositories: {
      count: 1000,
      memory_bytes: 32212254720, # 20gb
      cpu_shares: 512,
      cpu_quota_us: 200000 # 2 cores
    },
  },
}
```

### Configure repository cgroups (legacy method)

To configure repository cgroups in Gitaly using the legacy method, use the following settings
in `/etc/gitlab/gitlab.rb`:

- `cgroups_count` is the number of cgroups created. Each time a new
   command is spawned, Gitaly assigns it to one of these cgroups based
   on the command line arguments of the command. A circular hashing algorithm assigns
   commands to these cgroups.
- `cgroups_mountpoint` is where the parent cgroup directory is mounted. Defaults to `/sys/fs/cgroup`.
- `cgroups_hierarchy_root` is the parent cgroup under which Gitaly creates groups, and
   is expected to be owned by the user and group Gitaly runs as. Omnibus GitLab
   creates the set of directories `mountpoint/<cpu|memory>/hierarchy_root`
   when Gitaly starts.
- `cgroups_memory_enabled` enables or disables the memory limit on cgroups.
- `cgroups_memory_bytes` is the total memory limit each cgroup imposes on the processes added to it.
- `cgroups_cpu_enabled` enables or disables the CPU limit on cgroups.
- `cgroups_cpu_shares` is the CPU limit each cgroup imposes on the processes added to it. The maximum is 1024 shares,
  which represents 100% of CPU.

For example:

```ruby
# in /etc/gitlab/gitlab.rb
gitaly['cgroups_count'] = 1000
gitaly['cgroups_mountpoint'] = "/sys/fs/cgroup"
gitaly['cgroups_hierarchy_root'] = "gitaly"
gitaly['cgroups_memory_limit'] = 32212254720
gitaly['cgroups_memory_enabled'] = true
gitaly['cgroups_cpu_shares'] = 1024
gitaly['cgroups_cpu_enabled'] = true
```

### Configuring oversubscription

In the previous example using the new configuration method:

- The top level memory limit is capped at 60 GB.
- Each of the 1000 cgroups in the repositories pool is capped at 20 GB.

This configuration leads to "oversubscription". Each cgroup in the pool has a much larger capacity than 1/1000th
of the top-level memory limit.

This strategy has two main benefits:

- It gives the host protection from overall memory starvation (OOM), because the memory limit of the top-level cgroup
  can be set to a threshold smaller than the host's capacity. Processes outside of that cgroup are not at risk of OOM.
- It allows each individual cgroup in the pool to burst up to a generous upper
  bound (in this example 20 GB) that is smaller than the limit of the parent cgroup,
  but substantially larger than 1/N of the parent's limit. In this example, up
  to 3 child cgroups can concurrently burst up to their max. In general, all
  1000 cgroups would use much less than the 20 GB.

## Background repository optimization

Empty directories and unneeded configuration settings may accumulate in a repository and
slow down Git operations. Gitaly can schedule a daily background task with a maximum duration
to clean up these items and improve performance.

WARNING:
Background repository optimization is an experimental feature and may place significant load on the host while running.
Make sure to schedule this during off-peak hours and keep the duration short (for example, 30-60 minutes).

Configure background repository optimization in one of two ways:

::Tabs

:::TabTitle Linux package (Omnibus)

Edit `/etc/gitlab/gitlab.rb` and add:

```ruby
gitaly['configuration'] = {
  # ...
  daily_maintenance: {
    # ...
    start_hour: 4,
    start_minute: 30,
    duration: '30m',
    storages: ['default'],
  },
}
```

:::TabTitle Self-compiled (source)

Edit `/home/git/gitaly/config.toml` and add:

```toml
[daily_maintenance]
start_hour = 4
start_minute = 30
duration = '30m'
storages = ["default"]
```

::EndTabs

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

Before rotating a Gitaly authentication token, verify that you can
[monitor the authentication behavior](monitoring.md#queries) of your GitLab installation using
Prometheus.

You can then continue the rest of the procedure.

### Enable "auth transitioning" mode

Temporarily disable Gitaly authentication on the Gitaly servers by putting them into "auth
transitioning" mode as follows:

```ruby
# in /etc/gitlab/gitlab.rb
gitaly['configuration'] = {
  # ...
  auth: {
    # ...
    transitioning: true,
  },
}
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
   gitaly['configuration'] = {
      # ...
      auth: {
         # ...
         token: '<new secret token>',
      },
   }
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

After the new token is picked up by all Gitaly clients and Gitaly servers, the
**only non-zero rate** should be `enforced="false",status="would be ok"`.

### Disable "auth transitioning" mode

To re-enable Gitaly authentication, disable "auth transitioning" mode. Update the configuration on
your Gitaly servers as follows:

```ruby
# in /etc/gitlab/gitlab.rb
gitaly['configuration'] = {
  # ...
  auth: {
    # ...
    transitioning: false,
  },
}
```

WARNING:
Without completing this step, you have **no Gitaly authentication**.

### Verify authentication is enforced

Refresh your [Prometheus query](#verify-authentication-monitoring). You should now see a similar
result as you did at the start. For example:

```prometheus
{enforced="true",status="ok"}  4424.985419441742
```

`enforced="true"` means that authentication is being enforced.

## Pack-objects cache **(FREE SELF)**

[Gitaly](index.md), the service that provides storage for Git
repositories, can be configured to cache a short rolling window of Git
fetch responses. This can reduce server load when your server receives
lots of CI fetch traffic.

The pack-objects cache wraps `git pack-objects`, an internal part of
Git that gets invoked indirectly via the PostUploadPack and
SSHUploadPack Gitaly RPCs. Gitaly runs PostUploadPack when a
user does a Git fetch via HTTP, or SSHUploadPack when a
user does a Git fetch via SSH.
When the cache is enabled, anything that uses PostUploadPack or SSHUploadPack can
benefit from it. It is orthogonal to:

- The transport (HTTP or SSH).
- Git protocol version (v0 or v2).
- The type of fetch, such as full clones, incremental fetches, shallow clones,
  or partial clones.

The strength of this cache is its ability to deduplicate concurrent
identical fetches. It:

- Can benefit GitLab instances where your users run CI/CD pipelines with many concurrent jobs.
  There should be a noticeable reduction in server CPU utilization.
- Does not benefit unique fetches at all. For example, if you run a spot check by cloning a
  repository to your local computer, you are unlikely to see a benefit from this cache because
  your fetch is probably unique.

The pack-objects cache is a local cache. It:

- Stores its metadata in the memory of the Gitaly process it is enabled in.
- Stores the actual Git data it is caching in files on local storage.

Using local files has the benefit that the operating system may
automatically keep parts of the pack-objects cache files in RAM,
making it faster.

Because the pack-objects cache can lead to a significant increase in
disk write IO, it is off by default. In GitLab 15.11 and later,
the write workload is approximately 50% lower, but the cache is still disabled by default.

### Configure the cache

These configuration settings are available for the pack-objects cache. Each setting is discussed in greater detail
below.

| Setting   | Default                                            | Description                                                                                        |
|:----------|:---------------------------------------------------|:---------------------------------------------------------------------------------------------------|
| `enabled` | `false`                                            | Turns on the cache. When off, Gitaly runs a dedicated `git pack-objects` process for each request. |
| `dir`     | `<PATH TO FIRST STORAGE>/+gitaly/PackObjectsCache` | Local directory where cache files get stored.                                                      |
| `max_age` | `5m` (5 minutes)                                   | Cache entries older than this get evicted and removed from disk.                                   |
| `min_occurrences` | 1 | Minimum times a key must occur before a cache entry is created. |

In `/etc/gitlab/gitlab.rb`, set:

```ruby
gitaly['configuration'] = {
  # ...
  pack_objects_cache: {
    # ...
    enabled: true,
    # dir: '/var/opt/gitlab/git-data/repositories/+gitaly/PackObjectsCache',
    # max_age: '5m',
    # min_occurrences: 1,
  },
}
```

#### `enabled` defaults to `false`

The cache is disabled by default because in some cases, it can create an
[extreme increase](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/4010#note_534564684)
in the number of bytes written to disk. On GitLab.com, we have verified
that our repository storage disks can handle this extra workload, but
we felt we cannot assume this is true everywhere.

#### Cache storage directory `dir`

The cache needs a directory to store its files in. This directory
should be:

- In a file system with enough space. If the cache file system runs out of space, all
  fetches start failing.
- On a disk with enough IO bandwidth. If the cache disk runs out of IO bandwidth, all
  fetches, and probably the entire server, slows down.

By default, the cache storage directory is set to a subdirectory of the first Gitaly storage
defined in the configuration file.

Multiple Gitaly processes can use the same directory for cache storage. Each Gitaly process
uses a unique random string as part of the cache filenames it creates. This means:

- They do not collide.
- They do not reuse another process's files.

While the default directory puts the cache files in the same
file system as your repository data, this is not requirement. You can
put the cache files on a different file system if that works better for
your infrastructure.

The amount of IO bandwidth required from the disk depends on:

- The size and shape of the repositories on your Gitaly server.
- The kind of traffic your users generate.

You can use the `gitaly_pack_objects_generated_bytes_total` metric as a pessimistic estimate,
pretending your cache hit ratio is 0%.

The amount of space required depends on:

- The bytes per second that your users pull from the cache.
- The size of the `max_age` cache eviction window.

If your users pull 100 MB/s and you use a 5 minute window, then on average you have
`5*60*100MB = 30GB` of data in your cache directory. This average is an expected average, not
a guarantee. Peak size may exceed this average.

#### Cache eviction window `max_age`

The `max_age` configuration setting lets you control the chance of a
cache hit and the average amount of storage used by cache files.
Entries older than `max_age` get deleted from the disk.

Eviction does not interfere with ongoing requests. It is OK for `max_age` to be less than the time it takes to do a
fetch over a slow connection because Unix filesystems do not truly delete a file until all processes that are reading
the deleted file have closed it.

#### Minimum key occurrences `min_occurrences`

> [Introduced](https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/2222) in GitLab 15.11.

The `min_occurrences` setting controls how often an identical request
must occur before we create a new cache entry. The default value is `1`,
meaning that unique requests do not get written into the cache.

If you:

- Increase this number, your cache hit rate goes down and the
cache uses less disk space.
- Decrease this number, your cache hit
rate goes up and the cache uses more disk space.

You should set `min_occurrences` to `1`. On GitLab.com,
going from 0 to 1 saved us 50% cache disk space while barely affecting
the cache hit rate.

### Observe the cache

The cache can be observed [using metrics](monitoring.md#pack-objects-cache) and in the following logged
information:

|Message|Fields|Description|
|:---|:---|:---|
|`generated bytes`|`bytes`, `cache_key`|Logged when an entry was added to the cache|
|`served bytes`|`bytes`, `cache_key`|Logged when an entry was read from the cache|

In the case of a:

- Cache miss, Gitaly logs both a `generated bytes` and a `served bytes` message.
- Cache hit, Gitaly logs only a `served bytes` message.

Example:

```json
{
  "bytes":26186490,
  "cache_key":"1b586a2698ca93c2529962e85cda5eea8f0f2b0036592615718898368b462e19",
  "correlation_id":"01F1MY8JXC3FZN14JBG1H42G9F",
  "grpc.meta.deadline_type":"none",
  "grpc.method":"PackObjectsHook",
  "grpc.request.fullMethod":"/gitaly.HookService/PackObjectsHook",
  "grpc.request.glProjectPath":"root/gitlab-workhorse",
  "grpc.request.glRepository":"project-2",
  "grpc.request.repoPath":"@hashed/d4/73/d4735e3a265e16eee03f59718b9b5d03019c07d8b6c51f90da3a666eec13ab35.git",
  "grpc.request.repoStorage":"default",
  "grpc.request.topLevelGroup":"@hashed",
  "grpc.service":"gitaly.HookService",
  "grpc.start_time":"2021-03-25T14:57:52.747Z",
  "level":"info",
  "msg":"generated bytes",
  "peer.address":"@",
  "pid":20961,
  "span.kind":"server",
  "system":"grpc",
  "time":"2021-03-25T14:57:53.543Z"
}
{
  "bytes":26186490,
  "cache_key":"1b586a2698ca93c2529962e85cda5eea8f0f2b0036592615718898368b462e19",
  "correlation_id":"01F1MY8JXC3FZN14JBG1H42G9F",
  "grpc.meta.deadline_type":"none",
  "grpc.method":"PackObjectsHook",
  "grpc.request.fullMethod":"/gitaly.HookService/PackObjectsHook",
  "grpc.request.glProjectPath":"root/gitlab-workhorse",
  "grpc.request.glRepository":"project-2",
  "grpc.request.repoPath":"@hashed/d4/73/d4735e3a265e16eee03f59718b9b5d03019c07d8b6c51f90da3a666eec13ab35.git",
  "grpc.request.repoStorage":"default",
  "grpc.request.topLevelGroup":"@hashed",
  "grpc.service":"gitaly.HookService",
  "grpc.start_time":"2021-03-25T14:57:52.747Z",
  "level":"info",
  "msg":"served bytes",
  "peer.address":"@",
  "pid":20961,
  "span.kind":"server",
  "system":"grpc",
  "time":"2021-03-25T14:57:53.543Z"
}
```

## Repository consistency checks

Gitaly runs repository consistency checks:

- When triggering a repository check.
- When changes are fetched from a mirrored repository.
- When users push changes into repository.

These consistency checks verify that a repository has all required objects and
that these objects are valid objects. They can be categorized as:

- Basic checks that assert that a repository doesn't become corrupt. This
  includes connectivity checks and checks that objects can be parsed.
- Security checks that recognize objects that are suitable to exploit past
  security-related bugs in Git.
- Cosmetic checks that verify that all object metadata is valid. Older Git
  versions and other Git implementations may have produced objects with invalid
  metadata, but newer versions can interpret these malformed objects.

Removing malformed objects that fail the consistency checks requires a
rewrite of the repository's history, which often can't be done. Therefore,
Gitaly by default disables consistency checks for a range of cosmetic issues
that don't negatively impact repository consistency.

By default, Gitaly doesn't disable basic or security-related checks so
to not distribute objects that can trigger known vulnerabilities in Git
clients. This also limits the ability to import repositories containing such
objects even if the project doesn't have malicious intent.

### Override repository consistency checks

Instance administrators can override consistency checks if they must
process repositories that do not pass consistency checks.

For Omnibus GitLab installations, edit `/etc/gitlab/gitlab.rb` and set the
following keys (in this example, to disable the `hasDotgit` consistency check):

- In [GitLab 15.10](https://gitlab.com/gitlab-org/gitaly/-/issues/4754) and later:

  ```ruby
  ignored_blobs = "/etc/gitlab/instance_wide_ignored_git_blobs.txt"

  gitaly['configuration'] = {
    # ...
    git: {
      # ...
      config: [
        # Populate a file with one unabbreviated SHA-1 per line.
        # See https://git-scm.com/docs/git-config#Documentation/git-config.txt-fsckskipList
        { key: "fsck.skipList", value: ignored_blobs },
        { key: "fetch.fsck.skipList", value: ignored_blobs },
        { key: "receive.fsck.skipList", value: ignored_blobs },

        { key: "fsck.hasDotgit", value: "ignore" },
        { key: "fetch.fsck.hasDotgit", value: "ignore" },
        { key: "receive.fsck.hasDotgit", value: "ignore" },
        { key: "fsck.missingSpaceBeforeEmail", value: "ignore" },
      ],
    },
  }
  ```

- In [GitLab 15.3](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/6800) to GitLab 15.9:

  ```ruby
  ignored_blobs = "/etc/gitlab/instance_wide_ignored_git_blobs.txt"

  gitaly['gitconfig'] = [

   # Populate a file with one unabbreviated SHA-1 per line.
   # See https://git-scm.com/docs/git-config#Documentation/git-config.txt-fsckskipList
   { key: "fsck.skipList", value: ignored_blobs },
   { key: "fetch.fsck.skipList", value: ignored_blobs },
   { key: "receive.fsck.skipList", value: ignored_blobs },

   { key: "fsck.hasDotgit", value: "ignore" },
   { key: "fetch.fsck.hasDotgit", value: "ignore" },
   { key: "receive.fsck.hasDotgit", value: "ignore" },
   { key: "fsck.missingSpaceBeforeEmail", value: "ignore" },
  ]
  ```

- In GitLab 15.2 and earlier (legacy method):

  ```ruby
  ignored_git_errors = [
    "hasDotgit = ignore",
    "missingSpaceBeforeEmail = ignore",
  ]
  omnibus_gitconfig['system'] = {

   # Populate a file with one unabbreviated SHA-1 per line.
   # See https://git-scm.com/docs/git-config#Documentation/git-config.txt-fsckskipList
    "fsck.skipList" => ignored_blobs
    "fetch.fsck.skipList" => ignored_blobs,
    "receive.fsck.skipList" => ignored_blobs,

    "fsck" => ignored_git_errors,
    "fetch.fsck" => ignored_git_errors,
    "receive.fsck" => ignored_git_errors,
  }
  ```

For source installs, edit the Gitaly configuration (`gitaly.toml`) to do the
equivalent:

```toml
[[git.config]]
key = "fsck.hasDotgit"
value = "ignore"

[[git.config]]
key = "fetch.fsck.hasDotgit"
value = "ignore"

[[git.config]]
key = "receive.fsck.hasDotgit"
value = "ignore"

[[git.config]]
key = "fsck.missingSpaceBeforeEmail"
value = "ignore"

[[git.config]]
key = "fetch.fsck.missingSpaceBeforeEmail"
value = "ignore"

[[git.config]]
key = "receive.fsck.missingSpaceBeforeEmail"
value = "ignore"

[[git.config]]
key = "fsck.skipList"
value = "/etc/gitlab/instance_wide_ignored_git_blobs.txt"

[[git.config]]
key = "fetch.fsck.skipList"
value = "/etc/gitlab/instance_wide_ignored_git_blobs.txt"

[[git.config]]
key = "receive.fsck.skipList"
value = "/etc/gitlab/instance_wide_ignored_git_blobs.txt"
```

## Configure commit signing for GitLab UI commits

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/19185) in GitLab 15.4.

By default, Gitaly doesn't sign commits made using GitLab UI. For example, commits made using:

- Web editor.
- Web IDE.
- Merge requests.

You can configure Gitaly to sign commits made with the GitLab UI. The commits show as unverified and signed by an unknown
user. Support for improvements is proposed in [issue 19185](https://gitlab.com/gitlab-org/gitlab/-/issues/19185).

Configure Gitaly to sign commits made with the GitLab UI in one of two ways:

::Tabs

:::TabTitle Linux package (Omnibus)

1. [Create a GPG key](../../user/project/repository/gpg_signed_commits/index.md#create-a-gpg-key)
   and export it. For optimal performance, consider using an EdDSA key.

   ```shell
   gpg --export-secret-keys <ID> > signing_key.gpg
   ```

1. On the Gitaly nodes, copy the key into `/etc/gitlab/gitaly/`.
1. Edit `/etc/gitlab/gitlab.rb` and configure `gitaly['gpg_signing_key_path']`:

   ```ruby
   gitaly['configuration'] = {
      # ...
      git: {
        # ...
        signing_key: '/etc/gitlab/gitaly/signing_key.gpg',
      },
   }
   ```

1. Save the file and [reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure).

:::TabTitle Self-compiled (source)

1. [Create a GPG key](../../user/project/repository/gpg_signed_commits/index.md#create-a-gpg-key)
   and export it. For optimal performance, consider using an EdDSA key.

   ```shell
   gpg --export-secret-keys <ID> > signing_key.gpg
   ```

1. On the Gitaly nodes, copy the key into `/etc/gitlab`.
1. Edit `/home/git/gitaly/config.toml` and configure `signing_key`:

   ```toml
   [git]
   signing_key = "/etc/gitlab/gitaly/signing_key.gpg"
   ```

1. Save the file and [restart GitLab](../restart_gitlab.md#installations-from-source).

::EndTabs

## Generate configuration using an external command

> [Introduced](https://gitlab.com/gitlab-org/gitaly/-/issues/4828) in GitLab 15.11.

You can generate parts of the Gitaly configuration using an external command. You might do this:

- To configure nodes without having to distribute the full configuration to each of them.
- To configure using auto-discovery of the node's settings. For example, using DNS entries.
- To configure secrets at startup of the node, so that don't need to be visible in plain text.

To generate configuration using an external command, you must provide a script that dumps the
desired configuration of the Gitaly node in JSON format to its standard output.

For example, the following command configures the HTTP password used to connect to the
GitLab internal API using an AWS secret:

```ruby
#!/usr/bin/env ruby
require 'json'
JSON.generate({"gitlab": {"http_settings": {"password": `aws get-secret-value --secret-id ...`}}})
```

You must then make the script path known to Gitaly in one of two ways:

::Tabs

:::TabTitle Linux package (Omnibus)

Edit `/etc/gitlab/gitlab.rb` and configure the `config_command`:

```ruby
gitaly['configuration'] = {
    config_command: '/path/to/config_command',
}
```

:::TabTitle Self-compiled (source)

Edit `/home/git/gitaly/config.toml` and configure `config_command`:

```toml
config_command = "/path/to/config_command"
```

::EndTabs

After configuration, Gitaly executes the command on startup and parses its
standard output as JSON. The resulting configuration is then merged back into
the other Gitaly configuration.

Gitaly fails to start up if either:

- The configuration command fails.
- The output produced by the command cannot be parsed as valid JSON.
