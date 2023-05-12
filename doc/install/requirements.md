---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Installation system requirements **(FREE SELF)**

This page includes information about the minimum requirements you need to install and use GitLab.

## Software requirements

### Redis versions

GitLab 16.0 and later requires Redis 6.0 or later.

## Hardware requirements

### Storage

The necessary hard drive space largely depends on the size of the repositories you want to store in GitLab but as a *guideline* you should have at least as much free space as all your repositories combined take up.

The Omnibus GitLab package requires about 2.5 GB of storage space for installation.

If you want to be flexible about growing your hard drive space in the future consider mounting it using [logical volume management (LVM)](https://en.wikipedia.org/wiki/Logical_volume_management) so you can add more hard drives when you need them.

Apart from a local hard drive you can also mount a volume that supports the network file system (NFS) protocol. This volume might be located on a file server, a network attached storage (NAS) device, a storage area network (SAN) or on an Amazon Web Services (AWS) Elastic Block Store (EBS) volume.

If you have enough RAM and a recent CPU the speed of GitLab is mainly limited by hard drive seek times. Having a fast drive (7200 RPM and up) or a solid state drive (SSD) improves the responsiveness of GitLab.

NOTE:
Because file system performance may affect the overall performance of GitLab,
[we don't recommend using cloud-based file systems for storage](../administration/nfs.md#avoid-using-cloud-based-file-systems).

NOTE:
[NFS for Git repository storage is deprecated](https://about.gitlab.com/releases/2021/06/22/gitlab-14-0-released/#nfs-for-git-repository-storage-deprecated). See our official [Statement of Support](https://about.gitlab.com/support/statement-of-support/#gitaly-and-nfs) for further information.

### CPU

CPU requirements are dependent on the number of users and expected workload. Your exact needs may be more, depending on your workload. Your workload is influenced by factors such as - but not limited to - how active your users are, how much automation you use, mirroring, and repository/change size.

The following is the recommended minimum CPU hardware guidance for a handful of example GitLab user base sizes.

- **4 cores** is the **recommended** minimum number of cores and supports up to 500 users
- 8 cores supports up to 1000 users
- More users? Consult the [reference architectures page](../administration/reference_architectures/index.md)

### Memory

Memory requirements are dependent on the number of users and expected workload. Your exact needs may be more, depending on your workload. Your workload is influenced by factors such as - but not limited to - how active your users are, how much automation you use, mirroring, and repository/change size.

The following is the recommended minimum Memory hardware guidance for a handful of example GitLab user base sizes.

- **4 GB RAM** is the **required** minimum memory size and supports up to 500 users
  - Our [Memory Team](https://about.gitlab.com/handbook/engineering/development/enablement/data_stores/application_performance/) is working to reduce the memory requirement.
- 8 GB RAM supports up to 1000 users
- More users? Consult the [reference architectures page](../administration/reference_architectures/index.md)

In addition to the above, we generally recommend having at least 2 GB of swap on your server,
even if you currently have enough available RAM. Having swap helps to reduce the chance of errors occurring
if your available memory changes. We also recommend configuring the kernel's swappiness setting
to a low value like `10` to make the most of your RAM while still having the swap
available when needed.

NOTE:
Although excessive swapping is undesired and degrades performance, it is an
extremely important last resort against out-of-memory conditions. During
unexpected system load, such as OS updates or other services on the same host,
peak memory load spikes could be much higher than average. Having plenty of swap
helps avoid the Linux OOM killer unsafely terminating a potentially critical
process, such as PostgreSQL, which can have disastrous consequences.

## Database

PostgreSQL is the only supported database, which is bundled with the Omnibus GitLab package.
You can also use an [external PostgreSQL database](https://docs.gitlab.com/omnibus/settings/database.html#using-a-non-packaged-postgresql-database-management-server).
Support for MySQL was removed in [GitLab 12.1](../update/index.md#1210).

### PostgreSQL Requirements

The server running PostgreSQL should have _at least_ 5-10 GB of storage
available, though the exact requirements [depend on the number of users](../administration/reference_architectures/index.md).

We highly recommend using at least the minimum PostgreSQL versions (as specified in
the following table) as these were used for development and testing:

| GitLab version | Minimum PostgreSQL version |
|----------------|----------------------------|
| 13.0           | 11                         |
| 14.0           | 12.7                      |
| 15.0           | 12.10                      |
| 16.0           | 13.6                       |

You must also ensure the following extensions are loaded into every
GitLab database. [Read more about this requirement, and troubleshooting](postgresql_extensions.md).

| Extension    | Minimum GitLab version |
| ------------ | ---------------------- |
| `pg_trgm`    | 8.6                    |
| `btree_gist` | 13.1                   |
| `plpgsql`    | 11.7                   |

The following managed PostgreSQL services are known to be incompatible and should not be used:

| GitLab version | Managed service                                       |
|----------------|-------------------------------------------------------|
| 14.4+          | Amazon Aurora (see [14.4.0](../update/index.md#1440)) |

NOTE:
Support for [PostgreSQL 9.6 and 10 was removed in GitLab 13.0](https://about.gitlab.com/releases/2020/05/22/gitlab-13-0-released/#postgresql-11-is-now-the-minimum-required-version-to-install-gitlab) so that GitLab can benefit from PostgreSQL 11 improvements, such as partitioning.

#### Additional requirements for GitLab Geo

If you're using [GitLab Geo](../administration/geo/index.md), we strongly
recommend running Omnibus GitLab-managed instances, as we actively develop and
test based on those. We try to be compatible with most external (not managed by
Omnibus GitLab) databases (for example, [AWS Relational Database Service (RDS)](https://aws.amazon.com/rds/)),
but we can't guarantee compatibility.

#### Operating system locale compatibility and silent index corruption

Changes to locale data in `glibc` means that PostgreSQL database files are not fully compatible
between different OS releases.

To avoid index corruption, [check for locale compatibility](../administration/geo/replication/troubleshooting.md#check-os-locale-data-compatibility)
when:

- Moving binary PostgreSQL data between servers.
- Upgrading your Linux distribution.
- Updating or changing third party container images.

#### Gitaly Cluster database requirements

[Read more in the Gitaly Cluster documentation](../administration/gitaly/praefect.md).

#### Exclusive use of GitLab databases

Databases created or used for GitLab, Geo, Gitaly Cluster, or other components should be for the
exclusive use of GitLab. Do not make direct changes to the database, schemas, users, or other
properties except when following procedures in the GitLab documentation or following the directions
of GitLab Support or other GitLab engineers.

- The main GitLab application currently uses three schemas:

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

## Puma settings

The recommended settings for Puma are determined by the infrastructure on which it's running.
The GitLab Linux package defaults to the recommended Puma settings. Regardless of installation method, you can
tune the Puma settings:

- If you're using the GitLab Linux package, see [Puma settings](../administration/operations/puma.md)
  for instructions on changing the Puma settings.
- If you're using the GitLab Helm chart, see the
  [`webservice` chart](https://docs.gitlab.com/charts/charts/gitlab/webservice/index.html).

### Puma workers

The recommended number of workers is calculated as the highest of the following:

- `2`
- A combination of CPU and memory resource availability (see how this is configured automatically for the [Linux package](https://gitlab.com/gitlab-org/omnibus-gitlab/-/blob/ef9facdc927e7389db6a5e0655414ba8318c7b8a/files/gitlab-cookbooks/gitlab/libraries/puma.rb#L31-46)).

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
    - memory limit: (8 - 1.5) = 6
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

### Puma threads

The recommended number of threads is dependent on several factors, including total memory, and use
of [legacy Rugged code](../administration/gitaly/index.md#direct-access-to-git-in-gitlab).

- If the operating system has a maximum 2 GB of memory, the recommended number of threads is `1`.
  A higher value results in excess swapping, and decrease performance.
- If legacy Rugged code is in use, the recommended number of threads is `1`.
- In all other cases, the recommended number of threads is `4`. We don't recommend setting this
higher, due to how [Ruby MRI multi-threading](https://en.wikipedia.org/wiki/Global_interpreter_lock)
works.

### Puma per worker maximum memory

By default, each Puma worker is limited to 1.2 GB of memory.
You can [adjust this memory setting](../administration/operations/puma.md#reducing-memory-use) and should do so
if you must increase the number of Puma workers.

## Redis and Sidekiq

Redis stores all user sessions and the background task queue.
The storage requirements for Redis are minimal, about 25 kB per user.
Sidekiq processes the background jobs with a multi-threaded process.
This process starts with the entire Rails stack (200 MB+) but it can grow over time due to memory leaks.
On a very active server (10,000 billable users) the Sidekiq process can use 1 GB+ of memory.

## Prometheus and its exporters

[Prometheus](https://prometheus.io) and its related exporters are enabled by
default to enable in depth monitoring of GitLab. With default settings, these
processes consume approximately 200 MB of memory.

If you would like to disable Prometheus and it's exporters or read more information
about it, check the [Prometheus documentation](../administration/monitoring/prometheus/index.md).

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

We recommend using a separate machine for each GitLab Runner, if you plan to
use the CI features.
The GitLab Runner server requirements depend on:

- The type of [executor](https://docs.gitlab.com/runner/executors/) you configured on GitLab Runner.
- Resources required to run build jobs.
- Job concurrency settings.

Because the nature of the jobs varies for each use case, you must experiment by adjusting the job concurrency to get the optimum setting.

For reference, the [SaaS runners on Linux](../ci/runners/saas/linux_saas_runner.md)
are configured so that a **single job** runs in a **single instance** with:

- 1 vCPU.
- 3.75 GB of RAM.

## Supported web browsers

WARNING:
With GitLab 13.0 (May 2020) we have removed official support for Internet Explorer 11.

GitLab supports the following web browsers:

- [Mozilla Firefox](https://www.mozilla.org/en-US/firefox/new/)
- [Google Chrome](https://www.google.com/chrome/)
- [Chromium](https://www.chromium.org/getting-involved/dev-channel/)
- [Apple Safari](https://www.apple.com/safari/)
- [Microsoft Edge](https://www.microsoft.com/en-us/edge?form=MA13FJ)

For the listed web browsers, GitLab supports:

- The current and previous major versions of browsers.
- The current minor version of a supported major version.

NOTE:
We don't support running GitLab with JavaScript disabled in the browser and have no plans of supporting that
in the future because we have features such as issue boards which require JavaScript extensively.

## Security

After installation, be sure to read and follow guidance on [maintaining a secure GitLab installation](../security/index.md).

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, for example `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
