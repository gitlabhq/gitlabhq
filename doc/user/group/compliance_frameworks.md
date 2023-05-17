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
[compliance pipeline configuration](#compliance-pipelines) to the projects on which it is
[applied](../project/settings/index.md#add-a-compliance-framework-to-a-project).

Compliance frameworks are created on top-level groups. Group owners can create, edit, and delete compliance frameworks:

1. On the top bar, select **Main menu > Groups > View all groups** and find your group.
1. On the left sidebar, select **Settings** > **General**.
1. Expand the **Compliance frameworks** section.
1. Create, edit, or delete compliance frameworks.

Subgroups and projects have access to all compliance frameworks created on their top-level group. However, compliance frameworks cannot be created, edited,
or deleted at the subgroup or project level. Project owners can choose a framework to apply to their projects.

## Default compliance frameworks

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/375036) in GitLab 15.6.

Group owners can set a default compliance framework. The default framework is applied to all the new and imported
projects that are created in that group. It does not affect the framework applied to the existing projects. The
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

## Compliance pipelines **(ULTIMATE)**

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/3156) in GitLab 13.9, disabled behind `ff_evaluate_group_level_compliance_pipeline` [feature flag](../../administration/feature_flags.md).
> - [Enabled by default](https://gitlab.com/gitlab-org/gitlab/-/issues/300324) in GitLab 13.11.
> - [Feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/issues/331231) in GitLab 14.2.

Group owners can configure a compliance pipeline in a project separate to other projects. By default, the compliance
pipeline configuration (for example, `.compliance-gitlab-ci.yml`) is run instead of the pipeline configuration (for example, `.gitlab-ci.yml`) of labeled
projects.

However, the compliance pipeline configuration can reference the `.gitlab-ci.yml` file of the labeled projects so that:

- The compliance pipeline can also run jobs of labeled project pipelines. This allows for centralized control of
  pipeline configuration.
- Jobs and variables defined in the compliance pipeline can't be changed by variables in the labeled project's
  `.gitlab-ci.yml` file.

For more information, see:

- [Example configuration](#example-configuration) for help configuring a compliance pipeline that runs jobs from
  labeled project pipeline configuration.
- The [Create a compliance pipeline](../../tutorials/compliance_pipeline/index.md) tutorial.

### Effect on labeled projects

Users have no way of knowing that a compliance pipeline has been configured and might be confused why their own
pipelines are not running at all, or include jobs that they did not define themselves.

When authoring pipelines on a labeled project, there is no indication that a compliance pipeline has been configured.
The only marker at the project level is the compliance framework label itself, but the label does not say whether the
framework has a compliance pipeline configured or not.

Therefore, communicate with project users about compliance pipeline configuration to reduce uncertainty and confusion.

### Configure a compliance pipeline

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
  - project: '$CI_PROJECT_PATH'
    file: '$CI_CONFIG_PATH'
    ref: '$CI_COMMIT_SHA' # Must be defined or MR pipelines always use the use default branch
    rules:
      - if: $CI_PROJECT_PATH != "my-group/project-1" # Must be the hardcoded path to the project that hosts this configuration.
```

The `rules` configuration in the `include` definition avoids circular inclusion in case the compliance pipeline must be able to run in the host project itself.
You can leave it out if your compliance pipeline only ever runs in labeled projects.

#### Compliance pipelines and custom pipeline configuration hosted externally

The example above assumes that all projects host their pipeline configuration in the same project.
If any projects use [configuration hosted externally to the project](../../ci/pipelines/settings.md#specify-a-custom-cicd-configuration-file):

- The `include` section in the example compliance pipeline configuration must be adjusted.
  For example, using [`include:rules`](../../ci/yaml/includes.md#use-rules-with-include):

  ```yaml
  include:
    # If the custom path variables are defined, include the project's external config file.
    - project: '$PROTECTED_PIPELINE_CI_PROJECT_PATH'
      file: '$PROTECTED_PIPELINE_CI_CONFIG_PATH'
      ref: '$PROTECTED_PIPELINE_CI_REF'
      rules:
        - if: $PROTECTED_PIPELINE_CI_PROJECT_PATH && $PROTECTED_PIPELINE_CI_CONFIG_PATH && $PROTECTED_PIPELINE_CI_REF
    # If any custom path variable is not defined, include the project's internal config file as normal.
    - project: '$CI_PROJECT_PATH'
      file: '$CI_CONFIG_PATH'
      ref: '$CI_COMMIT_SHA'
      rules:
        - if: $PROTECTED_PIPELINE_CI_PROJECT_PATH == null || $PROTECTED_PIPELINE_CI_CONFIG_PATH == null || $PROTECTED_PIPELINE_CI_REF == null
  ```

- [CI/CD variables](../../ci/variables/index.md) must be added to projects with external
  pipeline configuration. In this example:

  - `PROTECTED_PIPELINE_CI_PROJECT_PATH`: The path to the project hosting the configuration file, for example `group/subgroup/project`.
  - `PROTECTED_PIPELINE_CI_CONFIG_PATH`: The path to the configuration file in the project, for example `path/to/.gitlab-ci.yml`.
  - `PROTECTED_PIPELINE_CI_REF`: The ref to use when retrieving the configuration file, for example `main`.

#### Compliance pipelines in merge requests originating in project forks

When a merge request originates in a fork, the branch to be merged usually only exists in the fork.
When creating such a merge request against a project with compliance pipelines, the above snippet fails with a
`Project <project-name> reference <branch-name> does not exist!` error message.
This error occurs because in the context of the target project, `$CI_COMMIT_REF_NAME` evaluates to a non-existing
branch name.

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

The following are a few best practices for ensuring that these jobs are always run exactly
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

Therefore, in projects with compliance frameworks, you should replace
[parent-child pipelines](../../ci/pipelines/downstream_pipelines.md#parent-child-pipelines) with the following:

- Direct [`include`](../../ci/yaml/index.md#include) statements that provide the parent pipeline with child pipeline configuration.
- Child pipelines placed in another project that are run using the [trigger API](../../ci/triggers/index.md) rather than the parent-child
  pipeline feature.

This alternative ensures the compliance pipeline does not re-start the parent pipeline.

## Troubleshooting

### Cannot remove compliance framework from a project

Because of a [known issue](https://gitlab.com/gitlab-org/gitlab/-/issues/390626), if you move a project, its compliance
framework becomes orphaned and can't be removed. To manually remove a compliance framework from a project, run the
following GraphQL mutation with your project's ID:

```graphql
mutation {
  projectSetComplianceFramework(input: {projectId: "gid://gitlab/Project/1234567", complianceFrameworkId: null}) {
    errors
  }
}
```

### Compliance jobs are overwritten by target repository

If you use the `extends` statement in a compliance pipeline configuration, compliance jobs are overwritten by the target repository job. For example,
you could have the following `.compliance-gitlab-ci.yml` configuration:

```yaml
"compliance job":
  extends:
    - .compliance_template
  stage: build

.compliance_template:
  script:
    - echo "take compliance action"
```

You could also have the following `.gitlab-ci.yml` configuration:

```yaml
"compliance job":
  stage: test
  script:
    - echo "overwriting compliance action"
```

This configuration results in the target repository pipeline overwriting the compliance pipeline, and you get the following message:
`overwriting compliance action`.

To avoid overwriting a compliance job, don't use the `extends` keyword in compliance pipeline configuration. For example,
you could have the following `.compliance-gitlab-ci.yml` configuration:

```yaml
"compliance job":
  stage: build
  script:
    - echo "take compliance action"
```

You could also have the following `.gitlab-ci.yml` configuration:

```yaml
"compliance job":
  stage: test
  script:
    - echo "overwriting compliance action"
```

This configuration doesn't overwrite the compliance pipeline and you get the following message:
`take compliance action`.
