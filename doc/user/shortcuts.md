---
stage: Create
group: Editor
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference
disqus_identifier: 'https://docs.gitlab.com/ee/workflow/shortcuts.html'
---

# GitLab keyboard shortcuts **(FREE)**

GitLab has several keyboard shortcuts you can use to access its different
features.

To display a window in GitLab that lists its keyboard shortcuts, use one of the
following methods:

- Press <kbd>?</kbd>.
- In the Help menu in the top right of the application, select **Keyboard shortcuts**.

Although [global shortcuts](#global-shortcuts) work from any area of GitLab,
you must be in specific pages for the other shortcuts to be available, as
explained in each section.

## Global shortcuts

These shortcuts are available in most areas of GitLab:

| Keyboard shortcut               | Description |
|---------------------------------|-------------|
| <kbd>?</kbd>                    | Show or hide the shortcut reference sheet. |
| <kbd>Shift</kbd> + <kbd>p</kbd> | Go to your Projects page. |
| <kbd>Shift</kbd> + <kbd>g</kbd> | Go to your Groups page. |
| <kbd>Shift</kbd> + <kbd>a</kbd> | Go to your Activity page. |
| <kbd>Shift</kbd> + <kbd>l</kbd> | Go to your Milestones page. |
| <kbd>Shift</kbd> + <kbd>s</kbd> | Go to your Snippets page. |
| <kbd>s</kbd> / <kbd>/</kbd>     | Put cursor in the search bar. |
| <kbd>Shift</kbd> + <kbd>i</kbd> | Go to your Issues page. |
| <kbd>Shift</kbd> + <kbd>m</kbd> | Go to your [Merge requests](project/merge_requests/index.md) page. |
| <kbd>Shift</kbd> + <kbd>t</kbd> | Go to your To-Do List page. |
| <kbd>p</kbd> then <kbd>b</kbd>     | Show or hide the Performance Bar. |
| <kbd>g</kbd> then <kbd>x</kbd>     | Toggle between [GitLab](https://gitlab.com/) and [GitLab Next](https://next.gitlab.com/) (GitLab SaaS only). |
| <kbd>.</kbd>                    | Open the [Web IDE](project/web_ide/index.md). |

Additionally, the following shortcuts are available when editing text in text
fields (for example, comments, replies, issue descriptions, and merge request
descriptions):

| macOS shortcut | Windows shortcut | Description |
|----------------|------------------|-------------|
| <kbd>↑</kbd>   | <kbd>↑</kbd>     | Edit your last comment. You must be in a blank text field below a thread, and you must already have at least one comment in the thread. |
| <kbd>Command</kbd> + <kbd>Shift</kbd> + <kbd>p</kbd> | <kbd>Control</kbd> + <kbd>Shift</kbd> + <kbd>p</kbd> | Toggle Markdown preview when editing text in a text field that has **Write** and **Preview** tabs at the top. |
| <kbd>Command</kbd> + <kbd>b</kbd>       | <kbd>Control</kbd> + <kbd>b</kbd> | Bold the selected text (surround it with `**`). |
| <kbd>Command</kbd> + <kbd>i</kbd>       | <kbd>Control</kbd> + <kbd>i</kbd> | Italicize the selected text (surround it with `_`). |
| <kbd>Command</kbd> + <kbd>k</kbd>       | <kbd>Control</kbd> + <kbd>k</kbd> | Add a link (surround the selected text with `[]()`). |

The shortcuts for editing in text fields are always enabled, even if other
keyboard shortcuts are disabled.

## Project

These shortcuts are available from any page in a project. You must type them
relatively quickly to work, and they take you to another page in the project.

| Keyboard shortcut           | Description |
|-----------------------------|-------------|
| <kbd>g</kbd> + <kbd>p</kbd> | Go to the project home page (**Project > Details**). |
| <kbd>g</kbd> + <kbd>v</kbd> | Go to the project activity feed (**Project > Activity**). |
| <kbd>g</kbd> + <kbd>r</kbd> | Go to the project releases list (**Project > Releases**). |
| <kbd>g</kbd> + <kbd>f</kbd> | Go to the [project files](#project-files) list (**Repository > Files**). |
| <kbd>t</kbd>                | Go to the project file search page. (**Repository > Files**, select **Find Files**). |
| <kbd>g</kbd> + <kbd>c</kbd> | Go to the project commits list (**Repository > Commits**). |
| <kbd>g</kbd> + <kbd>n</kbd> | Go to the [repository graph](#repository-graph) page (**Repository > Graph**). |
| <kbd>g</kbd> + <kbd>d</kbd> | Go to repository charts (**Analytics > Repository Analytics**). |
| <kbd>g</kbd> + <kbd>i</kbd> | Go to the project issues list (**Issues > List**). |
| <kbd>i</kbd>                | Go to the New Issue page (**Issues**, select **New Issue** ). |
| <kbd>g</kbd> + <kbd>b</kbd> | Go to the project issue boards list (**Issues > Boards**). |
| <kbd>g</kbd> + <kbd>m</kbd> | Go to the project [merge requests](project/merge_requests/index.md) list (**Merge Requests**). |
| <kbd>g</kbd> + <kbd>j</kbd> | Go to the CI/CD jobs list (**CI/CD > Jobs**). |
| <kbd>g</kbd> + <kbd>l</kbd> | Go to the project metrics (**Monitor > Metrics**). |
| <kbd>g</kbd> + <kbd>e</kbd> | Go to the project environments (**Deployments > Environments**). |
| <kbd>g</kbd> + <kbd>k</kbd> | Go to the project Kubernetes cluster integration page (**Infrastructure > Kubernetes clusters**). Note that you must have at least [`maintainer` permissions](permissions.md) to access this page. |
| <kbd>g</kbd> + <kbd>s</kbd> | Go to the project snippets list (**Snippets**). |
| <kbd>g</kbd> + <kbd>w</kbd> | Go to the [project wiki](project/wiki/index.md) (**Wiki**), if enabled. |

### Issues and merge requests

These shortcuts are available when viewing issues and [merge requests](project/merge_requests/index.md):

| Keyboard shortcut            | Description |
|------------------------------|-------------|
| <kbd>e</kbd>                 | Edit description. |
| <kbd>a</kbd>                 | Change assignee. |
| <kbd>m</kbd>                 | Change milestone. |
| <kbd>l</kbd>                 | Change label. |
| <kbd>r</kbd>                 | Start writing a comment. Pre-selected text is quoted in the comment. Can't be used to reply in a thread. |
| <kbd>n</kbd>                 | Move to next unresolved discussion (merge requests only). |
| <kbd>p</kbd>                 | Move to previous unresolved discussion (merge requests only). |
| <kbd>]</kbd> or <kbd>j</kbd> | Move to next file (merge requests only). |
| <kbd>[</kbd> or <kbd>k</kbd> | Move to previous file (merge requests only). |
| <kbd>b</kbd>                 | Copy source branch name (merge requests only). |
| <kbd>.</kbd>                 | Open the [Web IDE](project/web_ide/index.md). |

### Project files

These shortcuts are available when browsing the files in a project (go to
**Repository > Files**):

| Keyboard shortcut | Description |
|-------------------|-------------|
| <kbd>↑</kbd>      | Move selection up. |
| <kbd>↓</kbd>      | Move selection down. |
| <kbd>Enter</kbd>  | Open selection. |
| <kbd>Escape</kbd> | Go back to file list screen (only while searching for files, **Repository > Files**, then select **Find File**). |
| <kbd>y</kbd>      | Go to file permalink (only while viewing a file). |
| <kbd>.</kbd>     | Open the [Web IDE](project/web_ide/index.md). |

### Web IDE

These shortcuts are available when editing a file with the [Web IDE](project/web_ide/index.md):

| macOS shortcut                  | Windows shortcut    | Description |
|---------------------------------|---------------------|-------------|
| <kbd>Command</kbd> + <kbd>p</kbd>     | <kbd>Control</kbd> + <kbd>p</kbd> | Search for, and then open another file for editing. |
| <kbd>Command</kbd> + <kbd>Enter</kbd> | <kbd>Control</kbd> + <kbd>Enter</kbd> | Commit (when editing the commit message). |

### Repository graph

These shortcuts are available when viewing the project [repository graph](project/repository/index.md#repository-history-graph)
page (go to **Repository > Graph**):

| Keyboard shortcut                                                  | Description |
|--------------------------------------------------------------------|-------------|
| <kbd>←</kbd> or <kbd>h</kbd>                                       | Scroll left. |
| <kbd>→</kbd> or <kbd>l</kbd>                                       | Scroll right. |
| <kbd>↑</kbd> or <kbd>k</kbd>                                       | Scroll up. |
| <kbd>↓</kbd> or <kbd>j</kbd>                                       | Scroll down. |
| <kbd>Shift</kbd> + <kbd>↑</kbd> or <kbd>Shift</kbd> + <kbd>k</kbd> | Scroll to top. |
| <kbd>Shift</kbd> + <kbd>↓</kbd> or <kbd>Shift</kbd> + <kbd>j</kbd> | Scroll to bottom. |

### Wiki pages

This shortcut is available when viewing a [wiki page](project/wiki/index.md):

| Keyboard shortcut | Description |
|-------------------|-------------|
| <kbd>e</kbd>      | Edit wiki page. |

### Content editor

These shortcuts are available when editing a file with the
[Content Editor](https://about.gitlab.com/direction/create/editor/content_editor/):

| macOS shortcut | Windows shortcut | Description |
|----------------|------------------|-------------|
| <kbd>Command</kbd> + <kbd>C</kbd> | <kbd>Control</kbd> + <kbd>C</kbd> | Copy |
| <kbd>Command</kbd> + <kbd>X</kbd> | <kbd>Control</kbd> + <kbd>X</kbd> | Cut |
| <kbd>Command</kbd> + <kbd>V</kbd> | <kbd>Control</kbd> + <kbd>V</kbd> | Paste |
| <kbd>Command</kbd> + <kbd>Shift</kbd> + <kbd>V</kbd> | <kbd>Control</kbd> + <kbd>Shift</kbd> + <kbd>V</kbd> | Paste without formatting |
| <kbd>Command</kbd> + <kbd>Z</kbd> | <kbd>Control</kbd> + <kbd>Z</kbd> | Undo |
| <kbd>Command</kbd> + <kbd>Shift</kbd> + <kbd>V</kbd> | <kbd>Control</kbd> + <kbd>Shift</kbd> + <kbd>V</kbd> | Redo |
| <kbd>Shift</kbd> + <kbd>Enter</kbd> | <kbd>Shift</kbd> + <kbd>Enter</kbd> | Add a line break |

#### Formatting

| macOS shortcut | Windows/Linux shortcut | Description |
|----------------|------------------------|-------------|
| <kbd>Command</kbd> + <kbd>b</kbd> | <kbd>Control</kbd> + <kbd>b</kbd>  | Bold |
| <kbd>Command</kbd> + <kbd>i</kbd> | <kbd>Control</kbd> + <kbd>i</kbd>   | Italic |
| <kbd>Command</kbd> + <kbd>Shift</kbd> + <kbd>x</kbd>  | <kbd>Control</kbd> + <kbd>Shift</kbd> + <kbd>x</kbd>   | Strikethrough |
| <kbd>Command</kbd> + <kbd>e</kbd> | <kbd>Control</kbd> + <kbd>e</kbd>   | Code |
| <kbd>Command</kbd> + <kbd>Alt</kbd> + <kbd>0</kbd> | <kbd>Control</kbd> + <kbd>Alt</kbd> + <kbd>0</kbd> | Apply normal text style |
| <kbd>Command</kbd> + <kbd>Alt</kbd> + <kbd>1</kbd> | <kbd>Control</kbd> + <kbd>Alt</kbd> + <kbd>1</kbd> | Apply heading style 1 |
| <kbd>Command</kbd> + <kbd>Alt</kbd> + <kbd>2</kbd> | <kbd>Control</kbd> + <kbd>Alt</kbd> + <kbd>2</kbd> | Apply heading style 2 |
| <kbd>Command</kbd> + <kbd>Alt</kbd> + <kbd>3</kbd> | <kbd>Control</kbd> + <kbd>Alt</kbd> + <kbd>3</kbd> | Apply heading style 3 |
| <kbd>Command</kbd> + <kbd>Alt</kbd> + <kbd>4</kbd> | <kbd>Control</kbd> + <kbd>Alt</kbd> + <kbd>4</kbd> | Apply heading style 4 |
| <kbd>Command</kbd> + <kbd>Alt</kbd> + <kbd>5</kbd> | <kbd>Control</kbd> + <kbd>Alt</kbd> + <kbd>5</kbd> | Apply heading style 5 |
| <kbd>Command</kbd> + <kbd>Alt</kbd> + <kbd>6</kbd> | <kbd>Control</kbd> + <kbd>Alt</kbd> + <kbd>6</kbd> | Apply heading style 6 |
| <kbd>Command</kbd> + <kbd>Shift</kbd> + <kbd>7</kbd> | <kbd>Control</kbd> + <kbd>Shift</kbd> + <kbd>7</kbd> | Ordered list |
| <kbd>Command</kbd> + <kbd>Shift</kbd> + <kbd>8</kbd> | <kbd>Control</kbd> + <kbd>Shift</kbd> + <kbd>8</kbd> | Bullet list |
| <kbd>Command</kbd> + <kbd>Shift</kbd> + <kbd>9</kbd> | <kbd>Control</kbd> + <kbd>Shift</kbd> + <kbd>9</kbd> | Task list |
| <kbd>Command</kbd> + <kbd>Shift</kbd> + <kbd>b</kbd> | <kbd>Control</kbd> + <kbd>Shift</kbd> + <kbd>b</kbd> | Blockquote |
| <kbd>Command</kbd> + <kbd>Alt</kbd> + <kbd>c</kbd> | <kbd>Control</kbd> + <kbd>Shift</kbd> + <kbd>c</kbd> | Code block |
| <kbd>Command</kbd> + <kbd>,</kbd> | <kbd>Control</kbd> + <kbd>,</kbd> | Subscript |
| <kbd>Command</kbd> + <kbd>.</kbd> | <kbd>Control</kbd> + <kbd>.</kbd> | Superscript |
| <kbd>Tab</kbd> | <kbd>Tab</kbd> | Indent list |
| <kbd>Shift</kbd> + <kbd>Tab</kbd> | <kbd>Shift</kbd> + <kbd>Tab</kbd> | Outdent list |

#### Text selection

| macOS shortcut | Windows shortcut | Description |
|----------------|------------------|-------------|
| <kbd>Command</kbd> + <kbd>a</kbd>     | <kbd>Control</kbd> + <kbd>a</kbd> | Select all |
| <kbd>Shift</kbd> + <kbd>←</kbd> | <kbd>Shift</kbd> + <kbd>←</kbd> | Extend selection one character to left |
| <kbd>Shift</kbd> + <kbd>→</kbd> | <kbd>Shift</kbd> + <kbd>→</kbd> | Extend selection one character to right |
| <kbd>Shift</kbd> + <kbd>↑</kbd> | <kbd>Shift</kbd> + <kbd>↑</kbd> | Extend selection one line up |
| <kbd>Shift</kbd> + <kbd>↓</kbd> | <kbd>Shift</kbd> + <kbd>↓</kbd> | Extend selection one line down |
| <kbd>Command</kbd> + <kbd>Shift</kbd> + <kbd>↑</kbd> | <kbd>Control</kbd> + <kbd>Shift</kbd> + <kbd>↑</kbd> | Extend selection to the beginning of the document |
| <kbd>Command</kbd> + <kbd>Shift</kbd> + <kbd>↓</kbd> | <kbd>Control</kbd> + <kbd>Shift</kbd> + <kbd>↓</kbd>  | Extend selection to the end of the document |

### Filtered search

These shortcuts are available when using a [filtered search input](search/index.md):

| macOS shortcut       | Windows shortcut                       | Description |
|----------------------|----------------------------------------|-------------|
| <kbd>Command</kbd>   | <kbd>Delete</kbd>                      | Clear entire search filter. |
| <kbd>Option</kbd>    | <kbd>Control</kbd> + <kbd>Delete</kbd> | Clear one token at a time. |

## Epics **(PREMIUM)**

These shortcuts are available when viewing [epics](group/epics/index.md):

| Keyboard shortcut | Description |
|-------------------|-------------|
| <kbd>r</kbd>      | Start writing a comment. Pre-selected text is quoted in the comment. Can't be used to reply in a thread. |
| <kbd>e</kbd>      | Edit description. |
| <kbd>l</kbd>      | Change label. |

## Disable keyboard shortcuts

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/22113) in GitLab 12.8.

To disable keyboard shortcuts:

1. While viewing a page that supports keyboard shortcuts, and outside a text box,
press <kbd>?</kbd> to display the list of shortcuts.
1. Select **Toggle shortcuts**.
