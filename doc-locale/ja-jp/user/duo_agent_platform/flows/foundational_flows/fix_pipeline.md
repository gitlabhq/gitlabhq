---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: CI/CDパイプライン修正フロー
---

{{< details >}}

- プラン: [Free](../../../../subscriptions/gitlab_credits.md#for-the-free-tier)、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 18.4で`duo_workflow_in_ci`および`ai_duo_agent_fix_pipeline_button`[フラグ](../../../../administration/feature_flags/_index.md)とともに[実験的機能](../../../../policy/development_stages_support.md)として導入されました。`duo_workflow_in_ci`はデフォルトで有効になっています。`ai_duo_agent_fix_pipeline_button`はデフォルトで無効になっています。これらのフラグは、インスタンスまたはプロジェクトに対して有効または無効にすることができます。
- GitLab 18.5のGitLab.comおよびGitLab Self-Managedで有効になりました。
- 機能フラグ`ai_duo_agent_fix_pipeline_button`は、GitLab 18.5で[デフォルトで有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/205086)になっています。
- GitLab 18.8で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/work_items/585273)になりました。機能フラグ`ai_duo_agent_fix_pipeline_button`は[削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/216681)されました。機能フラグ`duo_workflow_in_ci`は、GitLab 18.9で削除されました。
- GitLab 18.10では、GitLab.comのFreeティアでGitLabクレジットとともに利用できます。

{{< /history >}}

CI/CDパイプライン修正フローは、GitLab CI/CDパイプラインの問題を自動的に診断し、修正するのに役立ちます。このフローには次の特長があります:

- パイプラインの失敗ログとエラーメッセージを分析します。
- 設定の問題と構文エラーを特定します。
- パイプラインの失敗の種類に基づいて具体的な修正を提案します。
- 失敗しているパイプラインの修正を試みる変更を含むマージリクエストを作成します。

このフローは、次のようなさまざまなパイプラインの問題を自動的に修正できます:

- 構文エラーと設定エラー。
- 一般的なジョブの失敗。
- 依存関係とワークフローの問題。

このフローは、GitLab UIでのみ使用できます。

## 前提条件 {#prerequisites}

- [GitLab Duo Agent Platformの前提条件](../../_index.md#prerequisites)を満たしていること。
- **基本フローを許可**および**CI/CDパイプランの修正**を[トップレベルグループに対して](_index.md#turn-foundational-flows-on-or-off)オンにします。
- プロジェクトのデベロッパー、メンテナー、またはオーナーロールを持っていること。
- 既存の失敗しているパイプラインがある。
- [サービスアカウントを許可するようにプッシュルールを設定していること](../../troubleshooting.md#configure-push-rules-to-allow-a-service-account)。
- プロジェクトで[独自のRunnerを設定](../execution.md#configure-runners)しているか、[GitLabホストRunner](../../../../ci/runners/hosted_runners/_index.md)を有効にしていること。

## マージリクエストでパイプラインを修正する {#fix-the-pipeline-in-a-merge-request}

マージリクエストでCI/CDパイプラインを修正するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 左サイドバーで、**コード** > **マージリクエスト**を選択し、マージリクエストを開きます。
1. パイプラインを修正するには、次のいずれかの方法があります:
   - **概要**タブを選択し、失敗しているパイプラインの下にある**Duoでパイプラインを修正**を選択します。
   - **パイプライン**タブを選択し、右端の列にある**Duoでパイプラインを修正**（{{< icon name="tanuki-ai" >}}）を選択します。

1. 進捗を監視するには、**AI** > **セッション**を選択します。

セッションが完了すると、修正内容を含むマージリクエストへのリンクを示すコメント、または考えられる次のステップを説明するコメントが表示されます。

## 他のCI/CDパイプラインを修正する {#fix-other-cicd-pipelines}

マージリクエストに関連付けられていないCI/CDパイプラインを修正するには:

1. **ビルド** > **パイプライン**を選択します。
1. 失敗しているパイプラインを選択します。
1. 右上隅で、**Duoでパイプラインを修正**を選択します。
1. 進捗を監視するには、**AI** > **セッション**を選択します。

## フローが分析する内容 {#what-the-flow-analyzes}

CI/CDパイプライン修正フローでは、次の内容を調べます:

- パイプラインログ: エラーメッセージ、失敗したジョブの出力、終了コード。
- マージリクエストの変更内容: 失敗の原因となった可能性のある変更。
- 現在のリポジトリの内容: 構文エラー、Lintエラー、インポートエラーを特定するための情報。
- スクリプトエラー: コマンドの失敗、実行可能ファイルの不足、または権限の問題。

## フローログ処理 {#flow-log-processing}

CI/CDパイプライン修正フローには、ログの処理に関する既知のイシューがあります。

AIゲートウェイは、最後の150 KiBのジョブログのみを処理します。あなたのジョブが大量の出力を生成する場合、フローはログの以前の部分に表示される関連する失敗情報をキャプチャできない可能性があります。

このイシューを回避するには、次を試してください:

- デバッグログと進捗インジケーターを削除して、詳細な出力を減らします。
- 重要でない出力をShellリダイレクト(`> /dev/null`)を使用してリダイレクトします。
- スクリプトの最後に、主要なエラーメッセージをエコーする要約ステップを追加します。
- メインスクリプトの完了後に、`after_script`を使用して診断情報を出力します。
- 冗長なジョブを、より簡潔なログを持つ、より小さく焦点を絞ったジョブに分割します。
