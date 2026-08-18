---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 파이프라인 구성 사용자 지정
description: "파이프라인 설정을 구성하여 가시성, 시간 초과, Git 전략, 자동 취소 동작 및 자동 정리를 사용자 지정합니다."
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

프로젝트의 파이프라인 실행 방식을 사용자 지정할 수 있습니다.

## 파이프라인을 볼 수 있는 사용자 변경 {#change-which-users-can-view-your-pipelines}

공개 및 내부 프로젝트의 경우 다음을 볼 수 있는 사용자를 변경할 수 있습니다:

- 파이프라인
- 작업 출력 로그
- 작업 아티팩트
- [파이프라인 보안 결과](../../user/application_security/detect/security_scanning_results.md)

파이프라인 및 관련 기능의 가시성을 변경하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **CI/CD**를 선택합니다.
1. **일반 파이프라인**을 확장합니다.
1. **프로젝트 기반 파이프라인 공개범위** 체크박스를 선택하거나 해제합니다. 선택하면 파이프라인 및 관련 기능이 표시됩니다:

   - [**공개**](../../user/public_access.md) 프로젝트의 경우 모든 사용자에게 표시됩니다.
   - **내부** 프로젝트의 경우 [외부 사용자](../../administration/external_users.md)를 제외한 모든 인증된 사용자에게 표시됩니다.
   - **비공개** 프로젝트의 경우 모든 프로젝트 멤버(게스트 이상)에게 표시됩니다.

   해제되면:

   - **공개** 프로젝트의 경우 작업 로그, 작업 아티팩트, 파이프라인 보안 대시보드 및 **CI/CD** 메뉴 항목은 프로젝트 멤버(리포터 이상)에게만 표시됩니다. 게스트 사용자를 포함한 다른 사용자는 파이프라인 및 작업의 상태만 볼 수 있으며 머지 리퀘스트 또는 커밋을 볼 때만 가능합니다.
   - **내부** 프로젝트의 경우 파이프라인은 [외부 사용자](../../administration/external_users.md)를 제외한 모든 인증된 사용자에게 표시됩니다. 관련 기능은 프로젝트 멤버(리포터 이상)에게만 표시됩니다.
   - **비공개** 프로젝트의 경우 파이프라인 및 관련 기능은 프로젝트 멤버(리포터 이상)에게만 표시됩니다.

### 공개 프로젝트에서 프로젝트 외부 멤버에 대한 파이프라인 가시성 변경 {#change-pipeline-visibility-for-non-project-members-in-public-projects}

[공개 프로젝트](../../user/public_access.md)에서 프로젝트 외부 멤버에 대한 파이프라인 가시성을 제어할 수 있습니다.

이 설정은 다음과 같은 경우 효과가 없습니다:

