---
stage: AI-powered
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab for VS Code 확장을 사용하여 IDE에서 직접 GitLab 프로젝트로 작업할 수 있습니다.
title: VS Code에서 프로젝트로 작업하기
---

GitLab for VS Code 확장을 사용하여 GitLab 프로젝트로 작업합니다:

- 이슈에서 작업을 계획하고 추적합니다.
- AI 네이티브 계획 및 코딩을 위해 GitLab Duo를 사용합니다.
- 머지 리퀘스트에서 변경 사항을 검토하고 논의합니다.
- 브랜치를 비교하고 GitLab에서 파일을 봅니다.
- 스니펫으로 코드를 저장하고 공유합니다.

확장을 사용하여 VS Code에서 직접 많은 작업을 완료할 수 있습니다. 다른 작업의 경우 확장이 브라우저에서 GitLab을 엽니다.

## 전제 조건 {#prerequisites}

- [확장 인증](setup.md#connect-to-gitlab)을 수행하고 GitLab의 에 연결합니다.
- GitLab Duo의 경우 [구성 요구사항](setup.md#configure-gitlab-duo)을 검토합니다.

## 작업할 때 GitLab Duo 사용 {#use-gitlab-duo-as-you-work}

GitLab for VS Code 확장을 사용하면 프로젝트에서 작업할 때 GitLab Duo Agent Platform 및 GitLab Duo(비에이전트)에 액세스할 수 있습니다.

### GitLab Duo Agent Platform {#gitlab-duo-agent-platform}

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab Duo Agentic Chat, 에이전트 및 플로우를 사용하려면:

1. 왼쪽 사이드바에서 **GitLab Duo Agent Platform**({{< icon name="duo-agentic-chat" >}})을 선택합니다.
1. Agentic Chat과 상호 작용하려면 채팅 탭을 선택하고 프롬프트를 입력합니다.
1. 에이전트로 작업하려면 채팅 탭을 선택한 다음 **새 채팅** ({{< icon name="duo-chat-new" >}}) 드롭다운 목록을 사용하여 작업할 기초 또는 사용자 지정 에이전트를 선택합니다.
1. Software Development 플로우를 사용하려면 플로우 탭을 선택한 다음 프롬프트를 입력합니다.

GitLab Duo Code Suggestions를 사용하려면:

1. 하단 상태 표시줄에서 **Duo** ({{< icon name="tanuki-ai" >}}) 를 선택하여 기능 상태를 확인합니다.
1. 코드를 작성할 때 인라인 코드 제안을 검토하고 수락합니다.

### GitLab Duo {#gitlab-duo}

{{< details >}}

- 티어:  Premium, Ultimate
- 추가 기능: GitLab Duo Pro 또는 Enterprise, GitLab Duo with Amazon Q
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 19.0의 일부로 2026년 5월 21일부터 GitLab Duo Core 고객을 대상으로 GitLab Duo Non-Agentic Chat 액세스가 제거됨(`no_duo_classic_for_duo_core_users` 기능 플래그 사용). 기본적으로 활성화됨.

{{< /history >}}

GitLab Duo Non-Agentic Chat을 사용하려면:

1. 왼쪽 사이드바에서 **GitLab Duo Chat** ({{< icon name="duo-chat" >}}) 을 선택합니다.
1. 메시지 상자에 질문을 입력하고 <kbd>Enter</kbd> 키를 누르거나 **Send**를 선택합니다.

GitLab Duo Code Suggestions를 사용하려면:

1. 하단 상태 표시줄에서 **Duo** ({{< icon name="tanuki-ai" >}}) 를 선택하여 기능 상태를 확인합니다.
1. 코드를 작성할 때 인라인 코드 제안을 검토하고 수락합니다.

## 이슈 생성 {#create-an-issue}

현재 프로젝트에서 이슈를 생성하려면:

1. 명령 팔레트를 여세요:
   - macOS의 경우 <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>를 누르세요.
   - Windows 또는 Linux의 경우 <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>를 누르세요.
1. 명령 팔레트에서 **GitLab: Create New Issue on Current Project** 를 검색하고 <kbd>Enter</kbd> 를 누릅니다.

GitLab이 **새 이슈** 페이지를 기본 브라우저에서 엽니다.

## 머지 리퀘스트 생성 {#create-a-merge-request}

현재 프로젝트에서 머지 리퀘스트를 생성하려면 하단 상태 표시줄에서 **Create MR** ({{< icon name="merge-request-open" >}}) 을 선택합니다.

또는 명령 팔레트를 사용할 수 있습니다:

1. 명령 팔레트를 여세요:
   - macOS의 경우 <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>를 누르세요.
   - Windows 또는 Linux의 경우 <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>를 누르세요.
1. 명령 팔레트에서 **GitLab: Create New Merge Request on Current Project** 를 검색하고 <kbd>Enter</kbd> 를 누릅니다.

GitLab이 **새 머지 리퀘스트** 페이지를 기본 브라우저에서 엽니다.

## 이슈 및 머지 리퀘스트 보기 {#view-issues-and-merge-requests}

특정 프로젝트의 이슈 및 머지 리퀘스트를 보려면:

1. VS Code의 왼쪽 사이드바에서 **GitLab** ({{< icon name="tanuki" >}})을 선택하세요.
1. 이슈 및 머지 리퀘스트 섹션을 확장합니다.
1. 프로젝트를 선택하여 확장합니다.
1. 다음 옵션 중 하나를 선택하여 항목 목록을 검토합니다:
   - **내게 할당된 이슈**
   - **내가 만든 이슈**
   - **내게 할당된 머지 리퀘스트**
   - **내가 검토 중인 머지 리퀘스트**
   - **내가 만든 머지 리퀘스트**
   - **All project merge requests**
   - 귀사의 [사용자 지정 쿼리](custom_queries.md)
1. 이슈 또는 머지 리퀘스트를 선택하여 새 VS Code 탭에서 엽니다.

## 이슈 및 머지 리퀘스트 검색 {#search-issues-and-merge-requests}

필터링된 검색 또는 [고급 검색](../../integration/advanced_search/elasticsearch.md)을 사용하여 VS Code에서 직접 프로젝트의 이슈 및 머지 리퀘스트를 검색합니다. 필터링된 검색을 사용하면 미리 정의된 토큰을 사용하여 검색 결과를 구체화합니다. 고급 검색은 전체 GitLab 인스턴스에서 더 빠르고 효율적인 검색을 제공합니다.

전제 조건:

- GitLab 프로젝트의 구성원입니다.

프로젝트를 검색하려면:

1. VS Code에서 명령 팔레트를 여세요:
   - macOS의 경우 <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>를 누르세요.
   - Windows 또는 Linux의 경우 <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>를 누르세요.
1. 원하는 검색 유형을 선택합니다:
   - **GitLab: Search Project Issues (Supports Filters)**
   - **GitLab: Search Project Merge Requests (Supports Filters)**
   - **GitLab: Advanced Search (Issues, Merge Requests, Commits, Comments...)**
1. 프롬프트를 따라 검색 값을 입력하고 검색을 구체화합니다.

GitLab이 브라우저 탭에서 결과를 엽니다.

### 검색 결과를 필터링하는 토큰 {#tokens-to-filter-search-results}

필터를 추가하면 대규모 프로젝트의 검색 결과가 더 좋습니다. 확장은 머지 리퀘스트 및 이슈를 필터링하기 위해 이러한 토큰을 지원합니다:

| 토큰     | 예제                                                 | 설명 |
|-----------|---------------------------------------------------------|-------------|
| assignee  | `assignee: sjones`                                      | 할당자의 사용자 이름(`@` 제외). |
| author    | `author: zwei`                                          | 작성자의 사용자 이름(`@` 제외). |
| label     | `label: frontend` 또는 `label:frontend label: Discussion` | 단일 레이블입니다. 두 번 이상 사용 가능하며 동일한 쿼리에서 `labels`과(와) 함께 사용할 수 있습니다. |
| labels    | `labels: frontend, Discussion, performance`             | 쉼표로 구분된 목록의 여러 레이블입니다. 동일한 쿼리에서 `label`과(와) 함께 사용할 수 있습니다. |
| milestone | `milestone: 18.1`                                       | 마일스톤 제목(`%` 제외). |
| scope     | `scope: created-by-me`                                  | 이슈 또는 머지 리퀘스트의 범위입니다. 값: `created-by-me` (기본값), `assigned-to-me` 또는 `all`. |
| title     | `title: discussions refactor`                           | 제목 또는 설명에서 일치할 단어입니다. 구문 주위에 따옴표를 추가하지 마십시오. |

토큰 구문 및 지침:

- 각 토큰 이름 뒤에 콜론(`:`)이 필요합니다(예: `label:`).
  - 콜론 앞의 공백(`label :`)은 유효하지 않으며 구문 분석 오류를 반환합니다.
  - 토큰 이름 뒤의 공백은 선택 사항입니다. `label: frontend` 및 `label:frontend` 모두 유효합니다.
- `label` 및 `labels` 토큰을 여러 번 함께 사용할 수 있습니다. 이러한 쿼리는 동일한 결과를 반환합니다:
  - `labels: frontend discussion label: performance`
  - `label: frontend label: discussion label: performance`
  - `labels: frontend discussion performance` (결과 쿼리 결합)

단일 검색 쿼리에서 여러 토큰을 결합할 수 있습니다. 예를 들어:

```plaintext
title: new merge request widget author: zwei assignee: sjones labels: frontend, performance milestone: 17.5
```

이 검색 쿼리는 다음을 검색합니다:

- 제목: `new merge request widget`
- 작성자: `zwei`
- 할당자: `sjones`
- 레이블: `frontend` 및 `performance`
- 마일스톤: `17.5`

## 머지 리퀘스트 검토 {#review-a-merge-request}

VS Code에서 머지 리퀘스트를 검토하고, 댓글을 달고, 승인하려면:

1. 왼쪽 사이드바에서 **GitLab** ({{< icon name="tanuki" >}})을 선택합니다.
1. 이슈 및 머지 리퀘스트 섹션을 확장한 다음 프로젝트를 선택합니다.
1. 검토할 머지 리퀘스트를 선택합니다.
1. 머지 리퀘스트 번호와 제목 아래에서 **개요**를 선택하여 머지 리퀘스트에 대해 자세히 알아봅니다.
1. 파일의 제안된 변경 사항을 검토하려면 목록에서 파일을 선택하여 VS Code 탭에 표시합니다. GitLab은 탭에 인라인으로 diff 댓글을 표시합니다. 목록에서 삭제된 파일은 빨간색으로 표시됩니다:

   ![이 머지 리퀘스트에서 변경된 파일의 알파벳순 목록(변경 유형 포함).](img/vscode_view_changed_file_v17_6.png)

diff를 사용하려면:

- 논의를 검토하고 생성합니다.
- 이러한 논의를 해결하고 다시 엽니다.
- 개별 댓글을 삭제하고 편집합니다.

## 빠른 작업 사용 {#use-quick-actions}

이슈 및 머지 리퀘스트에서 [GitLab 빠른 작업](../../user/project/quick_actions.md)을 사용하려면:

1. VS Code에서 이슈 또는 머지 리퀘스트를 보는 지침을 따릅니다.
1. 아래로 스크롤하여 댓글 섹션을 찾습니다.
1. 새 댓글에 빠른 작업을 입력한 다음 <kbd>Enter</kbd> 를 누릅니다. 예를 들어, 이슈에 `bug` 레이블을 추가하려면 `/label bug`을(를) 입력합니다.

## 기본 브랜치와 비교 {#compare-with-default-branch}

머지 리퀘스트를 생성하지 않고 브랜치를 프로젝트의 기본 브랜치와 비교하려면:

1. 명령 팔레트를 여세요:
   - macOS의 경우 <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>를 누르세요.
   - Windows 또는 Linux의 경우 <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>를 누르세요.
1. 명령 팔레트에서 **GitLab: Compare Current Branch with Default Branch** 를 검색하고 <kbd>Enter</kbd> 를 누릅니다.

확장이 새 브라우저 탭을 엽니다. 프로젝트의 기본 브랜치에 대한 최신 커밋과 브랜치의 최신 커밋 사이의 diff를 표시합니다.

## GitLab UI에서 현재 파일 열기 {#open-current-file-in-gitlab-ui}

특정 줄이 강조 표시된 GitLab UI에서 현재 GitLab 프로젝트의 파일을 열려면:

1. VS Code에서 원하는 파일을 엽니다.
1. 강조 표시할 줄을 선택합니다.
1. 명령 팔레트를 여세요:
   - macOS의 경우 <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>를 누르세요.
   - Windows 또는 Linux의 경우 <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>를 누르세요.
1. 명령 팔레트에서 **GitLab: Open Active File on GitLab** 를 검색하고 <kbd>Enter</kbd> 를 누릅니다.

## 스니펫 생성 {#create-a-snippet}

코드 및 텍스트의 일부를 저장하고 다른 사용자와 공유하기 위해 [스니펫](../../user/snippets.md)을 생성합니다. 스니펫은 선택 영역 또는 전체 파일일 수 있습니다.

VS Code에서 스니펫을 생성하려면:

1. 스니펫의 콘텐츠를 선택합니다:
   - 전체 파일을 사용하여 스니펫을 생성하려면 파일을 엽니다.
   - 파일 선택을 사용하여 스니펫을 생성하려면 파일을 열고 포함할 줄을 선택합니다.
1. 명령 팔레트를 여세요:
   - macOS의 경우 <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>를 누르세요.
   - Windows 또는 Linux의 경우 <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>를 누르세요.
1. 명령 팔레트에서 **GitLab: Create Snippet** 를 검색하고 <kbd>Enter</kbd> 를 누릅니다.
1. 스니펫의 개인 정보 보호 수준을 선택합니다:
   - **비공개** 스니펫은 프로젝트 구성원에게만 표시됩니다.
   - **공개** 스니펫은 모든 사용자에게 표시됩니다.
1. 스니펫의 범위를 선택합니다:
   - **Snippet from file**은 활성 파일의 전체 콘텐츠를 사용합니다.
   - **Snippet from selection**은 활성 파일에서 선택한 줄을 사용합니다.

GitLab이 새 스니펫의 페이지를 새 브라우저 탭에서 엽니다.

### 패치 파일 생성 {#create-a-patch-file}

머지 리퀘스트를 검토할 때 여러 파일 변경을 제안하려면 스니펫 패치를 생성합니다.

1. 로컬 머신에서 변경 사항을 제안할 브랜치를 체크 아웃합니다.
1. VS Code에서 변경할 모든 파일을 편집합니다. 변경 사항을 커밋하지 마십시오.
1. 명령 팔레트를 여세요:
   - macOS의 경우 <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>를 누르세요.
   - Windows 또는 Linux의 경우 <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>를 누르세요.
1. 명령 팔레트에서 **GitLab: Create Snippet Patch** 를 검색하고 <kbd>Enter</kbd> 를 누릅니다. 이 명령은 `git diff` 명령을 실행하고 프로젝트에 GitLab 스니펫을 생성합니다.
1. **Patch name**을 입력하고 <kbd>Enter</kbd> 를 누릅니다. GitLab은 이 이름을 스니펫 제목으로 사용하고 `.patch`이(가) 추가된 파일 이름으로 변환합니다.
1. 스니펫의 개인 정보 보호 수준을 선택합니다:
   - **비공개** 스니펫은 프로젝트 구성원에게만 표시됩니다.
   - **공개** 스니펫은 모든 사용자에게 표시됩니다.

VS Code이 새 브라우저 탭에서 스니펫 패치를 엽니다. 스니펫 패치의 설명에는 패치를 적용하는 방법에 대한 지침이 포함되어 있습니다.

### 스니펫 삽입 {#insert-a-snippet}

구성원인 프로젝트에서 기존 단일 파일 또는 [다중 파일](../../user/snippets.md#add-or-remove-multiple-files) 스니펫을 삽입하려면:

1. 스니펫을 삽입할 위치에 커서를 놓습니다.
1. 명령 팔레트를 여세요:
   - macOS의 경우 <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>를 누르세요.
   - Windows 또는 Linux의 경우 <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>를 누르세요.
1. **GitLab: Insert Snippet** 를 검색하고 <kbd>Enter</kbd> 를 누릅니다.
1. 스니펫을 포함하는 프로젝트를 선택합니다.
1. 적용할 스니펫을 선택합니다.
1. 다중 파일 스니펫의 경우 적용할 파일을 선택합니다.

## 관련 항목 {#related-topics}

- [VS Code 확장의 프로그램에서 CI/CD 파이프라인](cicd.md)
- [GitLab for VS Code에서 애플리케이션 보안](security_scanning.md)
- [GitLab Duo Agent Platform](../../user/duo_agent_platform/_index.md)
- [GitLab Duo](../../user/gitlab_duo/feature_summary.md)
- [사용자 지정 쿼리](custom_queries.md)
