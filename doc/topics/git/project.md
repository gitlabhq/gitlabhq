---
stage: Tenant Scale
group: Organizations
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments"
title: 'Create a project with `git push`'
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

You can use `git push` to add a local project repository to GitLab. After you add a repository,
GitLab creates your project in your chosen namespace.

NOTE:
You cannot use `git push` to create projects with paths that were previously used or
[renamed](../../user/project/working_with_projects.md#rename-a-repository).
Previously used project paths have a redirect. Instead of creating a new project,
the redirect causes push attempts to redirect requests to the renamed project location.
To create a new project for a previously used or renamed project, use the UI
or the [Projects API](../../api/projects.md#create-a-project).

Prerequisites:

<!--- To push with SSH, you must have [an SSH key](../ssh.md) that is
  [added to your GitLab account](../ssh.md#add-an-ssh-key-to-your-gitlab-account).
-->
- You must have permission to add new projects to a [namespace](../../user/namespace/_index.md).
  To verify your permissions:

  1. On the left sidebar, select **Search or go to** and find your group.
  1. In the upper-right corner, confirm that **New project** is visible.

  If you do not have the necessary permission, contact your GitLab administrator.

To create a project with `git push`:

1. Push your local repository to GitLab with one of the following:

   - With SSH:

      - If your project uses the standard port 22, run:

        ```shell
        git push --set-upstream git@gitlab.example.com:namespace/myproject.git main
        ```

      - If your project requires a non-standard port number, run:

        ```shell
        git push --set-upstream ssh://git@gitlab.example.com:00/namespace/myproject.git main
        ```

   - With HTTP, run:

      ```shell
      git push --set-upstream https://gitlab.example.com/namespace/myproject.git master
      ```

      Replace the following values:

      - `gitlab.example.com` with the machine domain name hosts your Git repository.
      - `namespace` with your [namespace](../../user/namespace/_index.md) name.
      - `myproject` with your project name.
      - If specifying a port, change `00` to your project's required port number.
      - Optional. To export existing repository tags, append the `--tags` flag to
        your `git push` command.

1. Optional. Configure the remote:

   ```shell
   git remote add origin https://gitlab.example.com/namespace/myproject.git
   ```

When the `git push` operation completes, GitLab displays the following message:

```shell
remote: The private project namespace/myproject was created.
```

To view your new project, go to `https://gitlab.example.com/namespace/myproject`.
By default, your project's visibility is set to **Private**,
but you can [change the project's visibility](../../user/public_access.md#change-project-visibility).

## Related topics

- [Create a blank project](../../user/project/_index.md)
- [Create a project from a template](../../user/project/_index.md#create-a-project-from-a-built-in-template)
- [Clone a repository to your local machine](clone.md)
