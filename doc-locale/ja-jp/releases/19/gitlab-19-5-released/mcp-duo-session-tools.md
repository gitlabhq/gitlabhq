---
title: MCPサーバーのGitLab Duoエージェントとフローツール
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: agent_foundations
documentation_link: "../../../user/model_context_protocol/mcp_server_tools/#start_duo_session"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/21395
categories: [ Agent Tools ]
level: secondary
weight: 50
---

新しいGitLab Duoエージェントおよびフローツールにより、任意のMCPクライアントからGitLab Duoエージェントとフローを実行・追跡できます。

- `start_duo_session` はセッションを開始します。
- `get_duo_session` はセッションの現在の状態を読み取ります。
- `list_duo_sessions` はセッションの履歴をページングします。
- `list_duo_agents_and_flows` はプロジェクトで有効になっているGitLab Duoエージェントとフローを一覧表示します。
