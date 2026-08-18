---
stage: Facilitated functionality
group: Facilitated functionality
info: For more information, see <https://handbook.gitlab.com/handbook/product/categories/#facilitated-functionality>
description: GitLab 인스턴스를 관리하고 UI에서 기능을 구성합니다.
title: GitLab 운영자 영역
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

**운영자** 영역은 GitLab Self-Managed 인스턴스의 기능을 관리하고 구성하는 웹 UI를 제공합니다. 운영자인 경우 **운영자** 영역에 접근하려면:

- GitLab 18.5 이상:
  - 오른쪽 위 모서리에서 **Admin**을 선택합니다.
  - 상단 표시줄에서 **검색 또는 이동**을 선택한 다음 **운영자 영역**을 선택합니다.
- GitLab 17.3 이상: 왼쪽 사이드바 아래에서 **운영자**를 선택합니다.
- GitLab 16.7 이상: 왼쪽 사이드바 아래에서 **운영자 영역**을 선택합니다.
- GitLab 16.1 이상: 왼쪽 사이드바에서 **검색 또는 이동**을 선택한 다음 **운영자**를 선택합니다.
- GitLab 16.0 이상: 상단 표시줄에서 **Main menu** > **운영자**를 선택합니다.

GitLab 인스턴스가 관리자 모드를 사용하는 경우 [세션에 대해 관리자 모드 활성화](settings/sign_in_restrictions.md#turn-on-admin-mode-for-your-session)를 해야 **운영자**가 표시됩니다.

> [!note]
> GitLab Self-Managed 또는 GitLab Dedicated의 운영자만 **운영자** 영역에 접근할 수 있습니다. GitLab.com에서는 **운영자** 영역 기능을 사용할 수 없습니다.

## 프로젝트 관리 {#administering-projects}

{{< history >}}

- 새 모양이 GitLab 18.2에서 [도입](https://gitlab.com/groups/gitlab-org/-/epics/17782) 되었으며 [플래그](feature_flags/_index.md) `admin_projects_vue`를 사용합니다. 기본적으로 비활성화됨.
- GitLab 18.3에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/549452)합니다. 기능 플래그 `admin_projects_vue` 제거됨.

{{< /history >}}

GitLab 인스턴스의 모든 프로젝트를 관리하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **개요** > **프로젝트**를 선택합니다. 페이지에 각 프로젝트의 다음 항목이 표시됩니다:

   - 이름
   - 설명
   - 가시성 수준
   - 역할
   - 주제
   - 상태
   - 저장소 크기
   - 별 개수
   - 포크 개수
   - 머지 리퀘스트 개수
   - 이슈 개수

1. 선택사항. 탭을 선택합니다:

   - **활성**은 모든 활성 프로젝트를 표시합니다.
   - **비활성**은 보관되었거나 삭제 대기 중인 프로젝트를 표시합니다.

1. 선택사항. 필터를 결합하여 원하는 프로젝트를 찾습니다. 필터링 기준:

   - 이름. 최소 3자를 입력해야 합니다.
   - 공개, 내부 또는 비공개인 표시 여부.
   - 프로그래밍 언어.
   - 그룹 또는 사용자 네임스페이스.
   - 소유자 역할이 있는 프로젝트.

1. 선택사항. 정렬 순서를 변경하려면 정렬 드롭다운 목록을 선택하고 원하는 순서를 선택합니다. 사용 가능한 정렬 옵션은:

   - 이름
   - 생성 날짜
   - 업데이트 날짜
   - 별
   - 저장소 크기

### 프로젝트 편집 {#edit-a-project}

**운영자** 영역의 프로젝트 페이지에서 프로젝트의 이름 또는 설명을 편집하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **개요** > **프로젝트**를 선택합니다.
1. 편집할 프로젝트를 찾아 **조치** ({{< icon name="ellipsis_v" >}}) > **편집**을 선택합니다.
1. **프로젝트 이름** 또는 **프로젝트 설명**을 편집합니다.
1. **변경 사항 저장**을 선택합니다.

### 프로젝트 삭제 {#delete-a-project}

프로젝트를 삭제하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **개요** > **프로젝트**를 선택합니다.
1. 편집할 프로젝트를 찾아 **조치** ({{< icon name="ellipsis_v" >}}) > **삭제**를 선택합니다.
1. 확인 대화에서 **예, 프로젝트를 삭제합니다.**를 선택합니다.

## 사용자 관리 {#administering-users}

{{< history >}}

- 사용자 필터링이 GitLab 17.0에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/238183)되었습니다.

