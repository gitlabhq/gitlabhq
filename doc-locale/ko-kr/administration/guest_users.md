---
stage: Software Supply Chain Security
group: Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 게스트 사용자
description: 항목 수준 사용자 역할로 제한된 권한이 있는 기본 액세스를 할당합니다.
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

게스트 역할이 있는 사용자는 다른 사용자 역할에 비해 제한된 액세스 및 기능을 갖습니다. 해당 사용자의 [권한](../user/permissions.md)은 제한되며 민감한 프로젝트 데이터를 손상시키지 않으면서 기본 가시성과 상호 작용만 제공하도록 설계되었습니다.

게스트 역할이 있는 사용자:

- 공개 그룹 및 프로젝트에 액세스할 수 있습니다.
- 프로젝트 계획, 차단 항목 및 진행 지표를 볼 수 있습니다.
- 새로운 프로젝트 작업 항목을 만들고 링크할 수 있습니다.
- 다음과 같은 높은 수준의 프로젝트 정보를 볼 수 있습니다:
  - 분석
  - 사건 보고
  - 이슈 및 에픽
  - 라이선스
- 개인 네임스페이스에서 프로젝트, 그룹 및 코드 조각을 만들 수 없습니다.
- 자신이 생성하지 않은 기존 데이터를 수정할 수 없습니다.
- 프로젝트에서 코드를 볼 수 없습니다.

## 사용자 사용 현황 {#seat-usage}

- GitLab Free 및 Premium에서 게스트 역할이 있는 사용자는 청구 가능한 사용자로 계산되며 라이선스 사용자를 소비합니다.
- GitLab Ultimate에서 게스트 역할이 있는 사용자는 청구 가능한 사용자로 계산되지 않으며 라이선스 사용자를 소비하지 않습니다.

> [!note]
> 게스트 역할이 일반적으로 제한된 액세스를 제공하는 동안 [사용자 지정 역할](../user/custom_roles/_index.md) 을 만들고 [`View repository code`](../user/custom_roles/abilities.md#source-code-management) 권한을 사용하면 라이선스 사용자를 소비하지 않고 리포지토리의 코드에 액세스할 수 있습니다. 다른 권한을 추가하면 역할이 청구 가능한 사용자를 차지합니다.

## 게스트 역할을 사용자에게 할당 {#assign-guest-role-to-users}

전제 조건:

- 유지 관리자 또는 소유자 역할이 있어야 합니다.

그룹 또는 프로젝트의 현재 멤버에게 게스트 역할을 할당하거나 새로운 멤버를 만들 때 이 역할을 할당할 수 있습니다. API(for [groups](../api/group_members.md#add-a-group-member) 또는 [projects](../api/project_members.md#add-a-member-to-a-project)) 또는 GitLab UI를 통해 이를 수행할 수 있습니다.

현재 그룹 또는 프로젝트 멤버에게 게스트 역할을 할당하려면:

1. 상단 바에서 **Search or go to**를 선택하고 그룹 또는 프로젝트를 찾습니다.
1. **관리** > **멤버**를 선택하세요.
1. **역할** 열에서 게스트 역할을 할당하려는 그룹 또는 프로젝트 멤버의 현재 역할(예: **개발자**)을 선택하세요.
1. **역할 세부정보** 드로어에서 역할을 **게스트**로 변경하세요.
1. **역할 업데이트**를 선택하세요.

게스트 역할을 할당하려는 사용자가 아직 그룹 또는 프로젝트의 멤버가 아닌 경우:

1. 상단 바에서 **Search or go to**를 선택하고 그룹 또는 프로젝트를 찾습니다.
1. **관리** > **멤버**를 선택하세요.
1. **멤버 초대**를 선택하세요.
1. **사용자명, 이름 또는 이메일 주소**에서 관련 사용자를 선택하세요.
1. **역할 선택**에서 **게스트**를 선택하세요.
1. 선택사항. **액세스 만료일**에 날짜를 입력하세요.
1. **초대**를 선택하세요.
