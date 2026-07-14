---
stage: Analytics
group: Optimize
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Retrieve Value Stream Analytics data
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- Loading stage metrics through GraphQL [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/410327) in GitLab 17.0.

{{< /history >}}

Use the GraphQL API to request metrics from your configured value streams and value stream stages.
This data can be useful if you want to export Value Stream Analytics data to an external system or for a report.

The following metrics are available:

- Number of completed items in the stage. The count is limited to a maximum of 10,000 items.
- Median duration for the completed items in the stage.
- Average duration for the completed items in the stage.

## Retrieve configured value streams

Prerequisites:

- You must have the Reporter, Developer, Maintainer, or Owner role.

First, you must determine which value stream you want to use in the reporting.

To request the configured value streams for a group, run:

```graphql
group(fullPath: "your-group-path") {
  valueStreams {
    nodes {
      id
      name
    }
  }
}
```

Similarly, to request metrics for a project, run:

```graphql
project(fullPath: "your-project-path") {
  valueStreams {
    nodes {
      id
      name
    }
  }
}
```

## Retrieve metrics for a stage

To request metrics for stages of a value stream, run:

```graphql
group(fullPath: "your-group-path") {
  valueStreams(id: "your-value-stream-id") {
    nodes {
      stages {
        id
        name
      }
    }
  }
}
```

Depending on how you want to consume the data, you can request metrics for one specific stage or all stages in your value stream.

> [!note]
> Requesting metrics for all stages might be too slow for some installations.
> The recommended approach is to request metrics stage by stage.

Requesting metrics for the stage:

```graphql
group(fullPath: "your-group-path") {
  valueStreams(id: "your-value-stream-id") {
    nodes {
      stages(id: "your-stage-id") {
        id
        name
        metrics(timeframe: { start: "2024-03-01", end: "2024-03-31" }) {
          average {
            value
            unit
          }
          median {
            value
            unit
          }
          count {
            value
            unit
          }
        }
      }
    }
  }
}
```

> [!note]
> You should always request metrics with a given time frame.
> The longest supported time frame is 180 days.

The `metrics` node supports additional filtering options:

- Assignee usernames
- Author username
- Label names
- Milestone title

Example request with filters:

```graphql
group(fullPath: "your-group-path") {
  valueStreams(id: "your-value-stream-id") {
    nodes {
      stages(id: "your-stage-id") {
        id
        name
        metrics(
          labelNames: ["backend"],
          milestoneTitle: "17.0",
          timeframe: { start: "2024-03-01", end: "2024-03-31" }
        ) {
          average {
            value
            unit
          }
          median {
            value
            unit
          }
          count {
            value
            unit
          }
        }
      }
    }
  }
}
```

## Best practices

- To get an accurate view of the current status, request metrics as close to the end of the time frame as possible.
- For periodic reporting, you can create a script and use the [scheduled pipelines](../../ci/pipelines/schedules.md) feature to export the data in a timely manner.
- When invoking the API, you get the current data from the database. Over time, the same metrics might change due to changes in the underlying data in the database. For example, moving or removing a project from the group might affect group-level metrics.
- Re-requesting the metrics for previous periods and comparing them to the previously collected metrics can show skews in the data, which can help in discovering and explaining changing trends.
