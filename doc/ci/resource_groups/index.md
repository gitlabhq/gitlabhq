---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Control the job concurrency in GitLab CI/CD
---

# Resource group **(FREE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/15536) in GitLab 12.7.

By default, pipelines in GitLab CI/CD run in parallel. The parallelization is an important factor to improve
the feedback loop in merge requests, however, there are some situations that
you may want to limit the concurrency on deployment
jobs to run them one by one.
Use resource groups to strategically control
the concurrency of the jobs for optimizing your continuous deployments workflow with safety.

## Add a resource group

Provided that you have the following pipeline configuration (`.gitlab-ci.yml` file in your repository):

```yaml
build:
  stage: build
  script: echo "Your build script"

deploy:
  stage: deploy
  script: echo "Your deployment script"
  environment: production
```

Every time you push a new commit to a branch, it runs a new pipeline that has
two jobs `build` and `deploy`. But if you push multiple commits in a short interval, multiple
pipelines start running simultaneously, for example:

- The first pipeline runs the jobs `build` -> `deploy`
- The second pipeline runs the jobs `build` -> `deploy`

In this case, the `deploy` jobs across different pipelines could run concurrently
to the `production` environment. Running multiple deployment scripts to the same
infrastructure could harm/confuse the instance and leave it in a corrupted state in the worst case.

