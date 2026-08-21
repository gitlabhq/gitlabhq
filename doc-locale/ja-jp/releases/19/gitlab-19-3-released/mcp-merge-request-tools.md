---
title: マージリクエストの読み取りと検索のための新しいMCPツール
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated, gitlab_dedicated_for_government ]
stage: agent_foundations
documentation_link: "../../../user/model_context_protocol/mcp_server_tools"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/605878
categories: [ Agent Tools ]
level: secondary
weight: 50
---

`get_merge_request`を使用すると、マージリクエストとその差分、コミット、ノート、パイプライン、ディスカッションを1回の呼び出しで取得できます。これにより、AIエージェントがMRの全体像を把握するために複数のリクエストを連鎖させる必要がなくなります。

また、新しい`list_merge_requests`ツールを使用すると、作成者、担当者、レビュアー、状態、ラベル、またはフリーテキストクエリでマージリクエストを検索・フィルタリングできます。ワークフローを離れることなく、必要なMRを簡単に見つけることができます。
