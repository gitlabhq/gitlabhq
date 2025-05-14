---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab CI/CDの`workflow`キーワード
---

{{< details >}}

- プラン:Free、Premium、Ultimate
- 提供形態:GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

[`workflow`](_index.md#workflow)キーワードを使用すると、パイプラインが作成されるタイミングを制御できます。

`workflow`キーワードは、ジョブの前に評価されます。たとえば、ジョブがタグに対して実行するように設定されていても、ワークフローでタグパイプラインを禁止している場合、ジョブは実行されません。

## `workflow:rules`の一般的な`if`句

`workflow: rules`の`if`句の例:

| ルールの例                                        | 詳細                                                   |
|------------------------------------------------------|-----------------------------------------------------------|
| `if: '$CI_PIPELINE_SOURCE == "merge_request_event"'` | マージリクエストパイプラインが実行されるタイミングを制御します。                 |
| `if: '$CI_PIPELINE_SOURCE == "push"'`                | ブランチパイプラインとタグパイプラインの両方が実行されるタイミングを制御します。 |
| `if: $CI_COMMIT_TAG`                                 | タグパイプラインが実行されるタイミングを制御します。                           |
| `if: $CI_COMMIT_BRANCH`                              | ブランチパイプラインが実行されるタイミングを制御します。                        |

詳細については、「[`rules`の一般的な`if`句](../jobs/job_rules.md#common-if-clauses-with-predefined-variables)」を参照してください。

## `workflow: rules`の例

次の例では、以下が実行されます。

- パイプラインは、すべての`push`イベント（ブランチへの変更と新しいタグ）を実行します。
- `-draft`で終わるコミットメッセージを含むプッシュイベントのパイプラインは、`when: never`に設定されているため、実行されません。
- スケジュールまたはマージリクエストのパイプラインも、該当するルールの評価が「真」にならないため、実行されません。

```yaml
workflow:
  rules:
    - if: $CI_COMMIT_MESSAGE =~ /-draft$/
      when: never
    - if: $CI_PIPELINE_SOURCE == "push"
```

この例には厳密なルールがあり、条件に合わない場合にはパイプラインは**実行されません**。

別の方法として、すべてのルールを`when: never`にして、最後に`when: always`ルールを使用することもできます。`when: never`ルールに一致するパイプラインは実行されません。その他のすべてのパイプラインタイプは実行されます。例は以下のとおりです。

```yaml
workflow:
  rules:
    - if: $CI_PIPELINE_SOURCE == "schedule"
      when: never
    - if: $CI_PIPELINE_SOURCE == "push"
      when: never
    - when: always
```

この例では、スケジュールまたは`push`（ブランチとタグ）パイプラインのパイプラインが禁止されています。最後の`when: always`ルールは、マージリクエストパイプライン**などの**その他すべてのパイプラインタイプを実行します。

### ブランチパイプラインとマージリクエストパイプラインを切り替える

マージリクエストの作成後に、パイプラインをブランチパイプラインからマージリクエストパイプラインに切り替えるには、`.gitlab-ci.yml`ファイルに`workflow: rules`セクションを追加します。

両方のパイプラインタイプを同時に使用すると、[重複するパイプライン](../jobs/job_rules.md#avoid-duplicate-pipelines)が同時に実行される可能性があります。重複するパイプラインを防ぐには、[`CI_OPEN_MERGE_REQUESTS`変数](../variables/predefined_variables.md)を使用します。

ブランチパイプラインとマージリクエストパイプラインのみを実行し、その他の場合にはパイプラインを実行しないプロジェクトの例は以下のとおりです。以下を実行します。

- ブランチに対してマージリクエストが開かれていない場合は、ブランチパイプラインを実行する。
- ブランチに対してマージリクエストが開かれている場合は、マージリクエストパイプラインを実行する。

```yaml
workflow:
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
    - if: $CI_COMMIT_BRANCH && $CI_OPEN_MERGE_REQUESTS
      when: never
    - if: $CI_COMMIT_BRANCH
```

GitLabがトリガーを試行する場合:

- マージリクエストパイプラインの場合は、パイプラインを開始します。たとえば、マージリクエストパイプラインは、関連付けられたオープンマージリクエストがあるブランチへのプッシュでトリガーできます。
- ブランチパイプラインで、そのブランチに対してマージリクエストが開かれている場合は、ブランチパイプラインを実行しません。たとえば、ブランチパイプラインは、ブランチへの変更、APIコール、スケジュール済みパイプラインなどでトリガーできます。
- ブランチパイプラインで、ブランチに対して開かれているマージリクエストがない場合は、ブランチパイプラインを実行します。

マージリクエストの作成時にブランチパイプラインからマージリクエストパイプラインに切り替えるルールを既存の`workflow`セクションに追加することもできます。

このルールを`workflow`セクションの先頭に追加し、その後に既存の他のルールを追加します。

```yaml
workflow:
  rules:
    - if: $CI_COMMIT_BRANCH && $CI_OPEN_MERGE_REQUESTS && $CI_PIPELINE_SOURCE == "push"
      when: never
    - # Previously defined workflow rules here
```

ブランチで実行される[トリガーされたパイプライン](../triggers/_index.md)には、`$CI_COMMIT_BRANCH`が設定されており、同様のルールによってブロックされる可能性があります。トリガーされたパイプラインのパイプラインソースは、`trigger`または`pipeline`であるため、`&& $CI_PIPELINE_SOURCE == "push"`を使用すると、ルールがトリガーされたパイプラインをブロックしなくなります。

### マージリクエストパイプラインを使用したGit Flow

`workflow: rules`は、マージリクエストパイプラインで使用できます。これらのルールを使用すると、フィーチャーブランチで[マージリクエストパイプライン機能](../pipelines/merge_request_pipelines.md)を使用しながら、長期的なブランチを維持してソフトウェアの複数のバージョンをサポートできます。

マージリクエスト、タグ、保護ブランチのパイプラインのみを実行する例は、以下のとおりです。

```yaml
workflow:
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
    - if: $CI_COMMIT_TAG
    - if: $CI_COMMIT_REF_PROTECTED == "true"
```

この例では、長期的なブランチが[保護されている](../../user/project/repository/branches/protected.md)ことを前提としています。

### 下書きマージリクエストのパイプラインをスキップする

`workflow: rules`を使用して、下書きマージリクエストのパイプラインをスキップできます。これらのルールを使用すると、開発が完了するまでコンピューティング時間の使用を回避できます。

たとえば、次のルールは、タイトルに`[Draft]`、`(Draft)`、または`Draft:`が含まれるマージリクエストのCIビルドを無効にします。

```yaml
workflow:
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event" && $CI_MERGE_REQUEST_TITLE =~ /^(\[Draft\]|\(Draft\)|Draft:)/
      when: never

stages:
  - build

build-job:
  stage: build
  script:
    - echo "Testing"
```

<!--- start_remove The following content will be removed on remove_date: '2025-05-15' -->

## `workflow:rules`テンプレート（非推奨）

{{< alert type="warning" >}}

GitLab 17.0で、`workflow:rules`テンプレートは[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/456394)となり、18.0で削除される予定です。これは重大な変更です。パイプラインで`workflow:rules`を設定するには、キーワードを明示的に追加します。オプションについては、上記の例を参照してください。

{{< /alert >}}

GitLabは、一般的なシナリオ用に`workflow: rules`を設定するテンプレートを提供しています。これらのテンプレートを使用すると、重複するパイプラインを防ぐことができます。

[`Branch-Pipelines` ンプレート](https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/gitlab/ci/templates/Workflows/Branch-Pipelines.gitlab-ci.yml)を使用すると、ブランチとタグに対してパイプラインが実行されます。

ブランチパイプラインの状態は、ブランチをソースとして使用するマージリクエストに表示されます。ただし、このパイプラインタイプは、[マージ結果パイプライン](../pipelines/merged_results_pipelines.md)、[マージトレイン](../pipelines/merge_trains.md)などの[マージリクエストパイプライン](../pipelines/merge_request_pipelines.md)が提供する機能はサポートしていません。このテンプレートでは、意図的にこれらの機能を回避しています。

機能を[含める](_index.md#include)には:

```yaml
include:
  - template: 'Workflows/Branch-Pipelines.gitlab-ci.yml'
```

[`MergeRequest-Pipelines`テンプレート](https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/gitlab/ci/templates/Workflows/MergeRequest-Pipelines.gitlab-ci.yml)を使用すると、デフォルトブランチ、タグ、すべてのタイプマージリクエストパイプラインに対してパイプラインが実行されます。いずれかの[マージリクエストパイプライン機能](../pipelines/merge_request_pipelines.md)を使用する場合は、このテンプレートを使用します。

機能を[含める](_index.md#include)には:

```yaml
include:
  - template: 'Workflows/MergeRequest-Pipelines.gitlab-ci.yml'
```

<!--- end_remove -->

## トラブルシューティング

### `Checking pipeline status.`メッセージが表示されてマージリクエストがスタックする

マージリクエストに`Checking pipeline status.`と表示されており、このメッセージが消えない場合（「スピナー」が回転し続ける場合）は、`workflow:rules`が原因である可能性があります。このイシューは、プロジェクトで[**パイプラインが完了している**](../../user/project/merge_requests/auto_merge.md#require-a-successful-pipeline-for-merge)が有効になっているとはいえ、`workflow:rules`がマージリクエストのパイプラインの実行を防いでいる場合に発生する可能性があります。

たとえば、以下のワークフローでは、パイプラインを実行できないため、マージリクエストをマージできません。

```yaml
workflow:
  rules:
    - changes:
        - .gitlab/**/**.md
      when: never
```
