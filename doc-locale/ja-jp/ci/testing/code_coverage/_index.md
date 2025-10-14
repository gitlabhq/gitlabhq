---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: コードカバレッジ
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

テストでカバーされているソースコードの量を追跡および可視化するように、コードカバレッジを設定します。以下を実行できます。

- `coverage`キーワードを使用して、全体的なカバレッジのメトリクスと傾向を追跡する。
- `artifacts:reports:coverage_report`キーワードを使用して、行ごとのカバレッジを可視化する。

## カバレッジレポートを設定する {#configure-coverage-reporting}

[`coverage`](../../yaml/_index.md#coverage)キーワードを使用して、テストカバレッジを監視し、マージリクエストでカバレッジ要件を適用します。

カバレッジレポートでは、次のことが可能です。

- マージリクエストで全体的なカバレッジ率を表示する。
- 複数のテストジョブからカバレッジを集約する。
- カバレッジチェックの承認ルールを追加する。
- 経時的なカバレッジの傾向を追跡する。

カバレッジレポートを設定するには:

1. `coverage`キーワードをパイプライン設定に追加します。

   ```yaml
   test-unit:
     script:
       - coverage run unit/
     coverage: '/TOTAL.+ ([0-9]{1,3}%)/'

   test-integration:
     script:
       - coverage run integration/
     coverage: '/TOTAL.+ ([0-9]{1,3}%)/'
   ```

1. テスト出力形式に一致するように正規表現（regex）を設定します。一般的なパターンについては、[カバレッジの正規表現パターン](#coverage-regex-patterns)を参照してください。
1. 複数のジョブからカバレッジを集約するには、含める各ジョブに`coverage`キーワードを追加します。
1. オプション: [カバレッジチェックの承認ルールを追加](#add-a-coverage-check-approval-rule)します。

### カバレッジの正規表現パターン {#coverage-regex-patterns}

次のサンプル正規表現パターンは、一般的なテストカバレッジツールからのカバレッジ出力を解析するように設計されています。

正規表現パターンを注意深くテストしてください。ツールの出力形式は時間とともに変化する可能性があり、これらのパターンは期待どおりに動作しなくなる可能性があります。

<!-- vale gitlab_base.Spelling = NO -->
<!-- markdownlint-disable MD056 -->
<!--
Verify regex patterns carefully, especially patterns containing the pipe (`|`) character.
To use `|` in the text of a table cell (not as cell delimiters), you must escape it with a backslash (`\|`).
Verify all tables render as expected both in GitLab and on docs.gitlab.com.
See: https://docs.gitlab.com/user/markdown/#tables
-->

{{< tabs >}}

{{< tab title="PythonとRuby" >}}

| ツール       | 言語 | コマンド        | 正規表現パターン |
|------------|----------|----------------|---------------|
| pytest-cov | Python   | `pytest --cov` | `/TOTAL.*? (100(?:\.0+)?\%\|[1-9]?\d(?:\.\d+)?\%)$/` |
| Simplecov  | Ruby     | `rspec spec`   | `/(?:LOC\s\(\d+\.\d+%\|Line Coverage:\s\d+\.\d+%)/` |

{{< /tab >}}

{{< tab title="C/C++とRust" >}}

| ツール      | 言語 | コマンド           | 正規表現パターン |
|-----------|----------|-------------------|---------------|
| gcovr     | C/C++    | `gcovr`           | `/^TOTAL.*\s+(\d+\%)$/` |
| tarpaulin | Rust     | `cargo tarpaulin` | `/^\d+.\d+% coverage/` |

{{< /tab >}}

{{< tab title="JavaとJVM" >}}

| ツール      | 言語    | コマンド                            | 正規表現パターン |
|-----------|-------------|------------------------------------|---------------|
| JaCoCo    | Java/Kotlin | `./gradlew test jacocoTestReport`  | `/Total.*?([0-9]{1,3})%/` |
| Scoverage | Scala       | `sbt coverage test coverageReport` | `/(?i)total.*? (100(?:\.0+)?\%\|[1-9]?\d(?:\.\d+)?\%)$/` |

{{< /tab >}}

{{< tab title="Node.js" >}}

| ツール | コマンド                              | 正規表現パターン |
|------|--------------------------------------|---------------|
| tap  | `tap --coverage-report=text-summary` | `/^Statements\s*:\s*([^%]+)/` |
| nyc  | `nyc npm test`                       | `/All files[^\|]*\|[^\|]*\s+([\d\.]+)/` |
| jest | `jest --ci --coverage`               | `/All files[^\|]*\|[^\|]*\s+([\d\.]+)/` |

{{< /tab >}}

{{< tab title="PHP" >}}

| ツール    | コマンド                                  | 正規表現パターン |
|---------|------------------------------------------|---------------|
| pest    | `pest --coverage --colors=never`         | `/Statement coverage[A-Za-z\.*]\s*:\s*([^%]+)/` |
| phpunit | `phpunit --coverage-text --colors=never` | `/^\s*Lines:\s*\d+.\d+\%/` |

{{< /tab >}}

{{< tab title="Go" >}}

| ツール              | コマンド          | 正規表現パターン |
|-------------------|------------------|---------------|
| go test（シングル）  | `go test -cover` | `/coverage: \d+.\d+% of statements/` |
| go test（プロジェクト） | `go test -coverprofile=cover.profile && go tool cover -func cover.profile` | `/total:\s+\(statements\)\s+\d+.\d+%/` |

{{< /tab >}}

{{< tab title=".NETとPowerShell" >}}

| ツール      | 言語   | コマンド | 正規表現パターン |
|-----------|------------|---------|---------------|
| OpenCover | .NET       | なし    | `/(Visited Points).*\((.*)\)/` |
| dotnet test（[MSBuild](https://github.com/coverlet-coverage/coverlet/blob/master/Documentation/MSBuildIntegration.md)） | .NET | `dotnet test` | `/Total\s*\\|*\s(\d+(?:\.\d+)?)/` |
| Pester    | PowerShell | なし    | `/Covered (\d{1,3}(\.|,)?\d{0,2}%)/` |

{{< /tab >}}

{{< tab title="Elixir" >}}

| ツール        | コマンド            | 正規表現パターン |
|-------------|--------------------|---------------|
| excoveralls | なし               | `/\[TOTAL\]\s+(\d+\.\d+)%/` |
| mix         | `mix test --cover` | `/\d+.\d+\%\s+\|\s+Total/` |

{{< /tab >}}

{{< /tabs >}}

<!-- vale gitlab_base.Spelling = YES -->
<!-- markdownlint-enable MD056 -->

## カバレッジの可視化 {#coverage-visualization}

[`artifacts:reports:coverage_report`](../../yaml/artifacts_reports.md#artifactsreportscoverage_report)キーワードを使用して、マージリクエスト内のテストでカバーされる特定のコード行を表示します。

次の形式でカバレッジレポートを生成できます。

- Cobertura: Java、JavaScript、Python、Rubyなどの複数の言語に対応。
- JaCoCo: Javaプロジェクトにのみ対応。

カバレッジの可視化では、[アーティファクトレポート](../../yaml/_index.md#artifactsreports)を使用して次のことを行います。

1. ワイルドカードパスなど、1つ以上のカバレッジレポートを収集する。
1. すべてのレポートからカバレッジ情報を結合する。
1. 結合された結果をマージリクエストの差分に表示する。

カバレッジファイルはバックグラウンドジョブで解析されるため、パイプラインの完了からマージリクエストに可視化が表示されるまでに遅延が発生する可能性があります。

デフォルトでは、カバレッジの可視化データは作成から1週間で期限切れになります。

### カバレッジの可視化を設定する {#configure-coverage-visualization}

カバレッジの可視化を設定するには:

1. カバレッジレポートを生成するようにテストツールを設定します。
1. `artifacts:reports:coverage_report`設定をパイプラインに追加します。

   ```yaml
   test:
     script:
       - run tests with coverage
     artifacts:
       reports:
         coverage_report:
           coverage_format: cobertura  # or jacoco
           path: coverage/coverage.xml
   ```

言語固有の設定の詳細については、以下を参照してください。

- [Coberturaカバレッジレポート](cobertura.md)
- [JaCoCoカバレッジレポート](jacoco.md)

### 子パイプラインからのカバレッジレポート {#coverage-reports-from-child-pipelines}

子パイプラインからのカバレッジレポートは、マージリクエストの差分注釈には表示されますが、マージリクエストウィジェットには表示されません。これは、親パイプラインが子パイプラインによって生成されたカバレッジレポートアーティファクトにアクセスできないことが原因です。

子パイプラインからのカバレッジレポートをマージリクエストウィジェットに表示するサポートは、[エピック8205](https://gitlab.com/groups/gitlab-org/-/epics/8205)で提案されています。

## カバレッジチェックの承認ルールを追加する {#add-a-coverage-check-approval-rule}

{{< details >}}

- プラン: Premium、Ultimate

{{< /details >}}

プロジェクトのテストカバレッジを低下させるマージリクエストについて、特定のユーザーまたはグループによる承認を要求するように設定できます。

前提要件:

- [カバレッジレポートを設定](#configure-coverage-reporting)していること。

`Coverage-Check`承認ルールを追加するには:

1. プロジェクトに移動し、**設定 > マージリクエスト**を選択します。
1. **マージリクエスト承認**で、次のいずれかを実行します。
   - `Coverage-Check`承認ルールの横にある**有効化**を選択します。
   - 手動セットアップの場合は、**承認ルールを追加**を選択し、**ルール名**に`Coverage-Check`と入力します。
1. **ターゲットブランチ**を選択します。
1. **必要な承認数**を設定します。
1. 承認を行う**ユーザー**または**グループ**を選択します。
1. **変更を保存**を選択します。

{{< alert type="note" >}}

`Coverage-Check`承認ルールは、マージリクエストによって全体のカバレッジが向上したとしても、マージベースのパイプラインにカバレッジデータが含まれていない場合、承認を必須とします。

{{< /alert >}}

## カバレッジ結果を表示する {#view-coverage-results}

パイプラインが正常に実行された後、次の場所でコードカバレッジの結果を確認できます。

- マージリクエストウィジェット: ターゲットブランチと比較して、カバレッジ率とその変化を確認します。

  ![コードカバレッジ率を示すマージリクエストウィジェット](img/pipelines_test_coverage_mr_widget_v17_3.png)

- マージリクエストの差分: どの行がテストでカバーされているかを確認します。CoberturaレポートおよびJaCoCoレポートで使用できます。
- パイプラインジョブ: 個々のジョブのカバレッジ結果を監視します。

## カバレッジ履歴を表示する {#view-coverage-history}

プロジェクトまたはグループのコードカバレッジの推移を経時的に追跡できます。

### プロジェクトの場合 {#for-a-project}

プロジェクトのコードカバレッジ履歴を表示するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **分析 > リポジトリ分析**を選択します。
1. ドロップダウンリストから、履歴データを表示するジョブを選択します。
1. オプション: データのCSVファイルを表示するには、**元のデータをダウンロード（.csv）**を選択します。

### グループの場合 {#for-a-group}

{{< details >}}

- プラン: Premium、Ultimate

{{< /details >}}

グループ内のすべてのプロジェクトのコードカバレッジ履歴を表示するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **分析 > リポジトリ分析**を選択します。
1. オプション: データのCSVファイルを表示するには、**過去のテストカバレッジデータをCSV形式でダウンロード**を選択します。

## カバレッジバッジを表示する {#display-coverage-badges}

パイプラインバッジを使用して、プロジェクトのコードカバレッジのステータスを共有します。

プロジェクトにカバレッジバッジを追加するには、[テストカバレッジレポートバッジ](../../../user/project/badges.md#test-coverage-report-badges)を参照してください。

## トラブルシューティング {#troubleshooting}

### コードカバレッジからカラーコードを削除する {#remove-color-codes-from-code-coverage}

一部のテストカバレッジツールでは、正規表現で正しく解析されないANSIカラーコードが出力に含まれています。これにより、カバレッジの解析が失敗します。

一部のカバレッジツールには、出力のカラーコードを無効にするオプションがありません。その場合は、カラーコードを削除する1行のスクリプトに、カバレッジツールの出力をパイプします。

例:

```shell
lein cloverage | perl -pe 's/\e\[?.*?[\@-~]//g'
```
