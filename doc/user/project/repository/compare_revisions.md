---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Compare branches, tags, and commits to view the differences between revisions in a repository.
title: Compare revisions
---

Compare branches, tags, or commits to view the differences between revisions in a repository.
You can compare a branch, tag, or commit to another branch or commit.

To compare revisions:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Code** > **Compare revisions**.
1. Select the **Source** revision:
   - To search for a branch, enter the branch name. Exact matches are shown first.
   - To search for a tag, enter the tag name.
   - To search for a commit, enter the commit SHA.
   - To refine your search with operators:
     - `^` matches the beginning of the name: `^feat` matches `feat/user-authentication`.
     - `$` matches the end of the name: `widget$` matches `feat/search-box-widget`.
     - `*` matches using a wildcard: `branch*cache*` matches `fix/branch-search-cache-expiration`.
     - You can combine operators: `^chore/*migration$` matches `chore/user-data-migration`.
1. Select the **Target** repository and revision.
1. Below **Show changes**, select how to compare the revisions:
   <!-- vale gitlab_base.SubstitutionWarning = NO -->
   <!-- Disable Vale gitlab_base.SubstitutionWarning rule so that Vale doesn't flag "since" -->
   - **Only incoming changes from source** (default) shows differences from the source
     since the latest common commit on both revisions.
     It doesn't include unrelated changes made to the target after the source was created.
     This method uses the `git diff <from>...<to>`
     [Git command](../../../topics/git/commands.md).
     To compare revisions, this method uses the merge base instead of the actual commit, so
     changes from cherry-picked commits are shown as new changes.
   - **Include changes to target since source was created** shows all differences between
     the two revisions.
     This method uses the `git diff <from> <to>`
     [Git command](../../../topics/git/commands.md).
   <!-- vale gitlab_base.SubstitutionWarning = YES -->
1. Select **Compare**.
1. Optional. To reverse the **Source** and **Target**, select **Swap revisions**
   ({{< icon name="substitute" >}}).

The comparison page displays the list of commits and changed files between the revisions.

## Related topics

- [Branches](branches/_index.md)
- [Tags](tags/_index.md)
- [Commits](commits/_index.md)