- 프로젝트 가시성이 [**내부** 또는 **비공개**](../../user/public_access.md)로 설정되어 있으면 프로젝트 외부 멤버는 내부 또는 비공개 프로젝트에 액세스할 수 없습니다.
- [**프로젝트 기반 파이프라인 공개범위**](#change-which-users-can-view-your-pipelines) 설정이 비활성화됩니다.

프로젝트 외부 멤버에 대한 파이프라인 가시성을 변경하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **일반**을 선택합니다.
1. **표시 여부, 프로젝트 기능, 권한**을 확장합니다.
1. **CI/CD**의 경우 다음을 선택합니다:
   - **Only project members**: 프로젝트 멤버만 파이프라인을 볼 수 있습니다.
   - **액세스 권한이 있는 모든 사용자**: 프로젝트 외부 멤버도 파이프라인을 볼 수 있습니다.
1. **변경사항 저장**을 선택합니다.

[CI/CD 권한 표](../../user/permissions.md#project-cicd)는 **액세스 권한이 있는 모든 사용자**를 선택했을 때 프로젝트 외부 멤버가 액세스할 수 있는 파이프라인 기능을 나열합니다.

## 중복 파이프라인의 자동 취소 {#auto-cancel-redundant-pipelines}

같은 브랜치에서 새로운 변경 사항을 위한 파이프라인이 실행될 때 보류 중이거나 실행 중인 파이프라인을 자동으로 취소하도록 설정할 수 있습니다. 프로젝트 설정에서 이를 활성화할 수 있습니다:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **CI/CD**를 선택합니다.
1. **General Pipelines**을 확장합니다.
1. **중복 파이프라인의 자동 취소** 체크박스를 선택합니다.
1. **변경사항 저장**을 선택합니다.

[`interruptible`](../yaml/_index.md#interruptible) 키워드를 사용하여 실행 중인 작업을 완료 전에 취소할 수 있는지 여부를 나타냅니다. `interruptible: false`이 있는 작업이 시작되면 전체 파이프라인은 더 이상 중단 가능하지 않습니다.

## 오래된 배포 작업 방지 {#prevent-outdated-deployment-jobs}

프로젝트에 같은 시간대에 실행되도록 예약된 여러 동시 배포 작업이 있을 수 있습니다.

이로 인해 오래된 배포 작업이 새 작업 후에 실행되는 상황이 발생할 수 있으며, 이는 원하는 결과가 아닐 수 있습니다.

이 시나리오를 방지하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **CI/CD**를 선택합니다.
1. **일반 파이프라인**을 확장합니다.
1. **오래된 배포 작업 방지** 체크박스를 선택합니다.
1. 선택 사항. **배포 롤백을 위한 작업 재시도 허용** 체크박스를 해제합니다.
1. **변경사항 저장**을 선택합니다.

자세한 내용은 [배포 보안](../environments/deployment_safety.md#prevent-outdated-deployment-jobs)을 참조하세요.

## 파이프라인 또는 작업을 취소할 수 있는 역할 제한 {#restrict-roles-that-can-cancel-pipelines-or-jobs}

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

파이프라인 또는 작업을 취소할 수 있는 권한이 있는 역할을 사용자 지정할 수 있습니다.

기본적으로 개발자, 유지 보수자 또는 소유자 역할을 가진 사용자는 파이프라인 또는 작업을 취소할 수 있습니다. 취소 권한을 유지 보수자 또는 소유자 역할을 가진 사용자만으로 제한하거나 파이프라인 또는 작업의 취소를 완전히 방지할 수 있습니다.

파이프라인 또는 작업을 취소할 수 있는 권한을 변경하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **CI/CD**를 선택합니다.
1. **일반 파이프라인**을 확장합니다.
1. **파이프라인 또는 작업을 취소하는 데 필요한 최소 역할**에서 옵션을 선택합니다.
1. **변경사항 저장**을 선택합니다.

## 사용자 지정 CI/CD 구성 파일 지정 {#specify-a-custom-cicd-configuration-file}

GitLab은 CI/CD 구성 파일(`.gitlab-ci.yml`)을 프로젝트의 루트 디렉터리에서 찾아야 합니다. 그러나 프로젝트 외부의 위치를 포함하여 다른 파일 이름 경로를 지정할 수 있습니다.

경로를 사용자 지정하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **CI/CD**를 선택합니다.
1. **일반 파이프라인**을 확장합니다.
1. **CI/CD 설정 파일** 필드에 파일 이름을 입력합니다. 파일이:
   - 루트 디렉터리에 없으면 경로를 포함합니다.
   - 다른 프로젝트에 있으면 그룹 및 프로젝트 이름을 포함합니다.
   - 외부 사이트에 있으면 전체 URL을 입력합니다.
1. **변경사항 저장**을 선택합니다.

> [!note]
> 프로젝트의 [파이프라인 편집기](../pipeline_editor/_index.md)를 사용하여 다른 프로젝트 또는 외부 사이트의 CI/CD 구성 파일을 편집할 수 없습니다.

### 사용자 지정 CI/CD 구성 파일 예 {#custom-cicd-configuration-file-examples}

CI/CD 구성 파일이 루트 디렉터리에 없으면 경로는 루트 디렉터리에 상대적이어야 합니다. 예를 들어:

- `my/path/.gitlab-ci.yml`
- `my/path/.my-custom-file.yml`

CI/CD 구성 파일이 외부 사이트에 있으면 URL은 `.yml`로 끝나야 합니다:

- `http://example.com/generate/ci/config.yml`

CI/CD 구성 파일이 다른 프로젝트에 있으면:

- 파일은 기본 브랜치에 존재하거나 브랜치를 refname으로 지정해야 합니다.
- 경로는 다른 프로젝트의 루트 디렉터리에 상대적이어야 합니다.
- 경로 뒤에는 `@` 기호와 전체 그룹 및 프로젝트 경로가 와야 합니다.

예를 들어:

- `.gitlab-ci.yml@namespace/another-project`
- `my/path/.my-custom-file.yml@namespace/subgroup/another-project`
- `my/path/.my-custom-file.yml@namespace/subgroup1/subgroup2/another-project:refname`

구성 파일이 별도의 프로젝트에 있으면 더 세분화된 권한을 설정할 수 있습니다. 예를 들어:

- 구성 파일을 호스팅할 공개 프로젝트를 만듭니다.
- 파일을 편집할 수 있는 사용자에게만 프로젝트에 대한 쓰기 권한을 부여합니다.

그러면 다른 사용자 및 프로젝트는 구성 파일을 편집하지 않고도 액세스할 수 있습니다.

## 기본 Git 전략 선택 {#choose-the-default-git-strategy}

작업이 실행될 때 GitLab에서 리포지토리를 가져오는 방식을 선택할 수 있습니다.

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **CI/CD**를 선택합니다.
1. **일반 파이프라인**을 확장합니다.
1. **Git 전략** 아래에서 옵션을 선택합니다:
   - `git clone`은 모든 작업마다 처음부터 리포지토리를 복제하므로 느립니다. 그러나 로컬 작업 복사본은 항상 깨끗합니다.
   - `git fetch`은 로컬 작업 복사본을 다시 사용하므로 더 빠릅니다(존재하지 않으면 복제로 폴백됨). 특히 [큰 리포지토리](../../user/project/repository/monorepos/_index.md#use-git-fetch-in-cicd-operations)의 경우 이를 권장합니다.

구성된 Git 전략은 [`GIT_STRATEGY` 변수](../runners/configure_runners.md#git-strategy)로 `.gitlab-ci.yml` 파일에서 재정의할 수 있습니다.

## 복제 중 가져오는 변경 사항 수 제한 {#limit-the-number-of-changes-fetched-during-clone}

GitLab CI/CD가 리포지토리를 복제할 때 가져오는 변경 사항의 수를 제한할 수 있습니다.

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **CI/CD**를 선택합니다.
1. **일반 파이프라인**을 확장합니다.
1. **Git 전략** 아래에서 **Git shallow clone** 아래에 값을 입력합니다. 최대값은 `1000`입니다. shallow clone을 비활성화하고 GitLab CI/CD가 매번 모든 브랜치와 태그를 가져오도록 하려면 값을 비워 두거나 `0`로 설정합니다.

새로 만든 프로젝트의 기본 `git depth` 값은 `20`입니다.

이 값은 [`GIT_DEPTH` 변수](../../user/project/repository/monorepos/_index.md#use-shallow-clones-and-filters-in-cicd-processes)로 `.gitlab-ci.yml` 파일에서 재정의할 수 있습니다.

## 작업을 실행할 수 있는 시간 제한 설정 {#set-a-limit-for-how-long-jobs-can-run}

작업이 시간 초과되기 전에 실행할 수 있는 기간을 정의할 수 있습니다.

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **CI/CD**를 선택합니다.
1. **일반 파이프라인**을 확장합니다.
1. **시간 초과** 필드에 분 수를 입력하거나 `2 hours`와 같은 인간이 읽을 수 있는 값을 입력합니다. 10분 이상이어야 하고 1개월 미만이어야 합니다. 기본값은 60분입니다. 보류 중인 작업은 24시간의 비활동 후 삭제됩니다.

시간 초과를 초과한 작업은 실패로 표시됩니다.

프로젝트 시간 초과와 [러너 시간 초과](../runners/configure_runners.md#set-the-maximum-job-timeout)가 모두 설정되면 낮은 값이 우선합니다.

1시간 동안 출력이 없는 작업은 시간 초과와 관계없이 삭제됩니다. 이를 방지하려면 진행 상황을 지속적으로 출력하는 스크립트를 추가합니다. 자세한 내용은 [이슈 25359](https://gitlab.com/gitlab-org/gitlab/-/issues/25359#workaround)를 참조하세요.

## 파이프라인 배지 {#pipeline-badges}

[파이프라인 배지](../../user/project/badges.md)를 사용하여 프로젝트의 파이프라인 상태 및 테스트 커버리지를 나타낼 수 있습니다. 이 배지는 최신 성공한 파이프라인에 의해 결정됩니다.

## GitLab CI/CD 파이프라인 비활성화 {#disable-gitlab-cicd-pipelines}

GitLab CI/CD 파이프라인은 기본적으로 모든 새 프로젝트에서 활성화됩니다. Jenkins 또는 Drone CI와 같은 외부 CI/CD 서버를 사용하는 경우 커밋 상태 API와의 충돌을 피하기 위해 GitLab CI/CD를 비활성화할 수 있습니다.

프로젝트별로 또는 [인스턴스의 모든 새 프로젝트에 대해](../../administration/cicd/_index.md) GitLab CI/CD를 비활성화할 수 있습니다.

GitLab CI/CD를 비활성화하면:

- 왼쪽 사이드바의 **CI/CD** 항목이 제거됩니다.
- `/pipelines` 및 `/jobs` 페이지는 더 이상 사용할 수 없습니다.
- 기존 작업 및 파이프라인은 숨겨지며 제거되지 않습니다.

프로젝트에서 GitLab CI/CD를 비활성화하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **일반**을 선택합니다.
1. **표시 여부, 프로젝트 기능, 권한**을 확장합니다.
1. **리포지토리** 섹션에서 **CI/CD**를 끕니다.
1. **변경사항 저장**을 선택합니다.

이 변경 사항은 [외부 통합](../../user/project/integrations/_index.md#available-integrations)의 프로젝트에는 적용되지 않습니다.

## 자동 파이프라인 청소 {#automatic-pipeline-cleanup}

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 17.7에서 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/498969) [플래그](../../administration/feature_flags/_index.md) `ci_delete_old_pipelines`와 함께 기본적으로 비활성화되어 있습니다.
- [기능 플래그 `ci_delete_old_pipelines`](https://gitlab.com/gitlab-org/gitlab/-/issues/503153)가 GitLab 17.9에서 제거되었습니다.

{{< /history >}}

파이프라인 저장소를 관리하고 시스템 성능을 개선하는 데 도움이 되는 보존 기간을 설정합니다. 구성된 기간보다 오래된 파이프라인은 백그라운드 작업에 의해 자동으로 삭제됩니다. 정리는 파이프라인이 적격이 될 때 즉시가 아니라 백그라운드에서 주기적으로 실행됩니다. 오래된 파이프라인의 대규모 백로그가 있는 프로젝트는 여러 실행에 걸쳐 점진적으로 정리됩니다.

파이프라인이 삭제되면 해당 작업, 작업 로그 및 아티팩트도 영구적으로 삭제됩니다. 구성된 보존 기간보다 오래된 모든 파이프라인은 상태나 특정 브랜치 또는 태그에 대한 최신 파이프라인 여부와 관계없이 삭제 대상입니다.

전제 조건:

- 프로젝트의 소유자 역할

자동 파이프라인 정리를 구성하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **CI/CD**를 선택합니다.
1. **일반 파이프라인**을 확장합니다.
1. **자동 파이프라인 청소** 필드에 지속 시간을 입력합니다. 예를 들어 `2 weeks` 또는 `30 days` 값은 최소 1일 이상이어야 하고 인스턴스 최대값(기본값 1년) 이하여야 합니다. 파이프라인을 자동으로 삭제하지 않으려면 비워 두세요.
1. **변경사항 저장**을 선택합니다.

GitLab Self-Managed의 경우 관리자는 [자동 파이프라인 청소](../../administration/cicd/limits.md#maximum-retention-period-for-automatic-pipeline-cleanup)의 상한을 높일 수 있습니다.
