---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: スクリプトとジョブログ
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

[`script`](_index.md#script)セクションでは、特別な構文を使用して以下を実行できます。

- [長いコマンドを分割](#split-long-commands)して、複数行のコマンドにする。
- [カラーコードを使用](#add-color-codes-to-script-output)して、ジョブログを簡単にレビューできるようにする。
- [カスタムの折りたたみ可能なセクションを作成](../jobs/job_logs.md#custom-collapsible-sections)して、ジョブログの出力を簡素化する。

## `script`で特殊文字を使用する

`script`コマンドは、一重引用符または二重引用符で囲む必要がある場合があります。たとえば、コロン（`:`）を含むコマンドは、一重引用符（`'`）で囲む必要があります。YAMLパーサーでは、テキストを「キー: 値」のペアではなく、文字列として解釈する必要があります。

たとえば、以下のスクリプトではコロンを使用します。

```yaml
job:
  script:
    - curl --request POST --header 'Content-Type: application/json' "https://gitlab.example.com/api/v4/projects"
```

有効なYAMLとして認識されるようにするには、コマンド全体を一重引用符で囲む必要があります。コマンドですでに一重引用符を使用している場合、可能であれば二重引用符（`"`）に変更する必要があります。

```yaml
job:
  script:
    - 'curl --request POST --header "Content-Type: application/json" "https://gitlab.example.com/api/v4/projects"'
```

[CI Lint](lint.md)ツールを使用して、構文が有効であることを確認できます。

次の文字を使用する場合も注意してください。

- `{`、`}`、`[`、`]`、`,`、`&`、`*`、`#`、`?`、`|`、`-`、`<`、`>`、`=`、`!`、`%`、`@`、`` ` ``。

## ゼロ以外の終了コードを無視する

スクリプトコマンドがゼロ以外の終了コードを返すと、ジョブは失敗し、それ以降のコマンドは実行されません。

この動作を回避するには、終了コードを変数に格納します。

```yaml
job:
  script:
    - false || exit_code=$?
    - if [ $exit_code -ne 0 ]; then echo "Previous command failed"; fi;
```

## すべてのジョブにデフォルトの`before_script`または`after_script`を設定する

[`before_script`](_index.md#before_script)および[`after_script`](_index.md#after_script)を、[`default`](_index.md#default)とともに使用できます。

- `before_script`を`default`とともに使用して、すべてのジョブで`script`コマンドの前に実行されるコマンドのデフォルトの配列を定義します。
- `after_script`をdefaultとともに使用して、ジョブの完了またはキャンセル後に実行されるコマンドのデフォルトの配列を定義します。

ジョブで別のdefaultを定義と、defaultを上書きすることができます。defaultを無視するには、`before_script: []`または`after_script: []`を使用します。

```yaml
default:
  before_script:
    - echo "Execute this `before_script` in all jobs by default."
  after_script:
    - echo "Execute this `after_script` in all jobs by default."

job1:
  script:
    - echo "These script commands execute after the default `before_script`,"
    - echo "and before the default `after_script`."

job2:
  before_script:
    - echo "Execute this script instead of the default `before_script`."
  script:
    - echo "This script executes after the job's `before_script`,"
    - echo "but the job does not use the default `after_script`."
  after_script: []
```

## ジョブがキャンセルされた場合に`after_script`コマンドをスキップする

{{< history >}}

- GitLab 17.0で、[`ci_canceling_status`というフラグ](../../administration/feature_flags.md)とともに[導入](https://gitlab.com/groups/gitlab-org/-/epics/10158)されました。デフォルトでは有効になっています。GitLab Runnerバージョン16.11.1が必要です。
- GitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/460285)になりました。機能フラグ`ci_canceling_status`が削除されました。

{{< /history >}}

`before_script`または`script`セクションの実行中にジョブがキャンセルされた場合、[`after_script`](_index.md)コマンドが実行されます。

UIのジョブのステータスは、`after_script`の実行中は`canceling`ですが、`after_script`コマンドが完了すると`canceled`に変わります。`after_script`コマンドの実行中、`$CI_JOB_STATUS`の定義済み変数の値は`canceled`になります。

ジョブのキャンセル後に`after_script`コマンドが実行されないようにするには、`after_script`セクションを次のように設定します。

1. `after_script`セクションの開始時に、`$CI_JOB_STATUS`の定義済み変数を確認します。
1. 値が`canceled`の場合は、実行をすぐに終了します。

以下に例を示します。

```yaml
job1:
  script:
    - my-script.sh
  after_script:
    - if [ "$CI_JOB_STATUS" == "canceled" ]; then exit 0; fi
    - my-after-script.sh
```

## 長いコマンドを分割する

`|`（リテラル）および`>`（折りたたみ）[YAMLの複数行ブロックスカラーのインジケーター](https://yaml-multiline.info/)を使用して、長いコマンドを複数行のコマンドに分割し、読みやすさを向上させることができます。

{{< alert type="warning" >}}

複数のコマンドが1つのコマンド文字列に結合されている場合、最後のコマンドの失敗または成功のみが報告されます。[バグにより、以前のコマンドからのエラーは無視されます](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/25394)。これを回避するには、各コマンドを個別の`script`項目として実行するか、各コマンド文字列に`exit 1`コマンドを追加します。

{{< /alert >}}

`|`（リテラル）YAML複数行ブロックスカラーインジケーターを使用して、ジョブ記述の`script`セクションで複数行のコマンドを記述できます。各行は個別のコマンドとして処理されます。ジョブログでは最初のコマンドのみが繰り返されますが、追加のコマンドも引き続き実行されます。

```yaml
job:
  script:
    - |
      echo "First command line."
      echo "Second command line."
      echo "Third command line."
```

上記の例は、ジョブログでは次のように表示されます。

```shell
$ echo First command line # collapsed multiline command
First command line
Second command line.
Third command line.
```

`>`（折りたたみ）YAML複数行ブロックスカラーインジケーターは、セクション間の空の行を新しいコマンドの開始として処理します。

```yaml
job:
  script:
    - >
      echo "First command line
      is split over two lines."

      echo "Second command line."
```

これは、`>`または`|`ブロックスカラーインジケーターを使用しない複数行コマンドと同様に動作します。

```yaml
job:
  script:
    - echo "First command line
      is split over two lines."

      echo "Second command line."
```

上記の2つの例は、ジョブログでは次のように表示されます。

```shell
$ echo First command line is split over two lines. # collapsed multiline command
First command line is split over two lines.
Second command line.
```

`>`または`|`ブロックスカラーインジケーターを省略すると、GitLabは空白以外の行を連結してコマンドを形成します。連結時に行を実行できることを確認してください。

<!-- vale gitlab_base.MeaningfulLinkWords = NO -->

[Shellのヒアドキュメント](https://en.wikipedia.org/wiki/Here_document)は、`|`および`>`演算子でも機能します。以下の例では、小文字を大文字に変換します。

<!-- vale gitlab_base.MeaningfulLinkWords = YES -->

```yaml
job:
  script:
    - |
      tr a-z A-Z << END_TEXT
        one two three
        four five six
      END_TEXT
```

結果:

```shell
$ tr a-z A-Z << END_TEXT # collapsed multiline command
  ONE TWO THREE
  FOUR FIVE SIX
```

## スクリプト出力にカラーコードを追加する

スクリプト出力は、[ANSIエスケープコード](https://en.wikipedia.org/wiki/ANSI_escape_code#Colors)を使用するか、ANSIエスケープコードを出力するコマンドまたはプログラムを実行することで色付けされます。

たとえば、[カラーコード付きのBash](https://misc.flogisoft.com/bash/tip_colors_and_formatting)を使用する場合:

```yaml
job:
  script:
    - echo -e "\e[31mThis text is red,\e[0m but this text isn't\e[31m however this text is red again."
```

カラーコードは、Shell環境変数、または[CI/CD変数](../variables/_index.md#define-a-cicd-variable-in-the-gitlab-ciyml-file)で定義できます。これにより、コマンドが読みやすく、再利用可能になります。

たとえば、上記と同じ例を使用して、`before_script`で定義された環境変数を使用します。

```yaml
job:
  before_script:
    - TXT_RED="\e[31m" && TXT_CLEAR="\e[0m"
  script:
    - echo -e "${TXT_RED}This text is red,${TXT_CLEAR} but this part isn't${TXT_RED} however this part is again."
    - echo "This text is not colored"
```

または、[PowerShellカラーコード](https://superuser.com/a/1259916)を使用する場合:

```yaml
job:
  before_script:
    - $esc="$([char]27)"; $TXT_RED="$esc[31m"; $TXT_CLEAR="$esc[0m"
  script:
    - Write-Host $TXT_RED"This text is red,"$TXT_CLEAR" but this text isn't"$TXT_RED" however this text is red again."
    - Write-Host "This text is not colored"
```

## トラブルシューティング

### `:`を使用するスクリプトの`Syntax is incorrect`

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

### スクリプトで`&&`を使用してもジョブが失敗しない

`&&`を使用して2つのコマンドを1つのスクリプト行に結合すると、いずれかのコマンドが失敗した場合でも、ジョブが成功として返される場合があります。以下に例を示します。

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

### 折りたたみYAML複数行ブロックスカラーで複数行コマンドが保持されない

`- >`折りたたみYAML複数行ブロックスカラーを使用して長いコマンドを分割すると、追加のインデントにより、行が個々のコマンドとして処理されます。

以下に例を示します。

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

### ジョブログの出力が希望どおりにフォーマットされないか、予期しない文字が含まれている

色付けやフォーマットに環境変数を使用するツールでは、ジョブログのフォーマットが正しく表示されないことがあります。たとえば、`mypy`コマンドの場合:

![出力例](img/incorrect_log_rendering_v16_5.png)

GitLab Runnerは、コンテナのシェルを非対話モードで実行するため、シェルの`TERM`環境変数が`dumb`に設定されます。これらのツールのフォーマットを修正するには、以下を実行します。

- コマンドを実行する前に、シェルの環境で`TERM=ansi`を設定するための別のスクリプト行を追加します。
- 値が`ansi`の`TERM`[CI/CD変数](../variables/_index.md)を追加します。

### `after_script`セクションの実行が途中で停止し、`$CI_JOB_STATUS`の値が正しくない

GitLab Runner 16.9.0から16.11.0:

- `after_script`セクションの実行が途中で停止することがあります。
- `$CI_JOB_STATUS`定義済み変数のステータスは、[ジョブのキャンセル中に誤って`failed`として設定されています](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/37485)。
