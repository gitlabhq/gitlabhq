---
title: CI/CD analytics now shows accurate pipeline rates
tier: [ Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: verify
documentation_link: "../../../user/analytics/ci_cd_analytics"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/599923
categories: [ Continuous Integration (CI) ]
level: secondary
---

In previous versions of GitLab, the failure rate and success rate metrics on the
CI/CD analytics page (`<project>/-/pipelines/charts`) included canceled and skipped pipelines
in their calculations. This caused both rates to appear lower than expected. For example,
on `gitlab-org/gitlab` the two rates summed to only 98% instead of approximately 100%.

Now, GitLab calculates the failure rate and success rate using only completed pipelines, so
the results accurately reflect your pipeline health.
