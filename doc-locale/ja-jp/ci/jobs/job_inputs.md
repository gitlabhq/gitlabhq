---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: ジョブインプット
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 18.10で[導入](https://gitlab.com/groups/gitlab-org/-/work_items/17833)されました。
- GitLab Runner 18.9以降が必要です。

{{< /history >}}

ジョブインプットを使用して、手動での実行時やジョブの再試行時にオーバーライドできる、個々のCI/CDジョブの型指定され検証されたパラメータを定義します。[CI/CD変数](../variables/_index.md)とは異なり、ジョブインプットには以下の機能があります:

- 型安全性: 入力は`string`、`number`、`boolean`、または`array`配列で、自動検証が可能です。
- 明示的な契約: ジョブは、定義した入力のみを受け入れます。予期しないインプットは拒否されます。
- オーバーライド機能: 入力値はジョブの[実行時](#run-a-manual-job-with-input-values)に設定でき、ジョブの[再試行時](#retry-a-job-with-different-input-values)に変更できます。

ジョブインプットは、ジョブの動作を制御し、ジョブを再実行する際に調整が必要になる可能性のあるパラメータに使用します。たとえば、デプロイターゲット、テスト設定、または機能フラグなどです。

ジョブインプットは、定義されているジョブにスコープされ、インクルードされたファイルや他のジョブからはアクセスできません。設定をジョブやファイル間で共有する必要がある場合は、代わりに[CI/CD設定入力](../inputs/_index.md)を使用してください。

## ジョブインプットの比較 {#job-input-comparison}

### CI/CDパイプライン設定入力との比較 {#compared-to-cicd-pipeline-configuration-inputs}

ジョブインプットと[CI/CDパイプライン設定入力](../inputs/_index.md)は異なる目的で使用されます:

| 機能        | ジョブインプット                                                              | CI/CD設定入力 |
|----------------|-------------------------------------------------------------------------|---------------------|
| 目的        | 個々のジョブの動作を設定します                                       | 再利用可能なテンプレートとコンポーネントを設定します |
| 構文         | ジョブ定義の`inputs:`                                             | 設定のヘッダーの`spec:inputs:` |
| 補間  | `${{ job.inputs.INPUT_NAME }}`                                          | `$[[ inputs.INPUT_NAME ]]` |
| 評価     | ジョブの作成時に設定される値で、実行時/再試行時にオーバーライドできます | パイプライン作成時に設定され、パイプライン全体で固定される値 |
| デフォルト値 | 必須                                                                | オプション |
| スコープ          | 単一のジョブのみ                                                         | 全体的な設定ファイル、またはインクルードされたファイルに渡されます |

### 環境変数との比較 {#compared-to-environment-variables}

ジョブインプットは、ジョブが作成されるときにジョブの設定に補間されます。これらは環境変数ではなく、`$INPUT_NAME`構文ではアクセスできません。ジョブインプットは、スクリプトやその他のサポートされているキーワードで`${{ job.inputs.INPUT_NAME }}`構文を使用して直接使用できます。

## ジョブインプットを定義して使用する {#define-and-use-job-inputs}

ジョブで`inputs`キーワードを使用して、入力のパラメータを定義します。各入力にはデフォルト値が必要です。入力値は、`${{ job.inputs.INPUT_NAME }}` [Moa expression](../functions/moa.md)構文で参照します。

例: 

```yaml
deploy_job:
  inputs:
    target_env:
      default: staging
      options: [staging, production]
    replicas:
      type: number
      default: 3
    debug_mode:
      type: boolean
      default: false
  script:
    - 'echo "Deploying to ${{ job.inputs.target_env }}"'
    - 'echo "Replicas - ${{ job.inputs.replicas }}"'
    - 'if [ "${{ job.inputs.debug_mode }}" == "true" ]; then set -x; fi'
    - ./deploy.sh
```

### インプットの設定 {#input-configuration}

以下のキーワードで入力を設定します:

- `default`: ジョブの実行時に使用されるデフォルト値。すべてのジョブインプットにはデフォルトが必要です。
- `type`: オプション。入力の型。`string`（デフォルト）、`number`、`boolean`、または`array`配列です。
- `description`: オプション。入力の目的を示す人間が読める説明。
- `options`: オプション。許可されている値のリスト。入力はこれらの値のいずれかに一致する必要があります。
- `regex`: オプション。入力が一致する必要がある正規表現パターン。

例: 

```yaml
test_job:
  inputs:
    test_framework:
      default: rspec
      description: Testing framework to use
      options: [rspec, minitest, cucumber]
    parallel_count:
      type: number
      default: 5
      description: Number of parallel test jobs
    run_integration_tests:
      type: boolean
      default: false
      description: Whether to run integration tests
    test_tags:
      type: array
      default: [smoke, regression]
      description: Test tags to run
  script:
    - bundle exec ${{ job.inputs.test_framework }}
    - 'echo "Running ${{ job.inputs.parallel_count }} parallel jobs"'
```

ジョブインプットは、ジョブが作成されるとき、および入力値がオーバーライドされるときに検証されます。検証が失敗すると、ジョブは明確なエラーメッセージを表示して起動に失敗します。

### インプットの型 {#input-types}

ジョブインプットは以下の型をサポートしています:

- `string`（デフォルト）: テキスト値。例えば`"staging"`または`"v1.2.3"`。
- `number`: 数値。例えば`5`、`3.14`、または`-10`。
- `boolean`: ブール値。`true`または`false`のいずれか。
- `array`: 値の配列。例えば`[1, 2, 3]`または`["a", "b"]`。

APIまたはUIを介して入力値を渡す場合、配列はJSON形式である必要があります。例: `["value1", "value2"]`。

### ジョブインプットを使用できる場所 {#where-you-can-use-job-inputs}

単純な補間、または演算子や関数を使ったより複雑な式を使用できます。完全な構文については、[Moa expression language](../functions/moa.md)を参照してください。

ジョブインプットは、以下のジョブキーワードとそのサブキーで使用できます:

- `script`、`before_script`、および`after_script`
- `artifacts`
- `cache`
- `image`
- `services`

### 制限 {#limitations}

ジョブインプットは、ジョブが実行されるときに評価される`${{ job.inputs.INPUT_NAME }}`構文を使用します。これは、パイプラインの設定が作成されるときではありません。ジョブインプットは、パイプライン作成時に評価する必要がある設定の一部では使用できません。例えば:

- ジョブ名
- `stage`キーワード
- `rules`キーワード
- `include`キーワード
- 上記にリストされていないその他のジョブレベルのキーワード

これらのパイプライン部分を動的に設定するには、代わりに[CI/CDパイプライン設定入力](../inputs/_index.md)で`$[[ inputs.* ]]`構文を使用します。

## 入力値を提供する {#provide-input-values}

ジョブインプット値は、以下の状況で指定できます:

- 手動ジョブを実行する場合。
- ジョブが完了した後に再試行する場合。

### 入力値を使用して手動ジョブを実行する {#run-a-manual-job-with-input-values}

入力が定義されている手動ジョブを実行すると、その入力値を指定できます。

特定の入力を使用して手動ジョブを実行するには:

1. パイプライン、ジョブ、または[環境](../environments/deployments.md#configure-manual-deployments)ビューに移動します。
1. 手動ジョブの名前を選択し、**実行** ({{< icon name="play" >}}) は選択しないでください。
1. フォームで、入力値を指定します。
1. **ジョブを実行**を選択します。

### 異なる入力値でジョブを再試行する {#retry-a-job-with-different-input-values}

入力が定義されているジョブを再試行する際に、入力値を更新できます。

異なる入力でジョブを再試行するには:

1. ジョブの詳細ページに移動します。
1. **変更した値でジョブを再実行** ({{< icon name="chevron-down" >}}) を選択します。
1. フォームでは、以前の実行時の値で入力が事前に埋められています。必要に応じて入力値を変更します。
1. **ジョブを再実行**を選択します。

同じ入力値で再試行するには、代わりに**再試行** ({{< icon name="retry" >}}) を選択します。

## ジョブインプットの例 {#job-input-examples}

### 入力を使用した基本的なデプロイメントジョブ {#basic-deployment-job-with-inputs}

```yaml
deploy:
  when: manual
  inputs:
    target_env:
      default: staging
      description: Target deployment environment
      options: [staging, production]
    version:
      default: latest
      description: Application version to deploy
  script:
    - 'echo "Deploying version ${{ job.inputs.version }} to ${{ job.inputs.target_env }}"'
    - ./deploy.sh --env ${{ job.inputs.target_env }} --version ${{ job.inputs.version }}
```

### 検証付きのテストジョブ {#test-job-with-validation}

```yaml
integration_tests:
  inputs:
    test_suite:
      default: smoke
      description: Which test suite to run
      options: [smoke, regression, full]
    parallel_jobs:
      type: number
      default: 5
      description: Number of parallel test runners
    enable_debug:
      type: boolean
      default: false
      description: Enable debug logging
    tags:
      type: array
      default: ["critical"]
      description: Test tags to run
  script:
    - 'if [ "${{ job.inputs.enable_debug }}" == "true" ]; then export DEBUG=1; fi'
    - ./run_tests.sh
        --suite ${{ job.inputs.test_suite }}
        --parallel ${{ job.inputs.parallel_jobs }}
        --tags '${{ job.inputs.tags }}'
```

### 安全チェック付きのデータベース移行 {#database-migration-with-safety-checks}

```yaml
migrate_database:
  when: manual
  inputs:
    target_db:
      default: development
      description: Database environment
      options: [development, staging, production]
    migration_name:
      default: ""
      description: Specific migration to run (leave empty for all)
      regex: ^[a-zA-Z0-9_]*$
    dry_run:
      type: boolean
      default: true
      description: Run in dry-run mode without applying changes
  script:
    - 'echo "Running migrations on ${{ job.inputs.target_db }}"'
    - |
      if [ "${{ job.inputs.dry_run }}" == "true" ]; then
        echo "DRY RUN MODE - no changes will be applied"
        MIGRATION_FLAGS="--dry-run"
      fi
    - |
      if [ -n "${{ job.inputs.migration_name }}" ]; then
        ./migrate.sh $MIGRATION_FLAGS --migration ${{ job.inputs.migration_name }}
      else
        ./migrate.sh $MIGRATION_FLAGS --all
      fi
```

## APIでジョブインプットを使用する {#use-job-inputs-with-the-api}

APIを使用してジョブを実行または再試行する際に、ジョブインプット値を指定できます。

### 入力を含む手動ジョブを実行する {#run-a-manual-job-with-inputs}

`job_inputs`パラメータとともに[`POST /projects/:id/jobs/:job_id/play`エンドポイント](../../api/jobs.md#run-a-job)を使用します:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_token>" \
  --header "Content-Type: application/json" \
  --data '{
    "job_inputs": {
      "environment": "staging",
      "version": "v2.1.0"
    }
  }' \
  "https://gitlab.example.com/api/v4/projects/1/jobs/456/play"
```

### 入力を使用してジョブを再試行する {#retry-a-job-with-inputs}

`job_inputs`パラメータとともに[`POST /projects/:id/jobs/:job_id/retry`エンドポイント](../../api/jobs.md#retry-a-job)を使用します:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_token>" \
  --header "Content-Type: application/json" \
  --data '{
    "job_inputs": {
      "environment": "production",
      "replicas": 10
    }
  }' \
  "https://gitlab.example.com/api/v4/projects/1/jobs/123/retry"
```

### GraphQLを使用する {#use-graphql}

[`jobPlay`ミューテーション](../../api/graphql/reference/_index.md#mutationjobplay)または[`jobRetry`ミューテーション](../../api/graphql/reference/_index.md#mutationjobretry)を`inputs`引数とともに使用できます:

```graphql
mutation {
  jobPlay(input: {
    id: "gid://gitlab/Ci::Build/123",
    inputs: [
      { name: "environment", value: "production" },
      { name: "replicas", value: 10 }
    ]
  }) {
    job {
      id
      status
    }
    errors
  }
}
```

## トラブルシューティング {#troubleshooting}

### ジョブが`input must have a default value`で失敗する {#job-fails-with-input-must-have-a-default-value}

ジョブインプットには、入力が手動で指定できないパイプラインでジョブが実行されることを保証するために、常にデフォルト値が必要です。

このエラーを修正するには、すべての入力に`default`を追加します:

```yaml
my_job:
  inputs:
    target_env:
      default: staging  # Default specified
  script:
    - echo ${{ job.inputs.target_env }}
```

### 入力の検証が`unexpected value`で失敗しました {#input-validation-fails-with-unexpected-value}

入力の検証が失敗した場合は、以下を確認してください:

- `options`を使用している場合、値が許可されているオプションのいずれかと正確に一致していることを確認してください（大文字と小文字を区別）。
- `regex`を使用している場合、正規表現が入力値に一致するかをテストしてください。
- `type: number`を使用している場合、値が文字列ではなく数値であることを確認してください。
- `type: array`を使用している場合、APIを介して渡す際に値がJSON配列としてフォーマットされていることを確認してください。
