---
stage: Create
group: Code Review
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments"
description: "Use comments to discuss work, mention users, and suggest changes."
---

# Comments and threads

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

> - Paginated merge request discussions [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/340172) in GitLab 15.1 [with a flag](../../administration/feature_flags.md) named `paginated_mr_discussions`. Disabled by default.
> - Paginated merge request discussions [enabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/364497) in GitLab 15.2.
> - Paginated merge request discussions [enabled on self-managed](https://gitlab.com/gitlab-org/gitlab/-/issues/364497) in GitLab 15.3.
> - Paginated merge request discussions [generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/370075) in GitLab 15.8. Feature flag `paginated_mr_discussions` removed.

GitLab encourages communication through comments, threads, and
[Code Suggestions](../project/merge_requests/reviews/suggestions.md).

Two types of comments are available:

- A standard comment.
- A comment in a thread, which can be [resolved](../project/merge_requests/index.md#resolve-a-thread).

In a comment, you can enter [Markdown](../markdown.md) and use [quick actions](../project/quick_actions.md).

You can [suggest code changes](../project/merge_requests/reviews/suggestions.md) in your commit diff comment,
which the user can accept through the user interface.

## Places you can add comments

You can create comments in places like:

- Commit diffs
- Commits
- Designs
- Epics
- Issues
- Merge requests
- Snippets
- Tasks
- OKRs

Each object can have as many as 5,000 comments.

## Mentions

You can mention a user or a group (including [subgroups](../group/subgroups/index.md#mention-subgroups)) in your GitLab
instance with `@username` or `@groupname`. All mentioned users are notified with to-do items and emails.
Users can change this setting for themselves in the [notification settings](../profile/notifications.md).

You can quickly see which comments involve you, because
mentions for yourself (the user who is signed in) are highlighted
in a different color.

### Mentioning all members

> - [Flag](../../administration/feature_flags.md) named `disable_all_mention` [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/110586) in GitLab 16.1. Disabled by default. [Enabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/18442).

FLAG:
On self-managed GitLab, by default this flag is not enabled. To make it available, an administrator can [enable the feature flag](../../administration/feature_flags.md)
named `disable_all_mention`.
On GitLab.com, this flag is enabled.

When this feature flag is enabled, typing `@all` in comments and descriptions
results in plain text instead of a mention.
When you disable this feature, existing `@all` mentions in the Markdown texts are not affected
and remain as links. Only future `@all` mentions appear as plain text.

Avoid mentioning `@all` in comments and descriptions.
When you do it, you don't only mention the participants of the project, issue, or merge request,
but to all members of that project's parent group.
All these users receive an email notification and a to-do item. It might be interpreted as spam.

Notifications and mentions can be disabled in
[a group's settings](../group/manage.md#disable-email-notifications).

### Mention a group in an issue or merge request

When you mention a group in a comment, every member of the group gets a to-do item
added to their To-do list.

1. On the left sidebar, select **Search or go to** and find your project.
1. For merge requests, select **Code > Merge requests**, and find your merge request.
1. For issues, select **Plan > Issues**, and find your issue.
1. In a comment, type `@` followed by the user, group, or subgroup namespace.
   For example, `@alex`, `@alex-team`, or `@alex-team/marketing`.
1. Select **Comment**.

A to-do item is created for all the group and subgroup members.

For more information on mentioning subgroups see [Mention subgroups](../group/subgroups/index.md#mention-subgroups).

## Add a comment to a merge request diff

You can add comments to a merge request diff. These comments
persist, even when you:

- Force-push after a rebase.
- Amend a commit.

To add a commit diff comment:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Code > Merge requests**, and find your merge request.
1. Select the **Commits** tab, then select the commit message.
1. By the line you want to comment on, hover over the line number and select **Comment** (**{comment}**).
   You can select multiple lines by dragging the **Comment** (**{comment}**) icon.
1. Enter your comment and select **Start a review** or **Add comment now**.

The comment is displayed on the merge request's **Overview** tab.

The comment is not displayed on your project's **Code > Commits** page.

NOTE:
When your comment contains a reference to a commit included in the merge request,
it's converted to a link in the context of the merge request.
For example, `28719b171a056960dfdc0012b625d0b47b123196` becomes `28719b17` that links to
`https://gitlab.example.com/example-group/example-project/-/merge_requests/12345/diffs?commit_id=28719b171a056960dfdc0012b625d0b47b123196`.

## Reply to a comment by sending email

If you have ["reply by email"](../../administration/reply_by_email.md) configured,
you can reply to comments by sending an email.

- When you reply to a standard comment, it creates another standard comment.
- When you reply to a threaded comment, it creates a reply in the thread.
- When you [send an email to an issue email address](../project/issues/managing_issues.md#copy-issue-email-address),
  it creates a standard comment.

You can use [Markdown](../markdown.md) and [quick actions](../project/quick_actions.md) in your email replies.

## Edit a comment

You can edit your own comment at any time.
Anyone with at least the Maintainer role can also edit a comment made by someone else.

To edit a comment:

1. On the comment, select **Edit comment** (**{pencil}**).
1. Make your edits.
1. Select **Save changes**.

### Editing a comment to add a mention

By default, when you mention a user, GitLab [creates a to-do item](../todos.md#actions-that-create-to-do-items)
for them, and sends them a [notification email](../profile/notifications.md).

If you edit an existing comment to add a user mention that wasn't there before, GitLab:

- Creates a to-do item for the mentioned user.
- Does not send a notification email.

## Prevent comments by locking the discussion

You can prevent public comments in an issue or merge request.
When you do, only project members can add and edit comments.

Prerequisites:

- In merge requests, you must have at least the Developer role.
- In issues, you must have at least the Reporter role.

To lock an issue or merge request:

1. On the left sidebar, select **Search or go to** and find your project.
1. For merge requests, select **Code > Merge requests**, and find your merge request.
1. For issues, select **Plan > Issues**, and find your issue.
1. In the upper-right corner, select **Merge request actions** or **Issue actions** (**{ellipsis_v}**), then select **Lock discussion**.

A system note is added to the page details.

If an issue or merge request is closed with a locked discussion, then you cannot reopen it until the discussion is unlocked.

## Add an internal note

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/207473) in GitLab 13.9 [with a flag](../../administration/feature_flags.md) named `confidential_notes`. Disabled by default.
> - [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/351143) in GitLab 14.10: you can only mark comments in issues and epics as confidential. Previously, it was also possible for comments in merge requests and snippets.
> - [Renamed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/87403) from "confidential comments" to "internal notes" in GitLab 15.0.
> - [Enabled on GitLab.com and self-managed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/87383) in GitLab 15.0.
> - [Feature flag `confidential_notes`](https://gitlab.com/gitlab-org/gitlab/-/issues/362712) removed in GitLab 15.2.
> - [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/363045) permissions in GitLab 15.6 to at least the Reporter role. In GitLab 15.5 and earlier, issue or epic authors and assignees could also read and create internal notes.
> - Internal comments [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/142003) for merge requests in GitLab 16.9.

When you add an internal note to a _public_ issue, epic, or merge request, only project members
with least the Reporter role can view the note. Internal notes cannot be converted to regular comments,
and all replies to internal notes are also internal. Internal notes are shown in a different
color than public comments, and display an **Internal note** badge:

![Internal notes](img/add_internal_note_v16_9.png)

Prerequisites:

- You must have at least the Reporter role for the project.

To add an internal note:

1. On the issue, epic, or merge request, in the **Comment** text box, type a comment.
1. Below the comment, select the **Make this an internal note** checkbox.
1. Select **Add internal note**.

You can also mark an entire [issue as confidential](../project/issues/confidential_issues.md),
or create [confidential merge requests](../project/merge_requests/confidential.md).

## Show only comments

In discussions with many comments, filter the discussion to show only comments or history of
changes ([system notes](../project/system_notes.md)). System notes include changes to the description, mentions in other GitLab
objects, or changes to labels, assignees, and the milestone.
GitLab saves your preference, and applies it to every issue, merge request, or epic you view.

1. On a merge request, issue, or epic, select the **Overview** tab.
1. On the right side of the page, from the **Sort or filter** dropdown list, select a filter:
   - **Show all activity**: Display all user comments and system notes.
   - **Show comments only**: Display only user comments.
   - **Show history only**: Display only activity notes.

## Change activity sort order

Reverse the default order and interact with the activity feed sorted by most recent items
at the top. GitLab saves your preference in local storage and applies it to every issue,
merge request, or epic you view.

To change the activity sort order:

1. Open the **Overview** tab in a merge request, issue, or epic.
1. On the right side of the page, from the **Sort or filter** dropdown list, select the sort order
   **Newest first** or **Oldest first** (default).

## View description change history

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

You can see changes to the description listed in the history.

To compare the changes, select **Compare with previous version**.

## Assign an issue to the commenting user

You can assign an issue to a user who made a comment.

1. In the comment, select the **More Actions** (**{ellipsis_v}**) menu.
1. Select **Assign to commenting user**:
   ![Assign to commenting user](img/quickly_assign_commenter_v16_6.png)
1. To unassign the commenter, select the button again.

## Create a thread by replying to a standard comment

When you reply to a standard comment, you create a thread.

Prerequisites:

- You must have at least the Guest role.
- You must be in an issue, merge request, or epic. Threads in commits and snippets are not supported.

To create a thread by replying to a comment:

1. In the upper-right corner of the comment, select **Reply to comment** (**{reply}**).

   The reply section is displayed.

1. Enter your reply.
1. Select **Reply** or **Add comment now** (depending on where in the UI you are replying).

The top comment is converted to a thread.

## Create a thread without replying to a comment

You can create a thread without replying to a standard comment.

Prerequisites:

- You must have at least the Guest role.
- You must be in an issue, merge request, commit, or snippet.

To create a thread:

1. Enter a comment.
1. Below the comment, to the right of **Comment**, select the down arrow (**{chevron-down}**).
1. From the list, select **Start thread**.
1. Select **Start thread** again.

![Create a thread](img/create_thread_v16_6.png)

A threaded comment is created.

## Resolve a thread

> - Resolvable threads for issues [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/31114) in GitLab 16.3 [with a flag](../../administration/feature_flags.md) named `resolvable_issue_threads`. Disabled by default.
> - Resolvable threads for issues [enabled on GitLab.com and self-managed](https://gitlab.com/gitlab-org/gitlab/-/issues/31114) in GitLab 16.4.
> - Resolvable threads for issues [generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/31114) in GitLab 16.7. Feature flag `resolvable_issue_threads` removed.

You can resolve a thread when you want to finish a conversation.

Prerequisites:

- You must be in an issue or merge request.
- You must have at least the Developer role or be the author of the issue or merge request.

To resolve a thread:

1. Go to the thread.
1. Do one of the following:
   - In the upper-right corner of the original comment, select **Resolve thread** (**{check-circle}**).
   - Below the last reply, in the **Reply** field, select **Resolve thread**.
   - Below the last reply, in the **Reply** field, enter text, select the **Resolve thread** checkbox, and select **Add comment now**.
