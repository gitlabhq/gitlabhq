---
title: MCPサーバーのセマンティック検索ツール
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: agent_foundations
documentation_link: "../../../user/model_context_protocol/mcp_server_tools"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/627598
categories: [ Agent Tools ]
level: secondary
weight: 50
---

`semantic_code_search` は `semantic_search` に名称変更されました。このツールは、以前のリリースから変わらず、完全一致するシンボルやファイル名ではなく、意味によってコードを検索します。名称変更に伴い `scope` パラメーターが追加され、将来のリリースで追加のインデックス作成済みコンテンツタイプを同じツールに統合できるようになります。現時点では、`scope` は `code` のみを受け付けます。
