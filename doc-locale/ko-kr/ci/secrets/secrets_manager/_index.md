---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab 비밀 관리자
ignore_in_report: true
---

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab.com, GitLab Self-Managed
- 상태:  베타

{{< /details >}}

{{< history >}}

- [GitLab 18.3에 도입됨](https://gitlab.com/groups/gitlab-org/-/epics/16319) . [플래그 포함](../../../development/feature_flags/_index.md) `secrets_manager` 및 `ci_tanukey_ui`. 기본적으로 비활성화됨.
- 기능 플래그 `ci_tanukey_ui` GitLab 18.4에서 [제거됨](https://gitlab.com/gitlab-org/gitlab/-/issues/549940).
- GitLab 18.8에서 일부 사용자에게 비공개 베타로 제공되었습니다.
- 그룹 비밀 관리자 [도입됨](https://gitlab.com/groups/gitlab-org/-/work_items/17904) . 18.10에서 비공개 베타 사용자에게 제공됨 [플래그 포함](../../../development/feature_flags/_index.md) `group_secrets_manager`.
- 공개 베타 [GitLab 19.0에 도입됨](https://gitlab.com/groups/gitlab-org/-/work_items/21731).

{{< /history >}}

비밀은 CI/CD 작업이 기능하기 위해 필요한 민감한 정보를 나타냅니다. 비밀은 액세스 토큰, 데이터베이스 자격증명, 개인 키 또는 유사한 항목일 수 있습니다.

기본적으로 항상 작업에 사용 가능한 CI/CD 변수와 달리 비밀은 작업에서 명시적으로 요청해야 합니다.

GitLab 비밀 관리자를 사용하여 프로젝트 및 그룹의 비밀과 자격증명을 안전하게 저장하고 관리합니다.

GitLab 비밀 관리자 공개 베타는 **GitLab Premium and Ultimate** 고객을 위해 제공됩니다. GitLab.com 또는 자체 관리 인스턴스에서 공개 베타를 선택할 수 있습니다.

## GitLab.com에서 선택 {#opt-in-on-gitlabcom}

GitLab.com에서 최상위 그룹 소유자는 그룹에 대해 GitLab 비밀 관리자를 선택할 수 있습니다. 최상위 그룹에서 선택하면 해당 그룹 내의 모든 하위 그룹 및 프로젝트에서 사용할 수 있게 됩니다.

전제 조건:

- 최상위 그룹에 대한 소유자 역할이 있어야 합니다.
- 그룹이 **GitLab Premium or Ultimate** 계층에 있어야 합니다.

선택하려면:

1. 왼쪽 사이드바에서 **검색 또는 이동**을 선택하고 최상위 그룹을 찾습니다.
1. **설정** > **일반**을 선택합니다.
1. **권한 및 그룹 기능**을 확장합니다.
1. **Secrets Manager** 토글을 켭니다.

선택 후 그룹 및 프로젝트 소유자는 하위 그룹 및 프로젝트에 대해 비밀 관리자를 독립적으로 활성화할 수 있습니다. 지침은 [그룹 또는 프로젝트에 대해 활성화](#enable-for-a-group-or-project)를 참조하세요.

## 자체 관리에서 선택 {#opt-in-on-self-managed}

자체 관리 인스턴스에서 관리자는 먼저 인스턴스 수준에서 GitLab 비밀 관리자를 선택해야 합니다. 선택 후 소유자는 그룹 및 프로젝트에 대해 활성화할 수 있습니다.

전제 조건:

- GitLab 인스턴스에 대한 관리자 액세스 권한이 있어야 합니다.
- GitLab 19.0 이상.
- OpenBao를 설치하고 구성해야 합니다. 자세한 내용은 [관리](../../../administration/secrets_manager/_index.md)를 참조하세요.

선택하려면:

1. 왼쪽 사이드바의 맨 아래에서 **운영자**를 선택합니다.
1. **설정** > **일반**을 선택합니다.
1. **GitLab 비밀 관리자**를 확장합니다.
1. **Secrets Manager** 토글을 켭니다.

선택 후 그룹 및 프로젝트 소유자는 네임스페이스에 대해 비밀 관리자를 활성화할 수 있습니다. 지침은 [그룹 또는 프로젝트에 대해 활성화](#enable-for-a-group-or-project)를 참조하세요.

## 그룹 또는 프로젝트에 대해 활성화 {#enable-for-a-group-or-project}

### 프로젝트의 경우 {#for-a-project}

전제 조건:

- 프로젝트에 대한 소유자 역할이 있어야 합니다.

프로젝트에 대해 GitLab 비밀 관리자를 활성화하거나 비활성화하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾으세요.
1. 왼쪽 사이드바에서 **설정** > **일반**을 선택합니다.
1. **표시 여부, 프로젝트 기능, 권한**을 확장합니다.
1. **비밀 관리자** 토글을 켜고 비밀 관리자가 프로비저닝될 때까지 기다립니다.

   > [!warning]
   > 나중에 프로젝트의 비밀 관리자를 비활성화하면 모든 프로젝트 비밀이 영구적으로 삭제됩니다. 이러한 비밀은 복구할 수 없습니다.

프로젝트에 대해 정의된 비밀은 동일한 프로젝트의 파이프라인에서만 액세스할 수 있습니다.

### 그룹의 경우 {#for-a-group}

전제 조건:

- 그룹에 대한 소유자 역할이 있어야 합니다.

그룹에 대해 GitLab 비밀 관리자를 활성화하거나 비활성화하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **일반**을 선택합니다.
1. **권한 및 그룹 기능**을 확장합니다.
1. **비밀 관리자** 토글을 켜고 비밀 관리자가 프로비저닝될 때까지 기다립니다.

   > [!warning]
   > 나중에 그룹의 비밀 관리자를 비활성화하면 모든 그룹 비밀이 영구적으로 삭제됩니다. 이러한 비밀은 복구할 수 없습니다.

그룹에 대해 정의된 비밀은 그룹 아래의 프로젝트 또는 하위 그룹 계층의 파이프라인에서만 액세스할 수 있습니다.

## 비밀 정의 {#define-a-secret}

비밀을 비밀 관리자에 추가하여 보안 CI/CD 파이프라인 및 워크플로우에 사용할 수 있습니다.

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. **보안** > **비밀 관리자**를 선택합니다.
1. **비밀 추가**를 선택하고 세부정보를 입력합니다:
   - **이름**:  프로젝트 내에서 고유해야 합니다.
   - **값**:  10 KB(10,000바이트) 이하여야 합니다.
   - **설명**:  최대 200자입니다.
   - **환경**:  다음과 같을 수 있습니다:
     - **모두 (기본값)** (`*`)
     - 특정 [환경](../../environments/_index.md#types-of-environments).
     - [와일드카드 환경](../../environments/_index.md#limit-the-environment-scope-of-a-cicd-variable).
   - **브랜치**:  옵션은 프로젝트 설정에만 존재합니다. 다음과 같을 수 있습니다:
     - 특정 브랜치.
     - 와일드카드 브랜치(`*` 문자가 있어야 함).
   - **보호됨**:  옵션은 그룹 설정에만 존재합니다. 선택사항. 보호된 브랜치에서 실행되는 파이프라인으로만 비밀을 내보냅니다.
   - **교체 알림**:  선택사항. 설정된 일 수 후에 비밀을 교체하도록 이메일 미리 알림을 보냅니다. 최소 7일입니다.

비밀을 생성한 후 파이프라인 구성 또는 작업 스크립트에서 사용할 수 있습니다.

> [!warning]
> 비밀의 값은 비밀을 생성하거나 업데이트할 때 정의된 특정 환경 또는 브랜치에 대해 실행되는 모든 CI/CD 파이프라인 작업에 액세스할 수 있습니다. 이러한 비밀의 값에 액세스할 수 있는 권한이 있는 사용자만 지정된 환경 또는 브랜치에 대해 작업을 실행할 수 있는지 확인합니다.

## 작업 스크립트에서 비밀 사용 {#use-secrets-in-job-scripts}

### 프로젝트 비밀의 경우 {#for-project-secrets}

전제 조건:

- GitLab 러너 19.0 이상.

비밀 관리자로 정의된 비밀에 액세스하려면 [`secrets`](../../yaml/_index.md#secrets) 및 `gitlab_secrets_manager` 키워드를 사용합니다.

[파일 유형 변수](../../variables/_index.md#use-file-type-cicd-variables)와 유사하게 비밀은 다음과 같은 환경 변수로 제공됩니다:

- 비밀의 키를 환경 변수 이름으로.
- 비밀의 값은 임시 파일에 저장됩니다. 마스킹된 변수와 달리 비밀은 공백과 줄 바꿈을 포함할 수 있습니다.
- 임시 파일의 경로를 환경 변수 값으로.

예를 들어:

```yaml
job:
  secrets:
    KUBE_CA_PEM:
      gitlab_secrets_manager:
        name: kube-cert
  script:
   - kubectl config set-cluster e2e --server="https://example.com" --certificate-authority="$KUBE_CA_PEM"
```

작업이 비밀의 값을 출력하는 경우(예: `cat $KUBE_CA_PEM`를 실행하여) GitLab은 작업 로그의 값을 `[MASKED]`로 바꿉니다.

### 그룹 비밀의 경우 {#for-group-secrets}

전제 조건:

- GitLab 러너 19.0 이상.

그룹 비밀에 액세스하려면:

- [`secrets`](../../yaml/_index.md#secrets) 및 `gitlab_secrets_manager` 키워드를 사용합니다.
- 비밀 관리자 소스를 `source` 필드로 지정하고 형식은 `group/<full-path-to-group>`입니다.

예를 들어:

```yaml
job:
  secrets:
    TEST_SECRET:
      gitlab_secrets_manager:
        name: foo
        source: group/<full-path-to-group>
  script:
   - cat $TEST_SECRET
```

## 비밀 권한 관리 {#manage-secrets-permissions}

### 프로젝트의 경우 {#for-a-project-1}

전제 조건:

- 비밀 권한을 관리하려면 프로젝트에 대한 소유자 역할이 있어야 합니다.
- 프로젝트에 대한 관리자 역할이 있는 사용자는 정의된 권한을 볼 수 있습니다.
- 비밀 관리자를 프로젝트에 대해 활성화해야 합니다.

프로젝트에 대한 비밀 권한을 업데이트하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾으세요.
1. 왼쪽 사이드바에서 **설정** > **일반**을 선택합니다.
1. **표시 여부, 프로젝트 기능, 권한**을 확장합니다.
1. **비밀 관리자** 아래의 **비밀 관리자 사용자 권한** 섹션에서 사용자 권한을 관리할 수 있습니다:
   - **추가**를 선택하여 특정 사용자, 그룹 또는 역할에 대한 권한 규칙을 추가합니다.
   - 읽기, 쓰기(생성 및 업데이트) 및 비밀 삭제에 대한 권한 범위를 설정할 수 있습니다.

### 그룹의 경우 {#for-a-group-1}

전제 조건:

- 비밀 권한을 관리하려면 그룹에 대한 소유자 역할이 있어야 합니다. 그룹에 대한 소유자 역할이 있는 사용자만 정의된 권한을 볼 수 있습니다.
- 비밀 관리자를 그룹에 대해 활성화해야 합니다.

그룹에 대한 비밀 권한을 업데이트하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **일반**을 선택합니다.
1. **권한 및 그룹 기능**을 확장합니다.
1. **비밀 관리자** 아래의 **비밀 관리자 사용자 권한** 섹션에서 사용자 권한을 관리할 수 있습니다:
   - **추가**를 선택하여 특정 사용자, 그룹 또는 역할에 대한 권한 규칙을 추가합니다.
   - 읽기, 쓰기(생성 및 업데이트) 및 비밀 삭제에 대한 권한 범위를 설정할 수 있습니다.

그룹에 대한 소유자 역할이 있는 사용자는 항상 비밀 관리자의 모든 작업을 수행할 수 있는 권한이 있습니다.

## 프로젝트 또는 그룹 삭제 {#deletion-of-a-project-or-group}

[프로젝트 삭제](../../../user/project/working_with_projects.md#delete-a-project) 또는 비밀이 있는 [그룹 삭제](../../../user/group/_index.md#schedule-a-group-for-deletion)를 선택할 때:

- 프로젝트 또는 그룹의 비밀 관리자가 비활성화되고 비밀 저장 엔진에서 제거됩니다.
- 모든 비밀이 영구적으로 삭제됩니다.

## 프로젝트 또는 그룹 전송 {#transfer-of-a-project-or-group}

비밀이 있는 [프로젝트 전송](../../../user/project/working_with_projects.md#transfer-a-project) 또는 [그룹 전송](../../../user/group/manage.md#transfer-a-group)을 선택할 때:

- 프로젝트 또는 그룹에 대해 정의된 비밀은 새 네임스페이스의 프로젝트 또는 그룹으로 전송되지 않습니다.
- 프로젝트 또는 그룹의 비밀 관리자가 비활성화되고 비밀 저장 엔진에서 제거됩니다.
- 모든 비밀이 영구적으로 삭제됩니다.

## 비밀 교체 알림 {#secret-rotation-notifications}

프로젝트의 소유자 역할이 있는 사용자는 비밀 구성에서 지정한 날짜에 비밀을 교체하도록 이메일 알림을 받습니다.

## 일반 가용성 시점의 가격 {#pricing-at-general-availability}

GitLab 비밀 관리자는 공개 베타 중에는 무료이지만 일반 가용성으로 릴리스될 때 GitLab Credits를 사용합니다. 서비스 중단을 방지하기 위해 일반 가용성 전에 알림을 드려 GitLab Credits에 대해 온디맨드 청구를 선택할 수 있는 시간을 제공합니다.

## 피드백 제공 {#provide-feedback}

공개 베타 중에 피드백을 공유하거나 이슈를 보고하려면 [GitLab 비밀 관리자: 공개 베타의 고객 피드백](https://gitlab.com/gitlab-org/gitlab/-/work_items/598100) 이슈를 사용합니다.

## 문제 해결 {#troubleshooting}

### 오류: `reading from Vault: api error: status code 403` {#error-reading-from-vault-api-error-status-code-403}

CI/CD 파이프라인 작업이 비밀을 가져오려고 시도하면 이 오류가 반환될 수 있습니다:

```plaintext
ERROR: Job failed (system failure): resolving secrets: getting secret: get secret data: reading from Vault: api error: status code 403: 1 error occurred: * permission denied
```

이 오류는 작업이 존재하지 않거나 삭제된 비밀을 가져오려고 시도할 때 발생합니다.

### 오류: `inline auth JWT is required` {#error-inline-auth-jwt-is-required}

CI/CD 파이프라인 작업이 비밀을 가져오려고 시도하면 이 오류가 반환될 수 있습니다:

```plaintext
ERROR: Job failed (system failure): resolving secrets: creating vault client: configuring inline auth: inline auth JWT is required
```

이 오류는 프로젝트 또는 비밀이 속할 것으로 예상되는 그룹에 대해 비밀 관리자 인스턴스가 아직 프로비저닝되지 않았을 때 발생합니다. 러너는 비밀 관리자 역할이 아직 존재하지 않기 때문에 인증을 구성할 수 없습니다.

이 오류를 해결하려면 프로젝트 또는 그룹에 대해 [비밀 관리자 활성화](#enable-for-a-group-or-project)를 선택합니다.

프로비저닝이 완료될 때까지 기다렸다가 파이프라인을 다시 실행하기 전에 비밀을 생성합니다.
