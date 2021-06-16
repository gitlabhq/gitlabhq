---
type: reference, howto
stage: Manage
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Import your project from Gitea to GitLab **(FREE)**

Import your projects from Gitea to GitLab with minimal effort.

NOTE:
This requires Gitea `v1.0.0` or newer.

The Gitea importer can import:

- Repository description (GitLab 8.15+)
- Git repository data (GitLab 8.15+)
- Issues (GitLab 8.15+)
- Pull requests (GitLab 8.15+)
- Milestones (GitLab 8.15+)
- Labels (GitLab 8.15+)

When importing, repository public access is retained. If a repository is private in Gitea, it's
created as private in GitLab as well.

## How it works

Since Gitea is currently not an OAuth provider, author/assignee cannot be mapped
to users in your GitLab instance. This means that the project creator (most of
the times the current user that started the import process) is set as the author,
but a reference on the issue about the original Gitea author is kept.

The importer creates any new namespaces (groups) if they don't exist or in
the case the namespace is taken, the repository is imported under the user's
namespace that started the import process.

## Import your Gitea repositories

The importer page is visible when you create a new project.

![New project page on GitLab](img/import_projects_from_new_project_page.png)

Click the **Gitea** link and the import authorization process starts.

![New Gitea project import](img/import_projects_from_gitea_new_import.png)

### Authorize access to your repositories using a personal access token

With this method, you perform a one-off authorization with Gitea to grant
GitLab access your repositories:

1. Go to `https://your-gitea-instance/user/settings/applications` (replace
   `your-gitea-instance` with the host of your Gitea instance).
1. Click **Generate New Token**.
1. Enter a token description.
1. Click **Generate Token**.
1. Copy the token hash.
1. Go back to GitLab and provide the token to the Gitea importer.
1. Hit the **List Your Gitea Repositories** button and wait while GitLab reads
   your repositories' information. Once done, you are taken to the importer
   page to select the repositories to import.

### Select which repositories to import

After you've authorized access to your Gitea repositories, you are
redirected to the Gitea importer page.

From there, you can see the import statuses of your Gitea repositories.

- Those that are being imported show a _started_ status,
- those already successfully imported are green with a _done_ status,
- whereas those that are not yet imported have an **Import** button on the
  right side of the table.

You also can:

- Import all your Gitea projects in one go by hitting **Import all projects** in
  the upper left corner.
- Filter projects by name. If filter is applied, hitting **Import all projects**
  only imports matched projects.

![Gitea importer page](img/import_projects_from_gitea_importer_v12_3.png)

You can also choose a different name for the project and a different namespace,
if you have the privileges to do so.
