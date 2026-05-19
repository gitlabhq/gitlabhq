---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: ジョブ
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 18.11で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/228521)されました。

{{< /history >}}

> [!note]
> ジョブはソートに対応していません。

## クエリフィールド {#query-fields}

以下のフィールドは必須です: [プロジェクト](#job-project)

| フィールド                                          | 名前                | 演算子  |
| ---------------------------------------------- | ------------------- | ---------- |
| [種類](#job-kind)                              | `kind`              | `=`        |
| [パイプライン](#job-pipeline)                      | `pipeline`          | `=`        |
| [プロジェクト](#job-project)                        | `project`           | `=`        |
| [ステータス](#job-status)                          | `status`            | `=`        |
| [アーティファクトあり](#job-with-artifacts)          | `withArtifacts`     | `=`、`!=`  |

### 種類 {#job-kind}

**説明**: ジョブを種類でフィルタリングします。

**指定可能な値の型**:

- `Enum`、`bridge`または`build`のいずれか

**ノート**:

- `bridge`ジョブは、ダウンストリームのパイプラインを開始するトリガージョブです。
- `build`ジョブは通常のCI/CDジョブです。

### パイプライン {#job-pipeline}

**説明**: 所属するパイプラインのIIDを使用して、ジョブをフィルタリングします。

**指定可能な値の型**: `Number` (pipeline IID)

### プロジェクト {#job-project}

**説明**: ジョブをクエリするプロジェクトを指定します。このフィールドは**必須**です。

**指定可能な値の型**: `String`

### ステータス {#job-status}

**説明**: ジョブをCI/CDステータスでフィルタリングします。

**指定可能な値の型**:

- `Enum`、`canceled`、`canceling`、`created`、`failed`、`manual`、`pending`、`preparing`、`running`、`scheduled`、`skipped`、`success`、`waiting_for_callback`、または`waiting_for_resource`のいずれか

### アーティファクトあり {#job-with-artifacts}

**説明**: ジョブにアーティファクトがあるかどうかでフィルタリングします。

**指定可能な値の型**: `Boolean`（`true`または`false`）

## 表示フィールド {#display-fields}

| フィールド              | 名前（およびエイリアス）                   | 説明 |
| ------------------ | ---------------------------------- | ----------- |
| アクティブ             | `active`                           | ジョブがアクティブであるかどうかを表示 |
| 失敗を許可      | `allowFailure`                     | ジョブが失敗を許可されているかどうかを表示 |
| キャンセル可能         | `cancelable`                       | ジョブがキャンセル可能であるかどうかを表示 |
| カバレッジ           | `coverage`                         | コードカバレッジ率を表示 |
| 作成日時         | `created`、`createdAt`             | ジョブが作成された日時を表示 |
| 期間           | `duration`                         | ジョブの期間を表示 |
| 消去日時          | `erased`、`erasedAt`               | ジョブのアーティファクトが消去された日時を表示 |
| 失敗メッセージ    | `failureMessage`                   | 失敗メッセージを表示 |
| 完了日時        | `finished`、`finishedAt`           | ジョブが完了した日時を表示 |
| ID                 | `id`                               | ジョブIDを表示 |
| 種類               | `kind`                             | ジョブの種類（`bridge`または`build`）を表示 |
| 手動ジョブ         | `manualJob`                        | これが手動ジョブであるかどうかを表示 |
| 名前               | `name`                             | ジョブ名を表示 |
| 再生可能           | `playable`                         | ジョブが再生可能であるかどうかを表示 |
| キュー登録日時          | `queued`、`queuedAt`               | ジョブがキューに登録された日時を表示 |
| 参照名           | `refName`                          | Gitの参照名を表示 |
| リトライ済み            | `retried`                          | ジョブがリトライされたかどうかを表示 |
| リトライ可能          | `retryable`                        | ジョブがリトライ可能であるかどうかを表示 |
| スケジュール          | `scheduled`                        | ジョブがスケジュールされているかどうかを表示 |
| スケジュールタイプ    | `schedulingType`                   | スケジュールタイプを表示 |
| 短縮SHA          | `shortSha`                         | 短縮コミットSHAを表示 |
| ソース             | `source`                           | ジョブのソースを表示 |
| ステージ              | `stage`                            | ジョブが所属するパイプラインステージを表示 |
| 開始日時         | `started`、`startedAt`             | ジョブが開始された日時を表示 |
| ステータス             | `status`                           | ジョブステータスを表示 |
| スタック              | `stuck`                            | ジョブがスタックしているかどうかを表示 |
| タグ               | `tags`                             | Runnerのタグを表示 |
| トリガー済み          | `triggered`                        | ジョブがトリガーされたかどうかを表示 |
| Webパス           | `webPath`                          | ジョブへのWebパスを表示 |
| アーティファクトあり     | `withArtifacts`                    | ジョブにアーティファクトがあるかどうかを表示 |
