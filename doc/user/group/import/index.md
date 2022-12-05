---
stage: Manage
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Migrating groups with GitLab Migration **(FREE)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/249160) in GitLab 13.7 for group resources [with a flag](../../feature_flags.md) named `bulk_import`. Disabled by default.
> - Group items [enabled on GitLab.com and self-managed](https://gitlab.com/gitlab-org/gitlab/-/issues/338985) in GitLab 14.3.
> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/267945) in GitLab 14.4 for project resources [with a flag](../../feature_flags.md) named `bulk_import_projects`. Disabled by default.
> - [Enabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/339941) in GitLab 15.6.

FLAG:
On self-managed GitLab, by default [migrating group items](#migrated-group-items) is available. To hide the
feature, ask an administrator to [disable the feature flag](../../../administration/feature_flags.md) named `bulk_import`.
On self-managed GitLab, by default [migrating project items](#migrated-project-items) is not available. To show
this feature, ask an administrator to [enable the feature flag](../../../administration/feature_flags.md) named
`bulk_import_projects`. On GitLab.com, migration of both groups and projects is available.

Users with the Owner role on a top-level group can use GitLab Migration to migrate the group to:

- Another top-level group.
- The subgroup of any existing top-level group.
- Another GitLab instance, including GitLab.com.

Migrating groups using GitLab Migration is not the same as [migrating groups using file exports](../settings/import_export.md).
Importing and exporting groups using file exports requires you to export a group to a file and then import that file in
another GitLab instance. Migrating groups using GitLab Migration automates this step.

## Import your groups into GitLab

When you migrate a group, you connect to your GitLab instance and then choose
groups to import. Not all the data is migrated. See:

- [Migrated group items](#migrated-group-items).
- [Migrated project items](#migrated-project-items).

Leave feedback about group migration in [the relevant issue](https://gitlab.com/gitlab-org/gitlab/-/issues/284495).

NOTE:
You might need to reconfigure your firewall to prevent blocking the connection on the self-managed
instance.

### Connect to the remote GitLab instance

Before you begin, ensure that the target GitLab instance can communicate with the source over HTTPS
(HTTP is not supported). You might need to reconfigure your firewall to prevent blocking the connection on the self-managed
instance.

Then create the group you want to import into, and connect:

1. Create a new group or subgroup:

   - On the top bar, select `+` and then **New group**.
   - Or, on an existing group's page, in the top right, select **New subgroup**.

1. Select **Import group**.
1. Enter the source URL of your GitLab instance.
1. Generate or copy a [personal access token](../../../user/profile/personal_access_tokens.md)
   with the `api` and `read_repository` scopes on your remote GitLab instance.
1. Enter the [personal access token](../../../user/profile/personal_access_tokens.md) for your remote GitLab instance.
1. Select **Connect instance**.

### Select the groups to import

After you have authorized access to the GitLab instance, you are redirected to the GitLab Group
Migration importer page. The remote groups you have the Owner role for are listed.

1. By default, the proposed group namespaces match the names as they exist in remote instance, but based on your permissions, you can choose to edit these names before you proceed to import any of them.
1. Next to the groups you want to import, select **Import**.
1. The **Status** column shows the import status of each group. If you leave the page open, it updates in real-time.
1. After a group has been imported, select its GitLab path to open its GitLab URL.

![Group Importer page](img/bulk_imports_v14_1.png)

## Automate group and project import **(PREMIUM)**

For information on automating user, group, and project import API calls, see
[Automate group and project import](../../project/import/index.md#automate-group-and-project-import).

## Migrated group items

The [`import_export.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/import_export/group/import_export.yml)
file for groups lists many of the items migrated when migrating groups using group migration. View this file in the branch
for your version of GitLab to see the list of items relevant to you. For example,
[`import_export.yml` on the `14-10-stable-ee` branch](https://gitlab.com/gitlab-org/gitlab/-/blob/14-10-stable-ee/lib/gitlab/import_export/group/import_export.yml).

Migrating projects with file exports uses the same export and import mechanisms as creating projects from templates at the [group](../custom_project_templates.md) and
[instance](../../admin_area/custom_project_templates.md) levels. Therefore, the list of exported items is the same.

Items that are migrated to the target instance include:

- Badges ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/292431) in 13.11)
- Board Lists
- Boards
- Epics ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/250281) in 13.7)
  - Epic resource state events ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/291983) in GitLab 15.4)
- Finisher
- Group Labels ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/292429) in 13.9)
- Iterations ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/292428) in 13.10)
- Iterations cadences ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/96570) in 15.4)
- Members ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/299415) in 13.9)
  Group members are associated with the imported group if:
  - The user already exists in the target GitLab instance and
  - The user has a public email in the source GitLab instance that matches a
    confirmed email in the target GitLab instance
- Milestones ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/292427) in 13.10)
- Namespace Settings
- Releases
  - Milestones ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/339422) in GitLab 15.0).
- Subgroups
- Uploads

Any other items are **not** migrated.

## Migrated project items

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/267945) in GitLab 14.4 [with a flag](../../feature_flags.md) named `bulk_import_projects`. Disabled by default.
> - [Enabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/339941) in GitLab 15.6.

FLAG:
On self-managed GitLab, migrating project resources are not available by default. To make them available, ask an administrator to [enable the feature flag](../../../administration/feature_flags.md) named `bulk_import_projects`. On GitLab.com, migration of project resources is available.

The [`import_export.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/import_export/project/import_export.yml)
file for projects lists many of the items migrated when migrating projects using group migration. View this file in the branch
for your version of GitLab to see the list of items relevant to you. For example,
[`import_export.yml` on the `14-10-stable-ee` branch](https://gitlab.com/gitlab-org/gitlab/-/blob/14-10-stable-ee/lib/gitlab/import_export/project/import_export.yml).

Migrating projects with file exports uses the same export and import mechanisms as creating projects from templates at the [group](../../group/custom_project_templates.md) and
[instance](../../admin_area/custom_project_templates.md) levels. Therefore, the list of exported items is the same.

- Projects ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/267945) in GitLab 14.4)
  - Auto DevOps ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/339410) in GitLab 14.6)
  - Branches (including protected branches) ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/339414) in GitLab 14.7)
  - CI Pipelines ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/339407) in GitLab 14.6)
  - Designs ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/339421) in GitLab 15.1)
  - Issues ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/267946) in GitLab 14.4)
    - Issue iteration ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/96184) in 15.4)
    - Issue resource state events ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/291983) in GitLab 15.4)
    - Issue resource milestone events ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/291983) in GitLab 15.4)
    - Issue resource iteration events ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/291983) in GitLab 15.4)
    - Merge request URL references ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/267947) in GitLab 15.6)
  - Labels ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/339419) in GitLab 14.4)
  - LFS Objects ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/339405) in GitLab 14.8)
  - Members ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/341886) in GitLab 14.8)
  - Merge Requests ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/339403) in GitLab 14.5)
    - Multiple merge request assignees ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/339520) in GitLab 15.3)
    - Merge request reviewers ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/339520) in GitLab 15.3)
    - Merge request approvers ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/339520) in GitLab 15.3)
    - Merge request resource state events ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/291983) in GitLab 15.4)
    - Merge request resource milestone events ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/291983) in GitLab 15.4)
    - Issue URL references ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/267947) in GitLab 15.6)
  - Migrate Push Rules ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/339403) in GitLab 14.6)
  - Pull Requests (including external pull requests) ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/339409) in GitLab 14.5)
  - Pipeline History ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/339412) in GitLab 14.6)
  - Pipeline Schedules ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/339408) in GitLab 14.8)
  - Releases ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/339422) in GitLab 15.1)
  - Release Evidences ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/360567) in GitLab 15.1)
  - Repositories ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/267945) in GitLab 14.4)
  - Snippets ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/343438) in GitLab 14.6)
  - Uploads ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/339401) in GitLab 14.5)
  - Wikis ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/345923) in GitLab 14.6)

