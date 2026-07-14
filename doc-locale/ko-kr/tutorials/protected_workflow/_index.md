---
stage: Create
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: '튜토리얼: 프로젝트의 보호된 워크플로우 구축'
description: 프로젝트의 브랜치 보호 및 승인 워크플로우를 구성합니다.
---

<!-- vale gitlab_base.FutureTense = NO -->

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

팀이 새 프로젝트를 시작할 때, 효율성과 적절한 검토 사이의 균형을 맞추는 워크플로우가 필요합니다. GitLab에서는 사용자 그룹을 만들고, 이러한 그룹을 브랜치 보호와 결합한 다음, 승인 규칙으로 이러한 보호를 적용할 수 있습니다.

이 튜토리얼에서는 "Excelsior"라는 예제 프로젝트의 `1.x` 및 `1.x.x` 릴리스 브랜치에 대한 보호를 설정하고, 프로젝트의 최소한의 승인 워크플로우를 생성합니다.

1. [`engineering` 그룹 만들기](#create-the-engineering-group)
1. [`engineering`에서 하위 그룹 만들기](#create-subgroups-in-engineering)
1. [하위 그룹에 사용자 추가](#add-users-to-the-subgroups)
1. [Excelsior 프로젝트 만들기](#create-the-excelsior-project)
1. [기본 CODEOWNERS 파일 추가](#add-a-basic-codeowners-file)
1. [승인 규칙 구성](#configure-approval-rules)
1. [브랜치에서 코드 소유자 승인 적용](#enforce-codeowner-approval-on-branches)
1. [릴리스 브랜치 만들기](#create-the-release-branches)

## 시작하기 전에 {#before-you-begin}

- Maintainer 또는 Owner 역할이 있어야 합니다.
- 관리자 목록 및 해당 이메일 주소가 필요합니다.
- 백엔드 및 프론트엔드 엔지니어 목록 및 해당 이메일 주소가 필요합니다.
- 브랜치 이름에 대해 [시멘틱 버전 관리](https://semver.org/)를 이해합니다.

## `engineering` 그룹 만들기 {#create-the-engineering-group}

Excelsior 프로젝트를 설정하기 전에, 프로젝트를 소유할 그룹을 만들어야 합니다. 여기서 엔지니어링 그룹을 설정합니다.

1. 오른쪽 상단 모서리에서 **새로 만들기** ({{< icon name="plus" >}}) 및 **새 그룹**을 선택합니다.
1. **그룹 생성**을 선택합니다.
1. **그룹 이름**에 `Engineering`을(를) 입력합니다.
1. **그룹 URL**에 `engineering`을(를) 입력합니다.
1. **공개 수준**을 **비공개**로 설정합니다.
1. 경험을 개인화하여 GitLab이 가장 도움이 되는 정보를 표시하도록 합니다.
   - **역할**에서 **System administrator**를 선택합니다.
   - **누가 이 그룹을 사용하게 됩니까?**에서 **내 회사 또는 팀**을 선택합니다.
   - **이 그룹을 무엇에 사용할 것입니까?**에서 **내 코드를 저장하고 싶습니다**를 선택합니다.
1. 그룹에 멤버 초대를 건너뜁니다. 이 튜토리얼의 나중 섹션에서 사용자를 추가합니다.
1. **그룹 생성**을 선택합니다.

다음으로, 더 세밀한 제어를 위해 이 `engineering` 그룹에 하위 그룹을 추가합니다.

## `engineering`에서 하위 그룹 만들기 {#create-subgroups-in-engineering}

`engineering` 그룹은 좋은 시작이지만, Excelsior 프로젝트의 백엔드 엔지니어, 프론트엔드 엔지니어 및 관리자는 서로 다른 작업과 전문 분야를 가지고 있습니다.

여기 엔지니어링 그룹에서 3개의 더 세밀한 하위 그룹인 `managers`, `frontend` 및 `backend`를 만들어 수행하는 작업 유형으로 사용자를 분류합니다. 그런 다음 이러한 새 그룹을 `engineering` 그룹의 멤버로 추가합니다.

먼저 새 하위 그룹을 만듭니다.

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 `engineering`를 검색합니다.
1. `Engineering`라는 그룹을 선택합니다.

   ![검색 결과의 엔지니어링 그룹](img/search_engineering_v16_2.png)
1. `engineering` 그룹의 개요 페이지에서 오른쪽 상단 모서리에 **하위그룹 생성**을 선택합니다.
1. **하위 그룹 이름**에 `Managers`을(를) 입력합니다.
1. **공개 수준**을 **비공개**로 설정합니다.
1. **하위그룹 생성**을 선택합니다.

다음으로, 하위 그룹을 `engineering` 그룹의 멤버로 추가합니다.

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 `engineering`를 검색합니다.
1. `Engineering`라는 그룹을 선택합니다.
1. **관리** > **멤버**를 선택합니다.
1. 오른쪽 상단에서 **그룹 초대**를 선택합니다.
1. **초대할 그룹 선택**에서 `Engineering / Managers`를 선택합니다.
1. 하위 그룹을 추가할 때 **Maintainer** 역할을 선택합니다. 이렇게 하면 하위 그룹의 멤버가 `engineering` 그룹 및 해당 프로젝트에 액세스할 때 상속할 수 있는 최고 역할이 구성됩니다.
1. 선택 사항. 만료 날짜를 선택합니다.
1. **초대**를 선택합니다.

이 프로세스를 반복하여 `backend` 및 `frontend`에 대한 하위 그룹을 만듭니다. 완료되면 `engineering` 그룹을 다시 한 번 검색합니다. 개요 페이지에는 다음과 같이 3개의 하위 그룹이 표시되어야 합니다.

![엔지니어링 그룹에는 3개의 하위 그룹이 있습니다.](img/subgroup_structure_v16_1.png)

## 하위 그룹에 사용자 추가 {#add-users-to-the-subgroups}

이전 단계에서 부모 그룹(`engineering`)에 하위 그룹을 추가할 때, 하위 그룹의 멤버를 유지관리자 역할로 제한했습니다. 이 역할은 `engineering`에서 소유한 프로젝트에 대해 상속할 수 있는 최고 역할입니다. 결과적으로 다음과 같이 됩니다.

- 사용자 1이 게스트 역할로 `manager` 하위 그룹에 추가되며, `engineering` 프로젝트에서 게스트 역할을 받습니다.
- 사용자 2가 소유자 역할로 `manager` 그룹에 추가됩니다. 이 역할은 설정한 최대 역할(유지관리자)보다 높으므로, 사용자 2는 소유자 대신 유지관리자 역할을 받습니다.

`frontend` 하위 그룹에 사용자를 추가하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 `frontend`를 검색합니다.
1. `Frontend` 그룹을 선택합니다.
1. **관리** > **멤버**를 선택합니다.
1. **멤버 초대**를 선택합니다.
1. 필드를 채웁니다. 기본적으로 **Developer** 역할을 선택하고, 이 사용자가 다른 사람의 작업을 검토하는 경우 **Maintainer**로 승격시킵니다.
1. **초대**를 선택합니다.
1. 모든 프론트엔드 엔지니어를 `frontend` 하위 그룹에 추가할 때까지 이 단계를 반복합니다.

이제 `backend` 및 `managers` 그룹으로 동일한 작업을 수행합니다. 동일한 사용자가 여러 하위 그룹의 멤버가 될 수 있습니다.

## Excelsior 프로젝트 만들기 {#create-the-excelsior-project}

이제 그룹 구조가 준비되었으므로, 팀이 작업할 수 있도록 `excelsior` 프로젝트를 만듭니다. 프론트엔드 및 백엔드 엔지니어 모두 관여하므로, `excelsior`는 방금 만든 더 작은 하위 그룹이 아닌 `engineering`에 속해야 합니다.

새 `excelsior` 프로젝트를 만들려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 `engineering`를 검색합니다.
1. `Engineering`라는 그룹을 선택합니다.
1. `engineering` 그룹의 개요 페이지에서 오른쪽 상단 모서리에 **새로 만들기** ({{< icon name="plus" >}}) 및 **이 그룹에서** > **새 프로젝트/리포지토리**를 선택합니다.
1. **빈 프로젝트 생성**을 선택합니다.
1. 프로젝트 세부 정보를 입력합니다.
   - **프로젝트 이름** 필드에 `Excelsior`을(를) 입력합니다. **프로젝트 슬러그**는 `excelsior`로 자동으로 입력되어야 합니다.
   - **공개 수준**에서 **공개**를 선택합니다.
   - **README 파일을 포함하여 리포지토리 초기화**를 선택하여 리포지토리에 초기 파일을 추가합니다.
1. **프로젝트 생성**을 선택합니다.

GitLab은 `excelsior` 프로젝트를 만들고 해당 홈페이지로 리다이렉트합니다. 다음과 같이 보여야 합니다.

![새로운 거의 비어있는 excelsior 프로젝트](img/new_project_v16_2.png)

이 페이지의 기능을 다음 단계에서 사용합니다.

## 기본 CODEOWNERS 파일 추가 {#add-a-basic-codeowners-file}

CODEOWNERS 파일을 프로젝트의 루트 디렉터리에 추가하여 리뷰를 올바른 하위 그룹으로 라우팅합니다. 이 예제에서는 4개의 규칙을 설정합니다.

- 모든 변경 사항은 `engineering` 그룹의 누군가가 검토해야 합니다.
- 관리자는 CODEOWNERS 파일 자체에 대한 모든 변경 사항을 검토해야 합니다.
- 프론트엔드 엔지니어는 프론트엔드 파일에 대한 변경 사항을 검토해야 합니다.
- 백엔드 엔지니어는 백엔드 파일에 대한 변경 사항을 검토해야 합니다.

> [!note]
> GitLab Free는 선택적 리뷰만 지원합니다. 리뷰를 필수로 만들려면 GitLab Premium 또는 Ultimate가 필요합니다.

`excelsior` 프로젝트에 CODEOWNERS 파일을 추가하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 `Excelsior`를 검색합니다.
1. `Excelsior`라는 프로젝트를 선택합니다.
1. 브랜치 이름 옆에 더하기 아이콘({{< icon name="plus" >}})을 선택한 다음 **새 파일**을 선택합니다. ![프로젝트에서 새 파일 만들기](img/new_file_v16_2.png)
1. **파일명**에 `CODEOWNERS`을(를) 입력합니다. 이렇게 하면 프로젝트의 루트 디렉터리에 `CODEOWNERS`라는 파일이 생성됩니다.
1. 이 예제를 편집 영역에 붙여넣으면, 그룹 구조와 일치하지 않는 경우 `@engineering/`을(를) 변경합니다.

   ```plaintext
   # All changes should be reviewed by someone in the engineering group
   * @engineering

   # A manager should review any changes to this file
   CODEOWNERS @engineering/managers

   # Frontend files should be reviewed by FE engineers
   [Frontend] @engineering/frontend
   *.scss
   *.js

   # Backend files should be reviewed by BE engineers
   [Backend] @engineering/backend
   *.rb
   ```

1. **커밋 메시지**에 다음을 붙여넣습니다.

   ```plaintext
   Adds a new CODEOWNERS file

   Creates a small CODEOWNERS file to:
   - Route backend and frontend changes to the right teams
   - Route CODEOWNERS file changes to managers
   - Request all changes be reviewed
   ```

1. **커밋 변경**을 선택합니다.

CODEOWNERS 파일이 이제 프로젝트의 `main` 브랜치에 배치되었으며, 이 프로젝트에서 만들어진 모든 향후 브랜치에 사용할 수 있습니다.

## 승인 규칙 구성 {#configure-approval-rules}

CODEOWNERS 파일은 디렉터리 및 파일 유형에 대한 적절한 검토자를 설명합니다. 승인 규칙은 머지 리퀘스트를 이러한 검토자에게 지정합니다. 여기서는 새 CODEOWNERS 파일의 정보를 사용하고 릴리스 브랜치에 대한 보호를 추가하는 승인 규칙을 설정합니다.

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 `Excelsior`를 검색합니다.
1. `Excelsior`라는 프로젝트를 선택합니다.
1. **설정** > **머지 리퀘스트**를 선택합니다.
1. **머지 리퀘스트 승인** 섹션에서 **승인 규칙**로 스크롤합니다.
1. **승인 규칙 추가**를 선택합니다.
1. `Enforce CODEOWNERS`라는 규칙을 만듭니다.
1. **모든 보호된 브랜치**를 선택합니다.
1. GitLab Premium 및 GitLab Ultimate에서 규칙을 필수로 만들려면 **승인 필요**를 `1`로 설정합니다.
1. `managers` 그룹을 승인자로 추가합니다.
1. **승인 규칙 추가**를 선택합니다.
1. **승인 설정**으로 스크롤하고 **머지 리퀘스트에서 승인 규칙 편집 방지**가 선택되었는지 확인합니다.
1. **변경사항 저장**을 선택합니다.

추가되었을 때, `Enforce CODEOWNERS` 규칙은 다음과 같이 표시됩니다.

![새 승인 규칙 준비](img/approval_rules_v16_2.png)

## 브랜치에서 코드 소유자 승인 적용 {#enforce-codeowner-approval-on-branches}

프로젝트에 대한 여러 보호를 구성했으며, 이제 이러한 보호를 함께 결합하여 프로젝트의 중요한 브랜치를 보호할 준비가 되었습니다.

- 사용자가 논리적 그룹 및 하위 그룹으로 정렬됩니다.
- CODEOWNERS 파일은 파일 유형 및 디렉터리에 대한 주제 전문가를 설명합니다.
- 승인 규칙은 (GitLab Free에서) 주제 전문가에게 변경 사항을 검토하도록 권장하거나 (GitLab Premium 및 GitLab Ultimate에서) 필수로 요구합니다.

`excelsior` 프로젝트는 릴리스 브랜치 이름에 [시멘틱 버전 관리](https://semver.org/)를 사용하므로, 릴리스 브랜치는 `1.x` 및 `1.x.x` 패턴을 따른다는 것을 알 수 있습니다. 이러한 브랜치에 추가된 모든 코드가 주제 전문가에 의해 검토되고, 관리자가 릴리스 브랜치에 병합될 작업에 대한 최종 결정을 내리기를 원합니다.

한 번에 한 브랜치씩 보호를 만드는 대신 와일드카드 브랜치 규칙을 구성하여 여러 브랜치를 보호합니다.

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 `Excelsior`를 검색합니다.
1. `Excelsior`라는 프로젝트를 선택합니다.
1. **설정** > **리포지토리**를 선택합니다.
1. **브랜치 규칙**을 확장합니다.
1. **브랜치 규칙 추가** > **브랜치 이름 또는 패턴**을 선택합니다.
1. 드롭다운 목록에서 `1.*`을(를) 입력한 다음 **와일드카드 `1.*` 만들기**를 선택합니다.
1. 모든 사람이 커밋을 직접 푸시하지 않고 머지 리퀘스트를 제출하도록 하려면:
   1. **머지 허용** 섹션에서 **편집**을 선택하고 **유지관리자**로 설정한 다음 **변경사항 저장**을 선택합니다.
   1. **푸시와 머지가 허용됨** 섹션에서 **편집**을 선택하고 **아무도 없음**으로 설정한 다음 **변경사항 저장**을 선택합니다.
   1. **강제 푸시 허용**을 비활성화된 상태로 둡니다.
1. GitLab Premium 및 GitLab Ultimate에서 코드 소유자가 자신이 작업하는 파일에 대한 변경 사항을 검토하도록 하려면 **코드 소유자의 승인이 필요합니다.**를 토글합니다.
1. 브랜치 테이블에서 `Default`로 표시된 규칙을 찾습니다. (GitLab 버전에 따라 이 브랜치의 이름이 `main` 또는 `master`일 수 있습니다.) 이 브랜치의 값을 `1.*` 규칙에 사용한 설정과 일치하도록 설정합니다.

규칙이 이제 준비되었습니다. `1.*` 브랜치는 아직 존재하지 않더라도:

![main 및 1.x는 이제 보호됩니다.](img/branch_list_v16_1.png)

## 릴리스 브랜치 만들기 {#create-the-release-branches}

모든 브랜치 보호가 준비되었으므로, 이제 1.0.0 릴리스 브랜치를 만들 준비가 되었습니다.

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 `Excelsior`를 검색합니다.
1. `Excelsior`라는 프로젝트를 선택합니다.
1. 왼쪽 사이드바에서 **코드** > **브랜치**를 선택합니다.
1. 오른쪽 상단 모서리에서 **새 브랜치**를 선택합니다. 이름을 `1.0.0`로 지정합니다.
1. **브랜치 생성**을 선택합니다.

브랜치 보호는 이제 UI에 표시됩니다.

- 왼쪽 사이드바에서 **코드** > **브랜치**를 선택합니다. 브랜치 목록에서 브랜치 `1.0.0`는 보호되고 있음을 나타내야 합니다.

  ![1.0.0이 보호되고 있음을 보여주는 브랜치 목록](img/branch_is_protected_v16_2.png)
- 왼쪽 사이드바에서 **설정** > **리포지토리**를 선택한 다음 **브랜치 규칙**을 확장하여 모든 보호된 브랜치의 세부 정보를 확인합니다.

  ![보호된 브랜치 목록 및 해당 보호](img/protections_in_place_v16_2.png)

축하합니다! 엔지니어는 자신의 브랜치에서 독립적으로 작업할 수 있으며, 1.0.0 릴리스 브랜치를 고려할 수 있도록 제출된 모든 코드는 주제 전문가가 검토합니다.
