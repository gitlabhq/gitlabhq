---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GLQL data sources
---

GLQL can query the following data sources:

| Data source | Standard mode | [Analytics mode](../_index.md#analytics-mode) | `type` values | Description |
|---|---|---|---|---|
| Work items | {{< yes >}} | {{< no >}} | `Issue`, `Incident`, `TestCase`, `Requirement`, `Task`, `Ticket`, `Objective`, `KeyResult`, `Epic` | Issues, epics, and other work item types. Default when `type` is omitted. |
| Merge requests | {{< yes >}} | {{< yes >}} | `MergeRequest` | Code review and merge workflow. |
| Pipelines | {{< yes >}} | {{< yes >}} | `Pipeline` | CI/CD pipelines. |
| Jobs | {{< yes >}} | {{< no >}} | `Job` | CI/CD jobs within pipelines. |
| Projects | {{< yes >}} | {{< no >}} | `Project` | Projects within a namespace. |
| Agent platform sessions | {{< no >}} | {{< yes >}} | `AgentPlatformSession` | Aggregated GitLab Duo Agent Platform session analytics. |
| AI usage events | {{< no >}} | {{< yes >}} | `AiUsageEvent` | Aggregated GitLab Duo usage event analytics. |
| Code suggestions | {{< no >}} | {{< yes >}} | `CodeSuggestion` | Aggregated GitLab Duo Code Suggestions analytics. |
| Contributions | {{< no >}} | {{< yes >}} | `Contribution` | Aggregated contribution activity analytics. |
| Duo workflows | {{< no >}} | {{< yes >}} | `DuoWorkflow` | Aggregated GitLab Duo Agent Platform flow analytics, including credits used. |

Each data source has its own set of supported fields for filtering, display, and sorting.

Specify the data source in your query by using the `type` field.
For example, `type = Issue` or `type = MergeRequest`.
For data sources that support multiple types, use the `in` operator to query across types.
For example, `type in (Issue, Task)`.

## Scopes

Each data source requires a scope to define where to query data from.
The allowed scopes vary by data source and are documented on each data source page.

Define the scope in your query. For example:

```yaml
query: type = issue and project = "gitlab-org/gitlab"
```

If you don't specify a scope, GLQL infers it from where the query is embedded:

- In a project context (such as an issue or merge request description), GLQL uses the current project.
- In a group context (such as an epic description), GLQL uses the current group.

### Multiple groups and projects

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/628101) in GitLab 19.5.

{{< /history >}}

In [analytics mode](../_index.md#analytics-mode), the `group` and `project` filters accept a list,
so a single query can aggregate data across multiple groups or projects.
Use the `in` operator with full paths:

````yaml
```glql
display: table
mode: analytics
query: type = MergeRequest and group in ("gitlab-org", "gitlab-com") and merged > -30d
dimensions: merged(weekly) as "Week"
metrics: totalCount as "Total", throughputCount as "Merged"
sort: merged desc
```
````

You can list groups, projects, or both:

- `group in ("gitlab-org", "gitlab-com")` aggregates all projects in the listed groups, including subgroups.
- `project in ("gitlab-org/gitlab", "gitlab-org/gitaly")` aggregates only the listed projects.
- `group in ("gitlab-org") and project in ("gitlab-com/www-gitlab-com")` aggregates the union of both lists.
- `group = "gitlab-org" and project in ("gitlab-org/gitlab", "gitlab-org/gitaly")` aggregates only the listed projects,
  which must belong to the group.

For example, to compare projects from different groups side by side:

````yaml
```glql
display: table
mode: analytics
query: type = Pipeline and project in ("gitlab-org/gitlab", "gitlab-org/gitaly", "gitlab-com/www-gitlab-com") and finished > -30d
dimensions: project as "Project"
metrics: totalCount as "Total", successRate as "Success rate"
sort: totalCount desc
```
````

When you use a list:

- You can list at most 20 groups and projects combined.
- You must have access to every listed group and project. If any of them is missing or
  not accessible, the query fails with an error that names the paths that cannot be read.
- A list with a single path behaves like `group = "..."` or `project = "..."`.
- When you embed the query in a project or group, GLQL uses the listed paths as the scope instead of that project or group.

Lists are not supported in standard mode. Data sources such as work items and jobs accept
a single `group` or `project` value, and a list results in a compilation error.
