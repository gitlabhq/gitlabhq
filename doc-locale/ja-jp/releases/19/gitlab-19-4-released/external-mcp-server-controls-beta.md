---
title: MCPサーバーへのアクセスを制限する（ベータ版）
tier: [ Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated, gitlab_dedicated_for_government ]
stage: software_supply_chain_security
documentation_link: "../../../user/ai-governance/tool-governance/#block-model-context-protocol-mcp-servers"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/628378
categories: [ AI Governance ]
level: primary
weight: 50
---

MCP（Model Context Protocol）サーバーへのアクセスを制限できるようになりました。許可またはブロックの対象として指定できるのは次のとおりです。

- 外部MCPサーバー全体。
- MCPサーバー上の個別ツール。

この機能により、Duo Agent Platform内のAIエージェントがガバナンスの境界内で動作し、各自のアクティビティ、セッション、タスクを実行するためのスコープ内にあるMCPツールにのみアクセスできることを保証します。

これらの制御は、AIエージェントが実行されるあらゆる環境に一貫して適用されます。対象となる環境は次のとおりです。

- Agentic Chat。
- フロー。
- IDEおよびCLI環境。

この機能は現在ベータ版です。[イシュー #628378](https://gitlab.com/gitlab-org/gitlab/-/issues/628378) からフィードバックをお寄せください。
