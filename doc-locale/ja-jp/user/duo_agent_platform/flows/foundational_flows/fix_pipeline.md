---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: CI/CDパイプラインのフローを修正
---

{{< details >}}

- プラン: Premium、Ultimate
- アドオン: GitLab Duo Core、Pro、またはEnterprise。
- 提供形態: GitLab.com、GitLab Self-Managed
- ステータス: ベータ

{{< /details >}}

{{< history >}}

- GitLab 18.4で[実験](../../../../policy/development_stages_support.md)として導入されました。[フラグ](../../../../administration/feature_flags/_index.md)の名前は`duo_workflow_in_ci`と`ai_duo_agent_fix_pipeline_button`です。`duo_workflow_in_ci`はデフォルトで有効になっています。`ai_duo_agent_fix_pipeline_button`はデフォルトで無効になっています。これらのフラグは、インスタンスまたはプロジェクトに対して有効または無効にできます。
- GitLab 18.5のGitLab.comとGitLab Self-Managedで有効になりました。
- 機能フラグ`ai_duo_agent_fix_pipeline_button`は、GitLab 18.5で[デフォルトで有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/205086)になっています。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

{{< /alert >}}

Fix GitLab CI/CDパイプラインフローは、GitLab CI/CDパイプラインの問題を自動的に診断し、修正するのに役立ちます。このフローの内容:

- パイプラインの失敗ログとエラーメッセージを分析します。
- 設定の問題と構文エラーを特定します。
- パイプラインの失敗の種類に基づいて、具体的な修正を提案します。
- 失敗しているパイプラインの修正を試みる変更を含むマージリクエストを作成します。

このフローでは、次のようなさまざまなパイプラインの問題を自動的に修正できます:

- 構文と設定のエラー。
- 一般的なジョブの失敗。
- 依存関係とワークフローの問題。

このフローは、GitLab UIでのみ使用できます。

## 前提要件 {#prerequisites}

このフローを使用するには、以下が必要です:

- 既存の失敗したパイプラインがある。
- プロジェクトのデベロッパーロール以上を持っている。
- [他の前提条件](../../../duo_agent_platform/_index.md#prerequisites)を満たしている。
- [GitLab Duoサービスアカウントがコミットとブランチを作成できることを確認している](../../troubleshooting.md#session-is-stuck-in-created-state)。

## マージリクエストでパイプラインを修正 {#fix-the-pipeline-in-a-merge-request}

マージリクエストでCI/CDパイプラインを修正するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。[新しいナビゲーションをオン](../../../interface_redesign.md#turn-new-navigation-on-or-off)にしている場合、このフィールドは上部のバーにあります。
1. 左側のサイドバーで**コード** > **マージリクエスト**を選択し、マージリクエストを開きます。
1. パイプラインを修正するには、次のいずれかの方法があります:
   - **概要**タブを選択し、失敗しているパイプラインの下にある**Duoのパイプラインを修正**を選択します。
   - **パイプライン**タブを選択し、右端の列で**Duoのパイプラインを修正** ({{< icon name="tanuki-ai" >}}) を選択します。

1. 進捗を監視するには、**自動化** > **セッション**を選択します。

セッションが完了すると、コメントに修正を含むマージリクエストへのリンクが表示されるか、コメントに考えられる次のステップが記述されます。

## 他のCI/CDパイプラインを修正 {#fix-other-cicd-pipelines}

マージリクエストに関連付けられていないCI/CDパイプラインを修正するには:

1. **ビルド** > **パイプライン**を選択します。
1. 失敗しているパイプラインを選択します。
1. 右上隅にある**Duoのパイプラインを修正**を選択します。
1. 進捗を監視するには、**自動化** > **セッション**を選択します。

## フローが分析するもの {#what-the-flow-analyzes}

Fix CI/CDパイプラインフローでは、以下を調べます:

- **Pipeline logs**（パイプラインログ）: エラーメッセージ、失敗したジョブの出力、終了コード。
- **Merge request changes**（マージリクエスト）の変更点: 失敗の原因となった可能性のある変更。
- **The current repository contents**（現在のリポジトリコンテンツ）: 構文、lint、またはインポートエラーを識別するため。
- **Script errors**（スクリプトエラー）: コマンドの失敗、実行可能ファイルがない、または権限の問題。
