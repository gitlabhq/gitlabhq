---
stage: Analytics
group: Optimize
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab DuoとSDLCトレンドデータを取得する
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GraphQL APIを使用して、GitLab Duoデータを取得およびエクスポートします。

## AIの利用状況データを取得する {#retrieve-ai-usage-data}

{{< details >}}

- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 17.5で`code_suggestions_usage_events_in_pg`フラグとともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/474469)されました。デフォルトでは無効になっています。
- GitLab 17.7で機能フラグ`move_ai_tracking_to_instrumentation_layer`が[追加](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/167415)されました。デフォルトでは無効になっています。
- GitLab 17.8で`move_ai_tracking_to_instrumentation_layer`への依存関係が[削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/179527)されました。
- GitLab 17.8で機能フラグ`code_suggestions_usage_events_in_pg`が[削除](https://gitlab.com/gitlab-org/gitlab/-/issues/486469)されました。

{{< /history >}}

`AiUsageData`エンドポイントは、rawイベントデータを提供します。`codeSuggestionEvents`を介してコード提案に固有のイベントを公開し、`all`を介してすべてのrawイベントデータを公開します。

このエンドポイントを使用すると、イベントをBIツールにインポートしたり、すべてのGitLab Duoイベントのデータ、承認率、ユーザーごとのメトリクスを集計するスクリプトを作成したりできます。

ClickHouseがインストールされていないお客様の場合、データは3か月間保持されます。ClickHouseが構成されているお客様の場合、現在のところデータ保持ポリシーはありません。

`all`属性は、`startDate`、`endDate`、`events`、`userIds`、および標準ページネーションの値でフィルター可能です。

どのイベントが追跡されているかを確認するには、[`ai_tracking.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/gitlab/tracking/ai_tracking.rb)ファイルで宣言されているイベントを調べます。

### プロジェクトとグループの場合 {#for-projects-and-groups}

たとえば、`gitlab-org`グループのすべてのコード提案イベントの利用状況データを取得するには、次のようにします:

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

このクエリは、次の出力を返します:

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

または、`gitlab-org`グループのすべてのGitLab Duoイベントの利用状況データを取得するには、次のようにします:

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

このクエリは、次の出力を返します:

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

### インスタンスの場合 {#for-instances}

{{< details >}}

- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 18.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/582153)されました。これは[実験的機能](../../policy/development_stages_support.md)です。

{{< /history >}}

前提条件: 

- インスタンスの管理者である。

たとえば、インスタンス全体のすべてのGitLab Duo利用状況イベントを取得するには、次のようにします:

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

このクエリは、次の出力を返します:

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

## AIユーザーメトリクスを取得する {#retrieve-ai-user-metrics}

{{< details >}}

- 提供形態: GitLab.com、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 17.6で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/483049)されました。
- 機能フラグに固有のメトリクスタイプは、GitLab 18.7で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/483049)

{{< /history >}}

`AiUserMetrics`エンドポイントは、コード提案、GitLab Duo Chat、コードレビュー、エージェントプラットフォーム（GitLab Duo Agentic Chat）、ジョブトラブルシューティング、およびModel Context Protocol（Model Context Protocol）ツール呼び出しを含む、登録されているすべてのGitLab Duo機能に対して、事前集計されたユーザーごとのメトリクスを提供します。

このエンドポイントを使用すると、GitLab Duoユーザーのエンゲージメントを分析し、さまざまなGitLab Duo機能全体での使用頻度を測定できます。

前提条件: 

- ClickHouseが構成されている必要があります。

### イベントの合計数 {#total-event-counts}

`AiUserMetrics`エンドポイントは、次のレベルのイベント数集計を提供します:

- トップレベルの`totalEventCount`: ユーザーのすべてのGitLab Duo機能にわたる、すべてのイベント数の合計を返します。
- 機能レベルの`totalEventCount`: 機能のメトリクスタイプごとに使用可能で、その特定の機能のすべてのイベント数の合計を返します。

これらのフィールドを使用すると、さまざまなレベルの粒度で集計数を取得できます。

たとえば、トップレベルと機能レベルの両方の合計を取得するには、次のようにします:

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

このクエリは、次の出力を返します:

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

この例では: 

- トップレベルの`totalEventCount`（USER_1の場合は82）は、すべての機能にわたるすべてのイベントの合計です。
- 各機能の`totalEventCount`は、その機能内のイベントの合計のみを表します。
  - コード提案: 60件のイベント（承認10件+表示50）
  - チャット: 22件のイベント

### 機能フラグに固有のメトリクスタイプ {#feature-specific-metric-types}

`AiUserMetrics`エンドポイントは、機能フラグに固有のネストされたタイプを介して、詳細なメトリクスを提供します。各GitLab Duo機能には、その機能に関連するすべての追跡対象イベントのイベント数フィールドを公開する、独自の専用メトリクスタイプがあります。

使用可能な機能のメトリクスタイプは次のとおりです:

- `codeSuggestions`: コード提案固有のメトリクス
- `chat`: GitLab Duo Chat固有のメトリクス
- `codeReview`: コードレビュー固有のメトリクス
- `agentPlatform`: エージェントプラットフォーム固有のメトリクス（Agentic Chatセッションを含む）
- `troubleshootJob`: ジョブトラブルシューティング固有のメトリクス
- `mcp`: Model Context Protocol（Model Context Protocol）ツール呼び出しメトリクス

機能のメトリクスタイプごとに、以下が含まれます:

- その機能で追跡されるすべてのイベントの個々のイベント数フィールド
- その特定の機能のすべてのイベントを合計する`totalEventCount`フィールド

使用可能なイベント数フィールドは、システムに登録されているイベントに基づいて動的に生成されます。機能ごとに追跡されるイベントを確認するには、[`ai_tracking.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/gitlab/tracking/ai_tracking.rb)ファイルで宣言されているイベントを調べます。

たとえば、複数のGitLab Duo機能にわたる詳細なメトリクスを取得するには、次のようにします:

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

このクエリは、次の出力を返します:

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

## GitLab DuoおよびSDLCトレンドメトリクスを取得する {#retrieve-gitlab-duo-and-sdlc-trend-metrics}

{{< details >}}

- 提供形態: GitLab.com、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 16.11で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/443696)されました。
- アドオン要件が、GitLab 17.6でGitLab Duo EnterpriseからGitLab Duo Proに[変更されました](https://gitlab.com/gitlab-org/gitlab/-/issues/498497)。
- アドオン要件が、GitLab 18.7で[削除されました](https://gitlab.com/gitlab-org/gitlab/-/issues/580174)。

{{< /history >}}

`AiMetrics`エンドポイントは、GitLab DuoおよびSDLCトレンドダッシュボードを強化し、コード提案とGitLab Duo Chatに対して、事前集計された次のメトリクスを提供します:

- `codeSuggestionsShown`
- `codeSuggestionsAccepted`
- `codeSuggestionAcceptanceRate`
- `codeSuggestionUsers`
- `duoChatUsers`

前提条件: 

- ClickHouseが構成されている必要があります。

たとえば、`gitlab-org`グループの指定された期間のコード提案とGitLab Duo Chatの使用状況データを取得するには、次のようにします:

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

このクエリは、次の出力を返します:

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

## AIメトリクスデータをCSVにエクスポートする {#export-ai-metrics-data-to-csv}

[GitLab AI Metrics Exporter tool](https://gitlab.com/smathur/custom-duo-metrics)を使用して、AIメトリクスデータをCSVファイルにエクスポートできます。
