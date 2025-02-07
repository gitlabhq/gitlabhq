---
stage: Systems
group: Distribution
description: Prerequisites for installation.
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab installation requirements
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

This page contains information about the system requirements to install GitLab.

## Storage

The necessary storage space largely depends on the size of the repositories you want to have in GitLab.
As a guideline, you should have at least as much free space as all your repositories combined.

The Linux package requires about 2.5 GB of storage space for installation.
For storage flexibility, consider mounting your hard drive through logical volume management.
You should have a hard drive with at least 7,200 RPM or a solid-state drive to reduce response times.

Because file system performance might affect the overall performance of GitLab, you should
[avoid using cloud-based file systems for storage](../administration/nfs.md#avoid-using-cloud-based-file-systems).

## CPU

CPU requirements depend on the number of users and expected workload.
The workload includes your users' activity, use of automation and mirroring, and repository size.

For a maximum of 20 requests per second or 1,000 users, you should have 8 vCPU.
For more users or higher workload,
see [reference architectures](../administration/reference_architectures/_index.md).

## Memory

Memory requirements depend on the number of users and expected workload.
The workload includes your users' activity, use of automation and mirroring, and repository size.

For a maximum of 20 requests per second or 1,000 users, you should have 16 GB of memory.
For more users or higher workload,
see [reference architectures](../administration/reference_architectures/_index.md).

In some cases, GitLab can run with at least 8 GB of memory.
For more information, see
[running GitLab in a memory-constrained environment](https://docs.gitlab.com/omnibus/settings/memory_constrained_envs.html).

## PostgreSQL

[PostgreSQL](https://www.postgresql.org/) is the only supported database and is bundled with the Linux package.
You can also use an [external PostgreSQL database](https://docs.gitlab.com/omnibus/settings/database.html#using-a-non-packaged-postgresql-database-management-server)
[which must be tuned correctly](#postgresql-tuning).

Depending on the [number of users](../administration/reference_architectures/_index.md),
the PostgreSQL server should have:

- For most GitLab instances, at least 5 to 10 GB of storage
- For GitLab Ultimate, at least 12 GB of storage
  (1 GB of vulnerability data must be imported)

For the following versions of GitLab, use these PostgreSQL versions:

| GitLab version | Minimum PostgreSQL version | Maximum PostgreSQL version |
| -------------- | -------------------------- | -------------------------- |
| 18.x           | 16.x (proposed in [epic 12172](https://gitlab.com/groups/gitlab-org/-/epics/12172)) | To be determined |
| 17.x           | 14.x                       | 16.x ([tested against GitLab 16.10 and later](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/145298)) |
| 16.x           | 13.6                       | 15.x ([tested against GitLab 16.1 and later](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/119344)) |
| 15.x           | 12.10                      | 14.x ([tested against GitLab 15.11 only](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/114624)), 13.x |

Minor PostgreSQL releases [include only bug and security fixes](https://www.postgresql.org/support/versioning/).
Always use the latest minor version to avoid known issues in PostgreSQL.
For more information, see [issue 364763](https://gitlab.com/gitlab-org/gitlab/-/issues/364763).

To use a later major version of PostgreSQL than specified, check if a
[later version is bundled with the Linux package](http://gitlab-org.gitlab.io/omnibus-gitlab/licenses.html).

You must also ensure some extensions are loaded into every GitLab database.
For more information, see [managing PostgreSQL extensions](postgresql_extensions.md).

### GitLab Geo

For [GitLab Geo](../administration/geo/_index.md), you should use the Linux package or
[validated cloud providers](../administration/reference_architectures/_index.md#recommended-cloud-providers-and-services)
to install GitLab.
Compatibility with other external databases is not guaranteed.

For more information, see [requirements for running Geo](../administration/geo/_index.md#requirements-for-running-geo).

### Locale compatibility

When you change locale data in `glibc`, PostgreSQL database files are
no longer fully compatible between different operating systems.
To avoid index corruption,
[check for locale compatibility](../administration/geo/replication/troubleshooting/common.md#check-os-locale-data-compatibility)
when you:

- Move binary PostgreSQL data between servers.
- Upgrade your Linux distribution.
- Update or change third-party container images.

For more information, see [upgrading operating systems for PostgreSQL](../administration/postgresql/upgrading_os.md).

### GitLab schemas

You should create or use databases exclusively for GitLab, [Geo](../administration/geo/_index.md),
[Gitaly Cluster](../administration/gitaly/praefect.md), or other components.
Do not create or modify databases, schemas, users, or other properties except when you follow:

- Procedures in the GitLab documentation
- The directions of GitLab Support or engineers

The main GitLab application uses three schemas:

- The default `public` schema
- `gitlab_partitions_static` (created automatically)
- `gitlab_partitions_dynamic` (created automatically)

During Rails database migrations, GitLab might create or modify schemas or tables.
Database migrations are tested against the schema definition in the GitLab codebase.
If you modify any schema, [GitLab upgrades](../update/_index.md) might fail.

### PostgreSQL tuning

Here are some required settings for externally managed PostgreSQL instances.

| Tunable setting        | Required value | More information |
|:-----------------------|:---------------|:-----------------|
| `work_mem`             | minimum `8MB`  | This value is the Linux package default. In large deployments, if queries create temporary files, you should increase this setting. |
| `maintenance_work_mem` | minimum `64MB` | You require [more for larger database servers](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/8377#note_1728173087). |
| `shared_buffers`       | minimum `2GB`  | You require more for larger database servers. The Linux package default is set to 25% of server RAM. |
| `statement_timeout`    | maximum 1 min  | A statement timeout prevents runaway issues with locks and the database rejecting new clients. One minute matches the Puma rack timeout setting. |

## Puma

The recommended [Puma](https://puma.io/) settings depend on your [installation](install_methods.md).
By default, the Linux package uses the recommended settings.

To adjust Puma settings:

- For the Linux package, see [Puma settings](../administration/operations/puma.md).
- For the GitLab Helm chart, see the
  [`webservice` chart](https://docs.gitlab.com/charts/charts/gitlab/webservice/index.html).

### Workers

The recommended number of Puma workers largely depends on CPU and memory capacity.
By default, the Linux package uses the recommended number of workers.
For more information about how this number is calculated,
see [`puma.rb`](https://gitlab.com/gitlab-org/omnibus-gitlab/-/blob/master/files/gitlab-cookbooks/gitlab/libraries/puma.rb?ref_type=heads#L46-69).

A node must never have fewer than two Puma workers.
For example, a node should have:

- Two workers for 2 CPU cores and 8 GB of memory
- Two workers for 4 CPU cores and 4 GB of memory
- Four workers for 4 CPU cores and 8 GB of memory
- Six workers for 8 CPU cores and 8 GB of memory
- Eight workers for 8 CPU cores and 16 GB of memory

By default, each Puma worker is limited to 1.2 GB of memory.
You can [adjust this setting](../administration/operations/puma.md#reducing-memory-use) in `/etc/gitlab/gitlab.rb`.

You can also increase the number of Puma workers, provided enough CPU and memory capacity is available.
More workers would reduce response times and improve the ability to handle parallel requests.
Run tests to verify the optimal number of workers for your [installation](install_methods.md).

### Threads

The recommended number of Puma threads depends on total system memory.
A node should use:

- One thread for an operating system with a maximum of 2 GB of memory
- Four threads for an operating system with more than 2 GB of memory

More threads would lead to excessive swapping and lower performance.

## Redis

[Redis](https://redis.io/) stores all user sessions and background tasks
and requires about 25 kB per user on average.

In GitLab 16.0 and later, Redis 6.x or 7.x is required.
For more information about end-of-life dates, see the
[Redis documentation](https://redis.io/docs/latest/operate/rs/installing-upgrading/product-lifecycle/).

For Redis:

- Use a standalone instance (with or without high availability).
  Redis Cluster is not supported.
- Set the [eviction policy](../administration/redis/replication_and_failover_external.md#setting-the-eviction-policy) as appropriate.

## Sidekiq

[Sidekiq](https://sidekiq.org/) uses a multi-threaded process for background jobs.
This process initially consumes more than 200 MB of memory
and might grow over time due to memory leaks.

On a very active server with more than 10,000 billable users,
the Sidekiq process might consume more than 1 GB of memory.

## Prometheus

By default, [Prometheus](https://prometheus.io) and its related exporters are enabled to monitor GitLab.
These processes consume approximately 200 MB of memory.

For more information, see
[monitoring GitLab with Prometheus](../administration/monitoring/prometheus/_index.md).

## Supported web browsers

GitLab supports the following web browsers:

- [Mozilla Firefox](https://www.mozilla.org/en-US/firefox/new/)
- [Google Chrome](https://www.google.com/chrome/)
- [Chromium](https://www.chromium.org/getting-involved/dev-channel/)
- [Apple Safari](https://www.apple.com/safari/)
- [Microsoft Edge](https://www.microsoft.com/en-us/edge?form=MA13QK)

GitLab supports:

- The two most recent major versions of these browsers
- The current minor version of a supported major version

Running GitLab with JavaScript disabled in these browsers is not supported.

## Related topics

- [Install GitLab Runner](https://docs.gitlab.com/runner/install/)
- [Secure your installation](../security/_index.md)
