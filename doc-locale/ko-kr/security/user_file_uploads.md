---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "이슈, 머지 리퀘스트, 에픽에 업로드된 파일의 액세스 제어 및 보안을 관리합니다."
title: 사용자 파일 업로드
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

사용자는 다음 위치에 파일을 업로드할 수 있습니다:

- 프로젝트의 이슈 또는 머지 리퀘스트.
- 그룹의 에픽.

GitLab은 이러한 업로드된 파일에 대해 권한이 없는 사용자가 URL을 추측하는 것을 방지하기 위해 임의의 32자 ID를 포함한 직접 URL을 생성합니다. 이러한 임의 처리는 민감한 정보가 포함된 파일에 대한 보안을 제공합니다.

사용자가 GitLab 이슈, 머지 리퀘스트, 에픽에 업로드한 파일에는 URL 경로에 `/uploads/<32-character-id>`가 포함되어 있습니다.

> [!warning]
> 특히 파일이 실행 파일이거나 스크립트인 경우, 알 수 없거나 신뢰할 수 없는 출처에서 업로드한 파일을 다운로드할 때 주의하세요.

## 업로드된 파일의 액세스 제어 {#access-control-for-uploaded-files}

다음 위치에 업로드된 이미지가 아닌 파일에 대한 액세스:

- 이슈 또는 머지 리퀘스트는 프로젝트 공개 수준에 따라 결정됩니다.
- 그룹 에픽은 그룹 공개 수준에 따라 결정됩니다.

공개 프로젝트 또는 그룹의 경우, 이슈, 머지 리퀘스트, 에픽이 기밀이더라도 누구나 직접 첨부 파일 URL을 통해 이러한 파일에 액세스할 수 있습니다. 비공개 및 내부 프로젝트의 경우, GitLab은 인증된 프로젝트 멤버만 PDF와 같은 이미지가 아닌 파일 업로드에 액세스할 수 있도록 보장합니다. 기본적으로 이미지 파일은 동일한 제한이 없으며, 누구나 URL을 사용하여 이미지 파일을 볼 수 있습니다. 이미지 파일을 보호하려면 [모든 미디어 파일에 대한 인증 확인을 활성화](#enable-authorization-checks-for-all-media-files)하여 인증된 사용자만 볼 수 있게 만드세요.

이미지에 대한 인증 확인은 알림 이메일의 본문에 표시 문제를 유발할 수 있습니다. 이메일은 GitLab으로 인증되지 않은 클라이언트(예: Outlook, Apple Mail 또는 모바일 디바이스)에서 자주 읽혀집니다. 클라이언트가 GitLab에 대해 인증되지 않은 경우, 이메일의 이미지가 손상되고 사용할 수 없게 나타납니다.

## 모든 미디어 파일에 대한 인증 확인 활성화 {#enable-authorization-checks-for-all-media-files}

인증된 프로젝트 멤버만 비공개 및 내부 프로젝트에서 이미지가 아닌 첨부 파일(PDF 포함)을 볼 수 있습니다.

비공개 또는 내부 프로젝트의 이미지 파일에 인증 요구 사항을 적용하려면:

전제 조건:

- 프로젝트에 대해 Maintainer 또는 Owner 역할이 필요합니다.
- 프로젝트 공개 수준 설정은 **비공개** 또는 **내부**여야 합니다.

모든 미디어 파일에 대한 인증 설정을 구성하려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **일반**을 선택합니다.
1. **표시 여부, 프로젝트 기능, 권한**을 확장합니다.
1. **프로젝트 공개 수준**으로 스크롤하고 **미디어 파일을 보려면 인증 필요**를 선택하세요.

> [!note]
> 공개 프로젝트의 경우 이 옵션을 선택할 수 없습니다.

## 업로드된 파일 삭제 {#delete-uploaded-files}

{{< history >}}

- REST API가 [추가되어](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/157066) GitLab 17.2에서 지원됩니다.

{{< /history >}}

업로드된 파일이 민감하거나 기밀 정보를 포함할 때 파일을 삭제해야 합니다. 파일을 삭제하면 사용자는 파일에 액세스할 수 없으며 직접 URL은 404 오류를 반환합니다.

프로젝트 소유자 및 유지보수자는 [대화형 GraphQL 탐색기](../api/graphql/_index.md#interactive-graphql-explorer)를 사용하여 [GraphQL 엔드포인트](../api/graphql/reference/_index.md#mutationuploaddelete)에 액세스하고 업로드된 파일을 삭제할 수 있습니다.

예를 들어:

```graphql
mutation{
  uploadDelete(input: { projectPath: "<path/to/project>", secret: "<32-character-id>" , filename: "<filename>" }) {
    upload {
      id
      size
      path
    }
    errors
  }
}
```

유지보수자 또는 소유자 역할이 없는 프로젝트 멤버는 이 GraphQL 엔드포인트에 액세스할 수 없습니다.

REST API를 [프로젝트](../api/project_markdown_uploads.md#delete-an-uploaded-file-by-secret-and-filename) 또는 [그룹](../api/group_markdown_uploads.md#delete-an-uploaded-file-by-secret-and-filename)에 사용하여 업로드된 파일을 삭제할 수도 있습니다.
