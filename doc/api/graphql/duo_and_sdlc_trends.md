---
stage: Plan
group: Optimize
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Retrieve GitLab Duo and SDLC trend data
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Add-on: GitLab Duo Pro, GitLab Duo Enterprise
- Offering: GitLab Self-Managed

{{< /details >}}

Use the GraphQL API to retrieve and export GitLab Duo and SDLC trend data.

## Retrieve AI usage data

{{< details >}}

- Add-on: GitLab Duo Enterprise

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/474469) in GitLab 17.5 with a flag named `code_suggestions_usage_events_in_pg`. Disabled by default.
- Feature flag `move_ai_tracking_to_instrumentation_layer` [added](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/167415) in GitLab 17.7. Disabled by default.
- Dependency on `move_ai_tracking_to_instrumentation_layer` [removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/179527) in GitLab 17.8.
- Feature flag `code_suggestions_usage_events_in_pg` [removed](https://gitlab.com/gitlab-org/gitlab/-/issues/486469) in GitLab 17.8.

{{< /history >}}

The `AiUsageData` endpoint provides raw event data for Code Suggestions:

- Size
- Language
- User
- Type (shown, accepted, or rejected)

You can use this endpoint to import events into a BI tool or write scripts that aggregate the data, acceptance rates, and per-user metrics for Code Suggestions events.

Data is retained for three months.

For example, to retrieve usage data for all Code Suggestions events for the `gitlab-org` group:

```graphql
query {
  group(fullPath: "gitlab-org") {
    aiUsageData {
      codeSuggestionEvents {
        nodes {
          event
          timestamp
          language
          suggestionSize
          user {
            username
          }
        }
      }
    }
  }
}
```

The query returns the following output:

```graphql
{
  "data": {
    "group": {
      "aiUsageData": {
        "codeSuggestionEvents": {
          "nodes": [
            {
              "event": "CODE_SUGGESTION_SHOWN_IN_IDE",
              "timestamp": "2024-12-22T18:17:25Z",
              "language": null,
              "suggestionSize": null,
              "user": {
                "username": "jasbourne"
              }
            },
            {
              "event": "CODE_SUGGESTION_REJECTED_IN_IDE",
              "timestamp": "2024-12-22T18:13:45Z",
              "language": null,
              "suggestionSize": null,
              "user": {
                "username": "jasbourne"
              }
            },
            {
              "event": "CODE_SUGGESTION_ACCEPTED_IN_IDE",
              "timestamp": "2024-12-22T18:13:44Z",
              "language": null,
              "suggestionSize": null,
              "user": {
                "username": "jasbourne"
              }
            }
          ]
        }
      }
    }
  }
}
```

## Retrieve AI user metrics

{{< details >}}

- Add-on: GitLab Duo Enterprise

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/483049) in GitLab 17.6.

{{< /history >}}

The `AiUserMetrics` endpoint provides pre-aggregated per-user metrics for Code Suggestions and GitLab Duo Chat.

You can use this endpoint to list all Duo users and their usage frequency for Code Suggestions and Duo Chat.

Prerequisites:

- You must have ClickHouse configured.

For example, to retrieve the number of accepted Code Suggestions and interactions with Duo Chat for all users
in the `gitlab-org` group:

```graphql
query {
  group(fullPath:"gitlab-org") {
    aiUserMetrics {
      nodes {
        codeSuggestionsAcceptedCount
        duoChatInteractionsCount
        user {
          username
        }
      }
    }
  }
}
```

The query returns the following output:

```graphql
{
  "data": {
    "group": {
      "aiUserMetrics": {
        "nodes": [
          {
            "codeSuggestionsAcceptedCount": 10,
            "duoChatInteractionsCount": 22,
            "user": {
              "username": "USER_1"
            }
          },
          {
            "codeSuggestionsAcceptedCount": 12,
            "duoChatInteractionsCount": 30,
            "user": {
              "username": "USER_2"
            }
          }
        ]
      }
    }
  }
}
```

## Retrieve GitLab Duo and SDLC trend metrics

{{< details >}}

- Add-on: GitLab Duo Pro

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/443696) in GitLab 16.11.
- Add-on requirement [changed](https://gitlab.com/gitlab-org/gitlab/-/issues/498497) from GitLab Duo Enterprise to GitLab Duo Pro in GitLab 17.6.

{{< /history >}}

The `AiMetrics` endpoint powers the GitLab Duo and SDLC trends dashboard and provides the following pre-aggregated metrics for Code Suggestions and Duo Chat:

- `codeSuggestionsShown`
- `codeSuggestionsAccepted`
- `codeSuggestionAcceptanceRate`
- `codeSuggestionUsers`
- `duoChatUsers`

Prerequisites:

- You must have ClickHouse configured.

For example, to retrieve Code Suggestions and Duo Chat usage data for a specified time period for the `gitlab-org` group:

```graphql
query {
  group(fullPath: "gitlab-org") {
    aiMetrics(startDate: "2024-12-01", endDate: "2024-12-31") {
      codeSuggestions{
        shownCount
        acceptedCount
        acceptedLinesOfCode
        shownLinesOfCode
      }
      codeContributorsCount
      duoChatContributorsCount
      duoAssignedUsersCount
      duoUsedCount
    }
  }
}
```

The query returns the following output:

```graphql
{
  "data": {
    "group": {
      "aiMetrics": {
        "codeSuggestions": {
          "shownCount": 88728,
          "acceptedCount": 7016,
          "acceptedLinesOfCode": 9334,
          "shownLinesOfCode": 124118
        },
        "codeContributorsCount": 719,
        "duoChatContributorsCount": 681,
        "duoAssignedUsersCount": 1910,
        "duoUsedCount": 714
      }
    }
  },
}
```

## Export AI metrics data to CSV

You can export AI metrics data to a CSV file with the
[GitLab AI Metrics Exporter tool](https://gitlab.com/smathur/custom-duo-metrics).
