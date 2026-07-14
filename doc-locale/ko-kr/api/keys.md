---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Keys API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 [SSH 키](../user/ssh.md)에 대한 정보를 검색합니다. 배포 키 지문에 대한 쿼리는 해당 키를 사용하는 프로젝트에 대한 정보도 검색합니다.

API 호출에서 SHA256 지문을 사용하는 경우 지문을 URL 인코딩해야 합니다.

## SSH 키 ID로 사용자 검색 {#retrieve-user-by-ssh-key-id}

전제 조건:

- 인스턴스에 대한 관리자 액세스 권한이 있어야 합니다.

지정된 SSH 키를 소유한 사용자에 대한 정보를 검색합니다.

```plaintext
GET /keys/:id
```

지원되는 속성:

| 속성 | 유형    | 필수 | 설명           |
|-----------|---------|----------|-----------------------|
| `id`      | 정수 | 예      | SSH 키의 ID입니다. |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)와 다음 응답 속성을 반환합니다:

| 속성           | 유형    | 설명 |
|---------------------|---------|-------------|
| `created_at`        | 문자열  | ISO 8601 형식의 SSH 키 생성 날짜 및 시간입니다. |
| `expires_at`        | 문자열  | ISO 8601 형식의 SSH 키 만료 날짜 및 시간입니다. |
| `id`                | 정수 | SSH 키의 ID입니다. |
| `key`               | 문자열  | SSH 키 콘텐츠입니다. |
| `last_used_at`      | 문자열  | ISO 8601 형식의 SSH 키 마지막 사용 날짜 및 시간입니다. |
| `title`             | 문자열  | SSH 키의 제목입니다. |
| `usage_type`        | 문자열  | SSH 키의 사용 유형입니다(예: `auth` 또는 `auth_and_signing`). |
| `user`              | 객체  | SSH 키와 연결된 사용자입니다. |
| `user.avatar_url`   | 문자열  | 사용자 아바타의 URL입니다. |
| `user.bio`          | 문자열  | 사용자의 약력입니다. |
| `user.created_at`   | 문자열  | ISO 8601 형식의 사용자 계정 생성 날짜 및 시간입니다. |
| `user.id`           | 정수 | 사용자의 ID입니다. |
| `user.linkedin`     | 문자열  | 사용자의 LinkedIn 프로필 URL입니다. |
| `user.location`     | 문자열  | 사용자의 위치입니다. |
| `user.name`         | 문자열  | 사용자의 이름입니다. |
| `user.organization` | 문자열  | 사용자의 조직입니다. |
| `user.public_email` | 문자열  | 사용자의 공개 이메일 주소입니다. |
| `user.state`        | 문자열  | 사용자의 상태입니다. |
| `user.twitter`      | 문자열  | 사용자의 Twitter 프로필 URL입니다. |
| `user.username`     | 문자열  | 사용자의 사용자 이름입니다. |
| `user.web_url`      | 문자열  | 사용자 프로필의 URL입니다. |
| `user.website_url`  | 문자열  | 사용자의 웹 사이트 URL입니다. |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/keys/1"
```

응답 예시:

```json
{
  "id": 1,
  "title": "Sample key 25",
  "key": "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAIEAiPWx6WM4lhHNedGfBpPJNPpZ7yKu+dnn1SJejgt1256k6YjzGGphH2TUxwKzxcKDKKezwkpfnxPkSMkuEspGRt/aZZ9wa++Oi7Qkr8prgHc4soW6NUlfDzpvZK2H5E7eQaSeP3SAwGmQKUFHCddNaP0L+hM7zhFNzjFvpaMgJw0=",
  "created_at": "2015-09-03T07:24:44.627Z",
  "expires_at": "2020-05-05T00:00:00.000Z",
  "last_used_at": "2020-04-07T00:00:00.000Z",
  "usage_type": "auth",
  "user": {
    "name": "John Smith",
    "username": "john_smith",
    "id": 25,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/cfa35b8cd2ec278026357769582fa563?s=40\u0026d=identicon",
    "web_url": "http://localhost:3000/john_smith",
    "created_at": "2015-09-03T07:24:01.670Z",
    "bio": null,
    "location": null,
    "public_email": "john@example.com",
    "linkedin": "",
    "twitter": "",
    "website_url": "",
    "organization": null,
    "last_sign_in_at": "2015-09-03T07:24:01.670Z",
    "confirmed_at": "2015-09-03T07:24:01.670Z",
    "last_activity_on": "2015-09-03",
    "email": "john@example.com",
    "theme_id": 2,
    "color_scheme_id": 1,
    "projects_limit": 10,
    "current_sign_in_at": null,
    "identities": [],
    "can_create_group": true,
    "can_create_project": true,
    "two_factor_enabled": false,
    "external": false,
    "private_profile": null
  }
}
```

## SSH 키 지문으로 사용자 검색 {#retrieve-user-by-ssh-key-fingerprint}

전제 조건:

- 인스턴스에 대한 관리자 액세스 권한이 있어야 합니다.

지정된 SSH 키를 소유한 사용자에 대한 정보를 검색합니다.

```plaintext
GET /keys
```

지원되는 속성:

| 속성     | 유형   | 필수 | 설명                    |
|---------------|--------|----------|--------------------------------|
| `fingerprint` | 문자열 | 예      | SSH 키의 지문입니다. |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)와 다음 응답 속성을 반환합니다:

| 속성                 | 유형    | 설명 |
|---------------------------|---------|-------------|
| `created_at`              | 문자열  | ISO 8601 형식의 SSH 키 생성 날짜 및 시간입니다. |
| `expires_at`              | 문자열  | ISO 8601 형식의 SSH 키 만료 날짜 및 시간입니다. |
| `id`                      | 정수 | SSH 키의 ID입니다. |
| `key`                     | 문자열  | SSH 키 콘텐츠입니다. |
| `last_used_at`            | 문자열  | ISO 8601 형식의 SSH 키 마지막 사용 날짜 및 시간입니다. |
| `title`                   | 문자열  | SSH 키의 제목입니다. |
| `usage_type`              | 문자열  | SSH 키의 사용 유형입니다(예: `auth` 또는 `auth_and_signing`). |
| `user`                    | 객체  | SSH 키와 연결된 사용자입니다. |
| `user.avatar_url`         | 문자열  | 사용자 아바타의 URL입니다. |
| `user.bio`                | 문자열  | 사용자의 약력입니다. |
| `user.can_create_group`   | 부울 | `true`인 경우 사용자가 그룹을 생성할 수 있습니다. |
| `user.can_create_project` | 부울 | `true`인 경우 사용자가 프로젝트를 생성할 수 있습니다. |
| `user.color_scheme_id`    | 정수 | 사용자의 색상 구성표 ID입니다. |
| `user.confirmed_at`       | 문자열  | ISO 8601 형식의 사용자 확인 날짜 및 시간입니다. |
| `user.created_at`         | 문자열  | ISO 8601 형식의 사용자 계정 생성 날짜 및 시간입니다. |
| `user.current_sign_in_at` | 문자열  | ISO 8601 형식의 사용자 현재 로그인 날짜 및 시간입니다. |
| `user.email`              | 문자열  | 사용자의 이메일 주소입니다. |
| `user.external`           | 부울 | `true`인 경우 사용자는 외부 사용자입니다. |
| `user.id`                 | 정수 | 사용자의 ID입니다. |
| `user.identities`         | 배열   | 사용자와 연결된 신원입니다. |
| `user.last_activity_on`   | 문자열  | 사용자의 마지막 활동 날짜입니다. |
| `user.last_sign_in_at`    | 문자열  | ISO 8601 형식의 사용자 마지막 로그인 날짜 및 시간입니다. |
| `user.linkedin`           | 문자열  | 사용자의 LinkedIn 프로필 URL입니다. |
| `user.location`           | 문자열  | 사용자의 위치입니다. |
| `user.name`               | 문자열  | 사용자의 이름입니다. |
| `user.organization`       | 문자열  | 사용자의 조직입니다. |
| `user.private_profile`    | 부울 | `true`인 경우 사용자의 프로필은 비공개입니다. |
| `user.projects_limit`     | 정수 | 사용자의 프로젝트 제한입니다. |
| `user.public_email`       | 문자열  | 사용자의 공개 이메일 주소입니다. |
| `user.state`              | 문자열  | 사용자 계정의 상태입니다. |
| `user.theme_id`           | 정수 | 사용자의 테마 ID입니다. |
| `user.twitter`            | 문자열  | 사용자의 Twitter 프로필 URL입니다. |
| `user.two_factor_enabled` | 부울 | `true`인 경우 사용자에 대해 2단계 인증이 활성화됩니다. |
| `user.username`           | 문자열  | 사용자의 사용자 이름입니다. |
| `user.web_url`            | 문자열  | 사용자 프로필의 URL입니다. |
| `user.website_url`        | 문자열  | 사용자의 웹 사이트 URL입니다. |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/keys?fingerprint=ba:81:59:68:d7:6c:cd:02:02:bf:6a:9b:55:4e:af:d1"
```

