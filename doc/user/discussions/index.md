---
stage: Create
group: Code Review
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments"
type: reference, howto
---

# Threads **(FREE)**

GitLab encourages communication through comments, threads, and suggestions.

For example, you can create a comment in the following places:

- Issues
- Epics
- Merge requests
- Snippets
- Commits
- Commit diffs

There are standard comments, and you also have the option to create a comment
in the form of a thread. A comment can also be [turned into a thread](#start-a-thread-by-replying-to-a-standard-comment)
when it receives a reply.

The comment area supports [Markdown](../markdown.md) and [quick actions](../project/quick_actions.md). You can edit your own
comment at any time, and anyone with [Maintainer access level](../permissions.md) or
higher can also edit a comment made by someone else.

You can also reply to a comment notification email to reply to the comment if
[Reply by email](../../administration/reply_by_email.md) is configured for your GitLab instance. Replying to a standard comment
creates another standard comment. Replying to a threaded comment creates a reply in the thread. Email replies support
[Markdown](../markdown.md) and [quick actions](../project/quick_actions.md), just as if you replied from the web.

NOTE:
There is a limit of 5,000 comments for every object, for example: issue, epic, and merge request.

## Resolvable comments and threads

> - [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/5022) in GitLab 8.11.
> - Resolvable threads can be added only to merge request diffs.
> - Resolving comments individually was [removed](https://gitlab.com/gitlab-org/gitlab/-/issues/28750) in GitLab 13.6.

Thread resolution helps keep track of progress during planning or code review.

Every thread in merge requests, commits, commit diffs, and
snippets is initially displayed as unresolved. They can then be individually resolved by anyone
with at least Developer access to the project or by the author of the change being reviewed.
If the thread has been resolved and a non-member un-resolves their own response,
this also unresolves the discussion thread.
If the non-member then resolves this same response, this resolves the discussion thread.

The need to resolve threads prevents you from forgetting to address feedback and lets you
hide threads that are no longer relevant.

!["A thread between two people on a piece of code"](img/thread_view.png)

### Commit threads in the context of a merge request

For reviewers with commit-based workflow, it may be useful to add threads to
specific commit diffs in the context of a merge request. These threads
persist through a commit ID change when:

- force-pushing after a rebase
- amending a commit

To create a commit diff thread:

1. Navigate to the merge request **Commits** tab. A list of commits that
   constitute the merge request are shown.

   ![Merge request commits tab](img/merge_request_commits_tab.png)

1. Navigate to a specific commit, select the **Changes** tab (where you
   are only be presented diffs from the selected commit), and leave a comment.

   ![Commit diff discussion in merge request context](img/commit_comment_mr_context.png)

1. Any threads created this way are shown in the merge request's
   **Discussions** tab and are resolvable.

   ![Merge request Discussions tab](img/commit_comment_mr_discussions_tab.png)

Threads created this way only appear in the original merge request
and not when navigating to that commit under your project's
**Repository > Commits** page.

NOTE:
When a link of a commit reference is found in a thread inside a merge
request, it is automatically converted to a link in the context of the
current merge request.

### Marking a comment or thread as resolved

You can mark a thread as resolved by selecting the **Resolve thread**
button at the bottom of the thread.

!["Resolve thread" button](img/resolve_thread_button_v13_3.png)

Alternatively, you can mark each comment as resolved individually.

!["Resolve comment" button](img/resolve_comment_button.png)

### Move all unresolved threads in a merge request to an issue

To continue all open threads from a merge request in a new issue, select
**Resolve all threads in new issue**.

![Open new issue for all unresolved threads](img/btn_new_issue_for_all_threads.png)

Alternatively, when your project only accepts merge requests [when all threads
are resolved](#only-allow-merge-requests-to-be-merged-if-all-threads-are-resolved),
an **open an issue to resolve them later** link displays in the merge
request widget.

![Link in merge request widget](img/resolve_thread_open_issue_v13_9.png)

This prepares an issue with its content referring to the merge request and
the unresolved threads.

![Issue mentioning threads in a merge request](img/preview_issue_for_threads.png)

Hitting **Create issue** causes all threads to be marked as resolved and
add a note referring to the newly created issue.

![Mark threads as resolved notice](img/resolve_thread_issue_notice.png)

You can now proceed to merge the merge request from the UI.

### Moving a single thread to a new issue

To create a new issue for a single thread, you can use the **Resolve this
thread in a new issue** button.

![Create issue for thread](img/new_issue_for_thread.png)

This directs you to a new issue prefilled with the content of the
thread, similar to the issues created for delegating multiple
threads at once. Saving the issue marks the thread as resolved and
add a note to the merge request thread referencing the new issue.

![New issue for a single thread](img/preview_issue_for_thread.png)

### Only allow merge requests to be merged if all threads are resolved

You can prevent merge requests from being merged until all threads are
resolved.

Navigate to your project's settings page, select the
**Only allow merge requests to be merged if all threads are resolved** check
box and hit **Save** for the changes to take effect.

![Only allow merge if all the threads are resolved settings](img/only_allow_merge_if_all_threads_are_resolved.png)

From now on, you can't merge from the UI until all threads
are resolved.

![Only allow merge if all the threads are resolved message](img/resolve_thread_open_issue_v13_9.png)

### Automatically resolve merge request diff threads when they become outdated

You can automatically resolve merge request diff threads on lines modified
with a new push.

Navigate to your project's settings page, select the **Automatically resolve
merge request diffs threads on lines changed with a push** check box and hit
**Save** for the changes to take effect.

![Automatically resolve merge request diff threads when they become outdated](img/automatically_resolve_outdated_discussions.png)

From now on, any threads on a diff are resolved by default if a push
makes that diff section outdated. Threads on lines that don't change and
top-level resolvable threads are not automatically resolved.

## Commit threads

You can add comments and threads to a particular commit under your
project's **Repository > Commits**.

WARNING:
Threads created this way are lost if the commit ID changes after a
force push.

## Threaded discussions

While resolvable threads are only available to merge request diffs,
threads can also be added without a diff. You can start a specific
thread which looks like a thread, on issues, commits, snippets, and
merge requests.

To start a threaded discussion, select the **Comment** button toggle dropdown,
select **Start thread**, and then select **Start thread** when you're ready to
post the comment.

![Comment type toggle](img/comment_type_toggle.gif)

This posts a comment with a single thread to allow you to discuss specific
comments in greater detail.

![Thread comment](img/discussion_comment.png)

## Image threads

Sometimes a thread is revolved around an image. With image threads,
you can easily target a specific coordinate of an image and start a thread
around it. Image threads are available in merge requests and commit detail views.

To start an image thread, hover your mouse over the image. Your mouse pointer
should convert into an icon, indicating that the image is available for commenting.
Simply click anywhere on the image to create a new thread.

![Start image thread](img/start_image_discussion.gif)

After you select the image, a comment form is displayed that would be the start
of your thread. After you save your comment, a new badge is displayed on
top of your image. This badge represents your thread.

NOTE:
This thread badge is typically associated with a number that is only used as a visual
reference for each thread. In the merge request thread tab,
this badge is indicated with a comment icon, because each thread renders a new
image section.

Image threads also work on diffs that replace an existing image. In this diff view
mode, you can toggle the different view modes and still see the thread point badges.

| 2-up        | Swipe      | Onion Skin |
|:-----------:|:----------:|:----------:|
| ![2-up view](img/two_up_view.png) | ![swipe view](img/swipe_view.png) | ![onion skin view](img/onion_skin_view.png) |

Image threads also work well with resolvable threads. Resolved threads
on diffs (not on the merge request discussion tab) appear collapsed on page
load and have a corresponding badge counter to match the counter on the image.

![Image resolved thread](img/image_resolved_discussion.png)

## Lock discussions

For large projects with many contributors, it may be useful to stop threads
in issues or merge requests in these scenarios:

- The project maintainer has already resolved the thread and it is not helpful
  for continued feedback.
- The project maintainer has already directed new conversation
  to newer issues or merge requests.
- The people participating in the thread are trolling, abusive, or otherwise
  being unproductive.

In these cases, a user with Developer permissions or higher in the project can lock (and unlock)
an issue or a merge request, using the "Lock" section in the sidebar. For issues,
a user with Reporter permissions can lock (and unlock).

| Unlock | Lock |
| :-----------: | :----------: |
| ![Turn off discussion lock](img/turn_off_lock.png) | ![Turn on discussion lock](img/turn_on_lock.png) |

System notes indicate locking and unlocking.

![Discussion lock system notes](img/discussion_lock_system_notes.png)

In a locked issue or merge request, only team members can add new comments and
edit existing comments. Non-team members are restricted from adding or editing comments.

| Team member | Non-team member |
| :-----------: | :----------: |
| ![Comment form member](img/lock_form_member.png) | ![Comment form non-member](img/lock_form_non_member.png) |

Additionally, locked issues and merge requests can't be reopened.

## Confidential Comments

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/207473) in GitLab 13.9.
> - [Deployed behind a feature flag](../feature_flags.md), disabled by default.
> - Disabled on GitLab.com.
> - Not recommended for production use.
> - To use in GitLab self-managed instances, ask a GitLab administrator to enable it. **(FREE SELF)**

WARNING:
This feature might not be available to you. Check the **version history** note above for details.

When creating a comment, you can make it visible only to the project members (users with Reporter and higher permissions).

To create a confidential comment, select the **Make this comment confidential** check box before you submit it.

![Confidential comments](img/confidential_comments_v13_9.png)

## Filtering notes

> - [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/26723) in GitLab 11.5.

For issues with many comments like activity notes and user comments, sometimes
finding useful information can be hard. There is a way to filter comments from single notes and threads for merge requests and issues.

From a merge request's **Discussion** tab, or from an epic/issue overview, find the filter's dropdown menu on the right side of the page, from which you can choose one of the following options:

- **Show all activity**: displays all user comments and system notes
  (issue updates, mentions from other issues, changes to the description, etc).
- **Show comments only**: only displays user comments in the list.
- **Show history only**: only displays activity notes.

![Notes filters dropdown options](img/index_notes_filters.png)

After you select one of the filters in a given issue or merge request, GitLab saves
your preference, so that it persists when you visit the same page again
from any device you're logged into.

## Start a thread by replying to a standard comment

> - [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/30299) in GitLab 11.9

To reply to a standard (non-thread) comment, you can use the **Reply to comment** button.

![Reply to comment button](img/reply_to_comment_button.png)

The **Reply to comment** button is only displayed if you have permissions to reply to an existing thread, or start a thread from a standard comment.

Selecting the **Reply to comment** button brings the reply area into focus and you can type your reply.

![Reply to comment feature](img/reply_to_comment.gif)

Replying to a non-thread comment converts the non-thread comment to a
thread after the reply is submitted. This conversion is considered an edit
to the original comment, so a note about when it was last edited appears underneath it.

This feature exists only for issues, merge requests, and epics. Commits, snippets, and merge request diff threads are
not supported yet.

## Assign an issue to the commenting user

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/191455) in GitLab 13.1.

You can assign an issue to a user who made a comment.

In the comment, select the **More Actions** menu, and then select **Assign to commenting user**.

Select the button again to unassign the commenter.

![Assign to commenting user](img/quickly_assign_commenter_v13_1.png)

## Enable or disable Confidential Comments **(FREE SELF)**

Confidential Comments is under development and not ready for production use. It is
deployed behind a feature flag that is **disabled by default**.
[GitLab administrators with access to the GitLab Rails console](../../administration/feature_flags.md)
can enable it.

To enable it:

```ruby
Feature.enable(:confidential_notes)
```

To disable it:

```ruby
Feature.disable(:confidential_notes)
```
