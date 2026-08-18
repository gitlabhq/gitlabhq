---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 감사자 사용자
description: 모든 리소스에 대한 감사 및 규정 준수 모니터링을 위한 읽기 전용 액세스를 제공합니다.
---

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

감사자 사용자는 인스턴스의 모든 그룹, 프로젝트 및 기타 리소스에 대한 읽기 전용 액세스 권한을 가집니다.

감사자 사용자:

- 모든 그룹 및 프로젝트에 대한 읽기 전용 액세스 권한을 가집니다.
  - [알려진 문제](https://gitlab.com/gitlab-org/gitlab/-/issues/542815)로 인해 사용자는 읽기 전용 작업을 수행하려면 리포터, 개발자, 유지보수자 또는 소유자 역할을 가져야 합니다.
- 할당된 역할에 따라 그룹 및 프로젝트에 대한 추가 [권한](../user/permissions.md)을 가질 수 있습니다.
- 개인 네임스페이스에서 그룹, 프로젝트 또는 스니펫을 생성할 수 있습니다.
- Admin 영역을 볼 수 없으며 관리 작업을 수행할 수 없습니다.
- 그룹 또는 프로젝트 설정에 액세스할 수 없습니다.
- [디버그 로깅](../ci/variables/variables_troubleshooting.md#enable-debug-logging)이 활성화된 경우 작업 로그를 볼 수 없습니다.
- [파이프라인 편집기](../ci/pipeline_editor/_index.md)를 포함하여 편집을 위해 설계된 영역에 액세스할 수 없습니다.

감사자 사용자는 다음과 같은 상황에서 사용되기도 합니다:

- 조직에서 전체 GitLab 인스턴스에 걸쳐 보안 정책 규정 준수를 테스트해야 하는 경우. 감사자 사용자는 모든 프로젝트에 추가되거나 관리자 액세스를 부여받지 않고도 이를 수행할 수 있습니다.
- 특정 사용자가 GitLab 인스턴스의 많은 수의 프로젝트를 봐야 하는 경우. 모든 프로젝트에 사용자를 수동으로 추가하는 대신 모든 프로젝트에 자동으로 액세스할 수 있는 감사자 사용자를 생성할 수 있습니다.

> [!note]
> 감사자 사용자는 청구 대상 사용자로 간주되며 라이선스 사용자를 소비합니다.

## 감사자 사용자 생성 {#create-an-auditor-user}

전제 조건:

- 관리자 액세스 권한이 있어야 합니다.

새 감사자 사용자를 생성하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **개요** > **사용자**를 선택합니다.
1. **새 사용자**를 선택합니다.
1. **계정** 섹션에서 필수 계정 정보를 입력합니다.
1. **사용자 유형**의 경우 **감사자**를 선택합니다.
1. **사용자 생성**을 선택합니다.

다음을 사용하여 감사자 사용자를 생성할 수도 있습니다:

- [SAML 그룹](../integration/saml.md#auditor-groups).
- [사용자 API](../api/users.md).
