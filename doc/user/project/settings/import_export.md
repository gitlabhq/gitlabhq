# Project import/export

> - [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/issues/3050) in GitLab 8.9.
> - From GitLab 10.0, administrators can disable the project export option on the GitLab instance.

Existing projects running on any GitLab instance or GitLab.com can be exported with all their related
data and be moved into a new GitLab instance.

The **GitLab import/export** button is displayed if the project import option is enabled.

See also:

- [Project import/export API](../../../api/project_import_export.md)
- [Project import/export administration rake tasks](../../../administration/raketasks/project_import_export.md) **(CORE ONLY)**

To set up a project import/export:

  1. Navigate to **{admin}** **Admin Area >** **{settings}** **Settings > Visibility and access controls**.
  1. Scroll to **Import sources**
  1. Enable desired **Import sources**

## Important notes

Note the following:

- Imports will fail unless the import and export GitLab instances are
  compatible as described in the [Version history](#version-history).
- Exports are stored in a temporary [shared directory](../../../development/shared_files.md)
  and are deleted every 24 hours by a specific worker.
- Group members are exported as project members, as long as the user has
  maintainer or admin access to the group where the exported project lives. Import admins should map users by email address.
  Otherwise, a supplementary comment is left to mention that the original author and
  the MRs, notes, or issues will be owned by the importer.
- Project members with owner access will be imported as maintainers.
- If an imported project contains merge requests originating from forks,
  then new branches associated with such merge requests will be created
  within a project during the import/export. Thus, the number of branches
  in the exported project could be bigger than in the original project.

## Version history

The following table lists updates to Import/Export:

| GitLab version   | Import/Export schema version |
| ---------------- | --------------------- |
| 11.1 to current  | 0.2.4                 |
| 10.8             | 0.2.3                 |
| 10.4             | 0.2.2                 |
| 10.3             | 0.2.1                 |
| 10.0             | 0.2.0                 |
| 9.4.0            | 0.1.8                 |
| 9.2.0            | 0.1.7                 |
| 8.17.0           | 0.1.6                 |
| 8.13.0           | 0.1.5                 |
| 8.12.0           | 0.1.4                 |
| 8.10.3           | 0.1.3                 |
| 8.10.0           | 0.1.2                 |
| 8.9.5            | 0.1.1                 |
| 8.9.0            | 0.1.0                 |

Projects can be exported and imported only between versions of GitLab with matching Import/Export versions.

For example, 8.10.3 and 8.11 have the same Import/Export version (0.1.3)
and the exports between them will be compatible.

## Exported contents

The following items will be exported:

- Project and wiki repositories
- Project uploads
- Project configuration, including services
- Issues with comments, merge requests with diffs and comments, labels, milestones, snippets,
  and other project entities
- Design Management files and data **(PREMIUM)**
- LFS objects
- Issue boards

The following items will NOT be exported:

- Build traces and artifacts
- Container registry images
- CI variables
- Webhooks
- Any encrypted tokens
- Merge Request Approvers
- Push Rules
- Awards

NOTE: **Note:**
For more details on the specific data persisted in a project export, see the
[`import_export.yml`](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/import_export/import_export.yml) file.

## Exporting a project and its data

1. Go to your project's homepage.

1. Click **{settings}** **Settings** in the sidebar.

1. Scroll down to find the **Export project** button:

   ![Export button](img/import_export_export_button.png)

1. Once the export is generated, you should receive an e-mail with a link to
   download the file:

   ![Email download link](img/import_export_mail_link.png)

1. Alternatively, you can come back to the project settings and download the
   file from there, or generate a new export. Once the file is available, the page
   should show the **Download export** button:

   ![Download export](img/import_export_download_export.png)

## Importing the project

1. The GitLab project import feature is the first import option when creating a
   new project. Click on **GitLab export**:

   ![New project](img/import_export_new_project.png)

1. Enter your project name and URL. Then select the file you exported previously:

   ![Select file](img/import_export_select_file.png)

1. Click on **Import project** to begin importing. Your newly imported project
   page will appear soon.

NOTE: **Note:**
If use of the `Internal` visibility level
[is restricted](../../../public_access/public_access.md#restricting-the-use-of-public-or-internal-projects),
all imported projects are given the visibility of `Private`.

## Rate limits

To help avoid abuse, users are rate limited to:

| Request Type     | Limit                       |
| ---------------- | --------------------------- |
| Export           | 1 project per 5 minutes     |
| Download export  | 10 projects per 10 minutes  |
| Import           | 30 projects per 10 minutes  |
