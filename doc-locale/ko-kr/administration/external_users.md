---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 외부 사용자
description: 특정 리소스에 대해 제한된 권한으로 외부 멤버에게 제한된 액세스 권한을 부여합니다.
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

외부 사용자는 인스턴스의 내부 또는 비공개 그룹과 프로젝트에 대한 제한된 액세스 권한을 가집니다. 일반 사용자와 달리 외부 사용자는 명시적으로 그룹 또는 프로젝트에 추가되어야 합니다. 그러나 일반 사용자처럼 외부 사용자는 멤버 역할이 할당되고 관련된 모든 [권한](../user/permissions.md#project-permissions)을 얻습니다.

외부 사용자:

- 공개 그룹, 프로젝트 및 스니펫에 액세스할 수 있습니다.
- 멤버인 내부 또는 비공개 그룹과 프로젝트에 액세스할 수 있습니다.
- 멤버인 모든 최상위 그룹에서 부분군, 프로젝트 및 스니펫을 생성할 수 있습니다.
- 개인 네임스페이스에서 그룹, 프로젝트 또는 스니펫을 생성할 수 없습니다.

외부 사용자는 조직 외부의 사용자가 특정 프로젝트에만 액세스해야 할 때 일반적으로 생성됩니다. 외부 사용자에게 역할을 할당할 때는 역할과 관련된 [프로젝트 가시성](../user/public_access.md#change-project-visibility) 및 [권한](../user/project/settings/_index.md#configure-project-features-and-permissions)을 알아야 합니다. 예를 들어 외부 사용자가 비공개 프로젝트에 대해 게스트 역할이 할당되면 코드에 액세스할 수 없습니다.

> [!note]
> 외부 사용자는 청구 가능한 사용자로 계산되며 라이선스 사용자를 소비합니다.
>
> 외부 공급자 목록을 [생성](../integration/omniauth.md#create-an-external-providers-list)한 경우 나열된 공급자로 로그인한 사용자는 자동으로 외부로 표시됩니다.

## 외부 사용자 생성 {#create-an-external-user}

전제 조건:

- 관리자 액세스 권한이 있어야 합니다.

새 외부 사용자를 생성하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **개요** > **사용자**를 선택합니다.
1. **새 사용자**를 선택합니다.
1. **계정** 섹션에서 필수 계정 정보를 입력합니다.
1. 선택사항. **액세스** 섹션에서 프로젝트 제한 또는 사용자 유형 설정을 구성합니다.
1. **외부** 확인란을 선택합니다.
1. **사용자 생성**을 선택합니다.

다음을 사용하여 외부 사용자를 생성할 수도 있습니다:

- [SAML 그룹](../integration/saml.md#external-groups).
- [LDAP 그룹](auth/ldap/ldap_synchronization.md#external-groups).
- [외부 공급자 목록](../integration/omniauth.md#create-an-external-providers-list).
- [사용자 API](../api/users.md).

## 기본으로 새 사용자를 외부로 설정 {#make-new-users-external-by-default}

인스턴스를 구성하여 기본적으로 모든 새 사용자를 외부로 설정할 수 있습니다. 나중에 이 사용자 계정을 수정하여 외부 지정을 제거할 수 있습니다.

이 기능을 구성할 때 이메일 주소를 식별하는 데 사용되는 정규식을 정의할 수도 있습니다. 일치하는 이메일을 가진 새 사용자는 제외되며 외부 사용자로 표시되지 않습니다. 이 정규식은 다음을 충족해야 합니다:

- Ruby 형식을 사용합니다.
- JavaScript로 변환할 수 있습니다.
- 대소문자를 무시하는 플래그 세트(`/regex pattern/i`)를 가집니다.

예를 들어:

- `\.int@example\.com$`:  `.int@domain.com`로 끝나는 이메일 주소와 일치합니다.
- `^(?:(?!\.ext@example\.com).)*$\r?`:  `.ext@example.com`를 포함하지 않는 이메일 주소와 일치합니다.

> [!warning]
> 정규식을 추가하면 정규식 거부 서비스(ReDoS) 공격의 위험이 증가할 수 있습니다.

전제 조건:

- GitLab Self-Managed 인스턴스의 관리자여야 합니다.

새 사용자를 기본으로 외부로 설정하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **Settings** > **General**을 선택합니다.
1. **계정과 제한** 섹션을 확장합니다.
1. **기본으로 새 사용자를 외부로 설정** 확인란을 선택합니다.
1. 선택사항. **이메일 제외 패턴** 필드에 정규식을 입력합니다.
1. **변경 사항 저장**을 선택합니다.
