---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab CI/CDの`workflow`キーワード
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

`.gitlab-ci.yml`ファイルで[`workflow`](_index.md#workflow)キーワードを使用して、パイプラインがいつ作成されるかを制御します。

`workflow`キーワードは、ジョブの前に評価されます。たとえば、ジョブがタグに対して実行するように設定されていても、ワークフローでタグパイプラインを禁止している場合、ジョブは実行されません。

## `workflow:rules`の一般的な`if`句 {#common-if-clauses-for-workflowrules}

`workflow: rules`の`if`句の例:

| ルールの例                                        | 詳細 |
|------------------------------------------------------|---------|
| `if: '$CI_PIPELINE_SOURCE == "merge_request_event"'` | マージリクエストパイプラインを実行するタイミングを制御します。 |
| `if: '$CI_PIPELINE_SOURCE == "push"'`                | ブランチパイプラインとタグパイプラインの両方を実行するタイミングを制御します。 |
| `if: $CI_COMMIT_TAG`                                 | タグパイプラインを実行するタイミングを制御します。 |
| `if: $CI_COMMIT_BRANCH`                              | ブランチパイプラインを実行するタイミングを制御します。 |

詳細については、[`rules`の一般的な`if`句](../jobs/job_rules.md#common-if-clauses-with-predefined-variables)を参照してください。

## `workflow: rules`の例 {#workflow-rules-examples}

次の例では、以下が実行されます:

- すべての`push`イベント（ブランチへの変更と新しいタグ）に対してパイプラインが実行されます。
- コミットメッセージが`-draft`で終わるプッシュイベントのパイプラインは、`when: never`に設定されているため実行されません。
- スケジュールまたはマージリクエストのパイプラインも、trueと評価されるルールが存在しないため実行されません。

```yaml
workflow:
  rules:
    - if: $CI_COMMIT_MESSAGE =~ /-draft$/
      when: never
    - if: $CI_PIPELINE_SOURCE == "push"
```

この例ではルールが厳密に定義されており、条件に該当しない場合はパイプラインは**not**（実行されません）。

別の方法として、すべてのルールを`when: never`にして、最後に`when: always`ルールを指定することもできます。`when: never`ルールに一致するパイプラインは実行されません。それ以外のすべてのパイプラインタイプは実行されます。次に例を示します:

```yaml
workflow:
  rules:
    - if: $CI_PIPELINE_SOURCE == "schedule"
      when: never
    - if: $CI_PIPELINE_SOURCE == "push"
      when: never
    - when: always
```

この例では、スケジュールや`push`（ブランチとタグ）に対するパイプラインは実行されません。最後の`when: always`ルールは、マージリクエストパイプライン**including**（を含む）その他すべてのパイプラインタイプを実行します。

### ブランチパイプラインとマージリクエストパイプラインを切り替える {#switch-between-branch-pipelines-and-merge-request-pipelines}

マージリクエストの作成後に、パイプラインをブランチパイプラインからマージリクエストパイプラインに切り替えるには、`.gitlab-ci.yml`ファイルに`workflow: rules`セクションを追加します。

両方のパイプラインタイプを同時に使用すると、[重複するパイプライン](../jobs/job_rules.md#avoid-duplicate-pipelines)が同時に実行される可能性があります。パイプラインの重複を防ぐには、[`CI_OPEN_MERGE_REQUESTS`変数](../variables/predefined_variables.md)を使用します。

ブランチパイプラインとマージリクエストパイプラインのみを実行し、それ以外の場合にはパイプラインを実行しないプロジェクトの例を次に示します。この例は、次のように動作します:

- ブランチに対してマージリクエストがオープンされていない場合は、ブランチパイプラインを実行する。
- ブランチに対してマージリクエストがオープンされている場合は、マージリクエストパイプラインを実行する。

```yaml
workflow:
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
    - if: $CI_COMMIT_BRANCH && $CI_OPEN_MERGE_REQUESTS
      when: never
    - if: $CI_COMMIT_BRANCH
```

GitLabがトリガーしようとするパイプラインタイプに応じて、次のように動作します:

- マージリクエストパイプラインの場合、パイプラインを開始します。たとえば、マージリクエストパイプラインは、関連するマージリクエストがオープンされているブランチへのプッシュによってトリガーされることがあります。
- ブランチパイプラインの場合、そのブランチに対してマージリクエストがオープンされていれば、ブランチパイプラインは実行されません。たとえば、ブランチパイプラインは、ブランチへの変更、APIコール、スケジュール済みパイプラインなどによってトリガーされることがあります。
- ブランチパイプラインの場合、そのブランチに対してマージリクエストがオープンされていなければ、ブランチパイプラインが実行されます。

既存の`workflow`セクションにルールを追加して、マージリクエストが作成されたときにブランチパイプラインからマージリクエストパイプラインに切り替えることもできます。

このルールを`workflow`セクションの先頭に追加し、その後に既存の他のルールを続けます:

```yaml
workflow:
  rules:
    - if: $CI_COMMIT_BRANCH && $CI_OPEN_MERGE_REQUESTS && $CI_PIPELINE_SOURCE == "push"
      when: never
    - # Previously defined workflow rules here
```

ブランチで実行される[トリガーされたパイプライン](../triggers/_index.md)には`$CI_COMMIT_BRANCH`が設定されており、同様のルールによってブロックされる可能性があります。トリガーされたパイプラインのソースは`trigger`または`pipeline`であるため、`&& $CI_PIPELINE_SOURCE == "push"`を条件に追加することで、トリガーされたパイプラインがこのルールによってブロックされるのを防ぐことができます。

### マージリクエストパイプラインを使用したGit Flow {#git-flow-with-merge-request-pipelines}

`workflow: rules`は、マージリクエストパイプラインで使用できます。これらのルールを使用すると、フィーチャーブランチで[マージリクエストパイプラインの機能](../pipelines/merge_request_pipelines.md)を活用しながら、長期的なブランチを維持してソフトウェアの複数のバージョンをサポートできます。

たとえば、マージリクエスト、タグ、保護ブランチに対してのみパイプラインを実行するには、次のようにします:

```yaml
workflow:
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
    - if: $CI_COMMIT_TAG
    - if: $CI_COMMIT_REF_PROTECTED == "true"
```

この例では、長期的なブランチが[保護されている](../../user/project/repository/branches/protected.md)ことを前提としています。

### ドラフトマージリクエストのパイプラインをスキップする {#skip-pipelines-for-draft-merge-requests}

`workflow: rules`を使用して、ドラフトマージリクエストのパイプラインをスキップできます。これらのルールを使用すると、開発が完了するまでコンピューティング時間の消費を回避できます。

たとえば、次のルールは、タイトルに`[Draft]`、`(Draft)`、または`Draft:`が含まれるマージリクエストのCIビルドを無効にします:

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

## トラブルシューティング {#troubleshooting}

### `Checking pipeline status.`メッセージが表示されてマージリクエストがスタックする {#merge-request-stuck-with-checking-pipeline-status-message}

マージリクエストに`Checking pipeline status.`と表示され、このメッセージが消えない（「スピナー」が回転し続ける）場合、`workflow:rules`が原因である可能性があります。この問題は、プロジェクトで[**パイプラインが完了している**](../../user/project/merge_requests/auto_merge.md#require-a-successful-pipeline-for-merge)条件が有効になっているにもかかわらず、`workflow:rules`によってマージリクエストのパイプラインの実行が妨げられている場合に発生することがあります。

たとえば、次のワークフローではパイプラインを実行できないため、マージリクエストをマージできません:

```yaml
workflow:
  rules:
    - changes:
        - .gitlab/**/**.md
      when: never
```
