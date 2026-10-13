---
title: MCPサーバーのプロジェクトおよびユーザーツール
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: agent_foundations
documentation_link: "../../../user/model_context_protocol/mcp_server_tools"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/627598
categories: [ Agent Tools ]
level: secondary
weight: 50
---

新しいプロジェクトおよびユーザーツールにより、エージェントはGitLab MCPサーバーを通じて作業を正確に対象とするために必要なコンテキストを取得できます。

- `get_project`と`list_projects`はプロジェクトの詳細を検索・取得します。
- `list_project_members`はメンバーとその役割を一覧表示します。
- `get_user`は割り当てやメンションのためにユーザーの詳細を検索します。

以前は、エージェントはGitLab MCPサーバーを通じてプロジェクトのメンバーシップやユーザー情報を取得する方法がありませんでした。
