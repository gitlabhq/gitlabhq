---
type: reference
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# GitLab quick actions **(FREE)**

> - Introduced in [GitLab 12.1](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/26672):
>   once an action is executed, an alert appears when a quick action is successfully applied.
> - Introduced in [GitLab 13.2](https://gitlab.com/gitlab-org/gitlab/-/issues/16877): you can use
>   quick actions when updating the description of issues, epics, and merge requests.
> - Introduced in [GitLab 13.8](https://gitlab.com/gitlab-org/gitlab/-/issues/292393): when you enter
>   `/` into a description or comment field, all available quick actions are displayed in a scrollable list.
> - The rebase quick action was [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/49800) in GitLab 13.8.

Quick actions are text-based shortcuts for common actions that are usually done
by selecting buttons or dropdowns in the GitLab user interface. You can enter
these commands in the descriptions or comments of issues, epics, merge requests,
and commits.

Be sure to enter each quick action on a separate line to allow GitLab to
properly detect and execute the commands.

## Parameters

Many quick actions require a parameter. For example, the `/assign` quick action
requires a username. GitLab uses [autocomplete characters](autocomplete_characters.md)
with quick actions to help users enter parameters, by providing a list of
available values.

If you manually enter a parameter, it must be enclosed in double quotation marks
(`"`), unless it contains only these characters:

- ASCII letters
- Numbers (0-9)
- Underscore (`_`), hyphen (`-`), question mark (`?`), dot (`.`), or ampersand (`&`)

Parameters are case-sensitive. Autocomplete handles this, and the insertion
of quotation marks, automatically.

## Issues, merge requests, and epics

The following quick actions are applicable to descriptions, discussions, and
threads. Some quick actions might not be available to all subscription tiers.

| Command                               | Issue                  | Merge request          | Epic                   | Action |
|:--------------------------------------|:-----------------------|:-----------------------|:-----------------------|:-------|
| `/approve`                            | **{dotted-circle}** No | **{check-circle}** Yes | **{dotted-circle}** No | Approve the merge request. |
| `/assign @user`                       | **{check-circle}** Yes | **{check-circle}** Yes | **{dotted-circle}** No | Assign one user. |
| `/assign @user1 @user2`               | **{check-circle}** Yes | **{check-circle}** Yes | **{dotted-circle}** No | Assign multiple users. |
| `/assign me`                          | **{check-circle}** Yes | **{check-circle}** Yes | **{dotted-circle}** No | Assign yourself. |
| `/assign_reviewer @user` or `/reviewer @user` or `/request_review @user`            | **{dotted-circle}** No | **{check-circle}** Yes | **{dotted-circle}** No | Assign one user as a reviewer. |
| `/assign_reviewer @user1 @user2` or `/reviewer @user1 @user2` or `/request_review @user1 @user2`      | **{dotted-circle}** No | **{check-circle}** Yes | **{dotted-circle}** No | Assign multiple users as reviewers. |
| `/assign_reviewer me` or `/reviewer me` or `/request_review me`                 | **{dotted-circle}** No | **{check-circle}** Yes | **{dotted-circle}** No | Assign yourself as a reviewer. |
| `/award :emoji:`                      | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes | Toggle emoji award. |
| `/child_epic <epic>`                  | **{dotted-circle}** No | **{dotted-circle}** No | **{check-circle}** Yes | Add child epic to `<epic>`. The `<epic>` value should be in the format of `&epic`, `group&epic`, or a URL to an epic ([introduced in GitLab 12.0](https://gitlab.com/gitlab-org/gitlab/-/issues/7330)). |
| `/clear_weight`                       | **{check-circle}** Yes | **{dotted-circle}** No | **{dotted-circle}** No | Clear weight. |
| `/clone <path/to/project> [--with_notes]`| **{check-circle}** Yes | **{dotted-circle}** No | **{dotted-circle}** No | Clone the issue to given project, or the current one if no arguments are given ([introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/9421) in GitLab 13.7). Copies as much data as possible as long as the target project contains equivalent labels, milestones, and so on. Does not copy comments or system notes unless `--with_notes` is provided as an argument. |
| `/close`                              | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes | Close. |
| `/confidential`                       | **{check-circle}** Yes | **{dotted-circle}** No | **{dotted-circle}** No | Make confidential. |
| `/copy_metadata <!merge_request>`     | **{check-circle}** Yes | **{check-circle}** Yes | **{dotted-circle}** No | Copy labels and milestone from another merge request in the project. |
| `/copy_metadata <#issue>`             | **{check-circle}** Yes | **{check-circle}** Yes | **{dotted-circle}** No | Copy labels and milestone from another issue in the project. |
| `/create_merge_request <branch name>` | **{check-circle}** Yes | **{dotted-circle}** No | **{dotted-circle}** No | Create a new merge request starting from the current issue. |
| `/done`                               | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes | Mark to do as done. |
| `/draft`                              | **{dotted-circle}** No | **{check-circle}** Yes | **{dotted-circle}** No | Toggle the draft status. |
| `/due <date>`                         | **{check-circle}** Yes | **{dotted-circle}** No | **{dotted-circle}** No | Set due date. Examples of valid `<date>` include `in 2 days`, `this Friday` and `December 31st`.                                 |
| `/duplicate <#issue>`                 | **{check-circle}** Yes | **{dotted-circle}** No | **{dotted-circle}** No | Close this issue and mark as a duplicate of another issue. **(FREE)** Also, mark both as related. |
| `/epic <epic>`                        | **{check-circle}** Yes | **{dotted-circle}** No | **{dotted-circle}** No | Add to epic `<epic>`. The `<epic>` value should be in the format of `&epic`, `group&epic`, or a URL to an epic. |
| `/estimate <time>`                    | **{check-circle}** Yes | **{check-circle}** Yes | **{dotted-circle}** No | Set time estimate. For example, `/estimate 1mo 2w 3d 4h 5m`. Learn more about [time tracking](time_tracking.md). |
| `/invite_email email1 email2`         | **{check-circle}** Yes | **{dotted-circle}** No | **{dotted-circle}** No | Add up to six email participants. This action is behind feature flag `issue_email_participants`. |
| `/iteration *iteration:"iteration name"`     | **{check-circle}** Yes | **{dotted-circle}** No | **{dotted-circle}** No | Set iteration. For example, to set the `Late in July` iteration: `/iteration *iteration:"Late in July"` ([introduced in GitLab 13.1](https://gitlab.com/gitlab-org/gitlab/-/issues/196795)). |
| `/label ~label1 ~label2`              | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes | Add one or more labels. Label names can also start without a tilde (`~`), but mixed syntax is not supported. |
| `/lock`                               | **{check-circle}** Yes | **{check-circle}** Yes | **{dotted-circle}** No | Lock the discussions. |
| `/merge`                              | **{dotted-circle}** No | **{check-circle}** Yes | **{dotted-circle}** No | Merge changes. Depending on the project setting, this may be [when the pipeline succeeds](merge_requests/merge_when_pipeline_succeeds.md), or adding to a [Merge Train](../../ci/pipelines/merge_trains.md). |
| `/milestone %milestone`               | **{check-circle}** Yes | **{check-circle}** Yes | **{dotted-circle}** No | Set milestone. |
| `/move <path/to/project>`             | **{check-circle}** Yes | **{dotted-circle}** No | **{dotted-circle}** No | Move this issue to another project. |
| `/parent_epic <epic>`                 | **{dotted-circle}** No | **{dotted-circle}** No | **{check-circle}** Yes | Set parent epic to `<epic>`. The `<epic>` value should be in the format of `&epic`, `group&epic`, or a URL to an epic ([introduced in GitLab 12.1](https://gitlab.com/gitlab-org/gitlab/-/issues/10556)). |
| `/promote`                            | **{check-circle}** Yes | **{dotted-circle}** No | **{dotted-circle}** No | Promote issue to epic. |
| `/publish`                            | **{check-circle}** Yes | **{dotted-circle}** No | **{dotted-circle}** No | Publish issue to an associated [Status Page](../../operations/incident_management/status_page.md) ([Introduced in GitLab 13.0](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/30906)) |
| `/reassign @user1 @user2`             | **{check-circle}** Yes | **{check-circle}** Yes | **{dotted-circle}** No | Replace current assignees with those specified. |
| `/rebase`                             | **{dotted-circle}** No | **{check-circle}** Yes | **{dotted-circle}** No | Rebase source branch. This schedules a background task that attempts to rebase the changes in the source branch on the latest commit of the target branch. If `/rebase` is used, `/merge` is ignored to avoid a race condition where the source branch is merged or deleted before it is rebased. If there are merge conflicts, GitLab displays a message that a rebase cannot be scheduled. Rebase failures are displayed with the merge request status. |
| `/reassign_reviewer @user1 @user2`    | **{dotted-circle}** No | **{check-circle}** Yes | **{dotted-circle}** No | Replace current reviewers with those specified. |
| `/relabel ~label1 ~label2`            | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes | Replace current labels with those specified. |
| `/relate #issue1 #issue2`             | **{check-circle}** Yes | **{dotted-circle}** No | **{dotted-circle}** No | Mark issues as related. |
| `/remove_child_epic <epic>`           | **{dotted-circle}** No | **{dotted-circle}** No | **{check-circle}** Yes | Remove child epic from `<epic>`. The `<epic>` value should be in the format of `&epic`, `group&epic`, or a URL to an epic ([introduced in GitLab 12.0](https://gitlab.com/gitlab-org/gitlab/-/issues/7330)). |
| `/remove_due_date`                    | **{check-circle}** Yes | **{dotted-circle}** No | **{dotted-circle}** No | Remove due date. |
| `/remove_epic`                        | **{check-circle}** Yes | **{dotted-circle}** No | **{dotted-circle}** No | Remove from epic. |
| `/remove_estimate`                    | **{check-circle}** Yes | **{check-circle}** Yes | **{dotted-circle}** No | Remove time estimate. |
| `/remove_iteration`                   | **{check-circle}** Yes | **{dotted-circle}** No | **{dotted-circle}** No | Remove iteration ([introduced in GitLab 13.1](https://gitlab.com/gitlab-org/gitlab/-/issues/196795)). |
| `/remove_milestone`                   | **{check-circle}** Yes | **{check-circle}** Yes | **{dotted-circle}** No | Remove milestone. |
| `/remove_parent_epic`                 | **{dotted-circle}** No | **{dotted-circle}** No | **{check-circle}** Yes | Remove parent epic from epic ([introduced in GitLab 12.1](https://gitlab.com/gitlab-org/gitlab/-/issues/10556)). |
| `/remove_time_spent`                  | **{check-circle}** Yes | **{check-circle}** Yes | **{dotted-circle}** No | Remove time spent. |
| `/remove_zoom`                        | **{check-circle}** Yes | **{dotted-circle}** No | **{dotted-circle}** No | Remove Zoom meeting from this issue ([introduced in GitLab 12.4](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/16609)). |
| `/reopen`                             | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes | Reopen. |
| `/shrug <comment>`                    | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes | Append the comment with `¯\＿(ツ)＿/¯`. |
| `/spend <time> [<date>]` | **{check-circle}** Yes | **{check-circle}** Yes | **{dotted-circle}** No | Add or subtract spent time. Optionally, specify the date that time was spent on. For example, `/spend 1mo 2w 3d 4h 5m 2018-08-26` or `/spend -1h 30m`. Learn more about [time tracking](time_tracking.md). |
| `/submit_review`                      | **{dotted-circle}** No | **{check-circle}** Yes | **{dotted-circle}** No | Submit a pending review ([introduced in GitLab 12.7](https://gitlab.com/gitlab-org/gitlab/-/issues/8041)). |
| `/subscribe`                          | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes | Subscribe to notifications. |
| `/tableflip <comment>`                | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes | Append the comment with `(╯°□°)╯︵ ┻━┻`. |
| `/target_branch <local branch name>`  | **{dotted-circle}** No | **{check-circle}** Yes | **{dotted-circle}** No | Set target branch. |
| `/title <new title>`                  | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes | Change title. |
| `/todo`                               | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes | Add a to-do item. |
| `/unassign @user1 @user2`             | **{check-circle}** Yes | **{check-circle}** Yes | **{dotted-circle}** No | Remove specific assignees. |
| `/unassign`                           | **{dotted-circle}** No | **{check-circle}** Yes | **{dotted-circle}** No | Remove all assignees. |
| `/unassign_reviewer @user1 @user2` or `/remove_reviewer @user1 @user2`    | **{dotted-circle}** No | **{check-circle}** Yes | **{dotted-circle}** No | Remove specific reviewers. |
| `/unassign_reviewer` or `/remove_reviewer`                  | **{dotted-circle}** No | **{check-circle}** Yes | **{dotted-circle}** No | Remove all reviewers. |
| `/unlabel ~label1 ~label2` or `/remove_label ~label1 ~label2` | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes | Remove specified labels. |
| `/unlabel` or `/remove_label` | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes | Remove all labels. |
| `/unlock`                             | **{check-circle}** Yes | **{check-circle}** Yes | **{dotted-circle}** No | Unlock the discussions. |
| `/unsubscribe`                        | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes | Unsubscribe from notifications. |
| `/weight <value>`                     | **{check-circle}** Yes | **{dotted-circle}** No | **{dotted-circle}** No | Set weight. Valid options for `<value>` include `0`, `1`, `2`, and so on. |
| `/zoom <Zoom URL>`                    | **{check-circle}** Yes | **{dotted-circle}** No | **{dotted-circle}** No | Add Zoom meeting to this issue ([introduced in GitLab 12.4](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/16609)). |

## Commit messages

The following quick actions are applicable for commit messages:

| Command                 | Action                                    |
|:----------------------- |:------------------------------------------|
| `/tag v1.2.3 <message>` | Tags the commit with an optional message. |

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
