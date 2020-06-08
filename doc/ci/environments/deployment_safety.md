# Deployment safety

Deployment jobs can be more sensitive than other jobs in a pipeline,
and might need to be treated with extra care. GitLab has several features
that help maintain deployment security and stability.

You can:

- [Restrict write-access to a critical environment](#restrict-write-access-to-a-critical-environment)
- [Restrict deployments for a particular period](#restrict-deployments-for-a-particular-period)

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

You can ensure only one deployment job runs at a time with the [`resource_group` keyword](../yaml/README.md#resource_group) keyword in your `.gitlab-ci.yml`.

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

For more information, see [`resource_group` keyword in `.gitlab-ci.yml`](../yaml/README.md#resource_group).

## Skip outdated deployment jobs

The execution order of pipeline jobs can vary from run to run, which could cause
undesired behavior. For example, a deployment job in a newer pipeline could
finish before a deployment job in an older pipeline.
This creates a race condition where the older deployment finished later,
overwriting the "newer" deployment.

You can ensure that older deployment jobs are cancelled automatically when a newer deployment
runs by enabling the [Skip outdated deployment jobs](../pipelines/settings.md#skip-outdated-deployment-jobs) feature.

Example of a problematic pipeline flow **before** enabling Skip outdated deployment jobs:

1. Pipeline-A is created on the master branch.
1. Later, Pipeline-B is created on the master branch (with a newer commit SHA).
1. The `deploy` job in Pipeline-B finishes first, and deploys the newer code.
1. The `deploy` job in Pipeline-A finished later, and deploys the older code, **overwriting** the newer (latest) deployment.

The improved pipeline flow **after** enabling Skip outdated deployment jobs:

1. Pipeline-A is created on the `master` branch.
1. Later, Pipeline-B is created on the `master` branch (with a newer SHA).
1. The `deploy` job in Pipeline-B finishes first, and deploys the newer code.
1. The `deploy` job in Pipeline-A is automatically cancelled, so that it doesn't overwrite the deployment from the newer pipeline.

## Restrict deployments for a particular period

If you want to prevent deployments for a particular period, for example during a planned
vacation period when most employees are out, you can set up a [Deploy Freeze](../../user/project/releases/index.md#set-a-deploy-freeze).
During a deploy freeze period, no deployment can be executed. This is helpful to
ensure that deployments do not happen unexpectedly.

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

The [Skip outdated deployment jobs](../pipelines/settings.md#skip-outdated-deployment-jobs) might not work well with this configuration, and will need to be disabled.

There is a [plan to introduce a new annotation for environments](https://gitlab.com/gitlab-org/gitlab/-/issues/208655) to address this issue.
