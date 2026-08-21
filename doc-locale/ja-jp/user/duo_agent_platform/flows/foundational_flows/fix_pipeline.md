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

- GitLab 18.4で`duo_workflow_in_ci`および`ai_duo_agent_fix_pipeline_button`[機能フラグ](../../../../administration/feature_flags/_index.md)とともに[実験的機能](../../../../policy/development_stages_support.md)として導入されました。`duo_workflow_in_ci`はデフォルトで有効になっています。`ai_duo_agent_fix_pipeline_button`はデフォルトで無効になっています。これらのフラグは、インスタンスまたはプロジェクトに対して有効または無効にすることができます。
- GitLab 18.5のGitLab.comおよびGitLab Self-Managedで有効になりました。
- 機能フラグ`ai_duo_agent_fix_pipeline_button`は、GitLab 18.5で[デフォルトで有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/205086)になっています。
- GitLab 18.8で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/work_items/585273)になりました。機能フラグ`ai_duo_agent_fix_pipeline_button`は[削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/216681)されました。機能フラグ`duo_workflow_in_ci`は、GitLab 18.9で削除されました。
- GitLab 18.10で、GitLab.comのFreeプランにおいてGitLabクレジットを使用して利用できるようになりました。
- GitLab 19.1で、`fix_pipeline_next`[機能フラグ](../../../../administration/feature_flags/_index.md)とともに、マージリクエストに関連付けられたパイプラインの修正がコード提案として適用されるように[変更](https://gitlab.com/groups/gitlab-org/-/work_items/21837)されました。一部のユーザーを対象にGitLab.comで有効になりました。
- GitLab 19.2で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/241608)になりました。機能フラグ`fix_pipeline_next`は削除されました。

{{< /history >}}

CI/CDパイプライン修正フローは、GitLab CI/CDパイプラインの問題を診断し、修正を提案します。失敗を診断するために、フローは次の情報を調べます:

- エラーメッセージ、失敗したジョブの出力、終了コードなどのパイプラインログ。
- 失敗の原因となった可能性のあるマージリクエストの変更。
- 構文エラー、Lintエラー、またはインポートエラーを特定するためのリポジトリの内容。
- コマンドの失敗、実行可能ファイルの欠落、権限の問題などのスクリプトエラー。

フローが修正を適用する方法は、パイプラインのコンテキストによって異なります:

- パイプラインがマージリクエストに関連付けられている場合、フローはソースブランチにインラインコード提案を適用します。提案は、マージリクエストから直接レビューして適用できます。
  - 修正のため、現在のマージリクエストの差分に含まれていないファイルを変更する必要がある場合、フローは代わりに新しいマージリクエストを作成します。
- パイプラインがマージリクエストに関連付けられていない場合、フローは修正を含む新しいマージリクエストを作成します。

場合によっては、フローは修正を試みる代わりに、失敗および実行可能な次のステップについて説明するコメントを投稿します。たとえば、パイプラインがマージリクエストに関連付けられている場合、次のような状況でこの処理が行われます:

- 信頼性の高い修正を特定するためのコンテキストが不足している。
- 失敗がセキュリティに関係するため、人によるレビューが必要である。
- 失敗のカテゴリが、フローで対処可能なものではない。

セッションが開始および完了すると、フローはセッションへのリンクを含むシステムノートをマージリクエストに投稿します。このフローはGitLab UIでのみ使用できます。