응답 예시:

```json
{
  "id": 1,
  "title": "Sample key 1",
  "key": "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAIEAiPWx6WM4lhHNedGfBpPJNPpZ7yKu+dnn1SJejgt1016k6YjzGGphH2TUxwKzxcKDKKezwkpfnxPkSMkuEspGRt/aZZ9wa++Oi7Qkr8prgHc4soW6NUlfDzpvZK2H5E7eQaSeP3SAwGmQKUFHCddNaP0L+hM7zhFNzjFvpaMgJw0=",
  "created_at": "2019-11-14T15:11:13.222Z",
  "expires_at": "2020-05-05T00:00:00.000Z",
  "last_used_at": "2020-04-07T00:00:00.000Z",
  "usage_type": "auth",
  "user": {
    "id": 1,
    "name": "Administrator",
    "username": "root",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
    "web_url": "http://0.0.0.0:3000/root",
    "created_at": "2019-11-14T15:09:34.831Z",
    "bio": null,
    "location": null,
    "public_email": "",
    "linkedin": "",
    "twitter": "",
    "website_url": "",
    "organization": null,
    "last_sign_in_at": "2019-11-16T22:41:26.663Z",
    "confirmed_at": "2019-11-14T15:09:34.575Z",
    "last_activity_on": "2019-11-20",
    "email": "admin@example.com",
    "theme_id": 1,
    "color_scheme_id": 1,
    "projects_limit": 100000,
    "current_sign_in_at": "2019-11-19T14:42:18.078Z",
    "identities": [],
    "can_create_group": true,
    "can_create_project": true,
    "two_factor_enabled": false,
    "external": false,
    "private_profile": false,
    "shared_runners_minutes_limit": null,
    "extra_shared_runners_minutes_limit": null
  }
}
```

