---
title: Fix CI/CD Pipeline Flow suggests targeted fixes
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated, gitlab_dedicated_for_government ]
stage: verify
documentation_link: "../../../user/duo_agent_platform/flows/foundational_flows/fix_pipeline"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/21837
categories: [ Continuous Integration (CI) ]
level: secondary
weight: 10
---

GitLab Duo's Fix CI/CD Pipeline Flow now gives you two core improvements:

- When relevant files are already in your merge request diff, you get fixes as code suggestions directly on that merge request.
- The flow classifies pipeline failures before acting, so you get a more targeted diagnosis.

The flow also analyzes child pipeline failures across the full pipeline hierarchy,
lets you customize its behavior for your project with an `AGENTS.md` file,
and collapses AI reasoning by default to keep your merge request comments clean.

Share your feedback in the [feedback issue](https://gitlab.com/gitlab-org/gitlab/-/work_items/601991).
