---
stage: Manage
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Import your project from Gitea to GitLab **(FREE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/381902) in GitLab 15.8, GitLab no longer automatically creates namespaces or groups that don't exist. GitLab also no longer falls back to using the user's personal namespace if the namespace or group name is taken.

Import your projects from Gitea to GitLab.

The Gitea importer can import:

- Repository description
- Git repository data
- Issues
- Pull requests
- Milestones
- Labels

When importing, repository public access is retained. If a repository is private in Gitea, it's
created as private in GitLab as well.

Because Gitea isn't an OAuth provider, author/assignee can't be mapped to users
in your GitLab instance. This means the project creator (usually the user that
started the import process) is set as the author. A reference, however, is kept
on the issue about the original Gitea author.

## Prerequisites

> Requirement for Maintainer role instead of Developer role introduced in GitLab 16.0 and backported to GitLab 15.11.1 and GitLab 15.10.5.

- Gitea version 1.0.0 or later.
- [Gitea import source](../../admin_area/settings/visibility_and_access_controls.md#configure-allowed-import-sources)
  must be enabled. If not enabled, ask your GitLab administrator to enable it. The Gitea import source is enabled
  by default on GitLab.com.
- At least the Maintainer role on the destination group to import to. Using the Developer role for this purpose was
  [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/387891) in GitLab 15.8 and will be removed in GitLab 16.0.

## Import your Gitea repositories

The importer page is visible when you create a new project.

Select the **Gitea** link to start the import authorization process.

![New Gitea project import](img/import_projects_from_gitea_new_import.png)

### Authorize access to your repositories using a personal access token

With this method, you perform a one-off authorization with Gitea to grant
GitLab access your repositories:

1. Go to `https://your-gitea-instance/user/settings/applications` (replace
   `your-gitea-instance` with the host of your Gitea instance).
1. Select **Generate New Token**.
1. Enter a token description.
1. Select **Generate Token**.
1. Copy the token hash.
1. Go back to GitLab and provide the token to the Gitea importer.
1. Select **List Your Gitea Repositories** and wait while GitLab reads
   your repositories' information. After it's done, GitLab displays the importer
   page to select the repositories to import.

### Select which repositories to import

After you've authorized access to your Gitea repositories, you are
redirected to the Gitea importer page.

From there, you can view the import statuses of your Gitea repositories:

- Those that are being imported show a _started_ status.
- Those already successfully imported are green with a _done_ status.
- Those that aren't yet imported have **Import** on the right side of the table.
- Those that are already imported have **Re-import** on the right side of the table.

You also can:

- In the upper-left corner, select **Import all projects** to import all of your Gitea projects at once.
- Filter projects by name. If a filter is applied, **Import all projects**
  imports only selected projects.

![Gitea importer page](img/import_projects_from_gitea_importer_v12_3.png)

You can also choose a different name for the project and a different namespace,
if you have the privileges to do so.
