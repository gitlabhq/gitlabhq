---
stage: Systems
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Geo validation tests
---

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab Self-Managed

The Geo team performs manual testing and validation on common deployment configurations to ensure
that Geo works when upgrading between minor GitLab versions and major PostgreSQL database versions.

This section contains a journal of validation tests and links to the relevant issues.

## GitLab upgrades

The following are GitLab upgrade validation tests we performed.

<!-- vale gitlab_base.OutdatedVersions = NO -->

### July 2020

[Upgrade Geo multi-node installation](https://gitlab.com/gitlab-org/gitlab/-/issues/225359):

- Description: Tested upgrading from GitLab 12.10.12 to 13.0.10 package in a multi-node
  configuration. As part of the issue to [Fix zero-downtime upgrade process/instructions for multi-node Geo deployments](https://gitlab.com/gitlab-org/gitlab/-/issues/225684), we monitored for downtime using the looping pipeline, HAProxy stats dashboards, and a script to log readiness status on both nodes.
- Outcome: Partial success because we observed downtime during the upgrade of the primary and secondary sites.
- Follow up issues/actions:
  - [Investigate why `reconfigure` and `hup` cause downtime on multi-node Geo deployments](https://gitlab.com/gitlab-org/gitlab/-/issues/228898)
  - [Geo multi-node deployment upgrade: investigate order when upgrading non-deploy nodes](https://gitlab.com/gitlab-org/gitlab/-/issues/228954)

[Switch from repmgr to Patroni on a Geo primary site](https://gitlab.com/gitlab-org/gitlab/-/issues/224652):

- Description: Tested switching from repmgr to Patroni on a multi-node Geo primary site. Used [the orchestrator tool](https://gitlab.com/gitlab-org/gitlab-orchestrator) to deploy a Geo installation with 3 database nodes managed by repmgr. With this approach, we were also able to address a related issue for [verifying a Geo installation with Patroni and PostgreSQL 11](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/5113).
- Outcome: Partial success. We enabled Patroni on the primary site and set up database replication on the secondary site. However, we found that Patroni would delete the secondary site's replication slot whenever Patroni was restarted. Another issue is that when Patroni elects a new leader in the cluster, the secondary site fails to automatically follow the new leader. Until these issues are resolved, we cannot officially support and recommend Patroni for Geo installations.
- Follow up issues/actions:
  - [Investigate permanent replication slot for Patroni with Geo single node secondary](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/5528)

### June 2020

[Upgrade Geo multi-node installation](https://gitlab.com/gitlab-org/gitlab/-/issues/223284):

- Description: Tested upgrading from GitLab 12.9.10 to 12.10.12 package in a multi-node
  configuration. Monitored for downtime using the looping pipeline and HAProxy stats dashboards.
- Outcome: Partial success because we observed downtime during the upgrade of the primary and secondary sites.
- Follow up issues/actions:
  - [Fix zero-downtime upgrade process/instructions for multi-node Geo deployments](https://gitlab.com/gitlab-org/gitlab/-/issues/225684)
  - [Geo:check Rake task: Exclude AuthorizedKeysCommand check if node not running Puma](https://gitlab.com/gitlab-org/gitlab/-/issues/225454)
  - [Update instructions in the next upgrade issue to include monitoring HAProxy dashboards](https://gitlab.com/gitlab-org/gitlab/-/issues/225359)

[Upgrade Geo multi-node installation](https://gitlab.com/gitlab-org/gitlab/-/issues/208104):

- Description: Tested upgrading from GitLab 12.8.1 to 12.9.10 package in a multi-node
  configuration.
- Outcome: Partial success because we did not run the looping pipeline during the demo to validate
  zero-downtime.
- Follow up issues:
  - [Clarify how Puma should include deploy node](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/5460)
  - [Investigate MR creation failure after upgrade to 12.9.10](https://gitlab.com/gitlab-org/gitlab/-/issues/223282) Closed as false positive.

### February 2020

[Upgrade Geo multi-node installation](https://gitlab.com/gitlab-org/gitlab/-/issues/201837):

- Description: Tested upgrading from GitLab 12.7.5 to the latest GitLab 12.8 package in a multi-node
  configuration.
- Outcome: Partial success because we did not run the looping pipeline during the demo to monitor
  downtime.

### January 2020

[Upgrade Geo multi-node installation](https://gitlab.com/gitlab-org/gitlab/-/issues/200085):

- Description: Tested upgrading from GitLab 12.6.x to the latest GitLab 12.7 package in a multi-node
  configuration.
- Outcome: Upgrade test was successful.
- Follow up issues:
  - [Investigate Geo end-to-end test failures](https://gitlab.com/gitlab-org/gitlab/-/issues/201823).
  - [Add more logging to Geo end-to-end tests](https://gitlab.com/gitlab-org/gitlab/-/issues/201830).
  - [Excess service restarts during zero-downtime upgrade](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/5047).

[Upgrade Geo multi-node installation](https://gitlab.com/gitlab-org/gitlab/-/issues/199836):

- Description: Tested upgrading from GitLab 12.5.7 to GitLab 12.6.6 in a multi-node configuration.
- Outcome: Upgrade test was successful.
- Follow up issue:
  [Update documentation for zero-downtime upgrades to ensure deploy node it not in use](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/5046).

[Upgrade Geo multi-node installation](https://gitlab.com/gitlab-org/gitlab/-/issues/37044):

- Description: Tested upgrading from GitLab 12.4.x to the latest GitLab 12.5 package in a multi-node
  configuration.
- Outcome: Upgrade test was successful.
- Follow up issues:
  - [Investigate why HTTP push spec failed on primary node](https://gitlab.com/gitlab-org/gitlab/-/issues/199825).
  - [Investigate if documentation should be modified to include refresh foreign tables task](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/5041).

### October 2019

[Upgrade Geo multi-node installation](https://gitlab.com/gitlab-org/gitlab/-/issues/35262):

- Description: Tested upgrading from GitLab 12.3.5 to GitLab 12.4.1 in a multi-node configuration.
- Outcome: Upgrade test was successful.

[Upgrade Geo multi-node installation](https://gitlab.com/gitlab-org/gitlab/-/issues/32437):

- Description: Tested upgrading from GitLab 12.2.8 to GitLab 12.3.5.
- Outcome: Upgrade test was successful.

[Upgrade Geo multi-node installation](https://gitlab.com/gitlab-org/gitlab/-/issues/32435):

- Description: Tested upgrading from GitLab 12.1.9 to GitLab 12.2.8.
- Outcome: Partial success due to possible misconfiguration issues.

## PostgreSQL upgrades

The following are PostgreSQL upgrade validation tests we performed.

### September 2021

[Verify Geo installation with PostgreSQL 13](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/6131):

- Description: With PostgreSQL 13 available as an opt-in version in GitLab 14.1, we tested fresh installations of GitLab with Geo when PostgreSQL 13 is enabled.
- Outcome: Successfully built an environment with Geo and PostgreSQL 13 using [GitLab Environment Toolkit](https://gitlab.com/gitlab-org/gitlab-environment-toolkit) and performed Geo QA tests against the environment without failures.

### September 2020

[Verify PostgreSQL 12 upgrade for Geo installations](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/5454):

- Description: With PostgreSQL 12 available as an opt-in version in GitLab 13.3, we tested upgrading
  existing Geo installations from PostgreSQL 11 to 12. We also re-tested fresh installations of GitLab
  with Geo after fixes were made to support PostgreSQL 12. These tests were done using a
  nightly build of GitLab 13.4.
- Outcome: Tests were successful for Geo deployments with a single database node on the primary and secondary.
  We encountered known issues with repmgr and Patroni managed PostgreSQL clusters on the Geo primary. Using
  PostgreSQL 12 with a database cluster on the primary is not recommended until the issues are resolved.
- Known issues for PostgreSQL clusters:
  - [Ensure Patroni detects PostgreSQL update](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/5423)
  - [Allow configuring permanent replication slots in Patroni](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/5628)

### August 2020

[Verify Geo installation with PostgreSQL 12](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/5453):

- Description: Prior to PostgreSQL 12 becoming available as an opt-in version in GitLab 13.3,
  we tested fresh installations of GitLab 13.3 with PostgreSQL 12 enabled and Geo installed.
- Outcome: Setting up a Geo secondary required manual intervention because the `recovery.conf` file
  is no longer supported in PostgreSQL 12. We do not recommend deploying Geo with PostgreSQL 12 until
  the appropriate changes have been made to the Linux package and verified.
- Follow up issues:
  - [Update `replicate-geo-database` to support PostgreSQL 12](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/5575)
  - [Remove PostgreSQL 12 check in `replicate-geo-database` for 14.0](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/5576)

### April 2020

[PostgreSQL 11 upgrade procedure for Geo installations](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/4975):

- Description: Prior to making PostgreSQL 11 the default version of PostgreSQL in GitLab 12.10, we
  tested upgrading to PostgreSQL 11 in Geo deployments in GitLab 12.9.
- Outcome: Partially successful. Issues were discovered in multi-node configurations with a separate
  tracking database and concerns were raised about allowing automatic upgrades when Geo enabled.
- Follow up issues:
  - [`replicate-geo-database` incorrectly tries to back up repositories](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/5241).
  - [`pg-upgrade` fails to upgrade a standalone Geo tracking database](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/5242).
  - [`revert-pg-upgrade` fails to downgrade the PostgreSQL data of a Geo secondary's standalone tracking database](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/5243).
  - [Timeout error on Geo secondary read-replica near the end of `gitlab-ctl pg-upgrade`](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/5235).

[Verify Geo installation with PostgreSQL 11](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/4971):

- Description: Prior to making PostgreSQL 11 the default version of PostgreSQL in GitLab 12.10, we
  tested fresh installations of GitLab 12.9 with Geo installed with PostgreSQL 11.
- Outcome: Installation test was successful.

### September 2019

[Test and validate PostgreSQL 10.0 upgrade for Geo](https://gitlab.com/gitlab-org/gitlab/-/issues/12092):

- Description: With the 12.0 release, GitLab required an upgrade to PostgreSQL 10.0. We tested
  various upgrade scenarios up to GitLab 12.1.8.
- Outcome: Multiple issues were found when upgrading and addressed in follow-up issues.
- Follow up issues:
  - [`gitlab-ctl` reconfigure fails on Redis node in multi-node Geo setup](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/4706).
  - [Geo multi-node upgrade from 12.0.9 to 12.1.9 does not upgrade PostgreSQL](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/4705).
  - [Refresh foreign tables fails on app server in multi-node setup after upgrade to 12.1.9](https://gitlab.com/gitlab-org/gitlab/-/issues/32119).

## Object storage replication tests

The following are additional validation tests we performed.

### April 2022

[Validate Object storage replication using AWS based object storage](https://gitlab.com/gitlab-org/gitlab/-/issues/351463):

- Description: Tested the average time it takes for a single image to replicate from the primary object storage location to the secondary when using AWS based object storage replication and [GitLab based object storage replication](object_storage.md#enabling-gitlab-managed-object-storage-replication). This was tested by uploading a 1 MB image to a project on the primary site every second for 60 seconds. The time was then measured until a image was available on the secondary site. This was achieved using a [Ruby Script](https://gitlab.com/gitlab-org/quality/geo-replication-tester).
- Outcome: When using AWS managed replication the average time for an image to replicate between sites is about 49 seconds, this is true for when sites are located in the same region and when they are further apart (Europe to America). When using Geo managed replication in the same region the average time for replication took just 5 seconds, however when replicating cross region the average time rose to 33 seconds.

[Validate Object storage replication using GCP based object storage](https://gitlab.com/gitlab-org/gitlab/-/issues/351464):

- Description: Tested the average time it takes for a single image to replicate from the primary object storage location to the secondary when using GCP based object storage replication and [GitLab based object storage replication](object_storage.md#enabling-gitlab-managed-object-storage-replication). This was tested by uploading a 1 MB image to a project on the primary site every second for 60 seconds. The time was then measured until a image was available on the secondary site. This was achieved using a [Ruby Script](https://gitlab.com/gitlab-org/quality/geo-replication-tester).
- Outcome: GCP handles replication differently than other Cloud Providers. In GCP, the process is to a create single bucket that is either multi, dual, or single region based. This means that the bucket automatically stores replicas in a region based on the option chosen. Even when using multi region, this only replicates in a single continent, the options being America, Europe, or Asia. At current there doesn't seem to be any way to replicate objects between continents using GCP based replication. For Geo managed replication the average time when replicating in the same region was 6 seconds, and when replicating cross region this rose to just 9 seconds.

### January 2022

[Validate Object storage replication using Azure based object storage](https://gitlab.com/gitlab-org/gitlab/-/issues/348804#note_821294631):

- Description: Tested the average time it takes for a single image to replicate from the primary object storage location to the secondary when using Azure based object storage replication and [GitLab based object storage replication](object_storage.md#enabling-gitlab-managed-object-storage-replication). This was tested by uploading a 1 MB image to a project on the primary site every second for 60 seconds. The time was then measured until a image was available on the secondary site. This was achieved using a [Ruby Script](https://gitlab.com/gitlab-org/quality/geo-replication-tester).
- Outcome: When using Azure based replication the average time for an image to replicate from the primary object storage to the secondary was recorded as 40 seconds, the longest replication time was 70 seconds and the quickest was 11 seconds. When using GitLab based replication the average time for replication to complete was 5 seconds, the longest replication time was 10 seconds and the quickest was 3 seconds.
- Follow up issue:
  - [Validate Cross Region Object storage replication using Azure based object storage](https://gitlab.com/gitlab-org/gitlab/-/issues/358154)

### May 2021

[Test failover with object storage replication enabled](https://gitlab.com/gitlab-org/gitlab/-/issues/330362):

- Description: At the time of testing, Geo's object storage replication functionality was in beta. We tested that object storage replication works as intended and that the data was present on the new primary after a failover.
- Outcome: The test was successful. Data in object storage was replicated and present after a failover.
- Follow up issues:
  - [Geo: Failing to replicate initial Monitoring project](https://gitlab.com/gitlab-org/gitlab/-/issues/330485)

## Other tests

### August 2020

[Test Gitaly Cluster on a Geo Deployment](https://gitlab.com/gitlab-org/gitlab/-/issues/223210):

- Description: Tested a Geo deployment with Gitaly clusters configured on both the primary and secondary Geo sites. Triggered automatic Gitaly cluster failover on the primary Geo site, and ran end-to-end Geo tests. Then triggered Gitaly cluster failover on the secondary Geo site, and re-ran the end-to-end Geo tests.
- Outcome: Successful end-to-end tests before and after Gitaly cluster failover on the primary site, and before and after Gitaly cluster failover on the secondary site.
