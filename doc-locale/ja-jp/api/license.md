---
stage: Fulfillment
group: Utilization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: yes
title: ライセンスAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、ライセンスエンドポイントと対話します。詳細については、[ライセンスファイルまたはキーを使用してGitLab EEをアクティベートする](../administration/license_file.md)を参照してください。

前提条件: 

- インスタンスへの管理者アクセス権が必要です。

## ライセンス情報を取得する {#retrieve-license-information}

現在のライセンスに関する情報を取得します。

```plaintext
GET /license
```

```json
{
  "id": 2,
  "plan": "ultimate",
  "created_at": "2018-02-27T23:21:58.674Z",
  "starts_at": "2018-01-27",
  "expires_at": "2022-01-27",
  "historical_max": 300,
  "maximum_user_count": 300,
  "expired": false,
  "overage": 200,
  "user_limit": 100,
  "active_users": 300,
  "licensee": {
    "Name": "John Doe1",
    "Email": "johndoe1@gitlab.com",
    "Company": "GitLab"
  },
  "add_ons": {
    "GitLab_FileLocks": 1,
    "GitLab_Auditor_User": 1
  }
}
```

## すべてのライセンスを一覧表示 {#list-all-licenses}

すべてのライセンスに関する情報を一覧表示します。

```plaintext
GET /licenses
```

```json
[
  {
    "id": 1,
    "plan": "premium",
    "created_at": "2018-02-27T23:21:58.674Z",
    "starts_at": "2018-01-27",
    "expires_at": "2022-01-27",
    "historical_max": 300,
    "maximum_user_count": 300,
    "expired": false,
    "overage": 200,
    "user_limit": 100,
    "licensee": {
      "Name": "John Doe1",
      "Email": "johndoe1@gitlab.com",
      "Company": "GitLab"
    },
    "add_ons": {
      "GitLab_FileLocks": 1,
      "GitLab_Auditor_User": 1
    }
  },
  {
    "id": 2,
    "plan": "ultimate",
    "created_at": "2018-02-27T23:21:58.674Z",
    "starts_at": "2018-01-27",
    "expires_at": "2022-01-27",
    "historical_max": 300,
    "maximum_user_count": 300,
    "expired": false,
    "overage": 200,
    "user_limit": 100,
    "licensee": {
      "Name": "Doe John",
      "Email": "doejohn@gitlab.com",
      "Company": "GitLab"
    },
    "add_ons": {
      "GitLab_FileLocks": 1
    }
  }
]
```

超過分は、請求対象ユーザー数とライセンスされたユーザー数との差です。これは、ライセンスの有効期限が切れているかどうかによって計算方法が異なります。

- ライセンスの有効期限が切れている場合、過去最大の請求対象ユーザー数（`historical_max`）を使用します。
- ライセンスの有効期限が切れていない場合、現在の請求対象ユーザー数を使用します。

戻り値:

- ライセンスをJSON形式で含む応答とともに`200 OK`。ライセンスがない場合、これは空のJSON配列です。
- 現在のユーザーがライセンスの読み取りを許可されていない場合は`403 Forbidden`。

## ライセンスを取得する {#retrieve-a-license}

指定されたライセンスに関する情報を取得します。

```plaintext
GET /license/:id
```

サポートされている属性は以下のとおりです: 

| 属性 | 型    | 必須 | 説明               |
|-----------|---------|----------|---------------------------|
| `id`      | 整数 | はい      | GitLabライセンスのID。 |

次のステータスコードが返されます:

- `200 OK`: 応答にはJSON形式のライセンスが含まれます。
- `404 Not Found`: リクエストされたライセンスは存在しません。
- `403 Forbidden`: 現在のユーザーはライセンスの読み取りを許可されていません。

リクエスト例: 

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
--url "https://gitlab.example.com/api/v4/license/:id"
```

レスポンス例: 

```json
{
  "id": 1,
  "plan": "premium",
  "created_at": "2018-02-27T23:21:58.674Z",
  "starts_at": "2018-01-27",
  "expires_at": "2022-01-27",
  "historical_max": 300,
  "maximum_user_count": 300,
  "expired": false,
  "overage": 200,
  "user_limit": 100,
  "active_users": 50,
  "licensee": {
    "Name": "John Doe1",
    "Email": "johndoe1@gitlab.com",
    "Company": "GitLab"
  },
  "add_ons": {
    "GitLab_FileLocks": 1,
    "GitLab_Auditor_User": 1
  }
}
```

## ライセンスを作成する {#create-a-license}

新しいライセンスを作成します。

```plaintext
POST /license
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `license` | 文字列 | はい | ライセンス文字列 |

