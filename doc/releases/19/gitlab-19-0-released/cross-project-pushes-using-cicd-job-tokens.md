---
title: Cross-project pushes using CI/CD job tokens
stage: verify
level: secondary
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated, gitlab_dedicated_for_government ]
documentation_link: "../../../ci/jobs/ci_job_token/#allow-cross-project-git-push-requests-from-allowlisted-projects"
work_item: "https://gitlab.com/gitlab-org/gitlab/-/issues/479907"
categories: [ Continuous Integration (CI) ]
weight: 120
---

In previous versions of GitLab, you could only use a CI/CD job token (`CI_JOB_TOKEN`) to push
to the same repository where the pipeline runs. Cross-project pushes required a personal access
token or deploy token.

You can now use a job token to push to another project when:

1. The target project opts in.
1. The user who starts the pipeline has at least the Developer role in the target project.

This feature is behind the `allow_push_to_allowlisted_projects` feature flag, disabled by default
in GitLab 19.0. Ask your administrator to enable it.
