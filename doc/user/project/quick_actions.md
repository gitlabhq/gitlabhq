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

## Quick actions

{{< history >}}

- Epics as work items [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/468310) in GitLab 18.1.
- `/cc` quick action [removed](https://gitlab.com/gitlab-org/gitlab/-/issues/369571) in GitLab 18.3.

{{< /history >}}

The following quick actions are applicable to descriptions, discussions, and
threads. Some quick actions might not be available to all subscription tiers.

### `add_child`

Add one or more items as child items.

**Availability**:

- Epic (add issues, tasks, objectives, or key results)
- Issue (add tasks, objectives, or key results)
- Objective (add objectives or key results)

**Parameters**:

- `<item>`: The item to add as a child. The value should be in the format of `#item`, `group/project#item`, or a URL to the item.
  Multiple work items can be added as child items at the same time.

**Examples**:

- Add a single child item:

  ```plaintext
  /add_child #123
  ```

- Add multiple child items:

  ```plaintext
  /add_child #123 #456 group/project#789
  ```

- Add a child item using a URL:

  ```plaintext
  /add_child https://gitlab.com/group/project/-/work_items/123
  ```

### `add_contacts`

Add one or more active CRM contacts.

**Availability**:

- Issue

**Parameters**:

- `[contact:email1@example.com]`: One or more contact emails in the format `contact:email@example.com`.

**Examples**:

- Add a single contact:

  ```plaintext
  /add_contacts [contact:alex@example.com]
  ```

- Add multiple contacts:

  ```plaintext
  /add_contacts [contact:alex@example.com] [contact:sam@example.com]
  ```

**Additional details**:

- For more information, see [CRM contacts](../crm/_index.md).

### `add_email`

Add up to six email participants.

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/350460) in GitLab 13.8 [with a flag](../../administration/feature_flags/list.md) named `issue_email_participants`. Enabled by default.

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by a feature flag. For more information, see the history.

{{< /alert >}}

**Availability**:

- Incident
- Issue

**Parameters**:

- `email1 email2`: One or more email addresses, separated by spaces.

**Examples**:

- Add a single email participant:

  ```plaintext
  /add_email alex@example.com
  ```

- Add multiple email participants:

  ```plaintext
  /add_email alex@example.com sam@example.com
  ```

**Additional details**:

- Not supported in [issue templates](description_templates.md).
- For more information, see [email participants](service_desk/external_participants.md).

### `approve`

Approve the merge request.

**Availability**:

- Merge request

**Examples**:

- Approve a merge request:

  ```plaintext
  /approve
  ```

**Additional details**:

- To unapprove a merge request, use [`/unapprove`](#unapprove).

### `assign`

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/551805) for epics in GitLab 18.2.

{{< /history >}}

Assign one or more users to the work item.

**Availability**:

- Epic
- Incident
- Issue
- Merge request
- Task
- Objective
- Key Result

**Parameters**:

- `@user1 @user2`: One or more usernames to assign. Usernames must be prefixed with `@`.
- `me`: Assign yourself to the work item.

**Examples**:

- Assign a single user:

  ```plaintext
  /assign @alex
  ```

- Assign multiple users:

  ```plaintext
  /assign @alex @sam
  ```

- Assign yourself:

  ```plaintext
  /assign me
  ```

**Additional details**:

