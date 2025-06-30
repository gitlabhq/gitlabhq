---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GLQL fields
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Status: Beta

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/14767) in GitLab 17.4 [with a flag](../../administration/feature_flags/_index.md) named `glql_integration`. Disabled by default.
- Enabled on GitLab.com in GitLab 17.4 for a subset of groups and projects.
- Promoted to [beta](../../policy/development_stages_support.md#beta) status in GitLab 17.10.
- [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/476990) from experiment to beta in GitLab 17.10.
- Enabled on GitLab.com, GitLab Self-Managed, and GitLab Dedicated in GitLab 17.10.
{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by a feature flag.
For more information, see the history.
This feature is available for testing, but not ready for production use.

{{< /alert >}}

With GitLab Query Language (GLQL), fields are used to:

- [Filter](#fields-inside-query) the results returned from a [GLQL query](_index.md#query-syntax).
- [Control the details](#fields-in-glql-views) displayed in a [GLQL view](_index.md#presentation-syntax).
- [Sort](#fields-to-sort-glql-views-by) the results displayed in a GLQL view.

The following fields are available:

## Fields inside query

In a GLQL view, the `query` parameter can be used to include one more expressions of the
format `field operator value`.

### Type

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/491246) in GitLab 17.8.
- Support for querying epics [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/192680) in GitLab 18.1.

{{< /history >}}

**Description**: The type of object to query: one of the work item types or merge requests.

**Field name**: `type`

**Allowed operators**: `=`, `in`

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

- If omitted when used inside a GLQL view, all issue and work item types are included by default.
- Certain work item types (like `Issue`, `Task`, or `Objective`) cannot be used together with `MergeRequest` and `Epic` types.
- `type = Epic` queries can only be used together with the [group](#group) field.

**Examples**:

- List issues of type `Incident`:

  ```plaintext
  type = incident
  ```

- List issues of types `Issue` or `Task`:

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

### Approved by user

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/491246) in GitLab 17.8.
- Aliases `approvedBy` and `approvers` [introduced](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/137) in GitLab 18.0.

{{< /history >}}

**Description**: Query merge requests by one or more users who approved the merge request.

**Field name**: `approver`

**Aliases**: `approvedBy`, `approvers`

**Allowed operators**: `=`, `!=`

**Allowed value types**:

- `String`
- `User` (for example, `@username`)
- `List` (containing `String` or `User` values)
- `Nullable` (either of `null`, `none`, or `any`)

**Supported for object types**: `MergeRequest`

**Examples**:

- List all merge requests approved by current user and `@johndoe`

  ```plaintext
  type = MergeRequest and approver = (currentUser(), @johndoe)
  ```

### Assignees

{{< history >}}

- Alias `assignees` [introduced](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/137) in GitLab 18.0.

{{< /history >}}

**Description**: Query issues or merge requests by one or more users who are assigned to the issue or merge request.

**Field name**: `assignee`

**Aliases**: `assignees`

**Allowed operators**: `=`, `in`, `!=`

**Allowed value types**:

- `String`
- `User` (for example, `@username`)
- `List` (containing `String` or `User` values)
- `Nullable` (either of `null`, `none`, or `any`)

**Supported for object types**:

- `Issue`
- Work item types like `Task` or `Objective`
- `MergeRequest`

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

{{< /history >}}

**Description**: Query issues or merge request by their author.

**Field name**: `author`

**Allowed operators**: `=`, `!=`

**Allowed value types**:

- `String`
- `User` (for example, `@username`)

**Supported for object types**:

- `Issue`
- `Epic`
- Work item types like `Task` or `Objective`
- `MergeRequest`

**Examples**:

- List all issues where author is `@johndoe`:

  ```plaintext
  author = @johndoe
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

**Field name**: `cadence`

**Allowed operators**: `=`, `in`, `!=`

**Allowed value types**:

- `Number` (only positive integers)
- `List` (containing `Number` values)
- `Nullable` (either of `none`, or `any`)

**Supported for object types**:

- `Issue`
- Work item types like `Task` or `Objective`

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

{{< /history >}}

**Description**: Query issues or merge requests by the date when they were closed.

**Field name**: `closed`

**Aliases**: `closedAt`

**Allowed operators**: `=`, `>`, `<`, `>=`, `<=`

**Allowed value types**:

- `AbsoluteDate` (in the format `YYYY-MM-DD`)
- `RelativeDate` (in the format `<sign><digit><unit>`, where sign is `+`, `-`, or omitted,
  digit is an integer, and `unit` is one of `d` (days), `w` (weeks), `m` (months) or `y` (years))

**Supported for object types**:

- `Issue`
- Work item types like `Task` or `Objective`

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

**Description**: Query issues by their visibility to project members.

**Field name**: `confidential`

**Allowed operators**: `=`, `!=`

**Allowed value types**:

- `Boolean` (either of `true` or `false`)

**Supported for object types**:

- `Issue`
- `Epic`
- Work item types like `Task` or `Objective`

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

**Description**: Query issues or merge requests by the date when they were created.

**Field name**: `created`

**Aliases**: `createdAt`, `opened`, `openedAt`

**Allowed operators**: `=`, `>`, `<`, `>=`, `<=`

**Allowed value types**:

- `AbsoluteDate` (in the format `YYYY-MM-DD`)
- `RelativeDate` (in the format `<sign><digit><unit>`, where sign is `+`, `-`, or omitted,
  digit is an integer, and `unit` is one of `d` (days), `w` (weeks), `m` (months) or `y` (years))

**Supported for object types**:

- `Issue`
- `Epic`
- Work item types like `Task` or `Objective`
- `MergeRequests`

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

### Deployed at

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/491246) in GitLab 17.8.
- Alias `deployedAt` [introduced](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/137) in GitLab 18.0.
- Operators `>=` and `<=` [introduced](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/work_items/58) in GitLab 18.0.

{{< /history >}}

**Description**: Query merge requests by the date when they were deployed.

**Field name**: `deployed`

**Aliases**: `deployedAt`

**Allowed operators**: `=`, `>`, `<`, `>=`, `<=`

**Allowed value types**:

- `AbsoluteDate` (in the format `YYYY-MM-DD`)
- `RelativeDate` (in the format `<sign><digit><unit>`, where sign is `+`, `-`, or omitted,
  digit is an integer, and `unit` is one of `d` (days), `w` (weeks), `m` (months) or `y` (years))

**Supported for object types**: `MergeRequest`

**Additional details**:

- For the `=` operator, the time range is considered from 00:00 to 23:59 in the user's time zone.
- `>=` and `<=` operators are inclusive of the dates being queried, whereas `>` and `<` are not.

**Examples**:

- List all merge requests that have been deployed in the past week:

  ```plaintext
  type = MergeRequest and deployed > -1w
  ```

- List all merge requests that have been deployed in the month of January 2025:

  ```plaintext
  type = MergeRequest and deployed > 2025-01-01 and deployed < 2025-01-31
  ```

### Draft

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/491246) in GitLab 17.8.

{{< /history >}}

**Description**: Query merge requests by their draft status.

**Field name**: `draft`

**Allowed operators**: `=`, `!=`

**Allowed value types**:

- `Boolean` (either of `true` or `false`)

**Supported for object types**: `MergeRequest`

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

{{< /history >}}

**Description**: Query issues by the date when they are due.

**Field name**: `due`

**Aliases**: `dueDate`

**Allowed operators**: `=`, `>`, `<`, `>=`, `<=`

**Allowed value types**:

- `AbsoluteDate` (in the format `YYYY-MM-DD`)
- `RelativeDate` (in the format `<sign><digit><unit>`, where sign is `+`, `-`, or omitted,
  digit is an integer, and `unit` is one of `d` (days), `w` (weeks), `m` (months) or `y` (years))

**Supported for object types**:

- `Issue`
- Work item types like `Task` or `Objective`

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

**Field name**: `environment`

**Allowed operators**: `=`

**Allowed value types**: `String`

**Supported for object types**: `MergeRequest`

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

**Field name**: `epic`

**Allowed operators**: `=`

**Allowed value types**:

- `Number` (epic ID)
- `String` (containing an epic reference like `&123`)
- `Epic` (for example, `&123`, `gitlab-org&123`)

**Supported for object types**: `Issue`

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

**Description**: Query issues or merge requests within all projects in a given group.

**Field name**: `group`

**Allowed operators**: `=`

**Allowed value types**: `String`

**Supported for object types**:

- `Issue`
- Work item types like `Task` or `Objective`
- `MergeRequest`

**Additional details**:

- Only one group can be queried at a time.
- The `group` cannot be used together with the `project` field.
- If omitted when using inside a GLQL view in a group object (like an epic), `group` is assumed to
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

{{< history >}}

- Alias `healthStatus` [introduced](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/137) in GitLab 18.0.

{{< /history >}}

**Description**: Query issues by their health status.

**Field name**: `health`

**Aliases**: `healthStatus`

**Allowed operators**: `=`

**Allowed value types**:

- `StringEnum` (one of `"needs attention"`, `"at risk"` or `"on track"`)
- `Nullable` (either of `null`, `none`, or `any`)

**Supported for object types**:

- `Issue`
- Work item types like `Task` or `Objective`

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

**Description**: Query issues or merge requests by their IDs.

**Field name**: `id`

**Allowed operators**: `=`, `in`

**Allowed value types**:

- `Number` (only positive integers)
- `List` (containing `Number` values)

**Supported for object types**:

- `Issue`
- `Epic`
- Work item types like `Task` or `Objective`
- `MergeRequest`

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

**Description**: Query within the entire hierarchy of a group.

**Field name**: `includeSubgroups`

**Allowed operators**: `=`, `!=`

**Allowed value types**:

- `Boolean` (either of `true` or `false`)

**Supported for object types**:

- `Issue`
- `Epic`
- Work item types like `Task` or `Objective`
- `MergeRequest`

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

**Field name**: `iteration`

**Allowed operators**: `=`, `in`, `!=`

**Allowed value types**:

- `Number` (only positive integers)
- `Iteration` (for example, `*iteration:123456`)
- `List` (containing `Number` or `Iteration` values)
- `Enum` (only `current` is supported)
- `Nullable` (either of `none`, or `any`)

**Supported for object types**:

- `Issue`
- Work item types like `Task` or `Objective`

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

**Description**: Query issues or merge requests by their associated labels.

**Field name**: `label`

**Aliases**: `labels`

**Allowed operators**: `=`, `in`, `!=`

**Allowed value types**:

- `String`
- `Label` (for example, `~bug`, `~"team::planning"`)
- `List` (containing `String` or `Label` values)
- `Nullable` (either of `none`, or `any`)

**Supported for object types**:

- `Issue`
- `Epic`
- Work item types like `Task` or `Objective`
- `MergeRequest`

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

**Field name**: `merged`

**Aliases**: `mergedAt`

**Allowed operators**: `=`, `>`, `<`, `>=`, `<=`

**Allowed value types**:

- `AbsoluteDate` (in the format `YYYY-MM-DD`)
- `RelativeDate` (in the format `<sign><digit><unit>`, where sign is `+`, `-`, or omitted,
  digit is an integer, and `unit` is one of `d` (days), `w` (weeks), `m` (months) or `y` (years))

**Supported for object types**: `MergeRequest`

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

**Field name**: `merger`

**Aliases**: `mergedBy`

**Allowed operators**: `=`

**Allowed value types**:

- `String`
- `User` (for example, `@username`)
- `List` (containing `String` or `User` values)
- `Nullable` (either of `null`, `none`, or `any`)

**Supported for object types**: `MergeRequest`

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

**Description**: Query issues or merge requests by their associated milestone.

**Field name**: `milestone`

**Allowed operators**: `=`, `in`, `!=`

**Allowed value types**:

- `String`
- `Milestone` (for example, `%Backlog`, `%"Awaiting Further Demand"`)
- `List` (containing `String` or `Milestone` values)
- `Nullable` (either of `none`, or `any`)

**Supported for object types**:

- `Issue`
- `Epic`
- Work item types like `Task` or `Objective`
- `MergeRequest`

**Additional details**:

- Milestones containing spaces must be wrapped in quotes (`"`).
- Because an issue can have only one milestone, the `=` operator cannot be used with `List` type for the `milestone` field.
- The `in` operator is not supported for `MergeRequest` types.

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

### Project

**Description**: Query issues or merge requests within a particular project.

**Field name**: `project`

**Allowed operators**: `=`

**Allowed value types**: `String`

**Supported for object types**:

- `Issue`
- Work item types like `Task` or `Objective`
- `MergeRequest`

**Additional details**:

- Only one project can be queried at a time.
- The `project` field cannot be used together with the `group` field.
- If omitted when using inside a GLQL view, `project` is assumed to be the current project.

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

**Field name**: `reviewer`

**Aliases**: `reviewers`, `reviewedBy`

**Allowed operators**: `=`, `!=`

**Allowed value types**:

- `String`
- `User` (for example, `@username`)
- `List` (containing `String` or `User` values)
- `Nullable` (either of `null`, `none`, or `any`)

**Supported for object types**: `MergeRequest`

**Examples**:

- List all merge requests reviewed by current user and `@johndoe`

  ```plaintext
  type = MergeRequest and reviewer = (currentUser(), @johndoe)
  ```

### State

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/96) in GitLab 17.8.
- Support for querying epics by state [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/192680) in GitLab 18.1.

{{< /history >}}

**Description**: The state of this issue or merge request.

**Field name**: `state`

**Allowed operators**: `=`

**Allowed value types**:

- `Enum`
  - For issue and work item types, one of `opened`, `closed`, or `all`
  - For `MergeRequest` types, one of `opened`, `closed`, `merged`, or `all`

**Supported for object types**:

- `Issue`
- `Epic`
- Work item types like `Task` or `Objective`
- `MergeRequest`

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

### Updated at

{{< history >}}

- Alias `updatedAt` [introduced](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/137) in GitLab 18.0.
- Operators `>=` and `<=` [introduced](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/work_items/58) in GitLab 18.0.

{{< /history >}}

**Description**: Query issues or merge requests by when they were last updated.

**Field name**: `updated`

**Aliases**: `updatedAt`

**Allowed operators**: `=`, `>`, `<`, `>=`, `<=`

**Allowed value types**:

- `AbsoluteDate` (in the format `YYYY-MM-DD`)
- `RelativeDate` (in the format `<sign><digit><unit>`, where sign is `+`, `-`, or omitted,
  digit is an integer, and `unit` is one of `d` (days), `w` (weeks), `m` (months) or `y` (years))

**Supported for object types**:

- `Issue`
- Work item types like `Task` or `Objective`
- `MergeRequests`

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

**Description**: Query issues by their weight.

**Field name**: `weight`

**Allowed operators**: `=`, `!=`

**Allowed value types**:

- `Number` (only positive integers or 0)
- `Nullable` (either of `null`, `none`, or `any`)

**Supported for object types**:

- `Issue`
- Work item types like `Task` or `Objective`

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

## Fields in GLQL views

In GLQL views, the `fields` view parameter is a comma-separated list of fields, or field functions that
can be used to indicate what fields to include in the rendered GLQL view.

### Approved by user

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/491246) in GitLab 17.8.

{{< /history >}}

**Description**: Display all users who have approved a merge request listed in the view.

**Field name**: `approver`

**Aliases**: `approvers`, `approvedBy`

**Supported for**: Merge requests

### Assignees

**Description**: Display all users who are assigned to an object listed in the view.

**Field name**: `assignee`

**Aliases**: `assignees`

**Supported for**: Issues, merge requests

### Author

{{< history >}}

- Support for epics [added](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/192680) in GitLab 18.1.

{{< /history >}}

**Description**: Display the author of an object listed in the view.

**Field name**: `author`

**Supported for**: Issues, epics, merge requests

### Closed at

{{< history >}}

- Support for epics [added](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/192680) in GitLab 18.1.

{{< /history >}}

**Description**: Display relative time since today when an object listed in the view was closed.

**Field name**: `closed`

**Aliases**: `closedAt`

**Supported for**: Issues, epics, merge requests

### Confidential

{{< history >}}

- Support for epics [added](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/192680) in GitLab 18.1.

{{< /history >}}

**Description**: Display either `Yes` or `No` indicating whether an object listed in the view is confidential.

**Field name**: `confidential`

**Supported for**: Issues, epics

### Created at

{{< history >}}

- Support for epics [added](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/192680) in GitLab 18.1.

{{< /history >}}

**Description**: Display relative time since today when an object listed in the view was opened.

**Field name**: `created`

**Aliases**: `createdAt`

**Supported for**: Issues, epics, merge requests

### Deployed at

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/491246) in GitLab 17.8.

{{< /history >}}

**Description**: Display relative time since today when a merge request listed in the view was deployed.

**Field name**: `deployed`

**Aliases**: `deployedAt`

**Supported for**: Merge requests

### Draft

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/491246) in GitLab 17.8.

