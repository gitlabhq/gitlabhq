---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments"
type: concepts, howto
---

# Default branch **(FREE)**

When you create a new [project](../../index.md), GitLab creates a default branch
in the repository. A default branch has special configuration options not shared
by other branches:

- It's [initially protected](../../protected_branches.md#protected-branches) against
  accidental deletion and forced pushes.
- When a merge request uses an
  [issue closing pattern](../../issues/managing_issues.md#closing-issues-automatically)
  to close an issue, the work is merged into this branch.

The name of your [new project's](../../index.md) default branch depends on any
instance-level or group-level configuration changes made by your GitLab administrator.
GitLab checks first for specific customizations, then checks at a broader level,
using the GitLab default only if no customizations are set:

1. A [project-specific](#change-the-default-branch-name-for-a-project) custom default branch name.
1. A [subgroup-level](#group-level-custom-initial-branch-name) custom default branch name.
1. A [group-level](#group-level-custom-initial-branch-name) custom default branch name.
1. An [instance-level](#instance-level-custom-initial-branch-name) custom default branch name. **(FREE SELF)**
1. If no custom default branch name is set at any level, GitLab defaults to:
   - `main`: Projects created with GitLab 14.0 or later.
   - `master`: Projects created before GitLab 14.0.

In the GitLab UI, you can change the defaults at any level. GitLab also provides
the [Git commands you need](#update-the-default-branch-name-in-your-repository) to update your copy of the repository.

## Change the default branch name for a project

To update the default branch name for an individual [project](../../index.md):

1. Sign in to GitLab as a user with [Administrator](../../../permissions.md) permissions.
1. In the left navigation menu, go to **Settings > Repository**.
1. Expand **Default branch**, and select a new default branch.
1. (Optional) Select the **Auto-close referenced issues on default branch** check box to close
   issues when a merge request
   [uses a closing pattern](../../issues/managing_issues.md#closing-issues-automatically).
1. Select **Save changes**.

API users can also use the `default_branch` attribute of the
[Projects API](../../../../api/projects.md) when creating or editing a project.

## Change the default branch name for an instance or group

GitLab administrators can configure a new default branch name at the
[instance level](#instance-level-custom-initial-branch-name) or
[group level](#group-level-custom-initial-branch-name).

### Instance-level custom initial branch name **(FREE SELF)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/221013) in GitLab 13.2.
> - [Feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/issues/325163) in GitLab 13.12.

GitLab [administrators](../../../permissions.md) of self-managed instances can
customize the initial branch for projects hosted on that instance. Individual
groups and subgroups can override this instance-wide setting for their projects.

1. On the top bar, select **Menu >** **{admin}** **Admin**.
1. In the left sidebar, select **Settings > Repository**.
1. Expand **Default initial branch name**.
1. Change the default initial branch to a custom name of your choice.
1. Select **Save changes**.

Projects created on this instance after you change the setting use the
custom branch name, unless a group-level or subgroup-level configuration
overrides it.

### Group-level custom initial branch name

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/221014) in GitLab 13.6.

Administrators of groups and subgroups can configure the default branch name for a group:

1. Go to the group **Settings > Repository**.
1. Expand **Default initial branch name**.
1. Change the default initial branch to a custom name of your choice.
1. Select **Save changes**.

Projects created in this group after you change the setting use the custom branch name,
unless a subgroup configuration overrides it.

## Update the default branch name in your repository

WARNING:
Changing the name of your default branch can potentially break tests,
CI/CD configuration, services, helper utilities, and any integrations your repository
uses. Before you change this branch name, consult with your project owners and maintainers.
Ensure they understand the scope of this change includes references to the old
branch name in related code and scripts.

When changing the default branch name for an existing repository, you should preserve
the history of your default branch by renaming it, instead of deleting it. This example
renames a Git repository's (`example`) default branch.

1. On your local command line, navigate to your `example` repository, and ensure
   you're on the default branch:

   ```plaintext
   cd example
   git checkout master
   ```

1. Rename the existing default branch to the new name (`main`). The argument `-m`
   transfers all commit history to the new branch:

   ```plaintext
   git branch -m master main
   ```

1. Push the newly created `main` branch upstream, and set your local branch to track
   the remote branch with the same name:

   ```plaintext
   git push -u origin main
   ```

1. If you plan to remove the old default branch, update `HEAD` to point to your new default branch, `main`:

   ```plaintext
   git symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main
   ```

1. Sign in to GitLab as an [administrator](../../../permissions.md) and follow
   the instructions to
   [change the default branch for this project](#change-the-default-branch-name-for-a-project).
   Select `main` as your new default branch.
1. Protect your new `main` branch as described in the [protected branches documentation](../../protected_branches.md).
1. (Optional) If you want to delete the old default branch:
   1. Verify that nothing is pointing to it.
   1. Delete the branch on the remote:

      ```plaintext
      git push origin --delete master
      ```

      You can delete the branch at a later time, after you confirm the new default branch is working as expected.

1. Notify your project contributors of this change, because they must also take some steps:

   - Contributors should pull the new default branch to their local copy of the repository.
   - Contributors with open merge requests that target the old default branch should manually
     re-point the merge requests to use `main` instead.
1. In your repository, update any references to the old branch name in your code.
1. Update references to the old branch name in related code and scripts that reside outside
   your repository, such as helper utilities and integrations.

## Default branch rename redirect

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/329100) in GitLab 14.1

URLs for specific files or directories in a project embed the project's default
branch name, and are often found in documentation or browser bookmarks. When you
[update the default branch name in your repository](#update-the-default-branch-name-in-your-repository),
these URLs change, and must be updated.

To ease the transition period, whenever the default branch for a project is
changed, GitLab records the name of the old default branch. If that branch is
deleted, attempts to view a file or directory on it are redirected to the
current default branch, instead of displaying the "not found" page.

## Resources

- [Discussion of default branch renaming](https://lore.kernel.org/git/pull.656.v4.git.1593009996.gitgitgadget@gmail.com/)
  on the Git mailing list
- [March 2021 blog post: The new Git default branch name](https://about.gitlab.com/blog/2021/03/10/new-git-default-branch-name/)
