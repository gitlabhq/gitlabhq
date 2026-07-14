---
stage: Analytics
group: Optimize
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab Duo 및 SDLC 트렌드 데이터 검색
---

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GraphQL API를 사용하여 GitLab Duo 데이터를 검색하고 내보냅니다.

## AI 사용 현황 데이터 검색 {#retrieve-ai-usage-data}

{{< details >}}

- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 17.5에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/474469)되었으며 `code_suggestions_usage_events_in_pg` 플래그를 사용합니다. 기본적으로 비활성화됨.
- [추가](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/167415)된 `move_ai_tracking_to_instrumentation_layer` GitLab 17.7에서. 기본적으로 비활성화됨.
- `move_ai_tracking_to_instrumentation_layer`에 대한 종속성이 GitLab 17.8에서 [제거](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/179527)되었습니다.
- `code_suggestions_usage_events_in_pg` GitLab 17.8에서 [제거](https://gitlab.com/gitlab-org/gitlab/-/issues/486469)되었습니다.
- GitLab 18.7에서 `AiUsageData`에 대한 GitLab Duo Enterprise 추가 기능 요구 사항이 [제거](https://gitlab.com/gitlab-org/gitlab/-/issues/580174)되었습니다.

{{< /history >}}

`AiUsageData` 엔드포인트는 원시 이벤트 데이터를 제공합니다. `codeSuggestionEvents`를 통해 Code Suggestions 특정 이벤트를 노출하고 `all`를 통해 모든 원시 이벤트 데이터를 노출합니다.

> [!note]
> GitLab Duo Pro를 사용하는 이전 버전에서 `AiUsageData` 엔드포인트는 오류 메시지 없이 `null`을(를) 반환합니다.

이 엔드포인트를 사용하여 이벤트를 BI 도구로 가져오거나 모든 GitLab Duo 이벤트에 대한 데이터, 수용률 및 사용자별 메트릭을 집계하는 스크립트를 작성할 수 있습니다.

ClickHouse가 설치되지 않은 고객의 경우 데이터는 3개월 동안 유지됩니다. ClickHouse가 구성된 고객의 경우 현재 데이터 보존 정책이 없습니다.

`all` 및 `codeSuggestionEvents` 속성의 최대 날짜 범위는 1개월입니다. 여러 달에 걸쳐 데이터가 필요한 경우 각 월마다 별도의 쿼리를 실행합니다.

`all` 속성은 `startDate`, `endDate`, `events`, `userIds` 및 표준 페이지 매김 값으로 필터링할 수 있습니다.

추적 중인 이벤트를 확인하려면 [`ai_tracking.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/gitlab/tracking/ai_tracking.rb) 파일에 선언된 이벤트를 검토할 수 있습니다.

GitLab Duo Chat 이벤트(`request_duo_chat_response`)는 `extras` 필드를 채우지 않습니다. Code Suggestions 이벤트와 달리 Chat 상호 작용은 언어 또는 제안 메타데이터를 전달하지 않습니다. Chat 이벤트의 빈 `extras` 객체는 예상된 동작입니다.

### 프로젝트 및 그룹 {#for-projects-and-groups}

예를 들어 `gitlab-org` 그룹의 모든 Code Suggestions 이벤트에 대한 사용 현황 데이터를 검색하려면:

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

쿼리는 다음 출력을 반환합니다:

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

또는 `gitlab-org` 그룹의 모든 GitLab Duo 이벤트에 대한 사용 현황 데이터를 검색하려면:

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

쿼리는 다음 출력을 반환합니다:

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

### 인스턴스 {#for-instances}

{{< details >}}

- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 18.7에 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/582153). 이 기능은 [실험](../../policy/development_stages_support.md)입니다.

{{< /history >}}

전제 조건:

- 인스턴스의 관리자여야 합니다.

예를 들어 전체 인스턴스에 대한 모든 GitLab Duo 사용 이벤트를 검색하려면:

```graphql
query {
  aiUsageData {
    all(startDate: "2025-09-26", endDate: "2025-09-30") {
      nodes {
        event
        timestamp
        user {
          username
        }
        extras
      }
    }
  }
}
```

쿼리는 다음 출력을 반환합니다:

```json
{
  "data": {
    "aiUsageData": {
      "all": {
        "nodes": [
          {
            "event": "CODE_SUGGESTION_SHOWN_IN_IDE",
            "timestamp": "2025-09-26T18:17:25Z",
            "user": {
              "username": "jasbourne"
            },
            "extras": {}
          },
          {
            "event": "AGENT_PLATFORM_SESSION_STARTED",
            "timestamp": "2025-09-26T18:13:44Z",
            "user": {
              "username": "johndoe"
            },
            "extras": {
              "session_id": "abc123"
            }
          }
        ]
      }
    }
  }
}
```

## AI 사용자 메트릭 검색 {#retrieve-ai-user-metrics}

{{< details >}}

- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 17.6에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/483049)되었습니다.
- 기능별 메트릭 유형이 GitLab 18.7에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/483049)되었습니다

{{< /history >}}

`AiUserMetrics` 엔드포인트는 Code Suggestions, GitLab Duo Chat, 코드 검토, Agent Platform, Job Troubleshooting 및 Model Context Protocol(MCP) 도구 호출을 포함한 등록된 모든 GitLab Duo 기능에 대한 사전 집계된 사용자별 메트릭을 제공합니다.

이 엔드포인트를 사용하여 GitLab Duo 사용자 참여를 분석하고 다양한 GitLab Duo 기능 전반에 걸친 사용 빈도를 측정할 수 있습니다.

전제 조건:

- ClickHouse를 구성해야 합니다.

### 전체 이벤트 수 {#total-event-counts}

`AiUserMetrics` 엔드포인트는 다음의 이벤트 수 집계 수준을 제공합니다:

- 최상위 `totalEventCount`:  사용자의 모든 GitLab Duo 기능에 걸쳐 모든 이벤트 수의 합을 반환합니다.
- 기능 수준 `totalEventCount`:  각 기능 메트릭 유형에서 사용 가능하며 해당 특정 기능의 모든 이벤트 수의 합을 반환합니다.

이러한 필드를 사용하여 다양한 수준의 세분성으로 집계 수를 얻을 수 있습니다.

예를 들어 최상위 수준과 기능 수준 총합을 모두 검색하려면:

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

쿼리는 다음 출력을 반환합니다:

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

이 예시에서:

- 최상위 `totalEventCount`(USER_1의 경우 82)는 모든 기능에 걸쳐 모든 이벤트의 합입니다.
- 각 기능의 `totalEventCount`은 해당 기능 내의 이벤트 합입니다.
  - Code Suggestions:  60개 이벤트(허용 10개 + 표시 50개)
  - Chat:  22개 이벤트

### 기능별 메트릭 유형 {#feature-specific-metric-types}

`AiUserMetrics` 엔드포인트는 기능별 중첩 유형을 통해 자세한 메트릭을 제공합니다. 각 GitLab Duo 기능에는 해당 기능과 관련된 모든 추적 이벤트에 대한 이벤트 수 필드를 노출하는 자체 전용 메트릭 유형이 있습니다.

사용 가능한 기능 메트릭 유형은 다음을 포함합니다:

- `codeSuggestions`:  Code Suggestions 특정 메트릭
- `chat`:  GitLab Duo Chat 특정 메트릭
- `codeReview`:  코드 검토 특정 메트릭
- `agentPlatform`:  Agent Platform 특정 메트릭(에이전트 Chat 세션 포함)
- `troubleshootJob`:  작업 문제 해결 특정 메트릭
- `mcp`:  Model Context Protocol(MCP) 도구 호출 메트릭

각 기능 메트릭 유형은 다음을 포함합니다:

- 해당 기능에서 추적된 모든 이벤트에 대한 개별 이벤트 수 필드
- 해당 특정 기능의 모든 이벤트를 합산하는 `totalEventCount` 필드

사용 가능한 이벤트 수 필드는 시스템에 등록된 이벤트를 기반으로 동적으로 생성됩니다. 각 기능에 대해 추적 중인 이벤트를 확인하려면 [`ai_tracking.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/gitlab/tracking/ai_tracking.rb) 파일에 선언된 이벤트를 검토합니다.

예를 들어 여러 GitLab Duo 기능에 걸쳐 자세한 메트릭을 검색하려면:

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

쿼리는 다음 출력을 반환합니다:

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

## GitLab Duo 및 SDLC 추세 메트릭 검색 {#retrieve-gitlab-duo-and-sdlc-trend-metrics}

{{< details >}}

- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 16.11에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/443696)되었습니다.
- 추가 기능 요구 사항이 GitLab 17.6에서 GitLab Duo Enterprise에서 GitLab Duo Pro로 [변경](https://gitlab.com/gitlab-org/gitlab/-/issues/498497)되었습니다.
- GitLab 18.7에서 추가 기능 요구 사항이 [제거](https://gitlab.com/gitlab-org/gitlab/-/issues/580174)되었습니다.

{{< /history >}}

`AiMetrics` 엔드포인트는 GitLab Duo 및 SDLC 추세 대시보드를 지원하고 Code Suggestions 및 GitLab Duo Chat에 대한 다음의 사전 집계된 메트릭을 제공합니다:

- `codeSuggestionsShown`
- `codeSuggestionsAccepted`
- `codeSuggestionAcceptanceRate`
- `codeSuggestionUsers`
- `duoChatUsers`

전제 조건:

- ClickHouse를 구성해야 합니다.

예를 들어 `gitlab-org` 그룹의 지정된 기간에 대한 Code Suggestions 및 GitLab Duo Chat 사용 데이터를 검색하려면:

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
      duoUsedCount
    }
  }
}
```

쿼리는 다음 출력을 반환합니다:

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
        "duoUsedCount": 714
      }
    }
  },
}
```

## AI 메트릭 데이터를 CSV로 내보내기 {#export-ai-metrics-data-to-csv}

[GitLab AI Metrics Exporter tool](https://gitlab.com/smathur/custom-duo-metrics)을(를) 사용하여 AI 메트릭 데이터를 CSV 파일로 내보낼 수 있습니다.
