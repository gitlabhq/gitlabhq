---
title: MCPサーバーCI/CDアーティファクトツール
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: agent_foundations
documentation_link: "../../../user/model_context_protocol/mcp_server_tools"
work_item: https://gitlab.com/gitlab-org/gitlab/-/issues/585022
categories: [ Agent Tools ]
level: secondary
weight: 50
---

以前は、エージェントがCI/CDジョブのビルドアーティファクト内のファイルを確認する必要がある場合、1つのファイルを読み取るためだけにアーカイブ全体をダウンロードして解凍しなければなりませんでした。今回のリリースで、`get_artifact_file` MCPツールを使用することにより、ログ、生成されたレポート、テストフィクスチャなど、ジョブのアーティファクトから単一のファイルを直接読み取れるようになりました。