{{< /history >}}

**Description**: Display either `Yes` or `No` indicating whether a merge request listed in the view is in draft state.

**Field name**: `draft`

**Supported for**: Merge requests

### Description

{{< history >}}

- Support for epics [added](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/192680) in GitLab 18.1.

{{< /history >}}

**Description**: Displays the description of an issue or a merge request listed in the view.

**Field name**: `description`

**Supported for**: Issues, epics, merge requests

### Due date

{{< history >}}

- Support for epics [added](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/192680) in GitLab 18.1.

{{< /history >}}

**Description**: Display relative time since today when an object listed in the view is due.

**Field name**: `due`

**Aliases**: `dueDate`

**Supported for**: Issues, epics

### Health status

**Description**: Display a badge indicating the health status of an object listed in the view.

**Field name**: `health`

**Aliases**: `healthStatus`

**Supported for**: Issues

### ID

{{< history >}}

- Support for epics [added](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/192680) in GitLab 18.1.

{{< /history >}}

**Description**: Display the ID of an object listed in the view.

**Field name**: `id`

**Supported for**: Issues, epics, merge requests

### Iteration

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab-query-language/glql-haskell/-/issues/74) in GitLab 17.6.

{{< /history >}}

**Description**: Display the iteration an object listed in the view may be associated with.

