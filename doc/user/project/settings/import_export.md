---
stage: Foundations
group: Import and Integrate
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments"
title: Migrate projects and groups by using file exports
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Migrating groups and projects by using [direct transfer](../../group/import/_index.md) is recommended. However, in some
situations, you might need to migrate groups and project by using file exports.

## Known issues

- Due to a known issue, you might encounter a
  `PG::QueryCanceled: ERROR: canceling statement due to statement timeout` error.
  For more information, see the
  [troubleshooting documentation](import_export_troubleshooting.md#error-pgquerycanceled-error-canceling-statement-due-to-statement-timeout).
- In GitLab 17.0, 17.1, and 17.2, imported epics and work items are mapped
  to the importing user rather than the original author.

## Migrate projects by uploading an export file

Existing projects can be exported to a file and
then imported into another GitLab instance.

### Preserving user contributions

The requirements for preserving user contribution depends on whether you're migrating to GitLab.com or to a GitLab
self-managed instance.

#### When migrating from GitLab Self-Managed to GitLab.com

When migrating projects by using file exports, an administrator's access token is required for user contributions to map correctly.

Therefore, user contributions never map correctly when importing file exports from a self-managed instance to GitLab.com.
Instead, all GitLab user associations (such as comment author) are changed to the user importing the project. To preserve
contribution history, do one of the following:

- [Migrate by using direct transfer](../../group/import/_index.md).
- Consider engaging Professional Services. For more information, see the
  [Professional Services Full Catalog](https://about.gitlab.com/services/catalog/).

#### When migrating to GitLab Self-Managed

To ensure GitLab maps users and their contributions correctly:

- The owner of the project's top-level group should export the project so that the information of all members (direct
  and inherited) with access to the project can be included in the exported file. Project maintainers and owners can
  initiate the project export. However, only direct members of a project are then exported.
- An administrator must perform the import.
- Required users must exist on the destination GitLab instance. An administrator can create confirmed users either in
  bulk in a Rails console or one by one in the UI.
- Users must [set a public email in their profiles](../../profile/_index.md#set-your-public-email) on the source GitLab
  instance that matches their primary email address on the destination GitLab instance. You can also manually add users'
  public emails by [editing project export files](#edit-project-export-files).

When the email of an existing user matches the email of an imported user, that user is added as a
[direct member](../members/_index.md) to the imported project.

If any of the previous conditions are not met, user contributions are not mapped correctly. Instead, all GitLab user
associations are changed to the user who performed the import. That user becomes an author of merge requests created by
other users. Supplementary comments mentioning original authors are:

- Added for comments, merge request approvals, linked tasks, and items.
- Not added for the merge request or issue creator, added or removed labels, and merged-by information.

### Edit project export files

You can add or remove data from export files. For example, you can:

- Manually add users public emails to the `project_members.ndjson` file.
- Trim CI pipelines by removing lines from the `ci_pipelines.ndjson` file.

To edit a project export file:

1. Extract the exported `.tar.gz` file.
1. Edit the appropriate file . For example, `tree/project/project_members.ndjson`.
1. Compress the files back to a `.tar.gz` file.

You can also make sure that all members were exported by checking the `project_members.ndjson` file.

### Compatibility

> - Support for JSON-formatted project file exports [removed](https://gitlab.com/gitlab-org/gitlab/-/issues/389888) in GitLab 15.11.

Project file exports are in NDJSON format.

You can import project file exports that were exported from a version of GitLab up to two
[minor](../../../policy/maintenance.md#versioning) versions behind.

For example:

| Destination version | Compatible source versions |
|:--------------------|:---------------------------|
| 13.0                | 13.0, 12.10, 12.9          |
| 13.1                | 13.1, 13.0, 12.10          |

### Configure file exports as an import source

DETAILS:
**Offering:** GitLab Self-Managed, GitLab Dedicated

Before you can migrate projects on GitLab Self-Managed using file exports, GitLab administrators must:

1. [Enable file exports](../../../administration/settings/import_and_export_settings.md#enable-project-export) on the source
   instance.
1. Enable file exports as an import source for the destination instance. On GitLab.com, file exports are already enabled
   as an import source.

To enable file exports as an import source for the destination instance:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > General**.
1. Expand **Import and export settings**.
1. Scroll to **Import sources**.
1. Select the **GitLab export** checkbox.

### Between CE and EE

You can export projects from the [Community Edition to the Enterprise Edition](https://about.gitlab.com/install/ce-or-ee/)
and vice versa, assuming [compatibility](#compatibility) is met.

If you're exporting a project from the Enterprise Edition to the Community Edition, you may lose
data that is retained only in the Enterprise Edition. For more information, see
[downgrading from EE to CE](../../../index.md).

### Export a project and its data

Before you can import a project, you must export it.

Prerequisites:

- Review the list of [items that are exported](#project-items-that-are-exported). Not all items are exported.
- You must have at least the Maintainer role for the project.

To export a project and its data, follow these steps:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > General**.
1. Expand **Advanced**.
1. Select **Export project**.
1. After the export is generated, you can:
   - Follow a link contained in an email that you should receive.
   - Refresh the project settings page and in the **Export project** area, select **Download export**.

The export is generated in your configured `shared_path`, a temporary shared directory, and then
moved to your configured `uploads_directory`. Every 24 hours, a worker deletes these export files.

#### Project items that are exported

Exported project items depend on the version of GitLab you use. To determine if a
specific project item is exported:

1. Check the [`exporters` array](https://gitlab.com/gitlab-org/gitlab/-/blob/b819a6aa6d53573980dd9ee4a1bfe597d69e88e5/app/services/projects/import_export/export_service.rb#L24).
1. Check the [`project/import_export.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/import_export/project/import_export.yml)
   file for projects for your GitLab version. For example, <https://gitlab.com/gitlab-org/gitlab/-/blob/16-8-stable-ee/lib/gitlab/import_export/project/import_export.yml> for GitLab 16.8.

For a quick overview, items that are exported include:

- Project and wiki repositories
- Project uploads
- Project configuration, excluding integrations
- Issues
  - Issue comments
  - Issue iterations ([introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/96184) in GitLab 15.4)
  - Issue resource state events ([introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/291983) in GitLab 15.4)
  - Issue resource milestone events ([introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/291983) in GitLab 15.4)
  - Issue resource iteration events ([introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/291983) in GitLab 15.4)
- Merge requests
  - Merge request diffs
  - Merge request comments
  - Merge request resource state events ([introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/291983) in GitLab 15.4)
  - Merge request multiple assignees ([introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/339520) in GitLab 15.3)
  - Merge request reviewers ([introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/339520) in GitLab 15.3)
  - Merge request approvers ([introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/339520) in GitLab 15.3)
- Commit comments ([introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/391601) in GitLab 15.10)
- Labels
- Milestones
- Snippets
- Releases
- Time tracking and other project entities
- Design management files and data
- LFS objects
- Issue boards
- CI/CD pipelines
- Pipeline schedules (inactive and assigned to the user who initiated the import)
- Protected branches and tags
- Push rules
- Emoji reactions
- Direct project members
  (if you have at least the Maintainer role for the exported project's group)
- Inherited project members as direct project members
  (if you have the Owner role for the exported project's group or administrator access to the instance)
- Some merge request approval rules:
  - [Approvals for protected branches](../merge_requests/approvals/rules.md#approvals-for-protected-branches)
  - [Eligible approvers](../merge_requests/approvals/rules.md#eligible-approvers)
- Vulnerability report ([introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/501466) in GitLab 17.7)

#### Project items that are not exported

Items that are **not** exported include:

- [Child pipeline history](https://gitlab.com/gitlab-org/gitlab/-/issues/221088)
- Pipeline triggers
- Build traces and artifacts
- Package and container registry images
- CI/CD variables
- Webhooks
- Any encrypted tokens
- [Number of required approvals](https://gitlab.com/gitlab-org/gitlab/-/issues/221087)
- Repository size limits
- Deploy keys allowed to push to protected branches
- Secure files
- [Activity logs for Git-related events](https://gitlab.com/gitlab-org/gitlab/-/issues/214700) (for example, pushing and creating tags)
- Security policies associated with your project
- Links between issues and linked items
- Links to related merge requests
- Pipeline schedule variables

Migrating projects with file exports uses the same export and import mechanisms as creating projects from templates at the [group](../../group/custom_project_templates.md) and
[instance](../../../administration/custom_project_templates.md) levels. Therefore, the list of exported items is the same.

### Import a project and its data

You can import a project and its data. The amount of data you can import depends on the maximum import file size:

- On GitLab Self-Managed, administrators can
  [set maximum import file size](#set-maximum-import-file-size).
- On GitLab.com, the value is [set to 5 GB](../../gitlab_com/_index.md#account-and-limit-settings).

WARNING:
Only import projects from sources you trust. If you import a project from an untrusted source, it
may be possible for an attacker to steal your sensitive data.

#### Prerequisites

> - Requirement for Maintainer role instead of Developer role introduced in GitLab 16.0 and backported to GitLab 15.11.1 and GitLab 15.10.5.

- You must have [exported the project and its data](#export-a-project-and-its-data).
- Compare GitLab versions and ensure you are importing to a GitLab version that is the same or later
  than the GitLab version you exported from.
- Review [compatibility](#compatibility) for any issues.
- At least the Maintainer role on the destination group to migrate to.

#### Import a project

To import a project:

1. On the left sidebar, at the top, select **Create new** (**{plus}**) and **New project/repository**.
1. Select **Import project**.
1. In **Import project from**, select **GitLab export**.
1. Enter your project name and URL. Then select the file you exported previously.
1. Select **Import project**.

You can query the status of an import by using the [API](../../../api/project_import_export.md#import-status).
The query might return an import error or exceptions.

#### Changes to imported items

Exported items are imported with the following changes:

- Project members with the Owner role are imported with the Maintainer role.
- If an imported project contains merge requests originating from forks, new branches associated with these merge
  requests are created in the project. Therefore, the number of branches in the new project can be more than in the
  source project.
- If the `Internal` visibility level [is restricted](../../public_access.md#restrict-use-of-public-or-internal-projects),
  all imported projects are given `Private` visibility.

Deploy keys aren't imported. To use deploy keys, you must enable them in your imported project and update protected branches.

#### Import large projects

DETAILS:
**Offering:** GitLab Self-Managed, GitLab Dedicated

If you have a larger project, consider [using a Rake task](../../../administration/raketasks/project_import_export.md#import-large-projects).

### Set maximum import file size

DETAILS:
**Offering:** GitLab Self-Managed, GitLab Dedicated

Administrators can set the maximum import file size one of two ways:

- With the `max_import_size` option in the [Application settings API](../../../api/settings.md#update-application-settings).
- In the [**Admin** area UI](../../../administration/settings/import_and_export_settings.md#max-import-size).

The default is `0` (unlimited).

### Rate limits

To help avoid abuse, by default, users are rate limited to:

| Request type    | Limit                           |
|:----------------|:--------------------------------|
| Export          | 6 projects per minute           |
| Download export | 1 download per group per minute |
| Import          | 6 projects per minute           |

## Migrate groups by uploading an export file (deprecated)

> - [Deprecated](https://gitlab.com/groups/gitlab-org/-/epics/4619) in GitLab 14.6.

WARNING:
This feature was [deprecated](https://gitlab.com/groups/gitlab-org/-/epics/4619) in GitLab 14.6 and replaced by
[migrating groups by direct transfer](../../group/import/_index.md). However, this feature is still recommended for migrating groups between
offline systems. To follow progress on an alternative solution for [offline environments](../../application_security/offline_deployments/_index.md), see
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

### Additional information

- Exports are stored in a temporary directory and are deleted every 24 hours by a specific worker.
- To preserve group-level relationships from imported projects, export and import groups first so that projects can
  be imported into the desired group structure.
- Imported groups are given a `private` visibility level, unless imported into a parent group.
- If imported into a parent group, a subgroup inherits the same level of visibility unless otherwise restricted.
- You can export groups from the [Community Edition to the Enterprise Edition](https://about.gitlab.com/install/ce-or-ee/)
  and vice versa. The Enterprise Edition retains some group data that isn't part of the Community Edition. If you're
  exporting a group from the Enterprise Edition to the Community Edition, you may lose this data. For more information,
  see [downgrading from EE to CE](../../../index.md).

The maximum import file size depends on whether you import to GitLab Self-Managed or GitLab.com:

- If importing to a GitLab Self-Managed instance, you can import a import file of any size. Administrators can change
  this behavior using either:
  - The `max_import_size` option in the [Application settings API](../../../api/settings.md#update-application-settings).
  - The [**Admin** area](../../../administration/settings/account_and_limit_settings.md).
- On GitLab.com, you can import groups using import files of no more than
  [5 GB](../../gitlab_com/_index.md#account-and-limit-settings) in size.

### Compatibility

> - Support for JSON-formatted project file exports [removed](https://gitlab.com/gitlab-org/gitlab/-/issues/383682) in GitLab 15.8.

Group file exports are in NDJSON format.

You can import group file exports that were exported from a version of GitLab up to two
[minor](../../../policy/maintenance.md#versioning) versions behind.

For example:

| Destination version | Compatible source versions |
|:--------------------|:---------------------------|
| 13.0                | 13.0, 12.10, 12.9          |
| 13.1                | 13.1, 13.0, 12.10          |

### Group items that are exported

The [`import_export.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/import_export/group/import_export.yml)
file for groups lists items exported and imported when migrating groups using file exports. View this file in the branch
for your version of GitLab to check which items can be imported to the destination GitLab instance. For example,
[`import_export.yml` on the `16-8-stable-ee` branch](https://gitlab.com/gitlab-org/gitlab/-/blob/16-8-stable-ee/lib/gitlab/import_export/group/import_export.yml).

Group items that are exported include:

- Milestones
- Group Labels (_without_ associated label priorities)
- Boards and Board Lists
- Badges
- Subgroups (including all the aforementioned data)
- Epics
  - Epic resource state events. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/291983) in GitLab 15.4.
- Events
- [Wikis](../wiki/group.md)
- Iterations cadences. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/95372) in GitLab 15.4.

### Group items that are not exported

Items that are **not** exported include:

- Projects
- Runner tokens
- SAML discovery tokens
- Uploads

### Preparation

- To preserve the member list and their respective permissions on imported groups, review the users in these groups. Make
  sure these users exist before importing the desired groups.
- Users must set a public email in the source GitLab instance that matches their confirmed primary email in the
  destination GitLab instance. Most users receive an email asking them to confirm their email address.

### Export a group

Prerequisites:

- You must have the Owner role for the group.

To export the contents of a group:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > General**.
1. In the **Advanced** section, select **Export group**.
1. After the export is generated, you can:
   - Follow a link contained in an email that you should receive.
   - Refresh the group settings page and in the **Export project** area, select **Download export**.

### Import the group

To import the group:

1. On the left sidebar, at the top, select **Create new** (**{plus}**) and **New group**.
1. Select **Import group**.
1. In the **Import group from file** section, enter a group name and accept or modify the associated group URL.
1. Select **Choose file**.
1. Select the GitLab export file you want to import.
1. To begin importing, select **Import**.

### Rate limits

To help avoid abuse, by default, users are rate limited to:

| Request Type    | Limit |
|-----------------|-------|
| Export          | 6 groups per minute |
| Download export | 1 download per group per minute |
| Import          | 6 groups per minute |

## Related topics

- [Project import and export API](../../../api/project_import_export.md)
- [Project import and export administration Rake tasks](../../../administration/raketasks/project_import_export.md)
- [Migrating GitLab groups](../../group/import/_index.md)
- [Group import and export API](../../../api/group_import_export.md)
- [Migrate groups by direct transfer](../../group/import/_index.md).
