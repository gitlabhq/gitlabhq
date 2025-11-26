---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: DebianグループディストリビューションAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [機能フラグ](../../administration/feature_flags/_index.md)の背後にデプロイされ、デフォルトでは無効になっています。

{{< /history >}}

このAPIを使用して、[Debianグループディストリビューション](../../user/packages/debian_repository/_index.md)を管理します。このAPIはデフォルトで無効になっている機能フラグの背後にあります。このAPIを使用するには、[有効にする](#enable-the-debian-group-api)必要があります。

{{< alert type="warning" >}}

このAPIは開発中であり、本番環境での使用を意図したものではありません。

{{< /alert >}}

## DebianグループAPIを有効にする {#enable-the-debian-group-api}

Debianグループリポジトリのサポートは、まだ開発中です。デフォルトで無効になっている機能フラグの背後にゲートがあります。[GitLab RailsコンソールにアクセスできるGitLab管理者](../../administration/feature_flags/_index.md)は、それを有効にすることを選択できます。それを有効にするには、[DebianグループAPIを有効にする](../../user/packages/debian_repository/_index.md#enable-the-debian-group-api)の手順に従ってください。

## DebianディストリビューションAPIへの認証 {#authenticate-to-the-debian-distributions-apis}

[DebianディストリビューションAPIへの認証](../../user/packages/debian_repository/_index.md#authenticate-to-the-debian-distributions-apis)を参照してください。

## グループ内のすべてのDebianディストリビューションをリストする {#list-all-debian-distributions-in-a-group}

指定されたグループ内のDebianディストリビューションをリストします。

```plaintext
GET /groups/:id/-/debian_distributions
```

| 属性  | 型            | 必須 | 説明 |
| ---------- | --------------- | -------- | ----------- |
| `id`       | 整数または文字列  | はい      | グループのIDまたは[URLエンコードされたパス](../rest/_index.md#namespaced-paths)。 |
| `codename` | 文字列          | いいえ       | 特定の`codename`でフィルタリングします。 |
| `suite`    | 文字列          | いいえ       | 特定の`suite`でフィルタリングします。 |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/-/debian_distributions"
```

レスポンス例:

```json
[
  {
    "id": 1,
    "codename": "sid",
    "suite": null,
    "origin": null,
    "label": null,
    "version": null,
    "description": null,
    "valid_time_duration_seconds": null,
    "components": [
      "main"
    ],
    "architectures": [
      "all",
      "amd64"
    ]
  }
]
```

## 単一のDebianグループディストリビューション {#single-debian-group-distribution}

単一のDebianグループディストリビューションを取得します。

```plaintext
GET /groups/:id/-/debian_distributions/:codename
```

| 属性  | 型           | 必須 | 説明 |
| ---------- | -------------- | -------- | ----------- |
| `id`       | 整数または文字列 | はい      | グループのIDまたは[URLエンコードされたパス](../rest/_index.md#namespaced-paths)。 |
| `codename` | 文字列         | はい      | ディストリビューションの`codename`。 |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/-/debian_distributions/unstable"
```

レスポンス例:

```json
{
  "id": 1,
  "codename": "sid",
  "suite": null,
  "origin": null,
  "label": null,
  "version": null,
  "description": null,
  "valid_time_duration_seconds": null,
  "components": [
    "main"
  ],
  "architectures": [
    "all",
    "amd64"
  ]
}
```

## 単一のDebianグループディストリビューションキー {#single-debian-group-distribution-key}

単一のDebianグループディストリビューションキーを取得します。

```plaintext
GET /groups/:id/-/debian_distributions/:codename/key.asc
```

| 属性  | 型           | 必須 | 説明 |
| ---------- | -------------- | -------- | ----------- |
| `id`       | 整数または文字列 | はい      | グループのIDまたは[URLエンコードされたパス](../rest/_index.md#namespaced-paths)。 |
| `codename` | 文字列         | はい      | ディストリビューションの`codename`。 |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/-/debian_distributions/unstable/key.asc"
```

レスポンス例:

```plaintext
-----BEGIN PGP PUBLIC KEY BLOCK-----
Comment: Alice's OpenPGP certificate
Comment: https://www.ietf.org/id/draft-bre-openpgp-samples-01.html

mDMEXEcE6RYJKwYBBAHaRw8BAQdArjWwk3FAqyiFbFBKT4TzXcVBqPTB3gmzlC/U
b7O1u120JkFsaWNlIExvdmVsYWNlIDxhbGljZUBvcGVucGdwLmV4YW1wbGU+iJAE
ExYIADgCGwMFCwkIBwIGFQoJCAsCBBYCAwECHgECF4AWIQTrhbtfozp14V6UTmPy
MVUMT0fjjgUCXaWfOgAKCRDyMVUMT0fjjukrAPoDnHBSogOmsHOsd9qGsiZpgRnO
dypvbm+QtXZqth9rvwD9HcDC0tC+PHAsO7OTh1S1TC9RiJsvawAfCPaQZoed8gK4
OARcRwTpEgorBgEEAZdVAQUBAQdAQv8GIa2rSTzgqbXCpDDYMiKRVitCsy203x3s
E9+eviIDAQgHiHgEGBYIACAWIQTrhbtfozp14V6UTmPyMVUMT0fjjgUCXEcE6QIb
DAAKCRDyMVUMT0fjjlnQAQDFHUs6TIcxrNTtEZFjUFm1M0PJ1Dng/cDW4xN80fsn
0QEA22Kr7VkCjeAEC08VSTeV+QFsmz55/lntWkwYWhmvOgE=
=iIGO
-----END PGP PUBLIC KEY BLOCK-----
```

## Debianグループディストリビューションを作成する {#create-a-debian-group-distribution}

Debianグループディストリビューションを作成します。

```plaintext
POST /groups/:id/-/debian_distributions
```

| 属性                     | 型           | 必須 | 説明 |
| ----------------------------- | -------------- | -------- | ----------- |
| `id`                          | 整数または文字列 | はい      | グループのIDまたは[URLエンコードされたパス](../rest/_index.md#namespaced-paths)。 |
| `codename`                    | 文字列         | はい      | Debianディストリビューションのコードネーム。 |
| `suite`                       | 文字列         | いいえ       | 新しいDebianディストリビューションのスイート。 |
| `origin`                      | 文字列         | いいえ       | 新しいDebianディストリビューションのorigin。 |
| `label`                       | 文字列         | いいえ       | 新しいDebianディストリビューションのラベル。 |
| `version`                     | 文字列         | いいえ       | 新しいDebianディストリビューションのバージョン。 |
| `description`                 | 文字列         | いいえ       | 新しいDebianディストリビューションの説明。 |
| `valid_time_duration_seconds` | 整数        | いいえ       | 新しいDebianディストリビューションの有効期間（秒）。 |
| `components`                  | 文字列配列   | いいえ       | 新しいDebianディストリビューションのコンポーネントのリスト。 |
| `architectures`               | 文字列配列   | いいえ       | 新しいDebianディストリビューションのアーキテクチャのリスト。 |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/-/debian_distributions?codename=sid"
```

レスポンス例:

```json
{
  "id": 1,
  "codename": "sid",
  "suite": null,
  "origin": null,
  "label": null,
  "version": null,
  "description": null,
  "valid_time_duration_seconds": null,
  "components": [
    "main"
  ],
  "architectures": [
    "all",
    "amd64"
  ]
}
```

## Debianグループディストリビューションを更新する {#update-a-debian-group-distribution}

Debianグループディストリビューションを更新します。

```plaintext
PUT /groups/:id/-/debian_distributions/:codename
```

| 属性                     | 型           | 必須 | 説明 |
| ----------------------------- | -------------- | -------- | ----------- |
| `id`                          | 整数または文字列 | はい      | グループのIDまたは[URLエンコードされたパス](../rest/_index.md#namespaced-paths)。 |
| `codename`                    | 文字列         | はい      | Debianディストリビューションの新しいコードネーム。  |
| `suite`                       | 文字列         | いいえ       | Debianディストリビューションの新しいスイート。 |
| `origin`                      | 文字列         | いいえ       | Debianディストリビューションの新しいorigin。 |
| `label`                       | 文字列         | いいえ       | Debianディストリビューションの新しいラベル。 |
| `version`                     | 文字列         | いいえ       | Debianディストリビューションの新しいバージョン。 |
| `description`                 | 文字列         | いいえ       | Debianディストリビューションの新しい説明。 |
| `valid_time_duration_seconds` | 整数        | いいえ       | Debianディストリビューションの新しい有効期間（秒）。 |
| `components`                  | 文字列配列   | いいえ       | Debianディストリビューションの新しいコンポーネントのリスト。 |
| `architectures`               | 文字列配列   | いいえ       | Debianディストリビューションの新しいアーキテクチャのリスト。 |

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/-/debian_distributions/unstable?suite=new-suite&valid_time_duration_seconds=604800"
```

レスポンス例:

```json
{
  "id": 1,
  "codename": "sid",
  "suite": "new-suite",
  "origin": null,
  "label": null,
  "version": null,
  "description": null,
  "valid_time_duration_seconds": 604800,
  "components": [
    "main"
  ],
  "architectures": [
    "all",
    "amd64"
  ]
}
```

## Debianグループディストリビューションを削除する {#delete-a-debian-group-distribution}

Debianグループディストリビューションを削除します。

```plaintext
DELETE /groups/:id/-/debian_distributions/:codename
```

| 属性  | 型           | 必須 | 説明 |
| ---------- | -------------- | -------- | ----------- |
| `id`       | 整数または文字列 | はい      | グループのIDまたは[URLエンコードされたパス](../rest/_index.md#namespaced-paths)。 |
| `codename` | 文字列         | はい      | Debianディストリビューションのコードネーム。 |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/-/debian_distributions/unstable"
```
