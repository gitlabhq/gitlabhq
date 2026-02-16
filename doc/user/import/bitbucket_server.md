---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Migrate from Bitbucket Server
description: "Migrate from Bitbucket Server to GitLab."
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- User mapping by email address or username [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/36885) in GitLab 13.4 [with a flag](../../administration/feature_flags/_index.md) named `bitbucket_server_user_mapping_by_username`. Disabled by default.
- Requirement for Maintainer role instead of Developer role introduced in GitLab 16.0 and backported to GitLab 15.11.1 and GitLab 15.10.5.
- Ability to re-import projects [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/23905) in GitLab 15.9.
- Ability to import reviewers [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/416611) in GitLab 16.3.
- Support for pull request approval imports [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/135256) in GitLab 16.7.
- Mapping user mentions to GitLab users [added](https://gitlab.com/gitlab-org/gitlab/-/issues/433008) in GitLab 16.8.
- [Changed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/153041) to map users only by email address in GitLab 17.1.
- An **Imported** badge on some imported items [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/461211) in GitLab 17.2.
- [Changed on GitLab.com](https://gitlab.com/groups/gitlab-org/-/epics/14667) to [post-migration user contribution and membership mapping](mapping.md) in GitLab 17.8.
- Post-migration user and contribution membership mapping [enabled on GitLab.com and GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/176675) in GitLab 17.8.

{{< /history >}}

Import your projects from Bitbucket Server to GitLab.

The Bitbucket Server importer imports a subset of items from Bitbucket Server.

| Bitbucket Server item                                                         | Imported |
|:------------------------------------------------------------------------------|:---------|
| Repository description                                                        | {{< yes >}} |
| Git repository data                                                           | {{< yes >}} |
| Pull requests, including comments, user mentions, reviewers, and merge events | {{< yes >}} |
| LFS objects                                                                   | {{< yes >}} |
| Comments on code<sup>1</sup>                                                  | {{< yes >}} |
| Threads<sup>2</sup>                                                           | {{< yes >}} |
| Project filters<sup>3</sup>                                                   | {{< yes >}} |
| Attachments in Markdown                                                       | {{< no >}} |
| Task lists                                                                    | {{< no >}} |
| Emoji reactions                                                               | {{< no >}} |
| Pull request approvals                                                        | {{< no >}} |
| Approval rules for pull requests                                              | {{< no >}} |

Footnotes:

1. GitLab doesn't allow comments on arbitrary lines of code. Any out-of-bounds Bitbucket comments are inserted as
   comments in the merge request.
1. Multiple threading levels are collapsed into one thread and quotes are added as part of the original comment.
1. Project filtering doesn't support fuzzy search. Only **starts with** or **full match** strings are supported.

## Importer workflow

The Bitbucket Server importer supports [post-migration mapping](mapping.md) of user contributions for GitLab.com and
GitLab Self-Managed. The importer also supports an [alternative method](#alternative-method-of-mapping) of mapping.

When Bitbucket Server items are imported:

- Repository public access is retained. If a repository is private in Bitbucket, it's created as private in GitLab.
- Imported merge requests and comments have an **Imported** badge in GitLab.

When closed or merged pull requests are imported, commit SHAs that do not exist in the repository are fetched from
Bitbucket Server to make sure pull requests have commits tied to them:

- Source commit SHAs are saved with references in the format `refs/merge-requests/<iid>/head`.
- Target commit SHAs are saved with references in the format `refs/keep-around/<SHA>`.

If the source commit does not exist in the repository, a commit containing the SHA in the commit message is used instead.

## Estimating import duration

Every import from Bitbucket Server is different, which affects the duration of imports you perform.
However, to help estimate the duration of your import, a project comprised of the following data is likely to take 8 hours to import:

- 13,000 pull requests
- 7,000 tags
- 500 GiB repository

## Prerequisites

- Bitbucket Server must be accessible from the GitLab instance. The Bitbucket Server URL must be
  publicly resolvable or accessible on the network where GitLab is running.
- You must enable the [Bitbucket Server import source](../../administration/settings/import_and_export_settings.md#configure-allowed-import-sources)
  or ask your GitLab administrator to enable it. Enabled by default on GitLab.com.
- the Maintainer or Owner role on the destination group to import to.
- Bitbucket Server authentication token with administrator access. Without administrator access, some data is
  [not imported](https://gitlab.com/gitlab-org/gitlab/-/issues/446218).

## Import your Bitbucket Server repositories

To import your Bitbucket Server repositories:

1. Sign in to GitLab.
1. In the upper-right corner, select **Create new** ({{< icon name="plus" >}}) and **New project/repository**.
1. Select **Import project**.
1. Select **Bitbucket Server**.
1. Sign in to Bitbucket and grant GitLab access to your Bitbucket account.
1. Select the projects to import, or import all projects. You can filter projects by name and select
   the namespace for which to import each project.
1. To import a project:
   - For the first time, select **Import**.
   - Subsequent times, select **Re-import**. Specify a new name and select **Re-import** again. Re-importing creates a
     new copy of the source project.

## Alternative method of mapping

You can disable the `bitbucket_server_user_mapping` feature flag to use the alternative user contribution mapping method
for imports.

For imports to GitLab.com, you must use the [post-migration method](mapping.md) instead.

> [!flag]
> The availability of this feature is controlled by a feature flag. This feature is not recommended and is unavailable for
> migrations to GitLab.com. Problems that are found in this mapping method are unlikely to be fixed. Use the
> [post-migration method](mapping.md) instead that doesn't have these limitations.
> 
> For more information, see [issue 512213](https://gitlab.com/gitlab-org/gitlab/-/work_items/512213).

Using the alternative method, the importer tries to match a Bitbucket Server user's email address with a confirmed email address
in the GitLab user database. If no such user is found:

- The project creator is used instead. The importer appends a note in the comment to mark the original creator.
- For pull request reviewers, no reviewer is assigned.
- For pull request approvers, no approval is added.

Mentions on pull request descriptions and notes are matched to user profiles on a Bitbucket Server by using the user's email address.
If a user with the same email address is not found on GitLab, the mention is made static.
For a user to be matched, they must have a GitLab role that provides at least read access to the project.

If the project is public, GitLab only matches users who are invited to the project.

The importer creates any new namespaces (groups) if they don't exist. If the namespace is taken, the
repository imports under the namespace of the user who started the import process.

## Troubleshooting

The following sections contain solutions for problems you might encounter.

### General

If the GUI-based import tool does not work, you can try to:

- Use the [GitLab Import API](../../api/import.md#import-repository-from-bitbucket-server)
  Bitbucket Server endpoint.
- Set up [repository mirroring](../project/repository/mirror/_index.md).
  It provides verbose error output.

See the [troubleshooting section](bitbucket_cloud.md#troubleshooting)
for Bitbucket Cloud.

### LFS objects not imported

If the project import completes but LFS objects can't be downloaded or cloned, you may be using a
password or personal access token containing special characters. For more information, see
[this issue](https://gitlab.com/gitlab-org/gitlab/-/issues/337769).

### Import fails due to invalid/unresolved host address, or the import URL is blocked

If a project import fails with an error message such as `Importing the project failed: Import URL is blocked`, even though the initial connection to the Bitbucket
server succeeded, the Bitbucket server or a reverse proxy might not be configured correctly.

To troubleshoot this problem, use the [Projects API](../../api/projects.md) to check for the newly-created project and locate the `import_url` value of the project.

This value indicates the URL provided by the Bitbucket server to use for the import. If this URL isn't publicly resolvable, you can get unresolvable address errors.

To fix this problem, ensure that the Bitbucket server is aware of any proxy servers because proxy servers can impact how Bitbucket constructs and uses URLs.
For more information, see [Proxy and secure Bitbucket](https://confluence.atlassian.com/bitbucketserver/proxy-and-secure-bitbucket-776640099.html).

## Related topics

- [Migrate from Bitbucket Cloud](bitbucket_cloud.md).
- [Import and export settings](../../administration/settings/import_and_export_settings.md).
- [Sidekiq configuration for imports](../../administration/sidekiq/configuration_for_imports.md).
- [Running multiple Sidekiq processes](../../administration/sidekiq/extra_sidekiq_processes.md).
- [Processing specific job classes](../../administration/sidekiq/processing_specific_job_classes.md).
