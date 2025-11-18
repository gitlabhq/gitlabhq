---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Your project's merge method determines whether to squash commits before merging, and if merge commits are created when work merges.
title: Merge methods
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

The merge method you select for your project determines how the changes in your
merge requests are merged into an existing branch.

The examples on this page assume a `main` branch with commits A, C, and E, and a
`feature` branch with commits B and D:

```mermaid
%%{init: { "fontFamily": "GitLab Sans" }}%%
gitGraph
   accTitle: Diagram of a merge
   accDescr: A Git graph of five commits on two branches, which will be expanded on in other graphs in this page.
   commit id: "A"
   branch feature
   commit id: "B"
   commit id: "D"
   checkout main
   commit id: "C"
   commit id: "E"
```

## Configure a project's merge method

1. On the left sidebar, select **Search or go to** and find your project. If you've [turned on the new navigation](../../../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Settings** > **Merge requests**.
1. Select your desired **Merge method** from these options:
   - Merge commit
   - Merge commit with semi-linear history
   - Fast-forward merge
1. In **Squash commits when merging**, select the default behavior for handling commits:
   - **Do not allow**: Squashing is never performed, and the user cannot change the behavior.
   - **Allow**: Squashing is off by default, but the user can change the behavior.
   - **Encourage**: Squashing is on by default, but the user can change the behavior.
   - **Require**: Squashing is always performed, and the user cannot change the behavior.
1. Select **Save changes**.

## Merge commit

By default, GitLab creates a merge commit when a branch is merged into `main`.
A separate merge commit is always created, regardless of whether or not commits
are [squashed when merging](../squash_and_merge.md). This strategy can result
in both a squash commit and a merge commit being added to your `main` branch.

These diagrams show how the `feature` branch merges into `main` if you use the
**Merge commit** strategy. They are equivalent to the command `git merge --no-ff <feature>`,
and selecting `Merge commit` as the **Merge method** in the GitLab UI:

- After a feature branch is merged with the **Merge commit** method, your `main` branch
looks like this:

  ```mermaid
  %%{init: { 'gitGraph': {'logLevel': 'debug', 'showBranches': true, 'showCommitLabel':true,'mainBranchName': 'main', 'fontFamily': 'GitLab Sans'}} }%%
  gitGraph
     accTitle: Diagram of a merge commit
     accDescr: A Git graph showing how merge commits are created in GitLab when a feature branch is merged.
     commit id: "A"
     branch feature
     commit id: "B"
     commit id: "D"
     checkout main
     commit id: "C"
     commit id: "E"
     merge feature
  ```

- In comparison, a squash merge constructs a squash commit, a virtual copy of all commits
from the `feature` branch. The original commits (B and D) remain unchanged
on the `feature` branch, and then a merge commit is made on the `main` branch to merge in the squashed branch:

  ```mermaid
  %%{init: { 'gitGraph': {'showBranches': true, 'showCommitLabel':true,'mainBranchName': 'main', 'fontFamily': 'GitLab Sans'}} }%%
  gitGraph
     accTitle: Diagram of of a squash merge
     accDescr: A Git graph showing repository and branch structure after a squash commit is added to the main branch.
     commit id:"A"
     branch feature
     checkout main
     commit id:"C"
     checkout feature
     commit id:"B"
     commit id:"D"
     checkout main
     commit id:"E"
     branch "B+D"
     commit id: "B+D"
     checkout main
     merge "B+D"
  ```

The squash merge graph is equivalent to these settings in the GitLab UI:

- **Merge method**: Merge commit.
- **Squash commits when merging** should be set to either:
  - Require.
  - Either Allow or Encourage, and squashing must be selected on the merge request.

The squash merge graph is also equivalent to these commands:

  ```shell
  git checkout `git merge-base feature main`
  git merge --squash feature
  git commit --no-edit
  SOURCE_SHA=`git rev-parse HEAD`
  git checkout main
  git merge --no-ff $SOURCE_SHA
  ```

## Merge commit with semi-linear history

A merge commit is created for every merge, but the branch is only merged if
a fast-forward merge is possible. This ensures that if the merge request build
succeeded, the target branch build also succeeds after the merge. An example
commit graph generated using this merge method:

```mermaid
%%{init: { "fontFamily": "GitLab Sans" }}%%
gitGraph
  accTitle: Diagram of a merge commit
  accDescr: Shows the flow of commits when a branch merges with a merge commit.
  commit id: "Init"
  branch mr-branch-1
  commit
  commit
  checkout main
  merge mr-branch-1
  branch mr-branch-2
  commit
  commit
  checkout main
  merge mr-branch-2
  commit
  branch squash-mr
  commit id: "Squashed commits"
  checkout main
  merge squash-mr
```

