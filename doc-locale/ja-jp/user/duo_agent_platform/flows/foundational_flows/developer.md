---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: デベロッパーフロー
---

{{< details >}}

- プラン: [Free](../../../../subscriptions/gitlab_credits.md#for-the-free-tier)、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 18.3で`duo_workflow_in_ci`[フラグ](../../../../administration/feature_flags/_index.md)とともに[ベータ版](../../../../policy/development_stages_support.md)として導入されました。デフォルトでは無効になっていますが、インスタンスまたはユーザーに対して有効にすることができます。
- GitLab 18.6で、`Issue to MR`から`Developer Flow`に`duo_developer_button`という機能フラグとともに名前が変更されました。デフォルトでは無効になっていますが、インスタンスまたはユーザーに対して有効にすることができます。機能フラグ`duo_workflow`も有効にする必要がありますが、デフォルトでは有効になっています。
- GitLab 18.8で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/work_items/585273)になりました。
- GitLab 18.9で、機能フラグ`duo_workflow_in_ci`、`duo_developer_button`、および`duo_workflow`が削除されました。
- GitLab 18.10では、GitLab.comのFreeティアでGitLabクレジットとともに利用できます。
- GitLab 18.11でメンショントリガーが[導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/228817)。

{{< /history >}}

デベロッパーフローは、イシューとマージリクエストを横断してより効率的に作業するのに役立ちます。デベロッパーフローを次の目的で使用できます:

- イシューからドラフトのマージリクエストを作成します。
- 既存のマージリクエストについて、レビューフィードバックに基づいてイテレーションを行います。
- 実装アプローチを調査し、ディスカッションに調査結果を投稿します。
- 大規模なマージリクエストを、より小さく焦点を絞ったマージリクエストに分割します。
- マージコンフリクトを解決する。

## 前提条件 {#prerequisites}

