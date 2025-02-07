---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GLQL functions
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed
**Status:** Experiment

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/14767) in GitLab 17.4 [with a flag](../../administration/feature_flags.md) named `glql_integration`. Disabled by default.
> - Enabled on GitLab.com in GitLab 17.4 for a subset of groups and projects.
> - `iteration` and `cadence` fields [introduced](https://gitlab.com/gitlab-org/gitlab-query-language/gitlab-query-language/-/issues/74) in GitLab 17.6.

FLAG:
The availability of this feature is controlled by a feature flag.
For more information, see the history.
This feature is available for testing, but not ready for production use.

Use functions with [GitLab Query Language (GLQL)](_index.md) to create dynamic queries.

## Functions inside query

To make a query context-specific, use functions inside a [query](_index.md#query-syntax), for example,
by filtering by a current user or a date.

### Current user

**Function name**: `currentUser`

**Parameters**: None

**Syntax**: `currentUser()`

**Description**: Evaluates to the current authenticated user.

**Additional details**:

- Using this function in a query makes the query fail for users who are not authenticated.

**Examples**:

- List all issues where the current authenticated user is the assignee:

  ```plaintext
  assignee = currentUser()
  ```

- List all merge requests where the current authenticated user is the assignee but not the author:

  ```plaintext
  type = MergeRequest and assignee = currentUser() and author != currentUser()
  ```

### Today

**Function name**: `today`

**Parameters**: None

**Syntax**: `today()`

**Description**: Evaluates to today's date at 00:00 in the user's time zone.

**Additional details**:

- When used with the `=` operator, the time range is considered from 00:00 to 23:59 in the user's time zone.

**Examples**:

- List all issues created today:

  ```plaintext
  created = today()
  ```

- List all merge requests merged today:

  ```plaintext
  type = MergeRequest and merged = today()
  ```

## Functions in GLQL views

To derive a new column from an existing field of a [GLQL view](_index.md#glql-views), include
functions in the `fields` parameter.

### Extract labels into a new column

**Function name**: `labels`

**Parameters**: One or more `String` values

**Syntax**: `labels("field1", "field2")`

**Description**:

The `labels` function takes one or more label name string values as parameter,
and creates a filtered column with only those labels on issues.
The function also works as an extractor, so if a label has been extracted, it no longer shows up
in the regular `labels` column, if you choose to display that column as well.

**Additional details**:

- By default, this function looks for an exact match to the label name.
  A wildcard character (`*`) in the string to match any character.
- A minimum of 1 and maximum of 100 label names can be passed to the `labels` function.
- Label names passed to this function are case-insensitive. For example, `Deliverable` and `deliverable` are equivalent.

**Examples**:

- Include all `workflow` scoped labels in the column:

  ```plaintext
  labels("workflow::*")
  ```

- Include labels `Deliverable`, `Stretch`, and `Spike`:

  ```plaintext
  labels("Deliverable", "Stretch", "Spike")
  ```

- Include all labels like `backend`, `frontend`, and others that end with `end`:

  ```plaintext
  labels("*end")
  ```

To include the `labels` function in a GLQL view:

````markdown
```glql
display: list
fields: title, health, due, labels("workflow::*"), labels
limit: 5
query: project = "gitlab-org/gitlab" AND assignee = currentUser() AND opened = true
```
````
