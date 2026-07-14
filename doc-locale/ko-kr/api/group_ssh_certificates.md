---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 그룹 SSH 인증서 API
---

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab.com

{{< /details >}}

{{< history >}}

- GitLab 16.4에서 [도입되었으며](https://gitlab.com/gitlab-org/gitlab/-/issues/421915) [플래그](../administration/feature_flags/_index.md) `ssh_certificates_rest_endpoints`를 포함합니다. 기본적으로 비활성화됨.
- GitLab 16.9에서 [GitLab.com에서 활성화됨](https://gitlab.com/gitlab-org/gitlab/-/issues/424501).
- GitLab 17.7에서 [일반적으로 사용 가능함](https://gitlab.com/gitlab-org/gitlab/-/issues/424501). 기능 플래그 `ssh_certificates_rest_endpoints` 제거됨.

{{< /history >}}

이 API를 사용하여 [그룹용 SSH 인증서](../user/group/ssh_certificates.md)를 관리합니다. 최상위 그룹만 SSH 인증서를 저장할 수 있습니다.

전제 조건:

- 최상위 그룹에서 소유자여야 합니다.

## 모든 그룹 SSH 인증서 나열 {#list-all-group-ssh-certificates}

지정된 그룹의 모든 SSH 인증서를 나열합니다.

```plaintext
GET /groups/:id/ssh_certificates
```

매개변수:

| 속성  | 유형   | 필수 | 설명          |
| ---------- | ------ | -------- |----------------------|
| `id`      | 정수 | 예       | 그룹의 ID입니다. |

기본적으로 `GET` 요청은 API 결과가 페이지가 매겨지기 때문에 한 번에 20개의 결과를 반환합니다. [페이지 매김](rest/_index.md#pagination)을 자세히 읽어보세요.

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://primary.example.com/api/v4/groups/90/ssh_certificates"
```

응답 예시:

```json
[
  {
    "id": 12345,
    "title": "SSH Title 1",
    "key": "ssh-rsa AAAAB3NzaC1ea2dAAAADAQABAAAAgQDGbLkF44ScxRQi2FfA7VsHgGqptguSbmW26jkJhEiRZpGS4/+UzaaSqc8Psw2OhSsKc5QwfrB/ANpO4LhOjDzhf2FuD8ACkv3R7XtaJ+rN6PlyzoBfLAiSyzxhEoMFDBprTgaiZKgg2yQ9dRH55w3f6XMZ4hnaUae53nQgfQLxFw== example@gitlab.com",
    "created_at": "2023-09-08T12:39:00.172Z"
  },
  {
    "id":12346,
    "title":"SSH Title 2",
    "key": "ssh-rsa AAAAB3NzaC1ac2EAAAADAQABAAAAgQDTl/hHfu1F/KlR+QfgM2wUmyxcN5YeiaWluEGIrfXUeJuI+bK6xjpE3+2afHDYtE9VQkeL32KRjefX2d72Jeoa68ewt87Vn8CcGkUTOTpHNzeL8pHMKFs3m7ArSBxNg5vTdgAsq5dbDGNtat7b2WCHTNvtWoON1Jetne30uW2EwQ== example@gitlab.com",
    "created_at": "2023-09-08T12:39:00.244Z"
  }
]
```

## 그룹 SSH 인증서 추가 {#add-a-group-ssh-certificate}

지정된 그룹에 그룹 SSH 인증서를 추가합니다.

```plaintext
POST /groups/:id/ssh_certificates
```

매개변수:

| 속성 | 유형       | 필수 | 설명                           |
|-----------|------------| -------- |---------------------------------------|
| `id`      | 정수    | 예       | 그룹의 ID입니다.                  |
| `key`     | 문자열     | 예       | SSH 인증서의 공개 키입니다.|
| `title`   | 문자열     | 예       | SSH 인증서의 제목입니다.     |

요청 예시:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/ssh_certificates?title=newtitle&key=ssh-rsa+REDACTED+example%40gitlab.com"
```

응답 예시:

```json
{
  "id": 54321,
  "title": "newtitle",
  "key": "ssh-rsa ssh-rsa AAAAB3NzaC1ea2dAAAADAQABAAAAgQDGbLkF44ScxRQi2FfA7VsHgGqptguSbmW26jkJhEiRZpGS4/+UzaaSqc8Psw2OhSsKc5QwfrB/ANpO4LhOjDzhf2FuD8ACkv3R7XtaJ+rN6PlyzoBfLAiSyzxhEoMFDBprTgaiZKgg2yQ9dRH55w3f6XMZ4hnaUae53nQgfQLxFw== example@gitlab.com",
  "created_at": "2023-09-08T12:39:00.172Z"
}
```

## 그룹 SSH 인증서 삭제 {#delete-a-group-ssh-certificate}

지정된 그룹 SSH 인증서를 삭제합니다.

```plaintext
DELETE /groups/:id/ssh_certificates/:id
```

매개변수:

| 속성 | 유형    | 필수 | 설명                   |
|-----------|---------| -------- |-------------------------------|
| `id`      | 정수 | 예       | 그룹의 ID           |
| `id`      | 정수 | 예       | SSH 인증서의 ID |

요청 예시:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/ssh_certificates/12345"
```
