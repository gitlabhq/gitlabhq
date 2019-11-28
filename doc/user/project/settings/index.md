# Project settings

NOTE: **Note:**
Only project Maintainers and Admin users have the [permissions] to access a project
settings.

You can adjust your [project](../index.md) settings by navigating
to your project's homepage and clicking **Settings**.

## General settings

Under a project's general settings, you can find everything concerning the
functionality of a project.

### General project settings

Adjust your project's name, description, avatar, [default branch](../repository/branches/index.md#default-branch), and topics:

![general project settings](img/general_settings.png)

The project description also partially supports [standard Markdown](../../markdown.md#standard-markdown-and-extensions-in-gitlab). You can use [emphasis](../../markdown.md#emphasis), [links](../../markdown.md#links), and [line-breaks](../../markdown.md#line-breaks) to add more context to the project description.

### Sharing and permissions

Set up your project's access, [visibility](../../../public_access/public_access.md), and enable [Container Registry](../../packages/container_registry/index.md) for your projects:

![projects sharing permissions](img/sharing_and_permissions_settings_v12_3.png)

If Issues are disabled, or you can't access Issues because you're not a project member, then Labels and Milestones
links will be missing from the sidebar UI.

You can still access them with direct links if you can access Merge Requests. This is deliberate, if you can see
Issues or Merge Requests, both of which use Labels and Milestones, then you shouldn't be denied access to Labels and Milestones pages.

Project [Snippets](../../snippets.md) are enabled by default.

#### Disabling email notifications

You can disable all email notifications related to the project by selecting the
**Disable email notifications** checkbox.  Only the project owner is allowed to change
this setting.

### Issue settings

Add an [issue description template](../description_templates.md#description-templates) to your project, so that every new issue will start with a custom template.

### Merge request settings

Set up your project's merge request settings:

- Set up the merge request method (merge commit, [fast-forward merge](../merge_requests/fast_forward_merge.html)).
- Add merge request [description templates](../description_templates.md#description-templates).
- Enable [merge request approvals](../merge_requests/merge_request_approvals.md). **(STARTER)**
- Enable [merge only if pipeline succeeds](../merge_requests/merge_when_pipeline_succeeds.md).
- Enable [merge only when all threads are resolved](../../discussions/index.md#only-allow-merge-requests-to-be-merged-if-all-threads-are-resolved).
- Enable [`delete source branch after merge` option by default](../merge_requests/creating_merge_requests.md#deleting-the-source-branch)

![project's merge request settings](img/merge_requests_settings.png)

### Service Desk **(PREMIUM)**

Enable [Service Desk](../service_desk.md) for your project to offer customer support.

### Export project

Learn how to [export a project](import_export.md#importing-the-project) in GitLab.

### Advanced settings

Here you can run housekeeping, archive, rename, transfer, or remove a project.

#### Archiving a project

NOTE: **Note:**
Only project Owners and Admin users have the [permissions] to archive a project.

Archiving a project makes it read-only for all users and indicates that it is
no longer actively maintained. Projects that have been archived can also be
unarchived.

When a project is archived, the repository, issues, merge requests and all
other features are read-only. Archived projects are also hidden
in project listings.

To archive a project:

1. Navigate to your project's **Settings > General > Advanced settings**.
1. In the Archive project section, click the **Archive project** button.
1. Confirm the action when asked to.

#### Renaming a repository

NOTE: **Note:**
Only project Maintainers and Admin users have the [permissions] to rename a
repository. Not to be confused with a project's name where it can also be
changed from the [general project settings](#general-project-settings).

A project's repository name defines its URL (the one you use to access the
project via a browser) and its place on the file disk where GitLab is installed.

To rename a repository:

1. Navigate to your project's **Settings > General > Advanced settings**.
1. Under "Rename repository", change the "Path" to your liking.
1. Hit **Rename project**.

Remember that this can have unintended side effects since everyone with the
old URL will not be able to push or pull. Read more about what happens with the
[redirects when renaming repositories](../index.md#redirects-when-changing-repository-paths).

#### Transferring an existing project into another namespace

NOTE: **Note:**
Only project Owners and Admin users have the [permissions] to transfer a project.

You can transfer an existing project into a [group](../../group/index.md) if:

1. You have at least **Maintainer** [permissions] to that group.
1. The project is in a subgroup you own.
1. You are at least a **Maintainer** of the project under your personal namespace.
   Similarly, if you are an owner of a group, you can transfer any of its projects
   under your own user.

To transfer a project:

1. Navigate to your project's **Settings > General > Advanced settings**.
1. Under "Transfer project", choose the namespace you want to transfer the
   project to.
1. Confirm the transfer by typing the project's path as instructed.

Once done, you will be taken to the new project's namespace. At this point,
read what happens with the
[redirects from the old project to the new one](../index.md#redirects-when-changing-repository-paths).

NOTE: **Note:**
GitLab administrators can use the admin interface to move any project to any
namespace if needed.

[permissions]: ../../permissions.md#project-members-permissions

## Operations settings

### Error Tracking

Configure Error Tracking to discover and view [Sentry errors within GitLab](../operations/error_tracking.md).

### Jaeger tracing **(ULTIMATE)**

Add the URL of a Jaeger server to allow your users to [easily access the Jaeger UI from within GitLab](../operations/tracing.md).
