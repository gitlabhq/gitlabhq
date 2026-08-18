---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 위키
description: "문서, 외부 위키, 위키 이벤트 및 이력"
---

{{< details >}}

- 계층: Free, Premium, Ultimate
- 제공 서비스:  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

위키는 프로젝트 및 그룹 문서를 친숙한 형식으로 제공합니다. 위키 페이지:

- Markdown, RDoc, AsciiDoc 또는 Org 형식으로 기술 문서, 가이드 및 지식 기반을 생성합니다.
- GitLab 프로젝트 및 그룹과 직접 통합되는 협업 문서를 만듭니다.
- 버전 제어 및 협업을 위해 Git 리포지토리에 문서를 저장합니다.
- 사이드바 사용자 지정을 통해 사용자 지정 네비게이션 및 조직을 지원합니다.
- 콘텐츠를 PDF 파일로 내보내 오프라인 액세스 및 공유를 지원합니다.
- 콘텐츠를 코드베이스와 별도로 유지하면서 같은 프로젝트에 보관합니다.
- 페이지의 이모지 반응을 지원하여 피드백과 참여를 높입니다.

각 위키는 별도의 Git 리포지토리입니다. GitLab 웹 인터페이스 또는 [Git을 사용하여 로컬에서](#create-or-edit-wiki-pages-locally) 위키 페이지를 생성하고 편집할 수 있습니다. Markdown으로 작성된 위키 페이지는 모든 [Markdown 기능](../../markdown.md)을 지원하며 링크를 위한 [위키별 동작](markdown.md)을 제공합니다.

위키 페이지는 [사이드바](#sidebar)를 표시하며, 이를 사용자 지정할 수 있습니다.

## 프로젝트 위키 보기 {#view-a-project-wiki}

프로젝트 위키에 액세스하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 위키를 표시하려면:
   - 왼쪽 사이드바에서 **계획** > **위키**를 선택합니다.
   - 프로젝트의 아무 페이지에서나 <kbd>g</kbd>+<kbd>w</kbd> [위키 바로가기](../../shortcuts.md)를 사용합니다.

**계획** > **위키**가 프로젝트의 왼쪽 사이드바에 나열되지 않으면 프로젝트 관리자가 [비활성화](#enable-or-disable-a-project-wiki)한 것입니다.

## 위키의 기본 브랜치 구성 {#configure-a-default-branch-for-your-wiki}

위키 리포지토리는 인스턴스 또는 그룹의 [기본 브랜치 이름](../repository/branches/default.md)을 상속합니다. 사용자 지정 브랜치 이름이 구성되지 않은 경우 GitLab은 `main`을 사용합니다. 위키의 기본 브랜치 이름을 변경하려면 [리포지토리의 기본 브랜치 이름 업데이트](../repository/branches/default.md#update-the-default-branch-name-in-your-repository)를 수행합니다.

## 위키 홈 페이지 만들기 {#create-the-wiki-home-page}

{{< history >}}

- 페이지 제목과 경로 분리 [GitLab 17.2에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/30758) [플래그](../../../administration/feature_flags/_index.md) `wiki_front_matter` 및 `wiki_front_matter_title` 이름. 기본적으로 활성화됩니다.
- 기능 플래그 `wiki_front_matter` 및 `wiki_front_matter_title`이 GitLab 17.3에서 제거되었습니다.
- 몰입형 편집기 [GitLab 19.0에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/231662) [기능 플래그](../../../administration/feature_flags/_index.md) `wiki_immersive_editor` 이름. 기본적으로 활성화됩니다.

{{< /history >}}

> [!flag]
> 몰입형 편집기의 가용성은 기능 플래그로 제어됩니다. 자세한 내용은 기록을 참조하세요.

위키를 만들 때 비어 있습니다. 첫 번째 방문 시 위키를 볼 때 사용자가 보는 홈 페이지를 만들 수 있습니다. 이 페이지는 위키의 홈 페이지로 사용할 특정 경로가 필요합니다. 만들려면:

1. 상단 막대에서 **검색 또는 이동**을 선택하고 프로젝트 또는 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **계획** > **위키**를 선택합니다.
1. **첫 페이지 만들기**를 선택합니다.
1. 선택 사항. 홈 페이지의 **제목**을 변경합니다.
1. GitLab은 첫 페이지가 경로 `home`을 가져야 합니다. 이 경로의 페이지가 위키의 첫 페이지로 사용됩니다.
1. 선택 사항. **페이지 옵션 수정**({{< icon name="chevron-down" >}})을 선택하여:
   - 페이지의 **경로**를 변경합니다. 기본적으로 경로는 제목에서 생성됩니다. 페이지 경로는 [특수 문자](#special-characters-in-page-paths)를 사용하여 하위 디렉토리 및 형식을 지정하며 [길이 제한](#length-restrictions-for-file-and-directory-names)이 있습니다.
   - 콘텐츠 **포맷**을 변경합니다.
   - **템플릿**을 선택합니다. 자세한 내용은 [템플릿으로부터](#from-a-template)를 참조하세요.
1. 콘텐츠 영역에 홈 페이지에 대한 환영 메시지를 추가합니다. 나중에 언제든지 편집할 수 있습니다.
1. **페이지 생성**을 선택합니다. 저장 전에 커밋 메시지를 추가하려면 **페이지 생성** 옆의 화살표를 선택한 후 **메시지와 함께 변경사항 저장**을 선택합니다.

## 새 위키 페이지 만들기 {#create-a-new-wiki-page}

{{< history >}}

- 페이지 제목과 경로 분리 [GitLab 17.2에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/30758) [플래그](../../../administration/feature_flags/_index.md) `wiki_front_matter` 및 `wiki_front_matter_title` 이름. 기본적으로 활성화됩니다.
- 기능 플래그 `wiki_front_matter` 및 `wiki_front_matter_title`이 GitLab 17.3에서 제거되었습니다.
- 상단 바에서 위키 페이지 만들기 [GitLab 18.10에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/work_items/591976).
- 몰입형 편집기 [GitLab 19.0에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/231662) [기능 플래그](../../../administration/feature_flags/_index.md) `wiki_immersive_editor` 이름. 기본적으로 활성화됩니다.

{{< /history >}}

> [!flag]
> 몰입형 편집기의 가용성은 기능 플래그로 제어됩니다. 자세한 내용은 기록을 참조하세요.

전제 조건:

- Developer, Maintainer 또는 Owner 역할이 있어야 합니다.

프로젝트 또는 그룹에서 새 위키 페이지를 만들려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 그룹 또는 프로젝트를 찾습니다.
1. 오른쪽 위 모서리에서 **새로 만들기**({{< icon name="plus" >}})를 선택한 후 **새 위키 페이지**를 선택합니다.

또는:

1. 상단 막대에서 **검색 또는 이동**을 선택하고 프로젝트 또는 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **계획** > **위키**를 선택합니다.
1. **위키 동작**({{< icon name="ellipsis_v" >}})을 선택한 후 이 페이지 또는 다른 위키 페이지에서 **새 페이지**를 선택합니다.

새 페이지 양식을 연 후 다음 단계를 완료합니다:

1. 편집기 헤더에서 새 페이지에 대한 **제목**을 추가합니다.
1. 선택 사항. **페이지 옵션 수정**({{< icon name="chevron-down" >}})을 선택하여:
   - 페이지의 **경로**를 변경합니다. 기본적으로 경로는 제목에서 생성됩니다. 페이지 경로는 [특수 문자](#special-characters-in-page-paths)를 사용하여 하위 디렉토리 및 형식을 지정하며 [길이 제한](#length-restrictions-for-file-and-directory-names)이 있습니다.
   - 콘텐츠 **포맷**을 변경합니다.
   - **템플릿**을 선택합니다. 자세한 내용은 [템플릿으로부터](#from-a-template)를 참조하세요.
1. 선택 사항. 위키 페이지에 콘텐츠를 추가합니다.
1. 선택 사항. 파일을 첨부하면 GitLab이 위키의 Git 리포지토리에 저장합니다.
1. **페이지 생성**을 선택합니다. 저장 전에 커밋 메시지를 추가하려면 **페이지 생성** 옆의 화살표를 선택한 후 **메시지와 함께 변경사항 저장**을 선택합니다.

### 템플릿으로부터 {#from-a-template}

{{< history >}}

- 새 위키 페이지를 템플릿에서 직접 만들기 [GitLab 18.6에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/474328).

{{< /history >}}

프로젝트에 최소 하나의 템플릿이 있는 경우 [템플릿](#create-a-template)에서 새 위키 페이지를 만들 수 있습니다.

전제 조건:

- 이미 [최소 하나의 템플릿을 만들었어야](#create-a-template) 합니다.

{{< tabs >}}

{{< tab title="템플릿 목록" >}}

1. 상단 막대에서 **검색 또는 이동**을 선택하고 프로젝트 또는 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **계획** > **위키**를 선택합니다.
1. **텝플릿**을 선택하여 사용 가능한 모든 템플릿을 봅니다.
1. 사용하려는 템플릿 옆에서 **템플릿으로 부터 생성**을 선택합니다.
1. 새 페이지 양식이 다음과 같이 열립니다:
   - 콘텐츠 영역에 미리 채워진 템플릿 콘텐츠.
   - 템플릿 드롭다운 목록에서 선택된 템플릿.
1. 새 페이지의 제목을 입력합니다.
1. 필요에 따라 콘텐츠를 수정합니다.
1. **페이지 생성**을 선택합니다.

{{< /tab >}}

{{< tab title="템플릿 페이지에서" >}}

1. 상단 막대에서 **검색 또는 이동**을 선택하고 프로젝트 또는 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **계획** > **위키**를 선택합니다.
1. **텝플릿**을 선택하여 사용 가능한 모든 템플릿을 봅니다.
1. 사용하려는 템플릿을 선택합니다.
1. 페이지 헤더에서 **템플릿으로 부터 생성**을 선택합니다.
1. 새 페이지 양식이 현재 템플릿을 미리 선택하고 콘텐츠를 로드하여 열립니다.
1. 새 페이지의 제목을 입력합니다.
1. 필요에 따라 콘텐츠를 수정합니다.
1. **페이지 생성**을 선택합니다.

{{< /tab >}}

{{< tab title="새 페이지 양식에서" >}}

1. 상단 막대에서 **검색 또는 이동**을 선택하고 프로젝트 또는 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **계획** > **위키**를 선택합니다.
1. **새 페이지**를 선택합니다.
1. **템플릿 선택** 드롭다운 목록에서 원하는 템플릿을 선택합니다.
1. 템플릿 콘텐츠가 자동으로 콘텐츠 영역에 로드됩니다.
1. 페이지의 제목을 입력합니다.
1. 필요에 따라 콘텐츠를 수정합니다.
1. **페이지 생성**을 선택합니다.

{{< /tab >}}

{{< /tabs >}}

### 위키 페이지를 로컬에서 생성하거나 편집 {#create-or-edit-wiki-pages-locally}

위키는 Git 리포지토리를 기반으로 하므로 로컬로 복제하고 다른 모든 Git 리포지토리처럼 편집할 수 있습니다. 위키 리포지토리를 로컬로 복제하려면:

1. 상단 막대에서 **검색 또는 이동**을 선택하고 프로젝트 또는 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **계획** > **위키**를 선택합니다.
1. **위키 동작**({{< icon name="ellipsis_v" >}})을 선택한 후 **저장소 클론**을 선택합니다.
1. 화면의 지시사항을 따릅니다.

위키에 로컬로 추가하는 파일은 사용하려는 마크업 언어에 따라 다음 지원되는 확장자 중 하나를 사용해야 합니다. 지원하지 않는 확장자가 있는 파일은 GitLab으로 푸시할 때 표시되지 않습니다:

- Markdown 확장자: `.mdown`, `.mkd`, `.mkdn`, `.md`, `.markdown`.
- AsciiDoc 확장자: `.adoc`, `.ad`, `.asciidoc`.
- 기타 마크업 확장자: `.textile`, `.rdoc`, `.org`, `.creole`, `.wiki`, `.mediawiki`, `.rst`.

### 페이지 경로의 특수 문자 {#special-characters-in-page-paths}

{{< history >}}

- [GitLab 16.7에서 프론트 매터 기반 제목 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/133521) [플래그](../../../administration/feature_flags/_index.md) `wiki_front_matter` 및 `wiki_front_matter_title` 이름. 기본적으로 비활성화되어 있습니다.
- 기능 플래그 [`wiki_front_matter`](https://gitlab.com/gitlab-org/gitlab/-/issues/435056) 및 [`wiki_front_matter_title`](https://gitlab.com/gitlab-org/gitlab/-/issues/428259)이 GitLab 17.2에서 기본적으로 활성화되었습니다.
- 기능 플래그 `wiki_front_matter` 및 `wiki_front_matter_title`이 GitLab 17.3에서 제거되었습니다.

{{< /history >}}

위키 페이지는 Git 리포지토리의 파일로 저장되며 기본적으로 페이지의 파일 이름이 제목이기도 합니다. 파일 이름의 특정 문자는 특별한 의미를 가집니다:

- 페이지를 저장할 때 공백은 하이픈으로 변환됩니다.
- 하이픈(`-`)은 페이지를 표시할 때 공백으로 변환됩니다.
- 슬래시(`/`)는 경로 구분자로 사용되며 제목에 표시할 수 없습니다. 제목에 `/` 문자를 포함하는 파일을 만드는 경우 GitLab은 해당 경로를 만들기 위해 필요한 모든 하위 디렉토리를 만듭니다. 예를 들어 `docs/my-page` 제목은 경로 `/wikis/docs/my-page`를 가진 위키 페이지를 만듭니다.

이러한 제한을 피하려면 페이지 콘텐츠 앞의 프론트 매터 블록에 위키 페이지의 제목을 저장할 수도 있습니다. 예를 들어:

```yaml
---
title: Page title
---
```

### 파일 및 디렉토리 이름의 길이 제한 {#length-restrictions-for-file-and-directory-names}

많은 일반적인 파일 시스템에서 파일 및 디렉토리 이름에 대해 [255바이트 제한](https://en.wikipedia.org/wiki/Comparison_of_file_systems#Limits)이 있습니다. Git 및 GitLab은 모두 이러한 제한을 초과하는 경로를 지원합니다. 하지만 파일 시스템에서 이 제한을 적용하는 경우 이 제한을 초과하는 파일 이름이 포함된 위키의 로컬 사본을 체크아웃할 수 없습니다. 이 문제를 방지하기 위해 GitLab 웹 인터페이스 및 API는 이러한 제한을 적용합니다:

- 파일 이름의 경우 245바이트(파일 확장자를 위해 10바이트 예약).
- 디렉토리 이름의 경우 255바이트.

ASCII가 아닌 문자는 1바이트 이상을 차지합니다.

이 제한을 초과하는 파일을 로컬에서 여전히 만들 수 있지만 팀원이 나중에 위키를 로컬에서 체크아웃하지 못할 수 있습니다.

## 위키 페이지 편집 {#edit-a-wiki-page}

{{< history >}}

- 미리보기 모드에서 고정 **편집** [GitLab 18.11에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/work_items/590255).
- 몰입형 편집기 [GitLab 19.0에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/231662) [기능 플래그](../../../administration/feature_flags/_index.md) `wiki_immersive_editor` 이름. 기본적으로 활성화됩니다.

{{< /history >}}

> [!flag]
> 몰입형 편집기의 가용성은 기능 플래그로 제어됩니다. 자세한 내용은 기록을 참조하세요.

전제 조건:

- Developer, Maintainer 또는 Owner 역할이 있어야 합니다.

위키 편집기는 다음을 포함하는 고정 헤더와 함께 열립니다:

- 페이지 제목. 이를 인라인으로 편집할 수 있습니다.
- **페이지 옵션 수정**({{< icon name="chevron-down" >}})을 선택하여 페이지 경로, 형식을 변경하거나 템플릿을 선택합니다.
- 위키 사이드바를 표시하거나 숨기는 사이드바 토글({{< icon name="sidebar" >}}).
- **변경사항 저장** 및 **취소**를 선택하여 변경사항을 저장하거나 취소합니다.

위키 페이지를 편집하려면:

1. 상단 막대에서 **검색 또는 이동**을 선택하고 프로젝트 또는 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **계획** > **위키**를 선택합니다.
1. 편집하려는 페이지로 이동한 후:
   - <kbd>e</kbd> 위키 [바로가기](../../shortcuts.md#wiki-pages)를 사용합니다.
   - **편집**을 선택합니다.
1. 콘텐츠를 편집합니다.
1. **변경사항 저장**을 선택합니다. 저장 전에 커밋 메시지를 추가하려면 **변경사항 저장** 옆의 화살표를 선택한 후 **메시지와 함께 변경사항 저장**을 선택합니다.

페이지를 미리보고 스크롤하면 페이지 상단의 고정 바가 **편집** 및 기타 작업을 액세스할 수 있도록 유지합니다.

위키 페이지의 저장되지 않은 변경사항은 실수로 인한 데이터 손실을 방지하기 위해 로컬 브라우저 스토리지에 보존됩니다.

### 목차 만들기 {#create-a-table-of-contents}

{{< history >}}

- 위키 사이드바의 목차 [GitLab 17.2에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/281570).

{{< /history >}}

제목이 포함된 위키 페이지는 사이드바의 목차 섹션을 자동으로 표시합니다.

페이지 자체에 별도의 목차 섹션을 선택적으로 표시할 수도 있습니다. 위키 페이지의 부제목에서 목차를 생성하려면 `[[_TOC_]]` 태그를 사용합니다. 예시는 [목차](../../markdown.md#table-of-contents)를 참조하세요.

## 위키 페이지에 반응 {#react-to-a-wiki-page}

{{< history >}}

- [GitLab 19.1에서 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/510116)

{{< /history >}}

위키 페이지에 직접 이모지 반응을 추가할 수 있습니다. 반응은 페이지 콘텐츠 아래, 댓글 섹션 위에 나타납니다.

위키 페이지에 반응하려면:

1. 상단 막대에서 **검색 또는 이동**을 선택하고 프로젝트 또는 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **계획** > **위키**를 선택합니다.
1. 반응하려는 페이지로 이동합니다.
1. 페이지 콘텐츠 아래에서 기존 이모지를 선택하여 반응을 추가하거나 **반응 추가**({{< icon name="slight-smile" >}})를 선택하여 다른 이모지를 선택합니다.

반응을 제거하려면 이모지를 다시 선택합니다. 각 사용자는 페이지당 각 유형의 반응을 하나만 추가할 수 있습니다.

페이지에 첫 번째 반응을 추가하면 GitLab이 해당 페이지의 알림을 구독합니다.

## 위키 페이지 삭제 {#delete-a-wiki-page}

전제 조건:

- Developer, Maintainer 또는 Owner 역할이 있어야 합니다.

1. 상단 막대에서 **검색 또는 이동**을 선택하고 프로젝트 또는 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **계획** > **위키**를 선택합니다.
1. 삭제하려는 페이지로 이동합니다.
1. **위키 동작**({{< icon name="ellipsis_v" >}})을 선택한 후 **페이지 삭제**를 선택합니다.
1. 삭제를 확인합니다.

## 위키 페이지 이동 또는 이름 바꾸기 {#move-or-rename-a-wiki-page}

{{< history >}}

- 이동하거나 이름을 바꾼 위키 페이지에 대한 리디렉션 [GitLab 17.1에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/257892) [플래그](../../../administration/feature_flags/_index.md) `wiki_redirection` 이름. 기본적으로 활성화됩니다.
- 페이지 제목과 경로 분리 [GitLab 17.2에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/30758) [플래그](../../../administration/feature_flags/_index.md) `wiki_front_matter` 및 `wiki_front_matter_title` 이름. 기본적으로 활성화됩니다.
- 기능 플래그 `wiki_redirection`, `wiki_front_matter` 및 `wiki_front_matter_title`이 GitLab 17.3에서 제거되었습니다.

{{< /history >}}

GitLab 17.1 이상에서 페이지를 이동하거나 이름을 바꾸면 이전 페이지에서 새 페이지로의 리디렉션이 자동으로 설정됩니다. 리디렉션 목록은 Wiki 리포지토리의 `.gitlab/redirects.yml` 파일에 저장됩니다.

전제 조건:

- Developer, Maintainer 또는 Owner 역할이 있어야 합니다.

1. 상단 막대에서 **검색 또는 이동**을 선택하고 프로젝트 또는 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **계획** > **위키**를 선택합니다.
1. 이동하거나 이름을 바꾸려는 페이지로 이동합니다.
1. **편집**을 선택합니다.
1. 편집기 헤더에서 **페이지 옵션 수정**({{< icon name="chevron-down" >}})을 선택합니다.
1. 페이지를 이동하려면 **경로** 필드를 변경합니다. 예를 들어 `About` 아래에 `Company` 위키 페이지가 있고 이를 위키의 루트로 이동하려면 **경로**를 `About`에서 `/About`로 변경합니다.
1. 페이지의 이름을 바꾸려면 **경로**를 변경합니다.
1. **변경사항 저장**을 선택합니다.

## 위키 페이지 내보내기 {#export-a-wiki-page}

{{< history >}}

- [GitLab 16.3에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/414691) [플래그](../../../administration/feature_flags/_index.md) `print_wiki` 이름. 기본적으로 비활성화되어 있습니다.
- [GitLab.com 및 GitLab Self-Managed에서 활성화됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/134251/) GitLab 16.5.
- 기능 플래그 `print_wiki`이 GitLab 16.6에서 제거되었습니다.

{{< /history >}}

위키 페이지를 PDF 파일로 내보낼 수 있습니다:

1. 상단 막대에서 **검색 또는 이동**을 선택하고 프로젝트 또는 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **계획** > **위키**를 선택합니다.
1. 내보내려는 페이지로 이동합니다.
1. 오른쪽 위에서 **위키 동작**({{< icon name="ellipsis_v" >}})을 선택한 후 **PDF 출력**을 선택합니다.

위키 페이지의 PDF가 생성됩니다.

## Draw.io를 사용하여 위키에서 다이어그램 만들기 {#creating-diagrams-in-the-wiki-using-drawio}

diagrams.net 통합을 사용하면 위키 페이지에서 SVG 다이어그램을 만들고 삽입할 수 있습니다! 다이어그램 편집기는 일반 텍스트 편집기와 리치 텍스트 편집기 모두에서 사용할 수 있습니다.

GitLab.com에서는 이 통합이 모든 사용자에게 활성화되어 있으며 추가 구성이 필요하지 않습니다.

GitLab Self-Managed에서는 무료 diagrams.net 웹사이트와 통합하거나 오프라인 환경에서 자신만의 diagrams.net 사이트를 호스팅할 수 있습니다.

통합을 설정하려면 다음을 수행해야 합니다:

1. 무료 diagrams.net 웹사이트와 통합하거나 diagrams.net 서버를 구성합니다.
1. 통합을 활성화합니다.

통합을 완료한 후 diagrams.net 편집기가 제공된 URL과 함께 열립니다.

## 위키 페이지 템플릿 {#wiki-page-templates}

{{< history >}}

- GitLab 16.10에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/442228)되었습니다.

{{< /history >}}

새 페이지를 만들 때 사용하거나 기존 페이지에 적용할 템플릿을 만들 수 있습니다. 템플릿은 위키 리포지토리의 `templates/` 디렉토리에 저장되는 위키 페이지입니다.

### 템플릿 만들기 {#create-a-template}

전제 조건:

- Developer, Maintainer 또는 Owner 역할이 있어야 합니다.

1. 상단 막대에서 **검색 또는 이동**을 선택하고 프로젝트 또는 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **계획** > **위키**를 선택합니다.
1. **위키 동작**({{< icon name="ellipsis_v" >}})을 선택한 후 **텝플릿**을 선택합니다.
1. **New Template**을 선택합니다.
1. 템플릿 제목, 형식 및 콘텐츠를 입력합니다.

템플릿 경로는 제목에서 생성되며 편집할 수 없습니다. 템플릿의 이름을 바꾸려면 제목을 변경합니다. 제목은 경로의 일부로만 저장되므로 템플릿을 페이지에 적용해도 페이지 콘텐츠에 제목 메타데이터가 삽입되지 않습니다. 중첩된 템플릿을 만들려면 제목의 경로 구분자로 "/"를 사용합니다.

특정 형식의 템플릿은 같은 형식의 페이지에만 적용할 수 있습니다. 예를 들어 Markdown 템플릿은 Markdown 페이지에만 적용됩니다.

### 템플릿 적용 {#apply-a-template}

위키 페이지를 [만들거나](#create-a-new-wiki-page) [편집할](#edit-a-wiki-page) 때 템플릿을 적용할 수 있습니다.

전제 조건:

- 이미 [최소 하나의 템플릿을 만들었어야](#create-a-template) 합니다.

1. **콘텐츠** 섹션에서 **템플릿 선택** 드롭다운 목록을 선택합니다.
1. 목록에서 템플릿을 선택합니다. 페이지에 이미 일부 콘텐츠가 있는 경우 기존 콘텐츠를 덮어쓸 것임을 나타내는 경고가 표시됩니다.
1. **템플릿 적용**을 선택합니다.

### 페이지 템플릿을 이전 버전으로 복원 {#restore-a-page-template-to-a-previous-version}

{{< history >}}

- GitLab 18.6에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/383833)되었습니다.

{{< /history >}}

위키 페이지 템플릿을 이력에서 이전 버전으로 복원할 수 있습니다. 이는 복원된 콘텐츠로 새 버전을 만들면서 전체 버전 이력을 보존합니다.

전제 조건:

- Developer, Maintainer 또는 Owner 역할이 있어야 합니다.

위키 페이지 템플릿을 이전 버전으로 복원하려면:

1. 상단 막대에서 **검색 또는 이동**을 선택하고 프로젝트 또는 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **계획** > **위키**를 선택합니다.
1. **위키 동작**({{< icon name="ellipsis_v" >}})을 선택한 후 **텝플릿**을 선택합니다.
1. 템플릿을 선택합니다.
1. **위키 동작**({{< icon name="ellipsis_v" >}})을 선택한 후 **템플릿 이력**을 선택합니다.
1. 복원하려는 버전을 선택합니다.
1. 오른쪽 위에서 **이 버전으로 복구**를 선택합니다.
1. 커밋 대화상자에서 이 버전을 복원하는 이유를 설명하는 **커밋 메시지**를 추가합니다.
1. **복원**을 선택합니다.

페이지 템플릿이 선택한 버전으로 복원됩니다. 이전의 모든 버전은 페이지 이력에 남아 있습니다.

같은 프로세스를 사용하여 [위키 페이지를 복원](#restore-a-wiki-page-to-a-previous-version)할 수도 있습니다.

## 위키 페이지 구독 {#wiki-page-subscriptions}

위키 페이지 구독 기능을 통해 관심 있는 위키 페이지에 변경사항이 생기면 알림을 받을 수 있습니다. 이 기능은 팀원들에게 중요한 문서의 업데이트를 알려 협업을 강화할 수 있습니다.

특정 위키 페이지를 구독하여 다음의 경우 알림을 받을 수 있습니다:

- 페이지에 댓글 추가
- 댓글에 답장

### 위키 페이지 구독 {#subscribe-to-a-wiki-page}

1. 따라가려는 위키 페이지를 엽니다.
1. 오른쪽 위 모서리에서 **편집** 옆의 종 모양 아이콘({{< icon name="notifications" >}})을 선택합니다.
1. 종 모양 아이콘({{< icon name="notifications-off" >}})을 다시 선택하여 구독을 해제합니다.

구독 상태를 변경하면 GitLab이 확인 메시지를 표시합니다:

- 구독된 경우 `Notifications turned on`
- 구독이 취소된 경우 `Notifications turned off`

### 구독 권한 {#subscription-permissions}

위키 페이지를 볼 수 있는 액세스 권한이 있는 모든 사용자가 구독할 수 있습니다. 구독 상태는 개인적이며 다른 사용자에게 영향을 주지 않습니다.

### 알림 설정 {#notification-settings}

알림은 프로젝트 알림 설정을 따릅니다. 구성된 알림 채널을 통해 전달됩니다.

## 위키 페이지의 이력 보기 {#view-history-of-a-wiki-page}

위키 페이지의 변경사항이 시간 경과에 따라 위키의 Git 리포지토리에 기록됩니다. 이력 페이지는 다음을 표시합니다:

- 페이지의 리뷰.
- 페이지 작성자.
- 커밋 메시지.
- 마지막 업데이트.
- **Page version** 열의 리뷰 번호를 선택하여 이전 리뷰.

위키 페이지의 변경사항을 보려면:

1. 상단 막대에서 **검색 또는 이동**을 선택하고 프로젝트 또는 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **계획** > **위키**를 선택합니다.
1. 이력을 보려는 페이지로 이동합니다.
1. **위키 동작**({{< icon name="ellipsis_v" >}})을 선택한 후 **페이지 이력**을 선택합니다.

### 페이지 버전 간의 변경사항 보기 {#view-changes-between-page-versions}

버전 diff 파일 보기와 유사하게 위키 페이지의 버전에서 수행된 변경사항을 볼 수 있습니다:

1. 상단 막대에서 **검색 또는 이동**을 선택하고 프로젝트 또는 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **계획** > **위키**를 선택합니다.
1. 관심 있는 위키 페이지로 이동합니다.
1. **위키 동작**({{< icon name="ellipsis_v" >}})을 선택한 후 **페이지 이력**을 선택하여 모든 페이지 버전을 봅니다.
1. 관심 있는 버전의 **Diff** 열에서 커밋 메시지를 선택합니다.

### 위키 페이지를 이전 버전으로 복원 {#restore-a-wiki-page-to-a-previous-version}

{{< history >}}

- GitLab 18.6에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/383833)되었습니다.

{{< /history >}}

위키 페이지를 이력에서 이전 버전으로 복원할 수 있습니다. 이는 복원된 콘텐츠로 새 버전을 만들면서 전체 버전 이력을 보존합니다.

전제 조건:

- Developer, Maintainer 또는 Owner 역할이 있어야 합니다.

위키 페이지를 이전 버전으로 복원하려면:

1. 상단 막대에서 **검색 또는 이동**을 선택하고 프로젝트 또는 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **계획** > **위키**를 선택합니다.
1. 복원하려는 페이지로 이동합니다.
1. **위키 동작**({{< icon name="ellipsis_v" >}})을 선택한 후 **페이지 이력**을 선택합니다.
1. 복원하려는 버전을 선택합니다.
1. 오른쪽 위에서 **이 버전으로 복구**를 선택합니다.
1. 커밋 대화상자에서 이 버전을 복원하는 이유를 설명하는 **커밋 메시지**를 추가합니다.
1. **복원**을 선택합니다.

페이지가 선택한 버전으로 복원됩니다. 이전의 모든 버전은 페이지 이력에 남아 있습니다.

같은 프로세스를 사용하여 [위키 페이지 템플릿을 복원](#restore-a-page-template-to-a-previous-version)할 수도 있습니다.

## 사이드바 {#sidebar}

{{< history >}}

- 사이드바에서 제목으로 검색 [GitLab 17.1에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/156054).
- 사이드바의 15개 항목 제한 [GitLab 17.2에서 제거됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/158084).
- 사이드바 [GitLab 18.6에서 오른쪽 위에서 왼쪽 위로 이동됨](https://gitlab.com/gitlab-org/gitlab/-/issues/569910).
- 부동 사이드바 토글 [GitLab 18.9에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/221019) `wiki_floating_sidebar_toggle` 이름의 플래그. 기본적으로 비활성화되어 있습니다.
- 부동 사이드바 토글 [GitLab 18.11에서 일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/227437). 기능 플래그 `wiki_floating_sidebar_toggle`이 제거되었습니다.

{{< /history >}}

위키 페이지는 위키의 페이지 목록을 포함하는 사이드바를 표시하며 중첩된 트리로 표시되고 형제 페이지는 알파벳 순서로 나열됩니다.

사이드바의 검색 상자를 사용하여 위키에서 제목으로 페이지를 찾을 수 있습니다. 페이지의 왼쪽 위 모서리에 있는 사이드바 토글({{< icon name="sidebar" >}})을 사용하여 사이드바를 열거나 닫을 수 있습니다.

성능상의 이유로 사이드바는 5000개 항목 표시로 제한됩니다. 모든 페이지 목록을 보려면 사이드바에서 **View All Pages**를 선택합니다.

### 사이드바 사용자 지정 {#customize-sidebar}

사이드바 네비게이션의 콘텐츠를 수동으로 편집할 수 있습니다.

전제 조건:

- Developer, Maintainer 또는 Owner 역할이 있어야 합니다.

이 프로세스는 `_sidebar` 이름의 위키 페이지를 만들어 기본 사이드바 네비게이션을 완전히 대체합니다:

1. 상단 막대에서 **검색 또는 이동**을 선택하고 프로젝트 또는 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **계획** > **위키**를 선택합니다.
1. 페이지의 왼쪽 위 모서리에서 **커스텀 사이드바 추가**({{< icon name="settings" >}})을 선택합니다.
1. 완료되면 **변경사항 저장**을 선택합니다.

`_sidebar` 예, Markdown으로 형식 지정:

```markdown
### Home

- [Hello World](hello)
- [Foo](foo)
- [Bar](bar)

---

- [Sidebar](_sidebar)
```

## 프로젝트 위키 활성화 또는 비활성화 {#enable-or-disable-a-project-wiki}

위키는 GitLab에서 기본적으로 활성화됩니다. 프로젝트 [관리자](../../permissions.md)는 [공유 및 권한](../settings/_index.md#configure-project-features-and-permissions)의 지침을 따라 프로젝트 위키를 활성화 또는 비활성화할 수 있습니다.

GitLab Self-Managed의 관리자는 [추가 위키 설정을 구성](../../../administration/wikis/_index.md)할 수 있습니다.

[그룹 설정](group.md#configure-group-wiki-visibility)에서 그룹 위키를 비활성화할 수 있습니다.

## 외부 위키 연결 {#link-an-external-wiki}

프로젝트의 왼쪽 사이드바에서 외부 위키로의 링크를 추가하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **연동**을 선택합니다.
1. **외부 Wiki**를 선택합니다.
1. 외부 위키에 URL을 추가합니다.
1. 선택 사항. **테스트 설정**을 선택합니다.
1. **변경사항 저장**을 선택합니다.

이제 프로젝트의 왼쪽 사이드바에서 **외부 Wiki** 옵션을 볼 수 있습니다.

이 통합을 활성화하면 외부 위키로의 링크가 내부 위키로의 링크를 대체하지 않습니다. 사이드바에서 내부 위키를 숨기려면 [프로젝트의 위키 비활성화](#disable-the-projects-wiki)를 수행합니다.

외부 위키로의 링크를 숨기려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **연동**을 선택합니다.
1. **외부 Wiki**를 선택합니다.
1. **통합 활성화**에서 **활성** 확인란을 선택 취소합니다.
1. **변경사항 저장**을 선택합니다.

## 프로젝트의 위키 비활성화 {#disable-the-projects-wiki}

프로젝트의 내부 위키를 비활성화하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **일반**을 선택합니다.
1. **표시 여부, 프로젝트 기능, 권한**을 확장합니다.
1. 아래로 스크롤하여 **위키** 토글(회색)을 찾아 끕니다.
1. **변경사항 저장**을 선택합니다.

이제 내부 위키가 비활성화되었으며 사용자 및 프로젝트 멤버는:

- 프로젝트의 사이드바에서 위키로의 링크를 찾을 수 없습니다.
- 위키 페이지를 추가, 삭제 또는 편집할 수 없습니다.
- 모든 위키 페이지를 볼 수 없습니다.

이전에 추가한 위키 페이지는 위키를 다시 활성화하려는 경우를 대비해 보존됩니다. 다시 활성화하려면 위키를 비활성화하는 프로세스를 반복하지만 토글을 켜기(파란색)로 설정합니다.

## 리치 텍스트 편집기 {#rich-text-editor}

{{< history >}}

- [GitLab 16.2에서 콘텐츠 편집기에서 리치 텍스트 편집기로 이름 변경됨](https://gitlab.com/gitlab-org/gitlab/-/issues/398152).

{{< /history >}}

GitLab은 위키에서 GitLab Flavored Markdown을 위한 리치 텍스트 편집 환경을 제공합니다.

지원 사항:

- 굵게, 이탤릭, 블록 인용, 제목 및 인라인 코드를 포함하여 텍스트 형식을 지정합니다.
- 정렬된 목록, 순서가 지정되지 않은 목록 및 확인 목록의 형식을 지정합니다.
- 테이블 구조를 만들고 편집합니다.
- 구문 강조 표시를 사용하여 코드 블록을 삽입하고 형식을 지정합니다.
- Mermaid, PlantUML 및 Kroki 다이어그램을 미리봅니다.

### 리치 텍스트 편집기 사용 {#use-the-rich-text-editor}

{{< history >}}

- 몰입형 편집기 [GitLab 19.0에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/231662) [기능 플래그](../../../administration/feature_flags/_index.md) `wiki_immersive_editor` 이름. 기본적으로 활성화됩니다.

{{< /history >}}

> [!flag]
> 몰입형 편집기의 가용성은 기능 플래그로 제어됩니다. 자세한 내용은 기록을 참조하세요.

1. 새 위키 페이지를 [만들거나](#create-a-new-wiki-page) 기존 페이지를 [편집합니다](#edit-a-wiki-page).
1. **Markdown**을 형식으로 선택합니다. 몰입형 편집기에서 편집기 헤더에 **페이지 옵션 수정**({{< icon name="chevron-down" >}})을 선택하여 형식을 변경합니다.
1. 편집기 헤더에서 **리치 텍스트 편집으로 전환**을 선택합니다.
1. 리치 텍스트 편집기에서 사용할 수 있는 다양한 형식 옵션을 사용하여 페이지의 콘텐츠를 사용자 지정합니다.
1. 새 페이지의 경우 **페이지 생성**을 선택하거나 기존 페이지의 경우 **변경사항 저장**을 선택합니다.

일반 텍스트로 다시 전환하려면 **일반 텍스트 편집으로 전환**을 선택합니다.

참고 항목:

- [리치 텍스트 편집기](../../rich_text_editor.md)

### GitLab Flavored Markdown 지원 {#gitlab-flavored-markdown-support}

리치 텍스트 편집기에서 모든 GitLab Flavored Markdown 콘텐츠 유형을 지원하는 것은 진행 중인 작업입니다. CommonMark 및 GitLab Flavored Markdown 지원의 진행 중인 개발 상태를 읽으려면:

- [기본 Markdown 형식 지정 확장](https://gitlab.com/groups/gitlab-org/-/epics/5404) 에픽.
- [GitLab Flavored Markdown 확장](https://gitlab.com/groups/gitlab-org/-/epics/5438) 에픽.

## 위키 이벤트 추적 {#track-wiki-events}

GitLab은 위키 생성, 삭제 및 업데이트 이벤트를 추적합니다. 이러한 이벤트는 다음 페이지에 표시됩니다:

- [사용자 프로필](../../profile/_index.md#access-your-user-profile).
- 활동 페이지, 위키 유형에 따라:
  - [그룹 활동](../../group/manage.md#view-group-activity).
  - [프로젝트 활동](../working_with_projects.md#view-project-activity).

위키로의 커밋은 [리포지토리 분석](../../analytics/repository_analytics.md)에 포함되지 않습니다.

## 문제 해결 {#troubleshooting}

### Apache 역방향 프록시를 사용한 페이지 슬러그 렌더링 {#page-slug-rendering-with-apache-reverse-proxy}

페이지 슬러그는 [`ERB::Util.url_encode`](https://www.rubydoc.info/stdlib/erb/ERB%2FUtil.url_encode) 방법을 사용하여 인코딩됩니다. Apache 역방향 프록시를 사용하는 경우 Apache 구성의 `nocanon` 라인에 `ProxyPass` 인수를 추가하여 페이지 슬러그가 올바르게 렌더링되도록 할 수 있습니다.

### Rails 콘솔로 프로젝트 위키 다시 만들기 {#recreate-a-project-wiki-with-the-rails-console}

{{< details >}}

- 계층: Free, Premium, Ultimate
- 제공 서비스:  GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

> [!warning]
> 이 작업은 위키의 모든 데이터를 삭제합니다.
>
> 데이터를 직접 변경하는 모든 커밋은 올바르게 실행되지 않거나 올바른 조건에서 실행되지 않으면 손상될 수 있습니다. 인스턴스 백업이 복원될 준비가 된 테스트 환경에서 이들을 실행하는 것이 좋습니다.

프로젝트 위키에서 모든 데이터를 지우고 공백 상태로 다시 만들려면:

1. [Rails 콘솔 세션](../../../administration/operations/rails_console.md#starting-a-rails-console-session)을 시작합니다.
1. 이 커밋을 실행합니다:

   ```ruby
   # Enter your project's path
   p = Project.find_by_full_path('<username-or-group>/<project-name>')

   # This command deletes the wiki project from the filesystem.
   p.wiki.repository.remove

   # Refresh the wiki repository state.
   p.wiki.repository.expire_exists_cache
   ```

위키의 모든 데이터가 지워졌으며 위키를 사용할 준비가 되었습니다.

## 관련 항목 {#related-topics}

- [관리자를 위한 위키 설정](../../../administration/wikis/_index.md)
- [프로젝트 위키 API](../../../api/wikis.md)
- [그룹 위키 API](../../../api/group_wikis.md)
- [그룹 리포지토리 저장소 이동 API](../../../api/group_repository_storage_moves.md)
- [위키 바로가기](../../shortcuts.md#wiki-pages)
- [GitLab Flavored Markdown](../../markdown.md)
- [AsciiDoc](../../asciidoc.md)
