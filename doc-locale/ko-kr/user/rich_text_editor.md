---
stage: Plan
group: Planner Intelligence
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 리치 텍스트 편집기
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- 리치 텍스트 편집기는 GitLab 18.2에서 [새 사용자를 위한 기본 편집기로 설정](https://gitlab.com/gitlab-org/gitlab/-/issues/536611)되었습니다.

{{< /history >}}

리치 텍스트 편집기는 GitLab의 새 사용자를 위한 기본 텍스트 편집기입니다.

리치 텍스트 편집기는 다음에서 사용할 수 있습니다:

- [위키](project/wiki/_index.md)
- 이슈
- 에픽
- 머지 리퀘스트
- [디자인](project/issues/design_management.md)

편집기의 기능은 다음과 같습니다:

- 굵게, 기울임, 블록 인용, 제목 및 인라인 코드를 포함한 텍스트 형식을 지정합니다.
- 정렬된 목록, 정렬되지 않은 목록 및 체크리스트의 형식을 지정합니다.
- 링크, 첨부 파일, 이미지, 동영상 및 오디오를 삽입합니다.
- 테이블 구조를 생성하고 편집합니다.
- 구문 강조 표시가 있는 코드 블록을 삽입하고 형식을 지정합니다.
- 머메이드, PlantUML 및 Kroki 다이어그램을 실시간으로 미리 봅니다.

GitLab 전체에서 리치 텍스트 편집기를 더 많은 위치에 추가하는 작업을 추적하려면 [에픽 7098](https://gitlab.com/groups/gitlab-org/-/epics/7098)을 참조하세요.

## 리치 텍스트 편집기로 전환 {#switch-to-the-rich-text-editor}

리치 텍스트 편집기를 사용하여 설명, 위키 페이지를 편집하고 댓글을 추가합니다.

리치 텍스트 편집기로 전환하려면: 텍스트 상자의 왼쪽 하단 모서리에서 **리치 텍스트 편집으로 전환**을 선택합니다.

## 일반 텍스트 편집기로 전환 {#switch-to-the-plain-text-editor}

텍스트 상자에 마크다운 소스를 입력하려면 일반 텍스트 편집기를 사용해야 합니다.

일반 텍스트 편집기로 전환하려면: 텍스트 상자의 왼쪽 하단 모서리에서 **일반 텍스트 편집으로 전환**을 선택합니다.

![리치 텍스트 편집 모드의 텍스트 에디터로 왼쪽 아래에 "일반 텍스트 편집으로 전환" 텍스트 상자가 표시됨](img/rich_text_editor_01_v16_2.png)

## GitLab Flavored Markdown과의 호환성 {#compatibility-with-gitlab-flavored-markdown}

리치 텍스트 에디터는 [GitLab Flavored Markdown](markdown.md)과(와) 완벽하게 호환됩니다. 이는 데이터를 손실하지 않고 일반 텍스트와 리치 텍스트 모드 간에 전환할 수 있다는 의미입니다.

### 입력 규칙 {#input-rules}

리치 텍스트 에디터는 Markdown을 입력하는 것처럼 리치 콘텐츠로 작업할 수 있는 입력 규칙도 지원합니다.

지원되는 입력 규칙:

| 입력 규칙 구문                                         | 삽입된 콘텐츠     |
| --------------------------------------------------------- | -------------------- |
| `# Heading 1` ~ `###### Heading 6`                  | 제목 1 ~ 6 |
| `**bold**` 또는 `__bold__`                                  | 굵은 텍스트            |
| `_italics_` 또는 `*italics*`                                | 기울임꼴 텍스트      |
| `~~strike~~`                                              | 취소선        |
| `[link](https://example.com)`                             | 하이퍼링크            |
| `code`                                                    | 인라인 코드          |
| ` ```rb ` + <kbd>Enter</kbd> <br> ` ```js ` + <kbd>Enter</kbd> | 코드 블록      |
| `* List item`, 또는<br> `- List item`, 또는<br> `+ List item` | 순서 없는 목록       |
| `1. List item`                                            | 번호 매기기 목록        |
| `<details>`                                               | 접기 가능한 섹션  |

## 표 {#tables}

원본 Markdown과 달리 리치 텍스트 에디터를 사용하여 블록 콘텐츠 단락, 목록 항목, 다이어그램(또는 다른 테이블까지!)을 테이블 셀에 삽입할 수 있습니다.

### 테이블 삽입 {#insert-a-table}

테이블을 삽입하려면:

1. **테이블 삽입** {{< icon name="table" >}}을(를) 선택합니다.
1. 드롭다운 목록에서 새 테이블의 크기를 선택합니다.

![3행과 3열이 있는 테이블 크기 선택기](img/rich_text_editor_02_v16_2.png)

### 테이블 편집 {#edit-a-table}

테이블 셀 내에서 메뉴를 사용하여 행이나 열을 삽입하거나 삭제할 수 있습니다.

메뉴를 열려면: 셀의 오른쪽 위 모서리에서 chevron {{< icon name="chevron-down" >}}을(를) 선택합니다.

![테이블 작업을 표시하는 활성 chevron 메뉴](img/rich_text_editor_03_v16_2.png)

### 여러 셀에 대한 작업 {#operations-on-multiple-cells}

여러 셀을 선택하고 병합하거나 분할합니다.

선택한 셀을 하나로 병합하려면:

1. 여러 셀을 선택하고 하나를 선택한 다음 커서를 끕니다.
1. 셀의 오른쪽 위 모서리에서 chevron {{< icon name="chevron-down" >}} > **셀 N개 병합**을(를) 선택합니다.

병합된 셀을 분할하려면: 셀의 오른쪽 위 모서리에서 chevron {{< icon name="chevron-down" >}} > **셀 분할**을(를) 선택합니다.

### 테이블 셀에 붙여넣기 {#paste-into-a-table-cell}

{{< history >}}

- 테이블 메뉴 붙여넣기 작업이 GitLab 19.4에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/work_items/627112)되었습니다.
- 테이블 셀에 붙여넣기 위한 키보드 단축키가 GitLab 19.4에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/work_items/627699)되었습니다.

