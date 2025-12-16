---
stage: AI-powered
group: Workflow Catalog
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: AIカタログ
---

{{< details >}}

- プラン: Premium、Ultimate
- アドオン: GitLab Duo Core、Pro、またはEnterprise
- 提供形態: GitLab.com、GitLab Self-Managed
- ステータス: 実験的機能

{{< /details >}}

{{< collapsible title="モデル情報" >}}

- LLM: Anthropic [Claude Sonnet 4](https://www.anthropic.com/claude/sonnet)

{{< /collapsible >}}

{{< history >}}

- GitLab 18.5で`global_ai_catalog`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/549914)されました。GitLab.comで有効になりました。これは[実験的機能](../../policy/development_stages_support.md)です。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

{{< /alert >}}

AIカタログは、エージェント型AIをプロジェクトに追加するために使用できるエージェントのリストです。エージェントは、マージリクエストの作成などのタスクを実行し、複雑な質問に答えることができます。

AIカタログを使用して、以下を行います:

- GitLabチームおよびコミュニティメンバーによって作成されたエージェントを見つけます。
- エージェントを作成し、プロジェクト間で共有します。
- エージェントをプロジェクトに追加し、GitLab Duoチャット（エージェント型）で使用します。

## AIカタログを表示する {#view-the-ai-catalog}

前提要件: 

- [前提条件](_index.md#prerequisites)を満たす必要があります。
- AIカタログのエージェントを使用するには、PremiumまたはUltimateサブスクリプションがあるグループネームスペースに属するプロジェクトが必要です。

AIカタログを表示するには:

1. 左側のサイドバーで、**検索または移動先** > **検索**を選択します。
1. **AIカタログ**を選択します。

## 関連トピック {#related-topics}

- [エージェント](agents/_index.md)
