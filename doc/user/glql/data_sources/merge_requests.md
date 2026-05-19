---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Merge requests
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/491246) in GitLab 17.8.

{{< /history >}}

## Allowed scopes

| Scope     | Description                                           |
| --------- | ----------------------------------------------------- |
| `project` | Query merge requests in a specific project.           |
| `group`   | Query merge requests across all projects in a group, including subgroups. |

For more information, see [scopes](_index.md#scopes).

## Query fields

| Field                                                    | Name (and alias)                             | Operators                  |
| -------------------------------------------------------- | -------------------------------------------- | -------------------------- |
| [Approved by user](#mr-approved-by-user)                 | `approver`, `approvedBy`, `approvers`        | `=`, `!=`                  |
| [Assignees](#mr-assignees)                               | `assignee`, `assignees`                      | `=`, `!=`                  |
| [Author](#mr-author)                                     | `author`                                     | `=`, `!=`                  |
| [Closed at](#mr-closed-at)                               | `closed`, `closedAt`                         | `=`, `>`, `<`, `>=`, `<=`  |
| [Created at](#mr-created-at)                             | `created`, `createdAt`, `opened`, `openedAt` | `=`, `>`, `<`, `>=`, `<=`  |
| [Draft](#mr-draft)                                       | `draft`                                      | `=`, `!=`                  |
| [Environment](#mr-environment)                           | `environment`                                | `=`                        |
| [ID](#mr-identifier)                                     | `id`                                         | `=`, `in`                  |
| [Include subgroups](#mr-include-subgroups)               | `includeSubgroups`                            | `=`, `!=`                  |
| [Labels](#mr-labels)                                     | `label`, `labels`                            | `=`, `!=`                  |
| [Merged at](#mr-merged-at)                               | `merged`, `mergedAt`                         | `=`, `>`, `<`, `>=`, `<=`  |
| [Merged by user](#mr-merged-by-user)                     | `merger`, `mergedBy`                         | `=`                        |
| [Milestone](#mr-milestone)                               | `milestone`                                  | `=`, `!=`                  |
| [My reaction emoji](#mr-my-reaction-emoji)               | `myReaction`, `myReactionEmoji`              | `=`, `!=`                  |
| [Reviewers](#mr-reviewers)                               | `reviewer`, `reviewers`, `reviewedBy`        | `=`, `!=`                  |
| [Source branch](#mr-source-branch)                       | `sourceBranch`                               | `=`, `in`, `!=`            |
| [State](#mr-state)                                       | `state`                                      | `=`                        |
| [Subscribed](#mr-subscribed)                             | `subscribed`                                 | `=`, `!=`                  |
| [Target branch](#mr-target-branch)                       | `targetBranch`                               | `=`, `in`, `!=`            |
| [Deployed at](#mr-deployed-at)                           | `deployed`, `deployedAt`                     | `=`, `>`, `<`, `>=`, `<=`  |
| [Updated at](#mr-updated-at)                             | `updated`, `updatedAt`                       | `=`, `>`, `<`, `>=`, `<=`  |

### Approved by user {#mr-approved-by-user}

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

### Assignees {#mr-assignees}

**Description**: Query merge requests by one or more users who are assigned to them.

**Allowed value types**:

- `String`
- `User` (for example, `@username`)
- `Nullable` (either of `null`, `none`, or `any`)

**Notes**:

- `List` values and the `in` operator are not supported for merge requests.

### Author {#mr-author}

**Description**: Query merge requests by their author.

**Allowed value types**:

- `String`
- `User` (for example, `@username`)

**Notes**:

- The `in` operator is not supported for merge requests.

### Closed at {#mr-closed-at}

**Description**: Query merge requests by the date when they were closed.

**Allowed value types**:

- `AbsoluteDate` (in the format `YYYY-MM-DD`)
- `RelativeDate` (in the format `<sign><digit><unit>`, where sign is `+`, `-`, or omitted,
  digit is an integer, and `unit` is one of `d` (days), `w` (weeks), `m` (months) or `y` (years))

**Notes**:

- For the `=` operator, the time range is considered from 00:00 to 23:59 in the user's time zone.
- `>=` and `<=` operators are inclusive of the dates being queried, whereas `>` and `<` are not.

### Created at {#mr-created-at}

**Description**: Query merge requests by the date when they were created.

**Allowed value types**:

- `AbsoluteDate` (in the format `YYYY-MM-DD`)
- `RelativeDate` (in the format `<sign><digit><unit>`, where sign is `+`, `-`, or omitted,
  digit is an integer, and `unit` is one of `d` (days), `w` (weeks), `m` (months) or `y` (years))

**Notes**:

- For the `=` operator, the time range is considered from 00:00 to 23:59 in the user's time zone.
- `>=` and `<=` operators are inclusive of the dates being queried, whereas `>` and `<` are not.

### Draft {#mr-draft}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/491246) in GitLab 17.8.

{{< /history >}}

**Description**: Query merge requests by their draft status.

**Allowed value types**:

- `Boolean` (either of `true` or `false`)

### Deployed at {#mr-deployed-at}

**Description**: Query merge requests by the date when they were deployed.

**Allowed value types**:

- `AbsoluteDate` (in the format `YYYY-MM-DD`)
- `RelativeDate` (in the format `<sign><digit><unit>`, where sign is `+`, `-`, or omitted,
  digit is an integer, and `unit` is one of `d` (days), `w` (weeks), `m` (months) or `y` (years))

**Notes**:

- For the `=` operator, the time range is considered from 00:00 to 23:59 in the user's time zone.
- `>=` and `<=` operators are inclusive of the dates being queried, whereas `>` and `<` are not.

### Environment {#mr-environment}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/491246) in GitLab 17.8.

{{< /history >}}

**Description**: Query merge requests by the environment to which they have been deployed.

**Allowed value types**: `String`

### ID {#mr-identifier}

**Description**: Query merge requests by their IDs.

**Allowed value types**:

- `Number` (only positive integers)
- `List` (containing `Number` values)

### Include subgroups {#mr-include-subgroups}

**Description**: Query merge requests in the entire hierarchy of a group.

**Allowed value types**:

- `Boolean` (either of `true` or `false`)

**Notes**:

- This field can only be used with a `group` scope.
- The value of this field defaults to `false`.

### Labels {#mr-labels}

**Description**: Query merge requests by their associated labels.

**Allowed value types**:

- `String`
- `Label` (for example, `~bug`, `~"team::planning"`)
- `Nullable` (either of `none`, or `any`)

**Notes**:

- The `in` operator is not supported for merge requests.
- Scoped labels, or labels containing spaces must be wrapped in quotes.

### Merged at {#mr-merged-at}

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

**Notes**:

- For the `=` operator, the time range is considered from 00:00 to 23:59 in the user's time zone.
- `>=` and `<=` operators are inclusive of the dates being queried, whereas `>` and `<` are not.

### Merged by user {#mr-merged-by-user}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/491246) in GitLab 17.8.
- Alias `mergedBy` [introduced](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/137) in GitLab 18.0.

{{< /history >}}

**Description**: Query merge requests by the user that merged the merge request.

**Allowed value types**:

- `String`
- `User` (for example, `@username`)

### Milestone {#mr-milestone}

**Description**: Query merge requests by their associated milestone.

**Allowed value types**:

- `String`
- `Milestone` (for example, `%Backlog`, `%"Awaiting Further Demand"`)
- `Nullable` (either of `none`, or `any`)

**Notes**:

- The `in` operator is not supported for merge requests.
- Milestones containing spaces must be wrapped in quotes (`"`).

### My reaction emoji {#mr-my-reaction-emoji}

**Description**: Query merge requests by the current user's [emoji reaction](../../emoji_reactions.md) on it.

**Allowed value types**: `String`

### Reviewers {#mr-reviewers}

{{< history >}}

- Aliases `reviewers` and `reviewedBy` [introduced](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/merge_requests/137) in GitLab 18.0.

{{< /history >}}

**Description**: Query merge requests that were reviewed by one or more users.

**Allowed value types**:

- `String`
- `User` (for example, `@username`)
- `Nullable` (either of `null`, `none`, or `any`)

### Source branch {#mr-source-branch}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/197407) in GitLab 18.2.

{{< /history >}}

**Description:** Query merge requests by their source branch.

**Allowed value types:** `String`, `List`

**Notes**:

- `List` values are only supported with the `in` and `!=` operators.

### State {#mr-state}

**Description**: Query merge requests by state.

**Allowed value types**:

- `Enum`, one of `opened`, `closed`, `merged`, or `all`

**Notes**:

- The `state` field does not support the `!=` operator.

### Subscribed {#mr-subscribed}

**Description**: Query merge requests by whether the current user has
[set notifications](../../profile/notifications.md) on or off.

**Allowed value types**: `Boolean`

### Target branch {#mr-target-branch}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/197407) in GitLab 18.2.

{{< /history >}}

**Description:** Query merge requests by their target branch.

**Allowed value types:** `String`, `List`

**Notes**:

- `List` values are only supported with the `in` and `!=` operators.

### Updated at {#mr-updated-at}

**Description**: Query merge requests by when they were last updated.

**Allowed value types**:

- `AbsoluteDate` (in the format `YYYY-MM-DD`)
- `RelativeDate` (in the format `<sign><digit><unit>`, where sign is `+`, `-`, or omitted,
  digit is an integer, and `unit` is one of `d` (days), `w` (weeks), `m` (months) or `y` (years))

**Notes**:

- For the `=` operator, the time range is considered from 00:00 to 23:59 in the user's time zone.
- `>=` and `<=` operators are inclusive of the dates being queried, whereas `>` and `<` are not.

## Display fields

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/491246) in GitLab 17.8.
- Fields `sourceBranch`, `targetBranch`, `sourceProject`, and `targetProject` [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/197407) in GitLab 18.2.

{{< /history >}}

| Field            | Name or alias                         | Description |
| ---------------- | ------------------------------------- | ----------- |
| Approved         | `approved`                            | Display `Yes` or `No` indicating whether the merge request has been approved |
| Approved by user | `approver`, `approvers`, `approvedBy` | Display users who approved the merge request |
| Assignees        | `assignee`, `assignees`               | Display users assigned to the merge request |
| Author           | `author`                              | Display the author of the merge request |
| Closed at        | `closed`, `closedAt`                  | Display time since the merge request was closed |
| Created at       | `created`, `createdAt`                | Display time since the merge request was created |
| Description      | `description`                         | Display the description of the merge request |
| Draft            | `draft`                               | Display `Yes` or `No` indicating whether the merge request is in draft state |
| ID               | `id`                                  | Display the ID of the merge request |
| Labels           | `label`, `labels`                     | Display labels associated with the merge request |
| Last comment     | `lastComment`                         | Display the last comment made on the merge request |
| Merged at        | `merged`, `mergedAt`                  | Display time since the merge request was merged |
| Merged by user   | `merger`, `mergedBy`                  | Display the user who merged the merge request |
| Milestone        | `milestone`                           | Display the milestone associated with the merge request |
| Project          | `project`                             | Display the project the merge request belongs to |
| Reviewers        | `reviewer`, `reviewers`               | Display users assigned to review the merge request |
| Source branch    | `sourceBranch`                        | Display the source branch of the merge request |
| Source project   | `sourceProject`                       | Display the source project of the merge request |
| State            | `state`                               | Display a badge indicating the state. Values are `Open`, `Closed`, or `Merged` |
| Subscribed       | `subscribed`                          | Display `Yes` or `No` indicating whether the current user is subscribed |
| Target branch    | `targetBranch`                        | Display the target branch of the merge request |
| Target project   | `targetProject`                       | Display the target project of the merge request |
| Time estimate    | `timeEstimate`                        | Display the estimated time for the merge request |
| Title            | `title`                               | Display the title of the merge request |
| Total time spent | `totalTimeSpent`                      | Display the total time spent on the merge request |
| Updated at       | `updated`, `updatedAt`                | Display time since the merge request was last updated |

## Sort fields

| Field         | Name (and alias)       | Description                                     |
|---------------|------------------------|-------------------------------------------------|
| Closed at     | `closed`, `closedAt`   | Sort by closed date                             |
| Created       | `created`, `createdAt` | Sort by created date                            |
| Merged at     | `merged`, `mergedAt`   | Sort by merge date                              |
| Milestone     | `milestone`            | Sort by milestone due date                      |
| Popularity    | `popularity`           | Sort by the number of thumbs up emoji reactions |
| Title         | `title`                | Sort by title                                   |
| Updated at    | `updated`, `updatedAt` | Sort by last updated date                       |

## Examples

- List all merge requests in the `gitlab-org` group created by me sorted by the merge date (latest first):

  ````yaml
  ```glql
  display: table
  fields: title, reviewer, merged
  sort: merged desc
  query: group = "gitlab-org" and type = MergeRequest and state = merged and author = currentUser()
  limit: 10
  ```
  ````
