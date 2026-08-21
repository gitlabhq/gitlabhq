---
title: カスタムエージェントとフローの制限付き表示レベル
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: ai_catalog
documentation_link: "../../../user/duo_agent_platform/agents/custom/"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/22590
categories: [ AI Catalog Creation ]
level: secondary
weight: 50
---

カスタムエージェントとカスタムフローの表示レベルを、トップレベルグループ内のすべてのグループ、サブグループ、プロジェクトに対して**制限付き**に設定できるようになりました。

以前は、カスタムフローまたはエージェントの表示レベルを**非公開**（1つのプロジェクトのみ）または**公開**（GitLab.com上の全員に表示）にしか設定できませんでした。表示レベルを**制限付き**に設定すると、フローまたはエージェントはトップレベルグループ内のグループ、サブグループ、プロジェクトにのみ表示されます。これにより、カスタムエージェントとフローに関する内部ロジックが社外や組織外に共有されることを防ぎます。
