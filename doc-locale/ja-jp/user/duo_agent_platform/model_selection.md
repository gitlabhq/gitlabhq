---
stage: AI-powered
group: Custom Models
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: GitLab Duo機能の大規模言語モデルを設定する。
title: エージェントプラットフォームモデルの選択
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com

{{< /details >}}

すべてのGitLab Duo機能には、GitLabが選択したデフォルトの大規模言語モデルがあります。

GitLabは、機能のパフォーマンスを最適化するために、このデフォルトモデルを更新できます。そのため、ユーザーが何も操作しなくても、機能のモデルが変更される場合があります。

各機能にデフォルトモデルを使用したくない場合、または特定の要件がある場合は、利用可能な他のサポート対象モデルの配列から選択できます。

機能に特定のモデルを選択した場合、別のモデルを選択するまで、その機能はそのモデルを使用します。

## 機能のモデルを選択する {#select-a-model-for-a-feature}

{{< history >}}

- `ai_model_switching`[フラグ](../../administration/feature_flags/_index.md)とともに、GitLab 18.1でトップレベルグループ向けに[導入](https://gitlab.com/groups/gitlab-org/-/epics/17570)されました。デフォルトでは無効になっています。
- GitLab 18.4でベータ版に[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/526307)されました。
- GitLab 18.4で[有効](https://gitlab.com/gitlab-org/gitlab/-/issues/526307)になりました。
- GitLab Duo Agent Platformのモデル選択は、`duo_agent_platform_model_selection`[フラグ](../../administration/feature_flags/_index.md)とともに、GitLab 18.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/568112)されました。デフォルトでは無効になっています。
- GitLab 18.5で[一般提供](https://gitlab.com/groups/gitlab-org/-/epics/18818)になりました。機能フラグ`ai_model_switching`が有効になりました。
- GitLab 18.6で機能フラグ`duo_agent_platform_model_selection`が[有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/212051)になりました。
- GitLab 18.7で機能フラグ`ai_model_switching`が[削除](https://gitlab.com/gitlab-org/gitlab/-/issues/526307)されました。
- 機能フラグ`duo_agent_platform_model_selection`はGitLab 18.9で[削除されました](https://gitlab.com/gitlab-org/gitlab/-/issues/218591)。

{{< /history >}}

トップレベルグループの機能のモデルを選択できます。選択したモデルは、その機能に対して、すべての子グループとプロジェクトに適用されます。

前提条件: 

- グループのオーナーロールを持っている。
- モデルを選択するグループがトップレベルグループである。
- GitLab 18.3以降で、複数のGitLab Duoネームスペースに属している場合は、[デフォルトのネームスペースを割り当てる](../../user/profile/preferences.md#set-a-default-gitlab-duo-namespace)必要があります。

機能のモデルを選択するには:

1. 上部のバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定** > **GitLab Duo**を選択します。
1. **機能を設定**を選択します。
1. **GitLab Duo Agent Platform**セクションに移動します。
1. ドロップダウンリストからモデルを選択します。
1. オプション。セクション内のすべての機能にモデルを適用するには、**すべてに適用**を選択します。

{{< alert type="note" >}}

- IDEでは、GitLab Duo Chat（エージェント）のモデル選択は、接続タイプがWebSocketに設定されている場合にのみ適用されます。

- GitLab Duo Chat（エージェント）で使用されているOpenAIモデルは実験的なサポートを提供し、GPT-5、GPT-5 mini、GPT-5-Codexが対象です。この[イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/572864)で、GitLab Duo Chat（エージェント）でのOpenAIモデルの使用に関するフィードバックをお寄せください。

{{< /alert >}}

## デフォルトモデル {#default-models}

この表は、エージェントプラットフォームの各機能のデフォルトモデルを一覧表示しています。

| 機能 | モデル |
|-------|--------------|
| GitLab Duo Chat（エージェント） | Claude Haiku 4.5 |
| その他のすべてのエージェント | Claude Sonnet 4.5 Vertex |

## サポートされているモデル {#supported-models}

この表は、エージェントプラットフォームの機能で選択できるモデルを一覧表示しています。

| モデル | Agentic Chat | その他のすべてのエージェント |
|-------|--------------|------------------|
| Claude Sonnet 4 | {{< yes >}} | {{< yes >}} |
| Claude Sonnet 4 Vertex | {{< yes >}} | {{< yes >}} |
| Claude Sonnet 4.5 | {{< yes >}} | {{< yes >}} |
| Claude Sonnet 4.5 Vertex | {{< yes >}} | {{< yes >}} |
| Claude Haiku 4.5 | {{< yes >}} | {{< yes >}} |
| Claude Opus 4.5 | {{< yes >}} | {{< yes >}} |
| GPT-5 | {{< yes >}} | {{< yes >}} |
| GPT-5 Codex | {{< yes >}} | {{< yes >}} |
| GPT-5 Mini | {{< yes >}} | {{< yes >}} |
| GPT-5.2 | {{< yes >}} | {{< yes >}} |

## トラブルシューティング {#troubleshooting}

デフォルト以外のモデルを選択すると、次の問題が発生する可能性があります。

### モデルが利用できない {#model-is-not-available}

GitLab Duo AIネイティブ機能にデフォルトのGitLabモデルを使用している場合、GitLabは、最適なパフォーマンスと信頼性を維持するために、ユーザーに通知せずにデフォルトモデルを変更する場合があります。

GitLab Duo AIネイティブ機能に特定のモデルを選択していて、そのモデルが利用できない場合、自動フォールバックはありません。このモデルを使用する機能は使用できません。

### デフォルトのGitLab Duoネームスペースが設定されていない {#no-default-gitlab-duo-namespace}

選択したモデルでGitLab Duo機能を使用すると、デフォルトのGitLab Duoネームスペースが選択されていないことを示すエラーが表示される場合があります。例:

- GitLab Duoコード提案では、`Error 422: No default Duo group found. Select a default Duo group in your user preferences and try again.`が表示される場合があります
- GitLab Duo Chatでは、`Error G3002: I'm sorry, you have not selected a default GitLab Duo namespace. Please go to GitLab and in user Preferences - Behavior, select a default namespace for GitLab Duo.`が表示される場合があります

このイシューは、複数のGitLab Duoネームスペースに属しているにもかかわらず、デフォルトのネームスペースとして1つを選択していない場合に発生します。

これを解決するには、[デフォルトのGitLab Duoネームスペースを設定](../../user/profile/preferences.md#set-a-default-gitlab-duo-namespace)します。
