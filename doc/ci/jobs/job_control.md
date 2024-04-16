---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Choose when to run jobs

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

When a new pipeline starts, GitLab checks the pipeline configuration to determine
which jobs should run in that pipeline. You can configure jobs to run depending on
factors like the status of variables, or the pipeline type.

To configure a job to be included or excluded from certain pipelines, use [`rules`](../yaml/index.md#rules).

Use [`needs`](../yaml/index.md#needs) to configure a job to run as soon as the
earlier jobs it depends on finish running.

## Specify when jobs run with `rules`

Use [`rules`](../yaml/index.md#rules) to include or exclude jobs in pipelines.

Rules are evaluated in order until the first match. When a match is found, the job
is either included or excluded from the pipeline, depending on the configuration.
See the [`rules`](../yaml/index.md#rules) reference for more details.

Future keyword improvements are being discussed in our [epic for improving `rules`](https://gitlab.com/groups/gitlab-org/-/epics/2783),
where anyone can add suggestions or requests.

### `rules` examples

The following example uses `if` to define that the job runs in only two specific cases:

```yaml
job:
  script: echo "Hello, Rules!"
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
      when: manual
      allow_failure: true
    - if: $CI_PIPELINE_SOURCE == "schedule"
```

- If the pipeline is for a merge request, the first rule matches, and the job
  is added to the [merge request pipeline](../pipelines/merge_request_pipelines.md)
  with attributes of:
  - `when: manual` (manual job)
  - `allow_failure: true` (the pipeline continues running even if the manual job is not run)
- If the pipeline is **not** for a merge request, the first rule doesn't match, and the
  second rule is evaluated.
- If the pipeline is a scheduled pipeline, the second rule matches, and the job
  is added to the scheduled pipeline. No attributes were defined, so it is added
  with:
  - `when: on_success` (default)
  - `allow_failure: false` (default)
- In **all other cases**, no rules match, so the job is **not** added to any other pipeline.

Alternatively, you can define a set of rules to exclude jobs in a few cases, but
run them in all other cases:

```yaml
job:
  script: echo "Hello, Rules!"
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
      when: never
    - if: $CI_PIPELINE_SOURCE == "schedule"
      when: never
    - when: on_success
```

- If the pipeline is for a merge request, the job is **not** added to the pipeline.
- If the pipeline is a scheduled pipeline, the job is **not** added to the pipeline.
- In **all other cases**, the job is added to the pipeline, with `when: on_success`.

WARNING:
If you use a `when` clause as the final rule (not including `when: never`), two
simultaneous pipelines may start. Both push pipelines and merge request pipelines can
be triggered by the same event (a push to the source branch for an open merge request).
See how to [prevent duplicate pipelines](#avoid-duplicate-pipelines)
for more details.

#### Run jobs for scheduled pipelines

To configure a job to be executed only when the pipeline has been
scheduled, use the [`rules`](../yaml/index.md#rules) keyword.

In this example, `make world` runs in scheduled pipelines, and `make build`
runs in branch and tag pipelines:

```yaml
job:on-schedule:
  rules:
    - if: $CI_PIPELINE_SOURCE == "schedule"
  script:
    - make world

job:
  rules:
    - if: $CI_PIPELINE_SOURCE == "push"
  script:
    - make build
```

#### Skip job if the branch is empty

Use [`rules:changes:compare_to`](../yaml/index.md#ruleschangescompare_to) to avoid
running a job when the branch is empty, which saves CI/CD resources. Compare the
branch to the default branch, and if the branch:

- Doesn't have changed files, the job doesn't run.
- Has changed files, the job runs.

For example, in a project with `main` as the default branch:

```yaml
job:
  script:
    - echo "This job only runs for branches that are not empty"
  rules:
    - if: $CI_COMMIT_BRANCH
      changes:
        compare_to: 'refs/heads/main'
        paths:
          - '**/*'
```

The rule for this job compares all files and paths in the current branch
recursively (`**/*`) against the `main` branch. The rule matches and the
job runs only when there are changes to the files in the branch.

### Complex rules

You can use all `rules` keywords, like `if`, `changes`, and `exists`, in the same
rule. The rule evaluates to true only when all included keywords evaluate to true.

For example:

```yaml
docker build:
  script: docker build -t my-image:$CI_COMMIT_REF_SLUG .
  rules:
    - if: $VAR == "string value"
      changes:  # Include the job and set to when:manual if any of the follow paths match a modified file.
        - Dockerfile
        - docker/scripts/**/*
      when: manual
      allow_failure: true
```

If the `Dockerfile` file or any file in `/docker/scripts` has changed **and** `$VAR` == "string value",
then the job runs manually and is allowed to fail.

You can use [parentheses](#group-variable-expressions-together-with-parentheses) with `&&` and `||` to build more complicated variable expressions.

```yaml
job1:
  script:
    - echo This rule uses parentheses.
  rules:
    - if: ($CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH || $CI_COMMIT_BRANCH == "develop") && $MY_VARIABLE
```

### Avoid duplicate pipelines

If a job uses `rules`, a single action, like pushing a commit to a branch, can trigger
multiple pipelines. You don't have to explicitly configure rules for multiple types
of pipeline to trigger them accidentally.

Some configurations that have the potential to cause duplicate pipelines cause a
[pipeline warning](../debugging.md#pipeline-warnings) to be displayed.

For example:

```yaml
job:
  script: echo "This job creates double pipelines!"
  rules:
    - if: $CUSTOM_VARIABLE == "false"
      when: never
    - when: always
```

This job does not run when `$CUSTOM_VARIABLE` is false, but it *does* run in **all**
other pipelines, including **both** push (branch) and merge request pipelines. With
this configuration, every push to an open merge request's source branch
causes duplicated pipelines.

To avoid duplicate pipelines, you can:

- Use [`workflow`](../yaml/index.md#workflow) to specify which types of pipelines
  can run.
- Rewrite the rules to run the job only in very specific cases,
  and avoid a final `when` rule:

  ```yaml
  job:
    script: echo "This job does NOT create double pipelines!"
    rules:
      - if: $CUSTOM_VARIABLE == "true" && $CI_PIPELINE_SOURCE == "merge_request_event"
  ```

You can also avoid duplicate pipelines by changing the job rules to avoid either push (branch)
pipelines or merge request pipelines. However, if you use a `- when: always` rule without
`workflow: rules`, GitLab still displays a [pipeline warning](../debugging.md#pipeline-warnings).

For example, the following does not trigger double pipelines, but is not recommended
without `workflow: rules`:

```yaml
job:
  script: echo "This job does NOT create double pipelines!"
  rules:
    - if: $CI_PIPELINE_SOURCE == "push"
      when: never
    - when: always
```

You should not include both push and merge request pipelines in the same job without
[`workflow:rules` that prevent duplicate pipelines](../yaml/workflow.md#switch-between-branch-pipelines-and-merge-request-pipelines):

```yaml
job:
  script: echo "This job creates double pipelines!"
  rules:
    - if: $CI_PIPELINE_SOURCE == "push"
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
```

Also, do not mix `only/except` jobs with `rules` jobs in the same pipeline.
It may not cause YAML errors, but the different default behaviors of `only/except`
and `rules` can cause issues that are difficult to troubleshoot:

```yaml
job-with-no-rules:
  script: echo "This job runs in branch pipelines."

job-with-rules:
  script: echo "This job runs in merge request pipelines."
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
```

For every change pushed to the branch, duplicate pipelines run. One
branch pipeline runs a single job (`job-with-no-rules`), and one merge request pipeline
runs the other job (`job-with-rules`). Jobs with no rules default
to [`except: merge_requests`](../yaml/index.md#only--except), so `job-with-no-rules`
runs in all cases except merge requests.

### Common `if` clauses for `rules`

For behavior similar to the [`only`/`except` keywords](../yaml/index.md#only--except), you can
check the value of the `$CI_PIPELINE_SOURCE` variable:

| Value                         | Description |
|-------------------------------|-------------|
| `api`                         | For pipelines triggered by the [pipelines API](../../api/pipelines.md#create-a-new-pipeline). |
| `chat`                        | For pipelines created by using a [GitLab ChatOps](../chatops/index.md) command. |
| `external`                    | When you use CI services other than GitLab. |
| `external_pull_request_event` | When an external pull request on GitHub is created or updated. See [Pipelines for external pull requests](../ci_cd_for_external_repos/index.md#pipelines-for-external-pull-requests). |
| `merge_request_event`         | For pipelines created when a merge request is created or updated. Required to enable [merge request pipelines](../pipelines/merge_request_pipelines.md), [merged results pipelines](../pipelines/merged_results_pipelines.md), and [merge trains](../pipelines/merge_trains.md). |
| `parent_pipeline`             | For pipelines triggered by a [parent/child pipeline](../pipelines/downstream_pipelines.md#parent-child-pipelines) with `rules`. Use this pipeline source in the child pipeline configuration so that it can be triggered by the parent pipeline. |
| `pipeline`                    | For [multi-project pipelines](../pipelines/downstream_pipelines.md#multi-project-pipelines) created by [using the API with `CI_JOB_TOKEN`](../pipelines/downstream_pipelines.md#trigger-a-multi-project-pipeline-by-using-the-api), or the [`trigger`](../yaml/index.md#trigger) keyword. |
| `push`                        | For pipelines triggered by a `git push` event, including for branches and tags. |
| `schedule`                    | For [scheduled pipelines](../pipelines/schedules.md). |
| `trigger`                     | For pipelines created by using a [trigger token](../triggers/index.md#configure-cicd-jobs-to-run-in-triggered-pipelines). |
| `web`                         | For pipelines created by selecting **Run pipeline** in the GitLab UI, from the project's **Build > Pipelines** section. |
| `webide`                      | For pipelines created by using the [WebIDE](../../user/project/web_ide/index.md). |

The following example runs the job as a manual job in scheduled pipelines or in push
pipelines (to branches or tags), with `when: on_success` (default). It does not
add the job to any other pipeline type.

```yaml
job:
  script: echo "Hello, Rules!"
  rules:
    - if: $CI_PIPELINE_SOURCE == "schedule"
      when: manual
      allow_failure: true
    - if: $CI_PIPELINE_SOURCE == "push"
```

The following example runs the job as a `when: on_success` job in [merge request pipelines](../pipelines/merge_request_pipelines.md)
and scheduled pipelines. It does not run in any other pipeline type.

```yaml
job:
  script: echo "Hello, Rules!"
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
    - if: $CI_PIPELINE_SOURCE == "schedule"
```

Other commonly used variables for `if` clauses:

- `if: $CI_COMMIT_TAG`: If changes are pushed for a tag.
- `if: $CI_COMMIT_BRANCH`: If changes are pushed to any branch.
- `if: $CI_COMMIT_BRANCH == "main"`: If changes are pushed to `main`.
- `if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH`: If changes are pushed to the default
  branch. Use when you want to have the same configuration in multiple
  projects with different default branches.
- `if: $CI_COMMIT_BRANCH =~ /regex-expression/`: If the commit branch matches a regular expression.
- `if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH && $CI_COMMIT_TITLE =~ /Merge branch.*/`:
  If the commit branch is the default branch and the commit message title matches a regular expression.
  For example, the default commit message for a merge commit starts with `Merge branch`.
- `if: $CUSTOM_VARIABLE !~ /regex-expression/`: If the [custom variable](../variables/index.md)
  `CUSTOM_VARIABLE` does **not** match a regular expression.
- `if: $CUSTOM_VARIABLE == "value1"`: If the custom variable `CUSTOM_VARIABLE` is
  exactly `value1`.

### Variables in `rules:changes`

You can use CI/CD variables in `rules:changes` expressions to determine when
to add jobs to a pipeline:

```yaml
docker build:
  variables:
    DOCKERFILES_DIR: 'path/to/files'
  script: docker build -t my-image:$CI_COMMIT_REF_SLUG .
  rules:
    - changes:
      - $DOCKERFILES_DIR/**/*
```

You can use the `$` character for both variables and paths. For example, if the
`$DOCKERFILES_DIR` variable exists, its value is used. If it does not exist, the
`$` is interpreted as being part of a path.

### Reuse rules in different jobs

Use [`!reference` tags](../yaml/yaml_optimization.md#reference-tags) to reuse rules in different
jobs. You can combine `!reference` rules with regular job-defined rules:

```yaml
.default_rules:
  rules:
    - if: $CI_PIPELINE_SOURCE == "schedule"
      when: never
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH

job1:
  rules:
    - !reference [.default_rules, rules]
  script:
    - echo "This job runs for the default branch, but not schedules."

job2:
  rules:
    - !reference [.default_rules, rules]
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
  script:
    - echo "This job runs for the default branch, but not schedules."
    - echo "It also runs for merge requests."
```

## Create a job that must be run manually

You can require that a job doesn't run unless a user starts it. This is called a **manual job**.
You might want to use a manual job for something like deploying to production.

To specify a job as manual, add [`when: manual`](../yaml/index.md#when) to the job
in the `.gitlab-ci.yml` file.

By default, manual jobs display as skipped when the pipeline starts.

You can use [protected branches](../../user/project/protected_branches.md) to more strictly
[protect manual deployments](#protect-manual-jobs) from being run by unauthorized users.

### Types of manual jobs

Manual jobs can be either optional or blocking.

In optional manual jobs:

- [`allow_failure`](../yaml/index.md#allow_failure) is `true`, which is the default
  setting for jobs that have `when: manual` and no [`rules`](../yaml/index.md#rules),
  or `when: manual` defined outside of `rules`.
- The status does not contribute to the overall pipeline status. A pipeline can
  succeed even if all of its manual jobs fail.

In blocking manual jobs:

- `allow_failure` is `false`, which is the default setting for jobs that have `when: manual`
  defined inside [`rules`](../yaml/index.md#rules).
- The pipeline stops at the stage where the job is defined. To let the pipeline
  continue running, [run the manual job](#run-a-manual-job).
- Merge requests in projects with [**Pipelines must succeed**](../../user/project/merge_requests/merge_when_pipeline_succeeds.md#require-a-successful-pipeline-for-merge)
  enabled can't be merged with a blocked pipeline.
- The pipeline shows a status of **blocked**.

When using manual jobs in triggered pipelines with [`strategy: depend`](../yaml/index.md#triggerstrategy),
the type of manual job can affect the trigger job's status while the pipeline runs.

### Run a manual job

To run a manual job, you must have permission to merge to the assigned branch:

1. Go to the pipeline, job, [environment](../environments/index.md#configure-manual-deployments),
   or deployment view.
1. Next to the manual job, select **Play** (**{play}**).

You can also [add custom CI/CD variables when running a manual job](index.md#specifying-variables-when-running-manual-jobs).

### Protect manual jobs

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

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

Use [`when: delayed`](../yaml/index.md#when) to execute scripts after a waiting period, or if you want to avoid
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

To start a delayed job manually, select **Unschedule** (**{time-out}**) to stop the delay timer and then select **Play** (**{play}**).
Soon GitLab Runner starts the job.

## Parallelize large jobs

To split a large job into multiple smaller jobs that run in parallel, use the
[`parallel`](../yaml/index.md#parallel) keyword in your `.gitlab-ci.yml` file.

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

You can create a one-dimensional matrix of parallel jobs:

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

You can also [create a multi-dimensional matrix](../yaml/index.md#parallelmatrix).

### Run a matrix of parallel trigger jobs

You can run a [trigger](../yaml/index.md#trigger) job multiple times in parallel in a single pipeline,
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

You can use variables defined in `parallel: matrix` with the [`tags`](../yaml/index.md#tags)
keyword for dynamic runner selection:

```yaml
deploystacks:
  stage: deploy
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

#### Fetch artifacts from a `parallel:matrix` job

You can fetch artifacts from a job created with [`parallel:matrix`](../yaml/index.md#parallelmatrix)
by using the [`dependencies`](../yaml/index.md#dependencies) keyword. Use the job name
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

You can use variables defined in [`needs:parallel:matrix`](../yaml/index.md#needsparallelmatrix) with multiple parallelized jobs.

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

## Use predefined CI/CD variables to run jobs only in specific pipeline types

You can use [predefined CI/CD variables](../variables/predefined_variables.md) to choose
which pipeline types jobs run in, with:

- [`rules`](../yaml/index.md#rules)
- [`only:variables`](../yaml/index.md#onlyvariables--exceptvariables)
- [`except:variables`](../yaml/index.md#onlyvariables--exceptvariables)

The following table lists some of the variables that you can use, and the pipeline
types the variables can control for:

- Branch pipelines that run for Git `push` events to a branch, like new commits or tags.
- Tag pipelines that run only when a new Git tag is pushed to a branch.
- [Merge request pipelines](../pipelines/merge_request_pipelines.md) that run for changes
  to a merge request, like new commits or selecting **Run pipeline**
  in a merge request's pipelines tab.
- [Scheduled pipelines](../pipelines/schedules.md).

| Variables                                  | Branch | Tag | Merge request | Scheduled |
|--------------------------------------------|--------|-----|---------------|-----------|
| `CI_COMMIT_BRANCH`                         | Yes    |     |               | Yes       |
| `CI_COMMIT_TAG`                            |        | Yes |               | Yes, if the scheduled pipeline is configured to run on a tag. |
| `CI_PIPELINE_SOURCE = push`                | Yes    | Yes |               |           |
| `CI_PIPELINE_SOURCE = schedule`            |        |     |               | Yes       |
| `CI_PIPELINE_SOURCE = merge_request_event` |        |     | Yes           |           |
| `CI_MERGE_REQUEST_IID`                     |        |     | Yes           |           |

For example, to configure a job to run for merge request pipelines and scheduled pipelines,
but not branch or tag pipelines:

```yaml
job1:
  script:
    - echo
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
    - if: $CI_PIPELINE_SOURCE == "schedule"
    - if: $CI_PIPELINE_SOURCE == "push"
      when: never
```

## Regular expressions

The `@` symbol denotes the beginning of a ref's repository path.
To match a ref name that contains the `@` character in a regular expression,
you must use the hex character code match `\x40`.

Only the tag or branch name can be matched by a regular expression.
The repository path, if given, is always matched literally.

To match the tag or branch name,
the entire ref name part of the pattern must be a regular expression surrounded by `/`.
For example, you can't use `issue-/.*/` to match all tag names or branch names
that begin with `issue-`, but you can use `/issue-.*/`.

Regular expression flags must be appended after the closing `/`. Pattern matching
is case-sensitive by default. Use the `i` flag modifier, like `/pattern/i`, to make
a pattern case-insensitive:

```yaml
job:
  # use regexp
  only:
    - /^issue-.*$/i
  # use special keyword
  except:
    - branches
```

Use anchors `^` and `$` to avoid the regular expression
matching only a substring of the tag name or branch name.
For example, `/^issue-.*$/` is equivalent to `/^issue-/`,
while just `/issue/` would also match a branch called `severe-issues`.

## CI/CD variable expressions

Use variable expressions to control which jobs are created in a pipeline after changes
are pushed to GitLab. You can use variable expressions with:

- [`rules:if`](../yaml/index.md#rules).
- [`only:variables` and `except:variables`](../yaml/index.md#onlyvariables--exceptvariables).

For example, with `rules:if`:

```yaml
job1:
  variables:
    VAR1: "variable1"
  script:
    - echo "Test variable comparison
  rules:
    - if: $VAR1 == "variable1"
```

### Compare a variable to a string

You can use the equality operators `==` and `!=` to compare a variable with a
string. Both single quotes and double quotes are valid. The order doesn't matter,
so the variable can be first, or the string can be first. For example:

- `if: $VARIABLE == "some value"`
- `if: $VARIABLE != "some value"`
- `if: "some value" == $VARIABLE`

### Compare two variables

You can compare the values of two variables. For example:

- `if: $VARIABLE_1 == $VARIABLE_2`
- `if: $VARIABLE_1 != $VARIABLE_2`

### Check if a variable is undefined

You can compare a variable to the `null` keyword to see if it is defined. For example:

- `if: $VARIABLE == null`
- `if: $VARIABLE != null`

### Check if a variable is empty

You can check if a variable is defined but empty. For example:

- `if: $VARIABLE == ""`
- `if: $VARIABLE != ""`

### Check if a variable exists

You can check for the existence of a variable by using just the variable name in
the expression. The variable must not be empty. For example:

- `if: $VARIABLE`

### Compare a variable to a regex pattern

You can do regex pattern matching on variable values with the `=~` and `!~` operators.
Variable pattern matching with regular expressions uses the
[RE2 regular expression syntax](https://github.com/google/re2/wiki/Syntax).

Expressions evaluate as `true` if:

- Matches are found when using `=~`.
- Matches are *not* found when using `!~`.

For example:

- `if: $VARIABLE =~ /^content.*/`
- `if: $VARIABLE !~ /^content.*/`

Single-character regular expressions, like `/./`, are not supported and
produce an `invalid expression syntax` error.

Pattern matching is case-sensitive by default. Use the `i` flag modifier to make a
pattern case-insensitive. For example: `/pattern/i`.

NOTE:
When using the `=~` character, make sure the right side of the comparison always contains
a valid regular expression. If the right side of the comparison is not a valid regular expression
enclosed with `/` characters, the expression evaluates in an unexpected way. In that case,
the comparison checks if the left side is a substring of the right side. For example,
`"23" =~ "1234"` evaluates to true, which is the opposite of `"23" =~ /1234/`, which evaluates to false.
You should not configure your pipeline to rely on this behavior.

#### Store the regex pattern in a variable

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/35438) in GitLab 15.0 [with a flag](../../administration/feature_flags.md) named `ci_fix_rules_if_comparison_with_regexp_variable`, disabled by default.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/359740) and feature flag `ci_fix_rules_if_comparison_with_regexp_variable` removed in GitLab 15.1.

Variables on the right side of `=~` and `!~` expressions are evaluated as regular expressions.
The regular expression must be enclosed in forward slashes (`/`). For example:

```yaml
variables:
  pattern: '/^ab.*/'

regex-job1:
  variables:
    teststring: 'abcde'
  script: echo "This job will run, because 'abcde' matches the /^ab.*/ pattern."
  rules:
    - if: '$teststring =~ $pattern'

regex-job2:
  variables:
    teststring: 'fghij'
  script: echo "This job will not run, because 'fghi' does not match the /^ab.*/ pattern."
  rules:
    - if: '$teststring =~ $pattern'
```

### Join variable expressions together with `&&` or `||`

You can join multiple expressions using `&&` (and) or `||` (or), for example:

- `$VARIABLE1 =~ /^content.*/ && $VARIABLE2 == "something"`
- `$VARIABLE1 =~ /^content.*/ && $VARIABLE2 =~ /thing$/ && $VARIABLE3`
- `$VARIABLE1 =~ /^content.*/ || $VARIABLE2 =~ /thing$/ && $VARIABLE3`

The precedence of operators follows the [Ruby 2.5 standard](https://ruby-doc.org/core-2.5.0/doc/syntax/precedence_rdoc.html),
so `&&` is evaluated before `||`.

#### Group variable expressions together with parentheses

You can use parentheses to group expressions together. Parentheses take precedence over
`&&` and `||`, so expressions enclosed in parentheses are evaluated first, and the
result is used for the rest of the expression.

You can nest parentheses to create complex conditions, and the inner-most expressions
in parentheses are evaluated first.

For example:

- `($VARIABLE1 =~ /^content.*/ || $VARIABLE2) && ($VARIABLE3 =~ /thing$/ || $VARIABLE4)`
- `($VARIABLE1 =~ /^content.*/ || $VARIABLE2 =~ /thing$/) && $VARIABLE3`
- `$CI_COMMIT_BRANCH == "my-branch" || (($VARIABLE1 == "thing" || $VARIABLE2 == "thing") && $VARIABLE3)`
