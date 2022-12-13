---
stage: Manage
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Migrating GitLab groups **(FREE)**

You can migrate GitLab groups:

- From self-managed GitLab to GitLab.com.
- From GitLab.com to self-managed GitLab.
- From one self-managed GitLab instance to another.
- Between groups in the same GitLab instance.

You can migrate groups in two ways:

- By direct transfer (recommended).
- By uploading an export file.

## Migrate groups by direct transfer (recommended)

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

Prerequisites:

- Network connection between instances or GitLab.com. Must support HTTPS.
- Owner role on the top-level group to migrate.

You can import top-level groups to:

- Another top-level group.
- The subgroup of any existing top-level group.
- Another GitLab instance, including GitLab.com.

You can migrate:

- By direct transfer using either the UI or the [API](../../../api/bulk_imports.md).
- Many groups at once.

When migrating a top-level group to GitLab.com, all its subgroups and projects are migrated too.

Not all group and project resources are imported. See list of migrated resources below:

- [Migrated group items](#migrated-group-items).
- [Migrated project items](#migrated-project-items).

### Preparation

GitLab maps users and their contributions correctly provided:

- Users already exists on the target GitLab instance.
- Users have a public email on the source GitLab instance that matches their primary email on the target GitLab instance.
- When using an OmniAuth provider like SAML, GitLab and SAML accounts of users on GitLab must be linked. All users on the target GitLab instance must sign in
  and verify their account on the target GitLab instance.

You might need to reconfigure your firewall to prevent blocking the connection on the self-managed
instance.

### Connect to the source GitLab instance

Create the group you want to import to and connect the source:

1. Create either:

   - A new group. On the top bar, select **{plus-square}**, then **New group**, and select **Import group**.
   - A new subgroup. On existing group's page, either:
     - Select **New subgroup**.
     - On the top bar, Select **{plus-square}** and then **New subgroup**. Then on the left sidebar, select the **import an existing group** link.
1. Enter the URL of your source GitLab instance.
1. Generate or copy a [personal access token](../../../user/profile/personal_access_tokens.md)
   with the `api` scope on your source GitLab instance. Both `api` and `read_repository` scopes are required when migrating from GitLab 15.0 and earlier.
1. Enter the [personal access token](../../../user/profile/personal_access_tokens.md) for your source GitLab instance.
1. Select **Connect instance**.

### Select the groups to import

After you have authorized access to the source GitLab instance, you are redirected to the GitLab group
importer page. The top-level groups on the connected source instance you have the Owner role for are listed.

1. By default, the proposed group namespaces match the names as they exist in source instance, but based on your permissions, you can choose to edit these names before you proceed to import any of them.
1. Next to the groups you want to import, select **Import**.
1. The **Status** column shows the import status of each group. If you leave the page open, it updates in real-time.
1. After a group has been imported, select its GitLab path to open its GitLab URL.

![Group Importer page](img/bulk_imports_v14_1.png)

### Group import history

You can view all groups migrated by you by direct transfer listed on the group import history page. This list includes:

- Paths of source groups.
- Paths of destination groups.
- Start date of each import.
- Status of each import.
- Error details if any errors occurred.

To view group import history:

1. Sign in to GitLab.
1. On the top bar, select **Create new…** (**{plus-square}**).
1. Select **New group**.
1. Select **Import group**.
1. Select **History** in the upper right corner.
1. If there are any errors for a particular import, you can see them by selecting **Details**.

### Migrated group items

The [`import_export.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/import_export/group/import_export.yml)
file for groups lists many of the items imported when migrating groups by direct transfer. View this file in the branch
for your version of GitLab to see the list of items relevant to you. For example,
[`import_export.yml` on the `14-10-stable-ee` branch](https://gitlab.com/gitlab-org/gitlab/-/blob/14-10-stable-ee/lib/gitlab/import_export/group/import_export.yml).

Group items that are migrated to the target instance include:

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

### Migrated project items

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/267945) in GitLab 14.4 [with a flag](../../feature_flags.md) named `bulk_import_projects`. Disabled by default.
> - [Enabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/339941) in GitLab 15.6.

FLAG:
On self-managed GitLab, migrating project resources when migrating groups is not available by default. To make it available ask an administrator to [enable the feature flag](../../../administration/feature_flags.md) named `bulk_import_projects`. On GitLab.com, groups are migrated with all their projects by default.

The [`import_export.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/import_export/project/import_export.yml)
file for projects lists many of the items imported when migrating projects using group migration. View this file in the branch
for your version of GitLab to see the list of items relevant to you. For example,
[`import_export.yml` on the `14-10-stable-ee` branch](https://gitlab.com/gitlab-org/gitlab/-/blob/14-10-stable-ee/lib/gitlab/import_export/project/import_export.yml).

Project items that are migrated to the target instance include:

- Projects ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/267945) in GitLab 14.4)
  - Auto DevOps ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/339410) in GitLab 14.6)
  - Badges ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/75029) in GitLab 14.6)
  - Branches (including protected branches) ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/339414) in GitLab 14.7)
  - CI Pipelines ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/339407) in GitLab 14.6)
  - Designs ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/339421) in GitLab 15.1)
  - Issues ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/267946) in GitLab 14.4)
    - Issue iteration ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/96184) in 15.4)
    - Issue resource state events ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/291983) in GitLab 15.4)
    - Issue resource milestone events ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/291983) in GitLab 15.4)
    - Issue resource iteration events ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/291983) in GitLab 15.4)
    - Merge request URL references ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/267947) in GitLab 15.6)
    - Time Tracking ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/267946) in GitLab 14.4)
  - Issue boards ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/71661) in GitLab 14.4)
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
    - Time Tracking ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/339403) in GitLab 14.5)
  - Push Rules ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/339403) in GitLab 14.6)
  - Milestones ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/339417) in GitLab 14.5)
  - External Pull Requests ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/339409) in GitLab 14.5)
  - Pipeline History ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/339412) in GitLab 14.6)
  - Pipeline Schedules ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/339408) in GitLab 14.8)
  - Project Features ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/74722) in GitLab 14.6)
  - Releases ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/339422) in GitLab 15.1)
  - Release Evidences ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/360567) in GitLab 15.1)
  - Repositories ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/267945) in GitLab 14.4)
  - Snippets ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/343438) in GitLab 14.6)
  - Settings ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/339416) in GitLab 14.6)
    - Avatar ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/75249) in GitLab 14.6)
    - Container Expiration Policy ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/75653) in GitLab 14.6)
    - Project Properties ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/75898) in GitLab 14.6)
    - Service Desk ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/75653) in GitLab 14.6)
  - Uploads ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/339401) in GitLab 14.5)
  - Wikis ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/345923) in GitLab 14.6)

