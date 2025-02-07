---
stage: Systems
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Geo
---

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab Self-Managed

Geo is the solution for widely distributed development teams and for providing
a warm-standby as part of a disaster recovery strategy. Geo is **not** an out of the box HA solution.

WARNING:
Geo undergoes significant changes from release to release. Upgrades are
supported and [documented](#upgrading-geo), but you should ensure that you're
using the right version of the documentation for your installation.

To make sure you're using the right version of the documentation, go to [the Geo page on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/administration/geo/_index.md) and choose the appropriate release from the **Switch branch/tag** dropdown list. For example, [`v15.7.6-ee`](https://gitlab.com/gitlab-org/gitlab/-/blob/v15.7.6-ee/doc/administration/geo/_index.md).

Fetching large repositories can take a long time for teams and runners located far from a single GitLab instance.

Geo provides local caches that can be placed geographically close to remote teams which can serve read requests. This can reduce the time it takes
to clone and fetch large repositories, speeding up development and increasing the productivity of your remote teams.

Geo secondary sites transparently proxy write requests to the primary site. All Geo sites can be configured to respond to a single GitLab URL, to deliver a consistent, seamless, and comprehensive experience whichever site the user lands on.

Geo uses a set of defined terms that are described in the [Geo Glossary](glossary.md).
Be sure to familiarize yourself with those terms.

## Use cases

Implementing Geo addresses several use cases. This section provides some of the intended use cases and highlights their benefits.

### Regional disaster recovery

Geo as a [disaster recovery](disaster_recovery/_index.md) solution gives you a warm-standby secondary site in a different region from your primary site. Data is continuously synchronized to the secondary site ensuring it is always up to date. In the event of a disaster, such as data center or network outage or hardware failure, you can failover to a fully operational secondary site. You can test your disaster recovery processes and infrastructure with [planned failovers](disaster_recovery/planned_failover.md).

Benefits:

- Business continuity in the event of a regional disaster.
- Low Recovery Time Objective (RTO) and Recovery Point Objective (RPO).
- Automated (but not automatic) failover with GitLab Environment Toolkit (GET).
- Minimal operational effort - Unassisted continuous replication and verification ensures your secondary sites are up to date and replicated data is not corrupted during transit and at rest.

### Remote team acceleration

Establish Geo secondary sites geographically closer to your remote teams to provide local caches that accelerate read operations. You can have multiple Geo secondary sites, each tailored to synchronize only the projects your remote teams need. [Transparent proxying](secondary_proxy/_index.md) and geographic routing with [unified URL](replication/location_aware_git_url.md) ensures a consistent and seamless developer experience.

Benefits:

- Improve the GitLab experience for geographically distributed teams. Geo offers a complete GitLab experience on secondary sites: maintain one primary GitLab site while enabling secondary sites with read-write access and a complete UI experience for each of your distributed teams.
- Reduce from minutes to seconds the time taken for your distributed developers to clone and fetch large repositories and projects.
- Enable all of your developers to contribute ideas and work in parallel, no matter where they are located.
- Balance the read load between your primary and secondary sites.
- Overcome slow connections between distant offices, saving time by improving speed for distributed teams.
- Reduce the loading time for automated tasks, custom integrations, and internal workflows.

### CI/CD traffic offload

You can configure your CI/CD runners to [clone from Geo secondary sites](secondary_proxy/runners.md). You can tailor your secondary sites to match the needs of the runner workload and don't need to mirror the primary site. Supported read requests are served with cached data on the secondary site, and requests are transparently forwarded to the primary site when the data on the secondary site is stale or not available.

Benefits:

- On the primary site, reduce the impact of CI/CD traffic on user experience by moving traffic to secondary sites.
- Reduce cross-region traffic and locate CI/CD compute time where it's most economical for your organization. Create a single cross-region copy of the data and make it available to repeated read requests against the secondary site.

### Additional use cases

#### Infrastructure migrations

You can use Geo to migrate to new infrastructure. If you move your GitLab instance to a new server or data center, use Geo to migrate your GitLab data to the new instance in the background while your old instance continues to serve your users. Any changes to your active GitLab data are copied to your new instance, so there's no data loss during the cutover.

You cannot use Geo to migrate a PostgreSQL database from one operating system to another. See [Upgrading operating systems for PostgreSQL](../postgresql/upgrading_os.md).

Benefits:

- Significantly reduce downtime during migration compared to the backup and restore migration method. Copy data to the new instance in the background without stopping the active GitLab instance before the cutover downtime window.

#### Migration to GitLab Dedicated

You can also use Geo to migrate GitLab Self-Managed to [GitLab Dedicated](../../subscriptions/gitlab_dedicated/_index.md). A migration to GitLab Dedicated is similar to an infrastructure migration.

Benefits:

- Smoother onboarding experience with significantly lower downtime. Your team can continue to use GitLab Self-Managed while the data migration takes place in the background.

## What Geo is not designed to address

Geo is not designed to address every use case. This section provides examples of
use cases where Geo is not an appropriate solution.

### Enforce data export compliance

While Geo's [selective synchronization](replication/selective_synchronization.md) functionality allows you to restrict projects that are synchronized to secondary sites, it was designed to reduce cross-region traffic and storage requirements, not to enforce export compliance. You must independently determine your legal obligations with regard to privacy, cybersecurity, and applicable trade control laws on an ongoing basis based on solution and documentation. Both the solution and the documentation are subject to change.

### Provide access control

Geo [read-only secondary site](secondary_proxy/_index.md#disable-secondary-site-git-proxying) functionality is not a first-class feature, and might not be supported in the future. You should not rely on this functionality for access control purposes. GitLab provides [authentication and authorization](../auth/_index.md) controls that better serve this purpose.

### An alternative to zero downtime upgrades

Geo is a not a solution for [zero downtime upgrades](../../update/zero_downtime.md). You must upgrade the primary Geo site before upgrading secondary sites.

### Protect against malicious or unintentional corruption

Geo replicates corruption on the primary site to all secondary sites. To protect against malicious or unintentional corruption you should complement Geo with [backups](../backup_restore/_index.md).

### Active-active, high-availability configuration

Geo is designed to be a active-passive, high-availability solution. It operates an eventually consistent synchronization model which means that secondary sites are not tightly synchronized with the primary site. Secondary sites follow the primary with a small delay, which can result in a small amount of data loss after a disaster. Failover to a secondary site in the event of a disaster requires human intervention. However, large parts of the process of promoting a secondary site to become a primary is automated by the [GitLab Environment Toolkit (GET)](https://gitlab.com/gitlab-org/gitlab-environment-toolkit), provided you deploy all your sites using GET.

## Gitaly Cluster

Geo should not be confused with [Gitaly Cluster](../gitaly/praefect.md). For more information about
the difference between Geo and Gitaly Cluster, see [Comparison to Geo](../gitaly/_index.md#comparison-to-geo).

## How it works

This is a brief summary of how Geo works in your GitLab environment. For a more detailed information, see the [Geo Development page](../../development/geo.md).

Your Geo instance can be used for cloning and fetching projects, in addition to reading any data. This makes working with large repositories over large distances much faster.

![Geo overview](replication/img/geo_overview_v11_5.png)

When Geo is enabled, the:

- Original instance is known as the **primary** site.
- Replicating sites are known as **secondary** sites.

Keep in mind that:

- **Secondary** sites talk to the **primary** site to:
  - Get user data for logins (API).
  - Replicate repositories, LFS Objects, and Attachments (HTTPS + JWT).
- The **primary** site talks to the **secondary** sites for viewing replication details. The **primary** does a GraphQL query against the **secondary** site for sync and verification data (API).
- You can push directly to a **secondary** site (for both HTTP and SSH,
  including Git LFS), and it will proxy the requests to the **primary** site.
- Some [known issues](#known-issues) exist when using Geo.

### Architecture

The following diagram illustrates the underlying architecture of Geo.

![Geo architecture](replication/img/geo_architecture_v13_8.png)

In this diagram:

- There is the **primary** site and the details of one **secondary** site.
- Writes to the database can only be performed on the **primary** site. A **secondary** site receives database
  updates by using [PostgreSQL streaming replication](https://wiki.postgresql.org/wiki/Streaming_Replication).
- If present, the [LDAP server](#ldap) should be configured to replicate for [Disaster Recovery](disaster_recovery/_index.md) scenarios.
- A **secondary** site performs different type of synchronizations against the **primary** site, using a special
  authorization protected by JWT:
  - Repositories are cloned/updated via Git over HTTPS.
  - Attachments, LFS objects, and other files are downloaded via HTTPS using a private API endpoint.

From the perspective of a user performing Git operations:

- The **primary** site behaves as a full read-write GitLab instance.
- **Secondary** sites behave as full read-write GitLab instances. **Secondary** sites transparently proxy all operations to the **primary** site, with [some notable exceptions](secondary_proxy/_index.md#features-accelerated-by-secondary-geo-sites). In particular, Git fetches are served by the **secondary** site when it is up-to-date.

From the perspective of a user browsing the GitLab UI, or using the API:

- The **primary** site behaves as a full read-write GitLab instance.
- **Secondary** sites behave as full read-write GitLab instances. **Secondary** sites transparently proxy all operations to the **primary** site, with [some notable exceptions](secondary_proxy/_index.md#features-accelerated-by-secondary-geo-sites). In particular, web UI assets are served by the **secondary** site.

To simplify the diagram, some necessary components are omitted.

- Git over SSH requires [`gitlab-shell`](https://gitlab.com/gitlab-org/gitlab-shell).
- Git over HTTPS required [`gitlab-workhorse`](https://gitlab.com/gitlab-org/gitlab-workhorse).

A **secondary** site needs two different PostgreSQL databases:

- A read-only database instance that streams data from the main GitLab database.
- A [read/write database instance(tracking database)](#geo-tracking-database) used internally by the **secondary** site to record what data has been replicated.

The **secondary** sites also run an additional daemon: [Geo Log Cursor](#geo-log-cursor).

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
- [Supported PostgreSQL versions](https://handbook.gitlab.com/handbook/engineering/infrastructure-platforms/data-access/database-framework/postgresql-upgrade-cadence/) for your GitLab releases with [Streaming Replication](https://wiki.postgresql.org/wiki/Streaming_Replication).
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
[Web terminal](../../ci/environments/_index.md#web-terminals-deprecated) support requires your load balancer to correctly handle WebSocket connections.
When using HTTP or HTTPS proxying, your load balancer must be configured to pass through the `Connection` and `Upgrade` hop-by-hop headers. See the [web terminal](../integration/terminal.md) integration guide for more details.

NOTE:
When using HTTPS protocol for port 443, you must add an SSL certificate to the load balancers.
If you wish to terminate SSL at the GitLab application server instead, use TCP protocol.

NOTE:
If you are only using `HTTPS` for external/internal URLs, it is not necessary to open port 80 in the firewall.

#### Internal URL

HTTP requests from any Geo secondary site to the primary Geo site use the Internal URL of the primary
Geo site. If this is not explicitly defined in the primary Geo site settings in the **Admin** area, the
public URL of the primary site is used.

To update the internal URL of the primary Geo site:

1. On the left sidebar, at the bottom, select **Admin**.
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

## Known issues

WARNING:
These known issues reflect only the latest version of GitLab. If you are using an older version, additional issues might exist.

- Pushing directly to a **secondary** site redirects (for HTTP) or proxies (for SSH) the request to the **primary** site instead of [handling it directly](https://gitlab.com/gitlab-org/gitlab/-/issues/1381). You cannot use Git over HTTP with credentials embedded in the URI, for example, `https://user:personal-access-token@secondary.tld`. For more information, see how to [use a Geo Site](replication/usage.md).
- The **primary** site has to be online for OAuth login to happen. Existing sessions and Git are not affected. Support for the **secondary** site to use an OAuth provider independent from the primary is [being planned](https://gitlab.com/gitlab-org/gitlab/-/issues/208465).
- The installation takes multiple manual steps that together can take about an hour depending on circumstances. Consider using the
  [GitLab Environment Toolkit](https://gitlab.com/gitlab-org/gitlab-environment-toolkit) Terraform and Ansible scripts to deploy and operate production
  GitLab instances based on our [Reference Architectures](../reference_architectures/_index.md), including automation of common daily tasks.
  [Epic 1465](https://gitlab.com/groups/gitlab-org/-/epics/1465) proposes to improve Geo installation even more.
- Real-time updates of issues/merge requests (for example, via long polling) doesn't work on **secondary** sites where [http proxying is disabled](secondary_proxy/_index.md#disable-secondary-site-http-proxying).
- [Selective synchronization](replication/selective_synchronization.md) only limits what repositories and files are replicated. The entire PostgreSQL data is still replicated. Selective synchronization is not built to accommodate compliance / export control use cases.
- [Pages access control](../../user/project/pages/pages_access_control.md) doesn't work on secondaries. See [GitLab issue #9336](https://gitlab.com/gitlab-org/gitlab/-/issues/9336) for details.
- [Disaster recovery](disaster_recovery/_index.md) for deployments that have multiple secondary sites causes downtime due to the need to re-initialize PostgreSQL streaming replication on all non-promoted secondaries to follow the new primary site.
- For Git over SSH, to make the project clone URL display correctly regardless of which site you are browsing, secondary sites must use the same port as the primary.
  For more information, see [issue 339262](https://gitlab.com/gitlab-org/gitlab/-/issues/339262).
- Git push over SSH against a secondary site does not work for pushes over 1.86 GB. [GitLab issue #413109](https://gitlab.com/gitlab-org/gitlab/-/issues/413109) tracks this bug.
- Backups [cannot be run on Geo secondary sites](replication/troubleshooting/postgresql_replication.md#message-error-canceling-statement-due-to-conflict-with-recovery).
- Git push with options over SSH against a secondary site does not work and terminates the connection. For more information, see [issue 417186](https://gitlab.com/gitlab-org/gitlab/-/issues/417186).
- The Geo secondary site does not accelerate (serve) the clone request for the first stage of the pipeline in most cases. Later stages are not guaranteed to be served by the secondary site either, for example if the Git change is large, bandwidth is small, or pipeline stages are short. In general, it does serve the clone request for subsequent stages. [Issue 446176](https://gitlab.com/gitlab-org/gitlab/-/issues/446176) discusses the reasons for this and proposes an enhancement to increase the chance that Runner clone requests are served from the secondary site.
- When a single Git repository receives pushes at a high-enough rate, the secondary site's local copy can be perpetually out-of-date. This causes all Git fetches of that repository to be forwarded to the primary site. See [GitLab issue #455870](https://gitlab.com/gitlab-org/gitlab/-/issues/455870).
- [Proxying](secondary_proxy/_index.md) is implemented only in the GitLab application in the Puma service or Web service, so other services do not benefit from this behavior. You should use a [separate URL](secondary_proxy/_index.md#set-up-a-separate-url-for-a-secondary-geo-site) to ensure requests are always sent to the primary. These services include:
  - GitLab container registry - [can be configured to use a separate domain](../packages/container_registry.md#configure-container-registry-under-its-own-domain), such as `registry.example.com`. Secondary site container registries are intended only for disaster recovery. Users should not be routed to them, especially not for pushes, because the data is not propagated to the primary site.
  - GitLab Pages - should always use a separate domain, as part of [the prerequisites for running GitLab Pages](../pages/_index.md#prerequisites).
- With a [unified URL](secondary_proxy/_index.md#set-up-a-unified-url-for-geo-sites), Let's Encrypt can't generate certificates unless it can reach both IPs through the same domain. To use TLS certificates with Let's Encrypt, you can manually point the domain to one of the Geo sites, generate the certificate, then copy it to all other sites.
- When a [secondary site uses a separate URL](secondary_proxy/_index.md#set-up-a-separate-url-for-a-secondary-geo-site) from the primary site, [signing in the secondary site using SAML](replication/single_sign_on.md#saml-with-separate-url-with-proxying-enabled) is only supported if the SAML Identity Provider (IdP) allows an application to be configured with multiple callback URLs.
- Git clone and fetch requests with option `--depth` over SSH against a secondary site does not work and hangs indefinitely if the secondary site is not up to date at the time the request is initiated. This is due to problems related to translating Git SSH to Git https during proxying. For more information, see [issue 391980](https://gitlab.com/gitlab-org/gitlab/-/issues/391980). A new workflow that does not involve the aforementioned translation step is now available for Linux-packaged GitLab Geo secondary sites which can be enabled with a feature flag. For more details, see [comment in issue 454707](https://gitlab.com/gitlab-org/gitlab/-/issues/454707#note_2102067451). The fix for Cloud Native GitLab Geo secondary sites is tracked in [issue 5641](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/5641).
- Some customers have reported that `git fetch` over SSH when the secondary site is out of date hangs and/or times out and fails. `git clone` requests over SSH are not impacted. For more information, see [issue 454707](https://gitlab.com/gitlab-org/gitlab/-/issues/454707). A fix available for Linux-packaged GitLab Geo secondary sites which can be enabled with a feature flag. For more details, see [comment in issue 454707](https://gitlab.com/gitlab-org/gitlab/-/issues/454707#note_2102067451). The fix for Cloud Native GitLab Geo secondary sites is tracked in [issue 5641](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/5641).

### Replicated data types

There is a complete list of all GitLab [data types](replication/datatypes.md) and
[replicated data types](replication/datatypes.md#replicated-data-types).

## Post-installation documentation

After installing GitLab on the **secondary** sites and performing the initial configuration, see the following documentation for post-installation information.

### Setting up Geo

For information on configuring Geo, see [Set up Geo](setup/_index.md).

### Configuring Geo with Object Storage

For information on configuring Geo with Object storage, see [Geo with Object storage](replication/object_storage.md).

### Replicating the container registry

For more information on how to replicate the container registry, see [Container registry for a **secondary** site](replication/container_registry.md).

### Set up a unified URL for Geo sites

For an example of how to set up a single, location-aware URL with AWS Route53 or Google Cloud DNS, see [Set up a unified URL for Geo sites](secondary_proxy/_index.md#set-up-a-unified-url-for-geo-sites).

### Single Sign On (SSO)

For more information on configuring Single Sign-On (SSO), see [Geo with Single Sign-On (SSO)](replication/single_sign_on.md).

#### LDAP

For more information on configuring LDAP, see [Geo with Single Sign-On (SSO) > LDAP](replication/single_sign_on.md#ldap).

### Tuning Geo

For more information on tuning Geo, see [Tuning Geo](replication/tuning.md).

### Pausing and resuming replication

For more information, see [Pausing and resuming replication](replication/pause_resume_replication.md).

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

### Upgrading Geo

For information on how to update your Geo sites to the latest GitLab version, see [Upgrading the Geo sites](replication/upgrading_the_geo_sites.md).

### Security Review

For more information on Geo security, see [Geo security review](replication/security_review.md).

## Remove Geo site

For more information on removing a Geo site, see [Removing **secondary** Geo sites](replication/remove_geo_site.md).

## Disable Geo

To find out how to disable Geo, see [Disabling Geo](replication/disable_geo.md).

## Log files

Geo stores structured log messages in a `geo.log` file.

For more information on how to access and consume Geo logs, see the [Geo section in the log system documentation](../logs/_index.md#geolog).

## Disaster Recovery

For information on using Geo in disaster recovery situations to mitigate data-loss and restore services, see [Disaster Recovery](disaster_recovery/_index.md).

## Frequently Asked Questions

For answers to common questions, see the [Geo FAQ](replication/faq.md).

## Troubleshooting

- For Geo troubleshooting steps, see [Geo Troubleshooting](replication/troubleshooting/_index.md).

- For Disaster Recovery troubleshooting steps, see [Troubleshooting Geo failover](disaster_recovery/failover_troubleshooting.md).
