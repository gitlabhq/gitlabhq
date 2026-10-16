---
title: MCPサーバーのツールセット選択
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: agent_foundations
documentation_link: "../../../user/model_context_protocol/mcp_server/#select-tool-groups-toolsets"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/607755
categories: [ Agent Tools ]
level: secondary
weight: 50
---

GitLab MCPサーバーが公開するツールセットを選択できるようになりました。不要なツールが増えるほど、LLMのコンテキストウィンドウのスペースが無駄になり、特に複数のMCPサーバーを同時に使用している場合は、LLMが混乱するリスクも高まります。
