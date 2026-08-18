---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 사용자 애플리케이션 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 다음을 수행하는 사용자 수준 OAuth 애플리케이션을 관리합니다:

- [GitLab을 인증 공급자로 사용](../integration/oauth_provider.md)합니다.
- [사용자를 대신하여 GitLab 리소스에 액세스 허용](oauth2.md)합니다.

> [!note]
> 인스턴스 전체 애플리케이션을 관리하려면 [애플리케이션 API](applications.md)를 사용합니다.

전제 조건:

- 관리자 액세스 또는 애플리케이션을 소유한 사용자로 인증됨.

## 애플리케이션 만들기 {#create-an-application}

인증된 사용자를 위해 새로운 OAuth 애플리케이션을 만듭니다.

요청이 성공하면 `201`을 반환합니다.

```plaintext
POST /user/applications
```

지원되는 속성:

| 속성      | 유형    | 필수 | 설명                      |
|:---------------|:--------|:---------|:---------------------------------|
| `name`         | 문자열  | 예      | 애플리케이션의 이름입니다.         |
| `redirect_uri` | 문자열  | 예      | 애플리케이션의 리디렉션 URI입니다. |
| `scopes`       | 문자열  | 예      | 애플리케이션에서 사용 가능한 범위입니다. 여러 범위는 공백으로 구분합니다. |
| `confidential` | 부울 | 아니요       | `true`인 경우 애플리케이션이 클라이언트 시크릿과 같은 클라이언트 자격 증명을 안전하게 저장할 수 있습니다. 비기밀 애플리케이션(예: 네이티브 모바일 앱 및 Single Page Apps)은 클라이언트 자격 증명을 노출할 수 있습니다. 지정되지 않으면 `true`로 기본값이 설정됩니다. |

요청 예시:

```shell
curl --request POST \
    --header "PRIVATE-TOKEN: <your_access_token>" \
    --data "name=MyApplication&redirect_uri=http://redirect.uri&scopes=api read_user email" \
    --url "https://gitlab.example.com/api/v4/user/applications"
```

응답 예시:

```json
{
    "id":1,
    "application_id": "5832fc6e14300a0d962240a8144466eef4ee93ef0d218477e55f11cf12fc3737",
    "application_name": "MyApplication",
    "secret": "ee1dd64b6adc89cf7e2c23099301ccc2c61b441064e9324d963c46902a85ec34",
    "callback_url": "http://redirect.uri",
    "confidential": true
}
```

## 모든 애플리케이션 나열 {#list-all-applications}

인증된 사용자가 소유한 모든 애플리케이션을 나열합니다.

```plaintext
GET /user/applications
```

요청 예시:

```shell
curl --request GET \
    --header "PRIVATE-TOKEN: <your_access_token>" \
    --url "https://gitlab.example.com/api/v4/user/applications"
```

응답 예시:

```json
[
    {
        "id":1,
        "application_id": "5832fc6e14300a0d962240a8144466eef4ee93ef0d218477e55f11cf12fc3737",
        "application_name": "MyApplication",
        "callback_url": "http://redirect.uri",
        "confidential": true
    }
]
```

## 특정 애플리케이션 검색 {#retrieve-a-specific-application}

인증된 사용자가 소유한 특정 애플리케이션의 세부 정보를 검색합니다.

요청이 성공하면 `200`을 반환합니다.

```plaintext
GET /user/applications/:id
```

지원되는 속성:

| 속성 | 유형    | 필수 | 설명                                         |
|:----------|:--------|:---------|:----------------------------------------------------|
| `id`      | 정수 | 예      | 애플리케이션의 ID입니다. `application_id`과 다릅니다.' |

요청 예시:

```shell
curl --request GET \
    --header "PRIVATE-TOKEN: <your_access_token>" \
    --url "https://gitlab.example.com/api/v4/user/applications/:id"
```

응답 예시:

```json
{
    "id":1,
    "application_id": "5832fc6e14300a0d962240a8144466eef4ee93ef0d218477e55f11cf12fc3737",
    "application_name": "MyApplication",
    "callback_url": "http://redirect.uri",
    "confidential": true
}
```

## 애플리케이션 업데이트 {#update-an-application}

인증된 사용자가 소유한 기존 애플리케이션을 업데이트합니다.

요청이 성공하면 `200`을 반환합니다.

```plaintext
PUT /user/applications/:id
```

지원되는 속성:

| 속성      | 유형    | 필수 | 설명                      |
|:---------------|:--------|:---------|:---------------------------------|
| `id`           | 정수 | 예      | 애플리케이션의 ID입니다. `application_id`과 다릅니다.' |
| `name`         | 문자열  | 아니요       | 애플리케이션의 이름입니다.         |
| `scopes`       | 문자열  | 아니요       | 애플리케이션에서 사용 가능한 범위입니다. 여러 범위는 공백으로 구분합니다. |

요청 예시:

```shell
curl --request PUT \
    --header "PRIVATE-TOKEN: <your_access_token>" \
    --data "name=UpdatedApplication" \
    --url "https://gitlab.example.com/api/v4/user/applications/:id"
```

응답 예시:

```json
{
    "id":1,
    "application_id": "5832fc6e14300a0d962240a8144466eef4ee93ef0d218477e55f11cf12fc3737",
    "application_name": "UpdatedApplication",
    "callback_url": "http://redirect.uri",
    "confidential": true
}
```

## 애플리케이션 삭제 {#delete-an-application}

인증된 사용자가 소유한 지정된 애플리케이션을 삭제합니다.

요청이 성공하면 `204`을 반환합니다.

```plaintext
DELETE /user/applications/:id
```

지원되는 속성:

| 속성 | 유형    | 필수 | 설명                                         |
|:----------|:--------|:---------|:----------------------------------------------------|
| `id`      | 정수 | 예      | 애플리케이션의 ID입니다. `application_id`과 다릅니다.' |

요청 예시:

```shell
curl --request DELETE \
    --header "PRIVATE-TOKEN: <your_access_token>" \
    --url "https://gitlab.example.com/api/v4/user/applications/:id"
```
