---
stage: Create
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: 머지 리퀘스트에서 제안된 변경 사항을 읽는 방법을 이해합니다.
title: 머지 리퀘스트의 변경 사항
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

[머지 리퀘스트](_index.md)는 리포지토리의 소스 브랜치에서 파일에 대한 변경 사항 세트를 제안합니다. GitLab은 이러한 변경 사항을 현재 상태와 제안된 변경 사항 간의 _diff_(차이)로 표시합니다. 기본적으로 diff는 제안된 변경 사항(소스 브랜치)을 대상 브랜치와 비교합니다. 기본적으로 GitLab은 파일의 변경된 부분만 표시합니다.

이 예제는 텍스트 파일의 변경 사항을 보여줍니다. 기본 구문 강조 테마에서:

- _현재_ 버전은 빨간색으로 표시되며, 줄 앞에 빼기 기호(`-`)가 있습니다.
- _제안된_ 버전은 녹색으로 표시되며 줄 앞에 더하기 기호(`+`)가 있습니다.

![추가되고 제거된 코드 줄을 표시하는 머지 리퀘스트 diff입니다.](img/mr_diff_example_v16_9.png)

diff의 각 파일에 대한 헤더에 다음이 포함됩니다:

- **파일 내용 숨기기**({{< icon name="chevron-down" >}}) - 이 파일에 대한 모든 변경 사항을 숨깁니다.
- **경로**:  이 파일의 전체 경로입니다. 이 경로를 복사하려면 **파일 경로 복사**({{< icon name="copy-to-clipboard" >}})를 선택합니다.
- **Lines changed**:  이 파일에서 추가되고 제거된 줄의 수입니다. 형식은 `+2 -2`입니다.
- **조회됨**:  이 확인란을 선택하여 [파일을 조회됨으로 표시](#mark-files-as-viewed)하면 파일이 변경될 때까지 유지됩니다.
- **이 파일에 댓글 달기**({{< icon name="comment" >}}) - 파일의 특정 줄에 핀을 지정하지 않고 파일에 대한 일반 댓글을 남깁니다.
- **옵션**:  ({{< icon name="ellipsis_v" >}})를 선택하여 더 많은 파일 보기 옵션을 표시합니다.

diff는 파일 왼쪽의 여백에 탐색 및 댓글 보조 기능도 포함합니다:

- 더 많은 컨텍스트 표시:  **이전 20라인**({{< icon name="expand-up" >}})을 선택하여 이전 20개의 변경되지 않은 줄을 표시하거나, **다음 20라인**({{< icon name="expand-down" >}})을 선택하여 다음 20개의 변경되지 않은 줄을 표시합니다.
- 줄 번호는 두 열에 표시됩니다. 이전 줄 번호는 왼쪽에 표시되고 제안된 줄 번호는 오른쪽에 표시됩니다. 줄과 상호 작용하려면:
  - [댓글 옵션](#add-a-comment-to-a-merge-request-file)을 표시하려면 줄 번호 위에 마우스를 놓습니다.
  - 줄에 링크를 복사하려면 <kbd>Command</kbd>를 누르고 줄 번호를 선택(또는 마우스 오른쪽 버튼)한 다음 **Copy link address**를 선택합니다.
  - 줄을 강조하려면 줄 번호를 선택합니다.

## 변경된 파일 목록 표시 {#show-a-list-of-changed-files}

파일 브라우저를 사용하여 머지 리퀘스트에서 변경된 파일 목록을 봅니다:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾으세요.
1. 왼쪽 사이드바에서 **코드** > **머지 리퀘스트**를 선택하고 머지 리퀘스트를 찾습니다.
1. 머지 리퀘스트 제목 아래에서 **변경사항**을 선택합니다.
1. **파일 브라우저 보기**({{< icon name="file-tree" >}})를 선택하거나 <kbd>F</kbd>를 눌러 파일 트리를 표시합니다.
   - 중첩을 표시하는 트리 보기의 경우 **트리 보기**({{< icon name="file-tree" >}})를 선택합니다.
   - 중첩이 없는 파일 목록의 경우 **목록 보기**({{< icon name="list-bulleted" >}})를 선택합니다.

## 머지 리퀘스트의 모든 변경 사항 표시 {#show-all-changes-in-a-merge-request}

머지 리퀘스트에 포함된 변경 사항의 diff를 보려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾으세요.
1. 왼쪽 사이드바에서 **코드** > **머지 리퀘스트**를 선택하고 머지 리퀘스트를 찾습니다.
1. 머지 리퀘스트 제목 아래에서 **변경사항**을 선택합니다.
1. 머지 리퀘스트가 많은 파일을 변경하는 경우 특정 파일로 직접 이동할 수 있습니다:
   1. **파일 브라우저 보기**({{< icon name="file-tree" >}})를 선택하거나 <kbd>F</kbd>를 눌러 파일 트리를 표시합니다.
   1. 보려는 파일을 선택합니다.
   1. 파일 브라우저를 숨기려면 **파일 브라우저 보기**를 선택하거나 <kbd>F</kbd>를 다시 누릅니다.

GitLab은 성능을 개선하기 위해 많은 변경 사항이 있는 파일을 축소하고 메시지를 표시합니다:  **일부 변경 사항이 표시되지 않습니다.** 해당 파일의 변경 사항을 보려면 **파일 펼침**을 선택합니다.

### 연결된 파일을 먼저 표시 {#show-a-linked-file-first}

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab.com

{{< /details >}}

{{< history >}}

- GitLab 16.9에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/387246) 되었으며 [기능 플래그](../../../administration/feature_flags/_index.md) `pinned_file`로 제공됩니다. 기본적으로 비활성화됨.
- GitLab 17.4에서 [일반 공개](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/162503)되었습니다. 기능 플래그 `pinned_file`이(가) 제거되었습니다.

{{< /history >}}

머지 리퀘스트 링크를 팀 구성원과 공유할 때 변경된 파일 목록에서 특정 파일을 먼저 표시하고 싶을 수 있습니다. 원하는 파일을 먼저 표시하는 머지 리퀘스트 링크를 복사하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾으세요.
1. 왼쪽 사이드바에서 **코드** > **머지 리퀘스트**를 선택하고 머지 리퀘스트를 찾습니다.
1. 머지 리퀘스트 제목 아래에서 **변경사항**을 선택합니다.
1. 먼저 표시할 파일을 찾습니다. 파일 이름을 마우스 오른쪽 버튼으로 클릭하여 해당 링크를 복사합니다.
1. 해당 링크를 방문하면 선택한 파일이 목록 맨 위에 표시됩니다. 파일 브라우저는 파일 이름 옆에 링크 아이콘({{< icon name="link" >}})을 표시합니다:

   ![맨 위에 선택한 YAML 파일이 있는 머지 리퀘스트 파일 목록입니다.](img/linked_file_v17_4.png)

## 생성된 파일 축소 {#collapse-generated-files}

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 16.8에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/140180) 되었으며 [기능 플래그](../../../administration/feature_flags/_index.md) `collapse_generated_diff_files`로 제공됩니다. 기본적으로 비활성화됨.
- GitLab 16.10에서 [GitLab.com 및 GitLab Self-Managed에서 활성화](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/145100)되었습니다.
- `generated_file`이(가) GitLab 16.11에서 [일반 공개](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/148478)되었습니다. 기능 플래그 `collapse_generated_diff_files`이(가) 제거되었습니다.

