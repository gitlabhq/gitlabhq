---
stage: Verify
group: Continuous Integration
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference, index
last_update: 2019-07-03
---

# Pipelines for Merge Requests

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/15310) in GitLab 11.6.

In a [basic configuration](../pipelines/pipeline_architectures.md#basic-pipelines), GitLab runs a pipeline each time
changes are pushed to a branch.

If you want the pipeline to run jobs **only** on commits to a branch that is associated with a merge request,
you can use *pipelines for merge requests*.

In the UI, these pipelines are labeled as `detached`. Otherwise, these pipelines appear the same
as other pipelines.

Any user who has developer [permissions](../../user/permissions.md)
can run a pipeline for merge requests.

![Merge request page](img/merge_request.png)

If you use this feature with [merge when pipeline succeeds](../../user/project/merge_requests/merge_when_pipeline_succeeds.md),
pipelines for merge requests take precedence over the other regular pipelines.

## Prerequisites

To enable pipelines for merge requests:

- Your repository must be a GitLab repository, not an
  [external repository](../ci_cd_for_external_repos/index.md).
- [In GitLab 11.10 and later](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/25504),
  you must be using GitLab Runner 11.9.

## Configuring pipelines for merge requests

To configure pipelines for merge requests you need to configure your [CI/CD configuration file](../yaml/README.md).
There are a few different ways to do this:

### Use `rules` to run pipelines for merge requests

When using `rules`, which is the preferred method, we recommend starting with one
of the [`workflow:rules` templates](../yaml/README.md#workflowrules-templates) to ensure
your basic configuration is correct. Instructions on how to do this, as well as how
to customize, are available at that link.

### Use `only` or `except` to run pipelines for merge requests

If you want to continue using `only/except`, this is possible but please review the drawbacks
below.

When you use this method, you have to specify `only: - merge_requests` for each job. In this
example, the pipeline contains a `test` job that is configured to run on merge requests.

The `build` and `deploy` jobs don't have the `only: - merge_requests` keyword,
so they don't run on merge requests.

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

The behavior of the `only: [merge_requests]` keyword is such that _only_ jobs with
that keyword are run in the context of a merge request; no other jobs run.

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

- Since `A` and `B` are getting the `only:` rule to execute in all cases, they always run.
- Since `C` specifies that it should only run for merge requests, it doesn't run for any pipeline
  except a merge request pipeline.

This helps you avoid having to add the `only:` rule to all of your jobs to make
them always run. You can use this format to set up a Review App, helping to
save resources.

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
variable](../variables/predefined_variables.md) in
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

## Run pipelines in the parent project for merge requests from a forked project **(STARTER)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/217451) in GitLab 13.3.

By default, external contributors working from forks can't create pipelines in the
parent project. When a pipeline for merge requests is triggered by a merge request
coming from a fork:

- It's created and runs in the fork (source) project, not the parent (target) project.
- It uses the fork project's CI/CD configuration and resources.

Sometimes parent project members want the pipeline to run in the parent
project. This could be to ensure that the post-merge pipeline passes in the parent project.
For example, a fork project could try to use a corrupted runner that doesn't execute
test scripts properly, but reports a passed pipeline. Reviewers in the parent project
could mistakenly trust the merge request because it passed a faked pipeline.

Parent project members with at least [Developer permissions](../../user/permissions.md)
can create pipelines in the parent project for merge requests
from a forked project. In the merge request, go to the **Pipelines** and click
**Run Pipeline** button.

CAUTION: **Caution:**
Fork merge requests could contain malicious code that tries to steal secrets in the
parent project when the pipeline runs, even before merge. Reviewers must carefully
check the changes in the merge request before triggering the pipeline. GitLab shows
a warning that must be accepted before the pipeline can be triggered.

## Additional predefined variables

By using pipelines for merge requests, GitLab exposes additional predefined variables to the pipeline jobs.
Those variables contain information of the associated merge request, so that it's useful
to integrate your job with [GitLab Merge Request API](../../api/merge_requests.md).

You can find the list of available variables in [the reference sheet](../variables/predefined_variables.md).
The variable names begin with the `CI_MERGE_REQUEST_` prefix.

## Troubleshooting

### Two pipelines created when pushing to a merge request

If you are experiencing duplicated pipelines when using `rules`, take a look at
the [important differences between `rules` and `only`/`except`](../yaml/README.md#prevent-duplicate-pipelines),
which helps you get your starting configuration correct.

If you are seeing two pipelines when using `only/except`, please see the caveats
related to using `only/except` above (or, consider moving to `rules`).

It is not possible to run a job for branch pipelines first, then only for merge request
pipelines after the merge request is created (skipping the duplicate branch pipeline). See
the [related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/201845) for more details.

### Two pipelines created when pushing an invalid CI configuration file

Pushing to a branch with an invalid CI configuration file can trigger
the creation of two types of failed pipelines. One pipeline is a failed merge request
pipeline, and the other is a failed branch pipeline, but both are caused by the same
invalid configuration.
