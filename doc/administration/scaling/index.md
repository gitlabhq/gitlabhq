---
type: reference, concepts
---

# Scaling

GitLab supports a number of scaling options to ensure that your self-managed
instance is able to scale to meet your organization's needs.

On this page, we present examples of self-managed instances which demonstrate
how GitLab can be scaled up, scaled out or made highly available. These
examples progress from simple to complex as scaling or highly-available
components are added.

For detailed insight into how GitLab scales and configures GitLab.com, you can
watch [this 1 hour Q&A](https://www.youtube.com/watch?v=uCU8jdYzpac)
with [John Northrup](https://gitlab.com/northrup), and live questions coming
in from some of our customers.

## Reference architectures

GitLab can be set up on a single machine or scaled out to handle large number of users. In this section we'll detail the Reference Architectures that were built and verified by our Quality and Support teams.
Testing was done with our [GitLab Performance Tool](https://gitlab.com/gitlab-org/quality/performance) at specific coded workloads, and the throughputs used for testing were calculated based on sample customer data.

We test each endpoint type with the following number of requests per second (RPS) per 1000 users:

- API: 20 RPS
- Web: 2 RPS
- Git: 2 RPS

For up to 2,000 users we recommend going with a simple setup. Going above 2,000 users, we recommend scaling GitLab components to multiple machine nodes.
The machine nodes are grouped by component(s). The addition of these nodes adds limited fault tolerance to your GitLab instance.
As long as there is at least one of each component online and capable of handling the instance's usage load, your team's productivity will not be interrupted.
The same is true if you are looking to perform [zero-downtime updates](https://docs.gitlab.com/omnibus/update/#zero-downtime-updates).

When scaling GitLab there's a few factors to consider:

- Multiple application nodes to handle frontend traffic.
- A load balancer is added in front to distribute traffic across the application nodes.
- The application nodes connects to a shared file server and PostgreSQL and Redis services on the backend.

References:

- [Configure your load balancer for GitLab](../high_availability/load_balancer.md)
- [Configure your NFS server to work with GitLab](../high_availability/nfs.md)
- [Configure packaged PostgreSQL server to listen on TCP/IP](https://docs.gitlab.com/omnibus/settings/database.html#configure-packaged-postgresql-server-to-listen-on-tcpip)
- [Setting up a Redis-only server](https://docs.gitlab.com/omnibus/settings/redis.html#setting-up-a-redis-only-server)

NOTE: **Note:** Note that depending on your workflow the below recommended
reference architectures may need to be adapted accordingly. Your workload
is influenced by factors such as - but not limited to - how active your users are,
how much automation you use, mirroring, and repository/change size. Additionally the
shown memory values are given directly by [GCP machine types](https://cloud.google.com/compute/docs/machine-types).
On different cloud vendors a best effort like for like can be used.

### Up to 1,000 users

From 1 to 1,000 users, a single-node [Omnibus](https://docs.gitlab.com/omnibus/) setup with frequent backups is adequate.
Please refer to the [installation documentation](../../install/README.md) and [backup/restore documentation](https://docs.gitlab.com/omnibus/settings/backups.html#backup-and-restore-omnibus-gitlab-configuration).

| Users | Configuration([8](#footnotes)) | GCP type      | AWS type([9](#footnotes)) |
|-------|--------------------------------|---------------|---------------------------|
| 100   | 2 vCPU, 7.2GB Memory           | n1-standard-2 | c5.2xlarge                |
| 500   | 4 vCPU, 15GB Memory            | n1-standard-4 | m5.xlarge                 |
| 1000  | 8 vCPU, 30GB Memory            | n1-standard-8 | m5.2xlarge                |

This solution is appropriate for many teams that have a single server at their disposal. With automatic backup of the GitLab repositories, configuration, and the database, this can be an optimal solution if you don't have strict availability requirements.

You can also optionally configure GitLab to use an [external PostgreSQL service](../external_database.md) or an [external object storage service](../high_availability/object_storage.md) for added performance and reliability at a relatively low complexity cost.

### Up to 2,000 users

For up to 2,000 users, defining the reference architecture is [being worked on](https://gitlab.com/gitlab-org/quality/performance/-/issues/223).

### Up to 3,000 users

NOTE: **Note:** The 3,000-user reference architecture documented below is
designed to help your organization achieve a highly-available GitLab deployment.
If you do not have the expertise or need to maintain a highly-available
environment, you can have a simpler and less costly-to-operate environment by
deploying two or more GitLab Rails servers, external load balancing, an NFS
server, a PostgreSQL server and a Redis server. A reference architecture with
this alternative in mind is [being worked on](https://gitlab.com/gitlab-org/quality/performance/-/issues/223).

- **Supported users (approximate):** 2,000
- **Test RPS rates:** API: 40 RPS, Web: 4 RPS, Git: 4 RPS
- **Known issues:**  [List of known performance issues](https://gitlab.com/gitlab-org/gitlab/issues?label_name%5B%5D=Quality%3Aperformance-issues)

| Service                                                      | Nodes | Configuration ([8](#footnotes)) | GCP type      | AWS type ([9](#footnotes)) |
|--------------------------------------------------------------|-------|---------------------------------|---------------|----------------------------|
| GitLab Rails ([1](#footnotes))                               | 3     | 8 vCPU, 7.2GB Memory            | n1-highcpu-8  | c5.2xlarge                 |
| PostgreSQL                                                   | 3     | 2 vCPU, 7.5GB Memory            | n1-standard-2 | m5.large                   |
| PgBouncer                                                    | 3     | 2 vCPU, 1.8GB Memory            | n1-highcpu-2  | c5.large                   |
| Gitaly ([2](#footnotes)) ([5](#footnotes)) ([7](#footnotes)) | X     | 4 vCPU, 15GB Memory             | n1-standard-4 | m5.xlarge                  |
| Redis ([3](#footnotes))                                      | 3     | 2 vCPU, 7.5GB Memory            | n1-standard-2 | m5.large                   |
| Consul + Sentinel ([3](#footnotes))                          | 3     | 2 vCPU, 1.8GB Memory            | n1-highcpu-2  | c5.large                   |
| Sidekiq                                                      | 4     | 2 vCPU, 7.5GB Memory            | n1-standard-2 | m5.large                   |
| Cloud Object Storage ([4](#footnotes))                       | -     | -                               | -             | -                          |
| NFS Server ([5](#footnotes)) ([7](#footnotes))               | 1     | 4 vCPU, 3.6GB Memory            | n1-highcpu-4  | c5.xlarge                  |
| Monitoring node                                              | 1     | 2 vCPU, 1.8GB Memory            | n1-highcpu-2  | c5.large                   |
| External load balancing node ([6](#footnotes))               | 1     | 2 vCPU, 1.8GB Memory            | n1-highcpu-2  | c5.large                   |
| Internal load balancing node ([6](#footnotes))               | 1     | 2 vCPU, 1.8GB Memory            | n1-highcpu-2  | c5.large                   |

### Up to 5,000 users

- **Supported users (approximate):** 5,000
- **Test RPS rates:** API: 100 RPS, Web: 10 RPS, Git: 10 RPS
- **Known issues:**  [List of known performance issues](https://gitlab.com/gitlab-org/gitlab/issues?label_name%5B%5D=Quality%3Aperformance-issues)

| Service                                                      | Nodes | Configuration ([8](#footnotes)) | GCP type      | AWS type ([9](#footnotes)) |
|--------------------------------------------------------------|-------|---------------------------------|---------------|----------------------------|
| GitLab Rails ([1](#footnotes))                               | 3     | 16 vCPU, 14.4GB Memory          | n1-highcpu-16 | c5.4xlarge                 |
| PostgreSQL                                                   | 3     | 2 vCPU, 7.5GB Memory            | n1-standard-2 | m5.large                   |
| PgBouncer                                                    | 3     | 2 vCPU, 1.8GB Memory            | n1-highcpu-2  | c5.large                   |
| Gitaly ([2](#footnotes)) ([5](#footnotes)) ([7](#footnotes)) | X     | 8 vCPU, 30GB Memory             | n1-standard-8 | m5.2xlarge                 |
| Redis ([3](#footnotes))                                      | 3     | 2 vCPU, 7.5GB Memory            | n1-standard-2 | m5.large                   |
| Consul + Sentinel ([3](#footnotes))                          | 3     | 2 vCPU, 1.8GB Memory            | n1-highcpu-2  | c5.large                   |
| Sidekiq                                                      | 4     | 2 vCPU, 7.5GB Memory            | n1-standard-2 | m5.large                   |
| Cloud Object Storage ([4](#footnotes))                       | -     | -                               | -             | -                          |
| NFS Server ([5](#footnotes)) ([7](#footnotes))               | 1     | 4 vCPU, 3.6GB Memory            | n1-highcpu-4  | c5.xlarge                  |
| Monitoring node                                              | 1     | 2 vCPU, 1.8GB Memory            | n1-highcpu-2  | c5.large                   |
| External load balancing node ([6](#footnotes))               | 1     | 2 vCPU, 1.8GB Memory            | n1-highcpu-2  | c5.large                   |
| Internal load balancing node ([6](#footnotes))               | 1     | 2 vCPU, 1.8GB Memory            | n1-highcpu-2  | c5.large                   |

### Up to 10,000 users

- **Supported users (approximate):** 10,000
- **Test RPS rates:** API: 200 RPS, Web: 20 RPS, Git: 20 RPS
- **Known issues:**  [List of known performance issues](https://gitlab.com/gitlab-org/gitlab/issues?label_name%5B%5D=Quality%3Aperformance-issues)

| Service                                                      | Nodes | GCP Configuration ([8](#footnotes)) | GCP type       | AWS type ([9](#footnotes)) |
|--------------------------------------------------------------|-------|-------------------------------------|----------------|----------------------------|
| GitLab Rails ([1](#footnotes))                               | 3     | 32 vCPU, 28.8GB Memory              | n1-highcpu-32  | c5.9xlarge                 |
| PostgreSQL                                                   | 3     | 4 vCPU, 15GB Memory                 | n1-standard-4  | m5.xlarge                  |
| PgBouncer                                                    | 3     | 2 vCPU, 1.8GB Memory                | n1-highcpu-2   | c5.large                   |
| Gitaly ([2](#footnotes)) ([5](#footnotes)) ([7](#footnotes)) | X     | 16 vCPU, 60GB Memory                | n1-standard-16 | m5.4xlarge                 |
| Redis ([3](#footnotes)) - Cache                              | 3     | 4 vCPU, 15GB Memory                 | n1-standard-4  | m5.xlarge                  |
| Redis ([3](#footnotes)) - Queues / Shared State              | 3     | 4 vCPU, 15GB Memory                 | n1-standard-4  | m5.xlarge                  |
| Redis Sentinel ([3](#footnotes)) - Cache                     | 3     | 1 vCPU, 1.7GB Memory                | g1-small       | t2.small                   |
| Redis Sentinel ([3](#footnotes)) - Queues / Shared State     | 3     | 1 vCPU, 1.7GB Memory                | g1-small       | t2.small                   |
| Consul                                                       | 3     | 2 vCPU, 1.8GB Memory                | n1-highcpu-2   | c5.large                   |
| Sidekiq                                                      | 4     | 4 vCPU, 15GB Memory                 | n1-standard-4  | m5.xlarge                  |
| Cloud Object Storage ([4](#footnotes))                       | -     | -                                   | -              | -                          |
| NFS Server ([5](#footnotes)) ([7](#footnotes))               | 1     | 4 vCPU, 3.6GB Memory                | n1-highcpu-4   | c5.xlarge                  |
| Monitoring node                                              | 1     | 4 vCPU, 3.6GB Memory                | n1-highcpu-4   | c5.xlarge                  |
| External load balancing node ([6](#footnotes))               | 1     | 2 vCPU, 1.8GB Memory                | n1-highcpu-2   | c5.large                   |
| Internal load balancing node ([6](#footnotes))               | 1     | 2 vCPU, 1.8GB Memory                | n1-highcpu-2   | c5.large                   |

### Up to 25,000 users

- **Supported users (approximate):** 25,000
- **Test RPS rates:** API: 500 RPS, Web: 50 RPS, Git: 50 RPS
- **Known issues:**  [List of known performance issues](https://gitlab.com/gitlab-org/gitlab/issues?label_name%5B%5D=Quality%3Aperformance-issues)

| Service                                                      | Nodes | Configuration ([8](#footnotes)) | GCP type       | AWS type ([9](#footnotes)) |
|--------------------------------------------------------------|-------|---------------------------------|----------------|----------------------------|
| GitLab Rails ([1](#footnotes))                               | 5     | 32 vCPU, 28.8GB Memory          | n1-highcpu-32  | c5.9xlarge                 |
| PostgreSQL                                                   | 3     | 8 vCPU, 30GB Memory             | n1-standard-8  | m5.2xlarge                 |
| PgBouncer                                                    | 3     | 2 vCPU, 1.8GB Memory            | n1-highcpu-2   | c5.large                   |
| Gitaly ([2](#footnotes)) ([5](#footnotes)) ([7](#footnotes)) | X     | 32 vCPU, 120GB Memory           | n1-standard-32 | m5.8xlarge                 |
| Redis ([3](#footnotes)) - Cache                              | 3     | 4 vCPU, 15GB Memory             | n1-standard-4  | m5.xlarge                  |
| Redis ([3](#footnotes)) - Queues / Shared State              | 3     | 4 vCPU, 15GB Memory             | n1-standard-4  | m5.xlarge                  |
| Redis Sentinel ([3](#footnotes)) - Cache                     | 3     | 1 vCPU, 1.7GB Memory            | g1-small       | t2.small                   |
| Redis Sentinel ([3](#footnotes)) - Queues / Shared State     | 3     | 1 vCPU, 1.7GB Memory            | g1-small       | t2.small                   |
| Consul                                                       | 3     | 2 vCPU, 1.8GB Memory            | n1-highcpu-2   | c5.large                   |
| Sidekiq                                                      | 4     | 4 vCPU, 15GB Memory             | n1-standard-4  | m5.xlarge                  |
| Cloud Object Storage ([4](#footnotes))                       | -     | -                               | -              | -                          |
| NFS Server ([5](#footnotes)) ([7](#footnotes))               | 1     | 4 vCPU, 3.6GB Memory            | n1-highcpu-4   | c5.xlarge                  |
| Monitoring node                                              | 1     | 4 vCPU, 3.6GB Memory            | n1-highcpu-4   | c5.xlarge                  |
| External load balancing node ([6](#footnotes))               | 1     | 2 vCPU, 1.8GB Memory            | n1-highcpu-2   | c5.large                   |
| Internal load balancing node ([6](#footnotes))               | 1     | 4 vCPU, 3.6GB Memory            | n1-highcpu-4   | c5.xlarge                  |

### Up to 50,000 users

- **Supported users (approximate):** 50,000
- **Test RPS rates:** API: 1000 RPS, Web: 100 RPS, Git: 100 RPS
- **Known issues:**  [List of known performance issues](https://gitlab.com/gitlab-org/gitlab/issues?label_name%5B%5D=Quality%3Aperformance-issues)

| Service                                                      | Nodes | Configuration ([8](#footnotes)) | GCP type       | AWS type ([9](#footnotes)) |
|--------------------------------------------------------------|-------|---------------------------------|----------------|----------------------------|
| GitLab Rails ([1](#footnotes))                               | 12    | 32 vCPU, 28.8GB Memory          | n1-highcpu-32  | c5.9xlarge                 |
| PostgreSQL                                                   | 3     | 16 vCPU, 60GB Memory            | n1-standard-16 | m5.4xlarge                 |
| PgBouncer                                                    | 3     | 2 vCPU, 1.8GB Memory            | n1-highcpu-2   | c5.large                   |
| Gitaly ([2](#footnotes)) ([5](#footnotes)) ([7](#footnotes)) | X     | 64 vCPU, 240GB Memory           | n1-standard-64 | m5.16xlarge                |
| Redis ([3](#footnotes)) - Cache                              | 3     | 4 vCPU, 15GB Memory             | n1-standard-4  | m5.xlarge                  |
| Redis ([3](#footnotes)) - Queues / Shared State              | 3     | 4 vCPU, 15GB Memory             | n1-standard-4  | m5.xlarge                  |
| Redis Sentinel ([3](#footnotes)) - Cache                     | 3     | 1 vCPU, 1.7GB Memory            | g1-small       | t2.small                   |
| Redis Sentinel ([3](#footnotes)) - Queues / Shared State     | 3     | 1 vCPU, 1.7GB Memory            | g1-small       | t2.small                   |
| Consul                                                       | 3     | 2 vCPU, 1.8GB Memory            | n1-highcpu-2   | c5.large                   |
| Sidekiq                                                      | 4     | 4 vCPU, 15GB Memory             | n1-standard-4  | m5.xlarge                  |
| NFS Server ([5](#footnotes)) ([7](#footnotes))               | 1     | 4 vCPU, 3.6GB Memory            | n1-highcpu-4   | c5.xlarge                  |
| Cloud Object Storage ([4](#footnotes))                       | -     | -                               | -              | -                          |
| Monitoring node                                              | 1     | 4 vCPU, 3.6GB Memory            | n1-highcpu-4   | c5.xlarge                  |
| External load balancing node ([6](#footnotes))               | 1     | 2 vCPU, 1.8GB Memory            | n1-highcpu-2   | c5.large                   |
| Internal load balancing node ([6](#footnotes))               | 1     | 8 vCPU, 7.2GB Memory            | n1-highcpu-8   | c5.2xlarge                 |

## Configuring GitLab to scale

### Components not provided by Omnibus GitLab

Depending on your system architecture, you may require some components which are
not provided in Omnibus GitLab. If required, these should be configured before
setting up components provided by GitLab. Advice on how to select the right
solution for your organization is provided in the configuration instructions
listed below.

| Component | Description | Configuration instructions |
|-----------|-------------|----------------------------|
| Load balancer(s) ([6](#footnotes)) | Handles load balancing, typically when you have multiple GitLab application services nodes | [Load balancer configuration](../high_availability/load_balancer.md) ([6](#footnotes))      |
| Object storage service ([4](#footnotes)) | Recommended store for shared data objects | [Cloud Object Storage configuration](../object_storage.md) |
| NFS ([5](#footnotes)) ([7](#footnotes)) | Shared disk storage service. Can be used as an alternative for Gitaly or Object Storage. Required for GitLab Pages | [NFS configuration](../high_availability/nfs.md) |

### Components provided by Omnibus GitLab

The following components are provided by Omnibus GitLab. They are listed in the
order you'll typically configure them if they are required by your
[reference architecture](#reference-architectures) of choice.

| Component | Description | Configuration instructions |
|-----------|-------------|----------------------------|
| [Consul](../../development/architecture.md#consul) ([3](#footnotes)) | Service discovery and health checks/failover | [Consul HA configuration](../high_availability/consul.md) **(PREMIUM ONLY)** |
| [PostgreSQL](../../development/architecture.md#postgresql) | Database | [PostgreSQL configuration](https://docs.gitlab.com/omnibus/settings/database.html) |
| [PgBouncer](../../development/architecture.md#pgbouncer) | Database connection pooler | [PgBouncer configuration](../high_availability/pgbouncer.md#running-pgbouncer-as-part-of-a-non-ha-gitlab-installation) **(PREMIUM ONLY)** |
| Repmgr | PostgreSQL cluster management and failover | [PostgreSQL and Repmgr configuration](../high_availability/database.md) |
| [Redis](../../development/architecture.md#redis) ([3](#footnotes))  | Key/value store for fast data lookup and caching | [Redis configuration](../high_availability/redis.md) |
| Redis Sentinel | High availability for Redis | [Redis Sentinel configuration](../high_availability/redis.md) |
| [Gitaly](../../development/architecture.md#gitaly) ([2](#footnotes)) ([5](#footnotes)) ([7](#footnotes))  | Provides access to Git repositories | [Gitaly configuration](../gitaly/index.md#running-gitaly-on-its-own-server) |
| [Sidekiq](../../development/architecture.md#sidekiq) | Asynchronous/background jobs | [Sidekiq configuration](../high_availability/sidekiq.md) |
| [GitLab application services](../../development/architecture.md#unicorn)([1](#footnotes)) | Unicorn/Puma, Workhorse, GitLab Shell - serves front-end requests (UI, API, Git over HTTP/SSH) | [GitLab app scaling configuration](../high_availability/gitlab.md) |
| [Prometheus](../../development/architecture.md#prometheus) and [Grafana](../../development/architecture.md#grafana) | GitLab environment monitoring | [Monitoring node for scaling](../high_availability/monitoring_node.md) |

## Footnotes

1. In our architectures we run each GitLab Rails node using the Puma webserver
   and have its number of workers set to 90% of available CPUs along with 4 threads.

1. Gitaly node requirements are dependent on customer data, specifically the number of
   projects and their sizes. We recommend 2 nodes as an absolute minimum for HA environments
   and at least 4 nodes should be used when supporting 50,000 or more users.
   We also recommend that each Gitaly node should store no more than 5TB of data
   and have the number of [`gitaly-ruby` workers](../gitaly/index.md#gitaly-ruby)
   set to 20% of available CPUs. Additional nodes should be considered in conjunction
   with a review of expected data size and spread based on the recommendations above.

1. Recommended Redis setup differs depending on the size of the architecture.
   For smaller architectures (up to 5,000 users) we suggest one Redis cluster for all
   classes and that Redis Sentinel is hosted alongside Consul.
   For larger architectures (10,000 users or more) we suggest running a separate
   [Redis Cluster](../high_availability/redis.md#running-multiple-redis-clusters) for the Cache class
   and another for the Queues and Shared State classes respectively. We also recommend
   that you run the Redis Sentinel clusters separately as well for each Redis Cluster.

1. For data objects such as LFS, Uploads, Artifacts, etc. We recommend a [Cloud Object Storage service](../object_storage.md)
   over NFS where possible, due to better performance and availability.

1. NFS can be used as an alternative for both repository data (replacing Gitaly) and
   object storage but this isn't typically recommended for performance reasons. Note however it is required for
   [GitLab Pages](https://gitlab.com/gitlab-org/gitlab-pages/issues/196).

1. Our architectures have been tested and validated with [HAProxy](https://www.haproxy.org/)
   as the load balancer. However other reputable load balancers with similar feature sets
   should also work instead but be aware these aren't validated.

1. We strongly recommend that any Gitaly and / or NFS nodes are set up with SSD disks over
   HDD with a throughput of at least 8,000 IOPS for read operations and 2,000 IOPS for write
   as these components have heavy I/O. These IOPS values are recommended only as a starter
   as with time they may be adjusted higher or lower depending on the scale of your
   environment's workload. If you're running the environment on a Cloud provider
   you may need to refer to their documentation on how configure IOPS correctly.

1. The architectures were built and tested with the [Intel Xeon E5 v3 (Haswell)](https://cloud.google.com/compute/docs/cpu-platforms)
   CPU platform on GCP. On different hardware you may find that adjustments, either lower
   or higher, are required for your CPU or Node counts accordingly. For more information, a
   [Sysbench](https://github.com/akopytov/sysbench) benchmark of the CPU can be found
   [here](https://gitlab.com/gitlab-org/quality/performance/-/wikis/Reference-Architectures/GCP-CPU-Benchmarks).

1. AWS-equivalent configurations are rough suggestions and may change in the
   future. They have not yet been tested and validated.
