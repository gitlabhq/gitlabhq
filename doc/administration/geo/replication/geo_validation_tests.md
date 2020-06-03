---
stage: Enablement
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
type: howto
---

# Geo validation tests

The Geo team performs manual testing and validation on common deployment configurations to ensure
that Geo works when upgrading between minor GitLab versions and major PostgreSQL database versions.

This section contains a journal of recent validation tests and links to the relevant issues.

## GitLab upgrades

The following are GitLab upgrade validation tests we performed.

### February 2020

[Upgrade Geo multi-server installation](https://gitlab.com/gitlab-org/gitlab/-/issues/201837):

- Description: Tested upgrading from GitLab 12.7.5 to the latest GitLab 12.8 package in a multi-server
  configuration.
- Outcome: Partial success because we did not run the looping pipeline during the demo to monitor
  downtime.

### January 2020

[Upgrade Geo multi-server installation](https://gitlab.com/gitlab-org/gitlab/-/issues/200085):

- Description: Tested upgrading from GitLab 12.6.x to the latest GitLab 12.7 package in a multi-server
  configuration.
- Outcome: Upgrade test was successful.
- Follow up issues:
  - [Investigate Geo end-to-end test failures](https://gitlab.com/gitlab-org/gitlab/-/issues/201823).
  - [Add more logging to Geo end-to-end tests](https://gitlab.com/gitlab-org/gitlab/-/issues/201830).
  - [Excess service restarts during zero-downtime upgrade](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/5047).

[Upgrade Geo multi-server installation](https://gitlab.com/gitlab-org/gitlab/-/issues/199836):

- Description: Tested upgrading from GitLab 12.5.7 to GitLab 12.6.6 in a multi-server configuration.
- Outcome: Upgrade test was successful.
- Follow up issue:
  [Update documentation for zero-downtime upgrades to ensure deploy node it not in use](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/5046).

[Upgrade Geo multi-server installation](https://gitlab.com/gitlab-org/gitlab/-/issues/37044):

- Description: Tested upgrading from GitLab 12.4.x to the latest GitLab 12.5 package in a multi-server
  configuration.
- Outcome: Upgrade test was successful.
- Follow up issues:
  - [Investigate why HTTP push spec failed on primary node](https://gitlab.com/gitlab-org/gitlab/-/issues/199825).
  - [Investigate if documentation should be modified to include refresh foreign tables task](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/5041).

### October 2019

[Upgrade Geo multi-server installation](https://gitlab.com/gitlab-org/gitlab/-/issues/35262):

- Description: Tested upgrading from GitLab 12.3.5 to GitLab 12.4.1 in a multi-server configuration.
- Outcome: Upgrade test was successful.

[Upgrade Geo multi-server installation](https://gitlab.com/gitlab-org/gitlab/-/issues/32437):

- Description: Tested upgrading from GitLab 12.2.8 to GitLab 12.3.5.
- Outcome: Upgrade test was successful.

[Upgrade Geo multi-server installation](https://gitlab.com/gitlab-org/gitlab/-/issues/32435):

- Description: Tested upgrading from GitLab 12.1.9 to GitLab 12.2.8.
- Outcome: Partial success due to possible misconfiguration issues.

## PostgreSQL upgrades

The following are PostgreSQL upgrade validation tests we performed.

### April 2020

[PostgreSQL 11 upgrade procedure for Geo installations](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/4975):

- Description: Prior to making PostgreSQL 11 the default version of PostgreSQL in GitLab 12.10, we
  tested upgrading to PostgreSQL 11 in Geo deployments on GitLab 12.9.
- Outcome: Partially successful. Issues were discovered in multi-server configurations with a separate
  tracking database and concerns were raised about allowing automatic upgrades when Geo enabled.
- Follow up issues:
  - [`replicate-geo-database` incorrectly tries to back up repositories](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/5241).
  - [`pg-upgrade` fails to upgrade a standalone Geo tracking database](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/5242).
  - [`revert-pg-upgrade` fails to downgrade the PostgreSQL data of a Geo secondary’s standalone tracking database](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/5243).
  - [Timeout error on Geo secondary read-replica near the end of `gitlab-ctl pg-upgrade`](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/5235).

[Verify Geo installation with PostgreSQL 11](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/4971):

- Description: Prior to making PostgreSQL 11 the default version of PostgreSQL in GitLab 12.10, we
  tested fresh installations of GitLab 12.9 with Geo installed with PostgreSQL 11.
- Outcome: Installation test was successful.

### September 2019

[Test and validate PostgreSQL 10.0 upgrade for Geo](https://gitlab.com/gitlab-org/gitlab/-/issues/12092):

- Description: With the 12.0 release, GitLab required an upgrade to PostgreSQL 10.0. We tested
  various upgrade scenarios from GitLab 11.11.5 through to GitLab 12.1.8.
- Outcome: Multiple issues were found when upgrading and addressed in follow-up issues.
- Follow up issues:
  - [`gitlab-ctl` reconfigure fails on Redis node in multi-server Geo setup](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/4706).
  - [Geo multi-server upgrade from 12.0.9 to 12.1.9 does not upgrade PostgreSQL](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/4705).
  - [Refresh foreign tables fails on app server in multi-server setup after upgrade to 12.1.9](https://gitlab.com/gitlab-org/gitlab/-/issues/32119).
