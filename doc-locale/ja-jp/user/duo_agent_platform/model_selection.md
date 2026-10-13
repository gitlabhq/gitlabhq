---
stage: AI Platform
group: AI Model Services
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab Duo機能の大規模言語モデルを設定します。
title: Agent PlatformのAIモデル
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

すべてのGitLab Duo機能はデフォルトのモデルを使用します。GitLabは、パフォーマンスを最適化するためにデフォルトのモデルを更新する場合があります。モデルの変更はGitLab AIゲートウェイから行われ、特に明記されていない限り、GitLabのバージョンに関係なく有効になります。

一部の機能では別のモデルを選択でき、変更するまでその選択が維持されます。

## デフォルトモデル {#default-models}

{{< history >}}

- Code Review Flowの[個別のモデル設定](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/236876)はGitLab 19.1で導入されました。
- Code Review FlowのデフォルトLLMは、2026年5月20日にClaude Sonnet 4.6 Gemini Enterprise Agent Platformに[更新されました](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/merge_requests/5555)。
- Code Review FlowのデフォルトLLMは、2026年8月6日にClaude Sonnet 5 Gemini Enterprise Agent Platformに[更新されました](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/merge_requests/6422)。

{{< /history >}}

この表は、Agent Platformの各機能で使用されるデフォルトモデルを示しています。

| 機能 | モデル |
|-------|--------------|
| GitLab Duo Agentic Chat | Claude Sonnet 4.6 Gemini Enterprise Agent Platform |
| Code Review Flow[^earlier-code-review] | Claude Sonnet 5 Gemini Enterprise Agent Platform |
| セキュリティレビューフロー | Claude Sonnet 4.6 Gemini Enterprise Agent Platform |
| その他すべてのエージェント | Claude Sonnet 4.6 Gemini Enterprise Agent Platform |

