---
reading_time: true
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Reference architecture: up to 50,000 users **(PREMIUM ONLY)**

This page describes GitLab reference architecture for up to 50,000 users. For a
full list of reference architectures, see
[Available reference architectures](index.md#available-reference-architectures).

> - **Supported users (approximate):** 50,000
> - **High Availability:** Yes
> - **Test requests per second (RPS) rates:** API: 1000 RPS, Web: 100 RPS, Git: 100 RPS

| Service                                 | Nodes       | Configuration           | GCP             | AWS          | Azure    |
|-----------------------------------------|-------------|-------------------------|-----------------|--------------|----------|
| External load balancing node            | 1           | 8 vCPU, 7.2 GB memory   | n1-highcpu-8    | c5.2xlarge   | F8s v2   |
| Consul                                  | 3           | 2 vCPU, 1.8 GB memory   | n1-highcpu-2    | c5.large     | F2s v2   |
| PostgreSQL                              | 3           | 16 vCPU, 60 GB memory   | n1-standard-16  | m5.4xlarge   | D16s v3  |
| PgBouncer                               | 3           | 2 vCPU, 1.8 GB memory   | n1-highcpu-2    | c5.large     | F2s v2   |
| Internal load balancing node            | 1           | 8 vCPU, 7.2 GB memory   | n1-highcpu-8    | c5.2xlarge   | F8s v2   |
| Redis - Cache                           | 3           | 4 vCPU, 15 GB memory    | n1-standard-4   | m5.xlarge    | D4s v3   |
| Redis - Queues / Shared State           | 3           | 4 vCPU, 15 GB memory    | n1-standard-4   | m5.xlarge    | D4s v3   |
| Redis Sentinel - Cache                  | 3           | 1 vCPU, 1.7 GB memory   | g1-small        | t3.small     | B1MS     |
| Redis Sentinel - Queues / Shared State  | 3           | 1 vCPU, 1.7 GB memory   | g1-small        | t3.small     | B1MS     |
| Gitaly                                  | 2 (minimum) | 64 vCPU, 240 GB memory  | n1-standard-64  | m5.16xlarge  | D64s v3  |
| Sidekiq                                 | 4           | 4 vCPU, 15 GB memory    | n1-standard-4   | m5.xlarge    | D4s v3   |
| GitLab Rails                            | 12          | 32 vCPU, 28.8 GB memory | n1-highcpu-32   | c5.9xlarge   | F32s v2  |
| Monitoring node                         | 1           | 4 vCPU, 3.6 GB memory   | n1-highcpu-4    | c5.xlarge    | F4s v2   |
| Object storage                          | n/a         | n/a                     | n/a             | n/a          | n/a      |
| NFS server                              | 1           | 4 vCPU, 3.6 GB memory   | n1-highcpu-4    | c5.xlarge    | F4s v2   |

```mermaid
stateDiagram-v2
    [*] --> LoadBalancer
    LoadBalancer --> ApplicationServer

    ApplicationServer --> BackgroundJobs
    ApplicationServer --> Gitaly
    ApplicationServer --> Redis_Cache
    ApplicationServer --> Redis_Queues
    ApplicationServer --> PgBouncer
    PgBouncer --> Database
    ApplicationServer --> ObjectStorage
    BackgroundJobs --> ObjectStorage

    ApplicationMonitoring -->ApplicationServer
    ApplicationMonitoring -->PgBouncer
    ApplicationMonitoring -->Database
    ApplicationMonitoring -->BackgroundJobs

    ApplicationServer --> Consul

    Consul --> Database
    Consul --> PgBouncer
    Redis_Cache --> Consul
    Redis_Queues --> Consul
    BackgroundJobs --> Consul

    state Consul {
      "Consul_1..3"
    }

    state Database {
      "PG_Primary_Node"
      "PG_Secondary_Node_1..2"
    }

    state Redis_Cache {
      "R_Cache_Primary_Node"
      "R_Cache_Replica_Node_1..2"
      "R_Cache_Sentinel_1..3"
    }

    state Redis_Queues {
      "R_Queues_Primary_Node"
      "R_Queues_Replica_Node_1..2"
      "R_Queues_Sentinel_1..3"
    }

    state Gitaly {
      "Gitaly_1..2"
    }

    state BackgroundJobs {
      "Sidekiq_1..4"
    }

    state ApplicationServer {
      "GitLab_Rails_1..12"
    }

    state LoadBalancer {
      "LoadBalancer_1"
    }

    state ApplicationMonitoring {
      "Prometheus"
      "Grafana"
    }

    state PgBouncer {
      "Internal_Load_Balancer"
      "PgBouncer_1..3"
    }
```

The Google Cloud Platform (GCP) architectures were built and tested using the
[Intel Xeon E5 v3 (Haswell)](https://cloud.google.com/compute/docs/cpu-platforms)
CPU platform. On different hardware you may find that adjustments, either lower
or higher, are required for your CPU or node counts. For more information, see
our [Sysbench](https://github.com/akopytov/sysbench)-based
[CPU benchmark](https://gitlab.com/gitlab-org/quality/performance/-/wikis/Reference-Architectures/GCP-CPU-Benchmarks).

Due to better performance and availability, for data objects (such as LFS,
uploads, or artifacts), using an [object storage service](#configure-the-object-storage)
is recommended instead of using NFS. Using an object storage service also
doesn't require you to provision and maintain a node.

## Setup components

To set up GitLab and its components to accommodate up to 50,000 users:

1. [Configure the external load balancing node](#configure-the-external-load-balancer)
   to handle the load balancing of the GitLab application services nodes.
1. [Configure Consul](#configure-consul).
1. [Configure PostgreSQL](#configure-postgresql), the database for GitLab.
1. [Configure PgBouncer](#configure-pgbouncer).
1. [Configure the internal load balancing node](#configure-the-internal-load-balancer).
1. [Configure Redis](#configure-redis).
1. [Configure Gitaly](#configure-gitaly),
   which provides access to the Git repositories.
1. [Configure Sidekiq](#configure-sidekiq).
1. [Configure the main GitLab Rails application](#configure-gitlab-rails)
   to run Puma/Unicorn, Workhorse, GitLab Shell, and to serve all frontend
   requests (which include UI, API, and Git over HTTP/SSH).
1. [Configure Prometheus](#configure-prometheus) to monitor your GitLab
   environment.
1. [Configure the object storage](#configure-the-object-storage)
   used for shared data objects.
1. [Configure Advanced Search](#configure-advanced-search) (optional) for faster,
   more advanced code search across your entire GitLab instance.
1. [Configure NFS](#configure-nfs-optional) (optional, and not recommended)
   to have shared disk storage service as an alternative to Gitaly or object
   storage. You can skip this step if you're not using GitLab Pages (which
   requires NFS).

The servers start on the same 10.6.0.0/24 private network range, and can
connect to each other freely on these addresses.

The following list includes descriptions of each server and its assigned IP:

- `10.6.0.10`: External Load Balancer
- `10.6.0.11`: Consul 1
- `10.6.0.12`: Consul 2
- `10.6.0.13`: Consul 3
- `10.6.0.21`: PostgreSQL primary
- `10.6.0.22`: PostgreSQL secondary 1
- `10.6.0.23`: PostgreSQL secondary 2
- `10.6.0.31`: PgBouncer 1
- `10.6.0.32`: PgBouncer 2
- `10.6.0.33`: PgBouncer 3
- `10.6.0.40`: Internal Load Balancer
- `10.6.0.51`: Redis - Cache Primary
- `10.6.0.52`: Redis - Cache Replica 1
- `10.6.0.53`: Redis - Cache Replica 2
- `10.6.0.71`: Sentinel - Cache 1
- `10.6.0.72`: Sentinel - Cache 2
- `10.6.0.73`: Sentinel - Cache 3
- `10.6.0.61`: Redis - Queues Primary
- `10.6.0.62`: Redis - Queues Replica 1
- `10.6.0.63`: Redis - Queues Replica 2
- `10.6.0.81`: Sentinel - Queues 1
- `10.6.0.82`: Sentinel - Queues 2
- `10.6.0.83`: Sentinel - Queues 3
- `10.6.0.91`: Gitaly 1
- `10.6.0.92`: Gitaly 2
- `10.6.0.101`: Sidekiq 1
- `10.6.0.102`: Sidekiq 2
- `10.6.0.103`: Sidekiq 3
- `10.6.0.104`: Sidekiq 4
- `10.6.0.111`: GitLab application 1
- `10.6.0.112`: GitLab application 2
- `10.6.0.113`: GitLab application 3
- `10.6.0.121`: Prometheus

## Configure the external load balancer

In an active/active GitLab configuration, you'll need a load balancer to route
traffic to the application servers. The specifics on which load balancer to use
or its exact configuration is beyond the scope of GitLab documentation. We hope
that if you're managing multi-node systems like GitLab, you already have a load
balancer of choice. Some load balancer examples include HAProxy (open-source),
F5 Big-IP LTM, and Citrix Net Scaler. This documentation outline the ports and
protocols needed for use with GitLab.

This architecture has been tested and validated with [HAProxy](https://www.haproxy.org/)
as the load balancer. Although other load balancers with similar feature sets
could also be used, those load balancers have not been validated.

The next question is how you will handle SSL in your environment.
There are several different options:

- [The application node terminates SSL](#application-node-terminates-ssl).
- [The load balancer terminates SSL without backend SSL](#load-balancer-terminates-ssl-without-backend-ssl)
  and communication is not secure between the load balancer and the application node.
- [The load balancer terminates SSL with backend SSL](#load-balancer-terminates-ssl-with-backend-ssl)
  and communication is *secure* between the load balancer and the application node.

### Application node terminates SSL

Configure your load balancer to pass connections on port 443 as `TCP` rather
than `HTTP(S)` protocol. This will pass the connection to the application node's
NGINX service untouched. NGINX will have the SSL certificate and listen on port 443.

See the [NGINX HTTPS documentation](https://docs.gitlab.com/omnibus/settings/nginx.html#enable-https)
for details on managing SSL certificates and configuring NGINX.

### Load balancer terminates SSL without backend SSL

Configure your load balancer to use the `HTTP(S)` protocol rather than `TCP`.
The load balancer will then be responsible for managing SSL certificates and
terminating SSL.

Since communication between the load balancer and GitLab will not be secure,
there is some additional configuration needed. See the
[NGINX proxied SSL documentation](https://docs.gitlab.com/omnibus/settings/nginx.html#supporting-proxied-ssl)
for details.

### Load balancer terminates SSL with backend SSL

Configure your load balancer(s) to use the 'HTTP(S)' protocol rather than 'TCP'.
The load balancer(s) will be responsible for managing SSL certificates that
end users will see.

Traffic will also be secure between the load balancer(s) and NGINX in this
scenario. There is no need to add configuration for proxied SSL since the
connection will be secure all the way. However, configuration will need to be
added to GitLab to configure SSL certificates. See
[NGINX HTTPS documentation](https://docs.gitlab.com/omnibus/settings/nginx.html#enable-https)
for details on managing SSL certificates and configuring NGINX.

### Readiness checks

Ensure the external load balancer only routes to working services with built
in monitoring endpoints. The [readiness checks](../../user/admin_area/monitoring/health_check.md)
all require [additional configuration](../monitoring/ip_whitelist.md)
on the nodes being checked, otherwise, the external load balancer will not be able to
connect.

### Ports

The basic ports to be used are shown in the table below.

| LB Port | Backend Port | Protocol                 |
| ------- | ------------ | ------------------------ |
| 80      | 80           | HTTP (*1*)               |
| 443     | 443          | TCP or HTTPS (*1*) (*2*) |
| 22      | 22           | TCP                      |

- (*1*): [Web terminal](../../ci/environments/index.md#web-terminals) support requires
  your load balancer to correctly handle WebSocket connections. When using
  HTTP or HTTPS proxying, this means your load balancer must be configured
  to pass through the `Connection` and `Upgrade` hop-by-hop headers. See the
  [web terminal](../integration/terminal.md) integration guide for
  more details.
- (*2*): When using HTTPS protocol for port 443, you will need to add an SSL
  certificate to the load balancers. If you wish to terminate SSL at the
  GitLab application server instead, use TCP protocol.

If you're using GitLab Pages with custom domain support you will need some
additional port configurations.
GitLab Pages requires a separate virtual IP address. Configure DNS to point the
`pages_external_url` from `/etc/gitlab/gitlab.rb` at the new virtual IP address. See the
[GitLab Pages documentation](../pages/index.md) for more information.

| LB Port | Backend Port  | Protocol  |
| ------- | ------------- | --------- |
| 80      | Varies (*1*)  | HTTP      |
| 443     | Varies (*1*)  | TCP (*2*) |

- (*1*): The backend port for GitLab Pages depends on the
  `gitlab_pages['external_http']` and `gitlab_pages['external_https']`
  setting. See [GitLab Pages documentation](../pages/index.md) for more details.
- (*2*): Port 443 for GitLab Pages should always use the TCP protocol. Users can
  configure custom domains with custom SSL, which would not be possible
  if SSL was terminated at the load balancer.

#### Alternate SSH Port

Some organizations have policies against opening SSH port 22. In this case,
it may be helpful to configure an alternate SSH hostname that allows users
to use SSH on port 443. An alternate SSH hostname will require a new virtual IP address
compared to the other GitLab HTTP configuration above.

Configure DNS for an alternate SSH hostname such as `altssh.gitlab.example.com`.

| LB Port | Backend Port | Protocol |
| ------- | ------------ | -------- |
| 443     | 22           | TCP      |

<div align="right">
  <a type="button" class="btn btn-default" href="#setup-components">
    Back to setup components <i class="fa fa-angle-double-up" aria-hidden="true"></i>
  </a>
</div>

## Configure Consul

The following IPs will be used as an example:

- `10.6.0.11`: Consul 1
- `10.6.0.12`: Consul 2
- `10.6.0.13`: Consul 3

NOTE: **Note:**
The configuration processes for the other servers in your reference architecture will
use the `/etc/gitlab/gitlab-secrets.json` file from your Consul server to connect
with the other servers.

To configure Consul:

1. SSH in to the server that will host Consul.
1. [Download and install](https://about.gitlab.com/install/) the Omnibus GitLab
   package of your choice. Be sure to both follow _only_ installation steps 1 and 2
   on the page, and to select the correct Omnibus GitLab package, with the same version
   and type (Community or Enterprise editions) as your current install.
1. Edit `/etc/gitlab/gitlab.rb` and add the contents:

   ```ruby
   roles ['consul_role']

   ## Enable service discovery for Prometheus
   consul['enable'] = true
   consul['monitoring_service_discovery'] =  true

   ## The IPs of the Consul server nodes
   ## You can also use FQDNs and intermix them with IPs
   consul['configuration'] = {
      server: true,
      retry_join: %w(10.6.0.11 10.6.0.12 10.6.0.13),
   }

   # Set the network addresses that the exporters will listen on
   node_exporter['listen_address'] = '0.0.0.0:9100'

   # Disable auto migrations
   gitlab_rails['auto_migrate'] = false
   ```

1. [Reconfigure Omnibus GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure) for the changes to take effect.
1. Go through the steps again for all the other Consul nodes, and
   make sure you set up the correct IPs.

A Consul leader is _elected_ when the provisioning of the third Consul server is
complete. Viewing the Consul logs `sudo gitlab-ctl tail consul` displays
`...[INFO] consul: New leader elected: ...`.

You can list the current Consul members (server, client):

```shell
sudo /opt/gitlab/embedded/bin/consul members
```

You can verify the GitLab services are running:

```shell
sudo gitlab-ctl status
```

The output should be similar to the following:

```plaintext
run: consul: (pid 30074) 76834s; run: log: (pid 29740) 76844s
run: logrotate: (pid 30925) 3041s; run: log: (pid 29649) 76861s
run: node-exporter: (pid 30093) 76833s; run: log: (pid 29663) 76855s
```

<div align="right">
  <a type="button" class="btn btn-default" href="#setup-components">
    Back to setup components <i class="fa fa-angle-double-up" aria-hidden="true"></i>
  </a>
</div>

## Configure PostgreSQL

In this section, you'll be guided through configuring an external PostgreSQL database
to be used with GitLab.

### Provide your own PostgreSQL instance

If you're hosting GitLab on a cloud provider, you can optionally use a
managed service for PostgreSQL. For example, AWS offers a managed Relational
Database Service (RDS) that runs PostgreSQL.

If you use a cloud-managed service, or provide your own PostgreSQL:

1. Set up PostgreSQL according to the
   [database requirements document](../../install/requirements.md#database).
1. Set up a `gitlab` username with a password of your choice. The `gitlab` user
   needs privileges to create the `gitlabhq_production` database.
1. Configure the GitLab application servers with the appropriate details.
   This step is covered in [Configuring the GitLab Rails application](#configure-gitlab-rails).

See [Configure GitLab using an external PostgreSQL service](../postgresql/external.md) for
further configuration steps.

### Standalone PostgreSQL using Omnibus GitLab

The following IPs will be used as an example:

- `10.6.0.21`: PostgreSQL primary
- `10.6.0.22`: PostgreSQL secondary 1
- `10.6.0.23`: PostgreSQL secondary 2

First, make sure to [install](https://about.gitlab.com/install/)
the Linux GitLab package **on each node**. Following the steps,
install the necessary dependencies from step 1, and add the
GitLab package repository from step 2. When installing GitLab
in the second step, do not supply the `EXTERNAL_URL` value.

#### PostgreSQL primary node

1. SSH in to the PostgreSQL primary node.
1. Generate a password hash for the PostgreSQL username/password pair. This assumes you will use the default
   username of `gitlab` (recommended). The command will request a password
   and confirmation. Use the value that is output by this command in the next
   step as the value of `<postgresql_password_hash>`:

   ```shell
   sudo gitlab-ctl pg-password-md5 gitlab
   ```

1. Generate a password hash for the PgBouncer username/password pair. This assumes you will use the default
   username of `pgbouncer` (recommended). The command will request a password
   and confirmation. Use the value that is output by this command in the next
   step as the value of `<pgbouncer_password_hash>`:

   ```shell
   sudo gitlab-ctl pg-password-md5 pgbouncer
   ```

1. Generate a password hash for the Consul database username/password pair. This assumes you will use the default
   username of `gitlab-consul` (recommended). The command will request a password
   and confirmation. Use the value that is output by this command in the next
   step as the value of `<consul_password_hash>`:

   ```shell
   sudo gitlab-ctl pg-password-md5 gitlab-consul
   ```

1. On the primary database node, edit `/etc/gitlab/gitlab.rb` replacing values noted in the `# START user configuration` section:

   ```ruby
   # Disable all components except PostgreSQL and Repmgr and Consul
   roles ['postgres_role']

   # PostgreSQL configuration
   postgresql['listen_address'] = '0.0.0.0'
   postgresql['hot_standby'] = 'on'
   postgresql['wal_level'] = 'replica'
   postgresql['shared_preload_libraries'] = 'repmgr_funcs'

   # Disable automatic database migrations
   gitlab_rails['auto_migrate'] = false

   # Configure the Consul agent
   consul['services'] = %w(postgresql)

   # START user configuration
   # Please set the real values as explained in Required Information section
   #
   # Replace PGBOUNCER_PASSWORD_HASH with a generated md5 value
   postgresql['pgbouncer_user_password'] = '<pgbouncer_password_hash>'
   # Replace POSTGRESQL_PASSWORD_HASH with a generated md5 value
   postgresql['sql_user_password'] = '<postgresql_password_hash>'
   # Set `max_wal_senders` to one more than the number of database nodes in the cluster.
   # This is used to prevent replication from using up all of the
   # available database connections.
   postgresql['max_wal_senders'] = 4
   postgresql['max_replication_slots'] = 4

   # Replace XXX.XXX.XXX.XXX/YY with Network Address
   postgresql['trust_auth_cidr_addresses'] = %w(10.6.0.0/24)
   repmgr['trust_auth_cidr_addresses'] = %w(127.0.0.1/32 10.6.0.0/24)

   ## Enable service discovery for Prometheus
   consul['monitoring_service_discovery'] =  true

   # Set the network addresses that the exporters will listen on for monitoring
   node_exporter['listen_address'] = '0.0.0.0:9100'
   postgres_exporter['listen_address'] = '0.0.0.0:9187'

   ## The IPs of the Consul server nodes
   ## You can also use FQDNs and intermix them with IPs
   consul['configuration'] = {
      retry_join: %w(10.6.0.11 10.6.0.12 10.6.0.13),
   }
   #
   # END user configuration
   ```

1. Copy the `/etc/gitlab/gitlab-secrets.json` file from your Consul server, and replace
   the file of the same name on this server. If that file is not on this server,
   add the file from your Consul server to this server.

1. [Reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure) for the changes to take effect.

<div align="right">
  <a type="button" class="btn btn-default" href="#setup-components">
    Back to setup components <i class="fa fa-angle-double-up" aria-hidden="true"></i>
  </a>
</div>

#### PostgreSQL secondary nodes

1. On both the secondary nodes, add the same configuration specified above for the primary node
   with an additional setting (`repmgr['master_on_initialization'] = false`) that will inform `gitlab-ctl` that they are standby nodes initially
   and there's no need to attempt to register them as a primary node:

   ```ruby
   # Disable all components except PostgreSQL and Repmgr and Consul
   roles ['postgres_role']

   # PostgreSQL configuration
   postgresql['listen_address'] = '0.0.0.0'
   postgresql['hot_standby'] = 'on'
   postgresql['wal_level'] = 'replica'
   postgresql['shared_preload_libraries'] = 'repmgr_funcs'

   # Disable automatic database migrations
   gitlab_rails['auto_migrate'] = false

   # Configure the Consul agent
   consul['services'] = %w(postgresql)

   # Specify if a node should attempt to be primary on initialization.
   repmgr['master_on_initialization'] = false

   # Replace PGBOUNCER_PASSWORD_HASH with a generated md5 value
   postgresql['pgbouncer_user_password'] = '<pgbouncer_password_hash>'
   # Replace POSTGRESQL_PASSWORD_HASH with a generated md5 value
   postgresql['sql_user_password'] = '<postgresql_password_hash>'
   # Set `max_wal_senders` to one more than the number of database nodes in the cluster.
   # This is used to prevent replication from using up all of the
   # available database connections.
   postgresql['max_wal_senders'] = 4
   postgresql['max_replication_slots'] = 4

   # Replace with your network addresses
   postgresql['trust_auth_cidr_addresses'] = %w(10.6.0.0/24)
   repmgr['trust_auth_cidr_addresses'] = %w(127.0.0.1/32 10.6.0.0/24)

   ## Enable service discovery for Prometheus
   consul['monitoring_service_discovery'] =  true

   # Set the network addresses that the exporters will listen on for monitoring
   node_exporter['listen_address'] = '0.0.0.0:9100'
   postgres_exporter['listen_address'] = '0.0.0.0:9187'

   ## The IPs of the Consul server nodes
   ## You can also use FQDNs and intermix them with IPs
   consul['configuration'] = {
      retry_join: %w(10.6.0.11 10.6.0.12 10.6.0.13),
   }
   ```

1. Copy the `/etc/gitlab/gitlab-secrets.json` file from your Consul server, and replace
   the file of the same name on this server. If that file is not on this server,
   add the file from your Consul server to this server.

1. [Reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure) for the changes to take effect.

Advanced [configuration options](https://docs.gitlab.com/omnibus/settings/database.html)
are supported and can be added if needed.

<div align="right">
  <a type="button" class="btn btn-default" href="#setup-components">
    Back to setup components <i class="fa fa-angle-double-up" aria-hidden="true"></i>
  </a>
</div>

#### PostgreSQL post-configuration

SSH in to the **primary node**:

1. Open a database prompt:

   ```shell
   gitlab-psql -d gitlabhq_production
   ```

1. Make sure the `pg_trgm` extension is enabled (it might already be):

   ```shell
   CREATE EXTENSION pg_trgm;
   ```

1. Exit the database prompt by typing `\q` and Enter.

1. Verify the cluster is initialized with one node:

   ```shell
   gitlab-ctl repmgr cluster show
   ```

   The output should be similar to the following:

   ```plaintext
   Role      | Name     | Upstream | Connection String
   ----------+----------|----------|----------------------------------------
   * master  | HOSTNAME |          | host=HOSTNAME user=gitlab_repmgr dbname=gitlab_repmgr
   ```

1. Note down the hostname or IP address in the connection string: `host=HOSTNAME`. We will
   refer to the hostname in the next section as `<primary_node_name>`. If the value
   is not an IP address, it will need to be a resolvable name (via DNS or
   `/etc/hosts`)

SSH in to the **secondary node**:

1. Set up the repmgr standby:

   ```shell
   gitlab-ctl repmgr standby setup <primary_node_name>
   ```

   Do note that this will remove the existing data on the node. The command
   has a wait time.

   The output should be similar to the following:

   ```console
   Doing this will delete the entire contents of /var/opt/gitlab/postgresql/data
   If this is not what you want, hit Ctrl-C now to exit
   To skip waiting, rerun with the -w option
   Sleeping for 30 seconds
   Stopping the database
   Removing the data
   Cloning the data
   Starting the database
   Registering the node with the cluster
   ok: run: repmgrd: (pid 19068) 0s
   ```

Before moving on, make sure the databases are configured correctly. Run the
following command on the **primary** node to verify that replication is working
properly and the secondary nodes appear in the cluster:

```shell
gitlab-ctl repmgr cluster show
```

The output should be similar to the following:

```plaintext
Role      | Name    | Upstream  | Connection String
----------+---------|-----------|------------------------------------------------
* master  | MASTER  |           | host=<primary_node_name> user=gitlab_repmgr dbname=gitlab_repmgr
   standby | STANDBY | MASTER    | host=<secondary_node_name> user=gitlab_repmgr dbname=gitlab_repmgr
   standby | STANDBY | MASTER    | host=<secondary_node_name> user=gitlab_repmgr dbname=gitlab_repmgr
```

If the 'Role' column for any node says "FAILED", check the
[Troubleshooting section](troubleshooting.md) before proceeding.

Also, check that the `repmgr-check-master` command works successfully on each node:

```shell
su - gitlab-consul
gitlab-ctl repmgr-check-master || echo 'This node is a standby repmgr node'
```

This command relies on exit codes to tell Consul whether a particular node is a master
or secondary. The most important thing here is that this command does not produce errors.
If there are errors it's most likely due to incorrect `gitlab-consul` database user permissions.
Check the [Troubleshooting section](troubleshooting.md) before proceeding.

<div align="right">
  <a type="button" class="btn btn-default" href="#setup-components">
    Back to setup components <i class="fa fa-angle-double-up" aria-hidden="true"></i>
  </a>
</div>

## Configure PgBouncer

Now that the PostgreSQL servers are all set up, let's configure PgBouncer.
The following IPs will be used as an example:

- `10.6.0.31`: PgBouncer 1
- `10.6.0.32`: PgBouncer 2
- `10.6.0.33`: PgBouncer 3

1. On each PgBouncer node, edit `/etc/gitlab/gitlab.rb`, and replace
   `<consul_password_hash>` and `<pgbouncer_password_hash>` with the
   password hashes you [set up previously](#postgresql-primary-node):

   ```ruby
   # Disable all components except Pgbouncer and Consul agent
   roles ['pgbouncer_role']

   # Configure PgBouncer
   pgbouncer['admin_users'] = %w(pgbouncer gitlab-consul)

   pgbouncer['users'] = {
   'gitlab-consul': {
      password: '<consul_password_hash>'
   },
   'pgbouncer': {
      password: '<pgbouncer_password_hash>'
   }
   }

   # Configure Consul agent
   consul['watchers'] = %w(postgresql)
   consul['enable'] = true
   consul['configuration'] = {
   retry_join: %w(10.6.0.11 10.6.0.12 10.6.0.13)
   }

   # Enable service discovery for Prometheus
   consul['monitoring_service_discovery'] = true

   # Set the network addresses that the exporters will listen on
   node_exporter['listen_address'] = '0.0.0.0:9100'
   ```

1. Copy the `/etc/gitlab/gitlab-secrets.json` file from your Consul server, and replace
   the file of the same name on this server. If that file is not on this server,
   add the file from your Consul server to this server.

1. [Reconfigure Omnibus GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure) for the changes to take effect.

   If an error `execute[generate databases.ini]` occurs, this is due to an existing
   [known issue](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/4713).
   It will be resolved when you run a second `reconfigure` after the next step.

1. Create a `.pgpass` file so Consul is able to
   reload PgBouncer. Enter the PgBouncer password twice when asked:

   ```shell
   gitlab-ctl write-pgpass --host 127.0.0.1 --database pgbouncer --user pgbouncer --hostuser gitlab-consul
   ```

1. [Reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure) once again
   to resolve any potential errors from the previous steps.
1. Ensure each node is talking to the current primary:

   ```shell
   gitlab-ctl pgb-console # You will be prompted for PGBOUNCER_PASSWORD
   ```

1. Once the console prompt is available, run the following queries:

   ```shell
   show databases ; show clients ;
   ```

   The output should be similar to the following:

   ```plaintext
           name         |  host       | port |      database       | force_user | pool_size | reserve_pool | pool_mode | max_connections | current_connections
   ---------------------+-------------+------+---------------------+------------+-----------+--------------+-----------+-----------------+---------------------
    gitlabhq_production | MASTER_HOST | 5432 | gitlabhq_production |            |        20 |            0 |           |               0 |                   0
    pgbouncer           |             | 6432 | pgbouncer           | pgbouncer  |         2 |            0 | statement |               0 |                   0
   (2 rows)

    type |   user    |      database       |  state  |   addr         | port  | local_addr | local_port |    connect_time     |    request_time     |    ptr    | link | remote_pid | tls
   ------+-----------+---------------------+---------+----------------+-------+------------+------------+---------------------+---------------------+-----------+------+------------+-----
    C    | pgbouncer | pgbouncer           | active  | 127.0.0.1      | 56846 | 127.0.0.1  |       6432 | 2017-08-21 18:09:59 | 2017-08-21 18:10:48 | 0x22b3880 |      |          0 |
   (2 rows)
   ```

<div align="right">
  <a type="button" class="btn btn-default" href="#setup-components">
    Back to setup components <i class="fa fa-angle-double-up" aria-hidden="true"></i>
  </a>
</div>

### Configure the internal load balancer

If you're running more than one PgBouncer node as recommended, then at this time you'll need to set
up a TCP internal load balancer to serve each correctly.

The following IP will be used as an example:

- `10.6.0.40`: Internal Load Balancer

Here's how you could do it with [HAProxy](https://www.haproxy.org/):

```plaintext
global
    log /dev/log local0
    log localhost local1 notice
    log stdout format raw local0

defaults
    log global
    default-server inter 10s fall 3 rise 2
    balance leastconn

frontend internal-pgbouncer-tcp-in
    bind *:6432
    mode tcp
    option tcplog

    default_backend pgbouncer

backend pgbouncer
    mode tcp
    option tcp-check

    server pgbouncer1 10.6.0.21:6432 check
    server pgbouncer2 10.6.0.22:6432 check
    server pgbouncer3 10.6.0.23:6432 check
```

Refer to your preferred Load Balancer's documentation for further guidance.

<div align="right">
  <a type="button" class="btn btn-default" href="#setup-components">
    Back to setup components <i class="fa fa-angle-double-up" aria-hidden="true"></i>
  </a>
</div>

## Configure Redis

Using [Redis](https://redis.io/) in scalable environment is possible using a **Primary** x **Replica**
topology with a [Redis Sentinel](https://redis.io/topics/sentinel) service to watch and automatically
start the failover procedure.

Redis requires authentication if used with Sentinel. See
[Redis Security](https://redis.io/topics/security) documentation for more
information. We recommend using a combination of a Redis password and tight
firewall rules to secure your Redis service.
You are highly encouraged to read the [Redis Sentinel](https://redis.io/topics/sentinel) documentation
before configuring Redis with GitLab to fully understand the topology and
architecture.

The requirements for a Redis setup are the following:

1. All Redis nodes must be able to talk to each other and accept incoming
   connections over Redis (`6379`) and Sentinel (`26379`) ports (unless you
   change the default ones).
1. The server that hosts the GitLab application must be able to access the
   Redis nodes.
1. Protect the nodes from access from external networks
   ([Internet](https://gitlab.com/gitlab-org/gitlab-foss/uploads/c4cc8cd353604bd80315f9384035ff9e/The_Internet_IT_Crowd.png)),
   using a firewall.

In this section, you'll be guided through configuring two external Redis clusters
to be used with GitLab. The following IPs will be used as an example:

- `10.6.0.51`: Redis - Cache Primary
- `10.6.0.52`: Redis - Cache Replica 1
- `10.6.0.53`: Redis - Cache Replica 2
- `10.6.0.71`: Sentinel - Cache 1
- `10.6.0.72`: Sentinel - Cache 2
- `10.6.0.73`: Sentinel - Cache 3
- `10.6.0.61`: Redis - Queues Primary
- `10.6.0.62`: Redis - Queues Replica 1
- `10.6.0.63`: Redis - Queues Replica 2
- `10.6.0.81`: Sentinel - Queues 1
- `10.6.0.82`: Sentinel - Queues 2
- `10.6.0.83`: Sentinel - Queues 3

### Providing your own Redis instance

Managed Redis from cloud providers (such as AWS ElastiCache) will work. If these
services support high availability, be sure it _isn't_ of the Redis Cluster type.
Redis version 5.0 or higher is required, which is included with Omnibus GitLab
packages starting with GitLab 13.0. Older Redis versions don't support an
optional count argument to SPOP, which is required for [Merge Trains](../../ci/merge_request_pipelines/pipelines_for_merged_results/merge_trains/index.md).
Note the Redis node's IP address or hostname, port, and password (if required).
These will be necessary later when configuring the [GitLab application servers](#configure-gitlab-rails).

### Configure the Redis and Sentinel Cache cluster

This is the section where we install and set up the new Redis Cache instances.

Both the primary and replica Redis nodes need the same password defined in
`redis['password']`. At any time during a failover, the Sentinels can reconfigure
a node and change its status from primary to replica (and vice versa).

#### Configure the primary Redis Cache node

1. SSH in to the **Primary** Redis server.
1. [Download and install](https://about.gitlab.com/install/) the Omnibus GitLab
   package of your choice. Be sure to both follow _only_ installation steps 1 and 2
   on the page, and to select the correct Omnibus GitLab package, with the same version
   and type (Community or Enterprise editions) as your current install.
1. Edit `/etc/gitlab/gitlab.rb` and add the contents:

   ```ruby
   # Specify server role as 'redis_master_role'
   roles ['redis_master_role']

   # IP address pointing to a local IP that the other machines can reach to.
   # You can also set bind to '0.0.0.0' which listen in all interfaces.
   # If you really need to bind to an external accessible IP, make
   # sure you add extra firewall rules to prevent unauthorized access.
   redis['bind'] = '10.6.0.51'

   # Define a port so Redis can listen for TCP requests which will allow other
   # machines to connect to it.
   redis['port'] = 6379

   # Set up password authentication for Redis (use the same password in all nodes).
   redis['password'] = 'REDIS_PRIMARY_PASSWORD_OF_FIRST_CLUSTER'

   # Set the Redis Cache instance as an LRU
   # 90% of available RAM in MB
   redis['maxmemory'] = '13500mb'
   redis['maxmemory_policy'] = "allkeys-lru"
   redis['maxmemory_samples'] = 5

   ## Enable service discovery for Prometheus
   consul['enable'] = true
   consul['monitoring_service_discovery'] =  true

   ## The IPs of the Consul server nodes
   ## You can also use FQDNs and intermix them with IPs
   consul['configuration'] = {
      retry_join: %w(10.6.0.11 10.6.0.12 10.6.0.13),
   }

   # Set the network addresses that the exporters will listen on
   node_exporter['listen_address'] = '0.0.0.0:9100'
   redis_exporter['listen_address'] = '0.0.0.0:9121'

   # Prevent database migrations from running on upgrade
   gitlab_rails['auto_migrate'] = false
   ```

1. Copy the `/etc/gitlab/gitlab-secrets.json` file from your Consul server, and replace
   the file of the same name on this server. If that file is not on this server,
   add the file from your Consul server to this server.

1. [Reconfigure Omnibus GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure) for the changes to take effect.

You can specify multiple roles, like sentinel and Redis, as:
`roles ['redis_sentinel_role', 'redis_master_role']`. Read more about
[roles](https://docs.gitlab.com/omnibus/roles/).

#### Configure the replica Redis Cache nodes

1. SSH in to the **replica** Redis server.
1. [Download and install](https://about.gitlab.com/install/) the Omnibus GitLab
   package of your choice. Be sure to both follow _only_ installation steps 1 and 2
   on the page, and to select the correct Omnibus GitLab package, with the same version
   and type (Community or Enterprise editions) as your current install.
1. Edit `/etc/gitlab/gitlab.rb` and add the contents:

   ```ruby
   # Specify server role as 'redis_replica_role'
   roles ['redis_replica_role']

   # IP address pointing to a local IP that the other machines can reach to.
   # You can also set bind to '0.0.0.0' which listen in all interfaces.
   # If you really need to bind to an external accessible IP, make
   # sure you add extra firewall rules to prevent unauthorized access.
   redis['bind'] = '10.6.0.52'

   # Define a port so Redis can listen for TCP requests which will allow other
   # machines to connect to it.
   redis['port'] = 6379

   # The same password for Redis authentication you set up for the primary node.
   redis['password'] = 'REDIS_PRIMARY_PASSWORD_OF_FIRST_CLUSTER'

   # The IP of the primary Redis node.
   redis['master_ip'] = '10.6.0.51'

   # Port of primary Redis server, uncomment to change to non default. Defaults
   # to `6379`.
   #redis['master_port'] = 6379

   # Set the Redis Cache instance as an LRU
   # 90% of available RAM in MB
   redis['maxmemory'] = '13500mb'
   redis['maxmemory_policy'] = "allkeys-lru"
   redis['maxmemory_samples'] = 5

   ## Enable service discovery for Prometheus
   consul['enable'] = true
   consul['monitoring_service_discovery'] =  true

   ## The IPs of the Consul server nodes
   ## You can also use FQDNs and intermix them with IPs
   consul['configuration'] = {
      retry_join: %w(10.6.0.11 10.6.0.12 10.6.0.13),
   }

   # Set the network addresses that the exporters will listen on
   node_exporter['listen_address'] = '0.0.0.0:9100'
   redis_exporter['listen_address'] = '0.0.0.0:9121'

   # Prevent database migrations from running on upgrade
   gitlab_rails['auto_migrate'] = false
   ```

1. Copy the `/etc/gitlab/gitlab-secrets.json` file from your Consul server, and replace
   the file of the same name on this server. If that file is not on this server,
   add the file from your Consul server to this server.

1. [Reconfigure Omnibus GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure) for the changes to take effect.
1. Go through the steps again for all the other replica nodes, and
   make sure to set up the IPs correctly.

You can specify multiple roles, like sentinel and Redis, as:
`roles ['redis_sentinel_role', 'redis_master_role']`. Read more about
[roles](https://docs.gitlab.com/omnibus/roles/).

These values don't have to be changed again in `/etc/gitlab/gitlab.rb` after
a failover, as the nodes will be managed by the [Sentinels](#configure-the-sentinel-cache-nodes), and even after a
`gitlab-ctl reconfigure`, they will get their configuration restored by
the same Sentinels.

Advanced [configuration options](https://docs.gitlab.com/omnibus/settings/redis.html)
are supported and can be added if needed.

<div align="right">
  <a type="button" class="btn btn-default" href="#setup-components">
    Back to setup components <i class="fa fa-angle-double-up" aria-hidden="true"></i>
  </a>
</div>

#### Configure the Sentinel Cache nodes

Now that the Redis servers are all set up, let's configure the Sentinel
servers. The following IPs will be used as an example:

- `10.6.0.71`: Sentinel - Cache 1
- `10.6.0.72`: Sentinel - Cache 2
- `10.6.0.73`: Sentinel - Cache 3

NOTE: **Note:**
If you're using an external Redis Sentinel instance, be sure to exclude the
`requirepass` parameter from the Sentinel configuration. This parameter causes
clients to report `NOAUTH Authentication required.`.
[Redis Sentinel 3.2.x doesn't support password authentication](https://github.com/antirez/redis/issues/3279).

To configure the Sentinel Cache server:

1. SSH in to the server that will host Consul/Sentinel.
1. [Download and install](https://about.gitlab.com/install/) the Omnibus GitLab
   package of your choice. Be sure to both follow _only_ installation steps 1 and 2
   on the page, and to select the correct Omnibus GitLab package, with the same version
   and type (Community or Enterprise editions) as your current install.
1. Edit `/etc/gitlab/gitlab.rb` and add the contents:

   ```ruby
   roles ['redis_sentinel_role']

   ## Must be the same in every sentinel node
   redis['master_name'] = 'gitlab-redis-cache'

   ## The same password for Redis authentication you set up for the primary node.
   redis['master_password'] = 'REDIS_PRIMARY_PASSWORD_OF_FIRST_CLUSTER'

   ## The IP of the primary Redis node.
   redis['master_ip'] = '10.6.0.51'

   ## Define a port so Redis can listen for TCP requests which will allow other
   ## machines to connect to it.
   redis['port'] = 6379

   ## Port of primary Redis server, uncomment to change to non default. Defaults
   ## to `6379`.
   #redis['master_port'] = 6379

   ## Configure Sentinel's IP
   sentinel['bind'] = '10.6.0.71'

   ## Port that Sentinel listens on, uncomment to change to non default. Defaults
   ## to `26379`.
   #sentinel['port'] = 26379

   ## Quorum must reflect the amount of voting sentinels it take to start a failover.
   ## Value must NOT be greater then the amount of sentinels.
   ##
   ## The quorum can be used to tune Sentinel in two ways:
   ## 1. If a the quorum is set to a value smaller than the majority of Sentinels
   ##    we deploy, we are basically making Sentinel more sensible to primary failures,
   ##    triggering a failover as soon as even just a minority of Sentinels is no longer
   ##    able to talk with the primary.
   ## 1. If a quorum is set to a value greater than the majority of Sentinels, we are
   ##    making Sentinel able to failover only when there are a very large number (larger
   ##    than majority) of well connected Sentinels which agree about the primary being down.s
   sentinel['quorum'] = 2

   ## Consider unresponsive server down after x amount of ms.
   #sentinel['down_after_milliseconds'] = 10000

   ## Specifies the failover timeout in milliseconds. It is used in many ways:
   ##
   ## - The time needed to re-start a failover after a previous failover was
   ##   already tried against the same primary by a given Sentinel, is two
   ##   times the failover timeout.
   ##
   ## - The time needed for a replica replicating to a wrong primary according
   ##   to a Sentinel current configuration, to be forced to replicate
   ##   with the right primary, is exactly the failover timeout (counting since
   ##   the moment a Sentinel detected the misconfiguration).
   ##
   ## - The time needed to cancel a failover that is already in progress but
   ##   did not produced any configuration change (REPLICAOF NO ONE yet not
   ##   acknowledged by the promoted replica).
   ##
   ## - The maximum time a failover in progress waits for all the replica to be
   ##   reconfigured as replicas of the new primary. However even after this time
   ##   the replicas will be reconfigured by the Sentinels anyway, but not with
   ##   the exact parallel-syncs progression as specified.
   #sentinel['failover_timeout'] = 60000

   ## Enable service discovery for Prometheus
   consul['enable'] = true
   consul['monitoring_service_discovery'] =  true

   ## The IPs of the Consul server nodes
   ## You can also use FQDNs and intermix them with IPs
   consul['configuration'] = {
      retry_join: %w(10.6.0.11 10.6.0.12 10.6.0.13),
   }

   # Set the network addresses that the exporters will listen on
   node_exporter['listen_address'] = '0.0.0.0:9100'
   redis_exporter['listen_address'] = '0.0.0.0:9121'

   # Disable auto migrations
   gitlab_rails['auto_migrate'] = false
   ```

1. Copy the `/etc/gitlab/gitlab-secrets.json` file from your Consul server, and replace
   the file of the same name on this server. If that file is not on this server,
   add the file from your Consul server to this server.

1. [Reconfigure Omnibus GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure) for the changes to take effect.
1. Go through the steps again for all the other Consul/Sentinel nodes, and
   make sure you set up the correct IPs.

<div align="right">
  <a type="button" class="btn btn-default" href="#setup-components">
    Back to setup components <i class="fa fa-angle-double-up" aria-hidden="true"></i>
  </a>
</div>

### Configure the Redis and Sentinel Queues cluster

This is the section where we install and set up the new Redis Queues instances.

Both the primary and replica Redis nodes need the same password defined in
`redis['password']`. At any time during a failover, the Sentinels can reconfigure
a node and change its status from primary to replica (and vice versa).

#### Configure the primary Redis Queues node

1. SSH in to the **Primary** Redis server.
1. [Download and install](https://about.gitlab.com/install/) the Omnibus GitLab
   package of your choice. Be sure to both follow _only_ installation steps 1 and 2
   on the page, and to select the correct Omnibus GitLab package, with the same version
   and type (Community or Enterprise editions) as your current install.
1. Edit `/etc/gitlab/gitlab.rb` and add the contents:

   ```ruby
   # Specify server role as 'redis_master_role'
   roles ['redis_master_role']

   # IP address pointing to a local IP that the other machines can reach to.
   # You can also set bind to '0.0.0.0' which listen in all interfaces.
   # If you really need to bind to an external accessible IP, make
   # sure you add extra firewall rules to prevent unauthorized access.
   redis['bind'] = '10.6.0.61'

   # Define a port so Redis can listen for TCP requests which will allow other
   # machines to connect to it.
   redis['port'] = 6379

   # Set up password authentication for Redis (use the same password in all nodes).
   redis['password'] = 'REDIS_PRIMARY_PASSWORD_OF_SECOND_CLUSTER'

   ## Enable service discovery for Prometheus
   consul['enable'] = true
   consul['monitoring_service_discovery'] =  true

   ## The IPs of the Consul server nodes
   ## You can also use FQDNs and intermix them with IPs
   consul['configuration'] = {
      retry_join: %w(10.6.0.11 10.6.0.12 10.6.0.13),
   }

   # Set the network addresses that the exporters will listen on
   node_exporter['listen_address'] = '0.0.0.0:9100'
   redis_exporter['listen_address'] = '0.0.0.0:9121'
   ```

1. Only the primary GitLab application server should handle migrations. To
   prevent database migrations from running on upgrade, add the following
   configuration to your `/etc/gitlab/gitlab.rb` file:

   ```ruby
   gitlab_rails['auto_migrate'] = false
   ```

1. Copy the `/etc/gitlab/gitlab-secrets.json` file from your Consul server, and replace
   the file of the same name on this server. If that file is not on this server,
   add the file from your Consul server to this server.

1. [Reconfigure Omnibus GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure) for the changes to take effect.

You can specify multiple roles, like sentinel and Redis, as:
`roles ['redis_sentinel_role', 'redis_master_role']`. Read more about
[roles](https://docs.gitlab.com/omnibus/roles/).

#### Configure the replica Redis Queues nodes

1. SSH in to the **replica** Redis Queue server.
1. [Download and install](https://about.gitlab.com/install/) the Omnibus GitLab
   package of your choice. Be sure to both follow _only_ installation steps 1 and 2
   on the page, and to select the correct Omnibus GitLab package, with the same version
   and type (Community or Enterprise editions) as your current install.
1. Edit `/etc/gitlab/gitlab.rb` and add the contents:

   ```ruby
   # Specify server role as 'redis_replica_role'
   roles ['redis_replica_role']

   # IP address pointing to a local IP that the other machines can reach to.
   # You can also set bind to '0.0.0.0' which listen in all interfaces.
   # If you really need to bind to an external accessible IP, make
   # sure you add extra firewall rules to prevent unauthorized access.
   redis['bind'] = '10.6.0.62'

   # Define a port so Redis can listen for TCP requests which will allow other
   # machines to connect to it.
   redis['port'] = 6379

   # The same password for Redis authentication you set up for the primary node.
   redis['password'] = 'REDIS_PRIMARY_PASSWORD_OF_SECOND_CLUSTER'

   # The IP of the primary Redis node.
   redis['master_ip'] = '10.6.0.61'

   # Port of primary Redis server, uncomment to change to non default. Defaults
   # to `6379`.
   #redis['master_port'] = 6379

   ## Enable service discovery for Prometheus
   consul['enable'] = true
   consul['monitoring_service_discovery'] =  true

   ## The IPs of the Consul server nodes
   ## You can also use FQDNs and intermix them with IPs
   consul['configuration'] = {
      retry_join: %w(10.6.0.11 10.6.0.12 10.6.0.13),
   }

   # Set the network addresses that the exporters will listen on
   node_exporter['listen_address'] = '0.0.0.0:9100'
   redis_exporter['listen_address'] = '0.0.0.0:9121'

   # Disable auto migrations
   gitlab_rails['auto_migrate'] = false
   ```

1. Copy the `/etc/gitlab/gitlab-secrets.json` file from your Consul server, and replace
   the file of the same name on this server. If that file is not on this server,
   add the file from your Consul server to this server.

1. [Reconfigure Omnibus GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure) for the changes to take effect.
1. Go through the steps again for all the other replica nodes, and
   make sure to set up the IPs correctly.

You can specify multiple roles, like sentinel and Redis, as:
`roles ['redis_sentinel_role', 'redis_master_role']`. Read more about
[roles](https://docs.gitlab.com/omnibus/roles/).

These values don't have to be changed again in `/etc/gitlab/gitlab.rb` after
a failover, as the nodes will be managed by the [Sentinels](#configure-the-sentinel-queues-nodes), and even after a
`gitlab-ctl reconfigure`, they will get their configuration restored by
the same Sentinels.

Advanced [configuration options](https://docs.gitlab.com/omnibus/settings/redis.html)
are supported and can be added if needed.

<div align="right">
  <a type="button" class="btn btn-default" href="#setup-components">
    Back to setup components <i class="fa fa-angle-double-up" aria-hidden="true"></i>
  </a>
</div>

#### Configure the Sentinel Queues nodes

Now that the Redis servers are all set up, let's configure the Sentinel
servers. The following IPs will be used as an example:

- `10.6.0.81`: Sentinel - Queues 1
- `10.6.0.82`: Sentinel - Queues 2
- `10.6.0.83`: Sentinel - Queues 3

NOTE: **Note:**
If you're using an external Redis Sentinel instance, be sure to exclude the
`requirepass` parameter from the Sentinel configuration. This parameter causes
clients to report `NOAUTH Authentication required.`.
[Redis Sentinel 3.2.x doesn't support password authentication](https://github.com/antirez/redis/issues/3279).

To configure the Sentinel Queues server:

1. SSH in to the server that will host Sentinel.
1. [Download and install](https://about.gitlab.com/install/) the Omnibus GitLab
   package of your choice. Be sure to both follow _only_ installation steps 1 and 2
   on the page, and to select the correct Omnibus GitLab package, with the same version
   and type (Community or Enterprise editions) as your current install.
1. Edit `/etc/gitlab/gitlab.rb` and add the contents:

   ```ruby
   roles ['redis_sentinel_role']

   ## Must be the same in every sentinel node
   redis['master_name'] = 'gitlab-redis-persistent'

   ## The same password for Redis authentication you set up for the primary node.
   redis['master_password'] = 'REDIS_PRIMARY_PASSWORD_OF_SECOND_CLUSTER'

   ## The IP of the primary Redis node.
   redis['master_ip'] = '10.6.0.61'

   ## Define a port so Redis can listen for TCP requests which will allow other
   ## machines to connect to it.
   redis['port'] = 6379

   ## Port of primary Redis server, uncomment to change to non default. Defaults
   ## to `6379`.
   #redis['master_port'] = 6379

   ## Configure Sentinel's IP
   sentinel['bind'] = '10.6.0.81'

   ## Port that Sentinel listens on, uncomment to change to non default. Defaults
   ## to `26379`.
   #sentinel['port'] = 26379

   ## Quorum must reflect the amount of voting sentinels it take to start a failover.
   ## Value must NOT be greater then the amount of sentinels.
   ##
   ## The quorum can be used to tune Sentinel in two ways:
   ## 1. If a the quorum is set to a value smaller than the majority of Sentinels
   ##    we deploy, we are basically making Sentinel more sensible to primary failures,
   ##    triggering a failover as soon as even just a minority of Sentinels is no longer
   ##    able to talk with the primary.
   ## 1. If a quorum is set to a value greater than the majority of Sentinels, we are
   ##    making Sentinel able to failover only when there are a very large number (larger
   ##    than majority) of well connected Sentinels which agree about the primary being down.s
   sentinel['quorum'] = 2

   ## Consider unresponsive server down after x amount of ms.
   #sentinel['down_after_milliseconds'] = 10000

   ## Specifies the failover timeout in milliseconds. It is used in many ways:
   ##
   ## - The time needed to re-start a failover after a previous failover was
   ##   already tried against the same primary by a given Sentinel, is two
   ##   times the failover timeout.
   ##
   ## - The time needed for a replica replicating to a wrong primary according
   ##   to a Sentinel current configuration, to be forced to replicate
   ##   with the right primary, is exactly the failover timeout (counting since
   ##   the moment a Sentinel detected the misconfiguration).
   ##
   ## - The time needed to cancel a failover that is already in progress but
   ##   did not produced any configuration change (REPLICAOF NO ONE yet not
   ##   acknowledged by the promoted replica).
   ##
   ## - The maximum time a failover in progress waits for all the replica to be
   ##   reconfigured as replicas of the new primary. However even after this time
   ##   the replicas will be reconfigured by the Sentinels anyway, but not with
   ##   the exact parallel-syncs progression as specified.
   #sentinel['failover_timeout'] = 60000

   ## Enable service discovery for Prometheus
   consul['enable'] = true
   consul['monitoring_service_discovery'] =  true

   ## The IPs of the Consul server nodes
   ## You can also use FQDNs and intermix them with IPs
   consul['configuration'] = {
      retry_join: %w(10.6.0.11 10.6.0.12 10.6.0.13),
   }

   # Set the network addresses that the exporters will listen on
   node_exporter['listen_address'] = '0.0.0.0:9100'
   redis_exporter['listen_address'] = '0.0.0.0:9121'

   # Disable auto migrations
   gitlab_rails['auto_migrate'] = false
   ```

1. To prevent database migrations from running on upgrade, run:

   ```shell
   sudo touch /etc/gitlab/skip-auto-reconfigure
   ```

   Only the primary GitLab application server should handle migrations.

1. Copy the `/etc/gitlab/gitlab-secrets.json` file from your Consul server, and replace
   the file of the same name on this server. If that file is not on this server,
   add the file from your Consul server to this server.

1. [Reconfigure Omnibus GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure) for the changes to take effect.
1. Go through the steps again for all the other Sentinel nodes, and
   make sure you set up the correct IPs.

<div align="right">
  <a type="button" class="btn btn-default" href="#setup-components">
    Back to setup components <i class="fa fa-angle-double-up" aria-hidden="true"></i>
  </a>
</div>

## Configure Gitaly

NOTE: **Note:**
[Gitaly Cluster](../gitaly/praefect.md) support
for the Reference Architectures is being
worked on as a [collaborative effort](https://gitlab.com/gitlab-org/quality/reference-architectures/-/issues/1) between the Quality Engineering and Gitaly teams. When this component has been verified
some Architecture specs will likely change as a result to support the new
and improved designed.

[Gitaly](../gitaly/index.md) server node requirements are dependent on data,
specifically the number of projects and those projects' sizes. It's recommended
that a Gitaly server node stores no more than 5 TB of data. Depending on your
repository storage requirements, you may require additional Gitaly server nodes.

Due to Gitaly having notable input and output requirements, we strongly
recommend that all Gitaly nodes use solid-state drives (SSDs). These SSDs
should have a throughput of at least 8,000
input/output operations per second (IOPS) for read operations and 2,000 IOPS for
write operations. These IOPS values are initial recommendations, and may be
adjusted to greater or lesser values depending on the scale of your
environment's workload. If you're running the environment on a Cloud provider,
refer to their documentation about how to configure IOPS correctly.

Be sure to note the following items:

- The GitLab Rails application shards repositories into
  [repository storage paths](../repository_storage_paths.md).
- A Gitaly server can host one or more storage paths.
- A GitLab server can use one or more Gitaly server nodes.
- Gitaly addresses must be specified to be correctly resolvable for all Gitaly
  clients.
- Gitaly servers must not be exposed to the public internet, as Gitaly's network
  traffic is unencrypted by default. The use of a firewall is highly recommended
  to restrict access to the Gitaly server. Another option is to
  [use TLS](#gitaly-tls-support).

NOTE: **Note:**
The token referred to throughout the Gitaly documentation is an arbitrary
password selected by the administrator. This token is unrelated to tokens
created for the GitLab API or other similar web API tokens.

This section describes how to configure two Gitaly servers, with the following
IPs and domain names:

- `10.6.0.91`: Gitaly 1 (`gitaly1.internal`)
- `10.6.0.92`: Gitaly 2 (`gitaly2.internal`)

Assumptions about your servers include having the secret token be `gitalysecret`,
and that your GitLab installation has three repository storages:

- `default` on Gitaly 1
- `storage1` on Gitaly 1
- `storage2` on Gitaly 2

On each node:

1. [Download and install](https://about.gitlab.com/install/) the Omnibus GitLab
   package of your choice. Be sure to follow _only_ installation steps 1 and 2
   on the page, and _do not_ provide the `EXTERNAL_URL` value.
1. Edit the Gitaly server node's `/etc/gitlab/gitlab.rb` file to configure
   storage paths, enable the network listener, and to configure the token:

   <!--
   updates to following example must also be made at
   https://gitlab.com/gitlab-org/charts/gitlab/blob/master/doc/advanced/external-gitaly/external-omnibus-gitaly.md#configure-omnibus-gitlab
   -->

   ```ruby
   # /etc/gitlab/gitlab.rb

   # Gitaly and GitLab use two shared secrets for authentication, one to authenticate gRPC requests
   # to Gitaly, and a second for authentication callbacks from GitLab-Shell to the GitLab internal API.
   # The following two values must be the same as their respective values
   # of the GitLab Rails application setup
   gitaly['auth_token'] = 'gitalysecret'
   gitlab_shell['secret_token'] = 'shellsecret'

   # Avoid running unnecessary services on the Gitaly server
   postgresql['enable'] = false
   redis['enable'] = false
   nginx['enable'] = false
   puma['enable'] = false
   unicorn['enable'] = false
   sidekiq['enable'] = false
   gitlab_workhorse['enable'] = false
   grafana['enable'] = false

   # If you run a separate monitoring node you can disable these services
   alertmanager['enable'] = false
   prometheus['enable'] = false

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
   # Comment out following line if you only want to support TLS connections
   gitaly['listen_addr'] = "0.0.0.0:8075"
   ```

1. Append the following to `/etc/gitlab/gitlab.rb` for each respective server:
   - On `gitaly1.internal`:

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

   - On `gitaly2.internal`:

     ```ruby
     git_data_dirs({
       'storage2' => {
         'path' => '/mnt/gitlab/git-data'
       },
     })
     ```

   <!--
   updates to following example must also be made at
   https://gitlab.com/gitlab-org/charts/gitlab/blob/master/doc/advanced/external-gitaly/external-omnibus-gitaly.md#configure-omnibus-gitlab
   -->

1. Copy the `/etc/gitlab/gitlab-secrets.json` file from your Consul server, and
   then replace the file of the same name on this server. If that file isn't on
   this server, add the file from your Consul server to this server.

1. Save the file, and then [reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure).

### Gitaly TLS support

Gitaly supports TLS encryption. To be able to communicate
with a Gitaly instance that listens for secure connections you will need to use `tls://` URL
scheme in the `gitaly_address` of the corresponding storage entry in the GitLab configuration.

You will need to bring your own certificates as this isn't provided automatically.
The certificate, or its certificate authority, must be installed on all Gitaly
nodes (including the Gitaly node using the certificate) and on all client nodes
that communicate with it following the procedure described in
[GitLab custom certificate configuration](https://docs.gitlab.com/omnibus/settings/ssl.html#install-custom-public-certificates).

NOTE: **Note:**
The self-signed certificate must specify the address you use to access the
Gitaly server. If you are addressing the Gitaly server by a hostname, you can
either use the Common Name field for this, or add it as a Subject Alternative
Name. If you are addressing the Gitaly server by its IP address, you must add it
as a Subject Alternative Name to the certificate.
[gRPC does not support using an IP address as Common Name in a certificate](https://github.com/grpc/grpc/issues/2691).

It's possible to configure Gitaly servers with both an unencrypted listening
address (`listen_addr`) and an encrypted listening address (`tls_listen_addr`)
at the same time. This allows you to do a gradual transition from unencrypted to
encrypted traffic, if necessary.

To configure Gitaly with TLS:

1. Create the `/etc/gitlab/ssl` directory and copy your key and certificate there:

   ```shell
   sudo mkdir -p /etc/gitlab/ssl
   sudo chmod 755 /etc/gitlab/ssl
   sudo cp key.pem cert.pem /etc/gitlab/ssl/
   sudo chmod 644 key.pem cert.pem
   ```

1. Copy the cert to `/etc/gitlab/trusted-certs` so Gitaly will trust the cert when
   calling into itself:

   ```shell
   sudo cp /etc/gitlab/ssl/cert.pem /etc/gitlab/trusted-certs/
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

1. Delete `gitaly['listen_addr']` to allow only encrypted connections.

1. Save the file and [reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure).

<div align="right">
  <a type="button" class="btn btn-default" href="#setup-components">
    Back to setup components <i class="fa fa-angle-double-up" aria-hidden="true"></i>
  </a>
</div>

## Configure Sidekiq

Sidekiq requires connections to the Redis, PostgreSQL and Gitaly instances.
The following IPs will be used as an example:

- `10.6.0.101`: Sidekiq 1
- `10.6.0.102`: Sidekiq 2
- `10.6.0.103`: Sidekiq 3
- `10.6.0.104`: Sidekiq 4

To configure the Sidekiq nodes, on each one:

1. SSH in to the Sidekiq server.
1. [Download and install](https://about.gitlab.com/install/) the Omnibus GitLab
   package of your choice. Be sure to follow _only_ installation steps 1 and 2
   on the page.
1. Open `/etc/gitlab/gitlab.rb` with your editor:

   ```ruby
   ########################################
   #####        Services Disabled       ###
   ########################################

   nginx['enable'] = false
   grafana['enable'] = false
   prometheus['enable'] = false
   alertmanager['enable'] = false
   gitaly['enable'] = false
   gitlab_workhorse['enable'] = false
   nginx['enable'] = false
   puma['enable'] = false
   postgres_exporter['enable'] = false
   postgresql['enable'] = false
   redis['enable'] = false
   redis_exporter['enable'] = false
   gitlab_exporter['enable'] = false

   ########################################
   ####              Redis              ###
   ########################################

   ## Redis connection details
   ## First cluster that will host the cache
   gitlab_rails['redis_cache_instance'] = 'redis://:<REDIS_PRIMARY_PASSWORD_OF_FIRST_CLUSTER>@gitlab-redis-cache'

   gitlab_rails['redis_cache_sentinels'] = [
     {host: '10.6.0.71', port: 26379},
     {host: '10.6.0.72', port: 26379},
     {host: '10.6.0.73', port: 26379},
   ]

   ## Second cluster that will host the queues, shared state, and actioncable
   gitlab_rails['redis_queues_instance'] = 'redis://:<REDIS_PRIMARY_PASSWORD_OF_SECOND_CLUSTER>@gitlab-redis-persistent'
   gitlab_rails['redis_shared_state_instance'] = 'redis://:<REDIS_PRIMARY_PASSWORD_OF_SECOND_CLUSTER>@gitlab-redis-persistent'
   gitlab_rails['redis_actioncable_instance'] = 'redis://:<REDIS_PRIMARY_PASSWORD_OF_SECOND_CLUSTER>@gitlab-redis-persistent'

   gitlab_rails['redis_queues_sentinels'] = [
     {host: '10.6.0.81', port: 26379},
     {host: '10.6.0.82', port: 26379},
     {host: '10.6.0.83', port: 26379},
   ]
   gitlab_rails['redis_shared_state_sentinels'] = [
     {host: '10.6.0.81', port: 26379},
     {host: '10.6.0.82', port: 26379},
     {host: '10.6.0.83', port: 26379},
   ]
   gitlab_rails['redis_actioncable_sentinels'] = [
     {host: '10.6.0.81', port: 26379},
     {host: '10.6.0.82', port: 26379},
     {host: '10.6.0.83', port: 26379},
   ]

   #######################################
   ###              Gitaly             ###
   #######################################

   git_data_dirs({
     'default' => { 'gitaly_address' => 'tcp://gitaly1.internal:8075' },
     'storage1' => { 'gitaly_address' => 'tcp://gitaly1.internal:8075' },
     'storage2' => { 'gitaly_address' => 'tcp://gitaly2.internal:8075' },
   })
   gitlab_rails['gitaly_token'] = 'YOUR_TOKEN'

   #######################################
   ###            Postgres             ###
   #######################################
   gitlab_rails['db_host'] = '10.6.0.20' # internal load balancer IP
   gitlab_rails['db_port'] = 6432
   gitlab_rails['db_password'] = '<postgresql_user_password>'
   gitlab_rails['db_adapter'] = 'postgresql'
   gitlab_rails['db_encoding'] = 'unicode'
   gitlab_rails['auto_migrate'] = false

   #######################################
   ###      Sidekiq configuration      ###
   #######################################
   sidekiq['listen_address'] = "0.0.0.0"
   sidekiq['cluster'] = true # no need to set this after GitLab 13.0

   #######################################
   ###     Monitoring configuration    ###
   #######################################
   consul['enable'] = true
   consul['monitoring_service_discovery'] =  true

   consul['configuration'] = {
      retry_join: %w(10.6.0.11 10.6.0.12 10.6.0.13)
   }

   # Set the network addresses that the exporters will listen on
   node_exporter['listen_address'] = '0.0.0.0:9100'

   # Rails Status for prometheus
   gitlab_rails['monitoring_whitelist'] = ['10.6.0.121/32', '127.0.0.0/8']
   ```

1. Copy the `/etc/gitlab/gitlab-secrets.json` file from your Consul server, and replace
   the file of the same name on this server. If that file is not on this server,
   add the file from your Consul server to this server.

1. [Reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure) for the changes to take effect.

TIP: **Tip:**
You can also run [multiple Sidekiq processes](../operations/extra_sidekiq_processes.md).

<div align="right">
  <a type="button" class="btn btn-default" href="#setup-components">
    Back to setup components <i class="fa fa-angle-double-up" aria-hidden="true"></i>
  </a>
</div>

## Configure GitLab Rails

This section describes how to configure the GitLab application (Rails) component.

In our architecture, we run each GitLab Rails node using the Puma webserver, and
have its number of workers set to 90% of available CPUs, with four threads. For
nodes running Rails with other components, the worker value should be reduced
accordingly. We've determined that a worker value of 50% achieves a good balance,
but this is dependent on workload.

The following IPs will be used as an example:

- `10.6.0.111`: GitLab application 1
- `10.6.0.112`: GitLab application 2
- `10.6.0.113`: GitLab application 3

On each node perform the following:

1. [Download and install](https://about.gitlab.com/install/) the Omnibus GitLab
   package of your choice. Be sure to follow _only_ installation steps 1 and 2
   on the page.
1. Copy the `/etc/gitlab/gitlab-secrets.json` file from your Consul server, and replace
   the file of the same name on this server. If that file is not on this server,
   add the file from your Consul server to this server.

1. Edit `/etc/gitlab/gitlab.rb` and use the following configuration.
   To maintain uniformity of links across nodes, the `external_url`
   on the application server should point to the external URL that users will use
   to access GitLab. This would be the URL of the [external load balancer](#configure-the-external-load-balancer)
   which will route traffic to the GitLab application server:

   ```ruby
   external_url 'https://gitlab.example.com'

   # Gitaly and GitLab use two shared secrets for authentication, one to authenticate gRPC requests
   # to Gitaly, and a second for authentication callbacks from GitLab-Shell to the GitLab internal API.
   # The following two values must be the same as their respective values
   # of the Gitaly setup
   gitlab_rails['gitaly_token'] = 'gitalysecret'
   gitlab_shell['secret_token'] = 'shellsecret'

   git_data_dirs({
     'default' => { 'gitaly_address' => 'tcp://gitaly1.internal:8075' },
     'storage1' => { 'gitaly_address' => 'tcp://gitaly1.internal:8075' },
     'storage2' => { 'gitaly_address' => 'tcp://gitaly2.internal:8075' },
   })

   ## Disable components that will not be on the GitLab application server
   roles ['application_role']
   gitaly['enable'] = false
   nginx['enable'] = true
   sidekiq['enable'] = false

   ## PostgreSQL connection details
   # Disable PostgreSQL on the application node
   postgresql['enable'] = false
   gitlab_rails['db_host'] = '10.6.0.20' # internal load balancer IP
   gitlab_rails['db_port'] = 6432
   gitlab_rails['db_password'] = '<postgresql_user_password>'
   gitlab_rails['auto_migrate'] = false

   ## Redis connection details
   ## First cluster that will host the cache
   gitlab_rails['redis_cache_instance'] = 'redis://:<REDIS_PRIMARY_PASSWORD_OF_FIRST_CLUSTER>@gitlab-redis-cache'

   gitlab_rails['redis_cache_sentinels'] = [
     {host: '10.6.0.71', port: 26379},
     {host: '10.6.0.72', port: 26379},
     {host: '10.6.0.73', port: 26379},
   ]

   ## Second cluster that will host the queues, shared state, and actionable
   gitlab_rails['redis_queues_instance'] = 'redis://:<REDIS_PRIMARY_PASSWORD_OF_SECOND_CLUSTER>@gitlab-redis-persistent'
   gitlab_rails['redis_shared_state_instance'] = 'redis://:<REDIS_PRIMARY_PASSWORD_OF_SECOND_CLUSTER>@gitlab-redis-persistent'
   gitlab_rails['redis_actioncable_instance'] = 'redis://:<REDIS_PRIMARY_PASSWORD_OF_SECOND_CLUSTER>@gitlab-redis-persistent'

   gitlab_rails['redis_queues_sentinels'] = [
     {host: '10.6.0.81', port: 26379},
     {host: '10.6.0.82', port: 26379},
     {host: '10.6.0.83', port: 26379},
   ]
   gitlab_rails['redis_shared_state_sentinels'] = [
     {host: '10.6.0.81', port: 26379},
     {host: '10.6.0.82', port: 26379},
     {host: '10.6.0.83', port: 26379},
   ]
   gitlab_rails['redis_actioncable_sentinels'] = [
     {host: '10.6.0.81', port: 26379},
     {host: '10.6.0.82', port: 26379},
     {host: '10.6.0.83', port: 26379},
   ]

   # Set the network addresses that the exporters used for monitoring will listen on
   node_exporter['listen_address'] = '0.0.0.0:9100'
   gitlab_workhorse['prometheus_listen_addr'] = '0.0.0.0:9229'
   puma['listen'] = '0.0.0.0'

   # Add the monitoring node's IP address to the monitoring whitelist and allow it to
   # scrape the NGINX metrics
   gitlab_rails['monitoring_whitelist'] = ['10.6.0.121/32', '127.0.0.0/8']
   nginx['status']['options']['allow'] = ['10.6.0.121/32', '127.0.0.0/8']
   ```

1. Save the file and [reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure).
1. If you're using [Gitaly with TLS support](#gitaly-tls-support), make sure the
   `git_data_dirs` entry is configured with `tls` instead of `tcp`:

   ```ruby
   git_data_dirs({
     'default' => { 'gitaly_address' => 'tls://gitaly1.internal:9999' },
     'storage1' => { 'gitaly_address' => 'tls://gitaly1.internal:9999' },
     'storage2' => { 'gitaly_address' => 'tls://gitaly2.internal:9999' },
   })
   ```

   1. Copy the cert into `/etc/gitlab/trusted-certs`:

      ```shell
      sudo cp cert.pem /etc/gitlab/trusted-certs/
      ```

1. If you're [using NFS](#configure-nfs-optional):
   1. If necessary, install the NFS client utility packages using the following
      commands:

      ```shell
      # Ubuntu/Debian
      apt-get install nfs-common

      # CentOS/Red Hat
      yum install nfs-utils nfs-utils-lib
      ```

   1. Specify the necessary NFS mounts in `/etc/fstab`.
      The exact contents of `/etc/fstab` will depend on how you chose
      to configure your NFS server. See the [NFS documentation](../nfs.md)
      for examples and the various options.

   1. Create the shared directories. These may be different depending on your NFS
      mount locations.

      ```shell
      mkdir -p /var/opt/gitlab/.ssh /var/opt/gitlab/gitlab-rails/uploads /var/opt/gitlab/gitlab-rails/shared /var/opt/gitlab/gitlab-ci/builds /var/opt/gitlab/git-data
      ```

   1. Edit `/etc/gitlab/gitlab.rb` and use the following configuration:

      ```ruby
      ## Prevent GitLab from starting if NFS data mounts are not available
      high_availability['mountpoint'] = '/var/opt/gitlab/git-data'

      ## Ensure UIDs and GIDs match between servers for permissions via NFS
      user['uid'] = 9000
      user['gid'] = 9000
      web_server['uid'] = 9001
      web_server['gid'] = 9001
      registry['uid'] = 9002
      registry['gid'] = 9002
      ```

1. Save the file and [reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure).
1. Confirm the node can connect to Gitaly:

   ```shell
   sudo gitlab-rake gitlab:gitaly:check
   ```

   Then, tail the logs to see the requests:

   ```shell
   sudo gitlab-ctl tail gitaly
   ```

1. Optionally, from the Gitaly servers, confirm that Gitaly can perform callbacks to the internal API:

   ```shell
   sudo /opt/gitlab/embedded/bin/gitaly-hooks check /var/opt/gitlab/gitaly/config.toml
   ```

When you specify `https` in the `external_url`, as in the previous example,
GitLab expects that the SSL certificates are in `/etc/gitlab/ssl/`. If the
certificates aren't present, NGINX will fail to start. For more information, see
the [NGINX documentation](https://docs.gitlab.com/omnibus/settings/nginx.html#enable-https).

### GitLab Rails post-configuration

1. Designate one application node for running database migrations during
   installation and updates. Initialize the GitLab database and ensure all
   migrations ran:

   ```shell
   sudo gitlab-rake gitlab:db:configure
   ```

   If you encounter a `rake aborted!` error message stating that PgBouncer is
   failing to connect to PostgreSQL, it may be that your PgBouncer node's IP
   address is missing from PostgreSQL's `trust_auth_cidr_addresses` in `gitlab.rb`
   on your database nodes. Before proceeding, see
   [PgBouncer error `ERROR:  pgbouncer cannot connect to server`](troubleshooting.md#pgbouncer-error-error-pgbouncer-cannot-connect-to-server).

1. [Configure fast lookup of authorized SSH keys in the database](../operations/fast_ssh_key_lookup.md).

<div align="right">
  <a type="button" class="btn btn-default" href="#setup-components">
    Back to setup components <i class="fa fa-angle-double-up" aria-hidden="true"></i>
  </a>
</div>

## Configure Prometheus

The Omnibus GitLab package can be used to configure a standalone Monitoring node
running [Prometheus](../monitoring/prometheus/index.md) and
[Grafana](../monitoring/performance/grafana_configuration.md).

The following IP will be used as an example:

- `10.6.0.121`: Prometheus

To configure the Monitoring node:

1. SSH in to the Monitoring node.
1. [Download and install](https://about.gitlab.com/install/) the Omnibus GitLab
   package of your choice. Be sure to follow _only_ installation steps 1 and 2
   on the page.
1. Copy the `/etc/gitlab/gitlab-secrets.json` file from your Consul server, and replace
   the file of the same name on this server. If that file is not on this server,
   add the file from your Consul server to this server.

1. Edit `/etc/gitlab/gitlab.rb` and add the contents:

   ```ruby
   external_url 'http://gitlab.example.com'

   # Disable all other services
   gitlab_rails['auto_migrate'] = false
   alertmanager['enable'] = false
   gitaly['enable'] = false
   gitlab_exporter['enable'] = false
   gitlab_workhorse['enable'] = false
   nginx['enable'] = true
   postgres_exporter['enable'] = false
   postgresql['enable'] = false
   redis['enable'] = false
   redis_exporter['enable'] = false
   sidekiq['enable'] = false
   puma['enable'] = false
   unicorn['enable'] = false
   node_exporter['enable'] = false
   gitlab_exporter['enable'] = false

   # Enable Prometheus
   prometheus['enable'] = true
   prometheus['listen_address'] = '0.0.0.0:9090'
   prometheus['monitor_kubernetes'] = false

   # Enable Login form
   grafana['disable_login_form'] = false

   # Enable Grafana
   grafana['enable'] = true
   grafana['admin_password'] = '<grafana_password>'

   # Enable service discovery for Prometheus
   consul['enable'] = true
   consul['monitoring_service_discovery'] =  true
   consul['configuration'] = {
      retry_join: %w(10.6.0.11 10.6.0.12 10.6.0.13)
   }
   ```

1. Save the file and [reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure).
1. In the GitLab UI, set `admin/application_settings/metrics_and_profiling` > Metrics - Grafana to `/-/grafana` to
`http[s]://<MONITOR NODE>/-/grafana`

<div align="right">
  <a type="button" class="btn btn-default" href="#setup-components">
    Back to setup components <i class="fa fa-angle-double-up" aria-hidden="true"></i>
  </a>
</div>

## Configure the object storage

GitLab supports using an object storage service for holding numerous types of data.
It's recommended over [NFS](#configure-nfs-optional) and in general it's better
in larger setups as object storage is typically much more performant, reliable,
and scalable.

GitLab has been tested on a number of object storage providers:

- [Amazon S3](https://aws.amazon.com/s3/)
- [Google Cloud Storage](https://cloud.google.com/storage)
- [Digital Ocean Spaces](https://www.digitalocean.com/products/spaces/)
- [Oracle Cloud Infrastructure](https://docs.cloud.oracle.com/en-us/iaas/Content/Object/Tasks/s3compatibleapi.htm)
- [Openstack Swift](https://docs.openstack.org/swift/latest/s3_compat.html)
- [Azure Blob storage](https://docs.microsoft.com/en-us/azure/storage/blobs/storage-blobs-introduction)
- On-premises hardware and appliances from various storage vendors.
- MinIO. We have [a guide to deploying this](https://docs.gitlab.com/charts/advanced/external-object-storage/minio.html) within our Helm Chart documentation.

There are two ways of specifying object storage configuration in GitLab:

- [Consolidated form](../object_storage.md#consolidated-object-storage-configuration): A single credential is
  shared by all supported object types.
- [Storage-specific form](../object_storage.md#storage-specific-configuration): Every object defines its
  own object storage [connection and configuration](../object_storage.md#connection-settings).

Starting with GitLab 13.2, consolidated object storage configuration is available. It simplifies your GitLab configuration since the connection details are shared across object types. Refer to [Consolidated object storage configuration](../object_storage.md#consolidated-object-storage-configuration) guide for instructions on how to set it up.

For configuring object storage in GitLab 13.1 and earlier, or for storage types not
supported by consolidated configuration form, refer to the following guides based
on what features you intend to use:

|Object storage type|Supported by consolidated configuration?|
|-------------------|----------------------------------------|
| [Backups](../../raketasks/backup_restore.md#uploading-backups-to-a-remote-cloud-storage)|No|
| [Job artifacts](../job_artifacts.md#using-object-storage) including archived job logs | Yes |
| [LFS objects](../lfs/index.md#storing-lfs-objects-in-remote-object-storage) | Yes |
| [Uploads](../uploads.md#using-object-storage) | Yes |
| [Container Registry](../packages/container_registry.md#use-object-storage) (optional feature) | No |
| [Merge request diffs](../merge_request_diffs.md#using-object-storage) | Yes |
| [Mattermost](https://docs.mattermost.com/administration/config-settings.html#file-storage)| No |
| [Packages](../packages/index.md#using-object-storage) (optional feature) | Yes |
| [Dependency Proxy](../packages/dependency_proxy.md#using-object-storage) (optional feature) | Yes |
| [Pseudonymizer](../pseudonymizer.md#configuration) (optional feature) **(ULTIMATE ONLY)** | No |
| [Autoscale runner caching](https://docs.gitlab.com/runner/configuration/autoscale.html#distributed-runners-caching) (optional for improved performance) | No |
| [Terraform state files](../terraform_state.md#using-object-storage) | Yes |

Using separate buckets for each data type is the recommended approach for GitLab.

A limitation of our configuration is that each use of object storage is separately configured.
[We have an issue for improving this](https://gitlab.com/gitlab-org/gitlab/-/issues/23345)
and easily using one bucket with separate folders is one improvement that this might bring.

There is at least one specific issue with using the same bucket:
when GitLab is deployed with the Helm chart restore from backup
[will not properly function](https://docs.gitlab.com/charts/advanced/external-object-storage/#lfs-artifacts-uploads-packages-external-diffs-pseudonymizer)
unless separate buckets are used.

One risk of using a single bucket would be if your organization decided to
migrate GitLab to the Helm deployment in the future. GitLab would run, but the situation with
backups might not be realized until the organization had a critical requirement for the backups to
work.

<div align="right">
  <a type="button" class="btn btn-default" href="#setup-components">
    Back to setup components <i class="fa fa-angle-double-up" aria-hidden="true"></i>
  </a>
</div>

## Configure Advanced Search **(STARTER ONLY)**

You can leverage Elasticsearch and [enable Advanced Search](../../integration/elasticsearch.md)
for faster, more advanced code search across your entire GitLab instance.

Elasticsearch cluster design and requirements are dependent on your specific
data. For recommended best practices about how to set up your Elasticsearch
cluster alongside your instance, read how to
[choose the optimal cluster configuration](../../integration/elasticsearch.md#guidance-on-choosing-optimal-cluster-configuration).

<div align="right">
  <a type="button" class="btn btn-default" href="#setup-components">
    Back to setup components <i class="fa fa-angle-double-up" aria-hidden="true"></i>
  </a>
</div>

## Configure NFS (optional)

[Object storage](#configure-the-object-storage), along with [Gitaly](#configure-gitaly)
are recommended over NFS wherever possible for improved performance. If you intend
to use GitLab Pages, this currently [requires NFS](troubleshooting.md#gitlab-pages-requires-nfs).

See how to [configure NFS](../nfs.md).

<div align="right">
  <a type="button" class="btn btn-default" href="#setup-components">
    Back to setup components <i class="fa fa-angle-double-up" aria-hidden="true"></i>
  </a>
</div>

## Troubleshooting

See the [troubleshooting documentation](troubleshooting.md).

<div align="right">
  <a type="button" class="btn btn-default" href="#setup-components">
    Back to setup components <i class="fa fa-angle-double-up" aria-hidden="true"></i>
  </a>
</div>
