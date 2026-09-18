---
title: MCPサーバーの作業アイテムツール
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: agent_foundations
documentation_link: "../../../user/model_context_protocol/mcp_server_tools"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/627598
categories: [ Agent Tools ]
level: secondary
weight: 50
---

GitLab MCPサーバーに作業アイテムツールが追加され、エージェントおよびMCPクライアントからイシュー、エピック、タスク、インシデント、目標、主な成果の検索・参照・作成・更新が行えるようになりました。

`get_work_item`で単一アイテムの詳細を取得し、`list_work_items`でグループまたはプロジェクト横断の検索を行い、`save_work_item`であらゆる作業アイテムタイプの作成・更新が可能です。

イシューとエピックは作業アイテムタイプの一種であるため、`get_work_item`と`save_work_item`は、現在の`get_issue`および`create_issue`の機能をカバーしています。

`save_note`を使用すると、エージェントが作業アイテムやマージリクエストにコメントを投稿したり、既存のディスカッションスレッドに返信したりできます。このツールの導入に伴い、既存の`create_merge_request_note`および`create_workitem_note`はリネームされました。
