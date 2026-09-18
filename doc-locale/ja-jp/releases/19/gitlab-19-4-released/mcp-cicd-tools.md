---
title: MCPサーバーCI/CDツール
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: agent_foundations
documentation_link: "../../../user/model_context_protocol/mcp_server_tools"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/627598
categories: [ Agent Tools ]
level: secondary
weight: 50
---

新しいCI/CDツールにより、エージェントはあらゆるMCPクライアントからCI/CDをトリガー、確認、制御できるようになりました。

- `save_pipeline`は、ツールを切り替えることなくパイプラインの実行、再試行、またはキャンセルを行います。
- `get_job`は、ジョブのメタデータとジョブのトレースを返します。これにより、エージェントは失敗したビルドのログを読み取り、問題を自律的に診断できます。

これまで、エージェントはMCPを通じてパイプラインをトリガーしたり確認したりする手段がありませんでした。
