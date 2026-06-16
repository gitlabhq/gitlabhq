---
stage: AI-powered
group: Custom Models
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab Duo機能の大規模言語モデルを設定する。
title: エージェントプラットフォームAIモデル
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

すべてのGitLab Duo機能はデフォルトのモデルを使用します。GitLabは、パフォーマンスを最適化するためにデフォルトのモデルを更新する場合があります。一部の機能では、別のモデルを選択でき、そのモデルは変更するまで維持されます。

## デフォルトモデル {#default-models}

この表は、Agent Platformの各機能で使用されるデフォルトモデルを示しています。

| 機能 | モデル |
|-------|--------------|
| GitLab Duo Agentic Chat | Claude Sonnet 4.6 Vertex |
| コードレビューフロー | Claude Sonnet 4.6 Vertex |
| その他すべてのエージェント | Claude Sonnet 4.5 Vertex |

## サポートされているモデル {#supported-models}

この表は、Agent Platformの機能で選択できるモデルを示しています。

| モデル                | GitLab Duo Agentic Chat | コードレビューフロー | その他すべてのエージェント |
|----------------------|-------------------------|------------------|------------------|
| Claude Sonnet 4      | {{< yes >}}             | {{< yes >}}      | {{< yes >}}      |
| Claude Sonnet 4.5    | {{< yes >}}             | {{< yes >}}      | {{< yes >}}      |
| Claude Sonnet 4.6    | {{< yes >}}             | {{< yes >}}      | {{< yes >}}      |
| Claude Haiku 4.5     | {{< yes >}}             | {{< no >}}       | {{< yes >}}      |
| Claude Opus 4.5      | {{< yes >}}             | {{< no >}}       | {{< yes >}}      |
| Claude Opus 4.6      | {{< yes >}}             | {{< no >}}       | {{< yes >}}      |
| Claude Opus 4.7      | {{< yes >}}             | {{< no >}}       | {{< yes >}}      |
| GPT-5                | {{< yes >}}             | {{< no >}}       | {{< yes >}}      |
| GPT-5.1              | {{< yes >}}             | {{< no >}}       | {{< yes >}}      |
| GPT-5.2              | {{< yes >}}             | {{< no >}}       | {{< yes >}}      |
| GPT-5.5 <sup>1</sup> | {{< yes >}}             | {{< no >}}       | {{< yes >}}      |
| GPT-5 Codex          | {{< yes >}}             | {{< no >}}       | {{< yes >}}      |
| GPT-5.2 Codex        | {{< yes >}}             | {{< no >}}       | {{< yes >}}      |
| GPT-5.3 Codex        | {{< yes >}}             | {{< no >}}       | {{< yes >}}      |
| GPT-5 Mini           | {{< yes >}}             | {{< no >}}       | {{< yes >}}      |
| GPT-5.4 Mini         | {{< yes >}}             | {{< no >}}       | {{< yes >}}      |
| GPT-5.4 Nano         | {{< yes >}}             | {{< no >}}       | {{< yes >}}      |

**脚注**: 

1. このモデルは、[ベンダー側の制限されたデータ保持](../gitlab_duo/data_usage.md#data-retention)の対象となります。

## 機能のモデルを選択する {#select-a-model-for-a-feature}

{{< details >}}

- 提供形態: GitLab.com

{{< /details >}}

{{< history >}}

- `ai_model_switching`[フラグ](../../administration/feature_flags/_index.md)とともに、GitLab 18.1でトップレベルグループ向けに[導入](https://gitlab.com/groups/gitlab-org/-/epics/17570)されました。デフォルトでは無効になっています。
- GitLab 18.4でベータ版に[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/526307)されました。
- GitLab 18.4で[有効](https://gitlab.com/gitlab-org/gitlab/-/issues/526307)になりました。
- GitLab Duo Agent Platformのモデル選択は、`duo_agent_platform_model_selection`[フラグ](../../administration/feature_flags/_index.md)とともに、GitLab 18.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/568112)されました。デフォルトでは無効になっています。
- GitLab 18.5で[一般提供](https://gitlab.com/groups/gitlab-org/-/epics/18818)になりました。機能フラグ`ai_model_switching`が有効になりました。
- GitLab 18.6で機能フラグ`duo_agent_platform_model_selection`が[有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/212051)になりました。
- GitLab 18.7で機能フラグ`ai_model_switching`が[削除](https://gitlab.com/gitlab-org/gitlab/-/issues/526307)されました。
- 機能フラグ`duo_agent_platform_model_selection`は、GitLab 18.9で[削除](https://gitlab.com/gitlab-org/gitlab/-/issues/218591)されました。
- LLMは、GitLab 19.1でコードレビューフローのためにClaude Sonnet 4.6 Vertexに[更新されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/236876)。
- GitLab 19.1で、コードレビューフロー向けにGitLab Duoコードレビューから[個別のモデル選択](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/236876)が導入され、**Agentic Code Review**設定が使用されるようになりました。

{{< /history >}}

トップレベルグループの機能のモデルを選択できます。選択したモデルは、その機能に対して、すべての子グループとプロジェクトに適用されます。

前提条件: 

- グループのオーナーロールを持っている。
- モデルを選択するグループがトップレベルグループである。
- GitLab 18.3以降で、複数のGitLab Duoネームスペースに属している場合は、[デフォルトのネームスペースを割り当てる](../profile/preferences.md#set-a-default-gitlab-duo-namespace)必要があります。

機能のモデルを選択するには:

1. 上部のバーで、**検索または移動先**を選択して、グループを見つけます。
1. 左サイドバーで、**設定** > **GitLab Duo**を選択します。
1. **機能を設定**を選択します。
1. **GitLab Duo Agent Platform**セクションに移動します。
1. ドロップダウンリストからモデルを選択します。
1. オプション。セクション内のすべての機能にモデルを適用するには、**すべてに適用**を選択します。

IDEでは、GitLab Duo Agentic Chatのモデル選択は、接続タイプがWebSocketに設定されている場合にのみ適用されます。

GitLab Duo CLIのモデルを指定するには、[モデルを選択](../gitlab_duo_cli/_index.md#select-a-model)を参照してください。

## トラブルシューティング {#troubleshooting}

デフォルト以外のモデルを選択すると、次の問題が発生する可能性があります。

### モデルが利用できない {#model-is-not-available}

GitLab Duo AIネイティブ機能にデフォルトのGitLabモデルを使用している場合、GitLabは、最適なパフォーマンスと信頼性を維持するために、ユーザーに通知せずにデフォルトモデルを変更する場合があります。

GitLab Duo AIネイティブ機能に特定のモデルを選択していて、そのモデルが利用できない場合、自動フォールバックはありません。このモデルを使用する機能は使用できません。

### デフォルトのGitLab Duoネームスペースが設定されていない {#no-default-gitlab-duo-namespace}

選択したモデルでGitLab Duo機能を使用しているときに、デフォルトのGitLab Duoネームスペースを設定する必要があることを示すエラーが発生する場合があります。

この問題は、複数のGitLab Duoネームスペースに属している場合や、GitLabリモートが設定されていないプロジェクトでローカルに作業している場合に発生します。

これを解決するには、[デフォルトのGitLab Duoネームスペースを設定](../profile/preferences.md#set-a-default-gitlab-duo-namespace)します。
