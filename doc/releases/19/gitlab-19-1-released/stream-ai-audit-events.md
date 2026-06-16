---
title: Stream AI audit events to external destinations (beta)
offering: [ self_managed, gitlab_dedicated ]
tier: [ Ultimate ]
stage: software_supply_chain_security
documentation_link: "../../../administration/compliance/audit_event_streaming/#ai-audit-event-streaming"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/596268
categories: [ Audit Events ]
ignore_in_report: true
---

<!-- categories: Audit Events -->

You can now stream AI audit events to external destinations through the GitLab audit event streaming infrastructure, giving security and compliance teams real-time visibility into LLM and AI interactions.

With AI audit event streaming enabled, GitLab forwards these events to any active instance streaming destination, including your SIEM (Security Information and Event Management), alongside other audit events.
