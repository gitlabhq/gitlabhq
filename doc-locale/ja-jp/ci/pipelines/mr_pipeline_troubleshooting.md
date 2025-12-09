---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: マージリクエストパイプラインのトラブルシューティング
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

マージリクエストのマージリクエストパイプラインの操作中に、次のイシューが発生する可能性があります。

## ブランチにプッシュする際の2つのパイプライン {#two-pipelines-when-pushing-to-a-branch}

マージリクエストでパイプラインが重複する場合、パイプラインがブランチとマージリクエストの両方に対して同時に実行されるように設定されている可能性があります。パイプラインの設定を調整して、[重複するパイプラインを回避](../jobs/job_rules.md#avoid-duplicate-pipelines)してください。

`workflow:rules`を追加して、[ブランチのパイプラインからマージリクエストパイプラインにスイッチする](../yaml/workflow.md#switch-between-branch-pipelines-and-merge-request-pipelines)ことができます。ブランチでマージリクエストを開くと、パイプラインがマージリクエストパイプラインにスイッチします。

## 無効なCI/CD設定ファイルをプッシュする際の2つのパイプライン {#two-pipelines-when-pushing-an-invalid-cicd-configuration-file}

無効なCI/CD設定をマージリクエストのブランチにプッシュすると、失敗した2つのパイプラインがパイプラインタブに表示されます。1つのパイプラインは失敗したブランチパイプラインであり、もう1つは失敗したマージリクエストパイプラインです。

設定の構文が修正されると、それ以上失敗したパイプラインは表示されません。設定の問題を特定して修正するには、以下を使用できます:

- [パイプラインエディタ](../pipeline_editor/_index.md)を使用
- [CI Lintツール](../yaml/lint.md)。

## マージリクエストのパイプラインが失敗としてマークされているが、最新のパイプラインは成功しました {#the-merge-requests-pipeline-is-marked-as-failed-but-the-latest-pipeline-succeeded}

単一のマージリクエストの**パイプライン**タブに、ブランチパイプラインとマージリクエストパイプラインの両方を含めることができます。これは、[設定による](../yaml/workflow.md#switch-between-branch-pipelines-and-merge-request-pipelines)か、[事故による](#two-pipelines-when-pushing-to-a-branch)可能性があります。

プロジェクトで[**パイプラインが完了している**](../../user/project/merge_requests/auto_merge.md#require-a-successful-pipeline-for-merge)が有効になっており、両方のパイプラインタイプが存在する場合、ブランチパイプラインではなく、マージリクエストパイプラインがチェックされます。

したがって、マージリクエストパイプラインの結果は、**merge request pipeline**（マージリクエストパイプライン）が失敗した場合、**branch pipeline**（ブランチパイプライン）の結果とは関係なく、失敗としてマークされます。

ただし、次の点に注意が必要です:

- これらの条件は強制されません。
- 競合状態によって、どのパイプラインの結果を使用してマージリクエストをブロックまたは追跡するかが決まります。

このバグは、[イシュー384927](https://gitlab.com/gitlab-org/gitlab/-/issues/384927)で追跡されます。

## `An error occurred while trying to run a new pipeline for this merge request.` {#an-error-occurred-while-trying-to-run-a-new-pipeline-for-this-merge-request}

このエラーは、マージリクエストで**パイプラインの実行**を選択しても、プロジェクトでマージリクエストパイプラインが有効になっていない場合に発生する可能性があります。

このエラーメッセージの原因として考えられるのは、次のとおりです:

- プロジェクトでマージリクエストパイプラインが有効になっておらず、**パイプライン**タブにパイプラインがリストされておらず、**Run pipelines**（パイプラインの実行）を選択した場合。
- プロジェクトで以前はマージリクエストパイプラインが有効になっていたものの、設定が削除された。例: 

  1. マージリクエストの作成時に、プロジェクトの`.gitlab-ci.yml`設定ファイルでマージリクエストパイプラインが有効になっている。
  1. **パイプラインの実行**オプションは、マージリクエストの**パイプライン**タブで使用でき、この時点で**パイプラインの実行**を選択しても、エラーは発生しない可能性があります。
  1. プロジェクトの`.gitlab-ci.yml`ファイルが変更され、マージリクエストパイプラインの設定が削除された。
  1. 更新された設定をマージリクエストに取り込むために、ブランチがリベースされました。
  1. これで、パイプラインの設定はマージリクエストパイプラインをサポートしなくなりましたが、**パイプラインの実行**を選択してマージリクエストパイプラインを実行します。

**パイプラインの実行**が使用可能であっても、プロジェクトでマージリクエストパイプラインが有効になっていない場合は、このオプションを使用しないでください。コミットをプッシュするか、ブランチをリベースして、新しいブランチパイプラインをトリガーできます。

## `Merge blocked: pipeline must succeed. Push a new commit that fixes the failure`メッセージ {#merge-blocked-pipeline-must-succeed-push-a-new-commit-that-fixes-the-failure-message}

このメッセージは、マージリクエストパイプライン、[マージ結果パイプライン](merged_results_pipelines.md) 、または[マージトレインパイプライン](merge_trains.md)が失敗またはキャンセルされた場合に表示されます。これは、ブランチパイプラインが失敗した場合には発生しません。

マージリクエストパイプラインまたはマージ結果パイプラインがキャンセルまたは失敗した場合、次のことができます:

- マージリクエストのパイプラインタブで**パイプラインの実行**を選択して、パイプライン全体を再実行します。
- [失敗したジョブのみをリトライする](_index.md#view-pipelines)。パイプライン全体を再実行する場合、これは必要ありません。
- 新しいコミットをプッシュして、失敗を修正します。

マージトレインパイプラインが失敗した場合、次のことができます:

- 失敗を確認し、[`/merge`クイックアクション](../../user/project/quick_actions.md)を使用して、マージリクエストをすぐにトレインに再度追加できるかどうかを判断します。
- マージリクエストのパイプラインタブで**パイプラインの実行**を選択してパイプライン全体を再実行し、マージリクエストをトレインに再度追加します。
- コミットをプッシュして失敗を修正し、マージリクエストをトレインに再度追加します。

マージトレインパイプラインがマージリクエストのマージ前にキャンセルされた場合、失敗がなければ、次のことができます:

- トレインに再度追加します。
