---
stage: Manage
group: Import
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments"
---

# Migrating projects using file exports **(FREE)**

Existing projects on any self-managed GitLab instance or GitLab.com can be exported to a file and
then imported into a new GitLab instance. You can also:

- [Migrate groups](../../group/import/index.md) using the preferred method.
- [Migrate groups using file exports](../../group/settings/import_export.md).

GitLab maps user contributions correctly when an admin access token is used to perform the import.

As a result, migrating projects using file exports does not map user contributions correctly when you are importing
projects from a self-managed instance to GitLab.com.

Instead, all GitLab user associations (such as comment author) are changed to the user importing the project. For more
information, see the prerequisites and important notes in these sections:

- [Export a project and its data](../settings/import_export.md#export-a-project-and-its-data).
- [Import the project](../settings/import_export.md#import-a-project-and-its-data).

To preserve contribution history, [migrate using direct transfer](../../group/import/index.md#migrate-groups-by-direct-transfer-recommended).

If you migrate from GitLab.com to self-managed GitLab, an administrator can create users on the self-managed GitLab instance.

## Configure file exports as an import source **(FREE SELF)**

Before you can migrate projects on a self-managed GitLab instance using file exports, GitLab administrators must:

1. [Enable file exports](../../admin_area/settings/visibility_and_access_controls.md#enable-project-export) on the source
   instance.
1. Enable file exports as an import source for the destination instance. On GitLab.com, file exports are already enabled
   as an import source.

To enable file exports as an import source for the destination instance:

1. On the top bar, select **Main menu > Admin**.
1. On the left sidebar, select **Settings > General**.
1. Expand **Visibility and access controls**.
1. Scroll to **Import sources**.
1. Select the **GitLab export** checkbox.

## Between CE and EE

You can export projects from the [Community Edition to the Enterprise Edition](https://about.gitlab.com/install/ce-or-ee/)
and vice versa. This assumes [version history](#version-history) requirements are met.

If you're exporting a project from the Enterprise Edition to the Community Edition, you may lose
data that is retained only in the Enterprise Edition. For more information, see
[downgrading from EE to CE](../../../index.md).

## Export a project and its data

Before you can import a project, you must export it.

Prerequisites:

- Review the list of [items that are exported](#items-that-are-exported). Not all items are exported.
- You must have at least the Maintainer role for the project.
- Users must [set a public email](../../profile/index.md#set-your-public-email) in the source GitLab instance that matches one of their verified emails in the target GitLab instance for the user mapping to work correctly.

To export a project and its data, follow these steps:

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Settings > General**.
1. Expand **Advanced**.
1. Select **Export project**.
1. After the export is generated, you should receive an email with a link to download the file.
1. Alternatively, you can come back to the project settings and download the file from there or
   generate a new export. After the file is available, the page should show the **Download export**
   button.

The export is generated in your configured `shared_path`, a temporary shared directory, and then
moved to your configured `uploads_directory`. Every 24 hours, a worker deletes these export files.

### Items that are exported

The [`import_export.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/import_export/project/import_export.yml)
file for projects lists many of the items exported and imported when migrating projects using file exports. View this file in the branch
for your version of GitLab to see the list of items relevant to you. For example,
[`import_export.yml` on the `14-10-stable-ee` branch](https://gitlab.com/gitlab-org/gitlab/-/blob/14-10-stable-ee/lib/gitlab/import_export/project/import_export.yml).

Migrating projects with file exports uses the same export and import mechanisms as creating projects from templates at the [group](../../group/custom_project_templates.md) and
[instance](../../admin_area/custom_project_templates.md) levels. Therefore, the list of exported items is the same.

Items that are exported include:

- Project and wiki repositories
- Project uploads
- Project configuration, excluding integrations
- Issues
  - Issue comments
  - Issue iteration ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/96184) in 15.4)
  - Issue resource state events ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/291983) in GitLab 15.4)
  - Issue resource milestone events ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/291983) in GitLab 15.4)
  - Issue resource iteration events ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/291983) in GitLab 15.4)
- Merge requests
  - Merge request diffs
  - Merge request comments
  - Merge request resource state events ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/291983) in GitLab 15.4)
  - Merge request multiple assignees ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/339520) in GitLab 15.3)
  - Merge request reviewers ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/339520) in GitLab 15.3)
  - Merge request approvers ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/339520) in GitLab 15.3)
- Labels
- Milestones
- Snippets
- Time tracking and other project entities
- Design Management files and data
- LFS objects
- Issue boards
- Pipelines history
- Push Rules
- Awards
- Group members are exported as project members, as long as the user has the Maintainer role in the
  exported project's group, or is an administrator

Items that are **not** exported include:

- [Child pipeline history](https://gitlab.com/gitlab-org/gitlab/-/issues/221088)
- Build traces and artifacts
- Package and container registry images
- CI/CD variables
- Pipeline triggers
- Webhooks
- Any encrypted tokens
- [Number of required approvals](https://gitlab.com/gitlab-org/gitlab/-/issues/221088)
- Repository size limits
- Deploy keys allowed to push to protected branches
- Secure Files

## Import a project and its data

> Default maximum import file size [changed](https://gitlab.com/gitlab-org/gitlab/-/issues/251106) from 50 MB to unlimited in GitLab 13.8.

WARNING:
Only import projects from sources you trust. If you import a project from an untrusted source, it
may be possible for an attacker to steal your sensitive data.

Prerequisites:

- You must have [exported the project and its data](#export-a-project-and-its-data).
- Compare GitLab versions and ensure you are importing to a GitLab version that is the same or later
  than the GitLab version you exported to.
- Review the [Version history](#version-history) for compatibility issues.
- At least the Maintainer role on the destination group to migrate to. Using the Developer role for this purpose was
  [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/387891) in GitLab 15.8 and will be removed in GitLab 16.0.

To import a project:

1. When [creating a new project](../index.md#create-a-project),
   select **Import project**.
1. In **Import project from**, select **GitLab export**.
1. Enter your project name and URL. Then select the file you exported previously.
1. Select **Import project** to begin importing. Your newly imported project page appears shortly.

To get the status of an import, you can query it through the [API](../../../api/project_import_export.md#import-status).
As described in the API documentation, the query may return an import error or exceptions.

### Changes to imported items

Exported items are imported with the following changes:

- Project members with the Owner role are imported with the Maintainer role.
- If an imported project contains merge requests originating from forks, new branches associated with these merge
  requests are created in the project. Therefore, the number of branches in the new project can be more than in the
  source project.
- If the `Internal` visibility level [is restricted](../../public_access.md#restrict-use-of-public-or-internal-projects),
  all imported projects are given `Private` visibility.

Deploy keys aren't imported. To use deploy keys, you must enable them in your imported project and update protected branches.

### Import large projects **(FREE SELF)**

If you have a larger project, consider using a Rake task as described in the [developer documentation](../../../development/import_project.md#importing-via-a-rake-task).

## Automate group and project import **(PREMIUM)**

For information on automating user, group, and project import API calls, see
[Automate group and project import](../import/index.md#automate-group-and-project-import).

## Maximum import file size

Administrators can set the maximum import file size one of two ways:

- With the `max_import_size` option in the [Application settings API](../../../api/settings.md#change-application-settings).
- In the [Admin Area UI](../../admin_area/settings/account_and_limit_settings.md#max-import-size).

The default is `0` (unlimited).

For the GitLab.com setting, see the [Account and limit settings](../../gitlab_com/index.md#account-and-limit-settings)
section of the GitLab.com settings page.

## Map users for import

Imported users can be mapped by their public email addresses on self-managed instances, if an administrator (not an owner) does the import.

- The project must be exported by a project or group member with the Owner role.
- Public email addresses are not set by default. Users must [set it in their profiles](../../profile/index.md#set-your-public-email)
  for mapping to work correctly.
- For contributions to be mapped correctly, users must be an existing member of the namespace,
  or they can be added as a member of the project. Otherwise, a supplementary comment is left to mention that the original
  author and the merge requests, notes, or issues that are owned by the importer.
- Imported users are set as [direct members](../members/index.md)
  in the imported project.

For project migration imports performed over GitLab.com groups, preserving author information is
possible through a [professional services engagement](https://about.gitlab.com/services/migration/).

## Rate limits

To help avoid abuse, by default, users are rate limited to:

| Request Type     | Limit |
| ---------------- | ----- |
| Export           | 6 projects per minute |
| Download export  | 1 download per group per minute |
| Import           | 6 projects per minute |

## Version history

### 15.8+

Starting with GitLab 15.8, importing groups from a JSON export is no longer supported. Groups must be imported
in NDJSON format.

### 14.0+

In GitLab 14.0, the JSON format is no longer supported for project and group exports. To allow for a
transitional period, you can still import any JSON exports. The new format for imports and exports
is NDJSON.

### 13.0+

Starting with GitLab 13.0, GitLab can import bundles that were exported from a different GitLab deployment.
**This ability is limited to two previous GitLab [minor](../../../policy/maintenance.md#versioning)
releases**, which is similar to our process for [Security Releases](../../../policy/maintenance.md#security-releases).

For example:

| Current version | Can import bundles exported from |
|-----------------|----------------------------------|
| 13.0            | 13.0, 12.10, 12.9                |
| 13.1            | 13.1, 13.0, 12.10                |

## Related topics

- [Project import and export API](../../../api/project_import_export.md)
- [Project import and export administration Rake tasks](../../../administration/raketasks/project_import_export.md)
- [Migrating GitLab groups](../../group/import/index.md)
- [Group import and export API](../../../api/group_import_export.md)
