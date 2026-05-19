---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab Query Language（GLQL）データソース
---

GLQLは以下のデータソースをクエリできます:

| データソース | `type`の値 | 説明 |
|---|---|---|
| [作業アイテム](work_items.md) | `Issue`、`Incident`、`TestCase`、`Requirement`、`Task`、`Ticket`、`Objective`、`KeyResult`、`Epic` | イシュー、エピック、およびその他の作業アイテムタイプ。デフォルト。 `type`が省略された場合。 |
| [マージリクエスト](merge_requests.md) | `MergeRequest` | コードレビューとマージワークフロー。 |
| [パイプライン](pipelines.md) | `Pipeline` | CI/CDパイプライン。 |
| [ジョブ](jobs.md) | `Job` | パイプライン内のCI/CDジョブ。 |
| [プロジェクト](projects.md) | `Project` | ネームスペース内のプロジェクト。 |

各データソースには、フィルタリング、表示、ソートに対応する独自のフィールドセットがあります。

クエリ内で`type`フィールドを使用してデータソースを指定します。例: `type = Issue`、`type = MergeRequest`。複数のタイプをサポートするデータソースの場合、`in`演算子を使用してタイプ間でクエリを実行します。例: `type in (Issue, Task)`。