Items excluded from migration, because they contain sensitive information:

- Pipeline Triggers.

Migrating projects with file exports uses the same export and import mechanisms as creating projects from templates at the [group](../../group/custom_project_templates.md) and
[instance](../../admin_area/custom_project_templates.md) levels. Therefore, the list of exported items is the same.

### Troubleshooting

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

You can also see all migrated entities with any failures related to them using an
[API endpoint](../../../api/bulk_imports.md#list-all-gitlab-migrations-entities).

#### Stale imports

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/352985) in GitLab 14.10.

When troubleshooting group migration, an import may not complete because the import workers took
longer than 8 hours to execute. In this case, the `status` of either a `BulkImport` or
`BulkImport::Entity` is `3` (`timeout`):

```ruby
# Get relevant import records
import = BulkImports::Entity.where(namespace_id: Group.id).map(&:bulk_import)

import.status #=> 3 means that the import timed out.
```

### Provide feedback

Please leave your feedback about migrating groups by direct transfer in
[the feedback issue](https://gitlab.com/gitlab-org/gitlab/-/issues/284495).

## Migrate groups by uploading an export file (deprecated)

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/2888) in GitLab 13.0 as an experimental feature. May change in future releases.
> - [Deprecated](https://gitlab.com/groups/gitlab-org/-/epics/4619) in GitLab 14.6.

WARNING:
This feature was [deprecated](https://gitlab.com/groups/gitlab-org/-/epics/4619) in GitLab 14.6 and replaced by
[migrating groups by direct transfer](#migrate-groups-by-direct-transfer-recommended). To follow progress on a solution for
[offline environments](../../application_security/offline_deployments/index.md), see
[the relevant epic](https://gitlab.com/groups/gitlab-org/-/epics/8985).

Prerequisites:

- Owner role on the group to migrate.

Using file exports, you can:

- Export any group to a file and upload that file to another GitLab instance or to another location on the same instance.
- Use either the GitLab UI or the [API](../../../api/group_import_export.md).
- Migrate groups one by one, then export and import each project for the groups one by one.

GitLab maps user contributions correctly when an admin access token is used to perform the import. GitLab does not map
user contributions correctly when you are importing from a self-managed instance to GitLab.com. Correct mapping of user
contributions when importing from a self-managed instance to GitLab.com can be preserved with paid involvement of
Professional Services team.

Note the following:

- Exports are stored in a temporary directory and are deleted every 24 hours by a specific worker.
- To preserve group-level relationships from imported projects, run the Group Import/Export first, to allow projects to
  be imported into the desired group structure.
- Imported groups are given a `private` visibility level, unless imported into a parent group.
- If imported into a parent group, a subgroup inherits the same level of visibility unless otherwise restricted.
- You can export groups from the [Community Edition to the Enterprise Edition](https://about.gitlab.com/install/ce-or-ee/)
  and vice versa. The Enterprise Edition retains some group data that isn't part of the Community Edition. If you're
  exporting a group from the Enterprise Edition to the Community Edition, you may lose this data. For more information,
  see [downgrading from EE to CE](../../../index.md).

### Exported contents

The [`import_export.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/import_export/group/import_export.yml)
file for groups lists items exported and imported when migrating groups using file exports. View this file in the branch
for your version of GitLab to see the list of items relevant to you. For example,
[`import_export.yml` on the `14-10-stable-ee` branch](https://gitlab.com/gitlab-org/gitlab/-/blob/14-10-stable-ee/lib/gitlab/import_export/group/import_export.yml).

Group items that are exported include:

- Milestones
- Labels
- Boards and Board Lists
- Badges
- Subgroups (including all the aforementioned data)
- Epics
  - Epic resource state events ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/291983) in GitLab 15.4)
- Events
- [Wikis](../../project/wiki/group.md)
  ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/53247) in GitLab 13.9)
- Iterations cadences ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/95372) in 15.4)

Items that are **not** exported include:

- Projects
- Runner tokens
- SAML discovery tokens

### Preparation

- To preserve the member list and their respective permissions on imported groups, review the users in these groups. Make
sure these users exist before importing the desired groups.
- Users must set a public email in the source GitLab instance that matches one of their verified emails in the target GitLab instance.

### Enable export for a group

Prerequisite:

- You must have the Owner role for the group.

To enable import and export for a group:

1. On the top bar, select **Main menu > Admin**.
1. On the left sidebar, select **Settings > General**.
1. Expand **Visibility and access controls**.
1. In the **Import sources** section, select the checkboxes for the sources you want.

### Export a group

Prerequisites:

- You must have the Owner role for the group.

To export the contents of a group:

1. On the top bar, select **Main menu > Groups** and find your group.
1. On the left sidebar, select **Settings > General**.
1. In the **Advanced** section, select **Export Group**.
1. After the export is generated, you should receive an email with a link to the [exported contents](#exported-contents)
   in a compressed tar archive, with contents in NDJSON format.
1. Alternatively, you can download the export from the UI:

   1. Return to your group's **Settings > General** page.
   1. In the **Advanced** section, select **Download export**.
      You can also generate a new file by selecting **Regenerate export**.

You can also use the [group import/export API](../../../api/group_import_export.md).

### Import the group

1. Create a new group:
   - On the top bar, select **Create new…** (**{plus-square}**) and then **New group**.
   - On an existing group's page, select the **New subgroup** button.
1. Select **Import group**.
1. Enter your group name.
1. Accept or modify the associated group URL.
1. Select **Choose file**.
1. Select the file that you exported in the [Export a group](#export-a-group) section.
1. To begin importing, select **Import group**.

Your newly imported group page appears after the operation completes.

NOTE:
The maximum import file size can be set by the administrator, default is `0` (unlimited).
As an administrator, you can modify the maximum import file size. To do so, use the `max_import_size` option in the
[Application settings API](../../../api/settings.md#change-application-settings) or the
[Admin Area](../../admin_area/settings/account_and_limit_settings.md).
Default [modified](https://gitlab.com/gitlab-org/gitlab/-/issues/251106) from 50MB to 0 in GitLab 13.8.

### Rate limits

To help avoid abuse, by default, users are rate limited to:

| Request Type     | Limit                                    |
| ---------------- | ---------------------------------------- |
| Export           | 6 groups per minute                |
| Download export  | 1 download per group per minute  |
| Import           | 6 groups per minute                |

### Version history

#### 14.0+

In GitLab 14.0, the JSON format is no longer supported for project and group exports. To allow for a
transitional period, you can still import any JSON exports. The new format for imports and exports
is NDJSON.

#### 13.0+

GitLab can import bundles that were exported from a different GitLab deployment.
This ability is limited to two previous GitLab [minor](../../../policy/maintenance.md#versioning)
releases, which is similar to our process for [Security Releases](../../../policy/maintenance.md#security-releases).

For example:

| Current version | Can import bundles exported from |
|-----------------|----------------------------------|
| 13.0            | 13.0, 12.10, 12.9                |
| 13.1            | 13.1, 13.0, 12.10                |

## Automate group and project import **(PREMIUM)**

For information on automating user, group, and project import API calls, see
[Automate group and project import](../../project/import/index.md#automate-group-and-project-import).
