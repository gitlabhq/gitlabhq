---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: デプロイキーAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、[デプロイキー](../user/project/deploy_keys/_index.md)を操作します。

## デプロイキーのフィンガープリント {#deploy-key-fingerprints}

{{< history >}}

- [導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/91302) GitLab 15.2の`fingerprint_sha256`属性。

{{< /history >}}

一部のエンドポイントは、レスポンスの一部として公開キーのフィンガープリントを返します。これらのフィンガープリントを使用して、デプロイキーを作成したユーザーを識別できます。詳細については、[デプロイキーフィンガープリントでユーザーを取得する](keys.md#get-user-by-deploy-key-fingerprint)を参照してください。

次の属性には、デプロイキーのフィンガープリントが含まれています:

- `fingerprint`: MD5ハッシュを使用します。連邦情報処理規格対応システムでは利用できません。
- `fingerprint_sha256`: SHA256ハッシュを使用します。

## すべてのデプロイキーをリスト表示 {#list-all-deploy-keys}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- `projects_with_readonly_access`[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/119147) GitLab 16.0。

{{< /history >}}

GitLabインスタンスのすべてのプロジェクトにわたるすべてのデプロイキーのリストを取得します。このエンドポイントには管理者アクセス権が必要で、GitLab.comでは使用できません。

```plaintext
GET /deploy_keys
```

サポートされている属性は以下のとおりです:

| 属性   | 型     | 必須 | 説明           |
|:------------|:---------|:---------|:----------------------|
| `public` | ブール値 | いいえ | 公開されているデプロイキーのみを返します。`false`がデフォルトです。 |

リクエストの例:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/deploy_keys?public=true"
```

レスポンス例:

```json
[
  {
    "id": 1,
    "title": "Public key",
    "key": "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAAgQDNJAkI3Wdf0r13c8a5pEExB2YowPWCSVzfZV22pNBc1CuEbyYLHpUyaD0GwpGvFdx2aP7lMEk35k6Rz3ccBF6jRaVJyhsn5VNnW92PMpBJ/P1UebhXwsFHdQf5rTt082cSxWuk61kGWRQtk4ozt/J2DF/dIUVaLvc+z4HomT41fQ==",
    "fingerprint": "4a:9d:64:15:ed:3a:e6:07:6e:89:36:b3:3b:03:05:d9",
    "fingerprint_sha256": "SHA256:Jrs3LD1Ji30xNLtTVf9NDCj7kkBgPBb2pjvTZ3HfIgU",
    "created_at": "2013-10-02T10:12:29Z",
    "expires_at": null,
    "projects_with_write_access": [
      {
        "id": 73,
        "description": null,
        "name": "project2",
        "name_with_namespace": "Sidney Jones / project2",
        "path": "project2",
        "path_with_namespace": "sidney_jones/project2",
        "created_at": "2021-10-25T18:33:17.550Z"
      },
      {
        "id": 74,
        "description": null,
        "name": "project3",
        "name_with_namespace": "Sidney Jones / project3",
        "path": "project3",
        "path_with_namespace": "sidney_jones/project3",
        "created_at": "2021-10-25T18:33:17.666Z"
      }
    ],
    "projects_with_readonly_access": []
  },
  {
    "id": 3,
    "title": "Another Public key",
    "key": "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAAgQDIJFwIL6YNcCgVBLTHgM6hzmoL5vf0ThDKQMWT3HrwCjUCGPwR63vBwn6+/Gx+kx+VTo9FuojzR0O4XfwD3LrYA+oT3ETbn9U4e/VS4AH/G4SDMzgSLwu0YuPe517FfGWhWGQhjiXphkaQ+6bXPmcASWb0RCO5+pYlGIfxv4eFGQ==",
    "fingerprint": "0b:cf:58:40:b9:23:96:c7:ba:44:df:0e:9e:87:5e:75",
    "": "SHA256:lGI/Ys/Wx7PfMhUO1iuBH92JQKYN+3mhJZvWO4Q5ims",
    "created_at": "2013-10-02T11:12:29Z",
    "expires_at": null,
    "projects_with_write_access": [],
    "projects_with_readonly_access": [
      {
        "id": 74,
        "description": null,
        "name": "project3",
        "name_with_namespace": "Sidney Jones / project3",
        "path": "project3",
        "path_with_namespace": "sidney_jones/project3",
        "created_at": "2021-10-25T18:33:17.666Z"
      }
    ]
  }
]
```

## デプロイキーを追加 {#add-deploy-key}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 17.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/478476)されました。

{{< /history >}}

GitLabインスタンスのデプロイキーを作成します。このエンドポイントには管理者アクセス権が必要です。

```plaintext
POST /deploy_keys
```

サポートされている属性は以下のとおりです:

| 属性     | 型     | 必須 | 説明                                                                                                                       |
|:--------------|:---------|:---------|:----------------------------------------------------------------------------------------------------------------------------------|
| `key`         | 文字列   | はい      | 新しいデプロイキー                                                                                                                    |
| `title`       | 文字列   | はい      | 新しいデプロイキーのタイトル                                                                                                            |
| `expires_at`  | 日時 | いいえ       | デプロイキーの有効期限。値が指定されていない場合、有効期限は切れません。ISO 8601形式（`2024-12-31T08:00:00Z`）で指定します。 |

リクエスト例:

```shell
curl --request POST \ --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data "{"title": "My deploy key", "key": "ssh-rsa AAAA...", "expired_at": "2024-12-31T08:00:00Z"}" \
     --url "https://gitlab.example.com/api/v4/deploy_keys/"
```

レスポンス例:

```json
{
  "id": 5,
  "title": "My deploy key",
  "key": "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAAgQDNJAkI3Wdf0r13c8a5pEExB2YowPWCSVzfZV22pNBc1CuEbyYLHpUyaD0GwpGvFdx2aP7lMEk35k6Rz3ccBF6jRaVJyhsn5VNnW92PMpBJ/P1UebhXwsFHdQf5rTt082cSxWuk61kGWRQtk4ozt/J2DF/dIUVaLvc+z4HomT41fQ==",
  "fingerprint": "4a:9d:64:15:ed:3a:e6:07:6e:89:36:b3:3b:03:05:d9",
  "fingerprint_sha256": "SHA256:Jrs3LD1Ji30xNLtTVf9NDCj7kkBgPBb2pjvTZ3HfIgU",
  "usage_type": "auth_and_signing",
  "created_at": "2024-10-03T01:32:21.992Z",
  "expires_at": "2024-12-31T08:00:00.000Z"
}
```

## プロジェクトのデプロイキーをリスト表示 {#list-deploy-keys-for-project}

プロジェクトのデプロイキーのリストを取得します。

```plaintext
GET /projects/:id/deploy_keys
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 整数または文字列 | はい | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/deploy_keys"
```

レスポンス例:

```json
[
  {
    "id": 1,
    "title": "Public key",
    "key": "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAAgQDNJAkI3Wdf0r13c8a5pEExB2YowPWCSVzfZV22pNBc1CuEbyYLHpUyaD0GwpGvFdx2aP7lMEk35k6Rz3ccBF6jRaVJyhsn5VNnW92PMpBJ/P1UebhXwsFHdQf5rTt082cSxWuk61kGWRQtk4ozt/J2DF/dIUVaLvc+z4HomT41fQ==",
    "fingerprint": "4a:9d:64:15:ed:3a:e6:07:6e:89:36:b3:3b:03:05:d9",
    "fingerprint_sha256": "SHA256:Jrs3LD1Ji30xNLtTVf9NDCj7kkBgPBb2pjvTZ3HfIgU",
    "created_at": "2013-10-02T10:12:29Z",
    "expires_at": null,
    "can_push": false
  },
  {
    "id": 3,
    "title": "Another Public key",
    "key": "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAAgQDIJFwIL6YNcCgVBLTHgM6hzmoL5vf0ThDKQMWT3HrwCjUCGPwR63vBwn6+/Gx+kx+VTo9FuojzR0O4XfwD3LrYA+oT3ETbn9U4e/VS4AH/G4SDMzgSLwu0YuPe517FfGWhWGQhjiXphkaQ+6bXPmcASWb0RCO5+pYlGIfxv4eFGQ==",
    "fingerprint": "0b:cf:58:40:b9:23:96:c7:ba:44:df:0e:9e:87:5e:75",
    "": "SHA256:lGI/Ys/Wx7PfMhUO1iuBH92JQKYN+3mhJZvWO4Q5ims",
    "created_at": "2013-10-02T11:12:29Z",
    "expires_at": null,
    "can_push": false
  }
]
```

## ユーザーのプロジェクトデプロイキーをリスト表示 {#list-project-deploy-keys-for-user}

{{< history >}}

- GitLab 15.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/88917)されました。

{{< /history >}}

指定されたユーザー（リクエスタ）と認証済みユーザー（リクエスタ）の共通[プロジェクトデプロイキー](../user/project/deploy_keys/_index.md#scope)のリストを取得します。これは、**enabled project keys from the common projects of requester and requestee**（リクエスタとリクエステの共通プロジェクトからのキーを有効にしたプロジェクトのみ）をリストします。

```plaintext
GET /users/:id_or_username/project_deploy_keys
```

パラメータは以下のとおりです:

| 属性          | 型   | 必須 | 説明                                                        |
|------------------- |--------|----------|------------------------------------------------------------------- |
| `id_or_username`   | 文字列 | はい      | プロジェクトのデプロイキーを取得するユーザーのIDまたはユーザー名。 |

```json
[
  {
    "id": 1,
    "title": "Key A",
    "created_at": "2022-05-30T12:28:27.855Z",
    "expires_at": null,
    "key": "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILkYXU2fVeO4/0rDCSsswP5iIX2+B6tv15YT3KObgyDl Key",
    "fingerprint": "40:8e:fa:df:70:f7:a7:06:1e:0d:6f:ae:f2:27:92:01",
    "fingerprint_sha256": "SHA256:Ojq2LZW43BFK/AMP81jBkDGn9YpPWYRNcViKBB44LPU"
  },
  {
    "id": 2,
    "title": "Key B",
    "created_at": "2022-05-30T13:34:56.219Z",
    "expires_at": null,
    "key": "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAAgQDNJAkI3Wdf0r13c8a5pEExB2YowPWCSVzfZV22pNBc1CuEbyYLHpUyaD0GwpGvFdx2aP7lMEk35k6Rz3ccBF6jRaVJyhsn5VNnW92PMpBJ/P1UebhXwsFHdQf5rTt082cSxWuk61kGWRQtk4ozt/J2DF/dIUVaLvc+z4HomT41fQ==",
    "fingerprint": "4a:9d:64:15:ed:3a:e6:07:6e:89:36:b3:3b:03:05:d9",
    "": "SHA256:Jrs3LD1Ji30xNLtTVf9NDCj7kkBgPBb2pjvTZ3HfIgU"
  }
]
```

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/users/20/project_deploy_keys"
```

レスポンス例:

```json
[
  {
    "id": 1,
    "title": "Key A",
    "created_at": "2022-05-30T12:28:27.855Z",
    "expires_at": "2022-10-30T12:28:27.855Z",
    "key": "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILkYXU2fVeO4/0rDCSsswP5iIX2+B6tv15YT3KObgyDl Key",
    "fingerprint": "40:8e:fa:df:70:f7:a7:06:1e:0d:6f:ae:f2:27:92:01",
    "fingerprint_sha256": "SHA256:Ojq2LZW43BFK/AMP81jBkDGn9YpPWYRNcViKBB44LPU"
  }
]
```

## 単一のデプロイキーを取得 {#get-a-single-deploy-key}

単一のキーを取得します。

```plaintext
GET /projects/:id/deploy_keys/:key_id
```

パラメータは以下のとおりです:

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id`      | 整数または文字列 | はい | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `key_id`  | 整数 | はい | デプロイキーのID。 |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/deploy_keys/11"
```

レスポンス例:

```json
{
  "id": 1,
  "title": "Public key",
  "key": "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAAgQDNJAkI3Wdf0r13c8a5pEExB2YowPWCSVzfZV22pNBc1CuEbyYLHpUyaD0GwpGvFdx2aP7lMEk35k6Rz3ccBF6jRaVJyhsn5VNnW92PMpBJ/P1UebhXwsFHdQf5rTt082cSxWuk61kGWRQtk4ozt/J2DF/dIUVaLvc+z4HomT41fQ==",
  "fingerprint": "4a:9d:64:15:ed:3a:e6:07:6e:89:36:b3:3b:03:05:d9",
  "fingerprint_sha256": "SHA256:Jrs3LD1Ji30xNLtTVf9NDCj7kkBgPBb2pjvTZ3HfIgU",
  "created_at": "2013-10-02T10:12:29Z",
  "expires_at": null,
  "can_push": false
}
```

## プロジェクトのデプロイキーを追加 {#add-deploy-key-for-a-project}

プロジェクトの新しいデプロイキーを作成します。

デプロイキーが別のプロジェクトに既に存在する場合、元のデプロイキーが同じユーザーからアクセスできる場合にのみ、現在のプロジェクトに参加します。

```plaintext
POST /projects/:id/deploy_keys
```

| 属性    | 型 | 必須 | 説明 |
| -----------  | ---- | -------- | ----------- |
| `id`         | 整数または文字列 | はい | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `key`        | 文字列   | はい | 新しいデプロイキー |
| `title`      | 文字列   | はい | 新しいデプロイキーのタイトル |
| `can_push`   | ブール値  | いいえ  | デプロイキーはプロジェクトのリポジトリにプッシュできますか |
| `expires_at` | 日時 | いいえ | デプロイキーの有効期限。値が指定されていない場合、有効期限は切れません。ISO 8601形式（`2019-03-15T08:00:00Z`）で指定します。 |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data "{"title": "My deploy key", "key": "ssh-rsa AAAA...", "can_push": "true"}" \
     --url "https://gitlab.example.com/api/v4/projects/5/deploy_keys/"
```

レスポンス例:

```json
{
  "key": "ssh-rsa AAAA...",
  "id": 12,
  "title": "My deploy key",
  "can_push": true,
  "created_at": "2015-08-29T12:44:31.550Z",
  "expires_at": null
}
```

## デプロイキーを更新 {#update-deploy-key}

プロジェクトのデプロイキーを更新します。

```plaintext
PUT /projects/:id/deploy_keys/:key_id
```

| 属性  | 型 | 必須 | 説明 |
| ---------  | ---- | -------- | ----------- |
| `id`       | 整数または文字列 | はい | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `can_push` | ブール値 | いいえ  | デプロイキーはプロジェクトのリポジトリにプッシュできますか |
| `title`    | 文字列  | いいえ | 新しいデプロイキーのタイトル |

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data "{"title": "New deploy key", "can_push": true}" \
     --url "https://gitlab.example.com/api/v4/projects/5/deploy_keys/11"
```

レスポンス例:

```json
{
  "id": 11,
  "title": "New deploy key",
  "key": "ssh-rsa AAAA...",
  "created_at": "2015-08-29T12:44:31.550Z",
  "expires_at": null,
  "can_push": true
}
```

## デプロイキーを削除 {#delete-deploy-key}

プロジェクトからデプロイキーを削除します。デプロイキーがこのプロジェクトでのみ使用されている場合、システムから削除されます。

```plaintext
DELETE /projects/:id/deploy_keys/:key_id
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id`      | 整数または文字列 | はい | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `key_id`  | 整数 | はい | デプロイキーのID。 |

```shell
curl --request DELETE \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/5/deploy_keys/13"
```

## デプロイキーを有効にする {#enable-a-deploy-key}

使用できるように、プロジェクトのデプロイキーを有効にします。成功した場合、ステータスコード201で、有効になっているキーを返します。

```plaintext
POST /projects/:id/deploy_keys/:key_id/enable
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id`      | 整数または文字列 | はい | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `key_id`  | 整数 | はい | デプロイキーのID。 |

```shell
curl --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/5/deploy_keys/12/enable"
```

レスポンス例:

```json
{
  "key": "ssh-rsa AAAA...",
  "id": 12,
  "title": "My deploy key",
  "created_at": "2015-08-29T12:44:31.550Z",
  "expires_at": null
}
```

## 複数のプロジェクトにデプロイキーを追加 {#add-deploy-keys-to-multiple-projects}

同じグループ内の複数のプロジェクトに同じデプロイキーを追加する場合は、APIでこれを実現できます。

まず、すべてのプロジェクトをリストして、関心のあるプロジェクトのIDを見つけます:

```shell
curl --request GET \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects"
```

または、グループのIDを見つけます:

```shell
curl --request GET \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/groups"
```

次に、そのグループ内のすべてのプロジェクトをリストします（たとえば、グループ1234）:

```shell
curl --request GET \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/groups/1234"
```

これらのIDを使用して、すべてのプロジェクトに同じデプロイキーを追加します:

```shell
for project_id in 321 456 987; do
    curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
         --header "Content-Type: application/json" \
         --data "{"title": "my key", "key": "ssh-rsa AAAA..."}" \
         "https://gitlab.example.com/api/v4/projects/${project_id}/deploy_keys"
done
```
