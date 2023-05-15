---
stage: Data Stores
group: Tenant Scale
info: 'To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments'
type: reference, index, howto
---

# Project settings **(FREE)**

Use the **Settings** page to manage the configuration options in your [project](../index.md).

## View project settings

You must have at least the Maintainer role to view project settings.

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Settings > General**.
1. To display all settings in a section, select **Expand**.
1. Optional. Use the search box to find a setting.

## Edit project name and description

Use the project general settings to edit your project details.

1. Sign in to GitLab with at least the Maintainer role.
1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Settings > General**.
1. In the **Project name** text box, enter your project name.
1. In the **Project description** text box, enter your project description.
1. Under **Project avatar**, to change your project avatar, select **Choose file**.

## Assign topics to a project

Use topics to categorize projects and find similar new projects.

To assign topics to a project:

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Settings** > **General**.
1. In the **Topics** text box, enter the project topics. Popular topics are suggested as you type.
1. Select **Save changes**.

If you're an instance administrator, you can administer all project topics from the
[Admin Area's Topics page](../../admin_area/index.md#administering-topics).

## Add a compliance framework to a project **(PREMIUM)**

[Compliance frameworks](../../group/compliance_frameworks.md) can be assigned to projects within group that has a
compliance framework using either:

- The GitLab UI:
  1. On the top bar, select **Main menu > Projects > View all projects** and find your project.
  1. On the left sidebar, select **Settings** > **General**.
  1. Expand the **Compliance frameworks** section.
  1. Select a compliance framework.
  1. Select **Save changes**.
- In [GitLab 14.2](https://gitlab.com/gitlab-org/gitlab/-/issues/333249) and later, using the
  [GraphQL API](../../../api/graphql/reference/index.md#mutationprojectsetcomplianceframework). If you create
  compliance frameworks on subgroups with GraphQL, the framework is created on the root ancestor if the user has the
  correct permissions. The GitLab UI presents a read-only view to discourage this behavior.

## Configure project visibility, features, and permissions

To configure visibility, features, and permissions for a project:

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Settings > General**.
1. Expand the **Visibility, project features, permissions** section.
1. To change the project visibility, select the dropdown list. If you select to **Public**, you limit access to some features to **Only Project Members**.
1. To allow users to request access to the project, select the **Users can request access** checkbox.
1. Use the [toggles](#project-feature-settings) to enable or disable features in the project.
1. Select **Save changes**.

### Project feature settings

Use the toggles to enable or disable features in the project.

| Option                           | More access limit options | Description
| :------------------------------- | :------------------------ | :---------- |
| **Issues**                       | **{check-circle}** Yes | Activates the GitLab issues tracker.
| **Repository**                   | **{check-circle}** Yes | Enables [repository](../repository/index.md) functionality.
| **Merge requests**               | **{check-circle}** Yes | Enables [merge request](../merge_requests/index.md) functionality; also see [Merge request settings](#configure-merge-request-settings-for-a-project).
| **Forks**                        | **{check-circle}** Yes | Enables [forking](../repository/forking_workflow.md) functionality.
| **Git Large File Storage (LFS)** | **{dotted-circle}** No | Enables the use of [large files](../../../topics/git/lfs/index.md#git-large-file-storage-lfs).
| **Packages**                     | **{dotted-circle}** No | Supports configuration of a [package registry](../../../administration/packages/index.md#gitlab-package-registry-administration) functionality.
| **CI/CD**                        | **{check-circle}** Yes | Enables [CI/CD](../../../ci/index.md) functionality.
| **Container Registry**           | **{dotted-circle}** No | Activates a [registry](../../packages/container_registry/index.md) for your Docker images.
| **Analytics**                    | **{check-circle}** Yes | Enables [analytics](../../analytics/index.md).
| **Requirements**                 | **{check-circle}** Yes | Control access to [Requirements Management](../requirements/index.md).
| **Security and Compliance**      | **{check-circle}** Yes | Control access to [security features](../../application_security/index.md).
| **Wiki**                         | **{check-circle}** Yes | Enables a separate system for [documentation](../wiki/index.md).
| **Snippets**                     | **{check-circle}** Yes | Enables [sharing of code and text](../../snippets.md).
| **Pages**                        | **{check-circle}** Yes | Allows you to [publish static websites](../pages/index.md).
| **Metrics Dashboard**            | **{check-circle}** Yes | Control access to [metrics dashboard](../integrations/prometheus.md).
| **Releases**                     | **{check-circle}** Yes | Control access to [Releases](../releases/index.md).
| **Environments**                 | **{check-circle}** Yes | Control access to [Environments and Deployments](../../../ci/environments/index.md).
| **Feature flags**                | **{check-circle}** Yes | Control access to [Feature flags](../../../operations/feature_flags.md).
| **Monitor**                      | **{check-circle}** Yes | Control access to [Monitor](../../../operations/index.md) features.
| **Infrastructure**               | **{check-circle}** Yes | Control access to [Infrastructure](../../infrastructure/index.md) features.

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
  - **Container Registry**
  - **Git Large File Storage**
  - **Packages**

- Metrics dashboard access requires reading project environments and deployments.
  Users with access to the metrics dashboard can also access environments and deployments.

## Disable CVE identifier request in issues **(FREE SAAS)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/41203) in GitLab 13.4, only for public projects on GitLab.com.

In some environments, users can submit a [CVE identifier request](../../application_security/cve_id_request.md) in an issue.

To disable the CVE identifier request option in issues in your project:

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Settings > General**.
1. Expand the **Visibility, project features, permissions** section.
1. Under **Issues**, turn off the **CVE ID requests in the issue sidebar** toggle.
1. Select **Save changes**.

## Disable project email notifications

Prerequisites:

- You must be an Owner of the project to disable email notifications related to the project.

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Settings > General**.
1. Expand the **Visibility, project features, permissions** section.
1. Clear the **Disable email notifications** checkbox.

## Configure merge request settings for a project

Configure your project's merge request settings:

- Set up the [merge request method](../merge_requests/methods/index.md) (merge commit, fast-forward merge).
- Add merge request [description templates](../description_templates.md#description-templates).
- Enable [merge request approvals](../merge_requests/approvals/index.md).
- Enable [status checks](../merge_requests/status_checks.md).
- Enable [merge only if pipeline succeeds](../merge_requests/merge_when_pipeline_succeeds.md).
- Enable [merge only when all threads are resolved](../../discussions/index.md#prevent-merge-unless-all-threads-are-resolved).
- Enable [require an associated issue from Jira](../../../integration/jira/issues.md#require-associated-jira-issue-for-merge-requests-to-be-merged).
- Enable [**Delete source branch when merge request is accepted** option by default](#delete-the-source-branch-on-merge-by-default).
- Configure [suggested changes commit messages](../merge_requests/reviews/suggestions.md#configure-the-commit-message-for-applied-suggestions).
- Configure [merge and squash commit message templates](../merge_requests/commit_templates.md).
- Configure [the default target project](../merge_requests/creating_merge_requests.md#set-the-default-target-project) for merge requests coming from forks.
- Enable [Suggested Reviewers](../merge_requests/reviews/index.md#suggested-reviewers).

## Service Desk

Enable [Service Desk](../service_desk.md) for your project to offer customer support.

## Export project

Learn how to [export a project](import_export.md#import-a-project-and-its-data) in GitLab.

## Advanced project settings

Use the advanced settings to archive, rename, transfer,
[remove a fork relationship](../repository/forking_workflow.md#unlink-a-fork), or delete a project.

### Archive a project

When you archive a project, the repository, packages, issues, merge requests, and all
other features are read-only. Archived projects are also hidden from project listings.

To archive a project:

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Settings > General**.
1. Expand **Advanced**.
1. In the **Archive project** section, select **Archive project**.
1. To confirm, select **OK**.

### Unarchive a project

When you unarchive a project, you remove the read-only restriction and make it
available in project lists.

Prerequisites:

- To unarchive a project, you must be an administrator or a project Owner.

1. Find the archived project.
   1. On the top bar, select **Main menu > Projects > View all projects**.
   1. Select **Explore projects**.
   1. In the **Sort projects** dropdown list, select **Show archived projects**.
   1. In the **Filter by name** field, enter the project name.
   1. Select the project link.
1. On the left sidebar, select **Settings > General**.
1. Under **Advanced**, select **Expand**.
1. In the **Unarchive project** section, select **Unarchive project**.
1. To confirm, select **OK**.

### Rename a repository

A project's repository name defines its URL and its place on the file disk
where GitLab is installed.

Prerequisites:

You must be a project maintainer, owner, or administrator to rename a repository.

NOTE:
When you change the repository path, users may experience issues if they push to, or pull from, the old URL. For more information, see
[redirects when renaming repositories](../repository/index.md#what-happens-when-a-repository-path-changes).

To rename a repository:

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Settings > General**.
1. Expand the **Advanced** section.
1. In the **Change path** text box, edit the path.
1. Select **Change path**.

## Delete the source branch on merge by default

In merge requests, you can change the default behavior so that the
**Delete the source branch** checkbox is always selected.

To set this default:

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Settings > Merge requests**.
1. Select **Enable "Delete source branch" option by default**.
1. Select **Save changes**.

## Transfer a project to another namespace

When you transfer a project to another namespace, you move the project to a different group.

Prerequisites:

- You must have at least the Maintainer role for the [group](../../group/manage.md#create-a-group) to which you are transferring.
- You must be the Owner of the project you transfer.
- The group must allow creation of new projects.
- The project must not contain any [container images](../../packages/container_registry/index.md#move-or-rename-container-registry-repositories).
- Remove any npm packages. If you transfer a project to a different root namespace, the project must not contain any npm packages. When you update the path of a user or group, or transfer a subgroup or project, you must remove any npm packages first. You cannot update the root namespace of a project with npm packages. Make sure you update your .npmrc files to follow the naming convention and run npm publish if necessary.
- If a security policy is assigned to the project, it is automatically unassigned during the transfer.

To transfer a project:

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Settings > General**.
1. Expand **Advanced**.
1. Under **Transfer project**, choose the namespace to transfer the project to.
1. Select **Transfer project**.
1. Enter the project's name and select **Confirm**.

You are redirected to the project's new page and GitLab applies a redirect. For more information about repository redirects, see [What happens when a repository path changes](../repository/index.md#what-happens-when-a-repository-path-changes).

NOTE:
If you are an administrator, you can also use the [administration interface](../../admin_area/index.md#administering-projects)
to move any project to any namespace.

### Transferring a GitLab SaaS project to a different subscription tier

When you transfer a project from a namespace licensed for GitLab SaaS Premium or Ultimate to GitLab Free, the following paid feature data is deleted:

- [Project access tokens](../../../user/project/settings/project_access_tokens.md) are revoked
- [Pipeline subscriptions](../../../ci/pipelines/index.md#trigger-a-pipeline-when-an-upstream-project-is-rebuilt)
  and [test cases](../../../ci/test_cases/index.md) are deleted.

## Delete a project

You can mark a project to be deleted.

Prerequisite:

- You must have the Owner role for a project.

To delete a project:

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Settings > General**.
1. Expand **Advanced**.
1. In the "Delete project" section, select **Delete project**.
1. Confirm the action when asked to.

This action deletes a project including all associated resources (such as issues and merge requests).

WARNING:
The default deletion behavior for projects was changed to [delayed project deletion](https://gitlab.com/gitlab-org/gitlab/-/issues/32935)
in GitLab 12.6, and then to [immediate deletion](https://gitlab.com/gitlab-org/gitlab/-/issues/220382) in GitLab 13.2.

### Delayed project deletion **(PREMIUM)**

> - [Enabled for projects in personal namespaces](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/89466) in GitLab 15.1.
> - [Disabled for projects in personal namespaces](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/95495) in GitLab 15.3.

Projects in a group (not a personal namespace) can be deleted after a delay period. Multiple settings can affect whether
delayed project deletion is enabled for a particular project:

- Self-managed instance [settings](../../admin_area/settings/visibility_and_access_controls.md#delayed-project-deletion).
  You can enable delayed project deletion as the default setting for new groups, and configure the number of days for the
  delay. For GitLab.com, see the [GitLab.com settings](../../gitlab_com/index.md#delayed-project-deletion).
- Group [settings](../../group/manage.md#enable-delayed-project-deletion) to enabled delayed project deletion for all
  projects in the group.

### Delete a project immediately

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/191367) in GitLab 14.1.

If you don't want to wait, you can delete a project immediately.

Prerequisites:

- You must have the Owner role for a project.
- You have [marked the project for deletion](#delete-a-project).

To immediately delete a project marked for deletion:

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Settings > General**.
1. Expand **Advanced**.
1. In the "Permanently delete project" section, select **Delete project**.
1. Confirm the action when asked to.

The following are deleted:

- Your project and its repository.
- All related resources including issues and merge requests.

## Restore a project **(PREMIUM)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/32935) in GitLab 12.6.

To restore a project marked for deletion:

1. Navigate to your project, and select **Settings > General > Advanced**.
1. In the Restore project section, select **Restore project**.

## Monitor settings

### Alerts

Configure [alert integrations](../../../operations/incident_management/integrations.md#configuration) to triage and manage critical problems in your application as [alerts](../../../operations/incident_management/alerts.md).

### Incidents

#### Alert integration

Automatically [create](../../../operations/incident_management/alerts.md#trigger-actions-from-alerts), [notify on](../../../operations/incident_management/paging.md#email-notifications-for-alerts), and [resolve](../../../operations/incident_management/manage_incidents.md#automatically-close-incidents-via-recovery-alerts) incidents based on GitLab alerts.

#### PagerDuty integration

[Create incidents in GitLab for each PagerDuty incident](../../../operations/incident_management/manage_incidents.md#using-the-pagerduty-webhook).

#### Incident settings

[Manage Service Level Agreements for incidents](../../../operations/incident_management/incidents.md#service-level-agreement-countdown-timer) with an SLA countdown timer.

### Error Tracking

Configure Error Tracking to discover and view [Sentry errors within GitLab](../../../operations/error_tracking.md).

### Status Page **(ULTIMATE)**

[Add Storage credentials](../../../operations/incident_management/status_page.md#sync-incidents-to-the-status-page)
to enable the syncing of public Issues to a [deployed status page](../../../operations/incident_management/status_page.md#create-a-status-page-project).

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
