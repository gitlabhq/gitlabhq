---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Code suggestions
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/21212) in GitLab 19.1.

{{< /history >}}

Code suggestions is a data source that provides aggregated metrics about
[GitLab Duo Code Suggestions](../../project/repository/code_suggestions/_index.md)
usage across your project or group.

## Allowed modes

- [`analytics`](../_index.md#analytics-mode)

## Allowed scopes

| Scope     | Description                                                                 |
| --------- | --------------------------------------------------------------------------- |
| `project` | Query code suggestions in a specific project.                               |
| `group`   | Query code suggestions across all projects in a group, including subgroups. |

## Query fields

| Field                                      | Name (and alias) | Operators                 |
| ------------------------------------------ | ---------------- | ------------------------- |
| [IDE name](#cs-ide-name)                   | `ideName`        | `=`, `in`                 |
| [Language](#cs-language)                    | `language`       | `=`, `in`                 |
| [Timestamp](#cs-timestamp)                 | `timestamp`      | `=`, `>`, `<`, `>=`, `<=` |
| [User](#cs-user)                           | `user`           | `=`, `in`                 |

### IDE name {#cs-ide-name}

**Description**: Filter by the IDE used to generate suggestions.

**Allowed value types**:

- `String`
- `List` (use `in` operator for multiple values)

### Language {#cs-language}

**Description**: Filter by the programming language of the suggestion.

**Allowed value types**:

- `String`
- `List` (use `in` operator for multiple values)

### Timestamp {#cs-timestamp}

**Description**: Filter by when the suggestion was generated.
Use range operators to define a time window.

**Allowed value types**:

- `AbsoluteDate` (in the format `YYYY-MM-DD`)
- `RelativeDate` (in the format `<sign><digit><unit>`, where sign is `+`, `-`, or omitted,
  digit is an integer, and `unit` is one of `d` (days), `w` (weeks), `m` (months) or `y` (years))

### User {#cs-user}

**Description**: Filter by the user who received the suggestion.

**Allowed value types**:

- `Number` (user ID)
- `List` (use `in` operator for multiple user IDs)

> [!note]
> Support for username filtering is being tracked in [issue 599750](https://gitlab.com/gitlab-org/gitlab/-/work_items/599750).

## Dimensions

The following dimensions are supported:

| Dimension | Name (and alias) | Description                                          |
|-----------|------------------|------------------------------------------------------|
| IDE name  | `ideName`        | Group by IDE used (for example, VSCode, JetBrains).  |
| Language  | `language`       | Group by programming language.                       |
| Timestamp | `timestamp`      | Group by date.                                       |
| User      | `user`           | Group by user (displays avatar, name, and username). |

## Metrics

The following metrics are supported:

| Metric              | Name (and alias)    | Description                             |
|---------------------|---------------------|-----------------------------------------|
| Acceptance rate     | `acceptanceRate`    | Ratio of accepted to shown suggestions. |
| Accepted count      | `acceptedCount`     | Number of accepted suggestions.         |
| Rejected count      | `rejectedCount`     | Number of rejected suggestions.         |
| Shown count         | `shownCount`        | Number of suggestions shown to users.   |
| Suggestion size sum | `suggestionSizeSum` | Total volume of suggestions.            |
| Total count         | `totalCount`        | Total number of suggestions.            |
| Users count         | `usersCount`        | Number of unique users.                 |

## Examples

- Acceptance rate by language for the last 30 days:

  ````yaml
  ```glql
  display: table
  mode: analytics
  query: type = CodeSuggestion and timestamp >= -30d
  dimensions: language as "Language"
  metrics: totalCount as "Total", acceptanceRate as "Acceptance Rate"
  sort: acceptanceRate desc
  ```
  ````

- Usage by IDE:

  ````yaml
  ```glql
  display: table
  mode: analytics
  query: type = CodeSuggestion and timestamp >= -30d
  dimensions: ideName as "IDE"
  metrics: totalCount as "Total Suggestions", usersCount as "Active Users"
  sort: totalCount desc
  ```
  ````

- Overall metrics without grouping:

  ````yaml
  ```glql
  display: table
  mode: analytics
  query: type = CodeSuggestion and timestamp >= -30d
  metrics: totalCount as "Total", acceptedCount as "Accepted", rejectedCount as "Rejected", shownCount as "Shown", acceptanceRate as "Acceptance Rate"
  ```
  ````

- Suggestions per user for a specific project, filtered to Ruby:

  ````yaml
  ```glql
  display: table
  mode: analytics
  query: type = CodeSuggestion and timestamp >= -30d and language = "ruby"
  dimensions: user as "User"
  metrics: totalCount as "Total", acceptanceRate as "Acceptance Rate"
  sort: totalCount desc
  limit: 10
  ```
  ````

- Suggestions over time by language in a date range:

  ````yaml
  ```glql
  display: table
  mode: analytics
  query: type = CodeSuggestion and timestamp >= "2026-01-01" and timestamp <= "2026-03-31"
  dimensions: timestamp as "Date", language as "Language"
  metrics: totalCount as "Total", acceptanceRate as "Acceptance Rate"
  sort: timestamp desc
  ```
  ````

- Filter to specific IDEs and languages:

  ````yaml
  ```glql
  display: table
  mode: analytics
  query: type = CodeSuggestion and timestamp >= -7d and ideName in ("Visual Studio Code", "RubyMine") and language in ("ruby", "python")
  dimensions: ideName as "IDE", language as "Language"
  metrics: totalCount as "Total", acceptanceRate as "Rate"
  sort: totalCount desc
  ```
  ````
