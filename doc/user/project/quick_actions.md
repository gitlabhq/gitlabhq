---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab quick actions
description: Commands, shortcuts, and inline actions.
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Quick actions provide text-based shortcuts for common actions in GitLab.
Quick actions:

- Execute common actions without using the user interface.
- Support working with issues, merge requests, epics, and commits.
- Run automatically when you save descriptions or comments.
- Respond to specific contexts and conditions.
- Process multiple commands when entered on separate lines.

For example, you can use quick actions to:

- Assign users.
- Add labels.
- Set due dates.
- Change status.
- Set other attributes.

Each command starts with a forward slash (`/`) and must be entered on a separate line.
Many quick actions accept parameters, which you can enter with quotation marks (`"`) or specific formatting.

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

{{< history >}}

- `/cc` quick action [removed](https://gitlab.com/gitlab-org/gitlab/-/issues/369571) in GitLab 18.3.

{{< /history >}}

The following quick actions are applicable to descriptions, discussions, and
threads. Some quick actions might not be available to all subscription tiers.

<!--
Keep this table sorted alphabetically

To auto-format this table, use the VS Code Markdown Table formatter: `https://docs.gitlab.com/ee/development/documentation/styleguide/#editor-extensions-for-table-formatting`.
-->

| Command                                                                                         | Issue       | Merge request | Epic        | Action |
|:------------------------------------------------------------------------------------------------|:------------|:--------------|:------------|:-------|
| `/add_child <item>`                                                                             | {{< yes >}} | {{< no >}}    | {{< yes >}} | Add `<item>` as a child item. The `<item>` value should be in the format of `#item`, `group/project#item`, or a URL to the item. For issues, you can add tasks and OKRs. For epics, you can add issues, tasks, and OKRs. Multiple work items can be added as child items at the same time. |
| `/add_contacts [contact:email1@example.com] [contact:email2@example.com]`                       | {{< yes >}} | {{< no >}}    | {{< no >}}  | Add one or more active [CRM contacts](../crm/_index.md). |
| `/add_email email1 email2`                                                                      | {{< yes >}} | {{< no >}}    | {{< no >}}  | Add up to six [email participants](service_desk/external_participants.md). This action is behind the feature flag `issue_email_participants`. Not supported in [issue templates](description_templates.md). |
| `/approve`                                                                                      | {{< no >}}  | {{< yes >}}   | {{< no >}}  | Approve the merge request. |
| `/assign @user1 @user2`                                                                         | {{< yes >}} | {{< yes >}}   | {{< no >}}  | Assign one or more users. |
| `/assign me`                                                                                    | {{< yes >}} | {{< yes >}}   | {{< no >}}  | Assign yourself. |
| `/assign_reviewer @user1 @user2` or `/reviewer @user1 @user2`                                   | {{< no >}}  | {{< yes >}}   | {{< no >}}  | Assign one or more users as reviewers. |
| `/assign_reviewer me` or `/reviewer me`                                                         | {{< no >}}  | {{< yes >}}   | {{< no >}}  | Assign yourself as a reviewer. |
| `/blocked_by <item1> <item2>`                                                                   | {{< yes >}} | {{< no >}}    | {{< yes >}} | Mark the item as blocked by other items. The `<item>` value should be in the format of `#item`, `group/project#item`, or the full URL. ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/214232) in GitLab 16.0). |
| `/blocks <item1> <item2>`                                                                       | {{< yes >}} | {{< no >}}    | {{< yes >}} | Mark the item as blocking other items. The `<item>` value should be in the format of `#item`, `group/project#item`, or the full URL. ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/214232) in GitLab 16.0). |
| `/board_move ~column`                                                                           | {{< yes >}} | {{< no >}}    | {{< no >}}  | Move issue to column on the board. The project must have only one issue board. |
| `/clear_health_status`                                                                          | {{< yes >}} | {{< no >}}    | {{< yes >}} | Clear [health status](issues/managing_issues.md#health-status). |
| `/clear_weight`                                                                                 | {{< yes >}} | {{< no >}}    | {{< no >}}  | Clear weight. |
| `/clone <path/to/group_or_project> [--with_notes]`                                              | {{< yes >}} | {{< no >}}    | {{< yes >}} | Clone the work item to a given group or project, or the current one if no arguments are given. Copies as much data as possible as long as the target contains equivalent objects like labels, milestones, or epics. Does not copy comments or system notes unless `--with_notes` is provided as an argument. |
| `/close`                                                                                        | {{< yes >}} | {{< yes >}}   | {{< yes >}} | Close. |
| `/confidential`                                                                                 | {{< yes >}} | {{< no >}}    | {{< yes >}} | Mark issue or epic as confidential. |
| `/convert_to_ticket <email address>`                                                            | {{< yes >}} | {{< no >}}    | {{< no >}}  | [Convert an issue into a Service Desk ticket](service_desk/using_service_desk.md#convert-a-regular-issue-to-a-service-desk-ticket). [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/433376) in GitLab 16.9 |
| `/copy_metadata <!merge_request>`                                                               | {{< yes >}} | {{< yes >}}   | {{< no >}}  | Copy labels and milestone from another merge request in the project. |
| `/copy_metadata <#item>`                                                                        | {{< yes >}} | {{< yes >}}   | {{< yes >}} | Copy labels and milestone from another item in the project. |
| `/create_merge_request <branch name>`                                                           | {{< yes >}} | {{< no >}}    | {{< no >}}  | Create a new merge request starting from the current issue. |
| `/done`                                                                                         | {{< yes >}} | {{< yes >}}   | {{< yes >}} | Mark to-do item as done. |
| `/draft`                                                                                        | {{< no >}}  | {{< yes >}}   | {{< no >}}  | Set the [draft status](merge_requests/drafts.md). |
| `/due <date>`                                                                                   | {{< yes >}} | {{< no >}}    | {{< yes >}} | Set due date. Examples of valid `<date>` include `in 2 days`, `this Friday` and `December 31st`. See [Chronic](https://gitlab.com/gitlab-org/ruby/gems/gitlab-chronic#examples) for more examples. |
| `/duplicate <item>`                                                                             | {{< yes >}} | {{< no >}}    | {{< yes >}} | Close this item and mark as related to, and a duplicate of, `<item>`. |
| `/epic <epic>` or `/set_parent <epic>`                                                          | {{< yes >}} | {{< no >}}    | {{< yes >}} | Add to epic `<epic>` as a child item. The `<epic>` value should be in the format of `&epic`, `#epic`, `group&epic`, `group#epic`, or a URL to an epic. |
| `/estimate <time>` or `/estimate_time <time>`                                                   | {{< yes >}} | {{< yes >}}   | {{< yes >}} | Set time estimate. For example, `/estimate 1mo 2w 3d 4h 5m`. For more information, see [Time tracking](time_tracking.md). |
| `/health_status <value>`                                                                        | {{< yes >}} | {{< no >}}    | {{< yes >}} | Set [health status](issues/managing_issues.md#health-status). Valid options for `<value>` are `on_track`, `needs_attention`, and `at_risk`. |
| `/iteration *iteration:<iteration ID> or <iteration name>`                                      | {{< yes >}} | {{< no >}}    | {{< no >}}  | Set iteration. For example, to set the `Late in July` iteration: `/iteration *iteration:"Late in July"`. |
| `/iteration [cadence:<iteration cadence ID> or <iteration cadence name>] <--current or --next>` | {{< yes >}} | {{< no >}}    | {{< no >}}  | Set iteration to the current or next upcoming iteration of the referenced iteration cadence. For example, `/iteration [cadence:"Team cadence"] --current` sets the iteration to the current iteration of the iteration cadence named "Team cadence". [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/384885) in GitLab 16.9. |
| `/iteration <--current or --next>`                                                              | {{< yes >}} | {{< no >}}    | {{< no >}}  | Set iteration to the current or next upcoming iteration when a group has one iteration cadence. For example, `/iteration --current` sets the iteration to the current iteration of the iteration cadence. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/384885) in GitLab 16.9. |
| `/label ~label1 ~label2` or `/labels ~label1 ~label2`                                           | {{< yes >}} | {{< yes >}}   | {{< yes >}} | Add one or more labels. Label names can also start without a tilde (`~`), but mixed syntax is not supported. |
| `/link`                                                                                         | {{< yes >}} | {{< no >}}    | {{< no >}}  | Add a link and description to [linked resources](../../operations/incident_management/linked_resources.md) in an incident. |
| `/lock`                                                                                         | {{< yes >}} | {{< yes >}}   | {{< yes >}} | Lock the discussions. |
| `/merge`                                                                                        | {{< no >}}  | {{< yes >}}   | {{< no >}}  | Merge changes. Depending on the project setting, this may be [when the pipeline succeeds](merge_requests/auto_merge.md), or adding to a [Merge Train](../../ci/pipelines/merge_trains.md). |
| `/milestone %milestone`                                                                         | {{< yes >}} | {{< yes >}}   | {{< no >}}  | Set milestone. |
| `/move <path/to/group_or_project>`                                                              | {{< yes >}} | {{< no >}}    | {{< yes >}} | Move the work item to another group or project. Be careful when moving a work item to a location with different access rules. Before moving the work item, make sure it does not contain sensitive data. |
| `/page <policy name>`                                                                           | {{< yes >}} | {{< no >}}    | {{< no >}}  | Start escalations for the incident. |
| `/promote_to_incident`                                                                          | {{< yes >}} | {{< no >}}    | {{< no >}}  | Promote issue to incident. You can also use the quick action when creating a new issue. |
| `/promote to <type>`                                                                            | {{< yes >}} | {{< no >}}    | {{< no >}}  | Promote issue to `<type>`: `Epic` or `Incident`. |
| `/publish`                                                                                      | {{< yes >}} | {{< no >}}    | {{< no >}}  | Publish issue to an associated [Status Page](../../operations/incident_management/status_page.md). |
| `/react :emoji:`                                                                                | {{< yes >}} | {{< yes >}}   | {{< yes >}} | Toggle an emoji reaction. [Renamed](https://gitlab.com/gitlab-org/gitlab/-/issues/409884) from `/award` in GitLab 16.7. `/award` is still available as an aliased command. |
| `/ready`                                                                                        | {{< no >}}  | {{< yes >}}   | {{< no >}}  | Set the [ready status](merge_requests/drafts.md#mark-merge-requests-as-ready). |
| `/reassign @user1 @user2`                                                                       | {{< yes >}} | {{< yes >}}   | {{< no >}}  | Replace current assignees with those specified. |
| `/reassign_reviewer @user1 @user2`                                                              | {{< no >}}  | {{< yes >}}   | {{< no >}}  | Replace current reviewers with those specified. |
| `/rebase`                                                                                       | {{< no >}}  | {{< yes >}}   | {{< no >}}  | Rebase source branch on the latest commit of the target branch. For help, see [troubleshooting information](../../topics/git/troubleshooting_git.md). |
| `/relabel ~label1 ~label2`                                                                      | {{< yes >}} | {{< yes >}}   | {{< yes >}} | Replace current labels with those specified. |
| `/relate <item1> <item2>`                                                                       | {{< yes >}} | {{< no >}}    | {{< yes >}} | Mark items as related. The `<item>` value should be in the format of `#item`, `group/project#item`, or the full URL. |
| `/remove_child <item>`                                                                          | {{< yes >}} | {{< no >}}    | {{< yes >}} | Remove `<item>` as child item. The `<item>` value should be in the format of `#item`, `group/project#item`, or a URL to the item. |
| `/remove_contacts [contact:email1@example.com] [contact:email2@example.com]`                    | {{< yes >}} | {{< no >}}    | {{< no >}}  | Remove one or more [CRM contacts](../crm/_index.md) |
| `/remove_due_date`                                                                              | {{< yes >}} | {{< no >}}    | {{< no >}}  | Remove due date. |
| `/remove_email email1 email2`                                                                   | {{< yes >}} | {{< no >}}    | {{< no >}}  | Remove up to six [email participants](service_desk/external_participants.md). This action is behind the feature flag `issue_email_participants`. Not supported in issue templates, merge requests, or epics. |
| `/remove_estimate` or `/remove_time_estimate`                                                   | {{< yes >}} | {{< yes >}}   | {{< yes >}} | Remove time estimate. |
| `/remove_iteration`                                                                             | {{< yes >}} | {{< no >}}    | {{< no >}}  | Remove iteration. |
| `/remove_milestone`                                                                             | {{< yes >}} | {{< yes >}}   | {{< no >}}  | Remove milestone. |
| `/remove_parent`                                                                                | {{< yes >}} | {{< no >}}    | {{< yes >}} | Remove the parent from item. |
| `/remove_time_spent`                                                                            | {{< yes >}} | {{< yes >}}   | {{< yes >}} | Remove time spent. |
| `/remove_zoom`                                                                                  | {{< yes >}} | {{< no >}}    | {{< no >}}  | Remove Zoom meeting from this issue. |
| `/reopen`                                                                                       | {{< yes >}} | {{< yes >}}   | {{< yes >}} | Reopen. |
| `/request_review @user1 @user2`                                                                 | {{< no >}}  | {{< yes >}}   | {{< no >}}  | Assigns or requests a new review from one or more users. |
| `/request_review me`                                                                            | {{< no >}}  | {{< yes >}}   | {{< no >}}  | Assigns or requests a new review from one or more users. |
| `/ship`                                                                                         | {{< no >}}  | {{< yes >}}   | {{< no >}}  | Create a merge request pipeline and set auto-merge. This is an experimental feature. This action is behind the feature flag `ship_mr_quick_action`, which is disabled by default. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/78998) in GitLab 18.6. |
| `/set_parent <item>`                                                                            | {{< yes >}} | {{< no >}}    | {{< yes >}} | Set parent item. The `<item>` value should be in the format of `#IID`, reference, or a URL to an item. |
| `/severity <severity>`                                                                          | {{< yes >}} | {{< no >}}    | {{< no >}}  | Set the severity. Issue type must be `Incident`. Options for `<severity>` are `S1` ... `S4`, `critical`, `high`, `medium`, `low`, `unknown`. |
| `/shrug`                                                                                        | {{< yes >}} | {{< yes >}}   | {{< yes >}} | Add `¯\＿(ツ)＿/¯`. |
| `/spend <time> [<date>]` or `/spend_time <time> [<date>]`                                       | {{< yes >}} | {{< yes >}}   | {{< yes >}} | Add or subtract spent time. Optionally, specify the date that time was spent on. For example, `/spend 1mo 2w 3d 4h 5m 2018-08-26` or `/spend -1h 30m`. For more information, see [Time tracking](time_tracking.md). |
| `/status <value>`                                                                               | {{< yes >}} | {{< no >}}    | {{< no >}}  | Set [status](../work_items/status.md). Valid options for `<value>` include status options set for the namespace. |
| `/submit_review`                                                                                | {{< no >}}  | {{< yes >}}   | {{< no >}}  | Submit a pending review. |
| `/subscribe`                                                                                    | {{< yes >}} | {{< yes >}}   | {{< yes >}} | Subscribe to notifications. |
| `/tableflip`                                                                                    | {{< yes >}} | {{< yes >}}   | {{< yes >}} | Add `(╯°□°)╯︵ ┻━┻`. |
| `/target_branch <local branch name>`                                                            | {{< no >}}  | {{< yes >}}   | {{< no >}}  | Set target branch. |
| `/timeline <timeline comment> \| <date(YYYY-MM-DD)> <time(HH:MM)>`                              | {{< yes >}} | {{< no >}}    | {{< no >}}  | Add a timeline event to this incident. For example, `/timeline DB load spiked \| 2022-09-07 09:30`. |
| `/title <new title>`                                                                            | {{< yes >}} | {{< yes >}}   | {{< yes >}} | Change title. |
| `/todo`                                                                                         | {{< yes >}} | {{< yes >}}   | {{< yes >}} | Add a to-do item. |
| `/unapprove`                                                                                    | {{< no >}}  | {{< yes >}}   | {{< no >}}  | Unapprove the merge request. |
| `/unassign @user1 @user2`                                                                       | {{< yes >}} | {{< yes >}}   | {{< no >}}  | Remove specific assignees. |
| `/unassign_reviewer @user1 @user2` or `/remove_reviewer @user1 @user2`                          | {{< no >}}  | {{< yes >}}   | {{< no >}}  | Remove specific reviewers. |
| `/unassign_reviewer me`                                                                         | {{< no >}}  | {{< yes >}}   | {{< no >}}  | Remove yourself as a reviewer. |
| `/unassign_reviewer` or `/remove_reviewer`                                                      | {{< no >}}  | {{< yes >}}   | {{< no >}}  | Remove all reviewers. |
| `/unassign`                                                                                     | {{< no >}}  | {{< yes >}}   | {{< no >}}  | Remove all assignees. |
| `/unlabel ~label1 ~label2` or `/remove_label ~label1 ~label2`                                   | {{< yes >}} | {{< yes >}}   | {{< yes >}} | Remove specified labels. |
| `/unlabel` or `/remove_label`                                                                   | {{< yes >}} | {{< yes >}}   | {{< yes >}} | Remove all labels. |
| `/unlink <item>`                                                                                | {{< yes >}} | {{< no >}}    | {{< yes >}} | Remove link with to the provided issue. The `<item>` value should be in the format of `#item`, `group/project#item`, or the full URL. ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/414400) in GitLab 16.1). |
| `/unlock`                                                                                       | {{< yes >}} | {{< yes >}}   | {{< yes >}} | Unlock the discussions. |
| `/unsubscribe`                                                                                  | {{< yes >}} | {{< yes >}}   | {{< yes >}} | Unsubscribe from notifications. |
| `/weight <value>`                                                                               | {{< yes >}} | {{< no >}}    | {{< no >}}  | Set weight. Valid values are integers like `0`, `1`, or `2`. |
| `/zoom <Zoom URL>`                                                                              | {{< yes >}} | {{< no >}}    | {{< no >}}  | Add a Zoom meeting to this issue or incident. Users on GitLab Premium can add a short description when [adding a Zoom link to an incident](../../operations/incident_management/linked_resources.md#link-zoom-meetings-from-an-incident). |

## Work items

{{< history >}}

- Epics as work items [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/468310) in GitLab 18.1.

{{< /history >}}

Work items in GitLab include:

- [Tasks](../tasks.md)
- [OKRs](../okrs.md)
- [Epics](../group/epics/_index.md) (see [Issues, merge requests, and epics](#issues-merge-requests-and-epics))

The following quick actions can be applied through the description field when editing or commenting on work items.

<!--
Keep this table sorted alphabetically

To auto-format this table, use the VS Code Markdown Table formatter: `https://docs.gitlab.com/ee/development/documentation/styleguide/#editor-extensions-for-table-formatting`.
-->

| Command                                                       | Task        | Objective   | Key Result  | Action |
|:--------------------------------------------------------------|:------------|:------------|:------------|:-------|
| `/assign @user1 @user2`                                       | {{< yes >}} | {{< yes >}} | {{< yes >}} | Assign one or more users. |
| `/assign me`                                                  | {{< yes >}} | {{< yes >}} | {{< yes >}} | Assign yourself. |
| `/add_child <work_item>`                                      | {{< no >}}  | {{< yes >}} | {{< no >}}  | Add child to `<work_item>`. The `<work_item>` value should be in the format of `#item`, `group/project#item`, or a URL to a work item. Multiple work items can be added as child items at the same time. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/420797) in GitLab 16.5. |
| `/award :emoji:`                                              | {{< yes >}} | {{< yes >}} | {{< yes >}} | Toggle an emoji reaction. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/412275) in GitLab 16.5 |
| `/checkin_reminder <cadence>`                                 | {{< no >}}  | {{< yes >}} | {{< no >}}  | Schedule [check-in reminders](../okrs.md#schedule-okr-check-in-reminders). Options are `weekly`, `twice-monthly`, `monthly`, or `never` (default). [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/422761) in GitLab 16.4 with flags named `okrs_mvc` and `okr_checkin_reminders`. |
| `/clear_health_status`                                        | {{< yes >}} | {{< yes >}} | {{< yes >}} | Clear [health status](issues/managing_issues.md#health-status). |
| `/clear_weight`                                               | {{< yes >}} | {{< no >}}  | {{< no >}}  | Clear weight. |
| `/close`                                                      | {{< yes >}} | {{< yes >}} | {{< yes >}} | Close. |
| `/confidential`                                               | {{< yes >}} | {{< yes >}} | {{< yes >}} | Mark work item as confidential.  [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/412276) in GitLab 16.4. |
| `/copy_metadata <work_item>`                                  | {{< yes >}} | {{< yes >}} | {{< yes >}} | Copy labels and milestone from another work item in the same namespace. The `<work_item>` value should be in the format of `#item` or a URL to a work item. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/509076) in GitLab 17.9. |
| `/done`                                                       | {{< yes >}} | {{< yes >}} | {{< yes >}} | Mark to-do item as done. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/412277) in GitLab 16.2. |
| `/due <date>`                                                 | {{< yes >}} | {{< no >}}  | {{< yes >}} | Set due date. Examples of valid `<date>` include `in 2 days`, `this Friday` and `December 31st`. |
| `/health_status <value>`                                      | {{< yes >}} | {{< yes >}} | {{< yes >}} | Set [health status](issues/managing_issues.md#health-status). Valid options for `<value>` are `on_track`, `needs_attention`, or `at_risk`. |
| `/label ~label1 ~label2` or `/labels ~label1 ~label2`         | {{< yes >}} | {{< yes >}} | {{< yes >}} | Add one or more labels. Label names can also start without a tilde (`~`), but mixed syntax is not supported. |
| `/promote_to <type>`                                          | {{< yes >}} | {{< no >}}  | {{< yes >}} | Promotes work item to specified type. Available options for `<type>`: `issue` (promote a task), `objective` (promote a key result), `epic` (promote an issue). [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/412534) in GitLab 16.1. |
| `/reassign @user1 @user2`                                     | {{< yes >}} | {{< yes >}} | {{< yes >}} | Replace current assignees with those specified. |
| `/relabel ~label1 ~label2`                                    | {{< yes >}} | {{< yes >}} | {{< yes >}} | Replace current labels with those specified. |
| `/remove_due_date`                                            | {{< yes >}} | {{< no >}}  | {{< yes >}} | Remove due date. |
| `/remove_child <work_item>`                                   | {{< no >}}  | {{< yes >}} | {{< no >}}  | Remove the child `<work_item>`. The `<work_item>` value should be in the format of `#item`, `group/project#item`, or a URL to a work item. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/132761) in GitLab 16.10. |
| `/remove_parent`                                              | {{< yes >}} | {{< no >}}  | {{< yes >}} | Removes the parent work item. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/434344) in GitLab 16.9. |
| `/reopen`                                                     | {{< yes >}} | {{< yes >}} | {{< yes >}} | Reopen. |
| `/set_parent <work_item>`                                     | {{< yes >}} | {{< no >}}  | {{< yes >}} | Set parent work item to `<work_item>`. The `<work_item>` value should be in the format of `#item`, `group/project#item`, or a URL to a work item. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/420798) in GitLab 16.5. Alias `/epic` for issues [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/514942) in GitLab 17.10. |
| `/shrug`                                                      | {{< yes >}} | {{< yes >}} | {{< yes >}} | Add `¯\＿(ツ)＿/¯`. |
| `/status <value>`                                             | {{< yes >}} | {{< no >}}  | {{< no >}}  | Set [status](../work_items/status.md). Valid options for `<value>` include status options set for the namespace. |
| `/subscribe`                                                  | {{< yes >}} | {{< yes >}} | {{< yes >}} | Subscribe to notifications. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/420796) in GitLab 16.4 |
| `/tableflip`                                                  | {{< yes >}} | {{< yes >}} | {{< yes >}} | Add `(╯°□°)╯︵ ┻━┻`. |
| `/title <new title>`                                          | {{< yes >}} | {{< yes >}} | {{< yes >}} | Change title. |
| `/todo`                                                       | {{< yes >}} | {{< yes >}} | {{< yes >}} | Add a to-do item. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/412277) in GitLab 16.2. |
| `/type`                                                       | {{< yes >}} | {{< yes >}} | {{< yes >}} | Converts work item to specified type. Available options for `<type>` include `issue`, `task`, `objective` and `key result`. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/385227) in GitLab 16.0. |
| `/unassign @user1 @user2`                                     | {{< yes >}} | {{< yes >}} | {{< yes >}} | Remove specific assignees. |
| `/unassign`                                                   | {{< no >}}  | {{< yes >}} | {{< yes >}} | Remove all assignees. |
| `/unlabel ~label1 ~label2` or `/remove_label ~label1 ~label2` | {{< yes >}} | {{< yes >}} | {{< yes >}} | Remove specified labels. |
| `/unlabel` or `/remove_label`                                 | {{< yes >}} | {{< yes >}} | {{< yes >}} | Remove all labels. |
| `/unlink`                                                     | {{< yes >}} | {{< yes >}} | {{< yes >}} | Remove link to the provided work item. The `<work item>` value should be in the format of `#work_item`, `group/project#work_item`, or the full work item URL. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/481851) in GitLab 17.8. |
| `/unsubscribe`                                                | {{< yes >}} | {{< yes >}} | {{< yes >}} | Unsubscribe to notifications. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/420796) in GitLab 16.4 |
| `/weight <value>`                                             | {{< yes >}} | {{< no >}}  | {{< no >}}  | Set weight. Valid options for `<value>` include `0`, `1`, and `2`. |

## Commit comments

You can use quick actions when commenting on individual commits. These quick actions work only in
commit comment threads, not in commit messages or other GitLab contexts.

To use quick actions in commit comments:

1. Go to a commit page by selecting a commit from the commits list, merge request,
   or other commit links.
1. In the comment form at the bottom of the commit page, enter your quick action.
1. Select **Comment**.

The following quick actions are applicable for commit comments:

| Command                 | Action                                    |
|:----------------------- |:------------------------------------------|
| `/tag v1.2.3 <message>` | Creates a Git tag pointing to the commented commit, with an optional message. |

Here is an example Git tag:

```plaintext
Ready for release after security fix.
/tag v2.1.1 Security patch release
```

This comment creates a Git tag named `v2.1.1` pointing to the commit, with the
message "Security patch release".

## Troubleshooting

### Quick action isn't executed

If you run a quick action, but nothing happens, check if the quick action appears in the autocomplete
box as you type it.
If it doesn't, it's possible that:

- The feature related to the quick action isn't available to you based on your subscription tier or
  user role for the group or project.
- A required condition for the quick action isn't met.
  For example, you're running `/unlabel` on an issue without any labels.