## 배포 키 지문으로 사용자 검색 {#retrieve-user-by-deploy-key-fingerprint}

지정된 배포 키 지문을 사용하는 사용자 및 프로젝트에 대한 정보를 검색합니다. 배포 키는 생성 사용자에게 바인딩됩니다.

```plaintext
GET /keys
```

지원되는 속성:

| 속성     | 유형   | 필수 | 설명                        |
|---------------|--------|----------|------------------------------------|
| `fingerprint` | 문자열 | 예      | 배포 키의 지문입니다.   |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)와 다음 응답 속성을 반환합니다:

| 속성                                 | 유형    | 설명 |
|-------------------------------------------|---------|-------------|
| `created_at`                              | 문자열  | ISO 8601 형식의 배포 키 생성 날짜 및 시간입니다. |
| `deploy_keys_projects`                    | 배열   | 배포 키 프로젝트 정보입니다. |
| `deploy_keys_projects[].can_push`         | 부울 | `true`인 경우 배포 키가 프로젝트로 푸시할 수 있습니다. |
| `deploy_keys_projects[].created_at`       | 문자열  | ISO 8601 형식의 생성 날짜 및 시간입니다. |
| `deploy_keys_projects[].deploy_key_id`    | 정수 | 배포 키의 ID입니다. |
| `deploy_keys_projects[].id`               | 정수 | 배포 키 프로젝트 관계의 ID입니다. |
| `deploy_keys_projects[].project_id`       | 정수 | 프로젝트의 ID입니다. |
| `deploy_keys_projects[].updated_at`       | 문자열  | ISO 8601 형식의 마지막 업데이트 날짜 및 시간입니다. |
| `expires_at`                              | 문자열  | ISO 8601 형식의 배포 키 만료 날짜 및 시간입니다. |
| `id`                                      | 정수 | 배포 키의 ID입니다. |
| `key`                                     | 문자열  | 배포 키 콘텐츠입니다. |
| `last_used_at`                            | 문자열  | ISO 8601 형식의 배포 키 마지막 사용 날짜 및 시간입니다. |
| `title`                                   | 문자열  | 배포 키의 제목입니다. |
| `usage_type`                              | 문자열  | 배포 키의 사용 유형입니다(예: `auth` 또는 `auth_and_signing`). |
| `user`                                    | 객체  | 배포 키와 연결된 사용자입니다. |
| `user.avatar_url`                         | 문자열  | 사용자 아바타의 URL입니다. |
| `user.bio`                                | 문자열  | 사용자의 약력입니다. |
| `user.can_create_group`                   | 부울 | `true`인 경우 사용자가 그룹을 생성할 수 있습니다. |
| `user.can_create_project`                 | 부울 | `true`인 경우 사용자가 프로젝트를 생성할 수 있습니다. |
| `user.color_scheme_id`                    | 정수 | 사용자의 색상 구성표 ID입니다. |
| `user.confirmed_at`                       | 문자열  | ISO 8601 형식의 사용자 확인 날짜 및 시간입니다. |
| `user.created_at`                         | 문자열  | ISO 8601 형식의 사용자 계정 생성 날짜 및 시간입니다. |
| `user.current_sign_in_at`                 | 문자열  | ISO 8601 형식의 사용자 현재 로그인 날짜 및 시간입니다. |
| `user.email`                              | 문자열  | 사용자의 이메일 주소입니다. |
| `user.external`                           | 부울 | `true`인 경우 사용자는 외부 사용자입니다. |
| `user.extra_shared_runners_minutes_limit` | 정수 | 사용자의 추가 공유 러너 분 제한입니다. |
| `user.id`                                 | 정수 | 사용자의 ID입니다. |
| `user.identities`                         | 배열   | 사용자와 연결된 신원입니다. |
| `user.last_activity_on`                   | 문자열  | 사용자의 마지막 활동 날짜입니다. |
| `user.last_sign_in_at`                    | 문자열  | ISO 8601 형식의 사용자 마지막 로그인 날짜 및 시간입니다. |
| `user.linkedin`                           | 문자열  | 사용자의 LinkedIn 프로필 URL입니다. |
| `user.location`                           | 문자열  | 사용자의 위치입니다. |
| `user.name`                               | 문자열  | 사용자의 이름입니다. |
| `user.organization`                       | 문자열  | 사용자의 조직입니다. |
| `user.private_profile`                    | 부울 | `true`인 경우 사용자의 프로필은 비공개입니다. |
| `user.projects_limit`                     | 정수 | 사용자의 프로젝트 제한입니다. |
| `user.public_email`                       | 문자열  | 사용자의 공개 이메일 주소입니다. |
| `user.shared_runners_minutes_limit`       | 정수 | 사용자의 공유 러너 분 제한입니다. |
| `user.state`                              | 문자열  | 사용자 계정의 상태입니다. |
| `user.theme_id`                           | 정수 | 사용자의 테마 ID입니다. |
| `user.twitter`                            | 문자열  | 사용자의 Twitter 프로필 URL입니다. |
| `user.two_factor_enabled`                 | 부울 | `true`인 경우 사용자에 대해 2단계 인증이 활성화됩니다. |
| `user.username`                           | 문자열  | 사용자의 사용자 이름입니다. |
| `user.web_url`                            | 문자열  | 사용자 프로필의 URL입니다. |
| `user.website_url`                        | 문자열  | 사용자의 웹 사이트 URL입니다. |

