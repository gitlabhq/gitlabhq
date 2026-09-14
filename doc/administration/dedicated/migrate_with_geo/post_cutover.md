---
stage: GitLab Dedicated
group: Environment Automation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Version catch-up, feature activation, and license application after your instance is promoted.
title: Post-migration activities
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Dedicated

{{< /details >}}

After your GitLab Dedicated instance is promoted to the primary site,
several capabilities activate in a sequence of scheduled activities, arranged with you.
These activities happen after promotion rather than before, because they either cannot run while the
instance is a Geo secondary site, or they are deliberately held until you confirm that the migration
succeeded.

GitLab performs each of these activities except adding your license, which you do yourself.
Each one starts only after your post-cutover validation passes and your instance serves your users
without open issues from the cutover.
Your Professional Services migration team coordinates the schedule with you.

## Version catch-up

Upgrades are frozen from the pre-production cutover until the production cutover.
The freeze keeps both environments on an identical version, so that what you test is what you get.

Because of the freeze, when your instance is promoted it runs a version behind the rest of the GitLab Dedicated fleet.
GitLab Dedicated runs the previous minor version (N-1) relative to the current GitLab release.
For more information, see the [versioning model](../releases.md#versioning-model).

Catching up is deliberate, sequential work.
Your instance is upgraded through the intervening versions across multiple maintenance windows rather
than in a single jump.
Each of these upgrades is a
[zero-downtime upgrade](../maintenance.md#zero-downtime-upgrades), so catching up does not mean repeated
outages for your users.

An upgrade path can include required intermediate versions.
To see the versions a path includes, use the
[upgrade path tool](https://gitlab-com.gitlab.io/support/toolbox/upgrade-path/).

GitLab re-enables your weekly maintenance window after the catch-up is complete.
From that point, your instance follows the standard monthly release cadence like any other GitLab
Dedicated instance.
For more information, see [maintenance windows](../maintenance.md#maintenance-windows) and the
[release rollout schedule](../releases.md#release-rollout-schedule).

To track GitLab Dedicated version schedules, use the
[GitLab Dedicated info portal](https://gitlab-com.gitlab.io/cs-tools/gitlab-cs-tools/dedicated-info-portal/).

> [!note]
> During the catch-up period, your instance can run an older version than other GitLab Dedicated
> instances.
> This difference is expected and temporary.

## Advanced search

Advanced search is fully supported on GitLab Dedicated, and GitLab provisions and manages the search
infrastructure.

Geo does not replicate the advanced search index, so the index cannot be built while your instance is a
Geo secondary site.
GitLab therefore activates advanced search after promotion, at a time arranged with you, and indexes
your content then.
Your existing search cluster from the source instance is not migrated.
Basic search remains available while indexing runs.

For more information, see [advanced search](../../../integration/advanced_search/elasticsearch.md).

## Advanced analytics

Advanced analytical features are backed by ClickHouse Cloud.
These features are not active when your instance is promoted.
GitLab activates them in a separate scheduled step after the cutover.

Availability depends on your primary region, because ClickHouse Cloud is available only in supported
regions.
For more information, see [ClickHouse Cloud regions](../create_instance/data_residency_high_availability.md#clickhouse-cloud).

For what the integration provides, see [ClickHouse](../../../integration/clickhouse.md).

## Geo secondary site for disaster recovery

During the migration, your GitLab Dedicated instance runs as a single site.
Its secondary region is not configured, because the instance is itself acting as a Geo secondary site of
your source instance.
The standard GitLab Dedicated Geo disaster recovery topology is therefore not in place during the
migration.

GitLab adds the secondary site after the migration is complete.
Adding the secondary site is a deliberate step, because after it is added, returning to the earlier
replication arrangement is no longer possible.
After the secondary site is added, your instance has the same disaster recovery posture as any other
GitLab Dedicated instance.

For more information, see [Geo replication for disaster recovery](../disaster_recovery.md#geo-replication).

> [!note]
> Automated backups are in place throughout, including during the migration.
> For more information, see [automated backups](../disaster_recovery.md#automated-backups).

## Runners and CI/CD

Runner registration records are stored in the database, and the database is migrated, so your existing
runners are preserved.

If you keep your own domain, the instance hostname does not change, and your runners reconnect to GitLab
Dedicated without any configuration change.
If you move to a GitLab-provided domain, update the instance URL in your runner configuration.

Runners on much older GitLab versions can experience reconnection delays.
To keep the cutover smooth, bring self-managed runners up to a current version before the migration
window.

For more information, see
[runner connectivity during failover](../../geo/disaster_recovery/planned_failover.md#runner-connectivity-during-failover).

For GitLab-managed runners, see [hosted runners](../hosted_runners.md).

## Integrations and authentication

Integrations, webhooks, and outbound connectivity are validated during the pre-production
[testing period](process.md#testing-period).
After the production cutover, confirm the same integrations against your production instance.

Confirm the following items:

- Single sign-on
- Webhook delivery to your internal targets
- Email delivery
- Container registry access from runners and Kubernetes clusters
- Any integrations that reach private targets over outbound AWS PrivateLink
- Any external SaaS service that calls your instance, which needs an IP allowlist exception if you use
  an allowlist

You must re-register your GitLab agents for Kubernetes against the new GitLab agent server for
Kubernetes (KAS) URL.

## Add your GitLab Dedicated license

You must add your GitLab Dedicated license after the cutover.

During the migration, your database carries the license from your GitLab Self-Managed instance,
because GitLab replicates license information with the rest of the database.
That license does not cover your GitLab Dedicated subscription.

Your license contact receives the activation code for GitLab Dedicated and must activate it on the
promoted instance.
For more information, see [add the license key](../../license_file.md#add-license-in-the-admin-area).

If you did not receive the activation code, or activation fails, contact your GitLab account team.

## Related topics

- [Geo migration to GitLab Dedicated](_index.md)
- [Geo migration requirements](requirements.md)
- [Geo migration process](process.md)
