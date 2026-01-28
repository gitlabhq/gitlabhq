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

この機能は[GitLabクレジット](../../subscriptions/gitlab_credits.md)を使用します。

{{< /details >}}

{{< collapsible title="モデル情報" >}}

- LLM: Anthropic [Claude Sonnet 4](https://www.anthropic.com/claude/sonnet)

{{< /collapsible >}}

{{< history >}}

- GitLab 18.5で`global_ai_catalog`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/549914)されました。GitLab.comで[実験](../../policy/development_stages_support.md)として有効。
- 外部エージェントのサポートは、`ai_catalog_third_party_flows`というフラグ名でGitLab 18.6で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/207610)されました。GitLab.comで[実験](../../policy/development_stages_support.md)として有効。
- GitLab 18.7でベータ版に[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/568176)されました。
- GitLab 18.8で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/work_items/585273)になりました。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

{{< /alert >}}

AIカタログは、エージェントとワークフローの一元的なリストです。これらのエージェントとワークフローをプロジェクトに追加して、エージェント型AIのタスクの編成を開始します。

AIカタログを使用して以下を行います:

- GitLabチームとコミュニティメンバーが作成したエージェントとワークフローを見つけます。
- カスタムエージェントとワークフローを作成し、他のユーザーと共有します。
- プロジェクトでエージェントとワークフローを有効にして、GitLab Duo Agent Platform全体で使用できるようにします。

## AIカタログを表示する {#view-the-ai-catalog}

前提条件: 

- 前提[条件](_index.md#prerequisites)を満たす必要があります。
- GitLab.comでは、[GitLab Duoの実験的機能とベータ機能をオン](../../user/gitlab_duo/turn_on_off.md#on-gitlabcom-2)にしたトップレベルグループのメンバーである必要があります。
- AIカタログからエージェントとワークフローを有効にするには、プロジェクトのメンテナーロール以上が必要です。

AIカタログを表示するには:

1. 上部のバーで、**検索または移動先** > **検索**を選択します。
1. **AIカタログ**を選択します。

エージェントのリストが表示されます。利用可能なワークフローを表示するには、**フロー**タブを選択します。

## エージェントとワークフローのバージョン {#agent-and-flow-versions}

{{< history >}}

- GitLab 18.7で[導入](https://gitlab.com/groups/gitlab-org/-/epics/20022)されました。

{{< /history >}}

AIカタログ内の各カスタムエージェントとワークフローは、バージョン履歴を保持します。アイテムの設定を変更すると、GitLabは自動的に新しいバージョンを作成します。基本的なエージェントとワークフローはバージョニングを使用しません。

GitLabは、変更のスコープを示すためにセマンティックバージョニングを使用します。たとえば、エージェントのバージョン番号は、`1.0.0`や`1.1.0`のようになります。GitLabは、セマンティックバージョニングを自動的に管理します。エージェントまたはワークフローの更新は、常にマイナーバージョンをインクリメントします。

バージョニングにより、プロジェクトとグループは、テスト済みの安定したエージェントまたはワークフローの設定を引き続き使用できます。これにより、予期しない変更がワークフローに影響を与えるのを防ぎます。

### バージョンの作成 {#creating-versions}

GitLabは、次の場合にバージョンを作成します:

- カスタムエージェントのシステムプロンプトを更新します。
- 外部エージェントまたはワークフローの設定を変更します。

一貫した動作を保証するため、バージョンはイミュータブルです。

### バージョンのピン留め {#version-pinning}

AIカタログのアイテムをグループまたはプロジェクトで有効にすると、GitLabは特定のバージョンにピン留めします:

- グループでは、GitLabは最新バージョンをピン留めします。
- プロジェクトでは、GitLabはプロジェクトのトップレベルグループと同じバージョンをピン留めします。

バージョンのピン留めとは:

- プロジェクトまたはグループは、アイテムの固定バージョンを使用します。
- AIカタログ内のエージェントまたはワークフローを更新しても、設定には影響しません。
- 新しいバージョンをいつ採用するかを制御できます。

このアプローチは、AIを活用したワークフローに安定性と予測可能性をもたらします。

### 現在のバージョンを表示 {#view-the-current-version}

前提条件: 

- デベロッパーロール以上が必要です。

エージェントまたはワークフローの現在のバージョンを表示するには:

1. 上部のバーで、**検索または移動先**を選択し、プロジェクトまたはグループを見つけます。
1. 左側のサイドバーで、次のいずれかを選択します:
   - **自動化** > **エージェント**
   - **自動化** > **フロー**
1. エージェントまたはワークフローを選択して、詳細を表示します。

詳細ページには、以下が表示されます:

- プロジェクトまたはグループが使用しているピン留めされたバージョン。
- バージョン識別子。たとえば`1.2.0`などです。
- その特定のバージョンの設定に関する詳細。

### 最新バージョンに更新 {#update-to-the-latest-version}

前提条件: 

- メンテナーロール以上が必要です。

グループまたはプロジェクトでエージェントまたはワークフローの最新バージョンを使用するには:

1. 上部のバーで、**検索または移動先**を選択し、プロジェクトまたはグループを見つけます。
1. 左側のサイドバーで、次のいずれかを選択します:
   - **自動化** > **エージェント**
   - **自動化** > **フロー**
1. 更新するエージェントまたはワークフローを選択します。
1. 最新バージョンを注意深く確認します。更新するには、**最新バージョンを表示** > **`<x.y.z>`へ更新**を選択します。

## 関連トピック {#related-topics}

- [エージェント](agents/_index.md)
- [外部エージェント](agents/external.md)
