---
stage: AI-powered
group: Workflow Catalog
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Foundationalエージェント
---

{{< details >}}

- プラン: Premium、Ultimate
- アドオン: GitLab Duo Core、Pro、またはEnterprise。
- 提供形態: GitLab.com
- ステータス: ベータ

{{< /details >}}

{{< history >}}

- GitLab 18.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/576618)されました。

{{< /history >}}

Foundationalエージェントは、ドメイン固有の専門知識とコンテキスト認識によりGitLab Duoチャットの機能を拡張する、特殊なAIアシスタントです。

汎用的なGitLab Duoエージェントとは異なり、Foundationalエージェントは、専門分野の独自のワークフロー、フレームワーク、およびベストプラクティスを理解します。各エージェントは、GitLabの機能に関する深い知識と、実践者が実際にどのように作業するかを調整するためのロール固有の推論を組み合わせています。

Foundationalエージェントとやり取りすると、何を聞いているかだけでなく、自分の役割と目的のより広いコンテキストを理解するAIツールを利用していることになります。例: 

- 優先順位フレームワークと依存関係管理を理解する製品計画エージェント。
- 脆弱性パターンとコンプライアンス要件を認識するセキュリティエージェント。

これらのエージェントは、既存のGitLabワークフローにチャットを介して統合され、現在のコンテキストから離れることなく、専門的なサポートを提供するのに役立ちます。

GitLabは、専門知識が結果の品質を大幅に向上させるワークフローのためにFoundationalエージェントを提供します。各エージェントは、GitLab固有の実装、組織標準、およびそのドメインにおける業界のベストプラクティスを認識しています。この専門化により、汎用的なAIヘルプと比較して、より正確で、実用的で、状況に応じた適切な応答が可能になります。

## 利用可能なFoundationalエージェント {#available-foundational-agents}

次のFoundationalエージェントは、GitLab 18.5で利用可能です:

- [GitLab Duoプランナー](planner.md)（製品管理および計画ワークフロー用）。
- [GitLab Security Analystエージェント](security_analyst_agent.md)（セキュリティ分析および脆弱性管理用）。
