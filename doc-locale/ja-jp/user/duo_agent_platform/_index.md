---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab Duo Agent Platform
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< collapsible title="モデル情報" >}}

- LLM: Anthropic [Claude Sonnet 4](https://www.anthropic.com/claude/sonnet)
- [セルフホストモデル対応のGitLab Duo](../../administration/gitlab_duo_self_hosted/_index.md)で利用可能

{{< /collapsible >}}

{{< history >}}

- GitLab 18.2で[ベータ版](../../policy/development_stages_support.md)として導入されました。
- Self-Managedインスタンス上のGitLab Duo Agent Platform（[セルフホストモデル](../../administration/gitlab_duo_self_hosted/_index.md)およびクラウド接続されたGitLabモデルの両方）では、GitLab 18.4で[実験的機能](../../policy/development_stages_support.md#experiment)として、`self_hosted_agent_platform`[機能フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/groups/gitlab-org/-/epics/19213)されました。デフォルトでは無効になっています。
- GitLab 18.7で機能フラグ`self_hosted_agent_platform`は[有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/208951)になりました。
- GitLab 18.8で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/work_items/585273)になりました。
- GitLab 18.8以降では、GitLab Duo Agent PlatformとGitLabクレジットがサポートされています。
- 機能フラグ`self_hosted_agent_platform`は、GitLab 18.9で[削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/218589)されました。

{{< /history >}}

GitLab Duo Agent Platformは、複数のインテリジェントなアシスタント（「エージェント」）をソフトウェア開発ライフサイクル全体に組み込む、AIネイティブソリューションです。

- 線形のワークフローに従う代わりに、AIエージェントと非同期的にコラボレーションします。
- コードリファクタリングやセキュリティスキャンから調査まで、ルーチンタスクを特化型AIエージェントに委任します。

開始するには、[GitLab Duo Agent Platformのスタートガイド](../get_started/get_started_agent_platform.md)を参照してください。

## 前提条件 {#prerequisites}

Agent Platformを使用するには:

- GitLab Duoを[有効にする](turn_on_off.md#turn-gitlab-duo-on-or-off)。
- GitLab Duo ProまたはEnterpriseを契約していない場合は、トップレベルグループまたはインスタンスで[GitLab Duo Coreを有効にする](turn_on_off.md#turn-gitlab-duo-core-on-or-off)。
- 使用しているGitLabのバージョンに応じて:
  - GitLab 18.8以降では、[Agent Platformを有効にする](turn_on_off.md#turn-gitlab-duo-agent-platform-on-or-off)。
  - GitLab 18.7以前では、[ベータ版機能と実験的機能を有効にする](turn_on_off.md#turn-on-beta-and-experimental-features)。
- GitLab Self-Managedの場合は、[インスタンスを設定する](../../administration/gitlab_duo/configure/gitlab_self_managed.md)。
- GitLab Duo Self-Hostedの場合は、Agent Platformサービスで[AIゲートウェイをインストールする](../../install/install_ai_gateway.md)。

ローカル環境でAgent Platformを使用するには:

- エディタ拡張機能をインストールし、GitLabで認証する。
- [グループネームスペース](../namespace/_index.md)内にプロジェクトがある。
- デベロッパー、メンテナー、またはオーナーロールがある。

## 一般提供機能 {#generally-available-features}

これらの機能は一般提供されており、使用時に[GitLabクレジット](../../subscriptions/gitlab_credits.md)を消費します。

GitLab.comのFreeティアで利用可能な機能には、[GitLabクレジット](../../subscriptions/gitlab_credits.md#for-the-free-tier-on-gitlabcom)の購入が必要です。

| 機能 | Free | Premium | Ultimate |
|---------|---------|---------|---------|
| [GitLab Duo Chat（エージェント型）](../gitlab_duo_chat/agentic_chat.md)<br /> 複雑な質問に回答し、自律的にファイルを作成および編集します。 | {{< yes >}} | {{< yes >}}  | {{< yes >}} |
| [コード提案](code_suggestions/_index.md)<br /> コードを記述すると、AIによる提案が表示されます。 | {{< yes >}} | {{< yes >}}  | {{< yes >}} |
| [カスタムエージェント](agents/custom.md)<br /> 独自の開発要件に合わせてチーム固有のエージェントを構築します。 | {{< yes >}} |  {{< yes >}}  | {{< yes >}} |
| [外部エージェント](agents/external.md)<br /> サードパーティのインテグレーションとツールを安全に接続し、Agent Platformの機能を拡張します。 | {{< no >}} |  {{< yes >}}  | {{< yes >}} |
| [プランナーエージェント](agents/foundational_agents/planner.md)<br /> 作業を計画、優先順位付け、追跡します。 | {{< yes >}} | {{< yes >}}  | {{< yes >}} |
| [データ分析エージェント](agents/foundational_agents/data_analyst.md)<br /> データを分析し、開発メトリクスとプロジェクトデータからインサイトを生成します。 | {{< yes >}} | {{< yes >}}  | {{< yes >}} |
| [デベロッパーフロー](flows/foundational_flows/developer.md)<br /> イシューをマージリクエストに変換します。 | {{< yes >}} | {{< yes >}}  | {{< yes >}} |
| [コードレビューフロー](flows/foundational_flows/code_review.md)<br /> コードレビュータスクを自動化し、チーム全体でコーディング標準を適用します。 | {{< yes >}} | {{< yes >}}  | {{< yes >}} |
| [GitLab CI/CD変換フロー](flows/foundational_flows/convert_to_gitlab_ci.md)<br /> レガシーCI/CDパイプラインをGitLab CI/CD形式に変換します。 | {{< yes >}} | {{< yes >}}  | {{< yes >}} |
| [CI/CDパイプライン修正フロー](flows/foundational_flows/fix_pipeline.md)<br /> 失敗するCI/CDパイプラインを診断し、自動的に修正します。 | {{< yes >}} | {{< yes >}}  | {{< yes >}} |
| [ソフトウェア開発フロー](flows/foundational_flows/software_development.md)<br /> 実行する前に、完全な複数ステップの計画を作成します。 | {{< yes >}} | {{< yes >}}  | {{< yes >}} |
| [MCPクライアント](../gitlab_duo/model_context_protocol/mcp_clients.md)<br /> MCP互換のAIクライアントまたはIDE拡張機能からGitLabのリソースとツールにアクセスします。 1<sup>1</sup> | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| [SAST誤検出判定フロー](flows/foundational_flows/sast_false_positive_detection.md)<br /> SASTセキュリティスキャンにおける誤検出を自動的に識別し、フィルタリングします。 | {{< no >}} | {{< no >}}  | {{< yes >}} |
| [SAST脆弱性の修正フロー](flows/foundational_flows/agentic_sast_vulnerability_resolution.md)<br /> SASTの脆弱性に対する修正および修正ステップを自動的に生成します。 | {{< no >}} | {{< no >}}  | {{< yes >}} |
| [セキュリティ分析エージェント](agents/foundational_agents/security_analyst_agent.md)<br /> 反復的なセキュリティタスクを自動化します: トリアージイシューを行い、脆弱性を分析し、修正を生成します。 | {{< no >}} | {{< no >}}  | {{< yes >}} |

**脚注**: 

1. MCPクライアントは直接クレジットを消費しません。ただし、Agent Platformの使用（MCPクライアントを通じて行われたモデルリクエストなど）はクレジットを消費する場合があります。

## ベータ版機能と実験的機能 {#beta-and-experiment-features}

これらの機能はベータ版または実験的機能であり、GitLabクレジットを消費しません。

[GitLab.comのFree](../../subscriptions/gitlab_credits.md#for-the-free-tier-on-gitlabcom)ティアユーザーの場合、ベータ版機能および実験的機能はクレジットを消費しませんが、アクセスするにはMonthly Commitmentプールにクレジットが必要です。

> [!warning]
> 機能が一般提供されると、その機能の使用はすべてのGitLabバージョンとすべての製品でGitLabクレジットを消費し始めます。ベータ機能は、いつでも使用量課金によって一般公開に変更される可能性があります。

| 機能 | Free | Premium | Ultimate |
|---------|---|---|---|
| [カスタムフロー](flows/custom.md)<br /> 複数のエージェントを組み合わせて、ビジネス上の問題を解決します。 | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| [MCPサーバー](../gitlab_duo/model_context_protocol/mcp_server.md)<br /> AIツールとアプリケーションをGitLabインスタンスに安全に接続します。 | {{< no >}} | {{< yes >}} | {{< yes >}} |
| [CI Expert Agent](agents/foundational_agents/ci_expert_agent.md)<br /> GitLab CI/CDパイプラインを作成、デバッグ、および最適化します。 | {{< no >}} | {{< yes >}} | {{< yes >}} |
| [外部MCPサーバー](../gitlab_duo/model_context_protocol/ai_catalog_mcp_servers.md)<br /> カスタムエージェントを、MCPサーバーを使用して外部データソースやサードパーティサービスに接続します。 | {{< no >}} | {{< yes >}} | {{< yes >}} |
| [ナレッジグラフ](../project/repository/knowledge_graph/_index.md)<br /> コードリポジトリの構造化されたクエリ可能な表現を作成し、AI機能を強化します。 | {{< no >}} |{{< yes >}} | {{< yes >}} |
