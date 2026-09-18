---
title: MCPサーバーのマージリクエストツール
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: agent_foundations
documentation_link: "../../../user/model_context_protocol/mcp_server_tools"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/627598
categories: [ Agent Tools ]
level: secondary
weight: 50
---

マージリクエストツールを使用すると、エージェントはGitLab MCPサーバーを通じてマージリクエストのフルループを実行できます。

- `save_merge_request` はMRを作成・更新します。
- `get_merge_request` はMRを詳細に検査し、差分、コンフリクト、承認のファセットを新たに提供します。
- `list_merge_requests` はグループスコープでも動作するようになりました。
- `save_merge_request_review` は行レベルのレビューコメントを残し、差分コメントのバッチ処理とサマリーを1回の呼び出しで行います。
- `accept_merge_request` はチェックが通過するとMRをマージし、承認または承認取り消しも行えます。
