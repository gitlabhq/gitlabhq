---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Create a Git branch for your changes

A **branch** is a copy of the files in the repository at the time you create the branch.
You can work in your branch without affecting other branches. When
you're ready to add your changes to the main codebase, you can merge your branch into
the default branch, for example, `main`.

Use branches when you:

- Want to add code to a project but you're not sure if it works properly.
- Are collaborating on the project with others, and don't want your work to get mixed up.

A new branch is often called **feature branch** to differentiate from the
[default branch](../../user/project/repository/branches/default.md).

## Create a branch

To create a feature branch:

```shell
git checkout -b <name-of-branch>
```

GitLab enforces [branch naming rules](../../user/project/repository/branches/index.md#name-your-branch)
to prevent problems, and provides
[branch naming patterns](../../user/project/repository/branches/index.md#prefix-branch-names-with-issue-numbers)
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
