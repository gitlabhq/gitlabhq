---
title: "Exclude merge requests from automatic code reviews (Beta)"
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
tier: [ Free, Premium, Ultimate ]
stage: ai_coding
documentation_link: "../../../user/duo_agent_platform/flows/foundational_flows/code_review/#exclude-merge-requests-from-automatic-reviews"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/21585
categories: [ DAP Code Review ]
---


In previous versions of GitLab, when automatic reviews were turned on for a project or group, GitLab Duo reviewed every eligible merge request.
This included bot-authored dependency updates, feature branches, and experimental work, not just changes the team actually wanted feedback on.

You can now exclude specific merge requests from automatic reviews using exclusion rules.
Define a `.gitlab/duo/mr-review-automated-rules.yaml` file for a project or group, with exclusion rules based on the author, source branch, or target branch.
Rules support glob patterns like `dependabot/*` or `*-bot`.

You can still request a review manually for any excluded merge request.

This feature is in beta and is gated behind the `duo_code_review_automated_rules` feature flag, enabled by default.
