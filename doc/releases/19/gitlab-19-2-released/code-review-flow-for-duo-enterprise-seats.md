---
title: Code Review Flow for GitLab Duo Enterprise seats
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
tier: [ Premium, Ultimate ]
stage: ai_coding
documentation_link: "../../../user/project/merge_requests/duo_in_merge_requests/#turn-on-code-review-flow-for-gitlab-duo-enterprise-seats"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/22247
categories: [ DAP Code Review ]
---

In previous versions of GitLab, when users with GitLab Duo Enterprise seats requested a code review from GitLab Duo, GitLab Duo Code Review would complete the review. 
This would occur even if Code Review Flow was turned on for the group. There was no way to turn on the agentic flow for all users.

Now, top-level group Owners can change this default and configure all code reviews to use Code Review Flow instead,
regardless of the user's seat. All reviews will consume GitLab Credits.

This change gives users with GitLab Duo Enterprise seats the same repository-wide context awareness, multi-step reasoning, and review sessions as everyone else.
