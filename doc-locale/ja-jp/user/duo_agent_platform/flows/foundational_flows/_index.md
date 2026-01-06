---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Foundational flows
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

Foundational flowsは、GitLabによって構築およびメンテナンスされています。

各フローは、特定の問題を解決したり、開発タスクを支援したりするように設計されています。

次のFoundational flowsを使用できます:

- [ソフトウェア開発](software_development.md)。
- [CI/CDパイプラインを修正する](fix_pipeline.md)。
- [Jenkinsfileを`.gitlab-ci.yml`ファイルに変換する](convert_to_gitlab_ci.md)。
- [イシューをマージリクエストに変換する](issue_to_mr.md)。

## サポートされているAPIと権限 {#supported-apis-and-permissions}

GitLab UIでは、Foundational flowsは次のGitLab APIにアクセスできます:

- [プロジェクトAPI](../../../../api/projects.md)
- [イシューAPI](../../../../api/issues.md)
- [マージリクエストAPI](../../../../api/merge_requests.md)
- [Repository Files API](../../../../api/repository_files.md)
- [ブランチAPI](../../../../api/branches.md)
- [コミットAPI](../../../../api/commits.md)
- [CIパイプラインAPI](../../../../api/pipelines.md)
- [ラベルAPI](../../../../api/labels.md)
- [エピックAPI](../../../../api/epics.md)
- [ノートAPI](../../../../api/notes.md)
- [検索API](../../../../api/search.md)

Foundational flowsは、各ユーザーの権限を使用し、すべてのプロジェクトのアクセス制御とセキュリティポリシーを尊重します。
