---
type: reference, index
last_update: 2019-07-03
---

# Pipelines for Merge Requests

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/issues/15310) in GitLab 11.6.

In a [basic configuration](../pipelines/pipeline_architectures.md#basic-pipelines), GitLab runs a pipeline each time
changes are pushed to a branch.

If you want the pipeline to run jobs **only** when merge requests are created or updated,
you can use *pipelines for merge requests*.

In the UI, these pipelines are labeled as `detached`. Otherwise, these pipelines appear the same
as other pipelines.

Any user who has developer [permissions](../../user/permissions.md)
can run a pipeline for merge requests.

![Merge request page](img/merge_request.png)

NOTE: **Note**:
If you use this feature with [merge when pipeline succeeds](../../user/project/merge_requests/merge_when_pipeline_succeeds.md),
pipelines for merge requests take precedence over the other regular pipelines.

## Prerequisites

To enable pipelines for merge requests:

- You must have maintainer [permissions](../../user/permissions.md).
- Your repository must be a GitLab repository, not an
  [external repository](../ci_cd_for_external_repos/index.md).
- [In GitLab 11.10 and later](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/25504),
  you must be using GitLab Runner 11.9.

## Configuring pipelines for merge requests

To configure pipelines for merge requests, configure your [CI/CD configuration file](../yaml/README.md).
There are a few different ways to do this.

### Enable pipelines for merge requests for all jobs

The recommended method for enabling pipelines for merge requests for all jobs in
a pipeline is to use [`workflow:rules`](../yaml/README.md#workflowrules).

In this example, the pipeline always runs for all merge requests, as well as for all changes
to the master branch:

```yaml
workflow:
  rules:
    - if: $CI_MERGE_REQUEST_ID               # Execute jobs in merge request context
    - if: $CI_COMMIT_BRANCH == 'master'      # Execute jobs when a new commit is pushed to master branch

build:
  stage: build
  script: ./build

test:
  stage: test
  script: ./test

deploy:
  stage: deploy
  script: ./deploy
```

### Enable pipelines for merge requests for specific jobs

To enable pipelines for merge requests for specific jobs, you can use
[`rules`](../yaml/README.md#rules).

In the following example:

- The `build` job runs for all changes to the `master` branch, as well as for all merge requests.
- The `test` job runs for all merge requests.
- The `deploy` job runs for all changes to the `master` branch, but does *not* run
  for merge requests.

```yaml
build:
  stage: build
  script: ./build
  rules:
    - if: $CI_COMMIT_BRANCH == 'master'   # Execute jobs when a new commit is pushed to master branch
    - if: $CI_MERGE_REQUEST_ID            # Execute jobs in merge request context

test:
  stage: test
  script: ./test
  rules:
    - if: $CI_MERGE_REQUEST_ID             # Execute jobs in merge request context

deploy:
  stage: deploy
  script: ./deploy
  rules:
    - if: $CI_COMMIT_BRANCH == 'master'    # Execute jobs when a new commit is pushed to master branch
```

### Use `only` or `except` to run pipelines for merge requests

NOTE: **Note**:
The [`only` / `except`](../yaml/README.md#onlyexcept-basic) keywords are going to be deprecated
and you should not use them.

To enable pipelines for merge requests, you can use `only / except`. When you use this method,
you have to specify `only: - merge_requests` for each job.

In this example, the pipeline contains a `test` job that is configured to run on merge requests.

The `build` and `deploy` jobs don't have the `only: - merge_requests` parameter,
so they will not run on merge requests.

```yaml
build:
  stage: build
  script: ./build
  only:
  - master

test:
  stage: test
  script: ./test
  only:
  - merge_requests

deploy:
  stage: deploy
  script: ./deploy
  only:
  - master
```

#### Excluding certain jobs

The behavior of the `only: [merge_requests]` parameter is such that _only_ jobs with
that parameter are run in the context of a merge request; no other jobs will be run.

However, you can invert this behavior and have all of your jobs run _except_
for one or two.

Consider the following pipeline, with jobs `A`, `B`, and `C`. Imagine you want:

- All pipelines to always run `A` and `B`.
- `C` to run only for merge requests.

To achieve this, you can configure your `.gitlab-ci.yml` file as follows:

``` yaml
.only-default: &only-default
  only:
    - master
    - merge_requests
    - tags

A:
  <<: *only-default
  script:
    - ...

B:
  <<: *only-default
  script:
    - ...

C:
  script:
    - ...
  only:
    - merge_requests
```

Therefore:

- Since `A` and `B` are getting the `only:` rule to execute in all cases, they will always run.
- Since `C` specifies that it should only run for merge requests, it will not run for any pipeline
  except a merge request pipeline.

This helps you avoid having to add the `only:` rule to all of your jobs
in order to make them always run. You can use this format to set up a Review App, helping to save resources.

#### Excluding certain branches

Pipelines for merge requests require special treatment when
using [`only`/`except`](../yaml/README.md#onlyexcept-basic). Unlike ordinary
branch refs (for example `refs/heads/my-feature-branch`), merge request refs
use a special Git reference that looks like `refs/merge-requests/:iid/head`. Because
of this, the following configuration will **not** work as expected:

```yaml
# Does not exclude a branch named "docs-my-fix"!
test:
  only: [merge_requests]
  except: [/^docs-/]
```

Instead, you can use the
[`$CI_COMMIT_REF_NAME` predefined environment
variable](../variables/predefined_variables.md#variables-reference) in
combination with
[`only:variables`](../yaml/README.md#onlyvariablesexceptvariables) to
accomplish this behavior:

```yaml
test:
  only: [merge_requests]
  except:
    variables:
      - $CI_COMMIT_REF_NAME =~ /^docs-/
```

## Pipelines for Merged Results **(PREMIUM)**

Read the [documentation on Pipelines for Merged Results](pipelines_for_merged_results/index.md).

### Merge Trains **(PREMIUM)**

Read the [documentation on Merge Trains](pipelines_for_merged_results/merge_trains/index.md).

## Important notes about merge requests from forked projects

Note that the current behavior is subject to change. In the usual contribution
flow, external contributors follow the following steps:

1. Fork a parent project.
1. Create a merge request from the forked project that targets the `master` branch
   in the parent project.
1. A pipeline runs on the merge request.
1. A maintainer from the parent project checks the pipeline result, and merge
   into a target branch if the latest pipeline has passed.

Currently, those pipelines are created in a **forked** project, not in the
parent project. This means you cannot completely trust the pipeline result,
because, technically, external contributors can disguise their pipeline results
by tweaking their GitLab Runner in the forked project.

There are multiple reasons why GitLab doesn't allow those pipelines to be
created in the parent project, but one of the biggest reasons is security concern.
External users could steal secret variables from the parent project by modifying
`.gitlab-ci.yml`, which could be some sort of credentials. This should not happen.

We're discussing a secure solution of running pipelines for merge requests
that are submitted from forked projects,
see [the issue about the permission extension](https://gitlab.com/gitlab-org/gitlab/-/issues/11934).

## Additional predefined variables

By using pipelines for merge requests, GitLab exposes additional predefined variables to the pipeline jobs.
Those variables contain information of the associated merge request, so that it's useful
to integrate your job with [GitLab Merge Request API](../../api/merge_requests.md).

You can find the list of available variables in [the reference sheet](../variables/predefined_variables.md).
The variable names begin with the `CI_MERGE_REQUEST_` prefix.

## Troubleshooting

### Two pipelines created when pushing to a merge request

If two pipelines are created when you push a new change to a merge request,
check your CI configuration file.

For example, with this `.gitlab-ci.yml` configuration:

```yaml
test:
  script: ./test
  rules:
    - if: $CI_MERGE_REQUEST_ID                      # Include this job in pipelines for merge request
    - if: $CI_COMMIT_BRANCH                         # Include this job in all branch pipelines
  # Or, if you are using the `only:` keyword:
  # only:
  #  - merge_requests
  #  - branches
```

Two pipelines are created when you push a commit to a branch that also has a pending
merge request:

- A merge request pipeline that runs for the changes in the merge request. In
  **CI/CD > Pipelines**, the merge request icon (**{merge-request}**)
  and the merge request ID are displayed. If you hover over the ID, the merge request name is displayed.

  ![MR pipeline icon example](img/merge_request_pipelines_doubled_MR_v12_09.png)

- A "branch" pipeline that runs for the commit pushed to the branch. In **CI/CD > Pipelines**,
  the branch icon (**{branch}**) and branch name are displayed. This pipeline is
  created even if no merge request exists.

  ![branch pipeline icon example](img/merge_request_pipelines_doubled_branch_v12_09.png)

With the example configuration above, there is overlap between these two events.
When you push a commit to a branch that also has an open merge request pending,
both types of pipelines are created.

To fix this overlap, you must explicitly define which job should run for which
purpose, for example:

```yaml
test:
  script: ./test
  rules:
    - if: $CI_MERGE_REQUEST_ID                      # Include this job in pipelines for merge request
    - if: $CI_COMMIT_BRANCH == 'master'             # Include this job in master branch pipelines
```

Similar `rules:` should be added to all jobs to avoid any overlapping pipelines. Alternatively,
you can use the [`workflow:`](../yaml/README.md#exclude-jobs-with-rules-from-certain-pipelines)
parameter to add the same rules to all jobs globally.

### Two pipelines created when pushing an invalid CI configuration file

Similar to above, pushing to a branch with an invalid CI configuration file can trigger
the creation of two types of failed pipelines. One pipeline is a failed merge request
pipeline, and the other is a failed branch pipeline, but both are caused by the same
invalid configuration.

In rare cases, duplicate pipelines are created.

See [this issue](https://gitlab.com/gitlab-org/gitlab/-/issues/201845) for details.
