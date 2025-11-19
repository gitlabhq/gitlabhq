---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: リポジトリサブモジュールAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用すると、[Git サブモジュール](https://git-scm.com/book/en/v2/Git-Tools-Submodules)参照を特定のブランチにあるGitリポジトリ内で更新できます。

## リポジトリ内の既存のサブモジュール参照を更新 {#update-existing-submodule-reference-in-repository}

いくつかのワークフロー、特に自動化されたワークフローでは、サブモジュールの参照を更新して、それを使用する他のプロジェクトを最新の状態に保つことができます。

```plaintext
PUT /projects/:id/repository/submodules/:submodule
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 整数または文字列 | はい | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `submodule` | 文字列 | はい | サブモジュールへのURLエンコードされたフルパス。例: `lib%2Fclass%2Erb` |
| `branch` | 文字列 | はい | コミット先のブランチの名前 |
| `commit_sha` | 文字列 | はい | サブモジュールを更新するための完全なコミット  |
| `commit_message` | 文字列 | いいえ | コミットメッセージ。メッセージが指定されていない場合は、デフォルトが設定されます |

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/submodules/lib%2Fmodules%2Fexample" \
--data "branch=main&commit_sha=3ddec28ea23acc5caa5d8331a6ecb2a65fc03e88&commit_message=Update submodule reference"
```

レスポンス例:

```json
{
  "id": "ed899a2f4b50b4370feeea94676502b42383c746",
  "short_id": "ed899a2f4b5",
  "title": "Updated submodule example_submodule with oid 3ddec28ea23acc5caa5d8331a6ecb2a65fc03e88",
  "author_name": "Dmitriy Zaporozhets",
  "author_email": "dzaporozhets@sphereconsultinginc.com",
  "committer_name": "Dmitriy Zaporozhets",
  "committer_email": "dzaporozhets@sphereconsultinginc.com",
  "created_at": "2018-09-20T09:26:24.000-07:00",
  "message": "Updated submodule example_submodule with oid 3ddec28ea23acc5caa5d8331a6ecb2a65fc03e88",
  "parent_ids": [
    "ae1d9fb46aa2b07ee9836d49862ec4e2c46fbbba"
  ],
  "committed_date": "2018-09-20T09:26:24.000-07:00",
  "authored_date": "2018-09-20T09:26:24.000-07:00",
  "status": null
}
```
