---
stage: AI Coding
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: コードレビューフロー
---

{{< details >}}

- プラン: [Free](../../../../../subscriptions/gitlab_credits.md#for-the-free-tier)、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< collapsible title="モデル情報" >}}

- LLM: Anthropic Claude Sonnet 5 Vertex
- GitLab 19.0以前のLLM: GitLab Duoコードレビューの非エージェント型バージョン用の[デフォルトLLM](../../../../gitlab_duo/model_selection.md#default-models)。
- GitLab.comでは、[別のモデルを選択](../../../model_selection.md#select-a-model-for-a-feature)するには、**Agentic Code Review**設定を使用します。
- GitLab Self-ManagedおよびGitLab Dedicatedでは、お使いのGitLabバージョンに適した設定を使用して[別のモデルを選択](../../../../../administration/gitlab_duo/model_selection.md#select-a-model-for-code-review-flow)します。
- [セルフホストモデル対応のGitLab Duo](../../../../../administration/gitlab_duo_self_hosted/_index.md)で利用可能

{{< /collapsible >}}

{{< history >}}

- GitLab [18.7](https://gitlab.com/groups/gitlab-org/-/epics/18645)で`duo_code_review_on_agent_platform`[機能フラグ](../../../../../administration/feature_flags/_index.md)とともに[ベータ版](../../../../../policy/development_stages_support.md)として導入されました。デフォルトでは無効になっています。
- GitLab 18.8で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/work_items/585273)になりました。機能フラグ`duo_code_review_on_agent_platform`は[削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/217209)されました。
- GitLab 18.10で、GitLab.comのFreeプランにおいてGitLabクレジットを使用して利用できるようになりました。
- 2026年5月20日にLLMがClaude Sonnet 4.6 Vertexに[更新](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/merge_requests/5555)されました。
- 2026年8月6日にLLMがClaude Sonnet 5 Vertexに[更新](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/merge_requests/6422)されました。

{{< /history >}}

> [!note]
> アドオンとグループの設定に応じて、GitLabでは以下の2つのコードレビュー機能のいずれかが実行されます:
>
> - コードレビューフロー: GitLab Duo Agent Platformの一部であるエージェント型バージョン。
> - GitLab Duoコードレビュー: GitLab Duo Enterpriseアドオンを使用するユーザーのみが利用できる非エージェント型バージョン。
>
> このページでは、エージェント型バージョンについて説明します。
>
> この2つの機能の比較、およびGitLab Duo Enterpriseシートでコードレビューフローをオンにする方法の詳細については、[GitLab Duoを使用してコードをレビューする](../../../../project/merge_requests/duo_in_merge_requests.md#use-gitlab-duo-to-review-your-code)を参照してください。

コードレビューフローを使用すると、エージェント型AIによってコードレビューを効率化できます。

このフローには次の特長があります:

- コードの変更を分析する。
- リポジトリ構造やファイル間の依存関係を踏まえて、より高度にコンテキストを理解する。
- 実行可能なフィードバックを含む、詳細なレビューコメントを提供する。
- プロジェクトに合わせて調整されたカスタムレビュー指示をサポートする。

## 前提条件 {#prerequisites}

- [GitLab Duo Agent Platformの前提条件](../../../_index.md#prerequisites)を満たしている。
- [トップレベルグループ](../_index.md#turn-foundational-flows-on-or-off)で、**基本フローを許可**と**コードレビュー**をオンにしている。
- プロジェクトのデベロッパー、メンテナー、またはオーナーロールを持っている。
- 複数のGitLab Duoネームスペースに属している場合は、[デフォルトのGitLab Duoネームスペースを設定](../../../../profile/preferences.md#set-a-default-gitlab-duo-namespace)している。
- `gitlab--duo`タグとDockerイメージをサポートするexecutorを使用する[独自のRunnerを設定](../../execution/_index.md#configure-runners-to-execute-flows)するか、プロジェクトで[GitLabホストRunner](../../../../../ci/runners/hosted_runners/_index.md)をオンにしている。コードレビューフローはCI/CDジョブとして実行されるため、実行にはRunnerが必要です。

## フローを使用する {#use-the-flow}

コードレビューフローは、GitLab UIおよびREST APIを通じて利用できます。

### GitLab UIでのレビューリクエスト {#request-a-review-in-the-gitlab-ui}

{{< history >}}

- GitLab 19.2で、GitLab Duo Agentic Chatの会話においてフローを使用する機能が`agentic_foundational_flow_tool`[機能フラグ](../../../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/groups/gitlab-org/-/work_items/20484)されました。デフォルトでは有効になっています。

{{< /history >}}

> [!flag]
> この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

GitLab UIでレビューをリクエストするには:

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

### REST APIによるレビューリクエスト {#request-a-review-through-the-rest-api}

{{< details >}}

- ステータス: 実験的機能

{{< /details >}}

{{< history >}}

- GitLab 19.4でREST APIによるコードレビューの[トリガー](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/250117)が導入されました。

{{< /history >}}

REST APIを通じてレビューをリクエストするには、以下のパラメータで[フローをトリガー](../../../../../api/duo_agent_platform_flows.md#trigger-a-flow)します:

- `project_id`をマージリクエストを含むプロジェクトに設定します。
- `goal`を、レビューするマージリクエストのIID、またはそのマージリクエストの完全なURLのいずれかに設定します。
- `workflow_definition`を`code_review/v1`に設定します。または、`ai_catalog_item_consumer_id`をコードレビューフローの[コンシューマーID](../../../../../api/duo_agent_platform_flows.md#look-up-the-consumer-id)に設定します。
- `start_workflow`を`true`に設定して、すぐにレビューを開始します。

以下は、マージリクエスト`42`のコードレビューをトリガーする例です:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{
    "project_id": "5",
    "goal": "42",
    "workflow_definition": "code_review/v1",
    "start_workflow": true
  }' \
  --url "https://gitlab.example.com/api/v4/ai/duo_workflows/workflows"
```

## レビューでGitLab Duoとやり取りする {#interact-with-gitlab-duo-in-reviews}

レビュー後、コメントでのやり取りでGitLab Duoとフィードバックについて議論できます。インタラクションはコードレビューフローとは別の機能です。

詳細については、[GitLab Duoとのインタラクト](../../../../project/merge_requests/duo_in_merge_requests.md#interact-with-gitlab-duo)を参照してください。

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

除外するコンテンツを指定するには、[GitLab Duoからコンテキストを除外する](../../../context.md#exclude-context-from-gitlab-duo)を参照してください。

### ファイルとコンテキストの制限 {#file-and-context-limits}

コードレビューフローでは、プロンプトを処理可能なサイズに収めるために、次の2つの制限が適用されます:

- 10,000行を超えるファイルの場合、モデルに送信されるのは差分のみです。ファイル全体の内容は含まれません。
- プレスキャンで収集されるコンテキストの合計は、約1 MiBに制限されます。この上限を超えると、レビューステージが実行される前にコンテキストが約800 KiBに切り詰められます。

この制限はフローが収集するデータに適用され、[選択されたモデル](../../../model_selection.md)のコンテキストウィンドウとは別に扱われます。

非常に大規模なマージリクエストの場合、切り詰められたコンテキストがレビューで考慮されない可能性があります。このリスクを軽減するには:

- マージリクエストを、より小さなマージリクエストに分割する。
- レビューに関連しないファイルの[コンテキストを除外](../../../context.md#exclude-context-from-gitlab-duo)する。
- グループのオーナーまたはインスタンス管理者に対し、[GitLab.com](../../../model_selection.md#select-a-model-for-a-feature)または[GitLab Self-ManagedおよびGitLab Dedicated](../../../../../administration/gitlab_duo/model_selection.md#select-a-model-for-code-review-flow)に別のモデルを選択するよう依頼してください。

## カスタムコードレビュー指示 {#custom-code-review-instructions}

`mr-review-instructions.yaml`ファイルを使用して、コードレビューフローの動作をカスタマイズします。

リポジトリ固有のレビュー指示を使用して、GitLab Duoをガイドできます:

- コード品質の特定の側面（セキュリティ、パフォーマンス、保守性など）に重点を置く。
- プロジェクトに固有のコーディング標準やベストプラクティスを適用する。
- 特定のファイルパターンを対象に、カスタマイズされたレビュー基準を適用する。
- 特定の種類の変更について、より詳細な説明を提供する。

コードレビューフローは、`AGENTS.md`ファイルと`SKILL.md`ファイルを参照しません。

カスタム指示を設定するには、[GitLab Duoへのレビューの指示をカスタマイズする](../../../customize/review_instructions.md)を参照してください。

## 自動レビュー {#automatic-reviews}

{{< history >}}

- GitLab 18.0でプロジェクトの自動レビューがUI設定に[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/506537)されました。
- GitLab 18.4で`cascading_auto_duo_code_review_settings`[機能フラグ](../../../../../administration/feature_flags/_index.md)とともに、グループの自動レビューが[ベータ版](../../../../../policy/development_stages_support.md#beta)として[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/554070)されました。デフォルトでは無効になっています。
- 機能フラグ`cascading_auto_duo_code_review_settings`はGitLab 18.7で[削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/213240)されました。
- GitLab 19.1で、新規GitLab DuoトライアルのGitLab.comについては、グループおよびアプリケーションの自動レビューが[デフォルトで有効](https://gitlab.com/gitlab-org/gitlab/-/work_items/592822)になりました。

{{< /history >}}

GitLab Duoによる自動レビューは、プロジェクトまたはグループ内のすべてのマージリクエストが最初のレビューを受けることを保証します。

ユーザーがマージリクエストを作成すると、GitLab Duoは以下の場合を除き、自動的にレビューします:

- ドラフトとしてマークされている場合。GitLab Duoにマージリクエストをレビューさせるには、準備完了とマークします。
- 変更が含まれていない場合。GitLab Duoにマージリクエストをレビューさせるには、変更を追加します。
- 設定した除外ルールが1つ以上一致する場合。GitLab Duoがマージリクエストをレビューするには、手動でレビューをリクエストしてください。

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

設定はグループからプロジェクトにカスケードされます。より具体的な設定は、より広範な設定をオーバーライドします。

{{< /tab >}}

{{< /tabs >}}

自動レビューを有効にした後、特定のマージリクエストを除外するルールを指定できます。

自動レビューのクレジット使用量がどのように割り当てられるかについては、[実行されるコードレビュー機能を判定する](../../../../project/merge_requests/duo_in_merge_requests.md#determine-which-review-feature-runs)を参照してください。

### プロジェクトのマージリクエストを除外する {#exclude-merge-requests-for-a-project}

{{< history >}}

- GitLab 19.2で`duo_code_review_automated_rules`[フラグ](../../../../../administration/feature_flags/_index.md)とともに[ベータ版](../../../../../policy/development_stages_support.md#beta)として[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/240236)されました。デフォルトでは有効になっています。
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
> グループの[カスタムレビュー指示](../../../customize/review_instructions.md#configure-custom-review-instructions-for-a-group)を保存するようにプロジェクトをすでに設定している場合は、`mr-review-automated-rules.yaml`を同じプロジェクトに保存してください。グループのコードレビューをカスタマイズするために指定できるプロジェクトは1つだけなので、GitLabはそのプロジェクトの除外ルールも自動的にチェックします。以下の手順を再度実行する必要はありません。

前提条件: 

- グループのオーナーロール。
- グループ内のプロジェクトに、グループに適用する除外ルールが含まれている。

グループの除外ルールを設定するには:

{{< tabs >}}

{{< tab title="GitLab.com" >}}

トップレベルグループの場合:

1. 上部のバーで**検索または移動先**を選択して、トップレベルグループを見つけます。
1. 左側のサイドバーで、**設定** > **GitLab Duo**を選択します。
1. **設定の変更**を選択します。
1. **GitLab Duoの機能** > **コードレビューをカスタマイズ**で、`.gitlab/duo/mr-review-automated-rules.yaml`ファイルを含むプロジェクトを選択します。
1. **変更を保存**を選択します。

グループまたはサブグループの場合:

1. 上部のバーで、**検索または移動先**を選択して、グループまたはサブグループを見つけます。
1. 左側のサイドバーで、**設定** > **一般**を選択します。
1. **GitLab Duoの機能**を展開します。
1. **コードレビューをカスタマイズ**で、`.gitlab/duo/mr-review-automated-rules.yaml`ファイルが含まれているプロジェクトを選択します。
1. **変更を保存**を選択します。

{{< /tab >}}

{{< tab title="GitLab Self-ManagedおよびGitLab Dedicated" >}}

1. 上部のバーで、**検索または移動先**を選択して、グループまたはサブグループを見つけます。
1. 左側のサイドバーで、**設定** > **一般**を選択します。
1. **GitLab Duoの機能**を展開します。
1. **コードレビューをカスタマイズ**で、`.gitlab/duo/mr-review-automated-rules.yaml`ファイルが含まれているプロジェクトを選択します。
1. **変更を保存**を選択します。

{{< /tab >}}

{{< /tabs >}}

## トラブルシューティング {#troubleshooting}

コードレビューフローを使用している際に、問題に遭遇する可能性があります。

これらの問題を解決する方法については、[トラブルシューティング](troubleshooting.md)を参照してください。

## 関連トピック {#related-topics}

- [マージリクエストにおけるGitLab Duo](../../../../project/merge_requests/duo_in_merge_requests.md)
- [Agent PlatformのAIモデル](../../../model_selection.md)
- [GitLab Duo Enterpriseシートでコードレビューフローをオンにする](../../../../project/merge_requests/duo_in_merge_requests.md#turn-on-code-review-flow-for-gitlab-duo-enterprise-seats)。
