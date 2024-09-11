---
stage: Systems
group: Distribution
description: Prerequisites for installation.
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Installation system requirements

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** Self-managed

This page contains information about the minimum system requirements to install GitLab.

## Hardware

### Storage

The necessary storage space largely depends on the size of the repositories you want to have in GitLab.
As a guideline, you should have at least as much free space as all your repositories combined.

The Linux package requires about 2.5 GB of storage space for installation.
For storage flexibility, consider mounting your hard drive through logical volume management.
You should have a hard drive with at least 7200 RPM or a solid-state drive to improve the responsiveness of GitLab.

Because file system performance might affect the overall performance of GitLab, you should
[avoid using cloud-based file systems for storage](../administration/nfs.md#avoid-using-cloud-based-file-systems).

### CPU

CPU requirements depend on the number of users and expected workload.
The workload includes your users' activity, use of automation and mirroring, and repository size.

For a maximum of 20 requests per second or 1,000 users, you should have 8 vCPUs.
For more users or higher workload,
see [reference architectures](../administration/reference_architectures/index.md).

### Memory

Memory requirements depend on the number of users and expected workload.
The workload includes your users' activity, use of automation and mirroring, and repository size.

For a maximum of 20 requests per second or 1,000 users, you should have 16 GB of memory.
For more users or higher workload,
see [reference architectures](../administration/reference_architectures/index.md).

In certain circumstances, GitLab might run in a
[memory-constrained environment](https://docs.gitlab.com/omnibus/settings/memory_constrained_envs.html).

## Database

### PostgreSQL

PostgreSQL is the only supported database and is bundled with the Linux package.
You can also use an [external PostgreSQL database](https://docs.gitlab.com/omnibus/settings/database.html#using-a-non-packaged-postgresql-database-management-server).

Depending on the [number of users](../administration/reference_architectures/index.md),
the PostgreSQL server should have:

- For most GitLab instances, at least 5 to 10 GB of storage
- For GitLab Ultimate, at least 12 GB of storage
  (1 GB of vulnerability data must be imported)

For the following versions of GitLab, use these PostgreSQL versions:

| GitLab version | Minimum PostgreSQL version | Maximum PostgreSQL version |
| -------------- | -------------------------- | -------------------------- |
| 17.x           | 14.9                       | 15.x                       |
| 16.x           | 13.6                       | 15.x ([tested against GitLab 16.1 and later](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/119344)) |
| 15.x           | 12.10                      | 14.x ([tested against GitLab 15.11 only](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/114624)), 13.x |

Minor PostgreSQL releases [include only bug and security fixes](https://www.postgresql.org/support/versioning/).
Always use the latest minor version to avoid known issues in PostgreSQL.
For more information, see [issue 364763](https://gitlab.com/gitlab-org/gitlab/-/issues/364763).

To use a later major version of PostgreSQL than specified, check if a
[later version is bundled with the Linux package](http://gitlab-org.gitlab.io/omnibus-gitlab/licenses.html).

You must also ensure some extensions are loaded into every GitLab database.
For more information, see [managing PostgreSQL extensions](postgresql_extensions.md).

#### GitLab Geo

For [GitLab Geo](../administration/geo/index.md), you should use the Linux package or
[validated cloud providers](../administration/reference_architectures/index.md#recommended-cloud-providers-and-services)
to install GitLab.
Compatibility with other external databases is not guaranteed.

For more information, see [requirements for running Geo](../administration/geo/index.md#requirements-for-running-geo).

#### Locale compatibility

When you change locale data in `glibc`, PostgreSQL database files are
no longer fully compatible between different operating systems.
To avoid index corruption,
[check for locale compatibility](../administration/geo/replication/troubleshooting/common.md#check-os-locale-data-compatibility)
when you:

- Move binary PostgreSQL data between servers.
- Upgrade your Linux distribution.
- Update or change third-party container images.

For more information, see [upgrading operating systems for PostgreSQL](../administration/postgresql/upgrading_os.md).

#### GitLab schemas

You should create or use databases exclusively for GitLab, [Geo](../administration/geo/index.md),
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
If you modify any schema, [GitLab upgrades](../update/index.md) might fail.

## Puma

The recommended settings for Puma are determined by the infrastructure on which it's running.
The Linux package defaults to the recommended Puma settings. Regardless of installation method, you can
tune the Puma settings:

- If you're using the Linux package, see [Puma settings](../administration/operations/puma.md)
  for instructions on changing the Puma settings.
- If you're using the GitLab Helm chart, see the
  [`webservice` chart](https://docs.gitlab.com/charts/charts/gitlab/webservice/index.html).

### Workers

The recommended number of workers is calculated as the highest of the following:

- `2`
- A combination of CPU and memory resource availability (see how this is configured automatically for the [Linux package](https://gitlab.com/gitlab-org/omnibus-gitlab/-/blob/ef9facdc927e7389db6a5e0655414ba8318c7b8a/files/gitlab-cookbooks/gitlab/libraries/puma.rb#L31-46)).

By default, each Puma worker is limited to 1.2 GB of memory.
To increase the number of Puma workers, set
[`puma['per_worker_max_memory_mb']`](../administration/operations/puma.md#reducing-memory-use) to a higher limit.

Take for example the following scenarios:

- A node with 2 cores / 8 GB memory should be configured with **2 Puma workers**.

  Calculated as:

  ```plaintext
  The highest number from
  2
  And
  [
  the lowest number from
    - number of cores: 2
    - memory limit: (8 - 1.5) = 6.5
  ]
  ```

  So, the highest from 2 and 2 is 2.

- A node with 4 cores / 4 GB memory should be configured with **2 Puma workers**.

  ```plaintext
  The highest number from
  2
  And
  [
  the lowest number from
    - number of cores: 4
    - memory limit: (4 - 1.5) = 2.5
  ]
  ```

  So, the highest from 2 and 2 is 2.

- A node with 4 cores / 8 GB memory should be configured with **4 Puma workers**.

  ```plaintext
  The highest number from
  2
  And
  [
  the lowest number from
    - number of cores: 4
    - memory limit: (8 - 1.5) = 6.5
  ]
  ```

  So, the highest from 2 and 4 is 4.

You can increase the number of Puma workers, provided enough CPU and memory capacity is available.
A higher number of Puma workers usually helps to reduce the response time of the application
and increase the ability to handle parallel requests. You must perform testing to verify the
optimal settings for your infrastructure.

### Threads

The recommended number of threads is dependent on several factors, including total memory.

- If the operating system has a maximum 2 GB of memory, the recommended number of threads is `1`.
  A higher value results in excess swapping, and decrease performance.
- In all other cases, the recommended number of threads is `4`. We don't recommend setting this
  higher, due to how [Ruby MRI multi-threading](https://en.wikipedia.org/wiki/Global_interpreter_lock)
  works.

## Redis

Redis stores all user sessions and the background task queue.

The requirements for Redis are as follows:

- Redis 6.x or 7.x is required in GitLab 16.0 and later. However, you should upgrade to
  Redis 6.2.14 or later as [Redis 6.0 is no longer supported](https://endoflife.date/redis).
- Redis Cluster mode is not supported. Redis Standalone must be used, with or without HA.
- Storage requirements for Redis are minimal, about 25 kB per user on average.
- [Redis eviction mode](../administration/redis/replication_and_failover_external.md#setting-the-eviction-policy) set appropriately.

## Sidekiq

Sidekiq processes the background jobs with a multi-threaded process.
This process starts with the entire Rails stack (200 MB+) but it can grow over time due to memory leaks.
On a very active server (10,000 billable users) the Sidekiq process can use 1 GB+ of memory.

## Prometheus

By default, [Prometheus](https://prometheus.io) and its related exporters are enabled to monitor GitLab.
These processes consume approximately 200 MB of memory.

For more information, see
[monitoring GitLab with Prometheus](../administration/monitoring/prometheus/index.md).

## Supported web browsers

GitLab supports the following web browsers:

- [Mozilla Firefox](https://www.mozilla.org/en-US/firefox/new/)
- [Google Chrome](https://www.google.com/chrome/)
- [Chromium](https://www.chromium.org/getting-involved/dev-channel/)
- [Apple Safari](https://www.apple.com/safari/)
- [Microsoft Edge](https://www.microsoft.com/en-us/edge?form=MA13QK)

GitLab supports:

- The current and earlier major versions of these browsers
- The current minor version of a supported major version

Running GitLab with JavaScript disabled in these browsers is not supported.

## Related topics

- [Install GitLab Runner](https://docs.gitlab.com/runner/install/)
- [Secure your installation](../security/index.md)
