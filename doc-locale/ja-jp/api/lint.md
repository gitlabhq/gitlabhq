---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: CI Lint API
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、[GitLab CI/CD設定を検証する](../ci/yaml/lint.md)ことができます。

これらのエンドポイントは、JSONエンコードされたYAMLコンテンツを使用します。場合によっては、[`jq`](https://jqlang.org/)のようなサードパーティツールを使用して、リクエストを行う前にYAMLコンテンツを適切にフォーマットすると便利です。CI/CD設定の形式を維持したい場合に役立ちます。

例えば、次のコマンドはJQを使用して、指定されたYAMLファイルを適切にエスケープし、JSONとしてエンコードし、APIへのリクエストを行います。

```shell
jq --null-input --arg yaml "$(<example-gitlab-ci.yml)" '.content=$yaml' \
| curl --url "https://gitlab.com/api/v4/projects/:id/ci/lint?include_merged_yaml=true" \
--header 'Content-Type: application/json' \
--data @-
```

1. `example-gitlab-ci.yml`という名前のYAMLファイルを作成します:

   ```yaml
   .api_test:
     rules:
       - if: $CI_PIPELINE_SOURCE=="merge_request_event"
         changes:
           - src/api/*
   deploy:
     extends:
       - .api_test
     rules:
       - when: manual
         allow_failure: true
     script:
       - echo "hello world"
   ```

1. 入力YAMLファイル（`example-gitlab-ci.yml`）をエスケープしてエンコードし、それをGitLab APIに`POST`するには、`curl`と`jq`を組み合わせた1行コマンドを作成します:

   ```shell
   jq --null-input --arg yaml "$(<example-gitlab-ci.yml)" '.content=$yaml' \
   | curl --url "https://gitlab.com/api/v4/projects/:id/ci/lint?include_merged_yaml=true" \
       --header 'Content-Type: application/json' \
       --data @-
   ```

## このAPIからの応答を解析する {#parse-responses-from-this-api}

CI Lint APIからの応答を再フォーマットするには、次のいずれかの方法を使用します:

- CI Lint応答を`jq`に直接パイプします。
- API応答をテキストファイルとして保存し、`jq`に引数として次のように提供します:

  ```shell
  jq --raw-output '.merged_yaml | fromjson' <your_input_here>
  ```

例えば、このJSON配列:

```json
{"valid":"true","errors":[],"merged_yaml":"---\n.api_test:\n  rules:\n  - if: $CI_PIPELINE_SOURCE==\"merge_request_event\"\n    changes:\n    - src/api/*\ndeploy:\n  rules:\n  - when: manual\n    allow_failure: true\n  extends:\n  - \".api_test\"\n  script:\n  - echo \"hello world\"\n"}
```

解析および再フォーマットされると、結果のYAMLファイルには以下が含まれます:

```yaml
.api_test:
  rules:
  - if: $CI_PIPELINE_SOURCE=="merge_request_event"
    changes:
    - src/api/*
deploy:
  rules:
  - when: manual
    allow_failure: true
  extends:
  - ".api_test"
  script:
  - echo "hello world"
```

## CI/CD設定を検証する {#validate-cicd-configuration}

指定されたプロジェクトの`.gitlab-ci.yml`設定を検証します。このエンドポイントは、CI/CD設定をプロジェクトのコンテキストで検証します。これには以下が含まれます:

- プロジェクトのCI/CD変数を使用します。
- プロジェクトファイル内で`include:local`エントリを検索します。

```plaintext
POST /projects/:id/ci/lint
```

| 属性      | 型    | 必須 | 説明 |
|----------------|---------|----------|-------------|
| `content`      | 文字列  | はい      | CI/CD設定コンテンツ。 |
| `dry_run`      | ブール値 | いいえ       | [パイプライン](../ci/yaml/lint.md#simulate-a-pipeline)作成シミュレーションを実行するか、静的チェックのみを行います。デフォルトは`false`です。 |
| `include_jobs` | ブール値 | いいえ       | 静的チェックまたはパイプラインシミュレーションに存在するジョブのリストを応答に含めるかどうか。デフォルトは`false`です。 |
| `ref`          | 文字列  | いいえ       | もし`dry_run`が`true`の場合、CI/CD YAML設定を検証するために使用するブランチまたはタグのコンテキストを設定します。設定されていない場合、プロジェクトのデフォルトブランチが使用されます。 |

リクエスト例: 

```shell
curl --request POST \
  --header "Content-Type: application/json" \
  --url "https://gitlab.example.com/api/v4/projects/:id/ci/lint" \
  --data @- <<'EOF'
{
  "content": "{
    \"image\": \"ruby:2.6\",
    \"services\": [\"postgres\"],
    \"before_script\": [
      \"bundle install\",
      \"bundle exec rake db:create\"
    ],
    \"variables\": {
      \"DB_NAME\": \"postgres\"
    },
    \"stages\": [\"test\", \"deploy\", \"notify\"],
    \"rspec\": {
      \"script\": \"rake spec\",
      \"tags\": [\"ruby\", \"postgres\"],
      \"only\": [\"branches\"]
    }
  }"
}
EOF
```

レスポンス例:

- 有効な設定:

  ```json
  {
    "valid": true,
    "merged_yaml": "---\ntest_job:\n  script: echo 1\n",
    "errors": [],
    "warnings": [],
    "includes": []
  }
  ```

- 無効な設定:

  ```json
  {
    "valid": false,
    "errors": [
      "jobs config should contain at least one visible job"
    ],
    "warnings": [],
    "merged_yaml": "---\n\".job\":\n  script:\n  - echo \"A hidden job\"\n",
    "includes": []
  }
  ```

## 既存のCI/CD設定を検証する {#validate-existing-cicd-configuration}

{{< history >}}

- GitLab 16.5で`sha`属性が[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/369212)されました。
- GitLab 16.10で`sha`と`ref`は`content_ref`と`dry_run_ref`に[名称変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/143098)されました。

{{< /history >}}

指定されたプロジェクトの既存の`.gitlab-ci.yml`設定を検証します。このエンドポイントは、CI/CD設定をプロジェクトのコンテキストで検証します。これには以下が含まれます:

- プロジェクトのCI/CD変数を使用します。
- プロジェクトファイル内で`include:local`エントリを検索します。

```plaintext
GET /projects/:id/ci/lint
```

| 属性      | 型    | 必須 | 説明 |
|----------------|---------|----------|-------------|
| `content_ref`  | 文字列  | いいえ       | CI/CD設定コンテンツは、このコミットSHA、ブランチ、またはタグから取得されます。設定されていない場合、プロジェクトのデフォルトブランチのHEAD SHAが使用されます。 |
| `dry_run`      | ブール値 | いいえ       | パイプライン作成シミュレーションを実行するか、または静的チェックのみ実行します。 |
| `dry_run_ref`  | 文字列  | いいえ       | もし`dry_run`が`true`の場合、CI/CD YAML設定を検証するために使用するブランチまたはタグのコンテキストを設定します。設定されていない場合、プロジェクトのデフォルトブランチが使用されます。 |
| `include_jobs` | ブール値 | いいえ       | 静的チェックまたはパイプラインシミュレーションに存在するジョブのリストを応答に含めるかどうか。デフォルトは`false`です。 |
| `ref`          | 文字列  | いいえ       | （非推奨）`dry_run`が`true`の場合、CI/CD YAML設定を検証するために使用するブランチまたはタグコンテキストを設定します。設定されていない場合、プロジェクトのデフォルトブランチが使用されます。代わりに`dry_run_ref`を使用してください。 |
| `sha`          | 文字列  | いいえ       | （非推奨）CI/CD設定コンテンツは、このコミットSHA、ブランチ、またはタグから取得されます。設定されていない場合、プロジェクトのデフォルトブランチのHEAD SHAが使用されます。代わりに`content_ref`を使用してください。 |

リクエスト例: 

```shell
curl --request GET \
  --url "https://gitlab.example.com/api/v4/projects/:id/ci/lint"
```

レスポンス例:

- `include.yml`が[インクルードファイル](../ci/yaml/_index.md#include)として含まれ、`include_jobs`が`true`に設定された有効な設定:

  ```json
  {
    "valid": true,
    "errors": [],
    "warnings": [],
    "merged_yaml": "---\ninclude-job:\n  script:\n  - echo \"An included job\"\njob:\n  rules:\n  - if: \"$CI_COMMIT_BRANCH\"\n  script:\n  - echo \"A test job\"\n",
    "includes": [
      {
        "type": "local",
        "location": "include.yml",
        "blob": "https://gitlab.example.com/test-group/test-project/-/blob/ef5014c045873c5c4ffeb7a2f5be021a1d3ed703/include.yml",
        "raw": "https://gitlab.example.com/test-group/test-project/-/raw/ef5014c045873c5c4ffeb7a2f5be021a1d3ed703/include.yml",
        "extra": {},
        "context_project": "test-group/test-project",
        "context_sha": "ef5014c045873c5c4ffeb7a2f5be021a1d3ed703"
      }
    ],
    "jobs": [
      {
        "name": "include-job",
        "stage": "test",
        "before_script": [],
        "script": [
          "echo \"An included job\""
        ],
        "after_script": [],
        "tag_list": [],
        "only": {
          "refs": [
            "branches",
            "tags"
          ]
        },
        "except": null,
        "environment": null,
        "when": "on_success",
        "allow_failure": false,
        "needs": null
      },
      {
        "name": "job",
        "stage": "test",
        "before_script": [],
        "script": [
          "echo \"A test job\""
        ],
        "after_script": [],
        "tag_list": [],
        "only": null,
        "except": null,
        "environment": null,
        "when": "on_success",
        "allow_failure": false,
        "needs": null
      }
    ]
  }
  ```

- 無効な設定:

  ```json
  {
    "valid": false,
    "errors": [
      "jobs config should contain at least one visible job"
    ],
    "warnings": [],
    "merged_yaml": "---\n\".job\":\n  script:\n  - echo \"A hidden job\"\n",
    "includes": []
  }
  ```
