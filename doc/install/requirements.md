---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Prerequisites for installation.
title: GitLab installation requirements
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

GitLab Self-Managed has specific hardware, component, and infrastructure requirements that
vary based on your deployment size and workload. For larger or distributed deployments, use the
[sizing guide](../administration/reference_architectures/sizing.md) to determine the right
specifications for your environment.

## Hardware

You can deploy GitLab a single node or distributed across multiple nodes. The minimum
hardware requirements for a single-node installation are listed below. For distributed
deployments, requirements are allocated per component type and scale with load. Use the
[sizing guide](../administration/reference_architectures/sizing.md) to determine the right
specifications based on expected load and workload composition.

### CPU

For a single-node installation, 8 vCPU is the baseline. ARM-based processors are supported.
For distributed deployments, CPU is allocated per component type and scales with load.

> [!note]
> Burstable instance types are not recommended due to inconsistent performance.

### Memory

For a single-node installation, 16 GB is the baseline. For distributed deployments, memory
is allocated per component type and scales with load.

For single-node installations in memory-constrained environments, GitLab can run with at least 8 GB of memory.
For more information, see
[running GitLab in a memory-constrained environment](https://docs.gitlab.com/omnibus/settings/memory_constrained_envs/).

> [!note]
> Disable swap where possible. Swap can cause significant performance degradation under load.
> If swap cannot be disabled, provision sufficient memory so GitLab never uses it.

### Storage

Storage requirements are component-specific. For single-node installations, total all requirements on one machine. For distributed deployments, apply each to the relevant node type:

| Component | Minimum storage | Notes |
|-----------|----------------|-------|
| Application nodes (Rails, Sidekiq, Puma) | 40 GB | Package installation (~2.5 GB) plus OS, logs, and temporary files. |
| Repository storage (Gitaly) | At least as much as all repositories combined | See [Gitaly disk requirements](../administration/gitaly/_index.md#disk-requirements). |
| Database (PostgreSQL) | 5-12 GB | See [PostgreSQL storage requirements](#storage-requirements). |

Avoid network file systems such as NFS, Amazon EFS, and Azure Files, as they can significantly affect performance.
For more information, see [avoiding cloud-based file systems](../administration/nfs.md#avoid-using-cloud-based-file-systems).

> [!note]
> For best performance, use SSD-backed storage. This is particularly important for Gitaly, which is I/O intensive.
> Burstable disk types are not recommended due to inconsistent performance.

## Infrastructure

GitLab runs on a range of infrastructure types. The following sections cover supported
platforms and high availability requirements.

### Supported infrastructure

GitLab runs on cloud providers and self-managed infrastructure, provided the underlying
environment meets the hardware and component requirements described in this guide.
Commonly used cloud providers include AWS, GCP, and Azure.
[GitLab Support](https://support.gitlab.com/hc/en-us/articles/11625911285404-Statement-of-Support) covers GitLab itself; issues with the underlying infrastructure or platform are outside its scope.

For Cloud Native deployments, GitLab runs on any Kubernetes distribution meeting the
[GitLab Helm chart prerequisites](https://docs.gitlab.com/charts/installation/tools/).
Kubernetes platform-specific behavior such as networking, storage classes, and authentication is outside the scope of GitLab Support.

### High availability

HA deployments have specific network requirements:

- Latency between nodes must be lower than 5 ms to support synchronous replication.
- Deploying across availability zones is recommended for resilience. Use an odd number of zones to satisfy quorum requirements.
- Deploying across multiple self-managed data centers requires synchronous-capable latency, redundant network links, and an odd number of centers in the same geographic region.

> [!warning]
> A single GitLab instance must not span multiple geographic regions. For multi-region
> deployments, use [GitLab Geo](../administration/geo/_index.md), which is designed for
> geographically distributed installations.
> Infrastructure-related issues in multi-data-center deployments might be outside the scope of GitLab Support.

## Component requirements

### PostgreSQL

[PostgreSQL](https://www.postgresql.org/) is the only supported database and is available:

- As a [bundled instance](https://docs.gitlab.com/omnibus/settings/database/) with the Linux package.
- As an [external service](https://docs.gitlab.com/omnibus/settings/database/#using-a-non-packaged-postgresql-database-management-server).

For external instances, see:

- [Required settings](../administration/postgresql/tune.md#required-settings-for-external-instances) for externally managed instances.
- [Database schemas](../administration/postgresql/external.md#database-schemas) for schema guidance.
- [When to check locale compatibility](../administration/postgresql/upgrading_os.md#when-to-check-locale-compatibility) for locale considerations.

#### Supported versions

For the following versions of GitLab, use these PostgreSQL versions:

| GitLab version | Helm chart version | Minimum PostgreSQL version | Maximum PostgreSQL version |
| -------------- | ------------------ | -------------------------- | -------------------------- |
| 19.x           | 10.x               | 17.x                       | 17.x                       |
| 18.x           | 9.x                | [16.5](https://gitlab.com/gitlab-org/gitlab/-/issues/508672) | 17.x ([tested against GitLab 17.10 and later](https://gitlab.com/gitlab-org/gitlab/-/issues/521159)) |
| 17.x           | 8.x                | [14.14](https://gitlab.com/gitlab-org/gitlab/-/issues/508672) | 16.x ([tested against GitLab 16.10 and later](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/145298)) |
| 16.x           | 7.x                | 13.6                       | 15.x ([tested against GitLab 16.1 and later](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/119344)) |

Minor PostgreSQL releases [include only bug and security fixes](https://www.postgresql.org/support/versioning/).
Always use the latest minor version to avoid known issues in PostgreSQL.
For more information, see [issue 364763](https://gitlab.com/gitlab-org/gitlab/-/issues/364763).

To use a later major version of PostgreSQL than specified, check if a
[later version is bundled with the Linux package](http://gitlab-org.gitlab.io/omnibus-gitlab/licenses.html).

#### Storage requirements

Depending on the [number of users](../administration/reference_architectures/_index.md),
the PostgreSQL server should have:

- For most GitLab instances, at least 5 to 10 GB of storage.
- For GitLab Ultimate, at least 12 GB of storage
  (1 GB of vulnerability data must be imported).

#### Extensions

To install extensions, PostgreSQL requires superuser privileges. For instructions, see
[Manage PostgreSQL extensions](../administration/postgresql/extensions.md).

| Extension            | Minimum GitLab version | Type        | Database |
|----------------------|------------------------|-------------|----------|
| `amcheck`            | 18.4                   | Required    | Main |
| `btree_gist`         | 13.1                   | Required    | Main |
| `pg_trgm`            | 8.6                    | Required    | Main |
| `plpgsql`            | 11.7                   | Required    | Main, [Geo secondary tracking databases](../administration/geo/_index.md) (minimum version 9.0) |
| `pg_stat_statements` | -                      | Recommended | All |

#### Gitaly Cluster (Praefect)

[Gitaly Cluster](../administration/gitaly/praefect/_index.md) requires a dedicated PostgreSQL instance separate from the main GitLab database.
For full HA, use a third-party PostgreSQL solution.
A non-HA PostgreSQL instance using the Linux package is sufficient for environments that don't require database-level redundancy for Gitaly.

### Redis or Valkey

[Redis](https://redis.io/) or [Valkey](https://valkey.io/) stores all user sessions and background tasks.

The supported versions of Redis or Valkey are:

| Datastore | Recommended version | Minimum version |
| --------- | ------------------- | --------------- |
| Redis     | 7.2                 | 7.0<sup>1</sup> |
| Valkey    | 7.2                 | 7.2             |

<sup>1</sup> Redis 7.0 has reached end-of-life (EOL) upstream, but in some cases is actively
maintained by vendors. For example, Amazon ElastiCache for Redis 7.1 uses its own version number
but is built on Redis 7.0.

For more information about end-of-life dates for Redis, see the
[Redis documentation](https://redis.io/docs/latest/operate/oss_and_stack/install/version-mgmt/).

- Use a standalone instance (with or without high availability).
  Redis Cluster is not supported.
- Serverless Redis and Valkey variants are not supported.
- Set the [eviction policy](../administration/redis/replication_and_failover_external.md#setting-the-eviction-policy) as appropriate.

### Puma

The recommended [Puma](https://puma.io/) settings depend on your [installation](install_methods.md).
By default, the Linux package uses the recommended settings.

To adjust Puma settings:

- For the Linux package, see [Puma settings](../administration/operations/puma.md).
- For the GitLab Helm chart, see the
  [`webservice` chart](https://docs.gitlab.com/charts/charts/gitlab/webservice/).

For worker and thread sizing guidance, see
[Puma worker and thread sizing](../administration/operations/puma.md#worker-and-thread-sizing).

### Sidekiq

[Sidekiq](https://sidekiq.org/) processes background jobs using multiple threads.
Each process requires at least 200 MB of memory and can grow significantly under load.
For environments with more than 10,000 users, allocate at least 1 GB per Sidekiq process.

### Object storage

Object storage is required for distributed deployments and recommended for all installations.
It stores binary data including LFS objects, CI/CD artifacts, uploads, container registry data, and backups.

Use any S3-compatible object storage service. For configuration and a list of tested providers, see
[object storage](../administration/object_storage.md).

## Optional components

These components are not required for a core GitLab installation but have separate infrastructure or resource requirements when used.

### Container Registry

[GitLab Container Registry](../administration/packages/container_registry.md) stores Docker and OCI images for GitLab projects
and requires:

- A domain.
- TLS certificates.
- Either a file system or S3-compatible object storage.

For high-traffic environments, the registry can run on dedicated infrastructure separate from the main GitLab instance.

### GitLab Pages

[GitLab Pages](../administration/pages/_index.md) hosts static websites for projects and groups.
It runs as a separate daemon and requires a wildcard DNS record.
Custom domain support requires a secondary IP address and TLS certificates.

### Elasticsearch and OpenSearch

[Advanced search](../integration/advanced_search/elasticsearch.md) powers faster and more capable search across GitLab content.
It requires a separate Elasticsearch or OpenSearch cluster.
Cluster size depends on the volume of indexed data.

### Prometheus

[Prometheus](https://prometheus.io) monitoring is bundled with the Linux package and enabled by default.
For information on configuring or disabling it, see
[monitoring GitLab with Prometheus](../administration/monitoring/prometheus/_index.md).

### Zoekt

[Zoekt](../integration/zoekt/_index.md) provides exact code search across repositories
and runs as a separate service. For resource requirements, see
[Zoekt administration](../integration/zoekt/_index.md).

### ClickHouse

[ClickHouse](../integration/clickhouse.md) is an open-source column-oriented database used for product analytics features.
It runs as a separate database service. For resource requirements, see
[ClickHouse configuration](../integration/clickhouse.md).

### AI Gateway

[AI Gateway](install_ai_gateway.md) provides the backend service for GitLab Duo AI features.
It runs as a standalone service deployable on Docker or Kubernetes. For resource requirements,
see the installation guide.

### Secrets Manager

[GitLab Secrets Manager](../administration/secrets_manager/_index.md) provides native secrets management powered by OpenBao.
It runs as a separate Kubernetes service and requires a dedicated PostgreSQL database and load balancer.

## Supported web browsers

GitLab supports the following web browsers:

- [Mozilla Firefox](https://www.mozilla.org/en-US/firefox/new/)
- [Google Chrome](https://www.google.com/chrome/)
- [Chromium](https://www.chromium.org/getting-involved/dev-channel/)
- [Apple Safari](https://www.apple.com/safari/)
- [Microsoft Edge](https://www.microsoft.com/en-us/edge?form=MA13QK)

GitLab targets the [Baseline](https://web-platform-dx.github.io/baseline/) Widely available
browser set. These are the browser versions that support web platform features stable across
all core browsers. A feature reaches Widely available status after at least 30 months. The
Widely available browser set includes both desktop and mobile versions of these browsers.

Running GitLab with JavaScript disabled in these browsers is not supported.

## Related topics

- [Install GitLab Runner](https://docs.gitlab.com/runner/install/)
- [Secure your installation](../security/_index.md)
- [Requirements for running Geo](../administration/geo/_index.md#requirements-for-running-geo)
