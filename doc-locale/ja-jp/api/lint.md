---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title:  API
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、[GitLab CI/CD設定を検証します](../ci/yaml/lint.md)。

これらのエンドポイントは、JSONエンコードされたYAMLコンテンツを使用します。場合によっては、リクエストを行う前に、[`jq`](https://jqlang.org/)のようなサードパーティツールを使用してYAMLコンテンツを適切にフォーマットすると便利なことがあります。これは、CI/CD設定のフォーマットを維持したい場合に役立ちます。

たとえば、次のコマンドはJQを使用して、指定されたYAMLファイルを適切にエスケープし、JSONとしてエンコードし、APIにリクエストを送信します。

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

1. 入力YAMLファイル（`example-gitlab-ci.yml`）をエスケープしてエンコードし、それをGitLab APIに`POST`するには、`curl`と`jq`を組み合わせた1行のコマンドを作成します:

   ```shell
   jq --null-input --arg yaml "$(<example-gitlab-ci.yml)" '.content=$yaml' \
   | curl --url "https://gitlab.com/api/v4/projects/:id/ci/lint?include_merged_yaml=true" \
       --header 'Content-Type: application/json' \
       --data @-
   ```

## このAPIからのレスポンスを解析する {#parse-responses-from-this-api}

CI Lint APIからのレスポンスをリフォーマットするには、次のいずれかを実行します:

- CI Lintレスポンスを直接`jq`にパイプします。
- APIレスポンスをテキストファイルとして保存し、次のように`jq`に引数として提供します:

  ```shell
  jq --raw-output '.merged_yaml | fromjson' <your_input_here>
  ```

たとえば、次のJSON配列:

```json
{"valid":"true","errors":[],"merged_yaml":"---\n.api_test:\n  rules:\n  - if: $CI_PIPELINE_SOURCE==\"merge_request_event\"\n    changes:\n    - src/api/*\ndeploy:\n  rules:\n  - when: manual\n    allow_failure: true\n  extends:\n  - \".api_test\"\n  script:\n  - echo \"hello world\"\n"}
```

解析およびリフォーマットすると、結果のYAMLファイルには次のものが含まれます:

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

## 新しいCI/CD設定を検証します {#validate-a-new-cicd-configuration}

指定されたプロジェクトの新しい`.gitlab-ci.yml`設定を検証します。このエンドポイントは、プロジェクトのコンテキストでCI/CD設定を検証します。以下を含みます:

- プロジェクトのCI/CD変数の使用。
- プロジェクトのファイルで`include:local`エントリを検索します。

```plaintext
POST /projects/:id/ci/lint
```

| 属性      | 型    | 必須 | 説明 |
|----------------|---------|----------|-------------|
| `content`      | 文字列  | はい      | CI/CD設定コンテンツ。 |
| `dry_run`      | ブール値 | いいえ       | [パイプライン作成シミュレーション](../ci/yaml/lint.md#simulate-a-pipeline)を実行するか、静的チェックのみを実行します。デフォルトは`false`です。 |
| `include_jobs` | ブール値 | いいえ       | 静的チェックまたはパイプラインシミュレーションに存在するジョブのリストをレスポンスに含めるかどうか。デフォルトは`false`です。 |
| `ref`          | 文字列  | いいえ       | `dry_run`が`true`の場合、CI/CD YAML設定を検証するために使用するブランチまたはタグコンテキストを設定します。未設定の場合、デフォルトはプロジェクトのデフォルトブランチです。 |

リクエスト例:

```shell
curl --header "Content-Type: application/json" \
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

- 検証済みの設定:

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

## 既存のCI/CD設定を検証します {#validate-an-existing-cicd-configuration}

{{< history >}}

- `sha`属性は、GitLab 16.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/369212)されました。
- `sha`と`ref`は、GitLab 16.10で`content_ref`と`dry_run_ref`に[名前が変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/143098)されました。

{{< /history >}}

指定されたプロジェクトの既存の`.gitlab-ci.yml`設定を検証します。このエンドポイントは、プロジェクトのコンテキストでCI/CD設定を検証します。以下を含みます:

- プロジェクトのCI/CD変数の使用。
- プロジェクトのファイルで`include:local`エントリを検索します。

```plaintext
GET /projects/:id/ci/lint
```

| 属性      | 型    | 必須 | 説明 |
|----------------|---------|----------|-------------|
| `content_ref`  | 文字列  | いいえ       | CI/CD設定コンテンツは、このコミットSHA、ブランチ、またはタグから取得されます。設定されていない場合、プロジェクトのデフォルトブランチのヘッドのSHAにデフォルト設定されます。 |
| `dry_run`      | ブール値 | いいえ       | パイプライン作成シミュレーションを実行するか、または静的チェックのみ実行します。 |
| `dry_run_ref`  | 文字列  | いいえ       | `dry_run`が`true`の場合、CI/CD YAML設定を検証するために使用するブランチまたはタグコンテキストを設定します。未設定の場合、デフォルトはプロジェクトのデフォルトブランチです。 |
| `include_jobs` | ブール値 | いいえ       | 静的チェックまたはパイプラインシミュレーションに存在するジョブのリストをレスポンスに含めるかどうか。デフォルトは`false`です。 |
| `ref`          | 文字列  | いいえ       | （非推奨）`dry_run`が`true`の場合、CI/CD YAML設定を検証するために使用するブランチまたはタグコンテキストを設定します。未設定の場合、デフォルトはプロジェクトのデフォルトブランチです。代わりに`dry_run_ref`を使用してください。 |
| `sha`          | 文字列  | いいえ       | （非推奨）CI/CD設定コンテンツは、このコミットSHA、ブランチ、またはタグから取得されます。設定されていない場合、プロジェクトのデフォルトブランチのヘッドのSHAにデフォルト設定されます。代わりに`content_ref`を使用してください。 |

リクエスト例:

```shell
curl --url "https://gitlab.example.com/api/v4/projects/:id/ci/lint"
```

レスポンス例:

- 検証済みの設定、`include.yml`を[含まれるファイル](../ci/yaml/_index.md#include)として、`include_jobs`を`true`に設定:

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
