---
stage: Create
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: index, reference
---

# Changes tab in merge requests

The **Changes** tab on a [merge request](index.md), below the main merge request details and next to the discussion tab,
shows the changes to files between branches or commits. This view of changes to a
file is also known as a **diff**. By default, the diff view compares the file in the
merge request branch and the file in the target branch.

The diff view includes the following:

- The file's name and path.
- The number of lines added and deleted.
- Buttons for the following options:
  - Toggle comments for this file; useful for inline reviews.
  - Edit the file in the merge request's branch.
  - Show full file, in case you want to look at the changes in context with the rest of the file.
  - View file at the current commit.
  - Preview the changes with [Review Apps](../../../ci/review_apps/index.md).
- The changed lines, with the specific changes highlighted.

![Example screenshot of a source code diff](img/merge_request_diff_v12_2.png)

## Merge request diff file navigation

When reviewing changes in the **Changes** tab, the diff can be navigated using
the file tree or file list. As you scroll through large diffs with many
changes, you can quickly jump to any changed file using the file tree or file
list.

![Merge request diff file navigation](img/merge_request_diff_file_navigation.png)

## Collapsed files in the Changes view

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/232820) in GitLab 13.4.

When you review changes in the **Changes** tab, files with a large number of changes are collapsed
to improve performance. When files are collapsed, a warning appears at the top of the changes.
Select **Expand file** on any file to view the changes for that file.

## File-by-file diff navigation

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/222790) in GitLab 13.2.
> - [Feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/issues/229848) in GitLab 13.7.

For larger merge requests, consider reviewing one file at a time. To enable this feature:

1. In the top-right corner, select your avatar.
1. Select **Preferences**.
1. Scroll to the **Behavior** section and select **Show one file at a time on merge request's Changes tab**.
1. Select **Save changes**.

After you enable this setting, GitLab displays only one file at a time in the **Changes** tab when you review merge requests. You can select **Prev** and **Next** to view other changed files.

![File-by-file diff navigation](img/file_by_file_v13_2.png)

In [GitLab 13.7](https://gitlab.com/gitlab-org/gitlab/-/issues/233898) and later, if you want to change
this behavior, you can do so from your **User preferences** (as explained above) or directly in a
merge request:

1. Go to the merge request's **Changes** tab.
1. Select the cog icon (**{settings}**) to reveal the merge request's settings dropdown.
1. Select or clear the checkbox **Show one file at a time** to change the setting accordingly.

This change overrides the choice you made in your user preferences and persists until you clear your
browser's cookies or change this behavior again.

## Merge requests commit navigation

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/18140) in GitLab 13.0.

To seamlessly navigate among commits in a merge request:

1. Select the **Commits** tab.
1. Select a commit to open it in the single-commit view.
1. Navigate through the commits by either:

   - Selecting **Prev** and **Next** buttons below the tab buttons.
   - Using the <kbd>X</kbd> and <kbd>C</kbd> keyboard shortcuts.

![Merge requests commit navigation](img/commit_nav_v13_11.png)

## Incrementally expand merge request diffs

By default, the diff shows only the parts of a file which are changed.
To view more unchanged lines above or below a change select the
**Expand up** or **Expand down** icons. You can also select **Show unchanged lines**
to expand the entire file.

![Incrementally expand merge request diffs](img/incrementally_expand_merge_request_diffs_v12_2.png)

In GitLab [versions 13.1 and later](https://gitlab.com/gitlab-org/gitlab/-/issues/205401), when viewing a
merge request's **Changes** tab, if a certain file was only renamed, you can expand it to see the
entire content by selecting **Show file contents**.

## Ignore whitespace changes in Merge Request diff view

If you select the **Hide whitespace changes** button, you can see the diff
without whitespace changes (if there are any). This is also working when on a
specific commit page.

![MR diff](img/merge_request_diff.png)

NOTE:
You can append `?w=1` while on the diffs page of a merge request to ignore any
whitespace changes.

## Mark files as viewed

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/51513) in GitLab 13.9.
> - Deployed behind a feature flag, enabled by default.
> - Enabled on GitLab.com.
> - Recommended for production use.
> - For GitLab self-managed instances, GitLab administrators can opt to [disable it](#enable-or-disable-file-views). **(FREE SELF)**

When reviewing a merge request with many files multiple times, it may be useful to the reviewer
to focus on new changes and ignore the files that they have already reviewed and don't want to
see anymore unless they are changed again.

To mark a file as viewed:

1. Go to the merge request's **Diffs** tab.
1. On the right-top of the file, locate the **Viewed** checkbox.
1. Select it to mark the file as viewed.

Once checked, the file remains marked for that reviewer unless there are newly introduced
changes to its content or the checkbox is unchecked.

### Enable or disable file views **(FREE SELF)**

The file view feature is under development but ready for production use.
It is deployed behind a feature flag that is **enabled by default**.
[GitLab administrators with access to the GitLab Rails console](../../../administration/feature_flags.md)
can opt to enable it for your instance.

To enable it:

```ruby
Feature.enable(:local_file_reviews)
```

To disable it:

```ruby
Feature.disable(:local_file_reviews)
```
