---
stage: AI Coding
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: AIアシスト機能を使用して、マージリクエストに関する情報を取得します。
title: マージリクエストにおけるGitLab Duo
---

> [!disclaimer]

GitLab Duoは、マージリクエストのライフサイクル全体を通じて、コンテキストに応じた関連情報を提供するように設計されています。

## コード変更を要約して説明を生成する {#generate-a-description-by-summarizing-code-changes}

{{< details >}}

- プラン: Premium、Ultimate
- アドオン: GitLab Duo Enterprise
- 提供形態: GitLab.com、GitLab Self-Managed
- ステータス: ベータ版

{{< /details >}}

{{< collapsible title="モデル情報" >}}

- [デフォルトLLM](../../gitlab_duo/model_selection.md#default-models)
- [セルフホストモデル対応のGitLab Duo](../../../administration/gitlab_duo_self_hosted/_index.md)で利用可能

{{< /collapsible >}}

{{< history >}}

- GitLab 16.2で[実験的機能](../../../policy/development_stages_support.md#experiment)として[導入](https://gitlab.com/groups/gitlab-org/-/epics/10401)されました。
- GitLab 16.10でベータ版に[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/429882)されました。
- GitLab 17.6以降、GitLab Duoアドオンが必須になりました。
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

## GitLab Duoを使用してコードをレビューする {#use-gitlab-duo-to-review-your-code}

GitLab Duoは、マージリクエストをレビューし、潜在的なエラーを検出したり、標準への適合性に関するフィードバックを提供します。

GitLab Duoにレビューをリクエストすると、使用しているアドオンに応じて、2つのコードレビュー機能のいずれかが自動的に実行されます。グループのオーナーロールを持つユーザーは、すべてのユーザーに対してどちらの機能を実行するかを設定できます。

| 詳細              | [コードレビューフロー](../../duo_agent_platform/flows/foundational_flows/code_review/_index.md) | [GitLab Duoコードレビュー](../../gitlab_duo/code_review.md) |
|---------------------|--------------------------------------------------------------------------------------|-----------------------------------------------------------|
| レビュアー            | `@GitLabDuo`                                                                         | `@GitLabDuo`                                              |
| タイプ                | エージェント型                                                                              | 非エージェント型                                               |
| 必須アドオン     | なし。GitLabクレジットを使用します。                                                           | GitLab Duo Enterprise                                     |
| コンテキスト認識   | リポジトリ構造とファイル間の依存関係をより高度に理解           | マージリクエストと、その中のファイルの差分に重点を置く |
| 分析            | 複数ステップのエージェント型推論                                                         | 単一パス                                               |
| セッション作成    | {{< yes >}}                                                                          | {{< no >}}                                                |
| 自動レビュー   | {{< yes >}}                                                                          | {{< yes >}}                                               |
| カスタム指示 | {{< yes >}}                                                                          | {{< yes >}}                                               |
| カスタムコメント     | {{< yes >}}                                                                          | {{< yes >}}                                               |

### 実行するレビュー機能を決定する {#determine-which-review-feature-runs}

デフォルトでは、GitLabが実行するコードレビュー機能は、レビューを開始したユーザーによって決まります。

| レビューのトリガー                          | 開始ユーザー                      |
|-----------------------------------------|--------------------------------------|
| レビューを手動でリクエスト               | レビューをリクエストしたユーザー。    |
| マージリクエストを作成（ドラフトではない）     | マージリクエストの作成者。            |
| ドラフトのマージリクエストを準備完了としてマーク     | マージリクエストの作成者。            |

開始ユーザーにGitLab Duo Enterpriseシートが割り当てられている場合、GitLab Duoコードレビューが実行されます。割り当てられていない場合、コードレビューフローが実行されます。同じプロジェクトで両方の機能を実行できます。

グループのオーナーロールを持つユーザーは、シートの種類に関係なく、[すべてのレビューでコードレビューフローを使用するように設定](#turn-on-code-review-flow-for-gitlab-duo-enterprise-seats)できます。コードレビューフローが実行された場合、GitLabクレジットの使用量は開始ユーザーに帰属します。

レビューを実行した機能を確認するには、マージリクエストのアクティビティフィードを確認します。コードレビューフローが実行されると、レビューセッションが開始されます。レビューセッションが表示されない場合は、GitLab Duoコードレビューによってレビューが実行されています。

![GitLab Duoによって開始されたレビューセッションが表示されているマージリクエストのアクティビティフィード。](img/gitlab_duo_code_review_flow_session_v18_10.png)

レビューの完了後、[プロジェクトのセッション](../../duo_agent_platform/sessions/_index.md#view-sessions-for-your-project)でコードレビューフローセッションを確認することもできます。

#### GitLab Duo Enterpriseシートでコードレビューフローをオンにする {#turn-on-code-review-flow-for-gitlab-duo-enterprise-seats}

{{< history >}}

- GitLab 19.2で`duo_code_review_dap_routing_consent_enabled`[機能フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/240432)されました。デフォルトでは有効になっています。
- GitLab 19.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/602689)になりました。機能フラグ`duo_code_review_dap_routing_consent_enabled`は削除されました。

{{< /history >}}

GitLab Duo Enterpriseシートの所有者がGitLabクレジットを消費する機能を使用しないようにするため、これらのユーザーが開始するすべてのコードレビューでは、デフォルトでGitLab Duoコードレビューを使用します。この動作は、オーナーロールを持つユーザーがグループに対してコードレビューフローをオンにしている場合でも適用されます。

このデフォルトを変更して、ユーザーのシートに関係なく、すべてのコードレビューでコードレビューフローを使用するように設定できます。

GitLab Duo Enterpriseシートのデフォルトのコードレビュー機能をオーバーライドするには:

{{< tabs >}}

{{< tab title="GitLab.com" >}}

前提条件: 

- トップレベルグループのオーナーロール。
- トップレベルグループに対して[コードレビューフロー](../../duo_agent_platform/flows/foundational_flows/code_review/_index.md#prerequisites)がオンになっており、正しく設定されている。

1. 上部のバーで**検索または移動先**を選択して、トップレベルグループを見つけます。
1. **設定** > **GitLab Duo**を選択します。
1. **設定の変更**を選択します。
1. **フローの実行** > **基本フローを許可**で、**コードレビューフロー**チェックボックスをオフにしてから、もう一度オンにします。
1. 確認ダイアログで、**コードレビューフローを有効にする**を選択します。

{{< /tab >}}

{{< tab title="GitLab Self-ManagedおよびGitLab Dedicated" >}}

前提条件: 

- グループのメンテナーまたはオーナーのロール。
- インスタンスに対して[コードレビューフロー](../../duo_agent_platform/flows/foundational_flows/code_review/_index.md#prerequisites)がオンになっており、正しく設定されている。

1. 上部のバーで、**検索または移動先**を選択して、グループまたはサブグループを見つけます。
1. **設定** > **一般**を選択します。
1. **GitLab Duoの機能**を展開します。
1. **フローの実行**で、**コードレビューフロー**チェックボックスをオフにし、**変更を保存**を選択します。
1. もう一度**GitLab Duoの機能**を展開し、**フローの実行**で、**コードレビューフロー**チェックボックスをオンにします。
1. 確認ダイアログで、**コードレビューフローを有効にする**を選択します。
1. **変更を保存**を選択します。

{{< /tab >}}

{{< /tabs >}}

これで、グループ内のすべてのコードレビューでコードレビューフローが実行され、GitLabクレジットが消費されます。すべてのレビューをGitLab Duoコードレビューに戻すには、コードレビューフローをオフにします。

## GitLab Duoでディスカッションを解決する {#resolve-a-discussion-with-gitlab-duo}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 19.2で`resolve_discussion_with_duo`[機能フラグ](../../../administration/feature_flags/_index.md)とともに[ベータ版](../../../policy/development_stages_support.md)として[導入](https://gitlab.com/gitlab-org/gitlab/-/work_items/600990)されました。デフォルトでは有効になっています。
- GitLab 19.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/work_items/603482)になりました。

{{< /history >}}

> [!flag]
> この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

GitLab Duoを使用して、マージリクエストのレビューディスカッションを解決します。

GitLab Duoにディスカッションの解決を依頼すると、レビューコメントとその周辺のコードを読み取り、ソースブランチにリクエストされた変更を加えて、その変更をコミットおよびプッシュします。その後、GitLab Duoは変更のサマリーをディスカッションに返信し、スレッドを解決します。

この機能では、[GitLab Duo Agent Platform](../../duo_agent_platform/_index.md)のデベロッパーフローを使用します。

前提条件: 

- プロジェクトのデベロッパー、メンテナー、またはオーナーロール。
- [GitLab Duo Agent Platformの前提条件](../../duo_agent_platform/_index.md#prerequisites)。
- [トップレベルグループ](../../duo_agent_platform/flows/foundational_flows/_index.md#turn-foundational-flows-on-or-off)で、**基本フローを許可**と**デベロッパー**を有効にしている。
- [サービスアカウントを許可するようにプッシュルールを設定している](../../duo_agent_platform/troubleshooting.md#configure-push-rules-to-allow-a-service-account)。
- [独自のRunnerを設定](../../duo_agent_platform/flows/execution/_index.md#configure-runners-to-execute-flows)しているか、プロジェクトで[GitLabホストRunner](../../../ci/runners/hosted_runners/_index.md)をオンにしている。

GitLab Duoでディスカッションを解決するには:

1. マージリクエストで、未解決のディスカッションに移動します。
1. **スレッドを解決**の横にある**その他の解決オプション**（{{< icon name="chevron-down" >}}）を選択します。
1. **GitLab Duoで解決**を選択します。

GitLab Duoによってセッションが開始されます。このセッションは、[プロジェクトのセッション](../../duo_agent_platform/sessions/_index.md#view-sessions-for-your-project)で追跡できます。

## コードレビューのサマリーを生成する {#summarize-a-code-review}

{{< details >}}

- プラン: Premium、Ultimate
- アドオン: GitLab Duo Enterprise
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- ステータス: 実験的機能

{{< /details >}}

{{< collapsible title="モデル情報" >}}

- [デフォルトLLM](../../gitlab_duo/model_selection.md#default-models)
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

- [デフォルトLLM](../../gitlab_duo/model_selection.md#default-models)
- Amazon QのLLM: Amazon Q Developer
- [セルフホストモデル対応のGitLab Duo](../../../administration/gitlab_duo_self_hosted/_index.md)で利用可能

{{< /collapsible >}}

{{< history >}}

- GitLab 16.2で`generate_commit_message_flag`[機能フラグ](../../../administration/feature_flags/_index.md)とともに[実験的機能](../../../policy/development_stages_support.md#experiment)として[導入](https://gitlab.com/groups/gitlab-org/-/epics/10453)されました。デフォルトでは無効になっています。
- 機能フラグ`generate_commit_message_flag`は、GitLab 17.2で[デフォルトで有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/158339)になっています。
- 機能フラグ`generate_commit_message_flag`は、GitLab 17.7で[削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/173262)されました。
- GitLab 18.0でPremiumを含むように変更されました。
- LLMは、GitLab 18.1でClaude 4.0 Sonnetに[更新](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/193793)されました。
- GitLab 18.3でAmazon Qのサポートに変更されました。

{{< /history >}}

マージリクエストをマージする準備をするときは、GitLab Duoマージコミットメッセージ生成を使用して、提案されたマージコミットメッセージを編集します。

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 左側のサイドバーで、**コード** > **マージリクエスト**を選択して、マージリクエストを見つけます。
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
- [GitLab Duoでマージコンフリクトを解決する](conflicts.md#resolve-conflicts-with-gitlab-duo)

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
