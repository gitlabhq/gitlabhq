---
stage: Systems
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Configure Gitaly
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

Configure Gitaly in one of two ways:

::Tabs

:::TabTitle Linux package (Omnibus)

1. Edit `/etc/gitlab/gitlab.rb` and add or change the
   [Gitaly settings](https://gitlab.com/gitlab-org/gitaly/-/blob/master/config.toml.example).
1. Save the file and [reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation).

:::TabTitle Helm chart (Kubernetes)

1. Configure the [Gitaly chart](https://docs.gitlab.com/charts/charts/gitlab/gitaly/).
1. [Upgrade your Helm release](https://docs.gitlab.com/charts/installation/deployment.html).

:::TabTitle Self-compiled (source)

1. Edit `/home/git/gitaly/config.toml` and add or change the [Gitaly settings](https://gitlab.com/gitlab-org/gitaly/blob/master/config.toml.example).
1. Save the file and [restart GitLab](../restart_gitlab.md#self-compiled-installations).

::EndTabs

The following configuration options are also available:

- Enabling [TLS support](tls_support.md).
- Limiting [RPC concurrency](concurrency_limiting.md#limit-rpc-concurrency).
- Limiting [pack-objects concurrency](concurrency_limiting.md#limit-pack-objects-concurrency).

## About the Gitaly token

The token referred to throughout the Gitaly documentation is just an arbitrary password selected by
the administrator. It is unrelated to tokens created for the GitLab API or other similar web API
tokens.

## Run Gitaly on its own server

By default, Gitaly is run on the same server as Gitaly clients and is
configured as above. Single-server installations are best served by
this default configuration used by:

- [Linux package installations](https://docs.gitlab.com/omnibus/).
- [Self-compiled installations](../../install/installation.md).

However, Gitaly can be deployed to its own server, which can benefit GitLab installations that span
multiple machines.

NOTE:
When configured to run on their own servers, Gitaly servers must be
[upgraded](../../update/package/_index.md) before Gitaly clients in your cluster.

NOTE:
[Disk requirements](_index.md#disk-requirements) apply to Gitaly nodes.

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

The following diagram illustrates communication between Gitaly servers and GitLab Rails showing
the default ports for HTTP and HTTPs communication.

![Two Gitaly servers and a GitLab Rails exchanging information.](img/gitaly_network_v13_9.png)

WARNING:
Gitaly servers must not be exposed to the public internet as Gitaly network traffic is unencrypted
by default. The use of firewall is highly recommended to restrict access to the Gitaly server.
Another option is to [use TLS](tls_support.md).

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

To avoid downtime while rotating the Gitaly token, you can temporarily disable authentication using the `gitaly['auth_transitioning']` setting. For more information, see
[enable auth transitioning mode](#enable-auth-transitioning-mode).

#### Configure authentication

Gitaly and GitLab use two shared secrets for authentication:

- _Gitaly token_: used to authenticate gRPC requests to Gitaly.
- _GitLab Shell token_: used for authentication callbacks from GitLab Shell to the GitLab internal API.

::Tabs

:::TabTitle Linux package (Omnibus)

1. To configure the _Gitaly token_, edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitaly['configuration'] = {
      # ...
      auth: {
        # ...
        token: 'abc123secret',
      },
   }
   ```

1. Configure the _GitLab Shell token_ in one of two ways:

   - Method 1 (recommended):

     Copy `/etc/gitlab/gitlab-secrets.json` from the Gitaly client to same path on the Gitaly servers
     (and any other Gitaly clients).

   - Method 2:

     On all nodes running GitLab Rails, edit `/etc/gitlab/gitlab.rb`:

     ```ruby
     gitlab_shell['secret_token'] = 'shellsecret'
     ```

    On all nodes running Gitaly, edit `/etc/gitlab/gitlab.rb`:

     ```ruby
     gitaly['gitlab_secret'] = 'shellsecret'
     ```

     After those changes, reconfigure GitLab:

     ```shell
     sudo gitlab-ctl reconfigure
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

Configure Gitaly server.

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
   - For GitLab 15.3 and later, run `sudo -u git -- /opt/gitlab/embedded/bin/gitaly check /var/opt/gitlab/gitaly/config.toml`.
   - For GitLab 15.2 and earlier, run `sudo -u git -- /opt/gitlab/embedded/bin/gitaly-hooks check /var/opt/gitlab/gitaly/config.toml`.

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
   - For GitLab 15.3 and later, run `sudo -u git -- /opt/gitlab/embedded/bin/gitaly check /var/opt/gitlab/gitaly/config.toml`.
   - For GitLab 15.2 and earlier, run `sudo -u git -- /opt/gitlab/embedded/bin/gitaly-hooks check /var/opt/gitlab/gitaly/config.toml`.

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

Configure Gitaly clients in one of two ways. These instructions are for unencrypted connections but you can also enable [TLS support](tls_support.md):

::Tabs

:::TabTitle Linux package (Omnibus)

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   # Use the same token value configured on all Gitaly servers
   gitlab_rails['gitaly_token'] = '<AUTH_TOKEN>'

   gitlab_rails['repositories_storages'] = {
     'default'  => { 'gitaly_address' => 'tcp://gitaly1.internal:8075' },
     'storage1' => { 'gitaly_address' => 'tcp://gitaly1.internal:8075' },
     'storage2' => { 'gitaly_address' => 'tcp://gitaly2.internal:8075' },
   }
   ```

   Alternatively, if each Gitaly server is configured to use a different authentication token:

   ```ruby
   gitlab_rails['repositories_storages'] = {
     'default'  => { 'gitaly_address' => 'tcp://gitaly1.internal:8075', 'gitaly_token' => '<AUTH_TOKEN_1>' },
     'storage1' => { 'gitaly_address' => 'tcp://gitaly1.internal:8075', 'gitaly_token' => '<AUTH_TOKEN_1>' },
     'storage2' => { 'gitaly_address' => 'tcp://gitaly2.internal:8075', 'gitaly_token' => '<AUTH_TOKEN_2>' },
   }
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
gitlab_rails['repositories_storages'] = {
  'default' => { 'gitaly_address' => 'tcp://gitaly1.internal:8075' },
  'storage1' => { 'gitaly_address' => 'unix:/var/opt/gitlab/gitaly/gitaly.socket' },
  'storage2' => { 'gitaly_address' => 'tcp://gitaly2.internal:8075' },
}
```

To combine local and remote Gitaly servers, use an external address for the local Gitaly server. For
example:

```ruby
gitlab_rails['repositories_storages'] = {
  'default' => { 'gitaly_address' => 'tcp://gitaly1.internal:8075' },
  # Address of the GitLab server that also has Gitaly running on it
  'storage1' => { 'gitaly_address' => 'tcp://gitlab.internal:8075' },
  'storage2' => { 'gitaly_address' => 'tcp://gitaly2.internal:8075' },
}

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
reconfigure the GitLab application servers to remove the `default` storage because GitLab requires a storage called `default`.
[Read more](https://gitlab.com/gitlab-org/gitlab/-/issues/36175) about this limitation.

To work around the limitation:

1. Define an additional storage location on the new Gitaly service and configure the additional storage to be `default`.
1. In the [**Admin** area](../repository_storage_paths.md#configure-where-new-repositories-are-stored), set `default` to a weight of zero
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

## Control groups

WARNING:
Enabling limits on your environment should be done with caution and only
in select circumstances, such as to protect against unexpected traffic.
When reached, limits _do_ result in disconnects that negatively impact users.
For consistent and stable performance, you should first explore other options such as
adjusting node specifications, and [reviewing large repositories](../../user/project/repository/monorepos/_index.md) or workloads.

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

### Configure repository cgroups

> - This method of configuring repository cgroups was introduced in GitLab 15.1.
> - `cpu_quota_us`[introduced](https://gitlab.com/gitlab-org/gitaly/-/merge_requests/5422) in GitLab 15.10.
> - `max_cgroups_per_repo` [introduced](https://gitlab.com/gitlab-org/gitaly/-/issues/5689) in GitLab 16.7.
> - Documentation for the legacy method was [removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/176694) in GitLab 17.8.

To configure repository cgroups in Gitaly, use the following settings for `gitaly['configuration'][:cgroups]` in `/etc/gitlab/gitlab.rb`:

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
- `repositories.max_cgroups_per_repo` is the number of repository cgroups that Git processes
  targeting a specific repository can be distributed across. This enables more conservative
  CPU and memory limits to be configured for repository cgroups while still allowing for
  bursty workloads. For instance, with a `max_cgroups_per_repo` of `2` and a `memory_bytes`
  limit of 10 GB, independent Git operations against a specific repository can consume up
  to 20 GB of memory.

For example (not necessarily recommended settings):

```ruby
# in /etc/gitlab/gitlab.rb
gitaly['configuration'] = {
  # ...
  cgroups: {
    mountpoint: '/sys/fs/cgroup',
    hierarchy_root: 'gitaly',
    memory_bytes: 64424509440, # 60 GB
    cpu_shares: 1024,
    cpu_quota_us: 400000 # 4 cores
    repositories: {
      count: 1000,
      memory_bytes: 32212254720, # 20 GB
      cpu_shares: 512,
      cpu_quota_us: 200000, # 2 cores
      max_cgroups_per_repo: 2
    },
  },
}
```

### Configuring oversubscription

In the previous example:

- The top level memory limit is capped at 60 GB.
- Each of the 1000 cgroups in the repositories pool is capped at 20 GB.

This configuration leads to oversubscription. Each cgroup in the pool has a much larger capacity than 1/1000th
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
- [Enabling auth transitioning mode](#enable-auth-transitioning-mode).
- [Updating Gitaly authentication tokens](#update-gitaly-authentication-token).
- [Ensuring there are no authentication failures](#ensure-there-are-no-authentication-failures).
- [Disabling auth transitioning mode](#disable-auth-transitioning-mode).
- [Verifying authentication is enforced](#verify-authentication-is-enforced).

This procedure also works if you are running GitLab on a single server. In that case, the Gitaly
server and the Gitaly client refer to the same machine.

### Verify authentication monitoring

Before rotating a Gitaly authentication token, verify that you can
[monitor the authentication behavior](monitoring.md#queries) of your GitLab installation using
Prometheus.

You can then continue the rest of the procedure.

### Enable auth transitioning mode

Temporarily disable Gitaly authentication on the Gitaly servers by putting them into auth
transitioning mode as follows:

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

### Disable auth transitioning mode

To re-enable Gitaly authentication, disable auth transitioning mode. Update the configuration on
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

## Pack-objects cache

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

[Gitaly](_index.md), the service that provides storage for Git
repositories, can be configured to cache a short rolling window of Git
fetch responses. This can reduce server load when your server receives
lots of CI fetch traffic.

The pack-objects cache wraps `git pack-objects`, an internal part of
Git that gets invoked indirectly by using the PostUploadPack and
SSHUploadPack Gitaly RPCs. Gitaly runs PostUploadPack when a
user does a Git fetch by using HTTP, or SSHUploadPack when a
user does a Git fetch by using SSH.
When the cache is enabled, anything that uses PostUploadPack or SSHUploadPack can
benefit from it. It is independent of and unaffected by:

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
    enabled: true,
    # The default settings for "dir", "max_age" and "min_occurences" should be fine.
    # If you want to customize these, see details below.
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

WARNING:
All existing data in the specified directory will be removed.
Take care not to use a directory with existing data.

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
`5*60*100 MB = 30 GB` of data in your cache directory. This average is an expected average, not
a guarantee. Peak size may exceed this average.

#### Cache eviction window `max_age`

The `max_age` configuration setting lets you control the chance of a
cache hit and the average amount of storage used by cache files.
Entries older than `max_age` get deleted from the disk.

Eviction does not interfere with ongoing requests. It is OK for `max_age` to be less than the time it takes to do a
fetch over a slow connection because Unix filesystems do not truly delete a file until all processes that are reading
the deleted file have closed it.

#### Minimum key occurrences `min_occurrences`

> - [Introduced](https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/2222) in GitLab 15.11.

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

> - Logs for pack-objects caching was [changed](https://gitlab.com/gitlab-org/gitaly/-/merge_requests/5719) in GitLab 16.0.

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

## `cat-file` cache

A lot of Gitaly RPCs need to look up Git objects from repositories.
Most of the time we use `git cat-file --batch` processes for that. For
better performance, Gitaly can re-use these `git cat-file` processes
across RPC calls. Previously used processes are kept around in a
[`git cat-file` cache](https://about.gitlab.com/blog/2019/07/08/git-performance-on-nfs/#enter-cat-file-cache).
To control how much system resources this uses, we have a maximum number of
cat-file processes that can go into the cache.

The default limit is 100 `cat-file`s, which constitute a pair of
`git cat-file --batch` and `git cat-file --batch-check` processes. If
you see errors about "too many open files", or an
inability to create new processes, you may want to lower this limit.

Ideally, the number should be large enough to handle standard
traffic. If you raise the limit, you should measure the cache hit ratio
before and after. If the hit ratio does not improve, the higher limit is
probably not making a meaningful difference. Here is an example
Prometheus query to see the hit rate:

```plaintext
sum(rate(gitaly_catfile_cache_total{type="hit"}[5m])) / sum(rate(gitaly_catfile_cache_total{type=~"(hit)|(miss)"}[5m]))
```

Configure the `cat-file` cache in the [Gitaly configuration file](reference.md).

## Configure commit signing for GitLab UI commits

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/19185) in GitLab 15.4.
> - Displaying **Verified** badge for signed GitLab UI commits [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/124218) in GitLab 16.3 [with a flag](../feature_flags.md) named `gitaly_gpg_signing`. Disabled by default.
> - Verifying the signatures using multiple keys specified in `rotated_signing_keys` option [introduced](https://gitlab.com/gitlab-org/gitaly/-/merge_requests/6163) in GitLab 16.3.
> - [Enabled by default](https://gitlab.com/gitlab-org/gitaly/-/merge_requests/6876) on GitLab Self-Managed and GitLab Dedicated in GitLab 17.0.

FLAG:
On GitLab Self-Managed, by default this feature is available. To hide the feature,
an administrator can [disable the feature flag](../feature_flags.md) named `gitaly_gpg_signing`.
On GitLab.com, this feature is not available. On GitLab Dedicated, this feature is available.

By default, Gitaly doesn't sign commits made using GitLab UI. For example, commits made using:

- Web editor.
- Web IDE.
- Merge requests.

You can configure Gitaly to sign commits made with the GitLab UI.

By default, Gitaly sets the author of a commit as the committer. In this case,
it is harder to [Verify commits locally](../../user/project/repository/signed_commits/ssh.md#verify-commits-locally)
because the signature belongs to neither the author nor the committer of the commit.

You can configure Gitaly to reflect that a commit has been committed by your instance by
setting `committer_email` and `committer_name`. For example, on GitLab.com these configuration options are
set to `noreply@gitlab.com` and `GitLab`.

`rotated_signing_keys` is a list of keys to use for verification only. Gitaly tries to verify a web commit using the configured `signing_key`, and then uses
the rotated keys one by one until it succeeds. Set the `rotated_signing_keys` option when either:

- The signing key is rotated.
- You want to specify multiple keys to migrate projects from other instances and want to display their web commits as **Verified**.

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
1. Edit `/etc/gitlab/gitlab.rb` and configure `gitaly['git']['signing_key']`:

   ```ruby
   gitaly['configuration'] = {
      # ...
      git: {
        # ...
        committer_name: 'Your Instance',
        committer_email: 'noreply@yourinstance.com',
        signing_key: '/etc/gitlab/gitaly/signing_key.gpg',
        rotated_signing_keys: ['/etc/gitlab/gitaly/previous_signing_key.gpg'],
        # ...
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
   committer_name = "Your Instance"
   committer_email = "noreply@yourinstance.com"
   signing_key = "/etc/gitlab/gitaly/signing_key.gpg"
   rotated_signing_keys = ["/etc/gitlab/gitaly/previous_signing_key.gpg"]
   ```

1. Save the file and [restart GitLab](../restart_gitlab.md#self-compiled-installations).

::EndTabs

## Generate configuration using an external command

> - [Introduced](https://gitlab.com/gitlab-org/gitaly/-/issues/4828) in GitLab 15.11.

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
> - Server-side support added to Helm chart installations in GitLab 17.0.

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
        go_cloud_url: 'azblob://<bucket>'
    }
}
```

:::TabTitle Helm chart (Kubernetes)

For Helm-based deployments, see the
[server-side backup documentation for Gitaly chart](https://docs.gitlab.com/charts/charts/gitlab/gitaly/index.html#server-side-backups).

:::TabTitle Self-compiled (source)

Edit `/home/git/gitaly/config.toml` and configure `go_cloud_url`:

```toml
[backup]
go_cloud_url = "azblob://<bucket>"
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
        go_cloud_url: 'gs://<bucket>'
    }
}
```

:::TabTitle Helm chart (Kubernetes)

For Helm-based deployments, see the
[server-side backup documentation for Gitaly chart](https://docs.gitlab.com/charts/charts/gitlab/gitaly/index.html#server-side-backups).

:::TabTitle Self-compiled (source)

Edit `/home/git/gitaly/config.toml` and configure `go_cloud_url`:

```toml
[backup]
go_cloud_url = "gs://<bucket>"
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
        go_cloud_url: 's3://<bucket>?region=us-west-1'
    }
}
```

:::TabTitle Helm chart (Kubernetes)

For Helm-based deployments, see the
[server-side backup documentation for Gitaly chart](https://docs.gitlab.com/charts/charts/gitlab/gitaly/index.html#server-side-backups).

:::TabTitle Self-compiled (source)

Edit `/home/git/gitaly/config.toml` and configure `go_cloud_url`:

```toml
[backup]
go_cloud_url = "s3://<bucket>?region=us-west-1"
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

:::TabTitle Helm chart (Kubernetes)

For Helm-based deployments, see the
[server-side backup documentation for Gitaly chart](https://docs.gitlab.com/charts/charts/gitlab/gitaly/index.html#server-side-backups).

:::TabTitle Linux package (Omnibus)

Edit `/etc/gitlab/gitlab.rb` and configure the `go_cloud_url`:

```ruby
gitaly['env'] = {
    'AWS_ACCESS_KEY_ID' => 'minio_access_key_id',
    'AWS_SECRET_ACCESS_KEY' => 'minio_secret_access_key'
}
gitaly['configuration'] = {
    backup: {
        go_cloud_url: 's3://<bucket>?region=minio&endpoint=my.minio.local:8080&disableSSL=true&s3ForcePathStyle=true'
    }
}
```

:::TabTitle Self-compiled (source)

Edit `/home/git/gitaly/config.toml` and configure `go_cloud_url`:

```toml
[backup]
go_cloud_url = "s3://<bucket>?region=minio&endpoint=my.minio.local:8080&disableSSL=true&s3ForcePathStyle=true"
```

::EndTabs
