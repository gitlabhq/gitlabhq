---
stage: Security Platform
group: Secrets Manager Application
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab Secrets Manager
ignore_in_report: true
---

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 18.3에서 [도입](https://gitlab.com/groups/gitlab-org/-/epics/16319)되었으며 [기능 플래그](../../../development/feature_flags/_index.md) `secrets_manager` 및 `ci_tanukey_ui`를 포함합니다. 기본적으로 비활성화됨.
- 기능 플래그 `ci_tanukey_ui`가 GitLab 18.4에서 [제거됨](https://gitlab.com/gitlab-org/gitlab/-/issues/549940).
- GitLab 18.8에서 일부 사용자에게 비공개 베타로 제공됨.
- 그룹 비밀 관리자는 18.10에서 [도입](https://gitlab.com/groups/gitlab-org/-/work_items/17904)되었으며 [기능 플래그](../../../development/feature_flags/_index.md) `group_secrets_manager`를 사용하여 닫힌 베타 사용자에게 제공됩니다.
- GitLab 19.0에서 닫힌 베타에서 공개 베타로 [변경](https://gitlab.com/groups/gitlab-org/-/work_items/21731)되었습니다.
- GitLab 19.3에서 GitLab.com의 제한적 출시로 [변경](https://gitlab.com/groups/gitlab-org/-/work_items/10723)되었습니다.
- 프로젝트의 관리자 역할에 대한 기본 읽기 및 쓰기 권한이 GitLab 19.4에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/work_items/623437)되었습니다.
- 그룹의 비밀 권한이 GitLab 19.4에서 [제거](https://gitlab.com/gitlab-org/gitlab/-/work_items/623457)되었습니다. 그룹 권한은 더 이상 액세스를 부여하지 않으며, GraphQL API에서 `GROUP` 주체 유형, `PrincipalInput`의 `groupPath` 인수 및 `Principal`의 `group` 필드가 제거되었습니다. 대신 사용자 또는 역할에 권한을 부여하세요.

{{< /history >}}

GitLab Secrets Manager를 사용하여 프로젝트 및 그룹의 시크릿과 자격증명을 안전하게 저장하고 관리합니다.

시크릿은 CI/CD 작업이 실행되는 데 필요한 민감한 정보를 나타냅니다. 시크릿은 액세스 토큰, 데이터베이스 자격증명, 개인 키 등을 포함할 수 있습니다. 기본적으로 항상 작업에 사용할 수 있는 CI/CD 변수와 달리, 시크릿은 작업에서 명시적으로 요청해야 합니다.

GitLab 비밀 관리자는 [GitLab Credits를 사용](credit_usage.md)합니다.

공개 베타 중에 [피드백 이슈 598100](https://gitlab.com/gitlab-org/gitlab/-/work_items/598100)에서 피드백을 공유하세요.

## GitLab 비밀 관리자 활성화 {#enable-gitlab-secrets-manager}

최상위 그룹에 대해 비밀 관리자가 활성화되면 해당 그룹의 모든 하위 그룹 및 프로젝트에서도 사용할 수 있습니다.

GitLab Self-Managed에서 관리자는 먼저 인스턴스에 [GitLab 비밀 관리자를 설치 및 활성화](../../../administration/secrets_manager/_index.md)해야 합니다. 비밀 관리자가 설치 및 활성화된 후 인스턴스의 특정 그룹 및 프로젝트에 대해 활성화할 수 있습니다.

### GitLab.com {#for-gitlabcom}

{{< details >}}

상태:  제한적 출시

{{< /details >}}

- 30일 평가판을 시작하여 임시 평가 크레딧으로 GitLab 비밀 관리자를 시도할 수 있습니다. 평가판이 만료된 후 GitLab 비밀 관리자는 GitLab Credits를 사용하기 시작합니다. 서비스 중단을 피하려면 월별 커밋 크레딧 풀을 구매하거나 평가판이 종료되기 전에 온디맨드 청구를 활성화하세요. 자세한 내용은 [GitLab 비밀 관리자 크레딧 사용량](credit_usage.md)을 참조하세요.
- 2026년 8월 21일 이전에 베타에 참여한 경우 환경에 2026년 9월 21일까지 계속 액세스할 수 있는 유예 기간이 있습니다. 유예 기간이 지나면 GitLab에서 액세스를 비활성화합니다. 액세스를 계속하려면 유예 기간이 끝나기 전에 평가판을 시작하세요.

전제 조건:

- 최상위 그룹에 대한 Owner 역할이 있어야 합니다.

1. 상단 바에서 **검색 또는 이동**을 선택하고 최상위 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **안전함** > **비밀 관리자**를 선택하세요.
1. **30일 평가판 시작**을 선택하세요.

### GitLab Self-Managed {#for-gitlab-self-managed}

{{< details >}}

- 상태:  베타

{{< /details >}}

> [!note]
> GitLab 비밀 관리자는 공개 베타 중에 무료입니다. GitLab은 일반 공급 전에 알려드리므로 평가판을 시작하거나 GitLab Credits에 대한 온디맨드 청구를 선택할 시간이 있습니다.

#### 프로젝트의 경우 {#for-a-project}

전제 조건:

- 프로젝트에 대한 Owner 역할이 있어야 합니다.

프로젝트에 대해 GitLab Secrets Manager를 활성화하거나 비활성화하려면:

1. 상단 바에서 **Search or go to**를 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **Settings** > **General**을 선택합니다.
1. **Visibility, project features, permissions**를 확장합니다.
1. **GitLab 비밀 관리자** 토글을 켜고 비밀 관리자가 프로비저닝될 때까지 기다리세요.

   > [!warning]
   > 나중에 프로젝트의 시크릿 관리자를 비활성화하면, 모든 프로젝트 시크릿이 영구적으로 삭제됩니다. 이러한 시크릿은 복구할 수 없습니다.

프로젝트에 정의된 시크릿은 동일한 프로젝트의 파이프라인에서만 액세스할 수 있습니다.

#### 그룹의 경우 {#for-a-group}

{{< history >}}

- 최상위 그룹 설정이 GitLab 19.4에서 **설정** > **일반**에서 **설정** > **안전함**으로 [이동](https://gitlab.com/gitlab-org/gitlab/-/issues/605581)되었습니다.

{{< /history >}}

전제 조건:

- 그룹의 Owner 역할이 있어야 합니다.

그룹에 대해 GitLab Secrets Manager를 활성화하거나 비활성화하려면:

1. 상단 바에서 **Search or go to**를 선택하고 그룹을 찾습니다.
1. 왼쪽 사이드바에서:
   - 최상위 그룹에서 **설정** > **안전함**을 선택하세요.
   - 하위 그룹에서 **설정** > **일반**을 선택하고 **권한 및 그룹 기능**을 확장하세요.
1. **GitLab 비밀 관리자** 토글을 켜고 비밀 관리자가 프로비저닝될 때까지 기다리세요.

   > [!warning]
   > 나중에 그룹의 시크릿 관리자를 비활성화하면, 모든 그룹 시크릿이 영구적으로 삭제됩니다. 이러한 시크릿은 복구할 수 없습니다.

그룹에 정의된 시크릿은 해당 그룹 직속 프로젝트 또는 하위 그룹 계층의 파이프라인에서만 액세스할 수 있습니다.

## 시크릿 정의 {#define-a-secret}

시크릿을 시크릿 관리자에 추가하여 보안 CI/CD 파이프라인 및 워크플로에서 사용할 수 있습니다.

1. 상단 막대에서 **검색 또는 이동**을 선택하고 프로젝트 또는 그룹을 찾습니다.
1. **Secure** > **Secrets manager**를 선택합니다.
1. **Add secret**를 선택하고 세부 정보를 입력합니다.
   - **Name (이름)**: 프로젝트 내에서 고유해야 합니다.
   - **Value (값)**: 10 KB(10,000바이트) 이하여야 합니다.
   - **Description (설명)**: 최대 200자입니다.
   - **Environments (환경)**: 다음 중 하나일 수 있습니다.
     - **All (기본값)** (`*`)
     - 특정 [환경](../../environments/_index.md#types-of-environments).
     - [와일드카드 환경](../../environments/_index.md#limit-the-environment-scope-of-a-cicd-variable).
   - **Branch (브랜치)**: 이 옵션은 프로젝트 설정에만 존재합니다. 다음 중 하나일 수 있습니다.
     - 특정 브랜치.
     - 와일드카드 브랜치(`*` 문자가 포함되어야 함).
   - **Protected (보호됨)**: 이 옵션은 그룹 설정에만 존재합니다. 선택사항. 보호된 브랜치에서 실행되는 파이프라인으로만 시크릿을 내보냅니다.
   - **Rotation reminder (교체 알림)**: 선택사항. 설정된 일수 후에 시크릿을 교체하도록 이메일 알림을 보냅니다. 최소 7일입니다.

[기본적으로](../../../administration/instance_limits.md#secrets-manager-limits) 프로젝트당 최대 100개, 그룹당 500개의 비밀을 저장할 수 있습니다. 하위 그룹 또는 멤버 프로젝트의 비밀은 상위 그룹의 한도에 계산되지 않습니다.

비밀을 생성한 후:

- 파이프라인 구성 또는 작업 스크립트에서 사용할 수 있습니다.
- 비밀을 편집하면 값을 새 값으로만 덮어쓸 수 있습니다. UI를 통해 비밀 값을 검색할 수 없습니다. 자세한 내용은 [GitLab 비밀 관리자에 대한 권한](../../../user/permissions.md#project-secrets-manager)을 검토하세요.

> [!warning]
> 시크릿 값은 시크릿 생성 또는 업데이트 시 정의된 특정 환경이나 브랜치에 대해 실행되는 모든 CI/CD 파이프라인 작업에서 액세스할 수 있습니다. 이러한 시크릿 값에 액세스 권한이 있는 사용자만 지정된 환경이나 브랜치에서 작업을 실행할 수 있는지 확인합니다.

## 작업 스크립트에서 시크릿 사용 {#use-secrets-in-job-scripts}

기본적으로 [파일 유형 CI/CD 변수](../../variables/_index.md#use-file-type-cicd-variables)와 유사하게 비밀은 관련 환경 변수가 있는 파일로 작업에서 사용 가능하게 됩니다:

- 비밀의 키는 환경 변수 이름입니다.
- 비밀의 값은 임시 파일에 저장됩니다. 마스킹된 CI/CD 변수와 달리 비밀은 공백과 줄 바꿈을 포함할 수 있습니다.
- 임시 파일의 경로는 환경 변수 값입니다.

파일을 입력으로 허용하는 명령이 있는 작업 스크립트에서 비밀을 사용하거나 선택적으로 직접 [비밀을 환경 변수로 사용](#use-a-secret-as-an-environment-variable-with-file-false)하세요.

작업이 비밀의 값을 출력하면 GitLab은 작업 로그의 값을 `[MASKED]`로 바꿉니다.

### 프로젝트 시크릿의 경우 {#for-project-secrets}

전제 조건:

- GitLab Runner 19.0 이상이어야 합니다.

프로젝트의 비밀 관리자에 저장된 비밀에 액세스하려면 [`secrets`](../../yaml/_index.md#secrets) 및 `gitlab_secrets_manager` 키워드를 사용하세요.

예를 들어:

```yaml
job:
  secrets:
    KUBE_CA_PEM:
      gitlab_secrets_manager:
        name: kube_cert
  script:
   - kubectl config set-cluster e2e --server="https://example.com" --certificate-authority="$KUBE_CA_PEM"
```

### 그룹 시크릿의 경우 {#for-group-secrets}

전제 조건:

- GitLab Runner 19.0 이상이어야 합니다.

그룹의 비밀 관리자에 저장된 비밀에 액세스하려면:

- [`secrets`](../../yaml/_index.md#secrets) 및 `gitlab_secrets_manager` 키워드를 사용합니다.
- `source` 필드에 `group/` 접두사 다음에 `<full-path-to-group>`을 사용하여 비밀 관리자 소스로 그룹을 지정하세요.

예를 들어:

```yaml
job:
  secrets:
    KUBE_CA_PEM:
      gitlab_secrets_manager:
        name: kube_cert
        source: group/my-group/my-subgroup
  script:
   - kubectl config set-cluster e2e --server="https://example.com" --certificate-authority="$KUBE_CA_PEM"
```

### `file: false`을(를) 사용하여 비밀을 환경 변수로 사용 {#use-a-secret-as-an-environment-variable-with-file-false}

비밀을 환경 변수로 사용하고 파일에 저장하지 않으려면 비밀에 `file: false`을(를) 설정하세요. 예를 들어:

```yaml
job:
  secrets:
    DEPLOY_SECRET:
      gitlab_secrets_manager:
        name: deploy_credentials
      file: false
  script:
    - my_deploy_command --user username --pass $DEPLOY_SECRET
```

이 예에서 비밀은 작업에 `DEPLOY_SECRET` 변수로 제공되며, 다른 환경 변수처럼 사용할 수 있습니다.

## 시크릿 권한 관리 {#manage-secrets-permissions}

### 프로젝트의 경우 {#for-a-project-1}

전제 조건:

- 시크릿 권한을 관리하려면 프로젝트에 대한 Owner 역할이 있어야 합니다.
- 프로젝트에 대한 Maintainer 역할이 있는 사용자는 정의된 권한을 볼 수 있습니다.
- 프로젝트에 대해 시크릿 관리자가 활성화되어 있어야 합니다.

프로젝트에 대한 시크릿 권한을 업데이트하려면:

1. 상단 바에서 **Search or go to**를 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **Settings** > **General**을 선택합니다.
1. **Visibility, project features, permissions**를 확장합니다.
1. **GitLab 비밀 관리자** 아래의 **사용자 권한** 섹션에서:
   - **추가**를 선택하여 특정 사용자 또는 역할에 대한 권한 규칙을 추가하세요.
   - 권한 범위를 설정하여 메타데이터 읽기, 값 읽기, 쓰기(생성 및 업데이트) 및 비밀 삭제를 수행할 수 있습니다.

GitLab 19.4 이후에 활성화된 비밀 관리자의 경우 프로젝트의 관리자 역할을 가진 사용자는 기본적으로 읽기 및 쓰기(생성 및 업데이트) 권한을 가집니다. 소유자 역할을 가진 사용자는 이러한 기본 권한을 제거하거나 변경할 수 있습니다.

### 그룹의 경우 {#for-a-group-1}

{{< history >}}

- 최상위 그룹 설정이 GitLab 19.4에서 **설정** > **일반**에서 **설정** > **안전함**으로 [이동](https://gitlab.com/gitlab-org/gitlab/-/issues/605581)되었습니다.

{{< /history >}}

전제 조건:

- 비밀 권한을 관리하려면 그룹의 소유자 역할이 필요합니다. 그룹의 Owner 역할이 있는 사용자만 정의된 권한을 볼 수 있습니다.
- 그룹에 대해 시크릿 관리자가 활성화되어 있어야 합니다.

그룹에 대한 시크릿 권한을 업데이트하려면:

1. 상단 바에서 **Search or go to**를 선택하고 그룹을 찾습니다.
1. 왼쪽 사이드바에서:
   - 최상위 그룹에서 **설정** > **안전함**을 선택하세요.
   - 하위 그룹에서 **설정** > **일반**을 선택하고 **권한 및 그룹 기능**을 확장하세요.
1. **GitLab 비밀 관리자** 아래의 **사용자 권한** 섹션에서:
   - **추가**를 선택하여 특정 사용자 또는 역할에 대한 권한 규칙을 추가하세요.
   - 권한 범위를 설정하여 메타데이터 읽기, 값 읽기, 쓰기(생성 및 업데이트) 및 비밀 삭제를 수행할 수 있습니다.

그룹에 대해 Owner 역할이 있는 사용자는 항상 시크릿 관리자의 모든 작업을 수행할 수 있는 권한을 가집니다.

## 프로젝트 또는 그룹 삭제 {#deletion-of-a-project-or-group}

시크릿이 포함된 [프로젝트를 삭제](../../../user/project/working_with_projects.md#delete-a-project)하거나 [그룹을 삭제](../../../user/group/_index.md#schedule-a-group-for-deletion)할 때:

- 해당 프로젝트 또는 그룹의 시크릿 관리자가 비활성화되며 시크릿 저장 엔진에서 제거됩니다.
- 모든 시크릿이 영구적으로 삭제됩니다.

## 프로젝트 또는 그룹 이전 {#transfer-of-a-project-or-group}

시크릿이 포함된 [프로젝트를 이전](../../../user/project/working_with_projects.md#transfer-a-project)하거나 [그룹을 이전](../../../user/group/manage.md#transfer-a-group)할 때:

- 프로젝트 또는 그룹에 정의된 시크릿은 새 네임스페이스의 프로젝트 또는 그룹으로 이전되지 않습니다.
- 해당 프로젝트 또는 그룹의 시크릿 관리자가 비활성화되며 시크릿 저장 엔진에서 제거됩니다.
- 모든 시크릿이 영구적으로 삭제됩니다.

## 시크릿 교체 알림 {#secret-rotation-notifications}

프로젝트의 Owner 역할이 있는 사용자는 시크릿 구성에 지정된 날짜에 시크릿을 교체하라는 이메일 알림을 받습니다.

## CI/CD가 아닌 작업에서 비밀 액세스 {#access-secrets-from-non-cicd-workloads}

GitLab CI/CD 작업으로 실행되지 않는 작업은 비밀 관리자 API를 통해 비밀을 읽을 수 있습니다. 자세한 내용은 [CI/CD가 아닌 작업에서 비밀 액세스](non_cicd_access.md)를 참조하세요.

## 관련 항목 {#related-topics}

- [GitLab 비밀 관리자 크레딧 사용량](credit_usage.md)
- [변수용 비밀 감사 도구](https://gitlab.com/guided-explorations/secrets-management/secret-audit-tool-for-variables): GitLab 그룹 계층 구조에서 이름이 자격 증명(암호, 토큰, API 키 등)을 보유할 수 있음을 나타내는 CI/CD 변수를 스캔하는 커뮤니티 도구입니다. GitLab 비밀 관리자로 마이그레이션할 변수를 식별하는 데 도움이 되는 HTML 보고서를 생성합니다.

## 문제 해결 {#troubleshooting}

### 오류: `reading from Vault: api error: status code 403` {#error-reading-from-vault-api-error-status-code-403}

CI/CD 파이프라인 작업이 시크릿을 가져오려고 시도할 때 이 오류가 반환될 수 있습니다.

```plaintext
ERROR: Job failed (system failure): resolving secrets: getting secret: get secret data: reading from Vault: api error: status code 403: 1 error occurred: * permission denied
```

이 오류는 작업이 존재하지 않거나 삭제된 시크릿을 가져오려고 시도할 때 발생합니다.

### 오류: `inline auth JWT is required` {#error-inline-auth-jwt-is-required}

CI/CD 파이프라인 작업이 시크릿을 가져오려고 시도할 때 이 오류가 반환될 수 있습니다.

```plaintext
ERROR: Job failed (system failure): resolving secrets: creating vault client: configuring inline auth: inline auth JWT is required
```

이 오류는 시크릿이 속한 프로젝트 또는 그룹에 대해 시크릿 관리자 인스턴스가 아직 프로비저닝되지 않았을 때 발생합니다. 시크릿 관리자 역할이 아직 존재하지 않아 러너가 인증을 구성할 수 없습니다.

이 오류를 해결하려면 프로젝트 또는 그룹에 대해 비밀 관리자를 활성화하세요.

프로비저닝이 완료될 때까지 기다린 후, 파이프라인을 다시 실행하기 전에 시크릿을 생성합니다.

### 오류: `namespace does not have access to GitLab Secrets Manager` {#error-namespace-does-not-have-access-to-gitlab-secrets-manager}

네임스페이스가 GitLab 비밀 관리자에 액세스할 수 없을 때 러너가 요청을 선택하기 전에 GitLab 비밀 관리자에서 비밀을 요청하는 작업이 이 오류로 실패합니다.

#### GitLab.com {#gitlabcom}

GitLab.com의 가능한 원인:

- 평가판이 만료되었습니다.
- 그룹에 사용 가능한 GitLab Credits가 없습니다.
- 온디맨드 청구가 꺼져 있습니다.
- 구독 유예 기간이 만료되었습니다.
- 공개 베타가 종료되었으며 네임스페이스가 옵트인하지 않았습니다.

최상위 그룹에 대한 액세스를 복원하려면 무료 평가판을 시작하거나 비밀 관리자에 대한 온디맨드 청구를 활성화하세요. 구독이 만료된 경우 갱신하세요. 자세한 내용은 [GitLab 비밀 관리자 사용량 및 청구](secrets_manager_billing.md)를 참조하세요.

#### GitLab Self-Managed {#gitlab-self-managed}

GitLab Self-Managed에서 GitLab은 그룹별이 아니라 인스턴스 수준에서 비밀 관리자에 대한 액세스를 해결합니다.

가능한 원인:

- 인스턴스가 평가판 라이선스를 사용 중입니다. 비밀 관리자 평가판은 유료 구독에서만 사용할 수 있습니다.
- 비밀 관리자 평가판이 만료되었습니다.
- 인스턴스 구독에 GitLab 비밀 관리자가 포함되지 않습니다.
- 구독 유예 기간이 만료되었습니다.
- 오프라인 라이선스의 경우 라이선스에 활성 GitLab 비밀 관리자 추가 기능이 포함되지 않습니다.

액세스를 복원하려면 인스턴스 관리자에게 인스턴스 구독에 GitLab 비밀 관리자를 추가해 달라고 요청하세요. 유료 구독이 있는 인스턴스는 무료 평가판을 시작할 수도 있습니다.
