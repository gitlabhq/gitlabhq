---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference
---

# Requirements

This page includes useful information on the supported Operating Systems as well
as the hardware requirements that are needed to install and use GitLab.

## Operating Systems

### Supported Linux distributions

- Ubuntu (16.04/18.04/20.04)
- Debian (9/10)
- CentOS (6/7/8)
- openSUSE (Leap 15.1/Enterprise Server 12.2)
- Red Hat Enterprise Linux (please use the CentOS packages and instructions)
- Scientific Linux (please use the CentOS packages and instructions)
- Oracle Linux (please use the CentOS packages and instructions)

For the installation options, see [the main installation page](README.md).

### Unsupported Linux distributions and Unix-like operating systems

- Arch Linux
- Fedora
- FreeBSD
- Gentoo
- macOS

Installation of GitLab on these operating systems is possible, but not supported.
Please see the [installation from source guide](installation.md) and the [installation guides](https://about.gitlab.com/install/) for more information.

### Microsoft Windows

GitLab is developed for Linux-based operating systems.
It does **not** run on Microsoft Windows, and we have no plans to support it in the near future. For the latest development status view this [issue](https://gitlab.com/gitlab-org/gitlab/-/issues/22337).
Please consider using a virtual machine to run GitLab.

## Software requirements

### Ruby versions

From GitLab 13.6:

- Ruby 2.7 and later is required.

From GitLab 12.2:

- Ruby 2.6 and later is required.

You must use the standard MRI implementation of Ruby.
We love [JRuby](https://www.jruby.org/) and [Rubinius](https://github.com/rubinius/rubinius#the-rubinius-language-platform), but GitLab
needs several Gems that have native extensions.

### Go versions

The minimum required Go version is 1.13.

### Git versions

From GitLab 13.6:

- Git 2.29.x and later is required.

From GitLab 13.1:

- Git 2.24.x and later is required.
- Git 2.28.x and later [is recommended](https://gitlab.com/gitlab-org/gitaly/-/issues/2959).

### Node.js versions

Beginning in GitLab 12.9, we only support Node.js 10.13.0 or higher, and we have dropped
support for Node.js 8. (Node.js 6 support was dropped in GitLab 11.8)

We recommend Node 12.x, as it's faster.

GitLab uses [webpack](https://webpack.js.org/) to compile frontend assets, which requires a minimum
version of Node.js 10.13.0.

You can check which version you're running with `node -v`. If you're running
a version older than `v10.13.0`, you need to update it to a newer version. You
can find instructions to install from community maintained packages or compile
from source at the [Node.js website](https://nodejs.org/en/download/).

### Redis versions

GitLab 13.0 and later requires Redis version 4.0 or higher.

Redis version 5.0 or higher is recommended, as this is what ships with
[Omnibus GitLab](https://docs.gitlab.com/omnibus/) packages starting with GitLab 12.7.

## Hardware requirements

### Storage

The necessary hard drive space largely depends on the size of the repositories you want to store in GitLab but as a *rule of thumb* you should have at least as much free space as all your repositories combined take up.

If you want to be flexible about growing your hard drive space in the future consider mounting it using [logical volume management (LVM)](https://en.wikipedia.org/wiki/Logical_volume_management) so you can add more hard drives when you need them.

Apart from a local hard drive you can also mount a volume that supports the network file system (NFS) protocol. This volume might be located on a file server, a network attached storage (NAS) device, a storage area network (SAN) or on an Amazon Web Services (AWS) Elastic Block Store (EBS) volume.

If you have enough RAM and a recent CPU the speed of GitLab is mainly limited by hard drive seek times. Having a fast drive (7200 RPM and up) or a solid state drive (SSD) will improve the responsiveness of GitLab.

NOTE: **Note:**
Since file system performance may affect GitLab's overall performance, [we don't recommend using AWS EFS for storage](../administration/nfs.md#avoid-using-awss-elastic-file-system-efs).

### CPU

CPU requirements are dependent on the number of users and expected workload. Your exact needs may be more, depending on your workload. Your workload is influenced by factors such as - but not limited to - how active your users are, how much automation you use, mirroring, and repo/change size.

The following is the recommended minimum CPU hardware guidance for a handful of example GitLab user base sizes.

- **4 cores** is the **recommended** minimum number of cores and supports up to 500 users
- 8 cores supports up to 1000 users
- More users? Consult the [reference architectures page](../administration/reference_architectures/index.md)

### Memory

Memory requirements are dependent on the number of users and expected workload. Your exact needs may be more, depending on your workload. Your workload is influenced by factors such as - but not limited to - how active your users are, how much automation you use, mirroring, and repo/change size.

The following is the recommended minimum Memory hardware guidance for a handful of example GitLab user base sizes.

- **4GB RAM** is the **required** minimum memory size and supports up to 500 users
  - Our [Memory Team](https://about.gitlab.com/handbook/engineering/development/enablement/memory/) is working to reduce the memory requirement.
- 8GB RAM supports up to 1000 users
- More users? Consult the [reference architectures page](../administration/reference_architectures/index.md)

In addition to the above, we generally recommend having at least 2GB of swap on your server,
even if you currently have enough available RAM. Having swap will help reduce the chance of errors occurring
if your available memory changes. We also recommend configuring the kernel's swappiness setting
to a low value like `10` to make the most of your RAM while still having the swap
available when needed.

## Database

PostgreSQL is the only supported database, which is bundled with the Omnibus GitLab package.
You can also use an [external PostgreSQL database](https://docs.gitlab.com/omnibus/settings/database.html#using-a-non-packaged-postgresql-database-management-server).
Support for MySQL was removed in GitLab 12.1. Existing users using GitLab with
MySQL/MariaDB are advised to [migrate to PostgreSQL](../update/mysql_to_postgresql.md) before upgrading.

### PostgreSQL Requirements

The server running PostgreSQL should have _at least_ 5-10 GB of storage
available, though the exact requirements [depend on the number of users](../administration/reference_architectures/index.md).

We highly recommend users to use the minimum PostgreSQL versions specified below as these are the versions used for development and testing.

GitLab version | Minimum PostgreSQL version
-|-
10.0 | 9.6
13.0 | 11

You must also ensure the `pg_trgm` and `btree_gist` extensions are [loaded into every
GitLab database](postgresql_extensions.html).

NOTE: **Note:**
Support for [PostgreSQL 9.6 and 10 has been removed in GitLab 13.0](https://about.gitlab.com/releases/2020/05/22/gitlab-13-0-released/#postgresql-11-is-now-the-minimum-required-version-to-install-gitlab) so that GitLab can benefit from PostgreSQL 11 improvements, such as partitioning. For the schedule of transitioning to PostgreSQL 12, see [the related epic](https://gitlab.com/groups/gitlab-org/-/epics/2184).

#### Additional requirements for GitLab Geo

If you're using [GitLab Geo](../administration/geo/index.md):

- We strongly recommend running Omnibus-managed instances as they are actively
  developed and tested. We aim to be compatible with most external (not managed
  by Omnibus) databases (for example, [AWS Relational Database Service (RDS)](https://aws.amazon.com/rds/)) but we don't guarantee compatibility.

## Puma settings

The recommended settings for Puma are determined by the infrastructure on which it's running.
Omnibus GitLab defaults to the recommended Puma settings. Regardless of installation method, you can
tune the Puma settings.

If you're using Omnibus GitLab, see [Puma settings](https://docs.gitlab.com/omnibus/settings/puma.html)
for instructions on changing the Puma settings. If you're using the GitLab Helm chart, see the [Webservice chart](https://docs.gitlab.com/charts/charts/gitlab/webservice/index.html).

### Puma workers

The recommended number of workers is calculated as the highest of the following:

- `2`
- Number of CPU cores - 1

For example a node with 4 cores should be configured with 3 Puma workers.

You can increase the number of Puma workers, providing enough CPU and memory capacity is available.
A higher number of Puma workers will usually help to reduce the response time of the application
and increase the ability to handle parallel requests. You must perform testing to verify the
optimal settings for your infrastructure.

### Puma threads

The recommended number of threads is dependent on several factors, including total memory, and use
of [legacy Rugged code](../administration/gitaly/index.md#direct-access-to-git-in-gitlab).

- If the operating system has a maximum 2 GB of memory, the recommended number of threads is `1`.
  A higher value will result in excess swapping, and decrease performance.
- If legacy Rugged code is in use, the recommended number of threads is `1`.
- In all other cases, the recommended number of threads is `4`. We don't recommend setting this
higher, due to how [Ruby MRI multi-threading](https://en.wikipedia.org/wiki/Global_interpreter_lock)
works.

## Unicorn Workers

For most instances we recommend using: (CPU cores * 1.5) + 1 = Unicorn workers.
For example a node with 4 cores would have 7 Unicorn workers.

For all machines that have 2GB and up we recommend a minimum of three Unicorn workers.
If you have a 1GB machine we recommend to configure only two Unicorn workers to prevent excessive
swapping.

As long as you have enough available CPU and memory capacity, it's okay to increase the number of
Unicorn workers and this will usually help to reduce the response time of the applications and
increase the ability to handle parallel requests.

To change the Unicorn workers when you have the Omnibus package (which defaults to the
recommendation above) please see [the Unicorn settings in the Omnibus GitLab documentation](https://docs.gitlab.com/omnibus/settings/unicorn.html).

## Redis and Sidekiq

Redis stores all user sessions and the background task queue.
The storage requirements for Redis are minimal, about 25kB per user.
Sidekiq processes the background jobs with a multithreaded process.
This process starts with the entire Rails stack (200MB+) but it can grow over time due to memory leaks.
On a very active server (10,000 billable users) the Sidekiq process can use 1GB+ of memory.
                                    
## Prometheus and its exporters

As of Omnibus GitLab 9.0, [Prometheus](https://prometheus.io) and its related
exporters are enabled by default, to enable easy and in depth monitoring of
GitLab. Approximately 200MB of memory will be consumed by these processes, with
default settings.

If you would like to disable Prometheus and it's exporters or read more information
about it, check the [Prometheus documentation](../administration/monitoring/prometheus/index.md).

## GitLab Runner

We strongly advise against installing GitLab Runner on the same machine you plan
to install GitLab on. Depending on how you decide to configure GitLab Runner and
what tools you use to exercise your application in the CI environment, GitLab
Runner can consume significant amount of available memory.

Memory consumption calculations, that are available above, won't be valid if
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

Since the nature of the jobs varies for each use case, you will need to experiment by adjusting the job concurrency to get the optimum setting.

For reference, GitLab.com's [auto-scaling shared runner](../user/gitlab_com/index.md#shared-runners) is configured so that a **single job** will run in a **single instance** with:

- 1vCPU.
- 3.75GB of RAM.

## Supported web browsers

CAUTION: **Caution:**
With GitLab 13.0 (May 2020) we have removed official support for Internet Explorer 11.

GitLab supports the following web browsers:

- [Mozilla Firefox](https://www.mozilla.org/en-US/firefox/new/)
- [Google Chrome](https://www.google.com/chrome/)
- [Chromium](https://www.chromium.org/getting-involved/dev-channel)
- [Apple Safari](https://www.apple.com/safari/)
- [Microsoft Edge](https://www.microsoft.com/en-us/edge)

For the listed web browsers, GitLab supports:

- The current and previous major versions of browsers.
- The current minor version of a supported major version.

NOTE: **Note:**
We don't support running GitLab with JavaScript disabled in the browser and have no plans of supporting that
in the future because we have features such as Issue Boards which require JavaScript extensively.

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
