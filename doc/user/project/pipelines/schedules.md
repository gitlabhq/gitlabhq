---
type: reference, howto
---

# Pipeline schedules

> - Introduced in GitLab 9.1 as [Trigger Schedule](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/10533).
> - [Renamed to Pipeline Schedule](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/10853) in GitLab 9.2.

NOTE: **Note:**
Cron notation is parsed by [Fugit](https://github.com/floraison/fugit).

Pipelines are normally run based on certain conditions being met. For example, when a branch is pushed to repository.

Pipeline schedules can be used to also run [pipelines](../../../ci/pipelines.md) at specific intervals. For example:

- Every month on the 22nd for a certain branch.
- Once every day.

In addition to using the GitLab UI, pipeline schedules can be maintained using the
[Pipeline schedules API](../../../api/pipeline_schedules.md).

## Configuring pipeline schedules

To schedule a pipeline for project:

1. Navigate to the project's **CI / CD > Schedules** page.
1. Click the **New schedule** button.
1. Fill in the **Schedule a new pipeline** form.
1. Click the **Save pipeline schedule** button.

![New Schedule Form](img/pipeline_schedules_new_form.png)

NOTE: **Note:**
Pipelines execution [timing is dependent](#advanced-configuration) on Sidekiq's own schedule.

In the **Schedules** index page you can see a list of the pipelines that are
scheduled to run. The next run is automatically calculated by the server GitLab
is installed on.

![Schedules list](img/pipeline_schedules_list.png)

### Using variables

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/12328) in GitLab 9.4.

You can pass any number of arbitrary variables and they will be available in
GitLab CI so that they can be used in your [`.gitlab-ci.yml` file](../../../ci/yaml/README.md).

![Scheduled pipeline variables](img/pipeline_schedule_variables.png)

### Using only and except

To configure that a job can be executed only when the pipeline has been
scheduled (or the opposite), you can use
[only and except](../../../ci/yaml/README.md#onlyexcept-basic) configuration keywords.

For example:

```yaml
job:on-schedule:
  only:
    - schedules
  script:
    - make world

job:
  except:
    - schedules
  script:
    - make build
```

### Advanced configuration

The pipelines won't be executed exactly on schedule because schedules are handled by
Sidekiq, which runs according to its interval.

For example, only two pipelines will be created per day if:

- You set a schedule to create a pipeline every minute (`* * * * *`).
- The Sidekiq worker runs on 00:00 and 12:00 every day (`0 */12 * * *`).

To change the Sidekiq worker's frequency:

1. Edit the `gitlab_rails['pipeline_schedule_worker_cron']` value in your instance's `gitlab.rb` file.
1. [Restart GitLab](../../../administration/restart_gitlab.md).

For GitLab.com, refer to the [dedicated settings page](../../gitlab_com/index.md#cron-jobs).

## Working with scheduled pipelines

Once configured, GitLab supports many functions for working with scheduled pipelines.

### Running manually

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/15700) in GitLab 10.4.

To trigger a pipeline schedule manually, click the "Play" button:

![Play Pipeline Schedule](img/pipeline_schedule_play.png)

This will schedule a background job to run the pipeline schedule. A flash
message will provide a link to the CI/CD Pipeline index page.

NOTE: **Note:**
To help avoid abuse, users are rate limited to triggering a pipeline once per
minute.

### Taking ownership

Pipelines are executed as a user, who owns a schedule. This influences what projects and other resources the pipeline has access to.

If a user does not own a pipeline, you can take ownership by clicking the **Take ownership** button.
The next time a pipeline is scheduled, your credentials will be used.

![Schedules list](img/pipeline_schedules_ownership.png)

NOTE: **Note:**
If the owner of a pipeline schedule doesn't have the ability to create pipelines
on the target branch, the schedule will stop creating new pipelines. This can
happen if, for example, the owner is blocked or removed from the project, or
the target branch or tag is protected. In this case, someone with sufficient
privileges must take ownership of the schedule.

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
