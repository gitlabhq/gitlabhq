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

テストでカバーされているソースコードの量を追跡および可視化するようにコードカバレッジを設定します。以下を実行できます。

- `coverage`キーワードを使用して、全体的なカバレッジのメトリクスと傾向を追跡します。
- `artifacts:reports:coverage_report`キーワードを使用して、行ごとのカバレッジを可視化します。

## カバレッジレポートを設定する

[`coverage`](../../yaml/_index.md#coverage)キーワードを使用して、テストカバレッジを監視し、マージリクエストでカバレッジ要件を適用します。

カバレッジレポートでは、次のことが可能です。

- マージリクエストで全体的なカバレッジの割合を表示します。
- 複数のテストジョブからカバレッジを集約します。
- カバレッジチェックの承認ルールを追加します。
- 経時的なカバレッジの傾向を追跡します。

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

1. テスト出力形式に一致するように正規表現（regex）を設定します。一般的なパターンについては、「[カバレッジの正規表現パターン](#coverage-regex-patterns)」を参照してください。
1. 複数のジョブからカバレッジを集約するには、含める各ジョブに`coverage`キーワードを追加します。
1. オプション: [カバレッジチェックの承認ルールを追加](#add-a-coverage-check-approval-rule)します。

### カバレッジの正規表現パターン

次のサンプル正規表現パターンは、一般的なテストカバレッジツールからのカバレッジ出力を解析するように設計されています。

正規表現パターンを注意深くテストしてください。ツールの出力形式は時間とともに変化する可能性があり、これらのパターンは期待どおりに動作しなくなる可能性があります。

<!-- vale gitlab_base.Spelling = NO -->
<!-- markdownlint-disable MD056 -->
<!-- Verify regex patterns on docs.gitlab.com as escape characters render differently than in `.md` files rendered via GitLab code browser -->

{{< tabs >}}

{{< tab title="PythonとRuby" >}}

| ツール       | 言語 | コマンド        | 正規表現パターン |
|------------|----------|----------------|---------------|
| pytest-cov | Python   | `pytest --cov` | `/TOTAL.*? (100(?:\.0+)?\%\|[1-9]?\d(?:\.\d+)?\%)$/` |
| Simplecov  | Ruby     | `rspec spec`   | `/\(\d+.\d+\%\) covered/` |

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
| Pester    | PowerShell | なし    | `/Covered (\d+\.\d+%)/` |

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

## カバレッジの可視化

[`artifacts:reports:coverage_report`](../../yaml/artifacts_reports.md#artifactsreportscoverage_report)キーワードを使用して、マージリクエスト内のテストでカバーされる特定のコード行を表示します。

次の形式でカバレッジレポートを生成できます。

- Cobertura: Java、JavaScript、Python、Rubyなどの複数の言語に対応
- JaCoCo: Javaプロジェクトにのみ対応

カバレッジの可視化では、[アーティファクトレポート](../../yaml/_index.md#artifactsreports)を使用して次のことを行います。

1. ワイルドカードパスなど、1つ以上のカバレッジレポートを収集します。
1. すべてのレポートからのカバレッジ情報を結合します。
1. 結合された結果をマージリクエストの差分に表示します。

カバレッジファイルはバックグラウンドジョブで解析されるため、パイプラインの完了から可視化がマージリクエストに表示されるまでに遅延が発生する可能性があります。

デフォルトでは、カバレッジの可視化データは作成から1週間で期限切れになります。

### カバレッジの可視化を設定する

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

### 子パイプラインからのカバレッジレポート

{{< history >}}

- GitLab 15.1で、`ci_child_pipeline_coverage_reports`という名前の[フラグとともに](../../../administration/feature_flags.md)[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/363301)されました。デフォルトでは無効になっています。
- GitLab 15.2の[GitLab.comとGitLab Self-Managedで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/363557)になり、機能フラグ`ci_child_pipeline_coverage_reports`が削除されました。

{{< /history >}}

子パイプラインで生成されたカバレッジレポートは、親パイプラインのカバレッジレポートに含まれます。次に例を示します。

```yaml
child_test_pipeline:
  trigger:
    include:
      - local: path/to/child_pipeline_with_coverage.yml
```

## カバレッジチェックの承認ルールを追加する

{{< details >}}

- プラン: Premium、Ultimate

{{< /details >}}

プロジェクトのテストカバレッジを低下させるマージリクエストを承認するように、特定のユーザーまたはグループに要求できます。

前提要件:

- [カバレッジレポートを設定](#configure-coverage-reporting)していること。

`Coverage-Check`承認ルールを追加するには:

1. プロジェクトに移動し、**設定>マージリクエスト**を選択します。
1. **マージリクエストの承認**で、次のいずれかを実行します。
   - `Coverage-Check`承認ルールの横にある**有効化**を選択します。
   - 手動セットアップの場合は、**承認ルールを追加**を選択し、**ルール名**を入力します。例: `Coverage Check`。
1. **ターゲットブランチ**を選択します。
1. **必要な承認数**を設定します。
1. 承認を提供する**ユーザー**または**グループ**を選択します。
1. **変更の保存**を選択します。

## カバレッジ結果を表示する

パイプラインが正常に実行された後、次の場所にコードカバレッジの結果を表示できます。

- マージリクエストウィジェット: ターゲットブランチと比較して、カバレッジの割合と変更を確認します。

  ![コードカバレッジの割合を示すマージリクエストウィジェット](../img/pipelines_test_coverage_mr_widget_v17_3.png)

- マージリクエストの差分: どの行がテストでカバーされているかを確認します。CoberturaレポートおよびJaCoCoレポートで使用できます。
- パイプラインジョブ: 個々のジョブのカバレッジ結果を監視します。

## カバレッジ履歴を表示する

プロジェクトまたはグループのコードカバレッジの進化を経時的に追跡できます。

### プロジェクトの場合

プロジェクトのコードカバレッジ履歴を表示するには:

1. 左側のサイドバーで、**検索または移動**を選択し、プロジェクトを検索します。
1. **分析>リポジトリ分析**を選択します。
1. ドロップダウンリストから、履歴データを表示するジョブを選択します。
1. オプション: データのCSVファイルを表示するには、**元のデータをダウンロード（.csv）**を選択します。

### グループの場合

{{< details >}}

- プラン: Premium、Ultimate

{{< /details >}}

グループ内のすべてのプロジェクトのコードカバレッジ履歴を表示するには:

1. 左側のサイドバーで、**検索または移動**を選択し、グループを検索します。
1. **分析>リポジトリ分析**を選択します。
1. オプション: データのCSVファイルを表示するには、**過去のテストカバレッジデータをCSV形式でダウンロード**を選択します。

## カバレッジバッジを表示する

パイプラインバッジを使用して、プロジェクトのコードカバレッジの状態を共有します。

プロジェクトにカバレッジバッジを追加するには、「[テストカバレッジレポートバッジ](../../../user/project/badges.md#test-coverage-report-badges)」を参照してください。

## トラブルシューティング

### コードカバレッジからカラーコードを削除する

一部のテストカバレッジツールは、正規表現で正しく解析されないANSIカラーコードで出力します。これにより、カバレッジの解析が失敗します。

一部のカバレッジツールには、出力のカラーコードを無効にするオプションがありません。その場合は、カラーコードを削除する1行のスクリプトによってカバレッジツールの出力をパイプします。

次に例を示します。

```shell
lein cloverage | perl -pe 's/\e\[?.*?[\@-~]//g'
```
