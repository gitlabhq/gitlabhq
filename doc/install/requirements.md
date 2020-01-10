---
type: reference
---

# Requirements

This page includes useful information on the supported Operating Systems as well
as the hardware requirements that are needed to install and use GitLab.

## Operating Systems

### Supported Linux distributions

- Ubuntu
- Debian
- CentOS
- openSUSE
- Red Hat Enterprise Linux (please use the CentOS packages and instructions)
- Scientific Linux (please use the CentOS packages and instructions)
- Oracle Linux (please use the CentOS packages and instructions)

For the installations options, see [the main installation page](README.md).

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
It does **not** run on Microsoft Windows, and we have no plans to support it in the near future. For the latest development status view this [issue](https://gitlab.com/gitlab-org/gitlab/issues/22337).
Please consider using a virtual machine to run GitLab.

## Ruby versions

GitLab requires Ruby (MRI) 2.6. Support for Ruby versions below 2.6 (2.4, 2.5) will stop with GitLab 12.2.

You will have to use the standard MRI implementation of Ruby.
We love [JRuby](https://www.jruby.org/) and [Rubinius](https://rubinius.com) but GitLab
needs several Gems that have native extensions.

## Hardware requirements

### Storage

The necessary hard drive space largely depends on the size of the repos you want to store in GitLab but as a *rule of thumb* you should have at least as much free space as all your repos combined take up.

If you want to be flexible about growing your hard drive space in the future consider mounting it using LVM so you can add more hard drives when you need them.

Apart from a local hard drive you can also mount a volume that supports the network file system (NFS) protocol. This volume might be located on a file server, a network attached storage (NAS) device, a storage area network (SAN) or on an Amazon Web Services (AWS) Elastic Block Store (EBS) volume.

If you have enough RAM memory and a recent CPU the speed of GitLab is mainly limited by hard drive seek times. Having a fast drive (7200 RPM and up) or a solid state drive (SSD) will improve the responsiveness of GitLab.

NOTE: **Note:** Since file system performance may affect GitLab's overall performance, we do not recommend using EFS for storage. See the [relevant documentation](../administration/high_availability/nfs.md#avoid-using-awss-elastic-file-system-efs) for more details.

### CPU

This is the recommended minimum hardware for a handful of example GitLab user base sizes. Your exact needs may be more, depending on your workload. Your workload is influenced by factors such as - but not limited to - how active your users are, how much automation you use, mirroring, and repo/change size.

- 1 core supports up to 100 users but the application can be a bit slower due to having all workers and background jobs running on the same core
- **2 cores** is the **recommended** minimum number of cores and supports up to 100 users
- 4 cores supports up to 500 users
- 8 cores supports up to 1,000 users
- 32 cores supports up to 5,000 users
- More users? Run it high-availability on [multiple application servers](https://about.gitlab.com/solutions/high-availability/)

### Memory

This is the recommended minimum hardware for a handful of example GitLab user base sizes. Your exact needs may be more, depending on your workload. Your workload is influenced by factors such as - but not limited to - how active your users are, how much automation you use, mirroring, and repo/change size.

You need at least 8GB of addressable memory (RAM + swap) to install and use GitLab!
The operating system and any other running applications will also be using memory
so keep in mind that you need at least 4GB available before running GitLab. With
less memory GitLab will give strange errors during the reconfigure run and 500
errors during usage.

- 4GB RAM + 4GB swap supports up to 100 users but it will be very slow
- **8GB RAM** is the **recommended** minimum memory size for all installations and supports up to 100 users
- 16GB RAM supports up to 500 users
- 32GB RAM supports up to 1,000 users
- 128GB RAM supports up to 5,000 users
- More users? Run it high-availability on [multiple application servers](https://about.gitlab.com/solutions/high-availability/)

We recommend having at least [2GB of swap on your server](https://askubuntu.com/a/505344/310789), even if you currently have
enough available RAM. Having swap will help reduce the chance of errors occurring
if your available memory changes. We also recommend [configuring the kernel's swappiness setting](https://askubuntu.com/a/103916)
to a low value like `10` to make the most of your RAM while still having the swap
available when needed.

Our [Memory Team](https://about.gitlab.com/handbook/engineering/development/enablement/memory/) is actively working to reduce the memory requirement.

NOTE: **Note:** The 25 workers of Sidekiq will show up as separate processes in your process overview (such as `top` or `htop`) but they share the same RAM allocation since Sidekiq is a multithreaded application. Please see the section below about Unicorn workers for information about how many you need of those.

## Database

The server running the database should have _at least_ 5-10 GB of storage
available, though the exact requirements depend on the size of the GitLab
installation (e.g. the number of users, projects, etc).

We currently support the following databases:

- PostgreSQL

Support for MySQL was removed in GitLab 12.1. Existing users using GitLab with
MySQL/MariaDB are advised to [migrate to PostgreSQL](../update/mysql_to_postgresql.md) before upgrading.

### PostgreSQL Requirements

As of GitLab 10.0, PostgreSQL 9.6 or newer is required, and earlier versions are
not supported. We highly recommend users to use PostgreSQL 9.6 as this
is the PostgreSQL version used for development and testing.

Users using PostgreSQL must ensure the `pg_trgm` extension is loaded into every
GitLab database. This extension can be enabled (using a PostgreSQL super user)
by running the following query for every database:

```
CREATE EXTENSION pg_trgm;
```

On some systems you may need to install an additional package (e.g.
`postgresql-contrib`) for this extension to become available.

NOTE: **Note:** Support for PostgreSQL 9.6 and 10 will be removed in GitLab 13.0 so that GitLab can benefit from PostgreSQL 11 improvements, such as partitioning. For the schedule on adding support for PostgreSQL 11 and 12, see [the related epic](https://gitlab.com/groups/gitlab-org/-/epics/2184). For the release schedule for GitLab 13.0, see [GitLab's release and maintenance policy](../policy/maintenance.md).

#### Additional requirements for GitLab Geo

If you are using [GitLab Geo](../development/geo.md):

- We strongly recommend running Omnibus-managed instances as they are actively
  developed and tested. We aim to be compatible with most external (not managed
  by Omnibus) databases (for example, AWS RDS) but we do not guarantee
  compatibility.
- The
  [tracking database](../development/geo.md#using-the-tracking-database)
  requires the
  [postgres_fdw](https://www.postgresql.org/docs/9.6/postgres-fdw.html)
  extension.

```
CREATE EXTENSION postgres_fdw;
```

## Unicorn Workers

For most instances we recommend using: (CPU cores * 1.5) + 1 = Unicorn workers.
For example a node with 4 cores would have 7 Unicorn workers.

For all machines that have 2GB and up we recommend a minimum of three Unicorn workers.
If you have a 1GB machine we recommend to configure only two Unicorn workers to prevent excessive swapping.

As long as you have enough available CPU and memory capacity, it's okay to increase the number of Unicorn workers and this will usually help to reduce the response time of the applications and increase the ability to handle parallel requests.

To change the Unicorn workers when you have the Omnibus package (which defaults to the recommendation above) please see [the Unicorn settings in the Omnibus GitLab documentation](https://docs.gitlab.com/omnibus/settings/unicorn.html).

## Redis and Sidekiq

Redis stores all user sessions and the background task queue.
The storage requirements for Redis are minimal, about 25kB per user.
Sidekiq processes the background jobs with a multithreaded process.
This process starts with the entire Rails stack (200MB+) but it can grow over time due to memory leaks.
On a very active server (10,000 active users) the Sidekiq process can use 1GB+ of memory.

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

Memory consumption calculations, that are available above, will not be valid if
you decide to run GitLab Runner and the GitLab Rails application on the same
machine.

It is also not safe to install everything on a single machine, because of the
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

GitLab supports the following web browsers:

- Firefox
- Chrome/Chromium
- Safari
- Microsoft Edge
- Internet Explorer 11

For the listed web browsers, GitLab supports:

- The current and previous major versions of browsers except Internet Explorer.
- Only version 11 of Internet Explorer.
- The current minor version of a supported major version.

NOTE: **Note:** We do not support running GitLab with JavaScript disabled in the browser and have no plans of supporting that
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
