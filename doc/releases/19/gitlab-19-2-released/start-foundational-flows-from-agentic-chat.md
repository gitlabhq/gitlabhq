---
title: Start foundational flows from Agentic Chat
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: ai_clients
documentation_link: "../../../user/gitlab_duo_chat/agentic_chat"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/20484
categories: [ Web Chat ]
level: primary
weight: 20
---

In previous versions of GitLab, you started foundational flows from specific
UI actions, mentions, or assignments.
Now you can start them from Agentic Chat
in the GitLab UI as part of your conversation. 

When your request matches a specialist workflow, Agentic Chat hands off to one of these flows:

- [Developer Flow](../../../user/duo_agent_platform/flows/foundational_flows/developer.md):
  Implements changes or opens a merge request
- [Code Review Flow](../../../user/duo_agent_platform/flows/foundational_flows/code_review.md):
  Reviews a merge request
- [Fix CI/CD Pipeline Flow](../../../user/duo_agent_platform/flows/foundational_flows/fix_pipeline.md):
  Diagnoses and repairs a failed pipeline

You approve the handoff in chat, then follow progress in the conversation or
from **AI** > **Sessions**.
