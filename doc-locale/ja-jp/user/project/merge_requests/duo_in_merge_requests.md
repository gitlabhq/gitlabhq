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

GitLab Duoは、潜在的なエラーがないかマージリクエストをレビューし、規格への整合性に関するフィードバックを提供します。

次のいずれかの方法で、GitLab Duoをレビュアーとして追加します:

- GitLab Duoコードレビュー（クラシック）: 従来のコードレビュー機能。
- コードレビューフロー: GitLab Duo Agent Platformを介して利用できる新しいフロー。コンテキスト認識型が向上し、エージェント型機能を提供します。

2つのオプションには、異なる要件と前提条件があります。ただし、レビューをリクエストしてGitLab Duoを操作する方法は同じです。どちらのオプションも、自動レビュー、カスタム手順、カスタムコメントをサポートしています。

### GitLab Duoコードレビュー（クラシック） {#gitlab-duo-code-review-classic}

{{< details >}}

- プラン: Premium、Ultimate
- アドオン: GitLab Duo Enterprise
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< collapsible title="モデル情報" >}}

- LLM: Anthropic [Claude 4.0 Sonnet](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-sonnet-4)
- [セルフホストモデル対応のGitLab Duo](../../../administration/gitlab_duo_self_hosted/_index.md)で利用可能

{{< /collapsible >}}

{{< history >}}

