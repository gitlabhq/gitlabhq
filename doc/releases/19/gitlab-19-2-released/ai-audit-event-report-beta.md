---
title: AI audit event report (beta)
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

AI audit event reports are now available in beta, giving security and compliance teams a unified,
downloadable record of GitLab Duo agent activity.

Previously, agent activity was scattered across pipeline jobs and event histories, making it
difficult to reconstruct a session for:

- Incident investigation.
- Compliance review.
- AI governance reporting.

Now, each agent session produces a comprehensive audit artifact capturing:

- Inputs.
- Model and configuration context.
- The chronological event timeline.
- Outputs.

You can browse AI audit events from the **Governance** page, filter by agent and session details,
drill into individual events, and download the underlying session artifact.
