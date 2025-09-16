---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 'Reference architecture: Up to 1000 RPS or 50,000 users'
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

This page describes the GitLab reference architecture designed to target a peak load of 1000 requests per second (RPS), the typical peak load of up to 50,000 users, both manual and automated, based on real data.

For a full list of reference architectures, see
[Available reference architectures](_index.md#available-reference-architectures).

{{< alert type="note" >}}

Before deploying this architecture it's recommended to read through the [main documentation](_index.md) first,
specifically the [Before you start](_index.md#before-you-start) and [Deciding which architecture to use](_index.md#deciding-which-architecture-to-start-with) sections.

{{< /alert >}}

- **Target load**: API: 1000 RPS, Web: 100 RPS, Git (Pull): 100 RPS, Git (Push): 20 RPS
- **High Availability**: Yes ([Praefect](#configure-praefect-postgresql) needs a third-party PostgreSQL solution for HA)
- **Cloud Native Hybrid Alternative**: [Yes](#cloud-native-hybrid-reference-architecture-with-helm-charts-alternative)
- **Unsure which Reference Architecture to use?** [Go to this guide for more info](_index.md#deciding-which-architecture-to-start-with)

| Service                                  | Nodes | Configuration           | GCP example<sup>1</sup> | AWS example<sup>1</sup> | Azure example<sup>1</sup> |
|------------------------------------------|-------|-------------------------|------------------|---------------|-----------|
| External load balancer<sup>4</sup>       | 1     | 16 vCPU, 14.4 GB memory | `n1-highcpu-16`  | `c5.4xlarge`  | `F16s v2` |
| Consul<sup>2</sup>                       | 3     | 2 vCPU, 1.8 GB memory   | `n1-highcpu-2`   | `c5.large`    | `F2s v2`  |
| PostgreSQL<sup>2</sup>                   | 3     | 32 vCPU, 120 GB memory  | `n1-standard-32` | `m5.8xlarge`  | `D32s v3` |
| PgBouncer<sup>2</sup>                    | 3     | 2 vCPU, 1.8 GB memory   | `n1-highcpu-2`   | `c5.large`    | `F2s v2`  |
| Internal load balancer<sup>4</sup>       | 1     | 16 vCPU, 14.4 GB memory | `n1-highcpu-16`  | `c5.4xlarge`  | `F16s v2` |
| Redis/Sentinel - Cache<sup>3</sup>       | 3     | 4 vCPU, 15 GB memory    | `n1-standard-4`  | `m5.xlarge`   | `D4s v3`  |
| Redis/Sentinel - Persistent<sup>3</sup>  | 3     | 4 vCPU, 15 GB memory    | `n1-standard-4`  | `m5.xlarge`   | `D4s v3`  |
| Gitaly<sup>6</sup><sup>7</sup>           | 3     | 64 vCPU, 240 GB memory  | `n1-standard-64` | `m5.16xlarge` | `D64s v3` |
| Praefect<sup>6</sup>                     | 3     | 4 vCPU, 3.6 GB memory   | `n1-highcpu-4`   | `c5.xlarge`   | `F4s v2`  |
| Praefect PostgreSQL<sup>2</sup>          | 1+    | 2 vCPU, 1.8 GB memory   | `n1-highcpu-2`   | `c5.large`    | `F2s v2`  |
| Sidekiq<sup>8</sup>                      | 4     | 4 vCPU, 15 GB memory    | `n1-standard-4`  | `m5.xlarge`   | `D4s v3`  |
| GitLab Rails<sup>8</sup>                 | 12    | 32 vCPU, 28.8 GB memory | `n1-highcpu-32`  | `c5.9xlarge`  | `F32s v2` |
| Monitoring node                          | 1     | 4 vCPU, 3.6 GB memory   | `n1-highcpu-4`   | `c5.xlarge`   | `F4s v2`  |
| Object storage<sup>5</sup>               | -     | -                       | -                | -             | -         |

**Footnotes**:

<!-- Disable ordered list rule https://github.com/DavidAnson/markdownlint/blob/main/doc/Rules.md#md029---ordered-list-item-prefix -->
<!-- markdownlint-disable MD029 -->
1. Machine type examples are given for illustration purposes. These types are used in [validation and testing](_index.md#validation-and-test-results) but are not intended as prescriptive defaults. Switching to other machine types that meet the requirements as listed is supported, including ARM variants if available. See [Supported machine types](_index.md#supported-machine-types) for more information.
2. Can be optionally run on reputable third-party external PaaS PostgreSQL solutions. See [Provide your own PostgreSQL instance](#provide-your-own-postgresql-instance) for more information.
3. Can be optionally run on reputable third-party external PaaS Redis solutions. See [Provide your own Redis instances](#provide-your-own-redis-instances) for more information.
    - Redis is primarily single threaded and doesn't significantly benefit from an increase in CPU cores. For this size of architecture it's strongly recommended having separate Cache and Persistent instances as specified to achieve optimum performance.
4. Can be optionally run on reputable third-party load balancing services (LB PaaS). See [Recommended cloud providers and services](_index.md#recommended-cloud-providers-and-services) for more information.
5. Should be run on reputable Cloud Provider or Self Managed solutions. See [Configure the object storage](#configure-the-object-storage) for more information.
6. Gitaly Cluster (Praefect) provides the benefits of fault tolerance, but comes with additional complexity of setup and management.
   Review the existing [technical limitations and considerations before deploying Gitaly Cluster (Praefect)](../gitaly/praefect/_index.md#before-deploying-gitaly-cluster-praefect). If you want sharded Gitaly, use the same specs listed in the previous table for `Gitaly`.
7. Gitaly specifications are based on high percentiles of both usage patterns and repository sizes in good health.
   However, if you have [large monorepos](_index.md#large-monorepos) (larger than several gigabytes) or [additional workloads](_index.md#additional-workloads) these can significantly impact Git and Gitaly performance and further adjustments will likely be required.
8. Can be placed in Auto Scaling Groups (ASGs) as the component doesn't store any [stateful data](_index.md#autoscaling-of-stateful-nodes).
   However, [Cloud Native Hybrid setups](#cloud-native-hybrid-reference-architecture-with-helm-charts-alternative) are generally preferred as certain components
   such as like [migrations](#gitlab-rails-post-configuration) and [Mailroom](../incoming_email.md) can only be run on one node, which is handled better in Kubernetes.
<!-- markdownlint-enable MD029 -->

{{< alert type="note" >}}

For all PaaS solutions that involve configuring instances, it's recommended to implement a minimum of three nodes in three different availability zones to align with resilient cloud architecture practices.

{{< /alert >}}

```plantuml
@startuml 50k
skinparam linetype ortho

card "**External Load Balancer**" as elb #6a9be7
card "**Internal Load Balancer**" as ilb #9370DB

together {
  collections "**GitLab Rails** x12" as gitlab #32CD32
  collections "**Sidekiq** x4" as sidekiq #ff8dd1
}

together {
  card "**Prometheus**" as monitor #7FFFD4
  collections "**Consul** x3" as consul #e76a9b
}

card "Gitaly Cluster" as gitaly_cluster {
  collections "**Praefect** x3" as praefect #FF8C00
  collections "**Gitaly** x3" as gitaly #FF8C00
  card "**Praefect PostgreSQL***\n//Non fault-tolerant//" as praefect_postgres #FF8C00

  praefect -[#FF8C00]-> gitaly
  praefect -[#FF8C00]> praefect_postgres
}

card "Database" as database {
  collections "**PGBouncer** x3" as pgbouncer #4EA7FF
  card "**PostgreSQL** //Primary//" as postgres_primary #4EA7FF
  collections "**PostgreSQL** //Secondary// x2" as postgres_secondary #4EA7FF

  pgbouncer -[#4EA7FF]-> postgres_primary
  postgres_primary .[#4EA7FF]> postgres_secondary
}

card "redis" as redis {
  collections "**Redis Persistent** x3" as redis_persistent #FF6347
  collections "**Redis Cache** x3" as redis_cache #FF6347

  redis_cache -[hidden]-> redis_persistent
}

cloud "**Object Storage**" as object_storage #white

elb -[#6a9be7]-> gitlab
elb -[#6a9be7,norank]--> monitor

gitlab -[#32CD32,norank]--> ilb
gitlab -[#32CD32]r-> object_storage
gitlab -[#32CD32]----> redis
gitlab .[#32CD32]----> database
gitlab -[hidden]-> monitor
gitlab -[hidden]-> consul

sidekiq -[#ff8dd1,norank]--> ilb
sidekiq -[#ff8dd1]r-> object_storage
sidekiq -[#ff8dd1]----> redis
sidekiq .[#ff8dd1]----> database
sidekiq -[hidden]-> monitor
sidekiq -[hidden]-> consul

ilb -[#9370DB]--> gitaly_cluster
ilb -[#9370DB]--> database
ilb -[hidden]--> redis
ilb -[hidden]u-> consul
ilb -[hidden]u-> monitor

consul .[#e76a9b]u-> gitlab
consul .[#e76a9b]u-> sidekiq
consul .[#e76a9b]r-> monitor
consul .[#e76a9b]-> database
consul .[#e76a9b]-> gitaly_cluster
consul .[#e76a9b,norank]--> redis

monitor .[#7FFFD4]u-> gitlab
monitor .[#7FFFD4]u-> sidekiq
monitor .[#7FFFD4]> consul
monitor .[#7FFFD4]-> database
monitor .[#7FFFD4]-> gitaly_cluster
monitor .[#7FFFD4,norank]--> redis
monitor .[#7FFFD4]> ilb
monitor .[#7FFFD4,norank]u--> elb

@enduml
```

## Requirements

Before starting, see the [requirements](_index.md#requirements) for reference architectures.

## Testing methodology

The 1000 RPS / 50k user reference architecture is designed to accommodate most common workflows. GitLab regularly conducts smoke and performance testing against the following endpoint throughput targets:

| Endpoint type | Target throughput |
| ------------- | ----------------- |
| API           | 1000 RPS          |
| Web           | 100 RPS           |
| Git (Pull)    | 100 RPS           |
| Git (Push)    | 20 RPS            |

These targets are based on actual customer data reflecting total environmental loads for the specified user count, including CI pipelines and other workloads.

For more information about our testing methodology, see the [validation and test results](_index.md#validation-and-test-results) section.

### Performance considerations

You may need additional adjustments if your environment has:

- Consistently higher throughput than the listed targets
- [Large monorepos](_index.md#large-monorepos)
- Significant [additional workloads](_index.md#additional-workloads)

In these cases, refer to [scaling an environment](_index.md#scaling-an-environment) for more information. If you believe these considerations may apply to you, contact us for additional guidance as required.

### Load Balancer configuration

Our testing environment uses:

- HAProxy for Linux package environments
- Cloud Provider equivalents with NGINX Ingress for Cloud Native Hybrids

## Set up components

To set up GitLab and its components to accommodate up to 1000 RPS or 50,000 users:

1. [Configure the external load balancer](#configure-the-external-load-balancer)
   to handle the load balancing of the GitLab application services nodes.
1. [Configure the internal load balancer](#configure-the-internal-load-balancer)
   to handle the load balancing of GitLab application internal connections.
1. [Configure Consul](#configure-consul) for service discovery and health checking.
1. [Configure PostgreSQL](#configure-postgresql), the database for GitLab.
1. [Configure PgBouncer](#configure-pgbouncer) for database connection pooling and management.
1. [Configure Redis](#configure-redis), which stores session data, temporary
cache information, and background job queues.
1. [Configure Gitaly Cluster (Praefect)](#configure-gitaly-cluster-praefect),
   provides access to the Git repositories.
1. [Configure Sidekiq](#configure-sidekiq) for background job processing.
1. [Configure the main GitLab Rails application](#configure-gitlab-rails)
   to run Puma, Workhorse, GitLab Shell, and to serve all frontend
   requests (which include UI, API, and Git over HTTP/SSH).
1. [Configure Prometheus](#configure-prometheus) to monitor your GitLab
   environment.
1. [Configure the object storage](#configure-the-object-storage)
   used for shared data objects.
1. [Configure advanced search](#configure-advanced-search) (optional) for faster,
   more advanced code search across your entire GitLab instance.

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
- `10.6.0.61`: Redis - Persistent Primary
- `10.6.0.62`: Redis - Persistent Replica 1
- `10.6.0.63`: Redis - Persistent Replica 2
- `10.6.0.91`: Gitaly 1
- `10.6.0.92`: Gitaly 2
- `10.6.0.93`: Gitaly 3
- `10.6.0.131`: Praefect 1
- `10.6.0.132`: Praefect 2
- `10.6.0.133`: Praefect 3
- `10.6.0.141`: Praefect PostgreSQL 1 (non HA)
- `10.6.0.101`: Sidekiq 1
- `10.6.0.102`: Sidekiq 2
- `10.6.0.103`: Sidekiq 3
- `10.6.0.104`: Sidekiq 4
- `10.6.0.111`: GitLab application 1
- `10.6.0.112`: GitLab application 2
- `10.6.0.113`: GitLab application 3
- `10.6.0.114`: GitLab application 4
- `10.6.0.115`: GitLab application 5
- `10.6.0.116`: GitLab application 6
- `10.6.0.117`: GitLab application 7
- `10.6.0.118`: GitLab application 8
- `10.6.0.119`: GitLab application 9
- `10.6.0.120`: GitLab application 10
- `10.6.0.121`: GitLab application 11
- `10.6.0.122`: GitLab application 12
- `10.6.0.151`: Prometheus

## Configure the external load balancer

In a multi-node GitLab configuration, you'll need an external load balancer to route
traffic to the application servers.

The specifics on which load balancer to use, or its exact configuration
is beyond the scope of GitLab documentation but refer to [Load Balancers](_index.md) for more information around
general requirements. This section will focus on the specifics of
what to configure for your load balancer of choice.

### Readiness checks

Ensure the external load balancer only routes to working services with built
in monitoring endpoints. The [readiness checks](../monitoring/health_check.md)
all require [additional configuration](../monitoring/ip_allowlist.md)
on the nodes being checked, otherwise, the external load balancer will not be able to
connect.

### Ports

The basic ports to be used are shown in the table below.

| LB Port | Backend Port | Protocol                 |
| ------- | ------------ | ------------------------ |
| 80      | 80           | HTTP (*1*)               |
| 443     | 443          | TCP or HTTPS (*1*) (*2*) |
| 22      | 22           | TCP                      |

- (*1*): [Web terminal](../../ci/environments/_index.md#web-terminals-deprecated) support requires
  your load balancer to correctly handle WebSocket connections. When using
  HTTP or HTTPS proxying, this means your load balancer must be configured
  to pass through the `Connection` and `Upgrade` hop-by-hop headers. See the
  [web terminal](../integration/terminal.md) integration guide for
  more details.
- (*2*): When using HTTPS protocol for port 443, you must add an SSL
  certificate to the load balancers. If you wish to terminate SSL at the
  GitLab application server instead, use TCP protocol.

If you're using GitLab Pages with custom domain support you will need some
additional port configurations.
GitLab Pages requires a separate virtual IP address. Configure DNS to point the
`pages_external_url` from `/etc/gitlab/gitlab.rb` at the new virtual IP address. See the
[GitLab Pages documentation](../pages/_index.md) for more information.

| LB Port | Backend Port  | Protocol  |
| ------- | ------------- | --------- |
| 80      | Varies (*1*)  | HTTP      |
| 443     | Varies (*1*)  | TCP (*2*) |

- (*1*): The backend port for GitLab Pages depends on the
  `gitlab_pages['external_http']` and `gitlab_pages['external_https']`
  setting. See [GitLab Pages documentation](../pages/_index.md) for more details.
- (*2*): Port 443 for GitLab Pages should always use the TCP protocol. Users can
  configure custom domains with custom SSL, which would not be possible
  if SSL was terminated at the load balancer.

#### Alternate SSH Port

Some organizations have policies against opening SSH port 22. In this case,
it may be helpful to configure an alternate SSH hostname that allows users
to use SSH on port 443. An alternate SSH hostname will require a new virtual IP address
compared to the other GitLab HTTP configuration documented previously.

Configure DNS for an alternate SSH hostname such as `altssh.gitlab.example.com`.

| LB Port | Backend Port | Protocol |
| ------- | ------------ | -------- |
| 443     | 22           | TCP      |

### SSL

The next question is how you will handle SSL in your environment.
There are several different options:

- [The application node terminates SSL](#application-node-terminates-ssl).
- [The load balancer terminates SSL without backend SSL](#load-balancer-terminates-ssl-without-backend-ssl)
  and communication is not secure between the load balancer and the application node.
- [The load balancer terminates SSL with backend SSL](#load-balancer-terminates-ssl-with-backend-ssl)
  and communication is secure between the load balancer and the application node.

#### Application node terminates SSL

Configure your load balancer to pass connections on port 443 as `TCP` rather
than `HTTP(S)` protocol. This will pass the connection to the application node's
NGINX service untouched. NGINX will have the SSL certificate and listen on port 443.

See the [HTTPS documentation](https://docs.gitlab.com/omnibus/settings/ssl/)
for details on managing SSL certificates and configuring NGINX.

#### Load balancer terminates SSL without backend SSL

Configure your load balancer to use the `HTTP(S)` protocol rather than `TCP`.
The load balancer will then be responsible for managing SSL certificates and
terminating SSL.

Because communication between the load balancer and GitLab will not be secure,
there is some additional configuration needed. See the
[proxied SSL documentation](https://docs.gitlab.com/omnibus/settings/ssl/#configure-a-reverse-proxy-or-load-balancer-ssl-termination)
for details.

#### Load balancer terminates SSL with backend SSL

Configure your load balancers to use the 'HTTP(S)' protocol rather than 'TCP'.
The load balancers will be responsible for managing SSL certificates that
end users will see.

Traffic will also be secure between the load balancers and NGINX in this
scenario. There is no requirement to add configuration for proxied SSL because the
connection will be secure all the way. However, configuration must be
added to GitLab to configure SSL certificates. See
the [HTTPS documentation](https://docs.gitlab.com/omnibus/settings/ssl/)
for details on managing SSL certificates and configuring NGINX.

<div align="right">
  <a type="button" class="btn btn-default" href="#set-up-components">
    Back to set up components <i class="fa fa-angle-double-up" aria-hidden="true"></i>
  </a>
</div>

## Configure the internal load balancer

In a multi-node GitLab configuration, you'll need an internal load balancer to route
traffic for select internal components if configured
such as connections to [PgBouncer](#configure-pgbouncer) and [Gitaly Cluster (Praefect)](#configure-praefect).

The specifics on which load balancer to use, or its exact configuration
is beyond the scope of GitLab documentation but refer to [Load Balancers](_index.md) for more information around
general requirements. This section will focus on the specifics of
what to configure for your load balancer of choice.

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

frontend internal-praefect-tcp-in
    bind *:2305
    mode tcp
    option tcplog
    option clitcpka

    default_backend praefect

backend pgbouncer
    mode tcp
    option tcp-check

    server pgbouncer1 10.6.0.31:6432 check
    server pgbouncer2 10.6.0.32:6432 check
    server pgbouncer3 10.6.0.33:6432 check

backend praefect
    mode tcp
    option tcp-check
    option srvtcpka

    server praefect1 10.6.0.131:2305 check
    server praefect2 10.6.0.132:2305 check
    server praefect3 10.6.0.133:2305 check
```

Refer to your preferred Load Balancer's documentation for further guidance.

<div align="right">
  <a type="button" class="btn btn-default" href="#set-up-components">
    Back to set up components <i class="fa fa-angle-double-up" aria-hidden="true"></i>
  </a>
</div>

## Configure Consul

Next, we set up the Consul servers.

{{< alert type="note" >}}

Consul must be deployed in an odd number of 3 nodes or more. This is to ensure the nodes can take votes as part of a quorum.

{{< /alert >}}

The following IPs will be used as an example:

- `10.6.0.11`: Consul 1
- `10.6.0.12`: Consul 2
- `10.6.0.13`: Consul 3

To configure Consul:

1. SSH in to the server that will host Consul.
1. [Download and install](../../install/package/_index.md#supported-platforms) the Linux
   package of your choice. Be sure to only add the GitLab package repository and install GitLab
   for your chosen operating system. Select the same version
   and type (Community or Enterprise editions) as your current install.
1. Edit `/etc/gitlab/gitlab.rb` and add the contents:

   ```ruby
   roles(['consul_role'])

   ## Enable service discovery for Prometheus
   consul['monitoring_service_discovery'] =  true

   ## The IPs of the Consul server nodes
   ## You can also use FQDNs and intermix them with IPs
   consul['configuration'] = {
      server: true,
      retry_join: %w(10.6.0.11 10.6.0.12 10.6.0.13),
   }

   # Set the network addresses that the exporters will listen on
   node_exporter['listen_address'] = '0.0.0.0:9100'

   # Prevent database migrations from running on upgrade automatically
   gitlab_rails['auto_migrate'] = false
   ```

1. Copy the `/etc/gitlab/gitlab-secrets.json` file from the first Linux package node you configured and add or replace
   the file of the same name on this server. If this is the first Linux package node you are configuring then you can skip this step.

1. [Reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) for the changes to take effect.

1. Go through the steps again for all the other Consul nodes, and
   make sure you set up the correct IPs.

A Consul leader is elected when the provisioning of the third Consul server is
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
  <a type="button" class="btn btn-default" href="#set-up-components">
    Back to set up components <i class="fa fa-angle-double-up" aria-hidden="true"></i>
  </a>
</div>

## Configure PostgreSQL

In this section, you'll be guided through configuring a highly available PostgreSQL
cluster to be used with GitLab.

### Provide your own PostgreSQL instance

You can optionally use a [third party external service for PostgreSQL](../postgresql/external.md).

A reputable provider or solution should be used for this. [Google Cloud SQL](https://cloud.google.com/sql/docs/postgres/high-availability#normal)
and [Amazon RDS](https://aws.amazon.com/rds/) are known to work. However, Amazon Aurora is **incompatible** with load balancing enabled by default from
[14.4.0](https://archives.docs.gitlab.com/17.3/ee/update/versions/gitlab_14_changes/#1440).

See [Recommended cloud providers and services](_index.md#recommended-cloud-providers-and-services) for more information.

If you use a third party external service:

1. The HA Linux package PostgreSQL setup encompasses PostgreSQL, PgBouncer and Consul. All of these components would no longer be required when using a third party external service.
1. Set up PostgreSQL according to the
   [database requirements document](../../install/requirements.md#postgresql).
1. Set up a `gitlab` username with a password of your choice. The `gitlab` user
   needs privileges to create the `gitlabhq_production` database.
1. Configure the GitLab application servers with the appropriate details.
   This step is covered in [Configuring the GitLab Rails application](#configure-gitlab-rails).
1. The number of nodes required to achieve HA can differ, depending on the service, and can differ from the Linux package.
1. However, if [Database Load Balancing](../postgresql/database_load_balancing.md) via Read Replicas is desired for further improved performance it's recommended to follow the node count for the Reference Architecture.

### Standalone PostgreSQL using the Linux package

The recommended Linux package configuration for a PostgreSQL cluster with
replication and failover requires:

- A minimum of three PostgreSQL nodes.
- A minimum of three Consul server nodes.
- A minimum of three PgBouncer nodes that track and handle primary database reads and writes.
  - An [internal load balancer](#configure-the-internal-load-balancer) (TCP) to balance requests between the PgBouncer nodes.
- [Database Load Balancing](../postgresql/database_load_balancing.md) enabled.

  A local PgBouncer service to be configured on each PostgreSQL node. This is separate from the main PgBouncer cluster that tracks the primary.

The following IPs will be used as an example:

- `10.6.0.21`: PostgreSQL primary
- `10.6.0.22`: PostgreSQL secondary 1
- `10.6.0.23`: PostgreSQL secondary 2

First, make sure to [install](../../install/package/_index.md#supported-platforms)
the Linux package **on each node**. Be sure to only add the GitLab
package repository and install GitLab for your chosen operating system,
but do **not** provide the `EXTERNAL_URL` value.

#### PostgreSQL nodes

1. SSH in to one of the PostgreSQL nodes.
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

1. Generate a password hash for the PostgreSQL replication username/password pair. This assumes you will use the default
   username of `gitlab_replicator` (recommended). The command will request a password
   and a confirmation. Use the value that is output by this command in the next step
   as the value of `<postgresql_replication_password_hash>`:

   ```shell
   sudo gitlab-ctl pg-password-md5 gitlab_replicator
   ```

1. Generate a password hash for the Consul database username/password pair. This assumes you will use the default
   username of `gitlab-consul` (recommended). The command will request a password
   and confirmation. Use the value that is output by this command in the next
   step as the value of `<consul_password_hash>`:

   ```shell
   sudo gitlab-ctl pg-password-md5 gitlab-consul
   ```

1. On every database node, edit `/etc/gitlab/gitlab.rb` replacing values noted in the `# START user configuration` section:

   ```ruby
   # Disable all components except Patroni, PgBouncer and Consul
   roles(['patroni_role', 'pgbouncer_role'])

   # PostgreSQL configuration
   postgresql['listen_address'] = '0.0.0.0'

   # Sets `max_replication_slots` to double the number of database nodes.
   # Patroni uses one extra slot per node when initiating the replication.
   patroni['postgresql']['max_replication_slots'] = 6

   # Set `max_wal_senders` to one more than the number of replication slots in the cluster.
   # This is used to prevent replication from using up all of the
   # available database connections.
   patroni['postgresql']['max_wal_senders'] = 7

   # Prevent database migrations from running on upgrade automatically
   gitlab_rails['auto_migrate'] = false

   # Configure the Consul agent
   consul['enable'] = true
   consul['services'] = %w(postgresql)
   ## Enable service discovery for Prometheus
   consul['monitoring_service_discovery'] =  true

   # START user configuration
   # Please set the real values as explained in Required Information section
   #
   # Replace PGBOUNCER_PASSWORD_HASH with a generated md5 value
   postgresql['pgbouncer_user_password'] = '<pgbouncer_password_hash>'
   # Replace POSTGRESQL_REPLICATION_PASSWORD_HASH with a generated md5 value
   postgresql['sql_replication_password'] = '<postgresql_replication_password_hash>'
   # Replace POSTGRESQL_PASSWORD_HASH with a generated md5 value
   postgresql['sql_user_password'] = '<postgresql_password_hash>'

   # Set up basic authentication for the Patroni API (use the same username/password in all nodes).
   patroni['username'] = '<patroni_api_username>'
   patroni['password'] = '<patroni_api_password>'

   # Replace 10.6.0.0/24 with Network Address
   postgresql['trust_auth_cidr_addresses'] = %w(10.6.0.0/24 127.0.0.1/32)

   # Local PgBouncer service for Database Load Balancing
   pgbouncer['databases'] = {
      gitlabhq_production: {
         host: "127.0.0.1",
         user: "pgbouncer",
         password: '<pgbouncer_password_hash>'
      }
   }

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

PostgreSQL, with Patroni managing its failover, will default to use `pg_rewind` by default to handle conflicts.
Like most failover handling methods, this has a small chance of leading to data loss.
For more information, see the various [Patroni replication methods](../postgresql/replication_and_failover.md#selecting-the-appropriate-patroni-replication-method).

1. Copy the `/etc/gitlab/gitlab-secrets.json` file from the first Linux package node you configured and add or replace
   the file of the same name on this server. If this is the first Linux package node you are configuring then you can skip this step.

1. [Reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) for the changes to take effect.

Advanced [configuration options](https://docs.gitlab.com/omnibus/settings/database.html)
are supported and can be added if needed.

<div align="right">
  <a type="button" class="btn btn-default" href="#set-up-components">
    Back to set up components <i class="fa fa-angle-double-up" aria-hidden="true"></i>
  </a>
</div>

#### PostgreSQL post-configuration

SSH in to any of the Patroni nodes on the **primary site**:

1. Check the status of the leader and cluster:

   ```shell
   gitlab-ctl patroni members
   ```

   The output should be similar to the following:

   ```plaintext
   | Cluster       | Member                            |  Host     | Role   | State   | TL  | Lag in MB | Pending restart |
   |---------------|-----------------------------------|-----------|--------|---------|-----|-----------|-----------------|
   | postgresql-ha | <PostgreSQL primary hostname>     | 10.6.0.21 | Leader | running | 175 |           | *               |
   | postgresql-ha | <PostgreSQL secondary 1 hostname> | 10.6.0.22 |        | running | 175 | 0         | *               |
   | postgresql-ha | <PostgreSQL secondary 2 hostname> | 10.6.0.23 |        | running | 175 | 0         | *               |
   ```

If the 'State' column for any node doesn't say "running", check the
[PostgreSQL replication and failover troubleshooting section](../postgresql/replication_and_failover_troubleshooting.md#pgbouncer-error-error-pgbouncer-cannot-connect-to-server)
before proceeding.

<div align="right">
  <a type="button" class="btn btn-default" href="#set-up-components">
    Back to set up components <i class="fa fa-angle-double-up" aria-hidden="true"></i>
  </a>
</div>

### Configure PgBouncer

Now that the PostgreSQL servers are all set up, let's configure PgBouncer
for tracking and handling reads/writes to the primary database.

{{< alert type="note" >}}

PgBouncer is single threaded and doesn't significantly benefit from an increase in CPU cores.
Refer to the [scaling documentation](_index.md#scaling-an-environment) for more information.

{{< /alert >}}

The following IPs will be used as an example:

- `10.6.0.31`: PgBouncer 1
- `10.6.0.32`: PgBouncer 2
- `10.6.0.33`: PgBouncer 3

1. On each PgBouncer node, edit `/etc/gitlab/gitlab.rb`, and replace
   `<consul_password_hash>` and `<pgbouncer_password_hash>` with the
   password hashes you [set up previously](#postgresql-nodes):

   ```ruby
   # Disable all components except Pgbouncer and Consul agent
   roles(['pgbouncer_role'])

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
   consul['configuration'] = {
   retry_join: %w(10.6.0.11 10.6.0.12 10.6.0.13)
   }

   # Enable service discovery for Prometheus
   consul['monitoring_service_discovery'] = true

   # Set the network addresses that the exporters will listen on
   node_exporter['listen_address'] = '0.0.0.0:9100'
   ```

1. Copy the `/etc/gitlab/gitlab-secrets.json` file from the first Linux package node you configured and add or replace
   the file of the same name on this server. If this is the first Linux package node you are configuring then you can skip this step.

1. [Reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) for the changes to take effect.

   If an error `execute[generate databases.ini]` occurs, this is due to an existing
   [known issue](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/4713).
   It will be resolved when you run a second `reconfigure` after the next step.

1. Create a `.pgpass` file so Consul is able to
   reload PgBouncer. Enter the PgBouncer password twice when asked:

   ```shell
   gitlab-ctl write-pgpass --host 127.0.0.1 --database pgbouncer --user pgbouncer --hostuser gitlab-consul
   ```

1. [Reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) once again
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
  <a type="button" class="btn btn-default" href="#set-up-components">
    Back to set up components <i class="fa fa-angle-double-up" aria-hidden="true"></i>
  </a>
</div>

## Configure Redis

Using [Redis](https://redis.io/) in scalable environment is possible using a **Primary** x **Replica**
topology with a [Redis Sentinel](https://redis.io/docs/latest/operate/oss_and_stack/management/sentinel/) service to watch and automatically
start the failover procedure.

{{< alert type="note" >}}

Redis clusters must each be deployed in an odd number of 3 nodes or more. This is to ensure Redis Sentinel can take votes as part of a quorum. This does not apply when configuring Redis externally, such as a cloud provider service.

{{< /alert >}}

{{< alert type="note" >}}

Redis is primarily single threaded and doesn't significantly benefit from increasing CPU cores.
For this size of architecture it's strongly recommended having separate Cache and Persistent instances as specified to achieve optimum performance at this scale.
Refer to the [scaling documentation](_index.md#scaling-an-environment) for more information.
{{< /alert >}}

Redis requires authentication if used with Sentinel. See
[Redis Security](https://redis.io/docs/latest/operate/rc/security/) documentation for more
information. We recommend using a combination of a Redis password and tight
firewall rules to secure your Redis service.
You are highly encouraged to read the [Redis Sentinel](https://redis.io/docs/latest/operate/oss_and_stack/management/sentinel/) documentation
before configuring Redis with GitLab to fully understand the topology and
architecture.

The requirements for a Redis setup are the following:

1. All Redis nodes must be able to talk to each other and accept incoming
   connections over Redis (`6379`) and Sentinel (`26379`) ports (unless you
   change the default ones).
1. The server that hosts the GitLab application must be able to access the
   Redis nodes.
1. Protect the nodes from access from external networks
   (Internet),
   using a firewall.

In this section, you'll be guided through configuring two external Redis clusters
to be used with GitLab. The following IPs will be used as an example:

- `10.6.0.51`: Redis - Cache Primary
- `10.6.0.52`: Redis - Cache Replica 1
- `10.6.0.53`: Redis - Cache Replica 2
- `10.6.0.61`: Redis - Persistent Primary
- `10.6.0.62`: Redis - Persistent Replica 1
- `10.6.0.63`: Redis - Persistent Replica 2

### Provide your own Redis instances

You can optionally use a [third party external service for the Redis Cache and Persistence instances](../redis/replication_and_failover_external.md#redis-as-a-managed-service-in-a-cloud-provider) with the following guidance:

- A reputable provider or solution should be used for this. [Google Memorystore](https://cloud.google.com/memorystore/docs/redis/memorystore-for-redis-overview) and [AWS ElastiCache](https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/WhatIs.html) are known to work.
- Redis Cluster mode is specifically not supported, but Redis Standalone with HA is.
- You must set the [Redis eviction mode](../redis/replication_and_failover_external.md#setting-the-eviction-policy) according to your setup.

For more information, see [Recommended cloud providers and services](_index.md#recommended-cloud-providers-and-services).

### Configure the Redis Cache cluster

This is the section where we install and set up the new Redis Cache instances.

Both the primary and replica Redis nodes need the same password defined in
`redis['password']`. At any time during a failover, the Sentinels can reconfigure
a node and change its status from primary to replica (and vice versa).

#### Configure the primary Redis Cache node

1. SSH in to the **Primary** Redis server.
1. [Download and install](../../install/package/_index.md#supported-platforms) the Linux
   package of your choice. Be sure to only add the GitLab package repository and install GitLab
   for your chosen operating system. Select the same version
   and type (Community or Enterprise editions) as your current install.
1. Edit `/etc/gitlab/gitlab.rb` and add the contents:

   ```ruby
   # Specify server role as 'redis_master_role' with Sentinel and enable Consul agent
   roles(['redis_sentinel_role', 'redis_master_role', 'consul_role'])

   # Set IP bind address and Quorum number for Redis Sentinel service
   sentinel['bind'] = '0.0.0.0'
   sentinel['quorum'] = 2

   # IP address pointing to a local IP that the other machines can reach to.
   # You can also set bind to '0.0.0.0' which listen in all interfaces.
   # If you must bind to an external accessible IP, make
   # sure you add extra firewall rules to prevent unauthorized access.
   redis['bind'] = '10.6.0.51'

   # Define a port so Redis can listen for TCP requests which will allow other
   # machines to connect to it.
   redis['port'] = 6379

   ## Port of primary Redis server for Sentinel, uncomment to change to non default. Defaults
   ## to `6379`.
   #redis['master_port'] = 6379

   # Set up password authentication for Redis and replicas (use the same password in all nodes).
   redis['password'] = 'REDIS_PRIMARY_PASSWORD_OF_FIRST_CLUSTER'
   redis['master_password'] = 'REDIS_PRIMARY_PASSWORD_OF_FIRST_CLUSTER'

   ## Must be the same in every Redis node
   redis['master_name'] = 'gitlab-redis-cache'

   ## The IP of this primary Redis node.
   redis['master_ip'] = '10.6.0.51'

   # Set the Redis Cache instance as an LRU
   # 90% of available RAM in MB
   redis['maxmemory'] = '13500mb'
   redis['maxmemory_policy'] = "allkeys-lru"
   redis['maxmemory_samples'] = 5

   ## Enable service discovery for Prometheus
   consul['monitoring_service_discovery'] =  true

   ## The IPs of the Consul server nodes
   ## You can also use FQDNs and intermix them with IPs
   consul['configuration'] = {
      retry_join: %w(10.6.0.11 10.6.0.12 10.6.0.13),
   }

   # Set the network addresses that the exporters will listen on
   node_exporter['listen_address'] = '0.0.0.0:9100'
   redis_exporter['listen_address'] = '0.0.0.0:9121'
   redis_exporter['flags'] = {
        'redis.addr' => 'redis://10.6.0.51:6379',
        'redis.password' => 'redis-password-goes-here',
   }

   # Prevent database migrations from running on upgrade automatically
   gitlab_rails['auto_migrate'] = false
   ```

1. Copy the `/etc/gitlab/gitlab-secrets.json` file from the first Linux package node you configured and add or replace
   the file of the same name on this server. If this is the first Linux package node you are configuring then you can skip this step.

1. [Reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) for the changes to take effect.

#### Configure the replica Redis Cache nodes

1. SSH in to the **replica** Redis server.
1. [Download and install](../../install/package/_index.md#supported-platforms) the Linux
   package of your choice. Be sure to only add the GitLab package repository and install GitLab
   for your chosen operating system. Select the same version
   and type (Community or Enterprise editions) as your current install.
1. Edit `/etc/gitlab/gitlab.rb` and add the same contents as the primary node in the previous section by replacing `redis_master_node` with `redis_replica_node`:

   ```ruby
   # Specify server role as 'redis_replica_role' with Sentinel and enable Consul agent
   roles(['roles_sentinel_role', 'redis_replica_role', 'consul_role'])

   # Set IP bind address and Quorum number for Redis Sentinel service
   sentinel['bind'] = '0.0.0.0'
   sentinel['quorum'] = 2

   # IP address pointing to a local IP that the other machines can reach to.
   # You can also set bind to '0.0.0.0' which listen in all interfaces.
   # If you must bind to an external accessible IP, make
   # sure you add extra firewall rules to prevent unauthorized access.
   redis['bind'] = '10.6.0.52'

   # Define a port so Redis can listen for TCP requests which will allow other
   # machines to connect to it.
   redis['port'] = 6379

   ## Port of primary Redis server for Sentinel, uncomment to change to non default. Defaults
   ## to `6379`.
   #redis['master_port'] = 6379

   # Set up password authentication for Redis and replicas (use the same password in all nodes).
   redis['password'] = 'REDIS_PRIMARY_PASSWORD_OF_FIRST_CLUSTER'
   redis['master_password'] = 'REDIS_PRIMARY_PASSWORD_OF_FIRST_CLUSTER'

   ## Must be the same in every Redis node
   redis['master_name'] = 'gitlab-redis-cache'

   ## The IP of the primary Redis node.
   redis['master_ip'] = '10.6.0.51'

   # Set the Redis Cache instance as an LRU
   # 90% of available RAM in MB
   redis['maxmemory'] = '13500mb'
   redis['maxmemory_policy'] = "allkeys-lru"
   redis['maxmemory_samples'] = 5

   ## Enable service discovery for Prometheus
   consul['monitoring_service_discovery'] =  true

   ## The IPs of the Consul server nodes
   ## You can also use FQDNs and intermix them with IPs
   consul['configuration'] = {
      retry_join: %w(10.6.0.11 10.6.0.12 10.6.0.13),
   }

   # Set the network addresses that the exporters will listen on
   node_exporter['listen_address'] = '0.0.0.0:9100'
   redis_exporter['listen_address'] = '0.0.0.0:9121'
   redis_exporter['flags'] = {
        'redis.addr' => 'redis://10.6.0.52:6379',
        'redis.password' => 'redis-password-goes-here',
   }

   # Prevent database migrations from running on upgrade automatically
   gitlab_rails['auto_migrate'] = false
   ```

   1. Copy the `/etc/gitlab/gitlab-secrets.json` file from the first Linux package
      node you configured and add or replace the file of the same name on this
      server. If this is the first Linux package node you are configuring then you
      can skip this step.

   1. [Reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) for the changes
      to take effect.

   1. Go through the steps again for all the other replica nodes, and
      make sure to set up the IPs correctly.

Advanced [configuration options](https://docs.gitlab.com/omnibus/settings/redis.html) are supported and can be added if needed.

<div align="right">
  <a type="button" class="btn btn-default" href="#set-up-components">
    Back to set up components <i class="fa fa-angle-double-up" aria-hidden="true"></i>
  </a>
</div>

### Configure the Redis Persistent cluster

This is the section where we install and set up the new Redis Queues instances.

Both the primary and replica Redis nodes need the same password defined in
`redis['password']`. At any time during a failover, the Sentinels can reconfigure
a node and change its status from primary to replica (and vice versa).

#### Configure the primary Redis Persistent node

1. SSH in to the **Primary** Redis server.
1. [Download and install](../../install/package/_index.md#supported-platforms) the Linux
   package of your choice. Be sure to only add the GitLab package repository and install GitLab
   for your chosen operating system. Select the same version
   and type (Community or Enterprise editions) as your current install.
1. Edit `/etc/gitlab/gitlab.rb` and add the contents:

   ```ruby
   # Specify server roles as 'redis_master_role' with Sentinel and enable the Consul agent
   roles ['redis_sentinel_role', 'redis_master_role', 'consul_role']

   # Set IP bind address and Quorum number for Redis Sentinel service
   sentinel['bind'] = '0.0.0.0'
   sentinel['quorum'] = 2

   # IP address pointing to a local IP that the other machines can reach to.
   # You can also set bind to '0.0.0.0' which listen in all interfaces.
   # If you must bind to an external accessible IP, make
   # sure you add extra firewall rules to prevent unauthorized access.
   redis['bind'] = '10.6.0.61'

   # Define a port so Redis can listen for TCP requests which will allow other
   # machines to connect to it.
   redis['port'] = 6379

   ## Port of primary Redis server for Sentinel, uncomment to change to non default. Defaults
   ## to `6379`.
   #redis['master_port'] = 6379

   # Set up password authentication for Redis and replicas (use the same password in all nodes).
   redis['password'] = 'REDIS_PRIMARY_PASSWORD_OF_SECOND_CLUSTER'
   redis['master_password'] = 'REDIS_PRIMARY_PASSWORD_OF_SECOND_CLUSTER'

   ## Must be the same in every Redis node
   redis['master_name'] = 'gitlab-redis-persistent'

   ## The IP of this primary Redis node.
   redis['master_ip'] = '10.6.0.61'

   ## Enable service discovery for Prometheus
   consul['monitoring_service_discovery'] =  true

   ## The IPs of the Consul server nodes
   ## You can also use FQDNs and intermix them with IPs
   consul['configuration'] = {
      retry_join: %w(10.6.0.11 10.6.0.12 10.6.0.13),
   }

   # Set the network addresses that the exporters will listen on
   node_exporter['listen_address'] = '0.0.0.0:9100'
   redis_exporter['listen_address'] = '0.0.0.0:9121'

   # Prevent database migrations from running on upgrade automatically
   gitlab_rails['auto_migrate'] = false
   ```

1. Copy the `/etc/gitlab/gitlab-secrets.json` file from the first Linux package node you configured and add or replace
   the file of the same name on this server. If this is the first Linux package node you are configuring then you can skip this step.

1. [Reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) for the changes to take effect.

#### Configure the replica Redis Persistent nodes

1. SSH in to the **replica** Redis Persistent server.
1. [Download and install](../../install/package/_index.md#supported-platforms) the Linux
   package of your choice. Be sure to only add the GitLab package repository and install GitLab
   for your chosen operating system. Select the same version
   and type (Community or Enterprise editions) as your current install.
1. Edit `/etc/gitlab/gitlab.rb` and add the contents:

   ```ruby
   # Specify server roles as 'redis_replica_role' with Sentinel and enable Consul agent
   roles ['redis_sentinel_role', 'redis_replica_role', 'consul_role']

   # Set IP bind address and Quorum number for Redis Sentinel service
   sentinel['bind'] = '0.0.0.0'
   sentinel['quorum'] = 2

   # IP address pointing to a local IP that the other machines can reach to.
   # You can also set bind to '0.0.0.0' which listen in all interfaces.
   # If you must bind to an external accessible IP, make
   # sure you add extra firewall rules to prevent unauthorized access.
   redis['bind'] = '10.6.0.62'

   # Define a port so Redis can listen for TCP requests which will allow other
   # machines to connect to it.
   redis['port'] = 6379

   ## Port of primary Redis server for Sentinel, uncomment to change to non default. Defaults
   ## to `6379`.
   #redis['master_port'] = 6379

   # The same password for Redis authentication you set up for the primary node.
   redis['password'] = 'REDIS_PRIMARY_PASSWORD_OF_SECOND_CLUSTER'
   redis['master_password'] = 'REDIS_PRIMARY_PASSWORD_OF_SECOND_CLUSTER'

   ## Must be the same in every Redis node
   redis['master_name'] = 'gitlab-redis-persistent'

   # The IP of the primary Redis node.
   redis['master_ip'] = '10.6.0.61'

   ## Enable service discovery for Prometheus
   consul['monitoring_service_discovery'] =  true

   ## The IPs of the Consul server nodes
   ## You can also use FQDNs and intermix them with IPs
   consul['configuration'] = {
      retry_join: %w(10.6.0.11 10.6.0.12 10.6.0.13),
   }

   # Set the network addresses that the exporters will listen on
   node_exporter['listen_address'] = '0.0.0.0:9100'
   redis_exporter['listen_address'] = '0.0.0.0:9121'

   # Prevent database migrations from running on upgrade automatically
   gitlab_rails['auto_migrate'] = false
   ```

1. Copy the `/etc/gitlab/gitlab-secrets.json` file from the first Linux package node you configured and add or replace
   the file of the same name on this server. If this is the first Linux package node you are configuring then you can skip this step.

1. [Reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) for the changes to take effect.

1. Go through the steps again for all the other replica nodes, and
   make sure to set up the IPs correctly.

Advanced [configuration options](https://docs.gitlab.com/omnibus/settings/redis.html) are supported and can be added if needed.

<div align="right">
  <a type="button" class="btn btn-default" href="#set-up-components">
    Back to set up components <i class="fa fa-angle-double-up" aria-hidden="true"></i>
  </a>
</div>

## Configure Gitaly Cluster (Praefect)

[Gitaly Cluster (Praefect)](../gitaly/praefect/_index.md) is a GitLab-provided and recommended fault tolerant solution for storing Git
repositories. In this configuration, every Git repository is stored on every Gitaly node in the cluster, with one being
designated the primary, and failover occurs automatically if the primary node goes down.

{{< alert type="warning" >}}

**Gitaly specifications are based on high percentiles of both usage patterns and repository sizes in good health**.
**However, if you have [large monorepos](_index.md#large-monorepos) (larger than several gigabytes) or [additional workloads](_index.md#additional-workloads) these can significantly impact the performance of the environment and further adjustments may be required**.
If you believe this applies to you, contact us for additional guidance as required.

{{< /alert >}}

Gitaly Cluster (Praefect) provides the benefits of fault tolerance, but comes with additional complexity of setup and management.
Review the existing [technical limitations and considerations before deploying Gitaly Cluster (Praefect)](../gitaly/praefect/_index.md#before-deploying-gitaly-cluster-praefect).

For guidance on:

- Implementing sharded Gitaly instead, follow the [separate Gitaly documentation](../gitaly/configure_gitaly.md)
  instead of this section. Use the same Gitaly specs.
- Migrating existing repositories that aren't managed by Gitaly Cluster (Praefect), see
  [migrate to Gitaly Cluster (Praefect)](../gitaly/praefect/_index.md#migrate-to-gitaly-cluster-praefect).

The recommended cluster setup includes the following components:

- 3 Gitaly nodes: Replicated storage of Git repositories.
- 3 Praefect nodes: Router and transaction manager for Gitaly Cluster (Praefect).
- 1 Praefect PostgreSQL node: Database server for Praefect. A third-party solution
  is required for Praefect database connections to be made highly available.
- 1 load balancer: A load balancer is required for Praefect. The
  [internal load balancer](#configure-the-internal-load-balancer) is used.

This section details how to configure the recommended standard setup in order.
For more advanced setups refer to the [standalone Gitaly Cluster (Praefect) documentation](../gitaly/praefect/_index.md).

### Configure Praefect PostgreSQL

Praefect, the routing and transaction manager for Gitaly Cluster (Praefect), requires its own database server to store data on Gitaly Cluster (Praefect) status.

If you want to have a highly available setup, Praefect requires a third-party PostgreSQL database.
A built-in solution is being [worked on](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/7292).

#### Praefect non-HA PostgreSQL standalone using the Linux package

The following IPs will be used as an example:

- `10.6.0.141`: Praefect PostgreSQL

First, make sure to [install](../../install/package/_index.md#supported-platforms)
the Linux package on the Praefect PostgreSQL node. Be sure to only add the GitLab
package repository and install GitLab for your chosen operating system,
but do **not** provide the `EXTERNAL_URL` value.

1. SSH in to the Praefect PostgreSQL node.
1. Create a strong password to be used for the Praefect PostgreSQL user. Take note of this password as `<praefect_postgresql_password>`.
1. Generate the password hash for the Praefect PostgreSQL username/password pair. This assumes you will use the default
   username of `praefect` (recommended). The command will request the password `<praefect_postgresql_password>`
   and confirmation. Use the value that is output by this command in the next
   step as the value of `<praefect_postgresql_password_hash>`:

   ```shell
   sudo gitlab-ctl pg-password-md5 praefect
   ```

1. Edit `/etc/gitlab/gitlab.rb` replacing values noted in the `# START user configuration` section:

   ```ruby
   # Disable all components except PostgreSQL and Consul
   roles(['postgres_role', 'consul_role'])

   # PostgreSQL configuration
   postgresql['listen_address'] = '0.0.0.0'

   # Prevent database migrations from running on upgrade automatically
   gitlab_rails['auto_migrate'] = false

   # Configure the Consul agent
   ## Enable service discovery for Prometheus
   consul['monitoring_service_discovery'] =  true

   # START user configuration
   # Please set the real values as explained in Required Information section
   #
   # Replace PRAEFECT_POSTGRESQL_PASSWORD_HASH with a generated md5 value
   postgresql['sql_user_password'] = "<praefect_postgresql_password_hash>"

   # Replace XXX.XXX.XXX.XXX/YY with Network Address
   postgresql['trust_auth_cidr_addresses'] = %w(10.6.0.0/24 127.0.0.1/32)

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

1. Copy the `/etc/gitlab/gitlab-secrets.json` file from the first Linux package node you configured and add or replace
   the file of the same name on this server. If this is the first Linux package node you are configuring then you can skip this step.

1. [Reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) for the changes to take effect.

1. Follow the [post configuration](#praefect-postgresql-post-configuration).

<div align="right">
  <a type="button" class="btn btn-default" href="#set-up-components">
    Back to set up components <i class="fa fa-angle-double-up" aria-hidden="true"></i>
  </a>
</div>

#### Praefect HA PostgreSQL third-party solution

[As noted](#configure-praefect-postgresql), a third-party PostgreSQL solution for
Praefect's database is recommended if aiming for full High Availability.

There are many third-party solutions for PostgreSQL HA. The solution selected must have the following to work with Praefect:

- A static IP for all connections that doesn't change on failover.
- [`LISTEN`](https://www.postgresql.org/docs/16/sql-listen.html) SQL functionality must be supported.

{{< alert type="note" >}}

With a third-party setup, it's possible to colocate Praefect's database on the same server as
the main [GitLab](#provide-your-own-postgresql-instance) database as a convenience unless
you are using Geo, where separate database instances are required for handling replication correctly.
In this setup, the specs of the main database setup should not have to be changed because the impact should be
minimal.

{{< /alert >}}

A reputable provider or solution should be used for this. [Google Cloud SQL](https://cloud.google.com/sql/docs/postgres/high-availability#normal)
and [Amazon RDS](https://aws.amazon.com/rds/) are known to work. However, Amazon Aurora is **incompatible** with load balancing enabled by default from
[14.4.0](https://archives.docs.gitlab.com/17.3/ee/update/versions/gitlab_14_changes/#1440).

Once the database is set up, follow the [post configuration](#praefect-postgresql-post-configuration).

#### Praefect PostgreSQL post-configuration

After the Praefect PostgreSQL server has been set up, you must configure the user and database for Praefect to use.

We recommend the user be named `praefect` and the database `praefect_production`, and these can be configured as standard in PostgreSQL.
The password for the user is the same as the one you configured earlier as `<praefect_postgresql_password>`.

This is how this would work with a Linux package PostgreSQL setup:

1. SSH in to the Praefect PostgreSQL node.
1. Connect to the PostgreSQL server with administrative access.
   The `gitlab-psql` user should be used here for this as it's added by default in the Linux package.
   The database `template1` is used because it is created by default on all PostgreSQL servers.

   ```shell
   /opt/gitlab/embedded/bin/psql -U gitlab-psql -d template1 -h POSTGRESQL_SERVER_ADDRESS
   ```

1. Create the new user `praefect`, replacing `<praefect_postgresql_password>`:

   ```shell
   CREATE ROLE praefect WITH LOGIN CREATEDB PASSWORD '<praefect_postgresql_password>';
   ```

1. Reconnect to the PostgreSQL server, this time as the `praefect` user:

   ```shell
   /opt/gitlab/embedded/bin/psql -U praefect -d template1 -h POSTGRESQL_SERVER_ADDRESS
   ```

1. Create a new database `praefect_production`:

   ```shell
   CREATE DATABASE praefect_production WITH ENCODING=UTF8;
   ```

<div align="right">
  <a type="button" class="btn btn-default" href="#set-up-components">
    Back to set up components <i class="fa fa-angle-double-up" aria-hidden="true"></i>
  </a>
</div>

### Configure Praefect

Praefect is the router and transaction manager for Gitaly Cluster (Praefect) and all connections to Gitaly go through
it. This section details how to configure it.

{{< alert type="note" >}}

Praefect must be deployed in an odd number of 3 nodes or later. This is to ensure the nodes can take votes as part of a quorum.

{{< /alert >}}

Praefect requires several secret tokens to secure communications across the cluster:

- `<praefect_external_token>`: Used for repositories hosted on Gitaly Cluster (Praefect) and can only be accessed by Gitaly clients that carry this token.
- `<praefect_internal_token>`: Used for replication traffic inside Gitaly Cluster (Praefect). This is distinct from `praefect_external_token`
  because Gitaly clients must not be able to access internal nodes of the Gitaly Cluster (Praefect) directly; that could lead to data loss.
- `<praefect_postgresql_password>`: The Praefect PostgreSQL password defined in the previous section is also required as part of this setup.

Gitaly Cluster (Praefect) nodes are configured in Praefect via a `virtual storage`. Each storage contains
the details of each Gitaly node that makes up the cluster. Each storage is also given a name
and this name is used in several areas of the configuration. In this guide, the name of the storage will be
`default`. Also, this guide is geared towards new installs, if upgrading an existing environment
to use Gitaly Cluster (Praefect), you might have to use a different name.
Refer to the [Gitaly Cluster (Praefect) documentation](../gitaly/praefect/configure.md#praefect) for more information.

The following IPs will be used as an example:

- `10.6.0.131`: Praefect 1
- `10.6.0.132`: Praefect 2
- `10.6.0.133`: Praefect 3

To configure the Praefect nodes, on each one:

1. SSH in to the Praefect server.
1. [Download and install](../../install/package/_index.md#supported-platforms) the Linux
   package of your choice. Be sure to only add the GitLab package repository and install GitLab
   for your chosen operating system.
1. Edit the `/etc/gitlab/gitlab.rb` file to configure Praefect:

   {{< alert type="note" >}}

   You can't remove the `default` entry from `virtual_storages` because [GitLab requires it](../gitaly/configure_gitaly.md#gitlab-requires-a-default-repository-storage).

   {{< /alert >}}

   <!--
   Updates to example must be made at:
   - https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/administration/gitaly/praefect/_index.md
   - all reference architecture pages
   -->

   ```ruby
   # Avoid running unnecessary services on the Praefect server
   gitaly['enable'] = false
   postgresql['enable'] = false
   redis['enable'] = false
   nginx['enable'] = false
   puma['enable'] = false
   sidekiq['enable'] = false
   gitlab_workhorse['enable'] = false
   prometheus['enable'] = false
   alertmanager['enable'] = false
   gitlab_exporter['enable'] = false
   gitlab_kas['enable'] = false

   # Praefect Configuration
   praefect['enable'] = true

   # Prevent database migrations from running on upgrade automatically
   praefect['auto_migrate'] = false
   gitlab_rails['auto_migrate'] = false

   # Configure the Consul agent
   consul['enable'] = true
   ## Enable service discovery for Prometheus
   consul['monitoring_service_discovery'] = true

   # START user configuration
   # Please set the real values as explained in Required Information section
   #

   praefect['configuration'] = {
      # ...
      listen_addr: '0.0.0.0:2305',
      auth: {
         # ...
         #
         # Praefect External Token
         # This is needed by clients outside the cluster (like GitLab Shell) to communicate with the Praefect cluster
         token: '<praefect_external_token>',
      },
      # Praefect Database Settings
      database: {
         # ...
         host: '10.6.0.141',
         port: 5432,
         dbname: 'praefect_production',
         user: 'praefect',
         password: '<praefect_postgresql_password>',
      },
      # Praefect Virtual Storage config
      # Name of storage hash must match storage name in gitlab_rails['repositories_storages'] on GitLab
      # server ('praefect') and in gitaly['configuration'][:storage] on Gitaly nodes ('gitaly-1')
      virtual_storage: [
         {
            # ...
            name: 'default',
            node: [
               {
                  storage: 'gitaly-1',
                  address: 'tcp://10.6.0.91:8075',
                  token: '<praefect_internal_token>'
               },
               {
                  storage: 'gitaly-2',
                  address: 'tcp://10.6.0.92:8075',
                  token: '<praefect_internal_token>'
               },
               {
                  storage: 'gitaly-3',
                  address: 'tcp://10.6.0.93:8075',
                  token: '<praefect_internal_token>'
               },
            ],
         },
      ],
      # Set the network address Praefect will listen on for monitoring
      prometheus_listen_addr: '0.0.0.0:9652',
   }

   # Set the network address the node exporter will listen on for monitoring
   node_exporter['listen_address'] = '0.0.0.0:9100'

   ## The IPs of the Consul server nodes
   ## You can also use FQDNs and intermix them with IPs
   consul['configuration'] = {
      retry_join: %w(10.6.0.11 10.6.0.12 10.6.0.13),
   }
   #
   # END user configuration
   ```

1. Copy the `/etc/gitlab/gitlab-secrets.json` file from the first Linux package node you configured and add or replace
   the file of the same name on this server. If this is the first Linux package node you are configuring then you can skip this step.

1. Praefect requires to run some database migrations, much like the main GitLab application. For this
   you should select **one Praefect node only to run the migrations**, AKA the _Deploy Node_. This node
   must be configured first before the others as follows:

   1. In the `/etc/gitlab/gitlab.rb` file, change the `praefect['auto_migrate']` setting value from `false` to `true`

   1. To ensure database migrations are only run during reconfigure and not automatically on upgrade, run:

   ```shell
   sudo touch /etc/gitlab/skip-auto-reconfigure
   ```

   1. [Reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) for the changes to take effect and
      to run the Praefect database migrations.

1. On all other Praefect nodes, [reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) for the changes to take effect.

### Configure Gitaly

The [Gitaly](../gitaly/_index.md) server nodes that make up the cluster have
requirements that are dependent on data and load.

{{< alert type="warning" >}}

**Gitaly specifications are based on high percentiles of both usage patterns and repository sizes in good health**.
**However, if you have [large monorepos](_index.md#large-monorepos) (larger than several gigabytes) or [additional workloads](_index.md#additional-workloads) these can significantly impact the performance of the environment and further adjustments may be required**.
If you believe this applies to you, contact us for additional guidance as required.

{{< /alert >}}

Gitaly has certain [disk requirements](../gitaly/_index.md#disk-requirements) for Gitaly storages.

Gitaly servers must not be exposed to the public internet because network traffic
on Gitaly is unencrypted by default. The use of a firewall is highly recommended
to restrict access to the Gitaly server. Another option is to
[use TLS](#gitaly-cluster-praefect-tls-support).

For configuring Gitaly you should note the following:

- `gitaly['configuration'][:storage]` should be configured to reflect the storage path for the specific Gitaly node
- `auth_token` should be the same as `praefect_internal_token`

The following IPs will be used as an example:

- `10.6.0.91`: Gitaly 1
- `10.6.0.92`: Gitaly 2
- `10.6.0.93`: Gitaly 3

On each node:

1. [Download and install](../../install/package/_index.md#supported-platforms) the Linux
   package of your choice. Be sure to only add the GitLab
   package repository and install GitLab for your chosen operating system,
   but do **not** provide the `EXTERNAL_URL` value.
1. Edit the Gitaly server node's `/etc/gitlab/gitlab.rb` file to configure
   storage paths, enable the network listener, and to configure the token:

   <!--
   Updates to example must be made at:
   - https://gitlab.com/gitlab-org/charts/gitlab/blob/master/doc/advanced/external-gitaly/external-omnibus-gitaly.md#configure-omnibus-gitlab
   - https://gitlab.com/gitlab-org/gitlab/blob/master/doc/administration/gitaly/index.md#gitaly-server-configuration
   - all reference architecture pages
   -->

   ```ruby
   # https://docs.gitlab.com/omnibus/roles/#gitaly-roles
   roles(["gitaly_role"])

   # Prevent database migrations from running on upgrade automatically
   gitlab_rails['auto_migrate'] = false

   # Configure the gitlab-shell API callback URL. Without this, `git push` will
   # fail. This can be your 'front door' GitLab URL or an internal load
   # balancer.
   gitlab_rails['internal_api_url'] = 'https://gitlab.example.com'

   # Configure the Consul agent
   consul['enable'] = true
   ## Enable service discovery for Prometheus
   consul['monitoring_service_discovery'] = true

   # START user configuration
   # Please set the real values as explained in Required Information section
   #
   ## The IPs of the Consul server nodes
   ## You can also use FQDNs and intermix them with IPs
   consul['configuration'] = {
      retry_join: %w(10.6.0.11 10.6.0.12 10.6.0.13),
   }

   # Set the network address that the node exporter will listen on for monitoring
   node_exporter['listen_address'] = '0.0.0.0:9100'

   gitaly['configuration'] = {
      # Make Gitaly accept connections on all network interfaces. You must use
      # firewalls to restrict access to this address/port.
      # Comment out following line if you only want to support TLS connections
      listen_addr: '0.0.0.0:8075',
      # Set the network address that Gitaly will listen on for monitoring
      prometheus_listen_addr: '0.0.0.0:9236',
      auth: {
         # Gitaly Auth Token
         # Should be the same as praefect_internal_token
         token: '<praefect_internal_token>',
      },
      pack_objects_cache: {
         # Gitaly Pack-objects cache
         # Recommended to be enabled for improved performance but can notably increase disk I/O
         # Refer to https://docs.gitlab.com/ee/administration/gitaly/configure_gitaly.html#pack-objects-cache for more info
         enabled: true,
      },
   }

   #
   # END user configuration
   ```

1. Append the following to `/etc/gitlab/gitlab.rb` for each respective server:
   - On Gitaly node 1:

     ```ruby
     gitaly['configuration'] = {
        # ...
        storage: [
           {
              name: 'gitaly-1',
              path: '/var/opt/gitlab/git-data',
           },
        ],
     }
     ```

   - On Gitaly node 2:

     ```ruby
     gitaly['configuration'] = {
        # ...
        storage: [
           {
              name: 'gitaly-2',
              path: '/var/opt/gitlab/git-data',
           },
        ],
     }
     ```

   - On Gitaly node 3:

     ```ruby
     gitaly['configuration'] = {
        # ...
        storage: [
           {
              name: 'gitaly-3',
              path: '/var/opt/gitlab/git-data',
           },
        ],
     }
     ```

1. Copy the `/etc/gitlab/gitlab-secrets.json` file from the first Linux package node you configured and add or replace
   the file of the same name on this server. If this is the first Linux package node you are configuring then you can skip this step.

1. Save the file, and then [reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation).

### Gitaly Cluster (Praefect) TLS support

Praefect supports TLS encryption. To communicate with a Praefect instance that listens
for secure connections, you must:

- Use a `tls://` URL scheme in the `gitaly_address` of the corresponding storage entry
  in the GitLab configuration.
- Bring your own certificates because this isn't provided automatically. The certificate
  corresponding to each Praefect server must be installed on that Praefect server.

Additionally the certificate, or its certificate authority, must be installed on all Gitaly servers
and on all Praefect clients that communicate with it following the procedure described in
[GitLab custom certificate configuration](https://docs.gitlab.com/omnibus/settings/ssl/#install-custom-public-certificates) (and repeated below).

Note the following:

- The certificate must specify the address you use to access the Praefect server. You must add the hostname or IP
  address as a Subject Alternative Name to the certificate.
- You can configure Praefect servers with both an unencrypted listening address
  `listen_addr` and an encrypted listening address `tls_listen_addr` at the same time.
  This allows you to do a gradual transition from unencrypted to encrypted traffic, if
  necessary. To disable the unencrypted listener, set `praefect['configuration'][:listen_addr] = nil`.
- The Internal Load Balancer will also access to the certificates and must be configured
  to allow for TLS passthrough.
  Refer to the load balancers documentation on how to configure this.

To configure Praefect with TLS:

1. Create certificates for Praefect servers.

1. On the Praefect servers, create the `/etc/gitlab/ssl` directory and copy your key
   and certificate there:

   ```shell
   sudo mkdir -p /etc/gitlab/ssl
   sudo chmod 755 /etc/gitlab/ssl
   sudo cp key.pem cert.pem /etc/gitlab/ssl/
   sudo chmod 644 key.pem cert.pem
   ```

1. Edit `/etc/gitlab/gitlab.rb` and add:

   ```ruby
   praefect['configuration'] = {
      # ...
      tls_listen_addr: '0.0.0.0:3305',
      tls: {
         # ...
         certificate_path: '/etc/gitlab/ssl/cert.pem',
         key_path: '/etc/gitlab/ssl/key.pem',
      },
   }
   ```

1. Save the file and [reconfigure](../restart_gitlab.md#reconfigure-a-linux-package-installation).

1. On the Praefect clients (including each Gitaly server), copy the certificates,
   or their certificate authority, into `/etc/gitlab/trusted-certs`:

   ```shell
   sudo cp cert.pem /etc/gitlab/trusted-certs/
   ```

1. On the Praefect clients (except Gitaly servers), edit `gitlab_rails['repositories_storages']` in
   `/etc/gitlab/gitlab.rb` as follows:

   ```ruby
   gitlab_rails['repositories_storages'] = {
     "default" => {
       "gitaly_address" => 'tls://LOAD_BALANCER_SERVER_ADDRESS:3305',
       "gitaly_token" => 'PRAEFECT_EXTERNAL_TOKEN'
     }
   }
   ```

1. Save the file and [reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation).

<div align="right">
  <a type="button" class="btn btn-default" href="#set-up-components">
    Back to set up components <i class="fa fa-angle-double-up" aria-hidden="true"></i>
  </a>
</div>

## Configure Sidekiq

Sidekiq requires connection to the [Redis](#configure-redis),
[PostgreSQL](#configure-postgresql) and [Gitaly](#configure-gitaly) instances.
It also requires a connection to [Object Storage](#configure-the-object-storage) as recommended.

{{< alert type="note" >}}

[Because it's recommended to use Object storage](../object_storage.md) instead of NFS for data objects, the following
examples include the Object storage configuration.

{{< /alert >}}

{{< alert type="note" >}}

If you find that the environment's Sidekiq job processing is slow with long queues
you can scale it accordingly.
Refer to the [scaling documentation](_index.md#scaling-an-environment) for more information.
{{< /alert >}}

{{< alert type="note" >}}

When configuring additional GitLab functionality such as Container Registry, SAML, or LDAP,
update the Sidekiq configuration in addition to the Rails configuration.
Refer to the [external Sidekiq documentation](../sidekiq/_index.md) for more information.
{{< /alert >}}

- `10.6.0.101`: Sidekiq 1
- `10.6.0.102`: Sidekiq 2
- `10.6.0.103`: Sidekiq 3
- `10.6.0.104`: Sidekiq 4

To configure the Sidekiq nodes, on each one:

1. SSH in to the Sidekiq server.
1. Confirm that you can access the PostgreSQL, Gitaly, and Redis ports:

   ```shell
   telnet <GitLab host> 5432 # PostgreSQL
   telnet <GitLab host> 8075 # Gitaly
   telnet <GitLab host> 6379 # Redis
   ```

1. [Download and install](../../install/package/_index.md#supported-platforms) the Linux
   package of your choice. Be sure to only add the GitLab package repository and install GitLab
   for your chosen operating system.
1. Create or edit `/etc/gitlab/gitlab.rb` and use the following configuration:

   ```ruby
   # https://docs.gitlab.com/omnibus/roles/#sidekiq-roles
   roles(["sidekiq_role"])

   # External URL
   ## This should match the URL of the external load balancer
   external_url 'https://gitlab.example.com'

   # Redis
   ## Redis connection details
   ## First cluster that will host the cache data
   gitlab_rails['redis_cache_instance'] = 'redis://:<REDIS_PRIMARY_PASSWORD_OF_FIRST_CLUSTER>@gitlab-redis-cache'

   gitlab_rails['redis_cache_sentinels'] = [
     {host: '10.6.0.51', port: 26379},
     {host: '10.6.0.52', port: 26379},
     {host: '10.6.0.53', port: 26379},
   ]

   ## Second cluster that hosts all other persistent data
   redis['master_name'] = 'gitlab-redis-persistent'
   redis['master_password'] = '<REDIS_PRIMARY_PASSWORD_OF_SECOND_CLUSTER>'

   gitlab_rails['redis_sentinels'] = [
     {host: '10.6.0.61', port: 26379},
     {host: '10.6.0.62', port: 26379},
     {host: '10.6.0.63', port: 26379},
   ]

   # Gitaly
   # gitlab_rails['repositories_storages'] gets configured for the Praefect virtual storage
   # Address is Internal Load Balancer for Praefect
   # Token is praefect_external_token
   gitlab_rails['repositories_storages'] = {
     "default" => {
       "gitaly_address" => "tcp://10.6.0.40:2305", # internal load balancer IP
       "gitaly_token" => '<praefect_external_token>'
     }
   }

   # PostgreSQL
   gitlab_rails['db_host'] = '10.6.0.20' # internal load balancer IP
   gitlab_rails['db_port'] = 6432
   gitlab_rails['db_password'] = '<postgresql_user_password>'
   gitlab_rails['db_load_balancing'] = { 'hosts' => ['10.6.0.21', '10.6.0.22', '10.6.0.23'] } # PostgreSQL IPs

   ## Prevent database migrations from running on upgrade automatically
   gitlab_rails['auto_migrate'] = false

   # Sidekiq
   sidekiq['listen_address'] = "0.0.0.0"

   ## Set number of Sidekiq queue processes to the same number as available CPUs
   sidekiq['queue_groups'] = ['*'] * 4

   # Monitoring
   consul['enable'] = true
   consul['monitoring_service_discovery'] =  true

   consul['configuration'] = {
      retry_join: %w(10.6.0.11 10.6.0.12 10.6.0.13)
   }

   # Set the network addresses that the exporters will listen on
   node_exporter['listen_address'] = '0.0.0.0:9100'

   ## Add the monitoring node's IP address to the monitoring whitelist
   gitlab_rails['monitoring_whitelist'] = ['10.6.0.151/32', '127.0.0.0/8']

   # Object storage
   ## This is an example for configuring Object Storage on GCP
   ## Replace this config with your chosen Object Storage provider as desired
   gitlab_rails['object_store']['enabled'] = true
   gitlab_rails['object_store']['connection'] = {
     'provider' => 'Google',
     'google_project' => '<gcp-project-name>',
     'google_json_key_location' => '<path-to-gcp-service-account-key>'
   }
   gitlab_rails['object_store']['objects']['artifacts']['bucket'] = "<gcp-artifacts-bucket-name>"
   gitlab_rails['object_store']['objects']['external_diffs']['bucket'] = "<gcp-external-diffs-bucket-name>"
   gitlab_rails['object_store']['objects']['lfs']['bucket'] = "<gcp-lfs-bucket-name>"
   gitlab_rails['object_store']['objects']['uploads']['bucket'] = "<gcp-uploads-bucket-name>"
   gitlab_rails['object_store']['objects']['packages']['bucket'] = "<gcp-packages-bucket-name>"
   gitlab_rails['object_store']['objects']['dependency_proxy']['bucket'] = "<gcp-dependency-proxy-bucket-name>"
   gitlab_rails['object_store']['objects']['terraform_state']['bucket'] = "<gcp-terraform-state-bucket-name>"

   gitlab_rails['backup_upload_connection'] = {
     'provider' => 'Google',
     'google_project' => '<gcp-project-name>',
     'google_json_key_location' => '<path-to-gcp-service-account-key>'
   }
   gitlab_rails['backup_upload_remote_directory'] = "<gcp-backups-state-bucket-name>"

   gitlab_rails['ci_secure_files_object_store_enabled'] = true
   gitlab_rails['ci_secure_files_object_store_remote_directory'] = "gcp-ci_secure_files-bucket-name"

   gitlab_rails['ci_secure_files_object_store_connection'] = {
      'provider' => 'Google',
      'google_project' => '<gcp-project-name>',
      'google_json_key_location' => '<path-to-gcp-service-account-key>'
   }
   ```

1. Copy the `/etc/gitlab/gitlab-secrets.json` file from the first Linux package node you configured and add or replace
   the file of the same name on this server. If this is the first Linux package node you are configuring then you can skip this step.
1. Copy the SSH host keys (all in the name format `/etc/ssh/ssh_host_*_key*`) from the first Rails node you configured and
   add or replace the files of the same name on this server. This ensures host mismatch errors aren't thrown
   for your users as they hit the load balanced Rails nodes. If this is the first Linux package node you are configuring,
   then you can skip this step.
1. To ensure database migrations are only run during reconfigure and not automatically on upgrade, run:

   ```shell
   sudo touch /etc/gitlab/skip-auto-reconfigure
   ```

   Only a single designated node should handle migrations as detailed in the
   [GitLab Rails post-configuration](#gitlab-rails-post-configuration) section.

1. [Reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) for the changes to take effect.

<div align="right">
  <a type="button" class="btn btn-default" href="#set-up-components">
    Back to set up components <i class="fa fa-angle-double-up" aria-hidden="true"></i>
  </a>
</div>

## Configure GitLab Rails

This section describes how to configure the GitLab application (Rails) component.

Rails requires connections to the [Redis](#configure-redis),
[PostgreSQL](#configure-postgresql) and [Gitaly](#configure-gitaly) instances.
It also requires a connection to [Object Storage](#configure-the-object-storage) as recommended.

{{< alert type="note" >}}

[Because it's recommended to use Object storage](../object_storage.md) instead of NFS for data objects, the following
examples include the Object storage configuration.

{{< /alert >}}

The following IPs will be used as an example:

- `10.6.0.111`: GitLab application 1
- `10.6.0.112`: GitLab application 2
- `10.6.0.113`: GitLab application 3
- `10.6.0.114`: GitLab application 4
- `10.6.0.115`: GitLab application 5
- `10.6.0.116`: GitLab application 6
- `10.6.0.117`: GitLab application 7
- `10.6.0.118`: GitLab application 8
- `10.6.0.119`: GitLab application 9
- `10.6.0.120`: GitLab application 10
- `10.6.0.121`: GitLab application 11
- `10.6.0.122`: GitLab application 12

On each node perform the following:

1. [Download and install](../../install/package/_index.md#supported-platforms) the Linux
   package of your choice. Be sure to only add the GitLab package repository and install GitLab
   for your chosen operating system.

1. Edit `/etc/gitlab/gitlab.rb` and use the following configuration.
   To maintain uniformity of links across nodes, the `external_url`
   on the application server should point to the external URL that users will use
   to access GitLab. This would be the URL of the [external load balancer](#configure-the-external-load-balancer)
   which will route traffic to the GitLab application server:

   ```ruby
   external_url 'https://gitlab.example.com'

   # gitlab_rails['repositories_storages'] gets configured for the Praefect virtual storage
   # Address is Internal Load Balancer for Praefect
   # Token is praefect_external_token
   gitlab_rails['repositories_storages'] = {
     "default" => {
       "gitaly_address" => "tcp://10.6.0.40:2305", # internal load balancer IP
       "gitaly_token" => '<praefect_external_token>'
     }
   }

   ## Disable components that will not be on the GitLab application server
   roles(['application_role'])
   gitaly['enable'] = false
   sidekiq['enable'] = false

   ## PostgreSQL connection details
   # Disable PostgreSQL on the application node
   postgresql['enable'] = false
   gitlab_rails['db_host'] = '10.6.0.20' # internal load balancer IP
   gitlab_rails['db_port'] = 6432
   gitlab_rails['db_password'] = '<postgresql_user_password>'
   gitlab_rails['db_load_balancing'] = { 'hosts' => ['10.6.0.21', '10.6.0.22', '10.6.0.23'] } # PostgreSQL IPs

   # Prevent database migrations from running on upgrade automatically
   gitlab_rails['auto_migrate'] = false

   ## Redis connection details
   ## First cluster that will host the cache data
   gitlab_rails['redis_cache_instance'] = 'redis://:<REDIS_PRIMARY_PASSWORD_OF_FIRST_CLUSTER>@gitlab-redis-cache'

   gitlab_rails['redis_cache_sentinels'] = [
     {host: '10.6.0.51', port: 26379},
     {host: '10.6.0.52', port: 26379},
     {host: '10.6.0.53', port: 26379},
   ]

   ## Second cluster that hosts all other persistent data
   redis['master_name'] = 'gitlab-redis-persistent'
   redis['master_password'] = '<REDIS_PRIMARY_PASSWORD_OF_SECOND_CLUSTER>'

   gitlab_rails['redis_sentinels'] = [
     {host: '10.6.0.61', port: 26379},
     {host: '10.6.0.62', port: 26379},
     {host: '10.6.0.63', port: 26379},
   ]

   # Set the network addresses that the exporters used for monitoring will listen on
   node_exporter['listen_address'] = '0.0.0.0:9100'
   gitlab_workhorse['prometheus_listen_addr'] = '0.0.0.0:9229'
   puma['listen'] = '0.0.0.0'

   # Add the monitoring node's IP address to the monitoring whitelist and allow it to
   # scrape the NGINX metrics
   gitlab_rails['monitoring_whitelist'] = ['10.6.0.151/32', '127.0.0.0/8']
   nginx['status']['options']['allow'] = ['10.6.0.151/32', '127.0.0.0/8']

   #############################
   ###     Object storage    ###
   #############################

   # This is an example for configuring Object Storage on GCP
   # Replace this config with your chosen Object Storage provider as desired
   gitlab_rails['object_store']['enabled'] = true
   gitlab_rails['object_store']['connection'] = {
     'provider' => 'Google',
     'google_project' => '<gcp-project-name>',
     'google_json_key_location' => '<path-to-gcp-service-account-key>'
   }
   gitlab_rails['object_store']['objects']['artifacts']['bucket'] = "<gcp-artifacts-bucket-name>"
   gitlab_rails['object_store']['objects']['external_diffs']['bucket'] = "<gcp-external-diffs-bucket-name>"
   gitlab_rails['object_store']['objects']['lfs']['bucket'] = "<gcp-lfs-bucket-name>"
   gitlab_rails['object_store']['objects']['uploads']['bucket'] = "<gcp-uploads-bucket-name>"
   gitlab_rails['object_store']['objects']['packages']['bucket'] = "<gcp-packages-bucket-name>"
   gitlab_rails['object_store']['objects']['dependency_proxy']['bucket'] = "<gcp-dependency-proxy-bucket-name>"
   gitlab_rails['object_store']['objects']['terraform_state']['bucket'] = "<gcp-terraform-state-bucket-name>"

   gitlab_rails['backup_upload_connection'] = {
     'provider' => 'Google',
     'google_project' => '<gcp-project-name>',
     'google_json_key_location' => '<path-to-gcp-service-account-key>'
   }

   gitlab_rails['backup_upload_remote_directory'] = "<gcp-backups-state-bucket-name>"
   gitlab_rails['ci_secure_files_object_store_enabled'] = true
   gitlab_rails['ci_secure_files_object_store_remote_directory'] = "gcp-ci_secure_files-bucket-name"

   gitlab_rails['ci_secure_files_object_store_connection'] = {
      'provider' => 'Google',
      'google_project' => '<gcp-project-name>',
      'google_json_key_location' => '<path-to-gcp-service-account-key>'
   }
   ```

1. If you're using [Gitaly with TLS support](#gitaly-cluster-praefect-tls-support), make sure the
   `gitlab_rails['repositories_storages']` entry is configured with `tls` instead of `tcp`:

   ```ruby
   gitlab_rails['repositories_storages'] = {
     "default" => {
       "gitaly_address" => "tls://10.6.0.40:2305", # internal load balancer IP
       "gitaly_token" => '<praefect_external_token>'
     }
   }
   ```

   1. Copy the cert into `/etc/gitlab/trusted-certs`:

      ```shell
      sudo cp cert.pem /etc/gitlab/trusted-certs/
      ```

1. Copy the `/etc/gitlab/gitlab-secrets.json` file from the first Linux package node you configured and add or replace
   the file of the same name on this server. If this is the first Linux package node you are configuring then you can skip this step.
1. To ensure database migrations are only run during reconfigure and not automatically on upgrade, run:

   ```shell
   sudo touch /etc/gitlab/skip-auto-reconfigure
   ```

   Only a single designated node should handle migrations as detailed in the
   [GitLab Rails post-configuration](#gitlab-rails-post-configuration) section.

1. [Reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) for the changes to take effect.
1. [Enable incremental logging](#enable-incremental-logging).
1. Confirm the node can connect to Gitaly:

   ```shell
   sudo gitlab-rake gitlab:gitaly:check
   ```

   Then, tail the logs to see the requests:

   ```shell
   sudo gitlab-ctl tail gitaly
   ```

1. Optionally, from the Gitaly servers, confirm that Gitaly can perform callbacks to the internal API:
   - For GitLab 15.3 and later, run `sudo -u git -- /opt/gitlab/embedded/bin/gitaly check /var/opt/gitlab/gitaly/config.toml`.
   - For GitLab 15.2 and earlier, run `sudo -u git -- /opt/gitlab/embedded/bin/gitaly-hooks check /var/opt/gitlab/gitaly/config.toml`.

When you specify `https` in the `external_url`, as in the previous example,
GitLab expects that the SSL certificates are in `/etc/gitlab/ssl/`. If the
certificates aren't present, NGINX will fail to start. For more information, see
the [HTTPS documentation](https://docs.gitlab.com/omnibus/settings/ssl/).

### GitLab Rails post-configuration

1. Designate one application node for running database migrations during
   installation and updates. Initialize the GitLab database and ensure all
   migrations ran:

   ```shell
   sudo gitlab-rake gitlab:db:configure
   ```

   This operation requires configuring the Rails node to connect to the primary database
   directly, [bypassing PgBouncer](../postgresql/pgbouncer.md#procedure-for-bypassing-pgbouncer).
   After migrations have completed, you must configure the node to pass through PgBouncer again.

1. [Configure fast lookup of authorized SSH keys in the database](../operations/fast_ssh_key_lookup.md).

<div align="right">
  <a type="button" class="btn btn-default" href="#set-up-components">
    Back to set up components <i class="fa fa-angle-double-up" aria-hidden="true"></i>
  </a>
</div>

## Configure Prometheus

The Linux package can be used to configure a standalone Monitoring node
running [Prometheus](../monitoring/prometheus/_index.md).

The following IP will be used as an example:

- `10.6.0.151`: Prometheus

To configure the Monitoring node:

1. SSH in to the Monitoring node.
1. [Download and install](../../install/package/_index.md#supported-platforms) the Linux
   package of your choice. Be sure to only add the GitLab package repository and install GitLab
   for your chosen operating system.

1. Edit `/etc/gitlab/gitlab.rb` and add the contents:

   ```ruby
   roles(['monitoring_role', 'consul_role'])

   external_url 'http://gitlab.example.com'

   # Prometheus
   prometheus['listen_address'] = '0.0.0.0:9090'
   prometheus['monitor_kubernetes'] = false

   # Enable service discovery for Prometheus
   consul['monitoring_service_discovery'] =  true
   consul['configuration'] = {
      retry_join: %w(10.6.0.11 10.6.0.12 10.6.0.13)
   }

   # Configure Prometheus to scrape services not covered by discovery
   prometheus['scrape_configs'] = [
      {
         'job_name': 'pgbouncer',
         'static_configs' => [
            'targets' => [
            "10.6.0.31:9188",
            "10.6.0.32:9188",
            "10.6.0.33:9188",
            ],
         ],
      },
      {
         'job_name': 'praefect',
         'static_configs' => [
            'targets' => [
            "10.6.0.131:9652",
            "10.6.0.132:9652",
            "10.6.0.133:9652",
            ],
         ],
      },
   ]

   nginx['enable'] = false
   ```

1. Save the file and [reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation).

<div align="right">
  <a type="button" class="btn btn-default" href="#set-up-components">
    Back to set up components <i class="fa fa-angle-double-up" aria-hidden="true"></i>
  </a>
</div>

## Configure the object storage

GitLab supports using an [object storage](../object_storage.md) service for holding numerous types of data.
It's recommended over [NFS](../nfs.md) for data objects and in general it's better
in larger setups as object storage is typically much more performant, reliable,
and scalable. See [Recommended cloud providers and services](_index.md#recommended-cloud-providers-and-services) for more information.

There are two ways of specifying object storage configuration in GitLab:

- [Consolidated form](../object_storage.md#configure-a-single-storage-connection-for-all-object-types-consolidated-form): A single credential is
  shared by all supported object types.
- [Storage-specific form](../object_storage.md#configure-each-object-type-to-define-its-own-storage-connection-storage-specific-form): Every object defines its
  own object storage [connection and configuration](../object_storage.md#configure-the-connection-settings).

The consolidated form is used in the following examples when available.

Using separate buckets for each data type is the recommended approach for GitLab.
This ensures there are no collisions across the various types of data GitLab stores.
There are plans to [enable the use of a single bucket](https://gitlab.com/gitlab-org/gitlab/-/issues/292958)
in the future.

<div align="right">
  <a type="button" class="btn btn-default" href="#set-up-components">
    Back to set up components <i class="fa fa-angle-double-up" aria-hidden="true"></i>
  </a>
</div>

### Enable incremental logging

GitLab Runner returns job logs in chunks which the Linux package caches temporarily on disk in `/var/opt/gitlab/gitlab-ci/builds` by default, even when using consolidated object storage. With default configuration, this directory needs to be shared through NFS on any GitLab Rails and Sidekiq nodes.

While sharing the job logs through NFS is supported, avoid the requirement to use NFS by enabling [incremental logging](../cicd/job_logs.md#incremental-logging) (required when no NFS node has been deployed). Incremental logging uses Redis instead of disk space for temporary caching of job logs.

## Configure advanced search

You can leverage Elasticsearch and [enable advanced search](../../integration/advanced_search/elasticsearch.md)
for faster, more advanced code search across your entire GitLab instance.

Elasticsearch cluster design and requirements are dependent on your specific
data. For recommended best practices about how to set up your Elasticsearch
cluster alongside your instance, read how to
[choose the optimal cluster configuration](../../integration/advanced_search/elasticsearch.md#guidance-on-choosing-optimal-cluster-configuration).

<div align="right">
  <a type="button" class="btn btn-default" href="#set-up-components">
    Back to set up components <i class="fa fa-angle-double-up" aria-hidden="true"></i>
  </a>
</div>

## Cloud Native Hybrid reference architecture with Helm Charts (alternative)

An alternative approach is to run specific GitLab components in Kubernetes.
The following services are supported:

- GitLab Rails
- Sidekiq
- NGINX
- Toolbox
- Migrations
- Prometheus

Hybrid installations leverage the benefits of both cloud native and traditional
compute deployments. With this, stateless components can benefit from cloud native
workload management benefits while stateful components are deployed in compute VMs
with Linux package installations to benefit from increased permanence.

Refer to the Helm charts [Advanced configuration](https://docs.gitlab.com/charts/advanced/)
documentation for setup instructions including guidance on what GitLab secrets to sync
between Kubernetes and the backend components.

{{< alert type="note" >}}

This is an **advanced** setup. Running services in Kubernetes is well known
to be complex. **This setup is only recommended** if you have strong working
knowledge and experience in Kubernetes. The rest of this
section assumes this.

{{< /alert >}}

{{< alert type="warning" >}}

**Gitaly Cluster (Praefect) is not supported to be run in Kubernetes**.
Refer to [epic 6127](https://gitlab.com/groups/gitlab-org/-/epics/6127) for more details.

{{< /alert >}}

### Cluster topology

The following tables and diagram detail the hybrid environment using the same formats
as the typical environment documented previously.

First are the components that run in Kubernetes. These run across several node groups, although you can change
the overall makeup as desired as long as the minimum CPU and Memory requirements are observed.

| Component Node Group | Target Node Pool Totals | GCP Example     | AWS Example  |
|----------------------|-------------------------|-----------------|--------------|
| Webservice           | 308 vCPU<br/>385 GB memory (request)<br/>539 GB memory (limit) | 11 x `n1-standard-32` | 11 x `c5.9xlarge` |
| Sidekiq              | 12.6 vCPU<br/>28 GB memory (request)<br/>56 GB memory (limit) | 4 x `n1-standard-4` | 4 x `m5.xlarge`  |
| Supporting services  | 8 vCPU<br/>30 GB memory | 2 x `n1-standard-4` | 2 x `m5.xlarge`   |

- For this setup, we regularly [test](_index.md#validation-and-test-results) and recommended [Google Kubernetes Engine (GKE)](https://cloud.google.com/kubernetes-engine) and [Amazon Elastic Kubernetes Service (EKS)](https://aws.amazon.com/eks/). Other Kubernetes services may also work, but your mileage may vary.
- Machine type examples are given for illustration purposes. These types are used in [validation and testing](_index.md#validation-and-test-results) but are not intended as prescriptive defaults. Switching to other machine types that meet the requirements as listed is supported. See [Supported Machine Types](_index.md#supported-machine-types) for more information.
- The [Webservice](#webservice) and [Sidekiq](#sidekiq) target node pool totals are given for GitLab components only. Additional resources are required for the chosen Kubernetes provider's system processes. The given examples take this into account.
- The [Supporting](#supporting) target node pool total is given generally to accommodate several resources for supporting the GitLab deployment as well as any additional deployments you may wish to make depending on your requirements. Similar to the other node pools, the chosen Kubernetes provider's system processes also require resources. The given examples take this into account.
- In production deployments, it's not required to assign pods to specific nodes. However, it is recommended to have several nodes in each pool spread across different availability zones to align with resilient cloud architecture practices.
- Enabling autoscaling, such as Cluster Autoscaler, for efficiency reasons is encouraged, but it's generally recommended targeting a floor of 75% for Webservice and Sidekiq pods to ensure ongoing performance.

Next are the backend components that run on static compute VMs using the Linux package (or External PaaS
services where applicable):

| Service                                  | Nodes | Configuration          | GCP example<sup>1</sup> | AWS example<sup>1</sup> |
|------------------------------------------|-------|------------------------|------------------|---------------|
| Consul<sup>2</sup>                       | 3     | 2 vCPU, 1.8 GB memory  | `n1-highcpu-2`   | `c5.large`    |
| PostgreSQL<sup>2</sup>                   | 3     | 32 vCPU, 120 GB memory | `n1-standard-32` | `m5.8xlarge`  |
| PgBouncer<sup>2</sup>                    | 3     | 2 vCPU, 1.8 GB memory  | `n1-highcpu-2`   | `c5.large`    |
| Internal load balancer<sup>4</sup>       | 1     | 16 vCPU, 14.4 GB memory | `n1-highcpu-16` | `c5.4xlarge`  |
| Redis/Sentinel - Cache<sup>3</sup>       | 3     | 4 vCPU, 15 GB memory   | `n1-standard-4`  | `m5.xlarge`   |
| Redis/Sentinel - Persistent<sup>3</sup>  | 3     | 4 vCPU, 15 GB memory   | `n1-standard-4`  | `m5.xlarge`   |
| Gitaly<sup>6</sup><sup>7</sup>           | 3     | 64 vCPU, 240 GB memory | `n1-standard-64` | `m5.16xlarge` |
| Praefect<sup>6</sup>                     | 3     | 4 vCPU, 3.6 GB memory  | `n1-highcpu-4`   | `c5.xlarge`   |
| Praefect PostgreSQL<sup>2</sup>          | 1+    | 2 vCPU, 1.8 GB memory  | `n1-highcpu-2`   | `c5.large`    |
| Object storage<sup>5</sup>               | -     | -                      | -                | -             |

**Footnotes**:

<!-- Disable ordered list rule https://github.com/DavidAnson/markdownlint/blob/main/doc/Rules.md#md029---ordered-list-item-prefix -->
<!-- markdownlint-disable MD029 -->
1. Machine type examples are given for illustration purposes. These types are used in [validation and testing](_index.md#validation-and-test-results) but are not intended as prescriptive defaults. Switching to other machine types that meet the requirements as listed is supported, including ARM variants if available. See [Supported Machine Types](_index.md#supported-machine-types) for more information.
2. Can be optionally run on reputable third-party external PaaS PostgreSQL solutions. See [Provide your own PostgreSQL instance](#provide-your-own-postgresql-instance) for more information.
3. Can be optionally run on reputable third-party external PaaS Redis solutions. See [Provide your own Redis instances](#provide-your-own-redis-instances) for more information.
    - Redis is primarily single threaded and doesn't significantly benefit from an increase in CPU cores. For this size of architecture it's strongly recommended having separate Cache and Persistent instances as specified to achieve optimum performance.
4. Can be optionally run on reputable third-party load balancing services (LB PaaS). See [Recommended cloud providers and services](_index.md#recommended-cloud-providers-and-services) for more information.
5. Should be run on reputable Cloud Provider or Self Managed solutions. See [Configure the object storage](#configure-the-object-storage) for more information.
6. Gitaly Cluster (Praefect) provides the benefits of fault tolerance, but comes with additional complexity of setup and management.
   Review the existing [technical limitations and considerations before deploying Gitaly Cluster (Praefect)](../gitaly/praefect/_index.md#before-deploying-gitaly-cluster-praefect). If you want sharded Gitaly, use the same specs listed in the previous table for `Gitaly`.
7. Gitaly specifications are based on high percentiles of both usage patterns and repository sizes in good health.
   However, if you have [large monorepos](_index.md#large-monorepos) (larger than several gigabytes) or [additional workloads](_index.md#additional-workloads) these can significantly impact Git and Gitaly performance and further adjustments will likely be required.
<!-- markdownlint-enable MD029 -->

{{< alert type="note" >}}

For all PaaS solutions that involve configuring instances, it's recommended to implement a minimum of three nodes in three different availability zones to align with resilient cloud architecture practices.

{{< /alert >}}

```plantuml
@startuml 50k
skinparam linetype ortho

card "Kubernetes via Helm Charts" as kubernetes {
  card "**External Load Balancer**" as elb #6a9be7

  together {
    collections "**Webservice**" as gitlab #32CD32
    collections "**Sidekiq**" as sidekiq #ff8dd1
  }

  card "**Supporting Services**" as support
}

card "**Internal Load Balancer**" as ilb #9370DB
collections "**Consul** x3" as consul #e76a9b

card "Gitaly Cluster" as gitaly_cluster {
  collections "**Praefect** x3" as praefect #FF8C00
  collections "**Gitaly** x3" as gitaly #FF8C00
  card "**Praefect PostgreSQL***\n//Non fault-tolerant//" as praefect_postgres #FF8C00

  praefect -[#FF8C00]-> gitaly
  praefect -[#FF8C00]> praefect_postgres
}

card "Database" as database {
  collections "**PGBouncer** x3" as pgbouncer #4EA7FF
  card "**PostgreSQL** (Primary)" as postgres_primary #4EA7FF
  collections "**PostgreSQL** (Secondary) x2" as postgres_secondary #4EA7FF

  pgbouncer -[#4EA7FF]-> postgres_primary
  postgres_primary .[#4EA7FF]> postgres_secondary
}

card "redis" as redis {
  collections "**Redis Persistent** x3" as redis_persistent #FF6347
  collections "**Redis Cache** x3" as redis_cache #FF6347

  redis_cache -[hidden]-> redis_persistent
}

cloud "**Object Storage**" as object_storage #white

elb -[#6a9be7]-> gitlab
elb -[hidden]-> sidekiq
elb -[hidden]-> support

gitlab -[#32CD32]--> ilb
gitlab -[#32CD32]r--> object_storage
gitlab -[#32CD32,norank]----> redis
gitlab -[#32CD32]----> database

sidekiq -[#ff8dd1]--> ilb
sidekiq -[#ff8dd1]r--> object_storage
sidekiq -[#ff8dd1,norank]----> redis
sidekiq .[#ff8dd1]----> database

ilb -[#9370DB]--> gitaly_cluster
ilb -[#9370DB]--> database
ilb -[hidden,norank]--> redis

consul .[#e76a9b]--> database
consul .[#e76a9b,norank]--> gitaly_cluster
consul .[#e76a9b]--> redis

@enduml
```

### Kubernetes component targets

The following section details the targets used for the GitLab components deployed in Kubernetes.

#### Webservice

Each Webservice pod (Puma and Workhorse) is recommended to be run with the following configuration:

- 4 Puma Workers
- 4 vCPU
- 5 GB memory (request)
- 7 GB memory (limit)

For 1000 RPS or 50,000 users we recommend a total Puma worker count of around 308 so in turn it's recommended to run at
least 77 Webservice pods.

For further information on Webservice resource usage, see the Charts documentation on [Webservice resources](https://docs.gitlab.com/charts/charts/gitlab/webservice/#resources).

##### NGINX

It's also recommended deploying the NGINX controller pods across the Webservice nodes as a DaemonSet. This is to allow the controllers to scale dynamically with the Webservice pods they serve and take advantage of the higher network bandwidth larger machine types typically have.

This isn't a strict requirement. The NGINX controller pods can be deployed as desired as long as they have enough resources to handle the web traffic.

#### Sidekiq

Each Sidekiq pod is recommended to be run with the following configuration:

- 1 Sidekiq worker
- 900m vCPU
- 2 GB memory (request)
- 4 GB memory (limit)

Similar to the standard deployment documented previously, an initial target of 14 Sidekiq workers has been used here.
Additional workers may be required depending on your specific workflow.

For further information on Sidekiq resource usage, see the Charts documentation on [Sidekiq resources](https://docs.gitlab.com/charts/charts/gitlab/sidekiq/#resources).

### Supporting

The Supporting Node Pool is designed to house all supporting deployments that are not required on the Webservice and Sidekiq pools.

These supporting deployments include various deployments related to the Cloud Provider's implementation and supporting
GitLab deployments such as [GitLab Shell](https://docs.gitlab.com/charts/charts/gitlab/gitlab-shell/).

To make any additional deployments such as Container Registry, Pages, or Monitoring, deploy these in the Supporting Node Pool where possible and not in the Webservice or Sidekiq pools. The Supporting Node Pool has been designed
to accommodate several additional deployments. However, if your deployments don't fit into the
pool as given, you can increase the node pool accordingly. Conversely, if the pool in your use case is over-provisioned you can reduce accordingly.

### Example config file

An example for the GitLab Helm Charts targeting the 1000 RPS or 50,000 users reference architecture configuration [can be found in the Charts project](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/examples/ref/50k.yaml).

<div align="right">
  <a type="button" class="btn btn-default" href="#set-up-components">
    Back to set up components <i class="fa fa-angle-double-up" aria-hidden="true"></i>
  </a>
</div>

## Next steps

After following this guide you should now have a fresh GitLab environment with core functionality configured accordingly.

You may want to configure additional optional features of GitLab depending on your requirements. See [Steps after installing GitLab](../../install/next_steps.md) for more information.

{{< alert type="note" >}}

Depending on your environment and requirements, additional hardware requirements or adjustments may be required to set up additional features as desired. Refer to the individual pages for more information.

{{< /alert >}}
