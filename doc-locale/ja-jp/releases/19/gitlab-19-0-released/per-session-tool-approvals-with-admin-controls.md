---
title: セッション単位のツール承認と管理者コントロール
stage: ai-powered
level: secondary
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
documentation_link: "../../../user/gitlab_duo_chat/agentic_chat/#tool-approvals"
work_item: "https://gitlab.com/gitlab-org/gitlab/-/work_items/596366"
categories: [ Duo Agent Platform, Duo Chat ]
weight: 70
---

GitLab Duo Agentic Chatがツールを使用するには、その都度ユーザーの承認が必要でした。

今回のリリースで、信頼できるツールをセッション内で一度だけ承認すれば、同じセッション中は再承認なしで使用できるようになりました。ワークフローをより効率的に進めることができます。

管理者は、セッション単位のツール承認機能を使用可能にするかどうかを制御できます。以下の設定はインスタンスからグループ、プロジェクトへとカスケードされます。

- **デフォルトでオン**
- **デフォルトでオフ**
- **常にオフ**

管理者が**常にオフ**に設定しない限り、グループおよびサブグループは設定を変更できます。

デフォルト設定は**デフォルトでオフ**であり、管理者が変更しない限り、各ツールの実行には明示的な承認が必要です。
