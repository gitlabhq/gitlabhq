---
stage: Govern
group: Security Policies
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Pipeline execution policies

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/13266) in GitLab 17.2 [with a flag](../../../administration/feature_flags.md) named `pipeline_execution_policy_type`. Enabled by default. [Feature flag removed in GitLab 17.3](https://gitlab.com/gitlab-org/gitlab/-/issues/454278).

FLAG:
The availability of this feature is controlled by a feature flag.
For more information, see the history.

Use Pipeline execution policies to enforce CI/CD jobs for all applicable projects.

- <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> For a video walkthrough, see [Security Policies: Pipeline Execution Policy Type](https://www.youtube.com/watch?v=QQAOpkZ__pA).

## Pipeline execution policies schema

> - The `suffix` field was [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/159858) in GitLab 17.4 [with a flag](../../../administration/feature_flags.md) named `pipeline_execution_policy_suffix`. Disabled by default.

The YAML file with pipeline execution policies consists of an array of objects matching pipeline execution
policy schema nested under the `pipeline_execution_policy` key. You can configure a maximum of five
policies under the `pipeline_execution_policy` key. Any other policies configured after
the first five are not applied.

When you save a new policy, GitLab validates its contents against [this JSON schema](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/validators/json_schemas/security_orchestration_policy.json).
If you're not familiar with how to read [JSON schemas](https://json-schema.org/),
the following sections and tables provide an alternative.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `pipeline_execution_policy` | `array` of pipeline execution policy | true | List of pipeline execution policies (maximum five) |

## Pipeline execution policy schema

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | `string` | true | Name of the policy. Maximum of 255 characters.|
| `description` (optional) | `string` | true | Description of the policy. |
| `enabled` | `boolean` | true | Flag to enable (`true`) or disable (`false`) the policy. |
| `content` | `object` of [`content`](#content-type) | true | Reference to the CI/CD configuration to inject into project pipelines. |
| `pipeline_config_strategy` | `string` | false | Can either be `inject_ci` or `override_project_ci`. See [Pipeline strategies](#pipeline-strategies) for more information. |
| `suffix` | `string` | false | Can either be `on_conflict` (default), or `never`. Defines the behavior for handling job naming conflicts. `on_conflict` applies a unique suffix to the job names for jobs that would break the uniqueness. `never` causes the pipeline to fail if the job names across the project and all applicable policies are not unique. |
| `policy_scope` | `object` of [`policy_scope`](#policy_scope-scope-type) | false | Scopes the policy based on compliance framework labels or projects you define. |

Note the following:

- Users triggering a pipeline must have at least read access to the pipeline execution file specified in the pipeline execution policy, otherwise the pipelines do not start.
- If the pipeline execution file gets deleted or renamed, the pipelines in projects with the policy enforced might stop working.
- Pipeline execution policy jobs can be assigned to one of the two reserved stages:
  - `.pipeline-policy-pre` at the beginning of the pipeline, before the `.pre` stage.
  - `.pipeline-policy-post` at the very end of the pipeline, after the `.post` stage.
- Injecting jobs in any of the reserved stages is guaranteed to always work. Execution policy jobs can also be assigned to any standard (build, test, deploy) or user-declared stages. However, in this case, the jobs may be ignored depending on the project pipeline configuration.
- It is not possible to assign jobs to reserved stages outside of a pipeline execution policy.
- You should choose unique job names for pipeline execution policies. Some CI/CD configurations are based on job names and it can lead to unwanted results if a job exists multiple times in the same pipeline. The `needs` keyword, for example makes one job dependent on another. In case of multiple jobs with the same name, it will randomly depend on one of them.
- Pipeline execution policies remain in effect even if the project lacks a CI/CD configuration file.
- The order of the policies matters for the applied suffix.
- If any policy applied to a given project has `suffix: never`, the pipeline fails if another job with the same name is already present in the pipeline.

### Job naming best practice

> - Naming conflict handling [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/473189) in GitLab 17.4 with a flag named `pipeline_execution_policy_suffix`. Disabled by default.

FLAG:
The availability of job naming conflict handling is controlled by a feature flag.
For more information, see the history.

There is no visible indicator for jobs coming from a security policy. Adding a unique prefix or suffix to job names makes it easier to identify them and avoid job name collisions.

Examples:

- `policy1:deployments:sast` - good, unique across policies and projects.
- `sast` - bad, likely to be used elsewhere.

Pipeline execution policies handles naming conflicts depending on the `suffix` attribute. If there are multiple name with the same job:

- Using `on_conflict` (default), a suffix is added to a job if its name conflicts with another job in the pipeline.
- Using `never`, no suffix is added in case of conflicts and the pipeline fails.

The suffix is added based on the order in which the jobs are merged onto the main pipeline.

The order is as follows:

1. Project pipeline jobs
1. Project policy jobs (if applicable)
1. Group policy jobs (if applicable, ordered by hierarchy, the most top-level group is applied as last)

The applied suffix has the following format:

`:policy-<security-policy-project-id>-<policy-index>`.

Example of the resulting job: `sast:policy-123456-0`.

If multiple policies in on security policy project define the same job name, the numerical suffix corresponds to the index of the conflicting policy.

Example of the resulting jobs:

- `sast:policy-123456-0`
- `sast:policy-123456-1`

### Job stage best practice

Jobs defined in a pipeline execution policy can use any [stage](../../../ci/yaml/index.md#stage)
defined in the project's CI/CD configuration, also the reserved stages `.pipeline-policy-pre` and
`.pipeline-policy-post`.

NOTE:
If your policy contains jobs only in the `.pre` and `.post` stages, the policy's pipeline is
evaluated as "empty" and so is not merged with the project's pipeline. To use `.pre` and `.post`
stages in a pipeline execution policy, you **must** include another job running in another stage
which is available on the project, for example `.pipeline-policy-pre`.

When using the `inject_ci` [pipeline strategy](#pipeline-strategies), if a target project does not
contain its own `.gitlab-ci.yml` file, then the only stages available are the default pipeline
stages and the reserved stages.

When enforcing pipeline execution policies over projects whose CI/CD configuration you do not
control, you should define jobs in the `.pipeline-policy-pre` and `.pipeline-policy-post` stages.
These stages are always available, regardless of any project's CI/CD configuration.

### `content` type

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `project` | `string` | true | The full GitLab project path to a project on the same GitLab instance. |
| `file` | `string` | true | A full file path relative to the root directory (/). The YAML files must have the `.yml` or `.yaml` extension. |
| `ref` | `string` | false | The ref to retrieve the file from. Defaults to the HEAD of the project when not specified. |

### `policy_scope` scope type

> - Scoping by group [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/468384) in GitLab 17.4.

| Field | Type | Possible values | Description |
|-------|------|-----------------|-------------|
| `compliance_frameworks` | `array` |  | List of IDs of the compliance frameworks in scope of enforcement, in an array of objects with key `id`. |
| `projects` | `object` | `including`, `excluding` | Use `excluding:` or `including:` then list the IDs of the projects you wish to include or exclude, in an array of objects with key `id`. |
| `groups` | `object` | `including` | Use `including:` then list the IDs of the groups you wish to include, in an array of objects with key `id`. |

For example:

Projects with a specific compliance framework:

```yaml
 policy_scope:
  compliance_frameworks:
    - id: 1020076
```

Only a specific set of projects:

```yaml
policy_scope:
  projects:
    including:
      - id: 61213118
      - id: 59560885
 ```

All projects except one specific project:

```yaml
policy_scope:
  projects:
    excluding:
      - id: 59560885
```

## Pipeline strategies

Pipeline configuration strategy defines the method for merging the policy configuration with the project pipeline. Pipeline execution policies execute the jobs defined in the `.gitlab-ci.yml` file in isolated pipelines, which are merged into the pipelines of the target projects.

### `inject_ci`

This strategy adds custom CI/CD configurations into the existing project pipeline without completely replacing the project's original CI/CD configuration. It is suitable when you want to enhance or extend the current pipeline with additional steps, such as adding new security scans, compliance checks, or custom scripts.

Having multiple policies enabled injects all jobs additively.

When using this strategy, a project CI/CD configuration cannot override any behavior defined in the policy pipelines because each pipeline has an isolated YAML configuration.

For projects without a `.gitlab-ci.yml` file, this strategy will create the `.gitlab-ci.yml` file
implicitly. That is, a pipeline containing only the jobs defined in the pipeline execution policy is
executed.

### `override_project_ci`

This strategy completely replaces the project's existing CI/CD configuration with a new one defined by the pipeline execution policy. This strategy is ideal when the entire pipeline needs to be standardized or replaced, such as enforcing organization-wide CI/CD standards or compliance requirements.

The strategy takes precedence over other policies using the `inject_ci` strategy. If any policy with `override_project_ci` applies, the project CI configuration will be ignored. Other security policy configurations will not be overridden.

This strategy allows users to include the project CI/CD configuration in the pipeline execution policy configuration, enabling them to customize the policy jobs. For example, by combining policy and project CI/CD configuration into one YAML file, users can override `before_script` configuration.

NOTE:
When a pipeline execution policy uses workflow rules that prevent policy jobs from running, the
project's original CI/CD configuration remains in effect instead of being overridden. You can
conditionally apply pipeline execution policies to control when the policy impacts the project's
CI/CD configuration. For example, if you set a workflow rule `if: $CI_PIPELINE_SOURCE ==
"merge_request_event"`, the project's CI configuration is only overridden when the pipeline source
is a merge request event.

### Include a project's CI/CD configuration in the pipeline execution policy configuration

When using `override_project_ci` strategy, the project configuration can be included into the pipeline execution policy configuration:

```yaml
include:
  - project: $CI_PROJECT_PATH
    ref: $CI_COMMIT_SHA
    file: $CI_CONFIG_PATH

compliance_job:
 ...
```

## CI/CD variables

Pipeline execution jobs are executed in isolation. Variables defined in another policy or in the project's `.gitlab-ci.yml` file are not available in the pipeline execution policy
and cannot be overwritten from the outside.

Variables can be shared with pipeline execution policies using group or project settings. If a variable is not defined in a pipeline execution policy, the value from group or project settings is applied.
If the variable is defined in the pipeline execution policy, the group or project setting is overwritten.
This behavior is independent from the pipeline execution policy strategy.

You can [define project or group variables in the UI](../../../ci/variables/index.md#define-a-cicd-variable-in-the-ui).

## Examples

These examples demonstrate what you can achieve with pipeline execution policies.

### Pipeline execution policy

You can use the following example in a `.gitlab/security-policies/policy.yml` file stored in a
[security policy project](index.md#security-policy-project):

```yaml
---
pipeline_execution_policy:
- name: My pipeline execution policy
  description: Enforces CI/CD jobs
  enabled: true
  pipeline_config_strategy: override_project_ci
  content:
    include:
    - project: verify-issue-469027/policy-ci
      file: policy-ci.yml
      ref: main # optional
  policy_scope:
    projects:
      including:
      - id: 361
```

### Customize enforced jobs based on project variables

You can customize enforced jobs, based on the presence of a project variable. In this example,
the value of `CS_IMAGE` is defined in the policy as `alpine:latest`. However, if the project
also defines the value of `CS_IMAGE`, that value is used instead. The CI/CD variable must be a
predefined project variable, not defined in the project's `.gitlab-ci.yml` file.

```yaml
variables:
  CS_ANALYZER_IMAGE: "$CI_TEMPLATE_REGISTRY_HOST/security-products/container-scanning:7"
  CS_IMAGE: alpine:latest

policy::container-security:
  stage: .pipeline-policy-pre
  rules:
    - if: $CS_IMAGE
      variables:
        CS_IMAGE: $PROJECT_CS_IMAGE
    - when: always
  script:
    - echo "CS_ANALYZER_IMAGE:$CS_ANALYZER_IMAGE"
    - echo "CS_IMAGE:$CS_IMAGE"
```

### Customize security scanner's behavior with `before_script` in project configurations

To customize the behavior of a security job enforced by a policy in the project's `.gitlab-ci.yml`, you can override `before_script`.
To do so, use the `override_project_ci` strategy in the policy and include the project's CI/CD configuration. Example pipeline execution policy configuration:

```yaml
# policy.yml
type: pipeline_execution_policy
name: Secret detection
description: >-
  This policy enforces secret detection and allows projects to override the
  behavior of the scanner.
enabled: true
pipeline_config_strategy: override_project_ci
content:
  include:
    - project: gitlab-org/pipeline-execution-policies/compliance-project
      file: secret-detection.yml
```

```yaml
# secret-detection.yml
include:
  - project: $CI_PROJECT_PATH
    ref: $CI_COMMIT_SHA
    file: $CI_CONFIG_PATH
  - template: Security/Secret-Detection.gitlab-ci.yml
```

In the project's `.gitlab-ci.yml`, you can define `before_script` for the scanner:

```yaml
include:
  - template: Jobs/Secret-Detection.gitlab-ci.yml

secret_detection:
  before_script:
    - echo "Before secret detection"
```

By using `override_project_ci` and including the project's configuration, it allows for YAML configurations to be merged.

### Use group or project variables in a pipeline execution policy

You can use group or project variables in a pipeline execution policy.

With a project variable of `PROJECT_VAR="I'm a project"` the following pipeline execution policy job results in: `I'm a project`.

```yaml
pipeline execution policy job:
    stage: .pipeline-policy-pre
    script:
    - echo "$PROJECT_VAR"
```

### Enforce a variable's value by using a pipeline execution policy

The value of a variable defined in a pipeline execution policy overrides the value of a group or policy variable with the same name.
In this example, the project value of variable `PROJECT_VAR` is overwritten and the job results in: `I'm a pipeline execution policy`.

```yaml
variables:
  PROJECT_VAR: "I'm a pipeline execution policy"

pipeline execution policy job:
    stage: .pipeline-policy-pre
    script:
    - echo "$PROJECT_VAR"
```

### Example `policy.yml` with security policy scopes

In this example, the security policy's `policy_scope`:

- Includes any project with compliance frameworks with an ID of `9` applied to them.
- Excludes projects with an ID of `456`.

```yaml
pipeline_execution_policy:
- name: Pipeline execution policy
  description: ''
  enabled: true
  pipeline_config_strategy: inject_ci
  content:
    include:
    - project: my-group/pipeline-execution-ci-project
      file: policy-ci.yml
  policy_scope:
    compliance_frameworks:
    - id: 9
    projects:
      excluding:
      - id: 456
```
