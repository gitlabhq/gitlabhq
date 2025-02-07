---
stage: Create
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "Suggest improvements to the code in a merge request, and commit those improvements to the merge request directly from your browser."
title: Suggest changes
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Reviewers can suggest code changes with a Markdown syntax in merge request diff threads.
The merge request author (or other users with the appropriate role) can apply any or
all suggestions from the GitLab UI. Applying suggestions adds a commit to the
merge request, authored by the user who suggested the changes.

## Create suggestions

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Code > Merge requests** and find your merge request.
1. On the secondary menu, select **Changes**.
1. Find the lines of code you want to change.
   - To select a single line, hover over the line number and
     select **Add a comment to this line** (**{comment}**).
   - To select more lines:
     1. Hover over the line number, and select **Add a comment to this line** (**{comment}**):
        ![Comment on any diff file line](img/comment_on_any_diff_line_v16_6.png)
     1. Select and drag your selection to include all desired lines. To
        learn more, see [Multi-line suggestions](#multi-line-suggestions).
1. In the comment toolbar, select **Insert suggestion** (**{doc-code}**). GitLab
   inserts a pre-populated code block into your comment, like this:

   ````markdown
   ```suggestion:-0+0
   The content of the line you selected is shown here.
   ```
   ````

1. Edit the pre-populated code block to add your suggestion.
1. To add your comment immediately, select **Add comment now**, or use the keyboard shortcut:
   - macOS: <kbd>Shift</kbd> + <kbd>Command</kbd> + <kbd>Enter</kbd>
   - All other OSes: <kbd>Shift</kbd> + <kbd>Control</kbd> + <kbd>Enter</kbd>
1. To leave your comment unpublished until you finish a [review](_index.md), select
   **Start a review**, or use the keyboard shortcut:
   - macOS: <kbd>Command</kbd> + <kbd>Enter</kbd>
   - All other OSes: <kbd>Control</kbd> + <kbd>Enter</kbd>

### Multi-line suggestions

> - Multi-line suggestions [changed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/172981/) in GitLab 17.7 to support rendering when the suggestion contains a code block.

When you review a merge request diff, you can propose changes to multiple lines (up to 200)
in a single suggestion, by either:

- Selecting and dragging, as described in [Create suggestions](#create-suggestions).
  GitLab creates a suggestion block for you.
- Selecting a single line, then manually editing the range offsets in the suggestion block.

The range offsets in the first line of the suggestion describe line numbers relative
to the line you selected. The offsets specify the lines your suggestion intends to replace.
For example, this suggestion covers 2 lines above and 2 lines below the
commented line:

````markdown
```suggestion:-2+2
## Prevent approval by author

By default, the author of a merge request cannot approve it. To change this setting:
```
````

When applied, the suggestion replaces from 2 lines above to 2 lines below the commented line:

![Multi-line suggestion preview](img/multi-line-suggestion-preview_v16_6.png)

GitLab limits multi-line suggestions to 100 lines _above_ and 100
lines _below_ the commented diff line. This allows for up to 201 changed lines per
suggestion.

Multi-line comments display the comment's line numbers above the body of the comment:

![Multi-line comment selection displayed above comment](img/multiline-comment-saved_v17_5.png)

#### Using the rich text editor

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/388449) in GitLab 16.1 [with a flag](../../../../administration/feature_flags.md) named `content_editor_on_issues`. Disabled by default.
> - [Enabled on GitLab.com and GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/issues/375172) in GitLab 16.2.
> - Feature flag `content_editor_on_issues` removed in GitLab 16.5.

When you insert suggestions, use the WYSIWYG [rich text editor](../../../rich_text_editor.md) to move
up and down the source file's line numbers in the UI.

To add or subtract changed lines, next to **From line**, select **+** or **-**.

![Multi-line suggestion preview](img/suggest_changes_v16_2.png)

## Apply suggestions

Prerequisites:

- You must be the author of the merge request, or have at least the Developer role for the project.

To apply suggested changes directly from the merge request:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Code > Merge requests** and find your merge request.
1. Find the comment containing the suggestion you want to apply.
   - To apply suggestions individually, select **Apply suggestion**.
   - To apply multiple suggestions in a single commit, select **Add suggestion to batch**.
1. Optional. Provide a custom commit message to describe your change. If you
   don't provide a custom message, it uses the default commit message.
1. Select **Apply**.

After you apply a suggestion, GitLab:

- Marks the suggestion as **Applied**.
- Resolves the comment thread.
- Creates a new commit with the changes.
- (If the user has the Developer role) Pushes the suggested change directly into
  the codebase in the merge request's branch.

## Configure the commit message for applied suggestions

GitLab uses a default commit message when applying suggestions, but you can change
it. This message supports placeholders. For example, the default message
`Apply %{suggestions_count} suggestion(s) to %{files_count} file(s)` renders
like this if you apply three suggestions to two different files:

```plaintext
Apply 3 suggestion(s) to 2 file(s)
```

Merge requests created from forks use the template defined in the target project.
To meet your project's needs, customize these messages and include other
placeholder variables.

Prerequisites:

- You must have the Maintainer role.

To do this:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > Merge requests**.
1. Scroll to **Merge suggestions**, and alter the text to meet your needs.
   See [Supported variables](#supported-variables) for a list of placeholders
   you can use in this message.

### Supported variables

The template for commit messages for applied suggestions supports these variables:

| Variable               | Description | Output example |
|------------------------|-------------|----------------|
| `%{branch_name}`       | The name of the branch to which suggestions were applied. | `my-feature-branch` |
| `%{files_count}`       | The number of files to which suggestions were applied.| `2` |
| `%{file_paths}`        | The paths of the file to which suggestions were applied. Paths are separated by commas.| `docs/index.md, docs/about.md` |
| `%{project_path}`      | The project path. | `my-group/my-project` |
| `%{project_name}`      | The human-readable name of the project. | `My Project` |
| `%{suggestions_count}` | The number of suggestions applied.| `3` |
| `%{username}`          | The username of the user applying suggestions. | `user_1` |
| `%{user_full_name}`    | The full name of the user applying suggestions. | `User 1` |
| `%{co_authored_by}`    | Names and emails of suggestion authors in a `Co-authored-by` Git commit trailer format. | `Co-authored-by: Zane Doe <zdoe@example.com>` <br> `Co-authored-by: Blake Smith <bsmith@example.com>` |

For example, to customize the commit message to output
`Addresses user_1's review`, set the custom text to
`Addresses %{username}'s review`.

## Batch suggestions

Prerequisites:

- You must have a role for the project that allows you to commit to the source branch.

To reduce the number of commits added to your branch, apply multiple
suggestions in a single commit.

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Code > Merge requests** and find your merge request.
1. For each suggestion you want to apply, select **Add suggestion to batch**.
1. Optional. To remove a suggestion, select **Remove from batch**.
1. After you add your desired suggestions, select **Apply suggestions**.

   WARNING:
   If you apply a batch of suggestions containing changes from multiple authors,
   the resulting commit credits you as the author. If you configure your project
   to [prevent approvals from users who add commits](../approvals/settings.md#prevent-approvals-by-users-who-add-commits), you are no longer an eligible
   approver for this merge request.

1. Optional. Provide a custom commit message for [batch suggestions](#batch-suggestions)
   to describe your change. If you don't specify one, it uses
   the default commit message.

## Related topics

- [Suggestions API](../../../../api/suggestions.md)
