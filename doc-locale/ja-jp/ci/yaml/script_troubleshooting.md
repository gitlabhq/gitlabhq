---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: トラブルシューティングスクリプトおよびジョブログ
---

## `:`を使用するスクリプト内の`Syntax is incorrect` {#syntax-is-incorrect-in-scripts-that-use-}

スクリプトでコロン（`:`）を使用すると、GitLabは次のように出力することがあります。

- `Syntax is incorrect`
- `script config should be a string or a nested array of strings up to 10 levels deep`

たとえば、cURLコマンドの一部として`"PRIVATE-TOKEN: ${PRIVATE_TOKEN}"`を使用する場合:

```yaml
pages-job:
  stage: deploy
  script:
    - curl --header 'PRIVATE-TOKEN: ${PRIVATE_TOKEN}' "https://gitlab.example.com/api/v4/projects"
  environment: production
```

YAMLパーサーは、`:`がYAMLのキーワードを定義していると判断し、`Syntax is incorrect`エラーを出力します。

コロンを含むコマンドを使用するには、コマンド全体を一重引用符で囲む必要があります。既存の一重引用符（`'`）を二重引用符（`"`）に変更する必要がある場合があります。

```yaml
pages-job:
  stage: deploy
  script:
    - 'curl --header "PRIVATE-TOKEN: ${PRIVATE_TOKEN}" "https://gitlab.example.com/api/v4/projects"'
  environment: production
```

## スクリプトで`&&`を使用してもジョブが失敗しない {#job-does-not-fail-when-using--in-a-script}

`&&`を使用して2つのコマンドを1つのスクリプト行に結合すると、いずれかのコマンドが失敗した場合でも、ジョブが成功として返される場合があります。例: 

```yaml
job-does-not-fail:
  script:
    - invalid-command xyz && invalid-command abc
    - echo $?
    - echo "The job should have failed already, but this is executed unexpectedly."
```

2つのコマンドが失敗しても、`&&`演算子は`0`の終了コードを返し、引き続きジョブが実行されます。どちらかのコマンドが失敗した場合にスクリプトを強制的に終了させるには、行全体を括弧で囲みます。

```yaml
job-fails:
  script:
    - (invalid-command xyz && invalid-command abc)
    - echo "The job failed already, and this is not executed."
```

## 折り畳まれたYAML複数行スカラーによって複数行コマンドが保持されない {#multiline-commands-not-preserved-by-folded-yaml-multiline-block-scalar}

`- >`折りたたみYAML複数行ブロックスカラーを使用して長いコマンドを分割すると、追加のインデントにより、行が個々のコマンドとして処理されます。

例: 

```yaml
script:
  - >
    RESULT=$(curl --silent
      --header
        "Authorization: Bearer $CI_JOB_TOKEN"
      "${CI_API_V4_URL}/job"
    )
```

この場合、インデントによって改行が保持されるため、失敗します。

```plaintext
$ RESULT=$(curl --silent # collapsed multi-line command
curl: no URL specified!
curl: try 'curl --help' or 'curl --manual' for more information
/bin/bash: line 149: --header: command not found
/bin/bash: line 150: https://gitlab.example.com/api/v4/job: No such file or directory
```

次のいずれかの方法でこれを解決します。

- 余分なインデントを削除します。

  ```yaml
  script:
    - >
      RESULT=$(curl --silent
      --header
      "Authorization: Bearer $CI_JOB_TOKEN"
      "${CI_API_V4_URL}/job"
      )
  ```

- シェルの行継続を使用するなど、余分な改行が処理されるようにスクリプトを変更します。

  ```yaml
  script:
    - >
      RESULT=$(curl --silent \
        --header \
          "Authorization: Bearer $CI_JOB_TOKEN" \
        "${CI_API_V4_URL}/job")
  ```

## ジョブログ出力が期待通りにフォーマットされていない、または予期しない文字が含まれている {#job-log-output-is-not-formatted-as-expected-or-contains-unexpected-characters}

色付けやフォーマットに`TERM`環境変数を使用するツールでは、ジョブログのフォーマットが正しく表示されないことがあります。たとえば、`mypy`コマンドの場合:

![出力例](img/incorrect_log_rendering_v16_5.png)

GitLab Runnerは、コンテナのシェルを非対話モードで実行するため、シェルの`TERM`環境変数が`dumb`に設定されます。これらのツールのフォーマットを修正するには、以下を実行します。

- コマンドを実行する前に、シェルの環境で`TERM=ansi`を設定するための別のスクリプト行を追加します。
- 値が`ansi`の`TERM`[CI/CD変数](../variables/_index.md)を追加します。

## `after_script`セクションの実行が早期に停止し、`$CI_JOB_STATUS`の値が正しくない {#after_script-section-execution-stops-early-and-incorrect-ci_job_status-values}

GitLab Runner 16.9.0から16.11.0:

- `after_script`セクションの実行が途中で停止することがあります。
- `$CI_JOB_STATUS`定義済み変数のステータスは、[ジョブのキャンセル中に誤って`failed`として設定されています](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/37485)。
