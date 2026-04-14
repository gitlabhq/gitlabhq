---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GLQL fields
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/14767) in GitLab 17.4 [with a flag](../../administration/feature_flags/_index.md) named `glql_integration`. Disabled by default.
- Enabled on GitLab.com in GitLab 17.4 for a subset of groups and projects.
- [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/476990) from experiment to [beta](../../policy/development_stages_support.md#beta) in GitLab 17.10.
- [Enabled on GitLab.com, GitLab Self-Managed, and GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/work_items/476990) in GitLab 17.10.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/554870) in GitLab 18.3. Feature flag `glql_integration` removed.

{{< /history >}}

With GitLab Query Language (GLQL), fields are used to:

- Filter the results returned from a [GLQL query](_index.md#query-syntax).
- Control the details displayed in an [embedded view](_index.md#presentation-syntax).
- Sort the results displayed in an embedded view.

You use fields in three embedded view parameters:

- **`query`** - Set conditions to determine which items to retrieve.
  The `query` parameter can include one or more expressions of the
  format `<field> <operator> <value>`. Multiple expressions are joined with `and`,
  for example, `group = "gitlab-org" and author = currentUser()`.
- **`fields`** - Specify which columns and details appear in your view.
  A comma-separated list of fields or [field functions](functions.md#functions-in-embedded-views),
  for example, `fields: title, state, health, epic, milestone, weight, updated`.
- **`sort`** - Order items by specific criteria.
  A field name followed by a sort order (`asc` or `desc`),
  for example, `sort: updated desc`.

## Data sources

For a list of supported data sources and their fields, see [GLQL data sources](data_sources/_index.md).

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
  query: type = Issue and group = "gitlab-org" and label = "group::knowledge" and created > "2025-01-01" and created < "2025-03-01"
  ```
  ````

- Filter by recent updates to focus on active items:

  ````yaml
  ```glql
  display: table
  fields: title, labels, updated
  query: type = Issue and group = "gitlab-org" and label = "group::knowledge" and updated > -3m
  ```
  ````

- Use project-specific queries instead of group-wide searches when possible:

  ````yaml
  ```glql
  display: table
  fields: title, state, assignee
  query: type = Issue and project = "gitlab-org/gitlab" and state = opened and updated > -1m
  ```
  ````

### Error: `Invalid username reference`

You might get an error that states `Invalid username reference` when using the `@` symbol
with a username that starts with a number in GLQL queries. For example:

```plaintext
An error occurred when trying to display this embedded view:
* Error: Invalid username reference @123username
```

This issue occurs because the GLQL embedded view renderer does not support `@` mentions
for usernames that start with a number, even though these are valid in GitLab.

The workaround is to remove the `@` symbol and wrap the username in quotes.
For example, use `assignee = "123username"` instead of `assignee = @123username`.

For more information, see [issue 583119](https://gitlab.com/gitlab-org/gitlab/-/issues/583119).
