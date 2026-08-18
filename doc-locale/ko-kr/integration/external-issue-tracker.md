---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 외부 이슈 추적 도구
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab은 자체 [이슈 추적 도구](../user/project/issues/_index.md)를 갖고 있지만, GitLab 프로젝트당 외부 이슈 추적 도구를 구성할 수도 있습니다. 그러면 다음을 사용할 수 있습니다:

- GitLab 이슈 추적 도구와 함께 외부 이슈 추적 도구
- 외부 이슈 추적 도구만 사용

외부 추적 도구를 사용하면 `CODE-123` 형식을 사용하여 GitLab 머지 리퀘스트, 커밋 및 댓글에서 외부 이슈를 언급할 수 있습니다:

- `CODE`은 추적 도구의 고유 코드입니다.
- `123`은 추적 도구의 이슈 번호입니다.

참조는 이슈 링크로 표시됩니다.

## GitLab 이슈 추적 도구 비활성화 {#disable-the-gitlab-issue-tracker}

GitLab 이슈 추적 도구를 포함하여 프로젝트의 작업 항목을 비활성화하려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **일반**을 선택합니다.
1. **표시 여부, 프로젝트 기능, 권한**을 확장합니다.
1. **작업 항목** 아래에서 토글을 비활성화합니다.
1. **변경 사항 저장**을 선택합니다.

작업 항목 설정을 비활성화한 후, **작업 항목**은 왼쪽 사이드바에 표시되지 않습니다. 외부 이슈 추적 도구를 구성한 경우, [외부 이슈 추적 도구](#configure-an-external-issue-tracker)는 왼쪽 사이드바에 유지됩니다.

## 외부 이슈 추적 도구 구성 {#configure-an-external-issue-tracker}

다음 외부 이슈 추적 도구 중 하나를 구성할 수 있습니다:

- [Bugzilla](../user/project/integrations/bugzilla.md)
- [ClickUp](../user/project/integrations/clickup.md)
- [사용자 정의 이슈 추적 도구](../user/project/integrations/custom_issue_tracker.md)
- [엔지니어링 워크플로우 관리(EWM)](../user/project/integrations/ewm.md)
- [Jira](jira/_index.md)
- [Linear](../user/project/integrations/linear.md)
- [Phorge](../user/project/integrations/phorge.md)
- [Redmine](../user/project/integrations/redmine.md)
- [YouTrack](../user/project/integrations/youtrack.md)
