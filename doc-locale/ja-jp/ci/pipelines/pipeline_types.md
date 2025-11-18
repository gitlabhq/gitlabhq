---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: パイプラインの種類
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

プロジェクトでは、次のようなさまざまな種類のパイプラインを実行できます:

- ブランチパイプライン
- タグパイプライン
- マージリクエストパイプライン
- マージ結果パイプライン
- マージトレイン

これらの種類のパイプラインはすべて、マージリクエストの**パイプライン**タブに表示されます。

## ブランチパイプライン {#branch-pipeline}

ブランチに変更をコミットするたびに、パイプラインを実行できます。

この種類のパイプラインは、*ブランチパイプライン*と呼ばれます。パイプラインリストに`branch`ラベルが表示されます。

このパイプラインはデフォルトで実行されます。設定は必要ありません。

ブランチパイプライン:

- ブランチに新しいコミットをプッシュすると実行されます。
- [定義済み変数の一部](../variables/predefined_variables.md)にアクセスできます。
- ブランチが[保護ブランチ](../../user/project/repository/branches/protected.md)の場合、[保護された変数](../variables/_index.md#protect-a-cicd-variable)と[保護されたRunner](../runners/configure_runners.md#prevent-runners-from-revealing-sensitive-information)にアクセスできます。

## タグパイプライン {#tag-pipeline}

新しい[タグ](../../user/project/repository/tags/_index.md)を作成またはプッシュするたびに、パイプラインを実行できます。

この種類のパイプラインは、*タグパイプライン*と呼ばれます。パイプラインリストに`tag`ラベルが表示されます。

このパイプラインはデフォルトで実行されます。設定は必要ありません。

タグパイプライン:

- リポジトリに新しいタグを作成/プッシュすると実行されます。
- [定義済み変数の一部](../variables/predefined_variables.md)にアクセスできます。
- タグが[保護タグ](../../user/project/protected_tags.md)の場合、[保護された変数](../variables/_index.md#protect-a-cicd-variable)と[保護されたRunner](../runners/configure_runners.md#prevent-runners-from-revealing-sensitive-information)にアクセスできます。

## マージリクエストパイプライン {#merge-request-pipeline}

ブランチパイプラインの代わりに、マージリクエストでソースブランチに変更を加えるたびにパイプラインが実行されるように設定できます。

この種類のパイプラインは、*マージリクエストパイプライン*と呼ばれます。パイプラインリストに`merge request`ラベルが表示されます。

マージリクエストパイプラインは、デフォルトでは実行されません。`.gitlab-ci.yml`ファイルで、マージリクエストパイプラインとして実行するようにジョブを設定する必要があります。

詳細については、[マージリクエストパイプライン](merge_request_pipelines.md)を参照してください。

## マージ結果パイプライン {#merged-results-pipeline}

{{< history >}}

- `merged results`ラベルは、GitLab 16.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/132975)されました。

{{< /history >}}

*マージ結果パイプライン*は、ソースブランチとターゲットブランチをマージした結果に対して実行されます。これは、マージリクエストパイプラインの一種です。

これらのパイプラインはデフォルトでは実行されません。`.gitlab-ci.yml`ファイルで、ジョブをマージリクエストパイプラインとして実行するように設定し、マージ結果パイプラインを有効にする必要があります。

これらのパイプラインは、パイプラインリストに`merged results`ラベルが表示されます。

詳細については、[マージ結果パイプライン](merged_results_pipelines.md)を参照してください。

## マージトレイン {#merge-trains}

デフォルトブランチへのマージが頻繁に行われるプロジェクトでは、異なるマージリクエストの変更が互いに競合する可能性があります。*マージトレイン*を使用して、マージリクエストをキューに入れることで、各マージリクエストが、それ以前にキューに入れられた他のマージリクエストと比較され、すべてが整合して動作することを確認できます。

マージトレインはマージ結果パイプラインとは異なります。マージ結果パイプラインは、変更がデフォルトブランチのコンテンツで動作することを保証しますが、他のユーザーが同時にマージしているコンテンツでは保証されません。

これらのパイプラインはデフォルトでは実行されません。`.gitlab-ci.yml`ファイルで、ジョブをマージリクエストパイプラインとして実行するように設定し、マージ結果パイプラインを有効にして、マージトレインを有効にする必要があります。

これらのパイプラインは、パイプラインリストに`merge train`ラベルが表示されます。

詳細については、[マージトレイン](merge_trains.md)を参照してください。
