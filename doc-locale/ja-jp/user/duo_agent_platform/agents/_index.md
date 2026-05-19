---
stage: AI-powered
group: Workflow Catalog
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: エージェント
---

{{< details >}}

- プラン: [Free](../../../subscriptions/gitlab_credits.md#for-the-free-tier-on-gitlabcom)、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< collapsible title="モデル情報" >}}

- [デフォルトLLM](../model_selection.md#default-models)

{{< /collapsible >}}

{{< history >}}

- GitLab 18.5で`global_ai_catalog`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/549914)されました。GitLab.comで有効になりました。
- GitLab 18.7で基本エージェントとカスタムエージェントがベータ版に[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/568176)されました。
- GitLab 18.8で基本エージェント、外部エージェント、カスタムエージェントが[一般提供](https://gitlab.com/gitlab-org/gitlab/-/work_items/585273)になりました。
- 機能フラグ`global_ai_catalog`は18.10で[削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/223135)されました。
- GitLab 18.10では、GitLab.comのFreeティアでGitLabクレジットとともに利用できます。

{{< /history >}}

エージェントは、特定のタスクの実行や複雑な質問への回答を支援する、AI搭載アシスタントです。

GitLabでは、次の3種類のエージェントを利用できます:

- [基本エージェント](foundational_agents/_index.md)は、GitLabが一般的なワークフロー向けに作成した、事前構築済みで本番環境に対応したエージェントです。これらのエージェントには、特定のドメインに関する専門知識とツールが組み込まれています。基本エージェントはデフォルトでオンになっているため、GitLab Duo Chatですぐに使い始めることができます。
- [カスタムエージェント](custom.md)は、チーム固有のニーズに合わせて作成および設定するエージェントです。システムプロンプトを通じてその動作を定義し、アクセス可能なツールを選択します。カスタムエージェントは、基本エージェントではカバーできない、より専門的なワークフローが必要な場合に最適です。カスタムエージェントとやり取りするには、グループまたはプロジェクトで有効にして、Chatで使用できるようにします。
- [外部エージェント](external.md)は、GitLab外部のAIモデルプロバイダーと連携します。外部エージェントを使用して、ClaudeなどのモデルプロバイダーをGitLabで動作させることができます。外部エージェントは、ディスカッション、イシュー、またはマージリクエストから直接トリガーできます。
