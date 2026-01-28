---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 基盤フロー
---

{{< details >}}

- プラン: Premium、Ultimate
- アドオン: GitLab Duo Core、Pro、またはEnterprise
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

この機能は、[GitLabクレジット](../../../../subscriptions/gitlab_credits.md)を使用します。

{{< /details >}}

{{< collapsible title="モデル情報" >}}

- LLM: Anthropic [Claude Sonnet 4](https://www.anthropic.com/claude/sonnet)

{{< /collapsible >}}

Foundational flowはGitLabによって構築およびメンテナンスされ、GitLabによってメンテナンスされたバッジ（{{< icon name="tanuki-verified" >}}）を表示します。

各フローは、特定の問題の解決や開発タスクの支援を目的として設計されています。

次の基盤フローが利用可能です:

- [ソフトウェア開発](software_development.md): ソフトウェア開発ライフサイクル全体で、AIが生成したソリューションを作成します。
- [デベロッパー](developer.md): イシューから実用的なマージリクエストを作成します。
- [CI/CDパイプラインの修正](fix_pipeline.md): 失敗したジョブを診断して修正します。
- [GitLab CI/CDへの変換](convert_to_gitlab_ci.md): JenkinsパイプラインをCI/CDに移行します。
- [コードレビュー](code_review.md): AIネイティブの分析とフィードバックでコードレビューを自動化します。
- [SAST誤検出の検出](sast_false_positive_detection.md): SASTの検出結果で誤検出を自動的に識別してフィルタリングします。

## Foundational flowのセキュリティ {#security-for-foundational-flows}

GitLab UIでは、基盤フローは次のGitLab APIにアクセスできます:

- [プロジェクトAPI](../../../../api/projects.md)
- [イシューAPI](../../../../api/issues.md)
- [マージリクエストAPI](../../../../api/merge_requests.md)
- [リポジトリファイルAPI](../../../../api/repository_files.md)
- [ブランチAPI](../../../../api/branches.md)
- [コミットAPI](../../../../api/commits.md)
- [CIパイプラインAPI](../../../../api/pipelines.md)
- [ラベルAPI](../../../../api/labels.md)
- [エピックAPI](../../../../api/epics.md)
- [ノートAPI](../../../../api/notes.md)
- [検索API](../../../../api/search.md)

### サービスアカウント {#service-accounts}

Foundational flowは、サービスアカウントを使用してタスクを完了します。詳細については、[コンポジットアイデンティティワークフロー](../../composite_identity.md#composite-identity-workflow)を参照してください。

Foundational flowがマージリクエストを作成すると、マージリクエストはサービスアカウントに起因します。これは、トリガーされたフローのユーザーが、AIによって生成されたコードを承認してマージできることを意味します。SOC 2、SOX、ISO 27001、またはFedRAMPの要件を持つ組織は、[コンプライアンスに関する考慮事項](../../composite_identity.md#compliance-considerations-for-merge-requests)を確認し、適切な承認ポリシーを実装する必要があります。
