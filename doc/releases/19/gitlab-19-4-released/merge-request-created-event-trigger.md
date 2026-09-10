---
title: Merge request created event trigger
tier: [ Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: ai_coding
documentation_link: "../../../user/duo_agent_platform/triggers/"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/22279
categories: [ DAP Triggers ]
level: secondary
weight: 50
---

In previous versions of GitLab, the **Merge request** trigger event type only supported the **Approved**, **Marked ready**, and **Merge conflict** actions. You had no way to run a flow or external agent the moment someone opened a merge request without using a tool outside GitLab.

You can now select **Created** as a trigger action. When someone opens a merge request in draft or ready state, and GitLab generates the diff, your flow or external agent runs. Use this for a first-pass review, or to add context from related issues.

To configure this trigger, go to **AI > Triggers** in your project, or select it when you enable a flow.