MD5 지문이 있는 요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/keys?fingerprint=ba:81:59:68:d7:6c:cd:02:02:bf:6a:9b:55:4e:af:d1"
```

SHA256 지문(URL 인코딩)이 있는 요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/keys?fingerprint=SHA256%3AnUhzNyftwADy8AH3wFY31tAKs7HufskYTte2aXo%2FlCg"
```

SHA256 예시에서 `/`은(는) `%2F`(으)로 표시되고 `:`은(는) `%3A`(으)로 표시됩니다.

응답 예시:

```json
{
  "id": 1,
  "title": "Sample key 1",
  "key": "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAIEAiPWx6WM4lhHNedGfBpPJNPpZ7yKu+dnn1SJejgt1016k6YjzGGphH2TUxwKzxcKDKKezwkpfnxPkSMkuEspGRt/aZZ9wa++Oi7Qkr8prgHc4soW6NUlfDzpvZK2H5E7eQaSeP3SAwGmQKUFHCddNaP0L+hM7zhFNzjFvpaMgJw0=",
  "created_at": "2019-11-14T15:11:13.222Z",
  "expires_at": "2020-05-05T00:00:00.000Z",
  "last_used_at": "2020-04-07T00:00:00.000Z",
  "usage_type": "auth",
  "user": {
    "id": 1,
    "name": "Administrator",
    "username": "root",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
    "web_url": "http://0.0.0.0:3000/root",
    "created_at": "2019-11-14T15:09:34.831Z",
    "bio": null,
    "location": null,
    "public_email": "",
    "linkedin": "",
    "twitter": "",
    "website_url": "",
    "organization": null,
    "last_sign_in_at": "2019-11-16T22:41:26.663Z",
    "confirmed_at": "2019-11-14T15:09:34.575Z",
    "last_activity_on": "2019-11-20",
    "email": "admin@example.com",
    "theme_id": 1,
    "color_scheme_id": 1,
    "projects_limit": 100000,
    "current_sign_in_at": "2019-11-19T14:42:18.078Z",
    "identities": [],
    "can_create_group": true,
    "can_create_project": true,
    "two_factor_enabled": false,
    "external": false,
    "private_profile": false,
    "shared_runners_minutes_limit": null,
    "extra_shared_runners_minutes_limit": null
  },
  "deploy_keys_projects": [
    {
      "id": 1,
      "deploy_key_id": 1,
      "project_id": 1,
      "created_at": "2020-01-09T07:32:52.453Z",
      "updated_at": "2020-01-09T07:32:52.453Z",
      "can_push": false
    }
  ]
}
```