**Field name**: `iteration`

**Supported for**: Issues

### Labels

**Description**: Display all labels associated with an object listed in the view.

{{< history >}}

- Support for epics [added](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/192680) in GitLab 18.1.

{{< /history >}}

**Field name**: `label`

**Aliases**: `labels`

**Supported for**: Issues, epics, merge requests

### Last comment

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/512154) in GitLab 17.11.

{{< /history >}}

**Description**: Display the last comment made on an object listed in the view.

**Field name**: `lastComment`

**Supported for**: Issues, epics, merge requests

### Merged at

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/491246) in GitLab 17.8.

{{< /history >}}

**Description**: Display relative time since today when a merge request listed in the view was merged.

**Field name**: `merged`

**Aliases**: `mergedAt`

**Supported for**: Merge requests

### Milestone

**Description**: Display the milestone associated with an object listed in the view.

**Field name**: `milestone`

**Supported for**: Issues, epics, merge requests

### Reviewers

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/491246) in GitLab 17.8.

{{< /history >}}

**Description**: Display all users who are assigned to a merge request listed in the view for review.

**Field name**: `reviewer`

**Aliases**: `reviewers`

**Supported for**: Merge requests

### Start date

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/192680) in GitLab 18.1.

{{< /history >}}

**Description**: Display the start date of epics listed in the view.

