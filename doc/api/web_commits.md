---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Web Commits API
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/442533) in GitLab 17.4.

{{< /history >}}

Use this API to retrieve information about [web commits](../user/project/repository/web_editor.md).

## Get public signing key

Get the GitLab public key for signing web commits.

```plaintext
GET /web_commits/public_key
```

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) and the following
response attributes:

| Attribute    | Type   | Description                                |
|--------------|--------|--------------------------------------------|
| `public_key` | string | GitLab public key for signing web commits. |

Example request:

```shell
curl --request GET \
  --url "https://gitlab.example.com/api/v4/web_commits/public_key"
```

Example response:

```json
[
  {
    "public_key": "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAIEAiPWx6WM4lhHNedGfBpPJNPpZ7yKu+dnn1SJejgt4596k6YjzGGphH2TUxwKzxcKDKKezwkpfnxPkSMkuEspGRt/aZZ9wa++Oi7Qkr8prgHc4soW6NUlfDzpvZK2H5E7eQaSeP3SAwGmQKUFHCddNaP0L+hM7zhFNzjFvpaMgJw0="
  }
]
```
