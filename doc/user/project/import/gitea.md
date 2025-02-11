---
stage: Foundations
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Import your project from Gitea to GitLab
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/381902) in GitLab 15.8, GitLab no longer automatically creates namespaces or groups that don't exist. GitLab also no longer falls back to using the user's personal namespace if the namespace or group name is taken.
> - Ability to import projects with a `.` in their path [added](https://gitlab.com/gitlab-org/gitlab/-/issues/434175) in GitLab 16.11.
> - An **Imported** badge on some imported items [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/461208) in GitLab 17.2.

Import your projects from Gitea to GitLab.

The Gitea importer can import:

- Repository description
- Git repository data
- Issues
- Pull requests
- Milestones
- Labels

When importing:

- Repository public access is retained. If a repository is private in Gitea, it's created as private in GitLab as well.
- Imported issues, merge requests, and comments have an **Imported** badge in GitLab.

## Known issues

- Because Gitea is not an OAuth provider, the author or assignee cannot be mapped to users on
  your GitLab instance. The project creator (usually the user who started the import process)
  is then set as the author. For issues, you can still see the original Gitea author.
- The Gitea importer does not import diff notes from pull requests. See [this issue](https://gitlab.com/gitlab-org/gitlab/-/issues/450973) for more information.

## Prerequisites

> - Requirement for Maintainer role instead of Developer role introduced in GitLab 16.0 and backported to GitLab 15.11.1 and GitLab 15.10.5.

- Gitea version 1.0.0 or later.
- [Gitea import source](../../../administration/settings/import_and_export_settings.md#configure-allowed-import-sources)
  must be enabled. If not enabled, ask your GitLab administrator to enable it. The Gitea import source is enabled
  by default on GitLab.com.
- At least the Maintainer role on the destination group to import to.

## Import your Gitea repositories

The Gitea importer page is visible when you create a new project. To begin a Gitea import:

1. On the left sidebar, at the top, select **Create new** (**{plus}**) and **New project/repository**.
1. Select **Gitea** to start the import authorization process.

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
1. Select **List your Gitea repositories** and wait while GitLab reads
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
- Choose a different name for the project and a different namespace if you have the privileges to do so.

## User contribution and membership mapping

> - [Changed on GitLab.com](https://gitlab.com/groups/gitlab-org/-/epics/14667) to [user contribution and membership mapping](../import/_index.md#user-contribution-and-membership-mapping) in GitLab 17.8.
> - [Enabled on GitLab.com and GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/176675) in GitLab 17.8.

The Gitea importer uses an [improved method](../import/_index.md#user-contribution-and-membership-mapping)
of mapping user contributions for GitLab.com and GitLab Self-Managed.

### Old method of user contribution mapping

You can use the old user contribution mapping method for imports to GitLab Self-Managed and GitLab Dedicated instances.
To use this method, `importer_user_mapping` and `bulk_import_importer_user_mapping` must be disabled.
For imports to GitLab.com, you must
use the [improved method](../import/_index.md#user-contribution-and-membership-mapping) instead.

Using the old method, user contributions are assigned to the project creator (usually the user who started the import process) by default.
