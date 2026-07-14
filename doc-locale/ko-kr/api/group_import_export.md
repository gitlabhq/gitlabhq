---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 그룹 가져오기 및 내보내기 
description: "로 그룹을 가져오고 내보냅니다."
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 를 사용하여 [그룹 구조를 마이그레이션](../user/group/import/_index.md)할 수 있습니다. 이 를 [프로젝트 가져오기 및 내보내기](project_import_export.md)와 함께 사용하면 프로젝트 이슈와 그룹 에픽 간의 연결 같은 그룹 수준의 관계를 보존할 수 있습니다.

그룹 내보내기에는 다음이 포함됩니다:

- 그룹 마일스톤
- 그룹 보드
- 그룹 레이블
- 그룹 배지
- 그룹 구성원
- 그룹 이벤트
- 그룹 위키(Premium 및 Ultimate만 해당)
- 하위 그룹. 각 하위 그룹은 목록의 모든 이전 데이터를 포함합니다.

가져온 프로젝트의 그룹 수준 관계를 보존하려면 먼저 그룹 내보내기 및 가져오기를 실행해야 합니다. 이렇게 하면 프로젝트 내보내기를 원하는 그룹 구조로 가져올 수 있습니다.

[이슈 405168](https://gitlab.com/gitlab-org/gitlab/-/issues/405168) 때문에 가져온 그룹은 부모 그룹으로 가져오지 않는 한 `private` 가시성 수준을 갖습니다. 기본적으로 그룹을 부모 그룹으로 가져오면 하위 그룹은 부모와 동일한 수준의 가시성을 상속합니다.

가져온 그룹의 구성원 목록 및 해당 권한을 보존하려면 이러한 그룹의 사용자를 검토하세요. 원하는 그룹을 가져오기 전에 이러한 사용자가 존재하는지 확인하세요.

## 그룹 내보내기 만들기 {#create-a-group-export}

지정된 그룹에 대한 그룹 내보내기를 만듭니다.

```plaintext
POST /groups/:id/export
```

| 속성 | 유형              | 필수 | 설명 |
| --------- | ----------------- | -------- | ----------- |
| `id`      | 정수 또는 문자열 | 예      | 그룹의 ID입니다. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/export"
```

```json
{
  "message": "202 Accepted"
}
```

## 그룹 내보내기 다운로드 검색 {#retrieve-a-group-export-download}

지정된 그룹의 내보낸 아카이브를 검색합니다.

```plaintext
GET /groups/:id/export/download
```

| 속성 | 유형              | 필수 | 설명 |
| --------- | ----------------- | -------- | ----------- |
| `id`      | 정수 또는 문자열 | 예      | 그룹의 ID입니다. |

```shell
group=1
token=secret

curl --request GET \
  --header "PRIVATE-TOKEN: ${token}" \
  --output download_group_${group}.tar.gz \
  --url "https://gitlab.example.com/api/v4/groups/${group}/export/download"
```

```shell
ls *export.tar.gz
2020-12-05_22-11-148_namespace_export.tar.gz
```

그룹을 내보내는 데 소요되는 시간은 그룹의 크기에 따라 달라질 수 있습니다. 이 엔드포인트는 다음 중 하나를 반환합니다:

- 내보낸 아카이브(사용 가능한 경우)
- 404 메시지

## 그룹 가져오기 만들기 {#create-a-group-import}

파일을 업로드하여 그룹 가져오기를 만듭니다.

최대 가져오기 파일 크기는 GitLab Self-Managed의 관리자가 설정할 수 있습니다(기본값은 `0` (무제한)입니다). 관리자는 다음 중 하나의 방법으로 최대 가져오기 파일 크기를 수정할 수 있습니다:

- [**운영자** 영역](../administration/settings/import_and_export_settings.md)에서.
- [애플리케이션 설정](settings.md#update-application-settings)의 `max_import_size` 옵션을 사용합니다.

GitLab.com의 최대 가져오기 파일 크기에 대한 자세한 내용은 [계정 및 제한 설정](../user/gitlab_com/_index.md#account-and-limit-settings)을 참조하세요.

```plaintext
POST /groups/import
```

| 속성   | 유형           | 필수 | 설명 |
| ----------- | -------------- | -------- | ----------- |
| `file`      | 문자열         | 예      | 업로드할 파일입니다. |
| `name`      | 문자열         | 예      | 가져올 그룹의 이름입니다. |
| `path`      | 문자열         | 예      | 새 그룹의 이름 및 경로입니다. |
| `parent_id` | 정수        | 아니요       | 그룹을 가져올 부모 그룹의 ID입니다. 제공되지 않으면 현재 사용자의 네임스페이스로 기본 설정됩니다. |

파일 시스템에서 파일을 업로드하려면 `--form` 인수를 사용하세요. 이렇게 하면 cURL이 `Content-Type: multipart/form-data` 헤더를 사용하여 데이터를 게시합니다. `file=` 매개변수는 파일 시스템의 파일을 가리켜야 하며 `@`로 시작해야 합니다. 예를 들어:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --form "name=imported-group" \
  --form "path=imported-group" \
  --form "file=@/path/to/file" \
  --url "https://gitlab.example.com/api/v4/groups/import"
```

## 관련 항목 {#related-topics}

- [프로젝트 가져오기 및 내보내기](project_import_export.md)
