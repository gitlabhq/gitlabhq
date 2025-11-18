---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GLQL fields
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/14767) in GitLab 17.4 [with a flag](../../administration/feature_flags/_index.md) named `glql_integration`. Disabled by default.
- Enabled on GitLab.com in GitLab 17.4 for a subset of groups and projects.
- Promoted to [beta](../../policy/development_stages_support.md#beta) status in GitLab 17.10.
- [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/476990) from experiment to beta in GitLab 17.10.
- Enabled on GitLab.com, GitLab Self-Managed, and GitLab Dedicated in GitLab 17.10.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/554870) in GitLab 18.3. Feature flag `glql_integration` removed.

{{< /history >}}

With GitLab Query Language (GLQL), fields are used to:

- Filter the results returned from a [GLQL query](_index.md#query-syntax).
- Control the details displayed in an [embedded view](_index.md#presentation-syntax).
- Sort the results displayed in an embedded view.

You use fields in three embedded view parameters:

- **`query`** - Set conditions to determine which items to retrieve
- **`fields`** - Specify which columns and details appear in your view
- **`sort`** - Order items by specific criteria

The following sections describe the available fields for each component.

## Fields inside query

In an embedded view, the `query` parameter can be used to include one or more expressions of the
format `<field> <operator> <value>`. Multiple expressions are joined with `and`,
for example, `group = "gitlab-org" and author = currentUser()`.

Prerequisites:

- Querying epics is available in the Premium and Ultimate tier.

The table below provides an overview of all available query fields and their specifications:

| Field                                   | Name (and alias)                             | Operators                 | Supported for |
| --------------------------------------- | -------------------------------------------- | ------------------------- | ------------- |
| [Approved by user](#approved-by-user)   | `approver`, `approvedBy`, `approvers`        | `=`, `!=`                 | Merge requests |
| [Assignees](#assignees)                 | `assignee`, `assignees`                      | `=`, `in`, `!=`           | Issues, epics, merge requests |
| [Author](#author)                       | `author`                                     | `=`, `in`, `!=`           | Issues, epics, merge requests |
| [Cadence](#cadence)                     | `cadence`                                    | `=`, `in`                 | Issues |
| [Closed at](#closed-at)                 | `closed`, `closedAt`                         | `=`, `>`, `<`, `>=`, `<=` | Issues, epics |
| [Confidential](#confidential)           | `confidential`                               | `=`, `!=`                 | Issues, epics |
| [Created at](#created-at)               | `created`, `createdAt`, `opened`, `openedAt` | `=`, `>`, `<`, `>=`, `<=` | Issues, epics, merge requests |
| [Custom field](#custom-field)           | `customField("Field name")`                  | `=`                       | Issues, epics |
| [Draft](#draft)                         | `draft`                                      | `=`, `!=`                 | Merge requests |
| [Due date](#due-date)                   | `due`, `dueDate`                             | `=`, `>`, `<`, `>=`, `<=` | Issues, epics |
| [Environment](#environment)             | `environment`                                | `=`                       | Merge requests |
| [Epic](#epic)                           | `epic`                                       | `=`, `!=`                 | Issues |
| [Group](#group)                         | `group`                                      | `=`                       | Issues, epics, merge requests |
| [Health status](#health-status)         | `health`, `healthStatus`                     | `=`, `!=`                 | Issues, epics |
| [ID](#id)                               | `id`                                         | `=`, `in`                 | Issues, epics, merge requests |
| [Include subgroups](#include-subgroups) | `includeSubgroups`                           | `=`, `!=`                 | Issues, epics, merge requests |
| [Iteration](#iteration)                 | `iteration`                                  | `=`, `in`, `!=`           | Issues |
| [Labels](#labels)                       | `label`, `labels`                            | `=`, `in`, `!=`           | Issues, epics, merge requests |
| [Merged at](#merged-at)                 | `merged`, `mergedAt`                         | `=`, `>`, `<`, `>=`, `<=` | Merge requests |
| [Merged by user](#merged-by-user)       | `merger`, `mergedBy`                         | `=`                       | Merge requests |
| [Milestone](#milestone)                 | `milestone`                                  | `=`, `in`, `!=`           | Issues, epics, merge requests |
| [My reaction emoji](#my-reaction-emoji) | `myReaction`, `myReactionEmoji`              | `=`, `!=`                 | Issues, epics, merge requests |
| [Project](#project)                     | `project`                                    | `=`                       | Issues, merge requests |
| [Reviewers](#reviewers)                 | `reviewer`, `reviewers`, `reviewedBy`        | `=`, `!=`                 | Merge requests |
| [Source branch](#source-branch)         | `sourceBranch`                               | `=`, `in`, `!=`           | Merge requests |
| [State](#state)                         | `state`                                      | `=`                       | Issues, epics, merge requests |
| [Status](#status)                       | `status`                                     | `=`                       | Issues |
| [Subscribed](#subscribed)               | `subscribed`                                 | `=`, `!=`                 | Issues, epics, merge requests |
| [Target branch](#target-branch)         | `targetBranch`                               | `=`, `in`, `!=`           | Merge requests |
| [Type](#type)                           | `type`                                       | `=`, `in`                 | Issues, epics, merge requests |
| [Updated at](#updated-at)               | `updated`, `updatedAt`                       | `=`, `>`, `<`, `>=`, `<=` | Issues, epics, merge requests |
| [Weight](#weight)                       | `weight`                                     | `=`, `!=`                 | Issues |

### Approved by user

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/491246) in GitLab 17.8.
- Aliases `approvedBy` and `approvers` [introduced](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/137) in GitLab 18.0.
- Support for `Nullable` values [introduced](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/221) in GitLab 18.3.

{{< /history >}}

**Description**: Query merge requests by one or more users who approved the merge request.

**Allowed value types**:

- `String`
- `User` (for example, `@username`)
- `List` (containing `String` or `User` values)
- `Nullable` (either of `null`, `none`, or `any`)

**Examples**:

- List all merge requests approved by current user and `@johndoe`

  ```plaintext
  type = MergeRequest and approver = (currentUser(), @johndoe)
  ```

- List all merge requests that are not yet approved

  ```plaintext
  type = MergeRequest and approver = none
  ```

### Assignees

{{< history >}}

- Alias `assignees` [introduced](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/137) in GitLab 18.0.
- Support for querying epics by assignees [introduced](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/222) in GitLab 18.3.

{{< /history >}}

**Description**: Query issues, epics, or merge requests by one or more users who are assigned to them.

**Allowed value types**:

- `String`
- `User` (for example, `@username`)
- `List` (containing `String` or `User` values)
- `Nullable` (either of `null`, `none`, or `any`)

**Additional details**:

- `List` values and the `in` operator are not supported for `MergeRequest` types.

**Examples**:

- List all issues where assignee is `@johndoe`:

  ```plaintext
  assignee = @johndoe
  ```

- List all issues where assignees are both `@johndoe` and `@janedoe`:

  ```plaintext
  assignee = (@johndoe, @janedoe)
  ```

- List all issues where assignees are either of `@johndoe` or `@janedoe`:

  ```plaintext
  assignee in (@johndoe, @janedoe)
  ```

- List all issues where assignee is neither of `@johndoe` or `@janedoe`:

  ```plaintext
  assignee != (@johndoe, @janedoe)
  ```

- List all merge requests where assignee is `@johndoe`:

  ```plaintext
  type = MergeRequest and assignee = @johndoe
  ```

### Author

{{< history >}}

- Support for querying epics by author [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/192680) in GitLab 18.1.
- Support for `in` operator [introduced](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/221) in GitLab 18.3.

{{< /history >}}

**Description**: Query issues, epics, or merge requests by their author.

**Allowed value types**:

- `String`
- `User` (for example, `@username`)
- `List` (containing `String` or `User` values)

**Additional details:**

- The `in` operator is not supported for `MergeRequest` types.

**Examples**:

- List all issues where author is `@johndoe`:

  ```plaintext
  author = @johndoe
  ```

- List all epics where author is either `@johndoe` or `@janedoe`:

  ```plaintext
  type = Epic and author in (@johndoe, @janedoe)
  ```

- List all merge requests where author is `@johndoe`:

  ```plaintext
  type = MergeRequest and author = @johndoe
  ```

### Cadence

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab-query-language/glql-haskell/-/issues/74) in GitLab 17.6.

{{< /history >}}

**Description**: Query issues by the [cadence](../group/iterations/_index.md#iteration-cadences) that the issue's iteration is a part of.

**Allowed value types**:

- `Number` (only positive integers)
- `List` (containing `Number` values)
- `Nullable` (either of `none`, or `any`)

**Additional details**:

- Because an issue can have only one iteration, the `=` operator cannot be used with `List` type for the `cadence` field.

**Examples**:

- List all issues with iteration that are a part of cadence ID `123456`:

  ```plaintext
  cadence = 123456
  ```

- List all issues with iterations that are a part of any cadences `123` or `456`:

  ```plaintext
  cadence in (123, 456)
  ```

### Closed at

{{< history >}}

- Alias `closedAt` [introduced](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/137) in GitLab 18.0.
- Operators `>=` and `<=` [introduced](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/work_items/58) in GitLab 18.0.
- Support for querying epics by closed date [introduced](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/222) in GitLab 18.3.

{{< /history >}}

**Description**: Query issues or epics by the date when they were closed.

**Allowed value types**:

- `AbsoluteDate` (in the format `YYYY-MM-DD`)
- `RelativeDate` (in the format `<sign><digit><unit>`, where sign is `+`, `-`, or omitted,
  digit is an integer, and `unit` is one of `d` (days), `w` (weeks), `m` (months) or `y` (years))

**Additional details**:

- For the `=` operator, the time range is considered from 00:00 to 23:59 in the user's time zone.
- `>=` and `<=` operators are inclusive of the dates being queried, whereas `>` and `<` are not.

**Examples**:

- List all issues closed since yesterday:

  ```plaintext
  closed > -1d
  ```

- List all issues closed today:

  ```plaintext
  closed = today()
  ```

- List all issues closed in the month of February 2023:

  ```plaintext
  closed > 2023-02-01 and closed < 2023-02-28
  ```

### Confidential

{{< history >}}

- Support for querying epics by their confidentiality [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/192680) in GitLab 18.1.

{{< /history >}}

**Description**: Query issues or epics by their visibility to project members.

**Allowed value types**:

- `Boolean` (either of `true` or `false`)

**Additional details**:

- Confidential issues queried using GLQL are only visible to people who have permission to view them.

**Examples**:

- List all confidential issues:

  ```plaintext
  confidential = true
  ```

- List all issues that are not confidential:

  ```plaintext
  confidential = false
  ```

### Created at

{{< history >}}

- Aliases `createdAt`, `opened`, and `openedAt` [introduced](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/137) in GitLab 18.0.
- Operators `>=` and `<=` [introduced](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/work_items/58) in GitLab 18.0.
- Support for querying epics by creation date [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/192680) in GitLab 18.1.

{{< /history >}}

**Description**: Query issues, epics, or merge requests by the date when they were created.

**Allowed value types**:

- `AbsoluteDate` (in the format `YYYY-MM-DD`)
- `RelativeDate` (in the format `<sign><digit><unit>`, where sign is `+`, `-`, or omitted,
  digit is an integer, and `unit` is one of `d` (days), `w` (weeks), `m` (months) or `y` (years))

**Additional details**:

- For the `=` operator, the time range is considered from 00:00 to 23:59 in the user's time zone.
- `>=` and `<=` operators are inclusive of the dates being queried, whereas `>` and `<` are not.

**Examples**:

- List all issues that were created in the last week:

  ```plaintext
  created > -1w
  ```

- List all issues created today:

  ```plaintext
  created = today()
  ```

- List all issues created in the month of January 2025 that are still open:

  ```plaintext
  created > 2025-01-01 and created < 2025-01-31 and state = opened
  ```

### Custom field

{{< details >}}

- Tier: Premium, Ultimate

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/233) in GitLab 18.3.

{{< /history >}}

**Description**: Query issues or epics by [custom fields](../work_items/custom_fields.md).

**Allowed value types**:

- `String` (for single-select custom fields)
- `List` (of `String`, for multi-select custom fields)

**Additional details**:

- Custom field names and values are not case-sensitive.

**Examples**

- List all issues where the single-select "Subscription" custom field is set to "Free":

  ```plaintext
  customField("Subscription") = "Free"
  ```

- List all issues where the single-select "Subscription" and "Team" custom fields are set to
  "Free" and "Engineering" respectively:

  ```plaintext
  customField("Subscription") = "Free" and customField("Team") = "Engineering"
  ```

- List all issues where the multi-select "Category" custom field is set to "Markdown" and "Text Editors":

  ```plaintext
  customField("Category") = ("Markdown", "Text Editors")
  ```

  Alternatively:

  ```plaintext
  customField("Category") = "Markdown" and customField("Category") = "Text Editors"
  ```

### Draft

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/491246) in GitLab 17.8.

{{< /history >}}

**Description**: Query merge requests by their draft status.

**Allowed value types**:

- `Boolean` (either of `true` or `false`)

**Examples**:

- List all draft merge requests:

  ```plaintext
  type = MergeRequest and draft = true
  ```

- List all merge requests that are not in draft state:

  ```plaintext
  type = MergeRequest and draft = false
  ```

### Due date

{{< history >}}

- Alias `dueDate` [introduced](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/137) in GitLab 18.0.
- Operators `>=` and `<=` [introduced](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/work_items/58) in GitLab 18.0.
- Support for querying epics by due date [introduced](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/222) in GitLab 18.3.

{{< /history >}}

**Description**: Query issues or epics by the date when they are due.

**Allowed value types**:

- `AbsoluteDate` (in the format `YYYY-MM-DD`)
- `RelativeDate` (in the format `<sign><digit><unit>`, where sign is `+`, `-`, or omitted,
  digit is an integer, and `unit` is one of `d` (days), `w` (weeks), `m` (months) or `y` (years))

**Additional details**:

- For the `=` operator, the time range is considered from 00:00 to 23:59 in the user's time zone.
- `>=` and `<=` operators are inclusive of the dates being queried, whereas `>` and `<` are not.

**Examples**:

- List all issues due in a week:

  ```plaintext
  due < 1w
  ```

- List all issues that were overdue as of January 1, 2025:

  ```plaintext
  due < 2025-01-01
  ```

- List all issues that are due today (but not due yesterday or tomorrow):

  ```plaintext
  due = today()
  ```

- List all issues that have been overdue in the last 1 month:

  ```plaintext
  due > -1m and due < today()
  ```

### Environment

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/491246) in GitLab 17.8.

{{< /history >}}

**Description**: Query merge requests by the environment to which they have been deployed.

**Allowed value types**: `String`

**Examples**:

- List all merge requests that have been deployed to environment `production`:

  ```plaintext
  environment = "production"
  ```

### Epic

{{< details >}}

- Tier: Premium, Ultimate

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/issues/30) in GitLab 18.1.

{{< /history >}}

**Description**: Query issues by their parent epic ID or reference.

**Allowed value types**:

- `Number` (epic ID)
- `String` (containing an epic reference like `&123`)
- `Epic` (for example, `&123`, `gitlab-org&123`)

**Examples**:

- List all issues that have epic `&123` as their parent in project `gitlab-org/gitlab`:

  ```plaintext
  project = "gitlab-org/gitlab" and epic = &123
  ```

- List all issues that have epic `gitlab-com&123` as their parent in project `gitlab-org/gitlab`:

  ```plaintext
  project = "gitlab-org/gitlab" and epic = gitlab-com&123
  ```

### Group

**Description**: Query issues, epics, or merge requests within all projects in a given group.

**Allowed value types**: `String`

**Additional details**:

- Only one group can be queried at a time.
- The `group` cannot be used together with the `project` field.
- If omitted when using inside an embedded view in a group object (like an epic), `group` is assumed to
  be the current group.
- Using the `group` field queries all objects in that group, all its subgroups, and child projects.
- By default, issues or merge requests are searched in all descendant projects across all subgroups.
  To query only the direct child projects of the group, set the [`includeSubgroups` field](#include-subgroups) to `false`.

**Examples**:

- List all issues in the `gitlab-org` group and any of its subgroups:

  ```plaintext
  group = "gitlab-org"
  ```

- List all Tasks in the `gitlab-org` group and any of its subgroups:

  ```plaintext
  group = "gitlab-org" and type = Task
  ```

### Health status

{{< details >}}

- Tier: Ultimate

{{< /details >}}

{{< history >}}

- Alias `healthStatus` [introduced](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/137) in GitLab 18.0.
- Support for querying epics by health status [introduced](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/222) in GitLab 18.3.

{{< /history >}}

**Description**: Query issues or epics by their health status.

**Allowed value types**:

- `StringEnum` (one of `"needs attention"`, `"at risk"` or `"on track"`)
- `Nullable` (either of `null`, `none`, or `any`)

**Examples**:

- List all issues that don't have a health status set:

  ```plaintext
  health = any
  ```

- List all issues where the health status is "needs attention":

  ```plaintext
  health = "needs attention"
  ```

### ID

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/92) in GitLab 17.8.
- Support for querying epics by ID [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/192680) in GitLab 18.1.

{{< /history >}}

**Description**: Query issues, epics, or merge requests by their IDs.

**Allowed value types**:

- `Number` (only positive integers)
- `List` (containing `Number` values)

**Examples**:

- List issue with ID `123`:

  ```plaintext
  id = 123
  ```

- List issues with IDs `1`, `2`, or `3`:

  ```plaintext
  id in (1, 2, 3)
  ```

- List all merge requests with IDs `1`, `2`, or `3`:

  ```plaintext
  type = MergeRequest and id in (1, 2, 3)
  ```

### Include subgroups

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/106) in GitLab 17.10.
- Support for this field to be used with epics [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/192680) in GitLab 18.1.

{{< /history >}}

**Description**: Query issues, epics, or merge requests within the entire hierarchy of a group.

**Allowed value types**:

- `Boolean` (either of `true` or `false`)

**Additional details**:

- This field can only be used with the `group` field.
- The value of this field defaults to `false`.

**Examples**:

- List issues in any project that is a direct child of the `gitlab-org` group:

  ```plaintext
  group = "gitlab-org" and includeSubgroups = false
  ```

- List issues in any project within the entire hierarchy of the `gitlab-org` group:

  ```plaintext
  group = "gitlab-org" and includeSubgroups = true
  ```

### Iteration

{{< details >}}

- Tier: Premium, Ultimate

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab-query-language/glql-haskell/-/issues/74) in GitLab 17.6.
- Support for iteration value types [introduced](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/79) in GitLab 17.8.

{{< /history >}}

**Description**: Query issues by their associated [iteration](../group/iterations/_index.md).

**Allowed value types**:

- `Number` (only positive integers)
- `Iteration` (for example, `*iteration:123456`)
- `List` (containing `Number` or `Iteration` values)
- `Enum` (only `current` is supported)
- `Nullable` (either of `none`, or `any`)

**Additional details**:

- Because an issue can have only one iteration, the `=` operator cannot be used with `List` type for the `iteration` field.
- The `in` operator is not supported for `MergeRequest` types.

**Examples**:

- List all issues with iteration ID `123456` (using a number in the query):

  ```plaintext
  iteration = 123456
  ```

- List all issues that are a part of iterations `123` or `456` (using numbers):

  ```plaintext
  iteration in (123, 456)
  ```

- List all issues with iteration ID `123456` (using iteration syntax):

  ```plaintext
  iteration = *iteration:123456
  ```

- List all issues that are a part of iterations `123` or `456` (using iteration syntax):

  ```plaintext
  iteration in (*iteration:123, *iteration:456)
  ```

- List all issues in the current iteration

  ```plaintext
  iteration = current
  ```

### Labels

{{< history >}}

- Support for label value types [introduced](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/79) in GitLab 17.8.
- Alias `labels` [introduced](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/137) in GitLab 18.0.
- Support for querying epics by labels [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/192680) in GitLab 18.1.

{{< /history >}}

**Description**: Query issues, epics, or merge requests by their associated labels.

**Allowed value types**:

- `String`
- `Label` (for example, `~bug`, `~"team::planning"`)
- `List` (containing `String` or `Label` values)
- `Nullable` (either of `none`, or `any`)

**Additional details**:

- Scoped labels, or labels containing spaces must be wrapped in quotes.
- The `in` operator is not supported for `MergeRequest` types.

**Examples**:

- List all issues with label `~bug`:

  ```plaintext
  label = ~bug
  ```

- List all issues not having label `~"workflow::in progress"`:

  ```plaintext
  label != ~"workflow::in progress"
  ```

- List all issues with labels `~bug` and `~"team::planning"`:

  ```plaintext
  label = (~bug, ~"team::planning")
  ```

- List all issues with labels `~bug` or `~feature`:

  ```plaintext
  label in (~bug, ~feature)
  ```

- List all issues where the labels include neither of `~bug` or `~feature`:

  ```plaintext
  label != (~bug, ~feature)
  ```

- List all issues where none of the scoped labels apply, with scope `workflow::`:

  ```plaintext
  label != ~"workflow::*"
  ```

- List all merge requests with labels `~bug` and `~"team::planning"`

  ```plaintext
  type = MergeRequest and label = (~bug, ~"team::planning")
  ```

### Merged at

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/491246) in GitLab 17.8.
- Alias `mergedAt` [introduced](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/137) in GitLab 18.0.
- Operators `>=` and `<=` [introduced](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/work_items/58) in GitLab 18.0.

{{< /history >}}

**Description**: Query merge requests by the date when they were merged.

**Allowed value types**:

- `AbsoluteDate` (in the format `YYYY-MM-DD`)
- `RelativeDate` (in the format `<sign><digit><unit>`, where sign is `+`, `-`, or omitted,
  digit is an integer, and `unit` is one of `d` (days), `w` (weeks), `m` (months) or `y` (years))

**Additional details**:

- For the `=` operator, the time range is considered from 00:00 to 23:59 in the user's time zone.
- `>=` and `<=` operators are inclusive of the dates being queried, whereas `>` and `<` are not.

**Examples**:

- List all merge requests that have been merged in the last 6 months:

  ```plaintext
  type = MergeRequest and merged > -6m
  ```

- List all merge requests that have been merged in the month of January 2025:

  ```plaintext
  type = MergeRequest and merged > 2025-01-01 and merged < 2025-01-31
  ```

### Merged by user

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/491246) in GitLab 17.8.
- Alias `mergedBy` [introduced](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/137) in GitLab 18.0.

{{< /history >}}

**Description**: Query merge requests by the user that merged the merge request.

**Allowed value types**:

- `String`
- `User` (for example, `@username`)

**Examples**:

- List all merge requests merged by the current user:

  ```plaintext
  type = MergeRequest and merger = currentUser()
  ```

### Milestone

{{< history >}}

- Support for milestone value types [introduced](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/77) in GitLab 17.8.
- Support for querying epics by milestone [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/192680) in GitLab 18.1.

{{< /history >}}

**Description**: Query issues, epics, or merge requests by their associated milestone.

**Allowed value types**:

- `String`
- `Milestone` (for example, `%Backlog`, `%"Awaiting Further Demand"`)
- `List` (containing `String` or `Milestone` values)
- `Nullable` (either of `none`, or `any`)

**Additional details**:

- Milestones containing spaces must be wrapped in quotes (`"`).
- Because an issue can have only one milestone, the `=` operator cannot be used with `List` type for the `milestone` field.
- The `in` operator is not supported for `MergeRequest` and `Epic` types.
- The `Epic` type does not support wildcard milestone filters like `none` or `any`.

**Examples**:

- List all issues with milestone `%Backlog`:

  ```plaintext
  milestone = %Backlog
  ```

- List all issues with milestones `%17.7` or `%17.8`:

  ```plaintext
  milestone in (%17.7, %17.8)
  ```

- List all issues in an upcoming milestone:

  ```plaintext
  milestone = upcoming
  ```

- List all issues in a current milestone:

  ```plaintext
  milestone = started
  ```

- List all issues where the milestone is neither of `%17.7` or `%17.8`:

  ```plaintext
  milestone != (%17.7, %17.8)
  ```

### My reaction emoji

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/223) in GitLab 18.3.

{{< /history >}}

**Description**: Query issues, epics, or merge requests by the current user's [emoji reaction](../emoji_reactions.md) on it.

**Allowed value types**: `String`

**Examples**:

- List all issues where the current user reacted with the thumbs-up emoji:

  ```plaintext
  myReaction = "thumbsup"
  ```

- List all merge requests where the current user did not react with the thumbs-down emoji:

  ```plaintext
  type = MergeRequest and myReaction != "thumbsdown"
  ```

### Project

**Description**: Query issues or merge requests within a particular project.

**Allowed value types**: `String`

**Additional details**:

- Only one project can be queried at a time.
- The `project` field cannot be used together with the `group` field.
- If omitted when using inside an embedded view, `project` is assumed to be the current project.

**Examples**:

- List all issues and work items in the `gitlab-org/gitlab` project:

  ```plaintext
  project = "gitlab-org/gitlab"
  ```

### Reviewers

{{< history >}}

- Aliases `reviewers` and `reviewedBy` [introduced](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/137) in GitLab 18.0.

{{< /history >}}

**Description**: Query merge requests that were reviewed by one or more users.

**Allowed value types**:

- `String`
- `User` (for example, `@username`)
- `Nullable` (either of `null`, `none`, or `any`)

**Examples**:

- List all merge requests reviewed by current user:

  ```plaintext
  type = MergeRequest and reviewer = currentUser()
  ```

### Source branch

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/197407) in GitLab 18.2.

{{< /history >}}

**Description:** Query merge requests by their source branch.

**Allowed value types:** `String`, `List`

**Additional details**:

- `List` values are only supported with the `in` and `!=` operators.

**Examples**:

- List all merge requests from a specific branch:

  ```plaintext
  type = MergeRequest and sourceBranch = "feature/new-feature"
  ```

- List all merge requests from multiple branches:

  ```plaintext
  type = MergeRequest and sourceBranch in ("main", "develop")
  ```

- List all merge requests that are not from a specific branch:

  ```plaintext
  type = MergeRequest and sourceBranch != "main"
  ```

### State

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/96) in GitLab 17.8.
- Support for querying epics by state [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/192680) in GitLab 18.1.

{{< /history >}}

**Description**: Query issues, epics, or merge requests by state.

**Allowed value types**:

- `Enum`
  - For issue and work item types, one of `opened`, `closed`, or `all`
  - For `MergeRequest` types, one of `opened`, `closed`, `merged`, or `all`

**Additional details**:

- The `state` field does not support the `!=` operator.

**Examples**:

- List all closed issues:

  ```plaintext
  state = closed
  ```

- List all open issues:

  ```plaintext
  state = opened
  ```

- List all issues regardless of their state (also the default):

  ```plaintext
  state = all
  ```

- List all merged merge requests:

  ```plaintext
  type = MergeRequest and state = merged
  ```

### Status

{{< details >}}

- Tier: Premium, Ultimate

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/197407) in GitLab 18.2.

{{< /history >}}

**Description:** Query issues by their status.

**Allowed value types:** `String`

**Examples**:

- List all issues with status "To do":

  ```plaintext
  status = "To do"
  ```

### Subscribed

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/223) in GitLab 18.3.

{{< /history >}}

**Description**: Query issues, epics, or merge requests by whether the current user has
[set notifications](../profile/notifications.md)
on or off.

**Allowed value types**: `Boolean`

**Examples**:

- List all open issues where the current user has set notifications on:

  ```plaintext
  state = opened and subscribed = true
  ```

- List all merge requests where the current user has set notifications off:

  ```plaintext
  type = MergeRequest and subscribed = false
  ```

### Target branch

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/197407) in GitLab 18.2.

{{< /history >}}

**Description:** Query merge requests by their target branch.

**Allowed value types:** `String`, `List`

**Additional details**:

- `List` values are only supported with the `in` and `!=` operators.

**Examples**:

- List all merge requests targeting a specific branch:

  ```plaintext
  type = MergeRequest and targetBranch = "feature/new-feature"
  ```

- List all merge requests targeting multiple branches:

  ```plaintext
  type = MergeRequest and targetBranch in ("main", "develop")
  ```

- List all merge requests that are not targeting a specific branch:

  ```plaintext
  type = MergeRequest and targetBranch != "main"
  ```

### Type

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/491246) in GitLab 17.8.
- Support for querying epics [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/192680) in GitLab 18.1.

{{< /history >}}

**Description**: The type of object to query: issues, epics, or merge requests.

**Allowed value types**:

- `Enum`, one of:
  - `Issue`
  - `Incident`
  - `Epic`
  - `TestCase`
  - `Requirement`
  - `Task`
  - `Ticket`
  - `Objective`
  - `KeyResult`
  - `MergeRequest`
- `List` (containing one or more `enum` values)

**Additional details**:

- If omitted when used inside an embedded view, the default `type` is `Issue`.
- `type = Epic` queries can only be used together with the [group](#group) field.
- The `in` operator cannot be used to combine `Epic` and `MergeRequest` types with other types
  in the same query.

**Examples**:

- List incidents:

  ```plaintext
  type = incident
  ```

- List issues and tasks:

  ```plaintext
  type in (Issue, Task)
  ```

- List all merge requests assigned to the current user:

  ```plaintext
  type = MergeRequest and assignee = currentUser()
  ```

- List all epics authored by the current user in the group `gitlab-org`

  ```plaintext
  group = "gitlab-org" and type = Epic and author = currentUser()
  ```

### Updated at

{{< history >}}

- Alias `updatedAt` [introduced](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/137) in GitLab 18.0.
- Operators `>=` and `<=` [introduced](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/work_items/58) in GitLab 18.0.
- Support for querying epics by last updated [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/192680) in GitLab 18.1.

{{< /history >}}

**Description**: Query issues, epics, or merge requests by when they were last updated.

**Allowed value types**:

- `AbsoluteDate` (in the format `YYYY-MM-DD`)
- `RelativeDate` (in the format `<sign><digit><unit>`, where sign is `+`, `-`, or omitted,
  digit is an integer, and `unit` is one of `d` (days), `w` (weeks), `m` (months) or `y` (years))

**Additional details**:

- For the `=` operator, the time range is considered from 00:00 to 23:59 in the user's time zone.
- `>=` and `<=` operators are inclusive of the dates being queried, whereas `>` and `<` are not.

**Examples**:

- List all issues that haven't been edited in the last 1 month:

  ```plaintext
  updated < -1m
  ```

- List all issues that were edited today:

  ```plaintext
  updated = today()
  ```

- List all open MRs that haven't been edited in the last 1 week:

  ```plaintext
  type = MergeRequest and state = opened and updated < -1w
  ```

### Weight

{{< details >}}

- Tier: Premium, Ultimate

{{< /details >}}

**Description**: Query issues by their weight.

**Allowed value types**:

- `Number` (only positive integers or 0)
- `Nullable` (either of `null`, `none`, or `any`)

**Additional details**:

- Comparison operators `<` and `>` cannot be used.

**Examples**:

- List all issues with weight 5:

  ```plaintext
  weight = 5
  ```

- List all issues with weight not 5:

  ```plaintext
  weight != 5
  ```

## Fields in embedded views

{{< history >}}

- Field `iteration` [introduced](https://gitlab.com/gitlab-org/gitlab-query-language/glql-haskell/-/issues/74) in GitLab 17.6.
- Support for merge requests [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/491246) in GitLab 17.8.
- Field `lastComment` [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/512154) in GitLab 17.11.
- Support for epics [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/192680) in GitLab 18.1.
- Fields `status`, `sourceBranch`, `targetBranch`, `sourceProject`, and `targetProject` [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/197407) in GitLab 18.2.
- Fields `health`, and `type` in epics [introduced](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/222) in GitLab 18.3.
- Field `subscribed` [introduced](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/223) in GitLab 18.3.

{{< /history >}}

In embedded views, the `fields` view parameter is a comma-separated list of fields, or field functions that
can be used to indicate what fields to include in the rendered embedded view,
for example, `fields: title, state, health, epic, milestone, weight, updated`.

| Field            | Name or alias                         | Objects supported             | Description |
| ---------------- | ------------------------------------- | ----------------------------- | ----------- |
| Approved by user | `approver`, `approvers`, `approvedBy` | Merge requests                | Display users who approved the merge request |
| Assignees        | `assignee`, `assignees`               | Issues, merge requests        | Display users assigned to the object |
| Author           | `author`                              | Issues, epics, merge requests | Display the author of the object |
| Closed at        | `closed`, `closedAt`                  | Issues, epics, merge requests | Display time since the object was closed |
| Confidential     | `confidential`                        | Issues, epics                 | Display `Yes` or `No` indicating whether the object is confidential |
| Created at       | `created`, `createdAt`                | Issues, epics, merge requests | Display time since the object was created |
| Description      | `description`                         | Issues, epics, merge requests | Display the description of the object |
| Draft            | `draft`                               | Merge requests                | Display `Yes` or `No` indicating whether the merge request is in draft state |
| Due date         | `due`, `dueDate`                      | Issues, epics                 | Display time until the object is due |
| Epic             | `epic`                                | Issues                        | Display a link to the epic for the issue. Available in the Premium and Ultimate tier |
| Health status    | `health`, `healthStatus`              | Issues, epics                 | Display a badge indicating the health status of the object. Available in the Ultimate tier |
| ID               | `id`                                  | Issues, epics, merge requests | Display the ID of the object |
| Iteration        | `iteration`                           | Issues                        | Display the iteration associated with the object. Available in the Premium and Ultimate tier |
| Labels           | `label`, `labels`                     | Issues, epics, merge requests | Display labels associated with the object. Can accept parameters to filter specific labels, for example `labels("workflow::*", "backend")` |
| Last comment     | `lastComment`                         | Issues, epics, merge requests | Display the last comment made on the object |
| Merged at        | `merged`, `mergedAt`                  | Merge requests                | Display time since the merge request was merged |
| Milestone        | `milestone`                           | Issues, epics, merge requests | Display the milestone associated with the object |
| Reviewers        | `reviewer`, `reviewers`               | Merge requests                | Display users assigned to review the merge request |
| Source branch    | `sourceBranch`                        | Merge requests                | Display the source branch of the merge request |
| Source project   | `sourceProject`                       | Merge requests                | Display the source project of the merge request |
| Start date       | `start`, `startDate`                  | Epics                         | Display the start date of the epic |
| State            | `state`                               | Issues, epics, merge requests | Display a badge indicating the state of the object. For issues and epics, values are `Open` or `Closed`. For merge requests, values are `Open`, `Closed`, or `Merged` |
| Status           | `status`                              | Issues                        | Display a badge indicating the status of the issue. For example, "To do" or "Complete". Available in the Premium and Ultimate tiers. |
| Subscribed       | `subscribed`                          | Issues, epics, merge requests | Display `Yes` or `No` indicating whether the current user is subscribed to the object or not |
| Target branch    | `targetBranch`                        | Merge requests                | Display the target branch of the merge request |
| Target project   | `targetProject`                       | Merge requests                | Display the target project of the merge request |
| Title            | `title`                               | Issues, epics, merge requests | Display the title of the object |
| Type             | `type`                                | Issues, epics                 | Display the work item type, for example `Issue`, `Task`, or `Objective` |
| Updated at       | `updated`, `updatedAt`                | Issues, epics, merge requests | Display time since the object was last updated |
| Weight           | `weight`                              | Issues                        | Display the weight of the object. Available in the Premium and Ultimate tiers. |

## Fields to sort embedded views by

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/178) in GitLab 18.2.
- Support for sorting epics by health status [introduced](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/222) in GitLab 18.3.

{{< /history >}}

In embedded views, the `sort` view parameter is a field name followed by
a sort order (`asc` or `desc`) that sorts the results by the specified
field and order.

| Field         | Name (and alias)         | Supported for                 | Description                                     |
|---------------|--------------------------|-------------------------------|-------------------------------------------------|
| Closed at     | `closed`, `closedAt`     | Issues, epics, merge requests | Sort by closed date                             |
| Created       | `created`, `createdAt`   | Issues, epics, merge requests | Sort by created date                            |
| Due date      | `due`, `dueDate`         | Issues, epics                 | Sort by due date                                |
| Health status | `health`, `healthStatus` | Issues, epics                 | Sort by health status                           |
| Merged at     | `merged`, `mergedAt`     | Merge requests                | Sort by merge date                              |
| Milestone     | `milestone`              | Issues, merge requests        | Sort by milestone due date                      |
| Popularity    | `popularity`             | Issues, epics, merge requests | Sort by the number of thumbs up emoji reactions |
| Start date    | `start`, `startDate`     | Epics                         | Sort by start date                              |
| Title         | `title`                  | Issues, epics, merge requests | Sort by title                                   |
| Updated at    | `updated`, `updatedAt`   | Issues, epics, merge requests | Sort by last updated date                       |
| Weight        | `weight`                 | Issues                        | Sort by weight                                  |

**Examples**:

- List all issues in the `gitlab-org/gitlab` project sorted by title. Display columns
  `state`, `title`, and `updated`.

  ````yaml
  ```glql
  display: table
  fields: state, title, updated
  sort: title asc
  query: project = "gitlab-org/gitlab" and type = Issue
  ```
  ````

- List all merge requests in the `gitlab-org` group assigned to the
  authenticated user sorted by the merge date (latest first). Display columns
  `title`, `reviewer`, and `merged`.

  ````yaml
  ```glql
  display: table
  fields: title, reviewer, merged
  sort: merged desc
  query: group = "gitlab-org" and type = MergeRequest and state = merged and author = currentUser()
  limit: 10
  ```
  ````

- List all epics in the `gitlab-org` group sorted by the start date (oldest
  first). Display columns `title`, `state`, and `startDate`.

  ````yaml
  ```glql
  display: table
  fields: title, state, startDate
  sort: startDate asc
  query: group = "gitlab-org" and type = Epic
  ```
  ````

- List all issues in the `gitlab-org` group with an assigned weight sorted by
  the weight (highest first). Display columns `title`, `weight`, and `health`.

  ````yaml
  ```glql
  display: table
  fields: title, weight, health
  sort: weight desc
  query: group = "gitlab-org" and weight = any
  ```
  ````

- List all issues in the `gitlab-org` group due up to a week from today sorted by the due
  date (earliest first). Display columns `title`, `duedate`, and `assignee`.

  ````yaml
  ```glql
  display: table
  fields: title, dueDate, assignee
  sort: dueDate asc
  query: group = "gitlab-org" and due >= today() and due <= 1w
  ```
  ````

## Troubleshooting

### Query timeout errors

You might encounter these error messages:

```plaintext
Embedded view timed out. Add more filters to reduce the number of results.
```

```plaintext
Query temporarily blocked due to repeated timeouts. Please try again later or try narrowing your search scope.
```

These errors occur when your query takes too long to execute.
Large result sets and broad searches can cause timeouts.

To resolve this issue, add filters to limit your search scope:

- Add time range filters to limit results to a specific period, by using date fields like `created`, `updated`, or `closed`.
  For example:

  ````yaml
  ```glql
  display: table
  fields: title, labels, created
  query: group = "gitlab-org" and label = "group::knowledge" and created > "2025-01-01" and created < "2025-03-01"
  ```
  ````

- Filter by recent updates to focus on active items:

  ````yaml
  ```glql
  display: table
  fields: title, labels, updated
  query: group = "gitlab-org" and label = "group::knowledge" and updated > -3m
  ```
  ````

- Use project-specific queries instead of group-wide searches when possible:

  ````yaml
  ```glql
  display: table
  fields: title, state, assignee
  query: project = "gitlab-org/gitlab" and state = opened and updated > -1m
  ```
  ````
