---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Migrate from Gitea
description: "Migrate from Gitea to GitLab."
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/381902) in GitLab 15.8, GitLab no longer automatically creates namespaces or groups that don't exist. GitLab also no longer falls back to using the user's personal namespace if the namespace or group name is taken.
- Requirement for Maintainer role instead of Developer role introduced in GitLab 16.0 and backported to GitLab 15.11.1 and GitLab 15.10.5.
- Ability to import projects with a `.` in their path [added](https://gitlab.com/gitlab-org/gitlab/-/issues/434175) in GitLab 16.11.
- An **Imported** badge on some imported items [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/461208) in GitLab 17.2.
- [Changed on GitLab.com](https://gitlab.com/groups/gitlab-org/-/epics/14667) to [post-migration user contribution and membership mapping](mapping.md) in GitLab 17.8.
- Post-migration user and contribution membership mapping [enabled on GitLab.com and GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/176675) in GitLab 17.8.

{{< /history >}}

Import your projects from Gitea to GitLab.

The Gitea importer imports a subset of items from Gitea.

| Gitea item                    | Imported |
|:------------------------------|:---------|
| Repository description        | {{< yes >}} |
| Git repository data           | {{< yes >}} |
| Issues                        | {{< yes >}} |
| Pull requests                 | {{< yes >}} |
| Milestones                    | {{< yes >}} |
| Labels                        | {{< yes >}} |
| Diff notes from pull requests |          |

## Importer workflow

The Gitea importer supports post-migration mapping of user contributions for GitLab.com and GitLab Self-Managed. The
importer also supports an [alternative method](#alternative-method-of-mapping) of mapping.

When importing:

- Repository public access is retained. If a repository is private in Gitea, it's created as private in GitLab as well.
- Imported issues, merge requests, and comments have an **Imported** badge in GitLab.
- Because Gitea is not an OAuth provider, the author or assignee cannot be mapped to users on
  your GitLab instance. The project creator (usually the user who started the import process)
  is then set as the author. For issues, you can still see the original Gitea author.

## Prerequisites

- Gitea version 1.0.0 or later.
- You must enable the [Gitea import source](../../administration/settings/import_and_export_settings.md#configure-allowed-import-sources)
  or ask your GitLab administrator to enable it. Enabled by default on GitLab.com.
- the Maintainer or Owner role on the destination group to import to.

## Import your Gitea repositories

During the import, you create a personal access token and perform a one-off authorization with Gitea
to grant GitLab access your repositories.

To import your Gitea repositories:

1. In the upper-right corner, select **Create new** ({{< icon name="plus" >}}) and **New project/repository**.
1. To start the import authorization process, select **Gitea**.
1. Go to `https://your-gitea-instance/user/settings/applications`. Replace `your-gitea-instance` with the host of your
   Gitea instance.
1. Select **Generate New Token**.
1. Enter a token description.
1. Select **Generate Token**.
1. Copy the token hash.
1. Go back to GitLab and provide the token to the Gitea importer.
1. Select **List your Gitea repositories** and wait while GitLab reads your repositories' information. When complete,
   GitLab displays the importer page to select the repositories to import. From there, you can view the import statuses
   of your Gitea repositories:

   - Those that are being imported show a started status.
   - Those already successfully imported are green with a done status.
   - Those that aren't yet imported have **Import** on the right side of the table.
   - Those that are already imported have **Re-import** on the right side of the table.

1. To finish importing Gitea repositories, you can:

   - Import all of your Gitea projects at once. In the upper-left corner, select **Import all projects**.
   - Import only selected projects by filtering projects by name. If you apply a filter, **Import all projects** imports
     only selected projects.
   - Choose a different name for the project and a different namespace if you have the privileges to do so.

## Alternative method of mapping

In GitLab 18.5 and earlier, you can disable the `gitea_user_mapping` feature flag to use the alternative user
contribution mapping method for imports.

> [!flag]
> The availability of this feature is controlled by a feature flag. This feature is not recommended and is unavailable
> for:
>
> - Migrations to GitLab.com.
> - Migrations to GitLab Self-Managed and GitLab Dedicated 18.6 and later.
>
> Problems that are found in this mapping method are unlikely to be fixed. Use the
> [post-migration method](mapping.md) instead that doesn't have these limitations.
>
> For more information, see [issue 512211](https://gitlab.com/gitlab-org/gitlab/-/work_items/512211).

Using this method, user contributions are assigned to the project creator (usually the user who started the import
process) by default.

## Related topics

- [Import and export settings](../../administration/settings/import_and_export_settings.md).
- [Sidekiq configuration for imports](../../administration/sidekiq/configuration_for_imports.md).
- [Running multiple Sidekiq processes](../../administration/sidekiq/extra_sidekiq_processes.md).
- [Processing specific job classes](../../administration/sidekiq/processing_specific_job_classes.md).
