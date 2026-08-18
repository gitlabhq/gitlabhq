---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Jira 이슈 관리
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

[GitLab에서 Jira 이슈를 직접 관리](configure.md)할 수 있습니다. GitLab 커밋과 머지 리퀘스트에서 ID로 Jira 이슈를 참조할 수 있습니다. Jira 이슈 ID는 대문자여야 합니다.

## GitLab 활동 및 Jira 이슈 교차 참조 {#cross-reference-gitlab-activity-and-jira-issues}

이 통합을 통해 GitLab 이슈, 머지 리퀘스트 및 Git에서 작업하면서 Jira 이슈를 교차 참조할 수 있습니다. GitLab 이슈, 머지 리퀘스트, 댓글 또는 커밋에서 Jira 이슈를 언급하면:

- GitLab이 GitLab의 언급으로부터 Jira 이슈로 링크합니다.
- GitLab이 GitLab의 이슈, 머지 리퀘스트 또는 커밋으로 다시 링크하는 형식화된 댓글을 Jira 이슈에 추가합니다.

예를 들어, 이 커밋이 `GIT-1` Jira 이슈를 참조할 때:

```shell
git commit -m "GIT-1 this is a test commit"
```

GitLab이 해당 Jira 이슈에 추가합니다:

- **Web links** 섹션의 참조입니다.
- **활동** 섹션의 댓글로 다음 형식을 따릅니다:

  ```plaintext
  USER mentioned this issue in RESOURCE_NAME of [PROJECT_NAME|COMMENTLINK]:
  ENTITY_TITLE
  ```

  - `USER`: Jira 이슈를 언급한 사용자의 이름과 GitLab 사용자 프로필로의 링크입니다.
  - `RESOURCE_NAME`: Jira 이슈를 참조한 리소스의 유형(예: GitLab 커밋, 이슈 또는 머지 리퀘스트)입니다.
  - `PROJECT_NAME`: GitLab 프로젝트 이름입니다.
  - `COMMENTLINK`: Jira 이슈가 언급된 위치로의 링크입니다.
  - `ENTITY_TITLE`: GitLab 커밋(첫 번째 줄), 이슈 또는 머지 리퀘스트의 제목입니다.

GitLab 이슈, 머지 리퀘스트 또는 커밋당 Jira에 단일 교차 참조만 표시됩니다. 예를 들어, Jira 이슈를 참조하는 GitLab 머지 리퀘스트의 여러 댓글은 Jira의 해당 머지 리퀘스트에 대한 단일 교차 참조만 만듭니다.

이슈에서 [댓글을 비활성화](#disable-comments-on-jira-issues)할 수 있습니다.

### 머지 리퀘스트를 병합하기 위해 연결된 Jira 이슈가 필요 {#require-associated-jira-issue-for-merge-requests-to-be-merged}

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 통합을 통해 Jira 이슈를 참조하지 않는 경우 머지 리퀘스트가 병합되지 않도록 할 수 있습니다. 이 기능을 활성화하려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **머지 리퀘스트**를 선택합니다.
1. **머지 점검** 섹션에서 **Jira로 부터 연결된 이슈가 필요**를 선택합니다.
1. **저장**을 선택합니다.

이 기능을 활성화한 후 연결된 Jira 이슈를 참조하지 않는 머지 리퀘스트는 병합할 수 없습니다. 머지 리퀘스트에 **To merge, a Jira issue key must be mentioned in the title or description** 메시지가 표시됩니다.

## GitLab에서 Jira 이슈 일치 사용자 지정 {#customize-jira-issue-matching-in-gitlab}

{{< history >}}

- GitLab 15.10에 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/112826)됨.

{{< /history >}}

다음을 정의하여 GitLab이 Jira 이슈 키를 일치시키는 방식에 대한 사용자 지정 규칙을 구성할 수 있습니다:

