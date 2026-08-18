---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab CI/CD 변수 사용 및 다양한 환경에서의 확장.
title: 변수를 사용할 수 있는 위치
---

{{< details >}}

- 계층: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

[CI/CD 변수](_index.md) 문서에 설명된 대로 많은 다양한 변수를 정의할 수 있습니다. 그 중 일부는 모든 GitLab CI/CD 기능에 사용할 수 있지만 일부는 더 또는 덜 제한됩니다.

이 문서에서는 다양한 유형의 변수를 사용할 수 있는 위치와 방법을 설명합니다.

## 변수 사용 {#variables-usage}

정의된 변수를 사용할 수 있는 두 가지 위치가 있습니다. 다음입니다:

1. GitLab 쪽, `.gitlab-ci.yml` 파일에서입니다.
1. GitLab 러너 쪽, `config.toml`에서입니다.

### `.gitlab-ci.yml` 파일 {#gitlab-ciyml-file}

{{< history >}}

- `CI_ENVIRONMENT_*` 변수는 `CI_ENVIRONMENT_SLUG`를 제외하고 지원이 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/128694)되었습니다 (GitLab 16.4).

{{< /history >}}

| 정의                                                              | 확장 가능한가요? | 확장 위치        | 설명 |
|:------------------------------------------------------------------------|:-----------------|:-----------------------|:------------|
| [`after_script`](../yaml/_index.md#after_script)                        | 예              | 스크립트 실행 셸 | 변수 확장은 [실행 셸 환경](#execution-shell-environment)에서 수행됩니다. |
| [`artifacts:name`](../yaml/_index.md#artifactsname)                     | 예              | 러너                 | 변수 확장은 GitLab 러너의 [내부 변수 확장 메커니즘](#gitlab-runner-internal-variable-expansion-mechanism)에서 수행됩니다. |
| [`artifacts:paths`](../yaml/_index.md#artifactspaths)                   | 예              | 러너                 | 변수 확장은 GitLab 러너의 [내부 변수 확장 메커니즘](#gitlab-runner-internal-variable-expansion-mechanism)에서 수행됩니다. |
| [`artifacts:exclude`](../yaml/_index.md#artifactsexclude)               | 예              | 러너                 | 변수 확장은 GitLab 러너의 [내부 변수 확장 메커니즘](#gitlab-runner-internal-variable-expansion-mechanism)에서 수행됩니다. |
| [`before_script`](../yaml/_index.md#before_script)                      | 예              | 스크립트 실행 셸 | 변수 확장은 [실행 셸 환경](#execution-shell-environment)에서 수행됩니다 |
| [`cache:key`](../yaml/_index.md#cachekey)                               | 예              | 러너                 | 변수 확장은 GitLab 러너의 [내부 변수 확장 메커니즘](#gitlab-runner-internal-variable-expansion-mechanism)에서 수행됩니다. |
| [`cache:paths`](../yaml/_index.md#cachepaths)                           | 예              | 러너                 | 변수 확장은 GitLab 러너의 [내부 변수 확장 메커니즘](#gitlab-runner-internal-variable-expansion-mechanism)에서 수행됩니다. |
| [`cache:policy`](../yaml/_index.md#cachepolicy)                         | 예              | 러너                 | 변수 확장은 GitLab 러너의 [내부 변수 확장 메커니즘](#gitlab-runner-internal-variable-expansion-mechanism)에서 수행됩니다. |
| [`environment:name`](../yaml/_index.md#environmentname)                 | 예              | GitLab                 | `environment:url`과 유사하지만 변수 확장은 다음을 지원하지 않습니다:<br/><br/>- `CI_ENVIRONMENT_*` 변수.<br/>- [지속형 변수](#persisted-variables). |
| [`environment:url`](../yaml/_index.md#environmenturl)                   | 예              | GitLab                 | 변수 확장은 GitLab의 [내부 변수 확장 메커니즘](#gitlab-internal-variable-expansion-mechanism)에서 수행됩니다.<br/><br/>작업에 대해 정의된 모든 변수가 지원됩니다 (프로젝트/그룹 변수, `.gitlab-ci.yml`의 변수, 트리거의 변수, 파이프라인 일정의 변수).<br/><br/>GitLab 러너 `config.toml`에 정의된 변수 및 작업의 `script`에서 생성된 변수는 지원되지 않습니다. |
| [`environment:deployment_tier`](../yaml/_index.md#environmentdeployment_tier) | 예              | GitLab                 | `environment:url`과 유사하지만 변수 확장은 다음을 지원하지 않습니다:<br/><br/>- `CI_ENVIRONMENT_*` 변수.<br/>- [지속형 변수](#persisted-variables). |
| [`environment:auto_stop_in`](../yaml/_index.md#environmentauto_stop_in) | 예              | GitLab                 | 변수 확장은 GitLab의 [내부 변수 확장 메커니즘](#gitlab-internal-variable-expansion-mechanism)에서 수행됩니다.<br/><br/> 대체되는 변수의 값은 사람이 읽을 수 있는 자연 언어 형식의 시간 기간이어야 합니다. 자세한 내용은 [지원되는 값](../yaml/_index.md#environmentauto_stop_in)을 참조하세요. |
| [`environment:kubernetes:agent`](../yaml/_index.md#environmentkubernetes) | 예            | GitLab                 | `environment:url`과 유사하지만 변수 확장은 다음을 지원하지 않습니다:<br/><br/>- `CI_ENVIRONMENT_*` 변수.<br/>- [지속형 변수](#persisted-variables). |
| [`environment:kubernetes:namespace`](../yaml/_index.md#environmentkubernetes) | 예        | GitLab                 | `environment:url`과 유사하지만 변수 확장은 다음을 지원하지 않습니다:<br/><br/>- `CI_ENVIRONMENT_*` 변수.<br/>- [지속형 변수](#persisted-variables). |
| [`id_tokens:aud`](../yaml/_index.md#id_tokens)                          | 예              | GitLab                 | 변수 확장은 GitLab의 [내부 변수 확장 메커니즘](#gitlab-internal-variable-expansion-mechanism)에서 수행됩니다. 변수 확장이 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/414293)되었습니다 (GitLab 16.1). |
| [`image`](../yaml/_index.md#image)                                      | 예              | 러너                 | 변수 확장은 GitLab 러너의 [내부 변수 확장 메커니즘](#gitlab-runner-internal-variable-expansion-mechanism)에서 수행됩니다. |
| [`include`](../yaml/_index.md#include)                                  | 예              | GitLab                 | 변수 확장은 GitLab의 [내부 변수 확장 메커니즘](#gitlab-internal-variable-expansion-mechanism)에서 수행됩니다. <br/><br/>지원되는 변수에 대한 자세한 내용은 [include와 함께 변수 사용](../yaml/includes.md#use-variables-with-include)을 참조하세요. |
| [`resource_group`](../yaml/_index.md#resource_group)                    | 예              | GitLab                 | `environment:url`과 유사하지만 변수 확장은 다음을 지원하지 않습니다:<br/>- `CI_ENVIRONMENT_URL`<br/>- [지속형 변수](#persisted-variables). |
| [`rules:changes`](../yaml/_index.md#ruleschanges)                       | 아니요               | GitLab                 | 변수 확장은 GitLab의 [내부 변수 확장 메커니즘](#gitlab-internal-variable-expansion-mechanism)에서 수행됩니다. |
| [`rules:changes:compare_to`](../yaml/_index.md#ruleschangescompare_to)  | 아니요               | GitLab                 | 변수 확장은 GitLab의 [내부 변수 확장 메커니즘](#gitlab-internal-variable-expansion-mechanism)에서 수행됩니다. |
| [`rules:exists`](../yaml/_index.md#rulesexists)                         | 아니요               | GitLab                 | 변수 확장은 GitLab의 [내부 변수 확장 메커니즘](#gitlab-internal-variable-expansion-mechanism)에서 수행됩니다. |
| [`rules:if`](../yaml/_index.md#rulesif)                                 | 아니요               | 해당 없음         | 변수는 `$variable` 형식이어야 합니다. 지원되지 않는 것은 다음과 같습니다:<br/><br/>- `CI_ENVIRONMENT_SLUG` 변수.<br/>- [지속형 변수](#persisted-variables). |
| [`script`](../yaml/_index.md#script)                                    | 예              | 스크립트 실행 셸 | 변수 확장은 [실행 셸 환경](#execution-shell-environment)에서 수행됩니다. |
| [`services:name`](../yaml/_index.md#services)                           | 예              | 러너                 | 변수 확장은 GitLab 러너의 [내부 변수 확장 메커니즘](#gitlab-runner-internal-variable-expansion-mechanism)에서 수행됩니다. |
| [`tags`](../yaml/_index.md#tags)                                        | 예              | GitLab                 | 변수 확장은 GitLab의 [내부 변수 확장 메커니즘](#gitlab-internal-variable-expansion-mechanism)에서 수행됩니다. |
| [`trigger` 및 `trigger:project`](../yaml/_index.md#trigger)            | 예              | GitLab                 | 변수 확장은 GitLab의 [내부 변수 확장 메커니즘](#gitlab-internal-variable-expansion-mechanism)에서 수행됩니다. `trigger:project`의 변수 확장이 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/367660)되었습니다 (GitLab 15.3). |
| [`variables`](../yaml/_index.md#variables)                              | 예              | GitLab/러너          | 변수 확장은 먼저 GitLab의 [내부 변수 확장 메커니즘](#gitlab-internal-variable-expansion-mechanism)에서 수행되고, 인식되지 않은 변수나 사용 불가능한 변수는 GitLab 러너의 [내부 변수 확장 메커니즘](#gitlab-runner-internal-variable-expansion-mechanism)에서 확장됩니다. |
| [`workflow:name`](../yaml/_index.md#workflowname)                       | 예              | GitLab                 | 변수 확장은 GitLab의 [내부 변수 확장 메커니즘](#gitlab-internal-variable-expansion-mechanism)에서 수행됩니다.<br/><br/>`workflow`에서 사용 가능한 모든 변수가 지원됩니다:<br/>\- 프로젝트/그룹 변수.<br/>\- 전역 `variables` 및 `workflow:rules:variables` (규칙과 일치할 때).<br/>\- 상위 파이프라인에서 상속된 변수.<br/>\- 트리거의 변수.<br/>\- 파이프라인 일정의 변수.<br/><br/>GitLab 러너 `config.toml`에 정의된 변수, 작업에 정의된 변수 또는 [지속형 변수](#persisted-variables)는 지원되지 않습니다. |

### `config.toml` 파일 {#configtoml-file}

| 정의                           | 확장 가능한가요? | 설명 |
|:-------------------------------------|:-----------------|:------------|
| `runners.environment`                | 예              | 변수 확장은 GitLab 러너의 [내부 변수 확장 메커니즘](#gitlab-runner-internal-variable-expansion-mechanism)에서 수행됩니다 |
| `runners.kubernetes.pod_labels`      | 예              | 변수 확장은 GitLab 러너의 [내부 변수 확장 메커니즘](#gitlab-runner-internal-variable-expansion-mechanism)에서 수행됩니다 |
| `runners.kubernetes.pod_annotations` | 예              | 변수 확장은 GitLab 러너의 [내부 변수 확장 메커니즘](#gitlab-runner-internal-variable-expansion-mechanism)에서 수행됩니다 |

`config.toml`에 대한 자세한 내용은 [GitLab 러너 문서](https://docs.gitlab.com/runner/configuration/advanced-configuration/)에서 확인할 수 있습니다.

## 확장 메커니즘 {#expansion-mechanisms}

세 가지 확장 메커니즘이 있습니다:

- GitLab
- GitLab 러너
- 실행 셸 환경

### GitLab 내부 변수 확장 메커니즘 {#gitlab-internal-variable-expansion-mechanism}

확장된 부분은 `$variable`, `${variable}` 또는 `%variable%` 형식이어야 합니다. 각 형식은 다루는 OS/셸에 관계없이 같은 방식으로 처리됩니다. 확장은 러너가 작업을 받기 전에 GitLab에서 수행되기 때문입니다.

#### 중첩 변수 확장 {#nested-variable-expansion}

GitLab은 작업 변수 값을 러너로 보내기 전에 재귀적으로 확장합니다. 예를 들어 다음 시나리오에서:

```yaml
- BUILD_ROOT_DIR: '${CI_BUILDS_DIR}'
- OUT_PATH: '${BUILD_ROOT_DIR}/out'
- PACKAGE_PATH: '${OUT_PATH}/pkg'
```

러너는 유효하고 완전히 형성된 경로를 받습니다. 예를 들어 `${CI_BUILDS_DIR}`이 `/output`이면 `PACKAGE_PATH`은 `/output/out/pkg`이 됩니다.

사용할 수 없는 변수에 대한 참조는 그대로 유지됩니다. 이 경우 러너는 런타임에 [변수 값을 확장하려고 시도](#gitlab-runner-internal-variable-expansion-mechanism)합니다. 예를 들어 `CI_BUILDS_DIR`과 같은 변수는 런타임에만 러너에 의해 알려집니다.

### GitLab 러너 내부 변수 확장 메커니즘 {#gitlab-runner-internal-variable-expansion-mechanism}

- 지원됨: 프로젝트/그룹 변수, `.gitlab-ci.yml` 변수, `config.toml` 변수, 그리고 트리거, 파이프라인 일정, 수동 파이프라인의 변수.
- 지원되지 않음: 스크립트 내에 정의된 변수 (예: `export MY_VARIABLE="test"`).

러너는 변수 확장을 위해 Go의 `os.Expand()` 메서드를 사용합니다. 이는 `$variable` 및 `${variable}`으로 정의된 변수만 처리한다는 의미입니다. 또한 중요한 점은 확장이 한 번만 수행되므로 중첩 변수는 변수 정의의 순서와 GitLab에서 [중첩 변수 확장](#nested-variable-expansion)이 활성화되어 있는지 여부에 따라 작동할 수도, 작동하지 않을 수도 있다는 것입니다.

아티팩트 및 캐시 업로드의 경우 러너는 Go의 `os.Expand()` 대신 변수 확장을 위해 [mvdan.cc/sh/v3/expand](https://pkg.go.dev/mvdan.cc/sh/v3/expand)를 사용합니다. `mvdan.cc/sh/v3/expand`이 [매개변수 확장](https://www.gnu.org/software/bash/manual/html_node/Shell-Parameter-Expansion.html)을 지원하기 때문입니다.

### 실행 셸 환경 {#execution-shell-environment}

이는 `script` 실행 중에 발생하는 확장 단계입니다. 그 동작은 사용된 셸 (`bash`, `sh`, `cmd`, PowerShell)에 따라 달라집니다. 예를 들어 작업의 `script`에 `echo $MY_VARIABLE-${MY_VARIABLE_2}` 줄이 포함되어 있으면 bash/sh에서 올바르게 처리되어야 하지만 (변수가 정의되었는지 여부에 따라 빈 문자열 또는 일부 값을 남김) Windows의 `cmd` 또는 PowerShell에서는 작동하지 않습니다. 이 셸들은 다른 변수 구문을 사용합니다.

지원됨:

- `script`은 셸의 기본값인 모든 사용 가능한 변수(예: 모든 bash/sh 셸에 있어야 하는 `$PATH`)와 GitLab CI/CD에서 정의한 모든 변수(프로젝트/그룹 변수, `.gitlab-ci.yml` 변수, `config.toml` 변수, 그리고 트리거 및 파이프라인 일정의 변수)를 사용할 수 있습니다.
- `script`은 이전 줄에서 정의된 모든 변수도 사용할 수 있습니다. 따라서 예를 들어 `export MY_VARIABLE="test"` 변수를 정의하면:
  - `before_script`에서는 `before_script`의 후속 줄 및 관련 `script`의 모든 줄에서 작동합니다.
  - `script`에서는 `script`의 후속 줄에서 작동합니다.
  - `after_script`에서는 `after_script`의 후속 줄에서 작동합니다.

`after_script` 스크립트의 경우:

- 동일한 `after_script` 섹션 내의 스크립트 이전에 정의된 변수만 사용합니다.
- `before_script` 및 `script`에 정의된 변수를 사용하지 않습니다.

이러한 제한은 `after_script` 스크립트가 [분리된 셸 컨텍스트](../yaml/_index.md#after_script)에서 실행되기 때문에 존재합니다.

## 지속형 변수 {#persisted-variables}

일부 미리 정의된 변수를 지속형 변수라고 합니다. 지속형 변수는:

- [확장 위치](#gitlab-ciyml-file)가 다음인 정의에 대해 지원됩니다:
  - 러너.
  - 스크립트 실행 셸.
- 지원되지 않음:
  - [확장 위치](#gitlab-ciyml-file)가 GitLab인 정의의 경우.
  - `rules` [변수 표현식](../jobs/job_rules.md#cicd-variable-expressions)에서.

[파이프라인 트리거 작업](../yaml/_index.md#trigger)은 작업 수준의 지속형 변수를 사용할 수 없지만 파이프라인 수준의 지속형 변수를 사용할 수 있습니다.

일부 지속형 변수는 토큰을 포함하며 보안상의 이유로 일부 정의에서 사용할 수 없습니다.

파이프라인 수준의 지속형 변수:

- `CI_PIPELINE_ID`
- `CI_PIPELINE_URL`

작업 수준의 지속형 변수:

- `CI_DEPLOY_PASSWORD`
- `CI_DEPLOY_USER`
- `CI_JOB_ID`
- `CI_JOB_STARTED_AT`
- `CI_JOB_TOKEN`
- `CI_JOB_URL`
- `CI_PIPELINE_CREATED_AT`
- `CI_REGISTRY_PASSWORD`
- `CI_REGISTRY_USER`
- `CI_REPOSITORY_URL`

## 환경 범위를 사용한 변수 {#variables-with-an-environment-scope}

환경 범위로 정의된 변수가 지원됩니다. 환경 범위로 정의된 `$STAGING_SECRET` 변수가 있다고 가정하면 `review/staging/*`, 다음 작업이 생성되어 일치하는 변수 표현식에 따라 동적 환경을 사용합니다:

```yaml
my-job:
  stage: staging
  environment:
    name: review/$CI_JOB_STAGE/deploy
  script:
    - 'deploy staging'
  rules:
    - if: $STAGING_SECRET == 'something'
```
