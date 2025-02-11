---
stage: Foundations
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Migrating GitLab by using direct transfer
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

> - [Enabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/339941) in GitLab 15.6.
> - New application setting `bulk_import_enabled` [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/383268) in GitLab 15.8. `bulk_import` feature flag removed.
> - `bulk_import_projects` feature flag [removed](https://gitlab.com/gitlab-org/gitlab/-/issues/339941) in GitLab 15.10.

You can migrate GitLab groups:

- From GitLab Self-Managed to GitLab.com.
- From GitLab.com to GitLab Self-Managed.
- From one GitLab Self-Managed instance to another.
- Between groups in the same GitLab instance.

Migration by direct transfer creates a new copy of the group. If you want to move groups instead of copying groups, you
can [transfer groups](../manage.md#transfer-a-group) if the groups are in the same GitLab instance. Transferring groups
instead of migrating them is a faster and more complete option.

You can migrate groups in two ways:

- By direct transfer (recommended).
- By [uploading an export file](../../project/settings/import_export.md).

If you migrate from GitLab.com to a GitLab Self-Managed instance, an administrator can create users on the instance.

On GitLab Self-Managed, by default [migrating group items](migrated_items.md#migrated-group-items) is not available. To show the
feature, an administrator can [enable it in application settings](../../../administration/settings/import_and_export_settings.md#enable-migration-of-groups-and-projects-by-direct-transfer).

Migrating groups by direct transfer copies the groups from one place to another. You can:

- Copy many groups at once.
- In the GitLab UI, copy top-level groups to:
  - Another top-level group.
  - The subgroup of any existing top-level group.
  - Another GitLab instance, including GitLab.com.
- In the [API](../../../api/bulk_imports.md), copy top-level groups and subgroups to these locations.
- Copy groups with projects (in [beta](../../../policy/development_stages_support.md#beta) and not ready for production
  use) or without projects. Copying projects with groups is available:
  - On GitLab.com by default.

Not all group and project resources are copied. See list of copied resources below:

- [Migrated group items](migrated_items.md#migrated-group-items).
- [Migrated project items](migrated_items.md#migrated-project-items).

After you start a migration, you should not make any changes to imported groups or projects
on the source instance because these changes might not be copied to the destination instance.

WARNING:
Importing groups with projects is in [beta](../../../policy/development_stages_support.md#beta). This feature is not
ready for production use.

We invite you to leave your feedback about migrating by direct transfer in
[the feedback issue](https://gitlab.com/gitlab-org/gitlab/-/issues/284495).

## Migrating specific projects

Migrating groups by using direct transfer in the GitLab UI migrates all projects in the group. If you want to migrate only specific projects in the group by using direct
transfer, you must use the [API](../../../api/bulk_imports.md#start-a-new-group-or-project-migration).

## Known issues

- Because of [issue 406685](https://gitlab.com/gitlab-org/gitlab/-/issues/406685), files with a filename longer than 255 characters are not migrated.
- In GitLab 16.1 and earlier, you should **not** use direct transfer with
  [scheduled scan execution policies](../../application_security/policies/scan_execution_policies.md).
- For a list of other known issues, see [epic 6629](https://gitlab.com/groups/gitlab-org/-/epics/6629).
- In GitLab 16.9 and earlier, because of [issue 438422](https://gitlab.com/gitlab-org/gitlab/-/issues/438422), you might see the
  `DiffNote::NoteDiffFileCreationError` error. When this error occurs, the diff of a note on a merge request's diff
  is missing, but the note and the merge request are still imported.
- When mapped from the source instance, shared members are mapped as direct members on the destination unless those
  memberships already exist on the destination. This means that importing a top-level group on the source instance to a
  top-level group on the destination instance always maps to direct members in projects, even though the source top-level
  group contains the necessary shared membership hierarchy details. Support for full mapping of shared memberships is
  proposed in [issue 458345](https://gitlab.com/gitlab-org/gitlab/-/issues/458345).
- In GitLab 17.0, 17.1, and 17.2, imported epics and work items are mapped
  to the importing user rather than the original author.

## Estimating migration duration

Estimating the duration of migration by direct transfer is difficult. The following factors affect migration duration:

- Hardware and database resources available on the source and destination GitLab instances. More resources on the source and destination instances can result in
  shorter migration duration because:
  - The source instance receives API requests, and extracts and serializes the entities to export.
  - The destination instance runs the jobs and creates the entities in its database.
- Complexity and size of data to be exported. For example, imagine you want to migrate two different projects with 1000 merge requests each. The two projects can take
  very different amounts of time to migrate if one of the projects has a lot more attachments, comments, and other items on the merge requests. Therefore, the number
  of merge requests on a project is a poor predictor of how long a project will take to migrate.

There's no exact formula to reliably estimate a migration. However, the average durations of each pipeline worker importing a project relation can help you to get an idea of how long importing your projects might take:

| Project resource type       | Average time (in seconds) to import a record |
|:----------------------------|:---------------------------------------------|
| Empty Project               | 2.4                                          |
| Repository                  | 20                                           |
| Project Attributes          | 1.5                                          |
| Members                     | 0.2                                          |
| Labels                      | 0.1                                          |
| Milestones                  | 0.07                                         |
| Badges                      | 0.1                                          |
| Issues                      | 0.1                                          |
| Snippets                    | 0.05                                         |
| Snippet Repositories        | 0.5                                          |
| Boards                      | 0.1                                          |
| Merge Requests              | 1                                            |
| External Pull Requests      | 0.5                                          |
| Protected Branches          | 0.1                                          |
| Project Feature             | 0.3                                          |
| Container Expiration Policy | 0.3                                          |
| Service Desk Setting        | 0.3                                          |
| Releases                    | 0.1                                          |
| CI Pipelines                | 0.2                                          |
| Commit Notes                | 0.05                                         |
| Wiki                        | 10                                           |
| Uploads                     | 0.5                                          |
| LFS Objects                 | 0.5                                          |
| Design                      | 0.1                                          |
| Auto DevOps                 | 0.1                                          |
| Pipeline Schedules          | 0.5                                          |
| References                  | 5                                            |
| Push rule                   | 0.1                                          |

Though it's difficult to predict migration duration, we've seen:

- 100 projects (19.9k issues, 83k merge requests, 100k+ pipelines) migrated in 8 hours.
- 1926 projects (22k issues, 160k merge requests, 1.1 million pipelines) migrated in 34 hours.

If you are migrating large projects and encounter problems with timeouts or duration of the migration, see [Reducing migration duration](#reducing-migration-duration).

## Reducing migration duration

These are some strategies for reducing the duration of migrations that use direct transfer.

### Add Sidekiq workers to the destination instance

A single direct transfer migration runs five entities (groups or projects) per import at a time,
regardless of the number of workers available on the destination instance.
More Sidekiq workers on the destination instance can reduce the time it takes to import each entity,
as long as the instance has enough resources to handle additional concurrent jobs.
In GitLab 16.8 and later, with the introduction of bulk import and export of relations,
the number of available workers on the destination instance has become more critical.

For more information about how to add Sidekiq workers to the destination instance,
see [Sidekiq configuration](../../project/import/_index.md#sidekiq-configuration).

### Redistribute large projects or start separate migrations

The number of workers on the source instance should be enough to export the 5 concurrent entities in parallel (for each running import). Otherwise, there can be
delays and potential timeouts as the destination is waiting for exported data to become available.

Distributing projects in different groups helps to avoid timeouts. If several large projects are in the same group, you can:

1. Move large projects to different groups or subgroups.
1. Start separate migrations each group and subgroup.

The GitLab UI can only migrate top-level groups. Using the API, you can also migrate subgroups.

## Limits

> - Eight hour time limit on migrations [removed](https://gitlab.com/gitlab-org/gitlab/-/issues/429867) in GitLab 16.7.

Hardcoded limits apply on migration by direct transfer.

| Limit       | Description                                                                                                                                                                     |
|:------------|:--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 6           | Maximum number of migrations permitted by a destination GitLab instance per minute per user. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/386452) in GitLab 15.9. |
| 210 seconds | Maximum number of seconds to wait for decompressing an archive file.                                                                                                            |
| 50 MB       | Maximum length an NDJSON row can have.                                                                                                                                          |
| 5 minutes   | Maximum number of seconds until an empty export status on source instance is raised.                                                                                            |

[Configurable limits](../../../administration/settings/account_and_limit_settings.md) are also available.

In GitLab 16.3 and later, the following previously hard-coded settings are [configurable](https://gitlab.com/gitlab-org/gitlab/-/issues/384976):

- Maximum relation size that can be downloaded from the source instance (set to 5 GiB).
- Maximum size of a decompressed archive (set to 10 GiB).

You can test the maximum relation size limit using these APIs:

- [Group relations export API](../../../api/group_relations_export.md).
- [Project relations export API](../../../api/project_relations_export.md)

If either API produces files larger than the maximum relation size limit, group migration by direct transfer fails.

## Visibility rules

After migration:

- Private groups and projects stay private.
- Internal groups and projects:
  - Stay internal when copied into an internal group unless internal visibility is [restricted](../../../administration/settings/visibility_and_access_controls.md#restrict-visibility-levels). In that case, the groups and projects become private.
  - Become private when copied into a private group.
- Public groups and projects:
  - Stay public when copied into a public group unless public visibility is [restricted](../../../administration/settings/visibility_and_access_controls.md#restrict-visibility-levels). In that case, the groups and projects become internal.
  - Become internal when copied into an internal group unless internal visibility is [restricted](../../../administration/settings/visibility_and_access_controls.md#restrict-visibility-levels). In that case, the groups and projects become private.
  - Become private when copied into a private group.

If you used a private network on your source instance to hide content from the general public,
make sure to have a similar setup on the destination instance, or to import into a private group.

## Migration by direct transfer process

See [Migrate groups and projects by using direct transfer](direct_transfer_migrations.md).