When you visit the merge request page with `Merge commit with semi-linear history`
method selected, you can accept it only if a fast-forward merge is possible.
When a fast-forward merge is not possible, the user is given the option to rebase, see
[Rebasing in (semi-)linear merge methods](#rebasing-in-semi-linear-merge-methods).

This method is equivalent to the same Git commands as in the **Merge commit** method. However,
if your source branch is based on an out-of-date version of the target branch (such as `main`),
you must rebase your source branch.
This merge method creates a cleaner-looking history, while still enabling you to
see where every branch began and was merged.

## Fast-forward merge

Sometimes, a workflow policy might mandate a clean commit history without
merge commits. In such cases, the fast-forward merge is appropriate. With
fast-forward merge requests, you can retain a linear Git history without
creating merge commits.

A fast-forward merge is only possible when the target branch (such as `main`) has not
diverged from the source branch's base commit. If the target branch has new commits
that aren't in the source branch, you must first rebase the source branch.

When the fast-forward merge
([`--ff-only`](https://git-scm.com/docs/git-merge#git-merge---ff-only)) setting
is enabled, merging is only allowed if the branch can be fast-forwarded.
If a fast-forward merge is not possible, you are provided the option to rebase.
For more information, see
[Rebasing in (semi-)linear merge methods](#rebasing-in-semi-linear-merge-methods).

### Without squashing

When squashing is disabled, all commits from the source branch are added directly
to the target branch, maintaining their individual commit history.

Before merge, with `main` at commit A and `feature` containing commits B, C, and D:

```mermaid
%%{init: { "fontFamily": "GitLab Sans" }}%%
gitGraph
  accTitle: Branch state before fast-forward merge
  accDescr: Shows main branch at commit A, with feature branch containing commits B, C, and D.
  commit id: "A (main)"
  branch feature
  commit id: "B"
  commit id: "C"
  commit id: "D"
```

After fast-forward merge, `main` now points to commit D, including all commits from the feature branch:

```mermaid
%%{init: { "fontFamily": "GitLab Sans" }}%%
gitGraph
  accTitle: Result after fast-forward merge without squashing
  accDescr: Shows linear history with all individual commits B, C, and D now on main branch.
  commit id: "A"
  commit id: "B"
  commit id: "C"
  commit id: "D (main)"
```

This method is equivalent to `git merge --ff-only <source-branch>`.

### With squashing

When squashing is enabled, all commits from the source branch are first combined
into a single commit, then fast-forwarded to the target branch.

Before merge, with `main` at commit A and `feature` containing commits B, C, and D:

```mermaid
%%{init: { "fontFamily": "GitLab Sans" }}%%
gitGraph
  accTitle: Branch state before fast-forward merge with squashing
  accDescr: Shows main branch at commit A, with feature branch containing commits B, C, and D.
  commit id: "A (main)"
  branch feature
  commit id: "B"
  commit id: "C"
  commit id: "D"
```

After fast-forward merge with squashing, `main` now includes a single commit containing all changes from B, C, and D:

```mermaid
%%{init: { "fontFamily": "GitLab Sans" }}%%
gitGraph
  accTitle: Result after fast-forward merge with squashing
  accDescr: Shows linear history with commits B, C, and D combined into one squashed commit on main branch.
  commit id: "A"
  commit id: "B+C+D (main)"
```

This method is equivalent to `git merge --squash <source-branch>` followed by `git commit`.

## Rebasing in (semi-)linear merge methods

In these merge methods, you can merge only when your source branch is up-to-date with the target branch:

- Merge commit with semi-linear history.
- Fast-forward merge.

If a fast-forward merge is not possible but a conflict-free rebase is possible,
GitLab provides:

- The [`/rebase` quick action](../conflicts.md#rebase).
- The option to select **Rebase** in the user interface.

You must rebase the source branch locally before a fast-forward merge if both
conditions are true:

- The target branch is ahead of the source branch.
- A conflict-free rebase is not possible.

Rebasing may be required before squashing, even though squashing can itself be
considered equivalent to rebasing.

### Rebase without CI/CD pipeline

To rebase a merge request's branch without triggering a CI/CD pipeline, select
**Rebase without pipeline** from the merge request reports section.

This option is:

- Available when fast-forward merge is not possible but a conflict-free rebase is possible.
- Not available when the **Pipelines must succeed** option is enabled.

Rebasing without a CI/CD pipeline saves resources in projects with a semi-linear
workflow that requires frequent rebases.

## Related topics

- [Squash and merge](../squash_and_merge.md)