- GitLab 17.5で、[実験的機能](../../../policy/development_stages_support.md#experiment)として、2つの機能フラグ[`ai_review_merge_request`](https://gitlab.com/gitlab-org/gitlab/-/issues/456106)と[`duo_code_review_chat`](https://gitlab.com/gitlab-org/gitlab/-/issues/508632)の背後で[導入](https://gitlab.com/groups/gitlab-org/-/epics/14825)されました。両方ともデフォルトで無効になっています。
- 機能フラグ[`ai_review_merge_request`](https://gitlab.com/gitlab-org/gitlab/-/issues/456106)および[`duo_code_review_chat`](https://gitlab.com/gitlab-org/gitlab/-/issues/508632)は、17.10のGitLab.com、GitLab Self-Managed、GitLab Dedicatedでデフォルトで有効になっています。
- GitLab 17.10でベータ版に[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/516234)されました。
- GitLab 18.0でPremiumを含むように変更されました。
- 機能フラグ`ai_review_merge_request`は、GitLab 18.1で[削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/190639)されました。
- 機能フラグ`duo_code_review_chat`は、GitLab 18.1で[削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/190640)されました。
- GitLab 18.1で一般提供となりました。
- GitLab 18.3でセルフホストモデル対応のGitLab Duoでベータ版として利用可能に[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/524929)されました。
- GitLab 18.4でセルフホストモデル対応のGitLab Duoで一般提供に[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/548975)されました。

{{< /history >}}

マージリクエストをレビューする準備ができたら、GitLab Duoコードレビュー（クラシック）を使用して最初のレビューを実行します:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **コード** > **マージリクエスト**を選択して、マージリクエストを見つけます。
1. コメントボックスに、クイックアクション`/assign_reviewer @GitLabDuo`を入力するか、GitLab Duoをレビュアーとして割り当てます。

<i class="fa-youtube-play" aria-hidden="true"></i> [概要を見る](https://www.youtube.com/watch?v=SG3bhD1YjeY&list=PLFGfElNsQthZGazU1ZdfDpegu0HflunXW&index=2)

イシュー[517386](https://gitlab.com/gitlab-org/gitlab/-/issues/517386)で、この機能に関するフィードバックをお寄せください。

データ使用: この機能を使用すると、次のデータが大規模言語モデルに送信されます: 

- マージリクエストのタイトル
- マージリクエストの説明
- 変更が適用される前のファイルの内容（コンテキスト用）
- マージリクエストの差分
- ファイル名
- [カスタム指示](#customize-review-instructions-for-gitlab-duo)

### コードレビューフロー {#code-review-flow}

{{< details >}}

- プラン: Premium、Ultimate
- アドオン: GitLab Duo CoreまたはPro
- 提供形態: GitLab.com、GitLab Self-Managed

{{< /details >}}

{{< collapsible title="モデル情報" >}}

- LLM: Anthropic [Claude 4.0 Sonnet](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-sonnet-4)
- [セルフホストモデル対応のGitLab Duo](../../../administration/gitlab_duo_self_hosted/_index.md)で利用可能

{{< /collapsible >}}

{{< history >}}

- [ベータ](../../../policy/development_stages_support.md)として導入されました。GitLab [18.6](https://gitlab.com/groups/gitlab-org/-/epics/18645) `duo_code_review_on_agent_platform`という名前の[フラグを使用](../../../administration/feature_flags/_index.md)。デフォルトでは無効になっています。
- 機能フラグ`duo_code_review_on_agent_platform`は、GitLab 18.8で[削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/217209)されました。
- GitLab 18.8で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/work_items/585273)。

{{< /history >}}

コードレビューフローは、GitLab Duo Agent Platformを介して利用でき、エージェント型を使用してレビュー機能を強化します。

フローを有効にすると、GitLab Duoをレビュアーとして割り当てることができます。

設定と要件については、[Code Review Flow](../../duo_agent_platform/flows/foundational_flows/code_review.md)を参照してください。

### レビューでGitLab Duoと対話する {#interact-with-gitlab-duo-in-reviews}

コメントで`@GitLabDuo`をメンションして、マージリクエストでGitLab Duoと対話できます。レビューコメントに関するフォローアップの質問をしたり、マージリクエストのディスカッションスレッドで質問したりできます。

GitLab Duoとの対話は、マージリクエストの改善に取り組む際に、提案やフィードバックの向上に役立ちます。

GitLab Duoに提供されたフィードバックは、他のマージリクエストのその後のレビューには影響しません。この機能を追加するリクエストがあります。[イシュー560116](https://gitlab.com/gitlab-org/gitlab/-/issues/560116)を参照してください。

### プロジェクトのGitLab Duoによる自動レビュー {#automatic-reviews-from-gitlab-duo-for-a-project}

{{< history >}}

- GitLab 18.0でUI設定に[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/506537)されました。

{{< /history >}}

GitLab Duoの自動レビューにより、プロジェクト内のすべてのマージリクエストが初期レビューを受けるようになります。マージリクエストが作成されると、次の場合を除き、GitLab Duoがレビューします: 

- ドラフトとしてマークされている場合。GitLab Duoにマージリクエストをレビューさせるには、準備完了とマークします。
- 変更が含まれていない場合。GitLab Duoにマージリクエストをレビューさせるには、変更を追加します。

前提条件: 

- プロジェクトの[メンテナーロール](../../permissions.md)以上が必要です。

`@GitLabDuo`がマージリクエストを自動的にレビューできるようにするには: 

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **マージリクエスト**を選択します。
1. **GitLab Duoコードレビュー**セクションで、**GitLab Duoによる自動レビューを有効にする**を選択します。
1. **変更を保存**を選択します。

### グループとアプリケーションのGitLab Duoによる自動レビュー {#automatic-reviews-from-gitlab-duo-for-groups-and-applications}

{{< history >}}

- GitLab 18.4で`cascading_auto_duo_code_review_settings`[機能フラグ](../../../administration/feature_flags/_index.md)とともに[ベータ版](../../../policy/development_stages_support.md#beta)として[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/554070)されました。デフォルトでは無効になっています。
- 機能フラグ`cascading_auto_duo_code_review_settings`は、GitLab 18.7で[削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/213240)されました。

{{< /history >}}

グループまたはアプリケーションの設定を使用して、複数のプロジェクトで自動レビューを有効にします。

前提条件: 

- グループの自動レビューをオンにするには、グループのオーナーロールが必要です。
- すべてのプロジェクトの自動レビューをオンにするには、管理者である必要があります。

グループの自動レビューを有効にするには: 

1. 上部のバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定** > **一般**を選択します。
1. **マージリクエスト**セクションを展開します。
1. **GitLab Duoコードレビュー**セクションで、**GitLab Duoによる自動レビューを有効にする**を選択します。
1. **変更を保存**を選択します。

すべてのプロジェクトで自動レビューを有効にするには: 

1. 右上隅で、**管理者**を選択します。
1. **設定** > **一般**を選択します。
1. **GitLab Duoコードレビュー**セクションで、**GitLab Duoによる自動レビューを有効にする**を選択します。
1. **変更を保存**を選択します。

設定は、アプリケーションからグループ、プロジェクトへとカスケードします。より具体的な設定は、より広範な設定をオーバーライドします。

### GitLab Duoのレビュー手順をカスタマイズする {#customize-review-instructions-for-gitlab-duo}

プロジェクトで一貫性のある特定のコードレビュー標準を確保するために、カスタムMRレビュー手順を作成できます。

GitLab Duoコードレビュー（クラシック）とコードレビューフローはどちらも、カスタムコードレビュー手順をサポートしています。

詳細については、[GitLab Duoのレビュー手順のカスタマイズ](../../../user/gitlab_duo/customize_duo/review_instructions.md)を参照してください

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
1. **コード** > **マージリクエスト**を選択して、レビューするマージリクエストを見つけます。
1. レビューを送信する準備ができたら、**レビューを終了**を選択します。
1. **サマリーを追加**を選択します。

サマリーはコメントボックスに表示されます。レビューを送信する前に、サマリーを編集して改善することができます。

<i class="fa-youtube-play" aria-hidden="true"></i> [概要を見る](https://www.youtube.com/watch?v=Bx6Zajyuy9k)

[イシュー408991](https://gitlab.com/gitlab-org/gitlab/-/issues/408991)で、この実験的機能に関するフィードバックをお寄せください。

データ使用: この機能を使用すると、次のデータが大規模言語モデルに送信されます: 

- 下書きコメントのテキスト

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
1. **コード** > **マージリクエスト**を選択して、マージリクエストを見つけます。
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

マージリクエストでGitLab Duoを使用しているときに、次の問題が発生する可能性があります。

### 応答が受信されない {#response-not-received}

`@GitLabDuo`に言及または返信してGitLab Duoにレビューをリクエストしても応答がない場合は、適切なGitLab Duoアドオンがないことが原因である可能性があります。

GitLab Duoアドオンを確認するには、グループのオーナーにグループの[GitLab Duoシートの割り当て](../../../subscriptions/subscription-add-ons.md#view-assigned-gitlab-duo-users)を確認するように依頼してください。

GitLab Duoアドオンを変更するには、管理者にお問い合わせください。

### レビューにGitLab Duoを割り当てることができません {#unable-to-assign-gitlab-duo-to-review}

GitLab Duoをレビュアーとして割り当てることができない場合は、適切なGitLab Duoアドオンがないことが原因である可能性があります。

GitLab Duoアドオンを確認するには、グループのオーナーにグループの[GitLab Duoシートの割り当て](../../../subscriptions/subscription-add-ons.md#view-assigned-gitlab-duo-users)を確認するように依頼してください。

GitLab Duoアドオンを変更するには、管理者にお問い合わせください。

### エラー: `GitLab Duo Code Review was not automatically added...` {#error-gitlab-duo-code-review-was-not-automatically-added}

GitLab Duoからの自動レビューをオンにしてマージリクエストを作成しようとすると、次のエラーメッセージが表示される場合があります:

```plaintext
GitLab Duo Code Review was not automatically added because your account requires
GitLab Duo Enterprise. Contact your administrator to upgrade your account.
```

管理者に連絡して、[GitLab Duo Enterpriseシートを購入](../../../subscriptions/subscription-add-ons.md#purchase-gitlab-duo)し、割り当てるように依頼してください。
