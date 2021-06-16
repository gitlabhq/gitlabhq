---
stage: Create
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: index, reference
---

# Commits tab in merge requests **(FREE)**

The **Commits** tab in a merge request displays a sequential list of commits
to the Git branch your merge request is based on. From this page, you can review
full commit messages and copy a commit's SHA when you need to
[cherry-pick changes](cherry_pick_changes.md).

## Merge requests commit navigation

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/18140) in GitLab 13.0.

To seamlessly navigate among commits in a merge request:

1. Select the **Commits** tab.
1. Select a commit to open it in the single-commit view.
1. Navigate through the commits by either:

   - Selecting **Prev** and **Next** buttons below the tab buttons.
   - Using the <kbd>X</kbd> and <kbd>C</kbd> keyboard shortcuts.

![Merge requests commit navigation](img/commit_nav_v13_11.png)
