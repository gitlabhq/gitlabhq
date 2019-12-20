---
type: reference
---

# GitLab Quick Actions

Quick actions are textual shortcuts for common actions on issues, epics, merge requests,
and commits that are usually done by clicking buttons or dropdowns in GitLab's UI.
You can enter these commands while creating a new issue or merge request, or
in comments of issues, epics, merge requests, and commits. Each command should be
on a separate line in order to be properly detected and executed.

> From [GitLab 12.1](https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/26672), once an action is executed, an alert is displayed when a quick action is successfully applied.

## Quick Actions for issues, merge requests and epics

The following quick actions are applicable to descriptions, discussions and threads in:

- Issues
- Merge requests
- Epics **(ULTIMATE)**

| Command                               | Issue | Merge request | Epic | Action |
|:--------------------------------------|:------|:--------------|:-----|:------ |
| `/tableflip <comment>`                | ✓     | ✓             | ✓    | Append the comment with `(╯°□°)╯︵ ┻━┻` |
| `/shrug <comment>`                    | ✓     | ✓             | ✓    | Append the comment with `¯\＿(ツ)＿/¯` |
| `/todo`                               | ✓     | ✓             | ✓    | Add a To Do |
| `/done`                               | ✓     | ✓             | ✓    | Mark To Do as done |
| `/subscribe`                          | ✓     | ✓             | ✓    | Subscribe |
| `/unsubscribe`                        | ✓     | ✓             | ✓    | Unsubscribe |
| `/close`                              | ✓     | ✓             | ✓    | Close |
| `/reopen`                             | ✓     | ✓             | ✓    | Reopen |
| `/title <new title>`                  | ✓     | ✓             | ✓    | Change title |
| `/award :emoji:`                      | ✓     | ✓             | ✓    | Toggle emoji award |
| `/assign me`                          | ✓     | ✓             |      | Assign yourself |
| `/assign @user`                       | ✓     | ✓             |      | Assign one user |
| `/assign @user1 @user2`               | ✓     | ✓             |      | Assign multiple users **(STARTER)** |
| `/reassign @user1 @user2`             | ✓     | ✓             |      | Change assignee **(STARTER)** |
| `/unassign`                           | ✓     | ✓             |      | Remove current assignee |
| `/unassign @user1 @user2`             | ✓     | ✓             |      | Remove assignee(s) **(STARTER)** |
| `/milestone %milestone`               | ✓     | ✓             |      | Set milestone |
| `/remove_milestone`                   | ✓     | ✓             |      | Remove milestone |
| `/label ~label1 ~label2`              | ✓     | ✓             | ✓    | Add label(s). Label names can also start without `~` but mixed syntax is not supported |
| `/relabel ~label1 ~label2`            | ✓     | ✓             | ✓    | Replace existing label(s) with those specified |
| `/unlabel ~label1 ~label2`            | ✓     | ✓             | ✓    | Remove all or specific label(s) |
| `/copy_metadata <#issue>`             | ✓     | ✓             |      | Copy labels and milestone from another issue in the project |
| `/copy_metadata <!merge_request>`     | ✓     | ✓             |      | Copy labels and milestone from another merge request in the project |
| `/estimate <<W>w <DD>d <hh>h <mm>m>`  | ✓     | ✓             |      | Set time estimate. For example, `/estimate 1w 3d 2h 14m` |
| `/remove_estimate`                    | ✓     | ✓             |      | Remove time estimate |
| `/spend <time(<h>h <mm>m)> <date(<YYYY-MM-DD>)>` | ✓ | ✓      |      | Add spent time; optionally specify the date that time was spent on. For example, `/spend time(1h 30m)` or `/spend time(1h 30m) date(2018-08-26)` |
| `/spend <time(-<h>h <mm>m)> <date(<YYYY-MM-DD>)>` | ✓ | ✓     |      | Subtract spent time; optionally specify the date that time was spent on. For example, `/spend time(-1h 30m)` or `/spend time(-1h 30m) date(2018-08-26)` |
| `/remove_time_spent`                  | ✓     | ✓             |      | Remove time spent |
| `/lock`                               | ✓     | ✓             |      | Lock the thread |
| `/unlock`                             | ✓     | ✓             |      | Unlock the thread |
| `/due <date>`                         | ✓     |               |      | Set due date. Examples of valid `<date>` include `in 2 days`, `this Friday` and `December 31st` |
| `/remove_due_date`                    | ✓     |               |      | Remove due date |
| `/weight <value>`                     | ✓     |               |      | Set weight. Valid options for `<value>` include `0`, `1`, `2`, etc **(STARTER)** |
| `/clear_weight`                       | ✓     |               |      | Clear weight **(STARTER)** |
| `/epic <epic>`                        | ✓     |               |      | Add to epic `<epic>`. The `<epic>` value should be in the format of `&epic`, `group&epic`, or a URL to an epic. **(ULTIMATE)** |
| `/remove_epic`                        | ✓     |               |      | Remove from epic **(ULTIMATE)** |
| `/promote`                            | ✓     |               |      | Promote issue to epic **(ULTIMATE)** |
| `/confidential`                       | ✓     |               |      | Make confidential |
| `/duplicate <#issue>`                 | ✓     |               |      | Mark this issue as a duplicate of another issue and relate them for **(STARTER)** |
| `/create_merge_request <branch name>` | ✓     |               |      | Create a new merge request starting from the current issue |
| `/relate #issue1 #issue2`             | ✓     |               |      | Mark issues as related **(STARTER)** |
| `/move <path/to/project>`             | ✓     |               |      | Move this issue to another project |
| `/zoom <Zoom URL>`                    | ✓     |               |      | Add Zoom meeting to this issue. ([Introduced in GitLab 12.4](https://gitlab.com/gitlab-org/gitlab/merge_requests/16609)) |
| `/remove_zoom`                        | ✓     |               |      | Remove Zoom meeting from this issue. ([Introduced in GitLab 12.4](https://gitlab.com/gitlab-org/gitlab/merge_requests/16609)) |
| `/target_branch <local branch name>`  |       | ✓             |      | Set target branch |
| `/wip`                                |       | ✓             |      | Toggle the Work In Progress status |
| `/approve`                            |       | ✓             |      | Approve the merge request **(STARTER)** |
| `/submit_review`                      |       | ✓             |      | Submit a pending review. ([Introduced in GitLab 12.7](https://gitlab.com/gitlab-org/gitlab/issues/8041)) **(PREMIUM)** |
| `/merge`                              |       | ✓             |      | Merge (when pipeline succeeds) |
| `/child_epic <epic>`                  |       |               | ✓    | Add child epic to `<epic>`. The `<epic>` value should be in the format of `&epic`, `group&epic`, or a URL to an epic. ([Introduced in GitLab 12.0](https://gitlab.com/gitlab-org/gitlab/issues/7330)) **(ULTIMATE)** |
| `/remove_child_epic <epic>`           |       |               | ✓    | Remove child epic from `<epic>`. The `<epic>` value should be in the format of `&epic`, `group&epic`, or a URL to an epic. ([Introduced in GitLab 12.0](https://gitlab.com/gitlab-org/gitlab/issues/7330)) **(ULTIMATE)** |
| `/parent_epic <epic>`                 |       |               | ✓    | Set parent epic to `<epic>`. The `<epic>` value should be in the format of `&epic`, `group&epic`, or a URL to an epic. ([introduced in GitLab 12.1](https://gitlab.com/gitlab-org/gitlab/issues/10556)) **(ULTIMATE)** |
| `/remove_parent_epic`                 |       |               | ✓    | Remove parent epic from epic ([introduced in GitLab 12.1](https://gitlab.com/gitlab-org/gitlab/issues/10556)) **(ULTIMATE)** |

## Autocomplete characters

Many quick actions require a parameter, for example: username, milestone, and
label. [Autocomplete characters](autocomplete_characters.md) can make it easier
to enter a parameter, compared to selecting items from a list.

## Quick actions parameters

The easiest way to set parameters for quick actions is to use autocomplete. If
you manually enter a parameter, it must be enclosed in double quotation marks
(`"`), unless it contains only:

1. ASCII letters.
1. Numerals.
1. Underscore, hyphen, question mark, dot, and ampersand.

Parameters are also case-sensitive. Autocomplete handles this, and the insertion
of quotation marks, automatically.

## Quick actions for commit messages

The following quick actions are applicable for commit messages:

| Command                 | Action                                    |
|:------------------------|:------------------------------------------|
| `/tag v1.2.3 <message>` | Tags this commit with an optional message |

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
