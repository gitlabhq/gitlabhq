---
stage: AI-powered
group: Custom Models
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: GitLab Duo機能の大規模言語モデルを設定する。
title: GitLab Duoモデル選択
---

{{< details >}}

- プラン: Premium、Ultimate
- アドオン: GitLab Duo Core、Pro、またはEnterprise
- 提供形態: GitLab.com

{{< /details >}}

すべてのGitLab Duo機能には、GitLabが選択したデフォルトの大規模言語モデルがあります。

GitLabは、機能のパフォーマンスを最適化するために、このデフォルトモデルを更新できます。そのため、お客様が何も操作しなくても、機能のモデルが変更される場合があります。

各機能にデフォルトモデルを使用したくない場合、または特定の要件がある場合は、利用可能な他のサポート対象モデルの配列から選択できます。

機能に特定のモデルを選択した場合、別のモデルを選択するまで、その機能はそのモデルを使用します。

## 機能のモデルを選択する {#select-a-model-for-a-feature}

{{< history >}}

- `ai_model_switching`[フラグ](../../administration/feature_flags/_index.md)とともに、GitLab 18.1でトップレベルグループ向けに[導入](https://gitlab.com/groups/gitlab-org/-/epics/17570)されました。デフォルトでは無効になっています。
- GitLab 18.4でベータ版に[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/526307)されました。
- [有効](https://gitlab.com/gitlab-org/gitlab/-/issues/526307)（GitLab 18.4）。
- GitLab Duo Agent Platformのモデル選択は、`duo_agent_platform_model_selection`[フラグ](../../administration/feature_flags/_index.md)とともに、GitLab 18.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/568112)されました。デフォルトでは無効になっています。
- [一般提供](https://gitlab.com/groups/gitlab-org/-/epics/18818)（GitLab 18.5）。機能フラグ`ai_model_switching`が有効になりました。
- 機能フラグ`duo_agent_platform_model_selection`が[有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/212051)になりました（GitLab 18.6）。
- 機能フラグ`ai_model_switching`が[削除](https://gitlab.com/gitlab-org/gitlab/-/issues/526307)されました（GitLab 18.7）。

{{< /history >}}

{{< alert type="flag" >}}

GitLab Duoエージェントプラットフォームに対するこの機能の可用性は、機能フラグによって制御されます。詳細については、履歴を参照してください。

{{< /alert >}}

トップレベルグループの機能のモデルを選択できます。選択したモデルは、その機能に対して、すべての子グループとプロジェクトに適用されます。

前提条件: 

- グループのオーナーロールを持っている。
- モデルを選択するグループがトップレベルグループであること。
- GitLab 18.3以降で、複数のGitLab Duoネームスペースに属している場合は、[デフォルトのネームスペースを割り当てる](#assign-a-default-gitlab-duo-namespace)必要があります。

機能のモデルを選択するには:

1. 上部のバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定** > **GitLab Duo**を選択します。
1. **機能を設定**を選択します。
1. 設定する機能で、ドロップダウンリストからモデルを選択します。
1. オプション。セクション内のすべての機能にモデルを適用するには、**すべてに適用**を選択します。

![トップグループレベルでモデルを選択するためのGitLab UI](img/configure_model_selections_v18_1.png)

{{< alert type="note" >}}

- GitLab Duo Chat（エージェント型）のモデル選択は、GitLab Duo Chat（クラシック）とは独立しています。各機能は個別に設定する必要があります。一方の変更は他方に影響しません。

- IDEでは、GitLab Duo Chat（エージェント型）のモデル選択は、接続タイプがWebSocketに設定されている場合にのみ適用されます。

- GitLab Duo Chat（エージェント型）で使用されているOpenAIモデルは、GPT-5、GPT-5 mini、GPT-5-Codexに対して特に実験的なサポートを提供します。この[イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/572864)で、GitLab Duo Chat（エージェント型）でのOpenAIモデルの使用に関するフィードバックをお寄せください。

{{< /alert >}}

### デフォルトのGitLab Duoネームスペースを割り当てる {#assign-a-default-gitlab-duo-namespace}

複数のGitLab Duoネームスペースに属している場合は、1つをデフォルトのネームスペースとして選択する必要があります。

GitLab Duoが作業中のネームスペースを自動的に検出できない場合、デフォルトのネームスペースを使用して、使用するモデルを判断します。

[デフォルトのGitLab Duoネームスペースを設定する](../../user/profile/preferences.md#set-a-default-gitlab-duo-namespace)方法について説明します。

## トラブルシューティング {#troubleshooting}

デフォルト以外のモデルを選択すると、次の問題が発生する可能性があります。

### モデルは利用できません {#model-is-not-available}

GitLab Duo AIネイティブ機能にデフォルトのGitLabモデルを使用している場合、GitLabは、最適なパフォーマンスと信頼性を維持するために、ユーザーに通知せずにデフォルトモデルを変更する場合があります。

GitLab Duo AIネイティブ機能に特定のモデルを選択し、そのモデルが利用できない場合、自動フォールバックはありません。このモデルを使用する機能は使用できません。

### コード補完のレイテンシーの問題 {#latency-issues-with-code-completion}

[コード補完](../project/repository/code_suggestions/_index.md#code-completion-and-generation)に特定のモデルが選択されているプロジェクトの割り当てられたシートがある場合:

- IDE拡張機能が[AIゲートウェイへの直接接続](../../administration/gitlab_duo/gateway.md#region-support)を無効にします。
- コード補完リクエストはGitLabモノリスを経由し、次に指定されたモデルを選択して、これらのリクエストに応答します。

これにより、コード補完リクエストのレイテンシーが増加する可能性があります。

### デフォルトのGitLab Duoネームスペースが設定されていない {#no-default-gitlab-duo-namespace}

選択したモデルでGitLab Duo機能を使用すると、デフォルトのGitLab Duoネームスペースが選択されていないことを示すエラーが表示される場合があります。例:

- GitLab Duoコード提案では、`Error 422: No default Duo group found. Select a default Duo group in your user preferences and try again.`が表示される場合があります
- GitLab Duo Chatでは、`Error G3002: I'm sorry, you have not selected a default GitLab Duo namespace. Please go to GitLab and in user Preferences - Behavior, select a default namespace for GitLab Duo.`が表示される場合があります

このイシューは、複数のGitLab Duoネームスペースに属しているにもかかわらず、デフォルトのネームスペースとして1つを選択していない場合に発生します。

これを解決するには、[デフォルトのGitLab Duoネームスペースを設定](../../user/profile/preferences.md#set-a-default-gitlab-duo-namespace)します。
