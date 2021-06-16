---
stage: Enablement
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: howto
---

# Geo **(PREMIUM SELF)**

> - Introduced in GitLab Enterprise Edition 8.9.
> - Using Geo in combination with
>   [multi-node architectures](../reference_architectures/index.md)
>   is considered **Generally Available** (GA) in
>   [GitLab Premium](https://about.gitlab.com/pricing/) 10.4.

Geo is the solution for widely distributed development teams and for providing a warm-standby as part of a disaster recovery strategy.

## Overview

WARNING:
Geo undergoes significant changes from release to release. Upgrades **are** supported and [documented](#updating-geo), but you should ensure that you're using the right version of the documentation for your installation.

Fetching large repositories can take a long time for teams located far from a single GitLab instance.

Geo provides local, read-only sites of your GitLab instances. This can reduce the time it takes
to clone and fetch large repositories, speeding up development.

For a video introduction to Geo, see [Introduction to GitLab Geo - GitLab Features](https://www.youtube.com/watch?v=-HDLxSjEh6w).

To make sure you're using the right version of the documentation, navigate to [the Geo page on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/administration/geo/index.md) and choose the appropriate release from the **Switch branch/tag** dropdown. For example, [`v13.7.6-ee`](https://gitlab.com/gitlab-org/gitlab/-/blob/v13.7.6-ee/doc/administration/geo/index.md).

Geo uses a set of defined terms that is described in the [Geo Glossary](glossary.md), please familiarize yourself with those terms.

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

- Read-only **secondary** sites: Maintain one **primary** GitLab site while still enabling read-only **secondary** sites for each of your distributed teams.
- Authentication system hooks: **Secondary** sites receives all authentication data (like user accounts and logins) from the **primary** instance.
- An intuitive UI: **Secondary** sites use the same web interface your team has grown accustomed to. In addition, there are visual notifications that block write operations and make it clear that a user is on a **secondary** sites.

### Gitaly Cluster

Geo should not be confused with [Gitaly Cluster](../gitaly/praefect.md). For more information about
the difference between Geo and Gitaly Cluster, see
[How does Gitaly Cluster compare to Geo?](../gitaly/faq.md#how-does-gitaly-cluster-compare-to-geo).

## How it works

Your Geo instance can be used for cloning and fetching projects, in addition to reading any data. This makes working with large repositories over large distances much faster.

![Geo overview](replication/img/geo_overview.png)

When Geo is enabled, the:

- Original instance is known as the **primary** site.
- Replicated read-only sites are known as **secondary** sites.

Keep in mind that:

- **Secondary** sites talk to the **primary** site to:
  - Get user data for logins (API).
  - Replicate repositories, LFS Objects, and Attachments (HTTPS + JWT).
- In GitLab Premium 10.0 and later, the **primary** site no longer talks to **secondary** sites to notify for changes (API).
- Pushing directly to a **secondary** site (for both HTTP and SSH, including Git LFS) was [introduced](https://about.gitlab.com/releases/2018/09/22/gitlab-11-3-released/) in [GitLab Premium](https://about.gitlab.com/pricing/#self-managed) 11.3.
- There are [limitations](#limitations) when using Geo.

### Architecture

The following diagram illustrates the underlying architecture of Geo.

![Geo architecture](replication/img/geo_architecture.png)

In this diagram:

- There is the **primary** site and the details of one **secondary** site.
- Writes to the database can only be performed on the **primary** site. A **secondary** site receives database
  updates via PostgreSQL streaming replication.
- If present, the [LDAP server](#ldap) should be configured to replicate for [Disaster Recovery](disaster_recovery/index.md) scenarios.
- A **secondary** site performs different type of synchronizations against the **primary** site, using a special
  authorization protected by JWT:
  - Repositories are cloned/updated via Git over HTTPS.
  - Attachments, LFS objects, and other files are downloaded via HTTPS using a private API endpoint.

From the perspective of a user performing Git operations:

- The **primary** site behaves as a full read-write GitLab instance.
- **Secondary** sites are read-only but proxy Git push operations to the **primary** site. This makes **secondary** sites appear to support push operations themselves.

To simplify the diagram, some necessary components are omitted. Note that:

- Git over SSH requires [`gitlab-shell`](https://gitlab.com/gitlab-org/gitlab-shell) and OpenSSH.
- Git over HTTPS required [`gitlab-workhorse`](https://gitlab.com/gitlab-org/gitlab-workhorse).

Note that a **secondary** site needs two different PostgreSQL databases:

- A read-only database instance that streams data from the main GitLab database.
- [Another database instance](#geo-tracking-database) used internally by the **secondary** site to record what data has been replicated.

In **secondary** sites, there is an additional daemon: [Geo Log Cursor](#geo-log-cursor).

## Requirements for running Geo

The following are required to run Geo:

- An operating system that supports OpenSSH 6.9+ (needed for
  [fast lookup of authorized SSH keys in the database](../operations/fast_ssh_key_lookup.md))
  The following operating systems are known to ship with a current version of OpenSSH:
  - [CentOS](https://www.centos.org) 7.4+
  - [Ubuntu](https://ubuntu.com) 16.04+
- PostgreSQL 12+ with [Streaming Replication](https://wiki.postgresql.org/wiki/Streaming_Replication)
- Git 2.9+
- Git-lfs 2.4.2+ on the user side when using LFS
- All sites must run the same GitLab version.

Additionally, check the GitLab [minimum requirements](../../install/requirements.md),
and we recommend you use:

- At least GitLab Enterprise Edition 10.0 for basic Geo features.
- The latest version for a better experience.

### Firewall rules

The following table lists basic ports that must be open between the **primary** and **secondary** sites for Geo.

| **Primary** site | **Secondary** site | Protocol     |
|:-----------------|:-------------------|:-------------|
| 80               | 80                 | HTTP         |
| 443              | 443                | TCP or HTTPS |
| 22               | 22                 | TCP          |
| 5432             |                    | PostgreSQL   |

See the full list of ports used by GitLab in [Package defaults](https://docs.gitlab.com/omnibus/package-information/defaults.html)

NOTE:
[Web terminal](../../ci/environments/index.md#web-terminals) support requires your load balancer to correctly handle WebSocket connections.
When using HTTP or HTTPS proxying, your load balancer must be configured to pass through the `Connection` and `Upgrade` hop-by-hop headers. See the [web terminal](../integration/terminal.md) integration guide for more details.

NOTE:
When using HTTPS protocol for port 443, you need to add an SSL certificate to the load balancers.
If you wish to terminate SSL at the GitLab application server instead, use TCP protocol.

### LDAP

We recommend that if you use LDAP on your **primary** site, you also set up secondary LDAP servers on each **secondary** site. Otherwise, users are unable to perform Git operations over HTTP(s) on the **secondary** site using HTTP Basic Authentication. However, Git via SSH and personal access tokens still works.

NOTE:
It is possible for all **secondary** sites to share an LDAP server, but additional latency can be an issue. Also, consider what LDAP server is available in a [disaster recovery](disaster_recovery/index.md) scenario if a **secondary** site is promoted to be a **primary** site.

Check for instructions on how to set up replication in your LDAP service. Instructions are different depending on the software or service used. For example, OpenLDAP provides [these instructions](https://www.openldap.org/doc/admin24/replication.html).

### Geo Tracking Database

The tracking database instance is used as metadata to control what needs to be updated on the disk of the local instance. For example:

- Download new assets.
- Fetch new LFS Objects.
- Fetch changes from a repository that has recently been updated.

Because the replicated database instance is read-only, we need this additional database instance for each **secondary** site.

### Geo Log Cursor

This daemon:

- Reads a log of events replicated by the **primary** site to the **secondary** database instance.
- Updates the Geo Tracking Database instance with changes that need to be executed.

When something is marked to be updated in the tracking database instance, asynchronous jobs running on the **secondary** site execute the required operations and update the state.

This new architecture allows GitLab to be resilient to connectivity issues between the sites. It doesn't matter how long the **secondary** site is disconnected from the **primary** site as it is able to replay all the events in the correct order and become synchronized with the **primary** site again.

## Limitations

WARNING:
This list of limitations only reflects the latest version of GitLab. If you are using an older version, extra limitations may be in place.

- Pushing directly to a **secondary** site redirects (for HTTP) or proxies (for SSH) the request to the **primary** site instead of [handling it directly](https://gitlab.com/gitlab-org/gitlab/-/issues/1381), except when using Git over HTTP with credentials embedded within the URI. For example, `https://user:password@secondary.tld`.
- The **primary** site has to be online for OAuth login to happen. Existing sessions and Git are not affected. Support for the **secondary** site to use an OAuth provider independent from the primary is [being planned](https://gitlab.com/gitlab-org/gitlab/-/issues/208465).
- The installation takes multiple manual steps that together can take about an hour depending on circumstances. We are working on improving this experience. See [Omnibus GitLab issue #2978](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/2978) for details.
- Real-time updates of issues/merge requests (for example, via long polling) doesn't work on the **secondary** site.
- [Selective synchronization](replication/configuration.md#selective-synchronization) applies only to files and repositories. Other datasets are replicated to the **secondary** site in full, making it inappropriate for use as an access control mechanism.
- Object pools for forked project deduplication work only on the **primary** site, and are duplicated on the **secondary** site.
- GitLab Runners cannot register with a **secondary** site. Support for this is [planned for the future](https://gitlab.com/gitlab-org/gitlab/-/issues/3294).
- Configuring Geo **secondary** sites to [use high-availability configurations of PostgreSQL](https://gitlab.com/groups/gitlab-org/-/epics/2536) is currently in **alpha** support.
- [Selective synchronization](replication/configuration.md#selective-synchronization) only limits what repositories are replicated. The entire PostgreSQL data is still replicated. Selective synchronization is not built to accommodate compliance / export control use cases.

### Limitations on replication/verification

There is a complete list of all GitLab [data types](replication/datatypes.md) and [existing support for replication and verification](replication/datatypes.md#limitations-on-replicationverification).

## Setup instructions

For setup instructions, see [Setting up Geo](setup/index.md).

## Post-installation documentation

After installing GitLab on the **secondary** site(s) and performing the initial configuration, see the following documentation for post-installation information.

### Configuring Geo

For information on configuring Geo, see [Geo configuration](replication/configuration.md).

### Updating Geo

For information on how to update your Geo site(s) to the latest GitLab version, see [Updating the Geo sites](replication/updating_the_geo_nodes.md).

### Pausing and resuming replication

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/35913) in [GitLab Premium](https://about.gitlab.com/pricing/) 13.2.

WARNING:
In GitLab 13.2 and 13.3, promoting a secondary site to a primary while the
secondary is paused fails. Do not pause replication before promoting a
secondary. If the site is paused, be sure to resume before promoting. This
issue has been fixed in GitLab 13.4 and later.

WARNING:
Pausing and resuming of replication is currently only supported for Geo installations using an
Omnibus GitLab-managed database. External databases are currently not supported.

In some circumstances, like during [upgrades](replication/updating_the_geo_nodes.md) or a [planned failover](disaster_recovery/planned_failover.md), it is desirable to pause replication between the primary and secondary.

Pausing and resuming replication is done via a command line tool from the a node in the secondary site where the `postgresql` service is enabled.

If `postgresql` is on a standalone database node, ensure that `gitlab.rb` on that node contains the configuration line `gitlab_rails['geo_node_name'] = 'node_name'`, where `node_name` is the same as the `geo_name_name` on the application node.

**To Pause: (from secondary)**

```shell
gitlab-ctl geo-replication-pause
```

**To Resume: (from secondary)**

```shell
gitlab-ctl geo-replication-resume
```

### Configuring Geo for multiple nodes

For information on configuring Geo for multiple nodes, see [Geo for multiple servers](replication/multiple_servers.md).

### Configuring Geo with Object Storage

For information on configuring Geo with object storage, see [Geo with Object storage](replication/object_storage.md).

### Disaster Recovery

For information on using Geo in disaster recovery situations to mitigate data-loss and restore services, see [Disaster Recovery](disaster_recovery/index.md).

### Replicating the Container Registry

For more information on how to replicate the Container Registry, see [Docker Registry for a **secondary** site](replication/docker_registry.md).

### Security Review

For more information on Geo security, see [Geo security review](replication/security_review.md).

### Tuning Geo

For more information on tuning Geo, see [Tuning Geo](replication/tuning.md).

### Set up a location-aware Git URL

For an example of how to set up a location-aware Git remote URL with AWS Route53, see [Location-aware Git remote URL with AWS Route53](replication/location_aware_git_url.md).

### Backfill

Once a **secondary** site is set up, it starts replicating missing data from
the **primary** site in a process known as **backfill**. You can monitor the
synchronization process on each Geo site from the **primary** site's **Geo Nodes**
dashboard in your browser.

Failures that happen during a backfill are scheduled to be retried at the end
of the backfill.

## Remove Geo site

For more information on removing a Geo site, see [Removing **secondary** Geo sites](replication/remove_geo_site.md).

## Disable Geo

To find out how to disable Geo, see [Disabling Geo](replication/disable_geo.md).

## Frequently Asked Questions

For answers to common questions, see the [Geo FAQ](replication/faq.md).

## Log files

In GitLab 9.5 and later, Geo stores structured log messages in a `geo.log` file. For Omnibus installations, this file is at `/var/log/gitlab/gitlab-rails/geo.log`.

This file contains information about when Geo attempts to sync repositories and files. Each line in the file contains a separate JSON entry that can be ingested into. For example, Elasticsearch or Splunk.

For example:

```json
{"severity":"INFO","time":"2017-08-06T05:40:16.104Z","message":"Repository update","project_id":1,"source":"repository","resync_repository":true,"resync_wiki":true,"class":"Gitlab::Geo::LogCursor::Daemon","cursor_delay_s":0.038}
```

This message shows that Geo detected that a repository update was needed for project `1`.

## Troubleshooting

For troubleshooting steps, see [Geo Troubleshooting](replication/troubleshooting.md).
