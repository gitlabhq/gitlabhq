---
type: reference
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# GitLab quick actions **(FREE)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/26672) in GitLab 12.1:
>   once an action is executed, an alert appears when a quick action is successfully applied.
> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/16877) in GitLab 13.2: you can use
>   quick actions when updating the description of issues, epics, and merge requests.
> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/292393) in GitLab 13.8: when you enter
>   `/` into a description or comment field, all available quick actions are displayed in a scrollable list.
> - The rebase quick action was [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/49800) in GitLab 13.8.

Quick actions are text-based shortcuts for common actions that are usually done
by selecting buttons or dropdowns in the GitLab user interface. You can enter
these commands in the descriptions or comments of issues, epics, merge requests,
and commits.

Many quick actions are context-aware, requiring certain conditions be met. For example, to remove
an issue due date with `/remove_due_date`, the issue must have a due date set.

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
- Underscore (`_`), hyphen (`-`), question mark (`?`), dot (`.`), ampersand (`&`) or at (`@`)

Parameters are case-sensitive. Autocomplete handles this, and the insertion
of quotation marks, automatically.

## Issues, merge requests, and epics

The following quick actions are applicable to descriptions, discussions, and
threads. Some quick actions might not be available to all subscription tiers.

<!-- Keep this table sorted alphabetically -->
<!-- Don't prettify this table; it will expand out the last field into illegibility -->

