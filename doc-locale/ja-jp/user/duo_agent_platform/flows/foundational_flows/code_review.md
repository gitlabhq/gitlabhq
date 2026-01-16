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

{{< /details >}}

{{< collapsible title="モデル情報" >}}

- LLM: Anthropic [Claude 4.0 Sonnet](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-sonnet-4)
- [セルフホストモデル対応のGitLab Duo](../../../../administration/gitlab_duo_self_hosted/_index.md)で利用可能

{{< /collapsible >}}

{{< history >}}

- [ベータ](../../../../policy/development_stages_support.md)版として、GitLab [18.6](https://gitlab.com/groups/gitlab-org/-/epics/18645)で[フラグ](../../../../administration/feature_flags/_index.md)付きで`duo_code_review_on_agent_platform`が導入されました。デフォルトでは無効になっています。
- GitLab 18.8で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/work_items/585273)になりました。機能フラグ`duo_code_review_on_agent_platform`が[削除されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/217209)。

{{< /history >}}

> [!note]アドオンによっては、代わりにGitLab Duoコードレビュー（クラシック）にアクセスできる場合があります。[コードレビューフローの違い](#differences-from-gitlab-duo-code-review-classic)をご覧ください。

コードレビューフローは、エージェント型AIによるコードレビューを効率化するのに役立ちます。

このフローには次の特長があります:

- コードの変更、マージリクエストコメント、リンクされたイシューを分析します。
- リポジトリ構造とクロスファイルの依存関係のコンテキスト認識を強化します。
- 実用的なフィードバックを含む詳細なレビューコメントを提供します。
- プロジェクトに合わせて調整されたカスタムレビュー指示をサポートします。

このフローは、GitLab UIでのみ使用できます。

## フローを使用する {#use-the-flow}

前提条件: 

- [その他の前提条件](../_index.md#prerequisites)を満たしていることを確認してください。
- コードレビューフローが[オンになっている](../../../gitlab_duo/turn_on_off.md#turn-gitlab-duo-on-or-off)ことを確認します。

マージリクエストでコードレビューフローをトリガーするには:

1. 左側のサイドバーで、**コード** > **マージリクエスト**を選択し、マージリクエストを見つけます。
1. これらのいずれかの方法を使用して、レビューをトリガーします:
   - GitLab Duoをレビュアーとして割り当てます。
   - コメントボックスに、クイックアクション`/assign_reviewer @GitLabDuo`を入力します。

GitLab Duoとのやり取りは、次の方法で行うことができます:

- 説明や代替案を求めるために、レビューコメントに返信します。
- フォローアップの質問をするために、ディスカッションスレッドで`@GitLabDuo`に言及します。

### 自動コードレビュー {#automatic-code-reviews}

プロジェクトまたはグループの自動コードレビューを設定して、すべてのマージリクエストがGitLab Duoによる最初のレビューを受けられるようにすることができます。

[プロジェクトの自動レビューを有効にする](../../../project/merge_requests/duo_in_merge_requests.md#automatic-reviews-from-gitlab-duo-for-a-project)方法をご覧ください。

[グループとアプリケーションの自動レビューを有効にする](../../../project/merge_requests/duo_in_merge_requests.md#automatic-reviews-from-gitlab-duo-for-groups-and-applications)方法をご覧ください。

### カスタムコードレビュー指示 {#custom-code-review-instructions}

リポジトリ固有のレビュー指示で、コードレビューフローの動作をカスタマイズします。GitLab Duoを次のトリガーすることができます:

- 特定のコード品質の側面（セキュリティ、パフォーマンス、保守性など）に焦点を当てます。
- プロジェクトに固有のコーディング標準とベストプラクティスを適用します。
- 調整されたレビュー基準で特定のファイルパターンをターゲットにします。
- 特定の種類の変更について、より詳細な説明を提供します。

カスタム指示を設定するには、[GitLab Duoの指示をカスタマイズする](../../../gitlab_duo/customize_duo/review_instructions.md)を参照してください。

## GitLab Duoコードレビュー（クラシック）との違い {#differences-from-gitlab-duo-code-review-classic}

コードレビューフローは[GitLab Duoコードレビュー（クラシック）](../../../project/merge_requests/duo_in_merge_requests.md#gitlab-duo-code-review-classic)と同じコア機能を提供しますが、GitLab Duo Agent Platformの実装では、以下が提供されます:

- コンテキスト認識の向上: リポジトリ構造とクロスファイルの依存関係をより深く理解できます。
- エージェント型機能: より徹底的な分析のための多段階推論。
- 最新のアーキテクチャ: スケーラブルなGitLab Duo Agent Platform上に構築されています。

カスタム指示、自動レビュー、インタラクションパターンを含む既存のすべての機能は互換性を維持します。
