---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference
---

# Troubleshooting CI/CD **(FREE)**

GitLab provides several tools to help make troubleshooting your pipelines easier.

This guide also lists common issues and possible solutions.

## Verify syntax

An early source of problems can be incorrect syntax. The pipeline shows a `yaml invalid`
badge and does not start running if any syntax or formatting problems are found.

### Edit `gitlab-ci.yml` with the Web IDE

The [GitLab Web IDE](../user/project/web_ide/index.md) offers advanced authoring tools,
including syntax highlighting for the `.gitlab-ci.yml`, and is the recommended editing
experience (rather than the single file editor). It offers code completion suggestions
that ensure you are only using accepted keywords.

If you prefer to use another editor, you can use a schema like [the Schemastore `gitlab-ci` schema](https://json.schemastore.org/gitlab-ci)
with your editor of choice.

### Verify syntax with CI Lint tool

The [CI Lint tool](lint.md) is a simple way to ensure the syntax of a CI/CD configuration
file is correct. Paste in full `gitlab-ci.yml` files or individual jobs configuration,
to verify the basic syntax.

When a `.gitlab-ci.yml` file is present in a project, you can also use the CI Lint
tool to [simulate the creation of a full pipeline](lint.md#pipeline-simulation).
It does deeper verification of the configuration syntax.

## Verify variables

A key part of troubleshooting CI/CD is to verify which variables are present in a
pipeline, and what their values are. A lot of pipeline configuration is dependent
on variables, and verifying them is one of the fastest ways to find the source of
a problem.

[Export the full list of variables](variables/index.md#list-all-environment-variables)
available in each problematic job. Check if the variables you expect are present,
and check if their values are what you expect.

## GitLab CI/CD documentation

The [complete `gitlab-ci.yml` reference](yaml/index.md) contains a full list of
every keyword you may need to use to configure your pipelines.

You can also look at a large number of pipeline configuration [examples](examples/index.md)
and [templates](examples/index.md#cicd-templates).

### Documentation for pipeline types

Some pipeline types have their own detailed usage guides that you should read
if you are using that type:

- [Multi-project pipelines](pipelines/multi_project_pipelines.md): Have your pipeline trigger
  a pipeline in a different project.
- [Parent/child pipelines](pipelines/parent_child_pipelines.md): Have your main pipeline trigger
  and run separate pipelines in the same project. You can also
  [dynamically generate the child pipeline's configuration](pipelines/parent_child_pipelines.md#dynamic-child-pipelines)
  at runtime.
- [Pipelines for Merge Requests](pipelines/merge_request_pipelines.md): Run a pipeline
  in the context of a merge request.
  - [Pipelines for Merge Results](pipelines/pipelines_for_merged_results.md):
    Pipelines for merge requests that run on the combined source and target branch
  - [Merge Trains](pipelines/merge_trains.md):
    Multiple pipelines for merged results that queue and run automatically before
    changes are merged.

### Troubleshooting Guides for CI/CD features

There are troubleshooting guides available for some CI/CD features and related topics:

- [Container Registry](../user/packages/container_registry/index.md#troubleshooting-the-gitlab-container-registry)
- [GitLab Runner](https://docs.gitlab.com/runner/faq/)
- [Merge Trains](pipelines/merge_trains.md#troubleshooting)
- [Docker Build](docker/using_docker_build.md#troubleshooting)
- [Environments](environments/deployment_safety.md#ensure-only-one-deployment-job-runs-at-a-time)

## Common CI/CD issues

A lot of common pipeline issues can be fixed by analyzing the behavior of the `rules`
or `only/except` configuration. You shouldn't use these two configurations in the same
pipeline, as they behave differently. It's hard to predict how a pipeline runs with
this mixed behavior.

If your `rules` or `only/except` configuration makes use of [predefined variables](variables/predefined_variables.md)
like `CI_PIPELINE_SOURCE`, `CI_MERGE_REQUEST_ID`, you should [verify them](#verify-variables)
as the first troubleshooting step.

### Jobs or pipelines don't run when expected

The `rules` or `only/except` keywords are what determine whether or not a job is
added to a pipeline. If a pipeline runs, but a job is not added to the pipeline,
it's usually due to `rules` or `only/except` configuration issues.

If a pipeline does not seem to run at all, with no error message, it may also be
due to `rules` or `only/except` configuration, or the `workflow: rules` keyword.

If you are converting from `only/except` to the `rules` keyword, you should check
the [`rules` configuration details](yaml/index.md#rules) carefully. The behavior
of `only/except` and `rules` is different and can cause unexpected behavior when migrating
between the two.

The [common `if` clauses for `rules`](jobs/job_control.md#common-if-clauses-for-rules)
can be very helpful for examples of how to write rules that behave the way you expect.

#### Two pipelines run at the same time

Two pipelines can run when pushing a commit to a branch that has an open merge request
associated with it. Usually one pipeline is a merge request pipeline, and the other
is a branch pipeline.

This is usually caused by the `rules` configuration, and there are several ways to
[prevent duplicate pipelines](jobs/job_control.md#avoid-duplicate-pipelines).

#### A job is not in the pipeline

GitLab determines if a job is added to a pipeline based on the [`only/except`](yaml/index.md#only--except)
or [`rules`](yaml/index.md#rules) defined for the job. If it didn't run, it's probably
not evaluating as you expect.

#### No pipeline or the wrong type of pipeline runs

Before a pipeline can run, GitLab evaluates all the jobs in the configuration and tries
to add them to all available pipeline types. A pipeline does not run if no jobs are added
to it at the end of the evaluation.

If a pipeline did not run, it's likely that all the jobs had `rules` or `only/except` that
blocked them from being added to the pipeline.

If the wrong pipeline type ran, then the `rules` or `only/except` configuration should
be checked to make sure the jobs are added to the correct pipeline type. For
example, if a merge request pipeline did not run, the jobs may have been added to
a branch pipeline instead.

It's also possible that your [`workflow: rules`](yaml/index.md#workflow) configuration
blocked the pipeline, or allowed the wrong pipeline type.

### A job runs unexpectedly

A common reason a job is added to a pipeline unexpectedly is because the `changes`
keyword always evaluates to true in certain cases. For example, `changes` is always
true in certain pipeline types, including scheduled pipelines and pipelines for tags.

The `changes` keyword is used in combination with [`only/except`](yaml/index.md#onlychanges--exceptchanges)
or [`rules`](yaml/index.md#ruleschanges)). It's recommended to use `changes` with
`rules` or `only/except` configuration that ensures the job is only added to branch
pipelines or merge request pipelines.

### "fatal: reference is not a tree" error

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/17043) in GitLab 12.4.

Previously, you'd have encountered unexpected pipeline failures when you force-pushed
a branch to its remote repository. To illustrate the problem, suppose you've had the current workflow:

1. A user creates a feature branch named `example` and pushes it to a remote repository.
1. A new pipeline starts running on the `example` branch.
1. A user rebases the `example` branch on the latest default branch and force-pushes it to its remote repository.
1. A new pipeline starts running on the `example` branch again, however,
   the previous pipeline (2) fails because of `fatal: reference is not a tree:` error.

This is because the previous pipeline cannot find a checkout-SHA (which is associated with the pipeline record)
from the `example` branch that the commit history has already been overwritten by the force-push.
Similarly, [Pipelines for merged results](pipelines/pipelines_for_merged_results.md)
might have failed intermittently due to [the same reason](pipelines/pipelines_for_merged_results.md#intermittently-pipelines-fail-by-fatal-reference-is-not-a-tree-error).

As of GitLab 12.4, we've improved this behavior by persisting pipeline refs exclusively.
To illustrate its life cycle:

1. A pipeline is created on a feature branch named `example`.
1. A persistent pipeline ref is created at `refs/pipelines/<pipeline-id>`,
   which retains the checkout-SHA of the associated pipeline record.
   This persistent ref stays intact during the pipeline execution,
   even if the commit history of the `example` branch has been overwritten by force-push.
1. The runner fetches the persistent pipeline ref and gets source code from the checkout-SHA.
1. When the pipeline finishes, its persistent ref is cleaned up in a background process.

### Merge request pipeline messages

The merge request pipeline widget shows information about the pipeline status in
a merge request. It's displayed above the [ability to merge status widget](#merge-request-status-messages).

#### "Checking pipeline status" message

This message is shown when the merge request has no pipeline associated with the
latest commit yet. This might be because:

- GitLab hasn't finished creating the pipeline yet.
- You are using an external CI service and GitLab hasn't heard back from the service yet.
- You are not using CI/CD pipelines in your project.
- You are using CI/CD pipelines in your project, but your configuration prevented a pipeline from running on the source branch for your merge request.
- The latest pipeline was deleted (this is a [known issue](https://gitlab.com/gitlab-org/gitlab/-/issues/214323)).

After the pipeline is created, the message updates with the pipeline status.

### Merge request status messages

The merge request status widget shows the **Merge** button and whether or not a merge
request is ready to merge. If the merge request can't be merged, the reason for this
is displayed.

If the pipeline is still running, the **Merge** button is replaced with the
**Merge when pipeline succeeds** button.

If [**Merge Trains**](pipelines/merge_trains.md)
are enabled, the button is either **Add to merge train** or **Add to merge train when pipeline succeeds**. **(PREMIUM)**

#### "A CI/CD pipeline must run and be successful before merge" message

This message is shown if the [Pipelines must succeed](../user/project/merge_requests/merge_when_pipeline_succeeds.md#only-allow-merge-requests-to-be-merged-if-the-pipeline-succeeds)
setting is enabled in the project and a pipeline has not yet run successfully.
This also applies if the pipeline has not been created yet, or if you are waiting
for an external CI service. If you don't use pipelines for your project, then you
should disable **Pipelines must succeed** so you can accept merge requests.

### "The pipeline for this merge request did not complete. Push a new commit to fix the failure or check the troubleshooting documentation to see other possible actions." message

This message is shown if the [merge request pipeline](pipelines/merge_request_pipelines.md),
[merged results pipeline](pipelines/pipelines_for_merged_results.md),
or [merge train pipeline](pipelines/merge_trains.md)
has failed or been canceled.

If a merge request pipeline or merged result pipeline was canceled or failed, you can:

- Re-run the entire pipeline by clicking **Run pipeline** in the pipeline tab in the merge request.
- [Retry only the jobs that failed](pipelines/index.md#view-pipelines). If you re-run the entire pipeline, this is not necessary.
- Push a new commit to fix the failure.

If the merge train pipeline has failed, you can:

- Check the failure and determine if you can use the [`/merge` quick action](../user/project/quick_actions.md) to immediately add the merge request to the train again.
- Re-run the entire pipeline by clicking **Run pipeline** in the pipeline tab in the merge request, then add the merge request to the train again.
- Push a commit to fix the failure, then add the merge request to the train again.

If the merge train pipeline was canceled before the merge request was merged, without a failure, you can:

- Add it to the train again.

## Pipeline warnings

Pipeline configuration warnings are shown when you:

- [Validate configuration with the CI Lint tool](yaml/index.md).
- [Manually run a pipeline](pipelines/index.md#run-a-pipeline-manually).

### "Job may allow multiple pipelines to run for a single action" warning

When you use [`rules`](yaml/index.md#rules) with a `when:` clause without an `if:`
clause, multiple pipelines may run. Usually this occurs when you push a commit to
a branch that has an open merge request associated with it.

To [prevent duplicate pipelines](jobs/job_control.md#avoid-duplicate-pipelines), use
[`workflow: rules`](yaml/index.md#workflow) or rewrite your rules to control
which pipelines can run.

### Console workaround if job using resource_group gets stuck

```ruby
# find resource group by name
resource_group = Project.find_by_full_path('...').resource_groups.find_by(key: 'the-group-name')
busy_resources = resource_group.resources.where('build_id IS NOT NULL')

# identify which builds are occupying the resource
# (I think it should be 1 as of today)
busy_resources.pluck(:build_id)

# it's good to check why this build is holding the resource.
# Is it stuck? Has it been forcefully dropped by the system?
# free up busy resources
busy_resources.update_all(build_id: nil)
```

## How to get help

If you are unable to resolve pipeline issues, you can get help from:

- The [GitLab community forum](https://forum.gitlab.com/)
- GitLab [Support](https://about.gitlab.com/support/)
