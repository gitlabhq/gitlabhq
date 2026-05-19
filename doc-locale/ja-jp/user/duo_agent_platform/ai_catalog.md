---
stage: AI-powered
group: Workflow Catalog
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: AIカタログ
---

{{< details >}}

- プラン: [Free](../../subscriptions/gitlab_credits.md#for-the-free-tier-on-gitlabcom)、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< collapsible title="モデル情報" >}}

- LLM: Anthropic [Claude Sonnet 4](https://www.anthropic.com/claude/sonnet)

{{< /collapsible >}}

{{< history >}}

- GitLab 18.5で`global_ai_catalog`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/549914)されました。GitLab.comで[実験的機能](../../policy/development_stages_support.md)として有効になりました。
- GitLab 18.6で外部エージェントのサポートが`ai_catalog_third_party_flows`フラグとともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/207610)されました。GitLab.comで[実験的機能](../../policy/development_stages_support.md)として有効になりました。
- GitLab 18.7でベータ版に[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/568176)されました。
- GitLab 18.8で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/work_items/585273)になりました。
- 機能フラグ`global_ai_catalog`は18.10で[削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/223135)されました。
- GitLab 18.10でGitLab.comのFreeティアでGitLabクレジットとともに利用可能です。

{{< /history >}}

AIカタログは、エージェントとフローを一元的に管理するためのリストです。エージェント型AIのタスクのオーケストレーションを開始するには、これらのエージェントとフローをプロジェクトに追加します。

AIカタログを使用すると、次のことが可能です:

- GitLabチームとコミュニティメンバーが作成したエージェントとフローを見つける。
- カスタムエージェントやカスタムフローを作成し、他のユーザーと共有する。
- プロジェクトでエージェントやフローを有効にして、GitLab Duo Agent Platform全体で使用する。

## AIカタログを表示する {#view-the-ai-catalog}

{{< history >}}

- GitLab Duoサイドバーを使用してAIカタログを表示する機能は、GitLab 18.11で[導入](https://gitlab.com/gitlab-org/gitlab/-/work_items/592493)されました。

{{< /history >}}

前提条件: 

- [前提条件](_index.md#prerequisites)を満たしている必要があります。
- AIカタログからエージェントやフローを有効にするには:
  - グループでは、メンテナーまたはオーナーロールが必要です。
  - プロジェクトでは、メンテナーまたはオーナーロールが必要です。

AIカタログを表示するには、次のいずれかの方法があります:

- トップバーを使用する:
  1. 上部のバーで、**検索または移動先** > **検索**を選択します。
  1. **AIカタログ**を選択します。

- GitLab Duoサイドバーを使用する:
  1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
  1. GitLab Duoサイドバーで、**GitLab Duo AIカタログ** ({{< icon name="tanuki-ai" >}}) を選択します。

エージェントのリストが表示されます。

GitLab Self-Managedでは、以下のエージェントはAIカタログに表示されません:

- GitLab.comで作成されたカスタムエージェント。
- GitLabによって管理されている外部エージェントで、インスタンスに[追加されていないもの](agents/external.md#add-gitlab-managed-agents-to-other-instances)。

利用可能なフローを表示するには、**フロー**タブを選択します。

## エージェントとフローのバージョン {#agent-and-flow-versions}

{{< history >}}

- GitLab 18.7で[導入](https://gitlab.com/groups/gitlab-org/-/epics/20022)されました。

{{< /history >}}

AIカタログ内の各カスタムエージェントおよびカスタムフローは、バージョン履歴を保持します。アイテムの設定を変更すると、GitLabは自動的に新しいバージョンを作成します。基本エージェントと基本フローはバージョニングを使用しません。

GitLabでは、変更のスコープを示すためにセマンティックバージョニングを使用しています。たとえば、エージェントのバージョン番号は、`1.0.0`や`1.1.0`のようになります。GitLabはセマンティックバージョニングを自動的に管理します。エージェントまたはフローの更新では、常にマイナーバージョンをインクリメントします。

バージョニングにより、プロジェクトやグループは、テスト済みの安定したエージェントまたはフローの設定を継続的に使用できます。これにより、予期しない変更がワークフローに影響を及ぼすのを防ぐことができます。

### バージョンを作成する {#creating-versions}

GitLabは、次の場合にバージョンを作成します:

- カスタムエージェントのシステムプロンプトを更新した。
- 外部エージェントまたはフローの設定を変更した。

一貫した動作を保証するため、バージョンはイミュータブルです。

### バージョンのピン留め {#version-pinning}

{{< history >}}

- エージェントまたはフローを管理するプロジェクトは、常にそのアイテムの最新バージョンを使用します。GitLab 18.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/583024)されました。

{{< /history >}}

AIカタログアイテムを有効にすると:

- グループでは、GitLabは最新バージョンをピン留めします。
- そのアイテムを管理しないプロジェクトでは、GitLabはプロジェクトのトップレベルグループと同じバージョンをピン留めします。

バージョンのピン留めとは:

- プロジェクトまたはグループでは、固定されたバージョンのアイテムを使用します。
- AIカタログ内のエージェントやフローが更新されても、現在使用している設定には影響しません。
- 新しいバージョンをいつ採用するかを制御できます。

このアプローチにより、AIを活用したワークフローで安定性と予測可能性を確保できます。

アイテムを管理するプロジェクトでAIカタログアイテムを有効にする場合、GitLabはバージョンをピン留めしません。代わりに、マネージャープロジェクトは常にアイテムの最新バージョンを使用します。

GitLab 18.10より前に、エージェントまたはフローをそのマネージャープロジェクトで有効にしていた場合、設定はピン留めされたバージョンのままになります。

初めて最新バージョンに更新した後、GitLabはそれ以降、自動的に最新バージョンを使用します。

### 現在のバージョンを確認する {#view-the-current-version}

前提条件: 

- デベロッパー、メンテナー、またはオーナーロールが必要です。

エージェントまたはフローの現在のバージョンを確認するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトまたはグループを見つけます。
1. 左サイドバーで、いずれかを選択します:
   - **自動化** > **エージェント**
   - **自動化** > **フロー**
1. エージェントまたはフローを選択すると、その詳細を確認できます。

詳細ページには、以下が表示されます:

- プロジェクトまたはグループが使用しているピン留めされたバージョン。
- バージョン識別子。例: `1.2.0`。
- その特定のバージョンの設定に関する詳細。

### 最新バージョンに更新する {#update-to-the-latest-version}

前提条件: 

- メンテナーまたはオーナーのロールを持っている必要があります。

グループまたはプロジェクトでエージェントまたはフローの最新バージョンを使用するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトまたはグループを見つけます。
1. 左サイドバーで、いずれかを選択します:
   - **自動化** > **エージェント**
   - **自動化** > **フロー**
1. 更新するエージェントまたはフローを選択します。
1. 最新バージョンの内容を入念に確認します。更新するには、**最新バージョンを表示** > **`<x.y.z>`に更新**を選択します。

## 関連トピック {#related-topics}

- [エージェント](agents/_index.md)
- [外部エージェント](agents/external.md)
