---
stage: Create
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Merge conflicts **(FREE ALL)**

_Merge conflicts_ happen when the two branches in a merge request (the source and target) each have different
changes, and you must decide which change to accept. In a merge request, Git compares
the two versions of the files line by line. In most cases, GitLab can merge changes
together. However, if two branches both change the same lines, GitLab blocks the merge,
and you must choose which change you want to keep.

A merge request cannot merge until you either:

- Create a merge commit.
- Resolve the conflict through a rebase.

![Merge request widget](img/merge_request_widget.png)

## Conflicts you can resolve in the user interface

If your merge conflict meets all of the following conditions, you can resolve the
merge conflict in the GitLab user interface:

- The file is text, not binary.
- The file is in a UTF-8 compatible encoding.
- The file does not already contain conflict markers.
- The file, with conflict markers added, is less than 200 KB in size.
- The file exists under the same path in both branches.

If any file in your merge request contains conflicts, but can't meet all of these
criteria, you must resolve the conflict manually.

## Conflicts GitLab can't detect

GitLab does not detect conflicts when both branches rename a file to different names.
For example, these changes don't create a conflict:

1. On branch `a`, doing `git mv example.txt example1.txt`
1. On branch `b`, doing `git mv example1.txt example3.txt`.

When these branches merge, both `example1.txt` and `example3.txt` are present.

## Methods of resolving conflicts

GitLab shows [conflicts available for resolution](#conflicts-you-can-resolve-in-the-user-interface)
in the user interface, and you can also resolve conflicts locally through the command line:

- [Interactive mode](#resolve-conflicts-in-interactive-mode): UI method best for
  conflicts that only require you to select which version of a line to keep, without edits.
- [Inline editor](#resolve-conflicts-in-the-inline-editor): UI method best for more complex conflicts that require you to
  edit lines and manually blend changes together.
- [Command line](#resolve-conflicts-from-the-command-line): provides complete control over the most complex conflicts.

## Resolve conflicts in interactive mode

To resolve less-complex conflicts from the GitLab user interface:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Code > Merge requests** and find the merge request.
1. Select **Overview**, and scroll to the merge request reports section.
1. Find the merge conflicts message, and select **Resolve conflicts**.
   GitLab shows a list of files with merge conflicts. The conflicts are
   highlighted:

   ![Conflict section](img/conflict_section.png)
1. For each conflict, select **Use ours** or **Use theirs** to mark the version
   of the conflicted lines you want to keep. This decision is known as
   "resolving the conflict."
1. Enter a **Commit message**.
1. Select **Commit to source branch**.

Resolving conflicts merges the target branch of the merge request into the
source branch, using the version of the text you chose. If the source branch is
`feature` and the target branch is `main`, these actions are similar to running
`git switch feature; git merge main` locally.

## Resolve conflicts in the inline editor

Some merge conflicts are more complex, requiring you to manually modify lines to
resolve their conflicts. Use the merge conflict resolution editor to resolve complex
conflicts in the GitLab interface:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Code > Merge requests** and find the merge request.
1. Select **Overview**, and scroll to the merge request reports section.
1. Find the merge conflicts message, and select **Resolve conflicts**.
   GitLab shows a list of files with merge conflicts.
1. Select **Edit inline** to open the editor:
   ![Merge conflict editor](img/merge_conflict_editor.png)
1. After you resolve the conflict, enter a **Commit message**.
1. Select **Commit to source branch**.

## Resolve conflicts from the command line

While most conflicts can be resolved through the GitLab user interface, some are too complex.
Complex conflicts are best fixed locally, from the command line, to give you the
most control over each change:

1. Open the terminal and check out your feature branch. For example, `my-feature-branch`:

   ```shell
   git switch my-feature-branch
   ```

1. [Rebase your branch](../../../topics/git/git_rebase.md#rebase-by-using-git) against the
   target branch (here, `main`) so Git prompts you with the conflicts:

   ```shell
   git fetch
   git rebase origin/main
   ```

1. Open the conflicting file in your preferred code editor.
1. Find the conflict block:
   - It begins with the marker: `<<<<<<< HEAD`.
   - Next, it displays your changes.
   - The marker `=======` indicates the end of your changes.
   - Next, it displays the latest changes in the target branch.
   - The marker `>>>>>>>` indicates the end of the conflict.
1. Edit the file:
   1. Choose which version (before or after `=======`) you want to keep.
   1. Delete the version you don't want to keep.
   1. Delete the conflict markers.
1. Save the file.
1. Repeat the process for each file that contains conflicts.
1. Stage your changes in Git:

   ```shell
   git add .
   ```

1. Commit your changes:

   ```shell
   git commit -m "Fix merge conflicts"
   ```

1. Continue the rebase:

   ```shell
   git rebase --continue
   ```

   WARNING:
   Up to this point, you can run `git rebase --abort` to stop the process.
   Git aborts the rebase and rolls back the branch to the state you had before
   running `git rebase`.
   After you run `git rebase --continue`, you cannot abort the rebase.

1. [Force-push](../../../topics/git/git_rebase.md#force-pushing) the changes to your
   remote branch.

## Merge commit strategy

GitLab resolves conflicts by creating a merge commit in the source branch, but
does not merge it into the target branch. You can then review and test the
merge commit. Verify it contains no unintended changes and doesn't break your build.

## Related topics

- [Introduction to Git rebase and force-push](../../../topics/git/git_rebase.md)
- [Git applications for visualizing the Git workflow](https://git-scm.com/downloads/guis)

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that might go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, for example `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