## Troubleshooting Group Migration

In a [rails console session](../../../administration/operations/rails_console.md#starting-a-rails-console-session),
you can find the failure or error messages for the group import attempt using:

```ruby
# Get relevant import records
import = BulkImports::Entity.where(namespace_id: Group.id).map(&:bulk_import)

# Alternative lookup by user
import = BulkImport.where(user_id: User.find(...)).last

# Get list of import entities. Each entity represents either a group or a project
entities = import.entities

# Get a list of entity failures
entities.map(&:failures).flatten

# Alternative failure lookup by status
entities.where(status: [-1]).pluck(:destination_name, :destination_namespace, :status)
```

### Stale imports

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/352985) in GitLab 14.10.

When troubleshooting group migration, an import may not complete because the import workers took
longer than 8 hours to execute. In this case, the `status` of either a `BulkImport` or
`BulkImport::Entity` is `3` (`timeout`):

```ruby
# Get relevant import records
import = BulkImports::Entity.where(namespace_id: Group.id).map(&:bulk_import)

import.status #=> 3 means that the import timed out.
```

### Error: `404 Group Not Found`

If you attempt to import a group that has a path comprised of only numbers (for example, `5000`), GitLab attempts to find the group by ID instead of the
path. This causes a `404 Group Not Found` error. To solve this, the source group path must be changed to include a non-numerical character using either:

- The GitLab UI:

  1. On the top bar, select **Main menu > Groups** and find your group.
  1. On the left sidebar, select **Settings > General**.
  1. Expand **Advanced**.
  1. Under **Change group URL**, change the group URL to include non-numeric characters.

- The [Groups API](../../../api/groups.md#update-group).
