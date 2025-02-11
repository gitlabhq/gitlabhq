---
stage: Software Supply Chain Security
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

<!--- start_remove The following content will be removed on remove_date: '2025-08-15' -->

# Compliance pipelines (deprecated)

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

WARNING:
This feature was [deprecated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/159841) in GitLab 17.3
and is planned for removal in 19.0. Use [pipeline execution policy type](../application_security/policies/pipeline_execution_policies.md) instead.
This change is a breaking change. For more information, see the [migration guide](#pipeline-execution-policies-migration).

Group owners can configure a compliance pipeline in a project separate to other projects. By default, the compliance
pipeline configuration (for example, `.compliance-gitlab-ci.yml`) is run instead of the pipeline configuration (for example, `.gitlab-ci.yml`) of labeled
projects.

However, the compliance pipeline configuration can reference the `.gitlab-ci.yml` file of the labeled projects so that:

- The compliance pipeline can also run jobs of labeled project pipelines. This allows for centralized control of
  pipeline configuration.
- Jobs and variables defined in the compliance pipeline can't be changed by variables in the labeled project's
  `.gitlab-ci.yml` file.

NOTE:
Because of a [known issue](https://gitlab.com/gitlab-org/gitlab/-/issues/414004), project pipelines must be included first at the top of compliance pipeline configuration
to prevent projects overriding settings downstream.

For more information, see:

- [Example configuration](#example-configuration) for help configuring a compliance pipeline that runs jobs from
  labeled project pipeline configuration.
- The [Create a compliance pipeline](../../tutorials/compliance_pipeline/_index.md) tutorial.

## Pipeline execution policies migration

To consolidate and simplify scan and pipeline enforcement, we have introduced pipeline execution policies. We deprecated
compliance pipelines in GitLab 17.3 and will remove compliance pipelines in GitLab 19.0.

Pipeline execution policies extend a project's `.gitlab-ci.yml` file with the configuration provided in separate YAML file
(for example, `pipeline-execution.yml`) linked in the pipeline execution policy.

By default, when creating a new compliance framework, you are directed to use the pipeline execution policy type instead
of compliance pipelines.

Existing compliance pipelines must be migrated. Customers should migrate from compliance pipelines to the new
[pipeline execution policy type](../application_security/policies/pipeline_execution_policies.md) as soon as possible.

### Migrate an existing compliance framework

To migrate an existing compliance framework to use the pipeline execution policy type:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Secure > Compliance center**.
1. [Edit](compliance_frameworks.md#create-edit-or-delete-a-compliance-framework) the existing compliance framework.
1. In the banner than appears, select **Migrate pipeline to a policy** to create a new policy in the security policies.
1. Edit the compliance framework again to remove the compliance pipeline.

For more information, see [Security policy project](../application_security/policies/_index.md#security-policy-project).

If you receive a `Pipeline execution policy error: Job names must be unique` error during the migration, see the
[relevant troubleshooting information](#error-job-names-must-be-unique).

## Effect on labeled projects

Users have no way of knowing that a compliance pipeline has been configured and might be confused why their own
pipelines are not running at all, or include jobs that they did not define themselves.

When authoring pipelines on a labeled project, there is no indication that a compliance pipeline has been configured.
The only marker at the project level is the compliance framework label itself, but the label does not say whether the
framework has a compliance pipeline configured or not.

Therefore, communicate with project users about compliance pipeline configuration to reduce uncertainty and confusion.

### Multiple compliance frameworks

You can [apply to a single project](compliance_frameworks.md#apply-a-compliance-framework-to-a-project) multiple compliance frameworks with compliance pipelines configured.
In this case, only the first compliance framework applied to a project has its compliance pipeline included in the project pipeline.

To ensure that the correct compliance pipeline is included in a project:

1. Remove all compliance frameworks from the project.
1. Apply the compliance framework with the correct compliance pipeline to the project.
1. Apply additional compliance frameworks to the project.

## Configure a compliance pipeline

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/383209) in GitLab 15.11, compliance frameworks moved to compliance center.

To configure a compliance pipeline:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Secure** > **Compliance Center**.
1. Select **Frameworks** section.
1. Select **New framework** section, add information of compliance framework including path to the compliance framework configuration. Use the
   `path/file.y[a]ml@group-name/project-name` format. For example:

   - `.compliance-ci.yml@gitlab-org/gitlab`.
   - `.compliance-ci.yaml@gitlab-org/gitlab`.

This configuration is inherited by projects where the compliance framework label is
[applied](../project/working_with_projects.md#add-a-compliance-framework-to-a-project). In projects with the applied compliance
framework label, the compliance pipeline configuration is run instead of the labeled project's own pipeline configuration.

The user running the pipeline in the labeled project must at least have the Reporter role on the compliance project.

When used to enforce scan execution, this feature has some overlap with
[scan execution policies](../application_security/policies/scan_execution_policies.md). We have not
[unified the user experience for these two features](https://gitlab.com/groups/gitlab-org/-/epics/7312). For details on
the similarities and differences between these features, see [Enforce scan execution](../application_security/_index.md#enforce-scan-execution).

### Example configuration

The following example `.compliance-gitlab-ci.yml` includes the `include` keyword to ensure labeled project pipeline
configuration is also executed.

```yaml
include:  # Execute individual project's configuration (if project contains .gitlab-ci.yml)
  - project: '$CI_PROJECT_PATH'
    file: '$CI_CONFIG_PATH'
    ref: '$CI_COMMIT_SHA' # Must be defined or MR pipelines always use the use default branch
    rules:
      - if: $CI_PROJECT_PATH != "my-group/project-1" # Must run on projects other than the one hosting this configuration.

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
```

The `rules` configuration in the `include` definition avoids circular inclusion in case the compliance pipeline must be able to run in the host project itself.
You can leave it out if your compliance pipeline only ever runs in labeled projects.

#### Compliance pipelines and custom pipeline configuration hosted externally

The example above assumes that all projects host their pipeline configuration in the same project.
If any projects use [configuration hosted externally](../../ci/pipelines/settings.md#specify-a-custom-cicd-configuration-file),
the example configuration does not work. See [issue 393960](https://gitlab.com/gitlab-org/gitlab/-/issues/393960)
for more details.

With projects that use externally hosted configuration, you can try the this workaround:

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

- [CI/CD variables](../../ci/variables/_index.md) must be added to projects with external
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

#### Compliance pipelines in projects with no configuration file

The [example configuration](#example-configuration) above assumes that all projects contain
a pipeline configuration file (`.gitlab-ci.yml` by default). However, in projects
with no configuration file (and therefore no pipelines by default), the compliance pipeline
fails because the file specified in `include:project` is required.

To only include a configuration file if it exists in a target project, use
[`rules:exists:project`](../../ci/yaml/_index.md#rulesexistsproject):

```yaml
include:  # Execute individual project's configuration
  - project: '$CI_PROJECT_PATH'
    file: '$CI_CONFIG_PATH'
    ref: '$CI_COMMIT_SHA'
    rules:
      - exists:
          paths:
            - '$CI_CONFIG_PATH'
          project: '$CI_PROJECT_PATH'
          ref: '$CI_COMMIT_SHA'
```

In this example, a configuration file is only included if it exists for the given `ref`
in the project in `exists:project: $CI_PROJECT_PATH'`.

If `exists:project` is not specified in the compliance pipeline configuration, it searches for files in the project
in which the `include` is defined. In compliance pipelines, the `include` from the example above
is defined in the project hosting the compliance pipeline configuration file, not the project
running the pipeline.

## Ensure compliance jobs are always run

Compliance pipelines [use GitLab CI/CD](../../ci/_index.md) to give you an incredible amount of flexibility
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

- Add [a `rules:when:always` block](../../ci/yaml/_index.md#when) to each of your compliance jobs. This ensures they are
  non-modifiable and are always run.
- Explicitly set any [variables](../../ci/yaml/_index.md#variables) the job references. This:
  - Ensures that project-level pipeline configurations do not set them and alter their
    behavior. For example, see `before_script` and `after_script` configuration in the [example configuration](#example-configuration).
  - Includes any jobs that drive the logic of your job.
- Explicitly set the [container image](../../ci/yaml/_index.md#image) to run the job in. This ensures that your script
  steps execute in the correct environment.
- Explicitly set any relevant GitLab pre-defined [job keywords](../../ci/yaml/_index.md#job-keywords).
  This ensures that your job uses the settings you intend and that they are not overridden by
  project-level pipelines.

## Troubleshooting

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

### Prefilled variables are not shown

Because of a [known issue](https://gitlab.com/gitlab-org/gitlab/-/issues/382857),
compliance pipelines in GitLab 15.3 and later can prevent
[prefilled variables](../../ci/pipelines/_index.md#prefill-variables-in-manual-pipelines)
from appearing when manually starting a pipeline.

To workaround this issue, use `ref: '$CI_COMMIT_SHA'` instead of `ref: '$CI_COMMIT_REF_NAME'`
in the `include:` statement that executes the individual project's configuration.

The [example configuration](#example-configuration) has been updated with this change:

```yaml
include:
  - project: '$CI_PROJECT_PATH'
    file: '$CI_CONFIG_PATH'
    ref: '$CI_COMMIT_SHA'
```

### Error: `Job names must be unique`

To configure a compliance pipeline, the [example configuration](#example-configuration) recommends including the
individual project configuration with `include.project`.

The configuration can lead to an error when running the projects pipeline: `Pipeline execution policy error: Job names must be unique`.
This error occurs because the pipeline execution policy includes the project's `.gitlab-ci.yml` and tries to insert the
jobs when the jobs have already been declared in the pipeline.

To resolve this error, remove `include.project` from the separate YAML file linked in the pipeline execution policy.

<!--- end_remove -->
