---
stage: Growth
group: Engagement
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab 키보드 단축키
description: "전역 단축키, 탐색, 빠른 액세스"
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab에는 여러 가지 기능에 액세스할 수 있는 키보드 단축키가 있습니다.

GitLab의 키보드 단축키 목록을 표시하는 창을 열려면 다음 방법 중 하나를 사용합니다:

- <kbd>?</kbd>를 누르세요.
- 애플리케이션의 왼쪽 아래 모서리에서 **도움말**을 선택한 다음 **키보드 단축키**를 선택합니다.

[전역 단축키](#global-shortcuts)는 GitLab의 모든 영역에서 작동하지만, 다른 단축키는 각 섹션에서 설명한 대로 특정 페이지에서만 사용할 수 있습니다.

## 전역 단축키 {#global-shortcuts}

이러한 단축키는 GitLab의 대부분 영역에서 사용 가능합니다:

| 키보드 단축키                  | 설명 |
|------------------------------------|-------------|
| <kbd>?</kbd>                       | 단축키 참조 시트를 표시하거나 숨깁니다. |
| <kbd>Shift</kbd>+<kbd>h</kbd>      | 홈페이지로 이동합니다. |
| <kbd>Shift</kbd>+<kbd>p</kbd>      | **프로젝트** 페이지로 이동합니다. |
| <kbd>Shift</kbd>+<kbd>g</kbd>      | **그룹** 페이지로 이동합니다. |
| <kbd>Shift</kbd>+<kbd>a</kbd>      | **활동** 페이지로 이동합니다. |
| <kbd>Shift</kbd>+<kbd>l</kbd>      | **마일스톤** 페이지로 이동합니다. |
| <kbd>Shift</kbd>+<kbd>s</kbd>      | **스니펫** 페이지로 이동합니다. |
| <kbd>s</kbd> / <kbd>/</kbd>        | 검색 창에 커서를 놓습니다. |
| <kbd>f</kbd>                       | 필터 막대에 포커스를 맞춥니다. |
| <kbd>Shift</kbd>+<kbd>i</kbd>      | **이슈** 페이지로 이동합니다. |
| <kbd>Shift</kbd>+<kbd>m</kbd>      | **머지 리퀘스트** 페이지로 이동합니다. |
| <kbd>Shift</kbd>+<kbd>r</kbd>      | **검토 요청** 페이지로 이동합니다. |
| <kbd>Shift</kbd>+<kbd>t</kbd>      | **할 일 목록** 페이지로 이동합니다. |
| <kbd>p</kbd>, 그 다음 <kbd>b</kbd>    | 성능 표시줄을 표시하거나 숨깁니다. |
| <kbd>Escape</kbd>                  | 툴팁이나 팝오버를 숨깁니다. |
| <kbd>g</kbd>, 그 다음 <kbd>x</kbd>    | [GitLab](https://gitlab.com/)과 [GitLab Next](https://next.gitlab.com/) 간에 전환합니다(GitLab.com만 해당). |
| <kbd>.</kbd>                       | [Web IDE](project/web_ide/_index.md)를 엽니다. |
| <kbd>d</kbd>                       | GitLab Duo Chat을 엽니다. |

또한 텍스트 필드에서 텍스트를 편집할 때(예: 주석, 답글, 이슈 설명 및 머지 리퀘스트 설명) 다음 단축키를 사용할 수 있습니다:

| macOS 단축키                                       | Windows 단축키                                   | 설명 |
|------------------------------------------------------|----------------------------------------------------|-------------|
| <kbd>↑</kbd>                                         | <kbd>↑</kbd>                                       | 마지막 주석을 편집합니다. 스레드 아래의 빈 텍스트 필드에 있어야 하며, 이미 스레드에 최소한 하나의 주석이 있어야 합니다. |
| <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>p</kbd>     | <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>p</kbd>   | **쓰기** 및 **미리보기** 탭이 있는 텍스트 필드에서 텍스트를 편집할 때 Markdown 미리보기를 전환합니다. |
| <kbd>Command</kbd>+<kbd>b</kbd>                      | <kbd>Control</kbd>+<kbd>b</kbd>                    | 선택한 텍스트를 굵게 만듭니다(`**`로 감쌉니다). |
| <kbd>Command</kbd>+<kbd>i</kbd>                      | <kbd>Control</kbd>+<kbd>i</kbd>                    | 선택한 텍스트를 기울임꼴로 만듭니다(`_`로 감쌉니다). |
| <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>x</kbd>     | <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>x</kbd>   | 선택한 텍스트에 취소선을 그으면서 감쌉니다(`~~`). |
| <kbd>Command</kbd>+<kbd>k</kbd>                      | <kbd>Control</kbd>+<kbd>k</kbd>                    | 링크를 추가합니다(선택한 텍스트를 `[]()`로 감쌉니다). |
| <kbd>Command</kbd>+<kbd>[</kbd>                      | <kbd>Control</kbd>+<kbd>[</kbd>                    | 텍스트를 내어씁니다. |
| <kbd>Command</kbd>+<kbd>]</kbd>                      | <kbd>Control</kbd>+<kbd>]</kbd>                    | 텍스트를 들여씁니다. |
| <kbd>Command</kbd>+<kbd>Enter</kbd>                  | <kbd>Control</kbd>+<kbd>Enter</kbd>                | 변경 사항을 제출하거나 저장합니다. |

텍스트 필드 편집용 단축키는 다른 키보드 단축키를 비활성화했을 때도 항상 활성화됩니다.

## 프로젝트 {#project}

이러한 단축키는 프로젝트의 모든 페이지에서 사용할 수 있습니다. 빠르게 입력해야 작동하며, 프로젝트의 다른 페이지로 이동합니다.

| 키보드 단축키           | 설명 |
|-----------------------------|-------------|
| <kbd>g</kbd>+<kbd>o</kbd>   | **프로젝트 개요** 페이지로 이동합니다. |
| <kbd>g</kbd>+<kbd>v</kbd>   | 프로젝트 **활동** 페이지로 이동합니다(**관리** > **활동**). |
| <kbd>g</kbd>+<kbd>r</kbd>   | 프로젝트 **릴리즈** 페이지로 이동합니다(**배포** > **릴리즈**). |
| <kbd>g</kbd>+<kbd>f</kbd>   | [프로젝트 파일](#project-files)로 이동합니다(**코드** > **리포지토리**). |
| <kbd>t</kbd>                | 프로젝트 파일 검색 대화 상자를 엽니다. (**코드** > **리포지토리**, **파일 찾기** 선택). |
| <kbd>g</kbd>+<kbd>c</kbd>   | 프로젝트 **커밋** 페이지로 이동합니다(**코드** > **커밋**). |
| <kbd>g</kbd>+<kbd>n</kbd>   | [**리포지토리 그래프**](#repository-graph) 페이지로 이동합니다(**코드** > **리포지토리 그래프**). |
| <kbd>g</kbd>+<kbd>d</kbd>   | **리포지토리 분석** 페이지의 차트로 이동합니다(**분석** > **리포지토리 분석**). |
| <kbd>g</kbd>+<kbd>i</kbd>   | 프로젝트 **작업 항목** 페이지로 이동합니다(**계획** > **작업 항목**). |
| <kbd>i</kbd>                | **새 이슈** 페이지로 이동합니다(**계획** > **작업 항목**, **새 항목** 선택). |
| <kbd>g</kbd>+<kbd>b</kbd>   | 프로젝트 **이슈 보드** 페이지로 이동합니다(**계획** > **이슈 보드**). |
| <kbd>g</kbd>+<kbd>m</kbd>   | 프로젝트 **머지 리퀘스트** 페이지로 이동합니다(**코드** > **머지 리퀘스트**). |
| <kbd>g</kbd>+<kbd>p</kbd>   | CI/CD **파이프라인** 페이지로 이동합니다(**빌드** > **파이프라인**). |
| <kbd>g</kbd>+<kbd>j</kbd>   | CI/CD **작업** 페이지로 이동합니다(**빌드** > **작업**). |
| <kbd>g</kbd>+<kbd>e</kbd>   | 프로젝트 **환경** 페이지로 이동합니다(**운영** > **환경**). |
| <kbd>g</kbd>+<kbd>k</kbd>   | 프로젝트 **Kubernetes 클러스터** 통합 페이지로 이동합니다(**운영** > **Kubernetes 클러스터**). 이 페이지에 액세스하려면 최소한 [`maintainer` 권한](permissions.md)이 필요합니다. |
| <kbd>g</kbd>+<kbd>s</kbd>   | 프로젝트 **스니펫** 페이지로 이동합니다(**코드** > **스니펫**). |
| <kbd>g</kbd>+<kbd>w</kbd>   | 프로젝트 위키로 이동합니다(**계획** > **위키**, 활성화된 경우). |
| <kbd>.</kbd>                | Web IDE를 엽니다. |

### 이슈 {#issues}

이러한 단축키는 이슈를 볼 때 사용할 수 있습니다:

| 키보드 단축키           | 설명 |
|-----------------------------|-------------|
| <kbd>e</kbd>                | 설명을 편집합니다. |
| <kbd>a</kbd>                | 담당자를 변경합니다. |
| <kbd>m</kbd>                | 마일스톤을 변경합니다. |
| <kbd>l</kbd>                | 레이블을 변경합니다. |
| <kbd>c</kbd>+<kbd>r</kbd>   | 이슈 참조를 복사합니다. |
| <kbd>r</kbd>                | 주석 작성을 시작합니다. 미리 선택한 텍스트가 주석에서 인용됩니다. |
| <kbd>→</kbd>                | 다음 디자인으로 이동합니다. |
| <kbd>←</kbd>                | 이전 디자인으로 이동합니다. |
| <kbd>Escape</kbd>           | 디자인을 닫습니다. |

### 머지 리퀘스트 {#merge-requests}

이러한 단축키는 [머지 리퀘스트](project/merge_requests/_index.md)를 볼 때 사용할 수 있습니다:

| macOS 단축키                    | Windows 단축키                  | 설명 |
|-----------------------------------|-----------------------------------|-------------|
| <kbd>]</kbd> 또는 <kbd>j</kbd>      |                                   | 다음 파일로 이동합니다. |
| <kbd>[</kbd> 또는 <kbd>k</kbd>  |                                   | 이전 파일로 이동합니다. |
| <kbd>Command</kbd>+<kbd>p</kbd>   | <kbd>Control</kbd>+<kbd>p</kbd>   | 파일을 검색한 후 검토를 위해 파일로 이동합니다. |
| <kbd>n</kbd>                      |                                   | 다음 열린 스레드로 이동합니다. |
| <kbd>p</kbd>                      |                                   | 이전 열린 스레드로 이동합니다. |
| <kbd>b</kbd>                      |                                   | 소스 브랜치 이름을 복사합니다. |
| <kbd>c</kbd>+<kbd>r</kbd>         |                                   | 머지 리퀘스트 참조를 복사합니다. |
| <kbd>r</kbd>                      |                                   | 주석 작성을 시작합니다. 미리 선택한 텍스트가 주석에서 인용됩니다. |
| <kbd>Shift</kbd>+<kbd>Command</kbd>+<kbd>Enter</kbd> | <kbd>Shift</kbd>+<kbd>Control</kbd>+<kbd>Enter</kbd> | 즉시 주석을 게시합니다. |
| <kbd>Command</kbd>+<kbd>Enter</kbd> | <kbd>Control</kbd>+<kbd>Enter</kbd> | 검토의 일부로 대기 중인 상태로 주석을 추가합니다. |
| <kbd>c</kbd>                      |                                   | 다음 커밋으로 이동합니다. |
| <kbd>x</kbd>                      |                                   | 이전 커밋으로 이동합니다. |
| <kbd>Shift</kbd>+<kbd>f</kbd>     |                                   | 파일 브라우저를 전환합니다. |
| <kbd>v</kbd>                      |                                   | 파일을 보기 또는 보기 안 함으로 표시합니다. |
| <kbd>;</kbd>                      |                                   | 모든 파일을 펼칩니다. |
| <kbd>Shift</kbd>+<kbd>;</kbd>     |                                   | 모든 파일을 축소합니다. |
| <kbd>Shift</kbd>+<kbd>d</kbd>     |                                   | 인라인과 나란히 나타나는 차이 보기 간에 전환합니다. |

### 프로젝트 파일 {#project-files}

이러한 단축키는 프로젝트의 파일을 검색할 때 사용할 수 있습니다(**코드** > **리포지토리**로 이동):

| 키보드 단축키 | 설명 |
|-------------------|-------------|
| <kbd>↑</kbd>      | 선택 영역을 위로 이동합니다(파일을 검색할 때만 **코드** > **리포지토리**에서 **파일 찾기** 선택). |
| <kbd>↓</kbd>      | 선택 영역을 아래로 이동합니다(파일을 검색할 때만 **코드** > **리포지토리**에서 **파일 찾기** 선택). |
| <kbd>Enter</kbd>  | 선택 영역을 엽니다(파일을 검색할 때만 **코드** > **리포지토리**에서 **파일 찾기** 선택). |
| <kbd>Escape</kbd> | **파일 찾기** 화면으로 돌아갑니다(파일을 검색할 때만 **코드** > **리포지토리**에서 **파일 찾기** 선택). |
| <kbd>y</kbd>      | 파일 고정 링크로 이동합니다(파일을 볼 때만). |
| <kbd>.</kbd>      | Web IDE를 엽니다. |
| <kbd>Shift</kbd>+<kbd>f</kbd> | [파일 트리 브라우저](project/repository/files/file_tree_browser.md)를 표시하거나 숨깁니다. |
| <kbd>f</kbd>      | 검색 패널을 엽니다(파일 트리 브라우저가 열려 있을 때만). |

### 리포지토리 그래프 {#repository-graph}

이러한 단축키는 프로젝트 [리포지토리 그래프](project/repository/_index.md#repository-history-graph) 페이지를 볼 때 사용할 수 있습니다(**코드** > **리포지토리 그래프**로 이동):

| 키보드 단축키                                                  | 설명 |
|--------------------------------------------------------------------|-------------|
| <kbd>←</kbd> 또는 <kbd>h</kbd>                                       | 왼쪽으로 스크롤합니다. |
| <kbd>→</kbd> 또는 <kbd>l</kbd>                                       | 오른쪽으로 스크롤합니다. |
| <kbd>↑</kbd> 또는 <kbd>k</kbd>                                       | 위로 스크롤합니다. |
| <kbd>↓</kbd> 또는 <kbd>j</kbd>                                       | 아래로 스크롤합니다. |
| <kbd>Shift</kbd>+<kbd>↑</kbd> 또는 <kbd>Shift</kbd>+<kbd>k</kbd>     | 맨 위로 스크롤합니다. |
| <kbd>Shift</kbd>+<kbd>↓</kbd> 또는 <kbd>Shift</kbd>+<kbd>j</kbd>     | 맨 아래로 스크롤합니다. |

### 인시던트 {#incidents}

이러한 단축키는 인시던트를 볼 때 사용할 수 있습니다:

| 키보드 단축키             | 설명 |
|-------------------------------|-------------|
| <kbd>c</kbd>+<kbd>r</kbd>     | 인시던트 참조를 복사합니다. |

### 위키 페이지 {#wiki-pages}

이 단축키는 [위키 페이지](project/wiki/_index.md)를 볼 때 사용할 수 있습니다:

| 키보드 단축키 | 설명     |
|-------------------|-----------------|
| <kbd>e</kbd>      | 위키 페이지를 편집합니다. |

### 리치 텍스트 편집기 {#rich-text-editor}

이러한 단축키는 [리치 텍스트 에디터](rich_text_editor.md)로 파일을 편집할 때 사용할 수 있습니다:

| macOS 단축키 | Windows 단축키 | 설명 |
|----------------|------------------|-------------|
| <kbd>Command</kbd>+<kbd>c</kbd> | <kbd>Control</kbd>+<kbd>c</kbd> | 복사 |
| <kbd>Command</kbd>+<kbd>x</kbd> | <kbd>Control</kbd>+<kbd>x</kbd> | 잘라내기 |
| <kbd>Command</kbd>+<kbd>v</kbd> | <kbd>Control</kbd>+<kbd>v</kbd> | 붙여넣기 |
| <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>v</kbd> | <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>v</kbd> | 서식 없이 붙여넣기 |
| <kbd>Command</kbd>+<kbd>Option</kbd>+<kbd>v</kbd> | <kbd>Control</kbd>+<kbd>Alt</kbd>+<kbd>v</kbd> | 표 셀에서 복사한 표를 중첩 표로 셀 내부에 붙여넣습니다. |
| <kbd>Command</kbd>+<kbd>z</kbd> | <kbd>Control</kbd>+<kbd>z</kbd> | 실행 취소 |
| <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>v</kbd> | <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>v</kbd> | 다시 실행 |
| <kbd>Shift</kbd>+<kbd>Enter</kbd> | <kbd>Shift</kbd>+<kbd>Enter</kbd> | 줄 바꿈을 추가합니다. |

#### 서식 {#formatting}

| macOS 단축키 | Windows/Linux 단축키 | 설명 |
|----------------|------------------------|-------------|
| <kbd>Command</kbd>+<kbd>b</kbd> | <kbd>Control</kbd>+<kbd>b</kbd>  | 굵게 |
| <kbd>Command</kbd>+<kbd>i</kbd> | <kbd>Control</kbd>+<kbd>i</kbd>   | 기울임꼴 |
| <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>x</kbd>  | <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>x</kbd>   | 취소선 |
| <kbd>Command</kbd>+<kbd>k</kbd> | <kbd>Control</kbd>+<kbd>k</kbd>   | 링크 삽입 |
| <kbd>Command</kbd>+<kbd>Option</kbd>+<kbd>0</kbd> | <kbd>Control</kbd>+<kbd>Alt</kbd>+<kbd>0</kbd> | 일반 텍스트 스타일 적용 |
| <kbd>Command</kbd>+<kbd>Option</kbd>+<kbd>1</kbd> | <kbd>Control</kbd>+<kbd>Alt</kbd>+<kbd>1</kbd> | 제목 스타일 1 적용 |
| <kbd>Command</kbd>+<kbd>Option</kbd>+<kbd>2</kbd> | <kbd>Control</kbd>+<kbd>Alt</kbd>+<kbd>2</kbd> | 제목 스타일 2 적용 |
| <kbd>Command</kbd>+<kbd>Option</kbd>+<kbd>3</kbd> | <kbd>Control</kbd>+<kbd>Alt</kbd>+<kbd>3</kbd> | 제목 스타일 3 적용 |
| <kbd>Command</kbd>+<kbd>Option</kbd>+<kbd>4</kbd> | <kbd>Control</kbd>+<kbd>Alt</kbd>+<kbd>4</kbd> | 제목 스타일 4 적용 |
| <kbd>Command</kbd>+<kbd>Option</kbd>+<kbd>5</kbd> | <kbd>Control</kbd>+<kbd>Alt</kbd>+<kbd>5</kbd> | 제목 스타일 5 적용 |
| <kbd>Command</kbd>+<kbd>Option</kbd>+<kbd>6</kbd> | <kbd>Control</kbd>+<kbd>Alt</kbd>+<kbd>6</kbd> | 제목 스타일 6 적용 |
| <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>7</kbd>  | <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>7</kbd> | 번호 매기기 목록 |
| <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>8</kbd>  | <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>8</kbd> | 글머리 목록 |
| <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>9</kbd>  | <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>9</kbd> | 작업 목록 |
| <kbd>Command</kbd>+<kbd>Option</kbd>+<kbd>c</kbd> | <kbd>Control</kbd>+<kbd>Alt</kbd>+<kbd>c</kbd> | 코드 블록 |
| <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>h</kbd>  | <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>h</kbd> | 강조 |
| <kbd>Command</kbd>+<kbd>,</kbd> | <kbd>Control</kbd>+<kbd>,</kbd> | 아래첨자 |
| <kbd>Command</kbd>+<kbd>.</kbd> | <kbd>Control</kbd>+<kbd>.</kbd> | 위첨자 |
| <kbd>Tab</kbd> | <kbd>Tab</kbd> | 목록 들여쓰기 |
| <kbd>Shift</kbd>+<kbd>Tab</kbd> | <kbd>Shift</kbd>+<kbd>Tab</kbd> | 목록 내어쓰기 |

#### 텍스트 선택 {#text-selection}

| macOS 단축키                    | Windows 단축키                  | 설명 |
|-----------------------------------|-----------------------------------|-------------|
| <kbd>Command</kbd>+<kbd>a</kbd>   | <kbd>Control</kbd>+<kbd>a</kbd>   | 모두 선택 |
| <kbd>Shift</kbd>+<kbd>←</kbd>     | <kbd>Shift</kbd>+<kbd>←</kbd>     | 선택 영역을 왼쪽으로 한 문자씩 확장합니다. |
| <kbd>Shift</kbd>+<kbd>→</kbd>     | <kbd>Shift</kbd>+<kbd>→</kbd>     | 선택 영역을 오른쪽으로 한 문자씩 확장합니다. |
| <kbd>Shift</kbd>+<kbd>↑</kbd>     | <kbd>Shift</kbd>+<kbd>↑</kbd>     | 선택 영역을 위로 한 줄 확장합니다. |
| <kbd>Shift</kbd>+<kbd>↓</kbd>     | <kbd>Shift</kbd>+<kbd>↓</kbd>     | 선택 영역을 아래로 한 줄 확장합니다. |
| <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>↑</kbd> | <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>↑</kbd> | 선택 영역을 문서의 시작 부분까지 확장합니다. |
| <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>↓</kbd> | <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>↓</kbd> | 선택 영역을 문서의 끝까지 확장합니다. |

### GitLab Duo Chat {#gitlab-duo-chat}

{{< details >}}

- 티어:  Premium, Ultimate
- 추가 기능: GitLab Duo Core, Pro 또는 Enterprise, GitLab Duo와 Amazon Q
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 18.7에 도입되었습니다.

{{< /history >}}

다음 단축키는 지원되는 IDE에서 [GitLab Duo Non-Agentic Chat](gitlab_duo_chat/_index.md)을 사용할 때 사용할 수 있습니다.

| macOS 단축키                    | Windows 단축키                  | 설명 | VS Code | JetBrains IDE | Visual Studio |
|-----------------------------------|-----------------------------------|-------------|---|---|---|
| <kbd>Option</kbd>+<kbd>d</kbd>    | <kbd>Alt</kbd>+<kbd>d</kbd> | Chat을 열거나 닫거나 이미 열려 있는 경우 Chat에 포커스를 전환합니다.| {{< yes >}} | {{< yes >}} | {{< no >}} |
| <kbd>Option</kbd>+<kbd>n</kbd>    | <kbd>Alt</kbd>+<kbd>n</kbd> | Chat에서 새로운 대화를 시작합니다. | {{< yes >}} | {{< no >}} | {{< no >}} |
| <kbd>Option</kbd>+<kbd>r</kbd>    | <kbd>Alt</kbd>+<kbd>r</kbd> | [코드 리팩터링](gitlab_duo_chat/examples.md#refactor-code-in-the-ide)| {{< yes >}} | {{< no >}} | {{< no >}} |
| <kbd>Option</kbd>+<kbd>t</kbd>    | <kbd>Alt</kbd>+<kbd>t</kbd> | [테스트 작성](gitlab_duo_chat/examples.md#write-tests-in-the-ide)| {{< yes >}} | {{< no >}} | {{< no >}} |

IDE에서 이러한 단축키를 사용자 지정할 수 있습니다.

#### VS Code에서 사용자 지정 {#customize-in-vs-code}

1. VS Code에서 **설정** > **키보드 단축키**로 이동합니다.
1. 검색 텍스트 상자에 <kbd>GitLab</kbd>을 입력하여 모든 GitLab 단축키를 찾습니다.
1. 사용자 지정하려는 단축키의 경우 **키 바인딩 변경(Enter)** {{< icon name="pencil" >}}을 선택합니다.
1. 새 단축키 조합을 누르고 <kbd>Enter</kbd>를 누릅니다.

#### JetBrains IDE에서 사용자 지정 {#customize-in-jetbrains-ides}

1. JetBrains IDE에서 **설정** > **키맵**으로 이동하거나 IDE의 동등한 키보드 매핑 설정으로 이동합니다.
1. 모든 GitLab 단축키를 찾습니다.
1. 적절한 단축키를 사용자 지정하고 저장합니다.

#### Visual Studio에서 사용자 지정 {#customize-in-visual-studio}

1. Visual Studio에서 **도구** > **옵션**으로 이동합니다.
1. **환경** > **키보드**로 이동합니다.
1. **포함된 명령 표시:** 텍스트 상자에 <kbd>GitLab</kbd>을 입력하여 모든 GitLab 단축키를 찾습니다.
1. **단축키 입력** 아래에서 현재 단축키 조합을 선택합니다.
1. 새 단축키 조합을 누르고 **할당**을 선택합니다.
1. **확인**을 선택합니다.

## 에픽 {#epics}

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이러한 단축키는 [에픽](group/epics/_index.md)을 볼 때 사용할 수 있습니다:

| 키보드 단축키            | 설명       |
|------------------------------|-------------------|
| <kbd>e</kbd>                 | 설명을 편집합니다. |
| <kbd>l</kbd>                 | 레이블을 변경합니다.     |
| <kbd>c</kbd>+<kbd>r</kbd>    | 에픽 참조를 복사합니다. |

## 키보드 단축키 비활성화 {#disable-keyboard-shortcuts}

키보드 단축키를 비활성화하려면:

1. 오른쪽 위 모서리에서 아바타를 선택합니다.
1. **환경설정**을 선택합니다.
1. **행동** 섹션에서 **키보드 단축키 활성화** 확인란을 선택 해제합니다.
1. **변경 사항 저장**을 선택합니다.

## 키보드 단축키 활성화 {#enable-keyboard-shortcuts}

키보드 단축키를 활성화하려면:

1. 오른쪽 위 모서리에서 아바타를 선택합니다.
1. **환경설정**을 선택합니다.
1. **행동** 섹션에서 **키보드 단축키 활성화** 확인란을 선택합니다.
1. **변경 사항 저장**을 선택합니다.

## 문제 해결 {#troubleshooting}

### Linux 단축키 {#linux-shortcuts}

Linux 사용자는 운영 체제 또는 브라우저에 의해 재정의되는 GitLab 키보드 단축키를 만날 수 있습니다.