{{< /history >}}

**운영자** 영역의 사용자 페이지는 각 사용자에 대해 다음 정보를 표시합니다:

- 사용자명
- 이메일 주소
- 프로젝트 멤버십 수
- 그룹 멤버십 수
- 계정 생성 날짜
- 마지막 활동 날짜

**운영자** 영역의 사용자 페이지에서 모든 사용자를 관리하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **개요** > **사용자**를 선택합니다.
1. 선택사항. 정렬 순서를 변경하려면 (기본값: 사용자명):

   1. 정렬 드롭다운 목록을 선택합니다.
   1. 원하는 순서를 선택합니다.

1. 선택사항. 사용자 검색 상자를 사용하여 다음 기준으로 사용자를 검색하고 필터링합니다:

   - 사용자 **access level**.
   - **이중 인증**이 활성화되었는지 비활성화되었는지 여부.
   - 사용자 **state**.
   - 사용자 **type**이 [placeholder](../user/import/mapping/post_migration_mapping.md#placeholder-users)인지 여부.

1. 선택사항. 사용자 검색 필드에 텍스트를 입력한 다음 <kbd>Enter</kbd>를 누릅니다. 이 대소문자를 구분하지 않는 텍스트 검색은 이름, 사용자명 및 이메일에 부분 일치를 적용합니다.

사용자를 편집하려면 사용자의 행을 찾아 **편집**을 선택합니다.

### 사용자 삭제 {#delete-a-user}

**운영자** 영역의 사용자 페이지에서 사용자를 삭제하거나 사용자와 해당 기여도를 삭제하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **개요** > **사용자**를 선택합니다.
1. 삭제할 사용자를 찾습니다. 행에서 **사용자 관리** ({{< icon name="ellipsis_v" >}})를 선택한 다음 원하는 옵션을 선택합니다.

### 사용자 대리(Impersonation) {#user-impersonation}

운영자는 다른 운영자를 포함한 다른 사용자를 대리할 수 있습니다. 이를 통해 GitLab에서 사용자가 보는 것을 확인하고 사용자를 대신하여 조치를 취할 수 있습니다.

사용자를 대리하려면:

- UI를 통해:
  1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
  1. 왼쪽 사이드바에서 **개요** > **사용자**를 선택합니다.
  1. 사용자 목록에서 사용자를 선택합니다.
  1. 오른쪽 상단에서 **대리하기(Impersonate)**를 선택합니다.
  1. 대리를 중지하려면 오른쪽 상단에서 **대리(impersonation) 중지** ({{< icon name="incognito" >}})를 선택합니다.
- API를 사용하여 [대리 토큰](../api/rest/authentication.md#impersonation-tokens)을 사용합니다.

모든 대리 활동은 [감사 이벤트로 캡처](compliance/audit_event_reports.md#user-impersonation)됩니다. 기본적으로 대리는 활성화됩니다. GitLab은 [대리를 비활성화](../api/rest/authentication.md#disable-impersonation)하도록 구성할 수 있습니다.

### 사용자 ID {#user-identities}

{{< details >}}

- 티어:  Premium, Ultimate

{{< /details >}}

{{< history >}}

- 사용자의 SCIM ID 보기가 GitLab 15.3에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/294608)되었습니다.

{{< /history >}}

인증 제공자를 사용할 때 운영자는 사용자의 ID를 볼 수 있습니다. 이 페이지는 SCIM ID를 포함한 사용자의 ID를 표시합니다. 이 정보를 사용하여 SCIM 관련 문제를 해결하고 계정에 사용되는 ID를 확인합니다.

이를 수행하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **개요** > **사용자**를 선택합니다.
1. 사용자 목록에서 사용자를 선택합니다.
1. **ID**를 선택합니다.

### 사용자 권한 내보내기 {#user-permission-export}

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

사용자 권한을 내보내면 내보낸 정보는 사용자가 그룹 및 프로젝트에 보유한 직접 멤버십을 표시합니다. 처음 100,000명의 사용자로 제한되는 다음 데이터를 포함합니다:

- 사용자명
- 이메일
- 유형
- 경로
- 액세스 수준 ([프로젝트](../user/permissions.md#project-permissions) 및 [그룹](../user/permissions.md#group-permissions))
- 마지막 활동 날짜. 이 열을 채우는 활동 목록은 [사용자 API 설명서](../api/users.md#list-a-users-activity)를 참조하세요.

GitLab 인스턴스의 모든 활성 사용자에 대한 사용자 권한을 내보내려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **개요** > **사용자**를 선택합니다.
1. 오른쪽 상단에서 **Export permissions as CSV** ({{< icon name="export" >}})를 선택합니다.

### 사용자 통계 {#users-statistics}

**사용자 통계** 페이지는 역할별 사용자 계정의 개요를 제공합니다. 이 통계는 매일 계산됩니다. 마지막 업데이트 후에 변경된 사용자 변경사항은 반영되지 않습니다. 다음 총계도 포함됩니다:

- 청구 가능 사용자
- 차단된 사용자
- 전체 사용자

GitLab 청구는 [청구 가능 사용자](../subscriptions/manage_seats.md#billable-users)의 수를 기반으로 합니다.

### 사용자에게 이메일 추가 {#add-email-to-user}

사용자 계정에 이메일 주소를 수동으로 추가하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **개요** > **사용자**를 선택합니다.
1. 사용자를 찾아 선택합니다.
1. **편집**을 선택합니다.
1. **이메일**에 새 이메일 주소를 입력합니다. 새 이메일 주소가 사용자에게 추가되고 이전 이메일 주소가 보조 주소로 설정됩니다.
1. **변경 사항 저장**을 선택합니다.

## 사용자 집단 {#user-cohorts}

[집단](user_cohorts.md) 탭은 새 사용자의 월별 집단과 시간에 따른 활동을 표시합니다.

## 사용자가 최상위 그룹을 만드는 것 방지 {#prevent-a-user-from-creating-top-level-groups}

운영자는 특정 사용자가 최상위 그룹을 만드는 것을 방지할 수 있습니다. 이러한 사용자는 여전히 하위 그룹을 만들고 기존 조직 구조에서 협력할 수 있습니다.

사용자가 최상위 그룹을 만드는 것을 방지하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **개요** > **사용자**를 선택합니다.
1. 사용자를 찾아 선택합니다.
1. **편집**을 선택합니다.
1. **최상위 그룹을 생성할 수 있음** 체크박스를 선택 해제합니다.
1. **변경 사항 저장**을 선택합니다.

이 설정을 끈 후:

- 사용자는 최상위 그룹을 만들 수 없습니다.
- 사용자는 유지 관리자 또는 소유자 역할이 있는 그룹에서 하위 그룹을 만들 수 있습니다. 이는 그룹의 [하위 그룹 생성 권한](../user/group/subgroups/_index.md#change-who-can-create-subgroups)에 따라 결정됩니다.

## 그룹 관리 {#administering-groups}

{{< history >}}

- 새 모양이 GitLab 18.2에서 [도입](https://gitlab.com/groups/gitlab-org/-/epics/17783) 되었으며 [플래그](feature_flags/_index.md) `admin_groups_vue`를 사용합니다. 기본적으로 비활성화됨.
- GitLab 18.5에서 [GitLab.com, GitLab Self-Managed, GitLab Dedicated에서 활성화](https://gitlab.com/gitlab-org/gitlab/-/issues/553229)되었습니다.
- GitLab 18.6에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/574017)합니다. 기능 플래그 `admin_groups_vue` 제거됨.

{{< /history >}}

> [!flag]
> 이 기능의 사용 가능 여부는 기능 플래그에 의해 제어됩니다. 자세한 내용은 이력을 참조하세요.

GitLab 인스턴스의 모든 그룹을 관리하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **개요** > **그룹**을 선택합니다. 페이지에 각 그룹의 다음 항목이 표시됩니다:

   - 이름
   - 설명
   - 가시성 수준
   - 역할
   - 상태
   - 저장소 크기
   - 하위 그룹 개수
   - 프로젝트 개수
   - 멤버 수

1. 선택사항. 탭을 선택합니다:

   - **활성**은 모든 활성 그룹을 표시합니다.
   - **비활성**은 삭제 대기 중인 그룹을 표시합니다.

1. 선택사항. 정렬 순서를 변경하려면 정렬 드롭다운 목록을 선택하고 원하는 순서를 선택합니다. 사용 가능한 정렬 옵션은:

   - 이름
   - 생성 날짜
   - 업데이트 날짜
   - [저장소 크기](../user/storage_usage_quotas.md)

1. 선택사항. 검색 표시줄에서 그룹을 이름으로 필터링하려면 최소 3자를 입력합니다.
1. 선택사항. [새 그룹을 만들려면](../user/group/_index.md#create-a-group) **새 그룹**을 선택합니다.

### 그룹 편집 {#edit-a-group}

**운영자** 영역의 그룹 페이지에서 그룹의 이름 또는 설명을 편집하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **개요** > **그룹**을 선택합니다.
1. 편집할 그룹을 찾아 **조치** ({{< icon name="ellipsis_v" >}}) > **편집**을 선택합니다.
1. **그룹 이름** 또는 **Group description**을 편집합니다.
1. **변경 사항 저장**을 선택합니다.

### 그룹 삭제 {#delete-a-group}

그룹을 삭제하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **개요** > **그룹**을 선택합니다.
1. 편집할 그룹을 찾아 **조치** ({{< icon name="ellipsis_v" >}}) > **삭제**를 선택합니다.
1. 확인 대화에서 **확인**을 선택합니다.

## 주제 관리 {#administering-topics}

{{< details >}}

- 상태:  베타

{{< /details >}}

[주제](../user/project/project_topics.md)를 사용하여 유사한 프로젝트를 분류하고 찾습니다.

### 모든 주제 보기 {#view-all-topics}

GitLab 인스턴스의 모든 주제를 보려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **개요** > **주제**를 선택합니다.

각 주제에 대해 페이지는 그 이름과 주제로 레이블이 지정된 프로젝트 수를 표시합니다.

### 주제 검색 {#search-for-topics}

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **개요** > **주제**를 선택합니다.
1. 검색 상자에 검색 기준을 입력합니다. 주제 검색은 대소문자를 구분하지 않으며 부분 일치를 적용합니다.

### 주제 만들기 {#create-a-topic}

주제를 만들려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **개요** > **주제**를 선택합니다.
1. **새 주제**를 선택합니다.
1. **주제 슬러그 (이름)** 및 **주제 제목**을 입력합니다.
1. 선택사항. **설명**을 입력하고 **주제 아바타**를 추가합니다.
1. **변경 사항 저장**을 선택합니다.

만든 주제는 **주제 둘러보기** 페이지에 표시됩니다.

할당된 주제는 프로젝트에 접근할 수 있는 모든 사람에게만 표시되지만 누구나 GitLab 인스턴스에 존재하는 주제를 볼 수 있습니다. 주제의 이름에 민감한 정보를 포함하지 마세요.

### 주제 편집 {#edit-a-topic}

언제든지 주제의 이름, 제목, 설명 및 아바타를 편집할 수 있습니다. 주제를 편집하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **개요** > **주제**를 선택합니다.
1. 해당 주제의 행에서 **편집**을 선택합니다.
1. 주제 슬러그(이름), 제목, 설명 또는 아바타를 편집합니다.
1. **변경 사항 저장**을 선택합니다.

### 주제 삭제 {#remove-a-topic}

더 이상 주제가 필요하지 않으면 영구적으로 삭제할 수 있습니다. 주제를 삭제하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **개요** > **주제**를 선택합니다.
1. 주제를 삭제하려면 해당 주제의 행에서 **삭제**를 선택합니다.

### 주제 병합 {#merge-topics}

주제에 할당된 모든 프로젝트를 다른 주제로 이동할 수 있습니다. 소스 주제는 영구적으로 삭제됩니다. 병합된 주제가 삭제되면 복원할 수 없습니다.

주제를 병합하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **개요** > **주제**를 선택합니다.
1. **주제 병합**을 선택합니다.
1. **소스 주제** 드롭다운 목록에서 병합하고 제거할 주제를 선택합니다.
1. **대상 주제** 드롭다운 목록에서 소스 주제를 병합할 주제를 선택합니다.
1. **머지**를 선택합니다.

## Gitaly 서버 관리 {#administering-gitaly-servers}

GitLab 인스턴스의 모든 Gitaly 서버를 **운영자** 영역의 **Gitaly 서버** 페이지에서 나열할 수 있습니다. 자세한 내용은 [Gitaly](gitaly/_index.md)를 참조하세요.

**Gitaly 서버** 페이지에 접근하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **개요** > **Gitaly 서버**를 선택합니다.

페이지에는 각 Gitaly 서버에 대한 다음 정보가 포함됩니다:

| 필드          | 설명 |
|----------------|-------------|
| 저장소        | 리포지토리 저장소 |
| 주소        | Gitaly 서버가 수신 중인 네트워크 주소 |
| 서버 버전 | Gitaly 버전 |
| Git 버전    | Gitaly 서버에 설치된 Git 버전 |
| 최신 상태     | Gitaly 서버 버전이 사용 가능한 최신 버전인지 여부를 나타냅니다. 녹색 점은 서버가 최신 상태임을 나타냅니다. |

## 조직 관리 {#administering-organizations}

{{< history >}}

- GitLab 16.10에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/419540) 되었으며 [플래그](feature_flags/_index.md) `ui_for_organizations`를 사용합니다. 기본적으로 비활성화됨.

{{< /history >}}

> [!flag]
> GitLab Self-Managed의 경우 기본적으로 이 기능을 사용할 수 없습니다. 사용 가능하게 하려면 운영자가 [기능 플래그 활성화](feature_flags/_index.md) `ui_for_organizations`를 할 수 있습니다. GitLab.com 및 GitLab Dedicated에서는 이 기능을 사용할 수 없습니다. 이 기능은 프로덕션 사용을 위해 준비되지 않았습니다.

**운영자** 영역의 조직 페이지는 기본적으로 모든 프로젝트를 마지막으로 업데이트된 역순으로 나열합니다. 각 프로젝트는 다음을 표시합니다:

- 이름
- 네임스페이스
- 설명
- 크기, 최대 15분마다 업데이트됨

이 페이지에서 GitLab 인스턴스의 모든 조직을 관리하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **개요** > **조직**을 선택합니다.

## CI/CD 섹션 {#cicd-section}

### 러너 관리 {#administering-runners}

{{< history >}}

- GitLab 15.8에서 **개요** > **러너**에서 **CI/CD** > **러너**로 [이동](https://gitlab.com/gitlab-org/gitlab/-/issues/340859)되었습니다.

{{< /history >}}

GitLab 인스턴스의 모든 러너를 관리하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **CI/CD** > **러너**를 선택합니다.

각 러너에 대해 다음 정보가 표시됩니다:

| 속성    | 설명 |
|--------------|-------------|
| 상태       | 러너의 상태. [GitLab 15.1 이상](https://gitlab.com/gitlab-org/gitlab/-/issues/22224)에서 Ultimate 티어의 경우 업그레이드 상태를 사용할 수 있습니다. |
| 러너 세부 정보 | 러너에 대한 정보(부분 토큰 포함 및 러너가 등록된 컴퓨터에 대한 세부 정보 포함). |
| 버전      | GitLab Runner 버전. |
| 작업         | 러너가 실행한 총 작업 수. |
| 태그         | 러너와 연결된 태그. |
| 마지막 연락 | 러너가 마지막으로 GitLab 인스턴스와 접촉한 시간을 나타내는 타임스탬프. |

또한 각 러너를 편집, 일시 중지 또는 제거할 수 있습니다.

자세한 내용은 [GitLab Runner](https://docs.gitlab.com/runner/)를 참조하세요.

#### 러너 검색 및 필터링 {#search-and-filter-runners}

러너의 설명을 검색하려면:

1. **검색 또는 결과 필터** 텍스트 상자에 찾을 러너의 설명을 입력합니다.
1. <kbd>Enter</kbd>를 누릅니다.

러너를 상태, 유형 및 태그로 필터링하려면:

1. 탭 또는 **검색 또는 결과 필터** 텍스트 상자를 선택합니다.
1. 모든 **유형**을 선택하거나 **상태** 또는 **태그**로 필터링합니다.
1. 검색 기준을 선택하거나 입력합니다.

![상태별로 필터링된 러너의 속성.](img/index_runners_search_or_filter_v14_5.png)

#### 러너 대량 삭제 {#bulk-delete-runners}

{{< history >}}

- GitLab 15.4에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/370241)되었습니다.
- GitLab 15.5에서 [기능 플래그 제거](https://gitlab.com/gitlab-org/gitlab/-/issues/353981)되었습니다.

{{< /history >}}

한 번에 여러 러너를 삭제하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **CI/CD** > **러너**를 선택합니다.
1. 삭제하려는 러너의 왼쪽에 있는 체크박스를 선택합니다. 페이지의 모든 러너를 선택하려면 목록 위의 체크박스를 선택합니다.
1. **선택 항목 삭제**를 선택합니다.

### 작업 관리 {#administering-jobs}

{{< history >}}

- GitLab 15.8에서 **개요** > **작업**에서 **CI/CD** > **작업**으로 [이동](https://gitlab.com/gitlab-org/gitlab/-/issues/386311)되었습니다.

{{< /history >}}

GitLab 인스턴스의 모든 작업을 관리하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **CI/CD** > **작업**을 선택합니다. 모든 작업은 작업 ID의 내림차순으로 나열됩니다.
1. **전체** 탭을 선택하여 모든 작업을 나열합니다. **대기중**, **실행중** 또는 **완료** 탭을 선택하여 해당 상태의 작업만 나열합니다.

각 작업에 대해 다음 세부 정보가 나열됩니다:

| 필드    | 설명 |
|----------|-------------|
| 상태   | 작업 상태. **성공**, **생략** 또는 **실패** 중 하나.              |
| 작업      | 작업, 브랜치 및 작업을 시작한 커밋에 대한 링크 포함. |
| 파이프라인 | 특정 파이프라인에 대한 링크 포함.                               |
| 프로젝트  | 작업이 속한 프로젝트 및 조직의 이름.        |
| 러너   | 작업을 실행하기 위해 할당된 CI 러너의 이름.                      |
| 스테이지    | 작업이 `.gitlab-ci.yml` 파일에 선언된 스테이지.              |
| 이름     | `.gitlab-ci.yml` 파일에 지정된 작업의 이름.                   |
| 시간   | 작업의 지속 시간 및 작업이 완료된 후 경과 시간.                |
| 범위 | 테스트 범위의 백분율.                                           |

## 모니터링 섹션 {#monitoring-section}

다음 항목들은 **모니터링** 섹션의 **운영자** 영역을 설명합니다.

### 시스템 정보 {#system-information}

{{< history >}}

- 상대 시간 지원이 GitLab 15.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/341248)되었습니다. "가동 시간" 통계의 이름이 "시스템 시작"으로 변경되었습니다.

{{< /history >}}

**시스템 정보** 페이지는 다음 통계를 제공합니다:

| 필드          | 설명                                       |
|:---------------|:--------------------------------------------------|
| CPU            | 사용 가능한 CPU 코어 수                     |
| 메모리 사용률   | 사용 중인 메모리 및 사용 가능한 총 메모리         |
| 디스크 사용률     | 사용 중인 디스크 공간 및 사용 가능한 총 디스크 공간 |
| 시스템 시작됨 | GitLab을 호스팅하는 시스템이 시작된 시간. GitLab 15.1 이상에서는 이것이 가동 시간 통계였습니다. |

이 통계는 **시스템 정보** 페이지로 이동하거나 브라우저에서 페이지를 새로 고칠 때만 업데이트됩니다.

### 백그라운드 작업 {#background-jobs}

**백그라운드 작업** 페이지는 Sidekiq 대시보드를 표시합니다. Sidekiq은 GitLab에서 백그라운드 프로세스를 수행하는 데 사용됩니다.

Sidekiq 대시보드에는 다음이 포함됩니다:

- 각 [작업의 수명 주기 상태](https://github.com/sidekiq/sidekiq/wiki/Job-Lifecycle)에 대한 탭.
- 백그라운드 작업 통계의 분석.
- **Processed** 및 **실패함** 작업의 실시간 그래프, 선택 가능한 폴링 간격 포함.
- **Processed** 및 **실패함** 작업의 과거 그래프, 선택 가능한 시간 범위 포함.
- Redis 통계, 포함:
  - 버전 번호
  - 일 단위로 측정한 가동 시간
  - 연결 수
  - MB 단위로 측정한 현재 메모리 사용량
  - MB 단위로 측정한 최고 메모리 사용량

### 데이터 관리 {#data-management}

{{< history >}}

- GitLab 18.8에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/550952)되었습니다.

{{< /history >}}

**데이터 관리** 페이지는 Geo 기본 사이트의 모든 구성 요소에서 확인 상태를 보고 관리하는 포괄적인 인터페이스를 제공합니다. 구성 요소는 Geo에서 지원하는 [모든 데이터 유형](geo/replication/datatypes.md)을 포함합니다.

이 페이지를 사용하여:

- Rails 콘솔 접근 없이 확인 실패로 이어지는 고아 파일 또는 데이터베이스 레코드를 식별합니다.
- UI에서 직접 자세한 오류 정보를 보고 시정 조치를 취합니다.
- 모든 구성 요소의 확인 상태를 추적하고 실패 패턴을 식별합니다.
- 모든 객체에 대한 체크섬 계산을 한 번에 트리거합니다.

목록 보기는 선택한 구성 요소의 확인 상태를 표시합니다.

1. 드롭다운 목록에서 구성 요소를 선택하여 다양한 확인 모델(프로젝트, 업로드 등) 간에 전환합니다. 목록 보기에서 다음을 수행할 수 있습니다:

   - 체크섬 상태(실패함, 대기중, 성공)별로 객체를 필터링합니다.
   - 큰 결과 집합을 탐색합니다.
   - 각 객체의 마지막 체크섬 시간, 마지막 실패 시간 및 실패 이유를 봅니다.
   - 개별 객체에 대한 체크섬 계산을 트리거합니다.

1. 목록 보기에서 개별 모델을 선택하여 다음과 같은 특정 객체의 확인 상태에 대한 포괄적인 정보를 봅니다:

   - 확인된 객체에 대한 세부 정보.
   - 현재 체크섬 상태 및 기록.
   - 확인이 실패한 경우 자세한 실패 이유.
   - 객체의 체크섬을 다시 계산하는 옵션.

### 데이터베이스 진단 {#database-diagnostics}

{{< history >}}

- 콜레이션 상태 확인이 GitLab 18.3에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/555916)되었습니다.
- 스키마 상태 확인이 GitLab 18.3에서 누락된 인덱스, 테이블, 외래 키 및 시퀀스 확인과 함께 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/199796)되었습니다.
- 잘못된 시퀀스 소유자 확인이 GitLab 18.4에서 스키마 상태 확인에 [추가](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/197521)되었습니다.

{{< /history >}}

데이터베이스 진단 페이지는 데이터베이스의 일반적인 문제를 플래그하려고 시도하는 여러 확인으로 구성됩니다:

- [PostgreSQL 콜레이션 변경](https://gitlab.com/groups/gitlab-org/-/epics/8573)으로 인한 인덱스 손상
- [스키마 불일치](https://gitlab.com/groups/gitlab-org/-/epics/3928)

각 확인을 실행하려면 확인의 실행 단추를 선택합니다. 실행 단추를 선택하면 확인에서 정보를 페이지로 보고할 백그라운드 작업이 예약됩니다.

#### 콜레이션 상태 확인 {#collation-health-check}

콜레이션 상태 확인은 손상된 인덱스로 인한 PostgreSQL 문제를 감지하려고 시도합니다. 이는 PostgreSQL을 실행하는 이전 운영 체제가 `glibc` 버전 2.28보다 이전 버전을 사용한 경우 일반적으로 발생합니다. 자세한 내용은 [PostgreSQL 운영 체제 업그레이드](postgresql/upgrading_os.md)에 대한 설명서를 참조하세요.

문제가 있으면 **Corrupted Indexes** 섹션에 나열됩니다. 문제가 있으면 [손상된 인덱스 복구](raketasks/maintenance.md#repair-corrupted-database-indexes)할 수 있습니다.

콜레이션 상태 확인은 일반적으로 영향을 받는 테이블의 중복을 플래그하려고 시도합니다:

- `ci_refs`
- `ci_resource_groups`
- `environments`
- `merge_request_diff_commit_users`
- `sbom_components`
- `tags`
- `topics`

자세한 내용은 [이슈 505982](https://gitlab.com/gitlab-org/gitlab/-/issues/505982)를 참조하세요.

대시보드는 [`gitlab:db:collation_checker` Rake 작업](raketasks/maintenance.md#detect-postgresql-collation-version-mismatches)에 표시된 동일한 정보를 나열합니다.

#### 스키마 상태 확인 {#schema-health-check}

스키마 상태 확인은 데이터베이스의 상태를 대상 스키마와 비교하고 감지된 불일치를 나열합니다. 자동 스키마 복구 도구가 없습니다.

거짓 긍정을 발견하거나 확인 결과에 대한 질문이 있으면 [피드백 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/567561)를 참조하세요.

### 로그 {#logs}

이 로그 파일의 내용은 문제를 해결하는 데 도움이 될 수 있습니다. 각 로그 파일의 내용은 시간순으로 나열됩니다. 성능 문제를 최소화하기 위해 각 로그 파일의 최대 2000줄이 표시됩니다.

| 로그 파일                | 내용 |
|:------------------------|:---------|
| `application_json.log`  | GitLab 사용자 활동 |
| `git_json.log`          | GitLab과 Git 리포지토리의 상호 작용 실패 |
| `production.log`        | Puma에서 수신한 요청 및 해당 요청을 제공하기 위해 취한 조치 |
| `sidekiq.log`           | 백그라운드 작업 |
| `repocheck.log`         | 리포지토리 활동 |
| `integrations_json.log` | GitLab과 통합 시스템 간의 활동 |
| `kubernetes.log`        | Kubernetes 활동 |

이 로그 파일 및 해당 내용에 대한 자세한 내용은 [로그 시스템](logs/_index.md)을 참조하세요.

**로그** 보기는 **운영자** 영역 대시보드에서 제거되었습니다. 이는 다중 노드 시스템의 운영자 혼란을 방지하기 위함입니다. 이 보기는 다중 노드 설정에 대한 부분 정보를 제시합니다. 다중 노드 시스템의 경우 Elasticsearch 및 Splunk와 같은 서비스로 로그를 수집합니다.

### 감사 이벤트 {#audit-events}

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

**감사 이벤트** 페이지는 GitLab 서버에 대한 변경 사항을 나열합니다. 이 정보를 사용하여 모든 변경 사항을 제어, 분석 및 추적합니다.

### 통계 {#statistics}

대시보드의 **인스턴스 개요** 섹션은 GitLab 인스턴스의 현재 통계를 나열합니다. [애플리케이션 통계 API](../api/statistics.md#retrieve-application-statistics)를 사용하여 이 정보를 검색합니다.

이 통계는 10,000 미만의 값에 대해 정확한 개수를 표시합니다. 10,000 이상의 값의 경우 [`TablesampleCountStrategy`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/database/count/tablesample_count_strategy.rb?ref_type=heads#L16) 및 [`ReltuplesCountStrategy`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/database/count/reltuples_count_strategy.rb?ref_type=heads) 전략을 계산에 사용할 때 이 통계는 대략적인 데이터를 표시합니다.
