---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Scheduled pipelines
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Create pipeline schedules to run pipelines at regular intervals based on cron patterns.
Use pipeline schedules for tasks that need to run on a time-based schedule rather than triggered by code changes.

Unlike pipelines triggered by commits or merge requests, scheduled pipelines run independently of code changes.
This makes them suitable for tasks that need to happen regardless of development activity,
such as keeping deployments current or running periodic maintenance.

## Create a pipeline schedule

{{< history >}}

- Inputs option [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/525504) in GitLab 17.11.

{{< /history >}}

When you create a pipeline schedule, you become the schedule owner.
The pipeline runs with your permissions and can access [protected environments](../environments/protected_environments.md)
and use the [CI/CD job token](../jobs/ci_job_token.md) based on your access level.

Prerequisites:

- You must have at least the Developer role for the project.
- For schedules that target [protected branches](../../user/project/repository/branches/protected.md#protect-a-branch),
  you must have merge permissions for the target branch.
- Your `.gitlab-ci.yml` file must have valid syntax. You can [validate your configuration](../yaml/lint.md) before scheduling.

To create a pipeline schedule:

1. On the left sidebar, select **Search or go to** and find your project. If you've [turned on the new navigation](../../user/interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Build** > **Pipeline schedules**.
1. Select **New schedule**.
1. Complete the fields.
   - **Interval Pattern**: Select one of the preconfigured intervals, or enter a custom
     interval in [cron notation](../../topics/cron/_index.md). You can use any cron value,
     but scheduled pipelines cannot run more frequently than the instance's
     [maximum scheduled pipeline frequency](../../administration/cicd/_index.md#change-maximum-scheduled-pipeline-frequency).
   - **Target branch or tag**: Select the branch or tag for the pipeline.
   - **Inputs**: Set values for any [inputs](../inputs/_index.md) defined in your pipeline's `spec:inputs` section.
     These input values are used every time the scheduled pipeline runs. A schedule can have a maximum of 20 inputs.
   - **Variables**: Add any number of [CI/CD variables](../variables/_index.md) to the schedule.
     These variables are available only when the scheduled pipeline runs,
     and not in any other pipeline run. Inputs are recommended for pipeline configuration instead of variables
     because they offer improved security and flexibility.

If the project has reached the [maximum number of pipeline schedules](../../administration/instance_limits.md#number-of-pipeline-schedules),
delete unused schedules before adding another.

## Edit a pipeline schedule

Prerequisites:

- You must be the schedule owner or take ownership of the schedule.
- You must have at least the Developer role for the project.
- For schedules that target [protected branches](../../user/project/repository/branches/protected.md#protect-a-branch),
  you must have merge permissions for the target branch.
- For schedules that run on [protected tags](../../user/project/protected_tags.md#configuring-protected-tags),
  you must be allowed to create protected tags.

To edit a pipeline schedule:

1. On the left sidebar, select **Search or go to** and find your project. If you've [turned on the new navigation](../../user/interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Build** > **Pipeline schedules**.
1. Next to the schedule, select **Edit** ({{< icon name="pencil" >}}).
1. Make your changes, then select **Save changes**.

## Run manually

You can manually run scheduled pipelines once per minute.
When you run a scheduled pipeline manually, it uses your permissions instead of the schedule owner's permissions.

To trigger a pipeline schedule immediately instead of waiting for the next scheduled time:

1. On the left sidebar, select **Search or go to** and find your project. If you've [turned on the new navigation](../../user/interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Build** > **Pipeline schedules**.
1. Next to the schedule, select **Run** ({{< icon name="play" >}}).

## Take ownership

If a pipeline schedule becomes inactive because the original owner is unavailable, you can take ownership.

Scheduled pipelines execute with the permissions of the user who owns the schedule.

Prerequisites:

- You must have at least the Maintainer role for the project.

To take ownership of a schedule:

1. On the left sidebar, select **Search or go to** and find your project. If you've [turned on the new navigation](../../user/interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Build** > **Pipeline schedules**.
1. Next to the schedule, select **Take ownership**.

## View your scheduled pipelines

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/558979) in GitLab 18.4.

{{< /history >}}

To view the active pipeline schedules that you own across all your projects:

1. On the left sidebar, select your avatar. If you've [turned on the new navigation](../../user/interface_redesign.md#turn-new-navigation-on-or-off), this button is in the upper-right corner.
1. Select **Edit profile**.
1. Select **Account**.
1. Scroll to **Scheduled pipelines you own**.

## Related topics

- [CI/CD pipelines](_index.md)
- [Run jobs for scheduled pipelines](../jobs/job_rules.md#run-jobs-for-scheduled-pipelines)
- [Pipeline schedules API](../../api/pipeline_schedules.md)
- [Pipeline efficiency](pipeline_efficiency.md#reduce-how-often-jobs-run)

## Troubleshooting

When working with pipeline schedules, you might encounter the following issues.

### Scheduled pipeline becomes inactive

If a scheduled pipeline status changes to `Inactive` unexpectedly,
the schedule owner might have been blocked or removed from the project.

Take ownership of the schedule to reactivate it.

### Distribute pipeline schedules to prevent system load

To prevent excessive load from too many pipelines starting simultaneously,
review and distribute your pipeline schedules:

1. Run this command to extract and format schedule data:

   ```shell
   outfile=/tmp/gitlab_ci_schedules.tsv
   sudo gitlab-psql --command "
    COPY (SELECT
        ci_pipeline_schedules.cron,
        projects.path   AS project,
        users.email
    FROM ci_pipeline_schedules
    JOIN projects ON projects.id = ci_pipeline_schedules.project_id
    JOIN users    ON users.id    = ci_pipeline_schedules.owner_id
    ) TO '$outfile' CSV HEADER DELIMITER E'\t' ;"
   sort  "$outfile" | uniq -c | sort -n
   ```

1. Review the output to identify popular `cron` patterns.
   For example, many schedules might run at the start of every hour (`0 * * * *`).
1. Adjust the schedules to create a staggered [`cron` pattern](../../topics/cron/_index.md#cron-syntax), especially for large repositories.
   For example, instead of multiple schedules running at the start of every hour,
   distribute them throughout the hour (`5 * * * *`, `15 * * * *`, `25 * * * *`).
