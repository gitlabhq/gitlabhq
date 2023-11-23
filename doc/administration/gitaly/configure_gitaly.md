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
1. Save the file and [reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation).

:::TabTitle Self-compiled (source)

1. Edit `/home/git/gitaly/config.toml` and add or change the [Gitaly settings](https://gitlab.com/gitlab-org/gitaly/blob/master/config.toml.example).
1. Save the file and [restart GitLab](../restart_gitlab.md#self-compiled-installations).

::EndTabs

The following configuration options are also available:

- Enabling [TLS support](#enable-tls-support).
- Limiting [RPC concurrency](#limit-rpc-concurrency).
- Limiting [pack-objects concurrency](#limit-pack-objects-concurrency).

## About the Gitaly token

The token referred to throughout the Gitaly documentation is just an arbitrary password selected by
the administrator. It is unrelated to tokens created for the GitLab API or other similar web API
tokens.

## Run Gitaly on its own server

By default, Gitaly is run on the same server as Gitaly clients and is
[configured as above](#configure-gitaly). Single-server installations are best served by
this default configuration used by:

- [Linux package installations](https://docs.gitlab.com/omnibus/).
- [Self-compiled installations](../../install/installation.md).

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

Install Gitaly on each Gitaly server using either:

- A Linux package installation. [Download and install](https://about.gitlab.com/install/) the Linux package you want
  but **do not** provide the `EXTERNAL_URL=` value.
- A self-compiled installation. Follow the steps at [Install Gitaly](../../install/installation.md#install-gitaly).

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

1. Save the file and [restart GitLab](../restart_gitlab.md#self-compiled-installations).
1. On the Gitaly servers, edit `/home/git/gitaly/config.toml`:

   ```toml
   [auth]
   token = 'abc123secret'
   ```

1. Save the file and [restart GitLab](../restart_gitlab.md#self-compiled-installations).

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
            path: '/var/opt/gitlab/git-data/repositories',
         },
         {
            name: 'storage1',
            path: '/mnt/gitlab/git-data/repositories',
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
            path: '/srv/gitlab/git-data/repositories',
         },
      ],
   }
   ```

1. Save the file and [reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation).
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

1. Save the files and [restart GitLab](../restart_gitlab.md#self-compiled-installations).
1. Confirm that Gitaly can perform callbacks to the GitLab internal API:
   - For GitLab 15.3 and later, run `sudo /opt/gitlab/embedded/bin/gitaly check /var/opt/gitlab/gitaly/config.toml`.
   - For GitLab 15.2 and earlier, run `sudo /opt/gitlab/embedded/bin/gitaly-hooks check /var/opt/gitlab/gitaly/config.toml`.

::EndTabs

WARNING:
If directly copying repository data from a GitLab server to Gitaly, ensure that the metadata file,
default path `/var/opt/gitlab/git-data/repositories/.gitaly-metadata`, is not included in the transfer.
Copying this file causes GitLab to use the direct disk access to repositories hosted on the Gitaly server,
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

1. Save the file and [reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation).
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
         storage1:
           gitaly_address: tcp://gitaly1.internal:8075
           gitaly_token: AUTH_TOKEN_1
         storage2:
           gitaly_address: tcp://gitaly2.internal:8075
           gitaly_token: AUTH_TOKEN_2
   ```

1. Save the file and [restart GitLab](../restart_gitlab.md#self-compiled-installations).
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
      path: '/mnt/gitlab/git-data/repositories',
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

1. Save the file and [reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation).

:::TabTitle Self-compiled (source)

1. Edit `/etc/default/gitlab`:

   ```shell
   gitaly_enabled=false
   ```

1. Save the file and [restart GitLab](../restart_gitlab.md#self-compiled-installations).

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

1. Save the file and [reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation).
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

1. Save the file and [reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation).
1. Run `sudo gitlab-rake gitlab:gitaly:check` on the Gitaly client (for example, the
   Rails application) to confirm it can connect to Gitaly servers.
1. Verify Gitaly traffic is being served over TLS by
   [observing the types of Gitaly connections](#observe-type-of-gitaly-connections).
1. Optional. Improve security by:
   1. Disabling non-TLS connections by commenting out or deleting `gitaly['configuration'][:listen_addr]` in
      `/etc/gitlab/gitlab.rb`.
   1. Saving the file.
   1. [Reconfiguring GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation).

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
         storage1:
           gitaly_address: tls://gitaly1.internal:9999
         storage2:
           gitaly_address: tls://gitaly2.internal:9999
   ```

1. Save the file and [restart GitLab](../restart_gitlab.md#self-compiled-installations).
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

1. Save the file and [restart GitLab](../restart_gitlab.md#self-compiled-installations).
1. Verify Gitaly traffic is being served over TLS by
   [observing the types of Gitaly connections](#observe-type-of-gitaly-connections).
1. Optional. Improve security by:
   1. Disabling non-TLS connections by commenting out or deleting `listen_addr` in
      `/home/git/gitaly/config.toml`.
   1. Saving the file.
   1. [Restarting GitLab](../restart_gitlab.md#self-compiled-installations).

::EndTabs

#### Update the certificates

To update the Gitaly certificates after initial configuration:

::Tabs

:::TabTitle Linux package (Omnibus)

If the content of your SSL certificates under the `/etc/gitlab/ssl` directory have been updated, but no configuration changes have been made to
`/etc/gitlab/gitlab.rb`, then reconfiguring GitLab doesn’t affect Gitaly. Instead, you must restart Gitaly manually for the certificates to be loaded
by the Gitaly process:

```shell
sudo gitlab-ctl restart gitaly
```

If you change or update the certificates in `/etc/gitlab/trusted-certs` without making changes to the `/etc/gitlab/gitlab.rb` file, you must:

1. [Reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) so the symlinks for the trusted certificates are updated.
1. Restart Gitaly manually for the certificates to be loaded by the Gitaly process:

   ```shell
   sudo gitlab-ctl restart gitaly
   ```

:::TabTitle Self-compiled (source)

If the content of your SSL certificates under the `/etc/gitlab/ssl` directory have been updated, you must
[restart GitLab](../restart_gitlab.md#self-compiled-installations) for the certificates to be loaded by the Gitaly process.

If you change or update the certificates in `/usr/local/share/ca-certificates`, you must:

1. Run `sudo update-ca-certificates` to update the system's trusted store.
1. [Restart GitLab](../restart_gitlab.md#self-compiled-installations) for the certificates to be loaded by the Gitaly process.

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
         max_queue_wait: '1s',
         max_queue_size: 10,
      },
      {
         rpc: '/gitaly.SSHService/SSHUploadPackWithSidechannel',
         max_per_repo: 20,
         max_queue_wait: '1s',
         max_queue_size: 10,
      },
   ],
}
```

- `rpc` is the name of the RPC to set a concurrency limit for per repository.
- `max_per_repo` is the maximum number of in-flight RPC calls for the given RPC per repository.
- `max_queue_wait` is the maximum amount of time a request can wait in the concurrency queue to
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

## Limit pack-objects concurrency

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/7891) in GitLab 15.11 [with a flag](../../administration/feature_flags.md) named `gitaly_pack_objects_limiting_remote_ip`. Disabled by default.
> - [Generally available](https://gitlab.com/gitlab-org/gitaly/-/merge_requests/5772) in GitLab 16.0. Feature flag `gitaly_pack_objects_limiting_remote_ip` removed.

Gitaly triggers `git-pack-objects` processes when handling both SSH and HTTPS traffic to clone or pull repositories. These processes generate a `pack-file` and can
consume a significant amount of resources, especially in situations such as unexpectedly high traffic or concurrent pulls from a large repository. On GitLab.com, we also
observe problems with clients that have slow internet connections.

You can limit these processes from overwhelming your Gitaly server by setting pack-objects concurrency limits in the Gitaly configuration file. This setting limits the
number of in-flight pack-object processes per remote IP address.

WARNING:
Only enable these limits on your environment with caution and only in select circumstances, such as to protect against unexpected traffic. When reached, these limits
disconnect users. For consistent and stable performance, you should first explore other options such as adjusting node specifications, and
[reviewing large repositories](../../user/project/repository/managing_large_repositories.md) or workloads.

Example configuration:

```ruby
# in /etc/gitlab/gitlab.rb
gitaly['pack_objects_limiting'] = {
   'max_concurrency' => 15,
   'max_queue_length' => 200,
   'max_queue_wait' => '60s',
}
```

- `max_concurrency` is the maximum number of in-flight pack-object processes per key.
- `max_queue_length` is the maximum size the concurrency queue (per key) can grow to before requests are rejected by Gitaly.
- `max_queue_wait` is the maximum amount of time a request can wait in the concurrency queue to be picked up by Gitaly.

In the example above:

- Each remote IP can have at most 15 simultaneous pack-object processes in flight on a Gitaly node.
- If another request comes in from an IP that has used up its 15 slots, that request gets queued.
- If a request waits in the queue for more than 1 minute, it is rejected with an error.
- If the queue grows beyond 200, subsequent requests are rejected with an error.

When the pack-object cache is enabled, pack-objects limiting kicks in only if the cache is missed. For more, see [Pack-objects cache](#pack-objects-cache).

You can observe the behavior of this queue using Gitaly logs and Prometheus. For more information, see
[Monitor Gitaly pack-objects concurrency limiting](monitoring.md#monitor-gitaly-pack-objects-concurrency-limiting).

## Adaptive concurrency limiting

> [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/10734) in GitLab 16.6.

Gitaly supports two concurrency limits:

- An [RPC concurrency limit](#limit-rpc-concurrency), which allow you to configure a maximum number of simultaneous in-flight requests for each
  Gitaly RPC. The limit is scoped by RPC and repository.
- A [Pack-objects concurrency limit](#limit-pack-objects-concurrency), which restricts the number of concurrent Git data transfer request by IP.

If this limit is exceeded, either:

- The request is put in a queue.
- The request is rejected if the queue is full or if the request remains in the queue for too long.

Both of these concurrency limits can be configured statically. Though static limits can yield good protection results, they have some drawbacks:

- Static limits are not good for all usage patterns. There is no one-size-fits-all value. If the limit is too low, big repositories are
  negatively impacted. If the limit is too high, the protection is essentially lost.
- It's tedious to maintain a sane value for the concurrency limit, especially when the workload of each repository changes over time.
- A request can be rejected even though the server is idle because the rate doesn't factor in the load on the server.

You can overcome all of these drawbacks and keep the benefits of concurrency limiting by configuring adaptive concurrency limits. Adaptive
concurrency limits are optional and build on the two concurrency limiting types. It uses Additive Increase/Multiplicative Decrease (AIMD)
algorithm. Each adaptive limit:

- Gradually increases up to a certain upper limit during typical process functioning.
- Quickly decreases when the host machine has a resource problem.

This mechanism provides some headroom for the machine to "breathe" and speeds up current inflight requests.

![Gitaly Adaptive Concurrency Limit](img/gitaly_adaptive_concurrency_limit.png)

The adaptive limiter calibrates the limits every 30 seconds and:

- Increases the limits by one until reaching the upper limit.
- Decreases the limits by half when the top-level cgroup has either memory usage that exceeds 90%, excluding highly-evictable page caches,
  or CPU throttled for 50% or more of the observation time.

Otherwise, the limits increase by one until reaching the upper bound. For more information about technical implementation
of this system, please refer to [this blueprint](../../architecture/blueprints/gitaly_adaptive_concurrency_limit/index.md).

Adaptive limiting is enabled for each RPC or pack-objects cache individually. However, limits are calibrated at the same time.

### Enable adaptiveness for RPC concurrency

Prerequisites:

- Because adaptive limiting depends on [control groups](#control-groups), control groups must be enabled before using adaptive limiting.

The following is an example to configure an adaptive limit for RPC concurrency:

```ruby
# in /etc/gitlab/gitlab.rb
gitaly['configuration'] = {
    # ...
    concurrency: [
        {
            rpc: '/gitaly.SmartHTTPService/PostUploadPackWithSidechannel',
            max_queue_wait: '1s',
            max_queue_size: 10,
            adaptive: true,
            min_limit: 10,
            initial_limit: 20,
            max_limit: 40
        },
        {
            rpc: '/gitaly.SSHService/SSHUploadPackWithSidechannel',
            max_queue_wait: '10s',
            max_queue_size: 20,
            adaptive: true,
            min_limit: 10,
            initial_limit: 50,
            max_limit: 100
        },
   ],
}
```

In this example:

- `adaptive` sets whether the adaptiveness is enabled. If set, the `max_per_repo` value is ignored in favor of the following configuration.
- `initial_limit` is the per-repository concurrency limit to use when Gitaly starts.
- `max_limit` is the minimum per-repository concurrency limit of the configured RPC. Gitaly increases the current limit
  until it reaches this number.
- `min_limit` is the is the minimum per-repository concurrency limit of the configured RPC. When the host machine has a resource problem,
  Gitaly quickly reduces the limit until reaching this value.

For more information, see [RPC concurrency](#limit-rpc-concurrency).

### Enable adaptiveness for pack-objects concurrency

Prerequisites:

- Because adaptive limiting depends on [control groups](#control-groups), control groups must be enabled before using adaptive limiting.

The following is an example to configure an adaptive limit for pack-objects concurrency:

```ruby
# in /etc/gitlab/gitlab.rb
gitaly['pack_objects_limiting'] = {
   'max_queue_length' => 200,
   'max_queue_wait' => '60s',
   'adaptive' => true,
   'min_limit' => 10,
   'initial_limit' => 20,
   'max_limit' => 40
}
```

In this example:

- `adaptive` sets whether the adaptiveness is enabled. If set, the value of `max_concurrency` is ignored in favor of the following configuration.
- `initial_limit` is the per-IP concurrency limit to use when Gitaly starts.
- `max_limit` is the minimum per-IP concurrency limit for pack-objects. Gitaly increases the current limit until it reaches this number.
- `min_limit` is the is the minimum per-IP concurrency limit for pack-objects. When the host machine has a resources problem, Gitaly quickly
  reduces the limit until it reaches this value.

For more information, see [pack-objects concurrency](#limit-pack-objects-concurrency).

## Control groups

WARNING:
Enabling limits on your environment should be done with caution and only
in select circumstances, such as to protect against unexpected traffic.
When reached, limits _do_ result in disconnects that negatively impact users.
For consistent and stable performance, you should first explore other options such as
adjusting node specifications, and [reviewing large repositories](../../user/project/repository/managing_large_repositories.md) or workloads.

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
   is expected to be owned by the user and group Gitaly runs as. A Linux package installation
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
   is expected to be owned by the user and group Gitaly runs as. A Linux package installation
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

> Logs for pack-objects caching was [changed](https://gitlab.com/gitlab-org/gitaly/-/merge_requests/5719) in GitLab 16.0.

You can observe the cache [using metrics](monitoring.md#pack-objects-cache) and in the following logged information. These logs are part of the gRPC logs and can
be discovered when a call is executed.

| Field | Description |
|:---|:---|
| `pack_objects_cache.hit` | Indicates whether the current pack-objects cache was hit (`true` or `false`) |
| `pack_objects_cache.key` | Cache key used for the pack-objects cache |
| `pack_objects_cache.generated_bytes` | Size (in bytes) of the new cache being written |
| `pack_objects_cache.served_bytes` | Size (in bytes) of the cache being served |
| `pack_objects.compression_statistics` | Statistics regarding pack-objects generation |
| `pack_objects.enumerate_objects_ms` | Total time (in ms) spent enumerating objects sent by clients |
| `pack_objects.prepare_pack_ms` | Total time (in ms) spent preparing the packfile before sending it back to the client |
| `pack_objects.write_pack_file_ms` | Total time (in ms) spent sending back the packfile to the client. Highly dependent on the client's internet connection |
| `pack_objects.written_object_count` | Total number of objects Gitaly sends back to the client |

In the case of a:

- Cache miss, Gitaly logs both a `pack_objects_cache.generated_bytes` and `pack_objects_cache.served_bytes` message. Gitaly also logs some more detailed statistics of
  pack-object generation.
- Cache hit, Gitaly logs only a `pack_objects_cache.served_bytes` message.

Example:

```json
{
  "bytes":26186490,
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
  "msg":"finished unary call with code OK",
  "peer.address":"@",
  "pid":20961,
  "span.kind":"server",
  "system":"grpc",
  "time":"2021-03-25T14:57:53.543Z",
  "pack_objects.compression_statistics": "Total 145991 (delta 68), reused 6 (delta 2), pack-reused 145911",
  "pack_objects.enumerate_objects_ms": 170,
  "pack_objects.prepare_pack_ms": 7,
  "pack_objects.write_pack_file_ms": 786,
  "pack_objects.written_object_count": 145991,
  "pack_objects_cache.generated_bytes": 49533030,
  "pack_objects_cache.hit": "false",
  "pack_objects_cache.key": "123456789",
  "pack_objects_cache.served_bytes": 49533030,
  "peer.address": "127.0.0.1",
  "pid": 8813,
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

For Linux package installations, edit `/etc/gitlab/gitlab.rb` and set the
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

For self-compiled installations, edit the Gitaly configuration (`gitaly.toml`) to do the
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

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/19185) in GitLab 15.4.
> - Displaying **Verified** badge for signed GitLab UI commits [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/124218) in GitLab 16.3 [with a flag](../feature_flags.md) named `gitaly_gpg_signing`. Disabled by default.

FLAG:
On self-managed GitLab, by default this feature is not available. To make it available,
an administrator can [enable the feature flag](../feature_flags.md) named `gitaly_gpg_signing`.
On GitLab.com, this feature is not available.

By default, Gitaly doesn't sign commits made using GitLab UI. For example, commits made using:

- Web editor.
- Web IDE.
- Merge requests.

You can configure Gitaly to sign commits made with the GitLab UI. The commits show as unverified and signed by an unknown
user. Support for improvements is proposed in [issue 19185](https://gitlab.com/gitlab-org/gitlab/-/issues/19185).

Configure Gitaly to sign commits made with the GitLab UI in one of two ways:

::Tabs

:::TabTitle Linux package (Omnibus)

1. [Create a GPG key](../../user/project/repository/signed_commits/gpg.md#create-a-gpg-key)
   and export it, or [create an SSH key](../../user/ssh.md#generate-an-ssh-key-pair). For optimal performance, use an EdDSA key.

   Export GPG key:

   ```shell
   gpg --export-secret-keys <ID> > signing_key.gpg
   ```

   Or create an SSH key (with no passphrase):

   ```shell
   ssh-keygen -t ed25519 -f signing_key.ssh
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

1. Save the file and [reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation).

:::TabTitle Self-compiled (source)

1. [Create a GPG key](../../user/project/repository/signed_commits/gpg.md#create-a-gpg-key)
   and export it, or [create an SSH key](../../user/ssh.md#generate-an-ssh-key-pair). For optimal performance, use an EdDSA key.

   Export GPG key:

   ```shell
   gpg --export-secret-keys <ID> > signing_key.gpg
   ```

   Or create an SSH key (with no passphrase):

   ```shell
   ssh-keygen -t ed25519 -f signing_key.ssh
   ```

1. On the Gitaly nodes, copy the key into `/etc/gitlab`.
1. Edit `/home/git/gitaly/config.toml` and configure `signing_key`:

   ```toml
   [git]
   signing_key = "/etc/gitlab/gitaly/signing_key.gpg"
   ```

1. Save the file and [restart GitLab](../restart_gitlab.md#self-compiled-installations).

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

## Configure server-side backups

> - [Introduced](https://gitlab.com/gitlab-org/gitaly/-/issues/4941) in GitLab 16.3.
> - Server-side support for restoring a specified backup instead of the latest backup [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/132188) in GitLab 16.6.
> - Server-side support for creating incremental backups [introduced](https://gitlab.com/gitlab-org/gitaly/-/merge_requests/6475) in GitLab 16.6.

Repository backups can be configured so that the Gitaly node that hosts each
repository is responsible for creating the backup and streaming it to
object storage. This helps reduce the network resources required to create and
restore a backup.

Each Gitaly node must be configured to connect to object storage for backups.

After configuring server-side backups, you can
[create a server-side repository backup](../backup_restore/backup_gitlab.md#create-server-side-repository-backups).

### Configure Azure Blob storage

How you configure Azure Blob storage for backups depends on the type of installation you have. For self-compiled installations, you must set
the `AZURE_STORAGE_ACCOUNT` and `AZURE_STORAGE_KEY` environment variables outside of GitLab.

::Tabs

:::TabTitle Linux package (Omnibus)

Edit `/etc/gitlab/gitlab.rb` and configure the `go_cloud_url`:

```ruby
gitaly['env'] = {
    'AZURE_STORAGE_ACCOUNT' => 'azure_storage_account',
    'AZURE_STORAGE_KEY' => 'azure_storage_key' # or 'AZURE_STORAGE_SAS_TOKEN'
}
gitaly['configuration'] = {
    backup: {
        go_cloud_url: 'azblob://gitaly-backups'
    }
}
```

:::TabTitle Self-compiled (source)

Edit `/home/git/gitaly/config.toml` and configure `go_cloud_url`:

```toml
[backup]
go_cloud_url = "azblob://gitaly-backups"
```

::EndTabs

### Configure Google Cloud storage

Google Cloud storage (GCP) authenticates using Application Default Credentials. Set up Application Default Credentials on each Gitaly server using either:

- The [`gcloud auth application-default login`](https://cloud.google.com/sdk/gcloud/reference/auth/application-default/login) command.
- The `GOOGLE_APPLICATION_CREDENTIALS` environment variable. For self-compiled installations, set the environment
  variable outside of GitLab.

For more information, see [Application Default Credentials](https://cloud.google.com/docs/authentication/provide-credentials-adc).

The destination bucket is configured using the `go_cloud_url` option.

::Tabs

:::TabTitle Linux package (Omnibus)

Edit `/etc/gitlab/gitlab.rb` and configure the `go_cloud_url`:

```ruby
gitaly['env'] = {
    'GOOGLE_APPLICATION_CREDENTIALS' => '/path/to/service.json'
}
gitaly['configuration'] = {
    backup: {
        go_cloud_url: 'gs://gitaly-backups'
    }
}
```

:::TabTitle Self-compiled (source)

Edit `/home/git/gitaly/config.toml` and configure `go_cloud_url`:

```toml
[backup]
go_cloud_url = "gs://gitaly-backups"
```

::EndTabs

### Configure S3 storage

To configure S3 storage authentication:

- If you authenticate with the AWS CLI, you can use the default AWS session.
- Otherwise, you can use the `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` environment variables. For self-compiled installations, set the environment
  variables outside of GitLab.

For more information, see [AWS Session documentation](https://docs.aws.amazon.com/sdk-for-go/api/aws/session/).

The destination bucket and region are configured using the `go_cloud_url` option.

::Tabs

:::TabTitle Linux package (Omnibus)

Edit `/etc/gitlab/gitlab.rb` and configure the `go_cloud_url`:

```ruby
gitaly['env'] = {
    'AWS_ACCESS_KEY_ID' => 'aws_access_key_id',
    'AWS_SECRET_ACCESS_KEY' => 'aws_secret_access_key'
}
gitaly['configuration'] = {
    backup: {
        go_cloud_url: 's3://gitaly-backups?region=us-west-1'
    }
}
```

:::TabTitle Self-compiled (source)

Edit `/home/git/gitaly/config.toml` and configure `go_cloud_url`:

```toml
[backup]
go_cloud_url = "s3://gitaly-backups?region=us-west-1"
```

::EndTabs

#### Configure S3-compatible servers

S3-compatible servers such as MinIO are configured similarly to S3 with the addition of the `endpoint` parameter.

The following parameters are supported:

- `region`: The AWS region.
- `endpoint`: The endpoint URL.
- `disabledSSL`: A value of `true` disables SSL.
- `s3ForcePathStyle`: A value of `true` forces path-style addressing.

::Tabs

:::TabTitle Linux package (Omnibus)

Edit `/etc/gitlab/gitlab.rb` and configure the `go_cloud_url`:

```ruby
gitaly['env'] = {
    'AWS_ACCESS_KEY_ID' => 'minio_access_key_id',
    'AWS_SECRET_ACCESS_KEY' => 'minio_secret_access_key'
}
gitaly['configuration'] = {
    backup: {
        go_cloud_url: 's3://gitaly-backups?region=minio&endpoint=my.minio.local:8080&disableSSL=true&s3ForcePathStyle=true'
    }
}
```

:::TabTitle Self-compiled (source)

Edit `/home/git/gitaly/config.toml` and configure `go_cloud_url`:

```toml
[backup]
go_cloud_url = "s3://gitaly-backups?region=minio&endpoint=my.minio.local:8080&disableSSL=true&s3ForcePathStyle=true"
```

::EndTabs

## Configure negotiation timeouts

> [Introduced](https://gitlab.com/gitlab-org/gitaly/-/issues/5574) in GitLab 16.5.

Gitaly supports configurable negotiation timeouts.

Negotiation timeouts can be configured for the `git-upload-pack(1)` and `git-upload-archive(1)`
operations, which are invoked by a Gitaly node when you execute the `git fetch` and
`git archive --remote` commands respectively. You might need to increase the negotiation timeout:

- For particularly large repositories.
- When performing these commands in parallel.

These timeouts affect only the [negotiation phase](https://git-scm.com/docs/pack-protocol/2.2.3#_packfile_negotiation) of
remote Git operations, not the entire transfer.

Valid values for timeouts follow the format of [`ParseDuration`](https://pkg.go.dev/time#ParseDuration) in Go.

How you configure negotiation timeouts depends on the type of installation you have:

::Tabs

:::TabTitle Linux package (Omnibus)

Edit `/etc/gitlab/gitlab.rb`:

```ruby
gitaly['configuration'] = {
    timeout: {
        upload_pack_negotiation: '10m',      # 10 minutes
        upload_archive_negotiation: '20m',   # 20 minutes
    }
}
```

:::TabTitle Self-compiled (source)

Edit `/home/git/gitaly/config.toml`:

```toml
[timeout]
upload_pack_negotiation = "10m"
upload_archive_negotiation = "20m"
```

::EndTabs
