---
stage: Govern
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Compliance frameworks **(PREMIUM)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/276221) in GitLab 13.9.
> - [Feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/issues/287779) in GitLab 13.12.

You can create a compliance framework that is a label to identify that your project has certain compliance
requirements or needs additional oversight. The label can optionally enforce
[compliance pipeline configuration](#configure-a-compliance-pipeline) to the projects on which it is
[applied](../project/settings/index.md#add-a-compliance-framework-to-a-project).

Group owners can create, edit, and delete compliance frameworks:

1. On the top bar, select **Main menu > Groups > View all groups** and find your group.
1. On the left sidebar, select **Settings** > **General**.
1. Expand the **Compliance frameworks** section.
1. Create, edit, or delete compliance frameworks.

## Default compliance frameworks

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/375036) in GitLab 15.6.

Group owners can set a default compliance framework. The default framework is applied to all the new and imported 
projects that are created within that group. It does not affect the framework applied to the existing projects. The 
default framework cannot be deleted.

A compliance framework that is set to default has a **default** label.

### Set and remove as default

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/375038) in GitLab 15.7.

Group owners can set a compliance framework as default (or remove the setting):

1. On the top bar, select **Main menu > Groups > View all groups** and find your group.
1. On the left sidebar, select **Settings > General**.
1. Expand the **Compliance frameworks** section and locate the compliance framework to set (or remove) as default.
1. Select the vertical ellipsis (**{ellipsis_v}**) for the compliance frame and then select **Set default** (or
   **Remove default**).

### Example GraphQL mutations for setting a default compliance framework

Creating a new compliance framework and setting it as the default framework for the group.

```graphql
mutation {
    createComplianceFramework(
        input: {params: {name: "SOX", description: "Sarbanes-Oxley Act", color: "#87CEEB", default: true}, namespacePath: "gitlab-org"}
    ) {
        framework {
            id
            name
            default
            description
            color
            pipelineConfigurationFullPath
        }
        errors
    }
}
```

Setting an existing compliance framework as the default framework the group.

```graphql
mutation {
    updateComplianceFramework(
        input: {id: "gid://gitlab/ComplianceManagement::Framework/<id>", params: {default: true}}
    ) {
        complianceFramework {
            id
            name
            default
            description
            color
            pipelineConfigurationFullPath
        }
    }
}
```

