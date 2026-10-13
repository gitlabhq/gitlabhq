---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Git 파일 blame에 대한 설명서입니다.
title: Git 파일 blame
---

{{< details >}}

- 계층: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

[Git blame](https://git-scm.com/docs/git-blame)는 마지막 수정 시간, 작성자 및 커밋 해시를 포함하여 파일의 모든 줄에 대한 자세한 정보를 제공합니다.

## 파일의 blame 보기 {#view-blame-for-a-file}

{{< history >}}

- 파일 보기에서 blame을 직접 보는 기능이 GitLab 16.7에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/430950)되었으며 [플래그](../../../../administration/feature_flags/_index.md) `inline_blame` 이름으로 제공됩니다. 기본적으로 비활성화되어 있습니다.
- [GitLab.com, GitLab Self-Managed 및 GitLab Dedicated에서 활성화됨](https://gitlab.com/gitlab-org/gitlab/-/issues/501539)(GitLab 19.1)

{{< /history >}}

전제 조건:

- 파일에는 읽을 수 있는 텍스트 콘텐츠가 포함되어야 합니다. GitLab UI는 `git blame` 결과를 `.rb`, `.js`, `.md`, `.txt`, `.yml` 등 텍스트 파일 형식으로 표시합니다. 이미지 및 PDF와 같은 바이너리 파일은 지원되지 않습니다.

파일의 blame을 보려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **코드** > **리포지토리**를 선택합니다.
1. 검토할 파일을 선택합니다.
1. 다음 중 하나를 선택합니다:
   - 현재 파일의 보기를 변경하려면 파일 헤더에서 **Blame**을 선택합니다.
   - 전체 blame 페이지를 열려면 오른쪽 위 모서리에서 **Blame**을 선택합니다.
1. 보고 싶은 줄로 이동합니다.

**Blame**을 선택하면 다음 정보가 표시됩니다:

![Git blame 출력](img/file_blame_output_v18_11.png "Blame 버튼 출력")

커밋의 정확한 날짜와 시간을 보려면 날짜 위에 마우스를 올립니다. 커밋 나이에 대한 색상 범례를 표시하려면 [연령 표시 범례 보기](#show-age-indicator-legend)을 참조하세요.

### 이전 커밋을 blame 보기 {#blame-previous-commit}

특정 줄의 이전 리비전을 보려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **코드** > **리포지토리**를 선택합니다.
1. 검토할 파일을 선택합니다.
1. 오른쪽 위 모서리에서 **Blame**을 선택하고 보고 싶은 줄로 이동합니다.
1. **이 변경 이전의 blame 보기**({{< icon name="doc-versions" >}})를 선택하여 보고 싶은 변경 사항을 찾을 때까지 반복합니다.

### 특정 리비전 무시 {#ignore-specific-revisions}

{{< history >}}

- GitLab 17.10에서 `blame_ignore_revs` [플래그](../../../../administration/feature_flags/_index.md)로 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/514684)되었습니다. 기본적으로 비활성화되어 있습니다.
- [GitLab.com, GitLab Self-Managed 및 GitLab Dedicated에서 활성화됨](https://gitlab.com/gitlab-org/gitlab/-/issues/514325)(GitLab 17.10)
- [일반 공급](https://gitlab.com/gitlab-org/gitlab/-/issues/525095)(GitLab 17.11) 기능 플래그 `blame_ignore_revs`이 제거되었습니다.

{{< /history >}}

Git blame을 특정 리비전을 무시하도록 구성하려면:

1. 리포지토리의 루트에 `.git-blame-ignore-revs` 파일을 만듭니다.
1. 무시할 커밋 해시를 한 줄에 하나씩 추가합니다. 예를 들어:

   ```plaintext
   a24cb33c0e1390b0719e9d9a4a4fc0e4a3a069cc
   676c1c7e8b9e2c9c93e4d5266c6f3a50ad602a4c
   ```

1. blame 보기에서 파일을 엽니다.
1. **Blame 환경설정**({{< icon name="preferences" >}})을 선택합니다.
1. **특정 리비전을 무시** 체크박스를 선택합니다.

blame 보기가 새로 고쳐지고 `.git-blame-ignore-revs` 파일에 지정된 리비전을 건너뛰며 이전의 의미 있는 변경 사항을 대신 표시합니다.

### 연령 표시 범례 보기 {#show-age-indicator-legend}

{{< history >}}

- GitLab 18.11에 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/589722).

{{< /history >}}

인라인 blame 보기에서 연령 표시 범례를 표시하거나 숨길 수 있습니다. 범례는 **더 최신**에서 **더 이전**까지의 색상 척도를 표시하여 각 커밋의 나이를 해석하는 데 도움을 줍니다.

연령 표시 범례를 표시하거나 숨기려면:

1. blame 보기에서 파일을 엽니다.
1. **Blame 환경설정**({{< icon name="preferences" >}})을 선택합니다.
1. **연령 표시 범례 보기** 체크박스를 선택하거나 선택 취소합니다.

## 관련 항목 {#related-topics}

- [Git 파일 blame REST API](../../../../api/repository_files.md#retrieve-file-blame-history-from-a-repository)
- [일반 Git 명령](../../../../topics/git/commands.md)
- [Git을 사용한 파일 관리](../../../../topics/git/file_management.md)
- [파일 트리 브라우저](file_tree_browser.md)
