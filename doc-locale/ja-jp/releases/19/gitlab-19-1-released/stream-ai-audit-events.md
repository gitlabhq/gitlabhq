---
title: AIの監査イベントを外部の宛先にストリーミング（ベータ版）
offering: [ self_managed, gitlab_dedicated ]
tier: [ Ultimate ]
stage: software_supply_chain_security
documentation_link: "../../../administration/compliance/audit_event_streaming/#ai-audit-event-streaming"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/22383
categories: [ Audit Events ]
---

<!-- categories: Audit Events -->

GitLab監査イベントストリーミングインフラストラクチャを通じて、AI監査イベントを外部宛先にストリーミングできるようになりました。これにより、セキュリティおよびコンプライアンスチームは、LLMとAIのインタラクションをリアルタイムで把握できます。

AI監査イベントストリーミングを有効にすると、GitLabはこれらのイベントを、SIEM（セキュリティ情報およびイベント管理）を含むアクティブなインスタンスのすべてのストリーミング先に、他の監査イベントとともに転送します。
