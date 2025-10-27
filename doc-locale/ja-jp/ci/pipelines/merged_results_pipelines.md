---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: マージ結果パイプライン
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

マージ結果パイプラインは、ソースブランチとターゲットブランチをマージした結果に対して実行されます。[マージリクエストパイプライン](merge_request_pipelines.md)の一種です。

GitLabはマージ結果で内部コミットを作成するため、パイプラインはそれに対して実行できます。このコミットはいずれのブランチにも存在しませんが、パイプラインの詳細で表示できます。内部コミットの作成者は常に、マージリクエストを作成したユーザーとなります。

パイプラインは、パイプラインを実行した時点でのターゲットブランチに対して実行されます。ソースブランチで作業している間、ターゲットブランチは変更される可能性があります。マージ結果が正確であることを確認したい場合は、いつでもパイプラインを再実行できます。

ターゲットブランチに変更があり、それがソースブランチの変更と競合する場合、マージ結果パイプラインは実行できません。このような場合、パイプラインは[マージリクエストパイプライン](merge_request_pipelines.md)として実行され、`merge request`としてラベル付けされます。

## 前提要件 {#prerequisites}

マージ結果パイプラインを使用するには、次の前提要件を満たす必要があります:

- プロジェクトの`.gitlab-ci.yml`ファイルが、[マージリクエストパイプラインでジョブを実行](merge_request_pipelines.md#prerequisites)するように設定されている必要があります。
- リポジトリは、[外部リポジトリ](../ci_cd_for_external_repos/_index.md)ではなく、GitLabリポジトリである必要があります。

## マージ結果パイプラインを有効にする {#enable-merged-results-pipelines}

プロジェクトでマージ結果パイプラインを有効にするには、少なくともメンテナーロールが必要です:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定**>**マージリクエスト**を選択します。
1. **マージオプション**セクションで、**マージされた結果のパイプラインを有効にする**を選択します。
1. **変更を保存**を選択します。

{{< alert type="warning" >}}

マージリクエストパイプラインを使用するようにパイプラインを設定しないと、チェックボックスをオンにしても、マージリクエストが未解決の状態のままになったり、パイプラインがドロップされたりする可能性があります。

{{< /alert >}}

## トラブルシューティング {#troubleshooting}

### `rules:changes:compare_to`でジョブまたはパイプラインが予期せず実行される {#jobs-or-pipelines-run-unexpectedly-with-ruleschangescompare_to}

マージリクエストパイプラインで`rules:changes:compare_to`を使用すると、ジョブまたはパイプラインが予期せず実行されることがあります。

マージ結果パイプラインでは、GitLabが作成する内部コミットが、比較対象のベースとして使用されます。このコミットには、MRブランチの先端よりも多くの変更が含まれている可能性があり、予期しない結果が生じます。

### 成功したマージ結果パイプラインが失敗したブランチパイプラインをオーバーライドする {#successful-merged-results-pipeline-overrides-a-failed-branch-pipeline}

[**パイプラインが完了している**設定](../../user/project/merge_requests/auto_merge.md#require-a-successful-pipeline-for-merge)が有効になっている場合、失敗したブランチパイプラインが無視されることがあります。この問題を追跡するために、[イシュー385841](https://gitlab.com/gitlab-org/gitlab/-/issues/385841)がオープンになっています。
