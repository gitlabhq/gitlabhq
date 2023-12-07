---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Debugging CI/CD pipelines **(FREE ALL)**

GitLab provides several tools to help make it easier to debug your CI/CD configuration.

If you are unable to resolve pipeline issues, you can get help from:

- The [GitLab community forum](https://forum.gitlab.com/)
- GitLab [Support](https://about.gitlab.com/support/)

## Verify syntax

An early source of problems can be incorrect syntax. The pipeline shows a `yaml invalid`
badge and does not start running if any syntax or formatting problems are found.

### Edit `.gitlab-ci.yml` with the pipeline editor

The [pipeline editor](pipeline_editor/index.md) is the recommended editing
experience (rather than the single file editor or the Web IDE). It includes:

- Code completion suggestions that ensure you are only using accepted keywords.
- Automatic syntax highlighting and validation.
- The [CI/CD configuration visualization](pipeline_editor/index.md#visualize-ci-configuration),
  a graphical representation of your `.gitlab-ci.yml` file.

### Edit `.gitlab-ci.yml` locally

If you prefer to edit your pipeline configuration locally, you can use the
GitLab CI/CD schema in your editor to verify basic syntax issues. Any
[editor with Schemastore support](https://www.schemastore.org/json/#editors) uses
the GitLab CI/CD schema by default.

If you need to link to the schema directly, use this URL:

```plaintext
https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/assets/javascripts/editor/schema/ci.json
```

To see the full list of custom tags covered by the CI/CD schema, check the
latest version of the schema.

### Verify syntax with CI Lint tool

You can use the [CI Lint tool](lint.md) to verify that the syntax of a CI/CD configuration
snippet is correct. Paste in full `.gitlab-ci.yml` files or individual job configurations,
to verify the basic syntax.

When a `.gitlab-ci.yml` file is present in a project, you can also use the CI Lint
tool to [simulate the creation of a full pipeline](lint.md#simulate-a-pipeline).
It does deeper verification of the configuration syntax.

## Verify variables

A key part of troubleshooting CI/CD is to verify which variables are present in a
pipeline, and what their values are. A lot of pipeline configuration is dependent
on variables, and verifying them is one of the fastest ways to find the source of
a problem.

[Export the full list of variables](variables/index.md#list-all-variables)
available in each problematic job. Check if the variables you expect are present,
and check if their values are what you expect.

## Job configuration issues

A lot of common pipeline issues can be fixed by analyzing the behavior of the `rules`
or `only/except` configuration used to [control when jobs are added to a pipeline](jobs/job_control.md).
You shouldn't use these two configurations in the same pipeline, as they behave differently.
It's hard to predict how a pipeline runs with this mixed behavior. `rules` is the preferred
choice for controlling jobs, as `only` and `except` are no longer being actively developed.

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

### A job with the `changes` keyword runs unexpectedly

A common reason a job is added to a pipeline unexpectedly is because the `changes`
keyword always evaluates to true in certain cases. For example, `changes` is always
true in certain pipeline types, including scheduled pipelines and pipelines for tags.

The `changes` keyword is used in combination with [`only/except`](yaml/index.md#onlychanges--exceptchanges)
or [`rules`](yaml/index.md#ruleschanges). It's recommended to only use `changes` with
`if` sections in `rules` or `only/except` configuration that ensures the job is only added to
branch pipelines or merge request pipelines.

### Two pipelines run at the same time

Two pipelines can run when pushing a commit to a branch that has an open merge request
associated with it. Usually one pipeline is a merge request pipeline, and the other
is a branch pipeline.

This situation is usually caused by the `rules` configuration, and there are several ways to
[prevent duplicate pipelines](jobs/job_control.md#avoid-duplicate-pipelines).

### No pipeline or the wrong type of pipeline runs

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

### Pipeline with many jobs fails to start

A Pipeline that has more jobs than the instance's defined [CI/CD limits](../administration/settings/continuous_integration.md#set-cicd-limits)
fails to start.

To reduce the number of jobs in a single pipeline, you can split your `.gitlab-ci.yml`
configuration into more independent [parent-child pipelines](../ci/pipelines/pipeline_architectures.md#parent-child-pipelines).

## Pipeline warnings

Pipeline configuration warnings are shown when you:

- [Validate configuration with the CI Lint tool](yaml/index.md).
- [Manually run a pipeline](pipelines/index.md#run-a-pipeline-manually).

### `Job may allow multiple pipelines to run for a single action` warning

When you use [`rules`](yaml/index.md#rules) with a `when` clause without an `if`
clause, multiple pipelines may run. Usually this occurs when you push a commit to
a branch that has an open merge request associated with it.

To [prevent duplicate pipelines](jobs/job_control.md#avoid-duplicate-pipelines), use
[`workflow: rules`](yaml/index.md#workflow) or rewrite your rules to control
which pipelines can run.

## Troubleshooting

For help with a specific area, see:

- [Caching](caching/index.md#troubleshooting).
- [CI/CD job tokens](jobs/ci_job_token.md).
- [Container registry](../user/packages/container_registry/troubleshoot_container_registry.md).
- [Docker](docker/using_docker_build.md#troubleshooting).
- [Downstream pipelines](pipelines/downstream_pipelines.md#troubleshooting).
- [Environments](environments/deployment_safety.md#ensure-only-one-deployment-job-runs-at-a-time).
- [GitLab Runner](https://docs.gitlab.com/runner/faq/).
- [ID tokens](secrets/id_token_authentication.md#troubleshooting).
- [Jobs](jobs/index.md#troubleshooting).
- [Job control](jobs/job_control.md).
- [Job artifacts](jobs/job_artifacts_troubleshooting.md).
- [Merge request pipelines](pipelines/merge_request_pipelines.md#troubleshooting),
  [merged results pipelines](pipelines/merged_results_pipelines.md#troubleshooting),
  and [Merge trains](pipelines/merge_trains.md#troubleshooting).
- [Pipeline editor](pipeline_editor/index.md#troubleshooting).
- [Variables](variables/index.md#troubleshooting).
- [YAML `includes` keyword](yaml/includes.md#troubleshooting).
- [YAML `script` keyword](yaml/script.md#troubleshooting).

Otherwise, review the following troubleshooting sections for known status messages
and error messages.

### `A CI/CD pipeline must run and be successful before merge` message

This message is shown if the [**Pipelines must succeed**](../user/project/merge_requests/merge_when_pipeline_succeeds.md#require-a-successful-pipeline-for-merge)
setting is enabled in the project and a pipeline has not yet run successfully.
This also applies if the pipeline has not been created yet, or if you are waiting
for an external CI service.

If you don't use pipelines for your project, then you should disable **Pipelines must succeed**
so you can accept merge requests.

### `Checking ability to merge automatically` message

If your merge request is stuck with a `Checking ability to merge automatically`
message that does not disappear after a few minutes, you can try one of these workarounds:

- Refresh the merge request page.
- Close & Re-open the merge request.
- Rebase the merge request with the `/rebase` [quick action](../user/project/quick_actions.md).
- If you have already confirmed the merge request is ready to be merged, you can merge
  it with the `/merge` quick action.

This issue is [resolved](https://gitlab.com/gitlab-org/gitlab/-/issues/229352) in GitLab 15.5.

### `Checking pipeline status` message

This message displays when the merge request does not yet have a pipeline associated with the
latest commit. This might be because:

- GitLab hasn't finished creating the pipeline yet.
- You are using an external CI service and GitLab hasn't heard back from the service yet.
- You are not using CI/CD pipelines in your project.
- You are using CI/CD pipelines in your project, but your configuration prevented a pipeline from running on the source branch for your merge request.
- The latest pipeline was deleted (this is a [known issue](https://gitlab.com/gitlab-org/gitlab/-/issues/214323)).
- The source branch of the merge request is on a private fork.

After the pipeline is created, the message updates with the pipeline status.

### `Project <group/project> not found or access denied` message

This message is shown if configuration is added with [`include`](yaml/index.md#include) and either:

- The configuration refers to a project that can't be found.
- The user that is running the pipeline is unable to access any included projects.

To resolve this, check that:

- The path of the project is in the format `my-group/my-project` and does not include
  any folders in the repository.
- The user running the pipeline is a [member of the projects](../user/project/members/index.md#add-users-to-a-project)
  that contain the included files. Users must also have the [permission](../user/permissions.md#job-permissions)
  to run CI/CD jobs in the same projects.

### `The parsed YAML is too big` message

This message displays when the YAML configuration is too large or nested too deeply.
YAML files with a large number of includes, and thousands of lines overall, are
more likely to hit this memory limit. For example, a YAML file that is 200 kb is
likely to hit the default memory limit.

To reduce the configuration size, you can:

- Check the length of the expanded CI/CD configuration in the pipeline editor's
  [Full configuration](pipeline_editor/index.md#view-full-configuration) tab. Look for
  duplicated configuration that can be removed or simplified.
- Move long or repeated `script` sections into standalone scripts in the project.
- Use [parent and child pipelines](pipelines/downstream_pipelines.md#parent-child-pipelines) to move some
  work to jobs in an independent child pipeline.

On a self-managed instance, you can [increase the size limits](../administration/instance_limits.md#maximum-size-and-depth-of-cicd-configuration-yaml-files).

### `500` error when editing the `.gitlab-ci.yml` file

A [loop of included configuration files](pipeline_editor/index.md#configuration-validation-currently-not-available-message)
can cause a `500` error when editing the `.gitlab-ci.yml` file with the [web editor](../user/project/repository/web_editor.md).

Ensure that included configuration files do not create a loop of references to each other.

### `Failed to pull image` messages

> **Allow access to this project with a CI_JOB_TOKEN** setting [renamed to **Limit access _to_ this project**](https://gitlab.com/gitlab-org/gitlab/-/issues/411406) in GitLab 16.3.

A runner might return a `Failed to pull image` message when trying to pull a container image
in a CI/CD job.

The runner authenticates with a [CI/CD job token](jobs/ci_job_token.md)
when fetching a container image defined with [`image`](yaml/index.md#image)
from another project's container registry.

If the job token settings prevent access to the other project's container registry,
the runner returns an error message.

For example:

- ```plaintext
  WARNING: Failed to pull image with policy "always": Error response from daemon: pull access denied for registry.example.com/path/to/project, repository does not exist or may require 'docker login': denied: requested access to the resource is denied
  ```

- ```plaintext
  WARNING: Failed to pull image with policy "": image pull failed: rpc error: code = Unknown desc = failed to pull and unpack image "registry.example.com/path/to/project/image:v1.2.3": failed to resolve reference "registry.example.com/path/to/project/image:v1.2.3": pull access denied, repository does not exist or may require authorization: server message: insufficient_scope: authorization failed
  ```

These errors can happen if the following are both true:

- The [**Limit access _to_ this project**](jobs/ci_job_token.md#limit-job-token-scope-for-public-or-internal-projects)
  option is enabled in the private project hosting the image.
- The job attempting to fetch the image is running in a project that is not listed in
  the private project's allowlist.

To resolve this issue, add any projects with CI/CD jobs that fetch images from the container
registry to the target project's [job token allowlist](jobs/ci_job_token.md#allow-access-to-your-project-with-a-job-token).
