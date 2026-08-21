---
title: MCPのOAuthアプリケーションを事前登録する
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: agent_foundations
documentation_link: "../../../user/model_context_protocol/mcp_server#reuse-a-pre-registered-oauth-application"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/601437
categories: [ Agent Tools ]
level: secondary
weight: 50
---

以前は、`mcp` スコープが**管理者**エリアのOAuthアプリケーションフォームに表示されていなかったため、Dynamic Client Registration（DCR）を使用せずにMCPクライアント用のOAuthアプリケーションを事前登録することができませんでした。
今回のリリースで、**管理者**エリアから直接 `mcp` スコープを持つ共有OAuthアプリケーションを作成できるようになりました。これにより、ユーザーは安定したクライアントIDを再利用でき、共有ネットワーク上でのDCRのレート制限を回避できます。
