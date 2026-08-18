---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: SLSA 사전 서명 명세
---

{{< details >}}

- 계층: Ultimate
- 제공 서비스: GitLab.com
- 상태: 실험적 기능

{{< /details >}}

{{< history >}}

- [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/547865)됨: GitLab 18.3 [플래그](../../../../administration/feature_flags/_index.md) `slsa_provenance_statement` 포함 기본적으로 비활성화되어 있습니다.

{{< /history >}}

> [!flag]
> 이 기능의 가용성은 기능 플래그로 제어됩니다. 자세한 내용은 기록을 참조하세요. 이 기능은 테스트 가능하지만 프로덕션 사용 준비가 되지 않았습니다.

[SLSA 사전 서명 명세](https://slsa.dev/spec/v1.1/provenance)에서는 `buildType` 참조를 문서화하고 게시해야 합니다. 이 참조는 GitLab SLSA 증명서를 사용하는 사용자가 GitLab SLSA 사전 서명 문에 고유한 특정 필드를 구문 분석하는 데 도움이 됩니다.

자세한 내용은 SLSA [`buildType` 설명서](https://slsa.dev/spec/v1.1/provenance#builddefinition)를 참조하세요.

## `buildType` {#buildtype}

이 공식 [SLSA 사전 서명](https://slsa.dev/spec/v1.1/provenance) `buildType` 참조:

- GitLab [CI/CD 작업](_index.md)의 실행을 설명합니다.
- GitLab에서 호스팅하고 유지 관리합니다.

### 설명 {#description}

이 `buildType`는 소프트웨어 아티팩트를 구축하는 워크플로의 실행을 설명합니다.

> [!note]
> 소비자는 인식되지 않는 외부 매개변수를 무시해야 합니다. 기존 외부 매개변수의 의미를 변경하는 변경 사항은 없어야 합니다.

### 외부 매개변수 {#external-parameters}

외부 매개변수:

| 필드        | 값 |
|--------------|-------|
| `source`     | 프로젝트의 URL입니다. |
| `entryPoint` | 빌드를 트리거한 CI/CD 작업의 이름입니다. |
| `variables`  | 빌드 명령 실행 중에 사용 가능한 CI/CD 또는 환경 변수의 이름과 값입니다. 변수가 [숨겨지거나 마스킹된](../../../variables/_index.md) 경우 변수의 값이 `[MASKED]`로 설정됩니다. |

### 내부 매개변수 {#internal-parameters}

기본적으로 채워지는 내부 매개변수:

| 필드          | 값 |
|----------------|-------|
| `name`         | 러너의 이름입니다. |
| `executor`     | 러너 실행기입니다. |
| `architecture` | CI/CD 작업이 실행되는 아키텍처입니다. |
| `job`          | 빌드를 트리거한 CI/CD 작업의 ID입니다. |

### 예시 {#example}

이 예시는 GitLab에서 생성한 사전 서명 문의 형식을 보여줍니다:

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
