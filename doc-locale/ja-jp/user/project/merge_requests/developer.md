---
stage: Agent Foundations
group: Agent Developer
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: デベロッパーフロー
---

{{< details >}}

- プラン: [Free](../../../subscriptions/gitlab_credits.md#for-the-free-tier)、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 18.3で[ベータ](../../../policy/development_stages_support.md)として導入され、`duo_workflow_in_ci`という名前の[機能フラグを使用](../../../administration/feature_flags/_index.md)します。デフォルトでは無効になっていますが、インスタンスまたはユーザーに対して有効にすることができます。
- GitLab 18.6で`Issue to MR`から`Developer Flow`に名前が変更され、`duo_developer_button`フラグが導入されました。デフォルトでは無効になっていますが、インスタンスまたはユーザーに対して有効にすることができます。機能フラグ`duo_workflow`も有効にする必要がありますが、これはデフォルトで有効になっています。
- GitLab 18.8で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/work_items/585273)になりました。
- 機能フラグ`duo_workflow_in_ci`、`duo_developer_button`、`duo_workflow`はGitLab 18.9で削除されました。
- GitLab 18.10で、GitLab.comのFreeプランにおいてGitLabクレジットを使用して利用できるようになりました。
- GitLab 18.11でメンショントリガーが[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/228817)されました。
- 作業アイテムのステータス変更トリガー、およびフローを割り当てたときのワークプランのサポートが、GitLab 19.6で[導入](https://gitlab.com/gitlab-org/gitlab/-/work_items/633027)されました。

{{< /history >}}

デベロッパーフローは、イシューとマージリクエスト全体で、より効率的に作業するのに役立ちます。デベロッパーフローは次の目的で使用できます:

- イシューからドラフトマージリクエストを作成する。
- レビューフィードバックに基づき、既存のマージリクエストに対してイテレーションを行う。
- 実装方法を調査し、調査結果をディスカッションに投稿する。
- 大規模なマージリクエストを、焦点を絞った小さなマージリクエストに分割する。
- マージコンフリクトを解決する。

## 前提条件 {#prerequisites}

- [GitLab Duo Agent Platformの前提条件](../../duo_agent_platform/_index.md#prerequisites)を満たしていること。
- [トップレベルグループ](../../duo_agent_platform/flows/foundational_flows/_index.md#turn-foundational-flows-on-or-off)で、**基本フローを許可**と**デベロッパー**を有効にしていること。
- プロジェクトのデベロッパー、メンテナー、またはオーナーロールを持っている。
- [サービスアカウントを許可するようにプッシュルールを設定している](../../duo_agent_platform/troubleshooting.md#configure-push-rules-to-allow-a-service-account)。
- [独自のRunnerを設定](../../duo_agent_platform/flows/execution/_index.md#configure-runners-to-execute-flows)しているか、プロジェクトで[GitLabホストRunner](../../../ci/runners/hosted_runners/_index.md)をオンにしている。

最良の結果を得るために、デベロッパーフローを初めて使用する前に、[プロジェクトをセットアップ](#set-up-your-project)してください。`AGENTS.md`および`agent-config.yml`ファイルを設定すると、デベロッパーフローの結果の品質と信頼性が大幅に向上します。

## プロジェクトをセットアップする {#set-up-your-project}

デベロッパーフローがより良い結果を出せるようにするため、プロジェクトで次のオプション設定を行うことをおすすめします:

- `AGENTS.md`ファイルを追加する: テストコマンド、Lintルール、コミット形式、コードパターンなど、プロジェクトの規約を文書化する。デベロッパーフローは、リポジトリで作業する際に、このファイルをコンテキストとして使用します。詳細については、[AGENTS.mdカスタマイズファイル](../../duo_agent_platform/customize/agents_md.md)を参照してください。
- ワークスペースサブエージェントを追加する: `.agents/agents/`ディレクトリに専用のサブエージェントを定義すると、デベロッパーフローはレビューや調査などの集中的なタスクをそれらに委任できます。この機能は実験です。詳細については、[ワークスペースサブエージェント](../../duo_agent_platform/customize/workspace_subagents.md)を参照してください。
- 実行環境を設定する: プロジェクトで特定のツール（Go、Python、Node.jsなど）が必要な場合は、`agent-config.yml`ファイルでエージェント環境を設定します。これを設定しないと、デベロッパーフローは依存関係をインストールしたりテストを実行したりできず、ビルドまたはパスしない変更を生成する可能性が高くなります。環境が適切に設定されていると、デベロッパーフローはコミットする前にテストを実行し、自身の変更を検証できます。詳細については、[フロー実行を設定する](../../duo_agent_platform/flows/execution/_index.md)を参照してください。
- モデルを選択する: デベロッパーフローは、コストとパフォーマンスのバランスを考慮して調整されたGitLabのデフォルトモデルを使用します。集中的なタスクの場合、より高速なモデルを使用すると反復時間が短縮されます。複雑な複数ステップのタスクの場合、より高性能なモデルを使用すると、不完全な計画のリスクが軽減されます。詳細については、[GitLab Duo AIモデル](../../duo_agent_platform/model_selection.md)を参照してください。

## フローを使用する {#use-the-flow}

前提条件: 

- デベロッパーフローのトリガーで、イベントタイプ**メンション**と**割り当て**が[設定](../../duo_agent_platform/triggers/_index.md)されていること。

### ディスカッションでDuo Developerにメンションする {#mention-duo-developer-in-a-discussion}

コメントをデベロッパーフローの実行可能なタスクに変えるには、コメント内で`@duo-developer-<namespace>`にメンションしてください。`<namespace>`は、GitLabのネームスペースパス（`gitlab-org`など）に置き換えます。

イシューまたはマージリクエストの内容と提供したコンテキストの量に応じて、フローは次のタスクを実行できます:

- コードの変更
- マージリクエストとイシューの作成
- 実装アプローチの調査とそれに応じたレポートまたは更新の報告

例: 

```plaintext
@duo-developer-<namespace> research approaches for implementing pagination
on the /users endpoint, then create a draft MR with the most
promising approach.
```

デベロッパーフローは、自身のセッションへのリンクを返信します。

または、進捗状況を監視するには、左側のサイドバーで**AI** > **セッション**を選択します。

### イシューからマージリクエストを生成する {#generate-a-merge-request-from-an-issue}

イシューからマージリクエストを作成するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 左側のサイドバーで、**計画** > **作業アイテム**を選択し、次に**タイプ** = **イシュー**でフィルタリングします。
1. マージリクエストを作成するイシューを選択します。
1. イシューからマージリクエストを作成するには、次のいずれかを行います:
   - Duo Developerサービスアカウントをイシューに割り当てます:
     1. 右側のサイドバーの**担当者**セクションで、**編集**を選択します。
     1. `duo developer`と入力し、検索結果から選択します。
   - イシューのヘッダーの下にある**実装**を選択します。
1. 進捗状況を監視するには、左側のサイドバーで**AI** > **セッション**を選択します。
1. セッションが完了したら、イシューの**アクティビティ**セクションにあるリンクからマージリクエストをレビューします。

[ワークプラン](../../work_items/workplan.md)があるイシューにフローを割り当てると、フローはワークプランに従います。説明とワークプランが一致しない場合、フローはワークプランに従います。

### 作業アイテムのステータスが変更されたときにフローを開始する {#start-the-flow-when-a-work-item-status-changes}

作業アイテムが選択したステータスに変更されると、デベロッパーフローはその作業アイテムを実装し、マージリクエストを作成します。フローは、作業アイテムの[ワークプラン](../../work_items/workplan.md)をその仕様として使用します。作業アイテムにワークプランがない場合、フローは説明を使用します。

前提条件: 

- イベントタイプが**作業アイテム**で、アクションが**ステータス変更**のみであるデベロッパーフロー用の[トリガーを作成](../../duo_agent_platform/triggers/_index.md#create-a-trigger)します。**作成日**も選択した場合、ステータスを選択できず、作業アイテムが作成されたときにフローは開始しません。
- トリガーで、作業を開始するステータスを選択します。ステータスを選択しない場合、完了ステータスへの変更を含め、すべてのステータス変更でセッションが開始されます。

フローを開始するには:

1. 作業アイテムのステータスを、トリガーで選択したステータスのいずれかに変更します。
1. 進捗状況を監視するには、左側のサイドバーで**AI** > **セッション**を選択します。
1. セッションが完了したら、作業アイテムの**アクティビティ**セクションのリンクからマージリクエストを確認します。フローは、ステータスを変更したユーザーにマージリクエストを割り当てます。

### Agentic Chatでフローを使用する {#use-the-flow-in-agentic-chat}

{{< history >}}

- GitLab 19.2で`agentic_foundational_flow_tool`[機能フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/groups/gitlab-org/-/work_items/20484)されました。デフォルトでは有効になっています。
- GitLab 19.5で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/work_items/605446)となりました。機能フラグ`agentic_foundational_flow_tool`は削除されました。

{{< /history >}}

デベロッパーフローは、GitLab Duo Agentic Chatの会話で使用して、次のようなさまざまなタスクを完了できます:

- コーディングの目標を達成する。この目標に関連付けられたイシューは必要ありません。
- マージリクエストを開いてイシューを解決する。

Agentic Chatの会話でフローを使用するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. GitLab Duoサイドバーで、新規または既存のAgentic Chatの会話を開きます。
1. Agentic Chatに、デベロッパーフローを使用してタスクを達成するよう依頼します。

   フローの進行状況は、Chatの会話に表示されます。詳細については、以下のいずれかを行います:
   - 会話で**エージェントセッションを表示**を選択する。
   - 左側のサイドバーで、**AI** > **セッション**を選択します。

## ベストプラクティス {#best-practices}

### 明確なコンテキストを提供する {#provide-clear-context}

デベロッパーフローが把握しているのは、ユーザーが伝えた内容や、イシュー、マージリクエスト、Chatの会話、またはディスカッションスレッドのコンテキストで利用可能な情報のみです。人間の共同作業者が効率的に作業できるようにするための手法は、ここでも同じように当てはまります:

- 関連ファイルやディスカッションへのリンクを含め、問題の説明を明確に記述する。
- 何をもって「完了」とするかを定義する受け入れ条件を含める。
- 正確なファイルパスがわかっている場合は指定する。
- 一貫性を保つため、既存パターンのコード例を含める。

### ディスカッションでDuo Developerにメンションする際は明示的に指示する {#be-explicit-when-mentioning-duo-developer-in-discussions}

ディスカッションでDuo Developerにメンションする際は、何を実行してほしいのかを正確に伝えます。例: 

- 「`/api/users`エンドポイントのページネーションを実装するドラフトマージリクエストを作成してください。」
- 「このマージリクエストのレビューフィードバックに対応してください。」
- 「ログの生成に関する変更を別のマージリクエストに分割してください。」
- 「このサービスをgRPCに移行する方法を調査し、調査結果をここに投稿してください。」
- 「このマージリクエストにはマージコンフリクトがあります。解決してください。」

明確な指示がない場合、フローは独自の方法を選択するため、期待した結果が得られない可能性があります。

### タスクの焦点を絞る {#keep-tasks-focused}

複雑なタスクは、より小さく、スコープが絞られた、アクション指向のリクエストに分割してください。大規模で自由度の高いタスクは、イテレーションの上限に達しやすくなります。

## 例 {#examples}

### マージリクエストを生成するためのイシュー {#issue-for-generating-a-merge-request}

この例は、デベロッパーフローがマージリクエストを生成するために使用できる、適切に作成されたイシューを示しています。

```plaintext
## Description
The users endpoint currently returns all users at once,
which will cause performance issues as the user base grows.
Implement cursor-based pagination for the `/api/users` endpoint
to handle large datasets efficiently.

## Implementation plan
Add pagination to GET /users API endpoint.
Include pagination metadata in /users API response (per_page, page).
Add query parameters for per page size limit (default 5, max 20).

#### Files to modify
- `src/api/users.py` - Add pagination parameters and logic.
- `src/models/user.py` - Add pagination query method.
- `tests/api/test_users_api.py` - Add pagination tests.

## Acceptance criteria
- Accepts page and per_page query parameters (default: page=5, per_page=10).
- Limits per_page to a maximum of 20 users.
- Maintains existing response format for user objects in data array.
```

### マージリクエストのレビューフィードバックに対してイテレーションを行う {#iterate-on-merge-request-review-feedback}

マージリクエストをレビューした後、デベロッパーフローにメンションしてフィードバックに対応させることができます。たとえば、特定の行に対するレビューコメントで、次のように記述します:

```plaintext
@duo-developer-<namespace> move this validation logic into the `BaseService` class
in `app/services/base_service.rb` instead of duplicating it here.
```

また、レビュー全体を送信した後、デベロッパーフローにメンションして、すべての未解決スレッドに対応させることもできます:

```plaintext
@duo-developer-<namespace> please address the review feedback on this MR.
```

### マージリクエストを分割する {#split-a-merge-request}

マージリクエストが大きくなりすぎた場合は、その一部を別のマージリクエストとして抽出するようにデベロッパーフローに依頼できます:

```plaintext
@duo-developer-<namespace> the logging changes in this MR are out of scope.
Split them into a separate MR.
```

### 実装方法を調査する {#research-an-implementation-approach}

変更を加える前に、問題を調査して報告するようにデベロッパーフローに依頼できます:

```plaintext
@duo-developer-<namespace> research whether the `PUT /api/users` endpoint also needs
rate limiting like we added to the `POST /api/users` endpoint.
Post your findings here.
```

### Agentic Chatでデベロッパーフローを使用する {#use-the-developer-flow-in-agentic-chat}

デベロッパーフローは、Agentic Chatの会話で使用して、さまざまなタスクを完了できます:

- コーディングの目標を達成するには、次のように入力します:
  - `Use the developer flow to resolve this code review feedback.`
  - `Use the developer flow to update this dependency.`
- マージリクエストを開いてイシューを解決するには、次のように入力します:
  - `Resolve this issue.`
  - `Open a merge request to resolve this issue.`
