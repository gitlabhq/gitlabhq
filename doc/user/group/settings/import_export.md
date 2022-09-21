---
stage: Manage
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Migrating groups using file exports (deprecated) **(FREE)**

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/2888) in GitLab 13.0 as an experimental feature. May change in future releases.
> - [Deprecated](https://gitlab.com/groups/gitlab-org/-/epics/4619) in GitLab 14.6.

WARNING:
This feature was [deprecated](https://gitlab.com/groups/gitlab-org/-/epics/4619) in GitLab 14.6 and replaced by
[a different migration method](../import/index.md). To follow progress on a solution for
[offline environments](../../application_security/offline_deployments/index.md), see
[the relevant issue](https://gitlab.com/gitlab-org/gitlab/-/issues/363406).

You can export groups, with all their related data, from one GitLab instance to another. You can also:

- [Migrate groups](../import/index.md) using the preferred method.
- [Migrate projects using file exports](../../project/settings/import_export.md).

## Enable export for a group

Prerequisite:

- You must have the Owner role for the group.

To enable import and export for a group:

1. On the top bar, select **Main menu > Admin**.
1. On the left sidebar, select **Settings > General**.
1. Expand **Visibility and access controls**.
1. In the **Import sources** section, select the checkboxes for the sources you want.

## Important Notes

Note the following:

- Exports are stored in a temporary directory and are deleted every 24 hours by a specific worker.
- To preserve group-level relationships from imported projects, run the Group Import/Export first, to allow projects to
be imported into the desired group structure.
- Imported groups are given a `private` visibility level, unless imported into a parent group.
- If imported into a parent group, a subgroup inherits the same level of visibility unless otherwise restricted.
- To preserve the member list and their respective permissions on imported groups, review the users in these groups. Make
sure these users exist before importing the desired groups.
- Users must set a public email in the source GitLab instance that matches one of their verified emails in the target GitLab instance.

### Exported contents

The [`import_export.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/import_export/group/import_export.yml)
file for groups lists many of the items exported and imported when migrating groups using file exports. View this file in the branch
for your version of GitLab to see the list of items relevant to you. For example,
[`import_export.yml` on the `14-10-stable-ee` branch](https://gitlab.com/gitlab-org/gitlab/-/blob/14-10-stable-ee/lib/gitlab/import_export/group/import_export.yml).

Migrating projects with file exports uses the same export and import mechanisms as creating projects from templates at the [group](../custom_project_templates.md) and
[instance](../../admin_area/custom_project_templates.md) levels. Therefore, the list of exported items is the same.

Items that are exported include:

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

NOTE:
For more details on the specific data persisted in a group export, see the
[`import_export.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/import_export/group/import_export.yml) file.

## Export a group

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

NOTE:
The maximum import file size can be set by the Administrator, default is `0` (unlimited).
As an administrator, you can modify the maximum import file size. To do so, use the `max_import_size` option in the [Application settings API](../../../api/settings.md#change-application-settings) or the [Admin Area](../../admin_area/settings/account_and_limit_settings.md). Default [modified](https://gitlab.com/gitlab-org/gitlab/-/issues/251106) from 50MB to 0 in GitLab 13.8.

You can also use the [group import/export API](../../../api/group_import_export.md).

### Between CE and EE

You can export groups from the [Community Edition to the Enterprise Edition](https://about.gitlab.com/install/ce-or-ee/) and vice versa.

The Enterprise Edition retains some group data that isn't part of the Community Edition. If you're exporting a group from the Enterprise Edition to the Community Edition, you may lose this data. For more information, see [downgrading from EE to CE](../../../index.md).

## Import the group

1. Create a new group:
   - On the top bar, select **New** (**{plus}**) and then **New group**.
   - On an existing group's page, select the **New subgroup** button.
1. Select **Import group**.
1. Enter your group name.
1. Accept or modify the associated group URL.
1. Select **Choose file**.
1. Select the file that you exported in the [Export a group](#export-a-group) section.
1. To begin importing, select **Import group**.

Your newly imported group page appears after the operation completes.

## Automate group and project import **(PREMIUM)**

For information on automating user, group, and project import API calls, see
[Automate group and project import](../../project/import/index.md#automate-group-and-project-import).

## Version history

### 14.0+

In GitLab 14.0, the JSON format is no longer supported for project and group exports. To allow for a
transitional period, you can still import any JSON exports. The new format for imports and exports
is NDJSON.

### 13.0+

GitLab can import bundles that were exported from a different GitLab deployment.
This ability is limited to two previous GitLab [minor](../../../policy/maintenance.md#versioning)
releases, which is similar to our process for [Security Releases](../../../policy/maintenance.md#security-releases).

For example:

| Current version | Can import bundles exported from |
|-----------------|----------------------------------|
| 13.0            | 13.0, 12.10, 12.9                |
| 13.1            | 13.1, 13.0, 12.10                |

## Rate Limits

To help avoid abuse, by default, users are rate limited to:

| Request Type     | Limit                                    |
| ---------------- | ---------------------------------------- |
| Export           | 6 groups per minute                |
| Download export  | 1 download per group per minute  |
| Import           | 6 groups per minute                |

GitLab.com may have [different settings](../../gitlab_com/index.md#importexport) from the defaults.
