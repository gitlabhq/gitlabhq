---
stage: Systems
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Geo

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** Self-managed

Geo is the solution for widely distributed development teams and for providing
a warm-standby as part of a disaster recovery strategy.

WARNING:
Geo undergoes significant changes from release to release. Upgrades are
supported and [documented](#upgrading-geo), but you should ensure that you're
using the right version of the documentation for your installation.

Fetching large repositories can take a long time for teams and runners located far from a single GitLab instance.

Geo provides local caches that can be placed geographically close to remote teams which can serve read requests. This can reduce the time it takes
to clone and fetch large repositories, speeding up development and increasing the productivity of your remote teams.

Geo secondary sites transparently proxy write requests to the primary site. All Geo sites can be configured to respond to a single GitLab URL, to deliver a consistent, seamless, and comprehensive experience whichever site the user lands on.

To make sure you're using the right version of the documentation, go to [the Geo page on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/administration/geo/index.md) and choose the appropriate release from the **Switch branch/tag** dropdown list. For example, [`v15.7.6-ee`](https://gitlab.com/gitlab-org/gitlab/-/blob/v15.7.6-ee/doc/administration/geo/index.md).

Geo uses a set of defined terms that are described in the [Geo Glossary](glossary.md).
Be sure to familiarize yourself with those terms.

## Use cases

Implementing Geo provides the following benefits:

- Reduce from minutes to seconds the time taken for your distributed developers to clone and fetch large repositories and projects.
- Enable all of your developers to contribute ideas and work in parallel, no matter where they are.
- Balance the read-only load between your **primary** and **secondary** sites.

In addition, it:

- Can be used for cloning and fetching projects, in addition to reading any data available in the GitLab web interface (see [limitations](#limitations)).
- Overcomes slow connections between distant offices, saving time by improving speed for distributed teams.
- Helps reducing the loading time for automated tasks, custom integrations, and internal workflows.
- Can quickly fail over to a **secondary** site in a [disaster recovery](disaster_recovery/index.md) scenario.
- Allows [planned failover](disaster_recovery/planned_failover.md) to a **secondary** site.

Geo provides:

- A complete GitLab experience on **Secondary** sites: Maintain one **primary** GitLab site while enabling **secondary** sites with full read and write and UI experience for each of your distributed teams.
- Authentication system hooks: **Secondary** sites receive all authentication data (like user accounts and logins) from the **primary** instance.

### Gitaly Cluster

Geo should not be confused with [Gitaly Cluster](../gitaly/praefect.md). For more information about
the difference between Geo and Gitaly Cluster, see [Comparison to Geo](../gitaly/index.md#comparison-to-geo).

## How it works

This is a brief summary of how Geo works in your GitLab environment. For a more detailed information, see the [Geo Development page](../../development/geo.md).

Your Geo instance can be used for cloning and fetching projects, in addition to reading any data. This makes working with large repositories over large distances much faster.

![Geo overview](replication/img/geo_overview.png)

When Geo is enabled, the:

- Original instance is known as the **primary** site.
- Replicating sites are known as **secondary** sites.

Keep in mind that:

- **Secondary** sites talk to the **primary** site to:
  - Get user data for logins (API).
  - Replicate repositories, LFS Objects, and Attachments (HTTPS + JWT).
- The **primary** site doesn't talk to **secondary** sites to notify for changes (API).
- You can push directly to a **secondary** site (for both HTTP and SSH,
  including Git LFS).
- There are [limitations](#limitations) when using Geo.

### Architecture

The following diagram illustrates the underlying architecture of Geo.

![Geo architecture](replication/img/geo_architecture.png)

In this diagram:

- There is the **primary** site and the details of one **secondary** site.
- Writes to the database can only be performed on the **primary** site. A **secondary** site receives database
  updates by using [PostgreSQL streaming replication](https://wiki.postgresql.org/wiki/Streaming_Replication).
- If present, the [LDAP server](#ldap) should be configured to replicate for [Disaster Recovery](disaster_recovery/index.md) scenarios.
- A **secondary** site performs different type of synchronizations against the **primary** site, using a special
  authorization protected by JWT:
  - Repositories are cloned/updated via Git over HTTPS.
  - Attachments, LFS objects, and other files are downloaded via HTTPS using a private API endpoint.

From the perspective of a user performing Git operations:

- The **primary** site behaves as a full read-write GitLab instance.
- **Secondary** sites are read-only but proxy Git push operations to the **primary** site. This makes **secondary** sites appear to support push operations themselves.
- **Secondary** sites proxy web UI requests to the primary. This makes the **secondary** sites appear to support full UI read/write operations.

To simplify the diagram, some necessary components are omitted.

- Git over SSH requires [`gitlab-shell`](https://gitlab.com/gitlab-org/gitlab-shell) and OpenSSH.
- Git over HTTPS required [`gitlab-workhorse`](https://gitlab.com/gitlab-org/gitlab-workhorse).

A **secondary** site needs two different PostgreSQL databases:

- A read-only database instance that streams data from the main GitLab database.
- A [read/write database instance(tracking database)](#geo-tracking-database) used internally by the **secondary** site to record what data has been replicated.

In **secondary** sites, there is an additional daemon: [Geo Log Cursor](#geo-log-cursor).

## Requirements for running Geo

The following are required to run Geo:

- An operating system that supports OpenSSH 6.9 or later (needed for
  [fast lookup of authorized SSH keys in the database](../operations/fast_ssh_key_lookup.md))
  The following operating systems are known to ship with a current version of OpenSSH:
  - [CentOS](https://www.centos.org) 7.4 or later
  - [Ubuntu](https://ubuntu.com) 16.04 or later
- Where possible, you should also use the same operating system version on all
  Geo sites. If using different operating system versions between Geo sites, you
  **must** [check OS locale data compatibility](replication/troubleshooting/common.md#check-os-locale-data-compatibility)
  across Geo sites to avoid silent corruption of database indexes.
- [Supported PostgreSQL versions](https://handbook.gitlab.com/handbook/engineering/infrastructure/core-platform/data_stores/database/postgresql-upgrade-cadence/) for your GitLab releases with [Streaming Replication](https://wiki.postgresql.org/wiki/Streaming_Replication).
  - [PostgreSQL Logical replication](https://www.postgresql.org/docs/current/logical-replication.html) is not supported.
- All sites must run [the same PostgreSQL versions](setup/database.md#postgresql-replication).
- Git 2.9 or later
- Git-lfs 2.4.2 or later on the user side when using LFS
- All sites must run the exact same GitLab version. The [major, minor, and patch versions](../../policy/maintenance.md#versioning) must all match.
- All sites must define the same [repository storages](../repository_storage_paths.md).

Additionally, check the GitLab [minimum requirements](../../install/requirements.md),
and use the latest version of GitLab for a better experience.

### Firewall rules

The following table lists basic ports that must be open between the **primary** and **secondary** sites for Geo. To simplify failovers, you should open ports in both directions.

| Source site | Source port | Destination site | Destination port | Protocol    |
|-------------|-------------|------------------|------------------|-------------|
| Primary     | Any         | Secondary        | 80               | TCP (HTTP)  |
| Primary     | Any         | Secondary        | 443              | TCP (HTTPS) |
| Secondary   | Any         | Primary          | 80               | TCP (HTTP)  |
| Secondary   | Any         | Primary          | 443              | TCP (HTTPS) |
| Secondary   | Any         | Primary          | 5432             | TCP         |

See the full list of ports used by GitLab in [Package defaults](../package_information/defaults.md)

NOTE:
[Web terminal](../../ci/environments/index.md#web-terminals-deprecated) support requires your load balancer to correctly handle WebSocket connections.
When using HTTP or HTTPS proxying, your load balancer must be configured to pass through the `Connection` and `Upgrade` hop-by-hop headers. See the [web terminal](../integration/terminal.md) integration guide for more details.

NOTE:
When using HTTPS protocol for port 443, you must add an SSL certificate to the load balancers.
If you wish to terminate SSL at the GitLab application server instead, use TCP protocol.

NOTE:
If you are only using `HTTPS` for external/internal URLs, it is not necessary to open port 80 in the firewall.

#### Internal URL

HTTP requests from any Geo secondary site to the primary Geo site use the Internal URL of the primary
Geo site. If this is not explicitly defined in the primary Geo site settings in the Admin area, the
public URL of the primary site is used.

To update the internal URL of the primary Geo site:

1. On the left sidebar, at the bottom, select **Admin area**.
1. Select **Geo > Sites**.
1. Select **Edit** on the primary site.
1. Change the **Internal URL**, then select **Save changes**.

### Geo Tracking Database

The tracking database instance is used as metadata to control what needs to be updated on the local instance. For example:

- Download new assets.
- Fetch new LFS Objects.
- Fetch changes from a repository that has recently been updated.

Because the replicated database instance is read-only, we need this additional database instance for each **secondary** site.

### Geo Log Cursor

This daemon:

- Reads a log of events replicated by the **primary** site to the **secondary** database instance.
- Updates the Geo Tracking Database instance with changes that must be executed.

When something is marked to be updated in the tracking database instance, asynchronous jobs running on the **secondary** site execute the required operations and update the state.

This new architecture allows GitLab to be resilient to connectivity issues between the sites. It doesn't matter how long the **secondary** site is disconnected from the **primary** site as it is able to replay all the events in the correct order and become synchronized with the **primary** site again.

## Limitations

WARNING:
This list of limitations only reflects the latest version of GitLab. If you are using an older version, extra limitations may be in place.

- Pushing directly to a **secondary** site redirects (for HTTP) or proxies (for SSH) the request to the **primary** site instead of [handling it directly](https://gitlab.com/gitlab-org/gitlab/-/issues/1381). The limitation is that you cannot use Git over HTTP with credentials embedded in the URI, for example, `https://user:personal-access-token@secondary.tld`. For more information, see how to [use a Geo Site](replication/usage.md).
- The **primary** site has to be online for OAuth login to happen. Existing sessions and Git are not affected. Support for the **secondary** site to use an OAuth provider independent from the primary is [being planned](https://gitlab.com/gitlab-org/gitlab/-/issues/208465).
- The installation takes multiple manual steps that together can take about an hour depending on circumstances. Consider using the
  [GitLab Environment Toolkit](https://gitlab.com/gitlab-org/gitlab-environment-toolkit) Terraform and Ansible scripts to deploy and operate production
  GitLab instances based on our [Reference Architectures](../reference_architectures/index.md), including automation of common daily tasks.
  [Epic 1465](https://gitlab.com/groups/gitlab-org/-/epics/1465) proposes to improve Geo installation even more.
- Real-time updates of issues/merge requests (for example, via long polling) doesn't work on the **secondary** site.
- [Selective synchronization](replication/selective_synchronization.md) only limits what repositories and files are replicated. The entire PostgreSQL data is still replicated. Selective synchronization is not built to accommodate compliance / export control use cases.
- [Pages access control](../../user/project/pages/pages_access_control.md) doesn't work on secondaries. See [GitLab issue #9336](https://gitlab.com/gitlab-org/gitlab/-/issues/9336) for details.
- [Disaster recovery](disaster_recovery/index.md) for deployments that have multiple secondary sites causes downtime due to the need to perform complete re-synchronization and re-configuration of all non-promoted secondaries to follow the new primary site.
- For Git over SSH, to make the project clone URL display correctly regardless of which site you are browsing, secondary sites must use the same port as the primary. [GitLab issue #339262](https://gitlab.com/gitlab-org/gitlab/-/issues/339262) proposes to remove this limitation.
- Git push over SSH against a secondary site does not work for pushes over 1.86 GB. [GitLab issue #413109](https://gitlab.com/gitlab-org/gitlab/-/issues/413109) tracks this bug.
- Backups [cannot be run on secondaries](replication/troubleshooting/replication.md#message-error-canceling-statement-due-to-conflict-with-recovery).
- Git clone and fetch requests with option `--depth` over SSH against a secondary site does not work and hangs indefinitely if the secondary site is not up to date at the time the request is initiated. For more information, see [issue 391980](https://gitlab.com/gitlab-org/gitlab/-/issues/391980).
- Git push with options over SSH against a secondary site does not work and terminates the connection. For more information, see [issue 417186](https://gitlab.com/gitlab-org/gitlab/-/issues/417186).
- The Geo secondary site does not accelerate (serve) the clone request for the first stage of the pipeline in most cases. Later stages are not guaranteed to be served by the secondary site either, for example if the Git change is large, bandwidth is small, or pipeline stages are short. In general, it does serve the clone request for subsequent stages. [Issue 446176](https://gitlab.com/gitlab-org/gitlab/-/issues/446176) discusses the reasons for this and proposes an enhancement to increase the chance that Runner clone requests are served from the secondary site.

### Limitations on replication/verification

There is a complete list of all GitLab [data types](replication/datatypes.md) and [existing support for replication and verification](replication/datatypes.md#limitations-on-replicationverification).

## Setup instructions

For setup instructions, see [Setting up Geo](setup/index.md).

## Post-installation documentation

After installing GitLab on the **secondary** sites and performing the initial configuration, see the following documentation for post-installation information.

### Configuring Geo

For information on configuring Geo, see [Geo configuration](replication/configuration.md).

### Upgrading Geo

For information on how to update your Geo sites to the latest GitLab version, see [Upgrading the Geo sites](replication/upgrading_the_geo_sites.md).

### Pausing and resuming replication

WARNING:
Pausing and resuming of replication is only supported for Geo installations using a
Linux package-managed database. External databases are not supported.

In some circumstances, like during [upgrades](replication/upgrading_the_geo_sites.md) or a
[planned failover](disaster_recovery/planned_failover.md), it is desirable to pause replication between the primary and secondary.

If you plan to allow user activity on your secondary sites during the upgrade,
do not pause replication for a [zero-downtime upgrade](../../update/zero_downtime.md). While paused, the secondary site gets more and more out-of-date.
One known effect is that more and more Git fetches get redirected or proxied to the primary site. There may be additional unknown effects.

Pausing and resuming replication is done through a command-line tool from a specific node in the secondary site. Depending on your database architecture,
this will target either the `postgresql` or `patroni` service:

- If you are using a single node for all services on your secondary site, you must run the commands on this single node.
- If you have a standalone PostgreSQL node on your secondary site, you must run the commands on this standalone PostgreSQL node.
- If your secondary site is using a Patroni cluster, you must run these commands on the secondary Patroni standby leader node.

If you aren't using a single node for all services on your secondary site, ensure that the `/etc/gitlab/gitlab.rb` on your PostgreSQL or Patroni nodes
contains the configuration line `gitlab_rails['geo_node_name'] = 'node_name'`, where `node_name` is the same as the `geo_node_name` on the application node.

**To Pause: (from secondary site)**

Also, be aware that if PostgreSQL is restarted after pausing replication (either by restarting the VM or restarting the service with `gitlab-ctl restart postgresql`), PostgreSQL automatically resumes replication, which is something you wouldn't want during an upgrade or in a planned failover scenario.

```shell
gitlab-ctl geo-replication-pause
```

**To Resume: (from secondary site)**

```shell
gitlab-ctl geo-replication-resume
```

### Configuring Geo for multiple nodes

For information on configuring Geo for multiple nodes, see [Geo for multiple servers](replication/multiple_servers.md).

### Configuring Geo with Object Storage

For information on configuring Geo with Object storage, see [Geo with Object storage](replication/object_storage.md).

### Disaster Recovery

For information on using Geo in disaster recovery situations to mitigate data-loss and restore services, see [Disaster Recovery](disaster_recovery/index.md).

### Replicating the container registry

For more information on how to replicate the container registry, see [Container registry for a **secondary** site](replication/container_registry.md).

### Geo secondary proxy

For more information on using Geo proxying on secondary sites, see [Geo proxying for secondary sites](secondary_proxy/index.md).

### Single Sign On (SSO)

For more information on configuring Single Sign-On (SSO), see [Geo with Single Sign-On (SSO)](replication/single_sign_on.md).

#### LDAP

For more information on configuring LDAP, see [Geo with Single Sign-On (SSO) > LDAP](replication/single_sign_on.md#ldap).

### Security Review

For more information on Geo security, see [Geo security review](replication/security_review.md).

### Tuning Geo

For more information on tuning Geo, see [Tuning Geo](replication/tuning.md).

### Set up a location-aware Git URL

For an example of how to set up a location-aware Git remote URL with AWS Route53, see [Location-aware Git remote URL with AWS Route53](replication/location_aware_git_url.md).

### Backfill

When a **secondary** site is set up, it starts replicating missing data from
the **primary** site in a process known as **backfill**. You can monitor the
synchronization process on each Geo site from the **primary** site's **Geo Nodes**
dashboard in your browser.

Failures that happen during a backfill are scheduled to be retried at the end
of the backfill.

### Runners

- In addition to our standard best practices for deploying a [fleet of runners](https://docs.gitlab.com/runner/fleet_scaling/index.html), runners can also be configured to connect to Geo secondaries to spread out job load. See how to [register runners against secondaries](secondary_proxy/runners.md).
- See also how to handle [Disaster Recovery with runners](disaster_recovery/planned_failover.md#runner-failover).

## Remove Geo site

For more information on removing a Geo site, see [Removing **secondary** Geo sites](replication/remove_geo_site.md).

## Disable Geo

To find out how to disable Geo, see [Disabling Geo](replication/disable_geo.md).

## Frequently Asked Questions

For answers to common questions, see the [Geo FAQ](replication/faq.md).

## Log files

Geo stores structured log messages in a `geo.log` file.

For more information on how to access and consume Geo logs, see the [Geo section in the log system documentation](../logs/index.md#geolog).

## Troubleshooting

For troubleshooting steps, see [Geo Troubleshooting](replication/troubleshooting/index.md).