GitLab Duo Agent Platformを使用しており、失敗したパイプラインを自動的に修正する場合は、このフローの使用をおすすめします。このフローは、単一ジョブの失敗についてトラブルシューティングを行うためのGitLab Duo Chat機能である[根本原因分析](../../../gitlab_duo_chat/examples.md#troubleshoot-failed-cicd-jobs-with-root-cause-analysis)とは別の機能です。

## 前提条件 {#prerequisites}

- [GitLab Duo Agent Platformの前提条件](../../_index.md#prerequisites)を満たしていること。
- [トップレベルグループ](_index.md#turn-foundational-flows-on-or-off)で、**基本フローを許可**と**CI/CDパイプランの修正**をオンにしている。
- プロジェクトのデベロッパー、メンテナー、またはオーナーロールを持っている。
- 既存の失敗しているパイプラインがある。
- [サービスアカウントを許可するようにプッシュルールを設定していること](../../troubleshooting.md#configure-push-rules-to-allow-a-service-account)。
- プロジェクトで[独自のRunnerを設定](../execution/_index.md#configure-runners-to-execute-flows)しているか、[GitLabホストRunner](../../../../ci/runners/hosted_runners/_index.md)を有効にしていること。

## マージリクエストでパイプラインを修正する {#fix-the-pipeline-in-a-merge-request}

{{< history >}}

- GitLab 19.2で、GitLab Duo Agentic Chatの会話においてフローを使用する機能が`agentic_foundational_flow_tool`[機能フラグ](../../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/groups/gitlab-org/-/work_items/20484)されました。デフォルトでは有効になっています。

{{< /history >}}

> [!flag]
> この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

マージリクエストでCI/CDパイプラインを修正するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 左側のサイドバーで、**コード** > **マージリクエスト**を選択して、マージリクエストを開きます。
1. パイプラインを修正するには、次のいずれかの方法を使用します:
   - **概要**タブを選択し、失敗しているパイプラインの下にある**Duoでパイプラインを修正**を選択する。
   - **パイプライン**タブを選択し、右端の列にある**Duoでパイプラインを修正**（{{< icon name="tanuki-ai" >}}）を選択する。
   - GitLab Duoサイドバーで、新規または既存のAgentic Chatの会話を開き、Agentic Chatにパイプラインの修正を依頼する。
1. 進捗状況を監視するには、左側のサイドバーで**AI** > **セッション**を選択します。

   Agentic Chatを使用している場合、次の操作もできます:
   - Chatの会話で進捗状況を確認する。
   - 会話で**エージェントセッションを表示**を選択する。

セッションが完了すると、フローはマージリクエストにコード提案を追加するか、実行可能な次のステップについて説明するコメントを投稿します。

## 他のCI/CDパイプラインを修正する {#fix-other-cicd-pipelines}

マージリクエストに関連付けられていないCI/CDパイプラインを修正するには:

1. **ビルド** > **パイプライン**を選択します。
1. 失敗しているパイプラインを選択します。
1. 右上隅で、**Duoでパイプラインを修正**を選択します。
1. 進捗状況を監視するには、**AI** > **セッション**を選択します。

## `AGENTS.md`を使用してフローをカスタマイズする {#use-agentsmd-to-customize-the-flow}

フローは、リポジトリ内の[`AGENTS.md`](../../customize/agents_md.md)ファイルからリポジトリ固有の指示を読み取ります。`AGENTS.md`を使用して、次のような動作をカスタマイズできます:

- フローがコミットする変更のコミットメッセージ形式。
- フローが作成するマージリクエストのラベルや説明などのメタデータ。
- 特定の種類の失敗を分類して処理する方法。
- 同じフローが複数回失敗しないように、同じ種類の繰り返しの失敗をどのように処理するか。

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

例えば、移行の失敗を処理するには:

```markdown
## Migration failures

If a pipeline fails because of a database migration:

- Run `bin/rails db:migrate:status` to check the current migration state before attempting
  a fix.
- Do not edit or delete past migration files.
- If the migration cannot be safely reversed, post a comment describing the issue instead
  of attempting a fix.
```

## 既知の問題 {#known-issues}

- AIゲートウェイは、ジョブログの末尾150 KiBのみを処理します。ジョブから大量の出力が生成される場合、ログの前半にある関連性の高い失敗情報をフローが取得できない可能性があります。回避策については、次のセクションを参照してください。
- フローは、サンドボックス化されたランタイム環境でパッケージのインストールを常に検証できるとは限りません。依存関係が不足している場合、デフォルトのフローイメージをカスタマイズできます。[デフォルトのDockerイメージを変更する](../execution/images.md#change-the-default-docker-image)を参照してください。
- `AGENTS.md`に記載されているリポジトリの指示はフローの動作に影響を与えますが、すべての場合でそれに従うことを保証するものではありません。

## トラブルシューティング {#troubleshooting}

CI/CDパイプライン修正フローを使用する際に、次の問題が発生する可能性があります。

### フローが失敗の根本原因を特定できない {#flow-cannot-identify-the-root-cause-of-a-failure}

フローがパイプラインの失敗の根本原因を特定できない場合があります。

この問題は、ジョブログが150 KiBを超える場合に発生します。AIゲートウェイはジョブログの末尾150 KiBのみを処理するため、ログの前半にある関連性の高い失敗情報を取得できない可能性があります。

この問題を回避するには、次の方法を試してください:

- デバッグログや進捗インジケーターを削除して、詳細な出力を減らす。
- Shellリダイレクト（`> /dev/null`）を使用して、重要でない出力をリダイレクトする。
- スクリプトの最後にサマリーステップを追加し、主要なエラーメッセージを出力する。
- `after_script`を使用して、メインスクリプトの完了後に診断情報を出力する。
- 出力の多いジョブを、ログがより簡潔かつ小規模で目的を絞ったジョブに分割する。

### Duoでパイプラインを修正ボタンが表示されない {#fix-pipeline-with-duo-button-does-not-appear}

[前提条件](#prerequisites)を満たしているにもかかわらず、**Duoでパイプラインを修正**ボタンが表示されません。

この問題は、ボタンが3つの別々のページ（GitLab Duo、Duo Agent Platform、および基本フロー）の設定に依存しているために発生します。あるレベルで有効になっている設定が、その下にあるすべてのレベルで有効であることを保証するものではありません。

この問題を解決するには、各要件を再確認してください:

- [GitLab Duo](../../turn_on_off.md#turn-gitlab-duo-on-or-off)または[GitLab Duo Core](../../turn_on_off.md#turn-gitlab-duo-core-on-or-off)がオンになっていること。
- [Agent Platformがオンになっている](../../turn_on_off.md#turn-gitlab-duo-agent-platform-on-or-off)こと。
- **基本フローを許可**と**CI/CDパイプランの修正**がトップレベルグループでオンになっており、GitLab Self-Managedの場合はインスタンスでオンになっていること。

## フィードバックを提供する {#give-feedback}

チームは、CI/CDパイプライン修正フローの改善に積極的に取り組んでいます。問題を報告したり改善を提案したりするには、[フィードバックイシュー601991](https://gitlab.com/gitlab-org/gitlab/-/work_items/601991)にフィードバックを投稿してください。
