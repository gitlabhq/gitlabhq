---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: ジョブスクリプトでCI/CD変数を使用する
description: 設定、使用方法、セキュリティ。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

すべてのCI/CD変数は、ジョブの環境内で環境変数として設定されます。各環境のシェルに対して標準的な形式でジョブスクリプト内の変数を使用できます。

環境変数にアクセスするには、[Runner executorのシェル](https://docs.gitlab.com/runner/executors/)の構文を使用します。

## Bash、`sh`などでの使用 {#with-bash-sh-and-similar}

Bash、`sh`、および同様のシェルで環境変数にアクセスするには、CI/CD変数に（`$`）をプレフィックスとして付けます:

```yaml
job_name:
  script:
    - echo "$CI_JOB_ID"
```

## PowerShellでの使用 {#with-powershell}

システムによって設定された環境変数を含む、Windows PowerShell環境で変数にアクセスするには、変数名の前に`$env:`または`$`を付けます:

```yaml
job_name:
  script:
    - echo $env:CI_JOB_ID
    - echo $CI_JOB_ID
    - echo $env:PATH
```

[場合によっては](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/4115#note_157692820)、環境変数を適切に展開するには次のように引用符で囲む必要があります:

```yaml
job_name:
  script:
    - D:\\qislsf\\apache-ant-1.10.5\\bin\\ant.bat "-DsosposDailyUsr=$env:SOSPOS_DAILY_USR" portal_test
```

## Windowsバッチでの使用 {#with-windows-batch}

WindowsバッチでCI/CD変数にアクセスするには、次のように変数を`%`で囲みます:

```yaml
job_name:
  script:
    - echo %CI_JOB_ID%
```

[遅延展開](https://ss64.com/nt/delayedexpansion.html)には、変数を`!`で囲むこともできます。空白または改行を含む変数には、遅延展開が必要な場合があります:

```yaml
job_name:
  script:
    - echo !ERROR_MESSAGE!
```

## サービスコンテナ内での使用 {#in-service-containers}

[サービスコンテナ](../docker/using_docker_images.md)はCI/CD変数を使用できますが、デフォルトでは[`.gitlab-ci.yml`ファイルに保存された変数](_index.md#define-a-cicd-variable-in-the-gitlab-ciyml-file)にのみアクセスできます。サービスコンテナはデフォルトで信頼されないため、[GitLab UIで追加された](_index.md#define-a-cicd-variable-in-the-ui)変数は、サービスコンテナでは使用できません。

UIで定義した変数をサービスコンテナで使用できるようにするには、`.gitlab-ci.yml`で別の変数に再割り当てることができます:

```yaml
variables:
  SA_PASSWORD_YAML_FILE: $SA_PASSWORD_UI
```

再割り当てされた変数は、元の変数と同じ名前にすることはできません。名前が同じの場合、正しく展開されません。

## 環境変数を別のジョブに渡す {#pass-an-environment-variable-to-another-job}

ジョブで新しい環境変数を作成し、後のステージで別のジョブに渡すことができます。これらの変数は、パイプラインを設定するためのCI/CD変数として（たとえば、[`rules`キーワード](../yaml/_index.md#rules)で）使用することはできませんが、ジョブスクリプトでは使用できます。

ジョブで作成された環境変数は、次の方法で他のジョブに渡せます:

1. ジョブスクリプトで、変数を`.env`ファイルとして保存します。
   - ファイルの形式は、1行に1つの変数定義である必要があります。
   - 各行は、`VARIABLE_NAME=ANY VALUE HERE`という形式で記述する必要があります。
   - 値は引用符で囲むことができますが、改行文字を含めることはできません。
1. `.env`ファイルを[`artifacts:reports:dotenv`](../yaml/artifacts_reports.md#artifactsreportsdotenv)アーティファクトとして保存します。
1. 後のステージのジョブは、[ジョブが`dotenv`変数を受け取らないように構成](#control-which-jobs-receive-dotenv-variables)されていない限り、スクリプトで変数を使用できます。

例: 

```yaml
build-job:
  stage: build
  script:
    - echo "BUILD_VARIABLE=value_from_build_job" >> build.env
  artifacts:
    reports:
      dotenv: build.env

test-job:
  stage: test
  script:
    - echo "$BUILD_VARIABLE"  # Output is: 'value_from_build_job'
```

`dotenv`レポートからの変数は、ジョブ定義変数など、特定のタイプの新しい変数定義よりも[優先](_index.md#cicd-variable-precedence)されます。

[`dotenv`変数をダウンストリームパイプラインに渡す](../pipelines/downstream_pipelines.md#pass-dotenv-variables-created-in-a-job)こともできます。

### どのジョブが`dotenv`変数を受け取るかを制御する {#control-which-jobs-receive-dotenv-variables}

[`dependencies`](../yaml/_index.md#dependencies)キーワードまたは[`needs`](../yaml/_index.md#needs)キーワードを使用して、どのジョブが`dotenv`アーティファクトを受け取るのかを制御できます。

次の手順で、`dotenv`アーティファクトから環境変数を受け取らないようにできます:

- 空の`dependencies`または`needs`配列を渡す。
- [`needs:artifacts`](../yaml/_index.md#needsartifacts)を`false`として渡す。
- `dotenv`アーティファクトを持たないジョブのみをリストするように`needs`を設定する。

例: 

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
  needs: []
  script:
    - echo "This job has no dotenv artifacts"

test-job1:
  stage: test
  script:
    - echo "$BUILD_VERSION"  # Output is: 'v1.0.0'
  dependencies:
    - build-job1

test-job2:
  stage: test
  script:
    - echo "$BUILD_VERSION"  # Output is ''
  dependencies: []

test-job3:
  stage: test
  script:
    - echo "$BUILD_VERSION"  # Output is: 'v1.0.0'
  needs:
    - build-job1

test-job4:
  stage: test
  script:
    - echo "$BUILD_VERSION"  # Output is: 'v1.0.0'
  needs:
    - job: build-job1
      artifacts: true

test-job5:
  stage: deploy
  script:
    - echo "$BUILD_VERSION"  # Output is ''
  needs:
    - job: build-job1
      artifacts: false

test-job6:
  stage: deploy
  script:
    - echo "$BUILD_VERSION"  # Output is ''
  needs:
    - build-job2
```

## `script`セクションから`artifacts`または`cache`に環境変数を渡します。 {#pass-an-environment-variable-from-the-script-section-to-artifacts-or-cache}

{{< history >}}

- GitLab 16.4で[導入](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/29391)されました。

{{< /history >}}

`$GITLAB_ENV`を使用して、`script`セクションで定義された環境変数を`artifacts`または`cache`キーワードで使用します。例: 

```yaml
build-job:
  stage: build
  script:
    - echo "ARCH=$(arch)" >> $GITLAB_ENV
    - touch some-file-$(arch)
  artifacts:
    paths:
      - some-file-$ARCH
```

## 1つの変数に複数の値を格納する {#store-multiple-values-in-one-variable}

値の配列であるCI/CD変数を作成することはできませんが、シェルスクリプト手法を使用して同様の動作を実現できます。

たとえば、スペースで区切られた複数の値を変数に格納し、スクリプトでその値をループ処理できます:

```yaml
job1:
  variables:
    FOLDERS: src test docs
  script:
    - |
      for FOLDER in $FOLDERS
        do
          echo "The path is root/${FOLDER}"
        done
```

## 他の変数でCI/CD変数を使用する {#use-cicd-variables-in-other-variables}

次のように、他の変数内で変数を使用できます:

```yaml
job:
  variables:
    FLAGS: '-al'
    LS_CMD: 'ls "$FLAGS"'
  script:
    - 'eval "$LS_CMD"'  # Executes 'ls -al'
```

### 文字列の一部として {#as-part-of-a-string}

文字列の一部として変数を使用できます。中括弧（`{}`）で変数を囲み、変数名を周囲のテキストから区別しやすくすることができます。中括弧がない場合、隣接するテキストは変数名の一部として解釈されます。例: 

```yaml
job:
  variables:
    FLAGS: '-al'
    DIR: 'path/to/directory'
    LS_CMD: 'ls "$FLAGS"'
    CD_CMD: 'cd "${DIR}_files"'
  script:
    - 'eval "$LS_CMD"'  # Executes 'ls -al'
    - 'eval "$CD_CMD"'  # Executes 'cd path/to/directory_files'
```

### CI/CD変数で`$`文字を使用する {#use-the--character-in-cicd-variables}

`$`文字を別の変数の開始として解釈させたくない場合は、代わりに`$$`を使用します:

```yaml
job:
  variables:
    FLAGS: '-al'
    LS_CMD: 'ls "$FLAGS" $$TMP_DIR'
  script:
    - 'eval "$LS_CMD"'  # Executes 'ls -al $TMP_DIR'
```

これは、[CI/CD変数をダウンストリームパイプラインに渡す](../pipelines/downstream_pipelines_troubleshooting.md#variable-with--character-does-not-get-passed-to-a-downstream-pipeline-properly)場合には機能しません。
