---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: CI/CD 파이프라인 디버깅
description: "구성 유효성 검사, 경고, 오류 및 문제 해결"
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab은 CI/CD 구성을 디버깅하기 쉽게 도와주는 여러 도구를 제공합니다.

파이프라인 이슈를 해결할 수 없으면 다음에서 도움을 받을 수 있습니다:

- [GitLab 커뮤니티 포럼](https://forum.gitlab.com/)
- GitLab [지원](https://support.gitlab.com/)

특정 CI/CD 기능에 관련된 이슈가 발생하면 해당 기능의 관련 이슈 해결 섹션을 참조하세요:

- [캐싱](caching/_index.md#troubleshooting)
- [CI/CD 작업 토큰](jobs/ci_job_token.md#troubleshooting)
- [컨테이너 레지스트리](../user/packages/container_registry/troubleshoot_container_registry.md)
- [Docker](docker/docker_build_troubleshooting.md)
- [다운스트림 파이프라인](pipelines/downstream_pipelines_troubleshooting.md)
- [환경](environments/_index.md#troubleshooting)
- [러너](https://docs.gitlab.com/runner/faq/)
- [ID 토큰](secrets/id_token_authentication.md#troubleshooting)
- [작업](jobs/job_troubleshooting.md)
- [작업 아티팩트](jobs/job_artifacts_troubleshooting.md)
- [머지 리퀘스트 파이프라인](pipelines/mr_pipeline_troubleshooting.md) [병합 결과 파이프라인](pipelines/merged_results_pipelines.md#troubleshooting) 및 [머지 트레인](pipelines/merge_trains.md#troubleshooting)
- [파이프라인 편집기](pipeline_editor/_index.md#troubleshooting)
- [CI/CD 변수](variables/variables_troubleshooting.md)
- [YAML `includes` 키워드](yaml/includes.md#troubleshooting)
- [YAML `script` 키워드](yaml/script_troubleshooting.md)

## 디버깅 기법 {#debugging-techniques}

### 구문 확인 {#verify-syntax}

초기 문제 원인은 잘못된 구문일 수 있습니다. 파이프라인에서 `yaml invalid` 배지가 표시되고 구문 또는 형식 문제가 발견되면 실행되지 않습니다.

#### `.gitlab-ci.yml`을 파이프라인 편집기로 편집 {#edit-gitlab-ciyml-with-the-pipeline-editor}

[파이프라인 편집기](pipeline_editor/_index.md)는 권장되는 편집 환경입니다(단일 파일 편집기 또는 Web IDE는 아님). 포함 사항:

- 수락된 키워드만 사용하고 있는지 확인하는 코드 완성 제안
- 자동 구문 강조 표시 및 유효성 검사
- [CI/CD 구성 시각화](pipeline_editor/_index.md#visualize-ci-configuration) - `.gitlab-ci.yml` 파일의 그래픽 표현입니다.

#### `.gitlab-ci.yml`을 로컬로 편집 {#edit-gitlab-ciyml-locally}

파이프라인 구성을 로컬로 편집하려면 편집기의 GitLab CI/CD 스키마를 사용하여 기본 구문 이슈를 확인할 수 있습니다. [Schemastore 지원 편집기](https://www.schemastore.org/)는 기본적으로 GitLab CI/CD 스키마를 사용합니다.

스키마에 직접 연결해야 하는 경우 이 URL을 사용하세요:

```plaintext
https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/assets/javascripts/editor/schema/ci.json
```

CI/CD 스키마에서 다루는 사용자 지정 태그의 전체 목록을 보려면 최신 버전의 스키마를 확인하세요.

#### CI Lint 도구로 구문 확인 {#verify-syntax-with-ci-lint-tool}

[CI Lint 도구](yaml/lint.md)를 사용하여 CI/CD 구성 스니펫의 구문이 올바른지 확인할 수 있습니다. 전체 `.gitlab-ci.yml` 파일 또는 개별 작업 구성을 붙여넣어 기본 구문을 확인합니다.

프로젝트에 `.gitlab-ci.yml` 파일이 있으면 CI Lint 도구를 사용하여 [전체 파이프라인 생성 시뮬레이션](yaml/lint.md#simulate-a-pipeline)할 수도 있습니다. 구성 구문에 대한 더 심층적인 검증을 수행합니다.

### 파이프라인 이름 사용 {#use-pipeline-names}

[`workflow:name`](yaml/_index.md#workflowname)를 사용하여 모든 파이프라인 유형의 이름을 지정하면 파이프라인 목록에서 파이프라인을 더 쉽게 식별할 수 있습니다. 예를 들어:

```yaml
variables:
  PIPELINE_NAME: "Default pipeline name"

workflow:
  name: '$PIPELINE_NAME'
  rules:
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'
      variables:
        PIPELINE_NAME: "Merge request pipeline"
    - if: '$CI_PIPELINE_SOURCE == "schedule" && $PIPELINE_SCHEDULE_TYPE == "hourly_deploy"'
      variables:
        PIPELINE_NAME: "Hourly deployment pipeline"
    - if: '$CI_PIPELINE_SOURCE == "schedule"'
      variables:
        PIPELINE_NAME: "Other scheduled pipeline"
    - if: '$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH'
      variables:
        PIPELINE_NAME: "Default branch pipeline"
    - if: '$CI_COMMIT_BRANCH =~ /^\d{1,2}\.\d{1,2}-stable$/'
      variables:
        PIPELINE_NAME: "Stable branch pipeline"
```

### CI/CD 변수 {#cicd-variables}

#### 변수 확인 {#verify-variables}

CI/CD 문제 해결의 핵심은 파이프라인에 어떤 변수가 있는지, 그 값이 무엇인지 확인하는 것입니다. 많은 파이프라인 구성이 변수에 종속되어 있으며, 변수를 확인하는 것은 문제의 원인을 찾는 가장 빠른 방법 중 하나입니다.

[변수의 전체 목록 내보내기](variables/variables_troubleshooting.md#list-all-variables) \- 각 문제 있는 작업에서 사용 가능합니다. 예상되는 변수가 있는지 확인하고 해당 값이 예상한 대로인지 확인하세요.

#### CLI 명령에 플래그를 추가하려면 변수를 사용 {#use-variables-to-add-flags-to-cli-commands}

표준 파이프라인 실행에서는 사용되지 않지만 필요에 따라 디버깅에 사용할 수 있는 CI/CD 변수를 정의할 수 있습니다. 다음 예와 같은 변수를 추가하면 [파이프라인](pipelines/_index.md#run-a-pipeline-manually) 또는 [개별 작업](jobs/job_control.md#run-a-manual-job)의 수동 실행 중에 추가하여 명령의 동작을 수정할 수 있습니다. 예를 들어:

```yaml
my-flaky-job:
  variables:
    DEBUG_VARS: ""
  script:
    - my-test-command $DEBUG_VARS /test-dirs
```

이 예에서 `DEBUG_VARS`은 표준 파이프라인에서는 기본적으로 비어 있습니다. 작업의 동작을 디버깅해야 하면 파이프라인을 수동으로 실행하고 `DEBUG_VARS`을 `--verbose`로 설정하면 추가 출력을 얻을 수 있습니다.

### 종속성 {#dependencies}

종속성 관련 이슈는 파이프라인의 예기치 않은 이슈의 또 다른 일반적인 원인입니다.

#### 종속성 버전 확인 {#verify-dependency-versions}

작업에서 올바른 종속성 버전이 사용되고 있는지 확인하려면 주요 스크립트 명령을 실행하기 전에 출력할 수 있습니다. 예를 들어:

```yaml
job:
  before_script:
    - node --version
    - yarn --version
  script:
    - my-javascript-tests.sh
```

#### 버전 고정 {#pin-versions}

항상 종속성이나 이미지의 최신 버전을 사용하고 싶지만 업데이트에 예기치 않게 주요 변경사항이 포함될 수 있습니다. 예기치 않은 변경사항을 방지하기 위해 주요 종속성 및 이미지를 고정하는 것을 고려하세요. 예를 들어:

```yaml
variables:
  ALPINE_VERSION: '3.18.6'

job1:
  image: alpine:$ALPINE_VERSION  # This will never change unexpectedly
  script:
    - my-test-script.sh

job2:
  image: alpine:latest  # This might suddenly change
  script:
    - my-test-script.sh
```

중요한 보안 업데이트가 있을 수 있으므로 계속해서 종속성 및 이미지 업데이트를 정기적으로 확인해야 합니다. 그런 다음 업데이트된 이미지 또는 종속성이 파이프라인과 계속 작동하는지 확인하는 프로세스의 일부로 버전을 수동으로 업데이트할 수 있습니다.

### 작업 출력 확인 {#verify-job-output}

#### 출력을 상세하게 표시 {#make-output-verbose}

`--silent`을 사용하여 작업 로그의 출력량을 줄이면 작업에서 잘못된 부분을 파악하기 어렵게 할 수 있습니다. 또한 가능하면 `--verbose`를 사용하여 추가 세부 정보를 추가로 제공하는 것을 고려하세요.

```yaml
job1:
  script:
    - my-test-tool --silent         # If this fails, it might be impossible to identify the issue.
    - my-other-test-tool --verbose  # This command will likely be easier to debug.
```

#### 출력 및 보고서를 아티팩트로 저장 {#save-output-and-reports-as-artifacts}

일부 도구는 작업이 실행되는 동안에만 필요한 파일을 생성할 수 있지만, 이러한 파일의 내용은 디버깅에 사용될 수 있습니다. [`artifacts`](yaml/_index.md#artifacts)를 사용하여 나중에 분석하기 위해 저장할 수 있습니다:

```yaml
job1:
  script:
    - my-tool --json-output my-output.json
  artifacts:
    paths:
      - my-output.json
```

[`artifacts:reports`](yaml/artifacts_reports.md)로 구성된 보고서는 기본적으로 다운로드할 수 없지만 디버깅에 도움이 되는 정보를 포함할 수도 있습니다. 이 보고서를 검사할 수 있도록 사용할 수 있게 하려면 같은 기법을 사용하세요:

```yaml
job1:
  script:
    - rspec --format RspecJunitFormatter --out rspec.xml
  artifacts:
    reports:
      junit: rspec.xml
    paths:
      - rspec.xmp
```

> [!warning]
> 토큰, 비밀번호 또는 기타 민감한 정보를 아티팩트에 저장하지 마세요. 파이프라인에 액세스할 수 있는 모든 사용자가 볼 수 있습니다.

### 작업의 명령을 로컬에서 실행 {#run-the-jobs-commands-locally}

[Rancher Desktop](https://rancherdesktop.io/)과 같은 도구 또는 유사한 대안을 사용하여 로컬 머신에서 작업의 컨테이너 이미지를 실행할 수 있습니다. 그런 다음 컨테이너에서 작업의 `script` 명령을 실행하고 동작을 확인합니다.

### 근본 원인 분석으로 실패한 작업 문제 해결 {#troubleshoot-a-failed-job-with-root-cause-analysis}

GitLab Duo 근본 원인 분석을 GitLab Duo Chat에서 사용하여 [실패한 CI/CD 작업 문제 해결](../user/gitlab_duo_chat/examples.md#troubleshoot-failed-cicd-jobs-with-root-cause-analysis)할 수 있습니다.

## 작업 구성 이슈 {#job-configuration-issues}

많은 일반적인 파이프라인 이슈는 `rules` 또는 `only/except` 구성의 동작을 분석하여 [작업이 파이프라인에 추가되는 시기를 제어](jobs/job_control.md)하여 해결할 수 있습니다. 동작이 다르므로 같은 파이프라인에서 이 두 구성을 함께 사용하면 안 됩니다. 이러한 혼합 동작으로 파이프라인이 실행되는 방식을 예측하기 어렵습니다. `rules`는 작업을 제어하기 위한 선호되는 선택이며, `only`와 `except`은 더 이상 적극적으로 개발되지 않습니다.

`rules` 또는 `only/except` 구성이 [사전 정의된 변수](variables/predefined_variables.md)를 사용하는 경우, 예를 들어 `CI_PIPELINE_SOURCE`, `CI_MERGE_REQUEST_ID`인 경우 첫 번째 문제 해결 단계로 [변수 확인](#verify-variables)을 수행해야 합니다.

### 작업 또는 파이프라인이 예상대로 실행되지 않음 {#jobs-or-pipelines-dont-run-when-expected}

`rules` 또는 `only/except` 키워드는 작업이 파이프라인에 추가되는지 여부를 결정합니다. 파이프라인이 실행되지만 작업이 파이프라인에 추가되지 않으면 일반적으로 `rules` 또는 `only/except` 구성 이슈 때문입니다.

파이프라인이 오류 메시지 없이 실행되지 않으면 `rules` 또는 `only/except` 구성이나 `workflow: rules` 키워드 때문일 수도 있습니다.

`only/except`에서 `rules` 키워드로 변환하는 경우 [`rules` 구성 세부 정보](yaml/_index.md#rules)를 주의 깊게 확인해야 합니다. `only/except`와 `rules`의 동작이 다르므로 두 가지 사이를 마이그레이션할 때 예기치 않은 동작이 발생할 수 있습니다.

[`if` 절에 대한 일반적인 `rules`](jobs/job_rules.md#common-if-clauses-with-predefined-variables)는 예상대로 작동하는 규칙을 작성하는 방법의 예를 들기에 매우 유용할 수 있습니다.

파이프라인에 `.pre` 또는 `.post` 스테이지의 작업만 포함되어 있으면 실행되지 않습니다. 다른 스테이지에 최소한 하나의 다른 작업이 있어야 합니다.

### `.gitlab-ci.yml` 파일에 BOM(바이트 순서 표시)이 포함되어 있을 때 예기치 않은 동작 {#unexpected-behavior-when-gitlab-ciyml-file-contains-a-byte-order-mark-bom}

`.gitlab-ci.yml` 파일이나 기타 포함된 구성 파일에 있는 [UTF-8 BOM(바이트 순서 표시)](https://en.wikipedia.org/wiki/Byte_order_mark)은 잘못된 파이프라인 동작으로 이어질 수 있습니다. 바이트 순서 표시는 파일 구문 분석에 영향을 주어 일부 구성을 무시하게 합니다 - 작업이 누락될 수 있으며 변수의 값이 잘못될 수 있습니다. 일부 텍스트 편집기는 BOM 문자를 삽입하도록 구성할 수 있습니다.

파이프라인이 혼란스러운 동작을 하면 BOM 문자의 존재 여부를 표시할 수 있는 도구로 확인할 수 있습니다. 파이프라인 편집기는 문자를 표시할 수 없으므로 외부 도구를 사용해야 합니다. [이슈 354026](https://gitlab.com/gitlab-org/gitlab/-/issues/354026)을 참조하여 자세한 내용을 확인하세요.

### `changes` 키워드가 있는 작업이 예기치 않게 실행됨 {#a-job-with-the-changes-keyword-runs-unexpectedly}

작업이 예기치 않게 파이프라인에 추가되는 일반적인 이유는 `changes` 키워드가 특정 경우에 항상 true로 평가되기 때문입니다. 예를 들어 `changes`는 예약된 파이프라인과 태그에 대한 파이프라인을 포함한 특정 파이프라인 유형에서 항상 true입니다.

`changes` 키워드는 [`only/except`](yaml/deprecated_keywords.md#onlychanges--exceptchanges) 또는 [`rules`](yaml/_index.md#ruleschanges)와 함께 사용됩니다. `changes`을 `if` 섹션의 `rules` 또는 `only/except` 구성과 함께만 사용하여 작업이 브랜치 파이프라인 또는 머지 리퀘스트 파이프라인에만 추가되도록 하는 것이 좋습니다.

### 두 개의 파이프라인이 동시에 실행됨 {#two-pipelines-run-at-the-same-time}

열려 있는 머지 리퀘스트가 연결된 브랜치로 커밋을 푸시할 때 두 개의 파이프라인이 실행될 수 있습니다. 일반적으로 하나의 파이프라인은 머지 리퀘스트 파이프라인이고 다른 하나는 브랜치 파이프라인입니다.

이 상황은 일반적으로 `rules` 구성으로 인해 발생하며 [중복 파이프라인 방지](jobs/job_rules.md#avoid-duplicate-pipelines)하는 방법이 여러 가지 있습니다.

### 파이프라인이 실행되지 않거나 잘못된 유형의 파이프라인이 실행됨 {#no-pipeline-or-the-wrong-type-of-pipeline-runs}

파이프라인이 실행되기 전에 GitLab은 구성의 모든 작업을 평가하고 사용 가능한 모든 파이프라인 유형에 추가하려고 합니다. 평가 끝에 작업이 추가되지 않으면 파이프라인이 실행되지 않습니다.

파이프라인이 실행되지 않으면 모든 작업이 파이프라인에 추가되지 않도록 차단한 `rules` 또는 `only/except`가 있을 가능성이 높습니다.

잘못된 파이프라인 유형이 실행된 경우 `rules` 또는 `only/except` 구성을 확인하여 작업이 올바른 파이프라인 유형에 추가되었는지 확인해야 합니다. 예를 들어 머지 리퀘스트 파이프라인이 실행되지 않으면 작업이 브랜치 파이프라인에 추가되었을 수 있습니다.

[`workflow: rules`](yaml/_index.md#workflow) 구성이 파이프라인을 차단했거나 잘못된 파이프라인 유형을 허용했을 가능성도 있습니다.

풀 미러링을 사용 중이면 [풀 미러링 파이프라인 문제 해결 항목](../user/project/repository/mirror/troubleshooting.md#pull-mirroring-is-not-triggering-pipelines)을 확인할 수 있습니다.

### 많은 작업이 있는 파이프라인이 시작하지 못함 {#pipeline-with-many-jobs-fails-to-start}

인스턴스의 정의된 [CI/CD 한도](../administration/cicd/limits.md#maximum-number-of-jobs-in-a-pipeline)보다 많은 작업이 있는 파이프라인은 시작하지 못합니다.

단일 파이프라인의 작업 수를 줄이려면 `.gitlab-ci.yml` 구성을 더 많은 독립적인 [상위-하위 파이프라인](pipelines/pipeline_architectures.md#parent-child-pipelines)으로 분할할 수 있습니다.

## 파이프라인 경고 {#pipeline-warnings}

파이프라인 구성 경고는 다음 경우에 표시됩니다:

- [CI Lint 도구로 구성 유효성 검사](yaml/lint.md)합니다.
- [파이프라인 수동 실행](pipelines/_index.md#run-a-pipeline-manually)합니다.

### `Job may allow multiple pipelines to run for a single action` 경고 {#job-may-allow-multiple-pipelines-to-run-for-a-single-action-warning}

[`rules`](yaml/_index.md#rules)를 `when` 절과 함께 사용하지만 `if` 절이 없으면 여러 파이프라인이 실행될 수 있습니다. 일반적으로 이는 열려 있는 머지 리퀘스트가 연결된 브랜치로 커밋을 푸시할 때 발생합니다.

[중복 파이프라인 방지](jobs/job_rules.md#avoid-duplicate-pipelines)하려면 [`workflow: rules`](yaml/_index.md#workflow)를 사용하거나 규칙을 다시 작성하여 실행할 수 있는 파이프라인을 제어하세요.

## 파이프라인 오류 {#pipeline-errors}

### 오류: `Identity verification is required in order to run CI jobs` {#error-identity-verification-is-required-in-order-to-run-ci-jobs}

{{< details >}}

- 티어: Free
- 제공 서비스: GitLab.com

{{< /details >}}

GitLab.com의 무료 요금제로 GitLab 호스팅 러너를 사용할 때 `Identity verification is required in order to run CI jobs`라는 오류 메시지가 표시되면 ID 확인을 완료해야 합니다.

이 요구 사항은 무료 컴퓨팅 리소스의 오용을 방지하는 데 도움이 됩니다. 위험 점수에 따라 이메일, 전화번호를 확인하거나 결제 방법을 추가해야 할 수 있습니다. 자세한 내용은 [ID 확인](../security/identity_verification.md)을 참조하세요.

유효성 검사를 완료하려면:

1. 경고 배너에서 **내 계정 인증**을 선택합니다.
1. 메시지가 표시되면 ID 확인 단계를 따릅니다. 전화번호를 확인하거나 결제 방법을 추가하라는 요청을 받을 수 있습니다.
1. 새 커밋을 생성하거나 새 파이프라인을 수동으로 트리거합니다.

또는 다음을 수행할 수 있습니다:

- 유료 요금제로 업그레이드합니다.
- 네임스페이스에 대한 추가 컴퓨팅 분 구매합니다.
- GitLab 호스팅 러너 대신 프로젝트 또는 그룹 러너를 사용합니다.
- 그룹 소유자에게 자체 관리형 러너 설정을 요청합니다.

### `A CI/CD pipeline must run and be successful before merge` 메시지 {#a-cicd-pipeline-must-run-and-be-successful-before-merge-message}

프로젝트에서 [**파이프라인이 성공해야 함**](../user/project/merge_requests/auto_merge.md#require-a-successful-pipeline-for-merge) 설정이 활성화되어 있고 파이프라인이 아직 성공적으로 실행되지 않은 경우에 이 메시지가 표시됩니다. 파이프라인이 아직 생성되지 않았거나 외부 CI 서비스를 기다리고 있는 경우에도 적용됩니다.

프로젝트에 파이프라인을 사용하지 않으면 **파이프라인이 성공해야 함**을 비활성화하여 머지 리퀘스트를 수락할 수 있습니다.

### `Checking ability to merge automatically` 메시지 {#checking-ability-to-merge-automatically-message}

머지 리퀘스트가 몇 분 후에도 사라지지 않는 `Checking ability to merge automatically` 메시지로 고정되어 있으면 다음 중 하나의 해결 방법을 시도할 수 있습니다:

- 머지 리퀘스트 페이지를 새로 고칩니다.
- 머지 리퀘스트를 닫고 다시 엽니다.
- [`/rebase` 빠른 작업](../user/project/quick_actions.md#rebase)으로 머지 리퀘스트를 리베이스합니다.
- 머지 리퀘스트가 병합할 준비가 되었음을 이미 확인한 경우 `/merge` 빠른 작업으로 병합할 수 있습니다.

이 이슈는 GitLab 15.5에서 [해결](https://gitlab.com/gitlab-org/gitlab/-/issues/229352)되었습니다.

### `Checking pipeline status` 메시지 {#checking-pipeline-status-message}

이 메시지는 머지 리퀘스트가 최신 커밋과 연결된 파이프라인이 없을 때 회전하는 상태 아이콘({{< icon name="spinner" >}})과 함께 표시됩니다. 이는 다음 이유 때문일 수 있습니다:

- GitLab이 아직 파이프라인 생성을 완료하지 못했습니다.
- 외부 CI 서비스를 사용 중이며 GitLab이 서비스로부터 아직 응답을 받지 못했습니다.
- 프로젝트에서 CI/CD 파이프라인을 사용하고 있지 않습니다.
- 프로젝트에서 CI/CD 파이프라인을 사용 중이지만 구성이 머지 리퀘스트의 소스 브랜치에서 파이프라인이 실행되지 않도록 방지했습니다.
- 최신 파이프라인이 삭제되었습니다(이는 [알려진 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/214323)입니다).
- 머지 리퀘스트의 소스 브랜치가 프라이빗 포크에 있습니다.

파이프라인이 생성되면 메시지가 파이프라인 상태로 업데이트됩니다.

이러한 경우 중 일부에서 [**파이프라인이 성공해야 함**](../user/project/merge_requests/auto_merge.md#require-a-successful-pipeline-for-merge) 설정이 활성화되어 있으면 메시지가 아이콘이 계속 회전하는 상태로 고정될 수 있습니다. [이슈 334281](https://gitlab.com/gitlab-org/gitlab/-/issues/334281)을 참조하여 자세한 내용을 확인하세요.

### `Project <group/project> not found or access denied` 메시지 {#project-groupproject-not-found-or-access-denied-message}

[`include`](yaml/_index.md#include)로 구성이 추가되고 다음 중 하나인 경우에 이 메시지가 표시됩니다:

- 구성이 찾을 수 없는 프로젝트를 참조합니다.
- 파이프라인을 실행하는 사용자가 포함된 프로젝트에 액세스할 수 없습니다.

이를 해결하려면 다음을 확인하세요:

- 프로젝트의 경로가 `my-group/my-project` 형식이고 리포지토리의 폴더를 포함하지 않습니다.
- 파이프라인을 실행하는 사용자는 포함된 파일을 포함하는 프로젝트의 [구성원](../user/project/members/_index.md#add-users-to-a-project)입니다. 사용자는 같은 프로젝트에서 CI/CD 작업을 실행할 [권한](../user/permissions.md#project-cicd)도 가져야 합니다.

### `The parsed YAML is too big` 메시지 {#the-parsed-yaml-is-too-big-message}

YAML 구성이 너무 크거나 너무 깊게 중첩된 경우 이 메시지가 표시됩니다. 많은 포함을 포함하고 전반적으로 수천 줄이 있는 YAML 파일은 이 메모리 한계에 도달할 가능성이 더 높습니다. 예를 들어 200kb인 YAML 파일은 기본 메모리 한계에 도달할 가능성이 높습니다.

구성 크기를 줄이려면 다음을 수행할 수 있습니다:

- 파이프라인 편집기의 [전체 구성](pipeline_editor/_index.md#view-full-configuration) 탭에서 확장된 CI/CD 구성의 길이를 확인합니다. 제거하거나 단순화할 수 있는 중복된 구성을 찾습니다.
- 긴 또는 반복되는 `script` 섹션을 프로젝트의 독립형 스크립트로 이동합니다.
- [상위 및 하위 파이프라인](pipelines/downstream_pipelines.md#parent-child-pipelines)을 사용하여 일부 작업을 독립적인 하위 파이프라인의 작업으로 이동합니다.

GitLab Self-Managed에서 [크기 한계를 증가](../administration/cicd/limits.md#maximum-size-and-depth-of-cicd-configuration-yaml-files)할 수 있습니다.

### `500` 오류 - `.gitlab-ci.yml` 파일 편집 {#500-error-when-editing-the-gitlab-ciyml-file}

포함된 구성 파일의 루프는 [웹 편집기](../user/project/repository/web_editor.md)로 `.gitlab-ci.yml` 파일을 편집할 때 `500` 오류를 발생시킬 수 있습니다.

포함된 구성 파일이 서로에 대한 참조 루프를 생성하지 않도록 하세요.

### `Failed to pull image` 메시지 {#failed-to-pull-image-messages}

{{< history >}}

- GitLab 16.3에서 **CI_JOB_TOKEN을 사용하여 이 프로젝트 액세스 허용** 설정이 [**이 프로젝트 액세스 제한**](https://gitlab.com/gitlab-org/gitlab/-/issues/411406)으로 이름 변경되었습니다.

{{< /history >}}

러너는 CI/CD 작업에서 컨테이너 이미지를 가져오려고 할 때 `Failed to pull image` 메시지를 반환할 수 있습니다.

러너는 [CI/CD 작업 토큰](jobs/ci_job_token.md)으로 인증하여 [`image`](yaml/_index.md#image)로 정의된 컨테이너 이미지를 다른 프로젝트의 컨테이너 레지스트리에서 가져옵니다.

작업 토큰 설정이 다른 프로젝트의 컨테이너 레지스트리에 대한 액세스를 방지하면 러너는 오류 메시지를 반환합니다.

예를 들어:

- ```plaintext
  WARNING: Failed to pull image with policy "always": Error response from daemon: pull access denied for registry.example.com/path/to/project, repository does not exist or may require 'docker login': denied: requested access to the resource is denied
  ```

- ```plaintext
  WARNING: Failed to pull image with policy "": image pull failed: rpc error: code = Unknown desc = failed to pull and unpack image "registry.example.com/path/to/project/image:v1.2.3": failed to resolve reference "registry.example.com/path/to/project/image:v1.2.3": pull access denied, repository does not exist or may require authorization: server message: insufficient_scope: authorization failed
  ```

다음이 모두 참인 경우 이러한 오류가 발생할 수 있습니다:

- [**Limit access to this project**](jobs/ci_job_token.md#limit-job-token-scope-for-public-or-internal-projects) 옵션이 이미지를 호스팅하는 프라이빗 프로젝트에서 활성화되어 있습니다.
- 이미지를 가져오려는 작업이 프라이빗 프로젝트의 허용 목록에 나열되지 않은 프로젝트에서 실행 중입니다.

이 이슈를 해결하려면 컨테이너 레지스트리에서 이미지를 가져오는 CI/CD 작업이 있는 프로젝트를 대상 프로젝트의 [작업 토큰 허용 목록](jobs/ci_job_token.md#add-a-group-or-project-to-the-job-token-allowlist)에 추가하세요.

이러한 오류는 [프로젝트 액세스 토큰](../user/project/settings/project_access_tokens.md)을 사용하여 다른 프로젝트의 이미지에 액세스하려고 할 때도 발생할 수 있습니다. 프로젝트 액세스 토큰은 하나의 프로젝트로만 범위가 지정되어 있으므로 다른 프로젝트의 이미지에 액세스할 수 없습니다. 범위가 더 넓은 [다른 토큰 유형](../security/tokens/_index.md)을 사용해야 합니다.

#### 임의 또는 간헐적 `Failed to pull image` 오류 {#random-or-intermittent-failed-to-pull-image-errors}

CI/CD 작업에서 간헐적인 `Failed to pull image` 오류가 발생할 수 있습니다.

이 이슈는 사용자가 이미지에 액세스할 수 있는 권한이 다르고 러너가 해당 이미지를 캐시하는 방식과 함께 발생할 수 있습니다. 봇 사용자는 다른 프로젝트 구성원보다 권한이 다르기 때문에 일반적으로 영향을 받습니다.

예를 들어 파이프라인 이미지가 다른 프로젝트의 컨테이너 레지스트리에서 호스팅될 수 있습니다. 모든 사용자가 두 프로젝트에 모두 액세스할 수 있으면 문제가 아닙니다. 그러나 사용자(봇 사용자 등)가 이미지를 호스팅하는 프로젝트에 액세스할 수 없으면 `Failed to pull image` 오류가 발생할 수 있습니다.

러너가 성공적으로 이미지를 가져와 이미지에 액세스할 수 있는 권한이 있는 사용자를 위해 캐시할 때 오류가 간헐적이 됩니다. 이제 러너가 사용 가능한 이미지를 가지고 있으므로 다른 프로젝트에 액세스하여 이미지를 가져올 필요가 없습니다. 다른 프로젝트에 액세스할 수 없는 사용자를 포함한 모든 사용자는 이 이미지로 CI/CD 작업을 실행할 수 있습니다. 그러나 러너가 이미지를 가져와서 캐시한 적이 없으면 이미지 프로젝트에 액세스할 권한이 없는 사용자는 `Failed to pull image` 오류를 얻습니다.

이 이슈를 해결하려면 파이프라인을 실행하는 모든 사용자(봇 사용자 포함)가 가져온 이미지를 호스팅하는 프로젝트에 액세스할 수 있는지 확인하세요.

### `Something went wrong on our end` 메시지 또는 파이프라인 실행 중 `500` 오류 {#something-went-wrong-on-our-end-message-or-500-error-when-running-a-pipeline}

다음 파이프라인 오류가 수신될 수 있습니다:

- 머지 리퀘스트를 푸시하거나 생성할 때 `Something went wrong on our end` 메시지입니다.
- API를 사용하여 파이프라인을 트리거할 때 `500` 오류입니다.

프로젝트를 가져온 후 내부 ID 레코드가 동기화되지 않으면 이러한 오류가 발생할 수 있습니다.

이를 해결하려면 [이슈 352382의 해결 방법](https://gitlab.com/gitlab-org/gitlab/-/issues/352382#workaround)을 참조하세요.

### `config should be an array of hashes` 오류 메시지 {#config-should-be-an-array-of-hashes-error-message}

배열에서 여러 [`!reference` 태그](yaml/yaml_optimization.md#reference-tags)를 사용할 때 다음과 같은 오류가 표시될 수 있습니다:

```plaintext
This GitLab CI configuration is invalid: jobs:my_job_name:parallel:matrix config should be an array of hashes.
```

`script`, `rules` 및 `stages` 키워드는 여러 참조 태그를 사용할 수 있지만 배열을 예상하는 다른 키워드는 그렇지 않습니다. [이 제한을 해결하려면 중첩을 사용](https://gitlab.com/gitlab-org/gitlab/-/issues/439828#note_1918858137)하거나 [YAML 앵커](yaml/yaml_optimization.md#anchors)를 대신 사용할 수 있습니다.

### 오류: `jobs:<job-name> config should contain either a trigger or a needs:pipeline.` {#error-jobsjob-name-config-should-contain-either-a-trigger-or-a-needspipeline}

이 오류는 `.gitlab-ci.yml`의 작업이 `needs` 키워드를 사용하지만 `script:` 또는 `trigger:` 키워드를 사용하지 않을 때 발생할 수 있습니다.

모든 작업은 `script` 또는 `trigger` 키워드 중 하나를 사용해야 하므로 둘 다 사용하지 않는 작업에 적절한 키워드를 추가하세요.

### 오류: `config contains unknown keys: <key-name>` {#error-config-contains-unknown-keys-key-name}

`<keyword> config contains unknown keys: <key-name>`과 유사한 오류가 수신될 수 있습니다.

이 오류 메시지는 여러 이슈로 인해 발생할 수 있습니다:

- 키워드의 오타(예: `imag` - 잘못됨 대신 `image` \- 올바름).
- 키워드 또는 작업의 잘못된 공백 또는 들여쓰기.

예를 들어:

```yaml
test-job:
  artifacts:
    path:        # This is a typo, it should be `paths`
      - test
    image: test  # This indentation is incorrect, it should be at the same level as `script`.
  script:
    - echo
```
