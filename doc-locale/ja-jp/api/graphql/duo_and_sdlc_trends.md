---
stage: Plan
group: Optimize
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab DuoとSDLCの傾向データを取得する
---

{{< details >}}

- プラン: Premium、Ultimate
- アドオン: GitLab Duo Pro、GitLab Duo Enterprise
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GraphQL APIを使用して、GitLab Duoデータを取得およびエクスポートします。

## AIの使用状況データを取得する {#retrieve-ai-usage-data}

{{< details >}}

- アドオン: GitLab Duo Enterprise
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/474469) in GitLab 17.5で機能フラグ`code_suggestions_usage_events_in_pg`という名前のフラグとともに導入されました。デフォルトでは無効になっています。
- 機能フラグ`move_ai_tracking_to_instrumentation_layer`がGitLab 17.7で[追加](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/167415)されました。デフォルトでは無効になっています。
- `move_ai_tracking_to_instrumentation_layer`への依存関係がGitLab 17.8で[削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/179527)されました。
- 機能フラグ`code_suggestions_usage_events_in_pg`がGitLab 17.8で[削除](https://gitlab.com/gitlab-org/gitlab/-/issues/486469)されました。

{{< /history >}}

`AiUsageData`エンドポイントはrawイベントデータを取得します。これは、`codeSuggestionEvents`を介してコード提案固有のイベントと、`all`を介してすべてのrawイベントデータを公開します:

このエンドポイントを使用すると、イベントをBIツールにインポートしたり、すべてのDuoイベントのデータ、承認率、ユーザーごとのメトリクスを集計するスクリプトを作成したりできます。

ClickHouseがインストールされていないお客様の場合、データは3か月間保持されます。ClickHouseが構成されているお客様の場合、現在データ保持ポリシーはありません。

たとえば、`gitlab-org`グループのすべてのコード提案イベントの使用状況データを取得するには、次のようにします:

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

または、`gitlab-org`グループのすべてのDuoイベントの使用状況データを取得するには、次のようにします:

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

`all`属性は、`startDate`、`endDate`、`events`、`userIds`、および標準のページネーション値でフィルター可能です。

どのイベントが追跡されているかを確認するには、[`ai_tracking.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/gitlab/tracking/ai_tracking.rb)ファイルで宣言されているイベントを調べます。

## AIユーザーのメトリクスを取得する {#retrieve-ai-user-metrics}

{{< details >}}

- アドオン: GitLab Duo Enterprise
- 提供形態: GitLab.com、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 17.6で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/483049)されました。

{{< /history >}}

`AiUserMetrics`エンドポイントは、コード提案とGitLab Duoチャットのために、事前集計されたユーザーごとのメトリクスを提供します。

このエンドポイントを使用すると、すべてのDuoユーザーと、コード提案およびDuoチャットの使用頻度を一覧表示できます。

前提要件: 

- ClickHouseが構成されている必要があります。

たとえば、`gitlab-org`グループ内のすべてのユーザーについて、承認されたコード提案の数とDuoチャットとのインタラクションを取得するには、次のようにします:

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

このクエリは、次の出力を返します:

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

## GitLab DuoとSDLCの傾向メトリクスを取得する {#retrieve-gitlab-duo-and-sdlc-trend-metrics}

{{< details >}}

- アドオン: GitLab Duo Pro、GitLab Duo Enterprise
- 提供形態: GitLab.com、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 16.11で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/443696)されました。
- アドオンの要件がGitLab 17.6でGitLab Duo EnterpriseからGitLab Duo Proに[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/498497)されました。

{{< /history >}}

`AiMetrics`エンドポイントは、GitLab DuoおよびSDLCトレンドダッシュボードを強化し、コード提案およびDuoチャットについて、事前集計された次のメトリクスを提供します:

- `codeSuggestionsShown`
- `codeSuggestionsAccepted`
- `codeSuggestionAcceptanceRate`
- `codeSuggestionUsers`
- `duoChatUsers`

前提要件: 

- ClickHouseが構成されている必要があります。

たとえば、`gitlab-org`グループの指定された期間のコード提案とDuoチャットの使用状況データを取得するには、次のようにします:

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

[GitLab AIメトリクスexporterツール](https://gitlab.com/smathur/custom-duo-metrics)を使用して、AIメトリクスデータをCSVファイルにエクスポートできます。
