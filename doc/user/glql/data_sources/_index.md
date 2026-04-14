---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GLQL data sources
---

GLQL can query the following data sources:

| Data source | `type` values | Description |
|---|---|---|
| [Work items](work_items.md) | `Issue`, `Incident`, `TestCase`, `Requirement`, `Task`, `Ticket`, `Objective`, `KeyResult`, `Epic` | Issues, epics, and other work item types. Default when `type` is omitted. |
| [Merge requests](merge_requests.md) | `MergeRequest` | Code review and merge workflow. |
| [Pipelines](pipelines.md) | `Pipeline` | CI/CD pipelines. |
| [Jobs](jobs.md) | `Job` | CI/CD jobs within pipelines. |
| [Projects](projects.md) | `Project` | Projects within a namespace. |

Each data source has its own set of supported fields for filtering, display, and sorting.

Specify the data source in your query by using the `type` field.
For example, `type = Issue` or `type = MergeRequest`.
For data sources that support multiple types, use the `in` operator to query across types.
For example, `type in (Issue, Task)`.
