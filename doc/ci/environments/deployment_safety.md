---
stage: Release
group: Release
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Deployment safety

Deployment jobs can be more sensitive than other jobs in a pipeline,
and might need to be treated with extra care. GitLab has several features
that help maintain deployment security and stability.

You can:

- [Restrict write-access to a critical environment](#restrict-write-access-to-a-critical-environment)
- [Prevent deployments during deploy freeze windows](#prevent-deployments-during-deploy-freeze-windows)
- [Set appropriate roles to your project](#setting-appropriate-roles-to-your-project)
- [Protect production secrets](#protect-production-secrets)
- [Separate project for deployments](#separate-project-for-deployments)

If you are using a continuous deployment workflow and want to ensure that concurrent deployments to the same environment do not happen, you should enable the following options:

- [Ensure only one deployment job runs at a time](#ensure-only-one-deployment-job-runs-at-a-time)
- [Skip outdated deployment jobs](#skip-outdated-deployment-jobs)

## Restrict write access to a critical environment

By default, environments can be modified by any team member that has [Developer permission or higher](../../user/permissions.md#project-members-permissions).
If you want to restrict write access to a critical environment (for example a `production` environment),
you can set up [protected environments](protected_environments.md).

## Ensure only one deployment job runs at a time

Pipeline jobs in GitLab CI/CD run in parallel, so it's possible that two deployment
jobs in two different pipelines attempt to deploy to the same environment at the same
time. This is not desired behavior as deployments should happen sequentially.

You can ensure only one deployment job runs at a time with the [`resource_group` keyword](../yaml/index.md#resource_group) in your `.gitlab-ci.yml`.

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

For more information, see [`resource_group` keyword in `.gitlab-ci.yml`](../yaml/index.md#resource_group).

## Skip outdated deployment jobs

The execution order of pipeline jobs can vary from run to run, which could cause
undesired behavior. For example, a deployment job in a newer pipeline could
finish before a deployment job in an older pipeline.
This creates a race condition where the older deployment finished later,
overwriting the "newer" deployment.

You can ensure that older deployment jobs are cancelled automatically when a newer deployment
runs by enabling the [Skip outdated deployment jobs](../pipelines/settings.md#skip-outdated-deployment-jobs) feature.

Example of a problematic pipeline flow **before** enabling Skip outdated deployment jobs:

1. Pipeline-A is created on the default branch.
1. Later, Pipeline-B is created on the default branch (with a newer commit SHA).
1. The `deploy` job in Pipeline-B finishes first, and deploys the newer code.
1. The `deploy` job in Pipeline-A finished later, and deploys the older code, **overwriting** the newer (latest) deployment.

The improved pipeline flow **after** enabling Skip outdated deployment jobs:

1. Pipeline-A is created on the default branch.
1. Later, Pipeline-B is created on the default branch (with a newer SHA).
1. The `deploy` job in Pipeline-B finishes first, and deploys the newer code.
1. The `deploy` job in Pipeline-A is automatically cancelled, so that it doesn't overwrite the deployment from the newer pipeline.

## Prevent deployments during deploy freeze windows

If you want to prevent deployments for a particular period, for example during a planned
vacation period when most employees are out, you can set up a [Deploy Freeze](../../user/project/releases/index.md#prevent-unintentional-releases-by-setting-a-deploy-freeze).
During a deploy freeze period, no deployment can be executed. This is helpful to
ensure that deployments do not happen unexpectedly.
  
## Setting appropriate roles to your project

GitLab supports several different roles that can be assigned to your project members. See
[Project members permissions](../../user/permissions.md#project-members-permissions)
for an explanation of these roles and the permissions of each.

<div class="video-fallback">
  See the video: <a href="https://www.youtube.com/watch?v=Mq3C1KveDc0">How to secure your CD pipelines</a>.
</div>
<figure class="video-container">
  <iframe src="https://www.youtube.com/embed/Mq3C1KveDc0" frameborder="0" allowfullscreen="true"> </iframe>
</figure>

## Protect production secrets

Production secrets are needed to deploy successfully. For example, when deploying to the cloud,
cloud providers require these secrets to connect to their services. In the project settings, you can
define and protect CI/CD variables for these secrets. [Protected variables](../variables/index.md#protect-a-cicd-variable)
are only passed to pipelines running on [protected branches](../../user/project/protected_branches.md)
or [protected tags](../../user/project/protected_tags.md).
The other pipelines don't get the protected variable. You can also
[scope variables to specific environments](../variables/where_variables_can_be_used.md#variables-with-an-environment-scope).
We recommend that you use protected variables on protected environments to make sure that the
secrets aren't exposed unintentionally. You can also define production secrets on the
[runner side](../runners/configure_runners.md#prevent-runners-from-revealing-sensitive-information).
This prevents other maintainers from reading the secrets and makes sure that the runner only runs on
protected branches.

For more information, see [pipeline security](../pipelines/index.md#pipeline-security-on-protected-branches).

## Separate project for deployments

All project maintainers have access to production secrets. If you need to limit the number of users
that can deploy to a production environment, you can create a separate project and configure a new
permission model that isolates the CD permissions from the original project and prevents the
original project's maintainers from accessing the production secret and CD configuration. You can
connect the CD project to your development projects by using [multi-project pipelines](../pipelines/multi_project_pipelines.md).

## Protect `gitlab-ci.yml` from change

A `.gitlab-ci.yml` may contain rules to deploy an application to the production server. This
deployment usually runs automatically after pushing a merge request. To prevent developers from
changing the `gitlab-ci.yml`, you can define it in a different repository. The configuration can
reference a file in another project with a completely different set of permissions (similar to
[separating a project for deployments](#separate-project-for-deployments)).
In this scenario, the `gitlab-ci.yml` is publicly accessible, but can only be edited by users with
appropriate permissions in the other project.

For more information, see [Custom CI/CD configuration path](../pipelines/settings.md#custom-cicd-configuration-file).

## Troubleshooting

### Pipelines jobs fail with `The deployment job is older than the previously succeeded deployment job...`

This is caused by the [Skip outdated deployment jobs](../pipelines/settings.md#skip-outdated-deployment-jobs) feature.
If you have multiple jobs for the same environment (including non-deployment jobs), you might encounter this problem, for example:

```yaml
build:service-a:
 environment:
   name: production

build:service-b:
 environment:
   name: production
```

The [Skip outdated deployment jobs](../pipelines/settings.md#skip-outdated-deployment-jobs) might
not work well with this configuration, and must be disabled.
