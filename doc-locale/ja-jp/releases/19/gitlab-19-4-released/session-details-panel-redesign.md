---
title: GitLab Duo Agent Platformのセッション詳細パネルを再設計
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: agent_foundations
documentation_link: "../../../user/duo_agent_platform/sessions/#view-sessions-for-your-project"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/22662
categories: [ Agent Observability ]
level: secondary
weight: 50
---

エージェントセッションに関する重要な詳細を確認するには、煩雑なパネルを探し回る必要がありました。
新しいセッション詳細パネルでは、必要な情報を一目で確認できます。ステータス、タイムスタンプ、トリガーした
ユーザーが概要バーに表示され、右側のレールにはID、実行、補足の詳細が明確にラベル付けされたグループとして整理されています。

新しい**リンクされたアイテム**セクションでは、セッションを開始したものと、マージリクエスト、作業アイテム、ジョブ、コメントなど、セッションが生成したものが分けて表示されます。GitLab Duoサイドパネルでは、セッションの詳細が下部に固定された折りたたみ可能なバーに表示されるようになり、作業の邪魔にならずにアクセスできます。
