---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference
disqus_identifier: 'https://docs.gitlab.com/ee/workflow/shortcuts.html'
---

# GitLab keyboard shortcuts

GitLab has many useful keyboard shortcuts to make it easier to access different features.
You can see a modal listing keyboard shortcuts within GitLab itself by pressing <kbd>?</kbd>,
or clicking **Keyboard shortcuts** in the Help menu at the top right.
In [GitLab 12.8 and later](https://gitlab.com/gitlab-org/gitlab/-/issues/22113),
keyboard shortcuts can be disabled using the **Enable**/**Disable** toggle in this modal window.

The [Global Shortcuts](#global-shortcuts) work from any area of GitLab, but you must
be in specific pages for the other shortcuts to be available, as explained in each
section below.

## Global Shortcuts

These shortcuts are available in most areas of GitLab

| Keyboard Shortcut               | Description |
| ------------------------------- | ----------- |
| <kbd>?</kbd>                    | Show/hide shortcut reference sheet. |
| <kbd>Shift</kbd> + <kbd>p</kbd> | Go to your Projects page. |
| <kbd>Shift</kbd> + <kbd>g</kbd> | Go to your Groups page. |
| <kbd>Shift</kbd> + <kbd>a</kbd> | Go to your Activity page. |
| <kbd>Shift</kbd> + <kbd>l</kbd> | Go to your Milestones page. |
| <kbd>Shift</kbd> + <kbd>s</kbd> | Go to your Snippets page. |
| <kbd>s</kbd> / <kbd>/</kbd>     | Put cursor in the search bar. |
| <kbd>Shift</kbd> + <kbd>i</kbd> | Go to your Issues page. |
| <kbd>Shift</kbd> + <kbd>m</kbd> | Go to your Merge requests page.|
| <kbd>Shift</kbd> + <kbd>t</kbd> | Go to your To-Do List page. |
| <kbd>p</kbd> + <kbd>b</kbd>     | Show/hide the Performance Bar. |

Additionally, the following shortcuts are available when editing text in text fields,
for example comments, replies, issue descriptions, and merge request descriptions:

| Keyboard Shortcut                                                      | Description |
| ---------------------------------------------------------------------- | ----------- |
| <kbd>↑</kbd>                                                           | Edit your last comment. You must be in a blank text field below a thread, and you must already have at least one comment in the thread. |
| <kbd>⌘</kbd> (Mac) / <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>p</kbd> | Toggle Markdown preview, when editing text in a text field that has **Write** and **Preview** tabs at the top. |
| <kbd>⌘</kbd> (Mac) / <kbd>Ctrl</kbd> + <kbd>b</kbd>                    | Bold the selected text (surround it with `**`). |
| <kbd>⌘</kbd> (Mac) / <kbd>Ctrl</kbd> + <kbd>i</kbd>                    | Italicize the selected text (surround it with `_`). |
| <kbd>⌘</kbd> (Mac) / <kbd>Ctrl</kbd> + <kbd>k</kbd>                    | Add a link (surround the selected text with `[]()`). |

NOTE: **Note:**
The shortcuts for editing in text fields are always enabled, even when
other keyboard shortcuts are disabled as explained above.

## Project

These shortcuts are available from any page within a project. You must type them
relatively quickly to work, and they take you to another page in the project.

| Keyboard Shortcut           | Description |
| --------------------------- | ----------- |
| <kbd>g</kbd> + <kbd>p</kbd> | Go to the project home page (**Project > Details**). |
| <kbd>g</kbd> + <kbd>v</kbd> | Go to the project activity feed (**Project > Activity**). |
| <kbd>g</kbd> + <kbd>r</kbd> | Go to the project releases list (**Project > Releases**). |
| <kbd>g</kbd> + <kbd>f</kbd> | Go to the [project files](#project-files) list (**Repository > Files**). |
| <kbd>t</kbd>                | Go to the project file search page. (**Repository > Files**, click **Find Files**). |
| <kbd>g</kbd> + <kbd>c</kbd> | Go to the project commits list (**Repository > Commits**). |
| <kbd>g</kbd> + <kbd>n</kbd> | Go to the [repository graph](#repository-graph) page (**Repository > Graph**). |
| <kbd>g</kbd> + <kbd>d</kbd> | Go to repository charts (**Analytics > Repository Analytics**). |
| <kbd>g</kbd> + <kbd>i</kbd> | Go to the project issues list (**Issues > List**). |
| <kbd>i</kbd>                | Go to the New Issue page (**Issues**, click **New Issue** ). |
| <kbd>g</kbd> + <kbd>b</kbd> | Go to the project issue boards list (**Issues > Boards**). |
| <kbd>g</kbd> + <kbd>m</kbd> | Go to the project merge requests list (**Merge Requests**). |
| <kbd>g</kbd> + <kbd>j</kbd> | Go to the CI/CD jobs list (**CI/CD > Jobs**). |
| <kbd>g</kbd> + <kbd>l</kbd> | Go to the project metrics (**Operations > Metrics**). |
| <kbd>g</kbd> + <kbd>e</kbd> | Go to the project environments (**Operations > Environments**). |
| <kbd>g</kbd> + <kbd>k</kbd> | Go to the project Kubernetes cluster integration page (**Operations > Kubernetes**). Note that you must have at least [`maintainer` permissions](permissions.md) to access this page. |
| <kbd>g</kbd> + <kbd>s</kbd> | Go to the project snippets list (**Snippets**). |
| <kbd>g</kbd> + <kbd>w</kbd> | Go to the project wiki (**Wiki**), if enabled. |

### Issues and Merge Requests

These shortcuts are available when viewing issues and merge requests.

| Keyboard Shortcut            | Description |
| ---------------------------- | ----------- |
| <kbd>e</kbd>                 | Edit description. |
| <kbd>a</kbd>                 | Change assignee. |
| <kbd>m</kbd>                 | Change milestone. |
| <kbd>l</kbd>                 | Change label. |
| <kbd>r</kbd>                 | Start writing a comment. If any text is selected, it is quoted in the comment. Can't be used to reply within a thread. |
| <kbd>n</kbd>                 | Move to next unresolved discussion (merge requests only). |
| <kbd>p</kbd>                 | Move to previous unresolved discussion (merge requests only). |
| <kbd>]</kbd> or <kbd>j</kbd> | Move to next file (merge requests only). |
| <kbd>[</kbd> or <kbd>k</kbd> | Move to previous file (merge requests only). |
| <kbd>b</kbd>                 | Copy source branch name (merge requests only). |

### Project Files

These shortcuts are available when browsing the files in a project (navigate to
**Repository** > **Files**):

| Keyboard Shortcut | Description |
| ----------------- | ----------- |
| <kbd>↑</kbd>      | Move selection up. |
| <kbd>↓</kbd>      | Move selection down. |
| <kbd>enter</kbd>  | Open selection. |
| <kbd>esc</kbd>    | Go back to file list screen (only while searching for files, **Repository > Files** then click on **Find File**). |
| <kbd>y</kbd>      | Go to file permalink (only while viewing a file). |

### Web IDE

These shortcuts are available when editing a file with the [Web IDE](project/web_ide/index.md):

| Keyboard Shortcut                                       | Description |
| ------------------------------------------------------- | ----------- |
| <kbd>⌘</kbd> (Mac) / <kbd>Ctrl</kbd> + <kbd>p</kbd>     | Search for, and then open another file for editing. |
| <kbd>⌘</kbd> (Mac) / <kbd>Ctrl</kbd> + <kbd>Enter</kbd> | Commit (when editing the commit message). |

### Repository Graph

These shortcuts are available when viewing the project [repository graph](project/repository/index.md#repository-graph)
page (navigate to **Repository > Graph**):

| Keyboard Shortcut                                                  | Description |
| ------------------------------------------------------------------ | ----------- |
| <kbd>←</kbd> or <kbd>h</kbd>                                       | Scroll left. |
| <kbd>→</kbd> or <kbd>l</kbd>                                       | Scroll right. |
| <kbd>↑</kbd> or <kbd>k</kbd>                                       | Scroll up. |
| <kbd>↓</kbd> or <kbd>j</kbd>                                       | Scroll down. |
| <kbd>Shift</kbd> + <kbd>↑</kbd> or <kbd>Shift</kbd> + <kbd>k</kbd> | Scroll to top. |
| <kbd>Shift</kbd> + <kbd>↓</kbd> or <kbd>Shift</kbd> + <kbd>j</kbd> | Scroll to bottom. |

### Wiki pages

This shortcut is available when viewing a [wiki page](project/wiki/index.md):

| Keyboard Shortcut | Description |
| ----------------- | ----------- |
| <kbd>e</kbd>      | Edit wiki page. |

### Filtered Search

These shortcuts are available when using a [filtered search input](search/index.md):

| Keyboard Shortcut                                     | Description |
| ----------------------------------------------------- | ----------- |
| <kbd>⌘</kbd> (Mac) + <kbd>⌫</kbd>                     | Clear entire search filter. |
| <kbd>⌥</kbd> (Mac) / <kbd>Ctrl</kbd> + <kbd>⌫</kbd>   | Clear one token at a time. |

## Epics **(ULTIMATE)**

These shortcuts are available when viewing [Epics](group/epics/index.md):

| Keyboard Shortcut | Description |
| ----------------- | ----------- |
| <kbd>r</kbd>      | Start writing a comment. If any text is selected, it is quoted in the comment. Can't be used to reply within a thread. |
| <kbd>e</kbd>      | Edit description. |
| <kbd>l</kbd>      | Change label. |
