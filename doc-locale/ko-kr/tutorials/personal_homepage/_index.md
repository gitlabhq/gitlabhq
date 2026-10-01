---
stage: Growth
group: Engagement
info: For assistance with this tutorial, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments-to-other-projects-and-subjects>.
title: '튜토리얼: 개인 홈페이지 사용'
---

{{< details >}}

- 계층: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 18.1에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/546151) 되었으며 [플래그](../../administration/feature_flags/_index.md) `personal_homepage`라는 이름입니다. 기본적으로 비활성화되어 있습니다.
- [GitLab.com에서 활성화됨](https://gitlab.com/gitlab-org/gitlab/-/issues/554048)(GitLab 18.4에서 일부 사용자를 대상으로)
- [GitLab.com, GitLab Self-Managed 및 GitLab Dedicated에서 활성화됨](https://gitlab.com/groups/gitlab-org/-/epics/17932)(GitLab 18.5)
- 최근에 본 Wiki 페이지:
  - GitLab 19.0에서 `recently_viewed_wiki_pages` [플래그](../../administration/feature_flags/_index.md)로 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/233014)되었습니다. 기본적으로 비활성화되어 있습니다.
  - [일반 공개](https://gitlab.com/gitlab-org/gitlab/-/work_items/597889)(GitLab 19.1) 기능 플래그 `recently_viewed_wiki_pages`이 제거되었습니다.

{{< /history >}}

<!-- vale gitlab_base.FutureTense = NO -->

개인 홈페이지는 관련된 모든 정보를 한 곳에 통합합니다. 주의가 필요한 새로운 작업 항목을 빠르게 식별하거나 중단된 위치에서 계속할 수 있습니다.

이 튜토리얼을 따라 홈페이지를 탐색하는 방법을 배우고 최대한 활용하세요.

## 시작하기 전에 {#before-you-begin}

[개인 홈페이지](../../user/profile/preferences.md#choose-your-homepage)를 기본 홈페이지로 설정합니다.

## 홈페이지 액세스 {#access-the-homepage}

GitLab의 어디서나 개인 홈페이지에 액세스할 수 있습니다:

- 왼쪽 사이드바의 상단에서 **홈페이지**를 선택합니다.
- 상단 표시줄에서 **검색 또는 이동**을 선택하고 **귀하의 작업**을 선택한 후 **홈**을 선택합니다.

## 홈페이지의 레이아웃 {#layout-of-the-homepage}

상단 근처에서 아바타를 선택하여 상태를 설정합니다. 상태를 설정한 경우 아바타에 상태 배지와 이모지가 표시되며, 마우스를 올려 상태 텍스트를 볼 수 있습니다.

아바타 아래에서 관련된 머지 리퀘스트 및 이슈의 수를 확인합니다.

**주의가 필요한 항목** 목록은 입력이 필요한 GitLab의 모든 작업 항목을 보여줍니다.

**최신 업데이트를 팔로우** 피드는 GitLab 전체의 활동과 관심 있는 특정 프로젝트 및 사용자의 활동을 보여줍니다.

홈페이지의 오른쪽으로 이동하여 최근에 본 항목과 자주 방문하는 프로젝트에 대한 빠른 링크에 액세스합니다.

## 하루를 시작하기 위해 홈페이지 사용 {#use-the-homepage-to-start-your-day}

하루의 작업을 시작하기 위해 홈페이지를 사용할 수 있는 몇 가지 방법을 살펴봅시다:

1. **주의가 필요한 항목** 목록의 필터를 사용하여 가장 중요한 이벤트를 봅니다. 예를 들어 실패한 파이프라인 때문에 차단된 머지 리퀘스트를 보려면 필터 드롭다운 목록에서 **실패한 빌드**를 선택합니다.
1. 홈페이지 상단 근처에서 **Merge requests waiting for your review**를 선택하여 검토가 필요한 머지 리퀘스트를 보고 다른 항목을 차단 해제할 수 있습니다.

예를 들어 작업 중이었던 내용을 추적할 수도 있습니다:

1. **최신 업데이트를 팔로우** 섹션에서 **당신의 활동** 필터를 사용하여 최근 작업을 봅니다. 링크를 선택하여 이슈 또는 머지 리퀘스트로 직접 이동하고 중단된 위치에서 계속합니다.
1. 오른쪽의 **빠른 액세스** 위젯에서:
   - **최근 본 내역**을 선택하여 최근에 방문한 이슈, 머지 리퀘스트, 에픽 및 Wiki 페이지를 봅니다.
   - **프로젝트**를 선택하여 자주 방문하는 프로젝트와 별표를 받은 프로젝트를 봅니다.
     - 프로젝트 유형별로 필터링하려면 **디스플레이 옵션**({{< icon name="preferences" >}})을 선택합니다.
   - 링크를 선택하여 작업 중이던 항목으로 빠르게 돌아갑니다.

## 팀 활동과 연결 유지 {#stay-connected-with-team-activity}

프로젝트에서 협업하는 경우 프로젝트에 별표를 추가하여 나중에 쉽게 찾을 수 있습니다. 그런 다음 홈페이지를 사용하여 해당 프로젝트에서 일어나고 있는 일을 개요로 봅니다.

프로젝트에 별표를 추가하고 홈페이지에서 활동을 보려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 페이지의 오른쪽 위 모서리에서 **별표**({{< icon name="star" >}})를 선택합니다.
1. 왼쪽 사이드바의 상단에서 **홈페이지**를 선택합니다.
1. **최신 업데이트를 팔로우** 섹션에서 드롭다운 목록에서 **별점을 받은 프로젝트**를 선택합니다.

팀과 더 효과적으로 협업하려면 다른 GitLab 사용자를 팔로우하고 작업 중인 내용을 볼 수 있습니다:

1. GitLab에서 사용자 프로필(예: `https://gitlab.example.com/username`)로 이동하여 **팔로우**를 선택합니다. 또는 GitLab의 어디서나 이름 위에 마우스를 올릴 때 나타나는 작은 팝오버에서 **팔로우**를 선택합니다.
1. 왼쪽 사이드바의 상단에서 **홈페이지**를 선택합니다.
1. **최신 업데이트를 팔로우** 섹션에서 드롭다운 목록에서 **팔로우한 사용자**를 선택합니다.

## 관련 항목 {#related-topics}

홈페이지에서 보고 액세스할 수 있는 다양한 작업 항목에 대해 자세히 알아봅니다.

- [할 일 목록](../../user/todos.md)
- [머지 리퀘스트](../../user/project/merge_requests/_index.md)
- [이슈](../../user/project/issues/_index.md)
