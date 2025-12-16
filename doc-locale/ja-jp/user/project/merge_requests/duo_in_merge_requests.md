---
stage: Create
group: Code Creation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: AIアシスト機能を使用して、マージリクエストに関する情報を取得します。
title: マージリクエストにおけるGitLab Duo
---

{{< alert type="disclaimer" />}}

GitLab Duoは、マージリクエストのライフサイクル中に、コンテキストに関連する情報を提供するように設計されています。

## の変更を要約して説明を生成する {#generate-a-description-by-summarizing-code-changes}

{{< details >}}

- プラン: Premium、Ultimate
- アドオン: GitLab Duo Enterprise
- 提供形態: GitLab.com、GitLab Self-Managed
- ステータス: ベータ

{{< /details >}}

{{< collapsible title="モデル情報" >}}

- LLM: Anthropic [Claude 4.0 Sonnet](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-sonnet-4)
- [セルフホストモデル対応のGitLab Duo](../../../administration/gitlab_duo_self_hosted/_index.md)で利用可能: はい

{{< /collapsible >}}

{{< history >}}

- GitLab 16.2で （[実験](../../../policy/development_stages_support.md#experiment)的機能）として[導入](https://gitlab.com/groups/gitlab-org/-/epics/10401)されました。
- GitLab 16.10でbeta（ベータ版）に[Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/429882)されました。
- GitLab 17.6以降、GitLab Duoアドオンが必須となりました。
- LLMは、GitLab 17.10でClaude 3.7 Sonnetに[更新](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/186862)されました
- 機能フラグ`add_ai_summary_for_new_mr`[enabled by default](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/186108)（デフォルトで有効）はGitLab 17.11でデフォルトで有効になりました。
- GitLab 18.0で、Premiumに含まれるようになりました。
- LLMは、GitLab 18.1でClaude 4.0 Sonnetに[更新](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/193208)されました。

{{< /history >}}

マージリクエストを作成または編集する際に、GitLab Duoマージリクエストサマリーを使用してマージリクエストの説明を作成します。

1. [新しいマージリクエスト](creating_merge_requests.md)を作成します。
1. **説明**フィールドで、説明を挿入する場所にカーソルを置きます。
1. テキスト領域の上にあるツールバーで、**コード変更のサマリー** ({{< icon name="tanuki-ai" >}})を選択します。

   ![テキスト領域の上にあるツールバーに、[コード変更のサマリー]ボタンが表示されます。](img/merge_request_ai_summary_v17_6.png)

カーソルがあった場所に説明が挿入されます。

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>[概要を見る](https://www.youtube.com/watch?v=CKjkVsfyFd8&list=PLFGfElNsQthZGazU1ZdfDpegu0HflunXW)

この機能に関するフィードバックは、[issue 443236](https://gitlab.com/gitlab-org/gitlab/-/issues/443236)で提供してください。

データ使用量: ソースブランチのヘッドとターゲットブランチの間の変更の差分が、大規模言語モデルに送信されます。

## GitLab Duoにをレビューしてもらう {#have-gitlab-duo-review-your-code}

{{< details >}}

- プラン: Premium、Ultimate
- アドオン: GitLab Duo Enterprise
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< collapsible title="モデル情報" >}}

- LLM: Anthropic [Claude 4.0 Sonnet](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-sonnet-4)
- [セルフホストモデル対応のGitLab Duo](../../../administration/gitlab_duo_self_hosted/_index.md)で利用可能: はい

{{< /collapsible >}}

{{< history >}}

- GitLab 17.5では、[実験](../../../policy/development_stages_support.md#experiment)として[導入](https://gitlab.com/groups/gitlab-org/-/epics/14825)されました。[`ai_review_merge_request`](https://gitlab.com/gitlab-org/gitlab/-/issues/456106)と[`duo_code_review_chat`](https://gitlab.com/gitlab-org/gitlab/-/issues/508632)という名前の2つの機能フラグの背後にあり、両方ともデフォルトで無効になっています。
- 機能フラグ[`ai_review_merge_request`](https://gitlab.com/gitlab-org/gitlab/-/issues/456106)および[`duo_code_review_chat`](https://gitlab.com/gitlab-org/gitlab/-/issues/508632)は、GitLab.com、GitLab Self-Managed、およびGitLab Dedicatedで17.10にデフォルトで有効になっています。
- GitLab 17.10でbeta（ベータ版）に[Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/516234)されました。
- GitLab 18.0で、Premiumに含まれるようになりました。
- GitLab 18.1で機能フラグ`ai_review_merge_request`[removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/190639)（削除）されました。
- GitLab 18.1で機能フラグ`duo_code_review_chat`[removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/190640)（削除）されました。
- GitLab 18.1でgenerally available（一般提供）となりました。
- [変更](https://gitlab.com/gitlab-org/gitlab/-/issues/524929) GitLab 18.3のベータ版で、セルフホストモデルを使用したGitLab Duoで利用できるようになりました。
- [変更](https://gitlab.com/gitlab-org/gitlab/-/issues/548975) GitLab 18.4のセルフホストモデルを使用したGitLab Duoで一般的に利用できるようになりました。

{{< /history >}}

マージリクエストをレビューする準備ができたら、GitLab Duoコードレビューを使用して初期レビューを実行します:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **コード** > **マージリクエスト**を選択して、マージリクエストを見つけます。
1. コメントボックスに、クイックアクション`/assign_reviewer @GitLabDuo`を入力するか、レビュアーとしてGitLab Duoを割り当てます。

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>[概要を見る](https://www.youtube.com/watch?v=SG3bhD1YjeY&list=PLFGfElNsQthZGazU1ZdfDpegu0HflunXW&index=2)

この機能に関するフィードバックは、issue [517386](https://gitlab.com/gitlab-org/gitlab/-/issues/517386)で提供してください。

データ使用量: この機能を使用すると、次のデータが大規模言語モデルに送信されます:

- マージリクエストのタイトル
- マージリクエストの説明
- 変更が適用される前のファイルの内容（コンテキスト用）
- マージリクエストの差分
- ファイル名
- [カスタム手順](#customize-instructions-for-gitlab-duo-code-review)

### レビューでGitLab Duoを操作する {#interact-with-gitlab-duo-in-reviews}

コメントで`@GitLabDuo`に言及して、マージリクエストでGitLab Duoを操作できます。レビューコメントに関するフォローアップの質問をしたり、マージリクエストのディスカッションスレッドで質問したりできます。

GitLab Duoとのやり取りは、マージリクエストを改善するために、提案とフィードバックを改善するのに役立ちます。

GitLab Duoに提供されたフィードバックは、他のマージリクエストのその後のレビューには影響しません。この機能を追加するリクエストがあります。[issue 560116](https://gitlab.com/gitlab-org/gitlab/-/issues/560116)を参照してください。

### プロジェクトのGitLab Duoからの自動レビュー {#automatic-reviews-from-gitlab-duo-for-a-project}

{{< history >}}

- [変更](https://gitlab.com/gitlab-org/gitlab/-/issues/506537) GitLab 18.0のUI設定になりました。

{{< /history >}}

GitLab Duoからの自動レビューにより、プロジェクト内のすべてのマージリクエストが初期レビューを受けるようになります。マージリクエストが作成されると、次の場合を除き、GitLab Duoがレビューします:

- 下書きとしてマークされている。GitLab Duoにマージリクエストをレビューさせるには、準備完了とマークします。
- 変更が含まれていない。GitLab Duoにマージリクエストをレビューさせるには、変更を追加します。

前提要件: 

- プロジェクトで少なくとも[メンテナー](../../permissions.md)ロールが必要です。

`@GitLabDuo`がマージリクエストを自動的にレビューできるようにするには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **マージリクエスト**を選択します。
1. **GitLab Duoコードレビュー**セクションで、**GitLab Duoによる自動レビューを有効にする**を選択します。
1. **変更を保存**を選択します。

### グループとアプリケーションのGitLab Duoからの自動レビュー {#automatic-reviews-from-gitlab-duo-for-groups-and-applications}

{{< details >}}

- プラン: Premium、Ultimate
- アドオン: GitLab Duo Enterprise
- 提供形態: GitLab.com
- ステータス: ベータ

{{< /details >}}

{{< history >}}

- GitLab 18.4で`cascading_auto_duo_code_review_settings`[機能フラグ](../../../administration/feature_flags/_index.md)付きの[ベータ](../../../policy/development_stages_support.md#beta)版として[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/554070)されました。デフォルトでは無効になっています。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

{{< /alert >}}

グループまたはアプリケーションの設定を使用して、複数のプロジェクトの自動レビューを有効にします。

前提要件: 

- グループの自動レビューを有効にするには、グループのオーナーロールが必要です。
- すべてのプロジェクトの自動レビューを有効にするには、管理者である必要があります。

グループの自動レビューを有効にするには:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定** > **一般**を選択します。
1. **マージリクエスト**セクションを展開します。
1. **GitLab Duoコードレビュー**セクションで、**GitLab Duoによる自動レビューを有効にする**を選択します。
1. **変更を保存**を選択します。

すべてのプロジェクトの自動レビューを有効にするには:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **一般**を選択します。
1. **GitLab Duoコードレビュー**セクションで、**GitLab Duoによる自動レビューを有効にする**を選択します。
1. **変更を保存**を選択します。

設定は、アプリケーションからグループ、プロジェクトへと段階的に適用されます。より具体的な設定は、より広範な設定をオーバーライドします。

### GitLab Duoコードレビューの指示をカスタマイズする {#customize-instructions-for-gitlab-duo-code-review}

{{< history >}}

- GitLab 18.2で`duo_code_review_custom_instructions`[機能フラグ](../../../administration/feature_flags/_index.md)付きの[ベータ](../../../policy/development_stages_support.md#beta)版として[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/545136)されました。デフォルトでは無効になっています。
- 機能フラグ`duo_code_review_custom_instructions`はGitLab 18.3で[デフォルトで有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/199802)になりました。
- GitLab 18.4で機能フラグ`duo_code_review_custom_instructions`[removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/202262)（削除）されました。

{{< /history >}}

GitLab Duoコードレビューは、プロジェクトで一貫したコードレビュー標準を確保するのに役立ちます。ファイルのglobパターンを定義し、そのパターンに一致するファイルのカスタム指示を作成します。たとえば、Rubyファイルに対してのみRubyスタイルの規則を適用し、Goファイルに対してはGoスタイルの規則を適用します。GitLab Duoは、カスタム指示を標準のレビュー基準に追加します。

カスタム指示を構成するには:

1. リポジトリのルートで、`.gitlab/duo`ディレクトリが存在しない場合は作成します。
1. `.gitlab/duo`ディレクトリに、`mr-review-instructions.yaml`という名前のファイルを作成します。
1. 次の形式を使用して、カスタム指示を追加します:

```yaml
instructions:
  - name: <instruction_group_name>
    fileFilters:
      - <glob_pattern_1>
      - <glob_pattern_2>
      - !<exclude_pattern>  # Exclude files matching this pattern
    instructions: |
      <your_custom_review_instructions>
```

例: 

```yaml
instructions:
  - name: Ruby Style Guide
    fileFilters:
      - "*.rb"
      - "lib/**/*.rb"
      - "!spec/**/*.rb"  # Exclude test files
    instructions: |
      1. Ensure all methods have proper documentation
      2. Follow Ruby style guide conventions
      3. Prefer symbols over strings for hash keys

  - name: TypeScript Source Files
    fileFilters:
      - "**/*.ts"
      - "!**/*.test.ts"  # Exclude test files
      - "!**/*.spec.ts"  # Exclude spec files
    instructions: |
      1. Ensure proper TypeScript types (avoid 'any')
      2. Follow naming conventions
      3. Document complex functions

  - name: All Files Except Tests
    fileFilters:
      - "!**/*.test.*"   # Exclude all test files
      - "!**/*.spec.*"   # Exclude all spec files
      - "!test/**/*"     # Exclude test directories
      - "!spec/**/*"     # Exclude spec directories
    instructions: |
      1. Follow consistent code style
      2. Add meaningful comments for complex logic
      3. Ensure proper error handling

  - name: Test Coverage
    fileFilters:
      - "spec/**/*_spec.rb"
    instructions: |
      1. Test both happy paths and edge cases
      2. Include error scenarios
      3. Use shared examples to reduce duplication
```

### カスタマイズされたコードレビューコメント {#customized-code-review-comments}

GitLab Duoコードレビューがカスタム指示に基づいてコードレビューコメントを生成する場合、次の形式に従います:

```plaintext
According to custom instructions in '[instruction_name]': [specific feedback]
```

例: 

```plaintext
According to custom instructions in 'Ruby Style Guide': This method should have proper documentation explaining its purpose and parameters.
```

`instruction_name`の値は、`.gitlab/duo/mr-review-instructions.yaml`ファイルの`name`プロパティに対応しています。標準のGitLab Duoのコメントでは、この引用形式は使用されません。

## コードレビューを要約する {#summarize-a-code-review}

{{< details >}}

- プラン: Premium、Ultimate
- アドオン: GitLab Duo Enterprise
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- ステータス: 実験的機能

{{< /details >}}

{{< collapsible title="モデル情報" >}}

- LLM: Anthropic [Claude 4.0 Sonnet](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-sonnet-4)
- [セルフホストモデル対応のGitLab Duo](../../../administration/gitlab_duo_self_hosted/_index.md)で利用可能: はい

{{< /collapsible >}}

{{< history >}}

- GitLab 16.0で[実験的機能](../../../policy/development_stages_support.md#experiment)として[導入](https://gitlab.com/groups/gitlab-org/-/epics/10466)されました。
- 機能フラグ`summarize_my_code_review`がGitLab 17.10で[デフォルトで有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/182448)になりました。
- LLMは、GitLab 17.11でClaude 3.7 Sonnetに[更新](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/183873)されました。
- GitLab 18.0で、Premiumに含まれるようになりました。
- LLMは、GitLab 18.1でClaude 4.0 Sonnetに[更新](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/193685)されました。

{{< /history >}}

マージリクエストのレビューを完了し、[レビューを送信](reviews/_index.md#submit-a-review)する準備ができたら、GitLab Duoコードレビューサマリーを使用してコメントのサマリーを生成します。

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **コード** > **マージリクエスト**を選択し、レビューするマージリクエストを見つけます。
1. レビューを送信する準備ができたら、**Finish review**（レビューを終了）を選択します。
1. **Add Summary**（サマリーを追加）を選択します。

サマリーはコメントボックスに表示されます。レビューを送信する前に、サマリーを編集して絞り込むことができます。

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>[概要を見る](https://www.youtube.com/watch?v=Bx6Zajyuy9k)

この実験的機能に関するフィードバックを[issue](https://gitlab.com/gitlab-org/gitlab/-/issues/408991)（イシュー）408991で提供してください。

データ使用量: この機能を使用すると、次のデータが大規模言語モデルに送信されます:

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
- [セルフホストモデル対応のGitLab Duo](../../../administration/gitlab_duo_self_hosted/_index.md)で利用可能: はい

{{< /collapsible >}}

{{< history >}}

- GitLab 16.2で`generate_commit_message_flag`[機能フラグ](../../../administration/feature_flags/_index.md)付きの[実験](../../../policy/development_stages_support.md#experiment)的機能として[導入](https://gitlab.com/groups/gitlab-org/-/epics/10453)されました。デフォルトでは無効になっています。
- 機能フラグ`generate_commit_message_flag`がGitLab 17.2で[デフォルトで有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/158339)になりました。
- GitLab 17.7で機能フラグ`generate_commit_message_flag`が[削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/173262)されました。
- GitLab 18.0で、Premiumに含まれるようになりました。
- LLMは、GitLab 18.1でClaude 4.0 Sonnetに[更新](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/193793)されました。
- GitLab 18.3でのAmazon Qのサポートに変更されました。

{{< /history >}}

マージリクエストをマージする準備をするときは、GitLab Duoマージコミットメッセージ生成を使用して、提案されたマージコミットメッセージを編集します。

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **コード** > **マージリクエスト**を選択して、マージリクエストを見つけます。
1. マージウィジェットの**コミットメッセージを編集**チェックボックスを選択します。
1. **コミットメッセージを生成する**を選択します。
1. 提供されたコミットメッセージをレビューし、**挿入**を選択してコミットに追加します。

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>[概要を見る](https://www.youtube.com/watch?v=fUHPNT4uByQ)

データ使用量: この機能を使用すると、次のデータが大規模言語モデルに送信されます:

- ファイルの内容
- ファイル名

## 関連トピック {#related-topics}

- [GitLab Duoの可用性を制御する](../../gitlab_duo/turn_on_off.md)
- [GitLab Duo機能すべて](../../gitlab_duo/_index.md)
