---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: CI/CDパイプライン修正フロー
---

{{< details >}}

- プラン: [Free](../../../../subscriptions/gitlab_credits.md#for-the-free-tier)、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 18.4で[実験](../../../../policy/development_stages_support.md)として、[機能フラグ](../../../../administration/feature_flags/_index.md) `duo_workflow_in_ci`および`ai_duo_agent_fix_pipeline_button`とともに導入されました。`duo_workflow_in_ci`はデフォルトで有効になっています。`ai_duo_agent_fix_pipeline_button`はデフォルトで無効になっています。これらのフラグは、インスタンスまたはプロジェクトに対して有効または無効にすることができます。
- GitLab 18.5のGitLab.comおよびGitLab Self-Managedで有効になりました。
- 機能フラグ`ai_duo_agent_fix_pipeline_button`は、GitLab 18.5で[デフォルトで有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/205086)になっています。
- GitLab 18.8で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/work_items/585273)になりました。機能フラグ`ai_duo_agent_fix_pipeline_button`は[削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/216681)されました。機能フラグ`duo_workflow_in_ci`は、GitLab 18.9で削除されました。
- GitLab 18.10で、GitLab.comのFreeプランにおいてGitLabクレジットを使用して利用できるようになりました。
- マージリクエストに関連付けられたパイプラインへの修正は、GitLab 19.1で`fix_pipeline_next`という[機能フラグ](../../../../administration/feature_flags/_index.md)とともに、コード提案として適用されるように[変更](https://gitlab.com/groups/gitlab-org/-/work_items/21837)されました。GitLab.comの一部のユーザーで有効になっています。
- GitLab 19.2で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/241608)になりました。機能フラグ`fix_pipeline_next`は削除されました。

{{< /history >}}

CI/CDパイプライン修正フローは、GitLab CI/CDパイプラインにおける問題を診断し、修正を提案します。フローは、失敗を診断するために、以下を調べます:

- パイプラインジョブログ、エラーメッセージ、失敗したジョブの出力、終了コードなど。
- 失敗の原因となった可能性のあるマージリクエストの変更。
- リポジトリの内容。これには、構文、Lint、またはインポートエラーの特定が含まれます。
- スクリプトのエラー。これには、コマンドの失敗、不足している実行可能ファイル、または権限の問題が含まれます。

フローが修正を適用する方法は、パイプラインのコンテキストによって異なります:

- パイプラインがマージリクエストに関連付けられている場合、フローはソースブランチにインラインのコード提案を適用します。マージリクエストから直接レビューして提案を適用できます。
  - 修正に現在のマージリクエスト差分の外部にあるファイルへの変更が必要な場合、フローは代わりに新しいマージリクエストを作成します。
- パイプラインがマージリクエストに関連付けられていない場合、フローは修正を含む新しいマージリクエストを作成します。

場合によっては、修正を試みる代わりに、フローは失敗と可能性のある次のステップを説明するコメントを投稿します。これは、パイプラインがマージリクエストに関連付けられている場合に発生します。例:

- 信頼性の高い修正を決定するための十分なコンテキストが存在しません。
- 失敗はセキュリティ上の機密性が高く、担当者によってレビューされる必要があります。
- 失敗のカテゴリはフローによって対応できません。

セッションが開始および完了すると、フローはセッションへのリンクとともに、マージリクエストにシステムノートを投稿します。このフローはGitLab UIでのみ使用できます。

