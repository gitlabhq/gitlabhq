---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 프로젝트 수준 CI/CD 변수 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [`filter`](https://gitlab.com/gitlab-org/gitlab/-/issues/340185)를 GitLab 16.9에서 도입했습니다.

{{< /history >}}

이 API를 사용하여 프로젝트의 [CI/CD 변수](../ci/variables/_index.md#for-a-project)와 상호작용합니다.

## 프로젝트 변수 나열 {#list-project-variables}

프로젝트의 모든 변수를 나열합니다. `page`과 `per_page` [페이지 나누기](rest/_index.md#offset-based-pagination) 매개변수를 사용하여 결과의 페이지 나누기를 제어합니다.

```plaintext
GET /projects/:id/variables
```

| 속성 | 유형           | 필수 | 설명 |
|-----------|----------------|----------|-------------|
| `id`      | 정수 또는 문자열 | 예      | ID 또는 [프로젝트의 URL 인코딩 경로](rest/_index.md#namespaced-paths) |

요청 예시:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/variables"
```

응답 예시:

```json
[
    {
        "variable_type": "env_var",
        "key": "TEST_VARIABLE_1",
        "value": "TEST_1",
        "protected": false,
        "masked": true,
        "hidden": false,
        "raw": false,
        "environment_scope": "*",
        "description": null
    },
    {
        "variable_type": "env_var",
        "key": "TEST_VARIABLE_2",
        "value": "TEST_2",
        "protected": false,
        "masked": false,
        "hidden": false,
        "raw": false,
        "environment_scope": "*",
        "description": null
    }
]
```

## 단일 변수 검색 {#retrieve-a-single-variable}

단일 변수의 세부 정보를 검색합니다. 동일한 키를 가진 변수가 여러 개인 경우 `filter`을 사용하여 올바른 `environment_scope`을 선택합니다.

```plaintext
GET /projects/:id/variables/:key
```

| 속성 | 유형              | 필수 | 설명 |
| --------- | ----------------- | -------- | ----------- |
| `id`      | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths) |
| `key`     | 문자열            | 예      | 변수의 키입니다. |
| `filter`  | 해시              | 아니요       | 여러 변수가 동일한 키를 공유할 때 결과를 필터링합니다. 가능한 값: `[environment_scope]` |

요청 예시:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/variables/TEST_VARIABLE_1"
```

응답 예시:

```json
{
    "key": "TEST_VARIABLE_1",
    "variable_type": "env_var",
    "value": "TEST_1",
    "protected": false,
    "masked": true,
    "hidden": false,
    "raw": false,
    "environment_scope": "*",
    "description": null
}
```

`filter`을 포함한 요청 예시:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/variables/SCOPED_VARIABLE_1" \
  --form "filter[environment_scope]=production"
```

## 변수 생성 {#create-a-variable}

{{< history >}}

- `masked_and_hidden`과 `hidden` 특성을 GitLab 17.4에서 [도입했습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/29674).

{{< /history >}}

새 변수를 생성합니다. 동일한 `key`을 가진 변수가 이미 있으면 새 변수는 다른 `environment_scope`을 가져야 합니다. 그렇지 않으면 GitLab은 다음과 유사한 메시지를 반환합니다: `VARIABLE_NAME has already been taken`

```plaintext
POST /projects/:id/variables
```

| 속성           | 유형           | 필수 | 설명 |
|---------------------|----------------|----------|-------------|
| `id`                | 정수 또는 문자열 | 예      | ID 또는 [프로젝트의 URL 인코딩 경로](rest/_index.md#namespaced-paths) |
| `key`               | 문자열         | 예      | 변수의 `key`(255자 이하여야 함, `A-Z`, `a-z`, `0-9`, `_`만 허용됨) |
| `value`             | 문자열         | 예      | 변수의 `value` |
| `description`       | 문자열         | 아니요       | 변수에 대한 설명입니다. 기본값: `null`. GitLab 16.2에서 [도입했습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/409641). |
| `environment_scope` | 문자열         | 아니요       | 변수의 `environment_scope` 기본값: `*` |
| `masked`            | 부울        | 아니요       | 변수가 마스크되는지 여부입니다. 기본값: `false` |
| `masked_and_hidden` | 부울        | 아니요       | 변수가 마스크되고 숨겨지는지 여부입니다. 기본값: `false` |
| `protected`         | 부울        | 아니요       | 변수가 보호되는지 여부입니다. 기본값: `false` |
| `raw`               | 부울        | 아니요       | 변수가 원시 문자열로 처리되는지 여부입니다. 기본값: `true`. `false`일 때 값의 변수는 [확장됩니다](../ci/variables/_index.md#allow-cicd-variable-expansion). |
| `variable_type`     | 문자열         | 아니요       | 변수의 유형입니다. 사용 가능한 유형: `env_var`(기본값) 및 `file` |

요청 예시:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/variables" \
  --form "key=NEW_VARIABLE" \
  --form "value=new value"
```

응답 예시:

```json
{
    "variable_type": "env_var",
    "key": "NEW_VARIABLE",
    "value": "new value",
    "protected": false,
    "masked": false,
    "hidden": false,
    "raw": false,
    "environment_scope": "*",
    "description": null
}
```

## 변수 업데이트 {#update-a-variable}

프로젝트 변수를 업데이트합니다. 동일한 키를 가진 변수가 여러 개인 경우 `filter`을 사용하여 올바른 `environment_scope`을 선택합니다.

```plaintext
PUT /projects/:id/variables/:key
```

| 속성           | 유형              | 필수 | 설명 |
| ------------------- | ----------------- | -------- | ----------- |
| `id`                | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths) |
| `key`               | 문자열            | 예      | 변수의 키입니다. |
| `value`             | 문자열            | 예      | 변수의 값입니다. |
| `description`       | 문자열            | 아니요       | 변수에 대한 설명입니다. GitLab 16.2에서 [도입했습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/409641). 기본값: `null`. |
| `environment_scope` | 문자열            | 아니요       | 변수의 환경 범위 |
| `filter`            | 해시              | 아니요       | 여러 변수가 동일한 키를 공유할 때 결과를 필터링합니다. 가능한 값: `[environment_scope]` |
| `masked`            | 부울           | 아니요       | `true`이면 변수가 마스크됨을 나타냅니다. |
| `protected`         | 부울           | 아니요       | `true`이면 변수가 보호됨을 나타냅니다. |
| `raw`               | 부울           | 아니요       | `true`이면 변수가 원시 문자열로 처리됨을 나타냅니다. `false`일 때 변수 값은 [확장됩니다](../ci/variables/_index.md#allow-cicd-variable-expansion). 기본값: `true`. |
| `variable_type`     | 문자열            | 아니요       | 변수의 유형입니다. 사용 가능한 유형: `env_var`(기본값) 및 `file` |

요청 예시:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/variables/NEW_VARIABLE" \
  --form "value=updated value"
```

응답 예시:

```json
{
    "variable_type": "env_var",
    "key": "NEW_VARIABLE",
    "value": "updated value",
    "protected": true,
    "masked": false,
    "hidden": false,
    "raw": false,
    "environment_scope": "*",
    "description": "null"
}
```

`filter`을 포함한 요청 예시:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/variables/SCOPED_VARIABLE_1" \
  --form "value=updated value" \
  --form "environment_scope=production" \
  --form "filter[environment_scope]=production"
```

## 변수 삭제 {#delete-a-variable}

프로젝트 변수를 삭제합니다. 동일한 키를 가진 변수가 여러 개인 경우 `filter`을 사용하여 올바른 `environment_scope`을 선택합니다.

```plaintext
DELETE /projects/:id/variables/:key
```

| 속성 | 유형              | 필수 | 설명 |
| --------- | ----------------- | -------- | ----------- |
| `id`      | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths) |
| `key`     | 문자열            | 예      | 변수의 키입니다. |
| `filter`  | 해시              | 아니요       | 여러 변수가 동일한 키를 공유할 때 결과를 필터링합니다. 가능한 값: `[environment_scope]` |

요청 예시:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>"
  --url "https://gitlab.example.com/api/v4/projects/1/variables/VARIABLE_1"
```

`filter`을 포함한 요청 예시:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>"
  --url "https://gitlab.example.com/api/v4/projects/1/variables/SCOPED_VARIABLE_1" \
  --form "filter[environment_scope]=production"
```
