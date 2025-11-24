---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: フロー
---

{{< details >}}

- プラン: Premium、Ultimate
- アドオン: GitLab Duo Core、Pro、またはEnterprise。
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- ステータス: ベータ

{{< /details >}}

{{< collapsible title="モデル情報" >}}

- LLM: Anthropic [Claude Sonnet 4](https://www.anthropic.com/claude/sonnet)

{{< /collapsible >}}

{{< history >}}

- GitLab 18.3で`duo_workflow`[フラグ](../../../administration/feature_flags/_index.md)とともに[ベータ](../../../policy/development_stages_support.md)として導入されました。デフォルトでは有効になっています。
- 個々のフローには、追加のフラグが必要です。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

{{< /alert >}}

フローとは、1つまたは複数のエージェントが連携して複雑な問題を解決するものです。

フローは、IDEとGitLab UIで利用できます。

- UIでは、フローはGitLab CI/CDで直接実行され、ブラウザを離れることなく、一般的な開発タスクを自動化できます。
- IDEでは、フローはVS Code、Visual Studio、およびJetBrainsで利用できます。

## 利用可能なフロー {#available-flows}

以下のフローが利用可能です:

- [CI/CDパイプラインを修正](fix_pipeline.md)。
- [Jenkinsfileを`.gitlab-ci.yml`ファイルに変換](convert_to_gitlab_ci.md)。
- [イシューをマージリクエストに変換](issue_to_mr.md)。
- [ソフトウェア開発](software_development.md)のあらゆる側面に取り組みます。このフローでは、ニーズを記述すると、GitLab Duoがリポジトリ、コードベース、およびその構造を理解します。

選択したコードを理解するなど、より焦点を絞った作業には、[GitLab Duoチャット（エージェント型）](../../gitlab_duo_chat/agentic_chat.md)を使用します。

## フローをオンにする {#turn-on-flows}

フローをオンまたはオフにするには、[GitLab Duo設定](../../gitlab_duo/turn_on_off.md)を使用します。

## GitLab UIで実行中のフローを監視する {#monitor-running-flows-in-the-gitlab-ui}

プロジェクトで実行されているフローを表示するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **自動化** > **セッション**を選択します。

## IDEでフローの履歴を表示する {#view-flow-history-in-the-ides}

プロジェクトで実行したフローの履歴を表示するには:

- **フロー**タブで、下にスクロールして**Recent agent sessions**（最近のエージェントセッション）を表示します。

## サポートされているAPIと権限 {#supported-apis-and-permissions}

GitLab UIでは、フローは次のGitLab APIにアクセスできます:

- [プロジェクトAPI](../../../api/projects.md)
- [イシューAPI](../../../api/issues.md)
- [マージリクエストAPI](../../../api/merge_requests.md)
- [リポジトリファイルAPI](../../../api/repository_files.md)
- [ブランチAPI](../../../api/branches.md)
- [コミットAPI](../../../api/commits.md)
- [CIパイプラインAPI](../../../api/pipelines.md)
- [ラベルAPI](../../../api/labels.md)
- [エピックAPI](../../../api/epics.md)
- [ノートAPI](../../../api/notes.md)
- [検索API](../../../api/search.md)

フローは各ユーザーの権限を使用し、すべてのプロジェクトアクセス制御とセキュリティポリシーを尊重します。

## フィードバックを提供する {#give-feedback}

エージェントフローは、GitLab AI搭載の開発プラットフォームの一部です。皆様からのフィードバックは、これらのワークフローの改善に役立ちます。フローに関する問題を報告したり、改善点を提案するには、[このアンケートにご回答ください](https://gitlab.fra1.qualtrics.com/jfe/form/SV_9GmCPTV7oH9KNuu)。

## 関連トピック {#related-topics}

- [フローの実行場所を設定する](execution.md)
