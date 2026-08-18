---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "시간 제한 설정, 민감한 정보 보호, 태그 및 변수로 동작 제어, GitLab 러너의 아티팩트 및 캐시 설정 구성"
title: 러너 구성
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 문서에서는 GitLab UI에서 러너를 구성하는 방법을 설명합니다.

러너을 설치한 머신에서 러너를 구성해야 하는 경우 [러너r 설명서](https://docs.gitlab.com/runner/configuration/)를 참조하세요.

## 최대 작업 시간 초과 설정 {#set-the-maximum-job-timeout}

각 러너의 최대 작업 시간 초과를 지정하여 더 긴 작업 시간 초과를 가진 프로젝트가 러너를 사용하지 못하도록 할 수 있습니다. 최대 작업 시간 초과는 프로젝트에 정의된 작업 시간 초과보다 짧으면 사용됩니다.

러너의 최대 시간 초과를 설정하려면 REST API 엔드포인트 [`PUT /runners/:id`](../../api/runners.md#update-runners-details)에서 `maximum_timeout` 매개 변수를 설정합니다.

### 인스턴스 러너의 경우 {#for-an-instance-runner}

전제 조건:

- 관리자(administrator) 권한이 있어야 합니다.

GitLab Self-Managed에서 인스턴스 러너의 작업 시간 초과를 재정의할 수 있습니다.

GitLab.com에서는 GitLab 호스팅 인스턴스 러너의 작업 시간 초과를 재정의할 수 없으며 대신 [프로젝트 정의 시간 초과](../pipelines/settings.md#set-a-limit-for-how-long-jobs-can-run)를 사용해야 합니다.

최대 작업 시간 초과를 설정하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **CI/CD** > **러너**를 선택합니다.
1. 편집하려는 러너의 오른쪽에서 **편집** ({{< icon name="pencil" >}})을 선택합니다.
1. **최대 작업 시간 초과** 필드에 값을 초 단위로 입력합니다. 최소값은 600초(10분)입니다.
1. **변경사항 저장**을 선택합니다.

### 그룹 러너의 경우 {#for-a-group-runner}

전제 조건:

- 그룹의 Owner 역할이 있어야 합니다.

최대 작업 시간 초과를 설정하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **빌드** > **러너**를 선택합니다.
1. 편집하려는 러너의 오른쪽에서 **편집** ({{< icon name="pencil" >}})을 선택합니다.
1. **최대 작업 시간 초과** 필드에 값을 초 단위로 입력합니다. 최소값은 600초(10분)입니다.
1. **변경사항 저장**을 선택합니다.

### 프로젝트 러너의 경우 {#for-a-project-runner}

전제 조건:

- 프로젝트에 대해 Owner 역할이 필요합니다.

최대 작업 시간 초과를 설정하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **CI/CD**를 선택합니다.
1. **러너**를 확장합니다.
1. 편집하려는 러너의 오른쪽에서 **편집** ({{< icon name="pencil" >}})을 선택합니다.
1. **최대 작업 시간 초과** 필드에 값을 초 단위로 입력합니다. 최소값은 600초(10분)입니다. 정의되지 않은 경우 [프로젝트의 작업 시간 초과](../pipelines/settings.md#set-a-limit-for-how-long-jobs-can-run)가 대신 사용됩니다.
1. **변경사항 저장**을 선택합니다.

## 최대 작업 시간 초과가 작동하는 방식 {#how-maximum-job-timeout-works}

**예시 1 - Runner timeout bigger than project timeout**

1. 러너의 `maximum_timeout` 매개 변수를 24시간으로 설정합니다.
1. 프로젝트의 **최대 작업 시간 초과**를 **2 hours**으로 설정합니다.
1. 작업을 시작합니다.
1. 더 오래 실행되는 경우 작업이 **2 hours** 후 시간 초과됩니다.

**예시 2 - Runner timeout not configured**

1. 러너에서 `maximum_timeout` 매개 변수 구성을 제거합니다.
1. 프로젝트의 **최대 작업 시간 초과**를 **2 hours**으로 설정합니다.
1. 작업을 시작합니다.
1. 더 오래 실행되는 경우 작업이 **2 hours** 후 시간 초과됩니다.

**예시 3 - Runner timeout smaller than project timeout**

1. 러너의 `maximum_timeout` 매개 변수를 **30 minutes**으로 설정합니다.
1. 프로젝트의 **최대 작업 시간 초과**를 2시간으로 설정합니다.
1. 작업을 시작합니다.
1. 더 오래 실행되는 경우 작업이 **30 minutes** 후 시간 초과됩니다.

## `script` 및 `after_script` 시간 초과 설정 {#set-script-and-after_script-timeouts}

{{< history >}}

- GitLab Runner 16.4에서 [도입되었습니다](https://gitlab.com/gitlab-org/gitlab-runner/-/merge_requests/4335).

{{< /history >}}

`script` 및 `after_script`가 종료되기 전에 실행되는 시간을 제어하려면 `.gitlab-ci.yml` 파일에서 시간 초과 값을 지정합니다.

예를 들어, 장시간 실행되는 `script`을 조기에 종료하기 위해 시간 초과를 지정할 수 있습니다. 이를 통해 아티팩트와 캐시를 [작업 시간 초과](../pipelines/settings.md#set-a-limit-for-how-long-jobs-can-run)가 초과되기 전에 업로드할 수 있습니다. `script` 및 `after_script`의 시간 초과 값은 작업 시간 초과보다 작아야 합니다.

- `script`의 시간 초과를 설정하려면 작업 변수 `RUNNER_SCRIPT_TIMEOUT`를 사용합니다.
- `after_script`의 시간 초과를 설정하고 기본값인 5분을 재정의하려면 작업 변수 `RUNNER_AFTER_SCRIPT_TIMEOUT`를 사용합니다.

이 두 변수는 [Go의 기간 형식](https://pkg.go.dev/time#ParseDuration)을 허용합니다(예: `40s`, `1h20m`, `2h` `4h30m30s`).

예를 들어:

```yaml
job-with-script-timeouts:
  variables:
    RUNNER_SCRIPT_TIMEOUT: 15m
    RUNNER_AFTER_SCRIPT_TIMEOUT: 10m
  script:
    - "I am allowed to run for min(15m, remaining job timeout)."
  after_script:
    - "I am allowed to run for min(10m, remaining job timeout)."

job-artifact-upload-on-timeout:
  timeout: 1h                           # set job timeout to 1 hour
  variables:
     RUNNER_SCRIPT_TIMEOUT: 50m         # only allow script to run for 50 minutes
  script:
    - long-running-process > output.txt # will be terminated after 50m

  artifacts: # artifacts will have roughly ~10m to upload
    paths:
      - output.txt
    when: on_failure # on_failure because script termination after a timeout is treated as a failure
```

### `after_script` 실행 보장 {#ensuring-after_script-execution}

`after_script`이 성공적으로 실행되려면 `RUNNER_SCRIPT_TIMEOUT` + `RUNNER_AFTER_SCRIPT_TIMEOUT`의 합계가 작업의 구성된 시간 초과를 초과하지 않아야 합니다.

다음 예시는 주 스크립트가 시간 초과되더라도 `after_script`이 실행되도록 시간 초과를 구성하는 방법을 보여줍니다:

```yaml
job-with-script-timeouts:
  timeout: 5m
  variables:
    RUNNER_SCRIPT_TIMEOUT: 1m
    RUNNER_AFTER_SCRIPT_TIMEOUT: 1m
  script:
    - echo "Starting build..."
    - sleep 120 # Wait 2 minutes to trigger timeout. Script aborts after 1 minute due to RUNNER_SCRIPT_TIMEOUT.
    - echo "Build finished."
  after_script:
    - echo "Starting Clean-up..."
    - sleep 15 # Wait just a few seconds. Runs successfully because it's within RUNNER_AFTER_SCRIPT_TIMEOUT.
    - echo "Clean-up finished."
```

`script`은 `RUNNER_SCRIPT_TIMEOUT`로 인해 취소되지만, `after_script`은 15초가 걸리므로 성공적으로 실행되며, 이는 `RUNNER_AFTER_SCRIPT_TIMEOUT` 및 작업의 `timeout` 값 모두보다 작습니다.

## 민감한 정보 보호 {#protecting-sensitive-information}

인스턴스 러너는 기본적으로 GitLab 인스턴스의 모든 그룹 및 프로젝트에서 사용할 수 있으므로 인스턴스 러너 사용 시 보안 위험이 더 큽니다. 러너 실행기와 파일 시스템 구성은 보안에 영향을 미칩니다. 러너 호스트 환경에 접근할 수 있는 사용자는 러너가 실행한 코드와 러너 인증을 볼 수 있습니다. 예를 들어 러너 인증 토큰에 접근할 수 있는 사용자는 러너를 복제하고 벡터 공격에서 거짓 작업을 제출할 수 있습니다. 자세한 내용은 [보안 고려 사항](https://docs.gitlab.com/runner/security/)을 참조하세요.

## 롱 폴링 구성 {#configuring-long-polling}

작업 큐 대기 시간과 GitLab 서버의 부하를 줄이려면 [롱 폴링](long_polling.md)을 구성합니다.

## 포크된 프로젝트에서 인스턴스 러너 사용 {#using-instance-runners-in-forked-projects}

프로젝트가 포크되면 작업 관련 작업 설정이 복사됩니다. 프로젝트에 인스턴스 러너를 구성했고 사용자가 해당 프로젝트를 포크하면 인스턴스 러너가 이 프로젝트의 작업을 수행합니다.

[알려진 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/364303)로 인해 포크된 프로젝트의 러너 설정이 새 프로젝트 네임스페이스와 일치하지 않으면 다음 메시지가 표시됩니다: `An error occurred while forking the project. Please try again.`.

이 이슈를 해결하려면 포크된 프로젝트와 새 네임스페이스에서 인스턴스 러너 설정이 일관성 있게 적용되는지 확인합니다.

- 인스턴스 러너가 포크된 프로젝트에서 **사용**되면 새 네임스페이스에서도 **사용**되어야 합니다.
- 인스턴스 러너가 포크된 프로젝트에서 **사용 안 함**되면 새 네임스페이스에서도 **사용 안 함**되어야 합니다.

## 프로젝트의 러너 등록 토큰 재설정(더 이상 사용되지 않음) {#reset-the-runner-registration-token-for-a-project-deprecated}

> [!warning]
> 러너 등록 토큰을 전달하는 옵션 및 특정 구성 인수에 대한 지원은 레거시로 간주되며 권장되지 않습니다. [러너 생성 워크플로우](https://docs.gitlab.com/runner/register/#register-with-a-runner-authentication-token)를 사용하여 러너를 등록하기 위한 인증 토큰을 생성합니다. 이 프로세스는 러너 소유권의 완전한 추적성을 제공하고 러너 플릿의 보안을 향상시킵니다. 자세한 내용은 [새 러너 등록 워크플로우로 마이그레이션](new_creation_workflow.md)을 참조하세요.

프로젝트의 등록 토큰이 노출되었다고 생각하면 이를 재설정해야 합니다. 등록 토큰을 사용하여 프로젝트의 다른 러너를 등록할 수 있습니다. 이 새 러너를 사용하여 비밀 변수의 값을 얻거나 프로젝트 코드를 복제할 수 있습니다.

등록 토큰을 재설정하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **CI/CD**를 선택합니다.
1. **러너**를 확장합니다.
1. **New project runner**의 오른쪽에서 세로 줄임표({{< icon name="ellipsis_v" >}})를 선택합니다.
1. **등록 토큰 재설정**을 선택합니다.
1. **토큰 재설정**을 선택합니다.

등록 토큰을 재설정한 후에는 더 이상 유효하지 않으며 프로젝트에 새 러너를 등록하지 않습니다. 프로비저닝 및 등록 새 값에 사용하는 도구에서 등록 토큰도 업데이트해야 합니다.

## 인증 토큰 보안 {#authentication-token-security}

{{< history >}}

- GitLab 15.3에서 [도입되었으며](https://gitlab.com/gitlab-org/gitlab/-/issues/30942) [플래그](../../administration/feature_flags/_index.md)의 이름은 `enforce_runner_token_expires_at`입니다. 기본적으로 비활성화되어 있습니다.
- GitLab 15.5에서 [일반적으로 사용 가능합니다](https://gitlab.com/gitlab-org/gitlab/-/issues/377902). 기능 플래그 `enforce_runner_token_expires_at`이 제거되었습니다.

{{< /history >}}

각 러너는 GitLab 인스턴스에 연결하고 인증하기 위해 [러너 인증 토큰](../../api/runners.md#registration-and-authentication-tokens)을 사용합니다.

토큰이 손상되는 것을 방지하기 위해 토큰을 지정된 간격으로 자동으로 회전하도록 할 수 있습니다. 토큰이 회전될 때 러너의 상태(`online` 또는 `offline`)와 관계없이 각 러너에 대해 업데이트됩니다.

수동 개입이 필요하지 않으며 실행 중인 작업은 영향을 받지 않습니다. 토큰 회전에 대한 자세한 내용은 [회전 시 러너 인증 토큰이 업데이트되지 않음](new_creation_workflow.md#runner-authentication-token-does-not-update-when-rotated)을 참조하세요.

러너 인증 토큰을 수동으로 업데이트해야 하는 경우 명령을 실행하여 [토큰을 재설정](https://docs.gitlab.com/runner/commands/#gitlab-runner-reset-token)할 수 있습니다.

### 러너 구성 인증 토큰 재설정 {#reset-the-runner-configuration-authentication-token}

러너의 인증 토큰이 노출된 경우 공격자가 이를 사용하여 [러너를 복제](https://docs.gitlab.com/runner/security/#cloning-a-runner)할 수 있습니다.

러너 구성 인증 토큰을 재설정하려면:

1. 러너를 삭제합니다:
   - [인스턴스 러너 삭제](runners_scope.md#delete-instance-runners).
   - [그룹 러너 삭제](runners_scope.md#delete-a-group-runner).
   - [프로젝트 러너 삭제](runners_scope.md#delete-a-project-runner).
1. 새 러너 인증 토큰이 할당되도록 새 러너를 생성합니다:
   - [인스턴스 러너 생성](runners_scope.md#create-an-instance-runner-with-a-runner-authentication-token).
   - [그룹 러너 생성](runners_scope.md#create-a-group-runner-with-a-runner-authentication-token).
   - [프로젝트 러너 생성](runners_scope.md#create-a-project-runner-with-a-runner-authentication-token).
1. 선택 사항. 이전 러너 인증 토큰이 폐지되었는지 확인하려면 [러너 API](../../api/runners.md#verify-authentication-for-a-registered-runner)를 사용합니다.

러너 구성 인증 토큰을 재설정하려면 [러너 API](../../api/runners.md)를 사용할 수도 있습니다.

### 러너 인증 토큰 자동 회전 {#automatically-rotate-runner-authentication-tokens}

러너 인증 토큰을 회전할 간격을 지정할 수 있습니다. 러너 인증 토큰을 정기적으로 회전하면 손상된 토큰을 통한 GitLab 인스턴스에 대한 무단 접근 위험을 최소화합니다.

전제 조건:

- 러너는 [GitLab Runner 15.3 이상](https://docs.gitlab.com/runner/#gitlab-runner-versions)을 사용해야 합니다.
- 관리자(administrator) 권한이 있어야 합니다.

러너 인증 토큰을 자동으로 회전하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **CI/CD**를 선택합니다.
1. **지속적 통합 및 배포**를 확장합니다.
1. 러너에 대해 **Runners expiration** 시간을 설정하고, 만료 없음으로 비워두세요.
1. **변경사항 저장**을 선택합니다.

간격이 만료되기 전에 러너는 자동으로 새 러너 인증 토큰을 요청합니다. 토큰 회전에 대한 자세한 내용은 [회전 시 러너 인증 토큰이 업데이트되지 않음](new_creation_workflow.md#runner-authentication-token-does-not-update-when-rotated)을 참조하세요.

## 러너가 민감한 정보를 노출하지 않도록 방지 {#prevent-runners-from-revealing-sensitive-information}

러너가 민감한 정보를 노출하지 않도록 하려면 [보호된 브랜치](../../user/project/repository/branches/protected.md)에서만 작업을 실행하거나 [보호된 태그](../../user/project/protected_tags.md)가 있는 작업을 실행하도록 구성할 수 있습니다.

보호된 브랜치에서 작업을 실행하도록 구성된 러너는 [머지 리퀘스트 파이프라인에서 선택적으로 작업을 실행](../pipelines/merge_request_pipelines.md#control-access-to-protected-variables-and-runners)할 수 있습니다.

### 인스턴스 러너의 경우 {#for-an-instance-runner-1}

전제 조건:

- 관리자(administrator) 권한이 있어야 합니다.

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **CI/CD** > **러너**를 선택합니다.
1. 보호하려는 러너의 오른쪽에서 **편집** ({{< icon name="pencil" >}})을 선택합니다.
1. **보호됨** 체크박스를 선택합니다.
1. **변경사항 저장**을 선택합니다.

### 그룹 러너의 경우 {#for-a-group-runner-1}

전제 조건:

- 그룹의 Owner 역할이 있어야 합니다.

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **빌드** > **러너**를 선택합니다.
1. 보호하려는 러너의 오른쪽에서 **편집** ({{< icon name="pencil" >}})을 선택합니다.
1. **보호됨** 체크박스를 선택합니다.
1. **변경사항 저장**을 선택합니다.

### 프로젝트 러너의 경우 {#for-a-project-runner-1}

전제 조건:

- 프로젝트에 대해 Owner 역할이 필요합니다.

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **CI/CD**를 선택합니다.
1. **러너**를 확장합니다.
1. 보호하려는 러너의 오른쪽에서 **편집** ({{< icon name="pencil" >}})을 선택합니다.
1. **보호됨** 체크박스를 선택합니다.
1. **변경사항 저장**을 선택합니다.

## 러너가 실행할 수 있는 작업 제어 {#control-jobs-that-a-runner-can-run}

[태그](../yaml/_index.md#tags)를 사용하여 러너가 실행할 수 있는 작업을 제어할 수 있습니다. 예를 들어 Rails 테스트 스위트를 실행하는 데 필요한 종속성이 있는 러너에 대해 `rails` 태그를 지정할 수 있습니다.

GitLab CI/CD 태그는 Git 태그와 다릅니다. GitLab CI/CD 태그는 러너와 연결됩니다. Git 태그는 커밋과 연결됩니다.

### 인스턴스 러너의 경우 {#for-an-instance-runner-2}

전제 조건:

- 관리자(administrator) 권한이 있어야 합니다.

인스턴스 러너가 실행할 수 있는 작업을 제어하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **CI/CD** > **러너**를 선택합니다.
1. 편집하려는 러너의 오른쪽에서 **편집** ({{< icon name="pencil" >}})을 선택합니다.
1. 러너를 태그가 있거나 없는 작업으로 실행하도록 설정합니다:
   - 태그가 있는 작업을 실행하려면 **태그** 필드에 쉼표로 구분된 작업 태그를 입력합니다. 예를 들어 `macos`, `rails`.
   - 태그가 없는 작업을 실행하려면 **태그없는 작업 실행** 체크박스를 선택합니다.
1. **변경사항 저장**을 선택합니다.

### 그룹 러너의 경우 {#for-a-group-runner-2}

전제 조건:

- 그룹의 Owner 역할이 있어야 합니다.

그룹 러너가 실행할 수 있는 작업을 제어하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **빌드** > **러너**를 선택합니다.
1. 편집하려는 러너의 오른쪽에서 **편집** ({{< icon name="pencil" >}})을 선택합니다.
1. 러너를 태그가 있거나 없는 작업으로 실행하도록 설정합니다:
   - 태그가 있는 작업을 실행하려면 **태그** 필드에 쉼표로 구분된 작업 태그를 입력합니다. 예를 들어 `macos`, `ruby`.
   - 태그가 없는 작업을 실행하려면 **태그없는 작업 실행** 체크박스를 선택합니다.
1. **변경사항 저장**을 선택합니다.

### 프로젝트 러너의 경우 {#for-a-project-runner-2}

전제 조건:

- 프로젝트에 대해 Owner 역할이 필요합니다.

프로젝트 러너가 실행할 수 있는 작업을 제어하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **CI/CD**를 선택합니다.
1. **러너**를 확장합니다.
1. 편집하려는 러너의 오른쪽에서 **편집** ({{< icon name="pencil" >}})을 선택합니다.
1. 러너를 태그가 있거나 없는 작업으로 실행하도록 설정합니다:
   - 태그가 있는 작업을 실행하려면 **태그** 필드에 쉼표로 구분된 작업 태그를 입력합니다. 예를 들어 `macos`, `ruby`.
   - 태그가 없는 작업을 실행하려면 **태그없는 작업 실행** 체크박스를 선택합니다.
1. **변경사항 저장**을 선택합니다.

### 러너가 태그를 사용하는 방식 {#how-the-runner-uses-tags}

#### 러너는 태그가 있는 작업만 실행 {#runner-runs-only-tagged-jobs}

다음 예시는 러너가 태그가 있는 작업만 실행하도록 설정된 경우의 잠재적 영향을 보여줍니다.

예시 1:

1. 러너는 태그가 있는 작업만 실행하도록 구성되었으며 `docker` 태그가 있습니다.
1. `hello` 태그가 있는 작업이 실행되고 중단됩니다.

예시 2:

1. 러너는 태그가 있는 작업만 실행하도록 구성되었으며 `docker` 태그가 있습니다.
1. `docker` 태그가 있는 작업이 실행되고 실행됩니다.

예시 3:

1. 러너는 태그가 있는 작업만 실행하도록 구성되었으며 `docker` 태그가 있습니다.
1. 태그가 정의되지 않은 작업이 실행되고 중단됩니다.

#### 러너는 태그가 없는 작업을 실행할 수 있음 {#runner-is-allowed-to-run-untagged-jobs}

다음 예시는 러너가 태그가 있거나 없는 작업을 실행하도록 설정된 경우의 잠재적 영향을 보여줍니다.

예시 1:

1. 러너는 태그가 없는 작업을 실행하도록 구성되었으며 `docker` 태그가 있습니다.
1. 태그가 정의되지 않은 작업이 실행되고 실행됩니다.
1. `docker` 태그가 정의된 두 번째 작업이 실행되고 실행됩니다.

예시 2:

1. 러너는 태그가 없는 작업을 실행하도록 구성되었으며 정의된 태그가 없습니다.
1. 태그가 정의되지 않은 작업이 실행되고 실행됩니다.
1. `docker` 태그가 정의된 두 번째 작업이 중단됩니다.

#### 러너와 작업에 여러 태그가 있음 {#a-runner-and-a-job-have-multiple-tags}

작업과 러너를 일치시키는 선택 로직은 작업에 정의된 `tags` 목록을 기반으로 합니다.

다음 예시는 러너와 작업이 여러 태그를 가질 때의 영향을 보여줍니다. 러너가 작업을 실행하도록 선택되려면 작업 스크립트 블록에 정의된 모든 태그를 가져야 합니다.

예시 1:

1. 러너는 `[docker, shell, gpu]` 태그로 구성됩니다.
1. 작업에 `[docker, shell, gpu]` 태그가 있으며 실행되고 실행됩니다.

예시 2:

1. 러너는 `[docker, shell, gpu]` 태그로 구성됩니다.
1. 작업에 `[docker, shell,]` 태그가 있으며 실행되고 실행됩니다.

예시 3:

1. 러너는 `[docker, shell]` 태그로 구성됩니다.
1. 작업에 `[docker, shell, gpu]` 태그가 있으며 실행되지 않습니다.

### 다양한 플랫폼에서 작업을 실행하기 위해 태그 사용 {#use-tags-to-run-jobs-on-different-platforms}

태그를 사용하여 다양한 플랫폼에서 다양한 작업을 실행할 수 있습니다. 예를 들어 `osx` 태그가 있는 OS X 러너와 `windows` 태그가 있는 Windows 러너가 있으면 각 플랫폼에서 작업을 실행할 수 있습니다.

`.gitlab-ci.yml`에서 `tags` 필드를 업데이트합니다:

```yaml
windows job:
  stage: build
  tags:
    - windows
  script:
    - echo Hello, %USERNAME%!

osx job:
  stage: build
  tags:
    - osx
  script:
    - echo "Hello, $USER!"
```

### 태그에서 CI/CD 변수 사용 {#use-cicd-variables-in-tags}

`.gitlab-ci.yml` 파일에서 [CI/CD 변수](../variables/_index.md)를 `tags`와 함께 사용하여 동적 러너 선택을 합니다:

```yaml
variables:
  KUBERNETES_RUNNER: kubernetes

  job:
    tags:
      - docker
      - $KUBERNETES_RUNNER
    script:
      - echo "Hello runner selector feature"
```

## 변수로 러너 동작 구성 {#configure-runner-behavior-with-variables}

[CI/CD 변수](../variables/_index.md)를 사용하여 전역적으로 또는 개별 작업에 대해 러너 Git 동작을 구성할 수 있습니다:

- [`GIT_STRATEGY`](#git-strategy)
- [`GIT_SUBMODULE_STRATEGY`](#git-submodule-strategy)
- [`GIT_CHECKOUT`](#git-checkout)
- [`GIT_CLEAN_FLAGS`](#git-clean-flags)
- [`GIT_FETCH_EXTRA_FLAGS`](#git-fetch-extra-flags)
- [`GIT_CLONE_EXTRA_FLAGS`](#git-clone-extra-flags)
- [`GIT_SUBMODULE_UPDATE_FLAGS`](#git-submodule-update-flags)
- [`GIT_SUBMODULE_FORCE_HTTPS`](#rewrite-submodule-urls-to-https)
- [`GIT_DEPTH`](#shallow-cloning) (shallow cloning)
- [`GIT_SUBMODULE_DEPTH`](#git-submodule-depth)
- [`GIT_CLONE_PATH`](#custom-build-directories) (사용자 지정 빌드 디렉터리)
- [`TRANSFER_METER_FREQUENCY`](#artifact-and-cache-settings) (아티팩트/캐시 미터 업데이트 빈도)
- [`ARTIFACT_COMPRESSION_LEVEL`](#artifact-and-cache-settings) (아티팩트 아카이버 압축 수준)
- [`CACHE_COMPRESSION_LEVEL`](#artifact-and-cache-settings) (캐시 아카이버 압축 수준)
- [`CACHE_REQUEST_TIMEOUT`](#artifact-and-cache-settings) (캐시 요청 시간 초과)
- [`RUNNER_SCRIPT_TIMEOUT`](#set-script-and-after_script-timeouts)
- [`RUNNER_AFTER_SCRIPT_TIMEOUT`](#set-script-and-after_script-timeouts)
- [`AFTER_SCRIPT_IGNORE_ERRORS`](#ignore-errors-in-after_script)

또한 변수를 사용하여 러너가 [작업 실행의 특정 단계를 시도](#job-stages-attempts)하는 횟수를 구성할 수 있습니다.

Kubernetes 실행기를 사용할 때 변수를 사용하여 [요청 및 제한을 위한 Kubernetes CPU 및 메모리 할당을 재정의](https://docs.gitlab.com/runner/executors/kubernetes/#overwrite-container-resources)할 수 있습니다.

[러너 기능 플래그](https://docs.gitlab.com/runner/configuration/feature-flags/#available-feature-flags)는 [작업 및 파이프라인 변수](https://docs.gitlab.com/runner/configuration/feature-flags/#enable-feature-flag-in-pipeline-configuration)로도 허용됩니다.

### Git 전략 {#git-strategy}

`GIT_STRATEGY` 변수는 빌드 디렉터리가 준비되고 리포지토리 콘텐츠가 가져오는 방식을 구성합니다. 이 변수를 [`variables`](../yaml/_index.md#variables) 섹션에서 전역적으로 또는 작업별로 설정할 수 있습니다.

```yaml
variables:
  GIT_STRATEGY: clone
```

가능한 값은 `clone`, `fetch`, `none`, 그리고 `empty`입니다. 값을 지정하지 않으면 작업은 [프로젝트의 파이프라인 설정](../pipelines/settings.md#choose-the-default-git-strategy)을 사용합니다.

`clone`은 가장 느린 옵션입니다. 모든 작업에 대해 리포지토리를 처음부터 복제하여 로컬 작업 복사본이 항상 깨끗함을 보장합니다. 기존 작업 트리가 있으면 복제 전에 제거됩니다.

`fetch`은 로컬 작업 복사본을 재사용하므로 더 빠릅니다(존재하지 않으면 `clone`로 돌아감). `git clean`은 마지막 작업에서 수행한 모든 변경 사항을 실행 취소하는 데 사용되며, `git fetch`은 마지막 작업 실행 후 수행된 커밋을 검색하는 데 사용됩니다.

그러나 `fetch`은 이전 작업 트리에 대한 접근이 필요합니다. 이는 `shell` 또는 `docker` 실행기를 사용할 때 잘 작동합니다. 이들은 작업 트리를 보존하고 기본적으로 재사용하려고 시도하기 때문입니다.

이는 [Docker Machine 실행기](https://docs.gitlab.com/runner/executors/docker_machine/)를 사용할 때 제한 사항이 있습니다.

`none`의 Git 전략은 로컬 작업 복사본을 재사용하지만 GitLab에서 일반적으로 수행하는 모든 Git 작업을 건너뜁니다. 러너 사전 복제 스크립트도 건너뜁니다(있는 경우). 이 전략은 [`.gitlab-ci.yml` 스크립트](../yaml/_index.md#script)에 `fetch` 및 `checkout` 명령을 추가해야 할 수도 있습니다.

배포 작업과 같이 아티팩트에서만 작동하는 작업에 사용할 수 있습니다. Git 리포지토리 데이터가 있을 수 있지만 만료될 가능성이 높습니다. 캐시 또는 아티팩트에서 로컬 작업 복사본으로 가져온 파일만 의존해야 합니다. 이전 파이프라인의 캐시 및 아티팩트 파일이 여전히 있을 수 있음을 주의하세요.

`none`과 달리 `empty` Git 전략은 캐시 또는 아티팩트 파일을 다운로드하기 전에 전용 빌드 디렉터리를 삭제한 후 다시 생성합니다. 이 전략을 사용하면 러너 훅 스크립트(있는 경우)가 여전히 실행되어 추가 동작 사용자 지정을 허용합니다. `empty` Git 전략을 다음 경우에 사용합니다:

- 리포지토리 데이터가 없어도 됩니다.
- 작업을 실행할 때마다 깨끗하고 제어되거나 사용자 지정된 시작 상태를 원합니다.

### Git 서브모듈 전략 {#git-submodule-strategy}

`GIT_SUBMODULE_STRATEGY` 변수는 빌드 전 코드를 가져올 때 [Git 서브모듈](https://git-scm.com/book/en/v2/Git-Tools-Submodules)을 포함하는지 여부를 제어합니다. 이를 [`variables`](../yaml/_index.md#variables) 섹션에서 전역적으로 또는 작업별로 설정할 수 있습니다.

가능한 세 가지 값은 `none`, `normal`, 그리고 `recursive`입니다:

- `none`은 프로젝트 코드를 가져올 때 서브모듈이 포함되지 않음을 의미합니다. 이 설정은 1.10 이전 버전의 기본 동작과 일치합니다.

- `normal`은 최상위 수준 서브모듈만 포함됨을 의미합니다. 이는 다음과 같습니다:

  ```shell
  git submodule sync
  git submodule update --init
  ```

- `recursive`은 모든 서브모듈(서브모듈의 서브모듈 포함)이 포함됨을 의미합니다. 이 기능에는 Git v1.8.1 이상이 필요합니다. Docker를 기반으로 하지 않은 실행기와 함께 러너를 사용할 때 Git 버전이 해당 요구 사항을 충족하는지 확인합니다. 이는 다음과 같습니다:

  ```shell
  git submodule sync --recursive
  git submodule update --init --recursive
  ```

이 기능이 제대로 작동하려면 서브모듈을 `.gitmodules`에서 다음 중 하나로 구성해야 합니다:

- 공개적으로 접근 가능한 리포지토리의 HTTP(S) URL, 또는
- 동일한 GitLab 서버의 다른 리포지토리에 대한 상대 경로 [Git 서브모듈](git_submodules.md) 설명서를 참조하세요.

[`GIT_SUBMODULE_UPDATE_FLAGS`](#git-submodule-update-flags)를 사용하여 고급 동작을 제어하기 위한 추가 플래그를 제공할 수 있습니다.

### Git 체크아웃 {#git-checkout}

`GIT_CHECKOUT` 변수는 `GIT_STRATEGY`이 `clone` 또는 `fetch`로 설정되었을 때 `git checkout`을 실행해야 하는지를 지정하는 데 사용될 수 있습니다. 지정하지 않으면 기본값은 true입니다. 이를 [`variables`](../yaml/_index.md#variables) 섹션에서 전역적으로 또는 작업별로 설정할 수 있습니다.

`false`로 설정되면 러너는:

- `fetch`을 수행할 때 - 리포지토리를 업데이트하고 작업 복사본을 현재 리비전에 남깁니다,
- `clone`을 수행할 때 - 리포지토리를 복제하고 작업 복사본을 기본 브랜치에 남깁니다.

`GIT_CHECKOUT`이 `true`로 설정되면 `clone` 및 `fetch` 모두 동일하게 작동합니다. 러너는 CI 파이프라인과 관련된 리비전의 작업 복사본을 체크아웃합니다:

```yaml
variables:
  GIT_STRATEGY: clone
  GIT_CHECKOUT: "false"
script:
  - git checkout -B master origin/master
  - git merge $CI_COMMIT_SHA
```

### Git clean 플래그 {#git-clean-flags}

`GIT_CLEAN_FLAGS` 변수는 소스 체크아웃 후 `git clean`의 기본 동작을 제어하는 데 사용됩니다. 이를 [`variables`](../yaml/_index.md#variables) 섹션에서 전역적으로 또는 작업별로 설정할 수 있습니다.

`GIT_CLEAN_FLAGS`은 [`git clean`](https://git-scm.com/docs/git-clean) 명령의 모든 가능한 옵션을 허용합니다.

`git clean`은 `GIT_CHECKOUT: "false"`이 지정된 경우 비활성화됩니다.

`GIT_CLEAN_FLAGS`이:

- 지정하지 않으면 `git clean` 플래그의 기본값은 `-ffdx`입니다.
- `none` 값이 주어지면 `git clean`은 실행되지 않습니다.

예를 들어:

```yaml
variables:
  GIT_CLEAN_FLAGS: -ffdx -e cache/
script:
  - ls -al cache/
```

### Git fetch 추가 플래그 {#git-fetch-extra-flags}

`GIT_FETCH_EXTRA_FLAGS` 변수를 사용하여 `git fetch`의 동작을 제어합니다. 이를 [`variables`](../yaml/_index.md#variables) 섹션에서 전역적으로 또는 작업별로 설정할 수 있습니다.

`GIT_FETCH_EXTRA_FLAGS`은 [`git fetch`](https://git-scm.com/docs/git-fetch) 명령의 모든 옵션을 허용합니다. 그러나 `GIT_FETCH_EXTRA_FLAGS` 플래그는 수정할 수 없는 기본 플래그 이후에 추가됩니다.

기본 플래그는:

- [`GIT_DEPTH`](#shallow-cloning).
- [refspec](https://git-scm.com/book/en/v2/Git-Internals-The-Refspec) 목록입니다.
- `origin`라는 원격입니다.

`GIT_FETCH_EXTRA_FLAGS`이:

- 지정하지 않으면 `git fetch` 플래그의 기본값은 `--prune --quiet` 및 기본 플래그입니다.
- `none` 값이 주어지면 `git fetch`은 기본 플래그만 실행됩니다.

예를 들어 기본 플래그는 `--prune --quiet`이므로 `git fetch`을 `--prune`으로만 재정의하여 더 자세하게 만들 수 있습니다:

```yaml
variables:
  GIT_FETCH_EXTRA_FLAGS: --prune
script:
  - ls -al cache/
```

이전 구성으로 인해 `git fetch`이 다음 방식으로 호출됩니다:

```shell
git fetch origin $REFSPECS --depth 20  --prune
```

`$REFSPECS`은 GitLab에서 내부적으로 러너에 제공하는 값입니다.

### Git clone 추가 플래그 {#git-clone-extra-flags}

`GIT_CLONE_EXTRA_FLAGS` 변수를 사용하여 기본 `git clone` 작업에 추가 인수를 전달합니다. 이를 [`variables`](../yaml/_index.md#variables) 섹션에서 전역적으로 또는 작업별로 설정할 수 있습니다.

`GIT_CLONE_EXTRA_FLAGS`을 사용하려면:

- `FF_USE_GIT_NATIVE_CLONE`을 `true`로 설정하여 기본 `git clone` 기능을 활성화합니다.
- `GIT_STRATEGY`을 `clone`로 설정하여 fetch 대신 clone 전략을 사용합니다.
- Git 클라이언트는 최소 버전 2.49여야 합니다. 이 조건은 Linux 기반 이미지 버전 18.1 이상인 [헬퍼 이미지](https://docs.gitlab.com/runner/configuration/advanced-configuration/#helper-image)인 경우 자동으로 충족됩니다.

`GIT_CLONE_EXTRA_FLAGS`은 `git clone` 명령의 모든 옵션을 허용합니다. 플래그는 네이티브 `git clone` 명령에 추가되어 대체 리포지토리 참조 또는 clone 성능 최적화를 포함한 고급 사용 사례에 유연성을 제공합니다.

예를 들어 참조 리포지토리를 사용하여 clone 성능을 최적화할 수 있습니다:

```yaml
variables:
  FF_USE_GIT_NATIVE_CLONE: true
  GIT_STRATEGY: clone
  GIT_CLONE_EXTRA_FLAGS: "--reference-if-available /tmp/test"
```

`GIT_CLONE_EXTRA_FLAGS`이 지정되지 않으면 `git clone`은 기본 플래그만 사용합니다.

### CI 작업에서 특정 서브모듈 동기화 또는 제외 {#sync-or-exclude-specific-submodules-from-ci-jobs}

`GIT_SUBMODULE_PATHS` 변수를 사용하여 동기화 또는 업데이트해야 하는 서브모듈을 제어합니다. 이를 [`variables`](../yaml/_index.md#variables) 섹션에서 전역적으로 또는 작업별로 설정할 수 있습니다.

경로 구문은 [`git submodule`](https://git-scm.com/docs/git-submodule#Documentation/git-submodule.txt-ltpathgt82308203)와 동일합니다:

- 특정 경로를 동기화하고 업데이트하려면:

  ```yaml
  variables:
     GIT_SUBMODULE_PATHS: submoduleA submoduleB
  ```

- 특정 경로를 제외하려면:

  ```yaml
  variables:
     GIT_SUBMODULE_PATHS: ":(exclude)submoduleA :(exclude)submoduleB"
  ```

> [!warning]
> Git은 중첩된 경로를 무시합니다. 중첩된 서브모듈을 무시하려면 상위 서브모듈을 제외한 후 작업의 스크립트에서 수동으로 복제합니다. 예를 들어, `git clone <repo> --recurse-submodules=':(exclude)nested-submodule'`입니다. YAML을 올바르게 구문 분석할 수 있도록 문자열을 작은 따옴표로 감싸세요.

### Git 서브모듈 업데이트 플래그 {#git-submodule-update-flags}

`GIT_SUBMODULE_UPDATE_FLAGS` 변수를 사용하여 [`GIT_SUBMODULE_STRATEGY`](#git-submodule-strategy)이 `normal` 또는 `recursive`으로 설정된 경우 `git submodule update`의 동작을 제어합니다. 이를 [`variables`](../yaml/_index.md#variables) 섹션에서 전역적으로 또는 작업별로 설정할 수 있습니다.

`GIT_SUBMODULE_UPDATE_FLAGS`은 [`git submodule update`](https://git-scm.com/docs/git-submodule#Documentation/git-submodule.txt-update--init--remote-N--no-fetch--no-recommend-shallow-f--force--checkout--rebase--merge--referenceltrepositorygt--depthltdepthgt--recursive--jobsltngt--no-single-branch--ltpathgt82308203) 부명령의 모든 옵션을 허용합니다. 그러나 `GIT_SUBMODULE_UPDATE_FLAGS` 플래그는 몇 가지 기본 플래그 이후에 추가됩니다:

- `--init`, [`GIT_SUBMODULE_STRATEGY`](#git-submodule-strategy)이 `normal` 또는 `recursive`으로 설정된 경우.
- `--recursive`, [`GIT_SUBMODULE_STRATEGY`](#git-submodule-strategy)이 `recursive`로 설정된 경우.
- `GIT_DEPTH`. [shallow cloning](#shallow-cloning) 섹션에서 기본값을 참조하세요.

Git은 인수 목록에서 플래그의 마지막 발생을 인정하므로 `GIT_SUBMODULE_UPDATE_FLAGS`에서 수동으로 제공하면 이러한 기본 플래그를 재정의합니다.

예를 들어 이 변수를 사용하여:

- 리포지토리에서 추적된 커밋(기본값) 대신 최신 원격 `HEAD`을 가져와 `--remote` 플래그를 사용하여 모든 서브모듈을 자동으로 업데이트합니다.
- `--jobs 4` 플래그로 여러 병렬 작업에서 서브모듈을 가져와 체크아웃 속도를 높입니다.

```yaml
variables:
  GIT_SUBMODULE_STRATEGY: recursive
  GIT_SUBMODULE_UPDATE_FLAGS: --remote --jobs 4
script:
  - ls -al .git/modules/
```

이전 구성으로 인해 `git submodule update`이 다음 방식으로 호출됩니다:

```shell
git submodule update --init --depth 20 --recursive --remote --jobs 4
```

> [!warning]
> `--remote` 플래그를 사용할 때 빌드의 보안, 안정성 및 재현성에 대한 영향을 주의해야 합니다. 대부분의 경우 설계된 대로 서브모듈 커밋을 명시적으로 추적하고 자동 수정/종속성 봇을 사용하여 업데이트하는 것이 더 낫습니다.
>
> `--remote` 플래그는 서브모듈을 커밋된 리비전에서 체크아웃하는 데 필요하지 않습니다. 서브모듈을 최신 원격 버전으로 자동 업데이트하려는 경우에만 이 플래그를 사용합니다.

`--remote`의 동작은 Git 버전에 따라 다릅니다. 슈퍼프로젝트의 `.gitmodules` 파일에 지정된 브랜치가 서브모듈 리포지토리의 기본 브랜치와 다르면 일부 Git 버전은 다음 오류로 실패합니다:

`fatal: Unable to find refs/remotes/origin/<branch> revision in submodule path '<submodule-path>'`

러너는 서브모듈 업데이트가 실패할 때 원격 ref를 가져오려고 시도하는 "최고 노력" 폴백을 구현합니다.

이 폴백이 Git 버전에서 작동하지 않으면 다음 해결 방법 중 하나를 시도하세요:

- 슈퍼프로젝트에서 `.gitmodules`에 설정된 브랜치와 일치하도록 서브모듈 리포지토리의 기본 브랜치를 업데이트합니다.
- `GIT_SUBMODULE_DEPTH`을 `0`로 설정합니다.
- 서브모듈을 별도로 업데이트하고 `GIT_SUBMODULE_UPDATE_FLAGS`에서 `--remote` 플래그를 제거합니다.

### 서브모듈 URL을 HTTPS로 다시 작성 {#rewrite-submodule-urls-to-https}

{{< history >}}

- GitLab Runner 15.11에서 [도입되었습니다](https://gitlab.com/gitlab-org/gitlab-runner/-/merge_requests/3198).

{{< /history >}}

`GIT_SUBMODULE_FORCE_HTTPS` 변수를 사용하여 모든 Git 및 SSH 서브모듈 URL을 HTTPS로 강제로 다시 작성합니다. 동일한 GitLab 인스턴스에서 절대 URL을 사용하는 서브모듈을 복제할 수 있습니다. Git 또는 SSH 프로토콜로 구성되었더라도 가능합니다.

```yaml
variables:
  GIT_SUBMODULE_STRATEGY: recursive
  GIT_SUBMODULE_FORCE_HTTPS: "true"
```

활성화되면 러너는 [CI/CD 작업 토큰](../jobs/ci_job_token.md)을 사용하여 서브모듈을 복제합니다. 토큰은 작업을 실행하는 사용자의 권한을 사용하며 SSH 자격 증명이 필요하지 않습니다.

### Shallow cloning {#shallow-cloning}

`GIT_DEPTH`을 사용하여 가져오기 및 복제의 깊이를 지정할 수 있습니다. `GIT_DEPTH`는 리포지토리의 shallow 복제를 수행하며 복제를 크게 가속화할 수 있습니다. 많은 커밋 또는 오래된 대용량 바이너리를 가진 리포지토리에 도움이 될 수 있습니다. 값은 `git fetch` 및 `git clone`에 전달됩니다.

새로 생성된 프로젝트는 자동으로 [기본 `git depth` 값 `20`](../pipelines/settings.md#limit-the-number-of-changes-fetched-during-clone)을 갖습니다.

`1`의 깊이를 사용하고 작업 큐 또는 재시도 작업이 있으면 작업이 실패할 수 있습니다.

Git 가져오기 및 복제는 브랜치 이름과 같은 ref를 기반으로 하므로 러너는 특정 커밋 SHA를 복제할 수 없습니다. 여러 작업이 큐에 있거나 오래된 작업을 다시 시도하면 테스트할 커밋이 복제된 Git 히스토리에 있어야 합니다. `GIT_DEPTH`에 너무 작은 값을 설정하면 이러한 오래된 커밋을 실행하는 것이 불가능해질 수 있으며 작업 로그에 `unresolved reference`이 표시됩니다. `GIT_DEPTH`을 더 높은 값으로 변경하는 것을 다시 고려해야 합니다.

`git describe`을 사용하는 작업은 `GIT_DEPTH`이 설정되었을 때 올바르게 작동하지 않을 수 있습니다. Git 히스토리의 일부만 존재하기 때문입니다.

마지막 3개의 커밋만 가져오거나 복제하려면:

```yaml
variables:
  GIT_DEPTH: "3"
```

이를 [`variables`](../yaml/_index.md#variables) 섹션에서 전역적으로 또는 작업별로 설정할 수 있습니다.

### Git 서브모듈 깊이 {#git-submodule-depth}

{{< history >}}

- GitLab Runner 15.5에서 [도입되었습니다](https://gitlab.com/gitlab-org/gitlab-runner/-/merge_requests/3651).

{{< /history >}}

`GIT_SUBMODULE_DEPTH` 변수를 사용하여 [`GIT_SUBMODULE_STRATEGY`](#git-submodule-strategy)이 `normal` 또는 `recursive`로 설정된 경우 서브모듈 가져오기 및 복제의 깊이를 지정합니다. 이를 [`variables`](../yaml/_index.md#variables) 섹션에서 전역적으로 또는 특정 작업에 대해 설정할 수 있습니다.

`GIT_SUBMODULE_DEPTH` 변수를 설정할 때 [`GIT_DEPTH`](#shallow-cloning) 설정을 서브모듈에만 재정의합니다.

마지막 3개의 커밋만 가져오거나 복제하려면:

```yaml
variables:
  GIT_SUBMODULE_DEPTH: 3
```

### 사용자 지정 빌드 디렉터리 {#custom-build-directories}

기본적으로 러너는 `$CI_BUILDS_DIR` 디렉터리의 고유한 하위 경로에 리포지토리를 복제합니다. 그러나 프로젝트에서 특정 디렉터리에 코드가 필요할 수 있습니다(예: Go 프로젝트). 그 경우 `GIT_CLONE_PATH` 변수를 지정하여 러너에 리포지토리를 복제할 디렉터리를 알려줄 수 있습니다:

```yaml
variables:
  GIT_CLONE_PATH: $CI_BUILDS_DIR/project-name

test:
  script:
    - pwd
```

`GIT_CLONE_PATH`은 항상 `$CI_BUILDS_DIR` 내부에 있어야 합니다. `$CI_BUILDS_DIR`에 설정된 디렉터리는 실행기 및 [runners.builds_dir](https://docs.gitlab.com/runner/configuration/advanced-configuration/#the-runners-section) 설정의 구성에 따라 달라집니다.

이는 `custom_build_dir`이 [러너의 구성](https://docs.gitlab.com/runner/configuration/advanced-configuration/#the-runnerscustom_build_dir-section)에서 활성화된 경우에만 사용할 수 있습니다.

#### 동시성 처리 {#handling-concurrency}

`1`보다 큰 동시성을 사용하는 실행기는 실패로 이어질 수 있습니다. 여러 작업이 `builds_dir`이 작업 간에 공유되는 경우 동일한 디렉터리에서 작동할 수 있습니다.

러너는 이 상황을 방지하려고 시도하지 않습니다. 관리자와 개발자가 러너 구성의 요구 사항을 준수하는 것은 이들의 책임입니다.

이 시나리오를 피하기 위해 `$CI_BUILDS_DIR`에서 고유한 경로를 사용할 수 있습니다. 러너는 동시성의 고유한 `ID`를 제공하는 두 가지 추가 변수를 노출하기 때문입니다:

- `$CI_CONCURRENT_ID`: 지정된 실행기에서 실행 중인 모든 작업의 고유 ID입니다.
- `$CI_CONCURRENT_PROJECT_ID`: 지정된 실행기 및 프로젝트에서 실행 중인 모든 작업의 고유 ID입니다.

모든 시나리오 및 모든 실행기에서 잘 작동해야 하는 가장 안정적인 구성은 `GIT_CLONE_PATH`에서 `$CI_CONCURRENT_ID`을 사용하는 것입니다. 예를 들어:

```yaml
variables:
  GIT_CLONE_PATH: $CI_BUILDS_DIR/$CI_CONCURRENT_ID/project-name

test:
  script:
    - pwd -P
```

`$CI_CONCURRENT_PROJECT_ID`을 `$CI_PROJECT_PATH`와 함께 사용해야 합니다. `$CI_PROJECT_PATH`은 `group/subgroup/project` 형식의 리포지토리 경로를 제공합니다. 예를 들어:

```yaml
variables:
  GIT_CLONE_PATH: $CI_BUILDS_DIR/$CI_CONCURRENT_ID/$CI_PROJECT_PATH

test:
  script:
    - pwd -P
```

#### 중첩된 경로 {#nested-paths}

`GIT_CLONE_PATH`의 값은 한 번 확장됩니다. 이 값에 변수를 중첩할 수 없습니다.

예를 들어 `.gitlab-ci.yml` 파일에서 다음 변수를 정의합니다:

```yaml
variables:
  GOPATH: $CI_BUILDS_DIR/go
  GIT_CLONE_PATH: $GOPATH/src/namespace/project
```

`GIT_CLONE_PATH`의 값은 `$CI_BUILDS_DIR/go/src/namespace/project`로 한 번 확장되며 `$CI_BUILDS_DIR`이 확장되지 않았기 때문에 실패를 초래합니다.

### `after_script`에서 오류 무시 {#ignore-errors-in-after_script}

작업에서 [`after_script`](../yaml/_index.md#after_script)을 사용하여 작업의 `before_script` 및 `script` 섹션 이후에 실행해야 하는 명령 배열을 정의할 수 있습니다. `after_script` 명령은 스크립트 종료 상태(실패 또는 성공)와 관계없이 실행됩니다.

기본적으로 러너는 `after_script`이 실행될 때 발생하는 모든 오류를 무시합니다. `after_script`이 실행될 때 오류 발생 시 작업을 즉시 실패하도록 하려면 `AFTER_SCRIPT_IGNORE_ERRORS` CI/CD 변수를 `false`로 설정합니다. 예를 들어:

```yaml
variables:
  AFTER_SCRIPT_IGNORE_ERRORS: false
```

### 작업 스테이지 시도 {#job-stages-attempts}

실행 중인 작업이 다음 스테이지를 실행하려고 시도하는 횟수를 설정할 수 있습니다:

| 변수                        | 설명 |
|---------------------------------|-------------|
| `ARTIFACT_DOWNLOAD_ATTEMPTS`    | 작업을 실행하는 동안 아티팩트를 다운로드하려는 시도 횟수 |
| `EXECUTOR_JOB_SECTION_ATTEMPTS` | [`No Such Container`](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/4450) 오류 후 작업에서 섹션을 실행하려는 시도 횟수([Docker 실행기](https://docs.gitlab.com/runner/executors/docker/) 전용). |
| `GET_SOURCES_ATTEMPTS`          | 작업을 실행하는 동안 소스를 가져오려는 시도 횟수 |
| `RESTORE_CACHE_ATTEMPTS`        | 작업을 실행하는 동안 캐시를 복원하려는 시도 횟수 |

기본값은 단일 시도입니다.

예:

```yaml
variables:
  GET_SOURCES_ATTEMPTS: 3
```

이를 [`variables`](../yaml/_index.md#variables) 섹션에서 전역적으로 또는 작업별로 설정할 수 있습니다.

## GitLab.com 인스턴스 러너에서 사용할 수 없는 시스템 호출 {#system-calls-not-available-on-gitlabcom-instance-runners}

GitLab.com 인스턴스 러너는 CoreOS에서 실행됩니다. 이는 C 표준 라이브러리에서 `getlogin`과 같은 일부 시스템 호출을 사용할 수 없음을 의미합니다.

## 아티팩트 및 캐시 설정 {#artifact-and-cache-settings}

아티팩트 및 캐시 설정은 아티팩트와 캐시의 압축 비율을 제어합니다. 이러한 설정을 사용하여 작업으로 생성된 아카이브의 크기를 지정합니다.

- 느린 네트워크에서는 더 작은 아카이브에 대해 업로드가 더 빠를 수 있습니다.
- 빠른 네트워크에서 대역폭과 저장소가 문제가 아닌 경우 생성된 아카이브가 더 크더라도 가장 빠른 압축 비율을 사용하여 업로드가 더 빠를 수 있습니다.

[GitLab Pages](../../user/project/pages/_index.md)가 [HTTP Range 요청](https://developer.mozilla.org/en-US/docs/Web/HTTP/Range_requests)을 제공하려면 아티팩트가 `ARTIFACT_COMPRESSION_LEVEL: fastest` 설정을 사용해야 합니다. 압축되지 않은 zip 아카이브만 이 기능을 지원하기 때문입니다.

미터를 활성화하여 업로드 및 다운로드의 전송 속도를 제공할 수 있습니다.

`CACHE_REQUEST_TIMEOUT` 설정으로 캐시 업로드 및 다운로드의 최대 시간을 설정할 수 있습니다. 느린 캐시 업로드가 작업 기간을 크게 증가시키는 경우 이 설정을 사용합니다.

```yaml
variables:
  # output upload and download progress every 2 seconds
  TRANSFER_METER_FREQUENCY: "2s"

  # Use fast compression for artifacts, resulting in larger archives
  ARTIFACT_COMPRESSION_LEVEL: "fast"

  # Use no compression for caches
  CACHE_COMPRESSION_LEVEL: "fastest"

  # Set maximum duration of cache upload and download
  CACHE_REQUEST_TIMEOUT: 5
```

| 변수                     | 설명 |
|------------------------------|-------------|
| `TRANSFER_METER_FREQUENCY`   | 미터의 전송 속도를 얼마나 자주 출력할지 지정합니다. 기간으로 설정할 수 있습니다(예: `1s` 또는 `1m30s`). `0`의 기간은 미터를 비활성화합니다(기본값). 값을 설정하면 파이프라인이 아티팩트 및 캐시 업로드와 다운로드에 대한 진행률 미터를 표시합니다. |
| `ARTIFACT_COMPRESSION_LEVEL` | 압축 비율을 조정하려면 `fastest`, `fast`, `default`, `slow`, 또는 `slowest`로 설정합니다. 이 설정은 Fastzip 아카이버에서만 작동하므로 러너 기능 플래그 [`FF_USE_FASTZIP`](https://docs.gitlab.com/runner/configuration/feature-flags/#available-feature-flags)도 활성화해야 합니다. |
| `CACHE_COMPRESSION_LEVEL`    | 압축 비율을 조정하려면 `fastest`, `fast`, `default`, `slow`, 또는 `slowest`로 설정합니다. 이 설정은 Fastzip 아카이버에서만 작동하므로 러너 기능 플래그 [`FF_USE_FASTZIP`](https://docs.gitlab.com/runner/configuration/feature-flags/#available-feature-flags)도 활성화해야 합니다. |
| `CACHE_REQUEST_TIMEOUT`      | 단일 작업에 대한 캐시 업로드 및 다운로드 작업의 최대 기간을 분 단위로 구성합니다. 기본값은 `10`분입니다. |

### 높은 지연 연결에 대한 TCP 설정 조정 {#tune-tcp-settings-for-high-latency-connections}

러너와 GitLab 인스턴스 간에 상당한 네트워크 지연이 있으면 기본 TCP 윈도우 크기가 처리량을 제한할 수 있습니다. 러너 호스트에서 TCP 윈도우 크기를 증가시켜 더 많은 데이터를 전송할 수 있습니다.

예를 들어 Linux에서 최대 TCP 버퍼 크기를 증가합니다:

```shell
sudo sysctl -w net.core.rmem_max=16777216
sudo sysctl -w net.core.wmem_max=16777216
sudo sysctl -w net.ipv4.tcp_rmem="4096 87380 16777216"
sudo sysctl -w net.ipv4.tcp_wmem="4096 65536 16777216"
```

이러한 변경 사항을 재부팅 시에도 유지하려면 `/etc/sysctl.conf`에 추가합니다.

> [!note]
> TCP 조정은 러너 머신의 모든 네트워크 연결에 영향을 주는 호스트 수준 변경입니다. 먼저 프로덕션이 아닌 환경에서 변경 사항을 테스트합니다.

## 아티팩트 출처 메타데이터 {#artifact-provenance-metadata}

{{< history >}}

- GitLab Runner 15.1에서 [도입되었습니다](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/28940).

{{< /history >}}

러너는 [SLSA 출처](https://slsa.dev/spec/v1.0/provenance)를 생성하고 출처를 모든 빌드 아티팩트에 바인딩하는 [SLSA 명령문](https://slsa.dev/spec/v1.0/attestation-model#model-and-terminology)을 생성할 수 있습니다. 명령문을 아티팩트 출처 메타데이터라고 합니다.

아티팩트 출처 메타데이터를 활성화하려면 `RUNNER_GENERATE_ARTIFACTS_METADATA` 환경 변수를 `true`로 설정합니다. 변수를 전역적으로 또는 개별 작업에 대해 설정할 수 있습니다:

```yaml
variables:
  RUNNER_GENERATE_ARTIFACTS_METADATA: "true"

job1:
  variables:
    RUNNER_GENERATE_ARTIFACTS_METADATA: "true"
```

메타데이터는 아티팩트와 함께 저장된 일반 텍스트 `.json` 파일로 렌더링됩니다. 파일 이름은 `{ARTIFACT_NAME}-metadata.json`입니다. `ARTIFACT_NAME`은 `.gitlab-ci.yml` 파일에 정의된 [아티팩트 이름](../jobs/job_artifacts.md#with-an-explicitly-defined-artifact-name)입니다. 이름이 정의되지 않으면 기본 파일 이름은 `artifacts-metadata.json`입니다.

### 출처 메타데이터 형식 {#provenance-metadata-format}

아티팩트 출처 메타데이터는 [in-toto v0.1 명령문](https://github.com/in-toto/attestation/tree/v0.1.0/spec#statement) 형식으로 생성됩니다. [SLSA 1.0 출처](https://slsa.dev/spec/v1.0/provenance) 형식으로 생성된 출처 술어가 포함됩니다.

다음 필드는 기본적으로 채워집니다:

| 필드                                                             | 값 |
|-------------------------------------------------------------------|-------|
| `_type`                                                           | `https://in-toto.io/Statement/v0.1` |
| `subject`                                                         | 메타데이터가 적용되는 소프트웨어 아티팩트 세트 |
| `subject[].name`                                                  | 아티팩트의 파일 이름입니다. |
| `subject[].sha256`                                                | 아티팩트의 `sha256` 체크섬입니다. |
| `predicateType`                                                   | `https://slsa.dev/provenance/v1` |
| `predicate.buildDefinition.buildType`                             | `https://gitlab.com/gitlab-org/gitlab-runner/-/blob/{GITLAB_RUNNER_VERSION}/PROVENANCE.md`. 예를 들어 v15.0.0 |
| `predicate.runDetails.builder.id`                                 | 러너 세부 정보 페이지를 가리키는 URI입니다(예: `https://gitlab.com/gitlab-com/www-gitlab-com/-/runners/3785264`). |
| `predicate.buildDefinition.externalParameters`                    | 빌드 명령 실행 중에 사용 가능한 CI/CD 또는 환경 변수의 이름입니다. 값은 항상 빈 문자열로 표시되어 비밀을 보호합니다. |
| `predicate.buildDefinition.externalParameters.source`             | 프로젝트의 URL입니다. |
| `predicate.buildDefinition.externalParameters.entryPoint`         | 빌드를 트리거한 CI/CD 작업의 이름입니다. |
| `predicate.buildDefinition.internalParameters.name`               | 러너의 이름입니다. |
| `predicate.buildDefinition.internalParameters.executor`           | 러너 실행기. |
| `predicate.buildDefinition.internalParameters.architecture`       | CI/CD 작업이 실행되는 아키텍처입니다. |
| `predicate.buildDefinition.internalParameters.job`                | 빌드를 트리거한 CI/CD 작업의 ID입니다. |
| `predicate.buildDefinition.resolvedDependencies[0].uri`           | 프로젝트의 URL입니다. |
| `predicate.buildDefinition.resolvedDependencies[0].digest.sha256` | 프로젝트의 커밋 리비전입니다. |
| `predicate.runDetails.metadata.invocationId`                      | 빌드를 트리거한 CI/CD 작업의 ID입니다. |
| `predicate.runDetails.metadata.startedOn`                         | 빌드가 시작된 시간입니다. 이 필드는 `RFC3339` 형식입니다. |
| `predicate.runDetails.metadata.finishedOn`                        | 빌드가 종료된 시간입니다. 메타데이터 생성이 빌드 중에 발생하므로 이 시간은 GitLab에서 보고한 시간보다 약간 이릅니다. 이 필드는 `RFC3339` 형식입니다. |

출처 명령문은 이 예시와 유사해야 합니다:

```json
{
 "_type": "https://in-toto.io/Statement/v0.1",
 "predicateType": "https://slsa.dev/provenance/v1",
 "subject": [
  {
   "name": "x.txt",
   "digest": {
    "sha256": "ac097997b6ec7de591d4f11315e4aa112e515bb5d3c52160d0c571298196ea8b"
   }
  },
  {
   "name": "y.txt",
   "digest": {
    "sha256": "9eb634f80da849d828fcf42740d823568c49e8d7b532886134f9086246b1fdf3"
   }
  }
 ],
 "predicate": {
  "buildDefinition": {
   "buildType": "https://gitlab.com/gitlab-org/gitlab-runner/-/blob/2147fb44/PROVENANCE.md",
   "externalParameters": {
    "CI": "",
    "CI_API_GRAPHQL_URL": "",
    "CI_API_V4_URL": "",
    "CI_COMMIT_AUTHOR": "",
    "CI_COMMIT_BEFORE_SHA": "",
    "CI_COMMIT_BRANCH": "",
    "CI_COMMIT_DESCRIPTION": "",
    "CI_COMMIT_MESSAGE": "",
    [... additional environmental variables ...]
    "entryPoint": "build-job",
    "source": "https://gitlab.com/my-group/my-project/test-runner-generated-slsa-statement"
   },
   "internalParameters": {
    "architecture": "amd64",
    "executor": "docker+machine",
    "job": "10340684631",
    "name": "green-4.saas-linux-small-amd64.runners-manager.gitlab.com/default"
   },
   "resolvedDependencies": [
    {
     "uri": "https://gitlab.com/my-group/my-project/test-runner-generated-slsa-statement",
     "digest": {
      "sha256": "bdd2ecda9ef57b129c88617a0215afc9fb223521"
     }
    }
   ]
  },
  "runDetails": {
   "builder": {
    "id": "https://gitlab.com/my-group/my-project/test-runner-generated-slsa-statement/-/runners/12270857",
    "version": {
     "gitlab-runner": "2147fb44"
    }
   },
   "metadata": {
    "invocationId": "10340684631",
    "startedOn": "2025-06-13T07:25:13Z",
    "finishedOn": "2025-06-13T07:25:40Z"
   }
  }
 }
}
```

## 스테이징 디렉터리 {#staging-directory}

{{< history >}}

- GitLab Runner 15.0에서 [도입되었습니다](https://gitlab.com/gitlab-org/gitlab-runner/-/merge_requests/3403).

{{< /history >}}

시스템의 기본 임시 디렉터리에서 캐시 및 아티팩트를 아카이브하지 않으려면 다른 디렉터리를 지정할 수 있습니다.

시스템의 기본 임시 경로에 제약이 있는 경우 디렉터리를 변경해야 할 수 있습니다. 디렉터리 위치에 빠른 디스크를 사용하면 성능을 향상시킬 수도 있습니다.

디렉터리를 변경하려면 `ARCHIVER_STAGING_DIR`을 CI 작업의 변수로 설정하거나 러너를 등록할 때 러너 변수를 사용합니다(`gitlab register --env ARCHIVER_STAGING_DIR=<dir>`).

지정한 디렉터리는 추출 전 아티팩트 다운로드 위치로 사용됩니다. `fastzip` 아카이버를 사용하는 경우 이 위치는 아카이빙 시 스크래치 공간으로도 사용됩니다.

## `fastzip`을 구성하여 성능 향상 {#configure-fastzip-to-improve-performance}

{{< history >}}

- GitLab Runner 15.0에서 [도입되었습니다](https://gitlab.com/gitlab-org/gitlab-runner/-/merge_requests/3130).

{{< /history >}}

`fastzip`을 조정하려면 [`FF_USE_FASTZIP`](https://docs.gitlab.com/runner/configuration/feature-flags/#available-feature-flags) 플래그가 활성화되어 있는지 확인합니다. 그런 다음 아래 환경 변수 중 하나를 사용합니다.

| 변수                        | 설명 |
|---------------------------------|-------------|
| `FASTZIP_ARCHIVER_CONCURRENCY`  | 동시에 압축할 파일의 수입니다. 기본값은 사용 가능한 CPU 수입니다. |
| `FASTZIP_ARCHIVER_BUFFER_SIZE`  | 각 파일에 대한 동시성당 할당된 버퍼 크기입니다. 이 숫자를 초과하는 데이터는 스크래치 공간으로 이동합니다. 기본값은 2 MiB입니다. |
| `FASTZIP_EXTRACTOR_CONCURRENCY` | 동시에 압축 해제할 파일의 수입니다. 기본값은 사용 가능한 CPU 수입니다. |

zip 아카이브의 파일이 순차적으로 추가됩니다. 이로 인해 동시 압축이 어려워집니다. `fastzip`은 먼저 파일을 동시에 디스크로 압축한 후 결과를 zip 아카이브로 순차적으로 다시 복사하여 이 제한을 우회합니다.

더 작은 파일의 경우 디스크에 쓰고 내용을 다시 읽는 것을 피하기 위해 동시성당 작은 버퍼를 사용합니다. 이 설정은 `FASTZIP_ARCHIVER_BUFFER_SIZE`로 제어할 수 있습니다. 이 버퍼의 기본 크기는 2 MiB이므로 동시성이 16일 때 32 MiB를 할당합니다. 버퍼 크기를 초과하는 데이터는 디스크에 쓰고 다시 읽습니다. 따라서 버퍼 없음 `FASTZIP_ARCHIVER_BUFFER_SIZE: 0`을 사용하고 스크래치 공간만 유효한 옵션입니다.

`FASTZIP_ARCHIVER_CONCURRENCY`은 동시에 압축할 파일의 수를 제어합니다. 앞서 언급했듯이 이 설정은 사용 중인 메모리의 양을 증가시킬 수 있습니다. 스크래치 공간에 기록된 임시 데이터도 증가시킬 수 있습니다. 기본값은 사용 가능한 CPU 수이지만 메모리 영향을 고려할 때 항상 최선의 설정은 아닐 수 있습니다.

`FASTZIP_EXTRACTOR_CONCURRENCY`은 한 번에 압축 해제할 파일의 수를 제어합니다. zip 아카이브의 파일을 기본적으로 동시성에서 읽을 수 있으므로 추출기에 필요한 것 외에 추가 메모리가 할당되지 않습니다. 기본값은 사용 가능한 CPU 수입니다.
