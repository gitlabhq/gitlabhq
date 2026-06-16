---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: グループSSH証明書API
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com

{{< /details >}}

{{< history >}}

- GitLab 16.4で`ssh_certificates_rest_endpoints`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/421915)されました。デフォルトでは無効になっています。
- GitLab.comの[有効化](https://gitlab.com/gitlab-org/gitlab/-/issues/424501)（GitLab 16.9より）
- GitLab 17.7で[一般提供開始](https://gitlab.com/gitlab-org/gitlab/-/issues/424501)。機能フラグ`ssh_certificates_rest_endpoints`は削除されました。

{{< /history >}}

このAPIを使用して、[グループSSH証明書](../user/group/ssh_certificates.md)を管理します。トップレベルグループのみがSSH証明書を保存できます。

前提条件: 

- トップレベルグループのオーナーである必要があります。

## すべてのグループSSH証明書を一覧表示 {#list-all-group-ssh-certificates}

指定されたグループのすべてのSSH証明書を一覧表示します。

```plaintext
GET /groups/:id/ssh_certificates
```

パラメータは以下のとおりです:

| 属性  | 型   | 必須 | 説明          |
| ---------- | ------ | -------- |----------------------|
| `id`      | 整数 | はい       | グループのID。 |

APIの結果はページネーションされるため、デフォルトでは、`GET`リクエストは一度に20件の結果を返します。詳細については、[ページネーション](rest/_index.md#pagination)を参照してください。

リクエスト例: 

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://primary.example.com/api/v4/groups/90/ssh_certificates"
```

レスポンス例: 

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

## グループSSH証明書を追加 {#add-a-group-ssh-certificate}

指定されたグループにグループSSH証明書を追加します。

```plaintext
POST /groups/:id/ssh_certificates
```

パラメータは以下のとおりです:

| 属性 | 型       | 必須 | 説明                           |
|-----------|------------| -------- |---------------------------------------|
| `id`      | 整数    | はい       | グループのID。                  |
| `key`     | 文字列     | はい       | SSH証明書の公開キー。|
| `title`   | 文字列     | はい       | SSH証明書のタイトル。     |

リクエスト例: 

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/ssh_certificates?title=newtitle&key=ssh-rsa+REDACTED+example%40gitlab.com"
```

レスポンス例: 

```json
{
  "id": 54321,
  "title": "newtitle",
  "key": "ssh-rsa ssh-rsa AAAAB3NzaC1ea2dAAAADAQABAAAAgQDGbLkF44ScxRQi2FfA7VsHgGqptguSbmW26jkJhEiRZpGS4/+UzaaSqc8Psw2OhSsKc5QwfrB/ANpO4LhOjDzhf2FuD8ACkv3R7XtaJ+rN6PlyzoBfLAiSyzxhEoMFDBprTgaiZKgg2yQ9dRH55w3f6XMZ4hnaUae53nQgfQLxFw== example@gitlab.com",
  "created_at": "2023-09-08T12:39:00.172Z"
}
```

## グループSSH証明書を削除 {#delete-a-group-ssh-certificate}

指定されたグループSSH証明書を削除します。

```plaintext
DELETE /groups/:id/ssh_certificates/:id
```

パラメータは以下のとおりです:

| 属性 | 型    | 必須 | 説明                   |
|-----------|---------| -------- |-------------------------------|
| `id`      | 整数 | はい       | グループのID           |
| `id`      | 整数 | はい       | SSH証明書のID |

リクエスト例: 

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/ssh_certificates/12345"
```
