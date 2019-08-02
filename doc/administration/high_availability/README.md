---
type: reference, concepts
---

# Scaling and High Availability

GitLab supports several different types of clustering and high-availability.
The solution you choose will be based on the level of scalability and
availability you require. The easiest solutions are scalable, but not necessarily
highly available.

GitLab provides a service that is usually essential to most organizations: it
enables people to collaborate on code in a timely fashion. Any downtime should
therefore be short and planned. Luckily, GitLab provides a solid setup even on
a single server without special measures. Due to the distributed nature
of Git, developers can still commit code locally even when GitLab is not
available. However, some GitLab features such as the issue tracker and
Continuous Integration are not available when GitLab is down.

**Keep in mind that all highly-available solutions come with a trade-off between
cost/complexity and uptime**. The more uptime you want, the more complex the
solution. And the more complex the solution, the more work is involved in
setting up and maintaining it. High availability is not free and every HA
solution should balance the costs against the benefits.

There are many options when choosing a highly-available GitLab architecture. We
recommend engaging with GitLab Support to choose the best architecture for your
use-case. This page contains some various options and guidelines based on
experience with GitLab.com and Enterprise Edition on-premises customers.

For a detailed insight into how GitLab scales and configures GitLab.com, you can
watch [this 1 hour Q&A](https://www.youtube.com/watch?v=uCU8jdYzpac)
with [John Northrup](https://gitlab.com/northrup), and live questions coming in from some of our customers.

## GitLab Components

The following components need to be considered for a scaled or highly-available
environment. In many cases components can be combined on the same nodes to reduce
complexity.

- Unicorn/Workhorse - Web-requests (UI, API, Git over HTTP)
- Sidekiq - Asynchronous/Background jobs
- PostgreSQL - Database
  - Consul - Database service discovery and health checks/failover
  - PGBouncer - Database pool manager
- Redis - Key/Value store (User sessions, cache, queue for Sidekiq)
  - Sentinel - Redis health check/failover manager
- Gitaly - Provides high-level RPC access to Git repositories

## Scalable Architecture Examples

When an organization reaches a certain threshold it will be necessary to scale
the GitLab instance. Still, true high availability may not be necessary. There
are options for scaling GitLab instances relatively easily without incurring the
infrastructure and maintenance costs of full high availability.

### Basic Scaling

This is the simplest form of scaling and will work for the majority of
cases. Backend components such as PostgreSQL, Redis and storage are offloaded
to their own nodes while the remaining GitLab components all run on 2 or more
application nodes.

This form of scaling also works well in a cloud environment when it is more
cost-effective to deploy several small nodes rather than a single
larger one.

- 1 PostgreSQL node
- 1 Redis node
- 1 NFS/Gitaly storage server
- 2 or more GitLab application nodes (Unicorn, Workhorse, Sidekiq)
- 1 Monitoring node (Prometheus, Grafana)

#### Installation Instructions

Complete the following installation steps in order. A link at the end of each
section will bring you back to the Scalable Architecture Examples section so
you can continue with the next step.

1. [PostgreSQL](database.md#postgresql-in-a-scaled-environment)
1. [Redis](redis.md#redis-in-a-scaled-environment)
1. [Gitaly](gitaly.md) (recommended) or [NFS](nfs.md)
1. [GitLab application nodes](gitlab.md)
1. [Monitoring node (Prometheus and Grafana)](monitoring_node.md)

### Full Scaling

For very large installations it may be necessary to further split components
for maximum scalability. In a fully-scaled architecture the application node
is split into separate Sidekiq and Unicorn/Workhorse nodes. One indication that
this architecture is required is if Sidekiq queues begin to periodically increase
in size, indicating that there is contention or not enough resources.

- 1 PostgreSQL node
- 1 Redis node
- 2 or more NFS/Gitaly storage servers
- 2 or more Sidekiq nodes
- 2 or more GitLab application nodes (Unicorn, Workhorse)
- 1 Monitoring node (Prometheus, Grafana)

## High Availability Architecture Examples

When organizations require scaling *and* high availability the following
architectures can be utilized. As the introduction section at the top of this
page mentions, there is a tradeoff between cost/complexity and uptime. Be sure
this complexity is absolutely required before taking the step into full
high availability.

For all examples below, we recommend running Consul and Redis Sentinel on
dedicated nodes. If Consul is running on PostgreSQL nodes or Sentinel on
Redis nodes there is a potential that high resource usage by PostgreSQL or
Redis could prevent communication between the other Consul and Sentinel nodes.
This may lead to the other nodes believing a failure has occurred and automated
failover is necessary. Isolating them from the services they monitor reduces
the chances of split-brain.

The examples below do not really address high availability of NFS. Some enterprises
have access to NFS appliances that manage availability. This is the best case
scenario. In the future, GitLab may offer a more user-friendly solution to
[GitLab HA Storage](https://gitlab.com/gitlab-org/omnibus-gitlab/issues/2472).

There are many options in between each of these examples. Work with GitLab Support
to understand the best starting point for your workload and adapt from there.

### Horizontal

This is the simplest form of high availability and scaling. It requires the
fewest number of individual servers (virtual or physical) but does have some
trade-offs and limits.

This architecture will work well for many GitLab customers. Larger customers
may begin to notice certain events cause contention/high load - for example,
cloning many large repositories with binary files, high API usage, a large
number of enqueued Sidekiq jobs, etc. If this happens you should consider
moving to a hybrid or fully distributed architecture depending on what is causing
the contention.

- 3 PostgreSQL nodes
- 2 Redis nodes
- 3 Consul/Sentinel nodes
- 2 or more GitLab application nodes (Unicorn, Workhorse, Sidekiq, PGBouncer)
- 1 NFS/Gitaly server
- 1 Monitoring node (Prometheus, Grafana)

![Horizontal architecture diagram](img/horizontal.png)

### Hybrid

In this architecture, certain components are split on dedicated nodes so high
resource usage of one component does not interfere with others. In larger
environments this is a good architecture to consider if you foresee or do have
contention due to certain workloads.

- 3 PostgreSQL nodes
- 1 PgBouncer node
- 2 Redis nodes
- 3 Consul/Sentinel nodes
- 2 or more Sidekiq nodes
- 2 or more GitLab application nodes (Unicorn, Workhorse)
- 1 or more NFS/Gitaly servers
- 1 Monitoring node (Prometheus, Grafana)

![Hybrid architecture diagram](img/hybrid.png)

#### Reference Architecture

- **Supported Users (approximate):** 10,000
- **Known Issues:** While validating the reference architecture, slow endpoints were discovered and are being investigated. [gitlab-org/gitlab-ce/issues/64335](https://gitlab.com/gitlab-org/gitlab-ce/issues/64335)

The Support and Quality teams built, performance tested, and validated an
environment that supports about 10,000 users. The specifications below are a
representation of the work so far. The specifications may be adjusted in the
future based on additional testing and iteration.

NOTE: **Note:** The specifications here were performance tested against a specific coded workload. Your exact needs may be more, depending on your workload. Your workload is influenced by factors such as - but not limited to - how active your users are, how much automation you use, mirroring, and repo/change size.

- 3 PostgreSQL - 4 CPU, 16GiB memory per node
- 1 PgBouncer - 2 CPU, 4GiB memory
- 2 Redis - 2 CPU, 8GiB memory per node
- 3 Consul/Sentinel - 2 CPU, 2GiB memory per node
- 4 Sidekiq - 4 CPU, 16GiB memory per node
- 5 GitLab application nodes - 16 CPU, 64GiB memory per node
- 1 Gitaly - 16 CPU, 64GiB memory
- 1 Monitoring node - 2 CPU, 8GiB memory, 100GiB local storage

### Fully Distributed

This architecture scales to hundreds of thousands of users and projects and is
the basis of the GitLab.com architecture. While this scales well it also comes
with the added complexity of many more nodes to configure, manage and monitor.

- 3 PostgreSQL nodes
- 4 or more Redis nodes (2 separate clusters for persistent and cache data)
- 3 Consul nodes
- 3 Sentinel nodes
- Multiple dedicated Sidekiq nodes (Split into real-time, best effort, ASAP,
  CI Pipeline and Pull Mirror sets)
- 2 or more Git nodes (Git over SSH/Git over HTTP)
- 2 or more API nodes (All requests to `/api`)
- 2 or more Web nodes (All other web requests)
- 2 or more NFS/Gitaly servers
- 1 Monitoring node (Prometheus, Grafana)

![Fully Distributed architecture diagram](img/fully-distributed.png)

The following pages outline the steps necessary to configure each component
separately:

1. [Configure the database](database.md)
1. [Configure Redis](redis.md)
   1. [Configure Redis for GitLab source installations](redis_source.md)
1. [Configure NFS](nfs.md)
   1. [NFS Client and Host setup](nfs_host_client_setup.md)
1. [Configure the GitLab application servers](gitlab.md)
1. [Configure the load balancers](load_balancer.md)
1. [Monitoring node (Prometheus and Grafana)](monitoring_node.md)
