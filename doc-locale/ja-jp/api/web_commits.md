---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: WebコミットAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 17.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/442533)されました。

{{< /history >}}

このAPIを使用して、Web UIで作成されたコミットに関する取得を行います。

## 公開署名キーの取得 {#get-public-signing-key}

Webコミットに署名するためのGitLab公開キーを取得します。

```plaintext
GET /web_commits/public_key
```

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します:

| 属性    | 型   | 説明                                |
|--------------|--------|--------------------------------------------|
| `public_key` | 文字列 | Webコミットに署名するためのGitLab公開キー。 |

リクエスト例:

```shell
curl --request GET \
  --url "https://gitlab.example.com/api/v4/web_commits/public_key"
```

レスポンス例:

```json
[
  {
    "public_key": "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAIEAiPWx6WM4lhHNedGfBpPJNPpZ7yKu+dnn1SJejgt4596k6YjzGGphH2TUxwKzxcKDKKezwkpfnxPkSMkuEspGRt/aZZ9wa++Oi7Qkr8prgHc4soW6NUlfDzpvZK2H5E7eQaSeP3SAwGmQKUFHCddNaP0L+hM7zhFNzjFvpaMgJw0="
  }
]
```