```shell
curl --request POST \
--header "PRIVATE-TOKEN: <your_access_token>" \
--url "https://gitlab.example.com/api/v4/license?license=eyJkYXRhIjoiMHM5Q...S01Udz09XG4ifQ=="
```

レスポンス例: 

```json
{
  "id": 1,
  "plan": "ultimate",
  "created_at": "2018-02-27T23:21:58.674Z",
  "starts_at": "2018-01-27",
  "expires_at": "2022-01-27",
  "historical_max": 300,
  "maximum_user_count": 300,
  "expired": false,
  "overage": 200,
  "user_limit": 100,
  "active_users": 300,
  "licensee": {
    "Name": "John Doe1",
    "Email": "johndoe1@gitlab.com",
    "Company": "GitLab"
  },
  "add_ons": {
    "GitLab_FileLocks": 1,
    "GitLab_Auditor_User": 1
  }
}
```

戻り値:

- ライセンスが正常に追加された場合は`201 Created`。
- ライセンスを追加できなかった場合、その理由を説明するエラーメッセージとともに`400 Bad Request`。

## ライセンスを削除する {#delete-a-license}

指定されたライセンスを削除します。

```plaintext
DELETE /license/:id
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 整数 | はい | GitLabライセンスのID。 |

```shell
curl --request DELETE \
--header "PRIVATE-TOKEN: <your_access_token>" \
--url "https://gitlab.example.com/api/v4/license/:id"
```

戻り値:

- ライセンスが正常に削除された場合は`204 No Content`。
- 現在のユーザーがライセンスの削除を許可されていない場合は`403 Forbidden`。
- 削除するライセンスが見つからなかった場合は`404 Not Found`。

## 請求対象ユーザーの再計算をトリガーする {#trigger-recalculation-of-billable-users}

指定されたライセンスの請求対象ユーザーの再計算をトリガーします。

```plaintext
PUT /license/:id/refresh_billable_users
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 整数 | はい | GitLabライセンスのID。 |

```shell
curl --request PUT \
--header "PRIVATE-TOKEN: <your_access_token>" \
--url "https://gitlab.example.com/api/v4/license/:id/refresh_billable_users"
```

レスポンス例: 

```json
{
  "success": true
}
```

戻り値:

- 請求対象ユーザーの更新リクエストが正常に開始された場合は`202 Accepted`。
- 現在のユーザーがライセンスの請求対象ユーザーを更新することが許可されていない場合は`403 Forbidden`。
- ライセンスが見つからなかった場合は`404 Not Found`。

| 属性                    | 型          | 説明                               |
|:-----------------------------|:--------------|:------------------------------------------|
| `success`                    | ブール値       | リクエストが成功したかどうか。     |

## ライセンス使用状況情報を取得する {#retrieve-license-usage-information}

現在のライセンスに関する使用状況情報を取得し、CSV形式でエクスポートします。

```plaintext
GET /license/usage_export.csv
```

```shell
curl --request GET \
--header "PRIVATE-TOKEN: <your_access_token>" \
--url "https://gitlab.example.com/api/v4/license/usage_export.csv"
```

レスポンス例: 

```plaintext
License Key,"eyJkYXRhIjoib1EwRWZXU3RobDY2Yl=
"
Email,user@example.com
License Start Date,2023-02-22
License End Date,2024-02-22
Company,Example Corp.
Generated At,2023-09-05 06:56:23
"",""
Date,Billable User Count
2023-07-11 12:00:05,21
2023-07-13 12:00:06,21
2023-08-16 12:00:02,21
2023-09-04 12:00:12,21
```

戻り値:

- `200 OK`: 応答にはCSV形式のライセンス使用状況が含まれます。
- 現在のユーザーがライセンス使用状況の表示を許可されていない場合は`403 Forbidden`。
