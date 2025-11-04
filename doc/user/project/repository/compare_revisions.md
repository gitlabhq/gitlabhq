---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Compare branches, tags, and commits to view the differences between revisions in a repository.
title: Compare revisions
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Use **Compare revisions** to view the list of commits and files
changed between revisions.

You can compare:

- A branch to another branch.
- A tag to a branch or tag.
- A commit to another commit or branch.

## Compare methods

GitLab provides two methods to compare revisions:

- **Only incoming changes from source** (default): Displays differences from the source
  after the latest common commit on both revisions. This method excludes unrelated changes
  made to the target after the source was created. Use this to view only the changes introduced by
  the source revision.

  This method uses the `git diff <from>...<to>` Git command. It compares
  from the merge base (the common ancestor commit) to the target, instead of
  comparing the actual commits directly.

- **Include changes to target after source was created**: Displays all differences between
  the two revisions, including changes made to both the source and target. Use this to view the
  complete difference between two points in your repository's history.

  This method uses the `git diff <from> <to>` Git command. It compares the actual commits directly,
  displaying all changes between them.

## Compare branches, tags, or commits

To compare revisions:

1. On the left sidebar, select **Search or go to** and find your project. If you've [turned on the new navigation](../../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
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
1. Below **Show changes**, select either **Only incoming changes from source** (default) or
   **Include changes to target after source was created**.
1. Select **Compare**.
1. Optional. To reverse the **Source** and **Target**, select **Swap revisions**
   ({{< icon name="substitute" >}}).

The comparison page displays the list of commits and files changed between the revisions.

## Related topics

- [Branches](branches/_index.md)
- [Tags](tags/_index.md)
- [Commits](commits/_index.md)
- [Git commands](../../../topics/git/commands.md)
