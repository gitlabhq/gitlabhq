---
stage: GitLab Dedicated
group: Environment Automation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Migrate from GitLab Self-Managed to GitLab Dedicated with Geo.
title: Migrate to GitLab Dedicated with Geo
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Dedicated

{{< /details >}}

Geo replicates your GitLab Self-Managed instance to GitLab Dedicated,
then promotes it to your primary site.
This method migrates the most complete set of data, including repositories, database records,
and object storage contents.

Your instance stays in service throughout replication. Migration itself requires downtime only
during the cutover window. However, preparing your source instance beforehand might require
separate downtime.

GitLab Professional Services runs the migration with you.
Geo applies only when your source is a GitLab Self-Managed instance.
To migrate from GitLab.com or from another source control management system, or to migrate individual
groups and projects rather than a whole instance, see
[migrate to GitLab Dedicated](../../../subscriptions/gitlab_dedicated/_index.md#migrate-to-gitlab-dedicated).

## Migration phases

A Geo migration runs in the following phases:

| Phase | What happens | Who acts |
|-------|--------------|----------|
| Discovery and planning | Before you finalize your purchase of GitLab Dedicated, your Solutions Architect or Account Executive helps collect information about your environment. GitLab uses this information to assess migration feasibility, sizing, and timeline. | You and GitLab |
| Instance creation | After your purchase is finalized, you create your GitLab Dedicated instance yourself, or GitLab Professional Services creates it with you if you prefer. | You |
| Preparation | You move data to object storage, align repository storage names, build migration connectivity, and create database read replicas. You can do this work yourself or together with GitLab. For more information, see [Geo migration requirements](requirements.md) and [collect Geo migration secrets](secrets.md). | You, or you and GitLab |
| Geo replication | While GitLab replicates your data to your new GitLab Dedicated instance, your existing instance stays in service. For more information, see [Geo migration process](process.md). | GitLab |
| Cutover and testing | You rehearse the process with a pre-production cutover, test the result, then complete the migration with the production cutover. | You and GitLab |
| Post-migration activities | GitLab applies the remaining upgrades and activates capabilities such as advanced search, on a schedule agreed with you. You add your GitLab Dedicated license. For more information, see [post-migration activities](post_cutover.md). | You and GitLab |

GitLab Professional Services uses the
[Geo migration delivery kit](https://gitlab.com/gitlab-org/professional-services-automation/delivery-kits/migration-delivery-kits/migration-delivery-kit/-/blob/main/Geo/dedicated.md)
for the step-by-step technical procedures and scripts throughout these phases.

Plan for several months from discovery to production cutover.
GitLab confirms the timeline with you, because it depends on how much data you have and how much
preparation work your environment needs.

> [!note]
> You need only one environment of your own.
> You migrate from your single production instance.
> GitLab provisions both a pre-production and a production tenant, and the pre-production tenant
> exists only during the migration window so that one full cutover rehearsal can be run.
> You do not build or maintain it.

## Related topics

- [GitLab Dedicated architecture](../architecture.md)
- [Create your GitLab Dedicated instance](../create_instance/_index.md)
- [Geo](../../geo/_index.md)