[^earlier-code-review]: GitLab 19.0以前の場合、Code Review Flowは、非エージェント型バージョンのGitLab Duoコードレビューに設定された[デフォルトLLM](../gitlab_duo/model_selection.md#default-models)を使用します。

## サポートされているモデル {#supported-models}

{{< history >}}

- GPT-5.2およびGPT-5.3 Codexが、2026年5月26日にCode Review Flowのサポート対象モデルとして[追加されました](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/merge_requests/5652)。
- Claude Sonnet 5が、2026年8月3日にCode Review Flowのサポート対象モデルとして[追加されました](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/merge_requests/6383)。
- Code Review Flowのサポート対象モデルであるClaude Sonnet 4.5は、2026年8月10日に[非推奨となり](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/merge_requests/6483)、2026年8月25日に[削除されました](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/merge_requests/6621)。
- GLM 5.3、Kimi K3、およびMiniMax M3が、2026年9月16日にGitLab Duo Agentic Chatおよびその他のすべてのエージェントのサポート対象モデルとして[追加されました](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/merge_requests/6930)。
- GPT-6 SolおよびGPT-6 Lunaが、2026年9月22日にGitLab Duo Agentic Chatおよびその他のすべてのエージェントのサポート対象モデルとして[追加されました](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/merge_requests/7062)。

{{< /history >}}

この表は、Agent Platformの機能で選択できるモデルを示しています。

| モデル                       | GitLab Duo<br> Agentic Chat | Code Review Flow[^supported-models-earlier-code-review] | セキュリティレビューフロー | その他すべてのエージェント |
|-----------------------------|-------------------------|------------------|----------------------|------------------|
| Claude Fable 5[^model-subject-limited] | {{< yes >}}             | {{< no >}}       | {{< no >}}           | {{< yes >}}      |
| Claude Fable 5.1[^model-subject-limited] | {{< yes >}}             | {{< no >}}       | {{< no >}}           | {{< yes >}}      |
| Claude Sonnet 4.5           | {{< yes >}}             | {{< no >}}      | {{< yes >}}          | {{< yes >}}      |
| Claude Sonnet 4.6           | {{< yes >}}             | {{< yes >}}      | {{< yes >}}          | {{< yes >}}      |
| Claude Sonnet 5             | {{< yes >}}             | {{< yes >}}      | {{< no >}}           | {{< yes >}}      |
| Claude Haiku 4.5            | {{< yes >}}             | {{< no >}}       | {{< no >}}           | {{< yes >}}      |
| Claude Opus 4.5             | {{< yes >}}             | {{< no >}}       | {{< no >}}           | {{< yes >}}      |
| Claude Opus 4.6             | {{< yes >}}             | {{< no >}}       | {{< no >}}           | {{< yes >}}      |
| Claude Opus 4.7             | {{< yes >}}             | {{< no >}}       | {{< no >}}           | {{< yes >}}      |
| Claude Opus 4.8             | {{< yes >}}             | {{< no >}}       | {{< no >}}           | {{< yes >}}      |
| Claude Opus 5               | {{< yes >}}             | {{< no >}}       | {{< no >}}           | {{< yes >}}      |
| Claude Opus 5.5             | {{< yes >}}             | {{< no >}}       | {{< no >}}           | {{< yes >}}      |
| Gemini 3.5 Flash            | {{< yes >}}             | {{< no >}}       | {{< no >}}           | {{< yes >}}      |
| Gemini 3.6 Flash            | {{< yes >}}             | {{< no >}}       | {{< no >}}           | {{< yes >}}      |
| Gemini 3.7 Flash            | {{< yes >}}             | {{< no >}}       | {{< no >}}           | {{< yes >}}      |
| Gemini 3.8 Flash            | {{< yes >}}             | {{< no >}}       | {{< no >}}           | {{< yes >}}      |
| GLM 5.3                     | {{< yes >}}             | {{< no >}}       | {{< no >}}           | {{< yes >}}      |
| GPT-5                       | {{< yes >}}             | {{< no >}}       | {{< no >}}           | {{< yes >}}      |
| GPT-5.1                     | {{< yes >}}             | {{< no >}}       | {{< no >}}           | {{< yes >}}      |
| GPT-5.2                     | {{< yes >}}             | {{< yes >}}      | {{< yes >}}          | {{< yes >}}      |
| GPT-5 Codex                 | {{< yes >}}             | {{< no >}}       | {{< no >}}           | {{< yes >}}      |
| GPT-5.2 Codex               | {{< yes >}}             | {{< no >}}       | {{< no >}}           | {{< yes >}}      |
| GPT-5.3 Codex               | {{< yes >}}             | {{< yes >}}      | {{< yes >}}          | {{< yes >}}      |
| GPT-5 Mini                  | {{< yes >}}             | {{< no >}}       | {{< no >}}           | {{< yes >}}      |
| GPT-5.4 Mini                | {{< yes >}}             | {{< no >}}       | {{< no >}}           | {{< yes >}}      |
| GPT-5.4 Nano                | {{< yes >}}             | {{< no >}}       | {{< no >}}           | {{< yes >}}      |
| GPT-5.5[^model-subject-limited]        | {{< yes >}}             | {{< no >}}       | {{< no >}}           | {{< yes >}}      |
| GPT-5.6 Sol[^model-subject-limited]    | {{< yes >}}             | {{< no >}}       | {{< no >}}           | {{< yes >}}      |
| GPT-5.6 Terra[^model-subject-limited]  | {{< yes >}}             | {{< no >}}       | {{< no >}}           | {{< yes >}}      |
| GPT-5.6 Luna[^model-subject-limited]   | {{< yes >}}             | {{< no >}}       | {{< no >}}           | {{< yes >}}      |
| GPT-6 Astra[^model-subject-limited]    | {{< yes >}}             | {{< no >}}       | {{< no >}}           | {{< yes >}}      |
| GPT-6 Sol[^model-subject-limited]      | {{< yes >}}             | {{< no >}}       | {{< no >}}           | {{< yes >}}      |
| GPT-6 Luna[^model-subject-limited]     | {{< yes >}}             | {{< no >}}       | {{< no >}}           | {{< yes >}}      |
| Kimi K3                     | {{< yes >}}             | {{< no >}}       | {{< no >}}           | {{< yes >}}      |
| MiniMax M3                  | {{< yes >}}             | {{< no >}}       | {{< no >}}           | {{< yes >}}      |

[^supported-models-earlier-code-review]: GitLab 19.0以前の場合、Code Review Flowは、非エージェント型バージョンのGitLab Duoコードレビューで利用可能な[モデル](../gitlab_duo/model_selection.md#gitlab-duo-for-merge-requests)のみを使用できます。 [^model-subject-limited]: このモデルには、[ベンダー側での限定的なデータ保持](../gitlab_duo/data_usage.md#data-retention)が適用されます。

## 機能のモデルを選択する {#select-a-model-for-a-feature}

{{< details >}}

- 提供形態: GitLab.com

{{< /details >}}

{{< history >}}

- `ai_model_switching`[フラグ](../../administration/feature_flags/_index.md)とともに、GitLab 18.1でトップレベルグループ向けに[導入](https://gitlab.com/groups/gitlab-org/-/work_items/17570)されました。デフォルトでは無効になっています。
- GitLab 18.4でベータ版に[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/526307)されました。
- GitLab 18.4で[有効](https://gitlab.com/gitlab-org/gitlab/-/issues/526307)になりました。
- GitLab Duo Agent Platformのモデル選択は、`duo_agent_platform_model_selection`[フラグ](../../administration/feature_flags/_index.md)とともに、GitLab 18.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/568112)されました。デフォルトでは無効になっています。
- GitLab 18.5で[一般提供](https://gitlab.com/groups/gitlab-org/-/work_items/18818)になりました。機能フラグ`ai_model_switching`が有効になりました。
- GitLab 18.6で機能フラグ`duo_agent_platform_model_selection`が[有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/212051)になりました。
- 機能フラグ`ai_model_switching`はGitLab 18.7で[削除](https://gitlab.com/gitlab-org/gitlab/-/issues/526307)されました。
- 機能フラグ`duo_agent_platform_model_selection`はGitLab 18.9で[削除](https://gitlab.com/gitlab-org/gitlab/-/issues/218591)されました。
- Code Review Flowの[個別のモデル設定](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/236876)は、GitLab 19.1で**Agentic Code Review**設定を使用して導入されました。
- GitLab 19.1で、GitLab Duo Agentic Chatで使用できるモデルを特定のモデルに制限する機能が[追加](https://gitlab.com/groups/gitlab-org/-/work_items/22028)されました。
- Security Review FlowがGitLab 19.2のモデル選択に[追加されました](https://gitlab.com/gitlab-org/gitlab/-/issues/603981)。

{{< /history >}}

トップレベルグループで、機能に使用するデフォルトモデルを選択できます。選択したモデルは、すべての子グループとプロジェクトで、その機能に適用されます。

GitLab Self-ManagedまたはGitLab Dedicatedでインスタンスのモデルを設定するには、[モデル選択](../../administration/gitlab_duo/model_selection.md)を参照してください。

前提条件: 

- グループのオーナーロールが必要です。
- モデルを選択するグループがトップレベルグループである必要があります。
- GitLab 18.3以降で、複数のGitLab Duoネームスペースに属している場合は、[デフォルトのネームスペースを割り当てる](../profile/preferences.md#set-a-default-gitlab-duo-namespace)必要があります。

### Agentic Chatのモデルを選択する {#select-a-model-for-agentic-chat}

Agentic Chatのモデルを選択するには:

1. 上部のバーで、**検索または移動先**を選択して、グループを見つけます。
1. 左側のサイドバーで、**設定** > **GitLab Duo**を選択します。
1. **モデルの選択**の下で、**モデルの管理**を選択します。
1. **GitLab Duo Agentic Chat**セクションに移動します。
1. ドロップダウンリストからモデルを選択し、デフォルトモデルとして設定します。
1. オプション。Agentic Chatでユーザーが選択できるその他のモデルを制限するには:

   1. **利用可能なモデル**の下で、**設定**を選択します。
   1. **利用可能なモデル: Agentic Chat**ダイアログで、**特定のモデルに制限**チェックボックスをオンにします。
   1. Agentic Chatで使用できるようにするモデルを選択します。すべてのモデルを選択するには、**全てのモデルを選択**チェックボックスを選択します。すべてのモデルが選択されている場合、選択を解除するには**全てのモデルを選択解除**を選択します。

      > [!note]
      > デフォルトモデルは常にユーザーが利用でき、クリアすることはできません。変更を保存するには、デフォルトモデルに加えて少なくとも1つのモデルを選択する必要があります。

   1. **保存**を選択します。

   > [!note]
   > Agentic Chatを特定のモデルに制限しない場合、ユーザーはすべてのGitLab管理モデルから選択できます。

### その他のエージェント型機能のモデルを選択 {#select-a-model-for-other-agentic-features}

その他のエージェント型機能のモデルを選択するには:

1. 上部のバーで、**検索または移動先**を選択して、グループを見つけます。
1. 左側のサイドバーで、**設定** > **GitLab Duo**を選択します。
1. **モデルの選択**の下で、**モデルの管理**を選択します。
1. **GitLab Duo Agent Platform**の下で、設定したい機能を見つけます。
1. ドロップダウンリストからモデルを選択し、デフォルトモデルとして設定します。
1. オプション。セクション内のすべての機能にモデルを適用するには、**すべてに適用**を選択します。

GitLab Duo CLIのモデルを指定するには、[モデルを選択する](../gitlab_duo_cli/use.md#select-a-model)を参照してください。

### 適切なモデルを選択する {#selecting-the-right-model}

多くのユースケースでは、Claude Haiku 4.5やGPT-5.4 Miniのような、より高速でコスト効率の高いモデルから始めるのが最適な方法です。この方法を使用する場合:

1. Claude Haiku 4.5またはGPT-5.4 Miniを選択します。
1. ユースケースを十分にテストします。
1. パフォーマンスが要件を満たしているかを評価します。
1. 特定の機能が不足している場合にのみ、必要に応じてアップグレードします。

この方法は次の用途に使用できます:

- 探索的なタスクや大量のタスク
- 厳格なレイテンシー要件があるアプリケーション
- コストを重視する実装

## トラブルシューティング {#troubleshooting}

デフォルト以外のモデルを選択すると、次の問題が発生する可能性があります。

### モデルが利用できない {#model-is-not-available}

GitLab DuoのAIネイティブ機能にGitLabのデフォルトモデルを使用している場合、GitLabは最適なパフォーマンスと信頼性を維持するために、ユーザーに通知することなくデフォルトモデルを変更する場合があります。

GitLab DuoのAIネイティブ機能に特定のモデルを選択していて、そのモデルが利用できない場合、自動フォールバックは行われません。そのモデルを使用する機能は利用できなくなります。

### デフォルトのGitLab Duoのネームスペースが設定されていない {#no-default-gitlab-duo-namespace}

選択したモデルでGitLab Duo機能を使用しているときに、デフォルトのGitLab Duoのネームスペースを設定する必要があることを示すエラーが発生する場合があります。

この問題は、複数のGitLab Duoネームスペースに属している場合、またはGitLabリモートが設定されていないプロジェクトにおいてローカルで作業している場合に発生します。

これを解決するには、[デフォルトのGitLab Duoのネームスペースを設定](../profile/preferences.md#set-a-default-gitlab-duo-namespace)します。

### IDEでAgentic Chatのモデル選択が機能しない {#model-selection-for-agentic-chat-in-ides-does-not-work}

IDEでAgentic Chatのモデルを選択しても、モデル選択が機能しない場合があります。

これを解決するには:

1. IDEの接続タイプがWebSocketに設定されていることを確認します。
1. [GitLabインスタンスへのWebSocketトラフィックが許可されている](../../administration/gitlab_duo/configure/_index.md#allow-inbound-connections-from-clients-to-the-gitlab-instance)ことをネットワーク管理者に確認します。
