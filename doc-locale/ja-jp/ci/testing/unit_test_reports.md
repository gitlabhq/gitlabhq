---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 単体テストレポート
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

単体テストレポートは、マージリクエストとパイプラインの詳細でテスト結果を直接表示するため、ジョブログを検索しなくても失敗を特定できます。

次のような場合は、単体テストレポートを使用します。

- マージリクエストでテストの失敗をすぐに確認する。
- ブランチ間でテスト結果を比較する。
- エラーの詳細とスクリーンショットを使用して、失敗したテストをデバッグする。
- 経時的なテスト失敗パターンを追跡する。

単体テストレポートにはJUnit XML形式が必要です。ただし、このレポートはジョブステータスには影響しません。テストが失敗したときにジョブを失敗させるには、ジョブの[スクリプト](../yaml/_index.md#script)を0以外のステータスで終了させる必要があります。

GitLab Runnerは、JUnit XML形式のテスト結果を[アーティファクト](../yaml/artifacts_reports.md#artifactsreportsjunit)としてアップロードします。マージリクエストに移動すると、テスト結果はソースブランチ（head）とターゲットブランチ（base）の間で比較され、変更点が表示されます。

## ファイル形式とサイズ制限 {#file-format-and-size-limits}

単体テストレポートでは、適切な解析と表示を確実に行うために、特定の要件を満たすJUnit XML形式を使用する必要があります。

### ファイル要件 {#file-requirements}

テストレポートファイルは、次の条件を満たす必要があります。

- JUnit XML形式を使用し、ファイル拡張子は`.xml`にする。
- 各ファイルのサイズは30 MB未満とする。
- 1つのジョブ内のすべてのJUnitファイルの合計サイズは100 MB未満とする。

テスト名が重複している場合は、最初のテストのみが使用され、同じ名前の他のテストは無視されます。

テストケースの制限については、[単体テストレポートごとの最大テストケース](../../user/gitlab_com/_index.md#cicd)を参照してください。

### JUnit XML形式の仕様 {#junit-xml-format-specification}

GitLabは、JUnit XMLファイルから次の要素と属性を解析します。

| XML要素  | XML属性   | 説明 |
| ------------ | --------------- | ----------- |
| `testsuite`  | `name`          | テストスイート名（解析されるがUIには表示されない） |
| `testcase`   | `classname`     | テストクラス名またはカテゴリ名（スイート名として使用される） |
| `testcase`   | `name`          | 個々のテスト名 |
| `testcase`   | `file`          | テストが定義されているファイルパス |
| `testcase`   | `time`          | テストの実行時間（秒） |
| `failure`    | 要素の内容 | 失敗メッセージとスタックトレース |
| `error`      | 要素の内容 | エラーメッセージとスタックトレース |
| `skipped`    | 要素の内容 | テストをスキップした理由 |
| `system-out` | 要素の内容 | システムの出力と添付ファイルタグ（`testcase`要素からのみ解析される） |
| `system-err` | 要素の内容 | システムエラー出力（`testcase`要素からのみ解析される） |

{{< alert type="note" >}}

スイート名として使用されるのは`testsuite name`属性ではなく、`testcase classname`属性です。

{{< /alert >}}

#### XML構造の例 {#xml-structure-example}

```xml
<testsuites>
  <testsuite name="Authentication Tests" tests="1" failures="1">
    <testcase classname="LoginTest" name="test_invalid_password" file="spec/auth_spec.rb" time="0.23">
      <failure>Expected authentication to fail</failure>
      <system-out>[[ATTACHMENT|screenshots/failure.png]]</system-out>
    </testcase>
  </testsuite>
</testsuites>
```

このXMLはGitLabでは次のように表示されます。

- スイート: `LoginTest`（`testcase classname`より）
- 名前: `test_invalid_password`（`testcase name`より）
- ファイル: `spec/auth_spec.rb`（`testcase file`より）
- 時間: `0.23s`（`testcase time`より）
- スクリーンショット: テストの詳細ダイアログで利用可能（`testcase system-out`より）
- 非表示: 「Authentication Tests」（`testsuite name`より）

## テスト結果タイプ {#test-result-types}

テスト結果は、マージリクエストのソースブランチとターゲットブランチの間で比較され、変更点が表示されます。

- 新たに失敗したテスト: ターゲットブランチでは成功したが、自分のブランチでは失敗したテスト。
- 新たに発生したエラー: ターゲットブランチでは成功したが、自分のブランチではエラーが発生したテスト。
- 既存の失敗: 両方のブランチで失敗したテスト。
- 解決済みの失敗: ターゲットブランチでは失敗したが、自分のブランチでは成功したテスト。

ブランチを比較できない場合（たとえば、ターゲットブランチのデータがまだない場合）は、自分のブランチで失敗したテストのみが表示されます。

過去14日間にデフォルトブランチで失敗したテストについては、次のようなメッセージが表示されます: `Failed {n} time(s) in {default_branch} in the last 14 days`。このカウントには、完了したパイプラインで失敗したテストが含まれますが、[ブロックされたパイプライン](../jobs/job_control.md#types-of-manual-jobs)で失敗したテストは含まれません。ブロックされたパイプラインのサポートは、[イシュー431265](https://gitlab.com/gitlab-org/gitlab/-/issues/431265)で提案されています。

## 単体テストレポートを設定する {#configure-unit-test-reports}

単体テストレポートを設定すると、マージリクエストとパイプラインにテスト結果を表示できます。

単体テストレポートを設定するには、次の手順に従います。

1. JUnit XML形式のテストレポートを出力するようにテストジョブを設定します。設定の詳細については、テストフレームワークのドキュメントを確認してください。
1. `.gitlab-ci.yml`ファイルで、テストジョブに[`artifacts:reports:junit`](../yaml/artifacts_reports.md#artifactsreportsjunit)を追加します。
1. XMLテストレポートファイルのパスを指定します。
1. オプション: レポートファイルを参照できるようにするには、[`artifacts:paths`](../yaml/_index.md#artifactspaths)にそれらのファイルを指定します。
1. オプション: ジョブが失敗した場合でもレポートをアップロードするには、[`artifacts:when:always`](../yaml/_index.md#artifactswhen)を使用します。

RubyとRSpecの設定例:

```yaml
ruby:
  stage: test
  script:
    - bundle install
    - bundle exec rspec --format progress --format RspecJunitFormatter --out rspec.xml
  artifacts:
    when: always
    paths:
      - rspec.xml
    reports:
      junit: rspec.xml
```

次の場所でテスト結果を確認できます。

- テストジョブの完了後、パイプラインの詳細の**テスト**タブ。
- パイプラインの完了後、マージリクエストの**テストのサマリー**パネル。

## マージリクエストでテスト結果を表示する {#view-test-results-in-merge-requests}

マージリクエストでテスト失敗に関する詳細情報を表示します。

**テストのサマリー**パネルには、失敗したテストと成功したテストの数など、テスト結果の概要が表示されます。

![1件の失敗したテストと詳細を表示リンクを示す、展開済みのテストのサマリーパネル](img/test_summary_panel_expanded_v18_1.png)

テスト失敗の詳細を表示するには、次の手順に従います。

1. マージリクエストで、**テストのサマリー**パネルに移動します。
1. **テストのサマリー**パネルを展開するには、**詳細を表示**（{{< icon name="chevron-lg-down" >}}）を選択します。
1. 失敗したテストの横にある**詳細を表示**を選択します。

ダイアログには、テスト名、ファイルパス、実行時間、添付されたスクリーンショット（設定されている場合）、エラー出力が表示されます。

すべてのテスト結果を表示するには、次の手順に従います。

- **テストのサマリー**パネルから、**完全なレポート**を選択して、パイプライン詳細の**テスト**タブに移動します。

### 失敗したテスト名をコピーする {#copy-failed-test-names}

テスト名をコピーして、ローカルで再実行しデバッグします。

前提要件:

- JUnitレポートに、失敗したテストの`<file>`属性が含まれている必要があります。

すべての失敗したテスト名をコピーするには、次の手順に従います。

- **テストのサマリー**パネルから、**失敗したテストをコピー**（{{< icon name="copy-to-clipboard" >}}）を選択します。

失敗したテストは、スペースで区切られた文字列としてコピーされます。

失敗したテスト名を1つコピーするには、次の手順に従います。

1. **テストのサマリー**パネルを展開するには、**詳細を表示**（{{< icon name="chevron-lg-down" >}}）を選択します。
1. コピーするテストの横にある**詳細を表示**を選択します。
1. ダイアログで、**ローカルで再実行するためにテスト名をコピー**（{{< icon name="copy-to-clipboard" >}}）を選択します。

テスト名がクリップボードにコピーされます。

## パイプラインでテスト結果を表示する {#view-test-results-in-pipelines}

パイプラインの詳細ですべてのテストスイートとテストケースを表示します。

パイプラインのテスト結果を表示するには、次の手順に従います。

1. パイプラインの詳細ページに移動します。
1. **テスト**タブを選択します。
1. 任意のテストスイートを選択すると、個々のテストケースを確認できます。

![テスト数1671件、合計実行時間1分11秒、およびジョブごとの実行時間を示すテスト結果](img/pipelines_junit_test_report_v18_3.png)

[Pipelines API](../../api/pipelines.md#get-a-test-report-for-a-pipeline)を使用してテストレポートを取得することもできます。

### テストタイミングメトリクス {#test-timing-metrics}

テスト結果には、次のようなさまざまなタイミングメトリクスが表示されます。

パイプラインの所要時間: パイプラインが開始してから完了するまでの経過時間。

テスト実行時間: すべてのジョブにおけるすべてのテストの合計実行時間。

キュー時間: ジョブが利用可能なRunnerを待機していた時間。

ジョブが並列実行される場合、累積テスト実行時間がパイプラインの所要時間を超えることがあります。

パイプラインの所要時間は結果が得られるまでの時間を示し、テスト実行時間は使用されたコンピューティングリソースを示します。

たとえば、多数のテストジョブが複数のRunnerで並列実行された場合、81分で完了するパイプラインでも、テスト実行時間が9時間10分と表示されることがあります。

## テストレポートにスクリーンショットを追加する {#add-screenshots-to-test-reports}

テスト失敗のデバッグを支援するために、テストレポートにスクリーンショットを追加します。

テストレポートにスクリーンショットを追加するには、次の手順に従います。

1. JUnit XMLファイルで、`$CI_PROJECT_DIR`を基準としたスクリーンショットの相対パスを指定し、添付ファイルタグを追加します。

   ```xml
   <testcase time="1.00" name="Test">
     <system-out>[[ATTACHMENT|/path/to/some/file]]</system-out>
   </testcase>
   ```

1. `.gitlab-ci.yml`ファイルで、スクリーンショットをアーティファクトとしてアップロードするようにジョブを設定します。

   - スクリーンショットファイルのパスを指定します。
   - オプション: テストが失敗した場合にスクリーンショットをアップロードするには、[`artifacts:when: always`](../yaml/_index.md#artifactswhen)を使用します。

   例:

   ```yaml
   ruby:
     stage: test
     script:
       - bundle install
       - bundle exec rspec --format progress --format RspecJunitFormatter --out rspec.xml
       - # Your test framework should save screenshots to a directory
     artifacts:
       when: always
       paths:
         - rspec.xml
         - screenshots/
       reports:
         junit: rspec.xml
   ```

1. パイプラインを実行します。

**テストのサマリー**パネルで失敗したテストの**詳細を表示**を選択すると、テストの詳細ダイアログでスクリーンショットリンクにアクセスできます。

![テストの詳細とスクリーンショットの添付ファイルを含む、失敗した単体テストレポート](img/unit_test_report_screenshot_v18_1.png)

## トラブルシューティング {#troubleshooting}

### テストレポートが空で表示される {#test-report-appears-empty}

マージリクエストで、**テストのサマリー**パネルが空の状態で表示される場合があります。

この問題は、次の場合に発生します。

- レポートアーティファクトが期限切れになっている。
- JUnitファイルがサイズ制限を超えている。

この問題を解決するには、レポートアーティファクトの[`expire_in`](../yaml/_index.md#artifactsexpire_in)値をより長く設定するか、新しいパイプラインを実行して新しいレポートを生成します。

JUnitファイルがサイズ制限を超えている場合、次の内容を確認します。

- 個々のJUnitファイルが30 MB未満である。
- ジョブのすべてのJUnitファイルの合計サイズが100 MB未満である。

カスタム制限のサポートは、[エピック16374](https://gitlab.com/groups/gitlab-org/-/epics/16374)で提案されています。

### テスト結果が欠落している {#test-results-are-missing}

レポートで、予想よりも少ないテスト結果が表示される場合があります。

これは、JUnit XMLファイルに重複するテスト名がある場合に発生する可能性があります。それぞれの名前では最初のテストのみが使用され、重複は無視されます。

この問題を解決するには、すべてのテスト名とクラスが一意であることを確認してください。

### マージリクエストにテストレポートが表示されない {#no-test-reports-appear-in-merge-requests}

マージリクエストで**テストのサマリー**パネルがまったく表示されない場合があります。

この問題は、ターゲットブランチに比較対象のテストデータがない場合に発生する可能性があります。

この問題を解決するには、ターゲットブランチでパイプラインを実行して、ベースラインテストデータを生成します。

### JUnit XMLの解析エラー {#junit-xml-parsing-errors}

パイプライン内のジョブ名の横に解析エラーインジケーターが表示される場合があります。

これは、JUnit XMLファイルに形式エラーまたは無効な要素が含まれている場合に発生する可能性があります。

この問題を解決するには、次のようにします。

- JUnit XMLファイルが標準形式に従っていることを確認する。
- すべてのXML要素が適切に閉じられていることを確認する。
- 属性名と値が正しい形式で記述されていることを確認する。

[グループ化されたジョブ](../jobs/_index.md#group-similar-jobs-together-in-pipeline-views)では、そのグループの最初の解析エラーのみが表示されます。
