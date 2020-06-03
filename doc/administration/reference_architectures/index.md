---
type: reference, concepts
---
# Reference architectures

<!-- TBD to be reviewed by Eric -->

You can set up GitLab on a single server or scale it up to serve many users.
This page details the recommended Reference Architectures that were built and verified by GitLab's Quality and Support teams.

Below is a chart representing each architecture tier and the number of users they can handle. As your number of users grow with time, it’s recommended that you scale GitLab accordingly.

![Reference Architectures](img/reference-architectures.png)
<!-- Internal link: https://docs.google.com/spreadsheets/d/1obYP4fLKkVVDOljaI3-ozhmCiPtEeMblbBKkf2OADKs/edit#gid=1403207183 -->

Testing on these reference architectures were performed with [GitLab's Performance Tool](https://gitlab.com/gitlab-org/quality/performance)
at specific coded workloads, and the throughputs used for testing were calculated based on sample customer data.
After selecting the reference architecture that matches your scale, refer to
[Configure GitLab to Scale](#configure-gitlab-to-scale) to see the components
involved, and how to configure them.

Each endpoint type is tested with the following number of requests per second (RPS) per 1000 users:

- API: 20 RPS
- Web: 2 RPS
- Git: 2 RPS

For GitLab instances with less than 2,000 users, it's recommended that you use the [default setup](#automated-backups-core-only)
by [installing GitLab](../../install/README.md) on a single machine to minimize maintenance and resource costs.

If your organization has more than 2,000 users, the recommendation is to scale GitLab's components to multiple
machine nodes. The machine nodes are grouped by component(s). The addition of these
nodes increases the performance and scalability of to your GitLab instance.

When scaling GitLab, there are several factors to consider:

- Multiple application nodes to handle frontend traffic.
- A load balancer is added in front to distribute traffic across the application nodes.
- The application nodes connects to a shared file server and PostgreSQL and Redis services on the backend.

NOTE: **Note:** Depending on your workflow, the following recommended
reference architectures may need to be adapted accordingly. Your workload
is influenced by factors including how active your users are,
how much automation you use, mirroring, and repository/change size. Additionally the
displayed memory values are provided by [GCP machine types](https://cloud.google.com/compute/docs/machine-types).
For different cloud vendors, attempt to select options that best match the provided architecture.

## Available reference architectures

The following reference architectures are available:

- [Up to 1,000 users](1k_users.md)
- [Up to 2,000 users](2k_users.md)
- [Up to 3,000 users](3k_users.md)
- [Up to 5,000 users](5k_users.md)
- [Up to 10,000 users](10k_users.md)
- [Up to 25,000 users](25k_users.md)
- [Up to 50,000 users](50k_users.md)

## Availability Components

GitLab comes with the following components for your use, listed from
least to most complex:

1. [Automated backups](#automated-backups-core-only)
1. [Traffic load balancer](#traffic-load-balancer-starter-only)
1. [Zero downtime updates](#zero-downtime-updates-starter-only)
1. [Automated database failover](#automated-database-failover-premium-only)
1. [Instance level replication with GitLab Geo](#instance-level-replication-with-gitlab-geo-premium-only)

As you implement these components, begin with a single server and then do
backups. Only after completing the first server should you proceed to the next.

Also, not implementing extra servers for GitLab doesn't necessarily mean that you'll have
more downtime. Depending on your needs and experience level, single servers can
have more actual perceived uptime for your users.

### Automated backups **(CORE ONLY)**

> - Level of complexity: **Low**
> - Required domain knowledge: PostgreSQL, GitLab configurations, Git
> - Supported tiers: [GitLab Core, Starter, Premium, and Ultimate](https://about.gitlab.com/pricing/)

This solution is appropriate for many teams that have the default GitLab installation.
With automatic backups of the GitLab repositories, configuration, and the database,
this can be an optimal solution if you don't have strict requirements.
[Automated backups](../../raketasks/backup_restore.md#configuring-cron-to-make-daily-backups)
is the least complex to setup. This provides a point-in-time recovery of a predetermined schedule.

### Traffic load balancer **(STARTER ONLY)**

> - Level of complexity: **Medium**
> - Required domain knowledge: HAProxy, shared storage, distributed systems
> - Supported tiers: [GitLab Starter, Premium, and Ultimate](https://about.gitlab.com/pricing/)

This requires separating out GitLab into multiple application nodes with an added
[load balancer](../high_availability/load_balancer.md). The load balancer will distribute traffic
across GitLab application nodes. Meanwhile, each application node connects to a
shared file server and database systems on the back end. This way, if one of the
application servers fails, the workflow is not interrupted.
[HAProxy](https://www.haproxy.org/) is recommended as the load balancer.

With this added component you have a number of advantages compared
to the default installation:

- Increase the number of users.
- Enable zero-downtime upgrades.
- Increase availability.

### Zero downtime updates **(STARTER ONLY)**

> - Level of complexity: **Medium**
> - Required domain knowledge: PostgreSQL, HAProxy, shared storage, distributed systems
> - Supported tiers: [GitLab Starter, Premium, and Ultimate](https://about.gitlab.com/pricing/)

GitLab supports [zero-downtime updates](https://docs.gitlab.com/omnibus/update/#zero-downtime-updates).
Although you can perform zero-downtime updates with a single GitLab node, the recommendation is to separate GitLab into several application nodes.
As long as at least one of each component is online and capable of handling the instance's usage load, your team's productivity will not be interrupted during the update.

### Automated database failover **(PREMIUM ONLY)**

> - Level of complexity: **High**
> - Required domain knowledge: PgBouncer, Repmgr, shared storage, distributed systems
> - Supported tiers: [GitLab Premium and Ultimate](https://about.gitlab.com/pricing/)

By adding automatic failover for database systems, you can enable higher uptime
with additional database nodes. This extends the default database with
cluster management and failover policies.
[PgBouncer](../../development/architecture.md#pgbouncer) in conjunction with
[Repmgr](../high_availability/database.md) is recommended.

### Instance level replication with GitLab Geo **(PREMIUM ONLY)**

> - Level of complexity: **Very High**
> - Required domain knowledge: Storage replication
> - Supported tiers: [GitLab Premium and Ultimate](https://about.gitlab.com/pricing/)

[GitLab Geo](../geo/replication/index.md) allows you to replicate your GitLab
instance to other geographical locations as a read-only fully operational instance
that can also be promoted in case of disaster.

## Configure GitLab to scale

The following components are the ones you need to configure in order to scale
GitLab. They are listed in the order you'll typically configure them if they are
required by your [reference architecture](#reference-architectures) of choice.

Most of them are bundled in the GitLab deb/rpm package (called Omnibus GitLab),
but depending on your system architecture, you may require some components which are
not included in it. If required, those should be configured before
setting up components provided by GitLab. Advice on how to select the right
solution for your organization is provided in the configuration instructions
column.

| Component | Description | Configuration instructions | Bundled with Omnibus GitLab |
|-----------|-------------|----------------------------|
| Load balancer(s) ([6](#footnotes)) | Handles load balancing, typically when you have multiple GitLab application services nodes | [Load balancer configuration](../high_availability/load_balancer.md) ([6](#footnotes))      | No |
| Object storage service ([4](#footnotes)) | Recommended store for shared data objects | [Object Storage configuration](../object_storage.md) | No |
| NFS ([5](#footnotes)) ([7](#footnotes)) | Shared disk storage service. Can be used as an alternative Object Storage. Required for GitLab Pages | [NFS configuration](../high_availability/nfs.md) | No |
| [Consul](../../development/architecture.md#consul) ([3](#footnotes)) | Service discovery and health checks/failover | [Consul configuration](../high_availability/consul.md) **(PREMIUM ONLY)** | Yes |
| [PostgreSQL](../../development/architecture.md#postgresql) | Database | [PostgreSQL configuration](https://docs.gitlab.com/omnibus/settings/database.html) | Yes |
| [PgBouncer](../../development/architecture.md#pgbouncer) | Database connection pooler | [PgBouncer configuration](../high_availability/pgbouncer.md#running-pgbouncer-as-part-of-a-non-ha-gitlab-installation) **(PREMIUM ONLY)** | Yes |
| Repmgr | PostgreSQL cluster management and failover | [PostgreSQL and Repmgr configuration](../high_availability/database.md) | Yes |
| [Redis](../../development/architecture.md#redis) ([3](#footnotes))  | Key/value store for fast data lookup and caching | [Redis configuration](../high_availability/redis.md) | Yes |
| Redis Sentinel | Redis | [Redis Sentinel configuration](../high_availability/redis.md) | Yes |
| [Gitaly](../../development/architecture.md#gitaly) ([2](#footnotes)) ([7](#footnotes)) ([9](#footnotes)) | Provides access to Git repositories | [Gitaly configuration](../gitaly/index.md#running-gitaly-on-its-own-server) | Yes |
| [Sidekiq](../../development/architecture.md#sidekiq) | Asynchronous/background jobs | [Sidekiq configuration](../high_availability/sidekiq.md) | Yes |
| [GitLab application services](../../development/architecture.md#unicorn)([1](#footnotes)) | Puma/Unicorn, Workhorse, GitLab Shell - serves front-end requests (UI, API, Git over HTTP/SSH) | [GitLab app scaling configuration](../high_availability/gitlab.md) | Yes |
| [Prometheus](../../development/architecture.md#prometheus) and [Grafana](../../development/architecture.md#grafana) | GitLab environment monitoring | [Monitoring node for scaling](../high_availability/monitoring_node.md) | Yes |

## Footnotes

1. In our architectures we run each GitLab Rails node using the Puma webserver
   and have its number of workers set to 90% of available CPUs along with four threads. For
   nodes that are running Rails with other components the worker value should be reduced
   accordingly where we've found 50% achieves a good balance but this is dependent
   on workload.

1. Gitaly node requirements are dependent on customer data, specifically the number of
   projects and their sizes. We recommend two nodes as an absolute minimum,
   and at least four nodes should be used when supporting 50,000 or more users.
   We also recommend that each Gitaly node should store no more than 5TB of data
   and have the number of [`gitaly-ruby` workers](../gitaly/index.md#gitaly-ruby)
   set to 20% of available CPUs. Additional nodes should be considered in conjunction
   with a review of expected data size and spread based on the recommendations above.

1. Recommended Redis setup differs depending on the size of the architecture.
   For smaller architectures (less than 3,000 users) a single instance should suffice.
   For medium sized installs (3,000 - 5,000) we suggest one Redis cluster for all
   classes and that Redis Sentinel is hosted alongside Consul.
   For larger architectures (10,000 users or more) we suggest running a separate
   [Redis Cluster](../high_availability/redis.md#running-multiple-redis-clusters) for the Cache class
   and another for the Queues and Shared State classes respectively. We also recommend
   that you run the Redis Sentinel clusters separately for each Redis Cluster.

1. For data objects such as LFS, Uploads, Artifacts, etc. We recommend an [Object Storage service](../object_storage.md)
   over NFS where possible, due to better performance.

1. NFS can be used as an alternative for object storage but this isn't typically
   recommended for performance reasons. Note however it is required for [GitLab
   Pages](https://gitlab.com/gitlab-org/gitlab-pages/-/issues/196).

1. Our architectures have been tested and validated with [HAProxy](https://www.haproxy.org/)
   as the load balancer. Although other load balancers with similar feature sets
   could also be used, those load balancers have not been validated.

1. We strongly recommend that any Gitaly or NFS nodes be set up with SSD disks over
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

1. From GitLab 13.0, using NFS for Git repositories is deprecated. In GitLab
   14.0, support for NFS for Git repositories is scheduled to be removed.
   Upgrade to [Gitaly Cluster](../gitaly/praefect.md) as soon as possible.