- You can assign multiple users in a single command by separating usernames with spaces.
- To remove assignees, use [`/unassign`](#unassign).
- To replace assignees, use [`/reassign`](#reassign).

### `assign_reviewer`

Assign one or more users as reviewers.

**Availability**:

- Merge request

**Parameters**:

- `@user1 @user2`: One or more usernames to assign as reviewers. Usernames must be prefixed with `@`.
- `me`: Assign yourself as a reviewer.

**Examples**:

- Assign a single reviewer:

  ```plaintext
  /assign_reviewer @alex
  ```

- Assign multiple reviewers:

  ```plaintext
  /assign_reviewer @alex @sam
  ```

- Assign yourself as a reviewer:

  ```plaintext
  /assign_reviewer me
  ```

**Additional details**:

- You can assign multiple users in a single command by separating usernames with spaces.
- `/reviewer` is an alias for `/assign_reviewer`.
- To replace reviewers, use [`/reassign_reviewer`](#reassign_reviewer).
- To remove reviewers, use [`/unassign_reviewer`](#unassign_reviewer).

### `award`

Toggle an emoji reaction.

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/412275) in GitLab 16.5 for tasks, objectives, and key results.

{{< /history >}}

**Availability**:

- Task
- Objective
- Key Result

**Parameters**:

- `:emoji:`: The emoji to toggle. Must be in the format `:emoji_name:`.

**Examples**:

- Toggle a thumbs up reaction:

  ```plaintext
  /award :thumbsup:
  ```

- Toggle a heart reaction:

  ```plaintext
  /award :heart:
  ```

**Additional details**:

- `/award` is an alias of `/react`.
- For more information, see [emoji reactions](../emoji_reactions.md).

### `blocked_by`

Mark the item as blocked by other items.

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/214232) in GitLab 16.0.

{{< /history >}}

**Availability**:

- Epic
- Incident
- Issue

**Parameters**:

- `<item1> <item2>`: One or more items that block this item. The value should be in the format of `#item`, `group/project#item`, or the full URL.

**Examples**:

- Mark as blocked by a single item:

  ```plaintext
  /blocked_by #123
  ```

- Mark as blocked by multiple items:

  ```plaintext
  /blocked_by #123 group/project#456
  ```

- Mark as blocked by an item using a URL:

  ```plaintext
  /blocked_by https://gitlab.com/group/project/-/work_items/123
  ```

**Additional details**:

- To remove the blocking relationship, use [`/unlink`](#unlink).
- To mark the items as related, none blocking the other, use [`/relate`](#relate).

### `blocks`

Mark the item as blocking other items.

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/214232) in GitLab 16.0.

{{< /history >}}

**Availability**:

- Epic
- Incident
- Issue

**Parameters**:

- `<item1> <item2>`: One or more items that this item blocks. The value should be in the format of `#item`, `group/project#item`, or the full URL.

**Examples**:

- Mark as blocking a single item:

  ```plaintext
  /blocks #123
  ```

- Mark as blocking multiple items:

  ```plaintext
  /blocks #123 group/project#456
  ```

- Mark as blocking an item using a URL:

  ```plaintext
  /blocks https://gitlab.com/group/project/-/work_items/123
  ```

**Additional details**:

- To remove the blocking relationship, use [`/unlink`](#unlink).
- To mark the items as related, none blocking the other, use [`/relate`](#relate).

### `board_move`

Move issue to a column on the board.

**Availability**:

- Issue

**Parameters**:

- `~column`: The label name of the board column to move the issue to. Must be prefixed with `~`.

**Examples**:

- Move to a column:

  ```plaintext
  /board_move ~"In Progress"
  ```

**Additional details**:

- The project must have only one issue board.

### `checkin_reminder`

Schedule check-in reminders for objectives.

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/422761) in GitLab 16.4 with flags named `okrs_mvc` and `okr_checkin_reminders`. Disabled by default.

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by a feature flag. For more information, see the history.

{{< /alert >}}

**Availability**:

- Objective

**Parameters**:

- `<cadence>`: The reminder cadence. Options are:
  - `weekly`
  - `twice-monthly`
  - `monthly`
  - `never` (default)

**Examples**:

- Set weekly reminders:

  ```plaintext
  /checkin_reminder weekly
  ```

- Disable reminders:

  ```plaintext
  /checkin_reminder never
  ```

**Additional details**:

- For more information, see [schedule OKR check-in reminders](../okrs.md#schedule-okr-check-in-reminders).

### `clear_health_status`

Clear the health status.

**Availability**:

- Epic
- Issue
- Task
- Objective
- Key Result

**Examples**:

- Clear health status:

  ```plaintext
  /clear_health_status
  ```

**Additional details**:

- For more information, see [health status](issues/managing_issues.md#health-status).

### `clear_weight`

Clear the weight.

**Availability**:

- Issue
- Task

**Examples**:

- Clear weight:

  ```plaintext
  /clear_weight
  ```

### `clone`

Clone the work item to a given group or project.

**Availability**:

- Epic
- Incident
- Issue

**Parameters**:

- `<path/to/group_or_project>`: The path to the target group or project. If not provided, clones to the current project.
- `--with_notes`: Optional flag to include comments and system notes in the clone.

**Examples**:

- Clone to another project:

  ```plaintext
  /clone group/project
  ```

- Clone to the current project:

  ```plaintext
  /clone
  ```

- Clone with notes:

  ```plaintext
  /clone group/project --with_notes
  ```

**Additional details**:

- Copies as much data as possible as long as the target contains equivalent objects like labels, milestones, or epics.
- Does not copy comments or system notes unless `--with_notes` is provided as an argument.

### `close`

Close the work item.

**Availability**:

- Epic
- Incident
- Issue
- Merge request
- Task
- Objective
- Key Result

**Examples**:

- Close a work item:

  ```plaintext
  /close
  ```

**Additional details**:

- To reopen a work item, use [`/reopen`](#reopen).

### `confidential`

Mark the work item as confidential.

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/412276) in GitLab 16.4 for tasks, objectives, and key results.

{{< /history >}}

**Availability**:

- Epic
- Incident
- Issue
- Task
- Objective
- Key Result

**Examples**:

- Mark as confidential:

  ```plaintext
  /confidential
  ```

**Additional details**:

- For more information, see [who can see confidential issues](issues/confidential_issues.md#who-can-see-confidential-issues),
  [OKRs](../okrs.md#who-can-see-confidential-okrs), or
  [tasks](../tasks.md#who-can-see-confidential-tasks).
- To make an item not confidential, in the upper-right corner, select **More actions** ({{< icon name="ellipsis_v" >}}) and then **Turn off confidentiality**.

### `convert_to_ticket`

Convert an issue into a Service Desk ticket.

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/433376) in GitLab 16.9.

{{< /history >}}

**Availability**:

- Incident
- Issue

**Parameters**:

- `<email address>`: The email address to associate with the ticket.

**Examples**:

- Convert to a ticket:

  ```plaintext
  /convert_to_ticket user@example.com
  ```

**Additional details**:

- For more information, see [convert a regular issue to a Service Desk ticket](service_desk/using_service_desk.md#convert-a-regular-issue-to-a-service-desk-ticket).

### `copy_metadata`

Copy labels and milestone from another item.

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/509076) in GitLab 17.9 for tasks, objectives, and key results.

{{< /history >}}

**Availability**:

- Epic
- Incident
- Issue
- Merge request
- Task
- Objective
- Key Result

**Parameters**:

- `<#item>`: The item to copy metadata from. For merge requests, use the format `!MR_IID`. For other items, use `#item` or a URL.

**Examples**:

- Copy metadata from an issue:

  ```plaintext
  /copy_metadata #123
  ```

- Copy metadata from a merge request:

  ```plaintext
  /copy_metadata !456
  ```

- Copy metadata from a work item using a URL:

  ```plaintext
  /copy_metadata https://gitlab.com/group/project/-/work_items/123
  ```

**Additional details**:

- The item you want to copy metadata from must be in the same namespace.

### `create_merge_request`

Create a new merge request starting from the current issue.

**Availability**:

- Incident
- Issue
- Task

**Parameters**:

- `<branch name>`: The name of the branch to create for the merge request.

**Examples**:

- Create a merge request:

  ```plaintext
  /create_merge_request fix-bug-123
  ```

### `done`

Mark a to-do item as done.

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/412277) in GitLab 16.2 for tasks, objectives, and key results.

{{< /history >}}

**Availability**:

- Epic
- Incident
- Issue
- Merge request
- Task
- Objective
- Key Result

**Examples**:

- Mark to-do as done:

  ```plaintext
  /done
  ```

### `draft`

Set the draft status of a merge request.

**Availability**:

- Merge request

**Examples**:

- Mark as draft:

  ```plaintext
  /draft
  ```

**Additional details**:

- For more information, see [draft status](merge_requests/drafts.md).

### `due`

Set the due date.

**Availability**:

- Epic
- Incident
- Issue
- Task
- Key Result

**Parameters**:

- `<date>`: The due date. Examples of valid dates include `in 2 days`, `this Friday`, and `December 31st`.

**Examples**:

- Set due date to a specific date:

  ```plaintext
  /due December 31st
  ```

- Set due date relative to today:

  ```plaintext
  /due in 2 days
  ```

- Set due date to next Friday:

  ```plaintext
  /due this Friday
  ```

**Additional details**:

- For more date format examples, see [Chronic](https://gitlab.com/gitlab-org/ruby/gems/gitlab-chronic#examples).
- To remove the due date, use [`/remove_due_date`](#remove_due_date).

### `duplicate`

Close this item and mark as related to, and a duplicate of, another item.

**Availability**:

- Epic
- Incident
- Issue

**Parameters**:

- `<item>`: The item this is a duplicate of. The value should be in the format of `#item`, `group/project#item`, or a URL.

**Examples**:

- Mark as duplicate:

  ```plaintext
  /duplicate #123
  ```

- Mark as duplicate using a URL:

  ```plaintext
  /duplicate https://gitlab.com/group/project/-/work_items/123
  ```

### `epic`

Add to an epic as a child item.

**Availability**:

- Epic
- Issue

**Parameters**:

- `<epic>`: The epic to add this item to. The value should be in the format of `&epic`, `#epic`, `group&epic`, `group#epic`, or a URL to an epic.

**Examples**:

- Add to an epic by reference:

  ```plaintext
  /epic &123
  ```

- Add to an epic by group and reference:

  ```plaintext
  /epic group&456
  ```

- Add to an epic using a URL:

  ```plaintext
  /epic https://gitlab.com/groups/group/-/epics/123
  ```

**Additional details**:

- `/set_parent` behaves the same, but is available for more work item types.

### `estimate`

Set the time estimate.

**Availability**:

- Epic
- Incident
- Issue
- Merge request

**Parameters**:

- `<time>`: The time estimate. For example, `1mo 2w 3d 4h 5m`.

**Examples**:

- Set time estimate:

  ```plaintext
  /estimate 1mo 2w 3d 4h 5m
  ```

- Set time estimate in hours:

  ```plaintext
  /estimate 8h
  ```

**Additional details**:

- `/estimate_time` is an alias for `/estimate`.
- To remove an estimate, use [`/remove_estimate`](#remove_estimate).
- For more information, see [time tracking](time_tracking.md).

### `health_status`

Set the health status.

**Availability**:

- Epic
- Issue
- Task
- Objective
- Key Result

**Parameters**:

- `<value>`: The health status value. Valid options are `on_track`, `needs_attention`, and `at_risk`.

**Examples**:

- Set health status to on track:

  ```plaintext
  /health_status on_track
  ```

- Set health status to needs attention:

  ```plaintext
  /health_status needs_attention
  ```

- Set health status to at risk:

  ```plaintext
  /health_status at_risk
  ```

**Additional details**:

- For more information, see [health status](issues/managing_issues.md#health-status).

### `iteration`

Set the iteration.

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/384885) in GitLab 16.9 for `--current` and `--next` options.

{{< /history >}}

**Availability**:

- Incident
- Issue

**Parameters**:

- `*iteration:<iteration ID> or <iteration name>`: Set to a specific iteration by ID or name.
- `[cadence:<iteration cadence ID> or <iteration cadence name>] <--current or --next>`: Set to the current or next iteration of a specific cadence.
- `--current` or `--next`: Set to the current or next iteration when a group has one iteration cadence.

**Examples**:

- Set to a specific iteration by name:

  ```plaintext
  /iteration *iteration:"Late in July"
  ```

- Set to current iteration of a cadence:

  ```plaintext
  /iteration [cadence:"Team cadence"] --current
  ```

- Set to next iteration when group has one cadence:

  ```plaintext
  /iteration --next
  ```

**Additional details**:

- To remove the iteration, use [`/remove_iteration`](#remove_iteration).

### `label`

Add one or more labels.

**Availability**:

- Epic
- Incident
- Issue
- Merge request
- Task
- Objective
- Key Result

**Parameters**:

- `~label1 ~label2`: One or more label names.
  Label names can also start without a tilde (`~`), but mixed syntax is not supported.

**Examples**:

- Add a single label:

  ```plaintext
  /label ~bug
  ```

- Add multiple labels:

  ```plaintext
  /label ~bug ~"high priority"
  ```

- Add labels without tilde:

  ```plaintext
  /label bug "high priority"
  ```

**Additional details**:

- Labels with a space in the name must be in double quotation marks.
- `/labels` is an alias for `/label`.
- To remove labels, use [`/unlabel`](#unlabel).
- To replace labels, use [`/relabel`](#relabel).

### `link`

Add a link and description to linked resources in an incident.

**Availability**:

- Incident

**Examples**:

- Add a linked resource:

  ```plaintext
  /link
  ```

**Additional details**:

- For more information, see [linked resources](../../operations/incident_management/linked_resources.md).

### `lock`

Lock the discussions.

**Availability**:

- Epic
- Incident
- Issue
- Merge request

**Examples**:

- Lock discussions:

  ```plaintext
  /lock
  ```

**Additional details**:

- To unlock the discussions, use [`/unlock`](#unlock).

### `merge`

Merge the changes.

**Availability**:

- Merge request

**Examples**:

- Merge the merge request:

  ```plaintext
  /merge
  ```

**Additional details**:

- Depending on the project setting, this may be [when the pipeline succeeds](merge_requests/auto_merge.md), or adding to a [merge train](../../ci/pipelines/merge_trains.md).
- To start a new pipeline and set auto-merge, use [`/ship`](#ship).

### `milestone`

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/329) for epics in GitLab 18.2.

{{< /history >}}

Set the milestone.

**Availability**:

- Epic
- Incident
- Issue
- Merge request

**Parameters**:

- `%milestone`: The milestone name. Must be prefixed with `%`.

**Examples**:

- Set milestone:

  ```plaintext
  /milestone %"Sprint 1"
  ```

**Additional details**:

- To remove the milestone, use [`/remove_milestone`](#remove_milestone).

### `move`

Move the work item to another group or project.

**Availability**:

- Epic
- Incident
- Issue

**Parameters**:

- `<path/to/group_or_project>`: The path to the target group or project.

**Examples**:

- Move to another project:

  ```plaintext
  /move group/project
  ```

**Additional details**:

- Be careful when moving a work item to a location with different access rules.
  Before moving the work item, make sure it does not contain sensitive data.

### `page`

Start escalations for the incident.

**Availability**:

- Incident

**Parameters**:

- `<policy name>`: The escalation policy name.

**Examples**:

- Start escalations:

  ```plaintext
  /page "On-call policy"
  ```

### `promote_to`

Promote a work item to a specified type.

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/412534) in GitLab 16.1 for tasks and key results.

{{< /history >}}

**Availability**:

- Issue
- Task
- Key Result

**Parameters**:

- `<type>`: The type to promote to. Available options:
  - `Epic` (for issues)
  - `Incident` (for issues)
  - `issue` (for tasks)
  - `objective` (for key results)

**Examples**:

- Promote issue to epic:

  ```plaintext
  /promote_to Epic
  ```

- Promote task to issue:

  ```plaintext
  /promote_to issue
  ```

- Promote key result to objective:

  ```plaintext
  /promote_to objective
  ```

**Additional details**:

- For issues, `/promote_to_incident` is a shortcut for `/promote_to Incident`.
- To change the type of work items, also use [`/type`](#type).

### `promote_to_incident`

Promote an issue to an incident.

**Availability**:

- Issue

**Examples**:

- Promote to incident:

  ```plaintext
  /promote_to_incident
  ```

**Additional details**:

- You can also use this quick action when creating a new issue.

### `publish`

Publish an issue to an associated Status Page.

**Availability**:

- Issue

**Examples**:

- Publish to status page:

  ```plaintext
  /publish
  ```

**Additional details**:

- For more information, see [Status Page](../../operations/incident_management/status_page.md).

### `react`

Toggle an emoji reaction.

{{< history >}}

- [Renamed](https://gitlab.com/gitlab-org/gitlab/-/issues/409884) from `/award` in GitLab 16.7. `/award` is still available as an aliased command.

{{< /history >}}

**Availability**:

- Epic
- Incident
- Issue
- Merge request

**Parameters**:

- `:emoji:`: The emoji to toggle. Must be in the format `:emoji_name:`.

**Examples**:

- Toggle a thumbs up reaction:

  ```plaintext
  /react :thumbsup:
  ```

- Toggle a heart reaction:

  ```plaintext
  /react :heart:
  ```

**Additional details**:

- `/award` is an alias for `/react`.

### `ready`

Set the ready status of a merge request.

**Availability**:

- Merge request

**Examples**:

- Mark as ready:

  ```plaintext
  /ready
  ```

**Additional details**:

- For more information, see [mark merge requests as ready](merge_requests/drafts.md#mark-merge-requests-as-ready).

### `reassign`

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/551805) for epics in GitLab 18.2.

{{< /history >}}

Replace current assignees with those specified.

**Availability**:

- Epic
- Incident
- Issue
- Merge request
- Task
- Objective
- Key Result

**Parameters**:

- `@user1 @user2`: One or more usernames to assign. Usernames must be prefixed with `@`.

**Examples**:

- Reassign to a single user:

  ```plaintext
  /reassign @alex
  ```

- Reassign to multiple users:

  ```plaintext
  /reassign @alex @sam
  ```

**Additional details**:

- To add assignees without replacing the previous ones, use [`/assign`](#assign).
- To remove assignees, use [`/unassign`](#unassign).
- To replace assignees, use [`/reassign`](#reassign).

### `reassign_reviewer`

Replace current reviewers with those specified.

**Availability**:

- Merge request

**Parameters**:

- `@user1 @user2`: One or more usernames to assign as reviewers. Usernames must be prefixed with `@`.

**Examples**:

- Reassign to a single reviewer:

  ```plaintext
  /reassign_reviewer @alex
  ```

- Reassign to multiple reviewers:

  ```plaintext
  /reassign_reviewer @alex @sam
  ```

**Additional details**:

- To assign reviewers without replacing the previous ones, use [`/assign_reviewer`](#assign_reviewer).
- To remove reviewers, use [`/unassign_reviewer`](#unassign_reviewer).

### `rebase`

Rebase the source branch on the latest commit of the target branch. If there are conflicts, nothing happens.

**Availability**:

- Merge request

**Examples**:

- Rebase the merge request:

  ```plaintext
  /rebase
  ```

**Additional details**:

- For help, see [troubleshooting information](../../topics/git/troubleshooting_git.md).

### `relabel`

Replace current labels with those specified.

**Availability**:

- Epic
- Incident
- Issue
- Merge request
- Task
- Objective
- Key Result

**Parameters**:

- `~label1 ~label2`: One or more label names. Label names can also start without a tilde (`~`), but mixed syntax is not supported.

**Examples**:

- Replace with a single label:

  ```plaintext
  /relabel ~bug
  ```

- Replace with multiple labels:

  ```plaintext
  /relabel ~bug ~"high priority"
  ```

**Additional details**:

- Labels with a space in the name must be in double quotation marks.
- To add labels without replacing the previous ones, use [`/label`](#label).
- To remove labels, use [`/unlabel`](#unlabel).

### `relate`

Mark items as related.

**Availability**:

- Epic
- Incident
- Issue

**Parameters**:

- `<item1> <item2>`: One or more items to relate. The value should be in the format of `#item`, `group/project#item`, or the full URL.

**Examples**:

- Relate to a single item:

  ```plaintext
  /relate #123
  ```

- Relate to multiple items:

  ```plaintext
  /relate #123 group/project#456
  ```

**Additional details**:

- To remove the relationship, use [`/unlink`](#unlink).
- To mark the items as one blocking another, use [`/blocked_by`](#blocked_by) or [`/blocks`](#blocks).

### `remove_child`

Remove an item as a child item.

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/132761) in GitLab 16.10 for objectives.

{{< /history >}}

**Availability**:

- Epic
- Issue
- Objective

**Parameters**:

- `<item>`: The item to remove as a child. The value should be in the format of `#item`, `group/project#item`, or a URL to the item.

**Examples**:

- Remove a child item:

  ```plaintext
  /remove_child #123
  ```

- Remove a child item using a URL:

  ```plaintext
  /remove_child https://gitlab.com/group/project/-/work_items/123
  ```

### `remove_contacts`

Remove one or more CRM contacts.

**Availability**:

- Issue

**Parameters**:

- `[contact:email1@example.com]`: One or more contact emails in the format `contact:email@example.com`.

**Examples**:

- Remove a single contact:

  ```plaintext
  /remove_contacts [contact:alex@example.com]
  ```

- Remove multiple contacts:

  ```plaintext
  /remove_contacts [contact:alex@example.com] [contact:sam@example.com]
  ```

**Additional details**:

- For more information, see [CRM contacts](../crm/_index.md).

### `remove_due_date`

Remove the due date.

**Availability**:

- Epic
- Incident
- Issue
- Task
- Key Result

**Examples**:

- Remove due date:

  ```plaintext
  /remove_due_date
  ```

**Additional details**:

- To add or replace a due date, use [`/due`](#due).

### `remove_email`

Remove up to six email participants.

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/350460) in GitLab 13.8 [with a flag](../../administration/feature_flags/list.md) named `issue_email_participants`. Enabled by default.

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by a feature flag. For more information, see the history.

{{< /alert >}}

**Availability**:

- Incident
- Issue

**Parameters**:

- `email1 email2`: One or more email addresses, separated by spaces.

**Examples**:

- Remove a single email participant:

  ```plaintext
  /remove_email alex@example.com
  ```

- Remove multiple email participants:

  ```plaintext
  /remove_email alex@example.com sam@example.com
  ```

**Additional details**:

- Not supported in issue templates, merge requests, or epics.
- For more information, see [email participants](service_desk/external_participants.md).

### `remove_estimate`

Remove the time estimate.

**Availability**:

- Epic
- Incident
- Issue
- Merge request

**Examples**:

- Remove time estimate:

  ```plaintext
  /remove_estimate
  ```

**Additional details**:

- `/remove_time_estimate` is an alias for `/remove_estimate`.
- To add or replace an estimate, use [`/estimate`](#estimate).

### `remove_iteration`

Remove the iteration.

**Availability**:

- Incident
- Issue

**Examples**:

- Remove iteration:

  ```plaintext
  /remove_iteration
  ```

**Additional details**:

- To set an iteration, use [`/iteration`](#iteration).

### `remove_milestone`

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/329) for epics in GitLab 18.2.

{{< /history >}}

Remove the milestone.

**Availability**:

- Epic
- Incident
- Issue
- Merge request

**Examples**:

- Remove milestone:

  ```plaintext
  /remove_milestone
  ```

**Additional details**:

- To set the milestone, use [`/milestone`](#milestone).

### `remove_parent`

Remove the parent from the item.

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/434344) in GitLab 16.9 for tasks and key results.

{{< /history >}}

**Availability**:

- Epic
- Issue
- Task
- Key Result

**Examples**:

- Remove parent:

  ```plaintext
  /remove_parent
  ```

**Additional details**:

- To set the parent item, use [`/set_parent`](#set_parent).

### `remove_time_spent`

Remove time spent.

**Availability**:

- Epic
- Incident
- Issue
- Merge request

**Examples**:

- Remove time spent:

  ```plaintext
  /remove_time_spent
  ```

**Additional details**:

- To add time spent, use [`/spend`](#spend).

### `remove_zoom`

Remove a Zoom meeting from an issue.

**Availability**:

- Issue

**Examples**:

- Remove Zoom meeting:

  ```plaintext
  /remove_zoom
  ```

**Additional details**:

- To add a Zoom meeting, use [`/zoom`](#zoom).

### `reopen`

Reopen the work item.

**Availability**:

- Epic
- Incident
- Issue
- Merge request
- Task
- Objective
- Key Result

**Examples**:

- Reopen a work item:

  ```plaintext
  /reopen
  ```

**Additional details**:

- To close a work item, use [`/close`](#close).

### `request_review`

Assign a reviewer or request a new review from one or more users.

**Availability**:

- Merge request

**Parameters**:

- `@user1 @user2`: One or more usernames to request a review from. Usernames must be prefixed with `@`.
- `me`: Request a review from yourself.

**Examples**:

- Request review from a single user:

  ```plaintext
  /request_review @alex
  ```

- Request review from multiple users:

  ```plaintext
  /request_review @alex @sam
  ```

- Request review from yourself:

  ```plaintext
  /request_review me
  ```

**Additional details**:

- Behaves like [`/assign_reviewer`](#assign_reviewer), but also requests a new review from currently assigned reviewers.
- For more information, see [request a review](merge_requests/reviews/_index.md#request-a-review).

### `set_parent`

Set the parent item.

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/420798) in GitLab 16.5 for tasks and key results.
- Alias `/epic` for issues [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/514942) in GitLab 17.10.

{{< /history >}}

**Availability**:

- Epic
- Issue
- Task
- Key Result

**Parameters**:

- `<item>`: The parent item. The value should be in the format of `#IID`, reference, or a URL to an item.

**Examples**:

- Set parent by reference:

  ```plaintext
  /set_parent #123
  ```

- Set parent using a URL:

  ```plaintext
  /set_parent https://gitlab.com/group/project/-/work_items/123
  ```

**Additional details**:

- For issues, `/epic` is an alias for `/set_parent`.
- To remove the parent item, use [`/remove_parent`](#remove_parent).

### `severity`

Set the severity of an incident.

**Availability**:

- Incident

**Parameters**:

- `<severity>`: The severity level. Available options:
  - `S1`
  - `S2`
  - `S3`
  - `S4`
  - `critical`
  - `high`
  - `medium`
  - `low`
  - `unknown`

**Examples**:

- Set severity to critical:

  ```plaintext
  /severity critical
  ```

- Set severity using S-notation:

  ```plaintext
  /severity S1
  ```

### `ship`

Create a merge request pipeline and set auto-merge.

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/78998) in GitLab 18.6 [with a flag](../../administration/feature_flags/list.md) named `ship_mr_quick_action`. Disabled by default.

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by a feature flag. For more information, see the history.

{{< /alert >}}

**Availability**:

- Merge request

**Examples**:

- Ship the merge request:

  ```plaintext
  /ship
  ```

**Additional details**:

- This is an experimental feature.
- To merge immediately, use [`/merge`](#merge).

### `shrug`

Add `¯\_(ツ)_/¯` to the comment.

**Availability**:

- Epic
- Incident
- Issue
- Merge request
- Task
- Objective
- Key Result

**Examples**:

- Add shrug:

  ```plaintext
  /shrug
  ```

### `spend`

Add or subtract spent time.

**Availability**:

- Epic
- Incident
- Issue
- Merge request

**Parameters**:

- `<time>`: The time to add or subtract. For example, `1mo 2w 3d 4h 5m`. Use a negative value to subtract time.
- `[<date>]`: Optional. The date that time was spent on.

**Examples**:

- Add spent time:

  ```plaintext
  /spend 1mo 2w 3d 4h 5m
  ```

- Subtract spent time:

  ```plaintext
  /spend -1h 30m
  ```

- Add spent time on a specific date:

  ```plaintext
  /spend 1mo 2w 3d 4h 5m 2018-08-26
  ```

**Additional details**:

- `/spend_time` is an alias for `/spend`.
- To remove time spent, use [`/remove_time_spent`](#remove_time_spent).
- For more information, see [time tracking](time_tracking.md).

### `status`

Set the status.

**Availability**:

- Issue
- Task

**Parameters**:

- `<value>`: The status value. Available options include status options set for the namespace.

**Examples**:

- Set status:

  ```plaintext
  /status "In Progress"
  ```

**Additional details**:

- For more information, see [status](../work_items/status.md).

### `submit_review`

Submit a pending [review](merge_requests/reviews/_index.md#submit-a-review).

**Availability**:

- Merge request

**Examples**:

- Submit review:

  ```plaintext
  /submit_review
  ```

  ```plaintext
  /submit_review reviewed
  ```

- Submit review and approve:

  ```plaintext
  /submit_review approve
  ```

- Submit review and [request changes](merge_requests/reviews/_index.md#prevent-merge-when-you-request-changes):

  ```plaintext
  /submit_review requested_changes
  ```

### `subscribe`

Subscribe to notifications for a work item.

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/420796) in GitLab 16.4 for tasks, objectives, and key results.

{{< /history >}}

**Availability**:

- Epic
- Incident
- Issue
- Merge request
- Task
- Objective
- Key Result

**Examples**:

- Subscribe to notifications:

  ```plaintext
  /subscribe
  ```

**Additional details**:

- To unsubscribe from notifications, use [`/unsubscribe`](#unsubscribe).

### `tableflip`

Add `(╯°□°)╯︵ ┻━┻` to the comment.

**Availability**:

- Epic
- Incident
- Issue
- Merge request
- Task
- Objective
- Key Result

**Examples**:

- Add tableflip:

  ```plaintext
  /tableflip
  ```

### `target_branch`

Set the target branch of a merge request.

**Availability**:

- Merge request

**Parameters**:

- `<local branch name>`: The name of the target branch.

**Examples**:

- Set target branch:

  ```plaintext
  /target_branch main
  ```

### `timeline`

Add a timeline event to an incident.

**Availability**:

- Incident

**Parameters**:

- `<timeline comment> | <date(YYYY-MM-DD)> <time(HH:MM)>`: The timeline comment, date, and time, separated by `|`.

**Examples**:

- Add a timeline event:

  ```plaintext
  /timeline DB load spiked | 2022-09-07 09:30
  ```

### `title`

Change the title.

**Availability**:

- Epic
- Incident
- Issue
- Merge request
- Task
- Objective
- Key Result

**Parameters**:

- `<new title>`: The new title for the work item.

**Examples**:

- Change title:

  ```plaintext
  /title New title for this item
  ```

### `todo`

Add a to-do item for yourself.

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/412277) in GitLab 16.2 for tasks, objectives, and key results.

{{< /history >}}

**Availability**:

- Epic
- Incident
- Issue
- Merge request
- Task
- Objective
- Key Result

**Examples**:

- Add to-do:

  ```plaintext
  /todo
  ```

### `type`

Convert a work item to a specified type.

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/385227) in GitLab 16.0.

{{< /history >}}

**Availability**:

- Issue
- Key Result
- Objective
- Task

**Parameters**:

- `<type>`: The type to convert to. Available options:
  - `issue`
  - `task`
  - `objective`
  - `key result`

**Examples**:

- Convert to issue:

  ```plaintext
  /type issue
  ```

- Convert to task:

  ```plaintext
  /type task
  ```

**Additional details**:

- To convert an issue to an epic or incident, use [`/promote_to`](#promote_to).

### `unapprove`

Unapprove the merge request.

**Availability**:

- Merge request

**Examples**:

- Unapprove a merge request:

  ```plaintext
  /unapprove
  ```

**Additional details**:

- To approve a merge request, use [`/approve`](#approve).

### `unassign`

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/551805) for epics in GitLab 18.2.

{{< /history >}}

Remove assignees.

**Availability**:

- Epic
- Incident
- Issue
- Merge request
- Task
- Objective
- Key Result

**Parameters**:

- `@user1 @user2`: Optional. One or more usernames to unassign.
  If not provided, removes all assignees.

**Examples**:

- Remove specific assignees:

  ```plaintext
  /unassign @alex @sam
  ```

- Remove all assignees:

  ```plaintext
  /unassign
  ```

**Additional details**:

- To add assignees, use [`/assign`](#assign).
- To replace assignees, use [`/reassign`](#reassign).

### `unassign_reviewer`

Remove reviewers.

**Availability**:

- Merge request

**Parameters**:

- `@user1 @user2`: Optional. One or more usernames to remove as reviewers. If not provided, removes all reviewers.
- `me`: Remove yourself as a reviewer.

**Examples**:

- Remove specific reviewers:

  ```plaintext
  /unassign_reviewer @alex @sam
  ```

- Remove yourself as a reviewer:

  ```plaintext
  /unassign_reviewer me
  ```

- Remove all reviewers:

  ```plaintext
  /unassign_reviewer
  ```

**Additional details**:

- `/remove_reviewer` is an alias for `/unassign_reviewer`.
- To assign reviewers, use [`/assign_reviewer`](#assign_reviewer).
- To replace reviewers, use [`/reassign_reviewer`](#reassign_reviewer).

### `unlabel`

Remove labels.

**Availability**:

- Epic
- Incident
- Issue
- Merge request
- Task
- Objective
- Key Result

**Parameters**:

- `~label1 ~label2`: Optional. One or more label names to remove. If not provided, removes all labels.

**Examples**:

- Remove specific labels:

  ```plaintext
  /unlabel ~bug ~"high priority"
  ```

- Remove all labels:

  ```plaintext
  /unlabel
  ```

**Additional details**:

- Labels with a space in the name must be in double quotation marks.
- `/remove_label` is an alias for `/unlabel`.
- To add labels, use [`/label`](#label).
- To replace labels, use [`/relabel`](#relabel).

### `unlink`

Remove a link to another item.

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/414400) in GitLab 16.1 for issues and epics.
- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/481851) in GitLab 17.8 for tasks, objectives, and key results.

{{< /history >}}

**Availability**:

- Epic
- Incident
- Issue
- Task
- Objective
- Key Result

**Parameters**:

- `<item>`: The item to unlink. The value should be in the format of `#item`, `group/project#item`, or the full URL.

**Examples**:

- Unlink an item:

  ```plaintext
  /unlink #123
  ```

- Unlink an item using a URL:

  ```plaintext
  /unlink https://gitlab.com/group/project/-/work_items/123
  ```

**Additional details**:

- To set relationships between items, use [`/relate`](#relate), [`/blocks`](#blocks), or [`/blocked_by`](#blocked_by).

### `unlock`

Unlock the discussions.

**Availability**:

- Epic
- Issue
- Merge request

**Examples**:

- Unlock discussions:

  ```plaintext
  /unlock
  ```

**Additional details**:

- To lock the discussions, use [`/lock`](#lock).

### `unsubscribe`

Unsubscribe from notifications for a work item.

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/420796) in GitLab 16.4 for tasks, objectives, and key results.

{{< /history >}}

**Availability**:

- Epic
- Incident
- Issue
- Merge request
- Task
- Objective
- Key Result

**Examples**:

- Unsubscribe from notifications:

  ```plaintext
  /unsubscribe
  ```

**Additional details**:

- To subscribe to notifications, use [`/subscribe`](#subscribe).

### `weight`

Set the weight.

**Availability**:

- Issue
- Task

**Parameters**:

- `<value>`: The weight value. Valid values are integers like `0`, `1`, or `2`.

**Examples**:

- Set weight:

  ```plaintext
  /weight 3
  ```

### `zoom`

Add a Zoom meeting to an issue or incident.

**Availability**:

- Incident
- Issue

**Parameters**:

- `<Zoom URL>`: The URL of the Zoom meeting.

**Examples**:

- Add a Zoom meeting:

  ```plaintext
  /zoom https://zoom.us/j/123456789
  ```

**Additional details**:

- Users on GitLab Premium can add a short description when [adding a Zoom link to an incident](../../operations/incident_management/linked_resources.md#link-zoom-meetings-from-an-incident).
- To remove the Zoom meeting, use [`/remove_zoom`](#remove_zoom).

## Commit comments

You can use quick actions when commenting on individual commits. These quick actions work only in
commit comment threads, not in commit messages or other GitLab contexts.

To use quick actions in commit comments:

1. Go to a commit page by selecting a commit from the commits list, merge request,
   or other commit links.
1. In the comment form at the bottom of the commit page, enter your quick action.
1. Select **Comment**.

The following quick actions are applicable for commit comments:

### `tag`

Create a Git tag pointing to the commented commit.

**Parameters**:

- `v1.2.3`: The tag name.
- `<message>`: Optional. A message for the tag.

**Examples**:

- Create a tag with a message:

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
