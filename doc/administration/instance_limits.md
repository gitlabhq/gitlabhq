---
type: reference
---

# GitLab application limits

GitLab, like most large applications, enforces limits within certain features to maintain a
minimum quality of performance. Allowing some features to be limitless could affect security,
performance, data, or could even exhaust the allocated resources for the application.

## Number of comments per issue, merge request or commit

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/22388) in GitLab 12.4.

There's a limit to the number of comments that can be submitted on an issue,
merge request, or commit. When the limit is reached, system notes can still be
added so that the history of events is not lost, but user-submitted comments
will fail.

- **Max limit:** 5.000 comments

## Size of comments and descriptions of issues, merge requests, and epics

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/61974) in GitLab 12.2.

There is a limit to the size of comments and descriptions of issues, merge requests, and epics.
Attempting to add a body of text larger than the limit will result in an error, and the
item will not be created.

It's possible that this limit will be changed to a lower number in the future.

- **Max size:** ~1 million characters / ~1 MB

## Number of issues in the milestone overview

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/39453) in GitLab 12.10.

The maximum number of issues loaded on the milestone overview page is 3000.
When the number exceeds the limit the page displays an alert and links to a paginated
[issue list](../user/project/issues/index.md#issues-list) of all issues in the milestone.

- **Limit:** 3000 issues

## Number of pipelines per Git push

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/51401) in GitLab 11.10.

The number of pipelines that can be created in a single push is 4.
This is to prevent the accidental creation of pipelines when `git push --all`
or `git push --mirror` is used.

Read more in the [CI documentation](../ci/yaml/README.md#processing-git-pushes).

## Retention of activity history

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/21164) in GitLab 8.12.

Activity history for projects and individuals' profiles was limited to one year until [GitLab 11.4](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/52246) when it was extended to two years, and in [GitLab 12.4](https://gitlab.com/gitlab-org/gitlab/-/issues/33840) to three years.

## Number of embedded metrics

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/14939) in GitLab 12.7.

There is a limit when embedding metrics in GFM for performance reasons.

- **Max limit:** 100 embeds

## Number of webhooks

On GitLab.com, the [maximum number of webhooks](../user/gitlab_com/index.md#maximum-number-of-webhooks) per project, and per group, is limited.

To set this limit on a self-managed installation, run the following in the
[GitLab Rails console](troubleshooting/debug.md#starting-a-rails-console-session):

```ruby
# If limits don't exist for the default plan, you can create one with:
# Plan.default.create_limits!

# For project webhooks
Plan.default.limits.update!(project_hooks: 100)

# For group webhooks
Plan.default.limits.update!(group_hooks: 100)
```

NOTE: **Note:** Set the limit to `0` to disable it.

## Incoming emails from auto-responders

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/30327) in GitLab 12.4.

GitLab ignores all incoming emails sent from auto-responders by looking for the `X-Autoreply`
header. Such emails don't create comments on issues or merge requests.

## Amount of data sent from Sentry via Error Tracking

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/14926) in GitLab 12.6.

Sentry payloads sent to GitLab have a 1 MB maximum limit, both for security reasons
and to limit memory consumption.

## Max offset allowed via REST API for offset-based pagination

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/34565) in GitLab 13.0.

