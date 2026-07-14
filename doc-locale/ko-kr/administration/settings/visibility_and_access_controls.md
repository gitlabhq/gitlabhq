---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: yes
description: "프로젝트 공개 범위, 생성, 보존 및 삭제를 제어합니다."
title: 액세스 및 공개 범위 제어
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab 인스턴스의 운영자는 브랜치, 프로젝트, 스니펫, 그룹 등에 대한 특정 제어를 적용할 수 있습니다. 예를 들어 다음을 정의할 수 있습니다:

- 프로젝트를 생성하거나 삭제할 수 있는 역할
- 삭제된 프로젝트 및 그룹의 보존 기간
- 그룹, 프로젝트 및 스니펫의 공개 범위
- SSH 키에 허용되는 유형 및 길이
- 허용된 프로토콜(SSH 또는 HTTPS)과 클론 URL과 같은 Git 설정
- 푸시 미러링 및 풀 미러링을 허용하거나 방지합니다.

전제 조건:

- 관리자(administrator) 권한이 있어야 합니다.

공개 범위 및 액세스 제어 옵션에 액세스하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **Settings** > **General**을 선택합니다.
1. **공개 범위 및 액세스 설정**을 확장합니다.

## 프로젝트를 생성할 수 있는 역할 정의 {#define-which-roles-can-create-projects}

