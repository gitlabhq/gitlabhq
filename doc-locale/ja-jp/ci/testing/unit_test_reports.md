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

[CI/CD パイプライン](../pipelines/_index.md)を設定して、単体テストの結果をマージリクエストとパイプラインの詳細に直接表示できます。これにより、ジョブログを検索しなくても、テストの失敗を簡単に特定できます。

単体テストレポート:

- JUnitレポート形式が必要です。
- ジョブステータスには影響しません。単体テストが失敗した場合にジョブを失敗にするには、ジョブの[スクリプト](../yaml/_index.md#script)を0以外のステータスで終了する必要があります。

次のワークフローを検討してください。

1. デフォルトブランチは非常に安定しています。プロジェクトはGitLab CI/CDを使用しており、パイプラインに何も問題がないことが示されています。
1. チームの誰かがマージリクエストを送信すると、テストが失敗し、パイプラインにおなじみの赤いアイコンが表示されます。さらに調査するには、ジョブログを調べて失敗したテストの原因を突き止める必要があります。通常、ジョブログには何千行もの行が含まれています。
1. 単体テストレポートを設定すると、GitLabはすぐにそれらを収集してマージリクエストで公開します。ジョブログ内を検索する必要はありません。
1. 開発とデバッグのワークフローがより簡単、高速かつ効率的になります。

## 仕組み

まず、GitLab Runnerはすべての[JUnitレポート形式のXMLファイル](https://www.ibm.com/docs/en/developer-for-zos/16.0?topic=formats-junit-xml-format)を[アーティファクト](../yaml/artifacts_reports.md#artifactsreportsjunit)としてGitLabにアップロードします。次に、マージリクエストにアクセスすると、GitLabはheadブランチとbaseブランチのJUnitレポート形式のXMLファイルの比較を開始します。ここで、次のようになります。

- ベースブランチはターゲットブランチです（通常はデフォルトブランチ）。
- ヘッドブランチはソースブランチです（各マージリクエストの最新のパイプライン）。

**テストのサマリー**パネルには、失敗したテストの数、エラーが発生したテストの数、修正されたテストの数が表示されます。ベースブランチのデータが利用できないために比較を実行できない場合、パネルにはソースブランチの失敗したテストのリストのみが表示されます。

結果の種類は次のとおりです。

- **新たに失敗したテスト:** ベースブランチでは合格したが、ヘッドブランチでは失敗したテストケース
- **新しく発生したエラー:** ベースブランチでは合格したが、ヘッドブランチではテストエラーが原因で失敗したテストケース
- **既存の失敗:** ベースブランチで失敗し、ヘッドブランチでも失敗したテストケース
- **解決済みの失敗:** ベースブランチでは失敗したが、ヘッドブランチでは合格したテストケース

### 失敗したテストを表示する

**テストのサマリー**パネルの各エントリには、テスト名と結果の種類が表示されます。テスト名を選択すると、実行時間とエラー出力の詳細を示すモーダルウィンドウが開きます。

![テストレポートウィジェット](img/junit_test_report_v13_9.png)

#### 失敗したテスト名をコピーする

{{< history >}}

- GitLab 15.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/91552)されました。

{{< /history >}}

**テストのサマリー**パネルに失敗したテストがリストされている場合は、失敗したテストの名前とパスをコピーできます。名前とパスを使用して、検証のためにローカルでテストを検索して再実行します。

すべての失敗したテストの名前をコピーするには、**テストのサマリー**パネルの上部にある**失敗したテストをコピー**を選択します。失敗したテストは、テストがスペースで区切られた文字列としてリストされます。このオプションは、JUnitレポートが失敗したテストの`<file>`属性に値を入力する場合にのみ使用できます。

単一の失敗したテストの名前をコピーするには:

1. **テストのサマリーの詳細を表示**（{{< icon name="chevron-lg-down" >}}）を選択して、**テストのサマリー**パネルを展開します。
1. レビューするテストを選択します。
1. **ローカルで再実行するためにテスト名をコピー**（{{< icon name="copy-to-clipboard" >}}）を選択します。

### 最近の失敗回数

プロジェクトのデフォルトブランチで過去14日間にテストが失敗した場合、`Failed {n} time(s) in {default_branch} in the last 14 days`のようなメッセージがそのテストに対して表示されます。

計算には、完了したパイプラインで失敗したテストが含まれますが、[ブロックされたパイプライン](../jobs/job_control.md#types-of-manual-jobs)で失敗したテストは含まれません。[イシュー431265](https://gitlab.com/gitlab-org/gitlab/-/issues/431265)では、ブロックされたパイプラインも計算に追加することが提案されています。

## 設定方法

マージリクエストで単体テストレポートを有効にするには、`.gitlab-ci.yml`に[`artifacts:reports:junit`](../yaml/artifacts_reports.md#artifactsreportsjunit)を追加し、生成されたテストレポートのパスを指定する必要があります。レポートは`.xml`ファイルである必要があります。そうでない場合、[GitLabはエラー500を返します](https://gitlab.com/gitlab-org/gitlab/-/issues/216575)。

Rubyの次の例では、`test`ステージのジョブが実行され、GitLabはジョブから単体テストレポートを収集します。ジョブが実行されると、XMLレポートはアーティファクトとしてGitLabに保存され、結果はマージリクエストウィジェットに表示されます。

```yaml
## Use https://github.com/sj26/rspec_junit_formatter to generate a JUnit report format XML file with rspec
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

単体テストレポートの出力ファイルを参照できるようにするには、例に示すように、[`artifacts:paths`](../yaml/_index.md#artifactspaths)キーワードも使用します。ジョブが失敗した場合（テストに合格しなかった場合など）もレポートをアップロードするには、[`artifacts:when:always`](../yaml/_index.md#artifactswhen)キーワードを使用します。

JUnitレポート形式のXMLファイルに、同じ名前とクラスを持つ複数のテストを含めることはできません。

GitLab 15.0以前では、[parallel:matrix](../yaml/_index.md#parallelmatrix)ジョブのテストレポートが集約されるため、一部のレポート情報が表示されない場合があります。GitLab 15.1以降では、[このバグは修正](https://gitlab.com/gitlab-org/gitlab/-/issues/296814)され、すべてのレポート情報が表示されます。

## GitLabで単体テストレポートを表示する

JUnitレポート形式のXMLファイルがパイプラインの一部として生成およびアップロードされる場合、これらのレポートはパイプラインの詳細ページ内で確認できます。このページの**テスト**タブには、XMLファイルから報告されたテストスイートとテストケースのリストが表示されます。

![テストレポートウィジェット](img/pipelines_junit_test_report_v13_10.png)

既知のすべてのテストスイートを表示し、各スイートを選択して、スイートを構成するケースなどの詳細を確認できます。

[GitLab API](../../api/pipelines.md#get-a-pipelines-test-report)経由でレポートを取得することもできます。

### 単体テストレポートの解析エラー

JUnitレポートXMLの解析でエラーが発生した場合、ジョブ名の横にインジケーターが表示されます。アイコンにカーソルをおくと、ツールチップにパーサーエラーが表示されます。複数の解析エラーが[グループ化されたジョブ](../jobs/_index.md#group-similar-jobs-together-in-pipeline-views)から発生している場合、GitLabはグループからの最初のエラーのみを表示します。

![エラーを含むテストレポート](img/pipelines_junit_test_report_with_errors_v13_10.png)

テストケースの解析制限については、[単体テストレポートごとの最大テストケース数](../../user/gitlab_com/_index.md#cicd)を参照してください。

GitLabはJUnitレポートの非常に[大きなノード](https://nokogiri.org/tutorials/parsing_an_html_xml_document.html#parse-options)を解析しません。これをオプションにするための[イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/268035)がオープンされています。

## GitLabでJUnitスクリーンショットを表示する

スクリーンショットを[アーティファクト](../yaml/artifacts_reports.md#artifactsreportsjunit)としてGitLabにアップロードできます。JUnitレポート形式のXMLファイルに`attachment`タグが含まれている場合、GitLabは添付ファイルを解析します。スクリーンショットアーティファクトをアップロードする場合:

- `attachment`タグには、`$CI_PROJECT_DIR`を基準にしてアップロードしたスクリーンショットのパスを含める**必要があります**。次に例を示します。

  ```xml
  <testcase time="1.00" name="Test">
    <system-out>[[ATTACHMENT|/path/to/some/file]]</system-out>
  </testcase>
  ```

- テストが失敗した場合でもスクリーンショットがアップロードされるように、スクリーンショットをアップロードするジョブを[`artifacts:when: always`](../yaml/_index.md#artifactswhen)に設定する必要があります。

添付ファイルがアップロードされると、[パイプラインテストレポート](#view-unit-test-reports-on-gitlab)にスクリーンショットへのリンクが含まれます。次に例を示します。

![テストの詳細とスクリーンショットの添付ファイルを含む失敗した単体テストレポート](img/unit_test_report_screenshot_v13_12.png)

## トラブルシューティング

### テストレポートが空で表示される

マージリクエストで単体テストレポートを表示すると、次の理由により空で表示されることがあります。

1. レポートを含むアーティファクトの有効期限が切れている: この問題を解決するには、次のいずれかの操作を実行します。
   - レポートアーティファクトに、より長い[`expire_in`](../yaml/_index.md#artifactsexpire_in)値を設定する。
   - 新しいパイプラインを実行して、新しいレポートを生成する。

1. JUnitファイルがサイズ制限を超えている: この問題を解決するには、次の操作を実行します。
   - 個々のJUnitファイルが30 MB未満であることを確認する。
   - ジョブのJUnitサイズの合計が100 MB未満であることを確認しする。

   カスタム制限のサポートは、[エピック16374](https://gitlab.com/groups/gitlab-org/-/epics/16374)で提案されています。
