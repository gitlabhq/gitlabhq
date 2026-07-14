---
title: Agentic Chatのパターンベースのツール承認
offering: [ gitlab_com, self_managed, gitlab_dedicated]
tier: [ Premium, Ultimate ]
stage: ai-powered
documentation_link: "../../../user/gitlab_duo_chat/agentic_chat/#approve-tools-in-your-local-environment"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/21850
categories: [ 'Duo Agent Platform', 'Duo Chat', 'Editor Extensions' ]
weight: 50
---

<!-- categories: Duo Agent Platform, Duo Chat, Editor Extensions -->

これまで、Agentic Chatがツールの呼び出しを承認するよう求めた際、1回だけ承認するか、セッション中に同じ引数でのツール呼び出しをまとめて承認するかを選択できました。異なる引数を使用する場合は、その都度追加の承認が必要でした。

`git` 操作の連続実行など、類似したコマンドを繰り返すワークフローでは、ほぼ同一のプロンプトが次々と表示されていました。

今回のリリースで、新たに3つ目の承認オプションとして、**Approve all uses of this tool for session** （セッション中このツールのすべての使用を承認する）が追加されました。このオプションを選択すると、引数が承認済みのパターンに一致する限り、セッション中のそのツールの呼び出しがすべて承認されます。

パターンベースの承認は、GitLab UI、GitLab Duo CLI、GitLab for VS Code、およびJetBrains IDE向けGitLab DuoプラグインのAgentic Chatで利用できます。
