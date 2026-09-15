---
title: GitLab flow builder for custom flows (Beta)
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: ai_clients
documentation_link: "../../../user/duo_agent_platform/flows/custom/#create-a-flow"
work_item: https://gitlab.com/groups/gitlab-org/editor-extensions/-/work_items/236
categories: [ AI Catalog Creation ]
level: secondary
weight: 50
---

Build custom flows for your GitLab projects with the GitLab flow builder, a new visual
editor for AI-native workflows in the GitLab for VS Code extension.
Compose a flow visually from components (Agent, Custom tool, and AI task), or edit the
underlying YAML directly.

To start, open your flow's YAML file in VS Code and select **Open GitLab Flow Builder**.
Test your flow with the **Run** button, which opens an execution console.
When your flow is ready, select **Publish** to publish it to the AI Catalog.

The flow builder is available as a beta feature in GitLab for VS Code 6.87.0 and later. To get started, enable the `gitlab.featureFlags.flowBuilder` setting in VS Code.
