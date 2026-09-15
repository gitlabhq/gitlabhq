---
stage: AI Coding
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab Duoコードレビュー（非エージェント型）
---

{{< details >}}

- プラン: Premium、Ultimate
- アドオン: GitLab Duo Enterprise
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< collapsible title="モデル情報" >}}

- [デフォルトLLM](model_selection.md#default-models)
- [セルフホストモデル対応のGitLab Duo](../../administration/gitlab_duo_self_hosted/_index.md)で利用可能

{{< /collapsible >}}

{{< history >}}

- GitLab 17.5で、[実験的機能](../../policy/development_stages_support.md#experiment)として、[導入](https://gitlab.com/groups/gitlab-org/-/epics/14825)されました。機能フラグ[`ai_review_merge_request`](https://gitlab.com/gitlab-org/gitlab/-/issues/456106)と[`duo_code_review_chat`](https://gitlab.com/gitlab-org/gitlab/-/issues/508632)の背後で動作しており、どちらもデフォルトでは無効になっています。
- 機能フラグ[`ai_review_merge_request`](https://gitlab.com/gitlab-org/gitlab/-/issues/456106)および[`duo_code_review_chat`](https://gitlab.com/gitlab-org/gitlab/-/issues/508632)は、17.10のGitLab.com、GitLab Self-Managed、GitLab Dedicatedでデフォルトで有効になっています。
- GitLab 17.10でベータ版に[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/516234)されました。
- GitLab 18.0でPremiumを含むように変更されました。
- 機能フラグ`ai_review_merge_request`は、GitLab 18.1で[削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/190639)されました。
- 機能フラグ`duo_code_review_chat`は、GitLab 18.1で[削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/190640)されました。
- GitLab 18.1で一般提供になりました。
- GitLab 18.3でセルフホストモデル対応のGitLab Duoでベータ版として利用可能に[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/524929)されました。
- GitLab 18.4でセルフホストモデル対応のGitLab Duoで一般提供に[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/548975)されました。

{{< /history >}}

> [!note]
> アドオンとグループの設定に応じて、GitLabでは以下の2つのコードレビュー機能のいずれかが実行されます:
>
> - コードレビューフロー: GitLab Duo Agent Platformの一部であるエージェント型バージョン。
> - GitLab Duoコードレビュー: GitLab Duo Enterpriseアドオンを使用するユーザーのみが利用できる非エージェント型バージョン。
>
> このページでは、非エージェント型のバージョンについて説明します。[2つの機能の比較説明](../project/merge_requests/duo_in_merge_requests.md#use-gitlab-duo-to-review-your-code)をご覧ください。

GitLab Duoコードレビューは、プロジェクトでのコードレビューを効率化するのに役立ちます。

## GitLab Duoコードレビューを使用する {#use-gitlab-duo-code-review}

マージリクエストをレビューする準備ができたら、GitLab Duoコードレビューを使用して初期レビューを実行します: 

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 左側のサイドバーで、**コード** > **マージリクエスト**を選択して、マージリクエストを見つけます。
1. コメントボックスに、クイックアクション`/assign_reviewer @GitLabDuo`を入力するか、GitLab Duoをレビュアーとして割り当てます。

<i class="fa-youtube-play" aria-hidden="true"></i> [概要を見る](https://www.youtube.com/watch?v=SG3bhD1YjeY&list=PLFGfElNsQthZGazU1ZdfDpegu0HflunXW&index=2)

この機能に関するフィードバックは、[イシュー517386](https://gitlab.com/gitlab-org/gitlab/-/issues/517386)で提供してください。

### コンテキスト認識 {#contextual-awareness}

GitLab Duoコードレビューを使用すると、以下のデータが大規模言語モデルに送信されます:

- マージリクエストのタイトル
- マージリクエストの説明
- 変更が適用される前のファイルの内容（コンテキスト用）
- マージリクエストの差分
- ファイル名
- カスタム指示

除外するコンテンツを指定するには、[コードレビューからコンテキストを除外する](context.md#exclude-context-from-code-review)を参照してください。

#### 大規模なマージリクエストでの動作 {#behavior-on-large-merge-requests}

GitLab Duoコードレビューは、マージリクエストの差分と、変更されたファイルの元の内容をモデルに送信します。結合されたプロンプトは、[選択されたモデル](model_selection.md)のコンテキストウィンドウの対象となります。

大規模なマージリクエストの場合、GitLab Duoコードレビューは成功するレビューの可能性を高めるためにフォールバックを使用します:

1. 最初のリクエストには、マージリクエストの差分と元のファイル内容が含まれます。
1. このリクエストが失敗した場合、GitLab Duoコードレビューは元のファイル内容なしで自動的に再試行します。
1. 再試行も失敗した場合、GitLab Duoコードレビューは一般的なエラーメッセージを返します。

ファイル内容なしでの再試行は、プロンプトサイズを縮小しますが、変更をレビューする際にモデルが持つコンテキストも縮小します。コメントは、元のファイル内容を含むレビューよりも具体的ではない可能性があります。

GitLab DuoコードレビューのAIゲートウェイリクエストタイムアウトは120秒です。このウィンドウ内で完了しないレビューも、一般的なエラーとして表示されます。

大規模なマージリクエストでの失敗したレビューのリスクを軽減するには:

- 大規模なマージリクエストをより小さなマージリクエストに分割します。
- レビューに関連しないファイルの[コンテキストを除外](context.md#exclude-context-from-code-review)する。
- メンテナーまたはオーナーに、コードレビュー用の[別のモデルを選択](model_selection.md#select-a-model-for-a-feature)するよう依頼してください。

## レビューでGitLab Duoとやり取りする {#interact-with-gitlab-duo-in-reviews}

コメントで`@GitLabDuo`をメンションして、マージリクエストでGitLab Duoと対話できます。レビューコメントに関するフォローアップの質問をしたり、マージリクエストのディスカッションスレッドで質問したりできます。

GitLab Duoとの対話は、マージリクエストの改善に取り組む際に、提案やフィードバックの向上に役立ちます。

GitLab Duoに提供したフィードバックは、他のマージリクエストの以降のレビューには影響しません。この機能を追加するリクエストがあります。[イシュー560116](https://gitlab.com/gitlab-org/gitlab/-/issues/560116)を参照してください。

## カスタムコードレビュー指示 {#custom-code-review-instructions}

プロジェクト内で一貫性のある具体的なコードレビュー標準を確保するため、カスタムMRレビュー指示を作成できます。

詳細については、[GitLab Duoへのレビュー指示をカスタマイズする](customize_duo/review_instructions.md)を参照してください。

## 自動レビュー {#automatic-reviews}

{{< history >}}

- GitLab 18.0で、プロジェクトの自動レビューがUI設定に[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/506537)されました。
- GitLab 18.4で、グループとインスタンス向けの自動レビューが、[ベータ](../../policy/development_stages_support.md#beta)版として[機能フラグ](../../administration/feature_flags/_index.md) `cascading_auto_duo_code_review_settings`と共に[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/554070)されました。デフォルトでは無効になっています。
- 機能フラグ`cascading_auto_duo_code_review_settings`はGitLab 18.7で[削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/213240)されました。

{{< /history >}}

GitLab Duoによる自動レビューにより、プロジェクト、グループ、またはインスタンスのすべてのマージリクエストが最初のレビューを受けることが保証されます。

ユーザーがマージリクエストを作成すると、GitLab Duoは自動的にレビューを行いますが、以下の場合を除きます:

- ドラフトとしてマークされている場合。GitLab Duoにマージリクエストをレビューさせるには、準備完了とマークします。
- 変更が含まれていない場合。GitLab Duoにマージリクエストをレビューさせるには、変更を追加します。
- 設定した1つ以上の除外ルールと一致する場合。GitLab Duoがマージリクエストをレビューするようにするには、手動でレビューをリクエストしてください。

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

### プロジェクトのマージリクエストを除外する {#exclude-merge-requests-for-a-project}

{{< history >}}

- GitLab 19.2で`duo_code_review_automated_rules`[フラグ](../../administration/feature_flags/_index.md)とともに[ベータ版](../../policy/development_stages_support.md#beta)として[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/240236)されました。デフォルトでは有効になっています。
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
> グループ向けに[カスタムレビュー指示](customize_duo/review_instructions.md#configure-custom-review-instructions-for-a-group)を保存するプロジェクトをすでに設定している場合、`mr-review-automated-rules.yaml`を同じプロジェクトに保存します。グループのコードレビューをカスタマイズするために指定できるプロジェクトは1つだけであるため、GitLabは自動的にそのプロジェクトも除外ルールについてチェックします。以下の手順を再度実行する必要はありません。

前提条件: 

- グループのオーナーロール。
- グループ内のプロジェクトに、グループに適用する除外ルールが含まれている。

グループの除外ルールを設定するには:

1. 上部のバーで、**検索または移動先**を選択して、グループを見つけます。
1. 左側のサイドバーで、**設定** > **一般** > **GitLab Duoの機能**を選択します。
1. **コードレビューをカスタマイズ**で、`.gitlab/duo/mr-review-automated-rules.yaml`ファイルが含まれているプロジェクトを選択します。
1. **変更を保存**を選択します。

## トラブルシューティング {#troubleshooting}

### 大規模なマージリクエストでのレビューが失敗する {#review-fails-on-a-large-merge-request}

GitLab Duoコードレビューは、多数の大きな変更されたファイルを含むマージリクエストへのレビューの投稿に失敗する場合があります。一般的な原因は次のとおりです:

- 差分と元のファイル内容の合計サイズがモデルのコンテキストウィンドウを超過しています。
- AIゲートウェイのリクエストに120秒以上かかります。

再試行とタイムアウトの動作の詳細については、[大規模なマージリクエストでの動作](#behavior-on-large-merge-requests)を参照してください。

失敗を回避するには:

- マージリクエストを、より小さなマージリクエストに分割する。
- レビューに関連しないファイルの[コンテキストを除外](context.md#exclude-context-from-code-review)する。

詳細については、[イシュー596794](https://gitlab.com/gitlab-org/gitlab/-/work_items/596794)を参照してください。

## 関連トピック {#related-topics}

- [マージリクエストにおけるGitLab Duo](../project/merge_requests/duo_in_merge_requests.md)
- [GitLab Duo Enterpriseシートでコードレビューフローをオンにする](../project/merge_requests/duo_in_merge_requests.md#turn-on-code-review-flow-for-gitlab-duo-enterprise-seats)。