{{< /history >}}

코드 검토를 수행하는 데 필요한 파일에 집중하도록 도와주기 위해 GitLab은 여러 일반적인 유형의 생성된 파일을 축소합니다. GitLab은 이러한 파일을 기본적으로 축소합니다. 왜냐하면 코드 검토가 거의 필요하지 않기 때문입니다:

1. `.nib`, `.xcworkspacedata` 또는 `.xcurserstate` 확장자를 가진 파일입니다.
1. `package-lock.json` 또는 `Gopkg.lock`과 같은 패키지 잠금 파일입니다.
1. `node_modules` 폴더의 파일입니다.
1. 축소된 `js` 또는 `css` 파일입니다.
1. 소스 맵 참조 파일입니다.
1. 생성된 Go 파일(프로토콜 버퍼 컴파일러가 생성한 파일 포함)입니다.

파일 또는 경로를 생성됨으로 표시하려면 [`.gitattributes` 파일](../repository/files/git_attributes.md)에서 `gitlab-generated` 특성을 설정합니다.

### 축소된 파일 보기 {#view-a-collapsed-file}

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾으세요.
1. 왼쪽 사이드바에서 **코드** > **머지 리퀘스트**를 선택하고 머지 리퀘스트를 찾습니다.
1. 머지 리퀘스트 제목 아래에서 **변경사항**을 선택합니다.
1. 보려는 파일을 찾아 **파일 펼침**을 선택합니다.

