---
stage: Software Supply Chain Security
group: AI Governance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: AIエージェントのセッション、監査ログ、デベロッパーの活動状況を、中央のダッシュボードから組織全体で監視します。
title: AIガバナンスダッシュボード
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- ステータス: 限定提供

{{< /details >}}

{{< history >}}

- GitLab 19.4で`ai_governance_dashboard`[機能フラグ](../../administration/feature_flags/_index.md)とともに[ベータ版](../../policy/development_stages_support.md)として[導入](https://gitlab.com/gitlab-org/gitlab/-/work_items/603776)されました。デフォルトでは有効になっています。

{{< /history >}}

> [!warning]
> この機能は[ベータ版](../../policy/development_stages_support.md)です。予告なく変更される場合があります。詳細については、[GitLabテスト規約](https://handbook.gitlab.com/handbook/legal/testing-agreement/)を参照してください。

セキュリティおよびコンプライアンスチームは、AIガバナンスダッシュボードを使用して、グループ全体のAIエージェントの活動を監視できます。AIガバナンスダッシュボードは、以下の点について可視性を提供する主要業績評価指標（KPI）とデータカードを表示します:

- AIエージェントがどのように使用されているか。
- どのデベロッパーが最も活動的か。
- どのプロジェクトが最も活動量が多いか。

ダッシュボードは、過去7日間にスコープされたGitLab Duo Agent Platform（DAP）エージェントのデータのみを表示します。

## 前提条件 {#prerequisites}

- トップレベルグループのオーナーロール、または`read_agent_artifacts`の機能を持つカスタムロールがあること。
- `ai_governance_dashboard`機能フラグがグループで有効になっていること。

## ダッシュボードを表示 {#view-the-dashboard}

1. 上部のバーで**検索または移動先**を選択して、トップレベルグループを見つけます。
1. **設定** > **GitLab Duo**を選択します。
1. **ガバナンスを変更**を選択します。
1. **ダッシュボード**タブを選択します。

## 主要業績評価指標（KPI）タイル {#key-performance-indicator-kpi-tiles}

ダッシュボードのヘッダーには、2つのKPIタイルが表示されます。各タイルには、過去7日間のカウントと、その期間の毎日のトレンドを示すスパークラインが表示されます。

### AIエージェント {#ai-agents}

**AIエージェント**タイルは、過去7日間における個別のアクティブなエージェントインスタンスの数を示します。エージェントインスタンスは、ユーザー、プロジェクト、ネームスペース、エージェントタイプ、および環境ごとにユニークです。Duo Chatの会話は、このカウントから除外されます。

### AIセッション {#ai-sessions}

**AIセッション**タイルは、過去7日間におけるエージェントのワークフローセッションの合計数を示します。これには、すべてのDAPワークフロータイプが含まれます: IDE、ウェブ、チャット、およびアンビエントセッション。Duo Chatが含まれます。

## データカード {#data-cards}

KPIタイルの下には、エージェントの活動の内訳を示すデータカードが表示されます。

### 監査ログ {#audit-logs}

**監査ログ**カードは、[AI監査イベントレポート](ai-audit-events.md)へのリンクであり、エージェントセッションイベントの完全な記録を閲覧、フィルタリング、およびダウンロードできます。ダッシュボードに適用されたフィルターは、監査イベントタブにパススルーされます。

### AIエージェントのインベントリ {#ai-agent-inventory}

**AIエージェントのインベントリ**カードには、グループでアクティブなDAPエージェントがプロジェクト別にリスト表示されます。エージェントを実行する頻度で並べ替えることで、最も頻繁に実行されるエージェントを特定できます。

### デベロッパーアクティビティ {#developer-activity}

**デベロッパーアクティビティ**カードには、過去7日間におけるエージェントセッション数による上位ユーザーが表示されます。これを使用して、どのデベロッパーが最も積極的にAIエージェントを使用しているかを把握します。

### プロジェクト活動 {#project-exposure}

**プロジェクト活動**カードには、過去7日間におけるエージェントセッション数による上位プロジェクトが表示されます。これを使用して、どのプロジェクトが最も多くのAIエージェント活動量を持っているかを特定します。

### MCPサーバー {#mcp-servers}

**MCPサーバー**カードには、グループに登録されているModel Context Protocol（MCP）サーバーと、そのステータスがリスト表示されます。これを使用して、外部のどのMCPサーバーにエージェントが到達できるかを確認します。

サーバーの完全な説明を読み取るには、切り詰められた説明テキストにカーソルを合わせるか、フォーカスします。

このカードには、登録済みのサーバーのみがリスト表示されます。各サーバーがどのくらいの頻度で使用されているかは表示されません。

## 関連トピック {#related-topics}

- [AIガバナンス](_index.md)
- [ツールガバナンス](tool-governance.md)
- [GitLab Duo Agent Platform](../duo_agent_platform/_index.md)
