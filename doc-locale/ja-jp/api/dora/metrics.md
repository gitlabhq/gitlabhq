---
stage: Analytics
group: Optimize
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: プロジェクトおよびグループのDORAメトリクスをREST APIで取得する。
title: DevOps Research and Assessment（DORA）メトリクスAPI
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、グループおよびプロジェクトの[DORAメトリクス](../../user/analytics/dora_metrics.md)の詳細を取得する。

追加のエンドポイントは、[GraphQL API](../graphql/reference/_index.md)で利用できます。

前提条件: 

- レポーター、デベロッパー、メンテナー、またはオーナーロールが必要です。

## プロジェクトレベルのDORAメトリクスを取得する {#retrieve-project-level-dora-metrics}

指定したプロジェクトのDORAメトリクスを取得する。

```plaintext
GET /projects/:id/dora/metrics
```

| 属性            | 型             | 必須 | 説明 |
|:---------------------|:-----------------|:---------|:------------|
| `id`                 | 整数または文字列   | はい      | IDまたはプロジェクトのURLエンコードされた[パス](../rest/_index.md#namespaced-paths)は、認証済みユーザーによってアクセスできます。 |
| `metric`             | 文字列           | はい      | `deployment_frequency`、`lead_time_for_changes`、`time_to_restore_service`、`change_failure_rate`のいずれかです。 |
| `end_date`           | 文字列           | いいえ       | 日付範囲の終了日。ISO 8601日付形式。例: `2021-03-01`。デフォルトは現在の日付です。 |
| `environment_tiers`  | 文字列の配列 | いいえ       | 環境の[階層](../../ci/environments/_index.md#deployment-tier-of-environments)。デフォルトは`production`です。 |
| `interval`           | 文字列           | いいえ       | バケット化の間隔。`all`、`monthly`、または`daily`のいずれか。デフォルトは`daily`です。 |
| `start_date`         | 文字列           | いいえ       | 日付範囲の開始日。ISO 8601日付形式。例: `2021-03-01`。デフォルトは3か月前です。 |

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

## グループレベルのDORAメトリクスを取得する {#retrieve-group-level-dora-metrics}

指定したグループのDORAメトリクスを取得する。

```plaintext
GET /groups/:id/dora/metrics
```

| 属性           | 型             | 必須 | 説明 |
|:--------------------|:-----------------|:---------|:------------|
| `id`                | 整数または文字列   | はい      | IDまたはプロジェクトのURLエンコードされた[パス](../rest/_index.md#namespaced-paths)は、認証済みユーザーによってアクセスできます。 |
| `metric`            | 文字列           | はい      | `deployment_frequency`、`lead_time_for_changes`、`time_to_restore_service`、`change_failure_rate`のいずれかです。 |
| `end_date`          | 文字列           | いいえ       | 日付範囲の終了日。ISO 8601日付形式。例: `2021-03-01`。デフォルトは現在の日付です。 |
| `environment_tiers` | 文字列の配列 | いいえ       | 環境の[階層](../../ci/environments/_index.md#deployment-tier-of-environments)。デフォルトは`production`です。 |
| `interval`          | 文字列           | いいえ       | バケット化の間隔。`all`、`monthly`、または`daily`のいずれか。デフォルトは`daily`です。 |
| `start_date`        | 文字列           | いいえ       | 日付範囲の開始日。ISO 8601日付形式。例: `2021-03-01`。デフォルトは3か月前です。 |

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

以前に説明したプロジェクトとグループレベルのエンドポイントの両方で、API応答の`value`フィールドは、指定された`metric`クエリパラメータによって異なる意味を持ちます:

| `metric`クエリパラメータ   | 応答における`value`の説明 |
|:---------------------------|:-----------------------------------|
| `deployment_frequency`     | APIは、期間中の成功したデプロイの総数を返します。[イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/371271) 371271は、合計数ではなく日次平均を返すようにAPIを更新することを提案しています。 |
| `change_failure_rate`      | 期間中のインシデント数÷デプロイ数。本番環境でのみ利用可能です。 |
| `lead_time_for_changes`    | 期間中にデプロイされたすべてのMRについて、マージリクエスト（MR）のマージとMRのコミットのデプロイとの間の秒数の中央値。 |
| `time_to_restore_service`  | 期間中にインシデントが開いていた秒数の中央値。本番環境でのみ利用可能です。 |

> [!note]
> APIは、日次中央値の中央値を計算することにより、`monthly`および`all`の間隔を返します。これにより、返されるデータにわずかな不正確さが生じる可能性があります。
