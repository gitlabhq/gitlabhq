---
title: GitLab MCPサーバーツールのガバナンス
offering: [ gitlab_com, self_managed, gitlab_dedicated, gitlab_dedicated_for_government ]
tier: [ Free, Premium, Ultimate ]
stage: software_supply_chain_security
documentation_link: "../../../user/ai-governance/tool-governance"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/628391
categories: [ AI Governance ]
level: primary
weight: 50
---

以前は、[AIエージェントツールガバナンス](../../../user/ai-governance/tool-governance.md)ルールをGitLab Duo Agent Platformの内部ツールにのみ適用できました。GitLab MCPサーバーを通じてGitLab Duo Agent Platformとサードパーティエージェントの両方で利用可能なツールは、変更できない固定ルールに従っていました。

GitLab MCPサーバーツールを、GitLab Duo Agent Platformの内部ツールと同じ場所から管理できるようになりました。グループおよびプロジェクトの**GitLab Duo**設定で内部ツールと並んで表示され、各ツールのモードを設定できます。

- 読み取り専用ツールはデフォルトで**常に許可**に設定されているため、定期的な参照はチームの作業を中断することなく実行されます。
- 書き込みおよび削除ツールはデフォルトで**常に確認**に設定されており、エージェントが変更を加える前にレビュアーが確認できるチェックポイントが設けられています。
