---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: CI/CDパイプラインの修正フロー
---

{{< details >}}

- プラン: Premium、Ultimate
- アドオン: GitLab Duo Core、Pro、またはEnterprise
- 提供形態: GitLab.com、GitLab Self-Managed

この機能は[GitLabクレジット](../../../../subscriptions/gitlab_credits.md)を使用します。

{{< /details >}}

{{< history >}}

- GitLab 18.4で`duo_workflow_in_ci`および`ai_duo_agent_fix_pipeline_button`[フラグ](../../../../administration/feature_flags/_index.md)とともに[実験的機能](../../../../policy/development_stages_support.md)として導入されました。`duo_workflow_in_ci`はデフォルトで有効になっています。`ai_duo_agent_fix_pipeline_button`はデフォルトで無効になっています。これらのフラグは、インスタンスまたはプロジェクトに対して有効または無効にすることができます。
- GitLab 18.5のGitLab.comおよびGitLab Self-Managedで有効になりました。
- 機能フラグ`ai_duo_agent_fix_pipeline_button`は、GitLab 18.5で[デフォルトで有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/205086)になっています。
- GitLab 18.8で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/work_items/585273)になりました。機能フラグ`ai_duo_agent_fix_pipeline_button`は[削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/216681)されました。フィーチャフラグ`duo_workflow_in_ci`はGitLab 18.9で削除されました。

{{< /history >}}

CI/CDパイプラインの修正フローは、GitLab CI/CDパイプラインの問題を自動的に診断し、修正するのに役立ちます。このフローには次の特長があります:

- パイプラインの失敗ログとエラーメッセージを分析します。
- 設定の問題と構文エラーを特定します。
- パイプラインの失敗の種類に基づいて具体的な修正を提案します。
- 失敗しているパイプラインの修正を試みる変更を含むマージリクエストを作成します。

このフローは、次のようなさまざまなパイプラインの問題を自動的に修正できます:

- 構文エラーと設定エラー。
- 一般的なジョブの失敗。
- 依存関係とワークフローの問題。

このフローは、GitLab UIでのみ使用できます。

> [!note] Fix CI/CDパイプラインフローは、サービスアカウントを使用してマージリクエストを作成します。SOC 2、SOX法、ISO 27001、またはFedRAMPの要件がある組織は、適切なピアレビューポリシーが整備されていることを確認してください。詳細については、[マージリクエストに関するコンプライアンス上の考慮事項](../../composite_identity.md#compliance-considerations-for-merge-requests)を参照してください。

## 前提条件 {#prerequisites}

このフローを使用するには、次の要件を満たしている必要があります:

- 既存の失敗しているパイプラインがある。
- プロジェクトのデベロッパーロール以上を持っている。
- [他の前提条件](../../../duo_agent_platform/_index.md#prerequisites)を満たしている。
- [GitLab Duoサービスアカウントがコミットとブランチを作成できることを確認している](../../troubleshooting.md#session-is-stuck-in-created-state)。
- Fix CI/CDパイプラインフローが[オンになっている](../../../gitlab_duo/turn_on_off.md#turn-gitlab-duo-on-or-off)ことを確認してください。

## マージリクエストでパイプラインを修正する {#fix-the-pipeline-in-a-merge-request}

マージリクエストでCI/CDパイプラインを修正するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **コード** > **マージリクエスト**を選択して、マージリクエストを開きます。
1. パイプラインを修正するには、次のいずれかの方法があります:
   - **概要**タブを選択し、失敗しているパイプラインの下にある**Duoでパイプラインを修正**を選択します。
   - **パイプライン**タブを選択し、右端の列にある**Duoでパイプラインを修正**（{{< icon name="tanuki-ai" >}}）を選択します。

1. 進捗を監視するには、**自動化** > **セッション**を選択します。

セッションが完了すると、修正内容を含むマージリクエストへのリンクを示すコメント、または考えられる次のステップを説明するコメントが表示されます。

## 他のCI/CDパイプラインを修正する {#fix-other-cicd-pipelines}

マージリクエストに関連付けられていないCI/CDパイプラインを修正するには:

1. **ビルド** > **パイプライン**を選択します。
1. 失敗しているパイプラインを選択します。
1. 右上隅で、**Duoでパイプラインを修正**を選択します。
1. 進捗を監視するには、**自動化** > **セッション**を選択します。

## フローが分析する内容 {#what-the-flow-analyzes}

CI/CDパイプラインの修正フローでは、次の内容を調べます:

- パイプラインログ: エラーメッセージ、失敗したジョブの出力、終了コード。
- マージリクエストの変更: 失敗の原因となった可能性のある変更。
- 現在のリポジトリの内容: 構文エラー、Lintエラー、インポートエラーを特定するための情報。
- スクリプトエラー: コマンドの失敗、実行可能ファイルの不足、または権限の問題。