{{< /history >}}

<kbd>Ctrl</kbd>+<kbd>V</kbd> (또는 macOS에서 <kbd>Command</kbd>+<kbd>V</kbd>)를 누르면 GitLab은 기본적으로 복사된 셀을 테이블에 병합합니다.

콘텐츠 붙여넣기 방법을 선택하려면:

1. 대상 셀의 오른쪽 위 모서리에서 chevron {{< icon name="chevron-down" >}}을(를) 선택합니다.
1. 다음 옵션 중 하나를 선택합니다.
   - **셀에 붙여넣기**: 복사된 콘텐츠를 커서에 삽입합니다. 복사된 테이블은 셀 내에 중첩된 테이블이 됩니다.
   - **테이블에 붙여넣고 병합**: 복사된 셀을 테이블 전체에 분산시킵니다(기본 동작).

각 옵션은 레이블 옆에 키보드 단축키도 표시합니다. 메뉴를 열지 않고 복사된 테이블을 중첩 테이블로 붙여넣으려면 테이블 셀에 커서를 놓습니다. 그런 다음 <kbd>Ctrl</kbd>+<kbd>Alt</kbd>+<kbd>V</kbd> (또는 macOS에서 <kbd>Command</kbd>+<kbd>Option</kbd>+<kbd>V</kbd>)를 누릅니다.

처음으로 옵션을 사용할 때 브라우저가 클립보드 읽기 권한을 요청할 수 있습니다.

> [!note]
> GitLab Self-Managed의 경우 인스턴스가 일반 HTTP를 통해 제공되면 붙여넣기 옵션과 키보드 단축키를 사용할 수 없습니다. 이러한 기능은 클립보드에 대한 브라우저 액세스가 필요하며 브라우저는 HTTPS를 통해 제공되거나 `localhost`에서 제공되는 페이지에서만 액세스를 허용합니다.

## 다이어그램 삽입 {#insert-diagrams}

[Mermaid](https://mermaidjs.github.io/) 및 [PlantUML](https://plantuml.com/) 다이어그램을 삽입하고 다이어그램 코드를 입력하면서 실시간으로 미리 봅니다.

다이어그램을 삽입하려면:

1. 텍스트 상자의 상단 모음에서 {{< icon name="plus" >}} **추가 옵션**을(를) 선택한 다음 **머메이드 다이어그램** 또는 **PlantUML 다이어그램**을(를) 선택합니다.
1. 다이어그램의 코드를 입력합니다. 다이어그램 미리 보기가 텍스트 상자에 표시됩니다.

![LR 구문을 사용하여 왼쪽에서 오른쪽으로 흐름도를 만드는 리치 텍스트 에디터의 머메이드 다이어그램 미리 보기](img/rich_text_editor_04_v16_2.png)

## 관련 항목 {#related-topics}

- [기본 텍스트 에디터 설정](profile/preferences.md#set-the-default-text-editor)
- [키보드 단축키](shortcuts.md#rich-text-editor) \- 리치 텍스트 에디터
- [GitLab Flavored Markdown](markdown.md)
