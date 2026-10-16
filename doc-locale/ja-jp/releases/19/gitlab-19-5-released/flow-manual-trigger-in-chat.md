---
title: GitLab Duo Agentic Chatでカスタムフローを開始する
tier: [Free, Premium, Ultimate]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: ai_catalog
documentation_link: "../../../user/duo_agent_platform/agents/foundational_agents/flow_creator/"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/605161
categories: [ AI Catalog Creation ]
level: secondary
weight: 50
---

GitLab Duo Agentic Chatから、トリガーを事前に設定することなく、カスタムフローを直接開始できるようになりました。
以前は、カスタムフローを実行するには、メンション、アサイン、その他のイベントなどのトリガーイベントを設定する必要があり、フローのテストやイテレーションが困難でした。今回のリリースで、GitLab Duo Agentic Chatでメッセージを送信するだけで、プロジェクトで有効化されているAI Catalogフローを起動できるようになりました。送信したメッセージがフローのゴールとなります。ゴールを指定しない場合は、フロー自体の説明がゴールとして使用されます。
Chatには生成されたエージェントセッションへのリンクが表示されるため、進捗を確認できます。
