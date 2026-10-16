---
title: MCPサーバーグループツール
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: agent_foundations
documentation_link: "../../../user/model_context_protocol/mcp_server_tools"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/607719
categories: [ Agent Tools ]
level: secondary
weight: 50
---

以前は、MCP経由でGitLabに接続するエージェントが、IDやパスをハードコードせずにアクセス可能なグループやサブグループを検出する方法がありませんでした。新しい`list_groups`ツールを使用すると、エージェントが組織のグループ階層を自律的に参照できるようになり、識別子を推測するのではなく、アクションを実行する前に適切なグループを見つけることができます。
