---
title: マージリクエスト準備完了イベントトリガー
stage: ai-powered
level: secondary
tier: [ Premium, Ultimate ]
offering: [ gitlab_com, self_managed ]
documentation_link: "../../../user/duo_agent_platform/triggers/"
work_item: "https://gitlab.com/gitlab-org/gitlab/-/work_items/592454"
categories: [ Duo Agent Platform ]
weight: 30
---

フローと外部エージェントを**マージリクエスト準備完了**イベントで実行するよう設定できるようになりました。

ドラフトのマージリクエストがレビュー準備完了としてマークされると、GitLab Duoが自動的にフローまたは外部エージェントを実行します。

トリガーを設定するには、プロジェクトで**AI** > **トリガー**に移動してください。

この機能は`merge_request_ready_flow_trigger`機能フラグの背後にあり、デフォルトでは無効になっています。
