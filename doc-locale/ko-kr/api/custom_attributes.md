---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 사용자 정의 특성 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 사용자, 그룹, 프로젝트의 사용자 정의 특성을 관리합니다.

전제 조건:

- 인스턴스의 관리자여야 합니다.

## 모든 사용자 정의 특성 나열 {#list-all-custom-attributes}

지정된 리소스의 모든 사용자 정의 특성을 나열합니다.

```plaintext
GET /users/:id/custom_attributes
GET /groups/:id/custom_attributes
GET /projects/:id/custom_attributes
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id` | 정수 | 예 | 리소스의 ID |

```shell
curl --request GET \
   --header "PRIVATE-TOKEN: <your_access_token>" \
   --url "https://gitlab.example.com/api/v4/users/42/custom_attributes"
```

응답 예시:

```json
[
   {
      "key": "location",
      "value": "Antarctica"
   },
   {
      "key": "role",
      "value": "Developer"
   }
]
```

## 사용자 정의 특성 검색 {#retrieve-a-custom-attribute}

지정된 리소스의 사용자 정의 특성을 검색합니다.

```plaintext
GET /users/:id/custom_attributes/:key
GET /groups/:id/custom_attributes/:key
GET /projects/:id/custom_attributes/:key
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id` | 정수 | 예 | 리소스의 ID |
| `key` | 문자열 | 예 | 사용자 정의 특성의 키 |

```shell
curl --request GET \
   --header "PRIVATE-TOKEN: <your_access_token>" \
   --url "https://gitlab.example.com/api/v4/users/42/custom_attributes/location"
```

응답 예시:

```json
{
   "key": "location",
   "value": "Antarctica"
}
```

## 사용자 정의 특성 업데이트 {#update-a-custom-attribute}

지정된 리소스의 사용자 정의 특성을 업데이트하거나 생성합니다. 특성이 이미 존재하면 업데이트되고, 그렇지 않으면 새로 생성됩니다.

```plaintext
PUT /users/:id/custom_attributes/:key
PUT /groups/:id/custom_attributes/:key
PUT /projects/:id/custom_attributes/:key
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id` | 정수 | 예 | 리소스의 ID |
| `key` | 문자열 | 예 | 사용자 정의 특성의 키 |
| `value` | 문자열 | 예 | 사용자 정의 특성의 값 |

```shell
curl --request PUT \
   --header "PRIVATE-TOKEN: <your_access_token>" \
   --data "value=Greenland" \
   --url "https://gitlab.example.com/api/v4/users/42/custom_attributes/location"
```

응답 예시:

```json
{
   "key": "location",
   "value": "Greenland"
}
```

## 사용자 정의 특성 삭제 {#delete-custom-attribute}

지정된 리소스의 사용자 정의 특성을 삭제합니다.

```plaintext
DELETE /users/:id/custom_attributes/:key
DELETE /groups/:id/custom_attributes/:key
DELETE /projects/:id/custom_attributes/:key
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id` | 정수 | 예 | 리소스의 ID |
| `key` | 문자열 | 예 | 사용자 정의 특성의 키 |

```shell
curl --request DELETE \
   --header "PRIVATE-TOKEN: <your_access_token>" \
   --url "https://gitlab.example.com/api/v4/users/42/custom_attributes/location"
```