To ensure that a `deploy` job runs once at a time, you can specify
[`resource_group` keyword](../yaml/index.md#resource_group) to the concurrency sensitive job:

```yaml
deploy:
  ...
  resource_group: production
```

With this configuration, the safety on the deployments is assured while you
can still run `build` jobs concurrently for maximizing the pipeline efficiency.

## Requirements

- The basic knowledge of the [GitLab CI/CD pipelines](../pipelines/index.md)
- The basic knowledge of the [GitLab Environments and Deployments](../environments/index.md)
- At least the Developer role for the project to configure CI/CD pipelines.

### Limitations

Only one resource can be attached to a resource group.

## Process modes

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/202186) in GitLab 14.3.
> - [Feature flag `ci_resource_group_process_modes`](https://gitlab.com/gitlab-org/gitlab/-/issues/340380) removed in GitLab 14.4.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/202186) in GitLab 14.4.

You can choose a process mode to strategically control the job concurrency for your deployment preferences.
The following modes are supported:

- **Unordered:** This is the default process mode that limits the concurrency on running jobs.
  It's the easiest option to use when you don't care about the execution order
  of the jobs. It starts processing the jobs whenever a job ready to run.
- **Oldest first:** This process mode limits the concurrency of the jobs. When a resource is free,
  it picks the first job from the list of upcoming jobs (`created`, `scheduled`, or `waiting_for_resource` state)
  that are sorted by pipeline ID in ascending order.

  This mode is efficient when you want to ensure that the jobs are executed from the oldest pipeline.
  It is less efficient compared to the `unordered` mode in terms of the pipeline efficiency,
  but safer for continuous deployments.

- **Newest first:** This process mode limits the concurrency of the jobs. When a resource is free,
  it picks the first job from the list of upcoming jobs (`created`, `scheduled` or `waiting_for_resource` state)
  that are sorted by pipeline ID in descending order.

  This mode is efficient when you want to ensure that the jobs are executed from the newest pipeline and
  prevent all of the old deploy jobs with the [prevent outdated deployment jobs](../environments/deployment_safety.md#prevent-outdated-deployment-jobs) feature.
  This is the most efficient option in terms of the pipeline efficiency, but you must ensure that each deployment job is idempotent.

### Change the process mode

To change the process mode of a resource group, you must use the API and
send a request to [edit an existing resource group](../../api/resource_groups.md#edit-an-existing-resource-group)
by specifying the `process_mode`:

- `unordered`
- `oldest_first`
- `newest_first`

### An example of difference between the process modes

Consider the following `.gitlab-ci.yml`, where we have two jobs `build` and `deploy`
each running in their own stage, and the `deploy` job has a resource group set to
`production`:

```yaml
build:
  stage: build
  script: echo "Your build script"

deploy:
  stage: deploy
  script: echo "Your deployment script"
  environment: production
  resource_group: production
```

If three commits are pushed to the project in a short interval, that means that three
pipelines run almost at the same time:

- The first pipeline runs the jobs `build` -> `deploy`. Let's call this deployment job `deploy-1`.
- The second pipeline runs the jobs `build` -> `deploy`. Let's call this deployment job `deploy-2`.
- The third pipeline runs the jobs `build` -> `deploy`. Let's call this deployment job `deploy-3`.

Depending on the process mode of the resource group:

- If the process mode is set to `unordered`:
  - `deploy-1`, `deploy-2`, and `deploy-3` do not run in parallel.
  - There is no guarantee on the job execution order, for example, `deploy-1` could run before or after `deploy-3` runs.
- If the process mode is `oldest_first`:
  - `deploy-1`, `deploy-2`, and `deploy-3` do not run in parallel.
  - `deploy-1` runs first, `deploy-2` runs second, and `deploy-3` runs last.
- If the process mode is `newest_first`:
  - `deploy-1`, `deploy-2`, and `deploy-3` do not run in parallel.
  - `deploy-3` runs first, `deploy-2` runs second and `deploy-1` runs last.

## Pipeline-level concurrency control with cross-project/parent-child pipelines

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/39057) in GitLab 13.9.

You can define `resource_group` for downstream pipelines that are sensitive to concurrent
executions. The [`trigger` keyword](../yaml/index.md#trigger) can trigger downstream pipelines and the
[`resource_group` keyword](../yaml/index.md#resource_group) can co-exist with it. `resource_group` is efficient to control the
concurrency of deployment pipelines, while other jobs can continue to run concurrently.

The following example has two pipeline configurations in a project. When a pipeline starts running,
non-sensitive jobs are executed first and aren't affected by concurrent executions in other
pipelines. However, GitLab ensures that there are no other deployment pipelines running before
triggering a deployment (child) pipeline. If other deployment pipelines are running, GitLab waits
until those pipelines finish before running another one.

```yaml
# .gitlab-ci.yml (parent pipeline)

build:
  stage: build
  script: echo "Building..."

test:
  stage: test
  script: echo "Testing..."

deploy:
  stage: deploy
  trigger:
    include: deploy.gitlab-ci.yml
    strategy: depend
  resource_group: AWS-production
```

```yaml
# deploy.gitlab-ci.yml (child pipeline)

stages:
  - provision
  - deploy

provision:
  stage: provision
  script: echo "Provisioning..."

deployment:
  stage: deploy
  script: echo "Deploying..."
  environment: production
```

You must define [`strategy: depend`](../yaml/index.md#triggerstrategy)
with the `trigger` keyword. This ensures that the lock isn't released until the downstream pipeline
finishes.

## API

See the [API documentation](../../api/resource_groups.md).

## Related features

Read more how you can use GitLab for [safe deployments](../environments/deployment_safety.md).

## Troubleshooting

### Avoid dead locks in pipeline configurations

Because [`oldest_first` process mode](#process-modes) enforces the jobs to be executed in a pipeline order,
there is a case that it doesn't work well with the other CI features.

For example, when you run [a child pipeline](../pipelines/downstream_pipelines.md#parent-child-pipelines)
that requires the same resource group with the parent pipeline,
a dead lock could happen. Here is an example of a _bad_ setup:

```yaml
# BAD
test:
  stage: test
  trigger:
    include: child-pipeline-requires-production-resource-group.yml
    strategy: depend

deploy:
  stage: deploy
  script: echo
  resource_group: production
  environment: production
```

In a parent pipeline, it runs the `test` job that subsequently runs a child pipeline,
and the [`strategy: depend` option](../yaml/index.md#triggerstrategy) makes the `test` job wait until the child pipeline has finished.
The parent pipeline runs the `deploy` job in the next stage, that requires a resource from the `production` resource group.
If the process mode is `oldest_first`, it executes the jobs from the oldest pipelines, meaning the `deploy` job is executed next.

However, a child pipeline also requires a resource from the `production` resource group.
Because the child pipeline is newer than the parent pipeline, the child pipeline
waits until the `deploy` job is finished, something that never happens.

In this case, you should specify the `resource_group` keyword in the parent pipeline configuration instead:

```yaml
# GOOD
test:
  stage: test
  trigger:
    include: child-pipeline.yml
    strategy: depend
  resource_group: production # Specify the resource group in the parent pipeline

deploy:
  stage: deploy
  script: echo
  resource_group: production
  environment: production
```

### Jobs get stuck in "Waiting for resource"

Sometimes, a job hangs with the message `Waiting for resource: <resource_group>`. To resolve,
first check that the resource group is working correctly:

1. Go to the job details page.
1. Select **View job currently using resource**.
1. Check the job status:
   - If the status is `running` or `pending`, the feature is working correctly. Wait until the job finishes and releases the resource.
   - If the status is not `running` or `pending`, the feature might not be working correctly.
     [Open a new issue](https://gitlab.com/gitlab-org/gitlab/-/issues/new) with the following information:
     - The job ID.
     - The job status.
     - How often the problem occurs.
     - Steps to reproduce the problem.

You can also get job information from the GraphQL API. You should use the GraphQL API if you use pipeline-level concurrency control with cross-project/parent-child pipelines because the trigger jobs are not accessible from the UI.

To get job information from the GraphQL API:

1. Go to the pipeline details page.
1. Select the **Jobs** tab and find the ID of the stuck job.
1. Go to [GraphiQL explorer](../../api/graphql/index.md#graphiql).
1. Run the following query:

    ```graphql
    {
      project(fullPath: "<fullpath-to-your-project>") {
        name
        job(id: "gid://gitlab/Ci::Bridge/<job-id>") {
          name
          detailedStatus {
            action {
              path
              buttonTitle
            }
          }
        }
      }
    }
    ```

    The `job.detailedStatus.action.path` field contains the job ID using the resource.

1. Run the following query and check `job.status` field according to the criteria above. You can also visit the pipeline page from `pipeline.path` field.

    ```graphql
    {
      project(fullPath: "<fullpath-to-your-project>") {
        name
        job(id: "gid://gitlab/Ci::Bridge/<job-id-currently-using-the-resource>") {
          name
          status
          pipeline {
            path
          }
        }
      }
    }
    ```

    If the status is not `running` or `pending`, open a new issue.