- [정규식 패턴](#define-a-regex-pattern)
- [접두사](#define-a-prefix)

사용자 지정 규칙을 구성하지 않으면 [기본 동작](https://gitlab.com/gitlab-org/gitlab/-/blob/9b062706ac6203f0fa897a9baf5c8e9be1876c74/lib/gitlab/regex.rb#L245)이 사용됩니다.

### 정규식 패턴 정의 {#define-a-regex-pattern}

{{< history >}}

- 통합 이름이 GitLab 17.6에서 **Jira 이슈**로 [업데이트](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/166555)됨.

{{< /history >}}

정규식(regex)을 사용하여 Jira 이슈 키를 일치시킬 수 있습니다. 정규식 패턴은 [RE2 구문](https://github.com/google/re2/wiki/Syntax)을 따라야 합니다.

Jira 이슈 키에 대한 정규식 패턴을 정의하려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **연동**을 선택합니다.
1. **Jira 이슈**를 선택합니다.
1. **일치하는 Jira 이슈** 섹션으로 이동합니다.
1. **Jira 이슈 정규식** 텍스트 상자에 정규식 패턴을 입력합니다.
1. **변경 사항 저장**을 선택합니다.

자세한 내용은 [Atlassian 문서](https://confluence.atlassian.com/adminjiraserver073/changing-the-project-key-format-861253229.html)를 참조하세요.

### 접두사 정의 {#define-a-prefix}

{{< history >}}

- 통합 이름이 GitLab 17.6에서 **Jira 이슈**로 [업데이트](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/166555)됨.

{{< /history >}}

접두사를 사용하여 Jira 이슈 키를 일치시킬 수 있습니다. 예를 들어, Jira 이슈 키가 `ALPHA-1`이고 `JIRA#` 접두사를 정의하면 GitLab은 `JIRA#ALPHA-1`을 `ALPHA-1`가 아니라 일치시킵니다.

Jira 이슈 키에 대한 접두사를 정의하려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **연동**을 선택합니다.
1. **Jira 이슈**를 선택합니다.
1. **일치하는 Jira 이슈** 섹션으로 이동합니다.
1. **Jira 이슈 접두사** 텍스트 상자에 접두사를 입력합니다.
1. **변경 사항 저장**을 선택합니다.

## GitLab에서 Jira 이슈 종료 {#close-jira-issues-in-gitlab}

GitLab 전환 ID를 구성한 경우 GitLab에서 직접 Jira 이슈를 종료할 수 있습니다. 커밋 또는 머지 리퀘스트에서 트리거 단어 다음에 Jira 이슈 ID를 사용합니다. 트리거 단어와 Jira 이슈 ID가 포함된 커밋을 푸시하면 GitLab이 다음을 수행합니다:

1. 언급된 Jira 이슈에 댓글을 답니다.
1. Jira 이슈를 종료합니다. Jira 이슈에 해결책이 있으면 전환되지 않습니다.

예를 들어, 다음 트리거 단어 중 하나를 사용하여 Jira 이슈 `PROJECT-1`를 종료합니다:

- `Resolves PROJECT-1`
- `Closes PROJECT-1`
- `Fixes PROJECT-1`

커밋 또는 머지 리퀘스트는 프로젝트의 [기본 브랜치](../../user/project/repository/branches/default.md)를 대상으로 해야 합니다. 프로젝트의 기본 브랜치를 [프로젝트 설정](../../user/project/repository/branches/default.md#change-the-default-branch-name-for-a-project)에서 변경할 수 있습니다.

브랜치 이름이 Jira 이슈 ID와 일치하면 `Closes <JIRA-ID>`이 기존 머지 리퀘스트 템플릿에 자동으로 추가됩니다. 이슈를 종료하지 않으려면 [자동 이슈 종료를 비활성화](../../user/project/issues/managing_issues.md#disable-automatic-issue-closing)합니다.

### 이슈 종료에 대한 사용 사례 {#use-case-for-closing-issues}

이 예를 고려하세요:

1. 사용자가 새 기능을 요청하기 위해 Jira 이슈 `PROJECT-7`를 만듭니다.
1. 요청된 기능을 빌드하기 위해 GitLab에서 머지 리퀘스트를 만듭니다.
1. 머지 리퀘스트에서 이슈 종료 트리거 `Closes PROJECT-7`를 추가합니다.
1. 머지 리퀘스트가 병합되면:
   - GitLab이 Jira 이슈를 종료합니다.
   - GitLab이 Jira에 형식화된 댓글을 추가하여 이슈를 해결한 커밋으로 다시 연결합니다. [댓글을 비활성화](#disable-comments-on-jira-issues)할 수 있습니다.

## 자동 이슈 전환 {#automatic-issue-transitions}

자동 이슈 전환을 구성하면 참조된 Jira 이슈를 **완료** 범주의 다음 사용 가능한 상태로 전환할 수 있습니다. 이 설정을 구성하려면:

1. [GitLab 구성](configure.md) 지침을 참조합니다.
1. **Jira 전환 활성화** 확인란을 선택합니다.
1. **완료로 이동** 옵션을 선택합니다.

## 사용자 지정 이슈 전환 {#custom-issue-transitions}

고급 워크플로의 경우 사용자 지정 Jira 전환 ID를 지정할 수 있습니다:

1. Jira 구독 상태에 따라 방법을 사용합니다:

   - Jira Cloud 사용자의 경우: **텍스트** 보기에서 워크플로를 편집하여 전환 ID를 얻습니다. 전환 ID는 **Transitions** 열에 표시됩니다.
   - Jira Server 사용자의 경우: 다음 방법 중 하나로 전환 ID를 얻습니다:
     - 적절한 "열기" 상태에 있는 이슈를 사용하여 `https://yourcompany.atlassian.net/rest/api/2/issue/ISSUE-123/transitions`과 같은 요청으로 API를 사용합니다.
     - 원하는 전환에 대한 링크 위로 마우스를 이동하고 URL에서 **동작** 매개변수를 찾습니다.

   전환 ID는 워크플로 간에 다를 수 있습니다(예: 스토리 대신 버그). 변경하는 상태가 동일한 경우에도 마찬가지입니다.
1. [GitLab 구성](configure.md) 지침을 참조합니다.
1. **Jira 전환 활성화** 설정을 선택합니다.
1. **Custom transitions** 옵션을 선택합니다.
1. 텍스트 필드에 전환 ID를 입력합니다. 여러 전환 ID(`,` 또는 `;`로 구분)를 삽입하면 이슈가 지정한 순서대로 한 번에 하나씩 각 상태로 이동합니다. 전환에 실패하면 시퀀스가 중단됩니다.

## Jira 이슈에서 댓글 비활성화 {#disable-comments-on-jira-issues}

GitLab은 Jira 이슈에 댓글을 추가하지 않고도 소스 커밋 또는 머지 리퀘스트를 Jira 이슈와 교차 연결할 수 있습니다:

1. [GitLab 구성](configure.md) 지침을 참조합니다.
1. **댓글 활성화** 확인란을 선택 해제합니다.
