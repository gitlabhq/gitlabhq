---
stage: Data Stores
group: Tenant Scale
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Project features and permissions

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

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

## Enable and disable project features

Enabled project features are visible and accessible to project members.
You can disable specific project features, so that they are not visible and accessible to project members, regardless of their role.

To enable or disable individual features in a project:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > General**.
1. Expand **Visibility, project features, permissions**.
1. To enable a feature, turn on the toggle. To disable a feature, turn off the toggle.
1. Select **Save changes**.

## Disable project analytics

By default, project analytics are displayed under the **Analyze** item in the left sidebar.
To disable this feature and remove the **Analyze** item from the left sidebar:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > General**.
1. Expand **Visibility, project features, permissions**.
1. Turn off the **Analytics** toggle.
1. Select **Save changes**.

## Disable CVE identifier request in issues

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/41203) in GitLab 13.4, only for public projects on GitLab.com.

In some environments, users can submit a [CVE identifier request](../../application_security/cve_id_request.md) in an issue.

To disable the CVE identifier request option in issues in your project:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > General**.
1. Expand **Visibility, project features, permissions**.
1. Under **Issues**, turn off the **CVE ID requests in the issue sidebar** toggle.
1. Select **Save changes**.

## Disable project email notifications

Prerequisites:

- You must have the Owner role for the project.

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > General**.
1. Expand **Visibility, project features, permissions**.
1. Clear the **Disable email notifications** checkbox.

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
