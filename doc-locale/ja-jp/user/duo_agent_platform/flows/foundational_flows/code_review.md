---
stage: AI Coding
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: コードレビューフロー
---

{{< details >}}

- プラン: [Free](../../../../subscriptions/gitlab_credits.md#for-the-free-tier)、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< collapsible title="モデル情報" >}}

- LLM: Anthropic Claude Sonnet 4.6 Vertex
- [別のモデルを選択](../../model_selection.md)するには、**エージェント型コードレビュー**設定を使用します。
- [セルフホストモデル対応のGitLab Duo](../../../../administration/gitlab_duo_self_hosted/_index.md)で利用可能

{{< /collapsible >}}

{{< history >}}

- GitLab [18.7](https://gitlab.com/groups/gitlab-org/-/epics/18645)で`duo_code_review_on_agent_platform`[機能フラグ](../../../../administration/feature_flags/_index.md)とともに[ベータ版](../../../../policy/development_stages_support.md)として導入されました。デフォルトでは無効になっています。
- GitLab 18.8で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/work_items/585273)になりました。機能フラグ`duo_code_review_on_agent_platform`は[削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/217209)されました。
- GitLab 18.10で、GitLab.comのFreeプランにおいてGitLabクレジットを使用して利用できるようになりました。
- GitLabバージョン19.1で、LLMがClaude Sonnet 4.6 Vertexに[更新](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/236876)されました。

{{< /history >}}

> [!note]
> アドオンとグループの設定に応じて、GitLabでは以下の2つのコードレビュー機能のいずれかが実行されます:
>
> - コードレビューフロー: GitLab Duo Agent Platformの一部であるエージェント型バージョン。
> - GitLab Duoコードレビュー: GitLab Duo Enterpriseアドオンを使用するユーザーのみが利用できる非エージェント型バージョン。
>
> このページでは、エージェント型バージョンについて説明します。
>
> この2つの機能の比較、およびGitLab Duo Enterpriseシートでコードレビューフローをオンにする方法の詳細については、[GitLab Duoを使用してコードをレビューする](../../../project/merge_requests/duo_in_merge_requests.md#use-gitlab-duo-to-review-your-code)を参照してください。

コードレビューフローを使用すると、エージェント型AIによってコードレビューを効率化できます。

このフローでは次のことができます:

- コードの変更を分析する。
- リポジトリ構造やファイル間の依存関係を踏まえて、より高度にコンテキストを理解する。
- 実行可能なフィードバックを含む、詳細なレビューコメントを提供する。
- プロジェクトに合わせて調整されたカスタムレビュー指示をサポートする。

このフローはGitLab UIでのみ使用できます。

## 前提条件 {#prerequisites}

- [GitLab Duo Agent Platformの前提条件](../../_index.md#prerequisites)を満たしていること。
- [トップレベルグループ](_index.md#turn-foundational-flows-on-or-off)で、**基本フローを許可**と**コードレビュー**をオンにしている。
- プロジェクトのデベロッパー、メンテナー、またはオーナーロールを持っている。
- 複数のGitLab Duoネームスペースに属している場合は、[デフォルトのGitLab Duoネームスペースを設定](../../../profile/preferences.md#set-a-default-gitlab-duo-namespace)している。
- `gitlab--duo`タグとDockerイメージをサポートするexecutorを使用する[独自のRunnerを設定](../execution/_index.md#configure-runners-to-execute-flows)するか、プロジェクトで[GitLabホストRunner](../../../../ci/runners/hosted_runners/_index.md)をオンにしている。コードレビューフローはCI/CDジョブとして実行されるため、実行にはRunnerが必要です。

## フローを使用する {#use-the-flow}

{{< history >}}

- GitLab 19.2で、GitLab Duo Agentic Chatの会話においてフローを使用する機能が`agentic_foundational_flow_tool`[機能フラグ](../../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/groups/gitlab-org/-/work_items/20484)されました。デフォルトでは有効になっています。

{{< /history >}}

> [!flag]
> この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

マージリクエストでコードレビューフローを使用するには:

1. 左側のサイドバーで、**コード** > **マージリクエスト**を選択して、マージリクエストを見つけます。
1. 次のいずれかの方法でレビューをリクエストします:
   - `@GitLabDuo`をレビュアーとして割り当てる。
   - コメントボックスに、クイックアクション`/assign_reviewer @GitLabDuo`を入力する。
   - コメントボックスで`@GitLabDuo`をメンションし、レビューをリクエストする。
   - GitLab Duoサイドバーで、新規または既存のAgentic Chatの会話を開き、Agentic Chatにマージリクエストのレビューを依頼する。
1. 進捗状況を監視するには、左側のサイドバーで**AI** > **セッション**を選択します。

   Agentic Chatを使用している場合、次の操作もできます:
   - Chatの会話で進捗状況を確認する。
   - 会話で**エージェントセッションを表示**を選択する。

## レビューでGitLab Duoとやり取りする {#interact-with-gitlab-duo-in-reviews}

{{< history >}}

- GitLab 19.1で、コメントでのやり取りはGitLab Duo Agent Platformを使用するように[更新](https://gitlab.com/gitlab-org/gitlab/-/work_items/601102)されました。

{{< /history >}}

レビュアーとしてGitLab Duoを割り当てるだけでなく、次の方法でGitLab Duoとやり取りできます:

- レビューコメントに返信して、説明や別のアプローチを求める。
- ディスカッションスレッドで`@GitLabDuo`をメンションし、フォローアップの質問を行う。

コメントでのGitLab Duoとのディスカッションは、GitLab Duo Agent Platformを使用し、[クレジットを消費](../../../../subscriptions/gitlab_credits.md)します。

GitLab Duoに提供したフィードバックは、他のマージリクエストの以降のレビューには影響しません。この機能の追加は[イシュー560116](https://gitlab.com/gitlab-org/gitlab/-/issues/560116)で提案されています。

## コンテキスト認識 {#contextual-awareness}

コードレビューフローは、次の2つのステージで実行されます:

1. プレスキャン: このフローはマージリクエストの差分を調べ、それを使用して、プロジェクトリポジトリからフェッチする関連コンテキストを特定します。プレスキャンには通常、ディレクトリ一覧や、変更によって参照されているテストや依存関係など、関連ファイルの内容が含まれます。フェッチされる正確なコンテキストは、差分の分析によって異なります。
1. レビュー: このフローは、大規模言語モデルに次のデータを渡してレビューを実行します。レビューステージでは、オンデマンドで追加のコンテキストをフェッチすることはできません。

   - プレスキャンステップの結果。
   - マージリクエストのタイトル。
   - マージリクエストの説明。
   - マージリクエストの差分。
   - ファイルの元のバージョン。
   - ファイル名。
   - カスタムレビュー指示。

除外するコンテンツを指定するには、[GitLab Duoからコンテキストを除外する](../../context.md#exclude-context-from-gitlab-duo)を参照してください。

### ファイルとコンテキストの制限 {#file-and-context-limits}

コードレビューフローでは、プロンプトを処理可能なサイズに収めるために、次の2つの制限が適用されます:

- 10,000行を超えるファイルの場合、モデルに送信されるのは差分のみです。ファイル全体の内容は含まれません。
- プレスキャンで収集されるコンテキストの合計は、約1 MiBに制限されます。この上限を超えると、レビューステージが実行される前にコンテキストが約800 KiBに切り詰められます。

この制限はフローが収集するデータに適用され、[選択されたモデル](../../model_selection.md)のコンテキストウィンドウとは別に扱われます。

非常に大規模なマージリクエストの場合、切り詰められたコンテキストがレビューで考慮されない可能性があります。このリスクを軽減するには:

- マージリクエストを、より小さなマージリクエストに分割する。
- レビューに関連しないファイルの[コンテキストを除外](../../context.md#exclude-context-from-gitlab-duo)する。

## カスタムコードレビュー指示 {#custom-code-review-instructions}

`mr-review-instructions.yaml`ファイルを使用して、コードレビューフローの動作をカスタマイズします。

リポジトリ固有のレビュー指示を使用して、GitLab Duoをガイドできます:

- コード品質の特定の側面（セキュリティ、パフォーマンス、保守性など）に重点を置く。
- プロジェクトに固有のコーディング標準やベストプラクティスを適用する。
- 特定のファイルパターンを対象に、カスタマイズされたレビュー基準を適用する。
- 特定の種類の変更について、より詳細な説明を提供する。

コードレビューフローは、`AGENTS.md`ファイルと`SKILL.md`ファイルを参照しません。

カスタム指示を設定するには、[GitLab Duoへのレビューの指示をカスタマイズする](../../customize/review_instructions.md)を参照してください。

## 自動レビュー {#automatic-reviews}

{{< history >}}

- GitLab 18.0で、プロジェクトの自動レビューがUI設定に[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/506537)されました。
- GitLab 18.4で、グループとインスタンス向けの自動レビューが、[ベータ](../../../../policy/development_stages_support.md#beta)版として[機能フラグ](../../../../administration/feature_flags/_index.md) `cascading_auto_duo_code_review_settings`と共に[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/554070)されました。デフォルトでは無効になっています。
- 機能フラグ`cascading_auto_duo_code_review_settings`はGitLab 18.7で[削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/213240)されました。
- GitLab 19.1のGitLab.comで、新しいGitLab Duoトライアル向けに、グループおよびアプリケーション向けの自動レビューが[デフォルトで有効化](https://gitlab.com/gitlab-org/gitlab/-/work_items/592822)されました。

{{< /history >}}

GitLab Duoによる自動レビューにより、プロジェクト、グループ、またはインスタンスのすべてのマージリクエストが最初のレビューを受けることが保証されます。

ユーザーがマージリクエストを作成すると、GitLab Duoは自動的にレビューを行いますが、以下の場合を除きます:

- ドラフトとしてマークされている場合。GitLab Duoにマージリクエストをレビューさせるには、準備完了とマークします。
- 変更が含まれていない場合。GitLab Duoにマージリクエストをレビューさせるには、変更を追加します。
- 設定した1つ以上の除外ルールと一致する場合。GitLab Duoがマージリクエストをレビューするようにするには、手動でレビューをリクエストしてください。

GitLabバージョン19.1以降、GitLab.comの新しいGitLab Duoトライアルでは、グループの自動レビューがデフォルトで有効になっています。

{{< tabs >}}

{{< tab title="プロジェクト" >}}

前提条件: 

- プロジェクトのメンテナーまたはオーナーのロール。

プロジェクトの自動レビューを有効にするには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 左側のサイドバーで、**設定** > **マージリクエスト**を選択します。
1. **GitLab Duoコードレビュー**セクションで、**GitLab Duoによる自動レビューを有効にする**を選択します。
1. **変更を保存**を選択します。

{{< /tab >}}

{{< tab title="グループ" >}}

前提条件: 

- グループのオーナーロール。

グループの自動レビューを有効にするには:

1. 上部のバーで、**検索または移動先**を選択して、グループを見つけます。
1. 左側のサイドバーで、**設定** > **一般**を選択します。
1. **マージリクエスト**セクションを展開します。
1. **GitLab Duoコードレビュー**セクションで、**GitLab Duoによる自動レビューを有効にする**を選択します。
1. **変更を保存**を選択します。

設定はグループからプロジェクトへとカスケードされます。より具体的な設定は、より広範な設定をオーバーライドします。

{{< /tab >}}

{{< tab title="インスタンス" >}}

前提条件: 

- 管理者アクセス

インスタンスの自動レビューを有効にするには:

1. 右上隅で、**管理者**を選択します。
1. 左側のサイドバーで、**設定** > **一般**を選択します。
1. **GitLab Duoコードレビュー**セクションで、**GitLab Duoによる自動レビューを有効にする**を選択します。
1. **変更を保存**を選択します。

設定は、インスタンスからグループ、プロジェクトへとカスケードされます。より具体的な設定は、より広範な設定をオーバーライドします。

{{< /tab >}}

{{< /tabs >}}

自動レビューを有効にした後、特定のマージリクエストを除外するルールを指定できます。

自動レビューのクレジット使用量がどのように割り当てられるかについては、[実行されるコードレビュー機能を判定する](../../../project/merge_requests/duo_in_merge_requests.md#determine-which-review-feature-runs)を参照してください。

### プロジェクトのマージリクエストを除外する {#exclude-merge-requests-for-a-project}

{{< history >}}

- GitLab 19.2で`duo_code_review_automated_rules`[フラグ](../../../../administration/feature_flags/_index.md)とともに[ベータ版](../../../../policy/development_stages_support.md#beta)として[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/240236)されました。デフォルトでは有効になっています。
- GitLab 19.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/245852)になりました。機能フラグ`duo_code_review_automated_rules`は削除されました。

{{< /history >}}

プロジェクトで自動レビューがオンになっている場合、GitLab Duoは対象となるすべてのマージリクエストをレビューします。特定のマージリクエストを除外するには、`.gitlab/duo/mr-review-automated-rules.yaml`ファイルで除外ルールを定義します。

除外ルールは自動レビューのみに適用されます。除外されたマージリクエストでも、手動でレビューをリクエストできます。

除外ルールを定義するには:

1. リポジトリのルートで、`.gitlab/duo`ディレクトリが存在しない場合は作成します。
1. `.gitlab/duo`ディレクトリに、`mr-review-automated-rules.yaml`という名前のファイルを作成します。
1. 次の形式で除外ルールを追加します:

   ```yaml
   exclude:
     target_branches:
       - <pattern>
     source_branches:
       - <pattern>
     authors:
       - <pattern>
   ```

   各キーはオプションです。マージリクエストがいずれかのカテゴリのいずれかのパターンと一致する場合、GitLab Duoは自動レビューをスキップします:

   - `target_branches`: マージリクエストのターゲットブランチ名と照合します。
   - `source_branches`: マージリクエストのソースブランチ名と照合します。
   - `authors`: マージリクエスト作成者のユーザー名と照合します。

   パターンでは、ワイルドカード（glob）マッチングを使用できます。たとえば、`dependabot/*`は`dependabot/`で始まるすべてのソースブランチに一致します。

   たとえば、リリースブランチをターゲットとするマージリクエストや、ボットアカウントによって作成されたマージリクエストの自動レビューをスキップするには、次のようにします:

   ```yaml
   exclude:
     target_branches:
       - "release/*"
     authors:
       - "*-bot"
   ```

1. ファイルをリポジトリのデフォルトブランチにコミットします。

GitLab Duoは、リポジトリのデフォルトブランチから除外ルールを読み取ります。他のブランチにあるルールは適用されません。

### グループのマージリクエストを除外する {#exclude-merge-requests-for-a-group}

グループとそのサブグループ内のすべてのプロジェクトに適用する除外ルールを定義するには、テンプレートとして使用するプロジェクトを指定します。テンプレートプロジェクトには、`.gitlab/duo/mr-review-automated-rules.yaml`ファイルが含まれている必要があります。

GitLab Duoは、グループテンプレートプロジェクトにある除外ルールと、個々のプロジェクトで定義されているルールを組み合わせます。同じカテゴリが両方のレベルで定義されている場合、プロジェクトのルールが優先されます。グループとそのサブグループでそれぞれがテンプレートプロジェクトを設定している場合、GitLab Duoはすべてのレベルのルールを組み合わせます。

> [!note]
> グループ向けに[カスタムレビュー指示](../../customize/review_instructions.md#configure-custom-review-instructions-for-a-group)を保存するプロジェクトをすでに設定している場合、`mr-review-automated-rules.yaml`を同じプロジェクトに保存します。グループのコードレビューをカスタマイズするために指定できるプロジェクトは1つだけであるため、GitLabは自動的にそのプロジェクトも除外ルールについてチェックします。以下の手順を再度実行する必要はありません。

前提条件: 

- グループのオーナーロール。
- グループ内のプロジェクトに、グループに適用する除外ルールが含まれている。

グループの除外ルールを設定するには:

1. 上部のバーで、**検索または移動先**を選択して、グループを見つけます。
1. 左側のサイドバーで、**設定** > **一般** > **GitLab Duoの機能**を選択します。
1. **コードレビューをカスタマイズ**で、`.gitlab/duo/mr-review-automated-rules.yaml`ファイルが含まれているプロジェクトを選択します。
1. **変更を保存**を選択します。

## トラブルシューティング {#troubleshooting}

### `Error DCR4000` {#error-dcr4000}

`Code Review Flow is not enabled. Contact your group administrator to enable the foundational flow in the top-level group. Error code: DCR4000`というエラーが表示されることがあります。

このエラーは、[基本フロー](_index.md)またはコードレビューフローのいずれかが無効になっている場合に発生します。

管理者に連絡し、トップレベルグループのコードレビューフローを有効にするよう依頼してください。

### `Error DCR4001` {#error-dcr4001}

`Code Review Flow is enabled but the service account needs to be verified. Contact your administrator. Error code: DCR4001`というエラーが表示されることがあります。

このエラーは、コードレビューフローが有効になっているものの、トップレベルグループのサービスアカウントが存在しないか、準備ができていない場合に発生します。

管理者に、[サービスアカウントの存在を確認](../../troubleshooting.md#foundational-flow-service-account-not-created)し、問題を解決するための手順に従うよう依頼してください。

### `Error DCR4002` {#error-dcr4002}

`No GitLab Credits remain for this billing period. To continue using Code Review Flow, contact your administrator. Error code: DCR4002`というエラーが表示されることがあります。

このエラーは、現在の請求期間に割り当てられたGitLabクレジットをすべて使い切った場合に発生します。

追加のクレジットを購入するよう管理者に依頼するか、次の請求期間の開始時にクレジットがリセットされるまでお待ちください。

### `Error DCR4003` {#error-dcr4003}

`<User>, you don't have permission to create a pipeline for Code Review Flow in this project. Contact your administrator to update your permissions. Error code: DCR4003`というエラーが表示されることがあります。

このエラーは、コードレビューフローがCI/CDパイプライン上で実行され、このプロジェクトでパイプラインを作成する権限がないために発生します。

管理者に連絡し、[パイプラインの実行に必要な権限](../../../permissions.md)を付与するよう依頼してください。

### `Error DCR4004` {#error-dcr4004}

`<User>, you need to set a default GitLab Duo namespace to use Code Review Flow in this project. Please set a default GitLab Duo namespace in your preferences. Error code: DCR4004`というエラーが表示されることがあります。

このエラーは、GitLab Duoが、レビューを開始したユーザーのデフォルトのGitLab Duoネームスペースを特定できない場合に発生します。

[設定](../../../profile/preferences.md#set-a-default-gitlab-duo-namespace)でデフォルトのGitLab Duoネームスペースを設定し、もう一度レビューをリクエストしてください。

### `Error DCR4005` {#error-dcr4005}

`Code Review Flow could not obtain the required authentication tokens to connect to the GitLab AI Gateway and the GitLab API. Please request a new review. If the issue persists, contact your administrator. Error code: DCR4005`というエラーが表示されることがあります。

コードレビューフローがGitLab AIゲートウェイおよびGitLab APIに接続するには、認証トークンが必要です。このエラーは、通常、GitLab Duoの設定に誤りがあるか、一時的なインフラストラクチャの問題により、トークンを生成できない場合に発生します。

Self-Managedインスタンスの場合、管理者に[GitLab Duoの設定](../../../../administration/gitlab_duo/configure/_index.md)を確認するよう依頼してください。

### `Error DCR4006` {#error-dcr4006}

`Code Review Flow could not add the service account to this project. Contact your administrator to verify that the service account has the required project access. Error code: DCR4006`というエラーが表示されることがあります。

このエラーは、サービスアカウントをプロジェクトのメンバーとして追加できない場合に発生します。これは、グループメンバーシップのロックが有効になっている場合や、サービスアカウントに必要なアクセス権がない場合に発生する可能性があります。

管理者に連絡し、サービスアカウントをデベロッパーとしてプロジェクトに追加できることを確認するよう依頼してください。

### `Error DCR4007` {#error-dcr4007}

`Code Review Flow is not available for this project. Contact your administrator to verify that the flow is enabled and the required configuration is in place. Error code: DCR4007`というエラーが表示されることがあります。

このエラーは、プロジェクトでフローが無効になっているか、必要な設定が不足している場合に発生します。

管理者に連絡し、プロジェクトで[フローが有効になっている](_index.md#turn-foundational-flows-on-or-off)ことを確認するよう依頼してください。

### `Error DCR4008` {#error-dcr4008}

`Code Review Flow could not create the required CI/CD pipeline. Please request a new review. If the problem persists, contact your administrator. Error code: DCR4008`というエラーが表示されることがあります。

このエラーは、Runnerの可用性の問題や内部設定の問題により、コードレビューフローがレビューを実行するためのCI/CDパイプラインを作成または設定できない場合に発生します。

レビューを再試行してください。エラーが解決しない場合は、管理者に連絡してください。

### `Error DCR4009` {#error-dcr4009}

`Code Review Flow could not retrieve the source branch for this merge request. Please request a new review. Error code: DCR4009`というエラーが表示されることがあります。

このエラーは、コードレビューフローがマージリクエストのソースブランチを取得できない場合に発生します。

レビューを再試行してください。

### `Error DCR5000` {#error-dcr5000}

`Something went wrong while starting Code Review Flow. Please try again later. Error code: DCR5000`というエラーが表示されることがあります。

このエラーは、GitLab Duo Agent Platformが内部エラーによりコードレビューフローを開始できない場合に発生します。

レビューを再試行してください。エラーが解決しない場合は、管理者に連絡してください。

### `Error DCR5001` {#error-dcr5001}

`Code Review Flow completed the review but could not post the review comments. Please request a new review to try again. Error code: DCR5001`というエラーが表示されることがあります。

このエラーは、コードレビューフローがレビューを完了したものの、複数回試行してもレビューコメントを投稿できない場合に発生します。これは多くの場合、一時的なインフラストラクチャの問題が原因です。

新しいレビューをリクエストします。エラーが解決しない場合は、管理者に連絡してください。

### 大規模なマージリクエストのレビューでコンテキストが不足する {#missing-context-in-large-merge-request-reviews}

マージリクエストに大きな変更ファイルが多数含まれている場合、コードレビューフローでコンテキストが不足することがあります。

これは、プレスキャン結果が[ファイルとコンテキストの制限](#file-and-context-limits)を超え、レビューステージが実行される前にデータが切り詰められる場合に発生することがあります。

レビューを改善するには:

- マージリクエストを、より小さなマージリクエストに分割する。
- レビューに関連しないファイルの[コンテキストを除外](../../context.md#exclude-context-from-gitlab-duo)する。
- メンテナーまたはオーナーに、**エージェント型コードレビュー**設定を使用して[別のモデルを選択](../../model_selection.md)するよう依頼する。

### 設定診断スクリプト {#configuration-diagnostic-script}

記載されているエラーコードからコードレビューフローの問題の原因を特定できない場合は、診断スクリプトを実行してGitLab Duo設定を確認できます。

このスクリプトは、すべてのGitLab Duo Agent Platform機能に適用されるチェックを含め、コードレビューフローに必要な一連の設定をすべてチェックします。

詳細については、[設定診断スクリプトを実行する](../../troubleshooting.md#run-the-configuration-diagnostic-script)を参照してください。

## 関連トピック {#related-topics}

- [マージリクエストにおけるGitLab Duo](../../../project/merge_requests/duo_in_merge_requests.md)
- [Agent PlatformのAIモデル](../../model_selection.md)
- [GitLab Duo Enterpriseシートでコードレビューフローをオンにする](../../../project/merge_requests/duo_in_merge_requests.md#turn-on-code-review-flow-for-gitlab-duo-enterprise-seats)。
