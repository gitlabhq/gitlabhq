---
title: AI監査イベントレポート（ベータ版）
offering: [ gitlab_com, self_managed, gitlab_dedicated, gitlab_dedicated_for_government ]
tier: [ Premium, Ultimate ]
stage: software_supply_chain_security
documentation_link: "../../../user/duo_agent_platform/ai-audit-events/"
work_item: "https://gitlab.com/groups/gitlab-org/-/work_items/20237"
categories: [ Compliance Management, Audit Events ]
level: primary
ignore_in_report: true
---

<!-- categories: Compliance Management, Audit Events -->

AI監査イベントレポートがベータ版として利用可能になりました。セキュリティおよびコンプライアンスチームは、GitLab Duoエージェントのアクティビティを一元的にダウンロード可能な記録として確認できます。

これまで、エージェントのアクティビティはパイプラインジョブやイベント履歴に分散しており、以下の目的でセッションを再構成することが困難でした。

- インシデント調査。
- コンプライアンスレビュー。
- AIガバナンスレポート。

今回のリリースで、各エージェントセッションが以下の情報を含む包括的な監査アーティファクトを生成するようになりました。

- 入力。
- モデルおよび設定コンテキスト。
- 時系列のイベントタイムライン。
- 出力。

**ガバナンス**ページからAI監査イベントを参照し、エージェントやセッションの詳細でフィルタリングして、個々のイベントを詳しく確認したり、基となるセッションアーティファクトをダウンロードしたりできます。
