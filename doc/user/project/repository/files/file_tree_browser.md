---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Use the file tree browser to navigate repository files and directories.
title: File tree browser
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/19530) in GitLab 18.0 [with a flag](../../../../administration/feature_flags/_index.md) named `repository_file_tree_browser`. Disabled by default.
- [Enabled on GitLab.com, GitLab Self-Managed, and GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/issues/19530) in GitLab 18.9.

{{< /history >}}

> [!flag]
> The availability of this feature is controlled by a feature flag.
> For more information, see the history.

The file tree browser is a drawer that displays your repository's files and directories in
a collapsible tree structure. Use it to navigate your repository without scrolling
through long file listings.

The file tree browser helps you:

- Navigate nested directory structures.
- View the repository hierarchy.
- Switch between files while maintaining context of the directory structure.

## Show or hide the file tree browser

To show or hide the file tree browser:

1. On the top bar, select **Search or go to** and find your project.
1. Go to your repository files at `/<project>/-/tree/<branch>`.
1. In the upper-left corner, select the file tree browser icon ({{< icon name="file-tree" >}}).

You can also press <kbd>Shift</kbd>+<kbd>F</kbd> to toggle the file tree browser.

## Navigate files and directories

The file tree browser displays your repository's structure with files and directories you can
expand and collapse.

To navigate in the file tree browser:

1. Open the file tree browser. Either:

   - In the upper-left corner, select the file tree browser icon ({{< icon name="file-tree" >}}).
   - Press <kbd>Shift</kbd>+<kbd>F</kbd>.

1. To expand a directory, select {{< icon name="chevron-right" >}} next to the directory name.
1. To view a file, select the filename.

When you navigate directly to a nested file, the file tree browser automatically expands parent
directories and highlights the current file.

## Search files

Use the global search to find files by name in your repository.

To search files:

1. Open the file tree browser. Either:

   - In the upper-left corner, select the file tree browser icon ({{< icon name="file-tree" >}}).
   - Press <kbd>Shift</kbd>+<kbd>F</kbd>.

1. To open the global search dialog, select **Search files** or press <kbd>F</kbd>.
1. Enter part of the filename you want to find.
   The results list shows matching files and their parent directories.
1. Select or use the arrow keys and press <kbd>Enter</kbd> to go to a file.

If no files match your search, the search displays **No results found**.

## Keyboard shortcuts

The file tree browser supports these keyboard shortcuts:

| Shortcut                      | Action |
|-------------------------------|--------|
| <kbd>Shift</kbd>+<kbd>F</kbd> | Show or hide the file tree browser. |
| <kbd>F</kbd>                  | Open the global search dialog. |

For the full list of available keyboard shortcuts, see [GitLab keyboard shortcuts](../../../shortcuts.md).

### Tree navigation

The file tree browser implements the [W3C ARIA treeview pattern](https://www.w3.org/WAI/ARIA/apg/patterns/treeview/)
for keyboard navigation:

| Key                                                  | Function |
|------------------------------------------------------|----------|
| <kbd>Enter</kbd> or <kbd>Space</kbd>                 | Select the focused file or directory |
| <kbd>Down arrow</kbd>                                | Move focus to the next file or directory without opening or closing directories. Does nothing if focus is on the last item. |
| <kbd>Up arrow</kbd>                                  | Move focus to the previous file or directory without opening or closing directories. Does nothing if focus is on the first item. |
| <kbd>Right arrow</kbd>                               | When focus is on a closed directory, open it. When focus is on an open directory, move focus to the first item inside. Does nothing if focus is on a file. |
| <kbd>Left arrow</kbd>                                | When focus is on an open directory, close it. When focus is on a file or nested item, move focus to its parent directory. Does nothing if focus is on a closed root directory. |
| <kbd>Home</kbd> <sup>1</sup>                                     | Move focus to the first file or directory without opening or closing directories. |
| <kbd>End</kbd> <sup>1</sup>                                       | Move focus to the last file or directory without expanding closed directories. |
| <kbd>a</kbd>-<kbd>z</kbd>, <kbd>A</kbd>-<kbd>Z</kbd> | Move focus to the next file or directory with a name starting with the typed character. Search wraps to the first item if no match is found. Ignores items inside closed directories. |
| <kbd>*</kbd> (asterisk)                              | Expand all closed directories at the same level as the focused item. Focus does not move. |

**Footnotes**:

1. <kbd>Home</kbd> and <kbd>End</kbd> keys might not be available on all keyboards.

## Related topics

- [Web Editor](../web_editor.md)
- [Git file history](git_history.md)
- [Git file blame](git_blame.md)
