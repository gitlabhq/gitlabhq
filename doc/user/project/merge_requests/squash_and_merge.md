---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Squash and merge **(FREE)**

As you work on a feature branch, you often create small, self-contained commits. These small commits
help describe the process of building a feature, but can clutter your Git history after the feature
is finished. As you finish features, you can combine these commits and ensure a cleaner merge history
in your Git repository by using the _squash and merge_ strategy.

- Small commits are joined together, making it simpler to [revert all parts of a change](revert_changes.md).
- When the single commit merges into the target branch, it retains the full commit history.
- Your base branch remains clean, and contains meaningful commit messages.

Each time a branch merges into your base branch, up to two commits are added:

- The single commit created by squashing the commits from the branch.
- A merge commit, unless you have enabled [fast-forward merges](methods/index.md#fast-forward-merge)
  in your project. Fast-forward merges disable merge commits.

By default, squashed commits contain the following metadata:

- Message: Description of the squash commit, or a customized message
- Author: User that created the merge request
- Committer: User who initiated the squash

Project owners can [create new default messages](commit_templates.md) for all
squash commits and merge commits.

## Set default squash options for a merge request

Users with permission to create or edit a merge request can set the default squash options
for a merge request.

Prerequisites:

- Your project must be [configured](#configure-squash-options-for-a-project) to allow or
  encourage squashing.

To do this:

1. Go to the merge request and select **Edit**.
1. Select or clear the **Squash commits when merge request is accepted** checkbox.
1. Select **Save changes**.

## Squash commits in a merge request

If your project allows you to select squashing options for merge requests, to
squash the commits as part of the merge process:

1. Go to the merge request, and scroll to the merge request reports section that
   contains the **Merge** button.
1. Ensure the **Squash commits** checkbox is selected. This checkbox doesn't display
   if the project's squashing option is set to either **Do not allow** or **Require**.
1. Optional. To modify either the squash commit message or the merge commit message
   (depending on your project configuration), select **Modify commit messages**.
1. When the merge request is ready to merge, select **Merge**.

## Configure squash options for a project

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/17613) in GitLab 13.2 [with a flag](../../../administration/feature_flags.md) named `squash_options`, disabled by default.
> - [Enabled on GitLab.com and self-managed by default](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/39382) in GitLab 13.3.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/232536) in GitLab 13.8. Feature flag `squash_options` removed.

Prerequisites:

- You must have at least the Maintainer role for this project.

To configure the default squashing behavior for all merge requests in your project:

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Settings > Merge requests**.
1. In the **Squash commits when merging** section, select your desired behavior:
   - **Do not allow**: Squashing is never performed, and the option is not displayed.
   - **Allow**: Squashing is allowed, but cleared by default.
   - **Encourage**: Squashing is allowed and selected by default, but can be disabled.
   - **Require**: Squashing is always performed. While merge requests display the option
     to squash, users cannot change it.
1. Select **Save changes**.

## Related topics

- [Commit message templates](commit_templates.md)
- [Merge methods](methods/index.md)

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, for example `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