- [GitLab Duo Agent Platformの前提条件](../../_index.md#prerequisites)を満たしていること。
- [トップレベルグループ](_index.md#turn-foundational-flows-on-or-off)で、**基本フローを許可**と**デベロッパー**を有効にします。
- プロジェクトのデベロッパー、メンテナー、またはオーナーロールが必要です。
- [サービスアカウントを許可するようにプッシュルールを設定します](../../troubleshooting.md#configure-push-rules-to-allow-a-service-account)。
- プロジェクトで[独自のRunnerを設定する](../execution.md#configure-runners)か、[GitLabホスト型Runnerを有効にします](../../../../ci/runners/hosted_runners/_index.md)。

## プロジェクトをセットアップする {#set-up-your-project}

デベロッパーフローがより良い結果を出すのに役立つよう、以下のオプション設定でプロジェクトを設定する必要があります:

- `AGENTS.md`ファイルを追加します: テストコマンド、Lintルール、コミット形式、およびコードパターンなど、プロジェクトの慣例をドキュメント化します。デベロッパーフローは、リポジトリで作業する際に、このファイルをコンテキストとして使用します。詳細については、[AGENTS.mdカスタマイズファイル](../../customize/agents_md.md)を参照してください。
- 実行環境を設定します: プロジェクトに特定のツール (Go、Python、Node.jsなど) が必要な場合は、エージェント環境を`agent-config.yml`ファイルで設定します。適切に設定された環境があれば、デベロッパーフローはコミットする前にテストを実行し、自身の変更を検証できます。詳細については、[フローの実行を設定する](../execution.md)を参照してください。

## フローを使用する {#use-the-flow}

前提条件: 

- デベロッパーフローのトリガーでは、イベントタイプ**メンション**と**アサイン**が[設定されています](../../triggers/_index.md)。

### ディスカッションでDuo Developerをメンションする {#mention-duo-developer-in-a-discussion}

コメントをデベロッパーフローの実行可能なタスクにするには、ディスカッションで`@duo-developer-<namespace>`を使用してメンションします。`<namespace>`をGitLabのネームスペースパス (`gitlab-org`など) に置き換えます。

イシューまたはマージリクエストのコンテンツと提供するコンテキストの量に応じて、フローは以下のタスクを実行できます:

- codeコードの変更
- マージリクエストとイシューの作成
- 実装アプローチを調査し、それに応じてレポートまたは更新を報告する

例: 

```plaintext
@duo-developer-<namespace> research approaches for implementing pagination
on the /users endpoint, then create a draft MR with the most
promising approach.
```

デベロッパーフローは、そのセッションへのリンクで応答します。

あるいは、進捗を監視するには、左サイドバーで**AI** > **セッション**を選択します。

### イシューからマージリクエストを生成する {#generate-a-merge-request-from-an-issue}

イシューからマージリクエストを作成するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 左サイドバーで**Plan** > **作業アイテム**を選択し、次に**タイプ** = **Issue**でフィルタリングします。
1. マージリクエストを作成するイシューを選択します。
1. イシューからマージリクエストを作成するには、次のいずれかの方法を使用します:
   - Duo Developerサービスアカウントをイシューに割り当てます:
     1. 右サイドバーの**担当者**セクションで、**編集**を選択します。
     1. `duo developer`と入力し、検索結果から選択します。
   - イシューヘッダーの下にある**GitLab Duoでマージリクエストを生成**を選択します。
1. オプション。フローの進捗を監視するには、左サイドバーで**AI** > **セッション**を選択します。
1. セッションが完了したら、イシューの**アクティビティ**セクションにあるリンクからマージリクエストをレビューします。

## ベストプラクティス {#best-practices}

### 明確なコンテキストを提供する {#provide-clear-context}

デベロッパーフローは、あなたが伝える情報、またはイシュー、マージリクエスト、ディスカッションスレッドのコンテキストで利用可能な情報のみを知っています。人間の共同作業者を助けるのと同じプラクティスがここに適用されます:

- 関連ファイルやディスカッションへのリンクを含め、明確な問題記述を作成します。
- 「完了」の基準を定義する受け入れ基準を含めます。
- 正確なファイルパスを知っている場合は、それを指定します。
- 一貫性を保つため、既存パターンのコード例を含める。

### ディスカッションでDuo Developerをメンションする際は明確にする {#be-explicit-when-mentioning-duo-developer-in-discussions}

ディスカッションでDuo Developerをメンションする際は、実行してほしいことを正確に伝えます。例: 

- 「`/api/users`エンドポイントのページネーションを実装するドラフトのマージリクエストを作成します。」
- 「このマージリクエストに関するレビューフィードバックに対応します。」
- 「ロギングの変更を別のマージリクエストに分割します。」
- 「このサービスをgRPCに移行するためのアプローチを調査し、ここに調査結果を投稿してください。」
- 「このマージリクエストにはマージコンフリクトがあります。解決してください。」

明確な指示がない場合、フローは独自のアプローチを選択するため、期待と一致しない可能性があります。

### タスクに集中する {#keep-tasks-focused}

複雑なタスクは、より小さく、スコープが絞られた、アクション指向のリクエストに分割してください。大規模で自由度の高いタスクは、イテレーションの制限に達する可能性が高くなります。

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

### マージリクエストのレビューフィードバックにイテレーションを行う {#iterate-on-merge-request-review-feedback}

マージリクエストをレビューした後、Duo Developerデベロッパーフローをメンションしてフィードバックに対応できます。たとえば、特定の行に対するレビューコメントで、:

```plaintext
@duo-developer-<namespace> move this validation logic into the `BaseService` class
in `app/services/base_service.rb` instead of duplicating it here.
```

レビューを完了した後、デベロッパーフローをメンションして、すべての未解決のスレッドに対応することもできます:

```plaintext
@duo-developer-<namespace> please address the review feedback on this MR.
```

### マージリクエストを分割する {#split-a-merge-request}

マージリクエストが大きくなりすぎた場合は、デベロッパーフローにその一部を別のマージリクエストに抽出するように依頼できます:

```plaintext
@duo-developer-<namespace> the logging changes in this MR are out of scope.
Split them into a separate MR.
```

### 実装アプローチを調査する {#research-an-implementation-approach}

変更を加える前に、デベロッパーフローに問題を調査し、レポートするように依頼できます:

```plaintext
@duo-developer-<namespace> research whether the `PUT /api/users` endpoint also needs
rate limiting like we added to the `POST /api/users` endpoint.
Post your findings here.
```
