---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 그룹 수준 CI/CD 변수 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 16.9에서 [`filter`](https://gitlab.com/gitlab-org/gitlab/-/issues/340185)를 도입했습니다.

{{< /history >}}

이 API를 사용하여 그룹의 [CI/CD 변수](../ci/variables/_index.md#for-a-group)와 상호 작용합니다.

전제 조건:

- 그룹의 Owner 역할이 있어야 합니다.

## 모든 그룹 변수 나열 {#list-all-group-variables}

지정된 그룹의 모든 변수를 나열합니다. `page` 및 `per_page` [페이지 매김](rest/_index.md#offset-based-pagination) 매개변수를 사용하여 결과의 페이지 매김을 제어합니다.

```plaintext
GET /groups/:id/variables
```

| 속성 | 유형           | 필수 | 설명 |
|-----------|----------------|----------|-------------|
| `id`      | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths) |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/variables"
```

```json
[
    {
        "key": "TEST_VARIABLE_1",
        "variable_type": "env_var",
        "value": "TEST_1",
        "protected": false,
        "masked": false,
        "hidden": false,
        "raw": false,
        "environment_scope": "*",
        "description": null
    },
    {
        "key": "TEST_VARIABLE_2",
        "variable_type": "env_var",
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

## 그룹 변수의 세부 정보 검색 {#retrieve-details-of-a-group-variable}

{{< history >}}

- `filter` 매개변수는 GitLab 16.9에서 [도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/340185).

{{< /history >}}

지정된 그룹 변수의 세부 정보를 검색합니다. 동일한 키를 가진 변수가 여러 개인 경우 `filter`을(를) 사용하여 올바른 `environment_scope`을(를) 선택합니다.

```plaintext
GET /groups/:id/variables/:key
```

| 속성 | 유형              | 필수 | 설명 |
| --------- | ----------------- | -------- | ----------- |
| `id`      | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths). |
| `key`     | 문자열            | 예      | 변수의 키입니다. |
| `filter`  | 해시              | 아니요       | 여러 변수가 동일한 키를 공유할 때 결과를 필터링합니다. 가능한 값: `[environment_scope]`. Premium 및 Ultimate만 해당합니다. |

요청 예시:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/variables/TEST_VARIABLE_1"
```

```json
{
    "key": "TEST_VARIABLE_1",
    "variable_type": "env_var",
    "value": "TEST_1",
    "protected": false,
    "masked": false,
    "hidden": false,
    "raw": false,
    "environment_scope": "*",
    "description": null
}
```

`filter`을(를) 사용한 요청 예시:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/variables/SCOPED_VARIABLE_1" \
  --form "filter[environment_scope]=production"
```

## 그룹 변수 생성 {#create-a-group-variable}

{{< history >}}

- `masked_and_hidden` 및 `hidden` 속성이 GitLab 17.4에서 [도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/29674).

{{< /history >}}

그룹 변수를 생성합니다.

```plaintext
POST /groups/:id/variables
```

| 속성           | 유형              | 필수 | 설명 |
|---------------------|-------------------|----------|-------------|
| `id`                | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths). |
| `key`               | 문자열            | 예      | 변수의 `key`. 최대 255자입니다. `A-Z`, `a-z`, `0-9` 및 `_`만 허용됩니다. |
| `value`             | 문자열            | 예      | 변수의 `value`. |
| `description`       | 문자열            | 아니요       | 변수의 `description`. 최대 255자입니다. 기본값: `null`. |
| `environment_scope` | 문자열            | 아니요       | 변수의 [환경 범위](../ci/environments/_index.md#limit-the-environment-scope-of-a-cicd-variable). Premium 및 Ultimate만 해당합니다. |
| `masked`            | 부울           | 아니요       | 변수가 마스크되는지 여부입니다. |
| `masked_and_hidden` | 부울           | 아니요       | 변수가 마스크되고 숨겨지는지 여부입니다. 기본값: `false` |
| `protected`         | 부울           | 아니요       | 변수가 보호되는지 여부입니다. |
| `raw`               | 부울           | 아니요       | 변수가 원본 문자열로 처리되는지 여부입니다. 기본값: `true`. `false`일 때 값의 변수가 [확장됩니다](../ci/variables/_index.md#allow-cicd-variable-expansion). |
| `variable_type`     | 문자열            | 아니요       | 변수의 유형입니다. 사용 가능한 유형은 `env_var`(기본값) 및 `file`입니다. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/variables" \
  --form "key=NEW_VARIABLE" \
  --form "value=new value"
```

```json
{
    "key": "NEW_VARIABLE",
    "value": "new value",
    "variable_type": "env_var",
    "protected": false,
    "masked": false,
    "hidden": false,
    "raw": false,
    "environment_scope": "*",
    "description": null
}
```

## 그룹 변수 업데이트 {#update-a-group-variable}

{{< history >}}

- `filter` 매개변수는 GitLab 16.9에서 [도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/340185).

{{< /history >}}

지정된 그룹 변수를 업데이트합니다. 동일한 키를 가진 변수가 여러 개인 경우 `filter`을(를) 사용하여 올바른 `environment_scope`을(를) 선택합니다.

> [!warning]
> `environment_scope`이(가) 없는 환경 범위로 필터링할 때 엔드포인트는 동일한 이름이지만 다른 환경 범위를 가진 변수 업데이트로 대체됩니다. [그룹 변수의 세부 정보 검색](#retrieve-details-of-a-group-variable) 엔드포인트를 사용하여 주어진 변수의 범위 존재를 확인합니다.

```plaintext
PUT /groups/:id/variables/:key
```

| 속성           | 유형              | 필수 | 설명 |
| ------------------- | ----------------- | -------- | ----------- |
| `id`                | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths). |
| `key`               | 문자열            | 예      | 변수의 키입니다. |
| `value`             | 문자열            | 예      | 변수의 값입니다. |
| `description`       | 문자열            | 아니요       | 변수에 대한 설명입니다. GitLab 16.2에서 [도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/409641). 기본값: `null`. |
| `environment_scope` | 문자열            | 아니요       | 변수의 [환경 범위](../ci/environments/_index.md#limit-the-environment-scope-of-a-cicd-variable). Premium 및 Ultimate만 해당합니다. |
| `filter`            | 해시              | 아니요       | 여러 변수가 동일한 키를 공유할 때 결과를 필터링합니다. 가능한 값: `[environment_scope]`. Premium 및 Ultimate만 해당합니다. |
| `masked`            | 부울           | 아니요       | `true`이면 변수가 마스크됨을 나타냅니다. |
| `protected`         | 부울           | 아니요       | `true`이면 변수가 보호됨을 나타냅니다. |
| `raw`               | 부울           | 아니요       | `true`이면 변수가 원본 문자열로 처리됨을 나타냅니다. `false`일 때 변수 값이 [확장됩니다](../ci/variables/_index.md#allow-cicd-variable-expansion). 기본값: `true`. |
| `variable_type`     | 문자열            | 아니요       | 변수의 유형입니다. 사용 가능한 유형은 `env_var`(기본값) 및 `file`입니다. |

요청 예시:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/variables/NEW_VARIABLE" \
  --form "value=updated value"
```

```json
{
    "key": "NEW_VARIABLE",
    "value": "updated value",
    "variable_type": "env_var",
    "protected": true,
    "masked": true,
    "hidden": false,
    "raw": true,
    "environment_scope": "*",
    "description": null
}
```

`filter`을(를) 사용한 요청 예시:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/variables/SCOPED_VARIABLE_1" \
  --form "value=updated value" \
  --form "environment_scope=production" \
  --form "filter[environment_scope]=production"
```

## 그룹 변수 삭제 {#delete-a-group-variable}

{{< history >}}

- `filter` 매개변수는 GitLab 16.9에서 [도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/340185).

{{< /history >}}

지정된 그룹 변수를 삭제합니다. 동일한 키를 가진 변수가 여러 개인 경우 `filter`을(를) 사용하여 올바른 `environment_scope`을(를) 선택합니다.

```plaintext
DELETE /groups/:id/variables/:key
```

| 속성 | 유형              | 필수 | 설명 |
| --------- | ----------------- | -------- | ----------- |
| `id`      | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths). |
| `key`     | 문자열            | 예      | 변수의 키입니다. |
| `filter`  | 해시              | 아니요       | 여러 변수가 동일한 키를 공유할 때 결과를 필터링합니다. 가능한 값: `[environment_scope]`. Premium 및 Ultimate만 해당합니다. |

요청 예시:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/variables/VARIABLE_1"
```

`filter`을(를) 사용한 요청 예시:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/variables/SCOPED_VARIABLE_1" \
  --form "filter[environment_scope]=production"
```
