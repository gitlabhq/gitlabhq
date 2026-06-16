---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: TerraformモジュールレジストリAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、[Terraform CLI](../../user/packages/terraform_module_registry/_index.md)と対話します。

> [!warning]
> このAPIは[Terraform CLI](https://www.terraform.io/)によって使用され、通常は手動での使用を意図していません。記載されていない認証方法は、将来削除される可能性があります。

## 特定のモジュールで利用可能なバージョンを一覧表示 {#list-available-versions-for-a-specific-module}

指定されたモジュールの利用可能なすべてのバージョンを一覧表示します。

```plaintext
GET packages/terraform/modules/v1/:module_namespace/:module_name/:module_system/versions
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `module_namespace` | 文字列 | はい | Terraformモジュールのプロジェクトまたはサブグループが属するトップレベルグループ（ネームスペース）。|
| `module_name` | 文字列 | はい | モジュール名。 |
| `module_system` | 文字列 | はい | モジュールシステムまたは[プロバイダー](https://www.terraform.io/registry/providers)の名前。 |

```shell
curl --header "Authorization: Bearer <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/packages/terraform/modules/v1/group/hello-world/local/versions"
```

レスポンス例: 

```json
{
  "modules": [
    {
      "versions": [
        {
          "version": "1.0.0",
          "submodules": [],
          "root": {
            "dependencies": [],
            "providers": [
              {
                "name": "local",
                "version":""
              }
            ]
          }
        },
        {
          "version": "0.9.3",
          "submodules": [],
          "root": {
            "dependencies": [],
            "providers": [
              {
                "name": "local",
                "version":""
              }
            ]
          }
        }
      ],
      "source": "https://gitlab.example.com/group/hello-world"
    }
  ]
}
```

## モジュールの最新バージョンを取得 {#retrieve-latest-version-for-a-module}

指定されたモジュールの最新バージョンに関する情報を取得します。

```plaintext
GET packages/terraform/modules/v1/:module_namespace/:module_name/:module_system
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `module_namespace` | 文字列 | はい | Terraformモジュールのプロジェクトが属するグループ。 |
| `module_name` | 文字列 | はい | モジュール名。 |
| `module_system` | 文字列 | はい | モジュールシステムまたは[プロバイダー](https://www.terraform.io/registry/providers)の名前。 |

```shell
curl --header "Authorization: Bearer <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/packages/terraform/modules/v1/group/hello-world/local"
```

レスポンス例: 

```json
{
  "name": "hello-world/local",
  "provider": "local",
  "providers": [
    "local"
  ],
  "root": {
    "dependencies": []
  },
  "source": "https://gitlab.example.com/group/hello-world",
  "submodules": [],
  "version": "1.0.0",
  "versions": [
    "1.0.0"
  ]
}
```

## モジュールの特定のバージョンを取得 {#retrieve-a-specific-version-for-a-module}

指定されたモジュールの特定のバージョンに関する情報を取得します。

```plaintext
GET packages/terraform/modules/v1/:module_namespace/:module_name/:module_system/1.0.0
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `module_namespace` | 文字列 | はい | Terraformモジュールのプロジェクトが属するグループ。 |
| `module_name` | 文字列 | はい | モジュール名。 |
| `module_system` | 文字列 | はい | モジュールシステムまたは[プロバイダー](https://www.terraform.io/registry/providers)の名前。 |

```shell
curl --header "Authorization: Bearer <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/packages/terraform/modules/v1/group/hello-world/local/1.0.0"
```

レスポンス例: 

```json
{
  "name": "hello-world/local",
  "provider": "local",
  "providers": [
    "local"
  ],
  "root": {
    "dependencies": []
  },
  "source": "https://gitlab.example.com/group/hello-world",
  "submodules": [],
  "version": "1.0.0",
  "versions": [
    "1.0.0"
  ]
}
```

## 最新モジュールバージョンのダウンロードURLを取得 {#retrieve-download-url-for-latest-module-version}

最新のモジュールバージョンのダウンロードURLを`X-Terraform-Get`ヘッダーで取得します。

```plaintext
GET packages/terraform/modules/v1/:module_namespace/:module_name/:module_system/download
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `module_namespace` | 文字列 | はい | Terraformモジュールのプロジェクトが属するグループ。 |
| `module_name` | 文字列 | はい | モジュール名。 |
| `module_system` | 文字列 | はい | モジュールシステムまたは[プロバイダー](https://www.terraform.io/registry/providers)の名前。 |

```shell
curl --header "Authorization: Bearer <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/packages/terraform/modules/v1/group/hello-world/local/download"
```

レスポンス例: 

```plaintext
HTTP/1.1 204 No Content
Content-Length: 0
X-Terraform-Get: /api/v4/packages/terraform/modules/v1/group/hello-world/local/1.0.0/file?token=&archive=tgz
```

内部的には、このAPIエンドポイントは`packages/terraform/modules/v1/:module_namespace/:module_name/:module_system/:module_version/download`にリダイレクトされます。

## 特定のモジュールバージョンのダウンロードURLを取得 {#retrieve-download-url-for-a-specific-module-version}

指定されたモジュールバージョンのダウンロードURLを`X-Terraform-Get`ヘッダーで取得します。

```plaintext
GET packages/terraform/modules/v1/:module_namespace/:module_name/:module_system/:module_version/download
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `module_namespace` | 文字列 | はい | Terraformモジュールのプロジェクトが属するグループ。 |
| `module_name` | 文字列 | はい | モジュール名。 |
| `module_system` | 文字列 | はい | モジュールシステムまたは[プロバイダー](https://www.terraform.io/registry/providers)の名前。 |
| `module_version` | 文字列 | はい | ダウンロードする特定のモジュールバージョン。 |

```shell
curl --header "Authorization: Bearer <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/packages/terraform/modules/v1/group/hello-world/local/1.0.0/download"
```

レスポンス例: 

```plaintext
HTTP/1.1 204 No Content
Content-Length: 0
X-Terraform-Get: /api/v4/packages/terraform/modules/v1/group/hello-world/local/1.0.0/file?token=&archive=tgz
```

## モジュールをダウンロード {#download-module}

### ネームスペースから {#from-a-namespace}

```plaintext
GET packages/terraform/modules/v1/:module_namespace/:module_name/:module_system/:module_version/file
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `module_namespace` | 文字列 | はい | Terraformモジュールのプロジェクトが属するグループ。 |
| `module_name` | 文字列 | はい | モジュール名。 |
| `module_system` | 文字列 | はい | モジュールシステムまたは[プロバイダー](https://www.terraform.io/registry/providers)の名前。 |
| `module_version` | 文字列 | はい | ダウンロードする特定のモジュールバージョン。 |

```shell
curl --header "Authorization: Bearer <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/packages/terraform/modules/v1/group/hello-world/local/1.0.0/file"
```

出力をファイルに書き込むには:

```shell
curl --header "Authorization: Bearer <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/packages/terraform/modules/v1/group/hello-world/local/1.0.0/file" \
  --output hello-world-local.tgz
```

### プロジェクトから {#from-a-project}

```plaintext
GET /projects/:id/packages/terraform/modules/:module_name/:module_system/:module_version
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 整数または文字列 | はい | プロジェクトのIDまたはURLエンコードされたパス。 |
| `module_name` | 文字列 | はい | モジュール名。 |
| `module_system` | 文字列 | はい | モジュールシステムまたは[プロバイダー](https://www.terraform.io/registry/providers)の名前。 |
| `module_version` | 文字列 | いいえ | ダウンロードする特定のモジュールバージョン。省略された場合、最新のバージョンがダウンロードされます。 |

```shell
curl --user "<username>:<personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/terraform/modules/hello-world/local/1.0.0"
```

出力をファイルに書き込むには:

```shell
curl --user "<username>:<personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/terraform/modules/hello-world/local/1.0.0" \
  --output hello-world-local.tgz
```

## モジュールをアップロード {#upload-module}

指定されたプロジェクトにモジュールをアップロードします。

```plaintext
PUT /projects/:id/packages/terraform/modules/:module-name/:module-system/:module-version/file
```

| 属性        | 型              | 必須 | 説明 |
|------------------|-------------------|----------|-------------|
| `id`             | 整数または文字列 | はい      | プロジェクトのIDまたはURLエンコードされたパス。 |
| `module-name`    | 文字列            | はい      | モジュール名。 |
| `module-system`  | 文字列            | はい      | モジュールシステムまたは[プロバイダー](https://www.terraform.io/registry/providers)の名前。 |
| `module-version` | 文字列            | はい      | アップロードする特定のモジュールバージョン。 |

```shell
curl --fail-with-body \
   --header "PRIVATE-TOKEN: <your_access_token>" \
   --upload-file path/to/file.tgz \
   --url  "https://gitlab.example.com/api/v4/projects/<your_project_id>/packages/terraform/modules/my-module/my-system/0.0.1/file"
```

認証に使用できるトークン:

| ヘッダー          | 値 |
|-----------------|-------|
| `PRIVATE-TOKEN` | `api`スコープを持つ[パーソナルアクセストークン](../../user/profile/personal_access_tokens.md)。 |
| `DEPLOY-TOKEN`  | `write_package_registry`スコープを持つ[デプロイトークン](../../user/project/deploy_tokens/_index.md)。 |
| `JOB-TOKEN`     | [ジョブトークン](../../ci/jobs/ci_job_token.md)。 |

レスポンス例: 

```json
{
  "message": "201 Created"
}
```
