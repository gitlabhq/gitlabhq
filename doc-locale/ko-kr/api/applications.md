---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 애플리케이션 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

다음 API를 사용하여 인스턴스 전체의 OAuth 애플리케이션을 관리합니다:

- [GitLab을 인증 공급자로 사용](../integration/oauth_provider.md)합니다.
- [사용자를 대신하여 GitLab 리소스에 대한 액세스 허용](oauth2.md)합니다.

> [!note]
> 이 API를 사용하여 그룹 애플리케이션이나 개별 사용자 애플리케이션을 관리할 수 없습니다.

전제 조건:

- 인스턴스에 대한 관리자 액세스 권한이 있어야 합니다.

## 애플리케이션 생성 {#create-an-application}

애플리케이션을 생성합니다.

요청이 성공하면 `200`을 반환합니다.

```plaintext
POST /applications
```

지원되는 특성:

| 특성      | 유형    | 필수 | 설명                      |
|:---------------|:--------|:---------|:---------------------------------|
| `name`         | 문자열  | 예      | 애플리케이션의 이름입니다.         |
| `redirect_uri` | 문자열  | 예      | 애플리케이션의 리디렉션 URI입니다. |
| `scopes`       | 문자열  | 예      | 애플리케이션에서 사용할 수 있는 범위입니다. 여러 범위를 공백으로 구분합니다. |
| `confidential` | 부울 | 아니오       | `true`인 경우 애플리케이션은 클라이언트 보안 자격증명(예: 클라이언트 보안)을 안전하게 저장할 수 있습니다. 비공개 애플리케이션(네이티브 모바일 앱 및 단일 페이지 앱 등)은 클라이언트 보안 자격증명을 노출할 수 있습니다. 지정되지 않은 경우 `true`으로 기본값이 설정됩니다. |

요청 예시:

```shell
curl --request POST \
    --header "PRIVATE-TOKEN: <your_access_token>" \
    --data "name=MyApplication&redirect_uri=http://redirect.uri&scopes=api read_user email" \
    --url "https://gitlab.example.com/api/v4/applications"
```

응답 예시:

```json
{
    "id":1,
    "application_id": "5832fc6e14300a0d962240a8144466eef4ee93ef0d218477e55f11cf12fc3737",
    "application_name": "MyApplication",
    "secret": "ee1dd64b6adc89cf7e2c23099301ccc2c61b441064e9324d963c46902a85ec34",
    "callback_url": "http://redirect.uri",
    "confidential": true,
    "scopes": ["api", "read_user", "email"]
}
```

## 모든 애플리케이션 나열 {#list-all-applications}

모든 애플리케이션을 나열합니다.

```plaintext
GET /applications
```

요청 예시:

```shell
curl --request GET \
    --header "PRIVATE-TOKEN: <your_access_token>" \
    --url "https://gitlab.example.com/api/v4/applications"
```

응답 예시:

```json
[
    {
        "id":1,
        "application_id": "5832fc6e14300a0d962240a8144466eef4ee93ef0d218477e55f11cf12fc3737",
        "application_name": "MyApplication",
        "callback_url": "http://redirect.uri",
        "confidential": true,
        "scopes": ["api", "read_user"]
    }
]
```

> [!note]
> `secret` 값은 이 API에서 노출되지 않습니다.

## 애플리케이션 삭제 {#delete-an-application}

지정된 애플리케이션을 삭제합니다.

요청이 성공하면 `204`을 반환합니다.

```plaintext
DELETE /applications/:id
```

지원되는 특성:

| 특성 | 유형    | 필수 | 설명                                         |
|:----------|:--------|:---------|:----------------------------------------------------|
| `id`      | 정수 | 예      | 애플리케이션의 ID(`application_id` 아님)입니다. |

요청 예시:

```shell
curl --request DELETE \
    --header "PRIVATE-TOKEN: <your_access_token>" \
    --url "https://gitlab.example.com/api/v4/applications/:id"
```

## 애플리케이션 보안 갱신 {#renew-an-application-secret}

{{< history >}}

- GitLab 16.11에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/422420)됨.

{{< /history >}}

지정된 애플리케이션의 보안을 갱신합니다. 요청이 성공하면 `200`을 반환합니다.

```plaintext
POST /applications/:id/renew-secret
```

지원되는 특성:

| 특성 | 유형    | 필수 | 설명                                         |
|:----------|:--------|:---------|:----------------------------------------------------|
| `id`      | 정수 | 예      | 애플리케이션의 ID(`application_id` 아님)입니다. |

요청 예시:

```shell
curl --request POST \
    --header "PRIVATE-TOKEN: <your_access_token>" \
    --url "https://gitlab.example.com/api/v4/applications/:id/renew-secret"
```

응답 예시:

```json
{
    "id":1,
    "application_id": "5832fc6e14300a0d962240a8144466eef4ee93ef0d218477e55f11cf12fc3737",
    "application_name": "MyApplication",
    "secret": "ee1dd64b6adc89cf7e2c23099301ccc2c61b441064e9324d963c46902a85ec34",
    "callback_url": "http://redirect.uri",
    "confidential": true,
    "scopes": ["api", "read_user"]
}
```