| Command                                                                                          | Issue                  | Merge request          | Epic                   | Action |
|:-------------------------------------------------------------------------------------------------|:-----------------------|:-----------------------|:-----------------------|:-------|
| `/add_contacts [contact:email1@example.com] [contact:email2@example.com]`                        | **{check-circle}** Yes | **{dotted-circle}** No | **{dotted-circle}** No | Add one or more active [CRM contacts](../crm/index.md) ([introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/73413) in GitLab 14.6).
| `/approve`                                                                                       | **{dotted-circle}** No | **{check-circle}** Yes | **{dotted-circle}** No | Approve the merge request.
| `/assign @user1 @user2`                                                                          | **{check-circle}** Yes | **{check-circle}** Yes | **{dotted-circle}** No | Assign one or more users.
| `/assign me`                                                                                     | **{check-circle}** Yes | **{check-circle}** Yes | **{dotted-circle}** No | Assign yourself.
| `/assign_reviewer @user1 @user2` or `/reviewer @user1 @user2` or `/request_review @user1 @user2` | **{dotted-circle}** No | **{check-circle}** Yes | **{dotted-circle}** No | Assign one or more users as reviewers.
| `/assign_reviewer me` or `/reviewer me` or `/request_review me`                                  | **{dotted-circle}** No | **{check-circle}** Yes | **{dotted-circle}** No | Assign yourself as a reviewer.
| `/award :emoji:`                                                                                 | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes | Toggle emoji award.
| `/cc @user`                                                                                      | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes | Mention a user. In GitLab 15.0 and later, this command performs no action. You can instead type `CC @user` or only `@user`. [In GitLab 14.9 and earlier](https://gitlab.com/gitlab-org/gitlab/-/issues/31200), mentioning a user at the start of a line created a specific type of to-do item notification. |
| `/child_epic <epic>`                                                                             | **{dotted-circle}** No | **{dotted-circle}** No | **{check-circle}** Yes | Add child epic to `<epic>`. The `<epic>` value should be in the format of `&epic`, `group&epic`, or a URL to an epic.
| `/clear_health_status`                                                                           | **{check-circle}** Yes | **{dotted-circle}** No | **{dotted-circle}** No | Clear [health status](issues/managing_issues.md#health-status) ([introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/213814) in GitLab 14.7).
| `/clear_weight`                                                                                  | **{check-circle}** Yes | **{dotted-circle}** No | **{dotted-circle}** No | Clear weight.
| `/clone <path/to/project> [--with_notes]`                                                        | **{check-circle}** Yes | **{dotted-circle}** No | **{dotted-circle}** No | Clone the issue to given project, or the current one if no arguments are given ([introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/9421) in GitLab 13.7). Copies as much data as possible as long as the target project contains equivalent labels, milestones, and so on. Does not copy comments or system notes unless `--with_notes` is provided as an argument.
| `/close`                                                                                         | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes | Close.
| `/confidential`                                                                                  | **{check-circle}** Yes | **{dotted-circle}** No | **{check-circle}** Yes | Mark issue or epic as confidential. Support for epics [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/213741) in GitLab 15.6. |
| `/copy_metadata <!merge_request>`                                                                | **{check-circle}** Yes | **{check-circle}** Yes | **{dotted-circle}** No | Copy labels and milestone from another merge request in the project.
| `/copy_metadata <#issue>`                                                                        | **{check-circle}** Yes | **{check-circle}** Yes | **{dotted-circle}** No | Copy labels and milestone from another issue in the project.
| `/create_merge_request <branch name>`                                                            | **{check-circle}** Yes | **{dotted-circle}** No | **{dotted-circle}** No | Create a new merge request starting from the current issue.
| `/done`                                                                                          | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes | Mark to-do item as done.
| `/draft`                                                                                         | **{dotted-circle}** No | **{check-circle}** Yes | **{dotted-circle}** No | Set the [draft status](merge_requests/drafts.md). Use for toggling the draft status ([deprecated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/92654) in GitLab 15.4.) |
| `/due <date>`                                                                                    | **{check-circle}** Yes | **{dotted-circle}** No | **{dotted-circle}** No | Set due date. Examples of valid `<date>` include `in 2 days`, `this Friday` and `December 31st`. See [Chronic](https://gitlab.com/gitlab-org/ruby/gems/gitlab-chronic#examples) for more examples.
| `/duplicate <#issue>`                                                                            | **{check-circle}** Yes | **{dotted-circle}** No | **{dotted-circle}** No | Close this issue. Mark as a duplicate of, and related to, issue `<#issue>`.
| `/epic <epic>`                                                                                   | **{check-circle}** Yes | **{dotted-circle}** No | **{dotted-circle}** No | Add to epic `<epic>`. The `<epic>` value should be in the format of `&epic`, `group&epic`, or a URL to an epic.
| `/estimate <time>` or `/estimate_time <time>`                                                    | **{check-circle}** Yes | **{check-circle}** Yes | **{dotted-circle}** No | Set time estimate. For example, `/estimate 1mo 2w 3d 4h 5m`. For more information, see [Time tracking](time_tracking.md). Alias `/estimate_time` [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/16501) in GitLab 15.6.
| `/health_status <value>`                                                                         | **{check-circle}** Yes | **{dotted-circle}** No | **{dotted-circle}** No | Set [health status](issues/managing_issues.md#health-status). Valid options for `<value>` are `on_track`, `needs_attention`, and `at_risk` ([introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/213814) in GitLab 14.7).
| `/invite_email email1 email2`                                                                    | **{check-circle}** Yes | **{dotted-circle}** No | **{dotted-circle}** No | Add up to six email participants. This action is behind feature flag `issue_email_participants` and is not yet supported in issue templates.
| `/iteration *iteration:"iteration name"`                                                         | **{check-circle}** Yes | **{dotted-circle}** No | **{dotted-circle}** No | Set iteration. For example, to set the `Late in July` iteration: `/iteration *iteration:"Late in July"` ([introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/196795) in GitLab 13.1).
| `/label ~label1 ~label2` or `/labels ~label1 ~label2`                                            | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes | Add one or more labels. Label names can also start without a tilde (`~`), but mixed syntax is not supported.
| `/lock`                                                                                          | **{check-circle}** Yes | **{check-circle}** Yes | **{dotted-circle}** No | Lock the discussions.
| `/link`                                                                                          | **{check-circle}** Yes | **{dotted-circle}** No | **{dotted-circle}** No | Add a link and description to [linked resources](../../operations/incident_management/linked_resources.md) in an incident ([introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/374964) in GitLab 15.5). |
| `/merge`                                                                                         | **{dotted-circle}** No | **{check-circle}** Yes | **{dotted-circle}** No | Merge changes. Depending on the project setting, this may be [when the pipeline succeeds](merge_requests/merge_when_pipeline_succeeds.md), or adding to a [Merge Train](../../ci/pipelines/merge_trains.md).
| `/milestone %milestone`                                                                          | **{check-circle}** Yes | **{check-circle}** Yes | **{dotted-circle}** No | Set milestone.
| `/move <path/to/project>`                                                                        | **{check-circle}** Yes | **{dotted-circle}** No | **{dotted-circle}** No | Move this issue to another project. Be careful when moving an issue to a project with different access rules. Before moving the issue, make sure it does not contain sensitive data.
| `/parent_epic <epic>`                                                                            | **{dotted-circle}** No | **{dotted-circle}** No | **{check-circle}** Yes | Set parent epic to `<epic>`. The `<epic>` value should be in the format of `&epic`, `group&epic`, or a URL to an epic.
| `/promote`                                                                                       | **{check-circle}** Yes | **{dotted-circle}** No | **{dotted-circle}** No | Promote issue to epic.
| `/promote_to_incident`                                                                           | **{check-circle}** Yes | **{dotted-circle}** No | **{dotted-circle}** No | Promote issue to incident ([introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/296787) in GitLab 14.5). In [GitLab 15.8 and later](https://gitlab.com/gitlab-org/gitlab/-/issues/376760), you can also use the quick action when creating a new issue.
| `/page <policy name>`                                                                            | **{check-circle}** Yes | **{dotted-circle}** No | **{dotted-circle}** No | Start escalations for the incident ([introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/79977) in GitLab 14.9).
| `/publish`                                                                                       | **{check-circle}** Yes | **{dotted-circle}** No | **{dotted-circle}** No | Publish issue to an associated [Status Page](../../operations/incident_management/status_page.md) ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/30906) in GitLab 13.0)
| `/ready`                                                                                         | **{dotted-circle}** No | **{check-circle}** Yes | **{dotted-circle}** No | Set the [ready status](merge_requests/drafts.md#mark-merge-requests-as-ready) ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/90361) in GitLab 15.1).
| `/reassign @user1 @user2`                                                                        | **{check-circle}** Yes | **{check-circle}** Yes | **{dotted-circle}** No | Replace current assignees with those specified.
| `/reassign_reviewer @user1 @user2`                                                               | **{dotted-circle}** No | **{check-circle}** Yes | **{dotted-circle}** No | Replace current reviewers with those specified.
| `/rebase`                                                                                        | **{dotted-circle}** No | **{check-circle}** Yes | **{dotted-circle}** No | Rebase source branch. This schedules a background task that attempts to rebase the changes in the source branch on the latest commit of the target branch. If `/rebase` is used, `/merge` is ignored to avoid a race condition where the source branch is merged or deleted before it is rebased. If there are merge conflicts, GitLab displays a message that a rebase cannot be scheduled. Rebase failures are displayed with the merge request status. |
| `/relabel ~label1 ~label2`                                                                       | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes | Replace current labels with those specified.
| `/relate #issue1 #issue2`                                                                        | **{check-circle}** Yes | **{dotted-circle}** No | **{dotted-circle}** No | Mark issues as related.
| `/remove_child_epic <epic>`                                                                      | **{dotted-circle}** No | **{dotted-circle}** No | **{check-circle}** Yes | Remove child epic from `<epic>`. The `<epic>` value should be in the format of `&epic`, `group&epic`, or a URL to an epic.
| `/remove_contacts [contact:email1@example.com] [contact:email2@example.com]`                     | **{check-circle}** Yes | **{dotted-circle}** No | **{dotted-circle}** No | Remove one or more [CRM contacts](../crm/index.md) ([introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/73413) in GitLab 14.6).
| `/remove_due_date`                                                                               | **{check-circle}** Yes | **{dotted-circle}** No | **{dotted-circle}** No | Remove due date.
| `/remove_epic`                                                                                   | **{check-circle}** Yes | **{dotted-circle}** No | **{dotted-circle}** No | Remove from epic.
| `/remove_estimate` or `/remove_time_estimate`                                                    | **{check-circle}** Yes | **{check-circle}** Yes | **{dotted-circle}** No | Remove time estimate. Alias `/remove_time_estimate` [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/16501) in GitLab 15.6.
| `/remove_iteration`                                                                              | **{check-circle}** Yes | **{dotted-circle}** No | **{dotted-circle}** No | Remove iteration ([introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/196795) in GitLab 13.1).
| `/remove_milestone`                                                                              | **{check-circle}** Yes | **{check-circle}** Yes | **{dotted-circle}** No | Remove milestone.
| `/remove_parent_epic`                                                                            | **{dotted-circle}** No | **{dotted-circle}** No | **{check-circle}** Yes | Remove parent epic from epic.
| `/remove_time_spent`                                                                             | **{check-circle}** Yes | **{check-circle}** Yes | **{dotted-circle}** No | Remove time spent.
| `/remove_zoom`                                                                                   | **{check-circle}** Yes | **{dotted-circle}** No | **{dotted-circle}** No | Remove Zoom meeting from this issue.
| `/reopen`                                                                                        | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes | Reopen.
| `/severity <severity>`                                                                           | **{check-circle}** Yes | **{check-circle}** No  | **{check-circle}** No  | Set the severity. Issue type must be `Incident`. Options for `<severity>` are `S1` ... `S4`, `critical`, `high`, `medium`, `low`, `unknown`. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/334045) in GitLab 14.2.
| `/shrug <comment>`                                                                               | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes | Append the comment with `¯\＿(ツ)＿/¯`.
| `/spend <time> [<date>]` or `/spend_time <time> [<date>]`                                        | **{check-circle}** Yes | **{check-circle}** Yes | **{dotted-circle}** No | Add or subtract spent time. Optionally, specify the date that time was spent on. For example, `/spend 1mo 2w 3d 4h 5m 2018-08-26` or `/spend -1h 30m`. For more information, see [Time tracking](time_tracking.md). Alias `/spend_time` [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/16501) in GitLab 15.6.
| `/submit_review`                                                                                 | **{dotted-circle}** No | **{check-circle}** Yes | **{dotted-circle}** No | Submit a pending review.
| `/subscribe`                                                                                     | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes | Subscribe to notifications.
| `/tableflip <comment>`                                                                           | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes | Append the comment with `(╯°□°)╯︵ ┻━┻`.
| `/target_branch <local branch name>`                                                             | **{dotted-circle}** No | **{check-circle}** Yes | **{dotted-circle}** No | Set target branch.
| `/title <new title>`                                                                             | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes | Change title.
| `/timeline <timeline comment> \| <date(YYYY-MM-DD)> <time(HH:MM)>`                               | **{check-circle}** Yes | **{dotted-circle}** No | **{dotted-circle}** No | Add a timeline event to this incident. For example, `/timeline DB load spiked \| 2022-09-07 09:30`. ([introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/368721) in GitLab 15.4). |
| `/todo`                                                                                          | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes | Add a to-do item.
| `/unapprove`                                                                                     | **{dotted-circle}** No | **{check-circle}** Yes | **{dotted-circle}** No | Unapprove the merge request. ([introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/8103) in GitLab 14.3.
| `/unassign @user1 @user2`                                                                        | **{check-circle}** Yes | **{check-circle}** Yes | **{dotted-circle}** No | Remove specific assignees.
| `/unassign`                                                                                      | **{dotted-circle}** No | **{check-circle}** Yes | **{dotted-circle}** No | Remove all assignees.
| `/unassign_reviewer @user1 @user2` or `/remove_reviewer @user1 @user2`                           | **{dotted-circle}** No | **{check-circle}** Yes | **{dotted-circle}** No | Remove specific reviewers.
| `/unassign_reviewer me`                                                                          | **{dotted-circle}** No | **{check-circle}** Yes | **{dotted-circle}** No | Remove yourself as a reviewer.
| `/unassign_reviewer` or `/remove_reviewer`                                                       | **{dotted-circle}** No | **{check-circle}** Yes | **{dotted-circle}** No | Remove all reviewers.
| `/unlabel ~label1 ~label2` or `/remove_label ~label1 ~label2`                                    | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes | Remove specified labels.
| `/unlabel` or `/remove_label`                                                                    | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes | Remove all labels.
| `/unlock`                                                                                        | **{check-circle}** Yes | **{check-circle}** Yes | **{dotted-circle}** No | Unlock the discussions.
| `/unsubscribe`                                                                                   | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes | Unsubscribe from notifications.
| `/weight <value>`                                                                                | **{check-circle}** Yes | **{dotted-circle}** No | **{dotted-circle}** No | Set weight. Valid options for `<value>` include `0`, `1`, `2`, and so on.
| `/zoom <Zoom URL>`                                                                               | **{check-circle}** Yes | **{dotted-circle}** No | **{dotted-circle}** No | Add a Zoom meeting to this issue or incident. In [GitLab 15.3 and later](https://gitlab.com/gitlab-org/gitlab/-/issues/230853) users on GitLab Premium can add a short description when [adding a Zoom link to an incident](../../operations/incident_management/linked_resources.md#link-zoom-meetings-from-an-incident).

## Work items

> Executing quick actions from comments [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/391282) in GitLab 15.10.

Work items in GitLab include [tasks](../tasks.md) and [OKRs](../okrs.md).
The following quick actions can be applied through the description field when editing or commenting on work items.

| Command                                                                                          | Task                  | Objective          | Key Result                   | Action
|:-------------------------------------------------------------------------------------------------|:-----------------------|:-----------------------|:-----------------------|:-------|
| `/title <new title>`                                                                             | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes | Change title.
| `/close`                                                                                         | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes | Close.
| `/reopen`                                                                                        | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes | Reopen.
| `/shrug <comment>`                                                                               | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes | Append the comment with `¯\＿(ツ)＿/¯`.
| `/tableflip <comment>`                                                                           | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes | Append the comment with `(╯°□°)╯︵ ┻━┻`.
| `/cc @user`                                                                                      | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes | Mention a user. In GitLab 15.0 and later, this command performs no action. You can instead type `CC @user` or only `@user`. [In GitLab 14.9 and earlier](https://gitlab.com/gitlab-org/gitlab/-/issues/31200), mentioning a user at the start of a line creates a specific type of to-do item notification.
| `/assign @user1 @user2`                                                                          | **{check-circle}** Yes | **{check-circle}** Yes | **{dotted-circle}** Yes | Assign one or more users.
| `/assign me`                                                                                     | **{check-circle}** Yes | **{check-circle}** Yes | **{dotted-circle}** Yes | Assign yourself.
| `/unassign @user1 @user2`                                                                        | **{check-circle}** Yes | **{check-circle}** Yes | **{dotted-circle}** Yes | Remove specific assignees.
| `/unassign`                                                                                      | **{dotted-circle}** No | **{check-circle}** Yes | **{dotted-circle}** Yes | Remove all assignees.
| `/reassign @user1 @user2`                                                                        | **{check-circle}** Yes | **{check-circle}** Yes | **{dotted-circle}** Yes | Replace current assignees with those specified.
| `/label ~label1 ~label2` or `/labels ~label1 ~label2`                                            | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes | Add one or more labels. Label names can also start without a tilde (`~`), but mixed syntax is not supported.
| `/relabel ~label1 ~label2`                                                                       | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes | Replace current labels with those specified.
| `/unlabel ~label1 ~label2` or `/remove_label ~label1 ~label2`                                    | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes | Remove specified labels.
| `/unlabel` or `/remove_label`                                                                    | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes | Remove all labels.
| `/due <date>`                                                                                    | **{check-circle}** Yes | **{dotted-circle}** No | **{dotted-circle}** Yes | Set due date. Examples of valid `<date>` include `in 2 days`, `this Friday` and `December 31st`.
| `/remove_due_date`                                                                               | **{check-circle}** Yes | **{dotted-circle}** No | **{dotted-circle}** Yes | Remove due date.
| `/health_status <value>`                                                                         | **{check-circle}** Yes | **{dotted-circle}** Yes | **{dotted-circle}** Yes | Set [health status](issues/managing_issues.md#health-status). Valid options for `<value>` are `on_track`, `needs_attention`, and `at_risk`.
| `/clear_health_status`                                                                           | **{check-circle}** Yes | **{dotted-circle}** Yes | **{dotted-circle}** Yes | Clear [health status](issues/managing_issues.md#health-status).
| `/weight <value>`                                                                                | **{check-circle}** Yes | **{dotted-circle}** No | **{dotted-circle}** No | Set weight. Valid options for `<value>` include `0`, `1`, and `2`.
| `/clear_weight`                                                                                  | **{check-circle}** Yes | **{dotted-circle}** No | **{dotted-circle}** No | Clear weight.
| `/type`                                                                                          | **{check-circle}** Yes | **{dotted-circle}** Yes | **{dotted-circle}** Yes | Converts work item to specified type. Available options for `<type>` include `Issue`, `Task`, `Objective` and `Key Result`. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/385227) in GitLab 16.0 [with a flag](../../administration/feature_flags.md) named `work_items_mvc_2`. Disabled by default.

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

Each scenario can be a third-level heading, for example `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
