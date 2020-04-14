---
type: reference, concepts
---

# Availability

GitLab offers high availability options for organizations that require
the fault tolerance and redundancy necessary to maintain high-uptime operations.

Please consult our [scaling documentation](../scaling) if you want to resolve
performance bottlenecks you encounter in individual GitLab components without
incurring the additional complexity costs associated with maintaining a
highly-available architecture.

On this page, we present examples of self-managed instances which demonstrate
how GitLab can be scaled out and made highly available. These examples progress
from simple to complex as scaling or highly-available components are added.

For larger setups serving 2,000 or more users, we provide
[reference architectures](../scaling/index.md#reference-architectures) based on GitLab's
experience with GitLab.com and internal scale testing that aim to achieve the
right balance of scalability and availability.

For detailed insight into how GitLab scales and configures GitLab.com, you can
watch [this 1 hour Q&A](https://www.youtube.com/watch?v=uCU8jdYzpac)
with [John Northrup](https://gitlab.com/northrup), and live questions coming
in from some of our customers.

GitLab offers a number of options to manage availability and resiliency. Below are the options to consider with trade-offs.

| Event | GitLab Feature | Recovery Point Objective (RPO) | Recovery Time Objective (RTO) | Cost |
| ----- | -------------- | --- | --- | ---- |
| Availability Zone failure | "GitLab HA" | No loss | No loss | 2x Git storage, multiple nodes balanced across AZ's |
| Region failure | "GitLab Disaster Recovery" | 5-10 minutes | 30 minutes | 2x primary cost |
| All failures | Backup/Restore | Last backup | Hours to Days | Cost of storing the backups |

## High availability

### Omnibus installation with automatic database failover

By adding automatic failover for database systems, we can enable higher uptime with an additional layer of complexity.

- For PostgreSQL, we provide repmgr for server cluster management and failover
  and a combination of [PgBouncer](../high_availability/pgbouncer.md) and [Consul](../high_availability/consul.md) for
  database client cutover.
- For Redis, we use [Redis Sentinel](../high_availability/redis.md) for server failover and client cutover.

You can also optionally run [additional Sidekiq processes on dedicated hardware](../high_availability/sidekiq.md)
and configure individual Sidekiq processes to
[process specific background job queues](../operations/extra_sidekiq_processes.md)
if you need to scale out background job processing.

### GitLab Geo

GitLab Geo allows you to replicate your GitLab instance to other geographical locations as a read-only fully operational instance that can also be promoted in case of disaster.

This configuration is supported in [GitLab Premium and Ultimate](https://about.gitlab.com/pricing/).

References:

- [Geo Documentation](../geo/replication/index.md)
- [GitLab Geo with a highly available configuration](../geo/replication/high_availability.md)

## GitLab components and configuration instructions

The GitLab application depends on the following [components](../../development/architecture.md#component-diagram).
It can also depend on several third party services depending on
your environment setup. Here we'll detail both in the order in which
you would typically configure them along with our recommendations for
their use and configuration.

### Third party services

Here's some details of several third party services a typical environment
will depend on. The services can be provided by numerous applications
or providers and further advice can be given on how best to select.
These should be configured first, before the [GitLab components](#gitlab-components).

| Component                                              | Description                                                                                                         | Configuration instructions                              |
|--------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------|
| [Load Balancer(s)](../high_availability/load_balancer.md)[^6]               | Handles load balancing for the GitLab nodes where required                                                          | [Load balancer HA configuration](../high_availability/load_balancer.md)      |
| [Cloud Object Storage service](../high_availability/object_storage.md)[^4]  | Recommended store for shared data objects                                                                           | [Cloud Object Storage configuration](../high_availability/object_storage.md) |
| [NFS](../high_availability/nfs.md)[^5] [^7]                                 | Shared disk storage service. Can be used as an alternative for Gitaly or Object Storage. Required for GitLab Pages  | [NFS configuration](../high_availability/nfs.md)                             |

### GitLab components

Next are all of the components provided directly by GitLab. As mentioned
earlier, they are presented in the typical order you would configure
them.

| Component                                                                                                           | Description                                                         | Configuration instructions                                    |
|---------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------|---------------------------------------------------------------|
| [Consul](../../development/architecture.md#consul)[^3]                                                              | Service discovery and health checks/failover                        | [Consul HA configuration](../high_availability/consul.md) **(PREMIUM ONLY)**       |
| [PostgreSQL](../../development/architecture.md#postgresql)                                                          | Database                                                            | [Database HA configuration](../high_availability/database.md)                      |
| [PgBouncer](../../development/architecture.md#pgbouncer)                                                            | Database Pool Manager                                               | [PgBouncer HA configuration](../high_availability/pgbouncer.md) **(PREMIUM ONLY)** |
| [Redis](../../development/architecture.md#redis)[^3] with Redis Sentinel                                            | Key/Value store for shared data with HA watcher service             | [Redis HA configuration](../high_availability/redis.md)                            |
| [Gitaly](../../development/architecture.md#gitaly)[^2] [^5] [^7]                                                    | Recommended high-level storage for Git repository data              | [Gitaly HA configuration](../high_availability/gitaly.md)                          |
| [Sidekiq](../../development/architecture.md#sidekiq)                                                                | Asynchronous/Background jobs                                        | [Sidekiq configuration](../high_availability/sidekiq.md)                           |
| [GitLab application nodes](../../development/architecture.md#unicorn)[^1]                                           | (Unicorn / Puma, Workhorse) - Web-requests (UI, API, Git over HTTP) | [GitLab app HA/scaling configuration](../high_availability/gitlab.md)              |
| [Prometheus](../../development/architecture.md#prometheus) and [Grafana](../../development/architecture.md#grafana) | GitLab environment monitoring                                       | [Monitoring node for scaling/HA](../high_availability/monitoring_node.md)          |

In some cases, components can be combined on the same nodes to reduce complexity as well.

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
