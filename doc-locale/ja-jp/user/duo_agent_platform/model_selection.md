---
stage: AI-powered
group: Custom Models
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab Duo機能の大規模言語モデルを設定する。
title: Agent PlatformのAIモデル
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

すべてのGitLab Duo機能はデフォルトのモデルを使用します。GitLabは、パフォーマンスを最適化するためにデフォルトのモデルを更新する場合があります。一部の機能では別のモデルを選択でき、変更するまでその選択が維持されます。

## デフォルトモデル {#default-models}

この表は、Agent Platformの各機能で使用されるデフォルトモデルを示しています。

| 機能 | モデル |
|-------|--------------|
| GitLab Duo Agentic Chat | Claude Sonnet 4.6 Vertex |
| コードレビューフロー | Claude Sonnet 4.6 Vertex |
| その他すべてのエージェント | Claude Sonnet 4.6 Vertex |

## サポートされているモデル {#supported-models}

この表は、Agent Platformの機能で選択できるモデルを示しています。

| モデル                | GitLab Duo Agentic Chat | コードレビューフロー | その他すべてのエージェント |
|----------------------|-------------------------|------------------|------------------|
| Claude Fable 5 <sup>1</sup>      | {{< yes >}}             | {{< no >}}       | {{< yes >}}      |
| Claude Sonnet 4.5    | {{< yes >}}             | {{< yes >}}      | {{< yes >}}      |
| Claude Sonnet 4.6    | {{< yes >}}             | {{< yes >}}      | {{< yes >}}      |
| Claude Haiku 4.5     | {{< yes >}}             | {{< no >}}       | {{< yes >}}      |
| Claude Opus 4.5      | {{< yes >}}             | {{< no >}}       | {{< yes >}}      |
| Claude Opus 4.6      | {{< yes >}}             | {{< no >}}       | {{< yes >}}      |
| Claude Opus 4.7      | {{< yes >}}             | {{< no >}}       | {{< yes >}}      |
| Claude Opus 4.8      | {{< yes >}}             | {{< no >}}       | {{< yes >}}      |
| Gemini 3.5 Flash     | {{< yes >}}             | {{< no >}}       | {{< yes >}}      |
| GPT-5                | {{< yes >}}             | {{< no >}}       | {{< yes >}}      |
| GPT-5.1              | {{< yes >}}             | {{< no >}}       | {{< yes >}}      |
| GPT-5.2              | {{< yes >}}             | {{< yes >}}      | {{< yes >}}      |
| GPT-5.5 <sup>1</sup> | {{< yes >}}             | {{< no >}}       | {{< yes >}}      |
| GPT-5 Codex          | {{< yes >}}             | {{< no >}}       | {{< yes >}}      |
| GPT-5.2 Codex        | {{< yes >}}             | {{< no >}}       | {{< yes >}}      |
| GPT-5.3 Codex        | {{< yes >}}             | {{< yes >}}      | {{< yes >}}      |
| GPT-5 Mini           | {{< yes >}}             | {{< no >}}       | {{< yes >}}      |
| GPT-5.4 Mini         | {{< yes >}}             | {{< no >}}       | {{< yes >}}      |
| GPT-5.4 Nano         | {{< yes >}}             | {{< no >}}       | {{< yes >}}      |

**補足説明**: 

