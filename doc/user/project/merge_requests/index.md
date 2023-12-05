---
stage: Create
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Merge requests **(FREE ALL)**

To incorporate changes from a source branch to a target branch, you use a *merge request* (MR).

When you open a merge request, you can visualize and collaborate on the changes before merge.
Merge requests include:

- A description of the request.
- Code changes and inline code reviews.
- Information about CI/CD pipelines.
- A comment section for discussion threads.
- The list of commits.

## Create a merge request

Learn the various ways to [create a merge request](creating_merge_requests.md).

### Use merge request templates

When you create a merge request, GitLab checks for the existence of a
[description template](../description_templates.md) to add data to your merge request.
GitLab checks these locations in order from 1 to 5, and applies the first template
found to your merge request:

| Name | Project UI<br>setting | Group<br>`default.md` | Instance<br>`default.md` | Project<br>`default.md` | No template |
| :-- | :--: | :--: | :--: | :--: | :--: |
| Standard commit message | 1 | 2 | 3 | 4 | 5 |
| Commit message with an [issue closing pattern](../issues/managing_issues.md#closing-issues-automatically) like `Closes #1234` | 1 | 2 | 3 | 4 | 5 \* |
| Branch name [prefixed with an issue ID](../repository/branches/index.md#prefix-branch-names-with-issue-numbers), like `1234-example` | 1 \* | 2 \* | 3 \* | 4 \* | 5 \* |

NOTE:
Items marked with an asterisk (\*) also append an [issue closing pattern](../issues/managing_issues.md#closing-issues-automatically).

## View merge requests

You can view merge requests for your project, group, or yourself.

### For a project

To view all merge requests for a project:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Code > Merge requests**.

Or, to use a [keyboard shortcut](../../shortcuts.md), press <kbd>g</kbd> + <kbd>m</kbd>.

### For all projects in a group

To view merge requests for all projects in a group:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Code > Merge requests**.

If your group contains subgroups, this view also displays merge requests from the subgroup projects.

### Assigned to you

To view all merge requests assigned to you:

1. On the left sidebar, select **Search or go to**.
1. From the dropdown list, select **Merge requests assigned to me**.

or:

- To use a [keyboard shortcut](../../shortcuts.md), press <kbd>Shift</kbd> + <kbd>m</kbd>.

or:

1. On the left sidebar, select **Code > Merge requests** (**{merge-request}**).
1. From the dropdown list, select **Assigned**.

## Filter the list of merge requests

> - Filtering by `approved-by` [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/30335) in GitLab 13.0.
> - Filtering by `reviewer` [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/47605) in GitLab 13.7.
> - Filtering by potential approvers was moved to GitLab Premium in 13.9.
> - Filtering by `approved-by` moved to GitLab Premium in 13.9.
> - Filtering by `source-branch` [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/134555) in GitLab 16.6.

To filter the list of merge requests:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Code > Merge requests**.
1. Above the list of merge requests, select **Search or filter results...**.
1. From the dropdown list, select the attribute you wish to filter by. Some examples:
   - [**By environment or deployment date**](#by-environment-or-deployment-date).
   - **ID**: Enter filter `#30` to return only merge request 30.
   - User filters: Type (or select from the dropdown list) any of these filters to display a list of users:
     - **Approved-By**, for merge requests already approved by a user. **(PREMIUM ALL)**.
     - **Approver**, for merge requests that this user is eligible to approve.
       (For more information, read about [Code owners](../codeowners/index.md)). **(PREMIUM ALL)**
     - **Reviewer**, for merge requests reviewed by this user.
1. Select or type the operator to use for filtering the attribute. The following operators are
   available:
   - `=`: Is
   - `!=`: Is not
1. Enter the text to filter the attribute by.
   You can filter some attributes by **None** or **Any**.
1. Repeat this process to filter by multiple attributes. Multiple attributes are joined by a logical
   `AND`.
1. Select a **Sort direction**, either **{sort-lowest}** for descending order,
   or **{sort-highest}** for ascending order.

### By environment or deployment date

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/44041) in GitLab 13.6.

To filter merge requests by deployment data, such as the environment or a date,
you can type (or select from the dropdown list) the following:

- Environment
- Deployed-before
- Deployed-after

NOTE:
Projects using a [fast-forward merge method](methods/index.md#fast-forward-merge)
do not return results, as this method does not create a merge commit.

When filtering by an environment, a dropdown list presents all environments that
you can choose from.

When filtering by `Deployed-before` or `Deployed-after`:

- The date refers to when the deployment to an environment (triggered by the
  merge commit) completed successfully.
- You must enter the deploy date manually.
- Deploy dates use the format `YYYY-MM-DD`, and must be wrapped in double quotes (`"`)
  if you want to specify both a date and time (`"YYYY-MM-DD HH:MM"`).

## Add changes to a merge request

If you have permission to add changes to a merge request, you can add your changes
to an existing merge request in several ways, depending on the complexity of your
change and whether you need access to a development environment:

- [Edit changes in the Web IDE](../web_ide/index.md) in your browser with the
  <kbd>.</kbd> [keyboard shortcut](../../shortcuts.md). Use this
  browser-based method to edit multiple files, or if you are not comfortable with Git commands.
  You cannot run tests from the Web IDE.
- [Edit changes in Gitpod](../../../integration/gitpod.md#launch-gitpod-in-gitlab), if you
  need a fully-featured environment to both edit files, and run tests afterward. Gitpod
  supports running the [GitLab Development Kit (GDK)](https://gitlab.com/gitlab-org/gitlab-development-kit).
  To use Gitpod, you must [enable Gitpod in your user account](../../../integration/gitpod.md#enable-gitpod-in-your-user-settings).
- [Push changes from the command line](../../../gitlab-basics/start-using-git.md), if you are
  familiar with Git and the command line.

## Assign a user to a merge request

To assign the merge request to a user, use the `/assign @user`
[quick action](../quick_actions.md#issues-merge-requests-and-epics) in a text area in
a merge request, or:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Code > Merge requests** and find your merge request.
1. On the right sidebar, expand the right sidebar and locate the **Assignees** section.
1. Select **Edit**.
1. Search for the user you want to assign, and select the user.

The merge request is added to the user's assigned merge request list.

### Assign multiple users **(PREMIUM ALL)**

> Moved to GitLab Premium in 13.9.

GitLab enables multiple assignees for merge requests, if multiple people are
accountable for it:

![multiple assignees for merge requests sidebar](img/merge_request_assignees_v16_0.png)

To assign multiple assignees to a merge request, use the `/assign @user`
[quick action](../quick_actions.md#issues-merge-requests-and-epics) in a text area, or:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Code > Merge requests** and find your merge request.
1. On the right sidebar, expand the right sidebar and locate the **Assignees** section.
1. Select **Edit** and, from the dropdown list, select all users you want
   to assign the merge request to.

To remove an assignee, clear the user from the same dropdown list.

## Close a merge request

If you decide to permanently stop work on a merge request,
GitLab recommends you close the merge request rather than
[delete it](#delete-a-merge-request). The author and assignees of a merge request, and users with
Developer, Maintainer, or Owner [roles](../../permissions.md) in a project
can close merge requests in the project:

1. Go to the merge request you want to close.
1. Scroll to the comment box at the bottom of the page.
1. Following the comment box, select **Close merge request**.

GitLab closes the merge request, but preserves records of the merge request,
its comments, and any associated pipelines.

### Delete a merge request

GitLab recommends you close, rather than delete, merge requests.

WARNING:
You cannot undo the deletion of a merge request.

To delete a merge request:

1. Sign in to GitLab as a user with the project Owner role.
   Only users with this role can delete merge requests in a project.
1. Go to the merge request you want to delete, and select **Edit**.
1. Scroll to the bottom of the page, and select **Delete merge request**.

### Delete the source branch on merge

You can delete the source branch for a merge request:

- When you create a merge request, by selecting **Delete source branch when merge request accepted**.
- When you merge a merge request, if you have the Maintainer role, by selecting **Delete source branch**.

An administrator can make this option the default in the project's settings.

### Update merge requests when target branch merges **(FREE SELF)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/320902) in GitLab 13.9.
> - [Disabled on self-managed](https://gitlab.com/gitlab-org/gitlab/-/issues/320902) in GitLab 13.9.
> - [Enabled on self-managed](https://gitlab.com/gitlab-org/gitlab/-/issues/320895) GitLab 13.10.

Merge requests are often chained together, with one merge request depending on
the code added or changed in another merge request. To support keeping individual
merge requests small, GitLab can update up to four open merge requests when their
target branch merges into `main`. For example:

- **Merge request 1**: merge `feature-alpha` into `main`.
- **Merge request 2**: merge `feature-beta` into `feature-alpha`.

If these merge requests are open at the same time, and merge request 1 (`feature-alpha`)
merges into `main`, GitLab updates the destination of merge request 2 from `feature-alpha`
to `main`.

Merge requests with interconnected content updates are usually handled in one of these ways:

- Merge request 1 is merged into `main` first. Merge request 2 is then
  retargeted to `main`.
- Merge request 2 is merged into `feature-alpha`. The updated merge request 1, which
  now contains the contents of `feature-alpha` and `feature-beta`, is merged into `main`.

This feature works only when a merge request is merged. Selecting **Remove source branch**
after merging does not retarget open merge requests. This improvement is
[proposed as a follow-up](https://gitlab.com/gitlab-org/gitlab/-/issues/321559).

## Move sidebar actions

<!-- When the `moved_mr_sidebar` feature flag is removed, delete this topic and update the steps for these actions
like in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/87727/diffs?diff_id=522279685#5d9afba799c4af9920dab533571d7abb8b9e9163 -->

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/85584) in GitLab 14.10 [with a flag](../../../administration/feature_flags.md) named `moved_mr_sidebar`. Enabled by default.
> - [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/373757) to also move actions on issues, incidents, and epics in GitLab 16.0.

When this feature flag is enabled, in the upper-right corner,
**Merge request actions** (**{ellipsis_v}**) contains the following actions:

- The [notifications](../../profile/notifications.md#edit-notification-settings-for-issues-merge-requests-and-epics) toggle
- Mark merge request as ready or [draft](../merge_requests/drafts.md)
- Close merge request
- [Lock discussion](../../discussions/index.md#prevent-comments-by-locking-the-discussion)
- Copy reference

In GitLab 16.0 and later, similar action menus are available on issues, incidents, and epics.

When this feature flag is disabled, these actions are in the right sidebar.

## Merge request workflows

For a software developer working in a team:

1. You check out a new branch, and submit your changes through a merge request.
1. You gather feedback from your team.
1. You work on the implementation optimizing code with [Code Quality reports](../../../ci/testing/code_quality.md).
1. You verify your changes with [Unit test reports](../../../ci/testing/unit_test_reports.md) in GitLab CI/CD.
1. You avoid using dependencies whose license is not compatible with your project with [License approval policies](../../../user/compliance/license_approval_policies.md).
1. You request the [approval](approvals/index.md) from your manager.
1. Your manager:
   1. Pushes a commit with their final review.
   1. [Approves the merge request](approvals/index.md).
   1. Sets it to [auto-merge](merge_when_pipeline_succeeds.md) (formerly **Merge when pipeline succeeds**).
1. Your changes get deployed to production with [manual jobs](../../../ci/jobs/job_control.md#create-a-job-that-must-be-run-manually) for GitLab CI/CD.
1. Your implementations were successfully shipped to your customer.

For a web developer writing a webpage for your company's website:

1. You check out a new branch and submit a new page through a merge request.
1. You gather feedback from your reviewers.
1. You preview your changes with [Review Apps](../../../ci/review_apps/index.md).
1. You request your web designers for their implementation.
1. You request the [approval](approvals/index.md) from your manager.
1. Once approved, your merge request is [squashed and merged](squash_and_merge.md), and [deployed to staging with GitLab Pages](https://about.gitlab.com/blog/2021/02/05/ci-deployment-and-environments/).
1. Your production team [cherry-picks](cherry_pick_changes.md) the merge commit into production.

## Filter activity in a merge request

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/115383) in GitLab 15.11 [with a flag](../../../administration/feature_flags.md) named `mr_activity_filters`. Disabled by default.
> - [Enabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/387070) in GitLab 16.0.
> - [Enabled on self-managed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/126998) in GitLab 16.3 by default.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/132355) in GitLab 16.5. Feature flag `mr_activity_filters` removed.

To understand the history of a merge request, filter its activity feed to show you
only the items that are relevant to you.

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Code > Merge requests**.
1. Select a merge request.
1. Scroll to **Activity**.
1. On the right side of the page, select **Activity filter** to show the filter options.
   If you've selected filter options previously, this field shows a summary of your
   choices, like **Activity + 5 more**.
1. Select the types of activity you want to see. Options include:

   - Assignees & Reviewers
   - Approvals
   - Comments
   - Commits & branches
   - Edits
   - Labels
   - Lock status
   - Mentions
   - Merge request status
   - Tracking

1. Optional. Select **Sort** (**{sort-lowest}**) to reverse the sort order.

Your selection persists across all merge requests. You can also change the
sort order by clicking the sort button on the right.

## Resolve a thread

> Resolving comments individually was [removed](https://gitlab.com/gitlab-org/gitlab/-/issues/28750) in GitLab 13.6.

In a merge request, you can [resolve a thread](../../discussions/index.md#resolve-a-thread) when you want to finish a conversation.

At the top of the page, the number of unresolved threads is updated:

![Count of unresolved threads](img/unresolved_threads_v15_4.png)

### Move all unresolved threads in a merge request to an issue

If you have multiple unresolved threads in a merge request, you can
create an issue to resolve them separately. In the merge request, at the top of the page,
select the ellipsis icon button (**{ellipsis_v}**) in the threads control and then select **Resolve all with new issue**:

![Open new issue for all unresolved threads](img/create_new_issue_v15_4.png)

All threads are marked as resolved, and a link is added from the merge request to
the newly created issue.

### Move one unresolved thread in a merge request to an issue

If you have one specific unresolved thread in a merge request, you can
create an issue to resolve it separately. In the merge request, under the last reply
to the thread, next to **Resolve thread**, select **Create issue to resolve thread** (**{issue-new}**):

![Create issue for thread](img/new-issue-one-thread_v14_3.png)

The thread is marked as resolved, and a link is added from the merge request to
the newly created issue.

### Prevent merge unless all threads are resolved

You can prevent merge requests from being merged until all threads are
resolved. When this setting is enabled, the **Unresolved threads** counter in a merge request
is shown in orange when at least one thread remains unresolved.

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > Merge requests**.
1. In the **Merge checks** section, select the **All threads must be resolved** checkbox.
1. Select **Save changes**.

### Automatically resolve threads in a merge request when they become outdated

You can set merge requests to automatically resolve threads when lines are modified
with a new push.

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > Merge requests**.
1. In the **Merge options** section, select
   **Automatically resolve merge request diff threads when they become outdated**.
1. Select **Save changes**.

Threads are now resolved if a push makes a diff section outdated.
Threads on lines that don't change and top-level resolvable threads are not resolved.

## Move notifications and to-dos **(FREE SELF)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/132678) in GitLab 16.5 [with a flag](../../../administration/feature_flags.md) named `notifications_todos_buttons`. Disabled by default.
> - [Issues, incidents](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/133474), and [epics](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/133881) also updated.

FLAG:
On self-managed GitLab, by default this feature is not available. To make it available, an administrator can [enable the feature flag](../../../administration/feature_flags.md) named `notifications_todos_buttons`.
On GitLab.com, this feature is not available.

When this feature flag is enabled, the notifications and to-do item buttons are moved to the upper right corner of the page.

- On merge requests, these buttons are located to the far right of the tabs.
- On issues, incidents, and epics, these buttons are located at the top of the right sidebar.

## Related topics

- [Create a merge request](creating_merge_requests.md)
- [Review a merge request](reviews/index.md)
- [Authorization for merge requests](authorization_for_merge_requests.md)
- [Testing and reports](../../../ci/testing/index.md)
- [GitLab keyboard shortcuts](../../shortcuts.md)
- [Comments and threads](../../discussions/index.md)
- [Suggest code changes](reviews/suggestions.md)
- [CI/CD pipelines](../../../ci/index.md)
- [Push options](../push_options.md) for merge requests

## Troubleshooting

### Rebase a merge request from the Rails console **(FREE SELF)**

In addition to the `/rebase` [quick action](../quick_actions.md#issues-merge-requests-and-epics),
users with access to the [Rails console](../../../administration/operations/rails_console.md)
can rebase a merge request from the Rails console. Replace `<username>`,
`<namespace/project>`, and `<iid>` with appropriate values:

WARNING:
Any command that changes data directly could be damaging if not run correctly,
or under the right conditions. We highly recommend running them in a test environment
with a backup of the instance ready to be restored, just in case.

```ruby
u = User.find_by_username('<username>')
p = Project.find_by_full_path('<namespace/project>')
m = p.merge_requests.find_by(iid: <iid>)
MergeRequests::RebaseService.new(project: m.target_project, current_user: u).execute(m)
```

### Fix incorrect merge request status **(FREE SELF)**

If a merge request remains **Open** after its changes are merged,
users with access to the [Rails console](../../../administration/operations/rails_console.md)
can correct the merge request's status. Replace `<username>`, `<namespace/project>`,
and `<iid>` with appropriate values:

WARNING:
Any command that changes data directly could be damaging if not run correctly,
or under the right conditions. We highly recommend running them in a test environment
with a backup of the instance ready to be restored, just in case.

```ruby
u = User.find_by_username('<username>')
p = Project.find_by_full_path('<namespace/project>')
m = p.merge_requests.find_by(iid: <iid>)
MergeRequests::PostMergeService.new(project: p, current_user: u).execute(m)
```

Running this command against a merge request with unmerged changes causes the
merge request to display an incorrect message: `merged into <branch-name>`.

### Close a merge request from the Rails console **(FREE SELF)**

If closing a merge request doesn't work through the UI or API, you may want to attempt to close it in a [Rails console session](../../../administration/operations/rails_console.md#starting-a-rails-console-session):

WARNING:
Commands that change data can cause damage if not run correctly or under the right conditions. Always run commands in a test environment first and have a backup instance ready to restore.

```ruby
u = User.find_by_username('<username>')
p = Project.find_by_full_path('<namespace/project>')
m = p.merge_requests.find_by(iid: <iid>)
MergeRequests::CloseService.new(project: p, current_user: u).execute(m)
```

### Delete a merge request from the Rails console **(FREE SELF)**

If deleting a merge request doesn't work through the UI or API, you may want to attempt to delete it in a [Rails console session](../../../administration/operations/rails_console.md#starting-a-rails-console-session):

WARNING:
Any command that changes data directly could be damaging if not run correctly,
or under the right conditions. We highly recommend running them in a test environment
with a backup of the instance ready to be restored, just in case.

```ruby
u = User.find_by_username('<username>')
p = Project.find_by_full_path('<namespace/project>')
m = p.merge_requests.find_by(iid: <iid>)
Issuable::DestroyService.new(container: m.project, current_user: u).execute(m)
```

### Merge request pre-receive hook failed

If a merge request times out, you might see messages that indicate a Puma worker
timeout problem:

- In the GitLab UI:

  ```plaintext
  Something went wrong during merge pre-receive hook.
  500 Internal Server Error. Try again.
  ```

- In the `gitlab-rails/api_json.log` log file:

  ```plaintext
  Rack::Timeout::RequestTimeoutException
  Request ran for longer than 60000ms
  ```

This error can happen if your merge request:

- Contains many diffs.
- Is many commits behind the target branch.
- References a Git LFS file that is locked.

Users in self-managed installations can request an administrator review server logs
to determine the cause of the error. GitLab SaaS users should
[contact Support](https://about.gitlab.com/support/#contact-support) for help.
