---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
disqus_identifier: 'https://docs.gitlab.com/ee/user/project/pipelines/schedules.html'
type: reference, howto
---

# Pipeline schedules **(FREE)**

Use scheduled pipelines to run GitLab CI/CD [pipelines](index.md) at regular intervals.

## Prerequisites

For a scheduled pipeline to run:

- The schedule owner must have the Developer role. For pipelines on protected branches,
  the schedule owner must be [allowed to merge](../../user/project/protected_branches.md#configure-a-protected-branch)
  to the branch.
- The [CI/CD configuration](../yaml/index.md) must be valid.

Otherwise, the pipeline is not created. No error message is displayed.

## Add a pipeline schedule

To add a pipeline schedule:

1. On the top bar, select **Menu > Projects** and find your project.
1. On the left sidebar, select **CI/CD > Schedules**.
1. Select **New schedule** and fill in the form.
   - **Interval Pattern**: Select one of the preconfigured intervals, or enter a custom
     interval in [cron notation](../../topics/cron/index.md). You can use any cron value,
     but scheduled pipelines cannot run more frequently than the instance's
     [maximum scheduled pipeline frequency](../../administration/cicd.md#change-maximum-scheduled-pipeline-frequency).
   - **Variables**: Add any number of [CI/CD variables](../variables/index.md) to the schedule.
     These variables are available only when the scheduled pipeline runs,
     and not in any other pipeline run.

## Run manually

To trigger a pipeline schedule manually, so that it runs immediately instead of
the next scheduled time:

1. On the top bar, select **Menu > Projects** and find your project.
1. On the left sidebar, select **CI/CD > Schedules**.
1. On the right of the list, for
   the pipeline you want to run, select **Play** (**{play}**).

You can manually run scheduled pipelines once per minute.

## Take ownership

Scheduled pipelines execute with the permissions of the user
who owns the schedule. The pipeline has access to the same resources as the pipeline owner,
including [protected environments](../environments/protected_environments.md) and the
[CI/CD job token](../jobs/ci_job_token.md).

To take ownership of a pipeline created by a different user:

1. On the top bar, select **Menu > Projects** and find your project.
1. On the left sidebar, select **CI/CD > Schedules**.
1. On the right of the list, for
   the pipeline you want to become owner of, select **Take ownership**.

## Related topics

- Pipeline schedules can be maintained by using the [Pipeline schedules API](../../api/pipeline_schedules.md).
- You can [control which jobs are added to scheduled pipelines](../jobs/job_control.md#run-jobs-for-scheduled-pipelines).

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