GitLab Duo Agent Platformを使用し、失敗したパイプラインを自動的に修正したい場合は、このフローが推奨されるパスです。これは、単一ジョブの失敗をトラブルシューティングを行うためのGitLab Duo Chat機能である[根本原因分析](../../../gitlab_duo_chat/examples.md#troubleshoot-failed-cicd-jobs-with-root-cause-analysis)とは別のエクスペリエンスです。

## 前提条件 {#prerequisites}

- [GitLab Duo Agent Platformの前提条件](../../_index.md#prerequisites)を満たしていること。
- **基本フローを許可**および**CI/CDパイプランの修正**を[トップレベルグループに対して](_index.md#turn-foundational-flows-on-or-off)オンにします。
- プロジェクトのデベロッパー、メンテナー、またはオーナーロールを持っていること。
- 既存の失敗しているパイプラインがある。
- [サービスアカウントを許可するようにプッシュルールを設定していること](../../troubleshooting.md#configure-push-rules-to-allow-a-service-account)。
- プロジェクトで[独自のRunnerを設定](../execution.md#configure-runners-to-execute-flows)しているか、[GitLabホストRunner](../../../../ci/runners/hosted_runners/_index.md)を有効にしていること。

## マージリクエストでパイプラインを修正する {#fix-the-pipeline-in-a-merge-request}

{{< history >}}

- GitLab Duo Agentic Chatでのフローの使用は、GitLab 19.2で[機能フラグ](../../../../administration/feature_flags/_index.md) `agentic_foundational_flow_tool`という名前で[導入されました](https://gitlab.com/groups/gitlab-org/-/work_items/20484)。デフォルトでは有効になっています。

{{< /history >}}

> [!flag]
> この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

マージリクエストでCI/CDパイプラインを修正するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 左サイドバーで、**コード** > **マージリクエスト**を選択し、マージリクエストを開きます。
1. パイプラインを修正するには、次のいずれかの方法を使用します:
   - **概要**タブを選択し、失敗しているパイプラインの下にある**Duoでパイプラインを修正**を選択します。
   - **パイプライン**タブを選択し、一番右の列で**Duoでパイプラインを修正**（{{< icon name="tanuki-ai" >}}）を選択します。
   - GitLab Duoサイドバーで、新規または既存のAgentic Chat会話を開きます。Agentic Chatにパイプラインを修正するように依頼します。
1. 進捗状況を監視するには、左サイドバーで**AI** > **セッション**を選択します。

   Agentic Chatを使用している場合、以下のこともできます:
   - チャットの会話で進捗状況を確認します。
   - 会話で**View Agent Session**を選択します。

セッションが完了すると、フローはマージリクエストにコード提案を追加するか、可能性のある次のステップを説明するコメントを投稿します。

## 他のCI/CDパイプラインを修正する {#fix-other-cicd-pipelines}

マージリクエストに関連付けられていないCI/CDパイプラインを修正するには:

1. **ビルド** > **パイプライン**を選択します。
1. 失敗しているパイプラインを選択します。
1. 右上隅で、**Duoでパイプラインを修正**を選択します。
1. 進捗を監視するには、**AI** > **セッション**を選択します。

## `AGENTS.md`を使用してフローをカスタマイズする {#use-agentsmd-to-customize-the-flow}

フローは、リポジトリ内の[`AGENTS.md`](../../customize/agents_md.md)ファイルからリポジトリ固有の指示を読み取ります。`AGENTS.md`を使用して、次のような動作をカスタマイズできます:

- フローがコミットする変更のコミットメッセージ形式。
- フローが作成するマージリクエストのマージリクエストメタデータ（ラベル、説明など）。
- 特定の種類の失敗を分類および処理する方法。

例: 

```markdown
## Fix pipeline merge requests

When opening a merge request as part of the Fix Pipeline flow (the title contains [FixPipeline]),
apply labels based on the following failed pipeline scenarios:

- Pipeline failed on merge_request: apply "pipeline::tier-1". This runs the cheaper tier-1
  pipeline instead of the full default pipeline.
- Pipeline failed on the default_branch (main): apply both "pipeline::expedited" and
  "main:broken". Do not apply pipeline::tier-1 in this case.
- Pipeline failed on other branches: apply "pipeline::tier-1". Same treatment as the
  merge_request case.
```

## 既知の問題 {#known-issues}

- AIゲートウェイは、最後の150 KiBのジョブログのみを処理します。あなたのジョブが大量の出力を生成する場合、フローはログの以前の部分に表示される関連する失敗情報をキャプチャできない可能性があります。回避策については、次のセクションを参照してください。
- フローは、サンドボックス化されたランタイム環境でのパッケージのインストールを常に検証できるとは限りません。依存関係が不足している場合、デフォルトのフローイメージをカスタマイズできます。[デフォルトのDockerイメージを変更](../execution.md#change-the-default-docker-image)を参照してください。
- `AGENTS.md`に記載されているリポジトリの指示はフローの動作に影響を与えますが、すべての場合でそれに従うことを保証するものではありません。

## トラブルシューティング {#troubleshooting}

CI/CDパイプライン修正フローを使用しているときに、次のイシューに遭遇する可能性があります。

### フローが失敗の根本原因を特定できない {#flow-cannot-identify-the-root-cause-of-a-failure}

フローは、パイプラインの失敗の根本原因を特定できない場合があります。

このイシューは、ジョブログが150 KiBを超える場合に発生します。AIゲートウェイは最後の150 KiBのみを処理するため、ログの以前の部分に表示される関連する失敗情報はキャプチャされない可能性があります。

このイシューを回避するには、次を試してください:

- デバッグログと進捗インジケーターを削除して、詳細な出力を減らします。
- 重要でない出力をShellリダイレクト（`> /dev/null`）を使用してリダイレクトします。
- スクリプトの最後に、主要なエラーメッセージをエコーする要約ステップを追加します。
- メインスクリプトの完了後に、`after_script`を使用して診断情報を出力します。
- 冗長なジョブを、より簡潔なログを持つ、より小さく焦点を絞ったジョブに分割します。

## フィードバックを提供する {#give-feedback}

チームはCI/CDパイプライン修正フローを積極的に改善しています。イシューを報告したり、改善を提案したりするには、[フィードバックイシュー601991](https://gitlab.com/gitlab-org/gitlab/-/work_items/601991)にフィードバックを残してください。
