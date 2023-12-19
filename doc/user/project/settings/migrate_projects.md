---
stage: Data Stores
group: Tenant Scale
info: 'To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments'
---

# Migrate projects **(FREE ALL)**

## Export a project

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

Prerequisites:

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

## Restore a project **(PREMIUM ALL)**

Prerequisites:

- You must have the Owner role for the project.
- The project must be [marked for deletion](../working_with_projects.md#delete-a-project).

To restore a project marked for deletion:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > General**.
1. Expand **Advanced**.
1. In the Restore project section, select **Restore project**.

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

## Related topics

- [Migrating projects using file exports](import_export.md)
- [Troubleshooting file export project migrations](import_export_troubleshooting.md)
