---
title: 外部接続エージェント（ECA）をAIガバナンスに接続する
tier: [ Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: software_supply_chain_security
documentation_link: "../../../user/ai-governance/externally-connected-agents"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/633489
categories: [ AI Governance ]
level: primary
weight: 50
---

これまで、[AIガバナンスダッシュボード](../../../user/ai-governance/governance-dashboard.md)はGitLab Duo Agent Platformのエージェントからのアクティビティのみを表示していました。これにより、エージェントが実行していたセッション（ツール呼び出し、使用されたMCP、ユーザーとエージェントそれぞれからのプロンプトの入力と出力を含む）など、すべてのAgent Platformエージェントを完全に可視化できていました。

GitLab 19.5のリリースにより、一度だけ`glab govern setup`を実行することで、ガバナンスの可視化範囲をGitLab Duo Agent Platformのエージェントだけでなく、GitLab CLI（`glab`）を使用してClaude Code、Cursor、CodexなどのECA（外部接続エージェント）をGitLab AIガバナンスに接続できるようになりました。

**外部エージェントを許可する**と**AIの監査イベントを保存する**が有効になっている場合、セキュリティおよびコンプライアンスチームは、GitLab Duo Agent Platformのエージェントと並んで、GitLab外部で実行されるECAを可視化できます。対象となるすべてのエージェントセッションが記録され、実行者、エージェント、プロジェクト、実行日時が把握でき、セッションとツール呼び出しはAIガバナンスダッシュボードおよびAI監査イベントレポートに表示されます。監査イベントは、監査イベントストリーミングを通じてSIEMにも送信されます。

ツールの出力は送信されませんが、失敗したツール呼び出しからの短いエラーメッセージは例外です。

この機能はベータ版です。[イシュー633489](https://gitlab.com/gitlab-org/gitlab/-/work_items/633489)でフィードバックをお寄せください。
