---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: CI/CDパイプラインの修正
---

{{< details >}}

- プラン: Premium、Ultimate
- アドオン: GitLab Duo Core、Pro、またはEnterprise。
- 提供形態: GitLab.com、GitLab Self-Managed
- ステータス: ベータ

{{< /details >}}

{{< history >}}

- GitLab 18.4では、[実験](../../../policy/development_stages_support.md)として、[フラグ](../../../administration/feature_flags/_index.md)を立てて導入されました。フラグの名前は、`duo_workflow_in_ci`と`ai_duo_agent_fix_pipeline_button`です。`duo_workflow_in_ci`はデフォルトで有効になっています。`ai_duo_agent_fix_pipeline_button`はデフォルトで無効になっています。これらのフラグは、インスタンスまたはプロジェクトに対して有効または無効にできます。
- GitLab 18.5のGitLab.comとGitLab Self-Managedで有効。
- 機能フラグ`ai_duo_agent_fix_pipeline_button`はGitLab 18.5で[デフォルトで有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/205086)になりました。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

{{< /alert >}}

GitLab CI/CDパイプラインフローの修正は、GitLab CI/CDパイプラインの問題を自動的に診断して修正するのに役立ちます。このフロー:

- パイプラインの失敗ログとエラーメッセージを分析します。
- 設定の問題と構文エラーを特定します。
- パイプラインの失敗の種類に基づいて、具体的な修正を提案します。
- 失敗したパイプラインの修正を試みる変更を含むマージリクエストを作成します。

このフローは、以下を含むさまざまなパイプラインの問題を自動的に修正できます:

- 構文と設定のエラー。
- 一般的なジョブの失敗。
- 依存関係とワークフローの問題。

このフローは、GitLab UIでのみ使用できます。

## 前提要件 {#prerequisites}

このフローを使用するには、以下が必要です:

- 既存の失敗したパイプラインがある。
- プロジェクトで少なくともデベロッパーのロールを持っている。
- [その他の前提条件](../../duo_agent_platform/_index.md#prerequisites)を満たしている。

## フローを使用する {#use-the-flow}

CI/CDパイプラインを修正するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 左側のサイドバーで、**コード** > **マージリクエスト**を選択し、マージリクエストを開きます。
1. **パイプライン**タブを選択します。
1. 右端の列で、修正する失敗したパイプラインに対して、**Duoのパイプラインを修正**を選択します。
1. 進捗を監視するには、**自動化** > **セッション**を選択します。

   セッションが完了したら、マージリクエストに戻ります。
1. マージリクエストをレビューし、マージする前に必要に応じて変更を加えます。

## フローの分析対象 {#what-the-flow-analyzes}

CI/CDパイプラインフローの修正は、以下を調べます:

- **Pipeline logs**（パイプラインログ）: エラーメッセージ、失敗したジョブの出力、終了コード。
- **Merge request changes**（マージリクエストの変更点）: 失敗の原因となった可能性のある変更。
- **The current repository contents**（現在のリポジトリの内容）: 構文、lint処理、またはインポートエラーを識別するため。
- **Script errors**（スクリプトエラー）: コマンドの失敗、実行可能ファイルの欠落、または権限の問題。
