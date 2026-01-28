---
stage: AI-powered
group: Code Creation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: コードレビューフロー
---

{{< details >}}

- プラン: Premium、Ultimate
- アドオン: GitLab Duo CoreまたはPro
- 提供形態: GitLab.com、GitLab Self-Managed

この機能は[GitLabクレジット](../../../../subscriptions/gitlab_credits.md)を使用します。

{{< /details >}}

{{< collapsible title="モデル情報" >}}

- LLM: Anthropic [Claude 4.0 Sonnet](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-sonnet-4)
- [セルフホストモデル対応のGitLab Duo](../../../../administration/gitlab_duo_self_hosted/_index.md)で利用可能

{{< /collapsible >}}

{{< history >}}

- [ベータ](../../../../policy/development_stages_support.md)としてGitLab [18.7](https://gitlab.com/groups/gitlab-org/-/epics/18645)で、`duo_code_review_on_agent_platform`という名前の[with a flag](../../../../administration/feature_flags/_index.md)で導入されました。デフォルトでは無効になっています。
- GitLab 18.8で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/work_items/585273)になりました。機能フラグ`duo_code_review_on_agent_platform`は[削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/217209)されました。

{{< /history >}}

> [!note] アドオンによっては、GitLab Duoコードレビュー（クラシック）を利用できる場合があります。[コードレビューフローとの違い](#differences-from-gitlab-duo-code-review-classic)をご確認ください。

コードレビューフローは、エージェント型AIを活用してコードレビューを効率化します。

このフローには次の特長があります:

- コードの変更、マージリクエストコメント、リンクされたイシューを分析します。
- リポジトリ構造やファイル間の依存関係を踏まえて、より高度にコンテキストを理解します。
- 実行可能なフィードバックを含む、詳細なレビューコメントを提供します。
- プロジェクトに合わせてカスタマイズされたレビュー指示をサポートします。

このフローは、GitLab UIでのみ使用できます。

## フローを使用する {#use-the-flow}

前提条件: 

- [その他の前提条件](../_index.md#prerequisites)を満たしていることを確認してください。
- コードレビューフローが[オンになっている](../../../gitlab_duo/turn_on_off.md#turn-gitlab-duo-on-or-off)ことを確認してください。

マージリクエストでコードレビューフローをトリガーするには:

1. 左側のサイドバーで、**コード** > **マージリクエスト**を選択して、マージリクエストを見つけます。
1. 次のいずれかの方法でレビューをトリガーします:
   - GitLab Duoをレビュアーとして割り当てます。
   - コメントボックスに、クイックアクション`/assign_reviewer @GitLabDuo`を入力します。

次の方法でGitLab Duoとやり取りします:

- レビューコメントに返信して、補足説明や代替案を求めます。
- ディスカッションスレッドで`@GitLabDuo`をメンションし、フォローアップの質問を行います。

### 自動コードレビュー {#automatic-code-reviews}

プロジェクトまたはグループに対して自動コードレビューを設定することで、すべてのマージリクエストにGitLab Duoによる初回レビューが行われるようになります。

[プロジェクトの自動レビューを有効にする](../../../project/merge_requests/duo_in_merge_requests.md#automatic-reviews-from-gitlab-duo-for-a-project)方法をご覧ください。

[グループおよびアプリケーションの自動レビューを有効にする](../../../project/merge_requests/duo_in_merge_requests.md#automatic-reviews-from-gitlab-duo-for-groups-and-applications)方法をご覧ください。

### カスタムコードレビュー指示 {#custom-code-review-instructions}

リポジトリ固有のレビュー指示で、コードレビューフローの動作をカスタマイズします。次のようにGitLab Duoに指示できます:

- 特定のコード品質の側面（セキュリティ、パフォーマンス、保守性など）に重点を置く。
- プロジェクトに固有のコーディング標準やベストプラクティスを適用する。
- 特定のファイルパターンを対象に、カスタマイズされたレビュー基準を適用する。
- 特定の種類の変更について、より詳細な説明を提供する。

カスタム指示を設定するには、[GitLab Duoへの指示をカスタマイズする](../../../gitlab_duo/customize_duo/review_instructions.md)を参照してください。

## GitLab Duoコードレビュー（クラシック）との違い {#differences-from-gitlab-duo-code-review-classic}

コードレビューフローは、[GitLab Duoコードレビュー（クラシック）](../../../project/merge_requests/duo_in_merge_requests.md#gitlab-duo-code-review-classic)と同等の中核的な機能を提供しますが、GitLab Duo Agent Platform上の実装では次の点が強化されています:

- コンテキスト認識の向上: リポジトリ構造やファイル間の依存関係をより正確に把握します。
- エージェント型機能: より徹底的な分析を行うための多段階推論をサポートします。
- 最新のアーキテクチャ: スケーラブルなGitLab Duo Agent Platform上に構築されています。

カスタム指示、自動レビュー、インタラクションパターンを含む既存のすべての機能は、引き続き互換性があります。
