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

Use scheduled pipelines to run GitLab CI/CD [pipelines](_index.md) at regular intervals.

## Prerequisites

For a scheduled pipeline to run:

- The schedule owner must have the Developer role. For pipelines on protected branches,
  the schedule owner must be [allowed to merge](../../user/project/repository/branches/protected.md#protect-a-branch)
  to the branch.
- The `.gitlab-ci.yml` file must have valid syntax.

Otherwise, the pipeline is not created. No error message is displayed.

## Add a pipeline schedule

{{< history >}}

- **Inputs** option [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/525504) in GitLab 17.11.

{{< /history >}}

To add a pipeline schedule:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Build > Pipeline schedules**.
1. Select **New schedule** and fill in the form.
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

If the project already has the [maximum number of pipeline schedules](../../administration/instance_limits.md#number-of-pipeline-schedules),
you must delete unused schedules before you can add another.

## Edit a pipeline schedule

The owner of a pipeline schedule can edit it:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Build > Pipeline schedules**.
1. Next to the schedule, select **Edit** ({{< icon name="pencil" >}}) and fill in the form.

The user must have at least the Developer role for the project. If the user is
not the owner of the schedule, they must first [take ownership](#take-ownership)
of the schedule.

## Run manually

To trigger a pipeline schedule manually, so that it runs immediately instead of
the next scheduled time:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Build > Pipeline schedules**.
1. On the right of the list, for
   the pipeline you want to run, select **Run** ({{< icon name="play" >}}).

You can manually run scheduled pipelines once per minute.

When you run a scheduled pipeline manually, the pipeline runs with the
permissions of the user who triggered it, not the permissions of the schedule owner.

## Take ownership

Scheduled pipelines execute with the permissions of the user
who owns the schedule. The pipeline has access to the same resources as the pipeline owner,
including [protected environments](../environments/protected_environments.md) and the
[CI/CD job token](../jobs/ci_job_token.md).

To take ownership of a pipeline created by a different user:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Build > Pipeline schedules**.
1. On the right of the list, for
   the pipeline you want to become owner of, select **Take ownership**.

You need at least the Maintainer role to take ownership of a pipeline created by a different user.

## Related topics

- [Pipeline schedules API](../../api/pipeline_schedules.md)
- [Run jobs for scheduled pipelines](../jobs/job_rules.md#run-jobs-for-scheduled-pipelines)

## Troubleshooting

When working with pipeline schedules, you might encounter the following issues.

### Short refs are expanded to full refs

When you provide a short `ref` to the API, it is automatically expanded to a full `ref`.
This behavior is intended and ensures explicit resource identification.

The API accepts both short refs (such as `main`) and full refs (such as `refs/heads/main` or `refs/tags/main`).

### Ambiguous refs

In some cases, the API can't automatically expand a short `ref` to a full `ref`. This can happen when:

- You provide a short `ref` (such as `main`), but both a branch and a tag exist with that name.
- You provide a short `ref`, but no branch or tag with that name exists.

To resolve this issue, provide the full `ref` to ensure the correct resource is identified.

### View and optimize pipeline schedules

To prevent [excessive load](pipeline_efficiency.md) caused by too many pipelines starting simultaneously,
you can review and optimize your pipeline schedules.

To get an overview of all existing schedules and identify opportunities to distribute them more evenly:

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
   For example, you might see many schedules set to run at the start of each hour (`0 * * * *`).
1. Adjust the schedules to create a staggered [`cron` pattern](../../topics/cron/_index.md#cron-syntax), especially for large repositories.
   For example, instead of multiple schedules running at the start of each hour, distribute them throughout the hour (`5 * * * *`, `15 * * * *`, `25 * * * *`).

### Scheduled pipeline suddenly becomes inactive

If a scheduled pipeline status changes to `Inactive` unexpectedly, it might be because
the owner of the schedule was blocked or removed. [Take ownership](#take-ownership)
of the schedule to modify and activate it.
