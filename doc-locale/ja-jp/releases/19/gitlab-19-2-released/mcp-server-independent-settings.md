---
title: MCPサーバーをAgent Platformとは独立してオンにする
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated, gitlab_dedicated_for_government ]
stage: agent_foundations
documentation_link: "../../../user/model_context_protocol/mcp_server/"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/590729
categories: [ AI Agents ]
level: secondary
weight: 50
---

外部ツールがGitLabインスタンスまたはグループに接続する方法をより細かく制御できるようになりました。
GitLab MCPサーバーをAgent Platformの設定とは独立してオン・オフできます。

以前は、GitLab MCPサーバーとAgent Platformが同じオン・オフ設定を共有していたため、
Agent Platform機能をオンにせずにMCPサーバーだけをオンにすることはできませんでした。
今回のリリースで、Agent Platformをオンにせずに他のツールからGitLabをMCPサーバーとしてアクセスさせたり、
Agent Platform機能を使用しながらGitLab MCPサーバーをオフのままにしたりすることが可能になりました。
