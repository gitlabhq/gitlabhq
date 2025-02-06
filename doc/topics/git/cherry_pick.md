---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "Cherry-pick a Git commit when you want to add a single commit from one branch to another."
title: Cherry-pick changes with Git
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Use `git cherry-pick` to apply the changes from a specific commit to your current
working branch. Use this command to:

- Backport bug fixes from the default branch to previous release branches.
- Copy changes from a fork to the upstream repository.
- Apply specific changes without merging entire branches.

You can also use the GitLab UI to cherry-pick. For more information,
see [Cherry-pick changes](../../user/project/merge_requests/cherry_pick_changes.md).

WARNING:
Use `git cherry-pick` carefully because it can create duplicate commits and potentially
complicate your project history.

## Cherry-pick a single commit

To cherry-pick a single commit from another branch into your current working branch:

1. Check out the branch you want to cherry-pick into:

   ```shell
   git checkout your_branch
   ```

1. Identify the Secure Hash Algorithm (SHA) of the commit you want to cherry-pick.
   To find this, check the commit history or use the `git log` command. For example:

   ```shell
   $ git log

   commit 0000011111222223333344444555556666677777
   Merge: 88888999999 aaaaabbbbbb
   Author: user@example.com
   Date:   Tue Aug 31 21:19:41 2021 +0000
    ```

1. Use the `git cherry-pick` command. Replace `<commit_sha>` with the SHA of
   the commit you identified:

   ```shell
   git cherry-pick <commit_sha>
   ```

Git applies the changes from the specified commit to your current working branch.
If there are conflicts, a notification is displayed. You can then resolve the
conflicts and continue the cherry-pick process.

## Cherry-pick multiple commits

To cherry-pick multiple commits from another branch into your current working branch:

1. Check out the branch you want to cherry-pick into:

   ```shell
   git checkout your_branch
   ```

1. Identify the Secure Hash Algorithm (SHA) of the commit you want to cherry-pick.
   To find this, check the commit history or use the `git log` command. For example:

   ```shell
   $ git log

   commit 0000011111222223333344444555556666677777
   Merge: 88888999999 aaaaabbbbbb
   Author: user@example.com
   Date:   Tue Aug 31 21:19:41 2021 +0000
    ```

1. Use the `git cherry-pick` command for each commit,
   replacing `<commit_sha>` with the SHA of the commit:

   ```shell
   git cherry-pick <commit_sha_1>
   git cherry-pick <commit_sha_2>
   ...
   ```

Alternatively, you can cherry-pick a range of commits using the `..` notation:

   ```shell
   git cherry-pick <start_commit_sha>..<end_commit_sha>
   ```

This applies all the commits between `<start_commit_sha>` and `<end_commit_sha>`
to your current working branch.

## Cherry-pick a merge commit

Cherry-picking a merge commit applies the changes from the merge commit to your current working branch.

To cherry-pick a merge commit from another branch into your current working branch:

1. Check out the branch you want to cherry-pick into:

   ```shell
   git checkout your_branch
   ```

1. Identify the Secure Hash Algorithm (SHA) of the commit you want to cherry-pick.
   To find this, check the commit history or use the `git log` command. For example:

   ```shell
   $ git log

   commit 0000011111222223333344444555556666677777
   Merge: 88888999999 aaaaabbbbbb
   Author: user@example.com
   Date:   Tue Aug 31 21:19:41 2021 +0000
    ```

1. Use the `git cherry-pick` command with the `-m` option and the index of the parent commit
   you want to use as the mainline. Replace `<commit_sha>` with the SHA of the merge commit
   and `<parent_index>` with the index of the parent commit. The index starts from `1`. For example:

   ```shell
   git cherry-pick -m 1 <merge-commit-hash>
   ```

This configures Git to use the first parent as the mainline. To use the second parent as the mainline, use `-m 2`.

## Related topics

- [Cherry-pick changes with the GitLab UI](../../user/project/merge_requests/cherry_pick_changes.md).
- [Commits API](../../api/commits.md#cherry-pick-a-commit)

## Troubleshooting

If you encounter conflicts during cherry-picking:

1. Resolve the conflicts manually in the affected files.
1. Stage the resolved files:

   ```shell
   git add <resolved_file>
   ```

1. Continue the cherry-pick process:

   ```shell
   git cherry-pick --continue
   ```

To abort the cherry-pick process and return to the previous state,
use the following command:

```shell
git cherry-pick --abort
```

This undoes any changes made during the cherry-pick process.
