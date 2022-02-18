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

## View merge request commits in context

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/29274) in GitLab 13.12 [with a flag](../../../administration/feature_flags.md) named `context_commits`. Enabled by default.
> - [Enabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/320757) in GitLab 14.8.

WARNING:
This feature is in [beta](../../../policy/alpha-beta-support.md#beta-features)
and is [incomplete](https://gitlab.com/groups/gitlab-org/-/epics/1192).

FLAG:
On self-managed GitLab, by default this feature is available. To hide the feature,
ask an administrator to [disable the feature flag](../../../administration/feature_flags.md) named `context_commits`.
On GitLab.com, this feature is available.

When reviewing a merge request, it helps to have more context about the changes
made. That includes unchanged lines in unchanged files, and previous commits
that have already merged that the change is built on.

To add previously merged commits to a merge request for more context:

1. Go to your merge request.
1. Select the **Commits** tab.
1. Scroll to the end of the list of commits, and select **Add previously merged commits**:

   ![Add previously merged commits button](img/add_previously_merged_commits_button_v14_1.png)

1. Select the commits that you want to add.
1. Select **Save changes**.

To view the changes done on those previously merged commits:

1. On your merge request, select the **Changes** tab.
1. Scroll to **(file-tree)** **Compare** and select **previously merged commits**:

   ![Previously merged commits](img/previously_merged_commits_v14_1.png)