## Configure a compliance pipeline **(ULTIMATE)**

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/3156) in GitLab 13.9, disabled behind `ff_evaluate_group_level_compliance_pipeline` [feature flag](../../administration/feature_flags.md).
> - [Enabled by default](https://gitlab.com/gitlab-org/gitlab/-/issues/300324) in GitLab 13.11.
> - [Feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/issues/331231) in GitLab 14.2.

Group owners can configure a compliance pipeline in a project separate to other projects. By default, the compliance
pipeline configuration (`.gitlab-ci.yml` file) is run instead of the pipeline configuration of labeled projects.

However, the compliance pipeline configuration can reference the `.gitlab-ci.yml` file of the labeled projects so that:

- The compliance pipeline can also run jobs of labeled project pipelines. This allows for centralized control of
  pipeline configuration.
- Jobs and variables defined in the compliance pipeline can't be changed by variables in the labeled project's
  `.gitlab-ci.yml` file.

See [example configuration](#example-configuration) for help configuring a compliance pipeline that runs jobs from
labeled project pipeline configuration.

To configure a compliance pipeline:

1. On the top bar, select **Main menu > Groups > View all groups** and find your group.
1. On the left sidebar, select **Settings** > **General**.
1. Expand the **Compliance frameworks** section.
1. In **Compliance pipeline configuration (optional)**, add the path to the compliance framework configuration. Use the
   `path/file.y[a]ml@group-name/project-name` format. For example:

   - `.compliance-ci.yml@gitlab-org/gitlab`.
   - `.compliance-ci.yaml@gitlab-org/gitlab`.

This configuration is inherited by projects where the compliance framework label is
[applied](../project/settings/index.md#add-a-compliance-framework-to-a-project). In projects with the applied compliance
framework label, the compliance pipeline configuration is run instead of the labeled project's own pipeline configuration.

The user running the pipeline in the labeled project must at least have the Reporter role on the compliance project.

When used to enforce scan execution, this feature has some overlap with
[scan execution policies](../application_security/policies/scan-execution-policies.md). We have not
[unified the user experience for these two features](https://gitlab.com/groups/gitlab-org/-/epics/7312). For details on
the similarities and differences between these features, see [Enforce scan execution](../application_security/index.md#enforce-scan-execution).

### Example configuration

The following example `.compliance-gitlab-ci.yml` includes the `include` keyword to ensure labeled project pipeline
configuration is also executed.

```yaml
# Allows compliance team to control the ordering and interweaving of stages/jobs.
# Stages without jobs defined will remain hidden.
stages:
  - pre-compliance
  - build
  - test
  - pre-deploy-compliance
  - deploy
  - post-compliance

variables:  # Can be overridden by setting a job-specific variable in project's local .gitlab-ci.yml
  FOO: sast

sast:  # None of these attributes can be overridden by a project's local .gitlab-ci.yml
  variables:
    FOO: sast
  image: ruby:2.6
  stage: pre-compliance
  rules:
    - if: $CI_COMMIT_BRANCH && $CI_OPEN_MERGE_REQUESTS && $CI_PIPELINE_SOURCE == "push"
      when: never
    - when: always  # or when: on_success
  allow_failure: false
  before_script:
    - "# No before scripts."
  script:
    - echo "running $FOO"
  after_script:
    - "# No after scripts."

sanity check:
  image: ruby:2.6
  stage: pre-deploy-compliance
  rules:
    - if: $CI_COMMIT_BRANCH && $CI_OPEN_MERGE_REQUESTS && $CI_PIPELINE_SOURCE == "push"
      when: never
    - when: always  # or when: on_success
  allow_failure: false
  before_script:
    - "# No before scripts."
  script:
    - echo "running $FOO"
  after_script:
    - "# No after scripts."

audit trail:
  image: ruby:2.7
  stage: post-compliance
  rules:
    - if: $CI_COMMIT_BRANCH && $CI_OPEN_MERGE_REQUESTS && $CI_PIPELINE_SOURCE == "push"
      when: never
    - when: always  # or when: on_success
  allow_failure: false
  before_script:
    - "# No before scripts."
  script:
    - echo "running $FOO"
  after_script:
    - "# No after scripts."

include:  # Execute individual project's configuration (if project contains .gitlab-ci.yml)
  project: '$CI_PROJECT_PATH'
  file: '$CI_CONFIG_PATH'
  ref: '$CI_COMMIT_REF_NAME' # Must be defined or MR pipelines always use the use default branch
```

#### CF pipelines in Merge Requests originating in project forks

When an MR originates in a fork, the branch to be merged usually only exists in the fork.
When creating such an MR against a project with CF pipelines, the above snippet will fail with a
`Project <project-name> reference <branch-name> does not exist!` error message.
This is because in the context of the target project, `$CI_COMMIT_REF_NAME` evaluates to a non-existing branch name.

To get the correct context, use `$CI_MERGE_REQUEST_SOURCE_PROJECT_PATH` instead of `$CI_PROJECT_PATH`.
This variable is only available in
[merge request pipelines](../../ci/pipelines/merge_request_pipelines.md).

For example, for a configuration that supports both merge request pipelines originating in project forks and branch pipelines,
you need to [combine both `include` directives with `rules:if`](../../ci/yaml/includes.md#use-rules-with-include):

```yaml
include:  # Execute individual project's configuration (if project contains .gitlab-ci.yml)
  - project: '$CI_MERGE_REQUEST_SOURCE_PROJECT_PATH'
    file: '$CI_CONFIG_PATH'
    ref: '$CI_COMMIT_REF_NAME'
    rules:
      - if: $CI_PIPELINE_SOURCE == 'merge_request_event'
  - project: '$CI_PROJECT_PATH'
    file: '$CI_CONFIG_PATH'
    ref: '$CI_COMMIT_REF_NAME'
    rules:
      - if: $CI_PIPELINE_SOURCE != 'merge_request_event'
```

## Ensure compliance jobs are always run

Compliance pipelines [use GitLab CI/CD](../../ci/index.md) to give you an incredible amount of flexibility
for defining any sort of compliance jobs you like. Depending on your goals, these jobs
can be configured to be:

- Modified by users.
- Non-modifiable.

Generally, if a value in a compliance job:

- Is set, it cannot be changed or overridden by project-level configurations.
- Is not set, a project-level configuration may be set.

Either might be wanted or not depending on your use case.

There are a few best practices for ensuring that these jobs are always run exactly
as you define them and that downstream, project-level pipeline configurations
cannot change them:

- Add [a `rules:when:always` block](../../ci/yaml/index.md#when) to each of your compliance jobs. This ensures they are
  non-modifiable and are always run.
- Explicitly set any [variables](../../ci/yaml/index.md#variables) the job references. This:
  - Ensures that project-level pipeline configurations do not set them and alter their
    behavior.
  - Includes any jobs that drive the logic of your job.
- Explicitly set the [container image](../../ci/yaml/index.md#image) to run the job in. This ensures that your script
  steps execute in the correct environment.
- Explicitly set any relevant GitLab pre-defined [job keywords](../../ci/yaml/index.md#job-keywords).
  This ensures that your job uses the settings you intend and that they are not overridden by
  project-level pipelines.

## Avoid parent and child pipelines in GitLab 14.7 and earlier

NOTE:
This advice does not apply to GitLab 14.8 and later because [a fix](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/78878) added
compatibility for combining compliance pipelines, and parent and child pipelines.

Compliance pipelines start on the run of _every_ pipeline in a labeled project. This means that if a pipeline in the labeled project
triggers a child pipeline, the compliance pipeline runs first. This can trigger the parent pipeline, instead of the child pipeline.

Therefore, in projects with compliance frameworks, we recommend replacing
[parent-child pipelines](../../ci/pipelines/downstream_pipelines.md#parent-child-pipelines) with the following:

- Direct [`include`](../../ci/yaml/index.md#include) statements that provide the parent pipeline with child pipeline configuration.
- Child pipelines placed in another project that are run using the [trigger API](../../ci/triggers/index.md) rather than the parent-child
  pipeline feature.

This alternative ensures the compliance pipeline does not re-start the parent pipeline.
