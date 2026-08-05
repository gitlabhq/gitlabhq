---
title: GitLab Duo Developer enhancements for merge request workflows
stage: ai-powered
level: primary
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
documentation_link: "../../../user/duo_agent_platform/flows/foundational_flows/developer/"
work_item: "https://gitlab.com/gitlab-org/gitlab/-/merge_requests/228817"
categories: [ Duo Agent Platform ]
weight: 40
---

GitLab Duo Developer now supports multiple trigger methods: assign it to an issue, select
**Generate MR**, or `@mention` it in any issue or MR discussion thread to turn feedback,
To-do items, and design questions into code changes, follow-up MRs, or research summaries.

With `AGENTS.md` and `agent-config.yml`
configured, GitLab Duo Developer runs your tests and checks before committing. After a top-level
group or instance administrator enables the Developer Flow, GitLab automatically adds mention and assign triggers
to eligible projects.
