---
stage: AI-powered
group: Code Creation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: AIアシスト機能を使用して、マージリクエストに関する情報を取得します。
title: マージリクエストにおけるGitLab Duo
---

{{< alert type="disclaimer" />}}

GitLab Duoは、マージリクエストのライフサイクル全体を通じて、コンテキストに応じた関連情報を提供するように設計されています。

## コード変更を要約して説明を生成する {#generate-a-description-by-summarizing-code-changes}

{{< details >}}

- プラン: Premium、Ultimate
- アドオン: GitLab Duo Enterprise
- 提供形態: GitLab.com、GitLab Self-Managed
- ステータス: ベータ版

{{< /details >}}

{{< collapsible title="モデル情報" >}}

- LLM: Anthropic [Claude 4.0 Sonnet](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-sonnet-4)
- [セルフホストモデル対応のGitLab Duo](../../../administration/gitlab_duo_self_hosted/_index.md)で利用可能

{{< /collapsible >}}

{{< history >}}

- GitLab 16.2で[実験的機能](../../../policy/development_stages_support.md#experiment)として[導入](https://gitlab.com/groups/gitlab-org/-/epics/10401)されました。
- GitLab 16.10でベータ版に[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/429882)されました。
- GitLab 17.6以降、GitLab Duoアドオンが必須となりました。
- LLMは、GitLab 17.10でClaude 3.7 Sonnetに[更新](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/186862)されました
- 機能フラグ`add_ai_summary_for_new_mr`は、GitLab 17.11で[デフォルトで有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/186108)になっています。
- GitLab 18.0でPremiumを含むように変更されました。
- LLMは、GitLab 18.1でClaude 4.0 Sonnetに[更新](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/193208)されました。

{{< /history >}}

マージリクエストを作成または編集する際に、GitLab Duoマージリクエストサマリーを使用してマージリクエストの説明を作成します。

1. [新しいマージリクエストを作成します](creating_merge_requests.md)。
1. **説明**フィールドで、説明を挿入したい場所にカーソルを置きます。
1. テキストエリア上部のツールバーで、**コード変更のサマリー**（{{< icon name="tanuki-ai" >}}）を選択します。

   ![テキストエリア上部ツールバーで、「コード変更のサマリー」ボタンが表示されます。](img/merge_request_ai_summary_v17_6.png)

カーソルがあった場所に説明が挿入されます。

<i class="fa-youtube-play" aria-hidden="true"></i> [概要を見る](https://www.youtube.com/watch?v=CKjkVsfyFd8&list=PLFGfElNsQthZGazU1ZdfDpegu0HflunXW)

[イシュー443236](https://gitlab.com/gitlab-org/gitlab/-/issues/443236)で、この機能に関するフィードバックをお寄せください。

データ使用: ソースブランチのヘッドとターゲットブランチ間の変更差分が、大規模言語モデルに送信されます。

## GitLab Duoを使用してコードレビューをする {#use-gitlab-duo-to-review-your-code}

GitLab Duoは、マージリクエストをレビューし、潜在的なエラーを検出したり、標準への適合性に関するフィードバックを提供します。

`@GitLabDuo`にレビューをリクエストすると、次のいずれかの機能が実行されます:

- [Code Review Flow](../../duo_agent_platform/flows/foundational_flows/code_review.md): GitLab Duo Agent Platformを通じて利用できる新しいフロー。GitLabクレジットを使用します。
- [GitLab Duo Code Review (Classic)](../../gitlab_duo/code_review_classic.md): 従来のコードレビュー機能。

実行されるレビュー機能は、GitLab Duoレビューを開始するユーザーのアドオンによって異なります:

- 手動レビューリクエスト: レビューをリクエストするユーザー。
- 自動レビュー: マージリクエストの作成者であるユーザー。
- ドラフトで開始するマージリクエスト: MRを準備完了としてマークするユーザー。

レビュー機能はリクエスト元のユーザーのアドオンに基づいているため、両方の機能が同じプロジェクトで実行できます。

### レビュー機能の比較 {#how-the-review-features-compare}

両方のレビュー機能を同じように操作できますが、Code Review FlowはGitLab Duo Code Review (Classic)と比較して、機能が強化されています:

- コンテキスト認識の向上: リポジトリ構造やファイル間の依存関係をより正確に把握します。
- エージェント型機能: より徹底的な分析を行うための多段階推論をサポートします。
- 最新のアーキテクチャ: スケーラブルなGitLab Duo Agent Platform上に構築されています。

どちらの機能も、自動レビュー、カスタム指示、およびカスタムコメントをサポートしています。

## コードレビューを要約する {#summarize-a-code-review}

{{< details >}}

- プラン: Premium、Ultimate
- アドオン: GitLab Duo Enterprise
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- ステータス: 実験的機能

{{< /details >}}

{{< collapsible title="モデル情報" >}}

- LLM: Anthropic [Claude 4.0 Sonnet](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-sonnet-4)
- [セルフホストモデル対応のGitLab Duo](../../../administration/gitlab_duo_self_hosted/_index.md)で利用可能

{{< /collapsible >}}

{{< history >}}

- GitLab 16.0で[実験的機能](../../../policy/development_stages_support.md#experiment)として[導入](https://gitlab.com/groups/gitlab-org/-/epics/10466)されました。
- 機能フラグ`summarize_my_code_review`は、GitLab 17.10で[デフォルトで有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/182448)になっています。
- LLMは、GitLab 17.11でClaude 3.7 Sonnetに[更新](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/183873)されました。
- GitLab 18.0でPremiumを含むように変更されました。
- LLMは、GitLab 18.1でClaude 4.0 Sonnetに[更新](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/193685)されました。

{{< /history >}}

マージリクエストのレビューを完了し、[レビューを送信](reviews/_index.md#submit-a-review)する準備ができたら、GitLab Duoコードレビューサマリーを使用してコメントのサマリーを生成します。

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 左側のサイドバーで、**コード** > **マージリクエスト**を選択し、レビューするマージリクエストを見つけます。
1. レビューを送信する準備ができたら、**レビューを終了**を選択します。
1. **サマリーを追加**を選択します。

サマリーはコメントボックスに表示されます。レビューを送信する前に、サマリーを編集して改善することができます。

<i class="fa-youtube-play" aria-hidden="true"></i> [概要を見る](https://www.youtube.com/watch?v=Bx6Zajyuy9k)

[イシュー408991](https://gitlab.com/gitlab-org/gitlab/-/issues/408991)で、この実験的機能に関するフィードバックをお寄せください。

データ使用: この機能を使用すると、次のデータが大規模言語モデルに送信されます: 

- ドラフトコメントのテキスト

## マージコミットメッセージを生成する {#generate-a-merge-commit-message}

{{< details >}}

- プラン: Premium、Ultimate
- アドオン: GitLab Duo Enterprise、GitLab Duo with Amazon Q
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< collapsible title="モデル情報" >}}

- LLM: Anthropic [Claude 4.0 Sonnet](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-sonnet-4)
- Amazon QのLLM: Amazon Q Developer
- [セルフホストモデル対応のGitLab Duo](../../../administration/gitlab_duo_self_hosted/_index.md)で利用可能

{{< /collapsible >}}

{{< history >}}

- GitLab 16.2で`generate_commit_message_flag`[フラグ](../../../administration/feature_flags/_index.md)とともに[実験的機能](../../../policy/development_stages_support.md#experiment)として[導入](https://gitlab.com/groups/gitlab-org/-/epics/10453)されました。デフォルトでは無効になっています。
- 機能フラグ`generate_commit_message_flag`は、GitLab 17.2で[デフォルトで有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/158339)になっています。
- 機能フラグ`generate_commit_message_flag`は、GitLab 17.7で[削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/173262)されました。
- GitLab 18.0でPremiumを含むように変更されました。
- LLMは、GitLab 18.1でClaude 4.0 Sonnetに[更新](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/193793)されました。
- GitLab 18.3でAmazon Qのサポートに変更されました。

{{< /history >}}

マージリクエストをマージする準備をするときは、GitLab Duoマージコミットメッセージ生成を使用して、提案されたマージコミットメッセージを編集します。

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 左側のサイドバーで、**コード** > **マージリクエスト**を選択し、マージリクエストを見つけます。
1. マージウィジェットで**コミットメッセージを編集**チェックボックスを選択します。
1. **コミットメッセージを生成**を選択します。
1. 提供されたコミットメッセージをレビューし、**挿入**を選択してコミットに追加します。

<i class="fa-youtube-play" aria-hidden="true"></i> [概要を見る](https://www.youtube.com/watch?v=fUHPNT4uByQ)

データ使用: この機能を使用すると、次のデータが大規模言語モデルに送信されます: 

- ファイルの内容
- ファイル名

## 関連トピック {#related-topics}

- [GitLab Duoの可用性を制御する](../../gitlab_duo/turn_on_off.md)
- [GitLab Duo機能すべて](../../gitlab_duo/_index.md)

## トラブルシューティング {#troubleshooting}

マージリクエストでGitLab Duoを使用する場合、次の問題が発生する可能性があります。

### 応答がない {#response-not-received}

`@GitLabDuo`にメンションまたは返信してGitLab Duoにレビューをリクエストしても応答がない場合は、適切なGitLab Duoアドオンがないことが原因である可能性があります。

GitLab Duoアドオンを確認するには、グループの[GitLab Duoシートの割り当て](../../../subscriptions/subscription-add-ons.md#view-assigned-gitlab-duo-users)を確認するようグループオーナーに依頼してください。

GitLab Duoアドオンを変更するには、管理者にお問い合わせください。

### GitLab Duoをレビューに割り当てることができない {#unable-to-assign-gitlab-duo-to-review}

GitLab Duoをレビュアーとして割り当てることができない場合は、適切なGitLab Duoアドオンがないことが原因である可能性があります。

GitLab Duoアドオンを確認するには、グループの[GitLab Duoシートの割り当て](../../../subscriptions/subscription-add-ons.md#view-assigned-gitlab-duo-users)を確認するようグループオーナーに依頼してください。

GitLab Duoアドオンを変更するには、管理者にお問い合わせください。

### エラー: `GitLab Duo Code Review was not automatically added...` {#error-gitlab-duo-code-review-was-not-automatically-added}

GitLab Duoからの自動レビューをオンにしてマージリクエストを作成しようとすると、次のエラーメッセージが表示される場合があります:

```plaintext
GitLab Duo Code Review was not automatically added because your account requires
GitLab Duo Enterprise. Contact your administrator to upgrade your account.
```

管理者に連絡して、[GitLab Duo Enterpriseシートを購入](../../../subscriptions/subscription-add-ons.md#purchase-gitlab-duo)し、自分に割り当てるよう依頼してください。
