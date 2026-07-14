---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 프로젝트 가져오기 및 내보내기 API
description: "REST API를 사용하여 프로젝트를 가져오고 내보냅니다."
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 [프로젝트를 마이그레이션합니다](../user/project/settings/import_export.md). [그룹 가져오기 및 내보내기 API](group_import_export.md) 를 사용하여 먼저 부모 그룹 구조를 마이그레이션하면 프로젝트 이슈와 그룹 에픽 간의 연결과 같은 그룹 수준의 관계를 보존할 수 있습니다.

이 API를 사용한 후 [프로젝트 수준 CI/CD 변수 API](project_level_variables.md)를 사용하여 프로젝트의 CI/CD 변수를 보존하는 것이 좋습니다.

여전히 [컨테이너 레지스트리](../user/packages/container_registry/_index.md)를 일련의 Docker 끌어오기 및 푸시를 통해 마이그레이션해야 합니다. 모든 CI/CD 파이프라인을 다시 실행하여 빌드 아티팩트를 검색합니다.

전제 조건:

- 프로젝트 내보내기는 [프로젝트 및 해당 데이터 내보내기](../user/project/settings/import_export.md#export-a-project-and-its-data)를 참조하세요.
- 프로젝트 가져오기는 [프로젝트 및 해당 데이터 가져오기](../user/project/settings/import_export.md#import-a-project-and-its-data)를 참조하세요.

## 프로젝트 내보내기 {#export-a-project}

지정된 프로젝트를 내보냅니다.

`upload` 해시 매개변수를 사용하여 내보낸 프로젝트를 웹 서버 또는 S3 호환 플랫폼으로 업로드합니다. 내보내기의 경우 GitLab은 다음과 같이 동작합니다:

- 최종 서버에만 바이너리 데이터 파일 업로드를 지원합니다.
- 업로드 요청과 함께 `Content-Type: application/gzip` 헤더를 전송합니다. 서명의 일부로 사전 서명된 URL에 이를 포함하는지 확인하세요.
- 프로젝트 내보내기 프로세스를 완료하는 데 시간이 걸릴 수 있습니다. 업로드 URL이 짧은 만료 시간을 갖지 않으며 내보내기 프로세스 전체에서 사용 가능한지 확인하세요.
- 관리자는 최대 내보내기 파일 크기를 수정할 수 있습니다. 기본적으로 최대값은 무제한(`0`)입니다. 이를 변경하려면 다음 중 하나를 사용하여 `max_export_size`을(를) 편집하세요:
  - [GitLab UI](../administration/settings/import_and_export_settings.md).
  - [애플리케이션 설정 API](settings.md#update-application-settings)
- GitLab.com의 최대 가져오기 파일 크기에 대한 고정 제한이 있습니다. 자세한 내용은 [계정 및 제한 설정](../user/gitlab_com/_index.md#account-and-limit-settings)을(를) 참조하세요.

`upload[url]` 매개변수가 필요한 경우 `upload` 매개변수가 있어야 합니다.

Amazon S3으로 업로드하려면 [객체 업로드를 위한 사전 서명된 URL 생성](https://docs.aws.amazon.com/AmazonS3/latest/userguide/PresignedUrlUploadObject.html) 설명서 스크립트를 참조하여 `upload[url]`을(를) 생성하세요. [알려진 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/430277) 때문에 Amazon S3에 최대 파일 크기 5GB의 파일만 업로드할 수 있습니다.

```plaintext
POST /projects/:id/export
```

| 속성             | 유형              | 필수 | 설명 |
|-----------------------|-------------------|----------|-------------|
| `id`                  | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `upload[url]`         | 문자열            | 예      | 프로젝트를 업로드할 URL입니다. |
| `description`         | 문자열            | 아니요       | 프로젝트 설명을 재정의합니다. |
| `upload`              | 해시              | 아니요       | 내보낸 프로젝트를 웹 서버로 업로드하기 위한 정보를 포함하는 해시입니다. |
| `upload[http_method]` | 문자열            | 아니요       | 내보낸 프로젝트를 업로드할 HTTP 메서드입니다. `PUT` 및 `POST` 메서드만 허용됩니다. 기본값은 `PUT`입니다. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/export" \
  --data "upload[http_method]=PUT" \
  --data-urlencode "upload[url]=https://example-bucket.s3.eu-west-3.amazonaws.com/backup?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=<your_access_token>%2F20180312%2Feu-west-3%2Fs3%2Faws4_request&X-Amz-Date=20180312T110328Z&X-Amz-Expires=900&X-Amz-SignedHeaders=host&X-Amz-Signature=8413facb20ff33a49a147a0b4abcff4c8487cc33ee1f7e450c46e8f695569dbd"
```

```json
{
  "message": "202 Accepted"
}
```

## 프로젝트 내보내기 상태 검색 {#retrieve-the-status-of-a-project-export}

지정된 프로젝트의 가장 최근 내보내기 상태를 검색합니다.

```plaintext
GET /projects/:id/export
```

| 속성 | 유형              | 필수 | 설명 |
|-----------|-------------------|----------|-------------|
| `id`      | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/export"
```

상태는 다음 중 하나일 수 있습니다:

- `none`:  대기 중, 시작됨, 완료됨 또는 재생성 중인 내보내기가 없습니다.
- `queued`:  내보내기 요청이 수신되어 처리 대기열에 있습니다.
- `started`:  내보내기 프로세스가 시작되어 진행 중입니다. 다음을 포함합니다:
  - 내보내기 프로세스입니다.
  - 결과 파일에 대해 수행되는 작업(사용자에게 파일을 다운로드하도록 알려주는 이메일 전송 또는 내보낸 파일을 웹 서버로 업로드 등)입니다.
- `finished`:  내보내기 프로세스가 완료되고 사용자에게 알림이 전송된 후입니다.
- `regeneration_in_progress`:  내보내기 파일을 다운로드할 수 있으며 새 내보내기를 생성하는 요청이 진행 중입니다.

`_links`은(는) 내보내기가 완료된 경우에만 표시됩니다.

`created_at`은(는) 내보내기 시작 시간이 아닌 프로젝트 생성 타임스탬프입니다.

```json
{
  "id": 1,
  "description": "Itaque perspiciatis minima aspernatur corporis consequatur.",
  "name": "Gitlab Test",
  "name_with_namespace": "Gitlab Org / Gitlab Test",
  "path": "gitlab-test",
  "path_with_namespace": "gitlab-org/gitlab-test",
  "created_at": "2017-08-29T04:36:44.383Z",
  "export_status": "finished",
  "_links": {
    "api_url": "https://gitlab.example.com/api/v4/projects/1/export/download",
    "web_url": "https://gitlab.example.com/gitlab-org/gitlab-test/download_export"
  }
}
```

## 프로젝트 내보내기 다운로드 {#download-a-project-export}

지정된 프로젝트의 가장 최근 내보내기를 다운로드합니다.

```plaintext
GET /projects/:id/export/download
```

| 속성 | 유형              | 필수 | 설명                              |
| --------- | ----------------- | -------- | ---------------------------------------- |
| `id`      | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --remote-header-name \
  --remote-name \
  --url "https://gitlab.example.com/api/v4/projects/5/export/download"
```

```shell
ls *export.tar.gz
2017-12-05_22-11-148_namespace_project_export.tar.gz
```

## 로컬 아카이브에서 프로젝트 가져오기 {#import-a-project-from-a-local-archive}

{{< history >}}

- GitLab 16.0에서 개발자 역할 대신 유지 관리자 역할에 대한 요구 사항이 도입되었습니다.
- `namespace_id` 및 `namespace_path` 속성이 GitLab 18.7에서 [도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/511053).

{{< /history >}}

로컬 아카이브에서 프로젝트를 가져옵니다.

```plaintext
POST /projects/import
```

| 속성         | 유형              | 필수 | 설명 |
|-------------------|-------------------|----------|-------------|
| `file`            | 문자열            | 예      | 업로드할 파일입니다. |
| `path`            | 문자열            | 예      | 새 프로젝트의 이름 및 경로입니다. |
| `name`            | 문자열            | 아니요       | 가져올 프로젝트의 이름입니다. 제공되지 않은 경우 프로젝트의 경로로 기본값이 지정됩니다. |
| `namespace`       | 정수 또는 문자열 | 아니요       | (더 이상 사용되지 않음) 프로젝트를 가져올 네임스페이스의 ID 또는 경로입니다. 현재 사용자의 네임스페이스로 기본값이 지정됩니다.<br/><br/> 대상 그룹에 대한 유지 관리자 또는 소유자 역할이 필요합니다. 대신 `namespace_id` 또는 `namespace_path`을(를) 사용하세요. |
| `namespace_id`    | 정수           | 아니요       | 프로젝트를 가져올 네임스페이스의 ID입니다. 현재 사용자의 네임스페이스로 기본값이 지정됩니다.<br/><br/> 대상 그룹에 대한 유지 관리자 또는 소유자 역할이 필요합니다. |
| `namespace_path`  | 문자열            | 아니요       | 프로젝트를 가져올 네임스페이스의 경로입니다. 현재 사용자의 네임스페이스로 기본값이 지정됩니다.<br/><br/> 대상 그룹에 대한 유지 관리자 또는 소유자 역할이 필요합니다. |
| `override_params` | 해시              | 아니요       | [프로젝트 API](projects.md)에서 정의된 모든 필드를 지원합니다. |
| `overwrite`       | 부울           | 아니요       | 같은 경로의 프로젝트가 있으면 가져오기가 덮어씁니다. `false`로 기본값이 설정됩니다. |

전달된 재정의 매개변수는 내보내기 파일 내에 정의된 모든 값보다 우선합니다.

파일 시스템에서 파일을 업로드하려면 `--form` 인수를 사용하세요. 이로 인해 cURL이 `Content-Type: multipart/form-data` 헤더를 사용하여 데이터를 게시합니다. `file=` 매개변수는 파일 시스템의 파일을 가리켜야 하며 `@`가 앞에 와야 합니다. 예를 들어:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --form "path=api-project" \
  --form "file=@/path/to/file" \
  --url "https://gitlab.example.com/api/v4/projects/import"
```

cURL은 원격 서버에서 파일을 게시하는 것을 지원하지 않습니다. 이 예제는 Python의 `open` 메서드를 사용하여 프로젝트를 가져옵니다:

```python
import requests

url =  'https://gitlab.example.com/api/v4/projects/import'
files = { "file": open("project_export.tar.gz", "rb") }
data = {
    "path": "example-project",
    "namespace_path": "example-group"
}
headers = {
    'Private-Token': "<your_access_token>"
}

requests.post(url, headers=headers, data=data, files=files)
```

```json
{
  "id": 1,
  "description": null,
  "name": "api-project",
  "name_with_namespace": "Administrator / api-project",
  "path": "api-project",
  "path_with_namespace": "root/api-project",
  "created_at": "2018-02-13T09:05:58.023Z",
  "import_status": "scheduled",
  "correlation_id": "mezklWso3Za",
  "failed_relations": []
}
```

> [!note]
> 최대 가져오기 파일 크기는 관리자가 설정할 수 있습니다. 기본값은 `0`(무제한)입니다. 관리자는 최대 가져오기 파일 크기를 수정할 수 있습니다. 이를 수행하려면 [애플리케이션 설정 API](settings.md#update-application-settings) 또는 [**운영자** 영역](../administration/settings/account_and_limit_settings.md)에서 `max_import_size` 옵션을 사용하세요.

## 원격 아카이브에서 프로젝트 가져오기 {#import-a-project-from-a-remote-archive}

{{< details >}}

- 상태:  베타

{{< /details >}}

{{< history >}}

- `namespace_id` 및 `namespace_path` 속성이 GitLab 18.7에서 [도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/511053).

{{< /history >}}

> [!flag]
> GitLab Self-Managed에서 기본적으로 이 기능을 사용할 수 있습니다. 기능을 숨기려면 관리자가 `import_project_from_remote_file` 이름의 [기능 플래그를 비활성화](../administration/feature_flags/_index.md)할 수 있습니다. GitLab.com 및 GitLab Dedicated에서 이 기능을 사용할 수 있습니다.

원격 아카이브에서 프로젝트를 가져옵니다.

```plaintext
POST /projects/remote-import
```

| 속성         | 유형              | 필수 | 설명                              |
| ----------------- | ----------------- | -------- | ---------------------------------------- |
| `path`            | 문자열            | 예      | 새 프로젝트의 이름 및 경로입니다. |
| `url`             | 문자열            | 예      | 가져올 파일의 URL입니다. |
| `name`            | 문자열            | 아니요       | 가져올 프로젝트의 이름입니다. 제공되지 않으면 프로젝트의 경로로 기본값이 지정됩니다. |
| `namespace`       | 정수 또는 문자열 | 아니요       | (더 이상 사용되지 않음) 프로젝트를 가져올 네임스페이스의 ID 또는 경로입니다. 현재 사용자의 네임스페이스로 기본값이 지정됩니다.<br/><br/> 대상 그룹에 대한 유지 관리자 또는 소유자 역할이 필요합니다. 대신 `namespace_id` 또는 `namespace_path`을(를) 사용하세요. |
| `namespace_id`    | 정수           | 아니요       | 프로젝트를 가져올 네임스페이스의 ID입니다. 현재 사용자의 네임스페이스로 기본값이 지정됩니다.<br/><br/> 대상 그룹에 대한 유지 관리자 또는 소유자 역할이 필요합니다. |
| `namespace_path`  | 문자열            | 아니요       | 프로젝트를 가져올 네임스페이스의 경로입니다. 현재 사용자의 네임스페이스로 기본값이 지정됩니다.<br/><br/> 대상 그룹에 대한 유지 관리자 또는 소유자 역할이 필요합니다. |
| `overwrite`       | 부울           | 아니요       | 가져오기 시 같은 경로의 프로젝트를 덮어쓸지 여부입니다. `false`로 기본값이 설정됩니다. |
| `override_params` | 해시              | 아니요       | [프로젝트 API](projects.md)에서 정의된 모든 필드를 지원합니다. |

전달된 재정의 매개변수는 내보내기 파일 내에 정의된 모든 값보다 우선합니다.

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --url "https://gitlab.example.com/api/v4/projects/remote-import" \
  --data '{"url":"https://remoteobject/file?token=123123","path":"remote-project"}'
```

```json
{
  "id": 1,
  "description": null,
  "name": "remote-project",
  "name_with_namespace": "Administrator / remote-project",
  "path": "remote-project",
  "path_with_namespace": "root/remote-project",
  "created_at": "2018-02-13T09:05:58.023Z",
  "import_status": "scheduled",
  "correlation_id": "mezklWso3Za",
  "failed_relations": [],
  "import_error": null
}
```

`Content-Length` 헤더는 유효한 숫자를 반환해야 합니다. 최대 파일 크기는 10GB입니다. `Content-Type` 헤더는 `application/gzip`이어야 합니다.

## AWS S3 버킷에서 프로젝트 가져오기 {#import-a-project-from-an-aws-s3-bucket}

{{< history >}}

- `namespace_id` 및 `namespace_path` 속성이 GitLab 18.7에서 [도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/511053).

{{< /history >}}

지정된 AWS S3 버킷에 저장된 아카이브에서 프로젝트를 가져옵니다.

```plaintext
POST /projects/remote-import-s3
```

| 속성           | 유형              | 필수 | 설명 |
| ------------------- | ----------------- | -------- | ----------- |
| `access_key_id`     | 문자열            | 예      | [AWS S3 액세스 키 ID](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html). |
| `bucket_name`       | 문자열            | 예      | 파일이 저장된 [AWS S3 버킷 이름](https://docs.aws.amazon.com/AmazonS3/latest/userguide/bucketnamingrules.html)입니다. |
| `file_key`          | 문자열            | 예      | 파일을 식별하기 위한 [AWS S3 파일 키](https://docs.aws.amazon.com/AmazonS3/latest/userguide/UsingObjects.html)입니다. |
| `path`              | 문자열            | 예      | 새 프로젝트의 전체 경로입니다. |
| `region`            | 문자열            | 예      | 파일이 저장된 [AWS S3 리전 이름](https://docs.aws.amazon.com/AmazonS3/latest/userguide/Welcome.html#Regions)입니다. |
| `secret_access_key` | 문자열            | 예      | [AWS S3 비밀 액세스 키](https://docs.aws.amazon.com/IAM/latest/UserGuide/security-creds.html#access-keys-and-secret-access-keys). |
| `name`              | 문자열            | 아니요       | 가져올 프로젝트의 이름입니다. 제공되지 않으면 프로젝트의 경로로 기본값이 지정됩니다. |
| `namespace`         | 정수 또는 문자열 | 아니요       | (더 이상 사용되지 않음) 프로젝트를 가져올 네임스페이스의 ID 또는 경로입니다. 현재 사용자의 네임스페이스로 기본값이 지정됩니다.<br/><br/> 대상 그룹에 대한 유지 관리자 또는 소유자 역할이 필요합니다. 대신 `namespace_id` 또는 `namespace_path`을(를) 사용하세요. |
| `namespace_id`      | 정수           | 아니요       | 프로젝트를 가져올 네임스페이스의 ID입니다. 현재 사용자의 네임스페이스로 기본값이 지정됩니다.<br/><br/> 대상 그룹에 대한 유지 관리자 또는 소유자 역할이 필요합니다. |
| `namespace_path`    | 문자열            | 아니요       | 프로젝트를 가져올 네임스페이스의 경로입니다. 현재 사용자의 네임스페이스로 기본값이 지정됩니다.<br/><br/> 대상 그룹에 대한 유지 관리자 또는 소유자 역할이 필요합니다. |

전달된 재정의 매개변수는 내보내기 파일 내에 정의된 모든 값보다 우선합니다.

```shell
curl --request POST \
  --url "https://gitlab.example.com/api/v4/projects/remote-import-s3" \
  --header "PRIVATE-TOKEN: <your gitlab access key>" \
  --header 'Content-Type: application/json' \
  --data '{
  "name": "Sample Project",
  "path": "sample-project",
  "region": "<Your S3 region name>",
  "bucket_name": "<Your S3 bucket name>",
  "file_key": "<Your S3 file key>",
  "access_key_id": "<Your AWS access key id>",
  "secret_access_key": "<Your AWS secret access key>"
}'
```

이 예제는 Amazon S3에 연결하는 모듈을 사용하여 Amazon S3 버킷에서 가져옵니다:

```python
import requests
from io import BytesIO

s3_file = requests.get(presigned_url)

url =  'https://gitlab.example.com/api/v4/projects/import'
files = {'file': ('file.tar.gz', BytesIO(s3_file.content))}
data = {
    "path": "example-project",
    "namespace_path": "example-group"
}
headers = {
    'Private-Token': "<your_access_token>"
}

requests.post(url, headers=headers, data=data, files=files)
```

```json
{
  "id": 1,
  "description": null,
  "name": "Sample project",
  "name_with_namespace": "Administrator / sample-project",
  "path": "sample-project",
  "path_with_namespace": "root/sample-project",
  "created_at": "2018-02-13T09:05:58.023Z",
  "import_status": "scheduled",
  "correlation_id": "mezklWso3Za",
  "failed_relations": [],
  "import_error": null
}
```

## 프로젝트 가져오기 상태 검색 {#retrieve-the-status-of-a-project-import}

지정된 프로젝트의 가장 최근 가져오기 상태를 검색합니다.

```plaintext
GET /projects/:id/import
```

| 속성 | 유형           | 필수 | 설명                              |
| --------- | -------------- | -------- | ---------------------------------------- |
| `id`      | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/import"
```

상태는 다음 중 하나일 수 있습니다:

- `none`
- `scheduled`
- `failed`
- `started`
- `finished`

상태가 `failed`인 경우 `import_error` 아래에 가져오기 오류 메시지를 포함합니다. 상태가 `failed`, `started` 또는 `finished`인 경우 `failed_relations` 배열이 다음 중 하나로 인해 가져오기가 실패한 관계의 발생으로 채워질 수 있습니다:

- 복구 불가능한 오류입니다.
- 재시도가 소진되었습니다. 일반적인 예: 쿼리 시간 초과입니다.

> [!note]
> `id` 필드의 요소가 `failed_relations`의 실패 레코드를 참조하지만 관계는 참조하지 않습니다. 또한 `failed_relations` 배열은 100개 항목으로 제한됩니다.

```json
{
  "id": 1,
  "description": "Itaque perspiciatis minima aspernatur corporis consequatur.",
  "name": "Gitlab Test",
  "name_with_namespace": "Gitlab Org / Gitlab Test",
  "path": "gitlab-test",
  "path_with_namespace": "gitlab-org/gitlab-test",
  "created_at": "2017-08-29T04:36:44.383Z",
  "import_status": "started",
  "import_type": "github",
  "correlation_id": "mezklWso3Za",
  "failed_relations": [
    {
      "id": 42,
      "created_at": "2020-04-02T14:48:59.526Z",
      "exception_class": "RuntimeError",
      "exception_message": "A failure occurred",
      "source": "custom error context",
      "relation_name": "merge_requests",
      "line_number": 0
    }
  ]
}
```

GitHub에서 가져올 때 `stats` 필드는 GitHub에서 이미 가져온 객체 수와 이미 가져온 객체 수를 나열합니다:

```json
{
  "id": 1,
  "description": "Itaque perspiciatis minima aspernatur corporis consequatur.",
  "name": "Gitlab Test",
  "name_with_namespace": "Gitlab Org / Gitlab Test",
  "path": "gitlab-test",
  "path_with_namespace": "gitlab-org/gitlab-test",
  "created_at": "2017-08-29T04:36:44.383Z",
  "import_status": "started",
  "import_type": "github",
  "correlation_id": "mezklWso3Za",
  "failed_relations": [
    {
      "id": 42,
      "created_at": "2020-04-02T14:48:59.526Z",
      "exception_class": "RuntimeError",
      "exception_message": "A failure occurred",
      "source": "custom error context",
      "relation_name": "merge_requests",
      "line_number": 0
    }
  ],
  "stats": {
    "fetched": {
      "diff_note": 19,
      "issue": 3,
      "label": 1,
      "note": 3,
      "pull_request": 2,
      "pull_request_merged_by": 1,
      "pull_request_review": 16
    },
    "imported": {
      "diff_note": 19,
      "issue": 3,
      "label": 1,
      "note": 3,
      "pull_request": 2,
      "pull_request_merged_by": 1,
      "pull_request_review": 16
    }
  }
}
```

## 프로젝트 리소스 가져오기 {#import-project-resources}

{{< history >}}

- GitLab 16.11에서 [베타](../policy/development_stages_support.md#beta) 버전으로 [도입되었으며](https://gitlab.com/gitlab-org/gitlab/-/issues/425798) [플래그](../administration/feature_flags/_index.md) 이름은 `single_relation_import`입니다. 기본적으로 비활성화됨.
- GitLab 17.1에서 [일반적으로 사용 가능합니다](https://gitlab.com/gitlab-org/gitlab/-/issues/455889). 기능 플래그 `single_relation_import` 제거됨.

{{< /history >}}

프로젝트 아카이브에 포함된 [프로젝트 리소스](../user/project/settings/import_export.md#project-items-that-are-exported)를 가져옵니다. 가져올 항목의 유형은 `relation` 속성으로 제어됩니다. 이전에 가져온 항목을 건너뜁니다.

필수 프로젝트 내보내기 파일은 [로컬 아카이브에서 프로젝트 가져오기](#import-a-project-from-a-local-archive)에 설명된 것과 동일한 구조 및 크기 요구 사항을 준수합니다.

- 추출된 파일은 GitLab 프로젝트 내보내기의 구조를 준수해야 합니다.
- 아카이브는 관리자가 구성한 최대 가져오기 파일 크기를 초과하지 않아야 합니다.

```plaintext
POST /projects/import-relation
```

| 속성  | 유형   | 필수 | 설명                                                                                                    |
|------------|--------|----------|----------------------------------------------------------------------------------------------------------------|
| `file`     | 문자열 | 예      | 업로드할 파일입니다.                                                                                       |
| `path`     | 문자열 | 예      | 새 프로젝트의 이름 및 경로입니다.                                                                                 |
| `relation` | 문자열 | 예      | 가져올 관계의 이름입니다. `issues`, `milestones`, `ci_pipelines` 또는 `merge_requests` 중 하나여야 합니다. |

파일 시스템에서 파일을 업로드하려면 `--form` 옵션을 사용하세요. 이로 인해 cURL이 `Content-Type: multipart/form-data` 헤더를 사용하여 데이터를 게시합니다. `file=` 매개변수는 파일 시스템의 파일을 가리켜야 하며 `@`가 앞에 와야 합니다. 예를 들어:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --form "path=api-project" \
  --form "file=@/path/to/file" \
  --form "relation=issues" \
  --url "https://gitlab.example.com/api/v4/projects/import-relation"
```

```json
{
  "id": 9,
  "project_path": "namespace1/project1",
  "relation": "issues",
  "status": "finished"
}
```

## 프로젝트 리소스 가져오기 상태 검색 {#retrieve-the-status-of-a-project-resource-import}

{{< history >}}

- [GitLab 16.11에서 도입](https://gitlab.com/gitlab-org/gitlab/-/issues/425798)됨.

{{< /history >}}

지정된 프로젝트의 가장 최근 관계 가져오기 상태를 검색합니다. 한 번에 하나의 관계 가져오기만 예약할 수 있으므로 이 끝점을 사용하여 이전 가져오기가 성공적으로 완료되었는지 확인할 수 있습니다.

```plaintext
GET /projects/:id/relation-imports
```

| 속성 | 유형               | 필수 | 설명                                                                          |
| --------- |--------------------| -------- |--------------------------------------------------------------------------------------|
| `id`      | 정수 또는 문자열  | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/18/relation-imports"
```

```json
[
  {
    "id": 1,
    "project_path": "namespace1/project1",
    "relation": "issues",
    "status": "created",
    "created_at": "2024-03-25T11:03:48.074Z",
    "updated_at": "2024-03-25T11:03:48.074Z"
  }
]
```

상태는 다음 중 하나일 수 있습니다:

- `created`:  가져오기가 예약되었지만 아직 시작되지 않았습니다.
- `started`:  가져오기가 처리 중입니다.
- `finished`:  가져오기가 완료되었습니다.
- `failed`:  가져오기를 완료할 수 없습니다.
