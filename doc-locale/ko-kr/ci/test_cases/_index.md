---
stage: Plan
group: Product Planning
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab의 테스트 케이스는 팀이 기존 개발 플랫폼에서 테스트 시나리오를 만드는 데 도움이 될 수 있습니다.
title: 테스트 케이스
---

{{< details >}}

- 계층: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

테스트 케이스는 테스트 계획을 GitLab 워크플로우에 직접 통합합니다. 팀은 다음을 수행할 수 있습니다:

- 코드를 관리하는 것과 동일한 플랫폼에서 테스트 시나리오를 문서화합니다.
- 개발 작업과 함께 테스트 요구 사항을 추적합니다.
- 구현 및 테스트 팀 전반에 걸쳐 테스트 계획을 공유합니다.
- 기밀 설정을 통해 테스트 케이스 가시성을 관리합니다.
- 필요에 따라 테스트 케이스를 아카이빙하고 다시 엽니다.

팀은 테스트 케이스를 사용하여 개발 팀과 테스트 팀 간의 협업을 간소화하며, 이는 외부 테스트 계획 도구의 필요성을 제거합니다.

<i class="fa-youtube-play" aria-hidden="true"></i> 이슈와 에픽을 사용하여 요구 사항 및 테스트 요구 사항을 관리하면서 개발 워크플로우와 통합하는 방법을 알아보려면 [소프트웨어 개발 간소화: 요구 사항, 테스트 및 개발 워크플로우 통합](https://www.youtube.com/watch?v=wbfWM4y2VmM).
<!-- Video published on 2024-02-21 -->

## 테스트 케이스 만들기 {#create-a-test-case}

{{< history >}}

- [변경됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256) \- GitLab 17.7에서 최소 사용자 역할이 리포터에서 플래너로 변경되었습니다.

{{< /history >}}

전제 조건:

- 플래너, 리포터, 개발자, 유지보수자 또는 소유자 역할이 있어야 합니다.

GitLab 프로젝트에서 테스트 케이스를 만들려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **빌드** > **테스트 케이스**를 선택합니다.
1. **새 테스트 케이스**를 선택합니다. 새 테스트 케이스 양식으로 이동합니다. 여기에서 새 케이스의 제목, [설명](../../user/markdown.md)을 입력하고 파일을 첨부하며 [레이블](../../user/project/labels.md)을 할당할 수 있습니다.
1. **테스트 케이스 제출**을 선택합니다. 새 테스트 케이스를 보기 위해 이동합니다.

## 테스트 케이스 보기 {#view-a-test-case}

프로젝트의 테스트 케이스 목록에서 모든 테스트 케이스를 볼 수 있습니다. 이슈 목록을 검색 쿼리(레이블 또는 테스트 케이스 제목 포함)로 필터링합니다.

전제 조건:

- 공개 프로젝트의 비기밀 테스트 케이스: 프로젝트의 멤버일 필요가 없습니다.
- 개인 프로젝트의 비기밀 테스트 케이스: 프로젝트에 대해 게스트, 플래너, 리포터, 개발자, 유지보수자 또는 소유자 역할이 있어야 합니다.
- 기밀 테스트 케이스(프로젝트 가시성 무관): 프로젝트에 대해 플래너, 리포터, 개발자, 유지보수자 또는 소유자 역할이 있어야 합니다.

테스트 케이스를 보려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **빌드** > **테스트 케이스**를 선택합니다.
1. 보려는 테스트 케이스의 제목을 선택합니다. 테스트 케이스 페이지로 이동합니다.

![제목, 설명, 레이블 및 사이드바 옵션을 표시하는 테스트 케이스 페이지입니다.](img/test_case_show_v13_10.png)

## 테스트 케이스 편집 {#edit-a-test-case}

{{< history >}}

- [변경됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256) \- GitLab 17.7에서 최소 사용자 역할이 리포터에서 플래너로 변경되었습니다.

{{< /history >}}

테스트 케이스의 제목과 설명을 편집할 수 있습니다.

전제 조건:

- 플래너, 리포터, 개발자, 유지보수자 또는 소유자 역할이 있어야 합니다.
- 게스트 역할로 강등된 사용자는 더 높은 역할에 있을 때 만든 테스트 케이스를 계속 편집할 수 있습니다.

테스트 케이스를 편집하려면:

1. [테스트 케이스 보기](#view-a-test-case).
1. 오른쪽 위 모서리에서 **편집**을 선택합니다.
1. 테스트 케이스의 제목 또는 설명을 편집합니다.
1. **변경사항 저장**을 선택합니다.

## 테스트 케이스를 기밀로 설정 {#make-a-test-case-confidential}

{{< history >}}

- GitLab 16.5에서 [새로운](https://gitlab.com/gitlab-org/gitlab/-/issues/422121) 및 [기존](https://gitlab.com/gitlab-org/gitlab/-/issues/422120) 테스트 케이스에 도입되었습니다.
- [변경됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256) \- GitLab 17.7에서 최소 사용자 역할이 리포터에서 플래너로 변경되었습니다.

{{< /history >}}

개인 정보가 포함된 테스트 케이스 작업 중인 경우 이를 기밀로 설정할 수 있습니다.

전제 조건:

- 플래너, 리포터, 개발자, 유지보수자 또는 소유자 역할이 있어야 합니다.

테스트 케이스를 기밀로 설정하려면:

- [테스트 케이스를 만들 때](#create-a-test-case): **공개 수준** 아래에서 **This test case is confidential** 확인란을 선택합니다.
- [테스트 케이스를 편집할 때](#edit-a-test-case): 오른쪽 사이드바에서 **공개 수준** 옆의 **편집**을 선택한 후 **켜기**를 선택합니다.

새 테스트 케이스를 만들거나 기존 테스트 케이스를 편집할 때 [`/confidential` 빠른 작업](../../user/project/quick_actions.md#confidential)을 사용할 수도 있습니다.

## 테스트 케이스 아카이빙 {#archive-a-test-case}

{{< history >}}

- [변경됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256) \- GitLab 17.7에서 최소 사용자 역할이 리포터에서 플래너로 변경되었습니다.

{{< /history >}}

테스트 케이스 사용을 중단하려면 이를 아카이빙할 수 있습니다. 나중에 [아카이빙된 테스트 케이스를 다시 열 수 있습니다](#reopen-an-archived-test-case).

전제 조건:

- 플래너, 리포터, 개발자, 유지보수자 또는 소유자 역할이 있어야 합니다.

테스트 케이스를 아카이빙하려면 테스트 케이스 페이지에서 **Archive test case**을 선택합니다.

아카이빙된 테스트 케이스를 보려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **빌드** > **테스트 케이스**를 선택합니다.
1. **아카이빙됨**을 선택합니다.

## 아카이빙된 테스트 케이스 다시 열기 {#reopen-an-archived-test-case}

{{< history >}}

- [변경됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256) \- GitLab 17.7에서 최소 사용자 역할이 리포터에서 플래너로 변경되었습니다.

{{< /history >}}

아카이빙된 테스트 케이스를 다시 사용하기로 결정한 경우 이를 다시 열 수 있습니다.

전제 조건:

- 플래너, 리포터, 개발자, 유지보수자 또는 소유자 역할이 있어야 합니다.

아카이빙된 테스트 케이스를 다시 열려면:

1. [테스트 케이스 보기](#view-a-test-case).
1. **Reopen test case**를 선택합니다.