### 파일 유형에 대한 축소 동작 구성 {#configure-collapse-behavior-for-a-file-type}

파일 유형에 대한 기본 축소 동작을 변경하려면:

1. `.gitattributes` 파일이 프로젝트의 루트 디렉토리에 없으면 이 이름의 빈 파일을 만듭니다.
1. 수정하려는 각 파일 유형에 대해 `.gitattributes` 파일에 줄을 추가하여 파일 확장자와 원하는 동작을 선언합니다:

   ```conf
   # Collapse all files with a .txt extension
   *.txt gitlab-generated

   # Collapse all files within the docs directory
   docs/** gitlab-generated

   # Do not collapse package-lock.json
   package-lock.json -gitlab-generated
   ```

1. 변경 사항을 기본 브랜치에 커밋, 푸시 및 병합합니다.

변경 사항이 [기본 브랜치](../repository/branches/default.md)에 병합된 후 프로젝트의 이러한 유형의 모든 파일은 머지 리퀘스트에서 이 동작을 사용합니다.

GitLab이 생성된 파일을 감지하는 방법에 대한 기술적 세부 정보는 [`go-enry`](https://github.com/go-enry/go-enry/blob/master/data/generated.go) 리포지토리를 참조하세요.

## 한 번에 하나의 파일 표시 {#show-one-file-at-a-time}

더 큰 머지 리퀘스트의 경우 한 번에 하나의 파일을 검토할 수 있습니다. 이 설정을 사용자 기본 설정에서 또는 머지 리퀘스트를 검토할 때 변경할 수 있습니다. 머지 리퀘스트에서 이 설정을 변경하면 사용자 설정도 업데이트됩니다.

{{< tabs >}}

{{< tab title="머지 리퀘스트" >}}

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾으세요.
1. 왼쪽 사이드바에서 **코드** > **머지 리퀘스트**를 선택하고 머지 리퀘스트를 찾습니다.
1. 머지 리퀘스트 제목 아래에서 **변경사항**을 선택합니다.
1. **환경설정**({{< icon name="preferences" >}})을 선택합니다.
1. **한 번에 하나의 파일 표시**를 선택하거나 선택을 취소합니다.

{{< /tab >}}

{{< tab title="사용자 기본 설정" >}}

1. 오른쪽 위 모서리에서 아바타를 선택합니다.
1. **환경설정**을 선택합니다.
1. **행동** 섹션까지 스크롤하고 **머지 리퀘스트의 변경 탭에서 한 번에 하나의 파일 표시** 확인란을 선택합니다.
1. **변경사항 저장**을 선택합니다.

{{< /tab >}}

{{< /tabs >}}

이 설정이 활성화되었을 때 보려는 다른 파일을 선택하려면 다음 중 하나를 수행합니다:

- 파일 끝까지 스크롤하고 **이전** 또는 **다음**을 선택합니다.
- [키보드 단축키가 활성화](../../shortcuts.md#enable-keyboard-shortcuts)되어 있으면 <kbd>[</kbd>, <kbd>]</kbd>, <kbd>k</kbd> 또는 <kbd>j</kbd>를 누릅니다.
- **파일 브라우저 보기**({{< icon name="file-tree" >}})를 선택하고 보려는 다른 파일을 선택합니다.

## 변경 사항 비교 {#compare-changes}

머지 리퀘스트의 변경 사항을 다음 중 하나로 볼 수 있습니다:

- 인라인입니다. 변경 사항을 세로로 표시합니다. 줄의 이전 버전이 먼저 표시되고 새 버전이 바로 아래에 표시됩니다. 인라인 모드는 단일 줄 변경에 더 좋습니다.
- 나란히입니다. 줄의 이전 및 새 버전을 별도 열에 표시합니다. 나란히 모드는 많은 수의 순차적 줄에 영향을 주는 변경에 더 좋습니다.

머지 리퀘스트에서 변경된 줄을 표시하는 방법을 변경하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾으세요.
1. 왼쪽 사이드바에서 **코드** > **머지 리퀘스트**를 선택하고 머지 리퀘스트를 찾습니다.
1. 제목 아래에서 **변경사항**을 선택합니다.
1. **환경설정**({{< icon name="preferences" >}})을 선택합니다. **나란히** 또는 **인라인**을 선택합니다. 이 예제는 GitLab이 인라인 및 나란히 모드에서 동일한 변경을 렌더링하는 방법을 보여줍니다:

   {{< tabs >}}

   {{< tab title="인라인 변경" >}}

   ![인라인 모드에서 머지 리퀘스트 코드 변경입니다.](img/changes-inline_v17_10.png)

   {{< /tab >}}

   {{< tab title="나란히 변경" >}}

   ![나란히 모드에서 머지 리퀘스트 코드 변경입니다.](img/changes-sidebyside_v17_10.png)

   {{< /tab >}}

   {{< /tabs >}}

## 빠른 Diff {#rapid-diffs}

{{< details >}}

- 상태:  베타

{{< /details >}}

{{< history >}}

- GitLab 18.0에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/590833) 되었으며 [기능 플래그](../../../administration/feature_flags/_index.md) `rapid_diffs_on_mr_show`로 제공됩니다. 기본적으로 비활성화됨.
- GitLab 19.0에서 [GitLab.com 및 GitLab Self-Managed에서 활성화](https://gitlab.com/gitlab-org/gitlab/-/issues/539581)되었습니다.

{{< /history >}}

> [!flag]
> 이 기능의 가용성은 기능 플래그로 제어됩니다. 자세한 내용은 기록을 참조하세요.

빠른 Diff는 머지 리퀘스트에서 코드 변경을 더 빠르게 로드하고 상호 작용하는 방법입니다. diff를 검토할 때 첫 번째 파일을 보기 전의 시간을 단축합니다.

빠른 Diff는 베타 버전입니다. 클래식 diff 환경의 일부 기능은 사용할 수 없습니다. 알려진 제한 사항 목록은 [의견 이슈 596236](https://gitlab.com/gitlab-org/gitlab/-/issues/596236)을 참조하세요. 기능 패리티 로드맵은 [에픽 19380](https://gitlab.com/groups/gitlab-org/-/epics/19380)을 참조하세요.

### 빠른 Diff 켜기 {#turn-on-rapid-diffs}

모든 머지 리퀘스트에 대해 빠른 Diff를 켜려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾으세요.
1. 왼쪽 사이드바에서 **코드** > **머지 리퀘스트**를 선택하고 머지 리퀘스트를 찾습니다.
1. 머지 리퀘스트 제목 아래에서 **변경사항**을 선택합니다.
1. **Try Rapid Diffs**를 선택합니다.

페이지가 새로운 환경으로 다시 로드됩니다. 기본 설정이 세션 전체에서 유지됩니다.

빠른 Diff에 대한 의견을 공유하려면 **빠른 Diff** > **의견을 남겨 주세요**를 선택합니다.

### 빠른 Diff 끄기 {#turn-off-rapid-diffs}

빠른 Diff를 끄고 클래식 diff 로딩 환경으로 돌아가려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾으세요.
1. 왼쪽 사이드바에서 **코드** > **머지 리퀘스트**를 선택하고 머지 리퀘스트를 찾습니다.
1. 머지 리퀘스트 제목 아래에서 **변경사항**을 선택합니다.
1. **빠른 Diff**를 선택하여 드롭다운 목록을 엽니다.
1. **Switch to classic loading**을 선택합니다.

## 머지 리퀘스트에서 코드 설명 {#explain-code-in-a-merge-request}

{{< details >}}

- 계층:  Premium, Ultimate
- 추가 기능:  GitLab Duo Pro 또는 Enterprise, GitLab Duo with Amazon Q
- 제공:  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< collapsible title="모델 정보" >}}

- [기본 LLM](../../gitlab_duo/model_selection.md#default-models)
- Amazon Q용 LLM:  Amazon Q Developer

{{< /collapsible >}}

{{< history >}}

- GitLab 16.8에서 [일반 공개](https://gitlab.com/gitlab-org/gitlab/-/issues/429915)되었습니다.
- GitLab 17.6 이상에서 GitLab Duo 추가 기능이 필요하도록 변경되었습니다.
- GitLab 18.6에서 기본 LLM을 Claude Sonnet 4.5로 [업데이트](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/issues/1541)했습니다.

{{< /history >}}

다른 사람이 작성한 코드를 이해하기 위해 많은 시간을 보내거나 익숙하지 않은 언어로 작성된 코드를 이해하는 데 어려움을 겪는 경우 GitLab Duo에 코드 설명을 요청할 수 있습니다.

- <i class="fa-youtube-play" aria-hidden="true"></i> [개요 시청](https://youtu.be/1izKaLmmaCA?si=O2HDokLLujRro_3O)
  <!-- Video published on 2023-11-18 -->

전제 조건:

- 최소한 [실험 및 베타 기능 설정](../../gitlab_duo/turn_on_off.md#turn-on-beta-and-experimental-features)이 활성화된 그룹에 속해야 합니다.
- 프로젝트를 볼 수 있는 액세스 권한이 있어야 합니다.

머지 리퀘스트에서 코드를 설명하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾으세요.
1. 왼쪽 사이드바에서 **코드** > **머지 리퀘스트**를 선택한 후 머지 리퀨스트를 선택합니다.
1. **변경사항**을 선택합니다.
1. 설명하려는 파일에서 세 점({{< icon name="ellipsis_v" >}})을 선택하고 **View File @ $SHA**를 선택합니다.

   별도의 브라우저 탭이 열리고 최신 변경 사항이 있는 전체 파일을 표시합니다.

1. 새 탭에서 설명하려는 줄을 선택합니다.
1. 왼쪽에서 물음표({{< icon name="question" >}})를 선택합니다. 선택 항목의 첫 번째 줄까지 스크롤하여 이를 봐야 할 수도 있습니다.

   ![머지 리퀨스트에서 GitLab Duo를 사용하여 선택한 코드 스니펫을 설명하는 아이콘입니다.](img/explain_code_v17_1.png)

GitLab Duo Chat은 코드를 설명합니다. 설명이 생성되는 데 잠깐 시간이 걸릴 수 있습니다.

원하는 경우 설명의 품질에 대한 의견을 제공할 수 있습니다.

GitLab은 대형 언어 모델이 정확한 결과를 생성한다는 것을 보장할 수 없습니다. 설명을 주의해서 사용하세요.

다음에서도 코드를 설명할 수 있습니다:

- [파일](../repository/code_explain.md).
- [IDE](../../gitlab_duo_chat/examples.md#explain-selected-code).

## 댓글 펼치기/축소 {#expand-or-collapse-comments}

코드 변경을 검토할 때 인라인 댓글을 숨길 수 있습니다:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾으세요.
1. 왼쪽 사이드바에서 **코드** > **머지 리퀘스트**를 선택하고 머지 리퀘스트를 찾습니다.
1. 제목 아래에서 **변경사항**을 선택합니다.
1. 숨기려는 댓글이 포함된 파일로 스크롤합니다.
1. 댓글이 연결된 줄로 스크롤합니다. 여백에서 **접기**({{< icon name="collapse" >}})를 선택합니다:  ![머지 리퀨스트 diff에서 댓글을 축소하는 아이콘입니다.](img/collapse-comment_v17_1.png)

인라인 댓글을 펼쳐 다시 표시하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾으세요.
1. 왼쪽 사이드바에서 **코드** > **머지 리퀘스트**를 선택하고 머지 리퀘스트를 찾습니다.
1. 제목 아래에서 **변경사항**을 선택합니다.
1. 표시하려는 축소된 댓글이 포함된 파일로 스크롤합니다.
1. 댓글이 연결된 줄로 스크롤합니다. 여백에서 사용자 아바타를 선택합니다:  ![머지 리퀨스트 diff에서 댓글을 펼치는 아이콘입니다.](img/expand-comment_v17_10.png)

## 공백 변경 사항 무시 {#ignore-whitespace-changes}

공백 변경으로 인해 머지 리퀘스트의 실질적인 변경 사항을 보기가 더 어려워질 수 있습니다. 공백 변경 사항을 숨기거나 표시하도록 선택할 수 있습니다:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾으세요.
1. 왼쪽 사이드바에서 **코드** > **머지 리퀘스트**를 선택하고 머지 리퀘스트를 찾습니다.
1. 제목 아래에서 **변경사항**을 선택합니다.
1. 변경된 파일 목록 전에 **환경설정**({{< icon name="preferences" >}})을 선택합니다.
1. **공백 변경 사항 표시**를 선택하거나 선택을 취소합니다:

   ![환경설정 메뉴가 확장되고 '공백 변경 사항 표시' 옵션이 선택된 머지 리퀨스트 diff입니다.](img/merge_request_diff_v17_10.png)

## 파일을 조회됨으로 표시 {#mark-files-as-viewed}

많은 파일이 있는 머지 리퀘스트를 여러 번 검토할 때 이미 검토한 파일을 무시할 수 있습니다. 마지막 검토 후 변경되지 않은 파일을 숨기려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾으세요.
1. 왼쪽 사이드바에서 **코드** > **머지 리퀘스트**를 선택하고 머지 리퀘스트를 찾습니다.
1. 제목 아래에서 **변경사항**을 선택합니다.
1. 파일의 헤더에서 **조회됨** 확인란을 선택합니다.

조회됨으로 표시된 파일은 다음 중 하나가 발생하지 않는 한 다시 표시되지 않습니다:

- 파일의 내용이 변경됩니다.
- **조회됨** 확인란을 선택 취소합니다.

## diff에서 머지 리퀘스트 충돌 표시 {#show-merge-request-conflicts-in-diff}

대상 브랜치에 이미 있는 변경 사항을 표시하지 않으려면 GitLab은 머지 리퀘스트의 소스 브랜치를 대상 브랜치의 `HEAD`과 비교합니다.

소스 브랜치와 대상 브랜치가 충돌할 때 GitLab은 머지 리퀨스트 diff에 충돌된 각 파일에 대한 경고를 표시합니다:

![머지 리퀨스트 diff의 충돌 경고입니다.](img/conflict_ui_v15_6.png)

## diff에서 스캐너 결과 표시 {#show-scanner-findings-in-diff}

{{< details >}}

- 계층:  Ultimate
- 제공:  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

diff에 스캐너 결과를 표시할 수 있습니다. 자세한 내용은 다음을 참조하세요:

- [코드 품질 결과](../../../ci/testing/code_quality.md#merge-request-changes-view)
- [정적 분석 결과](../../application_security/sast/_index.md#merge-request-changes-view)

## 머지 리퀘스트 변경 사항 다운로드 {#download-merge-request-changes}

GitLab 외부에서 사용하기 위해 머지 리퀘스트에 포함된 변경 사항을 다운로드할 수 있습니다.

### Diff로 {#as-a-diff}

변경 사항을 diff로 다운로드하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾으세요.
1. 왼쪽 사이드바에서 **코드** > **머지 리퀘스트**를 선택하고 머지 리퀘스트를 찾습니다.
1. 머지 리퀘스트를 선택합니다.
1. 오른쪽 위 모서리에서 **코드** > **일반 diff**를 선택합니다.

머지 리퀘스트의 URL을 알고 있으면 `.diff`을 URL에 추가하여 명령줄에서 diff를 다운로드할 수도 있습니다. 이 예제는 머지 리퀘스트 `000000`의 diff를 다운로드합니다:

```plaintext
https://gitlab.com/gitlab-org/gitlab/-/merge_requests/000000.diff
```

한 줄 CLI 명령으로 diff를 다운로드하고 적용하려면:

```shell
curl "https://gitlab.com/gitlab-org/gitlab/-/merge_requests/000000.diff" | git apply
```

### 패치 파일로 {#as-a-patch-file}

변경 사항을 패치 파일로 다운로드하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾으세요.
1. 왼쪽 사이드바에서 **코드** > **머지 리퀘스트**를 선택하고 머지 리퀘스트를 찾습니다.
1. 머지 리퀘스트를 선택합니다.
1. 오른쪽 위 모서리에서 **코드** > **패치**를 선택합니다.

머지 리퀘스트의 URL을 알고 있으면 `.patch`을 URL에 추가하여 명령줄에서 패치를 다운로드할 수도 있습니다. 이 예제는 머지 리퀘스트 `000000`의 패치 파일을 다운로드합니다:

```plaintext
https://gitlab.com/gitlab-org/gitlab/-/merge_requests/000000.patch
```

[`git am`](https://git-scm.com/docs/git-am)을 사용하여 패치를 다운로드하고 적용하려면:

```shell
# Download and preview the patch
curl "https://gitlab.com/gitlab-org/gitlab/-/merge_requests/000000.patch" > changes.patch
git apply --check changes.patch

# Apply the patch
git am changes.patch
```

단일 명령으로 패치를 다운로드하고 적용할 수도 있습니다:

```shell
curl "https://gitlab.com/gitlab-org/gitlab/-/merge_requests/000000.patch" | git am
```

`git am`은 기본적으로 `-p1` 옵션을 사용합니다. 자세한 내용은 [`git-apply`](https://git-scm.com/docs/git-apply)를 참조하세요.

### 이전 diff 버전 다운로드 {#download-older-diff-versions}

{{< history >}}

- GitLab 18.7에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/373246)되었습니다.

{{< /history >}}

이전 diff 버전을 패치 또는 diff 파일로 다운로드하려면:

1. 다운로드하려는 [diff 버전을 비교](versions.md#compare-diff-versions)합니다.
1. `.diff` 또는 `.patch`을 URL 경로에 추가합니다.

예를 들어:

```plaintext
# As a diff file:
https://gitlab.com/gitlab-org/gitlab/-/merge_requests/123456/diffs.diff?diff_id=525410&start_sha=a1b2c3d4

# As a patch file:
https://gitlab.com/gitlab-org/gitlab/-/merge_requests/123456/diffs.patch?diff_id=525410&start_sha=a1b2c3d4
```

## 머지 리퀘스트 파일에 댓글 추가 {#add-a-comment-to-a-merge-request-file}

{{< history >}}

- GitLab 16.1에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/123515) 되었으며 [기능 플래그](../../../administration/feature_flags/_index.md) `comment_on_files`로 제공됩니다. 기본적으로 활성화됩니다.
- GitLab 16.2에서 [기능 플래그가 제거](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/125130)되었습니다.

{{< /history >}}

머지 리퀘스트 diff 파일에 댓글을 추가할 수 있습니다. 이러한 댓글은 리베이스 및 파일 변경에 영속됩니다.

머지 리퀘스트 파일에 댓글을 추가하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾으세요.
1. 왼쪽 사이드바에서 **코드** > **머지 리퀘스트**를 선택하고 머지 리퀘스트를 찾습니다.
1. **변경사항**을 선택합니다.
1. 댓글을 달려는 파일의 헤더에서 **이 파일에 댓글 달기**({{< icon name="comment" >}})를 선택합니다.

## 이미지에 댓글 추가 {#add-a-comment-to-an-image}

머지 리퀨스트 및 커밋 세부 정보 보기에서 이미지에 댓글을 추가할 수 있습니다. 이 댓글은 스레드일 수도 있습니다.

1. 이미지 위에 마우스를 놓습니다.
1. 댓글을 달려는 위치를 선택합니다.

GitLab은 이미지에 아이콘과 댓글 필드를 표시합니다.

## 관련 항목 {#related-topics}

- [버전 비교](../repository/compare_revisions.md)
- [분기 비교 다운로드](../repository/branches/_index.md#download-branch-comparisons)
- [머지 리퀨스트 검토](reviews/_index.md)
- [머지 리퀨스트 버전](versions.md)
