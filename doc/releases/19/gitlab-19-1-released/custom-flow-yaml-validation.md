---
title: Custom flows YAML validation
tier: [ Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
documentation_link: "../../../user/duo_agent_platform/flows/custom"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/597224
categories: [ AI Catalog ]
stage: ai-powered
level: secondary
weight: 50
---
The AI Catalog now validates your custom flow configuration before saving or triggering it.

Previously, syntax errors and misconfigured parameters in a custom flow (for example, missing inputs or unknown tool parameters) only surfaced at runtime, after a CI job had already started. This made debugging slow and difficult.

Now, when you save or update a custom flow in the AI Catalog, GitLab checks the configuration upfront and surfaces any errors directly in the UI. Valid flows are unaffected and continue to save and trigger as usual.
