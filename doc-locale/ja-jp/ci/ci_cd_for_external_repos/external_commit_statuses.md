---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 外部コミットステータス
description: 外部CI/CDシステムが、コミットステータスを使用してGitLabパイプラインと統合する方法。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

外部コミットステータスを使用すると、Jenkins、CircleCI、カスタムデプロイツールなどの外部CI/CDシステムをGitLabパイプラインと統合できます。外部システムはコミットステータスをGitLabにポストし、ステータスの結果はマージリクエストとコミットビューのCI/CDジョブとともに表示されます。

外部システムが[Commits API](../../api/commits.md#set-commit-pipeline-status)を使用してコミットステータスをポストすると、GitLabはこれらのステータスを既存のパイプラインに追加するか、それらを含める新しいパイプラインを作成して処理します。

## パイプラインの選択 {#pipeline-selection}

外部システムからコミットステータスをポストすると、検索または作成のアプローチが使用されます:

1. GitLabは、指定されたコミットSHAとrefsの最新の`non-archived` CIパイプラインを検索します。`pipeline_id`パラメータを含めることで、パイプラインを直接検索することもできます。
1. GitLabが適切なパイプラインを見つけた場合、新しいジョブステータスをそのパイプラインに追加します。既存のパイプラインに追加されたジョブの場合、`CI_PIPELINE_SOURCE`はパイプラインソース（`push`や`merge_request_event`など）と一致します。
1. 適切なパイプラインが存在しない場合、GitLabはジョブを含める新しいパイプラインを作成します。新しいパイプラインの場合、`CI_PIPELINE_SOURCE`は`external`です。

外部ジョブステータスは、他のGitLab CI/CDステージとは別に、パイプラインの`external`ステージに表示されます。

{{< alert type="warning" >}}

同じコミットに対して重複するパイプラインが存在する場合、外部ステータスの配置があいまいになります。GitLabは`newest_first`を使用して最新のパイプラインを選択しますが、同時パイプライン作成では、外部ステータスが予期しないパイプラインに表示されたり、マージリクエストビューに表示されなくなったりする可能性があります。

重複するパイプラインを回避したり、`pipeline_id`でパイプラインを直接ターゲットにしたりするには、[ワークフロールール](../yaml/workflow.md)を設定します。

{{< /alert >}}

## ジョブの更新と再試行 {#job-updates-and-retries}

外部システムからコミットステータスをポストする場合:

- 同じ`name` `user`および`sha`を持つ`running`または`pending`ジョブがターゲットパイプラインにすでに存在する場合、GitLabはそのステータスを更新します。
  - 別のユーザーが同じ`name`でジョブを更新すると、ジョブが再試行されます。これにより、新しいジョブが作成され、現在のパイプラインから古いジョブが非表示になります。
- `name`が同じで`status`が異なる（たとえば、`failed`とマークされたジョブに`success`を送信する）`running`または`pending`でないジョブを再試行できます。これにより、新しいジョブが作成され、現在のパイプラインから古いジョブが非表示になります。
- 異なる外部サービスは、一意のジョブ`name`を使用して、同じSHAとパイプラインにジョブを追加できます。

SHA/refsの組み合わせで更新がすでに進行中の場合、`409`エラーが返されます。このエラーを処理するには、リクエストを再試行してください。

## トラブルシューティング {#troubleshooting}

### マージリクエストに外部ステータスが表示されない {#external-statuses-not-visible-in-merge-requests}

外部CIステータスがマージリクエストパイプラインに表示されない場合:

1. 同じコミットに対してマージリクエストとブランチパイプラインの両方が実行されているかどうかを確認します。
1. [ワークフロールール](../yaml/workflow.md)が重複するパイプラインを防いでいることを確認してください。
1. 外部システムが正しいrefsにポストしていることを確認します。
1. コミットがマージリクエストに関連付けられている場合は、APIコールがマージリクエストのソースブランチ内のコミットを対象としていることを確認してください。

詳細については、[重複するパイプラインの回避](../jobs/job_rules.md#avoid-duplicate-pipelines)を参照してください。
