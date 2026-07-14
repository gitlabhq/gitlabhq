---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 인스턴스 수준 CI/CD 변수 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 인스턴스의 [CI/CD 변수](../ci/variables/_index.md#for-an-instance)와 상호 작용합니다.

## 모든 인스턴스 변수 나열 {#list-all-instance-variables}

{{< history >}}

- `description` 매개변수는 GitLab 16.8에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/418331)되었습니다.

{{< /history >}}

모든 인스턴스 수준 변수를 나열합니다. `page` 및 `per_page` [페이지 매김](rest/_index.md#offset-based-pagination) 매개변수를 사용하여 결과의 페이지 매김을 제어합니다.

```plaintext
GET /admin/ci/variables
```

```shell
curl \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/admin/ci/variables"
```

```json
[
    {
        "key": "TEST_VARIABLE_1",
        "description": null,
        "variable_type": "env_var",
        "value": "TEST_1",
        "protected": false,
        "masked": false,
        "raw": false
    },
    {
        "key": "TEST_VARIABLE_2",
        "description": null,
        "variable_type": "env_var",
        "value": "TEST_2",
        "protected": false,
        "masked": false,
        "raw": false
    }
]
```

## 인스턴스 변수 세부 정보 검색 {#retrieve-instance-variable-details}

{{< history >}}

- `description` 매개변수는 GitLab 16.8에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/418331)되었습니다.

{{< /history >}}

특정 인스턴스 수준 변수의 세부 정보를 검색합니다.

```plaintext
GET /admin/ci/variables/:key
```

| 특성 | 유형    | 필수 | 설명 |
|-----------|---------|----------|-------------|
| `key`     | 문자열  | 예      | 변수의 `key` |

```shell
curl \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/admin/ci/variables/TEST_VARIABLE_1"
```

```json
{
    "key": "TEST_VARIABLE_1",
    "description": null,
    "variable_type": "env_var",
    "value": "TEST_1",
    "protected": false,
    "masked": false,
    "raw": false
}
```

## 인스턴스 변수 생성 {#create-instance-variable}

{{< history >}}

- `description` 매개변수는 GitLab 16.8에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/418331)되었습니다.

{{< /history >}}

새 인스턴스 수준 변수를 생성합니다.

[인스턴스 수준 변수의 최대 개수](../administration/cicd/limits.md#instance-cicd-variable-limit)를 변경할 수 있습니다.

```plaintext
POST /admin/ci/variables
```

| 특성       | 유형    | 필수 | 설명 |
|-----------------|---------|----------|-------------|
| `key`           | 문자열  | 예      | 변수의 `key` 최대 255자이며, `A-Z`, `a-z`, `0-9` 및 `_`만 사용할 수 있습니다. |
| `value`         | 문자열  | 예      | 변수의 `value` 최대 10,000자입니다. |
| `description`   | 문자열  | 아니요       | 변수의 설명입니다. 최대 255자입니다. |
| `masked`        | 부울 | 아니요       | 변수가 마스킹되는지 여부입니다. |
| `protected`     | 부울 | 아니요       | 변수가 보호되는지 여부입니다. |
| `raw`           | 부울 | 아니요       | 변수가 확장 가능한지 여부입니다. |
| `variable_type` | 문자열  | 아니요       | 변수의 유형입니다. 사용 가능한 유형은 `env_var` (기본값) 및 `file`입니다. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/admin/ci/variables" \
  --form "key=NEW_VARIABLE" \
  --form "value=new value"
```

```json
{
    "key": "NEW_VARIABLE",
    "description": null,
    "value": "new value",
    "variable_type": "env_var",
    "protected": false,
    "masked": false,
    "raw": false
}
```

## 인스턴스 변수 업데이트 {#update-instance-variable}

{{< history >}}

- `description` 매개변수는 GitLab 16.8에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/418331)되었습니다.

{{< /history >}}

인스턴스 수준 변수를 업데이트합니다.

```plaintext
PUT /admin/ci/variables/:key
```

| 특성       | 유형    | 필수 | 설명 |
|-----------------|---------|----------|-------------|
| `description`   | 문자열  | 아니요       | 변수의 설명입니다. 최대 255자입니다. |
| `key`           | 문자열  | 예      | 변수의 `key` 최대 255자이며, `A-Z`, `a-z`, `0-9` 및 `_`만 사용할 수 있습니다. |
| `masked`        | 부울 | 아니요       | 변수가 마스킹되는지 여부입니다. |
| `protected`     | 부울 | 아니요       | 변수가 보호되는지 여부입니다. |
| `raw`           | 부울 | 아니요       | 변수가 확장 가능한지 여부입니다. |
| `value`         | 문자열  | 예      | 변수의 `value` 최대 10,000자입니다. |
| `variable_type` | 문자열  | 아니요       | 변수의 유형입니다. 사용 가능한 유형은 `env_var` (기본값) 및 `file`입니다. |

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/admin/ci/variables/NEW_VARIABLE" \
  --form "value=updated value"
```

```json
{
    "key": "NEW_VARIABLE",
    "description": null,
    "value": "updated value",
    "variable_type": "env_var",
    "protected": true,
    "masked": true,
    "raw": true
}
```

## 인스턴스 변수 삭제 {#delete-instance-variable}

인스턴스 수준 변수를 삭제합니다.

```plaintext
DELETE /admin/ci/variables/:key
```

| 특성 | 유형   | 필수 | 설명 |
|-----------|--------|----------|-------------|
| `key`     | 문자열 | 예      | 변수의 `key` |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/admin/ci/variables/VARIABLE_1"
```
