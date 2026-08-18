---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: エージェント型AIによる破壊的変更の解決フロー
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- ステータス: ベータ版

{{< /details >}}

{{< history >}}

- GitLab 19.2で[ベータ](../../../../policy/development_stages_support.md#beta)版として[導入](https://gitlab.com/groups/gitlab-org/-/work_items/17884)（[機能フラグ](../../../../administration/feature_flags/_index.md) `enable_dependency_bump_breaking_changes`と`dependency_bump_web_search`という名称）。デフォルトでは有効になっています。

{{< /history >}}

> [!flag]
> この機能の提供状況は機能フラグによって制御されます。詳細については、履歴を参照してください。

このエージェント型AIによる破壊的変更の解決フローは、依存関係の更新のマージリクエストにおけるパイプラインの失敗を自動的に分析し、導入された破壊的な変更を解決するためのコード修正を生成します。

依存関係の更新マージリクエストのパイプラインが失敗すると、GitLab Duoはその失敗を分析し、修正の生成を試みます。そのフローは以下を検証します:

- パイプラインのエラーログを分析し、失敗の根本原因を特定します。
- 依存関係の変更履歴とリリースノートを分析し、破壊的な変更を特定します。
- 更新された依存関係のコード使用パターンを分析し、変更が必要な箇所を特定します。

修正の生成後、フローはそれらを依存関係の更新マージリクエストブランチに直接コミットし、パイプラインを再実行します。

結果はAI分析に基づいているため、マージする前にレビューしてください。

## 前提条件 {#prerequisites}

- [GitLab Duo Agent Platformの前提条件](../../_index.md#prerequisites)を満たしている。
- **基本フローを許可**と**依存関係の更新による互換性の問題を解消**を[トップレベルグループ向けに](_index.md#turn-foundational-flows-on-or-off)有効にします。
- [サービスアカウントを許可するようにプッシュルールを設定している](../../troubleshooting.md#configure-push-rules-to-allow-a-service-account)。
- [独自のRunnerを設定](../execution.md)しているか、プロジェクトで[GitLabホストRunner](../../../../ci/runners/hosted_runners/_index.md)をオンにしている。
- プロジェクトで機能を有効にします。[エージェント型AIによる破壊的変更の解決を有効にする](../../../application_security/dependency_scanning/agentic-breaking-change-resolution.md#enable-agentic-breaking-change-resolution)を参照してください。

## エージェント型AIによる破壊的変更の解決フローを実行します {#run-the-agentic-breaking-change-resolution-flow}

自動修正エージェントによって作成された依存関係の更新マージリクエストのパイプラインが失敗し、その機能がプロジェクトで有効になっている場合、フローは自動的に実行されます。

フローは手動でトリガーすることもできます:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 左側のサイドバーで、**コード** > **マージリクエスト**を選択します。
1. パイプラインが失敗した依存関係の更新マージリクエストを選択します。
1. パイプラインウィジェットで、**Duoで破壊的な変更を解決**を選択します。

フローはバックグラウンドで実行されます。完了すると、生成された修正をMRブランチにコミットし、パイプラインを再実行します。

## 関連トピック {#related-topics}

- [エージェント型AIによる破壊的変更の解決](../../../application_security/dependency_scanning/agentic-breaking-change-resolution.md)
- [依存関係スキャン](../../../application_security/dependency_scanning/_index.md)
- [GitLab Duo](../../../gitlab_duo/_index.md)
