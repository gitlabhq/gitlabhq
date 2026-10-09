---
title: Follow-up reviews in Code Review Flow
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: ai_coding
documentation_link: "../../../user/duo_agent_platform/flows/foundational_flows/code_review/#follow-up-reviews"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/21620
categories: [ DAP Code Review ]
level: secondary
weight: 50
---

In previous versions of GitLab, when you asked GitLab Duo to review a merge request again, it treated the review
as a first pass. It could repeat findings from its earlier threads, even ones you had
already addressed.

Now, Code Review Flow uses comment threads from earlier GitLab Duo reviews, including your replies, to evaluate
new changes. GitLab Duo focuses on lines added after its last review, does not repeat points it
already raised, and lists outstanding findings in its summary. If you reply on a thread to
explain why the code is correct, GitLab Duo does not raise the point again.

To start a follow-up review, ask GitLab Duo to review the merge request again. With
**Start a new review on push** turned on, GitLab Duo automatically starts a follow-up review when you push changes.
