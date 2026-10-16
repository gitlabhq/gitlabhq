---
title: "GitLab MCPサーバーの新しいレート制限"
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com ]
stage: agent_foundations
documentation_link: "../../../user/model_context_protocol/mcp_server/#rate-limits"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/22800
categories: [ Agent Tools ]
level: secondary
weight: 50
---

現在、MCPを介してエージェントをGitLabに接続している場合、ワークフローで実際に必要な頻度を超えて再接続や再試行が行われても制限がなく、GitLab.comではそのコストが発生します。

10月15日より、GitLab.com上のGitLab MCPサーバーでは、Freeプランのユーザーは1分あたり60リクエスト、PremiumおよびUltimateでは600リクエストに制限されます。再接続と再試行はすべてこの制限にカウントされます。エージェントでレート制限（HTTP 429）エラーが発生し始めた場合は、上位プランへのアップグレードを検討する前に、エージェントの再接続および再試行の設定を確認してください。
