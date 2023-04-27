---
stage: Manage
group: Import and Integrate
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments"
---

# Migrating projects using file exports **(FREE)**

Existing projects on any self-managed GitLab instance or GitLab.com can be exported to a file and
then imported into another GitLab instance. You can also copy GitLab projects to another location with more automation by
[migrating groups by direct transfer](../../group/import/index.md#migrate-groups-by-direct-transfer-recommended).

## Preserving user contributions

Preserving user contribution depends on meeting the following requirements:

### Migrating from GitLab self-managed to GitLab.com

When migrating projects by using file exports, an administrator's access token is required for user contributions to map correctly.

Therefore, user contributions never map correctly when importing file exports from a self-managed instance to GitLab.com. Instead, all GitLab user associations (such as
comment author) are changed to the user importing the project. To preserve contribution history, do one of the following:

- [Migrate by direct transfer](../../group/import/index.md#migrate-groups-by-direct-transfer-recommended).
- Consider paid GitLab [migration services](https://about.gitlab.com/services/migration/).

### Migrating to GitLab self-managed

To ensure GitLab maps users and their contributions correctly:

- The owner of the project's top-level group should export the project so that the information of all members (direct and inherited) with access to the project can be included in the exported file. Project maintainers and owners can initiate the project export. However, only direct members of a project are then exported.
- An administrator must perform the import with an administrator access token.
- Required users must exist on the destination GitLab instance. An administrator can create confirmed users either in bulk in a Rails console or one by one in the UI.
- Users must [set a public email in their profiles](../../profile/index.md#set-your-public-email) on the source GitLab instance that matches their primary email
  address on the destination GitLab instance. You can also manually add users' public emails by
  [editing project export files](#edit-project-export-files).

When the email of an existing user matches the email of an imported user, that user is added as a [direct member](../members/index.md) to the imported project.

If any of the previous conditions are not met, user contributions are not mapped correctly. Instead, all GitLab user associations are changed to the user who performed the import.
That user becomes an author of merge requests created by other users. Supplementary comments mentioning original authors are:

- Added for comments, merge request approvals, linked tasks, and items.
- Not added for the merge request or issue creator, added or removed labels, and merged-by information.

## Edit project export files

You can add or remove data from export files. For example, you can:

- Manually add users public emails to the `project_members.ndjson` file.
- Trim CI pipelines by removing lines from the `ci_pipelines.ndjson` file.

To edit a project export file:

1. Extract the exported `.tar.gz` file.
1. Edit the appropriate file . For example, `tree/project/project_members.ndjson`.
1. Compress the files back to a `.tar.gz` file.

You can also make sure that all members were exported by checking the `project_members.ndjson` file.

## Compatibility

> Support for JSON-formatted project file exports [removed](https://gitlab.com/gitlab-org/gitlab/-/issues/389888) in GitLab 15.11.

Project file exports are in NDJSON format.

You can import project file exports that were exported from a version of GitLab up to two
[minor](../../../policy/maintenance.md#versioning) versions behind, which is similar to our process for
[security releases](../../../policy/maintenance.md#security-releases).

For example:

| Destination version | Compatible source versions |
|:--------------------|:---------------------------|
| 13.0                | 13.0, 12.10, 12.9          |
| 13.1                | 13.1, 13.0, 12.10          |

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
and vice versa, assuming [compatibility](#compatibility) is met.

If you're exporting a project from the Enterprise Edition to the Community Edition, you may lose
data that is retained only in the Enterprise Edition. For more information, see
[downgrading from EE to CE](../../../index.md).

## Export a project and its data

Before you can import a project, you must export it.

Prerequisites:

- Review the list of [items that are exported](#items-that-are-exported). Not all items are exported.
- You must have at least the Maintainer role for the project.

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

Exported project items depend on the version of GitLab you use. To determine if a
specific project item is exported:

1. Check the [`exporters` array](https://gitlab.com/gitlab-org/gitlab/blob/0a60d6dcfa7b809cf4fe0c2e239f406014d92e34/app/services/projects/import_export/export_service.rb#L25-28).
1. Check the [`project/import_export.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/import_export/project/import_export.yml) file for projects for your GitLab version (for example, `<https://gitlab.com/gitlab-org/gitlab/-/blob/15-9-stable-ee/lib/gitlab/import_export/project/import_export.yml>` for GitLab 15.9).

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
- Time tracking and other project entities
- Design management files and data
- LFS objects
- Issue boards
- Pipelines history
- Push rules
- Awards
- Group members as long as the user has the Maintainer role in the
  exported project's group or is an administrator

### Items that are not exported

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

Migrating projects with file exports uses the same export and import mechanisms as creating projects from templates at the [group](../../group/custom_project_templates.md) and
[instance](../../admin_area/custom_project_templates.md) levels. Therefore, the list of exported items is the same.

## Import a project and its data

> Default maximum import file size [changed](https://gitlab.com/gitlab-org/gitlab/-/issues/251106) from 50 MB to unlimited in GitLab 13.8. Administrators of self-managed instances can [set maximum import file size](#set-maximum-import-file-size). On GitLab.com, the value is [set to 5 GB](../../gitlab_com/index.md#account-and-limit-settings).

WARNING:
Only import projects from sources you trust. If you import a project from an untrusted source, it
may be possible for an attacker to steal your sensitive data.

Prerequisites:

- You must have [exported the project and its data](#export-a-project-and-its-data).
- Compare GitLab versions and ensure you are importing to a GitLab version that is the same or later
  than the GitLab version you exported to.
- Review [compatibility](#compatibility) for any issues.
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

If you have a larger project, consider [using a Rake task](../../../administration/raketasks/project_import_export.md#import-large-projects).

## Set maximum import file size **(FREE SELF)**

Administrators can set the maximum import file size one of two ways:

- With the `max_import_size` option in the [Application settings API](../../../api/settings.md#change-application-settings).
- In the [Admin Area UI](../../admin_area/settings/account_and_limit_settings.md#max-import-size).

The default is `0` (unlimited).

## Rate limits

To help avoid abuse, by default, users are rate limited to:

| Request type    | Limit                           |
|:----------------|:--------------------------------|
| Export          | 6 projects per minute           |
| Download export | 1 download per group per minute |
| Import          | 6 projects per minute           |

## Related topics

- [Project import and export API](../../../api/project_import_export.md)
- [Project import and export administration Rake tasks](../../../administration/raketasks/project_import_export.md)
- [Migrating GitLab groups](../../group/import/index.md)
- [Group import and export API](../../../api/group_import_export.md)
- [Migrate groups by direct transfer](../../group/import/index.md#migrate-groups-by-direct-transfer-recommended).
- [Migrate groups by using file exports](../../group/import/index.md#migrate-groups-by-uploading-an-export-file-deprecated).