1. このモデルには、[ベンダー側での限定的なデータ保持](../gitlab_duo/data_usage.md#data-retention)が適用されます。

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
- 機能フラグ`ai_model_switching`は、GitLab 18.7で[削除](https://gitlab.com/gitlab-org/gitlab/-/issues/526307)されました。
- 機能フラグ`duo_agent_platform_model_selection`はGitLab 18.9で[削除](https://gitlab.com/gitlab-org/gitlab/-/issues/218591)されました。
- GitLab 19.1で、コードレビューフロー向けにLLMがClaude Sonnet 4.6 Vertexに[更新](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/236876)されました。
- GitLab 19.1で、コードレビューフロー向けにGitLab Duoコードレビューとは[別個のモデル選択](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/236876)が導入され、**エージェント型コードレビュー**設定を使用するようになりました。
- GPT-5.2およびGPT-5.3 Codexが、コードレビューフローの選択可能なモデルとしてGitLab 19.1で[追加されました](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/merge_requests/5652)。
- GitLab Duo Agentic Chatを特定のモデルに制限する機能が、GitLab 19.1で[追加されました](https://gitlab.com/groups/gitlab-org/-/work_items/22028)。

{{< /history >}}

トップレベルグループでは、機能ごとにモデルを選択できます。選択したモデルは、その機能に対して、すべての子グループとプロジェクトに適用されます。

前提条件: 

- グループのオーナーロールが必要です。
- モデルを選択するグループがトップレベルグループである必要があります。
- GitLab 18.3以降で、複数のGitLab Duoネームスペースに属している場合は、[デフォルトのネームスペースを割り当てる](../profile/preferences.md#set-a-default-gitlab-duo-namespace)必要があります。

### Agentic Chatのモデルを選択 {#select-a-model-for-agentic-chat}

Agentic Chatのモデルを選択するには:

1. 上部のバーで、**検索または移動先**を選択して、グループを見つけます。
1. 左側のサイドバーで、**設定** > **GitLab Duo**を選択します。
1. **機能を設定**を選択します。
1. **GitLab Duo Agentic Chat**セクションに移動します。
1. ドロップダウンリストからモデルを選択し、デフォルトモデルとして設定します。
1. オプション。オプション。ユーザーがAgentic Chat用に選択できる他のモデルを制限するには:

   1. **Available models**の下で、**設定する**を選択します。
   1. **Available models: Agentic Chat**ダイアログで、**Restrict to specific models**チェックボックスを選択します。
   1. Agentic Chatが使用できるモデルを選択します。
   1. **保存**を選択します。

   > [!note]
   > Agentic Chatを特定のモデルに制限しない場合、ユーザーはすべてのGitLab管理対象モデルから選択できます。

### 非Agentic Chat機能のモデルを選択 {#select-a-model-for-a-non-agentic-chat-feature}

非Agentic Chat機能のモデルを選択するには:

1. 上部のバーで、**検索または移動先**を選択して、グループを見つけます。
1. 左側のサイドバーで、**設定** > **GitLab Duo**を選択します。
1. **機能を設定**を選択します。
1. **GitLab Duo Agent Platform**セクションに移動します。
1. ドロップダウンリストからモデルを選択し、デフォルトモデルとして設定します。
1. オプション。セクション内のすべての機能にモデルを適用するには、**すべてに適用**を選択します。

GitLab Duo CLIのモデルを指定するには、[モデルを選択する](../gitlab_duo_cli/_index.md#select-a-model)を参照してください。

### 適切なモデルの選択 {#selecting-the-right-model}

多くのユースケースでは、Claude Haiku 4.5やGPT-5.4 Miniのような、より高速でコスト効率の高いモデルから始めるのが最適なアプローチとなり得ます。このアプローチの場合:

1. Claude Haiku 4.5またはGPT-5.4 Miniを選択します。
1. ユースケースを徹底的にテストします。
1. パフォーマンスが要件を満たしているかを評価します。
1. 特定の機能ギャップのために必要な場合にのみアップグレードします。

このアプローチは次の用途に使用できます:

- 探索的または大量のタスク
- 厳格なレイテンシー要件を持つアプリケーション
- コストに敏感な実装

## トラブルシューティング {#troubleshooting}

デフォルト以外のモデルを選択すると、次の問題が発生する可能性があります。

### モデルが利用できない {#model-is-not-available}

GitLab Duo AIネイティブ機能にデフォルトのGitLabモデルを使用している場合、GitLabは、最適なパフォーマンスと信頼性を維持するために、ユーザーに通知せずにデフォルトモデルを変更する場合があります。

GitLab Duo AIネイティブ機能に特定のモデルを選択していて、そのモデルが利用できない場合、自動フォールバックはありません。このモデルを使用する機能は使用できません。

### デフォルトのGitLab Duoのネームスペースが設定されていない {#no-default-gitlab-duo-namespace}

選択したモデルでGitLab Duo機能を使用しているときに、デフォルトのGitLab Duoのネームスペースを設定する必要があることを示すエラーが発生する場合があります。

この問題は、複数のGitLab Duoネームスペースに属している場合、またはGitLabリモートが設定されていないプロジェクトにおいてローカルで作業している場合に発生します。

これを解決するには、[デフォルトのGitLab Duoのネームスペースを設定](../profile/preferences.md#set-a-default-gitlab-duo-namespace)します。

### IDEでのAgentic Chatのモデル選択が機能しない {#model-selection-for-agentic-chat-in-ides-does-not-work}

ご使用のIDEでAgentic Chatのモデルを選択しているときに、モデル選択が機能しない場合があります。

これを解決するには、次の手順に従います:

1. ご使用のIDEの接続タイプがWebSocketに設定されていることを確認してください。
1. ネットワーク管理者に依頼して、GitLabインスタンスへのWebSocketトラフィックが[許可されていること](../../administration/gitlab_duo/configure/_index.md#allow-inbound-connections-from-clients-to-the-gitlab-instance)を確認してもらってください。
