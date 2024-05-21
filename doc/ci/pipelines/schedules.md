---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Scheduled pipelines

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

Use scheduled pipelines to run GitLab CI/CD [pipelines](index.md) at regular intervals.

## Prerequisites

For a scheduled pipeline to run:

- The schedule owner must have the Developer role. For pipelines on protected branches,
  the schedule owner must be [allowed to merge](../../user/project/protected_branches.md#add-protection-to-existing-branches)
  to the branch.
- The `.gitlab-ci.yml` file must have valid syntax.

Otherwise, the pipeline is not created. No error message is displayed.

## Add a pipeline schedule

To add a pipeline schedule:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Build > Pipeline schedules**.
1. Select **New schedule** and fill in the form.
   - **Interval Pattern**: Select one of the preconfigured intervals, or enter a custom
     interval in [cron notation](../../topics/cron/index.md). You can use any cron value,
     but scheduled pipelines cannot run more frequently than the instance's
     [maximum scheduled pipeline frequency](../../administration/cicd.md#change-maximum-scheduled-pipeline-frequency).
   - **Target branch or tag**: Select the branch or tag for the pipeline.
   - **Variables**: Add any number of [CI/CD variables](../variables/index.md) to the schedule.
     These variables are available only when the scheduled pipeline runs,
     and not in any other pipeline run.

If the project already has the [maximum number of pipeline schedules](../../administration/instance_limits.md#number-of-pipeline-schedules),
you must delete unused schedules before you can add another.

## Edit a pipeline schedule

The owner of a pipeline schedule can edit it:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Build > Pipeline schedules**.
1. Next to the schedule, select **Edit** (**{pencil}**) and fill in the form.

The user must have the Developer role or above for the project. If the user is
not the owner of the schedule, they must first [take ownership](#take-ownership)
of the schedule.

## Run manually

To trigger a pipeline schedule manually, so that it runs immediately instead of
the next scheduled time:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Build > Pipeline schedules**.
1. On the right of the list, for
   the pipeline you want to run, select **Run** (**{play}**).

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

### Short refs are expanded to Full refs

This behavior is normal and it introduced in order to enforce explicit resources.
The API still accepts both `short` (e.g. `main`) and `full` (e.g. `refs/heads/main` or `refs/tags/main`) refs and expands any `short`
ref provided, to a `full` ref.

### Ambiguous Refs

When a ref is being expanded, there can be cases where the full ref can't be automatically inferred.
Such cases can be:

- A `short` ref is provided (e.g. `main`) but **both** a branch and a tag exist with the provided `short` ref name
- A `short` ref is provided, but **neither** a branch or tag with the provided `short` ref name exist
