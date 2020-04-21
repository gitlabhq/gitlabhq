# Project settings

NOTE: **Note:**
Only project Maintainers and Admin users have the [permissions](../../permissions.md#project-members-permissions)
to access a project settings.

You can adjust your [project](../index.md) settings by navigating
to your project's homepage and clicking **Settings**.

## General settings

Under a project's general settings, you can find everything concerning the
functionality of a project.

### General project settings

Adjust your project's name, description, avatar, [default branch](../repository/branches/index.md#default-branch), and topics:

![general project settings](img/general_settings.png)

The project description also partially supports [standard Markdown](../../markdown.md#standard-markdown-and-extensions-in-gitlab). You can use [emphasis](../../markdown.md#emphasis), [links](../../markdown.md#links), and [line-breaks](../../markdown.md#line-breaks) to add more context to the project description.

#### Compliance framework **(ULTIMATE)**

You can select a framework label to identify that your project has certain compliance requirements or needs additional oversight. Available labels include:

- GDPR - General Data Protection Regulation
- HIPAA - Health Insurance Portability and Accountability Act
- PCI-DSS - Payment Card Industry-Data Security Standard
- SOC 2 - Service Organization Control 2
- SOX - Sarbanes-Oxley

### Sharing and permissions

For your repository, you can set up features such as public access, repository features,
documentation, access permissions, and more. To do so from your project,
go to **Settings** > **General**, and expand the **Visibility, project features, permissions**
section.

You can now change the [Project visibility](../../../public_access/public_access.md).
If you set **Project Visibility** to public, you can limit access to some features
to **Only Project Members**. In addition, you can select the option to
[Allow users to request access](../members/index.md#project-membership-and-requesting-access).

CAUTION: **Caution:**
If you [reduce a project's visibility level](../../../public_access/public_access.md#reducing-visibility),
that action unlinks all forks of that project.

Use the switches to enable or disable the following features:

| Option                            | More access limit options | Description                                                                                                                                                                                    |
|:----------------------------------|:--------------------------|:-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Issues**                        | ✓                         | Activates the GitLab issues tracker                                                                                                                                                            |
| **Repository**                    | ✓                         | Enables [repository](../repository/) functionality                                                                                                                                             |
| **Merge Requests**                | ✓                         | Enables [merge request](../merge_requests/) functionality; also see [Merge request settings](#merge-request-settings)                                                                          |
| **Forks**                         | ✓                         | Enables [forking](../index.md#fork-a-project) functionality                                                                                                                                    |
| **Pipelines**                     | ✓                         | Enables [CI/CD](../../../ci/README.md) functionality                                                                                                                                           |
| **Container Registry**            |                           | Activates a [registry](../../packages/container_registry/) for your docker images                                                                                                              |
| **Git Large File Storage**        |                           | Enables the use of [large files](../../../topics/git/lfs/index.md#git-lfs)                                                                                    |
| **Packages**                      |                           | Supports configuration of a [package registry](../../../administration/packages/index.md#gitlab-package-registry-administration-premium-only) functionality                                    |
| **Wiki**                          | ✓                         | Enables a separate system for [documentation](../wiki/)                                                                                                                                        |
| **Snippets**                      | ✓                         | Enables [sharing of code and text](../../snippets.md)                                                                                                                                          |
| **Pages**                         | ✓                         | Allows you to [publish static websites](../pages/)                                                                                                                                             |

Some features depend on others:

- If you disable the **Issues** option, GitLab also removes the following
  features:
  - **Issue Boards**
  - [**Service Desk**](#service-desk-premium) **(PREMIUM)**

  NOTE: **Note:**
  When the **Issues** option is disabled, you can still access **Milestones**
  from merge requests.

- Additionally, if you disable both **Issues** and **Merge Requests**, you will no
  longer have access to:
  - **Labels**
  - **Milestones**

- If you disable **Repository** functionality, GitLab also disables the following
  features for your project:

  - **Merge Requests**
  - **Pipelines**
  - **Container Registry**
  - **Git Large File Storage**
  - **Packages**

#### Disabling email notifications

Project owners can disable all [email notifications](../../profile/notifications.md#gitlab-notification-emails)
related to the project by selecting the **Disable email notifications** checkbox.

### Merge request settings

Set up your project's merge request settings:

- Set up the merge request method (merge commit, [fast-forward merge](../merge_requests/fast_forward_merge.md)).
- Add merge request [description templates](../description_templates.md#description-templates).
- Enable [merge request approvals](../merge_requests/merge_request_approvals.md). **(STARTER)**
- Enable [merge only if pipeline succeeds](../merge_requests/merge_when_pipeline_succeeds.md).
- Enable [merge only when all threads are resolved](../../discussions/index.md#only-allow-merge-requests-to-be-merged-if-all-threads-are-resolved).
- Enable [`delete source branch after merge` option by default](../merge_requests/getting_started.md#deleting-the-source-branch)
- Configure [suggested changes commit messages](../../discussions/index.md#configure-the-commit-message-for-applied-suggestions)

![project's merge request settings](img/merge_requests_settings.png)

### Service Desk **(PREMIUM)**

Enable [Service Desk](../service_desk.md) for your project to offer customer support.

### Export project

Learn how to [export a project](import_export.md#importing-the-project) in GitLab.

### Advanced settings

Here you can run housekeeping, archive, rename, transfer, [remove a fork relationship](#removing-a-fork-relationship), or remove a project.

#### Archiving a project

Archiving a project makes it read-only for all users and indicates that it's
no longer actively maintained. Projects that have been archived can also be
unarchived. Only project Owners and Admin users have the
[permissions](../../permissions.md#project-members-permissions) to archive a project.

When a project is archived, the repository, issues, merge requests, and all
other features are read-only. Archived projects are also hidden
in project listings.

To archive a project:

1. Navigate to your project's **{settings}** **Settings > General**.
1. Under **Advanced**, click **Expand**.
1. In the **Archive project** section, click the **Archive project** button.
1. Confirm the action when asked to.

#### Unarchiving a project

Unarchiving a project removes the read-only restriction on a project, and makes it
available in project listings. Only project Owners and Admin users have the
[permissions](../../permissions.md#project-members-permissions) to unarchive a project.

To find an archived project:

1. Sign in to GitLab as a user with project Owner or Admin permissions.
1. If you:
   - Have the project's URL, open the project's page in your browser.
   - Don't have the project's URL:
   1. Click **Projects > Explore projects**.
   1. In the **Sort projects** dropdown box, select **Show archived projects**.
   1. In the **Filter by name** field, provide the project's name.
   1. Click the link to the project to open its **Details** page.

Next, to unarchive the project:

1. Navigate to your project's **{settings}** **Settings > General**.
1. Under **Advanced**, click **Expand**.
1. In the **Unarchive project** section, click the **Unarchive project** button.
1. Confirm the action when asked to.

#### Renaming a repository

NOTE: **Note:**
Only project Maintainers and Admin users have the [permissions](../../permissions.md#project-members-permissions) to rename a
repository. Not to be confused with a project's name where it can also be
changed from the [general project settings](#general-project-settings).

A project's repository name defines its URL (the one you use to access the
project via a browser) and its place on the file disk where GitLab is installed.

To rename a repository:

1. Navigate to your project's **{settings}** **Settings > General**.
1. Under **Advanced**, click **Expand**.
1. Under "Rename repository", change the "Path" to your liking.
1. Hit **Rename project**.

Remember that this can have unintended side effects since everyone with the
old URL won't be able to push or pull. Read more about what happens with the
[redirects when renaming repositories](../index.md#redirects-when-changing-repository-paths).

#### Transferring an existing project into another namespace

NOTE: **Note:**
Only project Owners and Admin users have the [permissions](../../permissions.md#project-members-permissions)
to transfer a project.

You can transfer an existing project into a [group](../../group/index.md) if:

1. You have at least **Maintainer** [permissions](../../permissions.md#project-members-permissions) to that group.
1. The project is in a subgroup you own.
1. You're at least a **Maintainer** of the project under your personal namespace.
   Similarly, if you're an owner of a group, you can transfer any of its projects
   under your own user.

To transfer a project:

1. Navigate to your project's **{settings}** **Settings > General**.
1. Under **Advanced**, click **Expand**.
1. Under "Transfer project", choose the namespace you want to transfer the
   project to.
1. Confirm the transfer by typing the project's path as instructed.

Once done, you will be taken to the new project's namespace. At this point,
read what happens with the
[redirects from the old project to the new one](../index.md#redirects-when-changing-repository-paths).

NOTE: **Note:**
GitLab administrators can use the admin interface to move any project to any
namespace if needed.

#### Remove a project

NOTE: **Note:**
Only project owners and admins have [permissions](../../permissions.md#project-members-permissions) to remove a project.

To remove a project:

1. Navigate to your project, and select **{settings}** **Settings > General > Advanced**.
1. In the Remove project section, click the **Remove project** button.
1. Confirm the action when asked to.

This action either:

- Removes a project including all associated resources (issues, merge requests etc).
- Since [GitLab 12.6](https://gitlab.com/gitlab-org/gitlab/issues/32935), on
  [GitLab Premium or GitLab.com Silver](https://about.gitlab.com/pricing/) or higher tiers, marks a project for
  deletion. The deletion will happen 7 days later by default, but this can be changed in the
  [instance settings](../../admin_area/settings/visibility_and_access_controls.md#default-deletion-adjourned-period-premium-only).

#### Restore a project **(PREMIUM)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/issues/32935) in GitLab 12.6.

To restore a project marked for deletion:

1. Navigate to your project, and select **{settings}** **Settings > General > Advanced**.
1. In the Restore project section, click the **Restore project** button.

#### Removing a fork relationship

Forking is a great way to [contribute to a project](../repository/forking_workflow.md)
of which you're not a member.
If you want to use the fork for yourself and don't need to send
[merge requests](../merge_requests.md) to the upstream project,
you can safely remove the fork relationship.

CAUTION: **Caution:**
Once removed, the fork relationship cannot be restored. You will no longer be able to send merge requests to the source, and if anyone has forked your project, their fork will also lose the relationship.

To do so:

1. Navigate to your project's **Settings > General > Advanced**.
1. Under **Remove fork relationship**, click the likewise-labeled button.
1. Confirm the action by typing the project's path as instructed.

NOTE: **Note:**
Only project maintainers have the [permissions](../../permissions.md#project-members-permissions)
to remove a fork relationship.

## Operations settings

### Error Tracking

Configure Error Tracking to discover and view [Sentry errors within GitLab](../operations/error_tracking.md).

### Jaeger tracing **(ULTIMATE)**

Add the URL of a Jaeger server to allow your users to [easily access the Jaeger UI from within GitLab](../operations/tracing.md).
