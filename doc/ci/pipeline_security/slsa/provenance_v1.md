---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: SLSA provenance specification
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Status: Experiment

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/547865) in GitLab 18.3 [with a flag](../../../administration/feature_flags/_index.md) named `slsa_provenance_statement`. Disabled by default.

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by a feature flag.
For more information, see the history.
This feature is available for testing, but not ready for production use.

{{< /alert >}}

The [SLSA provenance specification](https://slsa.dev/spec/v1.1/provenance) requires
the `buildType` reference to be documented and published. This reference is to assist consumers of
GitLab SLSA attestations with parsing specific fields that are unique to GitLab SLSA provenance statements.

See the SLSA [`buildType` documentation](https://slsa.dev/spec/v1.1/provenance#builddefinition)
for more details.

## `buildType`

This official [SLSA Provenance](https://slsa.dev/spec/v1.1/provenance) `buildType` reference:

- Describes the execution of a GitLab [CI/CD job](_index.md).
- Is hosted and maintained by GitLab.

### Description

This `buildType` describes the execution of a workflow that builds a software
artifact.

{{< alert type="note" >}}

Consumers should ignore unrecognized external parameters. Any changes must
not change the semantics of existing external parameters.

{{< /alert >}}

### External parameters

The external parameters:

| Field        | Value |
|--------------|-------|
| `source`     | The URL of the project. |
| `entryPoint` | The name of the CI/CD job that triggered the build. |
| `variables`  | The names and values of any CI/CD or environment variables available during the build command execution. If the variable is [masked or hidden](../../variables/_index.md) the value of the variable is set to `[MASKED]`. |

### Internal parameters

The internal parameters, which are populated by default:

| Field          | Value |
|----------------|-------|
| `name`         | The name of the runner. |
| `executor`     | The runner executor. |
| `architecture` | The architecture on which the CI/CD job is run. |
| `job`          | The ID of the CI/CD job that triggered the build. |

### Example

This example shows the format of a GitLab-generated provenance statement:

```json
{
  "_type": "https://in-toto.io/Statement/v1",
  "subject": [
    {
      "name": "artifacts.zip",
      "digest": {
        "sha256": "717a1ee89f0a2829cf5aad57054c83615675b04baa913bdc19999d7519edf3f2"
      }
    }
  ],
  "predicateType": "https://slsa.dev/provenance/v1",
  "predicate": {
    "buildDefinition": {
      "buildType": "<Link to Build Type>",
      "externalParameters": {
        "source": "http://gdk.test:3000/root/repo_name",
        "entryPoint": "build-job",
        "variables": {
          "CI_PIPELINE_ID": "576",
          "CI_PIPELINE_URL": "http://gdk.test:3000/root/repo_name/-/pipelines/576",
          "CI_JOB_ID": "412",
[... additional environment variables ...]
          "masked_and_hidden_variable": "[MASKED]",
          "masked_variable": "[MASKED]",
          "visible_variable": "visible_variable",
        }
      },
      "internalParameters": {
        "architecture": "arm64",
        "executor": "docker",
        "job": 412,
        "name": "9-mfdkBG"
      },
      "resolvedDependencies": [
        {
          "uri": "http://gdk.test:3000/root/repo_name",
          "digest": {
            "gitCommit": "a288201509dd9a85da4141e07522bad412938dbe"
          }
        }
      ]
    },
    "runDetails": {
      "builder": {
        "id": "http://gdk.test:3000/groups/user/-/runners/33",
        "version": {
          "gitlab-runner": "4d7093e1"
        }
      },
      "metadata": {
        "invocationId": 412,
        "startedOn": "2025-06-05T01:33:18Z",
        "finishedOn": "2025-06-05T01:33:23Z"
      }
    }
  }
}
```
