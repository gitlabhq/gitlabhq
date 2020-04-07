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
| [GitLab application services](../../development/architecture.md#unicorn) | Unicorn/Puma, Workhorse, GitLab Shell - serves front-end requests requests (UI, API, Git over HTTP/SSH) | [GitLab app scaling configuration](../high_availability/gitlab.md) |
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
