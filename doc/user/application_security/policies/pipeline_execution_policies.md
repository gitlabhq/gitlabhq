---
stage: Govern
group: Security Policies
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Pipeline execution policies

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/13266) in GitLab 17.2 [with a flag](../../../administration/feature_flags.md) named `pipeline_execution_policy_type`. Disabled by default.

FLAG:
The availability of this feature is controlled by a feature flag.
For more information, see the history.
This feature is available for testing, but not ready for production use.

Use Pipeline execution policies to enforce CI/CD jobs for all applicable projects.

- <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> For a video walkthrough, see [Security Policies: Pipeline Execution Policy Type](https://www.youtube.com/watch?v=QQAOpkZ__pA).

## Pipeline execution policies schema

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
| `pipeline_config_strategy` | `string` | false | Can either be `inject_ci` or `override_project_ci`. Defines the method for merging the policy configuration with the project pipeline. `inject_ci` preserves the project CI configuration and injects additional jobs from the policy. Having multiple policies enabled injects all jobs additively. `override_project_ci` replaces the project CI configuration and keeps only the policy jobs in the pipeline. |
| `policy_scope` | `object` of [`policy_scope`](#policy_scope-scope-type) | false | Scopes the policy based on compliance framework labels or projects you define. |

Note the following:

- Jobs variables from pipeline execution policies take precedence over the project's CI/CD configuration.
- Users triggering a pipeline must have at least read access to CI file specified in `content`.
- Pipeline execution policy jobs can be assigned to one of the two reserved stages:
  - `.pipeline-policy-pre` at the beginning of the pipeline, before the `.pre` stage.
  - `.pipeline-policy-post` at the very end of the pipeline, after the `.post` stage.
- Injecting jobs in any of the reserved stages is guaranteed to always work. Execution policy jobs can also be assigned to any standard (build, test, deploy) or user-declared stages. However, in this case, the jobs may be ignored depending on the project pipeline configuration.
- It is not possible to assign jobs to reserved stages outside of a pipeline execution policy.

### `content` type

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `project` | `string` | true | The full GitLab project path to a project on the same GitLab instance. |
| `file` | `string` | true | A full file path relative to the root directory (/). The YAML files must have the `.yml` or `.yaml` extension. |
| `ref` | `string` | false | The ref to retrieve the file from. Defaults to the HEAD of the project when not specified. |

### `policy_scope` scope type

| Field | Type | Possible values | Description |
|-------|------|-----------------|-------------|
| `compliance_frameworks` | `array` |  | List of IDs of the compliance frameworks in scope of enforcement, in an array of objects with key `id`. |
| `projects` | `object` |  `including`, `excluding` | Use `excluding:` or `including:` then list the IDs of the projects you wish to include or exclude, in an array of objects with key `id`. |

### Example security policies project

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
