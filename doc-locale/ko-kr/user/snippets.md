---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "브라우저에서 코드, 텍스트, 파일을 저장하고 공유하려면 스니펫을 사용합니다. 스니펫은 버전 관리, 댓글 달기 및 임베드를 지원합니다."
title: 스니펫
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab 스니펫을 사용하면 코드와 텍스트를 다른 사용자와 저장하고 공유할 수 있습니다. 스니펫에서 [댓글을 달고](#comment-on-snippets), [복제하며](#clone-snippets), [버전 관리를 사용](#versioned-snippets)할 수 있습니다. [여러 파일을 포함할 수](#add-or-remove-multiple-files) 있습니다. [구문 강조](#filenames), [임베드](#embed-snippets), [다운로드](#download-snippets)도 지원하며, [스니펫 API](../api/snippets.md)를 통해 스니펫을 유지 관리할 수 있습니다.

다음을 사용하여 스니펫을 만들고 관리할 수 있습니다:

- GitLab 사용자 인터페이스입니다.
- [GitLab for VS Code 확장](../editor_extensions/visual_studio_code/projects.md#create-a-snippet)입니다.
- [`glab` CLI](../editor_extensions/gitlab_cli/_index.md)입니다.

![GitLab의 샘플 콘텐츠를 표시하는 코드 스니펫입니다.](img/snippet_sample_v16_6.png)

GitLab은 두 가지 유형의 스니펫을 제공합니다:

- 개인 스니펫: 모든 프로젝트와 독립적입니다. [표시 여부](public_access.md)를 공개 또는 비공개로 설정할 수 있습니다.
- 프로젝트 스니펫: 특정 프로젝트와 연관됩니다. 표시 여부를 공개 또는 프로젝트 멤버만 볼 수 있도록 설정할 수 있습니다.

GitLab.com에서 그룹 소유자는 [개인 스니펫 생성을 제한](group/manage.md#restrict-personal-snippets-for-enterprise-users)할 수 있으며 [엔터프라이즈 사용자](enterprise_user/_index.md)에게 적용됩니다.

## 스니펫 표시 여부 {#snippet-visibility}

프로젝트 스니펫의 경우 프로젝트의 표시 여부가 항상 스니펫의 표시 여부 설정보다 우선합니다. 공개로 표시된 스니펫은 이미 프로젝트에 액세스할 수 없는 사람은 액세스할 수 없습니다.

| 프로젝트 가시성 | 공개 스니펫에 액세스할 수 있는 사용자 | 비공개 스니펫에 액세스할 수 있는 사용자 |
|--------------------|-------------------------------|--------------------------------|
| 비공개            | 프로젝트 멤버만          | 프로젝트 멤버만           |
| 내부           | 인증된 사용자(외부 사용자 제외) | 프로젝트 멤버만 |
| 공개             | 모두                      | 프로젝트 멤버만           |

> [!note]
> GitLab.com에서 `Internal` 표시 여부 설정은 새로운 프로젝트, 그룹, 스니펫에 대해 비활성화됩니다. `Internal` 표시 여부 설정을 사용하는 기존 스니펫은 이 설정을 유지합니다. 자세한 내용은 [이슈 12388](https://gitlab.com/gitlab-org/gitlab/-/issues/12388)을 참조하세요.

개인 스니펫의 경우 스니펫의 표시 여부 설정이 액세스를 직접 제어합니다:

- **공개**: 누구든지 인증 없이 스니펫에 액세스할 수 있습니다.
- **비공개**: 오직 당신만 스니펫에 액세스할 수 있습니다.

## 스니펫 만들기 {#create-snippets}

개인 스니펫 또는 프로젝트 스니펫을 만들고 싶은지 여부에 따라 여러 방법으로 스니펫을 만들 수 있습니다:

1. 만들려는 스니펫의 종류를 선택합니다:
   - 개인 스니펫을 만들려면 다음 중 하나를 수행합니다:
     - [스니펫 대시보드](https://gitlab.com/dashboard/snippets)에서 **새 스니펫**을 선택합니다.
     - 프로젝트에서: 왼쪽 사이드바에서 **새로 만들기** ({{< icon name="plus" >}})를 선택합니다. **GitLab 에서** 아래에서 **새 스니펫**을 선택합니다.
     - 다른 모든 페이지에서: 오른쪽 위 모서리에서 **새로 만들기** ({{< icon name="plus" >}}) 를 선택한 다음 **새 스니펫**을 선택합니다.
     - `glab` CLI에서 [`glab snippet create`](https://gitlab.com/gitlab-org/cli/-/blob/main/docs/source/snippet/create.md) 명령을 사용합니다. 전체 지침은 명령의 설명서를 참조하세요.
     - [GitLab for VS Code 확장](../editor_extensions/visual_studio_code/_index.md)을 설치한 경우 [`Gitlab: Create snippet` 명령](https://marketplace.visualstudio.com/items?itemName=GitLab.gitlab-workflow#create-snippet)을 사용합니다.
   - 프로젝트 스니펫을 만들려면: 프로젝트의 페이지로 이동합니다. **새로 만들기** ({{< icon name="plus" >}})를 선택합니다. **이 프로젝트에서** 아래에서 **새 스니펫**을 선택합니다.
1. **제목**에 제목을 추가합니다.
1. 선택 사항입니다. **설명**에 스니펫을 설명합니다.
1. **파일**에서 파일에 `example.rb` 또는 `index.html`와 같은 적절한 이름과 확장자를 지정합니다. 적절한 확장자가 있는 파일명은 [구문 강조](#filenames)를 표시합니다. 파일명을 추가하지 않으면 알려진 [복사 붙여넣기 버그](https://gitlab.com/gitlab-org/gitlab/-/issues/22870)가 발생할 수 있습니다. 파일명을 제공하지 않으면 GitLab이 [자동으로 이름을 만듭니다](#filenames).
1. 선택 사항입니다. 스니펫에 [여러 파일](#add-or-remove-multiple-files)을 추가합니다.
1. 표시 여부 수준을 선택하고 **스니펫 만들기**를 선택합니다.

프로젝트 스니펫의 경우 프로젝트의 표시 여부가 외부 경계로 작동합니다. 자세한 내용은 [스니펫 표시 여부](#snippet-visibility)를 참조하세요.

스니펫을 만든 후에도 [파일을 더 추가](#add-or-remove-multiple-files)할 수 있습니다. 스니펫은 [기본적으로 버전 관리됩니다](#versioned-snippets).

## 스니펫 검색 {#discover-snippets}

GitLab에서 자신에게 보이는 모든 스니펫을 검색하려면 다음을 수행합니다:

- 프로젝트의 스니펫 보기:
  1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
  1. 왼쪽 사이드바에서 **코드** > **스니펫**을 선택합니다.
- 만든 모든 스니펫 보기:
  1. 상단 표시줄에서 **검색 또는 이동**을 선택합니다.
  1. **귀하의 작업**을 선택합니다.
  1. **스니펫**을 선택합니다.

  GitLab.com에서는 [스니펫에 직접 액세스](https://gitlab.com/dashboard/snippets)할 수도 있습니다.

- 모든 공개 스니펫 탐색:
  1. 상단 표시줄에서 **검색 또는 이동**을 선택합니다.
  1. **탐색**을 선택합니다.
  1. **스니펫**을 선택합니다.

  GitLab.com에서는 [모든 공개 스니펫에 직접 액세스](https://gitlab.com/explore/snippets)할 수도 있습니다.

## 스니펫의 기본 표시 여부 변경 {#change-default-visibility-of-snippets}

프로젝트 스니펫은 기본적으로 활성화되고 사용 가능합니다. 기본 표시 여부를 변경하려면:

1. 프로젝트에서 **설정** > **일반**으로 이동합니다.
1. **표시 여부, 프로젝트 기능, 권한** 섹션을 펼친 후 **스니펫**까지 스크롤합니다.
1. 기본 표시 여부를 전환하고 스니펫을 모든 사람이 볼 수 있는지 또는 프로젝트 멤버만 볼 수 있는지 선택합니다.
1. **변경 사항 저장**을 선택합니다.

## 버전 관리되는 스니펫 {#versioned-snippets}

개인 및 프로젝트 스니펫은 기본적으로 버전 관리를 사용합니다.

이는 모든 스니펫이 생성되는 순간 기본 브랜치로 초기화된 자체 기본 리포지토리를 가져옵니다. 스니펫에 대한 변경 사항이 저장될 때마다 기본 브랜치에 대한 새 커밋이 기록됩니다. 커밋 메시지는 자동으로 생성됩니다. 스니펫의 리포지토리에는 오직 하나의 브랜치만 있습니다. 이 브랜치를 삭제하거나 다른 브랜치를 만들 수 없습니다.

## 파일명 {#filenames}

스니펫은 제공된 파일명 및 확장자에 따라 구문 강조를 지원합니다. 파일명과 확장자 없이 스니펫을 제출할 수 있지만 리포지토리에 파일로 콘텐츠를 만들려면 유효한 이름이 필요합니다.

스니펫에 대해 파일명과 확장자가 제공되지 않으면 GitLab은 `snippetfile<x>.txt` 형식의 파일명을 추가하며 여기서 `<x>`는 1부터 시작하여 파일에 추가된 번호를 나타냅니다. 이름 없는 스니펫을 더 추가하면 이 번호가 증가합니다.

GitLab의 이전 버전에서 13.0으로 업그레이드할 때 지원되는 파일명이 없는 기존 스니펫의 이름이 호환되는 형식으로 변경됩니다. 예를 들어 스니펫의 파일명이 `http://a-weird-filename.me`이면 스니펫의 리포지토리에 포함시키기 위해 `http-a-weird-filename-me`로 변경됩니다. 스니펫은 ID로 저장되므로 파일명을 변경하면 스니펫의 직접 링크 또는 임베드 링크가 끊어집니다.

## 마크다운 파일 미리보기 {#preview-markdown-files}

{{< history >}}

- GitLab 19.4에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/246399)되었습니다.

{{< /history >}}

스니펫을 만들거나 편집할 때 마크다운 파일의 실시간 미리보기를 볼 수 있습니다.

스니펫에서 마크다운 파일을 미리보려면:

1. 스니펫을 만들거나 기존 스니펫으로 이동한 후 **편집**을 선택합니다.
1. 파일에 `example.md`과 같은 마크다운 파일명을 지정합니다.
1. 파일 편집기에서 오른쪽 클릭을 한 후 **마크다운 미리보기**를 선택합니다.

미리보기가 콘텐츠 옆에 표시되며 입력할 때 업데이트됩니다. 미리보기를 닫으려면 편집기에서 오른쪽 클릭을 한 후 **실시간 미리보기 숨기기**를 선택합니다.

## 여러 파일 추가 또는 제거 {#add-or-remove-multiple-files}

단일 스니펫은 최대 10개의 파일을 지원하므로 관련 파일을 함께 유지할 수 있습니다:

- 스크립트와 출력을 포함하는 스니펫입니다.
- HTML, CSS, 자바스크립트 코드를 포함하는 스니펫입니다.
- `docker-compose.yml` 파일과 관련 `.env` 파일을 포함하는 스니펫입니다.
- `gulpfile.js` 파일과 `package.json` 파일로, 함께 프로젝트를 부트스트랩하고 종속성을 관리하는 데 사용될 수 있습니다.

스니펫에 10개 이상의 파일이 필요하면 대신 [위키](project/wiki/_index.md)를 만들어야 합니다. 위키는 모든 구독 수준의 프로젝트에서 사용할 수 있으며 [Premium](https://about.gitlab.com/pricing/)에서 [그룹](project/wiki/group.md)에서 사용할 수 있습니다.

여러 파일이 있는 스니펫은 [스니펫 목록](https://gitlab.com/dashboard/snippets)에 파일 개수를 표시합니다:

![GitLab 스니펫의 세부정보를 표시하는 도구팁입니다.](img/snippet_tooltip_v17_4.png)

Git을 사용하여 스니펫을 관리할 수 있습니다 ([버전 관리됨](#versioned-snippets) Git 리포지토리로), [스니펫 API](../api/snippets.md)를 통해, 그리고 GitLab UI에서입니다.

GitLab UI를 통해 스니펫에 새 파일을 추가하려면:

1. GitLab UI에서 스니펫으로 이동합니다.
1. 오른쪽 위 모서리에서 **편집**을 선택합니다.
1. **다른 파일 추가**를 선택합니다.
1. 제공된 양식 필드에 파일의 콘텐츠를 추가합니다.
1. **변경 사항 저장**을 선택합니다.

GitLab UI를 통해 스니펫에서 파일을 삭제하려면:

1. GitLab UI에서 스니펫으로 이동합니다.
1. 오른쪽 위 모서리에서 **편집**을 선택합니다.
1. 삭제하려는 각 파일의 파일명 옆에서 **파일 삭제**를 선택합니다.
1. **변경 사항 저장**을 선택합니다.

## 스니펫 복제 {#clone-snippets}

업데이트를 받으려면 스니펫을 복제하고 로컬로 복사하지 마세요. 복제하면 스니펫과 리포지토리의 연결이 유지됩니다.

스니펫을 복제하려면:

- **복제**를 선택한 다음 SSH 또는 HTTPS로 복제할 URL을 복사합니다.

복제된 스니펫에 변경 사항을 커밋하고 변경 사항을 GitLab으로 푸시할 수 있습니다.

## 스니펫 임베드 {#embed-snippets}

공개 스니펫은 어떤 웹 사이트에도 공유하고 임베드할 수 있습니다. GitLab 스니펫을 여러 위치에서 재사용할 수 있으며 소스의 모든 변경 사항이 임베드된 스니펫에 반영됩니다. 임베드되면 사용자가 다운로드하거나 스니펫을 원시 형식으로 볼 수 있습니다.

스니펫을 임베드하려면:

1. 스니펫이 공개적으로 표시되는지 확인합니다:
   - 프로젝트 스니펫의 경우:
     1. 프로젝트와 스니펫 모두 공개여야 합니다. 비공개 또는 내부 프로젝트의 공개 스니펫은 임베드할 수 없습니다.
     1. 프로젝트에서 **설정** > **일반**으로 이동합니다. **표시 여부, 프로젝트 기능, 권한** 섹션을 펼친 후 **스니펫**까지 스크롤합니다. 스니펫 권한을 **모든 사용자가 액세스 가능**으로 설정합니다.
   - 개인 스니펫의 경우:
     1. 스니펫으로 이동합니다.
     1. **편집**을 선택합니다.
     1. 표시 여부를 **공개**로 설정하고 **변경사항 저장**을 선택합니다.
1. 스니펫의 **임베드** 섹션에서 **복사**를 선택하여 웹 사이트 또는 블로그 게시물에 추가할 수 있는 한 줄 스크립트를 복사합니다. 예를 들어:

   ```html
   <script src="https://gitlab.com/namespace/project/snippets/SNIPPET_ID.js"></script>
   ```

1. 스크립트를 파일에 추가합니다.

임베드된 스니펫은 다음을 표시하는 헤더를 표시합니다:

- 파일명(정의된 경우).
- 스니펫 크기입니다.
- GitLab으로의 링크입니다.
- 실제 스니펫 콘텐츠입니다.

예를 들어:

<script src="https://gitlab.com/gitlab-org/gitlab-foss/snippets/1717978.js"></script>

## 스니펫 다운로드 {#download-snippets}

스니펫의 원시 콘텐츠를 다운로드할 수 있습니다. 기본적으로 Linux 스타일 줄 끝 (`LF`)으로 다운로드됩니다. 원본 줄 끝을 유지하려면 `line_ending=raw` 매개변수를 추가해야 합니다 (예: `https://gitlab.com/snippets/SNIPPET_ID/raw?line_ending=raw`). GitLab 웹 인터페이스를 사용하여 스니펫을 만든 경우 원본 줄 끝은 Windows 스타일 (`CRLF`)입니다.

## 스니펫에 댓글 달기 {#comment-on-snippets}

스니펫을 사용하면 그 코드에 대해 대화를 나누고 사용자 협업을 장려할 수 있습니다.

## 스니펫을 스팸으로 표시 {#mark-snippet-as-spam}

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab Self-Managed의 관리자는 스니펫을 스팸으로 표시할 수 있습니다.

사전 요구 사항:

- 인스턴스의 관리자여야 합니다.
- [Akismet](../integration/akismet.md) 스팸 보호가 인스턴스에서 활성화되어야 합니다.

이 작업을 수행하려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **코드** > **스니펫**을 선택합니다.
1. 스팸으로 보고하려는 스니펫을 선택합니다.
1. **스팸으로 제출**을 선택합니다.

GitLab은 스팸을 Akismet으로 전달합니다.

## 문제 해결 {#troubleshooting}

### 스니펫 제한 {#snippet-limitations}

- 만들 수 있는 스니펫의 개수에 제한이 없습니다.
- 브랜치 생성 또는 삭제는 지원되지 않습니다. 기본 브랜치만 사용됩니다.
- Git 태그는 스니펫 리포지토리에서 지원되지 않습니다.
- 스니펫의 리포지토리는 10개 파일로 제한됩니다. 10개를 초과하는 파일을 푸시하면 오류가 발생합니다.
- GitLab UI에서 리비전은 사용자에게 표시되지 않지만 [이슈 39271](https://gitlab.com/gitlab-org/gitlab/-/issues/39271)에서 업데이트를 제안합니다.
- 스니펫의 기본 [최대 크기](../administration/snippets/_index.md)는 현재(2024-04-17 기준) 50MB입니다.
- Git LFS는 지원되지 않습니다.

### 스니펫 리포지토리 크기 줄이기 {#reduce-snippets-repository-size}

버전 관리되는 스니펫은 [네임스페이스 저장소 크기](../administration/settings/account_and_limit_settings.md)의 일부로 간주되므로 스니펫의 리포지토리를 가능한 한 압축된 상태로 유지하는 것이 좋습니다.

리포지토리 압축 도구에 대한 자세한 내용은 [리포지토리 크기 줄이기](project/repository/repository_size.md#methods-to-reduce-repository-size)에 대한 설명서를 참조하세요.

### 스니펫 텍스트 상자에 텍스트를 입력할 수 없음 {#cannot-enter-text-into-the-snippet-text-box}

파일명 필드 후의 텍스트 영역이 비활성화되어 새 스니펫을 만들 수 없으면 다음 해결 방법을 사용합니다:

1. 스니펫의 제목을 입력합니다.
1. **파일** 필드의 하단으로 스크롤한 다음 **다른 파일 추가**를 선택합니다. GitLab은 두 번째 파일을 추가할 두 번째 필드 집합을 표시합니다.
1. 두 번째 파일의 파일명 필드에 [이슈 22870](https://gitlab.com/gitlab-org/gitlab/-/issues/22870)을 방지하기 위해 파일명을 입력합니다.
1. 두 번째 파일의 텍스트 영역에 문자열을 입력합니다.
1. 첫 번째 파일명으로 스크롤 백하고 **파일 삭제**를 선택합니다.
1. 나머지 파일을 만든 후 완료되면 **스니펫 만들기**를 선택합니다.

## 관련 항목 {#related-topics}

- [스니펫 설정 구성](../administration/snippets/_index.md) (GitLab Self-Managed)
