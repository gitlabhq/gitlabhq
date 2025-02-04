---
stage: Systems
group: Distribution
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Avoiding required stops
---

Required stops are any changes to GitLab [components](architecture.md) or
dependencies that result in the need to upgrade to and stop at a specific
`major.minor` version when [upgrading GitLab](../update/_index.md).

While Development maintains a [maintenance policy](../policy/maintenance.md)
that results in a three-release (3 month) backport window - GitLab maintains a
much longer window of [version support](https://about.gitlab.com/support/statement-of-support/#version-support)
that includes the current major version, as well as the two previous major
versions. Based on the schedule of previous major releases, GitLab customers can
lag behind the current release for up to three years and still expect to have
support for upgrades.

For example, a GitLab user upgrading from GitLab 14.0.12 to GitLab 16.1,
which is a fully supported [upgrade path](../update/upgrade_paths.md), may have
the following required stops: `14.3.6`, `14.9.5`, `14.10.5`, `15.0.5`, `15.1.6`,
`15.4.6`, and `15.11.11` before upgrading to the latest `16.1.z` version.

Past required stops have not been discovered for months after their introduction,
often as the result of extensive troubleshooting and assistance from Support
Engineers, Customer Success Managers, and Development Engineers as users upgrade
across greater than 1-3 minor releases.

Wherever possible, a required stop should be avoided. If it can't be avoided,
the required stop should be aligned to a _scheduled_ required stop.

Scheduled required stops are often implemented for the previous `major`.`minor`
release just prior to a `major` version release in order to accommodate multiple
[planned deprecations](../update/terminology.md#deprecation) and known
[breaking changes](../update/terminology.md#breaking-change).

Additionally, as of GitLab 16, we have introduced
[_scheduled_ `major`.`minor` required stops](../update/upgrade_paths.md):

>>>
During GitLab 16.x, we are scheduling two or three required upgrade stops.

We will give at least two milestones of notice when we schedule a required
upgrade stop. The first planned required upgrade stop is scheduled for GitLab
16.3. If nothing is introduced requiring an upgrade stop, GitLab 16.3 will be
treated as a regular upgrade.
>>>

## Retroactively adding required stops

In cases where we are considering retroactively declaring an unplanned required stop,
contact the [Distribution team product manager](https://handbook.gitlab.com/handbook/product/categories/#distributionbuild-group) to advise on next steps. If there
is uncertainty about whether we should declare a required stop, the Distribution product
manager may escalate to GitLab product leadership (VP or Chief Product Officer) to make
a final determination. This may happen, for example, if a change might require a stop for
a small subset of very large GitLab Self-Managed instances and there are well-defined workarounds
if customers run into issues.

## Causes of required stops

### Inaccurate assumptions about completed migrations

The majority of required stops are due to assumptions about the state of the
data model in a given release, usually in the form of interdependent database
migrations, or code changes that assume that schema changes introduced in
prior migrations have completed by the time the code loads.

Designing changes and migrations for [backwards compatibility between versions](multi_version_compatibility.md) can mitigate stop concerns with continuous or
zero-downtime upgrades. However, the **contract** phase will likely introduce
a required stop when a migration/code change is introduced that requires
that background migrations have completed before running or loading.

WARNING:
If you're considering adding or removing a migration, or introducing code that
assumes that migrations have completed in a given release, first review
the database-related documentation on [required stops](database/required_stops.md).

#### Examples

- GitLab `12.1`: Introduced a background migration changing `merge_status` in
  MergeRequests depending on the `state` value. The `state` attribute was removed
  in `12.10`. It took until `13.6` to document the required stop.
- GitLab `13.8`: Includes a background migration to deal with duplicate service
  records. In `13.9`, a unique index was applied in another migration that
  depended on the background migration completing. Not discovered/documented until
  GitLab `14.3`
- GitLab `14.3`: Includes a potentially long-running background migration against
  `merge_request_diff_commits` that was foregrounded in `14.5`. This change resulted in
   extensive downtime for users with large GitLab installations. Not documented
   until GitLab `15.1`
- GitLab `14.9`: Includes a batched background migration for `namespaces` and `projects`
  that needs to finish before another batched background migration added in `14.10` executes,
  forcing a required stop. The migration can take hours or days to complete on
  large GitLab installations.

Additional details as well as links to related issues and merge requests can be
found in: [Issue: Put in place measures to avoid addition/proliferation of GitLab upgrade path stops](https://gitlab.com/gitlab-org/gitlab/-/issues/375553)

### Removal of code workarounds and mitigations

Similar to assumptions about the data model/schema/migration state, required
`major.minor` stops have been introduced due to the intentional removal of
code implemented to workaround previously discovered issues.

#### Examples

- GitLab `13.1`: A security fix in Rails `6.0.3.1` introduced a CSRF token change
  (causing a canary environment incident). We introduced code to maintain acceptance
  of previously generated tokens, and removed the code in `13.2`, creating a known
  required stop in `13.1`.
- GitLab `15.4`: Introduces a migration to fix an inaccurate `expires_at` timestamp
  for job artifacts that had been mitigated in code since GitLab `14.9`. The
  workaround was removed in GitLab `15.6`, causing `15.4` to be a required stop.

### Deprecations

Deprecations, particularly [breaking changes](../update/terminology.md#breaking-change)
can also cause required stops if they introduce long migration delays or require
manual actions on the part of GitLab administrators.

These are generally accepted as a required stop around a major release, either
stopping at the latest `major.minor` release immediately proceeding
a new `major` release, and potentially the latest `major.0` patch release, and
to date, discovered required stops related to deprecations have been limited to
these releases.

Not every deprecation is granted a required stop, as in most cases, the user
is able to tweak their configuration before they start their upgrade without causing
downtime or other major issues.

#### Examples

Examples of deprecations are too numerous to be listed here, but can found in the:

- [Deprecations and removals by version](../update/deprecations.md).
- Version-specific upgrading instructions:
  - [GitLab 17](../update/versions/gitlab_17_changes.md)
  - [GitLab 16](../update/versions/gitlab_16_changes.md)
  - [GitLab 15](../update/versions/gitlab_15_changes.md)
- [GitLab chart upgrade notes](https://docs.gitlab.com/charts/installation/upgrade.html).

## Adding required stops

### Planning the required stop milestone

We can't add required stops to every milestone, as this hurts our user experience
while upgrading GitLab. The Distribution group is responsible for helping planning and defining
when required stops are introduced.

From GitLab 17.5, we will introduce required stops in the X.2, X.5, X.8, and X.11 minor milestones. If you introduce code changes or features that require an upgrade stop, you
must align your changes with these milestones in mind.

### Before the required stop is released

Before releasing a known required stop, complete these steps. If the required stop
is identified after release, the following steps must still be completed:

1. In the same MR, update the [upgrade paths](../update/upgrade_paths.md) documentation to include the new
   required stop, and the [`upgrade_path.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/upgrade_path.yml).
   The `upgrade_path.yml` is the single source of truth (SSoT) for all our required stops.
1. Communicate the changes with the customer Support and Release management teams.
1. File an issue with the Database group to squash migrations to that version in the next release. Use this
   template for your issue:

   ```markdown
   Title: `Squash migrations to <Required stop version>`
   As a result of the required stop added for <required stop version> we should squash
   migrations up to that version, and update the minimum schema version.

   Deliverables:
   - [ ] Migrations are squashed up to <required stop version>
   - [ ] `Gitlab::Database::MIN_SCHEMA_VERSION` matches init_schema version

   /label ~"group::database" ~"section::enablement" ~"devops::data_stores" ~"Category:Database" ~"type::maintenance"
   /cc @gitlab-org/database-team/triage
   ```

### In the release following the required stop

1. In the `charts` project, update the
   [upgrade check hook](https://docs.gitlab.com/charts/development/upgrade_stop.html)
   to the required stop version.

## GitLab-maintained projects which depend on `upgrade_path.yml`

We have multiple projects depending on the `upgrade_path.yml` SSoT. Therefore,
any change to the structure of this file needs to take into consideration that
it might affect one of the following projects:

- [Release Tools](https://gitlab.com/gitlab-org/release-tools)
- [Support Upgrade Path](https://gitlab.com/gitlab-com/support/toolbox/upgrade-path)
- [Upgrade Tester](https://gitlab.com/gitlab-org/quality/upgrade-tester)
- [GitLab QA](https://gitlab.com/gitlab-org/gitlab-qa)
- [PostgreSQL Dump Generator](https://gitlab.com/gitlab-org/quality/pg-dump-generator)

## Further reading

- [Documentation: Database required stops](database/required_stops.md)
- [Documentation: Upgrading GitLab](../update/_index.md)
  - [Package (Omnibus) upgrade](../update/package/_index.md)
  - [Docker upgrade](../install/docker/upgrade.md)
  - [GitLab chart](https://docs.gitlab.com/charts/installation/upgrade.html)
- [Example of required stop planning issue (17.3)](https://gitlab.com/gitlab-org/gitlab/-/issues/457453)
- [Issue: Put in place measures to avoid addition/proliferation of GitLab upgrade path stops](https://gitlab.com/gitlab-org/gitlab/-/issues/375553)
- [Issue: Brainstorm ways for background migrations to be finalized without introducing a required upgrade step](https://gitlab.com/gitlab-org/gitlab/-/issues/357561)
- [Issue: Scheduled required paths for GitLab upgrades to improve UX](https://gitlab.com/gitlab-org/gitlab/-/issues/358417)
- [Issue: Automate upgrade stop planning process](https://gitlab.com/gitlab-org/gitlab/-/issues/438921)
- [Epic: GitLab Releases and Maintenance policies](https://gitlab.com/groups/gitlab-com/gl-infra/-/epics/988)
