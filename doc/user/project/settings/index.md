---
stage: Data Stores
group: Tenant Scale
info: 'To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments'
type: reference, index, howto
---

# Project settings **(FREE ALL)**

Use the **Settings** page to manage the configuration options in your [project](../index.md).

## View project settings

Prerequisite:

- You must have at least the Maintainer role for the project.

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > General**.
1. To display all settings in a section, select **Expand**.
1. Optional. Use the search box to find a setting.

## Edit project name and description

Use the project general settings to edit your project details.

Prerequisite:

- You must have at least the Maintainer role for the project.

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > General**.
1. In the **Project name** text box, enter your project name.
1. In the **Project description** text box, enter your project description.
1. Under **Project avatar**, to change your project avatar, select **Choose file**.

## Assign topics to a project

Use [topics](../working_with_projects.md#organizing-projects-with-topics) to categorize projects and find similar new projects.

To assign topics to a project:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings** > **General**.
1. In the **Topics** text box, enter the project topics. Popular topics are suggested as you type.
1. Select **Save changes**.

If you're an instance administrator, you can administer all project topics from the
[Admin Area's Topics page](../../../administration/admin_area.md#administering-topics).

NOTE:
The assigned topics are visible only to users with access to the project, but everyone can see which topics exist on the GitLab instance. Do not include sensitive information in the name of a topic.

## Rename a repository

A project's repository name defines its URL and its place on the file disk
where GitLab is installed.

Prerequisite:

- You must be an administrator or have the Maintainer or Owner role for the project.

NOTE:
When you change the repository path, users may experience issues if they push to, or pull from, the old URL. For more information, see
[redirects when renaming repositories](../repository/index.md#what-happens-when-a-repository-path-changes).

To rename a repository:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > General**.
1. Expand **Advanced**.
1. In the **Change path** text box, edit the path.
1. Select **Change path**.

## Configure project features and permissions

To configure features and permissions for a project:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > General**.
1. Expand **Visibility, project features, permissions**.
1. To allow users to request access to the project, select the **Users can request access** checkbox.
1. To enable or disable features in the project, use the feature toggles.
1. Select **Save changes**.

When you disable a feature, the following additional features are also disabled:

- If you disable the **Issues** feature, project users cannot use:

  - **Issue Boards**
  - **Service Desk**
  - Project users can still access **Milestones** from merge requests.

- If you disable **Issues** and **Merge Requests**, project users cannot use:

  - **Labels**
  - **Milestones**

- If you disable **Repository**, project users cannot access:

  - **Merge requests**
  - **CI/CD**
  - **Git Large File Storage**
  - **Packages**

- The metrics dashboard requires read access to project environments and deployments.
  Users with access to the metrics dashboard can also access environments and deployments.

## Configure merge request settings for a project

Configure your project's merge request settings:

- Set up the [merge request method](../merge_requests/methods/index.md) (merge commit, fast-forward merge).
- Add merge request [description templates](../description_templates.md).
- Enable:
  - [Merge request approvals](../merge_requests/approvals/index.md).
  - [Status checks](../merge_requests/status_checks.md).
  - [Merge only if pipeline succeeds](../merge_requests/merge_when_pipeline_succeeds.md).
  - [Merge only when all threads are resolved](../merge_requests/index.md#prevent-merge-unless-all-threads-are-resolved).
  - [Required associated issue from Jira](../../../integration/jira/issues.md#require-associated-jira-issue-for-merge-requests-to-be-merged).
  - [GitLab Duo Suggested Reviewers](../merge_requests/reviews/index.md#gitlab-duo-suggested-reviewers)
  - [**Delete source branch when merge request is accepted** option by default](#delete-the-source-branch-on-merge-by-default).
- Configure:
  - [Suggested changes commit messages](../merge_requests/reviews/suggestions.md#configure-the-commit-message-for-applied-suggestions).
  - [Merge and squash commit message templates](../merge_requests/commit_templates.md).
  - [Default target project](../merge_requests/creating_merge_requests.md#set-the-default-target-project) for merge requests coming from forks.

### Delete the source branch on merge by default

In merge requests, you can change the default behavior so that the
**Delete the source branch** checkbox is always selected.

To set this default:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > Merge requests**.
1. Select **Enable "Delete source branch" option by default**.
1. Select **Save changes**.

## Export project

You can [export a project and its data](import_export.md#export-a-project-and-its-data).

## Transfer a project to another namespace

When you transfer a project to another namespace, you move the project to a different group.

Prerequisites:

- You must have at least the Maintainer role for the [group](../../group/index.md#create-a-group) you are transferring to.
- You must be the Owner of the project you transfer.
- The group must allow creation of new projects.
- The project must not contain any [container images](../../packages/container_registry/index.md#move-or-rename-container-registry-repositories).
- The project must not have a security policy.
  If a security policy is assigned to the project, it is automatically unassigned during the transfer.
- If the root namespace changes, you must remove npm packages that follow the [naming convention](../../../user/packages/npm_registry/index.md#naming-convention) from the project.
  After you transfer the project you can either:

  - Update the package scope with the new root namespace path, and publish it again to the project.
  - Republish the package to the project without updating the root namespace path, which causes the package to no longer follow the naming convention.
    If you republish the package without updating the root namespace path, it will not be available at the [instance level endpoint](../../../user/packages/npm_registry/index.md#install-from-the-instance-level).

To transfer a project:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > General**.
1. Expand **Advanced**.
1. Under **Transfer project**, choose the namespace to transfer the project to.
1. Select **Transfer project**.
1. Enter the project's name and select **Confirm**.

You are redirected to the project's new page and GitLab applies a redirect. For more information about repository redirects, see [What happens when a repository path changes](../repository/index.md#what-happens-when-a-repository-path-changes).

NOTE:
If you are an administrator, you can also use the [administration interface](../../../administration/admin_area.md#administering-projects)
to move any project to any namespace.

### Transferring a GitLab SaaS project to a different subscription tier

When you transfer a project from a namespace licensed for GitLab SaaS Premium or Ultimate to GitLab Free:

- [Project access tokens](../../../user/project/settings/project_access_tokens.md) are revoked.
- [Pipeline subscriptions](../../../ci/pipelines/index.md#trigger-a-pipeline-when-an-upstream-project-is-rebuilt)
  and [test cases](../../../ci/test_cases/index.md) are deleted.

## Archive a project

When you archive a project, the repository, packages, issues, merge requests, and all
other features become read-only. Archived projects are also hidden from project lists.

To archive a project:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > General**.
1. Expand **Advanced**.
1. In the **Archive project** section, select **Archive project**.
1. To confirm, select **OK**.

## Unarchive a project

When you unarchive a project, the read-only restriction is removed,
and the project becomes available in project lists.

Prerequisite:

- You must be an administrator or have the Owner role for the project.

1. Find the archived project.
   1. On the left sidebar, select **Search or go to**.
   1. Select **View all my projects**.
   1. Select **Explore projects**.
   1. In the **Sort projects** dropdown list, select **Show archived projects**.
   1. In the **Filter by name** field, enter the project name.
   1. Select the project link.
1. On the left sidebar, select **Settings > General**.
1. Under **Advanced**, select **Expand**.
1. In the **Unarchive project** section, select **Unarchive project**.
1. To confirm, select **OK**.

## Delete a project

> - Default deletion behavior for projects changed to [delayed project deletion](https://gitlab.com/gitlab-org/gitlab/-/issues/32935) in GitLab 12.6.
> - Default deletion behavior for projects changed to [immediate deletion](https://gitlab.com/gitlab-org/gitlab/-/issues/220382) in GitLab 13.2.
> - Default deletion behavior for projects on the Premium and Ultimate tier changed to [delayed project deletion](https://gitlab.com/gitlab-org/gitlab/-/issues/389557) in GitLab 16.0.
> - Default deletion behavior changed to delayed deletion on the Premium and Ultimate tier [on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/393622) and [on self-managed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/119606) in GitLab 16.0.

You can mark a project to be deleted.
After you delete a project:

- Projects in personal namespaces are deleted immediately.
- Projects in groups are deleted after a retention period.

Prerequisite:

- You must have the Owner role for a project.

To delete a project:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > General**.
1. Expand **Advanced**.
1. In the **Delete this project** section, select **Delete project**.
1. On the confirmation dialog, enter the project name and select **Yes, delete project**.

This action deletes the project and all associated resources (such as issues and merge requests).

You can also [delete projects using the Rails console](../working_with_projects.md#delete-a-project-using-console).

### Delayed project deletion **(PREMIUM ALL)**

> - [Enabled for projects in personal namespaces](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/89466) in GitLab 15.1.
> - [Disabled for projects in personal namespaces](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/95495) in GitLab 15.3.
> - Enabled delayed deletion by default and removed the option to delete immediately [on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/393622) and [on self-managed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/119606) in GitLab 16.0.

Prerequisite:

- You must have the Owner role for the project.

Projects in a group (not a personal namespace) can be deleted after a delay period.

On self-managed instances, group administrators can define a deletion delay period of between 1 and 90 days.
On SaaS, there is a non-adjustable default retention period of seven days.

You can [view projects that are pending deletion](../working_with_projects.md#view-projects-pending-deletion),
and use the Rails console to
[find projects that are pending deletion](../working_with_projects.md#find-projects-that-are-pending-deletion).

### Delete a project immediately

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/191367) in GitLab 14.1.
> - Option to delete projects immediately from the Admin Area and as a group setting removed [on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/393622) and [on self-managed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/119606) in GitLab 16.0.

Prerequisites:

- You must have the Owner role for the project.
- The project must be [marked for deletion](#delete-a-project).

If you don't want to wait for delayed deletion, you can delete a project immediately. To do this, perform the steps for [deleting a projects](#delete-a-project) again.

In the first cycle of deleting a project, the project is moved to the delayed deletion queue and automatically deleted after the retention period has passed.
If during this delayed deletion time you run a second deletion cycle, the project is deleted immediately.

To immediately delete a project marked for deletion:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > General**.
1. Expand **Advanced**.
1. In the **Delete this project** section, select **Delete project**.
1. On the confirmation dialog, enter the project name and select **Yes, delete project**.

## Restore a project **(PREMIUM ALL)**

Prerequisites:

- You must have the Owner role for the project.
- The project must be [marked for deletion](#delete-a-project).

To restore a project marked for deletion:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > General**.
1. Expand **Advanced**.
1. In the Restore project section, select **Restore project**.

## Disable project analytics

By default, [analytics for a project](../../analytics/index.md#project-level-analytics) are displayed under the **Analyze** item in the left sidebar.
To disable this feature and remove the **Analyze** item from the left sidebar:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > General**.
1. Expand **Visibility, project features, permissions**.
1. Turn off the **Analytics** toggle.
1. Select **Save changes**.

## Disable CVE identifier request in issues **(FREE SAAS)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/41203) in GitLab 13.4, only for public projects on GitLab.com.

In some environments, users can submit a [CVE identifier request](../../application_security/cve_id_request.md) in an issue.

To disable the CVE identifier request option in issues in your project:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > General**.
1. Expand **Visibility, project features, permissions**.
1. Under **Issues**, turn off the **CVE ID requests in the issue sidebar** toggle.
1. Select **Save changes**.

## Disable project email notifications

Prerequisite:

- You must have the Owner role for the project.

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > General**.
1. Expand **Visibility, project features, permissions**.
1. Clear the **Disable email notifications** checkbox.

## Related topics

- [Alert integrations](../../../operations/incident_management/integrations.md#configuration)
- [PagerDuty incident management](../../../operations/incident_management/manage_incidents.md#using-the-pagerduty-webhook)
- [SLA countdown timer](../../../operations/incident_management/incidents.md#service-level-agreement-countdown-timer)
- [Error tracking](../../../operations/error_tracking.md)
- [Incidents sync](../../../operations/incident_management/status_page.md#sync-incidents-to-the-status-page)
- [Service Desk](../service_desk/index.md)

## Troubleshooting

When working with project settings, you might encounter the following issues, or require alternate methods to complete specific tasks.

### Transfer a project through console

If transferring a project through the UI or API is not working, you can attempt the transfer in a [Rails console session](../../../administration/operations/rails_console.md#starting-a-rails-console-session).

```ruby
p = Project.find_by_full_path('<project_path>')

# To set the owner of the project
current_user = p.creator

# Namespace where you want this to be moved
namespace = Namespace.find_by_full_path("<new_namespace>")

Projects::TransferService.new(p, current_user).execute(namespace)
```
