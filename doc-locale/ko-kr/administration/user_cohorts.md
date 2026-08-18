---
stage: Facilitated functionality
group: Facilitated functionality
info: For more information, see <https://handbook.gitlab.com/handbook/product/categories/#facilitated-functionality>
description: 사용자 유지율과 활동 추세를 시간 경과에 따라 분석합니다.
gitlab_dedicated: yes
title: 사용자 코호트
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

사용자의 GitLab 활동을 시간 경과에 따라 분석할 수 있습니다.

사용자 코호트 테이블을 어떻게 해석합니까? 다음 사용자 코호트를 포함한 예시를 검토해 보겠습니다:

![2020년 3월과 4월을 강조하는 유지율 및 비활성 지표를 표시하는 사용자 코호트 테이블](img/cohorts_v13_9.png)

2020년 3월 코호트의 경우 이 서버에 3명의 사용자가 추가되었으며 이 달 이후 활동 상태가 유지되고 있습니다. 1개월 후(2020년 4월)에는 2명의 사용자가 여전히 활동 중입니다. 5개월 후(2020년 8월)에는 이 코호트의 1명 사용자가 여전히 활동 중이거나, 3월에 가입한 원래 3명 코호트의 33%입니다.

**비활성 사용자** 열은 해당 월 동안 추가되었지만 인스턴스에서 활동이 없었던 사용자의 수를 표시합니다.

사용자의 활동을 어떻게 측정합니까? GitLab은 다음 조건을 만족하면 사용자를 활동 상태로 간주합니다:

- 사용자가 로그인합니다.
- 사용자가 Git 활동(푸시 또는 풀)을 수행합니다.
- 사용자가 대시보드, 프로젝트, 이슈 또는 머지 리퀘스트와 관련된 페이지를 방문합니다.
- 사용자가 API를 사용합니다.
- 사용자가 GraphQL API를 사용합니다.

## 사용자 코호트 보기 {#view-user-cohorts}

전제 조건:

- 관리자 액세스 권한이 있어야 합니다.

사용자 코호트를 보려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **개요** > **사용자**를 선택합니다.
1. **코호트** 탭을 선택합니다.
