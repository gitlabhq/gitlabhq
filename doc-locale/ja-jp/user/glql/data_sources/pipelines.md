---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: パイプライン
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 18.11で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/228521)されました。

{{< /history >}}

> [!note]
> パイプラインはソートをサポートしていません。

## クエリフィールド {#query-fields}

以下のフィールドは必須です: [プロジェクト](#pipeline-project)

| フィールド                                          | 名前（およびエイリアス）                             | 演算子                  |
| ---------------------------------------------- | -------------------------------------------- | -------------------------- |
| [Author](#pipeline-author)                     | `author`                                     | `=`                        |
| [プロジェクト](#pipeline-project)                   | `project`                                    | `=`                        |
| [Ref](#pipeline-ref)                           | `ref`                                        | `=`                        |
| [スコープ](#pipeline-scope)                       | `scope`                                      | `=`                        |
| [SHA](#pipeline-sha)                           | `sha`                                        | `=`                        |
| [ソース](#pipeline-source)                     | `source`                                     | `=`                        |
| [ステータス](#pipeline-status)                     | `status`                                     | `=`                        |
| [Updated at](#pipeline-updated-at)             | `updated`、`updatedAt`                       | `=`、`>`、`<`、`>=`、`<=`  |

### 作成者 {#pipeline-author}

**説明**: トリガーしたユーザーによってパイプラインをフィルタリングします。

**指定可能な値の型**:

- `String`
- `User` （例: `@username`）

### プロジェクト {#pipeline-project}

**説明**: パイプラインをクエリするプロジェクトを指定します。このフィールドは**required**です。

**指定可能な値の型**: `String`

### Ref {#pipeline-ref}

**説明**: Git ref（ブランチまたはタグ名）でパイプラインをフィルタリングします。

**指定可能な値の型**: `String`

### スコープ {#pipeline-scope}

**説明**: スコープでパイプラインをフィルタリングします。

**指定可能な値の型**:

- `Enum`（`branches`、`tags`、`finished`、`pending`、または`running`のいずれか）

### SHA {#pipeline-sha}

**説明**: コミットSHAでパイプラインをフィルタリングします。

**指定可能な値の型**: `String`

### ソース {#pipeline-source}

**説明**: トリガーしたものによってパイプラインをフィルタリングします。

**指定可能な値の型**: `String`

### ステータス {#pipeline-status}

**説明**: CI/CDステータスでパイプラインをフィルタリングします。

**指定可能な値の型**:

- `Enum`、`canceled`、`canceling`、`created`、`failed`、`manual`、`pending`、`preparing`、`running`、`scheduled`、`skipped`、`success`、`waiting_for_callback`、または`waiting_for_resource`のいずれか

### Updated at {#pipeline-updated-at}

**説明**: パイプラインが最後に更新された日時でフィルタリングします。

**指定可能な値の型**:

- `AbsoluteDate` （`YYYY-MM-DD`形式で）
- `RelativeDate` （`<sign><digit><unit>`形式。`+`、`-`、または省略された記号、整数である桁、および`unit`が`d` (日)、 `w` (週)、 `m` (月)、または`y` (年) のいずれかである）

**ノート**:

- `=`演算子の場合、時刻範囲はユーザーのタイムゾーンで00:00から23:59までと見なされます。
- `>=`および`<=`演算子は、クエリされる日付を含みますが、`>`および`<`は含みません。

## 表示フィールド {#display-fields}

| フィールド              | 名前（およびエイリアス）                   | 説明 |
| ------------------ | ---------------------------------- | ----------- |
| アクティブ             | `active`                           | パイプラインがアクティブであるかどうかを表示します |
| キャンセル可能         | `cancelable`                       | パイプラインをキャンセルできるかどうかを表示します |
| 子              | `child`                            | これが子パイプラインであるかどうかを表示します |
| コミット日時       | `committed`、`committedAt`         | コミットタイムスタンプを表示します |
| 完了           | `complete`                         | パイプラインが完了しているかどうかを表示します |
| コンピューティング時間    | `computeMinutes`                   | 使用されたコンピューティング時間を表示します |
| 設定ソース      | `configSource`                     | パイプラインの設定ソースを表示します |
| カバレッジ           | `coverage`                         | コードカバレッジ率を表示 |
| 作成日時         | `created`、`createdAt`             | パイプラインが作成された日時を表示します |
| 期間           | `duration`                         | パイプラインの期間を表示します |
| 失敗したジョブ数  | `failedJobsCount`                  | 失敗したジョブの数を表示します |
| 失敗理由     | `failureReason`                    | パイプラインの失敗の理由を表示します |
| 完了日時        | `finished`、`finishedAt`           | パイプラインが終了した日時を表示します |
| ID                 | `id`                               | パイプラインIDを表示します |
| IID                | `iid`                              | パイプラインの内部IDを表示します |
| 最新             | `latest`                           | これがRefの最新のパイプラインであるかどうかを表示します |
| 名前               | `name`                             | パイプライン名を表示します |
| パス               | `path`                             | パイプラインのパスを表示します |
| Ref                | `ref`                              | Git ref（ブランチまたはタグ）を表示します |
| リトライ可能          | `retryable`                        | パイプラインを再試行できるかどうかを表示します |
| SHA                | `sha`                              | コミットSHAを表示します |
| ソース             | `source`                           | パイプラインをトリガーしたものを表示します |
| 開始日時         | `started`、`startedAt`             | パイプラインが開始された日時を表示します |
| ステータス             | `status`                           | パイプラインのステータスを表示します |
| スタック              | `stuck`                            | パイプラインがスタックしているかどうかを表示します |
| 合計ジョブ数         | `totalJobs`                        | ジョブの合計数を表示します |
| Updated at         | `updated`、`updatedAt`             | パイプラインが最後に更新された日時を表示します |
| 警告           | `warnings`                         | パイプラインの警告を表示します |
| YAMLエラー        | `yamlErrors`                       | パイプラインにYAMLエラーがあるかどうかを表示します |
| YAMLエラーメッセージ| `yamlErrorMessages`                | YAMLエラーメッセージを表示します |
