---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "러너의 유형, 가용성 및 관리 방법에 대해 알아봅니다."
title: 러너 관리
---

{{< details >}}

- 계층: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab Runner는 다음과 같은 유형의 러너를 가지고 있으며, 액세스 권한을 부여할 대상에 따라 가용성이 결정됩니다:

- [인스턴스 러너](#instance-runners)는 GitLab 인스턴스의 모든 그룹 및 프로젝트에서 사용할 수 있습니다.
- [그룹 러너](#group-runners)는 그룹의 모든 프로젝트 및 하위 그룹에서 사용할 수 있습니다.
- [프로젝트 러너](#project-runners)는 특정 프로젝트와 연관됩니다. 일반적으로 프로젝트 러너는 한 번에 하나의 프로젝트에서만 사용됩니다.

## 인스턴스 러너 {#instance-runners}

*인스턴스 러너*는 GitLab 인스턴스의 모든 프로젝트에서 사용할 수 있습니다.

비슷한 요구 사항이 있는 여러 작업이 있을 때 인스턴스 러너를 사용합니다. 많은 프로젝트를 위해 여러 러너가 유휴 상태로 있는 대신, 여러 프로젝트를 처리할 수 있는 몇 개의 러너를 사용할 수 있습니다.

GitLab Self-Managed를 사용하는 경우 관리자는 다음을 수행할 수 있습니다:

- [GitLab Runner 설치](https://docs.gitlab.com/runner/install/) 및 인스턴스 러너 등록.
- 각 그룹의 인스턴스 러너 [컴퓨팅 분 구성](../../administration/cicd/compute_minutes.md#set-the-compute-quota-for-a-group)의 최대 개수를 설정합니다.

GitLab.com을 사용하는 경우:

- [GitLab이 유지 관리하는 인스턴스 러너](_index.md) 목록에서 선택할 수 있습니다.
- 인스턴스 러너는 계정에 포함된 [컴퓨팅 분](../pipelines/compute_minutes.md)을 소비합니다.

### 러너 인증 토큰으로 인스턴스 러너 만들기 {#create-an-instance-runner-with-a-runner-authentication-token}

{{< history >}}

- GitLab 15.10에서 [소개되었습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/383139). `create_runner_workflow_for_admin` [플래그](../../administration/feature_flags/_index.md) 뒤에 배포되었습니다.
- GitLab 16.0에서 [기본적으로 활성화됨](https://gitlab.com/gitlab-org/gitlab/-/issues/389269).
- GitLab 16.2에서 [일반 공급됨](https://gitlab.com/gitlab-org/gitlab/-/issues/415447). 기능 플래그 `create_runner_workflow_for_admin`이 제거되었습니다.

{{< /history >}}

전제 조건:

- 관리자(administrator) 권한이 있어야 합니다.

러너를 만들 때 러너 인증 토큰이 할당되며, 이를 사용하여 등록합니다. 작업 큐에서 작업을 선택할 때 러너는 이 토큰을 사용하여 GitLab에 인증합니다.

인스턴스 러너를 만들려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **CI/CD** > **러너**를 선택합니다.
1. **인스턴스 러너 생성**를 선택합니다.
1. GitLab Runner가 설치된 운영 체제를 선택합니다.
1. **태그** 섹션의 **태그** 필드에서 러너가 실행할 수 있는 작업을 지정하는 작업 태그를 입력합니다. 이 러너에 대한 작업 태그가 없으면 **Run untagged**을 선택합니다.
1. 선택 사항. **러너 설명** 필드에서 GitLab에 표시할 러너 설명을 입력합니다.
1. 선택 사항. **구성** 섹션에서 추가 구성을 추가합니다.
1. **러너 만들기**를 선택합니다.
1. 온스크린 지침에 따라 명령줄에서 러너를 등록합니다. 명령줄에서 메시지가 나타나면:
   - `GitLab instance URL`에 대해 GitLab 인스턴스의 URL을 사용합니다. 예를 들어, 프로젝트가 `gitlab.example.com/yourname/yourproject`에 호스팅되는 경우, GitLab 인스턴스 URL은 `https://gitlab.example.com`입니다.
   - `executor`에 대해 [실행기](https://docs.gitlab.com/runner/executors/)의 유형을 입력합니다. 실행기는 러너가 작업을 실행하는 환경입니다.

[API를 사용](../../api/users.md#create-a-runner-linked-to-a-user)하여 러너를 만들 수도 있습니다.

> [!note]
> 러너 인증 토큰은 등록 중에 제한된 시간 동안 UI에 표시됩니다. 러너를 등록한 후 인증 토큰은 `config.toml`에 저장됩니다.

### 등록 토큰으로 인스턴스 러너 만들기(사용 중단됨) {#create-an-instance-runner-with-a-registration-token-deprecated}

> [!warning]
> 러너 등록 토큰을 전달하고 특정 구성 인수를 지원하는 옵션은 레거시로 간주되며 권장되지 않습니다. [러너 생성 워크플로우](https://docs.gitlab.com/runner/register/#register-with-a-runner-authentication-token)를 사용하여 러너를 등록할 인증 토큰을 생성합니다. 이 프로세스는 러너 소유권의 완전한 추적성을 제공하고 러너 플릿의 보안을 강화합니다. 자세한 내용은 [새 러너 등록 워크플로우로 마이그레이션](new_creation_workflow.md)을 참조하세요.

전제 조건:

- 러너 등록 토큰은 **운영자** 영역에서 [활성화](../../administration/settings/continuous_integration.md#control-runner-registration)되어야 합니다.
- 관리자(administrator) 권한이 있어야 합니다.

인스턴스 러너를 만들려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **CI/CD** > **러너**를 선택합니다.
1. **인스턴스 러너 등록**을 선택합니다.
1. 등록 토큰을 복사합니다.
1. [러너를 등록](https://docs.gitlab.com/runner/register/#register-with-a-runner-registration-token-legacy)합니다.

### 인스턴스 러너 일시 중지 또는 재개 {#pause-or-resume-an-instance-runner}

전제 조건:

- 관리자(administrator) 권한이 있어야 합니다.

러너를 일시 중지하여 GitLab 인스턴스의 그룹과 프로젝트로부터 작업을 수락하지 않도록 할 수 있습니다.

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **CI/CD** > **러너**를 선택합니다.
1. 검색 상자에 러너 설명을 입력하거나 러너 목록을 필터링합니다.
1. 러너 목록에서 러너의 오른쪽에:
   - 러너를 일시 중지하려면 **중지** ({{< icon name="pause" >}})를 선택합니다.
   - 러너를 재개하려면 **재개** ({{< icon name="play" >}})를 선택합니다.

### 인스턴스 러너 삭제 {#delete-instance-runners}

전제 조건:

- 관리자(administrator) 권한이 있어야 합니다.

인스턴스 러너를 삭제하면 GitLab 인스턴스에서 영구적으로 삭제되며 그룹 및 프로젝트에서 더 이상 사용할 수 없습니다. 러너가 작업을 수락하지 않도록 일시적으로 중지하려면 대신 [일시 중지](#pause-or-resume-an-instance-runner)할 수 있습니다.

하나 또는 여러 인스턴스 러너를 삭제하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **CI/CD** > **러너**를 선택합니다.
1. 검색 상자에 러너 설명을 입력하거나 러너 목록을 필터링합니다.
1. 인스턴스 러너를 삭제합니다:
   - 단일 러너를 삭제하려면 러너 옆에서 **러너 삭제** ({{< icon name="remove" >}})를 선택합니다.
   - 여러 인스턴스 러너를 삭제하려면 각 러너의 체크박스를 선택하고 **선택 항목 삭제**를 선택합니다.
   - 모든 러너를 삭제하려면 러너 목록의 맨 위에 있는 체크박스를 선택하고 **선택 항목 삭제**를 선택합니다.
1. **러너 영구 삭제**를 선택합니다.

### 프로젝트에 대해 인스턴스 러너 활성화 {#enable-instance-runners-for-a-project}

GitLab.com에서 [인스턴스 러너](_index.md)는 기본적으로 모든 프로젝트에서 활성화됩니다.

GitLab Self-Managed에서 관리자는 [모든 새 프로젝트에 대해 활성화](../../administration/settings/continuous_integration.md#enable-instance-runners-for-new-projects)할 수 있습니다.

기존 프로젝트의 경우, 관리자는 [설치](https://docs.gitlab.com/runner/install/) 및 [등록](https://docs.gitlab.com/runner/register/)해야 합니다.

프로젝트에 대해 인스턴스 러너를 활성화하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **CI/CD**를 선택합니다.
1. **러너**를 확장합니다.
1. **이 프로젝트에 대한 인스턴스 러너를 켬** 토글을 활성화합니다.

### 그룹에 대해 인스턴스 러너 활성화 {#enable-instance-runners-for-a-group}

그룹에 대해 인스턴스 러너를 활성화하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **CI/CD**를 선택합니다.
1. **러너**를 확장합니다.
1. **Turn on instance runners for this group** 토글을 활성화합니다.

### 프로젝트에 대해 인스턴스 러너 비활성화 {#disable-instance-runners-for-a-project}

개별 프로젝트 또는 그룹에 대해 인스턴스 러너를 비활성화할 수 있습니다. 프로젝트 또는 그룹에 대한 소유자 역할이 있어야 합니다.

프로젝트에 대해 인스턴스 러너를 비활성화하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **CI/CD**를 선택합니다.
1. **러너**를 확장합니다.
1. **Instance runners** 영역에서 **Turn on runners for this project** 토글을 끕니다.

인스턴스 러너는 프로젝트에 대해 자동으로 비활성화됩니다:

- 상위 그룹에 대한 인스턴스 러너 설정이 비활성화되고
- 프로젝트에 대해 이 설정을 오버라이드하는 것이 허용되지 않는 경우.

### 그룹에 대해 인스턴스 러너 비활성화 {#disable-instance-runners-for-a-group}

그룹에 대해 인스턴스 러너를 비활성화하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **CI/CD**를 선택합니다.
1. **러너**를 확장합니다.
1. **이 그룹에 대해 인스턴스 러너를 활성화** 토글을 끕니다.
1. 선택 사항. 개별 프로젝트 또는 하위 그룹에 대해 인스턴스 러너를 활성화할 수 있도록 하려면 **프로젝트 및 하위 그룹이 그룹 설정을 오버라이드하도록 허용**을 선택합니다.

### 인스턴스 러너가 작업을 선택하는 방법 {#how-instance-runners-pick-jobs}

인스턴스 러너는 공정 사용 큐를 사용하여 작업을 처리합니다. 이 큐는 프로젝트가 수백 개의 작업을 만들고 사용 가능한 모든 인스턴스 러너 리소스를 사용하는 것을 방지합니다.

공정 사용 큐 알고리즘은 인스턴스 러너에서 이미 실행 중인 작업 수가 가장 적은 프로젝트를 기반으로 작업을 할당합니다.

예를 들어, 이러한 작업이 큐에 있는 경우:

- 프로젝트 1의 작업 1
- 프로젝트 1의 작업 2
- 프로젝트 1의 작업 3
- 프로젝트 2의 작업 4
- 프로젝트 2의 작업 5
- 프로젝트 3의 작업 6

여러 CI/CD 작업이 동시에 실행될 때, 공정 사용 알고리즘은 이 순서로 작업을 할당합니다:

1. 작업 1이 먼저입니다. 왜냐하면 실행 중인 작업이 없는 프로젝트(즉, 모든 프로젝트)에서 가장 낮은 작업 번호를 가지고 있기 때문입니다.
1. 작업 4가 다음입니다. 왜냐하면 4가 실행 중인 작업이 없는 프로젝트(프로젝트 1은 실행 중인 작업이 있음)에서 가장 낮은 작업 번호이기 때문입니다.
1. 작업 6이 다음입니다. 왜냐하면 6이 실행 중인 작업이 없는 프로젝트(프로젝트 1과 2는 실행 중인 작업이 있음)에서 가장 낮은 작업 번호이기 때문입니다.
1. 작업 2가 다음입니다. 왜냐하면 실행 중인 작업의 개수가 가장 적은 프로젝트 중에서(각각 1개), 가장 낮은 작업 번호이기 때문입니다.
1. 작업 5가 다음입니다. 왜냐하면 프로젝트 1은 이제 2개의 작업이 실행 중이고 작업 5는 프로젝트 2와 3 사이의 가장 낮은 남은 작업 번호이기 때문입니다.
1. 마지막으로 작업 3이 유일하게 남은 작업이기 때문입니다.

한 번에 하나의 작업만 실행할 때, 공정 사용 알고리즘은 이 순서로 작업을 할당합니다:

1. 작업 1이 먼저 선택됩니다. 왜냐하면 실행 중인 작업이 없는 프로젝트(즉, 모든 프로젝트)에서 가장 낮은 작업 번호를 가지고 있기 때문입니다.
1. 작업 1이 완료됩니다.
1. 작업 2가 다음입니다. 왜냐하면 작업 1을 완료한 후, 모든 프로젝트는 0개의 작업이 다시 실행 중이고, 2가 가장 낮은 사용 가능한 작업 번호이기 때문입니다.
1. 작업 4가 다음입니다. 왜냐하면 프로젝트 1이 작업을 실행하고 있고, 4가 작업이 실행 중이 아닌 프로젝트(프로젝트 2와 3)에서 가장 낮은 번호이기 때문입니다.
1. 작업 4가 완료됩니다.
1. 작업 5가 다음입니다. 왜냐하면 작업 4를 완료한 후, 프로젝트 2는 작업이 실행 중이 아니기 때문입니다.
1. 작업 6이 다음입니다. 왜냐하면 프로젝트 3이 실행 중인 작업이 없는 유일한 프로젝트이기 때문입니다.
1. 마지막으로 작업 3이 유일하게 남은 작업이기 때문입니다.

## 그룹 러너 {#group-runners}

그룹의 모든 프로젝트가 러너 세트에 액세스하기를 원할 때 그룹 러너를 사용합니다.

그룹 러너는 FIFO(먼저 들어온 먼저 나가는) 큐를 사용하여 작업을 처리합니다.

### 러너 인증 토큰으로 그룹 러너 만들기 {#create-a-group-runner-with-a-runner-authentication-token}

{{< history >}}

- GitLab 15.10에서 [소개되었습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/383143). `create_runner_workflow_for_namespace` [플래그](../../administration/feature_flags/_index.md) 뒤에 배포되었습니다. 기본적으로 비활성화되어 있습니다.
- GitLab 16.0에서 [기본적으로 활성화됨](https://gitlab.com/gitlab-org/gitlab/-/issues/393919).
- GitLab 16.2에서 [일반 공급됨](https://gitlab.com/gitlab-org/gitlab/-/issues/415447). 기능 플래그 `create_runner_workflow_for_admin`이 제거되었습니다.

{{< /history >}}

전제 조건:

- 그룹의 Owner 역할이 있어야 합니다.

GitLab Self-Managed 또는 GitLab.com용 그룹 러너를 만들 수 있습니다. 러너를 만들 때 러너 인증 토큰이 할당되며, 이를 사용하여 등록합니다. 러너는 작업 큐에서 작업을 선택할 때 이 토큰을 사용하여 GitLab에 인증합니다.

그룹 러너를 만들려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **빌드** > **러너**를 선택합니다.
1. **그룹 러너 생성**를 선택합니다.
1. **태그** 섹션의 **태그** 필드에서 러너가 실행할 수 있는 작업을 지정하는 작업 태그를 입력합니다. 이 러너에 대한 작업 태그가 없으면 **Run untagged**을 선택합니다.
1. 선택 사항. **러너 설명** 필드에 GitLab에 표시할 러너 설명을 추가합니다.
1. 선택 사항. **구성** 섹션에서 추가 구성을 추가합니다.
1. **러너 만들기**를 선택합니다.
1. GitLab Runner가 설치된 플랫폼을 선택합니다.
1. 온스크린 지침을 완료합니다:
   - Linux, macOS, Windows의 경우, 명령줄에서 메시지가 나타나면:
     - `GitLab instance URL`에 대해 GitLab 인스턴스의 URL을 사용합니다. 예를 들어, 프로젝트가 `gitlab.example.com/yourname/yourproject`에 호스팅되는 경우, GitLab 인스턴스 URL은 `https://gitlab.example.com`입니다.
     - `executor`에 대해 [실행기](https://docs.gitlab.com/runner/executors/)의 유형을 입력합니다. 실행기는 러너가 작업을 실행하는 환경입니다.
   - Google Cloud의 경우 [Google Cloud에서 러너 프로비저닝](provision_runners_google_cloud.md)을 참조하세요.

[API를 사용](../../api/users.md#create-a-runner-linked-to-a-user)하여 러너를 만들 수도 있습니다.

> [!note]
> 러너 인증 토큰은 등록 중에 짧은 시간 동안만 UI에 표시됩니다.

### 등록 토큰으로 그룹 러너 만들기(사용 중단됨) {#create-a-group-runner-with-a-registration-token-deprecated}

{{< history >}}

- 경로가 **설정** > **CI/CD** > **러너**에서 변경되었습니다.

{{< /history >}}

> [!warning]
> 러너 등록 토큰을 전달하고 특정 구성 인수를 지원하는 옵션은 레거시로 간주되며 권장되지 않습니다. [러너 생성 워크플로우](https://docs.gitlab.com/runner/register/#register-with-a-runner-authentication-token)를 사용하여 러너를 등록할 인증 토큰을 생성합니다. 이 프로세스는 러너 소유권의 완전한 추적성을 제공하고 러너 플릿의 보안을 강화합니다. 자세한 내용은 [새 러너 등록 워크플로우로 마이그레이션](new_creation_workflow.md)을 참조하세요.

전제 조건:

- 러너 등록 토큰은 최상위 그룹에서 [활성화](#enable-use-of-runner-registration-tokens-in-projects-and-groups)되어야 합니다.
- 그룹의 Owner 역할이 있어야 합니다.

그룹 러너를 만들려면:

1. [GitLab Runner 설치](https://docs.gitlab.com/runner/install/).
1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **빌드** > **러너**를 선택합니다.
1. 오른쪽 위 모서리에서 **그룹 러너 등록**을 선택합니다.
1. **러너 설치 및 등록 방법 표시**를 선택합니다. 이러한 지침에는 토큰, URL 및 러너를 등록할 명령이 포함됩니다.

또는 등록 토큰을 복사하고 [러너를 등록](https://docs.gitlab.com/runner/register/#register-with-a-runner-registration-token-legacy)하는 방법에 대한 설명서를 따릅니다.

### 그룹 러너 보기 {#view-group-runners}

{{< history >}}

- Maintainer 역할을 가진 사용자가 그룹 러너를 볼 수 있는 기능이 GitLab 16.4에서 [소개되었습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/384179).

{{< /history >}}

전제 조건:

- 그룹에 대한 Maintainer 또는 소유자 역할이 있어야 합니다.

그룹 및 해당 하위 그룹과 프로젝트의 모든 러너를 볼 수 있습니다. GitLab Self-Managed 또는 GitLab.com에 대해 이를 수행할 수 있습니다.

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **빌드** > **러너**를 선택합니다.

#### 그룹 러너를 필터링하여 상속된 항목만 표시 {#filter-group-runners-to-show-only-inherited}

{{< history >}}

- GitLab 15.5에서 [소개되었습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/337838/).
- GitLab 15.5에서 [일반 공급됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/101099). 기능 플래그 `runners_finder_all_available`이 제거되었습니다.

{{< /history >}}

목록의 모든 러너를 표시하거나 인스턴스 또는 다른 그룹에서 상속된 러너만 표시하도록 선택할 수 있습니다.

기본적으로 상속된 러너만 표시됩니다.

인스턴스에서 사용 가능한 모든 러너(인스턴스 러너 및 다른 그룹의 러너 포함)를 표시하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **빌드** > **러너**를 선택합니다.
1. 목록 위에서 **상속된 항목만 표시** 토글을 끕니다.

### 그룹 러너 일시 중지 또는 재개 {#pause-or-resume-a-group-runner}

전제 조건:

- 관리자이거나 그룹에 대한 소유자 역할이 있어야 합니다.

러너를 일시 중지하여 GitLab 인스턴스의 하위 그룹 및 프로젝트로부터 작업을 수락하지 않도록 할 수 있습니다. 여러 프로젝트에서 사용되는 그룹 러너를 일시 중지하면 모든 프로젝트에 대해 러너가 일시 중지됩니다.

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **빌드** > **러너**를 선택합니다.
1. 검색 상자에 러너 설명을 입력하거나 러너 목록을 필터링합니다.
1. 러너 목록에서 러너의 오른쪽에:
   - 러너를 일시 중지하려면 **중지** ({{< icon name="pause" >}})를 선택합니다.
   - 러너를 재개하려면 **재개** ({{< icon name="play" >}})를 선택합니다.

### 그룹 러너 삭제 {#delete-a-group-runner}

{{< history >}}

- 여러 러너 삭제 기능이 GitLab 15.6에서 [소개되었습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/361721/).

{{< /history >}}

전제 조건:

- 관리자이거나 그룹에 대한 소유자 역할이 있어야 합니다.

그룹 러너를 삭제하면 GitLab 인스턴스에서 영구적으로 삭제되며 하위 그룹 및 프로젝트에서 더 이상 사용할 수 없습니다. 러너가 작업을 수락하지 않도록 일시적으로 중지하려면 대신 [일시 중지](#pause-or-resume-a-group-runner)할 수 있습니다.

하나 또는 여러 그룹 러너를 삭제하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **빌드** > **러너**를 선택합니다.
1. 검색 상자에 러너 설명을 입력하거나 러너 목록을 필터링합니다.
1. 그룹 러너를 삭제합니다:
   - 단일 러너를 삭제하려면 러너 옆에서 **러너 삭제** ({{< icon name="remove" >}})를 선택합니다.
   - 여러 인스턴스 러너를 삭제하려면 각 러너의 체크박스를 선택하고 **선택 항목 삭제**를 선택합니다.
   - 모든 러너를 삭제하려면 러너 목록의 맨 위에 있는 체크박스를 선택하고 **선택 항목 삭제**를 선택합니다.
1. **러너 영구 삭제**를 선택합니다.

### 오래된 그룹 러너 정리 {#clean-up-stale-group-runners}

{{< details >}}

- 계층: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 15.1에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/363012)되었습니다.

{{< /history >}}

전제 조건:

- 그룹의 Owner 역할이 있어야 합니다.

7일 이상 비활성 상태였던 그룹 러너를 정리할 수 있습니다.

그룹 러너는 특정 그룹에서 생성된 러너입니다.

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **CI/CD**를 선택합니다.
1. **러너**를 확장합니다.
1. **오래된 러너 정리 활성화** 토글을 켭니다.

#### 오래된 러너 정리 로그 보기 {#view-stale-runner-cleanup-logs}

[Sidekiq 로그](../../administration/logs/_index.md#sidekiq-logs)를 확인하여 정리 결과를 확인할 수 있습니다. Kibana에서 다음 쿼리를 사용할 수 있습니다:

```json
{
  "query": {
    "match_phrase": {
      "json.class.keyword": "Ci::Runners::StaleGroupRunnersPruneCronWorker"
    }
  }
}
```

오래된 러너가 제거된 항목을 필터링합니다:

```json
{
  "query": {
    "range": {
      "json.extra.ci_runners_stale_group_runners_prune_cron_worker.total_pruned": {
        "gte": 1,
        "lt": null
      }
    }
  }
}
```

## 프로젝트 러너 {#project-runners}

특정 프로젝트에 대해 러너를 사용하려는 경우 프로젝트 러너를 사용합니다. 예를 들어, 다음과 같은 경우:

- 자격 증명이 필요한 배포 작업과 같은 특정 요구 사항이 있는 작업.
- 다른 러너와 분리될 수 있는 많은 CI 활동이 있는 프로젝트.

여러 프로젝트에서 사용할 수 있도록 프로젝트 러너를 설정할 수 있습니다. 프로젝트 러너는 각 프로젝트에 대해 명시적으로 활성화되어야 합니다.

프로젝트 러너는 FIFO([FIFO](https://en.wikipedia.org/wiki/FIFO_(computing_and_electronics))) 큐를 사용하여 작업을 처리합니다.

> [!note]
> 프로젝트 러너는 포크된 프로젝트로 자동으로 인스턴스를 가져오지 않습니다. 포크는 복제된 리포지토리의 CI/CD 설정을 복사합니다.

### 프로젝트 러너 소유권 {#project-runner-ownership}

러너가 처음 프로젝트에 연결될 때, 해당 프로젝트가 러너의 소유자가 됩니다.

소유자 프로젝트를 삭제하는 경우:

1. GitLab은 러너를 공유하는 다른 모든 프로젝트를 찾습니다.
1. GitLab은 가장 오래된 연관성을 가진 프로젝트에 소유권을 할당합니다.
1. 러너를 공유하는 다른 프로젝트가 없으면 GitLab은 러너를 자동으로 삭제합니다.

소유자 프로젝트에서 러너의 할당을 취소할 수 없습니다. 대신 러너를 삭제합니다.

### 러너 인증 토큰으로 프로젝트 러너 만들기 {#create-a-project-runner-with-a-runner-authentication-token}

{{< history >}}

- GitLab 15.10에서 [소개되었습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/383143). `create_runner_workflow_for_namespace` [플래그](../../administration/feature_flags/_index.md) 뒤에 배포되었습니다. 기본적으로 비활성화되어 있습니다.
- GitLab 16.0에서 [기본적으로 활성화됨](https://gitlab.com/gitlab-org/gitlab/-/issues/393919).
- GitLab 16.2에서 [일반 공급됨](https://gitlab.com/gitlab-org/gitlab/-/issues/415447). 기능 플래그 `create_runner_workflow_for_admin`이 제거되었습니다.

{{< /history >}}

전제 조건:

- 프로젝트에 대한 Maintainer 역할이 있어야 합니다.

GitLab Self-Managed 또는 GitLab.com용 프로젝트 러너를 만들 수 있습니다. 러너를 만들 때 러너 인증 토큰이 할당되며, 이를 사용하여 러너에 등록합니다. 러너는 작업 큐에서 작업을 선택할 때 이 토큰을 사용하여 GitLab에 인증합니다.

프로젝트 러너를 만들려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **CI/CD**를 선택합니다.
1. **러너** 섹션을 확장합니다.
1. **프로젝트 러너 생성**를 선택합니다.
1. GitLab Runner가 설치된 운영 체제를 선택합니다.
1. **태그** 섹션의 **태그** 필드에서 러너가 실행할 수 있는 작업을 지정하는 작업 태그를 입력합니다. 이 러너에 대한 작업 태그가 없으면 **Run untagged**을 선택합니다.
1. 선택 사항. **러너 설명** 필드에 GitLab에 표시할 러너에 대한 설명을 추가합니다.
1. 선택 사항. **구성** 섹션에서 추가 구성을 추가합니다.
1. **러너 만들기**를 선택합니다.
1. GitLab Runner가 설치된 플랫폼을 선택합니다.
1. 온스크린 지침을 완료합니다:
   - Linux, macOS, Windows의 경우, 명령줄에서 메시지가 나타나면:
     - `GitLab instance URL`에 대해 GitLab 인스턴스의 URL을 사용합니다. 예를 들어, 프로젝트가 `gitlab.example.com/yourname/yourproject`에 호스팅되는 경우, GitLab 인스턴스 URL은 `https://gitlab.example.com`입니다.
     - `executor`에 대해 [실행기](https://docs.gitlab.com/runner/executors/)의 유형을 입력합니다. 실행기는 러너가 작업을 실행하는 환경입니다.
   - Google Cloud의 경우 [Google Cloud에서 러너 프로비저닝](provision_runners_google_cloud.md)을 참조하세요.

[API를 사용](../../api/users.md#create-a-runner-linked-to-a-user)하여 러너를 만들 수도 있습니다.

> [!note]
> 러너 인증 토큰은 등록 중에 짧은 시간 동안만 UI에 표시됩니다.

### 등록 토큰으로 프로젝트 러너 만들기(사용 중단됨) {#create-a-project-runner-with-a-registration-token-deprecated}

> [!warning]
> 러너 등록 토큰을 전달하고 특정 구성 인수를 지원하는 옵션은 레거시로 간주되며 권장되지 않습니다. [러너 생성 워크플로우](https://docs.gitlab.com/runner/register/#register-with-a-runner-authentication-token)를 사용하여 러너를 등록할 인증 토큰을 생성합니다. 이 프로세스는 러너 소유권의 완전한 추적성을 제공하고 러너 플릿의 보안을 강화합니다. 자세한 내용은 [새 러너 등록 워크플로우로 마이그레이션](new_creation_workflow.md)을 참조하세요.

전제 조건:

- 러너 등록 토큰은 최상위 그룹에서 [활성화](#enable-use-of-runner-registration-tokens-in-projects-and-groups)되어야 합니다.
- 프로젝트에 대해 Maintainer 또는 Owner 역할이 필요합니다.

프로젝트 러너를 만들려면:

1. [GitLab Runner 설치](https://docs.gitlab.com/runner/install/).
1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **CI/CD**를 선택합니다.
1. **러너**를 확장합니다.
1. **Project runners** 섹션에서 URL과 토큰을 확인합니다.
1. [러너를 등록](https://docs.gitlab.com/runner/register/#register-with-a-runner-registration-token-legacy)합니다.

이제 러너가 프로젝트에 대해 활성화되었습니다.

### 프로젝트 러너 일시 중지 또는 재개 {#pause-or-resume-a-project-runner}

전제 조건:

- 관리자이거나 프로젝트에 대한 Maintainer 역할이 있어야 합니다.

프로젝트 러너를 일시 중지하여 할당된 GitLab 인스턴스의 프로젝트로부터 작업을 수락하지 않도록 할 수 있습니다.

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **CI/CD**를 선택합니다.
1. **러너**를 확장합니다.
1. **할당된 프로젝트 러너** 섹션에서 러너를 찾습니다.
1. 러너의 오른쪽에:
   - 러너를 일시 중지하려면 **중지** ({{< icon name="pause" >}})를 선택한 다음 **중지**를 선택합니다.
   - 러너를 재개하려면 **재개** ({{< icon name="play" >}})를 선택합니다.

### 프로젝트 러너 삭제 {#delete-a-project-runner}

전제 조건:

- 관리자이거나 프로젝트에 대한 Maintainer 역할이 있어야 합니다.
- 둘 이상의 프로젝트에 할당된 프로젝트 러너는 삭제할 수 없습니다. 러너를 삭제하기 전에 활성화된 모든 프로젝트에서 [비활성화](#enable-a-project-runner-for-a-different-project)해야 합니다.

프로젝트 러너를 삭제하면 GitLab 인스턴스에서 영구적으로 삭제되며 프로젝트에서 더 이상 사용할 수 없습니다. 러너가 작업을 수락하지 않도록 일시적으로 중지하려면 대신 [일시 중지](#pause-or-resume-a-project-runner)할 수 있습니다.

러너를 삭제하면 러너 호스트의 `config.toml` 파일에 구성이 계속 존재합니다. 삭제된 러너의 구성이 이 파일에 계속 있으면 러너 호스트는 계속 GitLab에 연결됩니다. 불필요한 API 트래픽을 방지하려면 [삭제된 러너의 등록을 취소](https://docs.gitlab.com/runner/commands/#gitlab-runner-unregister)해야 합니다.

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. **설정** > **CI/CD**를 선택합니다.
1. **러너**를 확장합니다.
1. **할당된 프로젝트 러너** 섹션에서 러너를 찾습니다.
1. 러너의 오른쪽에서 **Remove runner**를 선택합니다.
1. 러너를 삭제하려면 **삭제**를 선택합니다.

### 다른 프로젝트에 대해 프로젝트 러너 활성화 {#enable-a-project-runner-for-a-different-project}

프로젝트 러너를 만든 후 다른 프로젝트에 대해 활성화할 수 있습니다.

전제 조건: 다음에 대한 Maintainer 또는 소유자 역할이 있어야 합니다:

- 러너가 이미 활성화된 프로젝트.
- 러너를 활성화하려는 프로젝트.
- 프로젝트 러너는 [잠금](#prevent-a-project-runner-from-being-enabled-for-other-projects)되어 있으면 안 됩니다.

프로젝트에 대해 프로젝트 러너를 활성화하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **CI/CD**를 선택합니다.
1. **러너**를 확장합니다.
1. **Project runners** 영역에서 원하는 러너 옆에서 **Enable for this project**를 선택합니다.

활성화된 모든 프로젝트에서 프로젝트 러너를 편집할 수 있습니다. 잠금 해제 및 태그 및 설명 편집을 포함하는 수정 사항은 러너를 사용하는 모든 프로젝트에 영향을 미칩니다.

관리자는 [여러 프로젝트에 대해 러너를 활성화](../../administration/settings/continuous_integration.md#share-project-runners-with-multiple-projects)할 수 있습니다.

### 프로젝트 러너가 다른 프로젝트에 대해 활성화되지 않도록 방지 {#prevent-a-project-runner-from-being-enabled-for-other-projects}

프로젝트 러너를 "잠금"하여 다른 프로젝트에 대해 활성화할 수 없도록 구성할 수 있습니다. 이 설정은 처음 [러너를 등록](https://docs.gitlab.com/runner/register/)할 때 활성화할 수 있지만 나중에 변경할 수도 있습니다.

프로젝트 러너를 잠금 또는 잠금 해제하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **CI/CD**를 선택합니다.
1. **러너**를 확장합니다.
1. 잠금 또는 잠금 해제하려는 프로젝트 러너를 찾습니다. 활성화되어 있는지 확인합니다. 인스턴스 또는 그룹 러너는 잠금할 수 없습니다.
1. **편집** ({{< icon name="pencil" >}})을 선택합니다.
1. **현재 프로젝트 잠금** 체크박스를 선택합니다.
1. **변경사항 저장**을 선택합니다.

## 러너 상태 {#runner-statuses}

러너는 다음 상태 중 하나를 가질 수 있습니다.

| 상태  | 설명 |
|---------|-------------|
| `online`  | 러너는 지난 2시간 동안 GitLab에 연결되었으며 작업을 실행할 수 있습니다. |
| `offline` | 러너는 2시간 이상 GitLab에 연결되지 않았으며 작업을 실행할 수 없습니다. 러너를 확인하여 온라인 상태로 전환할 수 있는지 확인합니다. |
| `stale`   | 러너는 7일 이상 GitLab에 연결되지 않았습니다. 러너가 7일 이상 전에 생성되었지만 인스턴스에 연결된 적이 없으면 **stale**으로도 간주됩니다. |
| `never_contacted` | 러너는 GitLab에 연결된 적이 없습니다. 러너가 GitLab에 연결하도록 하려면 `gitlab-runner run`을(를) 실행합니다. |

## 오래된 러너 관리자 정리 {#stale-runner-manager-cleanup}

GitLab은 정기적으로 오래된 러너 관리자를 삭제하여 데이터베이스를 유지합니다. 러너가 GitLab 인스턴스에 연결되면 연결이 다시 생성됩니다.

## 러너 성능에 대한 통계 보기 {#view-statistics-for-runner-performance}

{{< details >}}

- 계층: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 15.8에서 [소개되었습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/377963).

{{< /history >}}

관리자는 러너 플릿의 성능에 대해 알아보기 위해 러너 통계를 볼 수 있습니다.

**Median job queued time** 값은 Instance 러너에 의해 실행된 가장 최근 100개 작업의 큐 지속 시간을 샘플링하여 계산됩니다. 최신 5000개 러너의 작업만 고려됩니다.

중간값은 50번째 백분위수에 속하는 값입니다. 절반의 작업은 중간값보다 오래 대기하고, 절반의 작업은 중간값보다 짧은 시간 동안 대기합니다.

러너 통계를 보려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **CI/CD** > **러너**를 선택합니다.
1. **측정항목 보기**를 선택합니다.

## 업그레이드해야 하는 러너 확인 {#determine-which-runners-need-to-be-upgraded}

{{< details >}}

- 계층: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 15.3에서 [소개되었습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/365078).

{{< /history >}}

전제 조건:

- 인스턴스 러너를 보기 위한 관리자 액세스 권한.
- 그룹 러너를 보기 위한 Maintainer 또는 소유자 역할.

러너가 사용하는 GitLab Runner의 버전은 [최신 상태로 유지](https://docs.gitlab.com/runner/#gitlab-runner-versions)되어야 합니다.

업그레이드해야 하는 러너를 확인하려면:

1. 러너 목록을 봅니다:
   - 그룹의 경우:
     1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
     1. **빌드** > **러너**를 선택합니다.
   - 인스턴스의 경우:
     1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
     1. **CI/CD** > **러너**를 선택합니다.

1. 러너 목록 위의 상태를 봅니다:
   - **Outdated - recommended**: 러너는 최신 `PATCH` 버전이 없으므로 보안 또는 높은 심각도 버그에 취약할 수 있습니다. 또는 러너가 GitLab 인스턴스보다 하나 이상의 `MAJOR` 버전이 뒤떨어져 있으므로 일부 기능을 사용할 수 없거나 제대로 작동하지 않을 수 있습니다.
   - **Outdated - available**: 최신 버전을 사용할 수 있지만 업그레이드는 필수적이지 않습니다.

1. 상태별로 목록을 필터링하여 업그레이드해야 하는 개별 러너를 봅니다.

## 러너의 IP 주소 확인 {#determine-the-ip-address-of-a-runner}

러너 문제를 해결하려면 러너의 IP 주소를 알아야 할 수 있습니다. GitLab은 러너가 작업을 폴링할 때 HTTP 요청의 소스를 확인하여 IP 주소를 저장하고 표시합니다. GitLab은 업데이트될 때마다 자동으로 러너의 IP 주소를 업데이트합니다.

인스턴스 러너와 프로젝트 러너의 IP 주소는 다양한 위치에서 찾을 수 있습니다.

### 인스턴스 러너의 IP 주소 확인 {#determine-the-ip-address-of-an-instance-runner}

전제 조건:

- 인스턴스에 대한 관리자 액세스 권한이 있어야 합니다.

인스턴스 러너의 IP 주소를 확인하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **CI/CD** > **러너**를 선택합니다.
1. 표에서 러너를 찾고 **IP 주소** 열을 봅니다.

![인스턴스 러너의 IP 주소 열을 보여주는 운영자 영역](img/shared_runner_ip_address_v14_5.png)

### 프로젝트 러너의 IP 주소 확인 {#determine-the-ip-address-of-a-project-runner}

프로젝트의 러너 IP 주소를 찾으려면 프로젝트에 대한 소유자 역할이 있어야 합니다.

1. 프로젝트의 **설정** > **CI/CD**로 이동하고 **러너** 섹션을 확장합니다.
1. 러너 이름을 선택하고 **IP 주소** 행을 찾습니다.

![프로젝트 러너의 IP 주소 필드를 보여주는 러너 세부 정보 페이지](img/project_runner_ip_address_v17_6.png)

## 러너 구성에 유지 관리 메모 추가 {#add-maintenance-notes-to-runner-configuration}

{{< details >}}

- 계층: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 15.1에서 [관리자용으로 소개됨](https://gitlab.com/gitlab-org/gitlab/-/issues/348299).
- GitLab 18.2에서 [그룹 및 프로젝트에 사용 가능하게 함](https://gitlab.com/gitlab-org/gitlab/-/issues/422621).

{{< /history >}}

러너를 문서화하기 위해 유지 관리 메모를 추가할 수 있습니다. 러너를 편집할 수 있는 사용자는 러너 세부 정보를 볼 때 메모를 봅니다.

이 기능을 사용하여 러너 구성을 변경하는 것과 관련된 결과 또는 문제에 대해 다른 사람에게 알립니다.

## 프로젝트 및 그룹에서 러너 등록 토큰 사용 활성화 {#enable-use-of-runner-registration-tokens-in-projects-and-groups}

{{< history >}}

- GitLab 16.11에서 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/148557)

{{< /history >}}

> [!warning]
> 러너 등록 토큰을 전달하고 특정 구성 인수를 지원하는 옵션은 레거시로 간주되며 권장되지 않습니다. [러너 생성 워크플로우](https://docs.gitlab.com/runner/register/#register-with-a-runner-authentication-token)를 사용하여 러너를 등록할 인증 토큰을 생성합니다. 이 프로세스는 러너 소유권의 완전한 추적성을 제공하고 러너 플릿의 보안을 강화합니다. 자세한 내용은 [새 러너 등록 워크플로우로 마이그레이션](new_creation_workflow.md)을 참조하세요.

GitLab 17.0에서 모든 GitLab 인스턴스에서 러너 등록 토큰의 사용이 비활성화됩니다.

전제 조건:

- 러너 등록 토큰은 **운영자** 영역에서 [활성화](../../administration/settings/continuous_integration.md#control-runner-registration)되어야 합니다.

프로젝트 및 그룹에서 러너 등록 토큰의 사용을 활성화하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **CI/CD**를 선택합니다.
1. **러너**를 확장합니다.
1. **프로젝트 및 그룹 멤버가 러너 등록 토큰을 사용하여 러너를 생성하도록 허용** 토글을 켭니다.
