---
stage: Plan
group: Optimize
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: REST APIを使用して、プロジェクトおよびグループのDORAメトリクスを取得します。
title: DevOps Research and Assessment (DORA) metrics API
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、グループおよびプロジェクトの[DORAメトリクス](../../user/analytics/dora_metrics.md)の詳細を取得します。

[GraphQL API](../graphql/reference/_index.md)で追加のエンドポイントを利用できます。

前提要件: 

- レポーターロール以上が必要です。

## プロジェクトレベルのDORAメトリクスを取得します {#get-project-level-dora-metrics}

プロジェクトレベルのDORAメトリクスを取得します。

```plaintext
GET /projects/:id/dora/metrics
```

| 属性            | 型             | 必須 | 説明 |
|:---------------------|:-----------------|:---------|:------------|
| `id`                 | 整数または文字列   | はい      | 認証済みユーザーがアクセスできるプロジェクトのID、または[URLエンコードされたパス](../rest/_index.md#namespaced-paths)。 |
| `metric`             | 文字列           | はい      | `deployment_frequency`、`lead_time_for_changes`、`time_to_restore_service`、`change_failure_rate`のいずれかです。 |
| `end_date`           | 文字列           | いいえ       | 日付範囲の終了日。ISO 8601形式の日付。例: `2021-03-01`。デフォルトは現在の日付です。 |
| `environment_tiers`  | 文字列の配列 | いいえ       | [環境の階層](../../ci/environments/_index.md#deployment-tier-of-environments)。デフォルトは`production`です。 |
| `interval`           | 文字列           | いいえ       | バケット間隔。`all`、`monthly`、`daily`のいずれか。デフォルトは`daily`です。 |
| `start_date`         | 文字列           | いいえ       | 日付範囲の開始日。ISO 8601形式の日付。例: `2021-03-01`。デフォルトは3か月前です。 |

リクエスト例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/dora/metrics?metric=deployment_frequency"
```

レスポンス例:

```json
[
  { "date": "2021-03-01", "value": 3 },
  { "date": "2021-03-02", "value": 6 },
  { "date": "2021-03-03", "value": 0 },
  { "date": "2021-03-04", "value": 0 },
  { "date": "2021-03-05", "value": 0 },
  { "date": "2021-03-06", "value": 0 },
  { "date": "2021-03-07", "value": 0 },
  { "date": "2021-03-08", "value": 4 }
]
```

## グループレベルのDORAメトリクスを取得します {#get-group-level-dora-metrics}

グループレベルのDORAメトリクスを取得します。

```plaintext
GET /groups/:id/dora/metrics
```

| 属性           | 型             | 必須 | 説明 |
|:--------------------|:-----------------|:---------|:------------|
| `id`                | 整数または文字列   | はい      | 認証済みユーザーがアクセスできるプロジェクトのID、または[URLエンコードされたパス](../rest/_index.md#namespaced-paths)。 |
| `metric`            | 文字列           | はい      | `deployment_frequency`、`lead_time_for_changes`、`time_to_restore_service`、`change_failure_rate`のいずれかです。 |
| `end_date`          | 文字列           | いいえ       | 日付範囲の終了日。ISO 8601形式の日付。例: `2021-03-01`。デフォルトは現在の日付です。 |
| `environment_tiers` | 文字列の配列 | いいえ       | [環境の階層](../../ci/environments/_index.md#deployment-tier-of-environments)。デフォルトは`production`です。 |
| `interval`          | 文字列           | いいえ       | バケット間隔。`all`、`monthly`、`daily`のいずれか。デフォルトは`daily`です。 |
| `start_date`        | 文字列           | いいえ       | 日付範囲の開始日。ISO 8601形式の日付。例: `2021-03-01`。デフォルトは3か月前です。 |

リクエスト例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/1/dora/metrics?metric=deployment_frequency"
```

レスポンス例:

```json
[
  { "date": "2021-03-01", "value": 3 },
  { "date": "2021-03-02", "value": 6 },
  { "date": "2021-03-03", "value": 0 },
  { "date": "2021-03-04", "value": 0 },
  { "date": "2021-03-05", "value": 0 },
  { "date": "2021-03-06", "value": 0 },
  { "date": "2021-03-07", "value": 0 },
  { "date": "2021-03-08", "value": 4 }
]
```

## `value`フィールド {#the-value-field}

前述のプロジェクトレベルとグループレベルのエンドポイントの両方について、API応答の`value`フィールドには、指定された`metric`クエリパラメータに応じて異なる意味があります:

| `metric`クエリパラメータ   | 応答の`value`の説明 |
|:---------------------------|:-----------------------------------|
| `deployment_frequency`     | APIは、期間中のデプロイの合計数を返します。[Issue 371271](https://gitlab.com/gitlab-org/gitlab/-/issues/371271)では、合計数ではなく、1日の平均を返すようにAPIを更新することを提案しています。 |
| `change_failure_rate`      | 期間中のデプロイ数で割ったインシデント数。本番環境でのみ使用できます。 |
| `lead_time_for_changes`    | 期間中にデプロイされたすべてのマージリクエストの、マージリクエストのマージとマージリクエストコミットのデプロイの間の秒数の中央値。 |
| `time_to_restore_service`  | 期間中にインシデントが開いていた秒数の中央値。本番環境でのみ使用できます。 |

{{< alert type="note" >}}

APIは、1日のメジアン値のメジアンを計算して、`monthly`および`all`の間隔を返します。これにより、返されるデータにわずかな不正確さが生じる可能性があります。

{{< /alert >}}