When using offset-based pagination in the REST API, there is a limit to the maximum
requested offset into the set of results. This limit is only applied to endpoints that
support keyset-based pagination. More information about pagination options can be
found in the [API docs section on pagination](../api/README.md#pagination).

To set this limit on a self-managed installation, run the following in the
[GitLab Rails console](troubleshooting/debug.md#starting-a-rails-console-session):

```ruby
# If limits don't exist for the default plan, you can create one with:
# Plan.default.create_limits!

Plan.default.limits.update!(offset_pagination_limit: 10000)
```

- **Default offset pagination limit:** 50000

NOTE: **Note:** Set the limit to `0` to disable it.

## CI/CD limits

### Number of jobs in active pipelines

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/32823) in GitLab 12.6.

The total number of jobs in active pipelines can be limited per project. This limit is checked
each time a new pipeline is created. An active pipeline is any pipeline in one of the following states:

- `created`
- `pending`
- `running`

If a new pipeline would cause the total number of jobs to exceed the limit, the pipeline
will fail with a `job_activity_limit_exceeded` error.

- On GitLab.com different [limits are defined per plan](../user/gitlab_com/index.md#gitlab-cicd) and they affect all projects under that plan.
- On [GitLab Starter](https://about.gitlab.com/pricing/#self-managed) tier or higher self-managed installations, this limit is defined for the `default` plan that affects all projects.
  This limit is disabled by default.

To set this limit on a self-managed installation, run the following in the
[GitLab Rails console](troubleshooting/debug.md#starting-a-rails-console-session):

```ruby
# If limits don't exist for the default plan, you can create one with:
# Plan.default.create_limits!

Plan.default.limits.update!(ci_active_jobs: 500)
```

NOTE: **Note:** Set the limit to `0` to disable it.

### Number of CI/CD subscriptions to a project

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/9045) in GitLab 12.9.

The total number of subscriptions can be limited per project. This limit is
checked each time a new subscription is created.

If a new subscription would cause the total number of subscription to exceed the
limit, the subscription will be considered invalid.

- On GitLab.com different [limits are defined per plan](../user/gitlab_com/index.md#gitlab-cicd) and they affect all projects under that plan.
- On [GitLab Starter](https://about.gitlab.com/pricing/#self-managed) tier or higher self-managed installations, this limit is defined for the `default` plan that affects all projects.

To set this limit on a self-managed installation, run the following in the
[GitLab Rails console](troubleshooting/debug.md#starting-a-rails-console-session):

```ruby
Plan.default.limits.update!(ci_project_subscriptions: 500)
```

NOTE: **Note:** Set the limit to `0` to disable it.

### Number of pipeline schedules

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/29566) in GitLab 12.10.

The total number of pipeline schedules can be limited per project. This limit is
checked each time a new pipeline schedule is created. If a new pipeline schedule
would cause the total number of pipeline schedules to exceed the limit, the
pipeline schedule will not be created.

On GitLab.com, different limits are [defined per plan](../user/gitlab_com/index.md#gitlab-cicd),
and they affect all projects under that plan.

On self-managed instances ([GitLab Starter](https://about.gitlab.com/pricing/#self-managed)
or higher tiers), this limit is defined for the `default` plan that affects all
projects. By default, there is no limit.

To set this limit on a self-managed installation, run the following in the
[GitLab Rails console](troubleshooting/debug.md#starting-a-rails-console-session):

```ruby
Plan.default.limits.update!(ci_pipeline_schedules: 100)
```

### Number of instance level variables

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/216097) in GitLab 13.1.

The total number of instance level CI/CD variables is limited at the instance level.
This limit is checked each time a new instance level variable is created. If a new variable
would cause the total number of variables to exceed the limit, the new variable will not be created.

On self-managed instances this limit is defined for the `default` plan. By default,
this limit is set to `25`.

To update this limit to a new value on a self-managed installation, run the following in the
[GitLab Rails console](troubleshooting/debug.md#starting-a-rails-console-session):

```ruby
Plan.default.limits.update!(ci_instance_level_variables: 30)
```

## Instance monitoring and metrics

### Incident Management inbound alert limits

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/17859) in GitLab 12.5.

Limiting inbound alerts for an incident reduces the number of alerts (issues)
that can be created within a period of time, which can help prevent overloading
your incident responders with duplicate issues. You can reduce the volume of
alerts in the following ways:

- Max requests per period per project, 3600 seconds by default.
- Rate limit period in seconds, 3600 seconds by default.

### Prometheus Alert JSON payloads

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/19940) in GitLab 12.6.

Prometheus alert payloads sent to the `notify.json` endpoint are limited to 1 MB in size.

### Generic Alert JSON payloads

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/16441) in GitLab 12.4.

Alert payloads sent to the `notify.json` endpoint are limited to 1 MB in size.

## Environment data on Deploy Boards

[Deploy Boards](../user/project/deploy_boards.md) load information from Kubernetes about
Pods and Deployments. However, data over 10 MB for a certain environment read from
Kubernetes won't be shown.

## Merge Request reports

Reports that go over the 20 MB limit won't be loaded. Affected reports:

- [Merge Request security reports](../user/project/merge_requests/testing_and_reports_in_merge_requests.md#security-reports-ultimate)
- [CI/CD parameter `artifacts:expose_as`](../ci/yaml/README.md#artifactsexpose_as)
- [JUnit test reports](../ci/junit_test_reports.md)

## Advanced Global Search limits

### Maximum field length

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/201826) in GitLab 12.8.

You can set a limit on the content of text fields indexed for Global Search.
Setting a maximum helps to reduce the load of the indexing processes. If any
text field exceeds this limit then the text will be truncated to this number of
characters and the rest will not be indexed and hence will not be searchable.

- On GitLab.com this is limited to 20000 characters
- For self-managed installations it is unlimited by default

This limit can be configured for self-managed installations when [enabling
Elasticsearch](../integration/elasticsearch.md#enabling-elasticsearch).

NOTE: **Note:** Set the limit to `0` to disable it.

## Wiki limits

- [Length restrictions for file and directory names](../user/project/wiki/index.md#length-restrictions-for-file-and-directory-names).

## Snippets limits

See the [documentation on Snippets settings](snippets/index.md).

## Push Event Limits

### Webhooks and Project Services

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/31009) in GitLab 12.4.

Total number of changes (branches or tags) in a single push. If changes are more
than the specified limit, hooks won't be executed.

More information can be found in these docs:

- [Webhooks push events](../user/project/integrations/webhooks.md#push-events)
- [Project services push hooks limit](../user/project/integrations/overview.md#push-hooks-limit)

### Activities

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/31007) in GitLab 12.4.

Total number of changes (branches or tags) in a single push to determine whether
individual push events or bulk push event will be created.

More information can be found in the [Push event activities limit and bulk push events documentation](../user/admin_area/settings/push_event_activities_limit.md).
