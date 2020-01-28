---
type: reference
---

# GitLab application limits

GitLab, like most large applications, enforces limits within certain features to maintain a
minimum quality of performance. Allowing some features to be limitless could affect security,
performance, data, or could even exhaust the allocated resources for the application.

## Number of comments per issue, merge request or commit

> [Introduced](https://gitlab.com/gitlab-org/gitlab/issues/22388) in GitLab 12.4.

There's a limit to the number of comments that can be submitted on an issue,
merge request, or commit. When the limit is reached, system notes can still be
added so that the history of events is not lost, but user-submitted comments
will fail.

- **Max limit:** 5.000 comments

## Number of pipelines per Git push

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/issues/51401) in GitLab 11.10.

The number of pipelines that can be created in a single push is 4.
This is to prevent the accidental creation of pipelines when `git push --all`
or `git push --mirror` is used.

Read more in the [CI documentation](../ci/yaml/README.md#processing-git-pushes).

## Retention of activity history

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/issues/21164) in GitLab 8.12.

Activity history for projects and individuals' profiles was limited to one year until [GitLab 11.4](https://gitlab.com/gitlab-org/gitlab-foss/issues/52246) when it was extended to two years, and in [GitLab 12.4](https://gitlab.com/gitlab-org/gitlab/issues/33840) to three years.

## Number of project webhooks

> [Introduced](https://gitlab.com/gitlab-org/gitlab/merge_requests/20730) in GitLab 12.6.

A maximum number of project webhooks applies to each GitLab.com tier. Check the
[Maximum number of webhooks (per tier)](../user/project/integrations/webhooks.md#maximum-number-of-webhooks-per-tier)
section in the Webhooks page.

To set this limit on a self-hosted installation, run the following in the
[GitLab Rails console](https://docs.gitlab.com/omnibus/maintenance/#starting-a-rails-console-session):

```ruby
# If limits don't exist for the default plan, you can create one with:
# Plan.default.create_limits!

Plan.default.limits.update!(project_hooks: 100)
```

NOTE: **Note:** Set the limit to `0` to disable it.

## CI/CD limits

### Number of jobs in active pipelines

> [Introduced](https://gitlab.com/gitlab-org/gitlab/issues/32823) in GitLab 12.6.

The total number of jobs in active pipelines can be limited per project. This limit is checked
each time a new pipeline is created. An active pipeline is any pipeline in one of the following states:

- `created`
- `pending`
- `running`

If a new pipeline would cause the total number of jobs to exceed the limit, the pipeline
will fail with a `job_activity_limit_exceeded` error.

- On GitLab.com different [limits are defined per plan](../user/gitlab_com/index.md#gitlab-cicd) and they affect all projects under that plan.
- On [GitLab Starter](https://about.gitlab.com/pricing/#self-managed) tier or higher self-hosted installations, this limit is defined for the `default` plan that affects all projects.
  This limit is disabled by default.

To set this limit on a self-hosted installation, run the following in the
[GitLab Rails console](https://docs.gitlab.com/omnibus/maintenance/#starting-a-rails-console-session):

```ruby
# If limits don't exist for the default plan, you can create one with:
# Plan.default.create_limits!

Plan.default.limits.update!(ci_active_jobs: 500)
```

NOTE: **Note:** Set the limit to `0` to disable it.
