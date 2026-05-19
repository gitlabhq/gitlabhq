---
stage: AI-powered
group: AI Coding
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
> アドオンに応じて、GitLabでは2つのコードレビュー機能のいずれかが実行されます:
>
> - コードレビューフロー: エージェント型のGitLab Duo Agent Platformの一部です。
> - GitLab Duoコードレビュー: 非エージェント型のバージョンで、GitLab Duo Enterpriseアドオンをご利用のユーザーのみが使用できます。
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

## レビューでGitLab Duoと対話する {#interact-with-gitlab-duo-in-reviews}

コメントで`@GitLabDuo`をメンションして、マージリクエストでGitLab Duoと対話できます。レビューコメントに関するフォローアップの質問をしたり、マージリクエストのディスカッションスレッドで質問したりできます。

GitLab Duoとの対話は、マージリクエストの改善に取り組む際に、提案やフィードバックの向上に役立ちます。

GitLab Duoに提供されたフィードバックは、他のマージリクエスト以後のレビューには影響しません。この機能を追加するリクエストがあります。[イシュー560116](https://gitlab.com/gitlab-org/gitlab/-/issues/560116)を参照してください。

## カスタムコードレビュー指示 {#custom-code-review-instructions}

プロジェクト内で一貫性のある具体的なコードレビュー標準を確保するため、カスタムMRレビュー指示を作成できます。

詳細については、[GitLab Duoへのレビュー指示をカスタマイズする](customize_duo/review_instructions.md)を参照してください。

## プロジェクトのGitLab Duoによる自動レビュー {#automatic-reviews-from-gitlab-duo-for-a-project}

{{< history >}}

- GitLab 18.0でUI設定に[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/506537)されました。

{{< /history >}}

GitLab Duoの自動レビューにより、プロジェクト内のすべてのマージリクエストが初期レビューを受けるようになります。マージリクエストが作成されると、次の場合を除き、GitLab Duoがレビューします: 

- ドラフトとしてマークされている場合。GitLab Duoにマージリクエストをレビューさせるには、準備完了とマークします。
- 変更が含まれていない場合。GitLab Duoにマージリクエストをレビューさせるには、変更を追加します。

前提条件: 

- プロジェクトの[メンテナーロール](../permissions.md)以上が必要です。

`@GitLabDuo`がマージリクエストを自動的にレビューできるようにするには、以下の手順に従います: 

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **マージリクエスト**を選択します。
1. **GitLab Duoコードレビュー**セクションで、**GitLab Duoによる自動レビューを有効にする**を選択します。
1. **変更を保存**を選択します。

## グループとアプリケーションのGitLab Duoによる自動レビュー {#automatic-reviews-from-gitlab-duo-for-groups-and-applications}

{{< history >}}

- GitLab 18.4で`cascading_auto_duo_code_review_settings`[機能フラグ](../../administration/feature_flags/_index.md)とともに[ベータ版](../../policy/development_stages_support.md#beta)として[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/554070)されました。デフォルトでは無効になっています。
- 機能フラグ`cascading_auto_duo_code_review_settings`は、GitLab 18.7で[削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/213240)されました。

{{< /history >}}

グループまたはアプリケーションの設定を使用して、複数のプロジェクトで自動レビューを有効にします。

前提条件: 

- グループの自動レビューをオンにするには、グループのオーナーロールが必要です。
- すべてのプロジェクトで自動レビューをオンにするには、管理者である必要があります。

グループの自動レビューを有効にするには、以下の手順に従います: 

1. 上部のバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定** > **一般**を選択します。
1. **マージリクエスト**セクションを展開します。
1. **GitLab Duoコードレビュー**セクションで、**GitLab Duoによる自動レビューを有効にする**を選択します。
1. **変更を保存**を選択します。

すべてのプロジェクトで自動レビューを有効にするには、以下の手順に従います: 

1. 右上隅で、**管理者**を選択します。
1. 左側のサイドバーで、**設定** > **一般**を選択します。
1. **GitLab Duoコードレビュー**セクションで、**GitLab Duoによる自動レビューを有効にする**を選択します。
1. **変更を保存**を選択します。

設定は、アプリケーションからグループ、プロジェクトへとカスケードします。より具体的な設定は、より広範な設定をオーバーライドします。

## 関連トピック {#related-topics}

- [マージリクエストにおけるGitLab Duo](../project/merge_requests/duo_in_merge_requests.md)
