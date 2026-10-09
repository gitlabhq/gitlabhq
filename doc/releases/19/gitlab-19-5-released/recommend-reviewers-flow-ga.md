---
title: Recommend reviewers with GitLab Duo
tier: [ Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: ai_coding
documentation_link: "../../../user/project/merge_requests/reviews/automatic_reviewer_assignment/#recommend-reviewers-flow"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/20711
categories: [ DAP Code Review ]
level: secondary
weight: 50
---

In previous versions of GitLab, you had to check each approval rule and guess who had time to review your merge request.
Or you assigned a whole group and hoped someone picked it up.

Now you can use the Recommend Reviewers Flow to suggest reviewers instead. The flow is generally available.

For each approval rule, it recommends the minimum number of reviewers needed, based on availability, workload, time zone, and recent activity.

Recommendations appear in the **Recommended** section of the merge request sidebar. Hover over a user to see why they were recommended.

To get started, turn on the flow for your top-level group. It runs when a merge request is created,
or you can create a trigger to run it when a draft is marked ready. To get new recommendations, select **Refresh**.
