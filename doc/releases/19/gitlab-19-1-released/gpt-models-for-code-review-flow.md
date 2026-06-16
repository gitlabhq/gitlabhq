---
title: GPT models for Code Review Flow
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
tier: [ Premium, Ultimate ]
stage: ai-powered
documentation_link: "../../../user/duo_agent_platform/model_selection/#supported-models"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/598322
categories: [ Duo Agent Platform, Duo Code Review ]
level: secondary
ignore_in_report: true
---

<!-- categories: Duo Agent Platform, Duo Code Review -->

In previous versions of GitLab, Code Review Flow supported only
Anthropic Claude models. Teams that could not use Anthropic models due to contractual, policy, or
procurement constraints had no way to run Code Review Flow.

You can now select GPT-5.2 or GPT-5.3 Codex as the model for Code Review Flow. Top-level
group Owners can switch the model for **Agentic Code Review** in **Settings** > **GitLab Duo** > **Configure features**, under **GitLab Duo Agent Platform**.
The GPT models are hosted through the GitLab AI Gateway, so no additional configuration
is required.

Both models passed benchmark evaluation against the GitLab Duo code review dataset, with review quality
comparable to the default Claude Sonnet 4.6 Vertex model. See the
[code review benchmark](https://duo-review-bench-6f7260.gitlab.io/) for results.
