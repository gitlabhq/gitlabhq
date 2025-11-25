---
stage: Plan
group: Optimize
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Retrieve GitLab Duo and SDLC trend data
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Use the GraphQL API to retrieve and export GitLab Duo data.

## Retrieve AI usage data

{{< details >}}

- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/474469) in GitLab 17.5 with a flag named `code_suggestions_usage_events_in_pg`. Disabled by default.
- Feature flag `move_ai_tracking_to_instrumentation_layer` [added](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/167415) in GitLab 17.7. Disabled by default.
- Dependency on `move_ai_tracking_to_instrumentation_layer` [removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/179527) in GitLab 17.8.
- Feature flag `code_suggestions_usage_events_in_pg` [removed](https://gitlab.com/gitlab-org/gitlab/-/issues/486469) in GitLab 17.8.

{{< /history >}}

The `AiUsageData` endpoint provides raw event data. It exposes Code Suggestions-specific events through `codeSuggestionEvents` and all raw event data through `all`:

You can use this endpoint to import events into a BI tool or write scripts that aggregate the data, acceptance rates, and per-user metrics for all Duo events.

Data is retained for three months for customers without ClickHouse installed. For customers with ClickHouse configured, there is currently no data retention policy.

For example, to retrieve usage data for all Code Suggestions events for the `gitlab-org` group:

```graphql
query {
  group(fullPath: "gitlab-org") {
    aiUsageData {
      codeSuggestionEvents(startDate: "2025-09-26") {
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
              "timestamp": "2025-09-26T18:17:25Z",
              "language": "python",
              "suggestionSize": 2,
              "user": {
                "username": "jasbourne"
              }
            },
            {
              "event": "CODE_SUGGESTION_REJECTED_IN_IDE",
              "timestamp": "2025-09-26T18:13:45Z",
              "language": "python",
              "suggestionSize": 2,
              "user": {
                "username": "jasbourne"
              }
            },
            {
              "event": "CODE_SUGGESTION_ACCEPTED_IN_IDE",
              "timestamp": "2025-09-26T18:13:44Z",
              "language": "python",
              "suggestionSize": 2,
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

Alternatively, to retrieve usage data for all Duo events for the `gitlab-org` group:

```graphql
query {
  group(fullPath: "gitlab-org") {
    aiUsageData {
      all(startDate: "2025-09-26") {
        nodes {
          event
          timestamp
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
        "all": {
          "nodes": [
            {
              "event": "FIND_NO_ISSUES_DUO_CODE_REVIEW_AFTER_REVIEW",
              "timestamp": "2025-09-26T18:17:25Z",
              "user": {
                "username": "jasbourne"
              }
            },
            {
              "event": "REQUEST_REVIEW_DUO_CODE_REVIEW_ON_MR_BY_AUTHOR",
              "timestamp": "2025-09-26T18:13:45Z",
              "user": {
                "username": "jasbourne"
              }
            },
            {
              "event": "AGENT_PLATFORM_SESSION_STARTED",
              "timestamp": "2025-09-26T18:13:44Z",
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

The `all` attribute is filterable by `startDate`, `endDate`, `events`, `userIds`, and standard pagination values.

To see which events are being tracked, you can examine the events declared in the [`ai_tracking.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/gitlab/tracking/ai_tracking.rb) file.

## Retrieve AI user metrics

{{< details >}}

- Offering: GitLab.com, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/483049) in GitLab 17.6.
- Feature-specific metric types [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/483049) in GitLab 18.7

{{< /history >}}

The `AiUserMetrics` endpoint provides pre-aggregated per-user metrics for all registered GitLab Duo features, including Code Suggestions, Duo Chat, Code Review, Agent Platform (Agentic Chat), Job Troubleshooting, and Model Context Protocol (MCP) tool calls.

You can use this endpoint to analyze GitLab Duo user engagement and measure usage frequency across different GitLab Duo features.

Prerequisites:

- You must have ClickHouse configured.

### Total event counts

The `AiUserMetrics` endpoint provides the following levels of event count aggregation:

- Top-level `totalEventCount`: Returns the sum of all event counts across all GitLab Duo features for a user.
- Feature-level `totalEventCount`: Available in each feature metric type, returns the sum of all event counts for that specific feature.

You can use these fields to get aggregate counts at different levels of granularity.

For example, to retrieve both top-level and feature-level totals:

```graphql
query {
  group(fullPath:"gitlab-org") {
    aiUserMetrics {
      nodes {
        user {
          username
        }
        totalEventCount
        codeSuggestions {
          totalEventCount
          codeSuggestionAcceptedInIdeEventCount
          codeSuggestionShownInIdeEventCount
        }
        chat {
          totalEventCount
          requestDuoChatResponseEventCount
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
            "user": {
              "username": "USER_1"
            },
            "totalEventCount": 82,
            "codeSuggestions": {
              "totalEventCount": 60,
              "codeSuggestionAcceptedInIdeEventCount": 10,
              "codeSuggestionShownInIdeEventCount": 50
            },
            "chat": {
              "totalEventCount": 22,
              "requestDuoChatResponseEventCount": 22
            }
          },
          {
            "user": {
              "username": "USER_2"
            },
            "totalEventCount": 102,
            "codeSuggestions": {
              "totalEventCount": 72,
              "codeSuggestionAcceptedInIdeEventCount": 12,
              "codeSuggestionShownInIdeEventCount": 60
            },
            "chat": {
              "totalEventCount": 30,
              "requestDuoChatResponseEventCount": 30
            }
          }
        ]
      }
    }
  }
}
```

In this example:

- The top-level `totalEventCount` (82 for USER_1) is the sum of all events across all features.
- Each feature's `totalEventCount` represents the sum of events within that feature only.
  - Code Suggestions: 60 events (10 accepted + 50 shown)
  - Chat: 22 events

### Feature-specific metric types

The `AiUserMetrics` endpoint provides detailed metrics through feature-specific nested types. Each GitLab Duo feature has its own dedicated metric type that exposes event count fields for all tracked events related to that feature.

Available feature metric types include:

- `codeSuggestions`: Code Suggestions-specific metrics
- `chat`: GitLab Duo Chat-specific metrics
- `codeReview`: Code Review-specific metrics
- `agentPlatform`: Agent Platform-specific metrics (includes Agentic Chat sessions)
- `troubleshootJob`: Job troubleshooting-specific metrics
- `mcp`: Model Context Protocol (MCP) tool call metrics

Each feature metric type includes:

- Individual event count fields for all tracked events in that feature
- A `totalEventCount` field that sums all events for that specific feature

The available event count fields are dynamically generated based on the events registered in the system. To see which events are tracked for each feature, examine the events declared in the [`ai_tracking.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/gitlab/tracking/ai_tracking.rb) file.

For example, to retrieve detailed metrics across multiple GitLab Duo features:

```graphql
query {
  group(fullPath:"gitlab-org") {
    aiUserMetrics {
      nodes {
        user {
          username
        }
        codeSuggestions {
          totalEventCount
          codeSuggestionAcceptedInIdeEventCount
          codeSuggestionShownInIdeEventCount
        }
        chat {
          totalEventCount
          requestDuoChatResponseEventCount
        }
        codeReview {
          totalEventCount
          requestReviewDuoCodeReviewOnMrByAuthorEventCount
          findNoIssuesDuoCodeReviewAfterReviewEventCount
        }
        agentPlatform {
          totalEventCount
          agentPlatformSessionStartedEventCount
          agentPlatformSessionFinishedEventCount
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
            "user": {
              "username": "USER_1"
            },
            "codeSuggestions": {
              "totalEventCount": 60,
              "codeSuggestionAcceptedInIdeEventCount": 10,
              "codeSuggestionShownInIdeEventCount": 50
            },
            "chat": {
              "totalEventCount": 22,
              "requestDuoChatResponseEventCount": 22
            },
            "codeReview": {
              "totalEventCount": 8,
              "requestReviewDuoCodeReviewOnMrByAuthorEventCount": 5,
              "findNoIssuesDuoCodeReviewAfterReviewEventCount": 3
            },
            "agentPlatform": {
              "totalEventCount": 15,
              "agentPlatformSessionStartedEventCount": 8,
              "agentPlatformSessionFinishedEventCount": 7
            }
          },
          {
            "user": {
              "username": "USER_2"
            },
            "codeSuggestions": {
              "totalEventCount": 72,
              "codeSuggestionAcceptedInIdeEventCount": 12,
              "codeSuggestionShownInIdeEventCount": 60
            },
            "chat": {
              "totalEventCount": 30,
              "requestDuoChatResponseEventCount": 30
            },
            "codeReview": {
              "totalEventCount": 5,
              "requestReviewDuoCodeReviewOnMrByAuthorEventCount": 3,
              "findNoIssuesDuoCodeReviewAfterReviewEventCount": 2
            },
            "agentPlatform": {
              "totalEventCount": 20,
              "agentPlatformSessionStartedEventCount": 12,
              "agentPlatformSessionFinishedEventCount": 8
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

- Offering: GitLab.com, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/443696) in GitLab 16.11.
- Add-on requirement [changed](https://gitlab.com/gitlab-org/gitlab/-/issues/498497) from GitLab Duo Enterprise to GitLab Duo Pro in GitLab 17.6.
- Add-on requirement [removed](https://gitlab.com/gitlab-org/gitlab/-/issues/580174) in GitLab 18.7.

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
