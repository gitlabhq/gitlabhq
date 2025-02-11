---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments"
description: "Use Git branches to develop new features. Add branch protections to critical branches to ensure only trusted users can merge into them."
title: Default branch
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

When you create a new [project](../../_index.md), GitLab creates a default branch
in the repository. A default branch has special configuration options not shared
by other branches:

- It cannot be deleted.
- It's [initially protected](protected.md) against
  forced pushes.
- When a merge request uses an
  [issue closing pattern](../../issues/managing_issues.md#closing-issues-automatically)
  to close an issue, the work is merged into this branch.

The name of your [new project's](../../_index.md) default branch depends on any
configuration changes made to your instance or group by your GitLab administrator.
GitLab checks first for specific customizations, then checks at a broader level,
using the GitLab default only if no customizations are set:

1. A [project-specific](#change-the-default-branch-name-for-a-project) custom default branch name.
1. [Custom group default branch name](#group-level-custom-initial-branch-name) specified in project's direct subgroup.
1. [Custom group default branch name](#group-level-custom-initial-branch-name) specified in project's top-level group.
1. A custom default branch name set for the [instance](#instance-level-custom-initial-branch-name).
1. If no custom default branch name is set at any level, GitLab defaults to `main`.

In the GitLab UI, you can change the defaults at any level. GitLab also provides
the [Git commands you need](#update-the-default-branch-name-in-your-repository) to update your copy of the repository.

## Change the default branch name for a project

Prerequisites:

- You have the Owner or Maintainer role for the project.

To update the default branch for an individual [project](../../_index.md):

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > Repository**.
1. Expand **Branch defaults**. For **Default branch**, select a new default branch.
1. Optional. Select the **Auto-close referenced issues on default branch** checkbox to close
   issues when a merge request
   [uses a closing pattern](../../issues/managing_issues.md#closing-issues-automatically).
1. Select **Save changes**.

API users can also use the `default_branch` attribute of the
[Projects API](../../../../api/projects.md) when creating or editing a project.

## Change the default branch name for an instance or group

GitLab administrators can configure a new default branch name for the
[entire instance](#instance-level-custom-initial-branch-name) or for
[individual groups](#group-level-custom-initial-branch-name).

### Instance-level custom initial branch name

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed, GitLab Dedicated

[Administrators](../../../permissions.md) of GitLab Self-Managed can
customize the initial branch for projects hosted on that instance. Individual
groups and subgroups can override the instance default for their projects.

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > Repository**.
1. Expand **Default branch**.
1. For **Initial default branch name**, select a new default branch.
1. Select **Save changes**.

Projects created on this instance after you change the setting use the
custom branch name, unless a group or subgroup configuration
overrides it.

### Group-level custom initial branch name

Users with the Owner role of groups and subgroups can configure the default branch name for a group:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > Repository**.
1. Expand **Default branch**.
1. For **Initial default branch name**, select a new default branch.
1. Select **Save changes**.

Projects created in this group after you change the setting use the custom branch name,
unless a subgroup configuration overrides it.

## Protect initial default branches

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

> - Full protection after initial push [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/118729) in GitLab 16.0.

GitLab administrators and group owners can define [branch protections](protected.md)
to apply to every repository's default branch
[for the instance](#instance-level-default-branch-protection) and
[individual groups](#group-level-default-branch-protection) with one of the following options:

- **Fully protected** - Default value. Developers cannot push new commits, but maintainers can.
  No one can force push.
- **Fully protected after initial push** - Developers can push the initial commit
  to a repository, but none afterward. Maintainers can always push. No one can force push.
- **Protected against pushes** - Developers cannot push new commits, but are
  allowed to accept merge requests to the branch. Maintainers can push to the branch.
- **Partially protected** - Both developers and maintainers can push new commits,
  but cannot force push.
- **Not protected** - Both developers and maintainers can push new commits
  and force push.

WARNING:
Unless **Fully protected** is chosen, a malicious developer could attempt to steal your sensitive data. For example, a malicious `.gitlab-ci.yml` file could be committed to a protected branch and later, if a pipeline is run against that branch, result in exfiltration of group CI/CD variables.

### Instance-level default branch protection

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed, GitLab Dedicated

This setting applies only to each repository's default branch. To protect other branches,
you must either:

- Configure [branch protection in the repository](protected.md).
- Configure [branch protection for groups](../../../group/manage.md#change-the-default-branch-protection-of-a-group).

Administrators of GitLab Self-Managed instances can customize the initial default branch protection for projects hosted on that instance. Individual
groups and subgroups can override the instance default setting for their projects.

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > Repository**.
1. Expand **Default branch**.
1. Select [**Initial default branch protection**](#protect-initial-default-branches).
1. To allow group owners to override the instance's default branch protection, select
   [**Allow owners to manage default branch protection per group**](#prevent-overrides-of-default-branch-protection).
1. Select **Save changes**.

#### Prevent overrides of default branch protection

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab Self-Managed, GitLab Dedicated

Group owners can override protections for default branches set for an entire instance
on a per-group basis. In
[GitLab Premium or Ultimate](https://about.gitlab.com/pricing/), GitLab administrators can
disable this privilege for group owners, enforcing the protection rule set for the instance:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > Repository**.
1. Expand the **Default branch** section.
1. Clear the **Allow owners to manage default branch protection per group** checkbox.
1. Select **Save changes**.

NOTE:
GitLab administrators can still update the default branch protection of a group.

### Group-level default branch protection

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Group owners can override protections for default branches set for an entire instance
on a per-group basis. In
[GitLab Premium or Ultimate](https://about.gitlab.com/pricing/), GitLab administrators can
[enforce protection of initial default branches](#prevent-overrides-of-default-branch-protection)
which locks this setting for group owners.

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > Repository**.
1. Expand **Default branch**.
1. Select [**Initial default branch protection**](#protect-initial-default-branches).
1. Select **Save changes**.

## Update the default branch name in your repository

WARNING:
Changing the name of your default branch can potentially break tests,
CI/CD configuration, services, helper utilities, and any integrations your repository
uses. Before you change this branch name, consult with your project owners and maintainers.
Ensure they understand the scope of this change includes references to the old
branch name in related code and scripts.

When you change the default branch name for an existing repository, don't create a new branch.
Preserve the history of your default branch by renaming it. This example renames a Git repository's
(`example`) default branch:

1. On your local command line, go to your `example` repository, and ensure
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

1. Sign in to GitLab with at least the Maintainer
   role and follow the instructions to
   [change the default branch for this project](#change-the-default-branch-name-for-a-project).
   Select `main` as your new default branch.
1. Protect your new `main` branch as described in the [protected branches documentation](protected.md).
1. Optional. If you want to delete the old default branch:
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

URLs for specific files or directories in a project embed the project's default
branch name, and are often found in documentation or browser bookmarks. When you
[update the default branch name in your repository](#update-the-default-branch-name-in-your-repository),
these URLs change, and must be updated.

To ease the transition period, whenever the default branch for a project is
changed, GitLab records the name of the old default branch. If that branch is
deleted, attempts to view a file or directory on it are redirected to the
current default branch, instead of displaying the "not found" page.

## Related topics

- [Configure a default branch for your wiki](../../wiki/_index.md)
- [Discussion of default branch renaming](https://lore.kernel.org/git/pull.656.v4.git.1593009996.gitgitgadget@gmail.com/)
  on the Git mailing list
- [March 2021 blog post: The new Git default branch name](https://about.gitlab.com/blog/2021/03/10/new-git-default-branch-name/)

## Troubleshooting

### Unable to change default branch: resets to current branch

We are tracking this problem in [issue 20474](https://gitlab.com/gitlab-org/gitlab/-/issues/20474).
This issue often occurs when a branch named `HEAD` is present in the repository.
To fix the problem:

1. In your local repository, create a new temporary branch and push it:

   ```shell
   git checkout -b tmp_default && git push -u origin tmp_default
   ```

1. In GitLab, proceed to [change the default branch](#change-the-default-branch-name-for-a-project) to that temporary branch.
1. From your local repository, delete the `HEAD` branch:

   ```shell
   git push -d origin HEAD
   ```

1. In GitLab, [change the default branch](#change-the-default-branch-name-for-a-project) to the one you intend to use.

### Query GraphQL for default branches

You can use a [GraphQL query](../../../../api/graphql/_index.md)
to retrieve the default branches for all projects in a group.

To return all projects in a single page of results, replace `GROUPNAME` with the
full path to your group. GitLab returns the first page of results. If `hasNextPage`
is `true`, you can request the next page by replacing the `null` in `after: null`
with the value of `endCursor`:

```graphql
{
 group(fullPath: "GROUPNAME") {
   projects(after: null) {
     pageInfo {
       hasNextPage
       endCursor
     }
     nodes {
       name
       repository {
         rootRef
       }
     }
   }
 }
}
```

### New subgroups do not inherit default branch name from a higher-level subgroup

When you configured a default branch in a subgroup that contains another subgroup that contains a project,
the default branch is not inherited.

We are tracking this problem in [issue 327208](https://gitlab.com/gitlab-org/gitlab/-/issues/327208).