**Field name**: `start`

**Aliases**: `startDate`

**Supported for**: Epics

### State

**Description**: Display a badge indicating the state of an object listed in the view. For issues and epics,
possible values are `Open` or `Closed`. For merge requests, possible values are `Open`, `Closed` or `Merged`.

**Field name**: `state`

**Supported for**: Issues, epics, merge requests

### Title

**Description**: Displays the title of an object listed in the view.

**Field name**: `title`

**Supported for**: Issues, epics, merge requests

### Type

**Description**: Displays the type of the work item listed in the view, for example Issue, Task, Objective, or Key Result.

**Field name**: `type`

**Supported for**: Issues

### Updated at

**Description**: Display relative time since today when an object listed in the view was last updated.

**Field name**: `updated`

**Aliases**: `updatedAt`

**Supported for**: Issues, epics, merge requests

### Weight

**Description**: Display the weight of an object listed in the view.

**Field name**: `weight`

**Supported for**: Issues

## Fields to sort GLQL views by

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/178) in GitLab 18.2.

{{< /history >}}

In GLQL views, the `sort` view parameter is a field name followed by
a sort order (`asc` or `desc`) that sorts the results by the specified
field and order.

| Field         | Name (and alias)         | Supported for                 | Description                                     |
|---------------|--------------------------|-------------------------------|-------------------------------------------------|
| Closed at     | `closed`, `closedAt`     | Issues, epics, merge requests | Sort by closed date                             |
| Created       | `created`, `createdAt`   | Issues, epics, merge requests | Sort by created date                            |
| Due date      | `due`, `dueDate`         | Issues, epics                 | Sort by due date                                |
| Health status | `health`, `healthStatus` | Issues                        | Sort by health status                           |
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
