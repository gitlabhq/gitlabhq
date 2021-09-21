---
stage: Release
group: Release
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
description: Control the job concurrency in GitLab CI/CD
---

# Resource Group **(FREE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/15536) in GitLab 12.7.

By default, pipelines in GitLab CI/CD run in parallel. The parallelization is an important factor to improve
the feedback loop in merge requests, however, there are some situations that
you may want to limit the concurrency on deployment
jobs to run them one by one.
Resource Group allows you to strategically control
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

In order to ensure that a `deploy` job runs once at a time, you can specify
[`resource_group` keyword](../yaml/index.md#resource_group) to the concurrency sensitive job:

```yaml
deploy:
  ...
  resource_group: production
```

With this configuration, the safety on the deployments is assured while you
can still run `build` jobs concurrently for maximizing the pipeline efficency.

## Requirements

- The basic knowledge of the [GitLab CI/CD pipelines](../pipelines/index.md)
- The basic knowledge of the [GitLab Environments and Deployments](../environments/index.md)
- [Developer role](../../user/permissions.md) (or above) in the project to configure CI/CD pipelines.

### Limitations

Only one resource can be attached to a resource group.

## Process modes

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/202186) in GitLab 14.3.

FLAG:
On self-managed GitLab, by default this feature is not available.
To make it available, ask an administrator to [enable the `ci_resource_group_process_modes` flag](../../administration/feature_flags.md).
On GitLab.com, this feature is not available.
The feature is not ready for production use.

You can choose a process mode to strategically control the job concurrency for your deployment preferences.
The following modes are supported:

- **Unordered:** This is the default process mode that limits the concurrency on running jobs.
  It's the easiest option to use and useful when you don't care about the execution order
  of the jobs. It starts processing the jobs whenever a job ready to run.
- **Oldest first:** This process mode limits the concurrency of the jobs. When a resource is free,
  it picks the first job from the list of upcoming jobs (`created`, `scheduled`, or `waiting_for_resource` state)
  that are sorted by pipeline ID in ascending order.

  This mode is useful when you want to ensure that the jobs are executed from the oldest pipeline.
  This is less efficient compared to the `unordered` mode in terms of the pipeline efficiency,
  but safer for continuous deployments.

- **Newest first:** This process mode limits the concurrency of the jobs. When a resource is free,
  it picks the first job from the list of upcoming jobs (`created`, `scheduled` or `waiting_for_resource` state)
  that are sorted by pipeline ID in descending order.

  This mode is useful when you want to ensure that the jobs are executed from the newest pipeline and
  cancel all of the old deploy jobs with the [skip outdated deployment jobs](../environments/deployment_safety.md#skip-outdated-deployment-jobs) feature.
  This is the most efficient option in terms of the pipeline efficiency, but you must ensure that each deployment job is idempotent.

### Change the process mode

To change the process mode of a resource group, you need to use the API and
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

## Pipeline-level concurrency control with Cross-Project/Parent-Child pipelines

See the how to [control the pipeline concurrency in cross-project pipelines](../yaml/index.md#pipeline-level-concurrency-control-with-cross-projectparent-child-pipelines).

## API

See the [API documentation](../../api/resource_groups.md).

## Related features

Read more how you can use GitLab for [safe deployments](../environments/deployment_safety.md).

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
