---
title: "GitLab Duoエージェントのツール承認ガードレール（ベータ版）"
offering: [ gitlab_com, self_managed, gitlab_dedicated, gitlab_dedicated_for_government ]
tier: [ Premium, Ultimate ]
stage: software_supply_chain_security
documentation_link: "../../../user/duo_agent_platform/agents/tool-governance/"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/22381
categories: [ AI Governance ]
level: primary
---

<!-- categories: AI Governance -->

管理者は、GitLab Duoエージェントに対してツールレベルの承認ポリシーを設定できるようになりました。これにより、実行時に人間の承認を必要とするゲートを設けて、機密性の高い操作を保護できます。

これまでは、AIエージェントがプロジェクトで承認されると、書き込みや削除などの操作を含む、あらゆるツールをさらなるレビューなしに実行できました。
今回のリリースで、グループおよびプロジェクトに対して、各ツールを次の3つのモードのいずれかにマッピングするルールを定義できるようになりました。

- Allow　許可（サイレント実行）
- Ask　確認（人間の承認が必要）
- Deny　拒否（完全にブロック）

AIエージェントが「Ask」モードのツールを呼び出すと、実行前にインライン承認カードがユーザーに表示されます。

このベータ版リリースには、Agentic Chat、IDE、およびフローが含まれており、すべての承認決定に対して監査イベントが出力されます。
