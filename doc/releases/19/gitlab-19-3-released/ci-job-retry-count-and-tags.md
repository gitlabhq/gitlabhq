---
title: "Two new CI/CD variables: retry count and job tags"
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated, gitlab_dedicated_for_government ]
stage: verify
co_create: true
documentation_link: "../../../ci/variables/predefined_variables/"
work_item: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/?sort=created_date&state=merged&milestone_title=19.3&label_name%5B%5D=Community%20contribution&label_name%5B%5D=release%20post%20item&label_name%5B%5D=group%3A%3Apipeline%20authoring
categories: [ Pipeline Composition ]
level: secondary
---

Your pipeline scripts can now tell whether they are running for the first time.
`CI_JOB_RETRY_COUNT` holds how many times the current job has been retried and is `0` on the
first run, so retry-aware logic no longer needs you to track state yourself. Separately,
`CI_JOB_TAGS` exposes the job's own configured tags, where previously only the runner's tags
were visible through `CI_RUNNER_TAGS`. Both are available with no configuration.

Thank you to [Giannis Kepas](https://gitlab.com/gkepas) and
[Dwight Blake](https://gitlab.com/lunivilen) for these contributions!
