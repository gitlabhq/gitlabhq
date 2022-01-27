---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# GitLab CI/CD `workflow` keyword **(FREE)**

Use the [`workflow`](index.md#workflow) keyword to control when pipelines are created.

The `workflow` keyword is evaluated before jobs. For example, if a job is configured to run
for tags, but the workflow prevents tag pipelines, the job never runs.

## Common `if` clauses for `workflow:rules`

Some example `if` clauses for `workflow: rules`:

| Example rules                                        | Details                                                   |
|------------------------------------------------------|-----------------------------------------------------------|
| `if: '$CI_PIPELINE_SOURCE == "merge_request_event"'` | Control when merge request pipelines run.                 |
| `if: '$CI_PIPELINE_SOURCE == "push"'`                | Control when both branch pipelines and tag pipelines run. |
| `if: $CI_COMMIT_TAG`                                 | Control when tag pipelines run.                           |
| `if: $CI_COMMIT_BRANCH`                              | Control when branch pipelines run.                        |

See the [common `if` clauses for `rules`](../jobs/job_control.md#common-if-clauses-for-rules) for more examples.

## `workflow: rules` examples

In the following example:

- Pipelines run for all `push` events (changes to branches and new tags).
- Pipelines for push events with `-draft` in the commit message don't run, because
  they are set to `when: never`.
- Pipelines for schedules or merge requests don't run either, because no rules evaluate to true for them.

```yaml
workflow:
  rules:
    - if: $CI_COMMIT_MESSAGE =~ /-draft$/
      when: never
    - if: '$CI_PIPELINE_SOURCE == "push"'
```

This example has strict rules, and pipelines do **not** run in any other case.

Alternatively, all of the rules can be `when: never`, with a final
`when: always` rule. Pipelines that match the `when: never` rules do not run.
All other pipeline types run. For example:

```yaml
workflow:
  rules:
    - if: '$CI_PIPELINE_SOURCE == "schedule"'
      when: never
    - if: '$CI_PIPELINE_SOURCE == "push"'
      when: never
    - when: always
```

This example prevents pipelines for schedules or `push` (branches and tags) pipelines.
The final `when: always` rule runs all other pipeline types, **including** merge
request pipelines.

## Switch between branch pipelines and merge request pipelines

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/201845) in GitLab 13.8.

To make the pipeline switch from branch pipelines to merge request pipelines after
a merge request is created, add a `workflow: rules` section to your `.gitlab-ci.yml` file.

If you use both pipeline types at the same time, [duplicate pipelines](../jobs/job_control.md#avoid-duplicate-pipelines)
might run at the same time. To prevent duplicate pipelines, use the
[`CI_OPEN_MERGE_REQUESTS` variable](../variables/predefined_variables.md).

The following example is for a project that runs branch and merge request pipelines only,
but does not run pipelines for any other case. It runs:

- Branch pipelines when a merge request is not open for the branch.
- Merge request pipelines when a merge request is open for the branch.

```yaml
workflow:
  rules:
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'
    - if: '$CI_COMMIT_BRANCH && $CI_OPEN_MERGE_REQUESTS'
      when: never
    - if: '$CI_COMMIT_BRANCH'
```

If the pipeline is triggered by:

- A merge request, run a merge request pipeline. For example, a merge request pipeline
  can be triggered by a push to a branch with an associated open merge request.
- A change to a branch, but a merge request is open for that branch, do not run a branch pipeline.
- A change to a branch, but without any open merge requests, run a branch pipeline.

You can also add a rule to an existing `workflow` section to switch from branch pipelines
to merge request pipelines when a merge request is created.

Add this rule to the top of the `workflow` section, followed by the other rules that
were already present:

```yaml
workflow:
  rules:
    - if: $CI_COMMIT_BRANCH && $CI_OPEN_MERGE_REQUESTS && $CI_PIPELINE_SOURCE == "push"
      when: never
    - ...                # Previously defined workflow rules here
```

[Triggered pipelines](../triggers/index.md) that run on a branch have a `$CI_COMMIT_BRANCH`
set and could be blocked by a similar rule. Triggered pipelines have a pipeline source
of `trigger` or `pipeline`, so `&& $CI_PIPELINE_SOURCE == "push"` ensures the rule
does not block triggered pipelines.

## `workflow:rules` templates

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/217732) in GitLab 13.0.

GitLab provides templates that set up `workflow: rules`
for common scenarios. These templates help prevent duplicate pipelines.

The [`Branch-Pipelines` template](https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/gitlab/ci/templates/Workflows/Branch-Pipelines.gitlab-ci.yml)
makes your pipelines run for branches and tags.

Branch pipeline status is displayed in merge requests that use the branch
as a source. However, this pipeline type does not support any features offered by
[merge request pipelines](../pipelines/merge_request_pipelines.md), like
[merged results pipelines](../pipelines/merged_results_pipelines.md)
or [merge trains](../pipelines/merge_trains.md).
This template intentionally avoids those features.

To [include](index.md#include) it:

```yaml
include:
  - template: 'Workflows/Branch-Pipelines.gitlab-ci.yml'
```

The [`MergeRequest-Pipelines` template](https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/gitlab/ci/templates/Workflows/MergeRequest-Pipelines.gitlab-ci.yml)
makes your pipelines run for the default branch, tags, and
all types of merge request pipelines. Use this template if you use any of the
the [merge request pipelines features](../pipelines/merge_request_pipelines.md).

To [include](index.md#include) it:

```yaml
include:
  - template: 'Workflows/MergeRequest-Pipelines.gitlab-ci.yml'
```
