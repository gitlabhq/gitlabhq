---
stage: AI-powered
group: Workflow Catalog
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: エージェント
---

{{< details >}}

- プラン: Premium、Ultimate
- アドオン: GitLab Duo Core、Pro、またはEnterprise
- 提供形態: GitLab.com、GitLab Self-Managed

{{< /details >}}

{{< collapsible title="モデル情報" >}}

- LLM: Anthropic [Claude Sonnet 4](https://www.anthropic.com/claude/sonnet)

{{< /collapsible >}}

{{< history >}}

- GitLab 18.5で`global_ai_catalog`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/549914)されました。GitLab.comで有効になりました。
- GitLab 18.7で基本エージェントとカスタムエージェントがベータ版に[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/568176)されました。
- GitLab 18.8で基本エージェント、外部エージェント、カスタムエージェントが[一般提供](https://gitlab.com/gitlab-org/gitlab/-/work_items/585273)になりました。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

{{< /alert >}}

エージェントは、特定のタスクを達成し、複雑な質問に答えるのに役立つAI搭載のアシスタントです。

GitLabは、3種類のエージェントを提供しています:

- [基本エージェント](foundational_agents/_index.md)は、GitLabが一般的なワークフローのために作成した、すぐに使用できる本番環境対応のエージェントです。これらのエージェントには、特定のドメインに関する専門的な知識とツールが付属しています。基本エージェントはデフォルトでオンになっているため、GitLab Duo Chatですぐに使用を開始できます。
- [Custom agents](custom.md)は、チーム固有のニーズに合わせて作成および構成するエージェントです。システムプロンプトを通じてその動作を定義し、アクセスできるツールを選択します。カスタムエージェントは、基本エージェントでは対応できない特殊なワークフローが必要な場合に最適です。カスタムエージェントを操作するには、グループまたはプロジェクトで有効にして、Chatで使用できるようにします。
- [External agents](external.md)は、GitLab外のAIモデルプロバイダーと統合します。外部エージェントを使用して、ClaudeのようなモデルプロバイダーがGitLabで動作できるようにします。外部エージェントは、ディスカッション、イシュー、またはマージリクエストから直接トリガーできます。

エージェントを使用するには、[prerequisites](../_index.md#prerequisites)を満たす必要があります。
