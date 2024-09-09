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

The server running PostgreSQL should have a certain amount of storage available, though the exact amount
[depends on the number of users](../administration/reference_architectures/index.md). For:

- Most GitLab self-managed instances, at least 5 to 10 GB of storage available.
- GitLab self-managed instance at the Ultimate tier, at least 12 GB of storage available, because 1 GB of vulnerability
  data must be imported.

You should use the versions of PostgreSQL specified in the following table for your version of GitLab because these were
used for development and testing:

| GitLab version | Minimum PostgreSQL version<sup>1</sup> | Maximum PostgreSQL version<sup>2</sup> |
|:---------------|:---------------------------------------|:---------------------------------------|
| 15.x           | 12.10                                  | 13.x (14.x<sup>3</sup>)                |
| 16.x           | 13.6                                   | 15.x<sup>4</sup>                       |
| 17.x           | 14.9                                   | 15.x<sup>4</sup>                       |

**Footnotes:**

1. PostgreSQL minor release upgrades (for example 14.8 to 14.9) [include only bug and security fixes](https://www.postgresql.org/support/versioning/).
   Patch levels in this table are not prescriptive. Always deploy the most recent patch level
   to avoid [known bugs in PostgreSQL that might be triggered by GitLab](https://gitlab.com/gitlab-org/gitlab/-/issues/364763).
1. If you want to run a later major release of PostgreSQL than the specified minimum
   [check if a more recent version shipped with Linux package (Omnibus) GitLab](http://gitlab-org.gitlab.io/omnibus-gitlab/licenses.html).
   `postgresql-new` is a later version that's definitely supported.
1. PostgreSQL 14.x [tested against GitLab 15.11 only](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/114624).
1. [Tested against GitLab 16.1 and later](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/119344).

You must also ensure the following extensions are loaded into every GitLab database.
For more information, see [managing PostgreSQL extensions](postgresql_extensions.md).

| Extension    | Minimum GitLab version |
| ------------ | ---------------------- |
| `pg_trgm`    | 8.6                    |
| `btree_gist` | 13.1                   |
| `plpgsql`    | 11.7                   |

The following managed PostgreSQL services are known to be incompatible and should not be used:

| GitLab version | Managed service                                       |
|----------------|-------------------------------------------------------|
| 14.4+          | Amazon Aurora (see [14.4.0](../update/versions/gitlab_14_changes.md#1440)) |

#### GitLab Geo

If you're using [GitLab Geo](../administration/geo/index.md), we strongly recommend running instances installed by using the Linux package or using
[validated cloud-managed instances](../administration/reference_architectures/index.md#recommended-cloud-providers-and-services),
as we actively develop and test based on those.
We cannot guarantee compatibility with other external databases.

For more information, see [requirements for running Geo](../administration/geo/index.md#requirements-for-running-geo).

#### Locale compatibility

Changes to locale data in `glibc` means that PostgreSQL database files are not fully compatible
between different OS releases.

To avoid index corruption, [check for locale compatibility](../administration/geo/replication/troubleshooting/common.md#check-os-locale-data-compatibility)
when:

- Moving binary PostgreSQL data between servers.
- Upgrading your Linux distribution.
- Updating or changing third party container images.

For more information, see how to [upgrade operating systems for PostgreSQL](../administration/postgresql/upgrading_os.md).

#### GitLab schemas

Databases created or used for GitLab, Geo, [Gitaly Cluster](../administration/gitaly/praefect.md), or other components should be for the
exclusive use of GitLab. Do not make direct changes to the database, schemas, users, or other
properties except when following procedures in the GitLab documentation or following the directions
of GitLab Support or other GitLab engineers.

- The main GitLab application uses three schemas:

  - The default `public` schema
  - `gitlab_partitions_static` (automatically created)
  - `gitlab_partitions_dynamic` (automatically created)

  No other schemas should be manually created.

- GitLab may create new schemas as part of Rails database migrations. This happens when performing
  a GitLab upgrade. The GitLab database account requires access to do this.

- GitLab creates and modifies tables during the upgrade process, and also as part of standard
  operations to manage partitioned tables.

- You should not modify the GitLab schema (for example, adding triggers or modifying tables).
  Database migrations are tested against the schema definition in the GitLab codebase. GitLab
  version upgrades may fail if the schema is modified.

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

## GitLab Runner

We strongly advise against installing GitLab Runner on the same machine you plan
to install GitLab on. Depending on how you decide to configure GitLab Runner and
what tools you use to exercise your application in the CI environment, GitLab
Runner can consume significant amount of available memory.

Memory consumption calculations, that are available above, are not valid if
you decide to run GitLab Runner and the GitLab Rails application on the same
machine.

It's also not safe to install everything on a single machine, because of the
[security reasons](https://docs.gitlab.com/runner/security/), especially when you plan to use shell executor with GitLab
Runner.

To use CI/CD features, you should use a separate machine for each GitLab Runner.
The GitLab Runner server requirements depend on:

- The type of [executor](https://docs.gitlab.com/runner/executors/) you configured on GitLab Runner.
- Resources required to run build jobs.
- Job concurrency settings.

Because the nature of the jobs varies for each use case, you must experiment by adjusting the job concurrency to get the optimum setting.

For reference, the [SaaS runners on Linux](../ci/runners/hosted_runners/linux.md)
are configured so that a **single job** runs in a **single instance** with:

- 1 vCPU.
- 3.75 GB of RAM.

## Supported web browsers

GitLab supports the following web browsers:

- [Mozilla Firefox](https://www.mozilla.org/en-US/firefox/new/)
- [Google Chrome](https://www.google.com/chrome/)
- [Chromium](https://www.chromium.org/getting-involved/dev-channel/)
- [Apple Safari](https://www.apple.com/safari/)
- [Microsoft Edge](https://www.microsoft.com/en-us/edge?form=MA13QK)

GitLab supports the:

- Current and previous major versions of these browsers
- Current minor version of a supported major version

Running GitLab with JavaScript disabled in these browsers is not supported.

## Related topics

- [Secure your installation](../security/index.md)
