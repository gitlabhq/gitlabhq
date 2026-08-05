---
title: Configure parallel pipeline limits for merge trains
stage: verify
level: secondary
tier: [ Premium, Ultimate ]
offering: [ self_managed, gitlab_dedicated ]
documentation_link: "../../../administration/cicd/limits/#merge-train-parallel-pipeline-limit"
work_item: "https://gitlab.com/gitlab-org/gitlab/-/work_items/374188"
categories: [ Continuous Integration (CI) ]
weight: 90
---

In previous versions of GitLab, you couldn't change the maximum of 20 parallel pipelines in a merge train,
which forced you to either overwhelm your runners or skip merge trains entirely.
Now you can configure the parallel pipeline limit per merge train to balance runner load and merge throughput.
You can set the limit per project or instance-wide.
Setting the limit to 1 means each merge request runs one at a time, against a clean target branch.

Thanks to [Norman Debald (@Modjo85)](https://gitlab.com/Modjo85) for this community contribution.
