---
title: GitLab Duo Slackインテグレーション（実験的機能）
tier: [ Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: agent_foundations
documentation_link: "../../../user/project/integrations/gitlab_slack_application/#gitlab-duo"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/22438
categories: [ External Agents ]
weight: 50
---

GitLab UIに切り替えることなく、Slackから直接GitLab Duoエージェントフローを実行できるようになりました。

GitLab Duo Slackインテグレーションを使用すると、任意のSlackチャンネルやスレッドで`@GitLab`とメンションすることができます。GitLabをメンションすることで、エージェントフローのトリガー、コードベースからの回答取得、会話からのGitLabイシュー作成が可能です。GitLab Duoはリアルタイムで進捗をSlackスレッドにストリーミングし、Slackを離れることなく回答を評価できるサムズアップ・サムズダウンのフィードバックボタンも表示されます。

このインテグレーションは実験的機能として提供されています。フィードバックを共有するには、[イシュー624364](https://gitlab.com/gitlab-org/gitlab/-/work_items/624364)にコメントを追加してください。
