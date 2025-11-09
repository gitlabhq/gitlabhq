---
stage: AI-powered
group: Custom Models
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: GitLab Duoの機能のために大規模言語モデルを設定します。
title: GitLab Duoモデルの選択
---

{{< details >}}

- プラン: Premium、Ultimate
- アドオン: GitLab Duo Core、Pro、またはEnterprise。
- 提供形態: GitLab.com

{{< /details >}}

{{< history >}}

- GitLab 18.4で[一般提供](https://gitlab.com/groups/gitlab-org/-/epics/18818)になりました。

{{< /history >}}

すべてのGitLab Duo機能には、GitLabによって選択された、事前選択済みのデフォルトの大規模言語モデル（LLM）があります。

GitLabは、機能のパフォーマンスを最適化するために、このデフォルトのLLMを更新できます。したがって、機能のLLMは、ユーザーが何もしなくても変更される可能性があります。

各機能にデフォルトのLLMを使用しない場合、または特定の要件がある場合は、利用可能な他のサポートされているLLMの配列から選択できます。

機能に特定のLLMを選択すると、別のLLMを選択するまで、その機能はそのLLMを使用します。

## 機能のLLMを選択します {#select-an-llm-for-a-feature}

### GitLab.com {#on-gitlabcom}

{{< history >}}

- [導入](https://gitlab.com/groups/gitlab-org/-/epics/17570)：GitLab 18.1のトップレベルグループ。`ai_model_switching`という名前の[機能フラグ](../../administration/feature_flags/_index.md)。デフォルトでは無効になっています。
- GitLab 18.4でベータ版に[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/526307)されました。
- GitLab 18.4で、[デフォルトで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/526307)になりました。
- [導入](https://gitlab.com/gitlab-org/gitlab/-/issues/568112)：GitLab 18.4のGitLab Duo Agent Platformのモデル選択。`duo_agent_platform_model_selection`という名前の[機能フラグ](../../administration/feature_flags/_index.md)。デフォルトでは無効になっています。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

{{< /alert >}}

GitLab.comでは、トップレベルグループの機能のモデルを選択できます。選択したモデルは、すべての子グループとプロジェクトのその機能に適用されます。

前提要件: 

- LLMを選択するグループは、以下を満たす必要があります。:
  - GitLab.comのトップレベルグループまたはネームスペースであること。
  - GitLab Duo Core、Pro、またはEnterpriseが有効になっていること。
- グループまたはネームスペースのオーナーロールが必要です。
- GitLab 18.3以降では、複数のGitLab Duoネームスペースに属している場合は、[デフォルトのネームスペースを割り当てる](#assign-a-default-gitlab-duo-namespace)必要があります。

機能に別のLLMを選択するには：:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定** > **GitLab Duo**を選択します。

   **GitLab Duo**が表示されない場合は、グループに対してGitLab Duo Core、Pro、またはEnterpriseがオンになっていることを確認してください。
1. **機能を設定**を選択します。
1. 構成する機能について、ドロップダウンリストからLLMを選択します。

![トップグループレベルでモデルを選択するためのGitLab UI](img/configure_model_selections_v18_1.png)

{{< alert type="note" >}}

- GitLab Duo Agentic Chatのモデル選択は、GitLab Duo Chat（クラシック）とは独立しています。各機能は個別に構成する必要があります。一方を変更しても、もう一方には影響しません。

- IDEでは、Agentic Chatのモデル選択は、「接続タイプ」がwebsocketsに設定されている場合にのみ適用されます。デフォルトの接続タイプはgRPCです。

- Agentic Chatで使用されているOpenAIモデルは、特にGPT-5、GPT-5 mini、およびGPT-5-Codexに対して実験的なサポートがあります。Agentic ChatでOpenAIモデルを使用することについてのフィードバックを、この[イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/572864)に残してください。

{{< /alert >}}

#### デフォルトのGitLab Duoネームスペースを割り当てる {#assign-a-default-gitlab-duo-namespace}

{{< history >}}

- [導入](https://gitlab.com/gitlab-org/gitlab/-/issues/552081)は、[機能フラグ](../../administration/feature_flags/_index.md)という名前でGitLab 18.3で`ai_user_default_duo_namespace`されました。デフォルトでは無効になっています。
- GitLab 18.4で、[デフォルトで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/560319)になりました。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

{{< /alert >}}

複数のGitLab Duoネームスペースに属している場合は、1つをデフォルトのネームスペースとして選択する必要があります。

これは、GitLab Duoが作業中のネームスペースを自動的に検出できず、その結果、使用するLLMを検出できない可能性があるため、これを行う必要があります。次に例を示します。:

- CLIでGitLab Duoを使用する場合。
- 新しいプロジェクトがGitで初期化されていないため、IDEは関連付けられたネームスペースを識別できません。

これが発生した場合、GitLab Duoはデフォルトのネームスペースで選択したLLMを使用します。

デフォルトのネームスペースを選択するには：:

1. GitLab.comで、左側のサイドバーでアバターを選択します。
1. **設定**を選択します。
1. **動作**セクションに移動します。
1. **デフォルトのGitLab Duoのネームスペース**ドロップダウンリストから、デフォルトとして設定するネームスペースを選択します。
1. **変更を保存**を選択します。

## トラブルシューティング {#troubleshooting}

デフォルト以外のモデルを選択すると、次の問題が発生する可能性があります。

### 大規模言語モデルは利用できません {#llm-is-not-available}

GitLab Duo AIネイティブ機能にGitLab Default LLMを使用している場合、GitLabは最適なパフォーマンスと信頼性を維持するために、ユーザーに通知することなくデフォルトのLLMを変更する可能性があります。

GitLab Duo AIネイティブ機能に特定のLLMを選択していて、そのLLMが利用できない場合、自動フォールバックはなく、このLLMを使用する機能は利用できません。

### コード補完のレイテンシーの問題 {#latency-issues-with-code-completion}

[コード補完](../project/repository/code_suggestions/_index.md#code-completion-and-generation)に特定のLLMが選択されたプロジェクトでシートが割り当てられている場合：:

- IDE拡張機能は、[AIゲートウェイへの直接接続](../../administration/gitlab_duo/gateway.md#region-support)を無効にします。
- コード補完リクエストはGitLabモノリスを通過し、次に指定されたモデルを選択して、これらのリクエストに応答します。

これにより、コード補完リクエストでレイテンシーが増加する可能性があります。

### デフォルトのGitLab Duoネームスペースがありません {#no-default-gitlab-duo-namespace}

選択したLLMでGitLab Duo機能を使用すると、デフォルトのGitLab Duoネームスペースを選択していないことを示すエラーが表示されることがあります。次に例を示します。、。:

- GitLab Duoコード提案では、`Error 422: No default Duo group found. Select a default Duo group in your user preferences and try again.`が表示される場合があります
- GitLab Duoチャットでは、`Error G3002: I'm sorry, you have not selected a default GitLab Duo namespace. Please select a default GitLab Duo namespace in your user preferences.`が表示される場合があります

この問題は、次の場合に発生します。:

- `ai_user_default_duo_namespace`機能フラグが有効になっています。
- 複数のGitLab Duoネームスペースに属していますが、1つをデフォルトのネームスペースとして選択していません。

これを解決するには、次のいずれかを実行できます。:

- [デフォルトのGitLab Duoネームスペースを割り当てる](#assign-a-default-gitlab-duo-namespace)。
- モデル選択機能がベータ版である間、この要件をオプトアウトするには、[GitLab Support](https://about.gitlab.com/support/)に`ai_user_default_duo_namespace`機能フラグを無効にするように依頼してください。
