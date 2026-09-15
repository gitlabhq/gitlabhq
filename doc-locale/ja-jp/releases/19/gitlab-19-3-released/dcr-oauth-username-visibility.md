---
title: MCPのOAuthアプリケーションを承認したユーザーを確認する
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated, gitlab_dedicated_for_government ]
stage: agent_foundations
documentation_link: "../../../user/model_context_protocol/mcp_server"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/605884
categories: [ AI Agents ]
level: secondary
weight: 50
---

以前は、MCPクライアントがOAuth動的クライアント登録（DCR）を使用してGitLabに接続した場合、動的に登録されたすべてのOAuthアプリケーションが管理者エリアに汎用的なクライアント名のみで表示されており、どのユーザーが特定のアプリケーションを承認したかを判別することができませんでした。
今回のリリースから、MCP OAuth接続を承認すると、アプリケーション名にユーザー名が自動的に付加されます。例えば、`[Unverified Dynamic Application] kiro — authorized by @username`のように表示されます。
これにより、追加の設定なしに、管理者エリアから各動的OAuthアプリケーションの背後にいるユーザーを素早く特定できるようになりました。
