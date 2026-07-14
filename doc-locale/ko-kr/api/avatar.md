---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 아바타 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 사용자 아바타와 상호작용합니다.

## 사용자 계정 아바타 검색 {#retrieve-user-account-avatar}

지정된 공개 이메일 주소와 연결된 사용자 계정 [아바타](../user/profile/_index.md#access-your-user-settings)의 URL을 검색합니다. 이 엔드포인트는 인증이 필요하지 않습니다.

- 성공하면 아바타의 URL을 반환합니다.
- 지정된 이메일 주소와 연결된 계정이 없으면 외부 아바타 서비스의 결과를 반환합니다.
- 공개 범위가 제한되어 있고 요청이 인증되지 않으면 `403 Forbidden`을 반환합니다.

```plaintext
GET /avatar?email=admin@example.com
```

매개변수:

| 속성 | 유형    | 필수 | 설명 |
| --------- | ------- | -------- | ----------- |
| `email`   | 문자열  | 예      | 계정의 공개 이메일 주소입니다. |
| `size`    | 정수 | 아니요       | 단일 픽셀 크기입니다. `Gravatar` 또는 구성된 `Libravatar` 서버에서만 아바타 조회에 사용됩니다. |

요청 예시:

```shell
curl --request GET \
  --url "https://gitlab.example.com/api/v4/avatar?email=admin@example.com&size=32"
```

응답 예시:

```json
{
  "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=64&d=identicon"
}
```

## 관련 항목 {#related-topics}

- [직접 아바타 업로드](users.md#upload-an-avatar-for-yourself).
- [프로젝트 아바타 업로드](projects.md#upload-a-project-avatar).
