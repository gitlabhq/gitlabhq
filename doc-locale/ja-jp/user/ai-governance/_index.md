---
stage: Software Supply Chain Security
group: AI Governance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: 組織全体でのAIエージェントのアクティビティを監視、監査、制御します。
title: AIガバナンス
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

AIガバナンス機能は、セキュリティチームとコンプライアンスチームが組織全体のAIエージェントのアクティビティを監視、監査、制御するのに役立ちます。

これらの機能は、GitLab Duo Agent Platformエージェントと、GitLab Model Context Protocol（MCP）サーバーを介して接続するClaude CodeやCursorなどの外部エージェントの両方に適用されます。

## 機能 {#features}

| 機能 | 説明 |
|:--------|:------------|
| [AIガバナンスダッシュボード](governance-dashboard.md) | グループ全体でAIエージェントセッション、監査ログ、デベロッパーの公開状況を監視します。 |
| [AI監査イベント](ai-audit-events.md) | コンプライアンスおよびガバナンスの目的で、エージェントのアクティビティの統合された記録を閲覧およびフィルターします。 |
| [ツールガバナンス](tool-governance.md) | 接続するすべてのクライアントに対して実行時に適用される、エージェントツール用の許可、要求、および拒否ポリシーを設定します。 |

各機能には異なるプランと可用性の要件があります。詳細については、個別の機能ページを確認してください。

## 関連トピック {#related-topics}

- [GitLab Duo Agent Platform](../duo_agent_platform/_index.md)
- [コンプライアンス機能](../compliance/_index.md)
- [監査イベント](../compliance/audit_events.md)
