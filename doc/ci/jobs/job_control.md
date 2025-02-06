---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Control how jobs run
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Before a new pipeline starts, GitLab checks the pipeline configuration to determine
which jobs can run in that pipeline. You can configure jobs to run depending on
conditions like the value of variables or the pipeline type with [`rules`](job_rules.md).

## Create a job that must be run manually

You can require that a job doesn't run unless a user starts it. This is called a **manual job**.
You might want to use a manual job for something like deploying to production.

To specify a job as manual, add [`when: manual`](../yaml/_index.md#when) to the job
in the `.gitlab-ci.yml` file.

By default, manual jobs display as skipped when the pipeline starts.

You can use [protected branches](../../user/project/repository/branches/protected.md) to more strictly
[protect manual deployments](#protect-manual-jobs) from being run by unauthorized users.

### Types of manual jobs

Manual jobs can be either optional or blocking.

In optional manual jobs:

- [`allow_failure`](../yaml/_index.md#allow_failure) is `true`, which is the default
  setting for jobs that have `when: manual` defined outside of `rules`.
- The status does not contribute to the overall pipeline status. A pipeline can
  succeed even if all of its manual jobs fail.

In blocking manual jobs:

- `allow_failure` is `false`, which is the default setting for jobs that have `when: manual`
  defined inside [`rules`](../yaml/_index.md#rules).
- The pipeline stops at the stage where the job is defined. To let the pipeline
  continue running, [run the manual job](#run-a-manual-job).
- Merge requests in projects with [**Pipelines must succeed**](../../user/project/merge_requests/auto_merge.md#require-a-successful-pipeline-for-merge)
  enabled can't be merged with a blocked pipeline.
- The pipeline shows a status of **blocked**.

When using manual jobs in triggered pipelines with [`strategy: depend`](../yaml/_index.md#triggerstrategy),
the type of manual job can affect the trigger job's status while the pipeline runs.

### Run a manual job

To run a manual job, you must have permission to merge to the assigned branch:

1. Go to the pipeline, job, [environment](../environments/deployments.md#configure-manual-deployments),
   or deployment view.
1. Next to the manual job, select **Run** (**{play}**).

### Specify variables when running manual jobs

When running manual jobs you can supply additional job specific variables.

You can do this from the job page of the manual job you want to run with
additional variables. To access this page, select the **name** of the manual job in
the pipeline view, *not* **Run** (**{play}**).

Define CI/CD variables here when you want to alter the execution of a job that uses
[CI/CD variables](../variables/_index.md).

If you add a variable that is already defined in the CI/CD settings or `.gitlab-ci.yml` file,
the [variable is overridden](../variables/_index.md#use-pipeline-variables) with the new value.
Any variables overridden by using this process are [expanded](../variables/_index.md#prevent-cicd-variable-expansion)
and not [masked](../variables/_index.md#mask-a-cicd-variable).

![The run manual job page with fields for specifying CI/CD variables.](img/manual_job_variables_v13_10.png)

### Add a confirmation dialog for manual jobs

Use [`manual_confirmation`](../yaml/_index.md#manual_confirmation) with `when: manual` to add a confirmation dialog for manual jobs.
The confirmation dialog helps to prevent accidental deployments or deletions,
especially for sensitive jobs like those that deploy to production.

Users are prompted to confirm the action before the manual job runs, which provides an additional layer of safety and control.

### Protect manual jobs

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Use [protected environments](../environments/protected_environments.md)
to define a list of users authorized to run a manual job. You can authorize only
the users associated with a protected environment to trigger manual jobs, which can:

- More precisely limit who can deploy to an environment.
- Block a pipeline until an approved user "approves" it.

To protect a manual job:

1. Add an `environment` to the job. For example:

   ```yaml
   deploy_prod:
     stage: deploy
     script:
       - echo "Deploy to production server"
     environment:
       name: production
       url: https://example.com
     when: manual
     rules:
       - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
   ```

1. In the [protected environments settings](../environments/protected_environments.md#protecting-environments),
   select the environment (`production` in this example) and add the users, roles or groups
   that are authorized to trigger the manual job to the **Allowed to Deploy** list. Only those in
   this list can trigger this manual job, and GitLab administrators
   who are always able to use protected environments.

You can use protected environments with blocking manual jobs to have a list of users
allowed to approve later pipeline stages. Add `allow_failure: false` to the protected
manual job and the pipeline's next stages only run after the manual job is triggered
by authorized users.

## Run a job after a delay

Use [`when: delayed`](../yaml/_index.md#when) to execute scripts after a waiting period, or if you want to avoid
jobs immediately entering the `pending` state.

You can set the period with `start_in` keyword. The value of `start_in` is an elapsed time
in seconds, unless a unit is provided. The minimum is one second, and the maximum is one week.
Examples of valid values include:

- `'5'` (a value with no unit must be surrounded by single quotes)
- `5 seconds`
- `30 minutes`
- `1 day`
- `1 week`

When a stage includes a delayed job, the pipeline doesn't progress until the delayed job finishes.
You can use this keyword to insert delays between different stages.

The timer of a delayed job starts immediately after the previous stage completes.
Similar to other types of jobs, a delayed job's timer doesn't start unless the previous stage passes.

The following example creates a job named `timed rollout 10%` that is executed 30 minutes after the previous stage completes:

```yaml
timed rollout 10%:
  stage: deploy
  script: echo 'Rolling out 10% ...'
  when: delayed
  start_in: 30 minutes
  environment: production
```

To stop the active timer of a delayed job, select **Unschedule** (**{time-out}**).
This job can no longer be scheduled to run automatically. You can, however, execute the job manually.

To start a delayed job manually, select **Unschedule** (**{time-out}**) to stop the delay timer and then select **Run** (**{play}**).
Soon GitLab Runner starts the job.

## Parallelize large jobs

To split a large job into multiple smaller jobs that run in parallel, use the
[`parallel`](../yaml/_index.md#parallel) keyword in your `.gitlab-ci.yml` file.

Different languages and test suites have different methods to enable parallelization.
For example, use [Semaphore Test Boosters](https://github.com/renderedtext/test-boosters)
and RSpec to run Ruby tests in parallel:

```ruby
# Gemfile
source 'https://rubygems.org'

gem 'rspec'
gem 'semaphore_test_boosters'
```

```yaml
test:
  parallel: 3
  script:
    - bundle
    - bundle exec rspec_booster --job $CI_NODE_INDEX/$CI_NODE_TOTAL
```

You can then go to the **Jobs** tab of a new pipeline build and see your RSpec
job split into three separate jobs.

WARNING:
Test Boosters reports usage statistics to the author.

### Run a one-dimensional matrix of parallel jobs

To run a job multiple times in parallel in a single pipeline, but with different variable values for each instance of the job,
use the [`parallel:matrix`](../yaml/_index.md#parallelmatrix) keyword:

```yaml
deploystacks:
  stage: deploy
  script:
    - bin/deploy
  parallel:
    matrix:
      - PROVIDER: [aws, ovh, gcp, vultr]
  environment: production/$PROVIDER
```

### Run a matrix of parallel trigger jobs

You can run a [trigger](../yaml/_index.md#trigger) job multiple times in parallel in a single pipeline,
but with different variable values for each instance of the job.

```yaml
deploystacks:
  stage: deploy
  trigger:
    include: path/to/child-pipeline.yml
  parallel:
    matrix:
      - PROVIDER: aws
        STACK: [monitoring, app1]
      - PROVIDER: ovh
        STACK: [monitoring, backup]
      - PROVIDER: [gcp, vultr]
        STACK: [data]
```

This example generates 6 parallel `deploystacks` trigger jobs, each with different values
for `PROVIDER` and `STACK`, and they create 6 different child pipelines with those variables.

```plaintext
deploystacks: [aws, monitoring]
deploystacks: [aws, app1]
deploystacks: [ovh, monitoring]
deploystacks: [ovh, backup]
deploystacks: [gcp, data]
deploystacks: [vultr, data]
```

### Select different runner tags for each parallel matrix job

You can use variables defined in `parallel: matrix` with the [`tags`](../yaml/_index.md#tags)
keyword for dynamic runner selection:

```yaml
deploystacks:
  stage: deploy
  script:
    - bin/deploy
  parallel:
    matrix:
      - PROVIDER: aws
        STACK: [monitoring, app1]
      - PROVIDER: gcp
        STACK: [data]
  tags:
    - ${PROVIDER}-${STACK}
  environment: $PROVIDER/$STACK
```

### Fetch artifacts from a `parallel:matrix` job

You can fetch artifacts from a job created with [`parallel:matrix`](../yaml/_index.md#parallelmatrix)
by using the [`dependencies`](../yaml/_index.md#dependencies) keyword. Use the job name
as the value for `dependencies` as a string in the form:

```plaintext
<job_name> [<matrix argument 1>, <matrix argument 2>, ... <matrix argument N>]
```

For example, to fetch the artifacts from the job with a `RUBY_VERSION` of `2.7` and
a `PROVIDER` of `aws`:

```yaml
ruby:
  image: ruby:${RUBY_VERSION}
  parallel:
    matrix:
      - RUBY_VERSION: ["2.5", "2.6", "2.7", "3.0", "3.1"]
        PROVIDER: [aws, gcp]
  script: bundle install

deploy:
  image: ruby:2.7
  stage: deploy
  dependencies:
    - "ruby: [2.7, aws]"
  script: echo hello
  environment: production
```

Quotes around the `dependencies` entry are required.

## Specify a parallelized job using needs with multiple parallelized jobs

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/254821) in GitLab 16.3.

You can use variables defined in [`needs:parallel:matrix`](../yaml/_index.md#needsparallelmatrix) with multiple parallelized jobs.

For example:

```yaml
linux:build:
  stage: build
  script: echo "Building linux..."
  parallel:
    matrix:
      - PROVIDER: aws
        STACK:
          - monitoring
          - app1
          - app2

mac:build:
  stage: build
  script: echo "Building mac..."
  parallel:
    matrix:
      - PROVIDER: [gcp, vultr]
        STACK: [data, processing]

linux:rspec:
  stage: test
  needs:
    - job: linux:build
      parallel:
        matrix:
          - PROVIDER: aws
            STACK: app1
  script: echo "Running rspec on linux..."

mac:rspec:
  stage: test
  needs:
    - job: mac:build
      parallel:
        matrix:
          - PROVIDER: [gcp, vultr]
            STACK: [data]
  script: echo "Running rspec on mac..."

production:
  stage: deploy
  script: echo "Running production..."
  environment: production
```

This example generates several jobs. The parallel jobs each have different values
for `PROVIDER` and `STACK`.

- 3 parallel `linux:build` jobs:
  - `linux:build: [aws, monitoring]`
  - `linux:build: [aws, app1]`
  - `linux:build: [aws, app2]`
- 4 parallel `mac:build` jobs:
  - `mac:build: [gcp, data]`
  - `mac:build: [gcp, processing]`
  - `mac:build: [vultr, data]`
  - `mac:build: [vultr, processing]`
- A `linux:rspec` job.
- A `production` job.

The jobs have three paths of execution:

- Linux path: The `linux:rspec` job runs as soon as the `linux:build: [aws, app1]`
  job finishes, without waiting for `mac:build` to finish.
- macOS path: The `mac:rspec` job runs as soon as the `mac:build: [gcp, data]` and
  `mac:build: [vultr, data]` jobs finish, without waiting for `linux:build` to finish.
- The `production` job runs as soon as all previous jobs finish.
