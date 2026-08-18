---
title: Agentic Chatから基本フローを開始可能に
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: ai_clients
documentation_link: "../../../user/gitlab_duo_chat/agentic_chat"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/20484
categories: [ Web Chat ]
level: primary
weight: 20
---

これまでのバージョンのGitLabでは、基本フローは特定のUI操作、メンション、割り当てからのみ開始できました。
現在は、GitLabのUI上でAgentic Chatとの会話の一部として、これらのフローを開始できるようになりました。

リクエストがスペシャリストワークフローに一致すると、Agentic Chatは以下のフローのいずれかにハンドオフします。

- [デベロッパーフロー](../../../user/duo_agent_platform/flows/foundational_flows/developer.md):
  変更を実装するか、マージリクエストを作成します
- [コードレビューフロー](../../../user/duo_agent_platform/flows/foundational_flows/code_review.md):
  マージリクエストをレビューします
- [CI/CDパイプライン修正フロー](../../../user/duo_agent_platform/flows/foundational_flows/fix_pipeline.md):
  失敗したパイプラインを診断して修復します

チャットでハンドオフを承認すると、会話内または**AI** > **セッション**から進捗を確認できます。
