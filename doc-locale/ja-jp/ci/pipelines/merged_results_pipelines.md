---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: マージ結果パイプラインを使用して、ソースブランチとターゲットブランチのコードを結合し、マージする前にテストします。
title: マージ結果パイプライン
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

マージ結果パイプラインは、ソースブランチとターゲットブランチのコードを結合した一時的なマージコミットをテストします。このコミットはどちらのブランチにも存在しませんが、パイプラインの詳細で確認できます。

このアプローチは、最新のターゲットブランチ内のコードで変更が機能することを確認し、マージする前にインテグレーションのイシューを検出し、異なるファイルでの変更が連携して機能することを確認するのに役立ちます。

ターゲットブランチに変更があり、それがソースブランチの変更と競合する場合、マージ結果パイプラインは実行できません。これらのケースでは、GitLabは代わりに標準のマージリクエストパイプラインを実行します。

## マージ結果パイプラインを有効にする {#enable-merged-results-pipelines}

前提条件: 

- プロジェクトのメンテナーまたはオーナーロールが必要です。
- お使いの`.gitlab-ci.yml`ファイルは[マージリクエストパイプライン](merge_request_pipelines.md#prerequisites)用に設定する必要があります。
- プロジェクトはGitLabでホストされている必要があります（GitHubやBitbucketのような外部リポジトリではありません）。

プロジェクトでマージ結果パイプラインを有効にするには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 左サイドバーで、**設定** > **マージリクエスト**を選択します。
1. **マージオプション**の下で、**マージ結果のパイプラインを有効にする**を選択します。
1. **変更を保存**を選択します。

> [!warning]
> この設定を有効にしても、`.gitlab-ci.yml`ファイルでマージリクエストパイプラインを設定しない場合、マージリクエストが未解決の状態でスタックするか、パイプラインがドロップされる可能性があります。

## トラブルシューティング {#troubleshooting}

マージ結果パイプラインを使用する場合、以下のイシューに遭遇する可能性があります。

### `rules:changes:compare_to`でジョブまたはパイプラインが予期せず実行される {#jobs-or-pipelines-run-unexpectedly-with-ruleschangescompare_to}

マージリクエストパイプラインで`rules:changes:compare_to`を使用すると、ジョブまたはパイプラインが予期せず実行されることがあります。

このイシューは、マージ結果パイプラインが一時的なマージコミットを比較のベースとして使用するため発生します。このコミットには、マージリクエストブランチとターゲットブランチの両方からの変更が含まれており、ルールが予期せずトリガーされる可能性があります。

たとえば、マージリクエストが`src/feature.js`を追加し、ターゲットブランチに`src/utils.js`が含まれている場合、一時的なマージコミットには両方のファイルが含まれます。`rules:changes:compare_to: main`を持つルールは、フィーチャーファイルだけでなく両方の変更を検出し、自身の変更のみで実行されるべきジョブをトリガーする可能性があります。

この問題を解決するには、次の手順に従います:

- デフォルトの比較動作を使用するには、`compare_to`パラメータを削除します。
- 変更ルールでは、より具体的なファイルパスパターンを使用してください。
- `compare_to`なしで`rules:changes`を使用することを検討してください。

### 成功したマージ結果パイプラインが失敗したブランチパイプラインをオーバーライドする {#successful-merged-results-pipeline-overrides-a-failed-branch-pipeline}

失敗したブランチパイプラインが、[**パイプラインが完了している**設定](../../user/project/merge_requests/auto_merge.md#require-a-successful-pipeline-for-merge)がアクティブ化されている場合に無視される状況に遭遇する可能性があります。

このイシューは、パイプラインロジックの優先順位付けが原因で発生します。改善のサポートは[イシュー385841](https://gitlab.com/gitlab-org/gitlab/-/issues/385841)で提案されています。
