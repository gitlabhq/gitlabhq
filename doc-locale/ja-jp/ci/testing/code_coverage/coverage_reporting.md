---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: テストカバレッジのパーセンテージをマージリクエスト、分析、バッジに表示します。
title: カバレッジレポート
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

[`coverage`](../../yaml/_index.md#coverage)キーワードを使用して、テストジョブのジョブログ出力からカバレッジ率を抽出し、マージリクエストと分析に表示します。

このキーワードは、カバレッジ率のみを表示します。MR差分に1行ごとのアノテーションは生成されません。行アノテーションを表示するには、[`artifacts:reports:coverage_report`](../../yaml/artifacts_reports.md#artifactsreportscoverage_report)を別途設定してください。

## カバレッジレポートを設定する {#configure-coverage-reporting}

カバレッジレポートを設定するには:

1. テストツールの出力に一致する正規表現で、ジョブに`coverage`キーワードを追加します:

   ```yaml
   test:
     script:
       - pytest --cov
     coverage: '/TOTAL.*? (100(?:\.0+)?\%|[1-9]?\d(?:\.\d+)?\%)$/'
   ```

1. 複数のジョブからカバレッジを集約するには、各ジョブに`coverage`キーワードを追加します。

### カバレッジの正規表現パターン {#coverage-regex-patterns}

次の正規表現パターンは、一般的なテストカバレッジツールの出力に一致します。ツールの出力形式は時間の経過とともに変更される可能性があるため、これらを慎重にテストしてください。

{{< tabs >}}

{{< tab title="PythonとRuby" >}}

| ツール           | 言語 | コマンド        | 正規表現パターン |
| -------------- | -------- | -------------- | ------------- |
| pytest-cov     | Python   | `pytest --cov` | `/TOTAL.*? (100(?:\.0+)?\%\|[1-9]?\d(?:\.\d+)?\%)$/` |
| Simplecov-html | Ruby     | `rspec spec`   | `/Line\sCoverage:\s\d+\.\d+%/` |

{{< /tab >}}

{{< tab title="C/C++とRust" >}}

| ツール      | 言語 | コマンド           | 正規表現パターン |
| --------- | -------- | ----------------- | ------------- |
| gcovr     | C/C++    | `gcovr`           | `/^TOTAL.*\s+(\d+\%)$/` |
| tarpaulin | Rust     | `cargo tarpaulin` | `/^\d+.\d+% coverage/` |

{{< /tab >}}

{{< tab title="JavaとJVM" >}}

| ツール      | 言語    | コマンド                            | 正規表現パターン |
| --------- | ----------- | ---------------------------------- | ------------- |
| JaCoCo    | Java/Kotlin | `./gradlew test jacocoTestReport`  | `/Total.*?([0-9]{1,3})%/` |
| Scoverage | Scala       | `sbt coverage test coverageReport` | `/(?i)total.*? (100(?:\.0+)?\%\|[1-9]?\d(?:\.\d+)?\%)$/` |

{{< /tab >}}

{{< tab title="Node.js" >}}

| ツール      | コマンド                                    | 正規表現パターン |
| --------- | ------------------------------------------ | ------------- |
| tap       | `tap --coverage-report=text-summary`       | `/^Statements\s*:\s*([^%]+)/` |
| nyc       | `nyc npm test`                             | `/All files[^\|]*\|[^\|]*\s+([\d\.]+)/` |
| jest      | `jest --ci --coverage`                     | `/All files[^\|]*\|[^\|]*\s+([\d\.]+)/` |
| node:test | `node --experimental-test-coverage --test` | `/all files[^\|]*\|[^\|]*\s+([\d\.]+)/` |

{{< /tab >}}

{{< tab title="PHP" >}}

| ツール    | コマンド                                  | 正規表現パターン |
| ------- | ---------------------------------------- | ------------- |
| pest    | `pest --coverage --colors=never`         | `/Statement coverage[A-Za-z\.*]\s*:\s*([^%]+)/` |
| phpunit | `phpunit --coverage-text --colors=never` | `/^\s*Lines:\s*\d+.\d+\%/` |

{{< /tab >}}

{{< tab title="Go" >}}

| ツール              | コマンド                                                                    | 正規表現パターン |
| ----------------- | -------------------------------------------------------------------------- | ------------- |
| go test（シングル）  | `go test -cover`                                                           | `/coverage: \d+.\d+% of statements/` |
| go test（プロジェクト） | `go test -coverprofile=cover.profile && go tool cover -func cover.profile` | `/total:\s+\(statements\)\s+\d+.\d+%/` |

{{< /tab >}}

{{< tab title=".NETとPowerShell" >}}

| ツール        | 言語   | コマンド       | 正規表現パターン |
| ----------- | ---------- | ------------- | ------------- |
| OpenCover   | .NET       | なし          | `/(Visited Points).*\((.*)\)/` |
| dotnet test | .NET       | `dotnet test` | `/Total\s*\|*\s(\d+(?:\.\d+)?)/` |
| Pester      | PowerShell | なし          | `/Covered (\d{1,3}(\.\|,)?\d{0,2}%)/` |

{{< /tab >}}

{{< tab title="Elixir" >}}

| ツール        | コマンド            | 正規表現パターン |
| ----------- | ------------------ | ------------- |
| excoveralls | なし               | `/\[TOTAL\]\s+(\d+\.\d+)%/` |
| mix         | `mix test --cover` | `/\d+.\d+\%\s+\|\s+Total/` |

{{< /tab >}}

{{< /tabs >}}

## カバレッジチェックの承認ルールを追加する {#add-a-coverage-check-approval-rule}

{{< details >}}

- プラン: Premium、Ultimate

{{< /details >}}

プロジェクトのテストカバレッジを低下させるマージリクエストについて、特定のユーザーまたはグループによる承認を要求するように設定できます。

前提条件: 

- カバレッジレポートを設定します。

`Coverage-Check`承認ルールを追加するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 左サイドバーで、**設定** > **マージリクエスト**を選択します。
1. **マージリクエスト承認**で、次のいずれかを実行します。
   - `Coverage-Check`承認ルールの横にある**有効化**を選択します。
   - 手動セットアップの場合は、**承認ルールを追加**を選択し、**ルール名**に`Coverage-Check`と入力します。
1. **ターゲットブランチ**を選択します。
1. **必要な承認数**を設定します。
1. 承認を行う**ユーザー**または**グループ**を選択します。
1. **変更を保存**を選択します。

> [!note]
> ベースパイプラインにカバレッジデータが含まれていない場合、マージリクエストが全体的なカバレッジを改善しても、`Coverage-Check`承認ルールは承認を必要とします。

## カバレッジ履歴を表示する {#view-coverage-history}

時間の経過とともにプロジェクトまたはグループのカバレッジの傾向を追跡することができます。

### プロジェクトの場合 {#for-a-project}

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 左サイドバーで、**分析** > **リポジトリ分析**を選択します。
1. ドロップダウンリストから、履歴データを表示するジョブを選択します。
1. オプション。データをダウンロードするには、**元のデータをダウンロード (.csv)**を選択します。

### グループの場合 {#for-a-group}

{{< details >}}

- プラン: Premium、Ultimate

{{< /details >}}

1. 上部のバーで、**検索または移動先**を選択して、グループを見つけます。
1. 左サイドバーで、**分析** > **リポジトリ分析**を選択します。
1. オプション。データをダウンロードするには、**過去のテストカバレッジデータをCSV形式でダウンロード**を選択します。

## カバレッジバッジを表示する {#display-coverage-badges}

プロジェクトにカバレッジバッジを追加するには、[テストカバレッジレポートバッジ](../../../user/project/badges.md#test-coverage-report-badges)を参照してください。

## トラブルシューティング {#troubleshooting}

カバレッジレポートの使用時に、次の問題が発生する可能性があります。

### MRウィジェットにカバレッジ率が表示されない {#coverage-percentage-does-not-appear-in-the-mr-widget}

`coverage`キーワードは、ジョブのジョブログ出力から正規表現を使用してパーセンテージを抽出します。パーセンテージが表示されない場合:

- 正規表現がツールの実際の出力と一致することを確認します。ジョブログから1行をコピーし、正規表現に対してテストします。
- 一部のツールは、正規表現の一致を妨げるANSIカラー出力を生成します。ツールのカラー出力の無効化をサポートしていない場合は、解析中の前にコードを削除します:

  ```shell
  lein cloverage | perl -pe 's/\e\[?.*?[\@-~]//g'
  ```

- ジョブが正常に完了したことを確認します。カバレッジは、成功したジョブからのみ抽出されます。
- 子パイプラインからのカバレッジ出力は記録されません。詳細については、[イシュー280818](https://gitlab.com/gitlab-org/gitlab/-/issues/280818)を参照してください。

> [!note]
> `coverage`キーワードは、MRウィジェットにパーセンテージのみを表示します。差分の1行ごとのアノテーションについては、[`artifacts:reports:coverage_report`](../../yaml/artifacts_reports.md#artifactsreportscoverage_report)を別途設定してください。
