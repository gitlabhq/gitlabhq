---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Terraform 모듈 레지스트리 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 [Terraform CLI](../../user/packages/terraform_module_registry/_index.md)와 상호작용합니다.

> [!warning]
> 이 API는 [Terraform CLI](https://www.terraform.io/)에서 사용되며 일반적으로 수동 사용을 위해 설계되지 않았습니다. 문서화되지 않은 인증 방법은 향후 제거될 수 있습니다.

## 특정 모듈의 사용 가능한 버전 나열 {#list-available-versions-for-a-specific-module}

지정된 모듈의 사용 가능한 모든 버전을 나열합니다.

```plaintext
GET packages/terraform/modules/v1/:module_namespace/:module_name/:module_system/versions
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `module_namespace` | 문자열 | 예 | Terraform 모듈의 프로젝트 또는 하위 그룹이 속한 최상위 그룹(네임스페이스)입니다.|
| `module_name` | 문자열 | 예 | 모듈 이름입니다. |
| `module_system` | 문자열 | 예 | 모듈 시스템 또는 [공급자](https://www.terraform.io/registry/providers)의 이름입니다. |

```shell
curl --header "Authorization: Bearer <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/packages/terraform/modules/v1/group/hello-world/local/versions"
```

응답 예:

```json
{
  "modules": [
    {
      "versions": [
        {
          "version": "1.0.0",
          "submodules": [],
          "root": {
            "dependencies": [],
            "providers": [
              {
                "name": "local",
                "version":""
              }
            ]
          }
        },
        {
          "version": "0.9.3",
          "submodules": [],
          "root": {
            "dependencies": [],
            "providers": [
              {
                "name": "local",
                "version":""
              }
            ]
          }
        }
      ],
      "source": "https://gitlab.example.com/group/hello-world"
    }
  ]
}
```

## 모듈의 최신 버전 검색 {#retrieve-latest-version-for-a-module}

지정된 모듈의 최신 버전에 대한 정보를 검색합니다.

```plaintext
GET packages/terraform/modules/v1/:module_namespace/:module_name/:module_system
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `module_namespace` | 문자열 | 예 | Terraform 모듈의 프로젝트가 속한 그룹입니다. |
| `module_name` | 문자열 | 예 | 모듈 이름입니다. |
| `module_system` | 문자열 | 예 | 모듈 시스템 또는 [공급자](https://www.terraform.io/registry/providers)의 이름입니다. |

```shell
curl --header "Authorization: Bearer <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/packages/terraform/modules/v1/group/hello-world/local"
```

응답 예:

```json
{
  "name": "hello-world/local",
  "provider": "local",
  "providers": [
    "local"
  ],
  "root": {
    "dependencies": []
  },
  "source": "https://gitlab.example.com/group/hello-world",
  "submodules": [],
  "version": "1.0.0",
  "versions": [
    "1.0.0"
  ]
}
```

## 모듈의 특정 버전 검색 {#retrieve-a-specific-version-for-a-module}

지정된 모듈의 특정 버전에 대한 정보를 검색합니다.

```plaintext
GET packages/terraform/modules/v1/:module_namespace/:module_name/:module_system/1.0.0
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `module_namespace` | 문자열 | 예 | Terraform 모듈의 프로젝트가 속한 그룹입니다. |
| `module_name` | 문자열 | 예 | 모듈 이름입니다. |
| `module_system` | 문자열 | 예 | 모듈 시스템 또는 [공급자](https://www.terraform.io/registry/providers)의 이름입니다. |

```shell
curl --header "Authorization: Bearer <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/packages/terraform/modules/v1/group/hello-world/local/1.0.0"
```

응답 예:

```json
{
  "name": "hello-world/local",
  "provider": "local",
  "providers": [
    "local"
  ],
  "root": {
    "dependencies": []
  },
  "source": "https://gitlab.example.com/group/hello-world",
  "submodules": [],
  "version": "1.0.0",
  "versions": [
    "1.0.0"
  ]
}
```

## 최신 모듈 버전의 다운로드 URL 검색 {#retrieve-download-url-for-latest-module-version}

`X-Terraform-Get` 헤더에서 최신 모듈 버전의 다운로드 URL을 검색합니다.

```plaintext
GET packages/terraform/modules/v1/:module_namespace/:module_name/:module_system/download
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `module_namespace` | 문자열 | 예 | Terraform 모듈의 프로젝트가 속한 그룹입니다. |
| `module_name` | 문자열 | 예 | 모듈 이름입니다. |
| `module_system` | 문자열 | 예 | 모듈 시스템 또는 [공급자](https://www.terraform.io/registry/providers)의 이름입니다. |

```shell
curl --header "Authorization: Bearer <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/packages/terraform/modules/v1/group/hello-world/local/download"
```

응답 예:

```plaintext
HTTP/1.1 204 No Content
Content-Length: 0
X-Terraform-Get: /api/v4/packages/terraform/modules/v1/group/hello-world/local/1.0.0/file?token=&archive=tgz
```

내부적으로 이 API 엔드포인트는 `packages/terraform/modules/v1/:module_namespace/:module_name/:module_system/:module_version/download`로 리디렉션됩니다.

## 특정 모듈 버전의 다운로드 URL 검색 {#retrieve-download-url-for-a-specific-module-version}

`X-Terraform-Get` 헤더에서 지정된 모듈 버전의 다운로드 URL을 검색합니다.

```plaintext
GET packages/terraform/modules/v1/:module_namespace/:module_name/:module_system/:module_version/download
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `module_namespace` | 문자열 | 예 | Terraform 모듈의 프로젝트가 속한 그룹입니다. |
| `module_name` | 문자열 | 예 | 모듈 이름입니다. |
| `module_system` | 문자열 | 예 | 모듈 시스템 또는 [공급자](https://www.terraform.io/registry/providers)의 이름입니다. |
| `module_version` | 문자열 | 예 | 다운로드할 특정 모듈 버전입니다. |

```shell
curl --header "Authorization: Bearer <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/packages/terraform/modules/v1/group/hello-world/local/1.0.0/download"
```

응답 예:

```plaintext
HTTP/1.1 204 No Content
Content-Length: 0
X-Terraform-Get: /api/v4/packages/terraform/modules/v1/group/hello-world/local/1.0.0/file?token=&archive=tgz
```

## 모듈 다운로드 {#download-module}

### 네임스페이스에서 {#from-a-namespace}

```plaintext
GET packages/terraform/modules/v1/:module_namespace/:module_name/:module_system/:module_version/file
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `module_namespace` | 문자열 | 예 | Terraform 모듈의 프로젝트가 속한 그룹입니다. |
| `module_name` | 문자열 | 예 | 모듈 이름입니다. |
| `module_system` | 문자열 | 예 | 모듈 시스템 또는 [공급자](https://www.terraform.io/registry/providers)의 이름입니다. |
| `module_version` | 문자열 | 예 | 다운로드할 특정 모듈 버전입니다. |

```shell
curl --header "Authorization: Bearer <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/packages/terraform/modules/v1/group/hello-world/local/1.0.0/file"
```

출력을 파일에 저장하려면:

```shell
curl --header "Authorization: Bearer <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/packages/terraform/modules/v1/group/hello-world/local/1.0.0/file" \
  --output hello-world-local.tgz
```

### 프로젝트에서 {#from-a-project}

```plaintext
GET /projects/:id/packages/terraform/modules/:module_name/:module_system/:module_version
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id` | 정수 또는 문자열 | 예 | 프로젝트의 ID 또는 URL 인코딩된 경로입니다. |
| `module_name` | 문자열 | 예 | 모듈 이름입니다. |
| `module_system` | 문자열 | 예 | 모듈 시스템 또는 [공급자](https://www.terraform.io/registry/providers)의 이름입니다. |
| `module_version` | 문자열 | 아니오 | 다운로드할 특정 모듈 버전입니다. 생략되면 최신 버전이 다운로드됩니다. |

```shell
curl --user "<username>:<personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/terraform/modules/hello-world/local/1.0.0"
```

출력을 파일에 저장하려면:

```shell
curl --user "<username>:<personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/terraform/modules/hello-world/local/1.0.0" \
  --output hello-world-local.tgz
```

## 모듈 업로드 {#upload-module}

지정된 프로젝트의 모듈을 업로드합니다.

```plaintext
PUT /projects/:id/packages/terraform/modules/:module-name/:module-system/:module-version/file
```

| 속성        | 유형              | 필수 | 설명 |
|------------------|-------------------|----------|-------------|
| `id`             | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 URL 인코딩된 경로입니다. |
| `module-name`    | 문자열            | 예      | 모듈 이름입니다. |
| `module-system`  | 문자열            | 예      | 모듈 시스템 또는 [공급자](https://www.terraform.io/registry/providers)의 이름입니다. |
| `module-version` | 문자열            | 예      | 업로드할 특정 모듈 버전입니다. |

```shell
curl --fail-with-body \
   --header "PRIVATE-TOKEN: <your_access_token>" \
   --upload-file path/to/file.tgz \
   --url  "https://gitlab.example.com/api/v4/projects/<your_project_id>/packages/terraform/modules/my-module/my-system/0.0.1/file"
```

인증에 사용할 수 있는 토큰:

| 헤더          | 값 |
|-----------------|-------|
| `PRIVATE-TOKEN` | `api` 범위가 있는 [개인 액세스 토큰](../../user/profile/personal_access_tokens.md)입니다. |
| `DEPLOY-TOKEN`  | `write_package_registry` 범위가 있는 [배포 토큰](../../user/project/deploy_tokens/_index.md)입니다. |
| `JOB-TOKEN`     | [작업 토큰](../../ci/jobs/ci_job_token.md)입니다. |

응답 예:

```json
{
  "message": "201 Created"
}
```
