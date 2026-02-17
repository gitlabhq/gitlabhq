---
stage: AI-powered
group: Code Creation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: コードレビューフロー
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed

この機能は[GitLabクレジット](../../../../subscriptions/gitlab_credits.md)を使用します。

{{< /details >}}

{{< collapsible title="モデル情報" >}}

- LLM: Anthropic [Claude 4.0 Sonnet](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-sonnet-4)
- [セルフホストモデル対応のGitLab Duo](../../../../administration/gitlab_duo_self_hosted/_index.md)で利用可能

{{< /collapsible >}}

{{< history >}}

- GitLab [18.7](https://gitlab.com/groups/gitlab-org/-/epics/18645)で`duo_code_review_on_agent_platform`[フラグ](../../../../administration/feature_flags/_index.md)とともに[ベータ版](../../../../policy/development_stages_support.md)として導入されました。デフォルトでは無効になっています。
- GitLab 18.8で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/work_items/585273)になりました。機能フラグ`duo_code_review_on_agent_platform`は[削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/217209)されました。

{{< /history >}}

> [!note] アドオンによっては、GitLab Duoコードレビュー（クラシック）を利用できる場合があります。[2つの機能の比較](../../../../user/project/merge_requests/duo_in_merge_requests.md#use-gitlab-duo-to-review-your-code)について学びます。

コードレビューフローは、エージェント型AIを活用してコードレビューを効率化します。

このフローには次の特長があります:

- コードの変更、マージリクエストコメント、リンクされたイシューを分析します。
- リポジトリ構造やファイル間の依存関係を踏まえて、より高度にコンテキストを理解します。
- 実行可能なフィードバックを含む、詳細なレビューコメントを提供します。
- プロジェクトに合わせて調整されたカスタムレビュー指示をサポートします。

このフローはGitLab UIでのみ使用できます。

## フローを使用する {#use-the-flow}

前提条件: 

- [Agent Platformの前提条件](../../../../user/duo_agent_platform/_index.md#prerequisites)を満たしていることを確認してください。
- トップレベルグループで**基本flowを許可する**と**コードレビュー**が[オンになっている](../../../gitlab_duo/turn_on_off.md#turn-gitlab-duo-on-or-off)ことを確認してください。

マージリクエストでコードレビューFlowを使用するには:

1. 左側のサイドバーで、**コード** > **マージリクエスト**を選択して、マージリクエストを見つけます。
1. これらのいずれかの方法を使用して、リクエストをレビューしてください:
   - `@GitLabDuo`をレビュアーとして割り当てます。
   - コメントボックスに、クイックアクション`/assign_reviewer @GitLabDuo`を入力します。

リクエストをレビューすると、コードレビューFlowは[session](../../sessions/_index.md)を開始します。レビューが完了するまで監視できます。

## レビューでGitLab Duoと対話する {#interact-with-gitlab-duo-in-reviews}

レビュアーとしてGitLab Duoを割り当てるだけでなく、次の方法でGitLab Duoとやり取りできます:

- レビューコメントに返信して、補足説明や代替案を求める。
- ディスカッションスレッドで`@GitLabDuo`をメンションし、フォローアップの質問を行う。

GitLab Duoとの対話は、マージリクエストの改善に取り組む際に、提案やフィードバックの向上に役立ちます。

GitLab Duoに提供されたフィードバックは、他のマージリクエストのその後のレビューには影響しません。この機能を追加するリクエストがあります。[イシュー560116](https://gitlab.com/gitlab-org/gitlab/-/issues/560116)を参照してください。

## カスタムコードレビュー指示 {#custom-code-review-instructions}

リポジトリ固有のレビュー指示で、コードレビューフローの動作をカスタマイズします。次のようにGitLab Duoに指示できます:

- 特定のコード品質の側面（セキュリティ、パフォーマンス、保守性など）に重点を置く。
- プロジェクトに固有のコーディング標準やベストプラクティスを適用する。
- 特定のファイルパターンを対象に、カスタマイズされたレビュー基準を適用する。
- 特定の種類の変更について、より詳細な説明を提供する。

カスタム指示を設定するには、[GitLab Duoへの指示をカスタマイズする](../../../gitlab_duo/customize_duo/review_instructions.md)を参照してください。

## プロジェクトのGitLab Duoによる自動レビュー {#automatic-reviews-from-gitlab-duo-for-a-project}

{{< history >}}

- GitLab 18.0でUI設定に[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/506537)されました。

{{< /history >}}

GitLab Duoの自動レビューにより、プロジェクト内のすべてのマージリクエストが初期レビューを受けるようになります。マージリクエストが作成されると、次の場合を除き、GitLab Duoがレビューします: 

- ドラフトとしてマークされている場合。GitLab Duoにマージリクエストをレビューさせるには、準備完了とマークします。
- 変更が含まれていない場合。GitLab Duoにマージリクエストをレビューさせるには、変更を追加します。

前提条件: 

- プロジェクトの[メンテナーロール](../../../permissions.md)以上が必要です。

`@GitLabDuo`がマージリクエストを自動的にレビューできるようにするには: 

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **マージリクエスト**を選択します。
1. **GitLab Duoコードレビュー**セクションで、**GitLab Duoによる自動レビューを有効にする**を選択します。
1. **変更を保存**を選択します。

## グループとアプリケーションのGitLab Duoによる自動レビュー {#automatic-reviews-from-gitlab-duo-for-groups-and-applications}

{{< history >}}

- GitLab 18.4で`cascading_auto_duo_code_review_settings`[機能フラグ](../../../../administration/feature_flags/_index.md)とともに[ベータ版](../../../../policy/development_stages_support.md#beta)として[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/554070)されました。デフォルトでは無効になっています。
- 機能フラグ`cascading_auto_duo_code_review_settings`は、GitLab 18.7で[削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/213240)されました。

{{< /history >}}

グループまたはアプリケーションの設定を使用して、複数のプロジェクトで自動レビューを有効にします。

前提条件: 

- グループの自動レビューをオンにするには、グループのオーナーロールが必要です。
- すべてのプロジェクトで自動レビューをオンにするには、管理者である必要があります。

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

## 関連トピック {#related-topics}

- [マージリクエストにおけるGitLab Duo](../../../../user/project/merge_requests/duo_in_merge_requests.md)
