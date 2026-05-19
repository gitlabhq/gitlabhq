---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page,
  see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: dotenv変数を特定のジョブに渡す
description: "パイプライン内のジョブ間で環境変数を渡すには、dotenvレポートを使用します。"
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

環境変数を他のジョブに渡すには、dotenvファイルを使用します。dotenvファイルは、`.env`拡張子を持つファイルで、環境変数のキーと値のリストを格納します。たとえば、`sample.env`ファイルの場合:

```plaintext
REVIEW_URL=review.example.com/123456
BUILD_VERSION=v1.0.0
```

dotenvファイルを[dotenvレポートアーティファクト](../yaml/artifacts_reports.md#artifactsreportsdotenv)として保存します。これは、同じパイプライン内の他のジョブ、ダウンストリームパイプラインに渡したり、動的な環境変数URLを設定したりできます。

dotenv変数は以下の方法で使用できます:

- 1つのジョブで値を生成し、後続のジョブで使用します。
- パイプラインステージ間で計算された値を渡します。
- デプロイの出力に基づいて動的な環境変数URLを設定します。
- 複数プロジェクトのパイプライン間で変数を共有します。

dotenv変数はジョブスクリプトでのみ使用でき、パイプラインの設定には使用できません。それらはジョブ変数や`.gitlab-ci.yml`で定義されたデフォルト変数よりも[優先](_index.md#cicd-variable-precedence)されますが、プロジェクト、グループ、インスタンス、またはパイプライン変数よりも優先されることはありません。

同じ変数名が`dotenv`レポートに複数回出現する場合、最後の値が使用されます。

## 変数を以降のジョブに渡す {#pass-variables-to-later-jobs}

デフォルトでは、dotenv変数は以降のすべてのステージのジョブで利用可能です。ジョブ間で変数を渡すには:

1. ジョブで、`VARIABLE_NAME=value`の形式で変数を含むファイル（たとえば、`build.env`）を、1行に1つの変数ずつ作成します。
1. ファイルを`dotenv`レポートアーティファクトとして出力します。
1. 以降のジョブで、スクリプト内の変数を使用します。

たとえば、`build-job`は`BUILD_VERSION=v1.0.0`を含む`build.env`を作成し、`test-job`はそれを環境変数として自動的に受け取ります:

```yaml
build-job:
  stage: build
  script:
    - echo "BUILD_VERSION=v1.0.0" >> build.env
  artifacts:
    reports:
      dotenv: build.env

test-job:
  stage: test
  script:
    - echo "Testing version $BUILD_VERSION"  # Output: 'Testing version v1.0.0'
```

> [!warning]
> 認証情報、APIキー、トークンなどの機密データをdotenvファイルに含めないでください。パイプラインユーザーはdotenvファイルの内容にアクセスできます。アクセスを制限するには、[`artifacts:access`](../yaml/_index.md#artifactsaccess)を使用します。

## どのジョブがdotenv変数を受け取るかを制御する {#control-which-jobs-receive-dotenv-variables}

どのジョブがdotenv変数を受け取るかを制御するには、[`dependencies`](../yaml/_index.md#dependencies)または[`needs`](../yaml/_index.md#needs)キーワードを使用します。

### 特定のジョブから継承する {#inherit-from-specific-jobs}

特定のジョブのみに継承を制限するには、`dependencies`を使用します:

```yaml
build-job1:
  stage: build
  script:
    - echo "BUILD_VERSION=v1.0.0" >> build.env
  artifacts:
    reports:
      dotenv: build.env

build-job2:
  stage: build
  script:
    - echo "This job has no dotenv artifacts"

test-job:
  stage: test
  script:
    - echo "$BUILD_VERSION"  # Output: 'v1.0.0'
  dependencies:
    - build-job1
    # build-job2 is not listed, so its artifacts are not inherited
```

### dotenv変数を除外する {#exclude-dotenv-variables}

名前付きジョブからジョブがdotenv変数を受け取るのを防ぐには、`needs`と`artifacts: false`を使用します。これにより、そのジョブからのすべてのアーティファクトのダウンロードがdotenv変数だけでなくブロックされます:

```yaml
test-job:
  stage: test
  script:
    - echo "$BUILD_VERSION"  # Output: '' (empty)
  needs:
    - job: build-job1
      artifacts: false
```

この例の[`needs`](../yaml/_index.md#needs)は、`build-job1`が完了するとすぐにジョブを開始させます。

または、空の[`dependencies`](../yaml/_index.md)配列を使用して、すべてのアップストリームジョブからのアーティファクトのダウンロードをブロックします:

```yaml
test-job:
  stage: test
  script:
    - echo "$BUILD_VERSION"  # Output: '' (empty)
  dependencies: []
```

## ダウンストリームパイプラインに変数を渡す {#pass-variables-to-downstream-pipelines}

dotenv変数の継承によって、dotenv変数をダウンストリームパイプラインに渡すことができます。[マルチプロジェクトパイプライン](../pipelines/downstream_pipelines.md#multi-project-pipelines)で、アップストリームジョブにdotenvアーティファクトを作成し、ダウンストリームジョブで`needs`を使用して継承します:

1. `.env`ファイルに変数を保存します。
1. `.env`ファイルを`dotenv`レポートアーティファクトとして保存します。
1. ダウンストリームパイプラインをトリガーします。

```yaml
build_vars:
  stage: build
  script:
    - echo "BUILD_VERSION=hello" >> build.env
  artifacts:
    reports:
      dotenv: build.env

deploy:
  stage: deploy
  trigger: my/downstream_project
```

ダウンストリームパイプラインで、`needs`を使用してアップストリームジョブからアーティファクトを継承するようにジョブを設定します。そのジョブはdotenv変数を受け取り、スクリプトで`BUILD_VERSION`にアクセスできます:

```yaml
test:
  stage: test
  script:
    - echo $BUILD_VERSION
  needs:
    - project: my/upstream_project
      job: build_vars
      ref: master
      artifacts: true
```

## 動的な環境URLを設定する {#set-a-dynamic-environment-url}

デプロイメントジョブの完了後に、dotenv変数を使用して動的な環境変数URLを設定できます。これは、外部のホスティングプラットフォームがデプロイごとに動的にURLを生成する場合に便利です。

詳細については、[動的環境変数URLの設定](../environments/_index.md#set-a-dynamic-environment-url)を参照してください。

## 複雑な値を格納する {#store-complex-values}

dotenvファイルには、複数行の値やエスケープが必要な特殊文字に対する制限など、特定のフォーマット上の制限があります。値にJSONが含まれている場合、複数行にわたる場合、またはエスケープが必要な文字が含まれている場合は、dotenv変数の使用を避けてください。代わりに、別のファイルアーティファクトを使用してください。値の制約の完全なリストについては、[フォーマット要件](#format-requirements)を参照してください。

使用しない:

```yaml
# Not supported
- echo 'CONFIG={"key": "value"}' >> build.env
```

別個のアーティファクトを使用します:

```yaml
build-job:
  stage: build
  script:
    - echo '{"key": "value"}' > config.json
  artifacts:
    paths:
      - config.json
```

## Dotenvファイルの要件 {#dotenv-file-requirements}

dotenvファイルは、以下のフォーマット、サイズ、および変数の要件を満たす必要があります。

GitLabは、[dotenv gem](https://github.com/bkeepers/dotenv)を使用してdotenvファイルを処理しますが、[元のdotenvルール](https://github.com/motdotla/dotenv?tab=readme-ov-file#what-rules-does-the-parsing-engine-follow)とgemの実装を超えた追加の制限を適用します。

### フォーマット要件 {#format-requirements}

- [UTF-8エンコード](../jobs/job_artifacts_troubleshooting.md#error-message-fatal-invalid-argument-when-uploading-a-dotenv-artifact-on-a-windows-runner)のみがサポートされています。
- ファイルには空行やコメント（`#`で始まる行）を含めることはできません。
- 変数名には、ASCII文字（`A-Za-z`）、数字（`0-9`）、およびアンダースコア（`_`）のみを含めることができます。
- dotenvファイルはクォーティングをサポートしていません。シングルクォーテーションまたはダブルクォーテーションはそのまま保持され、エスケープには使用できません。
- 値には改行やその他のエスケープが必要な特殊文字を含めることはできません。
- 複数行の値はサポートされていません。GitLabはアップロード時にファイルを拒否します。
- 先頭および末尾のスペースまたは改行文字（`\n`）は削除されます。

### サイズと変数の制限 {#size-and-variable-limits}

| 制限                                                      | 値 |
| ---------------------------------------------------------- | ----- |
| 最大ファイルサイズ                                          | 5 KB  |
| GitLab Self-Managedにおけるデフォルトの最大継承変数数 | 20    |

GitLab.comのティア制限については、[GitLab.com CI/CD設定](../../user/gitlab_com/_index.md#cicd)を参照してください。

GitLab Self-Managedでこれらの制限を変更するには、[CI/CD制限](../../administration/instance_limits.md#cicd-limits)を参照してください。
