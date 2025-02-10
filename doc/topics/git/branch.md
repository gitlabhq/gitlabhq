---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Create a Git branch for your changes
---

A **branch** is a copy of the files in the repository at the time you create the branch.
You can work in your branch without affecting other branches. When
you're ready to add your changes to the main codebase, you can merge your branch into
the default branch, for example, `main`.

Use branches when you:

- Want to add code to a project but you're not sure if it works properly.
- Are collaborating on the project with others, and don't want your work to get mixed up.

## Create a branch

To create a branch:

```shell
git checkout -b <name-of-branch>
```

GitLab enforces [branch naming rules](../../user/project/repository/branches/_index.md#name-your-branch)
to prevent problems, and provides
[branch naming patterns](../../user/project/repository/branches/_index.md#prefix-branch-names-with-issue-numbers)
to streamline merge request creation.

## Switch to a branch

All work in Git is done in a branch.
You can switch between branches to see the state of the files and work in that branch.

To switch to an existing branch:

```shell
git checkout <name-of-branch>
```

For example, to change to the `main` branch:

```shell
git checkout main
```

## Keep a branch up-to-date

Your branch does not automatically include changes merged to the default branch from other branches.
To include changes merged after you created your branch, you must update your branch manually.

To update your branch with the latest changes in the default branch, either:

- Run `git rebase` to [rebase](git_rebase.md) your branch against the default branch. Use this command when you want
  your changes to be listed in Git logs after the changes from the default branch.
- Run `git pull <remote-name> <default-branch-name>`. Use this command when you want your changes to appear in Git logs
  in chronological order with the changes from the default branch, or if you're sharing your branch with others. If
  you're unsure of the correct value for `<remote-name>`, run: `git remote`.

## Related topics

- [Branches](../../user/project/repository/branches/_index.md)
- [Tags](../../user/project/repository/tags/_index.md)
