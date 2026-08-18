---
title: カスタムエージェントの検証
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: agent_foundations
documentation_link: "../../../user/duo_agent_platform/agents/custom"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/601986
categories: [ AI Catalog Creation ]
level: secondary
weight: 50
---

以前は、実行時にプロンプトが失敗するカスタムエージェントをAIカタログに保存できました。たとえば、セキュリティルールに抵触するプロンプトを使用すると、エージェントは使用中に何も行わず、エラーも表示されませんでした。

カスタムエージェントを作成または更新する際、GitLabがプロンプトの設定を検証し、エージェントを保存する前にエラーを通知するようになりました。
