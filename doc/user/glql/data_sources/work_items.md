---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Work items
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Work items include the types:
`Issue`, `Incident`, `TestCase`, `Requirement`, `Task`, `Ticket`, `Objective`, `KeyResult`, and `Epic`.

> [!note]
> Querying epics is available only on the Premium and Ultimate tier.

## Allowed scopes

| Scope     | Description                                      |
| --------- | ------------------------------------------------ |
| `project` | Query work items in a specific project.          |
| `group`   | Query work items across all projects in a group, including subgroups. |

For more information, see [scopes](_index.md#scopes).

## Query fields

| Field                                                          | Name (and alias)                             | Operators                  | Types              |
| -------------------------------------------------------------- | -------------------------------------------- | -------------------------- | ------------------ |
| [Assignees](#workitem-assignees)                               | `assignee`, `assignees`                      | `=`, `in`, `!=`            | All                |
| [Author](#workitem-author)                                     | `author`                                     | `=`, `in`, `!=`            | All                |
| [Cadence](#workitem-cadence)                                   | `cadence`                                    | `=`, `in`                  | All except Epic    |
| [Closed at](#workitem-closed-at)                               | `closed`, `closedAt`                         | `=`, `>`, `<`, `>=`, `<=`  | All                |
| [Confidential](#workitem-confidential)                         | `confidential`                               | `=`, `!=`                  | All                |
| [Created at](#workitem-created-at)                             | `created`, `createdAt`, `opened`, `openedAt` | `=`, `>`, `<`, `>=`, `<=`  | All                |
| [Custom field](#workitem-custom-field)                         | `customField("Field name")`                  | `=`                        | All                |
| [Due date](#workitem-due-date)                                 | `due`, `dueDate`                             | `=`, `>`, `<`, `>=`, `<=`  | All                |
| [Epic](#workitem-epic)                                         | `epic`                                       | `=`, `!=`                  | All except Epic    |
| [Health status](#workitem-health-status)                       | `health`, `healthStatus`                     | `=`, `!=`                  | All                |
| [ID](#workitem-identifier)                                     | `id`                                         | `=`, `in`                  | All                |
| [Include subgroups](#workitem-include-subgroups)               | `includeSubgroups`                           | `=`, `!=`                  | All                |
| [Iteration](#workitem-iteration)                               | `iteration`                                  | `=`, `in`, `!=`            | All except Epic    |
| [Labels](#workitem-labels)                                     | `label`, `labels`                            | `=`, `in`, `!=`            | All                |
| [Milestone](#workitem-milestone)                               | `milestone`                                  | `=`, `in`, `!=`            | All                |
| [My reaction emoji](#workitem-my-reaction-emoji)               | `myReaction`, `myReactionEmoji`              | `=`, `!=`                  | All                |
| [Parent](#workitem-parent)                                     | `parent`                                     | `=`, `!=`                  | All except Epic    |
| [State](#workitem-state)                                       | `state`                                      | `=`                        | All                |
| [Status](#workitem-status)                                     | `status`                                     | `=`                        | All except Epic    |
| [Subscribed](#workitem-subscribed)                             | `subscribed`                                 | `=`, `!=`                  | All                |
| [Updated at](#workitem-updated-at)                             | `updated`, `updatedAt`                       | `=`, `>`, `<`, `>=`, `<=`  | All                |
| [Weight](#workitem-weight)                                     | `weight`                                     | `=`, `!=`                  | All except Epic    |

### Assignees {#workitem-assignees}

{{< history >}}

- Alias `assignees` [introduced](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/137) in GitLab 18.0.
- Support for querying epics by assignees [introduced](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/222) in GitLab 18.3.

{{< /history >}}

**Description**: Query work items by one or more users who are assigned to them.

**Allowed value types**:

- `String`
- `User` (for example, `@username`)
- `List` (containing `String` or `User` values)
- `Nullable` (either of `null`, `none`, or `any`)

### Author {#workitem-author}

{{< history >}}

- Support for querying epics by author [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/192680) in GitLab 18.1.
- Support for `in` operator [introduced](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/221) in GitLab 18.3.

{{< /history >}}

**Description**: Query work items by their author.

**Allowed value types**:

- `String`
- `User` (for example, `@username`)
- `List` (containing `String` or `User` values)

### Cadence {#workitem-cadence}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab-query-language/glql-haskell/-/issues/74) in GitLab 17.6.

{{< /history >}}

**Description**: Query work items except epics by the [cadence](../../group/iterations/_index.md#iteration-cadences) that the work item's iteration is a part of.

**Allowed value types**:

- `Number` (only positive integers)
- `List` (containing `Number` values)
- `Nullable` (either of `none`, or `any`)

**Notes**:

- Because a work item can have only one iteration, the `=` operator cannot be used with `List` type for the `cadence` field.

### Closed at {#workitem-closed-at}

{{< history >}}

- Alias `closedAt` [introduced](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/137) in GitLab 18.0.
- Operators `>=` and `<=` [introduced](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/work_items/58) in GitLab 18.0.
- Support for querying epics by closed date [introduced](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/222) in GitLab 18.3.

{{< /history >}}

**Description**: Query work items by the date when they were closed.

**Allowed value types**:

- `AbsoluteDate` (in the format `YYYY-MM-DD`)
- `RelativeDate` (in the format `<sign><digit><unit>`, where sign is `+`, `-`, or omitted,
  digit is an integer, and `unit` is one of `d` (days), `w` (weeks), `m` (months) or `y` (years))

**Notes**:

- For the `=` operator, the time range is considered from 00:00 to 23:59 in the user's time zone.
- `>=` and `<=` operators are inclusive of the dates being queried, whereas `>` and `<` are not.

### Confidential {#workitem-confidential}

{{< history >}}

- Support for querying epics by their confidentiality [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/192680) in GitLab 18.1.

{{< /history >}}

**Description**: Query work items by their visibility to project members.

**Allowed value types**:

- `Boolean` (either of `true` or `false`)

**Notes**:

- Confidential work items queried using GLQL are only visible to people who have permission to view them.

### Created at {#workitem-created-at}

{{< history >}}

- Aliases `createdAt`, `opened`, and `openedAt` [introduced](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/137) in GitLab 18.0.
- Operators `>=` and `<=` [introduced](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/work_items/58) in GitLab 18.0.
- Support for querying epics by creation date [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/192680) in GitLab 18.1.

{{< /history >}}

**Description**: Query work items by the date when they were created.

**Allowed value types**:

- `AbsoluteDate` (in the format `YYYY-MM-DD`)
- `RelativeDate` (in the format `<sign><digit><unit>`, where sign is `+`, `-`, or omitted,
  digit is an integer, and `unit` is one of `d` (days), `w` (weeks), `m` (months) or `y` (years))

**Notes**:

- For the `=` operator, the time range is considered from 00:00 to 23:59 in the user's time zone.
- `>=` and `<=` operators are inclusive of the dates being queried, whereas `>` and `<` are not.

### Custom field {#workitem-custom-field}

{{< details >}}

- Tier: Premium, Ultimate

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/233) in GitLab 18.3.

{{< /history >}}

**Description**: Query work items by [custom fields](../../work_items/custom_fields.md).

**Allowed value types**:

- `String` (for single-select custom fields)
- `List` (of `String`, for multi-select custom fields)

**Notes**:

- Custom field names and values are not case-sensitive.

### Due date {#workitem-due-date}

{{< history >}}

- Alias `dueDate` [introduced](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/137) in GitLab 18.0.
- Operators `>=` and `<=` [introduced](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/work_items/58) in GitLab 18.0.
- Support for querying epics by due date [introduced](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/222) in GitLab 18.3.

{{< /history >}}

**Description**: Query work items by the date when they are due.

**Allowed value types**:

- `AbsoluteDate` (in the format `YYYY-MM-DD`)
- `RelativeDate` (in the format `<sign><digit><unit>`, where sign is `+`, `-`, or omitted,
  digit is an integer, and `unit` is one of `d` (days), `w` (weeks), `m` (months) or `y` (years))

**Notes**:

- For the `=` operator, the time range is considered from 00:00 to 23:59 in the user's time zone.
- `>=` and `<=` operators are inclusive of the dates being queried, whereas `>` and `<` are not.

### Epic {#workitem-epic}

{{< details >}}

- Tier: Premium, Ultimate

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/issues/30) in GitLab 18.1.

{{< /history >}}

**Description**: Query work items by their parent epic ID or reference.

**Allowed value types**:

- `Number` (epic ID)
- `String` (containing an epic reference like `&123`)
- `Epic` (for example, `&123`, `gitlab-org&123`)

### Health status {#workitem-health-status}

{{< details >}}

- Tier: Ultimate

{{< /details >}}

{{< history >}}

- Alias `healthStatus` [introduced](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/137) in GitLab 18.0.
- Support for querying epics by health status [introduced](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/222) in GitLab 18.3.

{{< /history >}}

**Description**: Query work items by their health status.

**Allowed value types**:

- `StringEnum` (one of `"needs attention"`, `"at risk"` or `"on track"`)
- `Nullable` (either of `null`, `none`, or `any`)

### ID {#workitem-identifier}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/92) in GitLab 17.8.
- Support for querying epics by ID [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/192680) in GitLab 18.1.

{{< /history >}}

**Description**: Query work items by their IDs.

**Allowed value types**:

- `Number` (only positive integers)
- `List` (containing `Number` values)

### Include subgroups {#workitem-include-subgroups}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/106) in GitLab 17.10.
- Support for this field to be used with epics [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/192680) in GitLab 18.1.

{{< /history >}}

**Description**: Query work items in the entire hierarchy of a group.

**Allowed value types**:

- `Boolean` (either of `true` or `false`)

**Notes**:

- This field can only be used with a `group` scope.
- The value of this field defaults to `false`.

### Iteration {#workitem-iteration}

{{< details >}}

- Tier: Premium, Ultimate

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab-query-language/glql-haskell/-/issues/74) in GitLab 17.6.
- Support for iteration value types [introduced](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/79) in GitLab 17.8.

{{< /history >}}

**Description**: Query work items, except epics, by their associated [iteration](../../group/iterations/_index.md).

**Allowed value types**:

- `Number` (only positive integers)
- `Iteration` (for example, `*iteration:123456`)
- `List` (containing `Number` or `Iteration` values)
- `Enum` (only `current` is supported)
- `Nullable` (either of `none`, or `any`)

**Notes**:

- Because a work item can have only one iteration, the `=` operator cannot be used with `List` type for the `iteration` field.

### Labels {#workitem-labels}

{{< history >}}

- Support for label value types [introduced](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/79) in GitLab 17.8.
- Alias `labels` [introduced](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/137) in GitLab 18.0.
- Support for querying epics by labels [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/192680) in GitLab 18.1.

{{< /history >}}

**Description**: Query work items by their associated labels.

**Allowed value types**:

- `String`
- `Label` (for example, `~bug`, `~"team::planning"`)
- `List` (containing `String` or `Label` values)
- `Nullable` (either of `none`, or `any`)

**Notes**:

- Scoped labels, or labels containing spaces must be wrapped in quotes.

### Milestone {#workitem-milestone}

{{< history >}}

- Support for milestone value types [introduced](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/77) in GitLab 17.8.
- Support for querying epics by milestone [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/192680) in GitLab 18.1.

{{< /history >}}

**Description**: Query work items by their associated milestone.

**Allowed value types**:

- `String`
- `Milestone` (for example, `%Backlog`, `%"Awaiting Further Demand"`)
- `List` (containing `String` or `Milestone` values)
- `Nullable` (either of `none`, or `any`)

**Notes**:

- Milestones containing spaces must be wrapped in quotes (`"`).
- Because a work item can have only one milestone, the `=` operator cannot be used with `List` type for the `milestone` field.
- The `Epic` type does not support wildcard milestone filters like `none` or `any`.

### My reaction emoji {#workitem-my-reaction-emoji}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/223) in GitLab 18.3.

{{< /history >}}

**Description**: Query work items by the current user's [emoji reaction](../../emoji_reactions.md) on it.

**Allowed value types**: `String`

### Parent {#workitem-parent}

**Description**: Query work items, except epics, by their parent work item or epic.

**Allowed value types**:

- `Number` (parent ID)
- `String` (containing a reference like `#123`)
- `WorkItem` (for example, `#123`, `gitlab-org/gitlab#123`)
- `Epic` (for example, `&123`, `gitlab-org&123`)

### State {#workitem-state}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/96) in GitLab 17.8.
- Support for querying epics by state [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/192680) in GitLab 18.1.

{{< /history >}}

**Description**: Query work items by state.

**Allowed value types**:

- `Enum`, one of `opened`, `closed`, or `all`

**Notes**:

- The `state` field does not support the `!=` operator.

### Status {#workitem-status}

{{< details >}}

- Tier: Premium, Ultimate

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/197407) in GitLab 18.2.

{{< /history >}}

**Description:** Query work items by their status.

**Allowed value types:** `String`

### Subscribed {#workitem-subscribed}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/223) in GitLab 18.3.

{{< /history >}}

**Description**: Query work items by whether the current user has
[set notifications](../../profile/notifications.md) on or off.

**Allowed value types**: `Boolean`

### Updated at {#workitem-updated-at}

{{< history >}}

- Alias `updatedAt` [introduced](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/137) in GitLab 18.0.
- Operators `>=` and `<=` [introduced](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/work_items/58) in GitLab 18.0.
- Support for querying epics by last updated [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/192680) in GitLab 18.1.

{{< /history >}}

**Description**: Query work items by when they were last updated.

**Allowed value types**:

- `AbsoluteDate` (in the format `YYYY-MM-DD`)
- `RelativeDate` (in the format `<sign><digit><unit>`, where sign is `+`, `-`, or omitted,
  digit is an integer, and `unit` is one of `d` (days), `w` (weeks), `m` (months) or `y` (years))

**Notes**:

- For the `=` operator, the time range is considered from 00:00 to 23:59 in the user's time zone.
- `>=` and `<=` operators are inclusive of the dates being queried, whereas `>` and `<` are not.

### Weight {#workitem-weight}

{{< details >}}

- Tier: Premium, Ultimate

{{< /details >}}

**Description**: Query work items, except epics, by their weight.

**Allowed value types**:

- `Number` (only positive integers or 0)
- `Nullable` (either of `null`, `none`, or `any`)

**Notes**:

- Comparison operators `<` and `>` cannot be used.

## Display fields

{{< history >}}

- Field `iteration` [introduced](https://gitlab.com/gitlab-org/gitlab-query-language/glql-haskell/-/issues/74) in GitLab 17.6.
- Field `lastComment` [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/512154) in GitLab 17.11.
- Support for epics [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/192680) in GitLab 18.1.
- Field `status` [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/197407) in GitLab 18.2.
- Fields `health` and `type` in epics [introduced](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/222) in GitLab 18.3.

{{< /history >}}

| Field            | Name or alias                         | Types           | Description |
| ---------------- | ------------------------------------- | --------------- | ----------- |
| Assignees        | `assignee`, `assignees`               | All             | Display users assigned to the object |
| Author           | `author`                              | All             | Display the author of the object |
| Closed at        | `closed`, `closedAt`                  | All             | Display time since the object was closed |
| Color            | `color`                               | Epic only       | Display the color swatch associated with the epic |
| Confidential     | `confidential`                        | All             | Display `Yes` or `No` indicating whether the object is confidential |
| Created at       | `created`, `createdAt`                | All             | Display time since the object was created |
| Description      | `description`                         | All             | Display the description of the object |
| Due date         | `due`, `dueDate`                      | All             | Display time until the object is due |
| Epic             | `epic`                                | All except Epic | Display a link to the epic. Available in the Premium and Ultimate tier |
| Health status    | `health`, `healthStatus`              | All             | Display a badge indicating the health status. Available in the Ultimate tier |
| ID               | `id`                                  | All             | Display the ID of the object |
| Iteration        | `iteration`                           | All except Epic | Display the iteration. Available in the Premium and Ultimate tier |
| Labels           | `label`, `labels`                     | All             | Display labels. Can accept parameters to filter specific labels, for example `labels("workflow::*", "backend")` |
| Last comment     | `lastComment`                         | All             | Display the last comment made on the object |
| Milestone        | `milestone`                           | All             | Display the milestone associated with the object |
| Parent           | `parent`                              | All             | Display a link to the parent work item or epic |
| Progress         | `progress`                            | Objective and Key Result only | Display the progress percentage (0–100) of the work item |
| Project          | `project`                             | All except Epic | Display the project the work item belongs to |
| Start date       | `start`, `startDate`                  | Epic only       | Display the start date of the epic |
| State            | `state`                               | All             | Display a badge indicating the state. Values are `Open` or `Closed` |
| Status           | `status`                              | All except Epic | Display a badge indicating the status. For example, "To do" or "Complete". Available in the Premium and Ultimate tiers |
| Task completion status | `taskCompletionStatus`          | All             | Display task completion as a fraction (completed/total) |
| Time estimate    | `timeEstimate`                        | All             | Display the estimated time for the work item |
| Title            | `title`                               | All             | Display the title of the object |
| Total time spent | `totalTimeSpent`                      | All             | Display the total time spent on the work item |
| Type             | `type`                                | All             | Display the work item type, for example `Issue`, `Task`, or `Objective` |
| Updated at       | `updated`, `updatedAt`                | All             | Display time since the object was last updated |
| Weight           | `weight`                              | All except Epic | Display the weight. Available in the Premium and Ultimate tiers |

## Sort fields

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/178) in GitLab 18.2.
- Support for sorting epics by health status [introduced](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/222) in GitLab 18.3.

{{< /history >}}

| Field         | Name (and alias)         | Types           | Description                                     |
|---------------|--------------------------|-----------------|------------------------------------------------ |
| Closed at     | `closed`, `closedAt`     | All             | Sort by closed date                             |
| Created       | `created`, `createdAt`   | All             | Sort by created date                            |
| Due date      | `due`, `dueDate`         | All             | Sort by due date                                |
| Health status | `health`, `healthStatus` | All             | Sort by health status                           |
| Milestone     | `milestone`              | All except Epic | Sort by milestone due date                      |
| Popularity    | `popularity`             | All             | Sort by the number of thumbs up emoji reactions |
| Start date    | `start`, `startDate`     | Epic only       | Sort by start date                              |
| Title         | `title`                  | All             | Sort by title                                   |
| Updated at    | `updated`, `updatedAt`   | All             | Sort by last updated date                       |
| Weight        | `weight`                 | All except Epic | Sort by weight                                  |

## Examples

- List all issues in the `gitlab-org/gitlab` project sorted by title:

  ````yaml
  ```glql
  display: table
  fields: state, title, updated
  sort: title asc
  query: project = "gitlab-org/gitlab" and type = Issue
  ```
  ````

- List all epics in the `gitlab-org` group sorted by the start date (oldest first):

  ````yaml
  ```glql
  display: table
  fields: title, state, startDate
  sort: startDate asc
  query: group = "gitlab-org" and type = Epic
  ```
  ````

- List all issues in the `gitlab-org` group with an assigned weight sorted by
  the weight (highest first):

  ````yaml
  ```glql
  display: table
  fields: title, weight, health
  sort: weight desc
  query: type = Issue and group = "gitlab-org" and weight = any
  ```
  ````

- List all issues in the `gitlab-org` group due up to a week from today sorted by the due
  date (earliest first):

  ````yaml
  ```glql
  display: table
  fields: title, dueDate, assignee
  sort: dueDate asc
  query: type = Issue and group = "gitlab-org" and due >= today() and due <= 1w
  ```
  ````
