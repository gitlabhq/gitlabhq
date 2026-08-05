---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: エージェント型AIによる破壊的変更の解決
description: 依存を更新するマージリクエストにおける問題のAIネイティブな解決。
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 19.2で[導入](https://gitlab.com/groups/gitlab-org/-/work_items/17884)された、[ベータ](../../../policy/development_stages_support.md#beta)機能です。この機能には、`enable_dependency_bump_breaking_changes`および`dependency_bump_web_search`という名前の[機能フラグ](../../../administration/feature_flags/_index.md)が付属しています。

{{< /history >}}

エージェント型AIによる破壊的変更の解決は、オプトインの基本フローで、次のことを行います:

- 依存を更新するマージリクエストで失敗したパイプラインを分析します。
- 依存関係の更新によって導入された破壊的な変更を解決するための修正を生成します。

> [!warning]
> この機能が有効な場合、影響を受けるマージリクエストのパイプラインログおよびコードコンテキストは、分析のために大規模言語モデル（LLM）に送信されます。この機能を有効にする前に、組織のデータポリシーを確認してください。

この基本フローでは、GitLab Duoは次のことを行います:

- パイプラインのエラーログを調査し、失敗の根本原因を特定します。
- 依存の変更履歴とリリースノートを分析し、破壊的な変更を特定します。
- 更新された依存のコード使用パターンをレビューします。
- コード修正を生成し、依存を更新するMRブランチに直接コミットします。
- 修正を適用した後、パイプラインを再実行します。

結果はAI分析に基づいているため、マージリクエストする前にデベロッパーによるレビューが必要です。

## 前提条件 {#prerequisites}

- プロジェクトまたはグループで[GitLab Duoが有効になっている](../../gitlab_duo/turn_on_off.md)。
- ユーザー設定で[デフォルトのGitLab Duoのネームスペースが設定されている](../../profile/preferences.md#set-a-default-gitlab-duo-namespace)。
- [依存関係スキャンの自動修正](../remediate/auto_remediation.md)がプロジェクトで有効になっています。エージェント型AIによる破壊的変更の解決は、自動修正によって作成された依存を更新するマージリクエストに対して機能します。

## エージェント型AIによる破壊的変更の解決を有効にする {#enable-agentic-breaking-change-resolution}

この機能はデフォルトでオフになっており、グループとプロジェクトの両方のレベルで明示的に有効にする必要があります。

### トップレベルグループでこの基本フローを有効にする {#turn-on-this-foundational-flow-in-a-top-level-group}

グループ内のすべてのプロジェクトで基本フローを使用できるようにするには:

1. 上部のバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定** > **GitLab Duo**を選択します。
1. **基本フローを許可**で、**依存関係の更新による互換性の問題を解消**チェックボックスを選択します。
1. **変更を保存**を選択します。

### プロジェクトでこの基本フローを有効にする {#turn-on-this-foundational-flow-for-a-project}

前提条件: 

- プロジェクトのメンテナーまたはオーナーのロール。
- トップレベルグループで基本フローが有効になっていること。

特定のプロジェクトでエージェント型AIによる破壊的変更の解決を有効にするには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **一般**を選択します。
1. **GitLab Duo**を展開します。
1. **Turn on AI-powered resolution of dependency bump breaking changes**切替をオンにします。
1. **変更を保存**を選択します。

## フローをトリガーする {#trigger-the-flow}

フローは自動的に、または手動でトリガーできます。

### 自動トリガー {#automatic-trigger}

このフローは、次の条件を満たした場合に自動的に実行されます:

- 自動修正のエージェントによって作成された、依存を更新するマージリクエストでパイプラインが失敗します。
- この機能はプロジェクトで有効になっています。
- プロジェクトまたはグループでGitLab Duoの機能が有効になっている。

分析はバックグラウンドで実行されます。完了すると、生成された修正はマージリクエストブランチにコミットされ、パイプラインが再実行されます。

### 手動トリガー {#manual-trigger}

失敗したパイプラインを持つ（依存を更新する）マージリクエストで、エージェント型AIによる破壊的変更の解決を手動でトリガーするには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 左側のサイドバーで、**コード** > **マージリクエスト**を選択します。
1. パイプラインが失敗した依存関係の更新マージリクエストを選択します。
1. パイプラインウィジェットで、**Duoで破壊的な変更を解決**を選択します。

フローはバックグラウンドで実行されます。完了すると、生成された修正をMRブランチにコミットし、パイプラインを再実行します。

## フィードバックを提供する {#provide-feedback}

[フィードバックイシュー](https://gitlab.com/gitlab-org/gitlab/-/work_items/605189)でご意見をお寄せください。

## 関連トピック {#related-topics}

- [エージェント型AIによる破壊的変更の解決の基本フロー](../../duo_agent_platform/flows/foundational_flows/agentic-breaking-change-resolution.md)
- [依存関係スキャンの自動修正](../remediate/auto_remediation.md)
- [依存関係スキャン](_index.md)
- [GitLab Duo Agent Platform](../../duo_agent_platform/_index.md)
- [GitLab Duo](../../gitlab_duo/_index.md)
