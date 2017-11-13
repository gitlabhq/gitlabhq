# Project settings

You can adjust your [project](../index.md) settings by navigating
to your project's homepage and clicking **Settings**.

## General settings

Adjust your project's path and name, description, avatar, [default branch](../repository/branches/index.md#default-branch), and tags:

![general project settings](img/general_settings.png)

### Sharing and permissions

Set up your project's access, [visibility](../../../public_access/public_access.md), and enable [Container Registry](../container_registry.md) for your projects:

![projects sharing permissions](img/sharing_and_permissions_settings.png)

### Issue settings

Add an [issue description template](../description_templates.md#description-templates) to your project, so that every new issue will start with a custom template.

### Merge request settings

Set up your project's merge request settings:

- Set up the merge request method (merge commit, [fast-forward merge](../merge_requests/fast_forward_merge.html)).
- Merge request [description templates](../description_templates.md#description-templates).
- Enable [merge request approvals](https://docs.gitlab.com/ee/user/project/merge_requests/merge_request_approvals.html#merge-request-approvals), _available in [GitLab Enterprise Edition Starter](https://about.gitlab.com/gitlab-ee/)_.
- Enable [merge only of pipeline succeeds](../merge_requests/merge_when_pipeline_succeeds.md).
- Enable [merge only when all discussions are resolved](../../discussions/index.md#only-allow-merge-requests-to-be-merged-if-all-discussions-are-resolved).

![project's merge request settings](img/merge_requests_settings.png)

### Service Desk

Enable [Service Desk](https://docs.gitlab.com/ee/user/project/service_desk.html) for your project to offer customer support. Service Desk is available in [GitLab Enterprise Edition Premium](https://about.gitlab.com/gitlab-ee/).

### Export project

Learn how to [export a project](import_export.md#importing-the-project) in GitLab.

### Advanced settings

Here you can run housekeeping, archive, rename, transfer, or remove a project.

#### Archiving a project

>**Note:** Only Project Owners and Admin users have the permission to archive a project

It's possible to mark a project as archived via the Project Settings. An archived project will be hidden by default in the project listings.

An archived project can be fully restored and will therefore retain it's repository and all associated resources whilst in an archived state.
