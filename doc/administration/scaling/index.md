---
type: reference, concepts
---

# Scaling

GitLab supports a number of scaling options to ensure that your self-managed
instance is able to scale out to meet your organization's needs when scaling up
a single-box GitLab installation is no longer practical or feasible.

Please consult our [high availability documentation](../high_availability/README.md)
if your organization requires fault tolerance and redundancy features, such as
automatic database system failover.

## GitLab components and scaling instructions

Here's a list of components directly provided by Omnibus GitLab or installed as
part of a source installation and their configuration instructions for scaling.

| Component | Description | Configuration instructions |
|-----------|-------------|----------------------------|
| [PostgreSQL](../../development/architecture.md#postgresql) | Database | [PostgreSQL configuration](https://docs.gitlab.com/omnibus/settings/database.html) |
| [Redis](../../development/architecture.md#redis)  | Key/value store for fast data lookup and caching | [Redis configuration](../high_availability/redis.md) |
| [GitLab application services](../../development/architecture.md#unicorn) | Unicorn/Puma, Workhorse, GitLab Shell - serves front-end requests (UI, API, Git over HTTP/SSH) | [GitLab app scaling configuration](../high_availability/gitlab.md) |
| [PgBouncer](../../development/architecture.md#pgbouncer) | Database connection pooler | [PgBouncer configuration](../high_availability/pgbouncer.md#running-pgbouncer-as-part-of-a-non-ha-gitlab-installation) **(PREMIUM ONLY)** |
| [Sidekiq](../../development/architecture.md#sidekiq) | Asynchronous/background jobs | [Sidekiq configuration](../high_availability/sidekiq.md) |
| [Gitaly](../../development/architecture.md#gitaly) | Provides access to Git repositories | [Gitaly configuration](../gitaly/index.md#running-gitaly-on-its-own-server) |
| [Prometheus](../../development/architecture.md#prometheus) and [Grafana](../../development/architecture.md#grafana) | GitLab environment monitoring | [Monitoring node for scaling](../high_availability/monitoring_node.md) |

## Third-party services used for scaling

Here's a list of third-party services you may require as part of scaling GitLab.
The services can be provided by numerous applications or vendors and further
advice is given on how best to select the right choice for your organization's
needs.

| Component | Description | Configuration instructions |
|-----------|-------------|----------------------------|
| Load balancer(s) | Handles load balancing, typically when you have multiple GitLab application services nodes | [Load balancer configuration](../high_availability/load_balancer.md)      |
| Object storage service | Recommended store for shared data objects | [Cloud Object Storage configuration](../high_availability/object_storage.md) |
| NFS | Shared disk storage service. Can be used as an alternative for Gitaly or Object Storage. Required for GitLab Pages | [NFS configuration](../high_availability/nfs.md) |

## Examples

### Single-node Omnibus installation

This solution is appropriate for many teams that have a single server at their disposal. With automatic backup of the GitLab repositories, configuration, and the database, this can be an optimal solution if you don't have strict availability requirements.

You can also optionally configure GitLab to use an [external PostgreSQL service](../external_database.md)
or an [external object storage service](../high_availability/object_storage.md) for added
performance and reliability at a relatively low complexity cost.

References:

- [Installation Docs](../../install/README.md)
- [Backup/Restore Docs](https://docs.gitlab.com/omnibus/settings/backups.html#backup-and-restore-omnibus-gitlab-configuration)

### Omnibus installation with multiple application servers

This solution is appropriate for teams that are starting to scale out when
scaling up is no longer meeting their needs. In this configuration, additional application nodes will handle frontend traffic, with a load balancer in front to distribute traffic across those nodes. Meanwhile, each application node connects to a shared file server and PostgreSQL and Redis services on the back end.

The additional application servers adds limited fault tolerance to your GitLab
instance. As long as one application node is online and capable of handling the
instance's usage load, your team's productivity will not be interrupted. Having
multiple application nodes also enables [zero-downtime updates](https://docs.gitlab.com/omnibus/update/#zero-downtime-updates).

References:

- [Configure your load balancer for GitLab](../high_availability/load_balancer.md)
- [Configure your NFS server to work with GitLab](../high_availability/nfs.md)
- [Configure packaged PostgreSQL server to listen on TCP/IP](https://docs.gitlab.com/omnibus/settings/database.html#configure-packaged-postgresql-server-to-listen-on-tcpip)
- [Setting up a Redis-only server](https://docs.gitlab.com/omnibus/settings/redis.html#setting-up-a-redis-only-server)

## Recommended setups based on number of users

- 1 - 1000 Users: A single-node [Omnibus](https://docs.gitlab.com/omnibus/) setup with frequent backups. Refer to the [requirements page](../../install/requirements.md) for further details of the specs you will require.
- 1000 - 10000 Users: A scaled environment based on one of our [Reference Architectures](#reference-architectures), without the HA components applied. This can be a reasonable step towards a fully HA environment.
- 2000 - 50000+ Users: A scaled HA environment based on one of our [Reference Architectures](#reference-architectures) below.

## Reference architectures

In this section we'll detail the Reference Architectures that can support large numbers
of users. These were built, tested and verified by our Quality and Support teams.

Testing was done with our GitLab Performance Tool at specific coded workloads, and the
throughputs used for testing were calculated based on sample customer data. We
test each endpoint type with the following number of requests per second (RPS)
per 1000 users:

- API: 20 RPS
- Web: 2 RPS
- Git: 2 RPS

NOTE: **Note:** Note that depending on your workflow the below recommended
reference architectures may need to be adapted accordingly. Your workload
is influenced by factors such as - but not limited to - how active your users are,
how much automation you use, mirroring, and repo/change size. Additionally the
shown memory values are given directly by [GCP machine types](https://cloud.google.com/compute/docs/machine-types).
On different cloud vendors a best effort like for like can be used.

### 2,000 user configuration

- **Supported users (approximate):** 2,000
- **Test RPS rates:** API: 40 RPS, Web: 4 RPS, Git: 4 RPS
- **Known issues:**  [List of known performance issues](https://gitlab.com/gitlab-org/gitlab/issues?label_name%5B%5D=Quality%3Aperformance-issues)

| Service                     | Nodes | Configuration[^8]     | GCP type      | AWS type[^9] |
| ----------------------------|-------|-----------------------|---------------|--------------|
| GitLab Rails[^1]            | 3     | 8 vCPU, 7.2GB Memory  | n1-highcpu-8  | c5.2xlarge   |
| PostgreSQL                  | 3     | 2 vCPU, 7.5GB Memory  | n1-standard-2 | m5.large     |
| PgBouncer                   | 3     | 2 vCPU, 1.8GB Memory  | n1-highcpu-2  | c5.large     |
| Gitaly[^2] [^5] [^7]        | X     | 4 vCPU, 15GB Memory   | n1-standard-4 | m5.xlarge    |
| Redis[^3]                   | 3     | 2 vCPU, 7.5GB Memory  | n1-standard-2 | m5.large     |
| Consul + Sentinel[^3]       | 3     | 2 vCPU, 1.8GB Memory  | n1-highcpu-2  | c5.large     |
| Sidekiq                     | 4     | 2 vCPU, 7.5GB Memory  | n1-standard-2 | m5.large     |
| Cloud Object Storage[^4]    | -     | -                     | -             | -            |
| NFS Server[^5] [^7]         | 1     | 4 vCPU, 3.6GB Memory  | n1-highcpu-4  | c5.xlarge    |
| Monitoring node             | 1     | 2 vCPU, 1.8GB Memory  | n1-highcpu-2  | c5.large     |
| External load balancing node[^6] | 1 | 2 vCPU, 1.8GB Memory | n1-highcpu-2  | c5.large     |
| Internal load balancing node[^6] | 1 | 2 vCPU, 1.8GB Memory | n1-highcpu-2  | c5.large     |

### 5,000 user configuration

- **Supported users (approximate):** 5,000
- **Test RPS rates:** API: 100 RPS, Web: 10 RPS, Git: 10 RPS
- **Known issues:**  [List of known performance issues](https://gitlab.com/gitlab-org/gitlab/issues?label_name%5B%5D=Quality%3Aperformance-issues)

| Service                     | Nodes | Configuration[^8]      | GCP type      | AWS type[^9] |
| ----------------------------|-------|------------------------|---------------|--------------|
| GitLab Rails[^1]            | 3     | 16 vCPU, 14.4GB Memory | n1-highcpu-16 | c5.4xlarge   |
| PostgreSQL                  | 3     | 2 vCPU, 7.5GB Memory   | n1-standard-2 | m5.large     |
| PgBouncer                   | 3     | 2 vCPU, 1.8GB Memory   | n1-highcpu-2  | c5.large     |
| Gitaly[^2] [^5] [^7]        | X     | 8 vCPU, 30GB Memory    | n1-standard-8 | m5.2xlarge   |
| Redis[^3]                   | 3     | 2 vCPU, 7.5GB Memory   | n1-standard-2 | m5.large     |
| Consul + Sentinel[^3]       | 3     | 2 vCPU, 1.8GB Memory   | n1-highcpu-2  | c5.large     |
| Sidekiq                     | 4     | 2 vCPU, 7.5GB Memory   | n1-standard-2 | m5.large     |
| Cloud Object Storage[^4]    | -     | -                      | -             | -            |
| NFS Server[^5] [^7]         | 1     | 4 vCPU, 3.6GB Memory   | n1-highcpu-4  | c5.xlarge    |
| Monitoring node             | 1     | 2 vCPU, 1.8GB Memory   | n1-highcpu-2  | c5.large     |
| External load balancing node[^6] | 1 | 2 vCPU, 1.8GB Memory  | n1-highcpu-2  | c5.large     |
| Internal load balancing node[^6] | 1 | 2 vCPU, 1.8GB Memory  | n1-highcpu-2  | c5.large     |

### 10,000 user configuration

- **Supported users (approximate):** 10,000
- **Test RPS rates:** API: 200 RPS, Web: 20 RPS, Git: 20 RPS
- **Known issues:**  [List of known performance issues](https://gitlab.com/gitlab-org/gitlab/issues?label_name%5B%5D=Quality%3Aperformance-issues)

| Service                     | Nodes | GCP Configuration[^8]  | GCP type       | AWS type[^9] |
| ----------------------------|-------|------------------------|----------------|--------------|
| GitLab Rails[^1]            | 3     | 32 vCPU, 28.8GB Memory | n1-highcpu-32  | c5.9xlarge   |
| PostgreSQL                  | 3     | 4 vCPU, 15GB Memory    | n1-standard-4  | m5.xlarge    |
| PgBouncer                   | 3     | 2 vCPU, 1.8GB Memory   | n1-highcpu-2   | c5.large     |
| Gitaly[^2] [^5] [^7]        | X     | 16 vCPU, 60GB Memory   | n1-standard-16 | m5.4xlarge   |
| Redis[^3] - Cache           | 3     | 4 vCPU, 15GB Memory    | n1-standard-4  | m5.xlarge    |
| Redis[^3] - Queues / Shared State | 3 | 4 vCPU, 15GB Memory  | n1-standard-4  | m5.xlarge    |
| Redis Sentinel[^3] - Cache  | 3     | 1 vCPU, 1.7GB Memory   | g1-small       | t2.small     |
| Redis Sentinel[^3] - Queues / Shared State | 3 | 1 vCPU, 1.7GB Memory | g1-small | t2.small |
| Consul                      | 3     | 2 vCPU, 1.8GB Memory   | n1-highcpu-2   | c5.large     |
| Sidekiq                     | 4     | 4 vCPU, 15GB Memory    | n1-standard-4  | m5.xlarge    |
| Cloud Object Storage[^4]    | -     | -                      | -              | -            |
| NFS Server[^5] [^7]         | 1     | 4 vCPU, 3.6GB Memory   | n1-highcpu-4   | c5.xlarge    |
| Monitoring node             | 1     | 4 vCPU, 3.6GB Memory   | n1-highcpu-4   | c5.xlarge    |
| External load balancing node[^6] | 1 | 2 vCPU, 1.8GB Memory  | n1-highcpu-2   | c5.large     |
| Internal load balancing node[^6] | 1 | 2 vCPU, 1.8GB Memory  | n1-highcpu-2   | c5.large     |

### 25,000 user configuration

- **Supported users (approximate):** 25,000
- **Test RPS rates:** API: 500 RPS, Web: 50 RPS, Git: 50 RPS
- **Known issues:**  [List of known performance issues](https://gitlab.com/gitlab-org/gitlab/issues?label_name%5B%5D=Quality%3Aperformance-issues)

| Service                     | Nodes | Configuration[^8]      | GCP type       | AWS type[^9] |
| ----------------------------|-------|------------------------|----------------|--------------|
| GitLab Rails[^1]            | 5     | 32 vCPU, 28.8GB Memory | n1-highcpu-32  | c5.9xlarge   |
| PostgreSQL                  | 3     | 8 vCPU, 30GB Memory    | n1-standard-8  | m5.2xlarge   |
| PgBouncer                   | 3     | 2 vCPU, 1.8GB Memory   | n1-highcpu-2   | c5.large     |
| Gitaly[^2] [^5] [^7]        | X     | 32 vCPU, 120GB Memory  | n1-standard-32 | m5.8xlarge   |
| Redis[^3] - Cache           | 3     | 4 vCPU, 15GB Memory    | n1-standard-4  | m5.xlarge    |
| Redis[^3] - Queues / Shared State | 3 | 4 vCPU, 15GB Memory  | n1-standard-4  | m5.xlarge    |
| Redis Sentinel[^3] - Cache  | 3     | 1 vCPU, 1.7GB Memory   | g1-small       | t2.small     |
| Redis Sentinel[^3] - Queues / Shared State | 3 | 1 vCPU, 1.7GB Memory | g1-small | t2.small |
| Consul                      | 3     | 2 vCPU, 1.8GB Memory   | n1-highcpu-2   | c5.large     |
| Sidekiq                     | 4     | 4 vCPU, 15GB Memory    | n1-standard-4  | m5.xlarge    |
| Cloud Object Storage[^4]    | -     | -                      | -              | -            |
| NFS Server[^5] [^7]         | 1     | 4 vCPU, 3.6GB Memory   | n1-highcpu-4   | c5.xlarge    |
| Monitoring node             | 1     | 4 vCPU, 3.6GB Memory   | n1-highcpu-4   | c5.xlarge    |
| External load balancing node[^6] | 1 | 2 vCPU, 1.8GB Memory  | n1-highcpu-2   | c5.large     |
| Internal load balancing node[^6] | 1 | 4 vCPU, 3.6GB Memory  | n1-highcpu-4   | c5.xlarge    |

### 50,000 user configuration

- **Supported users (approximate):** 50,000
- **Test RPS rates:** API: 1000 RPS, Web: 100 RPS, Git: 100 RPS
- **Known issues:**  [List of known performance issues](https://gitlab.com/gitlab-org/gitlab/issues?label_name%5B%5D=Quality%3Aperformance-issues)

| Service                     | Nodes | Configuration[^8]      | GCP type       | AWS type[^9] |
| ----------------------------|-------|------------------------|----------------|--------------|
| GitLab Rails[^1]            | 12    | 32 vCPU, 28.8GB Memory | n1-highcpu-32  | c5.9xlarge   |
| PostgreSQL                  | 3     | 16 vCPU, 60GB Memory   | n1-standard-16 | m5.4xlarge   |
| PgBouncer                   | 3     | 2 vCPU, 1.8GB Memory   | n1-highcpu-2   | c5.large     |
| Gitaly[^2] [^5] [^7]        | X     | 64 vCPU, 240GB Memory  | n1-standard-64 | m5.16xlarge  |
| Redis[^3] - Cache           | 3     | 4 vCPU, 15GB Memory    | n1-standard-4  | m5.xlarge    |
| Redis[^3] - Queues / Shared State | 3 | 4 vCPU, 15GB Memory  | n1-standard-4  | m5.xlarge    |
| Redis Sentinel[^3] - Cache  | 3     | 1 vCPU, 1.7GB Memory   | g1-small       | t2.small     |
| Redis Sentinel[^3] - Queues / Shared State | 3 | 1 vCPU, 1.7GB Memory | g1-small | t2.small |
| Consul                      | 3     | 2 vCPU, 1.8GB Memory   | n1-highcpu-2   | c5.large     |
| Sidekiq                     | 4     | 4 vCPU, 15GB Memory    | n1-standard-4  | m5.xlarge    |
| NFS Server[^5] [^7]         | 1     | 4 vCPU, 3.6GB Memory   | n1-highcpu-4   | c5.xlarge    |
| Cloud Object Storage[^4]    | -     | -                      | -              | -            |
| Monitoring node             | 1     | 4 vCPU, 3.6GB Memory   | n1-highcpu-4   | c5.xlarge    |
| External load balancing node[^6] | 1 | 2 vCPU, 1.8GB Memory  | n1-highcpu-2   | c5.large     |
| Internal load balancing node[^6] | 1 | 8 vCPU, 7.2GB Memory  | n1-highcpu-8   | c5.2xlarge   |

[^1]: In our architectures we run each GitLab Rails node using the Puma webserver
      and have its number of workers set to 90% of available CPUs along with 4 threads.

[^2]: Gitaly node requirements are dependent on customer data, specifically the number of
      projects and their sizes. We recommend 2 nodes as an absolute minimum for HA environments
      and at least 4 nodes should be used when supporting 50,000 or more users.
      We also recommend that each Gitaly node should store no more than 5TB of data
      and have the number of [`gitaly-ruby` workers](../gitaly/index.md#gitaly-ruby)
      set to 20% of available CPUs. Additional nodes should be considered in conjunction
      with a review of expected data size and spread based on the recommendations above.

[^3]: Recommended Redis setup differs depending on the size of the architecture.
      For smaller architectures (up to 5,000 users) we suggest one Redis cluster for all
      classes and that Redis Sentinel is hosted alongside Consul.
      For larger architectures (10,000 users or more) we suggest running a separate
      [Redis Cluster](../high_availability/redis.md#running-multiple-redis-clusters) for the Cache class
      and another for the Queues and Shared State classes respectively. We also recommend
      that you run the Redis Sentinel clusters separately as well for each Redis Cluster.

[^4]: For data objects such as LFS, Uploads, Artifacts, etc. We recommend a [Cloud Object Storage service](../object_storage.md)
      over NFS where possible, due to better performance and availability.

[^5]: NFS can be used as an alternative for both repository data (replacing Gitaly) and
      object storage but this isn't typically recommended for performance reasons. Note however it is required for
      [GitLab Pages](https://gitlab.com/gitlab-org/gitlab-pages/issues/196).

[^6]: Our architectures have been tested and validated with [HAProxy](https://www.haproxy.org/)
      as the load balancer. However other reputable load balancers with similar feature sets
      should also work instead but be aware these aren't validated.

[^7]: We strongly recommend that any Gitaly and / or NFS nodes are set up with SSD disks over
      HDD with a throughput of at least 8,000 IOPS for read operations and 2,000 IOPS for write
      as these components have heavy I/O. These IOPS values are recommended only as a starter
      as with time they may be adjusted higher or lower depending on the scale of your
      environment's workload. If you're running the environment on a Cloud provider
      you may need to refer to their documentation on how configure IOPS correctly.

[^8]: The architectures were built and tested with the [Intel Xeon E5 v3 (Haswell)](https://cloud.google.com/compute/docs/cpu-platforms)
      CPU platform on GCP. On different hardware you may find that adjustments, either lower
      or higher, are required for your CPU or Node counts accordingly. For more information, a
      [Sysbench](https://github.com/akopytov/sysbench) benchmark of the CPU can be found
      [here](https://gitlab.com/gitlab-org/quality/performance/-/wikis/Reference-Architectures/GCP-CPU-Benchmarks).

[^9]: AWS-equivalent configurations are rough suggestions and may change in the
      future. They have not yet been tested and validated.
