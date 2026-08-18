---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 웹 커밋 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 17.4에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/442533)되었습니다.

{{< /history >}}

이 API를 사용하여 [웹 커밋](../user/project/repository/web_editor.md)에 대한 정보를 검색합니다.

## 공개 서명 키 검색 {#retrieve-public-signing-key}

웹 커밋에 서명하기 위한 GitLab 공개 키를 검색합니다.

```plaintext
GET /web_commits/public_key
```

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)와 다음 응답 속성을 반환합니다:

| 속성    | 유형   | 설명                                |
|--------------|--------|--------------------------------------------|
| `public_key` | 문자열 | 웹 커밋에 서명하기 위한 GitLab 공개 키입니다. |

요청 예시:

```shell
curl --request GET \
  --url "https://gitlab.example.com/api/v4/web_commits/public_key"
```

응답 예시:

```json
[
  {
    "public_key": "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAIEAiPWx6WM4lhHNedGfBpPJNPpZ7yKu+dnn1SJejgt4596k6YjzGGphH2TUxwKzxcKDKKezwkpfnxPkSMkuEspGRt/aZZ9wa++Oi7Qkr8prgHc4soW6NUlfDzpvZK2H5E7eQaSeP3SAwGmQKUFHCddNaP0L+hM7zhFNzjFvpaMgJw0="
  }
]
```
