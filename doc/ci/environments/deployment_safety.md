---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Deployment safety
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

[Deployment jobs](../jobs/_index.md#deployment-jobs) are a specific kind of CI/CD
job. They can be more sensitive than other jobs in a pipeline,
and might need to be treated with extra care. GitLab has several features
that help maintain deployment security and stability.

You can:

- Set appropriate roles to your project. See [Project members permissions](../../user/permissions.md#project-members-permissions)
  for the different user roles GitLab supports and the permissions of each.
- [Restrict write-access to a critical environment](#restrict-write-access-to-a-critical-environment)
- [Prevent deployments during deploy freeze windows](#prevent-deployments-during-deploy-freeze-windows)
- [Protect production secrets](#protect-production-secrets)
- [Separate project for deployments](#separate-project-for-deployments)

If you are using a continuous deployment workflow and want to ensure that concurrent deployments to the same environment do not happen, you should enable the following options:

- [Ensure only one deployment job runs at a time](#ensure-only-one-deployment-job-runs-at-a-time)
- [Prevent outdated deployment jobs](#prevent-outdated-deployment-jobs)

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an overview, see [How to secure your CD pipelines/workflow](https://www.youtube.com/watch?v=Mq3C1KveDc0).

## Restrict write access to a critical environment

By default, environments can be modified by any team member that has at least the
Developer role.
If you want to restrict write access to a critical environment (for example a `production` environment),
you can set up [protected environments](protected_environments.md).

## Ensure only one deployment job runs at a time

Pipeline jobs in GitLab CI/CD run in parallel, so it's possible that two deployment
jobs in two different pipelines attempt to deploy to the same environment at the same
time. This is not desired behavior as deployments should happen sequentially.

You can ensure only one deployment job runs at a time with the [`resource_group` keyword](../yaml/_index.md#resource_group) in your `.gitlab-ci.yml`.

For example:

```yaml
deploy:
 script: deploy-to-prod
 resource_group: prod
```

Example of a problematic pipeline flow **before** using the resource group:

1. `deploy` job in Pipeline-A starts running.
1. `deploy` job in Pipeline-B starts running. *This is a concurrent deployment that could cause an unexpected result.*
1. `deploy` job in Pipeline-A finished.
1. `deploy` job in Pipeline-B finished.

The improved pipeline flow **after** using the resource group:

1. `deploy` job in Pipeline-A starts running.
1. `deploy` job in Pipeline-B attempts to start, but waits for the first `deploy` job to finish.
1. `deploy` job in Pipeline-A finishes.
1. `deploy` job in Pipeline-B starts running.

For more information, see [Resource Group documentation](../resource_groups/_index.md).

## Prevent outdated deployment jobs

> - [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/363328) in GitLab 15.5 to prevent outdated job runs.

The effective execution order of pipeline jobs can vary from run to run, which
could cause undesired behavior. For example, a [deployment job](../jobs/_index.md#deployment-jobs)
in a newer pipeline could finish before a deployment job in an older pipeline.
This creates a race condition where the older deployment finishes later,
overwriting the "newer" deployment.

You can prevent older deployment jobs from running when a newer deployment
job is started by enabling the [Prevent outdated deployment jobs](../pipelines/settings.md#prevent-outdated-deployment-jobs) feature.

When an older deployment job starts, it fails and is labeled:

- `failed outdated deployment job` in the pipeline view.
- `The deployment job is older than the latest deployment, and therefore failed.`
  when viewing the completed job.

When an older deployment job is manual, the **Run** (**{play}**) button is disabled with a message
`This deployment job does not run automatically and must be started manually, but it's older than the latest deployment, and therefore can't run.`.

Job age is determined by the job start time, not the commit time, so a newer commit
can be prevented in some circumstances.

### Job retries for rollback deployments

> - Rollback via job retry [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/378359) in GitLab 15.6.
> - Job retries for rollback deployments checkbox [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/410427) in GitLab 16.3.

You might need to quickly roll back to a stable, outdated deployment.
By default, pipeline job retries for [deployment rollback](deployments.md#deployment-rollback) are enabled.

To disable pipeline retries, clear the **Allow job retries for rollback deployments** checkbox. You should disable pipeline retries in sensitive projects.

When a rollback is required, you must run a new pipeline with a previous commit.

### Example

Example of a problematic pipeline flow **before** enabling Prevent outdated deployment jobs:

1. Pipeline-A is created on the default branch.
1. Later, Pipeline-B is created on the default branch (with a newer commit SHA).
1. The `deploy` job in Pipeline-B finishes first, and deploys the newer code.
1. The `deploy` job in Pipeline-A finished later, and deploys the older code, **overwriting** the newer (latest) deployment.

The improved pipeline flow **after** enabling Prevent outdated deployment jobs:

1. Pipeline-A is created on the default branch.
1. Later, Pipeline-B is created on the default branch (with a newer SHA).
1. The `deploy` job in Pipeline-B finishes first, and deploys the newer code.
1. The `deploy` job in Pipeline-A fails, so that it doesn't overwrite the deployment from the newer pipeline.

## Prevent deployments during deploy freeze windows

If you want to prevent deployments for a particular period, for example during a planned
vacation period when most employees are out, you can set up a [Deploy Freeze](../../user/project/releases/_index.md#prevent-unintentional-releases-by-setting-a-deploy-freeze).
During a deploy freeze period, no deployment can be executed. This is helpful to
ensure that deployments do not happen unexpectedly.

The next configured deploy freeze is displayed at the top of the
[environment deployments list](_index.md#view-environments-and-deployments)
page.

## Protect production secrets

Production secrets are needed to deploy successfully. For example, when deploying to the cloud,
cloud providers require these secrets to connect to their services. In the project settings, you can
define and protect CI/CD variables for these secrets. [Protected variables](../variables/_index.md#protect-a-cicd-variable)
are only passed to pipelines running on [protected branches](../../user/project/repository/branches/protected.md)
or [protected tags](../../user/project/protected_tags.md).
The other pipelines don't get the protected variable. You can also
[scope variables to specific environments](../variables/where_variables_can_be_used.md#variables-with-an-environment-scope).
We recommend that you use protected variables on protected environments to make sure that the
secrets aren't exposed unintentionally. You can also define production secrets on the
[runner side](../runners/configure_runners.md#prevent-runners-from-revealing-sensitive-information).
This prevents other users with the Maintainer role from reading the secrets and makes sure
that the runner only runs on protected branches.

For more information, see [pipeline security](../pipelines/_index.md#pipeline-security-on-protected-branches).

## Separate project for deployments

All users with the Maintainer role for the project have access to production secrets. If you need to limit the number of users
that can deploy to a production environment, you can create a separate project and configure a new
permission model that isolates the CD permissions from the original project and prevents the
original users with the Maintainer role for the project from accessing the production secret and CD configuration. You can
connect the CD project to your development projects by using [multi-project pipelines](../pipelines/downstream_pipelines.md#multi-project-pipelines).

## Protect `.gitlab-ci.yml` from change

A `.gitlab-ci.yml` may contain rules to deploy an application to the production server. This
deployment usually runs automatically after pushing a merge request. To prevent developers from
changing the `.gitlab-ci.yml`, you can define it in a different repository. The configuration can
reference a file in another project with a completely different set of permissions (similar to
[separating a project for deployments](#separate-project-for-deployments)).
In this scenario, the `.gitlab-ci.yml` is publicly accessible, but can only be edited by users with
appropriate permissions in the other project.

For more information, see [Custom CI/CD configuration path](../pipelines/settings.md#specify-a-custom-cicd-configuration-file).

## Require an approval before deploying

Before promoting a deployment to a production environment, cross-verifying it with a dedicated testing group is an effective way to ensure safety. For more information, see [Deployment Approvals](deployment_approvals.md).
