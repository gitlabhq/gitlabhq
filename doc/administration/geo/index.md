---
stage: Enablement
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: howto
---

# Geo **(PREMIUM ONLY)**

> - Introduced in GitLab Enterprise Edition 8.9.
> - Using Geo in combination with
>   [multi-node architectures](../reference_architectures/index.md)
>   is considered **Generally Available** (GA) in
>   [GitLab Premium](https://about.gitlab.com/pricing/) 10.4.

Geo is the solution for widely distributed development teams and for providing a warm-standby as part of a disaster recovery strategy.

## Overview

CAUTION: **Caution:**
Geo undergoes significant changes from release to release. Upgrades **are** supported and [documented](#updating-geo), but you should ensure that you're using the right version of the documentation for your installation.

Fetching large repositories can take a long time for teams located far from a single GitLab instance.

Geo provides local, read-only instances of your GitLab instances. This can reduce the time it takes
to clone and fetch large repositories, speeding up development.

For a video introduction to Geo, see [Introduction to GitLab Geo - GitLab Features](https://www.youtube.com/watch?v=-HDLxSjEh6w).

To make sure you're using the right version of the documentation, navigate to [the source version of this page on GitLab.com](https://gitlab.com/gitlab-org/gitlab/blob/master/doc/administration/geo/index.md) and choose the appropriate release from the **Switch branch/tag** dropdown. For example, [`v11.2.3-ee`](https://gitlab.com/gitlab-org/gitlab/blob/v11.2.3-ee/doc/administration/geo/index.md).

## Use cases

Implementing Geo provides the following benefits:

- Reduce from minutes to seconds the time taken for your distributed developers to clone and fetch large repositories and projects.
- Enable all of your developers to contribute ideas and work in parallel, no matter where they are.
- Balance the read-only load between your **primary** and **secondary** nodes.

In addition, it:

- Can be used for cloning and fetching projects, in addition to reading any data available in the GitLab web interface (see [limitations](#limitations)).
- Overcomes slow connections between distant offices, saving time by improving speed for distributed teams.
- Helps reducing the loading time for automated tasks, custom integrations, and internal workflows.
- Can quickly fail over to a **secondary** node in a [disaster recovery](disaster_recovery/index.md) scenario.
- Allows [planned failover](disaster_recovery/planned_failover.md) to a **secondary** node.

Geo provides:

- Read-only **secondary** nodes: Maintain one **primary** GitLab node while still enabling read-only **secondary** nodes for each of your distributed teams.
- Authentication system hooks: **Secondary** nodes receives all authentication data (like user accounts and logins) from the **primary** instance.
- An intuitive UI: **Secondary** nodes use the same web interface your team has grown accustomed to. In addition, there are visual notifications that block write operations and make it clear that a user is on a **secondary** node.

### Gitaly Cluster

Geo should not be confused with [Gitaly Cluster](../gitaly/praefect.md). For more information about
the difference between Geo and Gitaly Cluster, see [Gitaly Cluster compared to Geo](../gitaly/praefect.md#gitaly-cluster-compared-to-geo).

## How it works

Your Geo instance can be used for cloning and fetching projects, in addition to reading any data. This will make working with large repositories over large distances much faster.

![Geo overview](replication/img/geo_overview.png)

When Geo is enabled, the:

- Original instance is known as the **primary** node.
- Replicated read-only nodes are known as **secondary** nodes.

Keep in mind that:

- **Secondary** nodes talk to the **primary** node to:
  - Get user data for logins (API).
  - Replicate repositories, LFS Objects, and Attachments (HTTPS + JWT).
- In GitLab Premium 10.0 and later, the **primary** node no longer talks to **secondary** nodes to notify for changes (API).
- Pushing directly to a **secondary** node (for both HTTP and SSH, including Git LFS) was [introduced](https://about.gitlab.com/releases/2018/09/22/gitlab-11-3-released/) in [GitLab Premium](https://about.gitlab.com/pricing/#self-managed) 11.3.
- There are [limitations](#limitations) when using Geo.

### Architecture

The following diagram illustrates the underlying architecture of Geo.

![Geo architecture](replication/img/geo_architecture.png)

In this diagram:

- There is the **primary** node and the details of one **secondary** node.
- Writes to the database can only be performed on the **primary** node. A **secondary** node receives database
  updates via PostgreSQL streaming replication.
- If present, the [LDAP server](#ldap) should be configured to replicate for [Disaster Recovery](disaster_recovery/index.md) scenarios.
- A **secondary** node performs different type of synchronizations against the **primary** node, using a special
  authorization protected by JWT:
  - Repositories are cloned/updated via Git over HTTPS.
  - Attachments, LFS objects, and other files are downloaded via HTTPS using a private API endpoint.

From the perspective of a user performing Git operations:

- The **primary** node behaves as a full read-write GitLab instance.
- **Secondary** nodes are read-only but proxy Git push operations to the **primary** node. This makes **secondary** nodes appear to support push operations themselves.

To simplify the diagram, some necessary components are omitted. Note that:

- Git over SSH requires [`gitlab-shell`](https://gitlab.com/gitlab-org/gitlab-shell) and OpenSSH.
- Git over HTTPS required [`gitlab-workhorse`](https://gitlab.com/gitlab-org/gitlab-workhorse).

Note that a **secondary** node needs two different PostgreSQL databases:

- A read-only database instance that streams data from the main GitLab database.
- [Another database instance](#geo-tracking-database) used internally by the **secondary** node to record what data has been replicated.

In **secondary** nodes, there is an additional daemon: [Geo Log Cursor](#geo-log-cursor).

## Requirements for running Geo

The following are required to run Geo:

- An operating system that supports OpenSSH 6.9+ (needed for
  [fast lookup of authorized SSH keys in the database](../operations/fast_ssh_key_lookup.md))
  The following operating systems are known to ship with a current version of OpenSSH:
  - [CentOS](https://www.centos.org) 7.4+
  - [Ubuntu](https://ubuntu.com) 16.04+
- PostgreSQL 11+ with [Streaming Replication](https://wiki.postgresql.org/wiki/Streaming_Replication)
- Git 2.9+
- Git-lfs 2.4.2+ on the user side when using LFS
- All nodes must run the same GitLab version.

Additionally, check GitLab's [minimum requirements](../../install/requirements.md),
and we recommend you use:

- At least GitLab Enterprise Edition 10.0 for basic Geo features.
- The latest version for a better experience.

### Firewall rules

The following table lists basic ports that must be open between the **primary** and **secondary** nodes for Geo.

| **Primary** node | **Secondary** node | Protocol     |
|:-----------------|:-------------------|:-------------|
| 80               | 80                 | HTTP         |
| 443              | 443                | TCP or HTTPS |
| 22               | 22                 | TCP          |
| 5432             |                    | PostgreSQL   |

See the full list of ports used by GitLab in [Package defaults](https://docs.gitlab.com/omnibus/package-information/defaults.html)

NOTE: **Note:**
[Web terminal](../../ci/environments/index.md#web-terminals) support requires your load balancer to correctly handle WebSocket connections.
When using HTTP or HTTPS proxying, your load balancer must be configured to pass through the `Connection` and `Upgrade` hop-by-hop headers. See the [web terminal](../integration/terminal.md) integration guide for more details.

NOTE: **Note:**
When using HTTPS protocol for port 443, you will need to add an SSL certificate to the load balancers.
If you wish to terminate SSL at the GitLab application server instead, use TCP protocol.

### LDAP

We recommend that if you use LDAP on your **primary** node, you also set up secondary LDAP servers on each **secondary** node. Otherwise, users will not be able to perform Git operations over HTTP(s) on the **secondary** node using HTTP Basic Authentication. However, Git via SSH and personal access tokens will still work.

NOTE: **Note:**
It is possible for all **secondary** nodes to share an LDAP server, but additional latency can be an issue. Also, consider what LDAP server will be available in a [disaster recovery](disaster_recovery/index.md) scenario if a **secondary** node is promoted to be a **primary** node.

Check for instructions on how to set up replication in your LDAP service. Instructions will be different depending on the software or service used. For example, OpenLDAP provides [these instructions](https://www.openldap.org/doc/admin24/replication.html).

### Geo Tracking Database

The tracking database instance is used as metadata to control what needs to be updated on the disk of the local instance. For example:

- Download new assets.
- Fetch new LFS Objects.
- Fetch changes from a repository that has recently been updated.

Because the replicated database instance is read-only, we need this additional database instance for each **secondary** node.

### Geo Log Cursor

This daemon:

- Reads a log of events replicated by the **primary** node to the **secondary** database instance.
- Updates the Geo Tracking Database instance with changes that need to be executed.

When something is marked to be updated in the tracking database instance, asynchronous jobs running on the **secondary** node will execute the required operations and update the state.

This new architecture allows GitLab to be resilient to connectivity issues between the nodes. It doesn't matter how long the **secondary** node is disconnected from the **primary** node as it will be able to replay all the events in the correct order and become synchronized with the **primary** node again.

## Setup instructions

For setup instructions, see [Setting up Geo](setup/index.md).

## Post-installation documentation

After installing GitLab on the **secondary** nodes and performing the initial configuration, see the following documentation for post-installation information.

### Configuring Geo

For information on configuring Geo, see [Geo configuration](replication/configuration.md).

### Updating Geo

For information on how to update your Geo nodes to the latest GitLab version, see [Updating the Geo nodes](replication/updating_the_geo_nodes.md).

### Pausing and resuming replication

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/35913) in [GitLab Premium](https://about.gitlab.com/pricing/) 13.2.

DANGER: **Warning:**
In GitLab 13.2 and 13.3, promoting a secondary node to a primary while the
secondary is paused fails. Do not pause replication before promoting a
secondary. If the node is paused, be sure to resume before promoting. This
issue has been fixed in GitLab 13.4 and later.

CAUTION: **Caution:**
Pausing and resuming of replication is currently only supported for Geo installations using an
Omnibus GitLab-managed database. External databases are currently not supported.

In some circumstances, like during [upgrades](replication/updating_the_geo_nodes.md) or a [planned failover](disaster_recovery/planned_failover.md), it is desirable to pause replication between the primary and secondary.

Pausing and resuming replication is done via a command line tool from the secondary node where the `postgresql` service is enabled.

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

For more information on how to replicate the Container Registry, see [Docker Registry for a **secondary** node](replication/docker_registry.md).

### Security Review

For more information on Geo security, see [Geo security review](replication/security_review.md).

### Tuning Geo

For more information on tuning Geo, see [Tuning Geo](replication/tuning.md).

### Set up a location-aware Git URL

For an example of how to set up a location-aware Git remote URL with AWS Route53, see [Location-aware Git remote URL with AWS Route53](replication/location_aware_git_url.md).

## Remove Geo node

For more information on removing a Geo node, see [Removing **secondary** Geo nodes](replication/remove_geo_node.md).

## Disable Geo

To find out how to disable Geo, see [Disabling Geo](replication/disable_geo.md).

## Limitations

CAUTION: **Caution:**
This list of limitations only reflects the latest version of GitLab. If you are using an older version, extra limitations may be in place.

- Pushing directly to a **secondary** node redirects (for HTTP) or proxies (for SSH) the request to the **primary** node instead of [handling it directly](https://gitlab.com/gitlab-org/gitlab/-/issues/1381), except when using Git over HTTP with credentials embedded within the URI. For example, `https://user:password@secondary.tld`.
- Cloning, pulling, or pushing repositories that exist on the **primary** node but not on the **secondary** nodes where [selective synchronization](replication/configuration.md#selective-synchronization) does not include the project is not supported over SSH [but support is planned](https://gitlab.com/groups/gitlab-org/-/epics/2562). HTTP(S) is supported.
- The **primary** node has to be online for OAuth login to happen. Existing sessions and Git are not affected. Support for the **secondary** node to use an OAuth provider independent from the primary is [being planned](https://gitlab.com/gitlab-org/gitlab/-/issues/208465).
- The installation takes multiple manual steps that together can take about an hour depending on circumstances. We are working on improving this experience. See [Omnibus GitLab issue #2978](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/2978) for details.
- Real-time updates of issues/merge requests (for example, via long polling) doesn't work on the **secondary** node.
- [Selective synchronization](replication/configuration.md#selective-synchronization) applies only to files and repositories. Other datasets are replicated to the **secondary** node in full, making it inappropriate for use as an access control mechanism.
- Object pools for forked project deduplication work only on the **primary** node, and are duplicated on the **secondary** node.
- [External merge request diffs](../merge_request_diffs.md) will not be replicated if they are on-disk, and viewing merge requests will fail. However, external MR diffs in object storage **are** supported. The default configuration (in-database) does work.
- GitLab Runners cannot register with a **secondary** node. Support for this is [planned for the future](https://gitlab.com/gitlab-org/gitlab/-/issues/3294).
- Geo **secondary** nodes can not be configured to [use high-availability configurations of PostgreSQL](https://gitlab.com/groups/gitlab-org/-/epics/2536).

### Limitations on replication/verification

You can keep track of the progress to implement the missing items in
these epics/issues:

- [Unreplicated Data Types](https://gitlab.com/groups/gitlab-org/-/epics/893)
- [Verify all replicated data](https://gitlab.com/groups/gitlab-org/-/epics/1430)

There is a complete list of all GitLab [data types](replication/datatypes.md) and [existing support for replication and verification](replication/datatypes.md#limitations-on-replicationverification).

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