인스턴스에 프로젝트 생성 보호를 추가할 수 있습니다. 이러한 보호는 인스턴스에서 [그룹에 프로젝트를 추가](../../user/group/_index.md#specify-who-can-add-projects-to-a-group)할 수 있는 역할을 정의합니다.

**프로젝트를 생성하는 데 필요한 기본 최소 역할** 설정을 구성하면 새 그룹의 기본값을 설정합니다. 기존 그룹은 현재 권한을 유지합니다.

전제 조건:

- 관리자(administrator) 권한이 있어야 합니다.

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **Settings** > **General**을 선택합니다.
1. **공개 범위 및 액세스 설정**을 확장합니다.
1. **프로젝트를 생성하는 데 필요한 기본 최소 역할**에서 원하는 역할을 선택합니다:
   - 아무도 없음
   - 운영자
   - 소유자
   - 유지관리자
   - 개발자
1. **변경 사항 저장**을 선택합니다.

> [!note]
> **운영자**를 선택하고 [관리자 모드](sign_in_restrictions.md#admin-mode)가 활성화되어 있으면 운영자는 새 프로젝트를 생성하려면 관리자 모드를 입력해야 합니다.

## 운영자에게만 프로젝트 삭제 제한 {#restrict-project-deletion-to-administrators}

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

전제 조건:

- 운영자이거나 프로젝트에서 소유자 역할을 가져야 합니다.

프로젝트 삭제를 운영자에게만 제한하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **Settings** > **General**을 선택합니다.
1. **공개 범위 및 액세스 설정**을 확장합니다.
1. **프로젝트 삭제 허용됨**으로 스크롤하고 **운영자**를 선택합니다.
1. **변경 사항 저장**을 선택합니다.

제한을 비활성화하려면:

1. **소유자 및 운영자**를 선택합니다.
1. **변경 사항 저장**을 선택합니다.

## 삭제 보호 {#deletion-protection}

{{< history >}}

- GitLab 16.0에서 [일반 공개](https://gitlab.com/gitlab-org/gitlab/-/issues/389557) Premium 및 Ultimate만 해당.
- GitLab 18.0에서 GitLab Premium에서 GitLab Free로 [이동](https://gitlab.com/groups/gitlab-org/-/epics/17208)

{{< /history >}}

삭제 보호는 인스턴스에서 그룹 및 프로젝트의 실수로 인한 삭제를 방지합니다.

### 보존 기간 {#retention-period}

그룹 및 프로젝트는 정의한 보존 기간 동안 복원 가능한 상태로 유지됩니다. 기본적으로 보존 기간은 30일이지만 `1`에서 `90` 일 사이의 값으로 변경할 수 있습니다.

전제 조건:

- 운영자 액세스 권한이 있어야 합니다.

그룹 및 프로젝트에 대한 삭제 보호를 구성하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **Settings** > **General**을 선택합니다.
1. **공개 범위 및 액세스 설정**을 확장합니다.
1. **보존 기간**으로 스크롤하고 보존 기간을 `1`에서 `90` 일 사이의 값으로 설정합니다.
1. **변경 사항 저장**을 선택합니다.

### 기본값 무시 및 영구 삭제 {#override-defaults-and-delete-permanently}

지연을 무시하고 삭제하도록 표시된 프로젝트를 영구적으로 삭제하려면:

1. [프로젝트 복원](../../user/project/working_with_projects.md#restore-a-project)
1. [프로젝트 관리](../admin_area.md#administering-projects)에서 설명한 대로 프로젝트를 삭제합니다.

## 프로젝트 공개 범위 기본값 구성 {#configure-project-visibility-defaults}

기본 [새 프로젝트의 공개 범위 수준](../../user/public_access.md)을 설정하려면:

전제 조건:

- 관리자(administrator) 권한이 있어야 합니다.

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **Settings** > **General**을 선택합니다.
1. **공개 범위 및 액세스 설정**을 확장합니다.
1. 원하는 기본 프로젝트 공개 범위를 선택합니다:
   - **비공개** \- 각 사용자에게 명시적으로 프로젝트 액세스 권한을 부여합니다. 이 프로젝트가 그룹의 일부인 경우 그룹 멤버에게 액세스 권한을 부여합니다.
   - **내부** \- 외부 사용자를 제외한 모든 인증된 사용자가 프로젝트에 액세스할 수 있습니다.
   - **공개** \- 모든 사용자가 인증 없이 프로젝트에 액세스할 수 있습니다.
1. **변경 사항 저장**을 선택합니다.

## 스니펫 공개 범위 기본값 구성 {#configure-snippet-visibility-defaults}

새 [스니펫](../../user/snippets.md)의 기본 공개 범위 수준을 설정하려면:

전제 조건:

- 관리자(administrator) 권한이 있어야 합니다.

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **Settings** > **General**을 선택합니다.
1. **공개 범위 및 액세스 설정**을 확장합니다.
1. **Default snippet visibility**에서 원하는 공개 범위 수준을 선택합니다:
   - **비공개**
   - **내부** 이 설정은 GitLab.com의 새 프로젝트, 그룹 및 스니펫에 대해 비활성화됩니다. `Internal` 공개 범위 설정을 사용하는 기존 스니펫은 이 설정을 유지합니다. 이 변경 사항에 대해 자세히 알아보려면 [이슈 12388](https://gitlab.com/gitlab-org/gitlab/-/issues/12388)을 참조하세요.
   - **공개**
1. **변경 사항 저장**을 선택합니다.

## 그룹 공개 범위 기본값 구성 {#configure-group-visibility-defaults}

새 그룹의 기본 공개 범위 수준을 설정하려면:

전제 조건:

- 관리자(administrator) 권한이 있어야 합니다.

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **Settings** > **General**을 선택합니다.
1. **공개 범위 및 액세스 설정**을 확장합니다.
1. **Default group visibility**에서 원하는 공개 범위 수준을 선택합니다:
   - **비공개** \- 멤버만 그룹 및 해당 프로젝트를 볼 수 있습니다.
   - **내부** \- 외부 사용자를 제외한 모든 인증된 사용자가 그룹 및 모든 내부 프로젝트를 볼 수 있습니다.
   - **공개** \- 그룹 및 모든 공개 프로젝트를 보기 위해 인증이 필요하지 않습니다.
1. **변경 사항 저장**을 선택합니다.

그룹 공개 범위에 대해 자세히 알아보려면 [그룹 공개 범위](../../user/group/_index.md#group-visibility)를 참조하세요.

## 공개 범위 수준 제한 {#restrict-visibility-levels}

{{< history >}}

- GitLab 16.3에서 기본 프로젝트 및 그룹 공개 범위 제한을 방지하도록 [변경](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/124649)되었으며, `prevent_visibility_restriction` 이름의 [플래그](../feature_flags/_index.md)가 있습니다. 기본적으로 비활성화됨.
- `prevent_visibility_restriction` GitLab 16.4에서 기본적으로 [활성화](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/131203)
- `prevent_visibility_restriction` GitLab 16.7에서 [제거](https://gitlab.com/gitlab-org/gitlab/-/issues/433280)

{{< /history >}}

공개 범위 수준을 제한할 때 이러한 제한이 변경 중인 항목에서 공개 범위를 상속하는 하위 그룹 및 프로젝트의 권한과 어떻게 상호 작용하는지 고려합니다.

이 설정은 개인 네임스페이스에서 생성된 프로젝트에는 적용되지 않습니다. 이 기능을 [엔터프라이즈 사용자](../../user/enterprise_user/_index.md) 로 확장하기 위한 [기능 요청](https://gitlab.com/gitlab-org/gitlab/-/issues/382749)이 있습니다.

그룹, 프로젝트, 스니펫 및 선택한 페이지에 대해 공개 범위 수준을 제한하려면:

전제 조건:

- 관리자(administrator) 권한이 있어야 합니다.

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **Settings** > **General**을 선택합니다.
1. **공개 범위 및 액세스 설정**을 확장합니다.
1. **제한된 공개 수준**에서 제한할 원하는 공개 범위 수준을 선택합니다.
   - **공개** 수준을 제한하는 경우:
     - 운영자만 공개 그룹, 프로젝트 및 스니펫을 생성할 수 있습니다.
     - 사용자 프로필은 웹 인터페이스를 통해 인증된 사용자에게만 표시됩니다.
     - 사용자 속성은 GraphQL API를 통해 표시되지 않습니다.
   - **내부** 수준을 제한하는 경우:
     - 운영자만 내부 그룹, 프로젝트 및 스니펫을 생성할 수 있습니다.
   - **비공개** 수준을 제한하는 경우:
     - 운영자만 비공개 그룹, 프로젝트 및 스니펫을 생성할 수 있습니다.
1. **변경 사항 저장**을 선택합니다.

> [!note]
> 새 프로젝트 또는 그룹의 기본값으로 설정된 공개 범위 수준을 제한할 수 없습니다. 반대로 새 프로젝트 또는 그룹의 기본값으로 제한된 공개 범위 수준을 설정할 수 없습니다.

## 활성화된 Git 액세스 프로토콜 구성 {#configure-enabled-git-access-protocols}

GitLab 액세스 제한을 사용하면 사용자가 GitLab과 통신하는 데 사용할 수 있는 프로토콜을 선택할 수 있습니다. 액세스 프로토콜을 비활성화해도 서버 자체에 대한 포트 액세스는 차단되지 않습니다. 프로토콜(SSH 또는 HTTP(S))에 사용되는 포트는 여전히 액세스 가능합니다. GitLab 제한은 애플리케이션 수준에서 적용됩니다.

GitLab은 선택한 프로토콜에 대해서만 Git 작업을 허용합니다:

- SSH와 HTTP(S)를 모두 활성화하면 사용자가 두 프로토콜 중 하나를 선택할 수 있습니다.
- 프로토콜을 하나만 활성화하면 프로젝트 페이지에는 허용된 프로토콜의 URL만 표시되며 변경 옵션이 없습니다.

인스턴스의 모든 프로젝트에 대해 활성화된 Git 액세스 프로토콜을 지정하려면:

전제 조건:

- 관리자(administrator) 권한이 있어야 합니다.

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **Settings** > **General**을 선택합니다.
1. **공개 범위 및 액세스 설정**을 확장합니다.
1. **활성화된 Git 액세스 프로토콜**에서 원하는 프로토콜을 선택합니다:
   - SSH와 HTTP(S) 모두
   - SSH만
   - HTTP(S)만
1. **변경 사항 저장**을 선택합니다.

> [!warning]
> GitLab은 [GitLab CI/CD 작업 토큰](../../ci/jobs/ci_job_token.md) 으로 수행되는 Git 클론 또는 페치 요청에 대해 [HTTP(S) 프로토콜을 허용](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/18021)합니다. 이는 GitLab 러너 및 CI/CD 작업이 이 설정을 필요로 하기 때문에 **SSH만**을 선택해도 발생합니다.

## HTTP(S)용 Git 클론 URL 사용자 지정 {#customize-git-clone-url-for-https}

{{< details >}}

- 제공 서비스: GitLab Self-Managed

{{< /details >}}

프로젝트 Git 클론 URL을 HTTP(S)용으로 사용자 지정할 수 있으며, 이는 프로젝트 페이지의 사용자에게 표시되는 클론 패널에 영향을 줍니다. 예를 들어:

- GitLab 인스턴스가 `https://example.com`에 있으면 프로젝트 클론 URL은 `https://example.com/foo/bar.git`과 유사합니다.
- 대신 `https://git.example.com/gitlab/foo/bar.git`과 같은 클론 URL을 원하면 이 설정을 `https://git.example.com/gitlab/`로 설정할 수 있습니다.

`gitlab.rb`에서 HTTP(S)용 사용자 지정 Git 클론 URL을 지정하려면 `gitlab_rails['gitlab_ssh_host']`의 새 값을 설정합니다. GitLab UI에서 새 값을 지정하려면:

전제 조건:

- 관리자(administrator) 권한이 있어야 합니다.

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **Settings** > **General**을 선택합니다.
1. **공개 범위 및 액세스 설정**을 확장합니다.
1. **HTTP(S)용 커스텀 Git 클론 URL**의 루트 URL을 입력합니다.
1. **변경 사항 저장**을 선택합니다.

## RSA, DSA, ECDSA, ED25519, ECDSA_SK, ED25519_SK SSH 키에 대한 기본값 구성 {#configure-defaults-for-rsa-dsa-ecdsa-ed25519-ecdsa_sk-ed25519_sk-ssh-keys}

이 옵션은 SSH 키에 대한 [허용되는 유형 및 길이](../../security/ssh_keys_restrictions.md)를 지정합니다.

각 키 유형에 대한 제한을 지정하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **Settings** > **General**을 선택합니다.
1. **공개 범위 및 액세스 설정**을 확장합니다.
1. **RSA SSH keys**로 이동합니다.
1. 각 키 유형에 대해 사용을 전체적으로 허용하거나 방지하거나 다음의 길이만 허용할 수 있습니다:
   - 최소 1024비트
   - 최소 2048비트
   - 최소 3072비트
   - 최소 4096비트
   - 최소 1024비트
1. **변경 사항 저장**을 선택합니다.

## 프로젝트 미러링 활성화 {#enable-project-mirroring}

GitLab은 기본적으로 프로젝트 미러링을 활성화합니다. 비활성화하면 [풀 미러링](../../user/project/repository/mirror/pull.md) 및 [푸시 미러링](../../user/project/repository/mirror/push.md) 모두 모든 리포지토리에서 더 이상 작동하지 않습니다. 운영자 사용자만 프로젝트별로 다시 활성화할 수 있습니다.

인스턴스의 프로젝트 유지관리자가 프로젝트별로 미러링을 구성할 수 있도록 하려면:

전제 조건:

- 관리자(administrator) 권한이 있어야 합니다.

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **리포지토리**를 선택합니다.
1. **리포지토리 미러링**을 확장합니다.
1. **프로젝트 유지관리자가 리포지토리 미러링을 구성하도록 허용**을 선택합니다.
1. **변경 사항 저장**을 선택합니다.

## 전역적으로 허용되는 IP 주소 범위 구성 {#configure-globally-allowed-ip-address-ranges}

운영자는 [그룹별 IP 제한](../../user/group/access_and_permissions.md#restrict-group-access-by-ip-address)과 IP 주소 범위를 결합할 수 있습니다. 전역적으로 허용되는 IP 주소는 그룹이 자신의 IP 주소 제한을 설정할 때에도 GitLab 설치의 여러 측면이 제대로 작동하도록 합니다.

예를 들어 GitLab Pages 데몬이 `10.0.0.0/24` 범위에서 실행되면 해당 범위를 전역적으로 허용합니다. GitLab Pages는 그룹의 IP 주소 제한에 `10.0.0.0/24` 범위가 포함되지 않더라도 여전히 파이프라인에서 아티팩트를 가져올 수 있습니다.

그룹의 허용 목록에 IP 주소 범위를 추가하려면:

전제 조건:

- 관리자(administrator) 권한이 있어야 합니다.

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **Settings** > **General**을 선택합니다.
1. **공개 범위 및 액세스 설정**을 확장합니다.
1. **전역적으로 허용되는 IP 범위**에서 IP 주소 범위 목록을 제공합니다. 이 목록:
   - IP 주소 범위의 개수에 대한 제한이 없습니다.
   - SSH 또는 HTTP 승인된 IP 주소 범위에 모두 적용됩니다. 이 목록을 권한 부여 유형별로 분할할 수 없습니다.
1. **변경 사항 저장**을 선택합니다.

## 그룹 및 프로젝트에 대한 초대 방지 {#prevent-invitations-to-groups-and-projects}

{{< history >}}

- GitLab 18.0에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/189954) 기본적으로 비활성화됨.

{{< /history >}}

운영자는 운영자가 아닌 사용자가 인스턴스의 모든 그룹 또는 프로젝트에 사용자를 초대하는 것을 방지할 수 있습니다. 이 설정을 구성하면 운영자만 인스턴스의 그룹 또는 프로젝트에 사용자를 초대할 수 있습니다.

> [!note]
> [공유](../../user/project/members/sharing_projects_groups.md) 또는 [마이그레이션](../../user/import/_index.md)과 같은 기능은 여전히 이러한 그룹 및 프로젝트에 대한 액세스를 허용할 수 있습니다.

전제 조건:

- 관리자(administrator) 권한이 있어야 합니다.

초대를 방지하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **Settings** > **General**을 선택합니다.
1. **공개 범위 및 액세스 설정**을 확장합니다.
1. **Prevent group member invitations** 체크박스를 선택합니다.
1. **변경 사항 저장**을 선택합니다.

## GitLab 크레딧 사용자 데이터 표시 {#display-gitlab-credits-user-data}

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- 사용자 데이터의 표시를 허용하는 인스턴스 설정이 GitLab 18.7에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/214538)되었으며, `usage_billing_dev` 이름의 [플래그](../feature_flags/_index.md)가 있습니다. [기본적으로 활성화](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/215714)
- 기능 플래그 `usage_billing_dev`이 GitLab 18.10에서 [제거](https://gitlab.com/gitlab-org/gitlab/-/work_items/566581)

{{< /history >}}

전제 조건:

- 관리자(administrator) 권한이 있어야 합니다.

[GitLab 크레딧 대시보드](../../subscriptions/gitlab_credits.md#gitlab-credits-dashboard)에서 사용자 데이터 표시를 활성화하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **Settings** > **General**을 선택합니다.
1. **공개 범위 및 액세스 설정**을 확장합니다.
1. **GitLab 크레딧 대시보드**에서 **사용자 데이터 표시** 체크박스를 선택합니다.
1. **변경 사항 저장**을 선택합니다.
