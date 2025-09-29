---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: "`rules`でジョブの実行タイミングを指定する"
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

[`rules`](../yaml/_index.md#rules)は、パイプラインにジョブを含めたり除外したりするために使用します。

ルールは順番に評価され、最初に一致したものが適用されます。一致が見つかると、そのジョブは設定に応じて、パイプラインに含められるか除外されます。

ルールはジョブの実行前に評価されるため、ジョブスクリプトで作成されたdotenv変数をルール内で使用することはできません。

キーワードの今後の改善については、[`rules`の改善を目的としたエピック](https://gitlab.com/groups/gitlab-org/-/epics/2783)で議論されており、誰でも提案やリクエストを追加できます。

## `rules`の例 {#rules-examples}

次の例では、`if`を使用して、2つの特定のケースでのみジョブが実行されるように定義しています。

```yaml
job:
  script: echo "Hello, Rules!"
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
      when: manual
      allow_failure: true
    - if: $CI_PIPELINE_SOURCE == "schedule"
```

- パイプラインがマージリクエスト用の場合、最初のルールが一致し、ジョブが次の属性を持って[マージリクエストパイプライン](../pipelines/merge_request_pipelines.md)に追加されます。
  - `when: manual`（手動ジョブ）
  - `allow_failure: true`（手動ジョブが実行されなくてもパイプラインの実行は継続される）
- パイプラインがマージリクエスト用**ではない**場合、最初のルールは一致せず、2番目のルールが評価されます。
- パイプラインがスケジュールされたパイプラインである場合、2番目のルールが一致し、ジョブがスケジュールされたパイプラインに追加されます。属性が定義されていないため、次の属性で追加されます。
  - `when: on_success`（デフォルト）
  - `allow_failure: false`（デフォルト）
- **その他すべての場合**では、一致するルールがないため、ジョブは他のパイプラインには**追加されません**。

または、いくつかのケースでジョブを除外し、それ以外のすべてのケースで実行するようなルールセットを定義することもできます。

```yaml
job:
  script: echo "Hello, Rules!"
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
      when: never
    - if: $CI_PIPELINE_SOURCE == "schedule"
      when: never
    - when: on_success
```

- パイプラインがマージリクエスト用の場合、ジョブはパイプラインに**追加されません**。
- パイプラインがスケジュールされたパイプラインの場合、ジョブはパイプラインに**追加されません**。
- **その他すべての場合では**、ジョブは`when: on_success`の設定でパイプラインに追加されます。

{{< alert type="warning" >}}

最後のルールとして`when`句（`when: never`を除く）を使用すると、2つのパイプラインが同時に開始される可能性があります。プッシュパイプラインとマージリクエストパイプラインが、同じイベント（オープンマージリクエストのソースブランチへのプッシュ）によってトリガーされる可能性があるためです。詳細については、[重複パイプラインを回避する](#avoid-duplicate-pipelines)方法をご覧ください。

{{< /alert >}}

### スケジュールされたパイプラインでジョブを実行する {#run-jobs-for-scheduled-pipelines}

パイプラインがスケジュールされている場合にのみ実行されるようにジョブを設定できます。次に例を示します。

```yaml
job:on-schedule:
  rules:
    - if: $CI_PIPELINE_SOURCE == "schedule"
  script:
    - make world

job:
  rules:
    - if: $CI_PIPELINE_SOURCE == "push"
  script:
    - make build
```

この例では、`make world`はスケジュールされたパイプラインで実行され、`make build`はブランチおよびタグパイプラインで実行されます。

### ブランチが空の場合にジョブをスキップする {#skip-jobs-if-the-branch-is-empty}

[`rules:changes:compare_to`](../yaml/_index.md#ruleschangescompare_to)を使用して、ブランチが空の場合にジョブをスキップします。これにより、CI/CDリソースを節約できます。この設定では、ブランチをデフォルトブランチと比較し、その結果に応じて処理します。

- ブランチに変更されたファイルがない場合、ジョブは実行されません。
- ブランチに変更されたファイルがある場合、ジョブは実行されます。

デフォルトブランチが`main`のプロジェクトの例を次に示します。

```yaml
job:
  script:
    - echo "This job only runs for branches that are not empty"
  rules:
    - if: $CI_COMMIT_BRANCH
      changes:
        compare_to: 'refs/heads/main'
        paths:
          - '**/*'
```

このジョブのルールは、現在のブランチにあるすべてのファイルとパス（`**/*`）を`main`ブランチと再帰的に比較します。ブランチ内のファイルが変更された場合にのみルールが一致し、ジョブが実行されます。

## 定義済み変数を使用した一般的な`if`句 {#common-if-clauses-with-predefined-variables}

`rules:if`句は、[定義済みCI/CD変数](../variables/predefined_variables.md)、特に[`CI_PIPELINE_SOURCE`定義済み変数](#ci_pipeline_source-predefined-variable)と組み合わせてよく使用されます。

次の例では、スケジュールされたパイプラインまたはプッシュパイプライン（ブランチまたはタグへのプッシュ）において、ジョブを手動ジョブとして`when: on_success`（デフォルト）で実行します。他のパイプラインタイプにはジョブは追加されません。

```yaml
job:
  script: echo "Hello, Rules!"
  rules:
    - if: $CI_PIPELINE_SOURCE == "schedule"
      when: manual
      allow_failure: true
    - if: $CI_PIPELINE_SOURCE == "push"
```

次の例では、[マージリクエストパイプライン](../pipelines/merge_request_pipelines.md)およびスケジュールされたパイプラインにおいて、ジョブを`when: on_success`ジョブとして実行します。他のパイプラインタイプでは実行されません。

```yaml
job:
  script: echo "Hello, Rules!"
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
    - if: $CI_PIPELINE_SOURCE == "schedule"
```

その他のよく使用される`if`句:

- `if: $CI_COMMIT_TAG`: タグに対する変更がプッシュされた場合。
- `if: $CI_COMMIT_BRANCH`: 任意のブランチに変更がプッシュされた場合。
- `if: $CI_COMMIT_BRANCH == "main"`: `main`ブランチに変更がプッシュされた場合。
- `if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH`: デフォルトブランチに変更がプッシュされた場合。異なるデフォルトブランチを持つ複数のプロジェクトで、同じ設定を使用する必要がある場合に使用します。
- `if: $CI_COMMIT_BRANCH =~ /regex-expression/`: コミットブランチが正規表現に一致する場合。
- `if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH && $CI_COMMIT_TITLE =~ /Merge branch.*/`: コミットブランチがデフォルトブランチであり、かつコミットメッセージのタイトルが正規表現に一致する場合。たとえば、マージコミットのデフォルトのコミットメッセージは`Merge branch`で始まります。
- `if: $CUSTOM_VARIABLE == "value1"`: カスタム変数`CUSTOM_VARIABLE`が`value1`と完全に一致する場合。

### 特定のパイプラインタイプでのみジョブを実行する {#run-jobs-only-in-specific-pipeline-types}

[定義済みCI/CD変数](../variables/predefined_variables.md)を[`rules`](../yaml/_index.md#rules)と組み合わせて使用することで、ジョブを実行するパイプラインタイプを選択できます。

次の表は、使用できる変数の一部と、各変数が制御できるパイプラインタイプを示しています。

- ブランチパイプライン: 新しいコミットやタグなど、ブランチへのGit `push`イベントで実行される。
- タグパイプライン: 新しいGitタグがブランチにプッシュされた場合にのみ実行される。
- [マージリクエストパイプライン](../pipelines/merge_request_pipelines.md): マージリクエストの変更（新しいコミットやマージリクエストのパイプラインタブで**パイプラインを実行する**を選択するなど）に応じて実行される。
- [スケジュールされたパイプライン](../pipelines/schedules.md)。

| 変数                                  | ブランチ | タグ | マージリクエスト | スケジュール |
|--------------------------------------------|--------|-----|---------------|-----------|
| `CI_COMMIT_BRANCH`                         | √    |     |               | √       |
| `CI_COMMIT_TAG`                            |        | √ |               | √（スケジュールされたパイプラインがタグで実行されるように設定されている場合） |
| `CI_PIPELINE_SOURCE = push`                | √    | √ |               |           |
| `CI_PIPELINE_SOURCE = schedule`            |        |     |               | √       |
| `CI_PIPELINE_SOURCE = merge_request_event` |        |     | √           |           |
| `CI_MERGE_REQUEST_IID`                     |        |     | √           |           |

たとえば、マージリクエストパイプラインやスケジュールされたパイプラインでは実行するが、ブランチパイプラインやタグパイプラインでは実行しないようにジョブを設定する場合は、次のようになります。

```yaml
job1:
  script:
    - echo
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
    - if: $CI_PIPELINE_SOURCE == "schedule"
    - if: $CI_PIPELINE_SOURCE == "push"
      when: never
```

### `CI_PIPELINE_SOURCE`定義済み変数 {#ci_pipeline_source-predefined-variable}

`CI_PIPELINE_SOURCE`変数を使用して、以下のパイプラインタイプにジョブを追加するタイミングを制御します。

| 値                           | 説明 |
|---------------------------------|-------------|
| `api`                           | [パイプラインAPI](../../api/pipelines.md#create-a-new-pipeline)によってトリガーされたパイプライン。 |
| `chat`                          | [GitLab ChatOps](../chatops/_index.md)コマンドを使用して作成されたパイプライン。 |
| `external`                      | GitLab以外のCIサービスを使用する場合。 |
| `external_pull_request_event`   | [GitHubの外部プルリクエスト](../ci_cd_for_external_repos/_index.md#pipelines-for-external-pull-requests)が作成または更新された場合。 |
| `merge_request_event`           | マージリクエストの作成または更新時に作成されたパイプライン。[マージリクエストパイプライン](../pipelines/merge_request_pipelines.md)、[マージ結果パイプライン](../pipelines/merged_results_pipelines.md)、[マージトレイン](../pipelines/merge_trains.md)を有効にする場合、必須。 |
| `ondemand_dast_scan`            | [DASTオンデマンドスキャン](../../user/application_security/dast/on-demand_scan.md)パイプライン。 |
| `ondemand_dast_validation`      | [DASTオンデマンド検証](../../user/application_security/dast/profiles.md#site-profile-validation)パイプライン。 |
| `parent_pipeline`               | [親/子パイプライン](../pipelines/downstream_pipelines.md#parent-child-pipelines)によってトリガーされたパイプライン。親パイプラインからトリガーできるように、子パイプラインの設定でこのパイプラインソースを使用します。 |
| `pipeline`                      | [`CI_JOB_TOKEN`を使用したAPI](../pipelines/downstream_pipelines.md#trigger-a-multi-project-pipeline-by-using-the-api)、または[`trigger`](../yaml/_index.md#trigger)キーワードにより作成された[マルチプロジェクトパイプライン](../pipelines/downstream_pipelines.md#multi-project-pipelines)。 |
| `push`                          | ブランチやタグを含む、Gitプッシュイベントによってトリガーされたパイプライン。 |
| `schedule`                      | [スケジュールされたパイプライン](../pipelines/schedules.md)。 |
| `security_orchestration_policy` | [スケジュールされたスキャン実行ポリシー](../../user/application_security/policies/scan_execution_policies.md)パイプライン。 |
| `trigger`                       | [トリガートークン](../triggers/_index.md#configure-cicd-jobs-to-run-in-triggered-pipelines)を使用して作成されたパイプライン。 |
| `web`                           | GitLab UIで、プロジェクトの**ビルド > パイプライン**セクションから**パイプラインを新規作成**を選択して作成されたパイプライン。 |
| `webide`                        | [Web IDE](../../user/project/web_ide/_index.md)を使用して作成されたパイプライン。 |

これらの値は、[パイプラインAPIエンドポイント](../../api/pipelines.md#list-project-pipelines)を使用する際に`source`パラメータとして返される値と同じです。

## 複合ルール {#complex-rules}

同じルール内で`if`、`changes`、`exists`などの`rules`キーワードをすべて使用できます。含まれるすべてのキーワードがtrueと評価された場合にのみ、そのルールはtrueと評価されます。

次に例を示します。

```yaml
docker build:
  script: docker build -t my-image:$CI_COMMIT_REF_SLUG .
  rules:
    - if: $VAR == "string value"
      changes:  # Include the job and set to when:manual if any of the follow paths match a modified file.
        - Dockerfile
        - docker/scripts/**/*
      when: manual
      allow_failure: true
```

`Dockerfile`ファイルまたは`/docker/scripts`内のファイルが変更され、**かつ**`$VAR` == 「文字列値」の場合、そのジョブは手動で実行され、失敗が許容されます。

[括弧](#join-variable-expressions-together)を`&&`や`||`と組み合わせて、より複雑な変数式を構築できます。

```yaml
job1:
  script:
    - echo This rule uses parentheses.
  rules:
    - if: ($CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH || $CI_COMMIT_BRANCH == "develop") && $MY_VARIABLE
```

## 重複パイプラインを回避する {#avoid-duplicate-pipelines}

ジョブで`rules`を使用する場合、ブランチへのコミットのプッシュなど、1つのアクションが複数のパイプラインをトリガーする可能性があります。複数のタイプのパイプラインをトリガーするためのルールを明示的に設定していなくても、この問題が起こり得ます。

重複パイプラインを引き起こす可能性のある一部の設定では、[パイプラインの警告](../debugging.md#pipeline-warnings)が表示されます。

次に例を示します。

```yaml
job:
  script: echo "This job creates double pipelines!"
  rules:
    - if: $CUSTOM_VARIABLE == "false"
      when: never
    - when: always
```

このジョブは`$CUSTOM_VARIABLE`がfalseの場合は実行されませんが、プッシュ（ブランチ）パイプラインとマージリクエストパイプラインの**両方**を含む、その他**すべての**パイプラインでは実行されます。この設定では、オープンマージリクエストのソースブランチにプッシュするたびに重複パイプラインが発生します。

重複パイプラインを回避するには、次の方法があります。

- [`workflow`](../yaml/_index.md#workflow)を使用して、実行可能なパイプラインのタイプを指定する。
- 非常に限られたケースでのみジョブを実行するようにルールを修正し、最後に`when`ルールを配置しない。

  ```yaml
  job:
    script: echo "This job does NOT create double pipelines!"
    rules:
      - if: $CUSTOM_VARIABLE == "true" && $CI_PIPELINE_SOURCE == "merge_request_event"
  ```

重複パイプラインを回避できるもう1つの方法は、プッシュ（ブランチ）パイプラインまたはマージリクエストパイプラインのいずれかを回避するようにジョブのルールを変更することです。ただし、`workflow: rules`を使用せずに`- when: always`ルールを使用した場合も、GitLabは依然として[パイプラインの警告](../debugging.md#pipeline-warnings)を表示します。

たとえば、次のスクリプトは二重パイプラインをトリガーしませんが、`workflow: rules`なしでの使用は推奨されていません。

```yaml
job:
  script: echo "This job does NOT create double pipelines!"
  rules:
    - if: $CI_PIPELINE_SOURCE == "push"
      when: never
    - when: always
```

[重複パイプラインを防ぐ`workflow:rules`](../yaml/workflow.md#switch-between-branch-pipelines-and-merge-request-pipelines)を使用しない場合、プッシュパイプラインとマージリクエストパイプラインの両方を同じジョブに含めるべきではありません。

```yaml
job:
  script: echo "This job creates double pipelines!"
  rules:
    - if: $CI_PIPELINE_SOURCE == "push"
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
```

また、同じパイプラインで`only/except`ジョブと`rules`ジョブを混在させないでください。YAMLエラーは発生しないかもしれませんが、`only/except`と`rules`のデフォルトの動作が異なるため、トラブルシューティングが困難な問題を引き起こす可能性があります。

```yaml
job-with-no-rules:
  script: echo "This job runs in branch pipelines."

job-with-rules:
  script: echo "This job runs in merge request pipelines."
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
```

ブランチに変更をプッシュするたびに、重複パイプラインが実行されます。1つのブランチパイプラインが1つのジョブ（`job-with-no-rules`）を実行し、1つのマージリクエストパイプラインが別のジョブ（`job-with-rules`）を実行します。ルールなしのジョブはデフォルトで[`except: merge_requests`](../yaml/deprecated_keywords.md#only--except)になるため、`job-with-no-rules`はマージリクエストを除くすべてのケースで実行されます。

## 異なるジョブでルールを再利用する {#reuse-rules-in-different-jobs}

[`!reference`タグ](../yaml/yaml_optimization.md#reference-tags)を使用して、異なるジョブでルールを再利用できます。`!reference`ルールと、ジョブで定義されている標準のルールを組み合わせることも可能です。次に例を示します。

```yaml
.default_rules:
  rules:
    - if: $CI_PIPELINE_SOURCE == "schedule"
      when: never
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH

job1:
  rules:
    - !reference [.default_rules, rules]
  script:
    - echo "This job runs for the default branch, but not schedules."

job2:
  rules:
    - !reference [.default_rules, rules]
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
  script:
    - echo "This job runs for the default branch, but not schedules."
    - echo "It also runs for merge requests."
```

## CI/CD変数式 {#cicd-variable-expressions}

[`rules:if`](../yaml/_index.md#rules)と変数式を組み合わせて、ジョブをパイプラインに追加するタイミングを制御します。

等価演算子`==`および`!=`を使用して、変数を文字列と比較できます。単一引用符と二重引用符のどちらも有効です。変数は比較の左辺に配置する必要があります。次に例を示します。

- `if: $VARIABLE == "some value"`
- `if: $VARIABLE != "some value"`

2つの変数の値を比較できます。次に例を示します。

- `if: $VARIABLE_1 == $VARIABLE_2`
- `if: $VARIABLE_1 != $VARIABLE_2`

変数を`null`キーワードと比較して、変数が定義されているかどうかを確認できます。次に例を示します。

- `if: $VARIABLE == null`
- `if: $VARIABLE != null`

変数が定義されているが空であるかどうかを確認できます。次に例を示します。

- `if: $VARIABLE == ""`
- `if: $VARIABLE != ""`

式で変数名のみを使用して、その変数が定義されており、かつ空でないかどうかを確認できます。次に例を示します。

- `if: $VARIABLE`

[変数式でCI/CD入力を使用する](../inputs/examples.md#use-cicd-inputs-in-variable-expressions)こともできます。

### 変数を正規表現と比較する {#compare-a-variable-to-a-regular-expression}

`=~`および`!~`演算子を使用して、変数値を正規表現とマッチングできます。正規表現を使用した変数パターンマッチングでは、[RE2正規表現構文](https://github.com/google/re2/wiki/Syntax)を使用します。

式は、次の場合に`true`として評価されます。

- `=~`を使用して一致が見つかった場合。
- `!~`を使用して一致が見つからなかった場合。

次に例を示します。

- `if: $VARIABLE =~ /^content.*/`
- `if: $VARIABLE !~ /^content.*/`

追加の注意点:

- `/./`などの1文字の正規表現はサポートされておらず、`invalid expression syntax`（無効な式構文）エラーが発生します。
- デフォルトでは、パターンマッチングは大文字と小文字を区別します。大文字と小文字を区別しないパターンにするには、`i`フラグ修飾子を使用します。例: `/pattern/i`。
- 正規表現でマッチングできるのは、タグ名またはブランチ名のみです。リポジトリパスが指定された場合、それは常にリテラルとして一致します。
- パターン全体を`/`で囲む必要があります。たとえば、`issue-/.*/`を使用して`issue-`で始まるすべてのタグ名またはブランチ名に一致させることはできませんが、`/issue-.*/`は使用可能です。
- `@`記号は、refのリポジトリパスの先頭を示します。正規表現で`@`文字を含むref名に一致させるには、16進文字コード`\x40`を使用する必要があります。
- 正規表現がタグ名またはブランチ名の部分文字列のみに一致するのを防ぐには、アンカー`^`と`$`を使用します。たとえば、`/^issue-.*$/`は`/^issue-/`と同等ですが、`/issue/`だけでは`severe-issues`という名前のブランチにも一致してしまいます。

### 正規表現を変数に保存する {#store-a-regular-expression-in-a-variable}

{{< history >}}

- GitLab 15.0で`ci_fix_rules_if_comparison_with_regexp_variable`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/35438)されました。デフォルトでは無効になっています。
- GitLab 15.1で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/359740)になり、機能フラグ`ci_fix_rules_if_comparison_with_regexp_variable`は削除されました。

{{< /history >}}

`=~`および`!~`式の右辺にある変数は、正規表現として評価されます。正規表現はスラッシュ（`/`）で囲む必要があります。次に例を示します。

```yaml
variables:
  pattern: '/^ab.*/'

regex-job1:
  variables:
    teststring: 'abcde'
  script: echo "This job will run, because 'abcde' matches the /^ab.*/ pattern."
  rules:
    - if: '$teststring =~ $pattern'

regex-job2:
  variables:
    teststring: 'fghij'
  script: echo "This job will not run, because 'fghi' does not match the /^ab.*/ pattern."
  rules:
    - if: '$teststring =~ $pattern'
```

正規表現内の変数は**解決されません**。次に例を示します。

```yaml
variables:
  string1: 'regex-job1'
  string2: 'regex-job2'
  pattern: '/$string2/'

regex-job1:
  script: echo "This job will NOT run, because the 'string1' variable inside the regex pattern is not resolved."
  rules:
    - if: '$CI_JOB_NAME =~ /$string1/'

regex-job2:
  script: echo "This job will NOT run, because the 'string2' variable inside the 'pattern' variable is not resolved."
  rules:
    - if: '$CI_JOB_NAME =~ $pattern'
```

### 変数式を結合する {#join-variable-expressions-together}

複数の式を`&&`（and）または`||`（or）を使用して結合できます。次に例を示します。

- `$VARIABLE1 =~ /^content.*/ && $VARIABLE2 == "something"`
- `$VARIABLE1 =~ /^content.*/ && $VARIABLE2 =~ /thing$/ && $VARIABLE3`
- `$VARIABLE1 =~ /^content.*/ || $VARIABLE2 =~ /thing$/ && $VARIABLE3`

演算子の優先順位は[Ruby 2.5標準](https://ruby-doc.org/core-2.5.0/doc/syntax/precedence_rdoc.html)に従うため、`&&`は`||`よりも先に評価されます。

括弧を使用して式をグループ化できます。括弧は`&&`や`||`よりも優先されるため、括弧内の式が先に評価され、その結果が式の残りの部分に使用されます。

括弧をネストして複雑な条件式を作成することもでき、最も内側の括弧内の式から順に評価されます。次に例を示します。

- `($VARIABLE1 =~ /^content.*/ || $VARIABLE2) && ($VARIABLE3 =~ /thing$/ || $VARIABLE4)`
- `($VARIABLE1 =~ /^content.*/ || $VARIABLE2 =~ /thing$/) && $VARIABLE3`
- `$CI_COMMIT_BRANCH == "my-branch" || (($VARIABLE1 == "thing" || $VARIABLE2 == "thing") && $VARIABLE3)`

## トラブルシューティング {#troubleshooting}

### `=~`を使用した正規表現マッチングでの予期しない動作 {#unexpected-behavior-from-regular-expression-matching-with-}

`=~`演算子を使用する場合は、比較の右辺に常に有効な正規表現が含まれていることを確認してください。

比較の右辺が`/`文字で囲まれた有効な正規表現でない場合、式は予期しない方法で評価されます。その場合、比較では、左辺が右辺の部分文字列かどうかがチェックされます。たとえば、`"23" =~ "1234"`はtrueと評価されますが、`"23" =~ /1234/`はfalseと評価されます。これらの結果は正反対なので注意が必要です。

このような挙動に依存したパイプライン設定は避けてください。
