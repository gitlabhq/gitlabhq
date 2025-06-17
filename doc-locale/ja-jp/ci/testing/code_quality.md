---
stage: Application Security Testing
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Code Quality
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

Code Qualityは、技術的負債になる前に保守性の問題を特定します。コードレビュー中に発生する自動フィードバックにより、チームはより良いコードを作成することができます。発見された問題はマージリクエストに直接表示されるため、最もコスト効率よく修正できるタイミングで問題を特定できます。

Code Qualityは複数のプログラミング言語に対応しており、一般的なLinter、スタイルチェッカー、複雑性アナライザーと統合することができます。既存のツールをコード品質ワークフローに組み込むことで、結果の表示方法を標準化しながら、チームの設定を維持できます。

## 各プランの機能

次の表に示すように、利用できる機能は[GitLabのプラン](https://about.gitlab.com/pricing/)によって異なります。

| 機能                                                                                     | Free                | Premium             | Ultimate            |
|:--------------------------------------------------------------------------------------------|:-----------------------|:-----------------------|:-----------------------|
| [CI/CDジョブからCode Qualityの結果をインポートする](#import-code-quality-results-from-a-cicd-job) | {{< icon name="check-circle" >}}はい | {{< icon name="check-circle" >}}はい | {{< icon name="check-circle" >}}はい |
| [CodeClimateベースのスキャンを使用する](#use-the-built-in-code-quality-cicd-template-deprecated)   | {{< icon name="check-circle" >}}はい | {{< icon name="check-circle" >}}はい | {{< icon name="check-circle" >}}はい |
| [マージリクエストウィジェットで発見を確認する](#merge-request-widget)                             | {{< icon name="check-circle" >}}はい | {{< icon name="check-circle" >}}はい | {{< icon name="check-circle" >}}はい |
| [パイプラインレポートで発見を確認する](#pipeline-details-view)                                 | {{< icon name="dotted-circle" >}}いいえ | {{< icon name="check-circle" >}}はい | {{< icon name="check-circle" >}}はい |
| [マージリクエストの変更ビューで発見を確認する](#merge-request-changes-view)               | {{< icon name="dotted-circle" >}}いいえ | {{< icon name="dotted-circle" >}}いいえ | {{< icon name="check-circle" >}}はい |
| [プロジェクトの品質概要ビューで全体的な健全性を分析する](#project-quality-view)           | {{< icon name="dotted-circle" >}}いいえ | {{< icon name="dotted-circle" >}}いいえ | {{< icon name="check-circle" >}}はい |

## 品質違反のコードをスキャンする

Code Qualityは、多くのスキャンツールからの結果のインポートをサポートするオープンシステムです。違反を見つけて表面化するには、以下の手順を実行します。

- スキャンツールを直接使用して、[結果をインポート](#import-code-quality-results-from-a-cicd-job)します。_（推奨）_
- [組み込みのCI/CDテンプレートを使用](#use-the-built-in-code-quality-cicd-template-deprecated)してスキャンを有効にします。このテンプレートでは、一般的なオープンソースツールをラップするCodeClimateエンジンを使用します。_（非推奨）_

1つのパイプラインで、複数のツールから結果をキャプチャすることができます。たとえば、コードLinterを実行してコードをスキャンしたり、言語Linterを実行してドキュメントをスキャンしたり、スタンドアロンツールをCodeClimateベースのスキャンで使用したりできます。Code Qualityはすべてのレポートを組み合わせるため、[結果を表示する](#view-code-quality-results)際にすべてのレポートを表示できます。

### CI/CDジョブからCode Qualityの結果をインポートする

多くの開発チームでは、すでにCI/CDパイプラインでLinter、スタイルチェッカー、その他のツールを使用して、コーディング標準の違反を自動的に検出しています。これらのツールをCode Qualityと統合することで、その発見を簡単に確認して修正することができます。

お使いのツールにドキュメント化された統合があるかどうかを確認するには、「[一般的なツールとCode Qualityのインテグレーション](#integrate-common-tools-with-code-quality)」を参照してください。

別のツールをCode Qualityと統合するには、以下を実行します。

1. CI/CDパイプラインにツールを追加します。
1. レポートをファイルとして出力するようにツールを設定します。
   - このファイルには、[特定のJSON形式](#code-quality-report-format)を使用する必要があります。
   - 多くのツールは、この出力形式をネイティブにサポートしています。「CodeClimateレポート」、「GitLab Code Qualityレポート」、またはそれに似た別の名前で呼ばれることもあります。
   - 他のツールでは、カスタムJSON形式またはテンプレートを使用してJSON出力を生成できることがあります。[レポート形式](#code-quality-report-format)の必須フィールドは少ないため、この出力タイプを使用してCode Qualityのレポートを作成できる場合があります。
1. このファイルと一致する[`codequality`レポートのアーティファクト](../yaml/artifacts_reports.md#artifactsreportscodequality)を宣言します。

パイプラインを実行すると、品質ツールの結果が[処理および表示](#view-code-quality-results)されます。

### 組み込みのCode Quality CI/CDテンプレートを使用する（非推奨）

{{< alert type="warning" >}}

この機能は、GitLab 17.3で[非推奨](../../update/deprecations.md#codeclimate-based-code-quality-scanning-will-be-removed)となり、18.0で削除される予定です。代わりに、[サポートされているツールからの結果を直接統合します](#import-code-quality-results-from-a-cicd-job)。

{{< /alert >}}

Code Qualityには、組み込みのCI/CDテンプレート`Code-Quality.gitlab-ci.yaml`も含まれています。このテンプレートは、オープンソースのCodeClimateスキャンエンジンに基づいてスキャンを実行します。

CodeClimateエンジンは以下を実行します。

- [サポートされている言語セット](https://docs.codeclimate.com/docs/supported-languages-for-maintainability)の基本的な保守性チェック。
- オープンソーススキャナーをラップしてソースコードを分析する、設定可能な[プラグイン](https://docs.codeclimate.com/docs/list-of-engines)のセット。

詳細については、「[CodeClimateベースのコード品質スキャンを設定する](code_quality_codeclimate_scanning.md)」を参照してください。

#### CodeClimateベースのスキャンから移行する

CodeClimateエンジンでは、カスタマイズ可能な[分析プラグイン](code_quality_codeclimate_scanning.md#configure-codeclimate-analysis-plugins)のセットを使用します。デフォルトで有効になっているものもありますが、明示的に有効にする必要があるものもあります。組み込みのプラグインを置き換えるため、次のインテグレーションを利用できます。

| プラグイン       | デフォルトで有効                                | 代替手段                                                                                                                                                                          |
|--------------|----------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 複製  | {{< icon name="check-circle" >}}はい                       | [PMD Copy/Paste Detectorを統合](#pmd-copypaste-detector)します。                                                                                                                        |
| ESLint       | {{< icon name="check-circle" >}}はい                       | [ESLintを統合](#eslint)します。                                                                                                                                                         |
| gofmt        | {{< icon name="dotted-circle" >}}いいえ                       | [golangci-lintを統合](#golangci-lint)し、[gofmt Linter](https://golangci-lint.run/usage/linters#gofmt)を有効にします。                                                              |
| golint       | {{< icon name="dotted-circle" >}}いいえ                       | [golangci-lintを統合](#golangci-lint)し、golintを置き換える付属のLinterのいずれかを有効にします。golintは[非推奨となり凍結](https://github.com/golang/go/issues/38968)されました。 |
| govet        | {{< icon name="dotted-circle" >}}いいえ                       | [golangci-lintを統合します](#golangci-lint)。golangci-lint[には、デフォルトでgovetが含まれます](https://golangci-lint.run/usage/linters#enabled-by-default)。                                    |
| markdownlint | {{< icon name="dotted-circle" >}}いいえ（コミュニティサポート型） | [markdownlint-cli2を統合](#markdownlint-cli2)します。                                                                                                                                   |
| pep8         | {{< icon name="dotted-circle" >}}いいえ                       | [Flake8](#flake8)、[Pylint](#pylint)、[Ruff](#ruff)のような代替のPython Linterを統合します。                                                                                  |
| RuboCop      | {{< icon name="dotted-circle" >}}はい                      | [RuboCopを統合](#rubocop)します。                                                                               |
| SonarPython  | {{< icon name="dotted-circle" >}}いいえ                       | [Flake8](#flake8)、[Pylint](#pylint)、[Ruff](#ruff)のような代替のPython Linterを統合します。                                                                                  |
| Stylelint    | {{< icon name="dotted-circle" >}}いいえ（コミュニティサポート型） | [Stylelintを統合します](#stylelint)。                                                                                                                                                   |
| SwiftLint    | {{< icon name="dotted-circle" >}}いいえ                       | [SwiftLintを統合します](#swiftlint)。                                                                                                                                                   |

## Code Qualityの結果を表示する

Code Qualityの結果は以下に表示されます。

- [マージリクエスト](#merge-request-widget)
- [マージリクエストの変更ビュー](#merge-request-changes-view)
- [パイプラインの詳細ビュー](#pipeline-details-view)
- [プロジェクトの品質ビュー](#project-quality-view)

### マージリクエスト

ターゲットブランチからのレポートを使用して比較できる場合、Code Qualityの分析結果がマージリクエストのウィジェットに表示されます。マージリクエストのウィジェットには、マージリクエストで行われた変更によって得たCode Qualityの発見と解決策が表示されます。同一のフィンガープリントを持つ複数のCode Qualityの発見は、マージリクエストのウィジェットに単一のエントリとして表示されます。個々の発見は、**パイプライン**の詳細ビューで利用できる完全なレポートで確認できます。

![重大度の高い順にマージリクエストの問題を表示します](img/code_quality_widget_v13_11.png)

### マージリクエストの変更ビュー

{{< details >}}

- プラン: Ultimate
- 提供: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

Code Qualityの結果は、マージリクエストの**変更**ビューに表示されます。Code Qualityの問題を含む行は、ガターの横に記号でマークされます。記号を選択して問題のリストを表示し、問題を選択して詳細を表示します。

![記号の色と形は、その行の問題の重大度を示します](img/code_quality_inline_indicator_v16_7.png)

### パイプラインの詳細ビュー

{{< details >}}

- プラン: Premium、Ultimate
- 提供: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

パイプラインによって生成されたCode Qualityの違反の完全なリストは、パイプラインの詳細ページの**コード品質**タブに表示されます。パイプラインの詳細ビューには、パイプラインが実行されたブランチで見つかったすべてのCode Qualityの発見が表示されます。

![ブランチ内のすべての問題を重大度の高い順に表示します](img/code_quality_report_v13_11.png)

### プロジェクトの品質ビュー

{{< details >}}

- プラン: Ultimate
- 提供: GitLab.com、GitLab Self-Managed
- ステータス:ベータ

{{< /details >}}

{{< history >}}

- GitLab 14.5で`project_quality_summary_page`という[フラグ](../../administration/feature_flags.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/72724)されました。この機能は[ベータ版](../../policy/development_stages_support.md)です。デフォルトでは無効になっています。

{{< /history >}}

プロジェクトの品質ビューに、Code Qualityの発見概要が表示されます。このビューは**分析 > CI/CD分析**で確認できますが、特定のプロジェクトに対して[`project_quality_summary_page`](../../user/feature_flags.md)機能フラグを有効にする必要があります。

![違反と呼ばれる問題の総数と、その後に重大度ごとの問題の数が表示されます。](img/code_quality_summary_v15_9.png)

## Code Qualityのレポート形式

次の形式でレポートを出力できる任意のツールから、[Code Qualityの結果をインポート](#import-code-quality-results-from-a-cicd-job)できます。この形式は、より少ないフィールドを含む[CodeClimateレポート形式](https://github.com/codeclimate/platform/blob/master/spec/analyzers/SPEC.md#data-types)のバージョンです。

[Code Qualityレポートアーティファクト](../yaml/artifacts_reports.md#artifactsreportscodequality)として提供するファイルには、単一のJSON配列が含まれている必要があります。その配列内の各オブジェクトには、少なくとも次のプロパティが必要です。

| 名前                                                      | 説明                                                                                                              | タイプ                                                                         |
|-----------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------|
| `description`                                             | 人間が読めるコード品質違反についての説明。                                                              | 文字列                                                                       |
| `check_name`                                              | この違反に関連するチェックやルールを表す一意の名前。                                           | 文字列                                                                       |
| `fingerprint`                                             | 特定のコード品質違反を識別するための一意のフィンガープリント（そのコンテンツのハッシュなど）。                   | 文字列                                                                       |
| `severity`                                                | 違反の重大度。                                                                                           | 文字列。有効な値は、`info`、`minor`、`major`、`critical`、`blocker`です。 |
| `location.path`                                           | リポジトリ内の相対パスとして表される、コード品質違反を含むファイル。`./`をプレフィックスにしないでください。 | 文字列                                                                       |
| `location.lines.begin`または`location.positions.begin.line` | コード品質違反が発生した行。                                                                   | 整数                                                                      |

この形式は、次の点で[CodeClimateレポート形式](https://github.com/codeclimate/platform/blob/master/spec/analyzers/SPEC.md#data-types)と異なります。

- [CodeClimateレポート形式](https://github.com/codeclimate/platform/blob/master/spec/analyzers/SPEC.md#data-types)は、より多くのプロパティをサポートしていますが、Code Qualityは上記のフィールドのみを処理します。
- GitLabパーサーでは、ファイルの先頭に[バイトオーダーマーク（BOM）](https://en.wikipedia.org/wiki/Byte_order_mark)を使用できません。

たとえば、以下は準拠レポートです。

```json
[
  {
    "description": "'unused' is assigned a value but never used.",
    "check_name": "no-unused-vars",
    "fingerprint": "7815696ecbf1c96e6894b779456d330e",
    "severity": "minor",
    "location": {
      "path": "lib/index.js",
      "lines": {
        "begin": 42
      }
    }
  }
]
```

## 一般的なツールをCode Qualityと統合する

多くのツールは、結果をCode Qualityと統合するために必要な[レポート形式](#code-quality-report-format)をネイティブにサポートしています。「CodeClimateレポート」、「GitLab Code Qualityレポート」、またはそれに似た別の名前で呼ばれることもあります。

他のツールは、カスタムテンプレートまたは形式の仕様を提供することで、JSON出力を生成するように設定できます。[レポート形式](#code-quality-report-format)の必須フィールドは少ないため、この出力タイプを使用してCode Qualityのレポートを作成できる場合があります。

CI/CDパイプラインですでにツールを使用している場合は、既存のジョブを適合させてCode Qualityレポートを追加する必要があります。既存のジョブを適合させることで、開発者を混乱させ、パイプラインの実行時間を長くする可能性のある別のジョブの実行を防ぐことができます。

ツールをまだ使用していない場合は、CI/CDジョブを最初から作成するか、[CI/CDカタログ](../components/_index.md#cicd-catalog)のコンポーネントを使用してツールを導入できます。

### コードスキャンツール

#### ESLint

CI/CDパイプラインにすでに[ESLint](https://eslint.org/)ジョブがある場合は、レポートを追加してその出力をCode Qualityに送信する必要があります。出力を統合するには、以下を実行します。

1. [`eslint-formatter-gitlab`](https://www.npmjs.com/package/eslint-formatter-gitlab)を、開発時依存関係としてプロジェクトに追加します。
1. ESLintの実行に使用するコマンドに、`--format gitlab`オプションを追加します。
1. レポートファイルの場所を指す[`codequality`レポートアーティファクト](../yaml/artifacts_reports.md#artifactsreportscodequality)を宣言します。
   - デフォルトでは、フォーマッターはCI/CDの設定を読み取り、レポートを保存するファイル名を推測します。フォーマッターがアーティファクトの宣言で使用したファイル名を推測できない場合は、アーティファクトに指定された`gl-code-quality-report.json`などのファイル名にCI/CD変数`ESLINT_CODE_QUALITY_REPORT`を設定します。

[ESLint CI/CDコンポーネント](https://gitlab.com/explore/catalog/components/code-quality-oss/codequality-os-scanners-integration)を使用または調整してスキャンを実行し、その出力をCode Qualityと統合することもできます。

#### Stylelint

CI/CDパイプラインにすでに[Stylelint](https://stylelint.io/)ジョブがある場合は、レポートを追加してその出力をCode Qualityに送信する必要があります。出力を統合するには、以下を実行します。

1. [`@studiometa/stylelint-formatter-gitlab`](https://www.npmjs.com/package/@studiometa/stylelint-formatter-gitlab)を、開発時依存関係としてプロジェクトに追加します。
1. Stylelintの実行に使用するコマンドに`--custom-formatter=@studiometa/stylelint-formatter-gitlab`オプションを追加します。
1. レポートファイルの場所を指す[`codequality`レポートアーティファクト](../yaml/artifacts_reports.md#artifactsreportscodequality)を宣言します。
   - デフォルトでは、フォーマッターはCI/CDの設定を読み取り、レポートを保存するファイル名を推測します。フォーマッターがアーティファクトの宣言で使用したファイル名を推測できない場合は、アーティファクトに指定された`gl-code-quality-report.json`などのファイル名にCI/CD変数`STYLELINT_CODE_QUALITY_REPORT`を設定します。

詳細およびCI/CDジョブ定義の例については、[`@studiometa/stylelint-formatter-gitlab`のドキュメント](https://www.npmjs.com/package/@studiometa/stylelint-formatter-gitlab#usage)を参照してください。

#### MyPy

CI/CDパイプラインにすでに[MyPy](https://mypy-lang.org/)ジョブがある場合は、その出力をCode Qualityに送信するためのレポートを追加する必要があります。出力を統合するには、以下を実行します。

1. プロジェクトの依存として[`mypy-gitlab-code-quality`](https://pypi.org/project/mypy-gitlab-code-quality/)をインストールします。
1. `mypy`コマンドを変更して、その出力をファイルに送信します。
1. ジョブ`script`にステップを追加し、`mypy-gitlab-code-quality`を使用してファイルを必要な形式に再処理します。以下に例を示します。

   ```yaml
   - mypy $(find -type f -name "*.py" ! -path "**/.venv/**") --no-error-summary > mypy-out.txt || true  # "|| true" is used for preventing job failure when mypy find errors
   - mypy-gitlab-code-quality < mypy-out.txt > gl-code-quality-report.json
   ```

1. レポートファイルの場所を指す[`codequality`レポートアーティファクト](../yaml/artifacts_reports.md#artifactsreportscodequality)を宣言します。

[MyPy CI/CDコンポーネント](https://gitlab.com/explore/catalog/components/code-quality-oss/codequality-os-scanners-integration)を使用または調整してスキャンを実行し、その出力をCode Qualityと統合することもできます。

#### Flake8

CI/CDパイプラインにすでに[Flake8](https://flake8.pycqa.org/)ジョブがある場合は、その出力をCode Qualityに送信するためのレポートを追加する必要があります。出力を統合するには、以下を実行します。

1. プロジェクトの依存として[`flake8-gl-codeclimate`](https://github.com/awelzel/flake8-gl-codeclimate)をインストールします。
1. Flake8の実行に使用するコマンドに引数`--format gl-codeclimate --output-file gl-code-quality-report.json`を追加します。
1. レポートファイルの場所を指す[`codequality`レポートアーティファクト](../yaml/artifacts_reports.md#artifactsreportscodequality)を宣言します。

[Flake8 CI/CDコンポーネント](https://gitlab.com/explore/catalog/components/code-quality-oss/codequality-os-scanners-integration)を使用または調整してスキャンを実行し、その出力をCode Qualityと統合することもできます。

#### Pylint

CI/CDパイプラインにすでに[Pylint](https://pypi.org/project/pylint/)ジョブがある場合は、その出力をCode Qualityに送信するためのレポートを追加する必要があります。出力を統合するには、以下を実行します。

1. プロジェクトの依存として[`pylint-gitlab`](https://pypi.org/project/pylint-gitlab/)をインストールします。
1. Pylintの実行に使用するコマンドに引数`--output-format=pylint_gitlab.GitlabCodeClimateReporter`を追加します。
1. `pylint`コマンドを変更して、その出力をファイルに送信します。
1. レポートファイルの場所を指す[`codequality`レポートアーティファクト](../yaml/artifacts_reports.md#artifactsreportscodequality)を宣言します。

[Pylint CI/CDコンポーネント](https://gitlab.com/explore/catalog/components/code-quality-oss/codequality-os-scanners-integration)を使用または調整してスキャンを実行し、その出力をCode Qualityと統合することもできます。

#### Ruff

CI/CDパイプラインにすでに[Ruff](https://docs.astral.sh/ruff/)ジョブがある場合は、その出力をCode Qualityに送信するためのレポートを追加する必要があります。出力を統合するには、以下を実行します。

1. Ruff の実行に使用するコマンドに引数`--output-format=gitlab`を追加します。
1. `ruff check`コマンドを変更して、その出力をファイルに送信します。
1. レポートファイルの場所を指す[`codequality`レポートアーティファクト](../yaml/artifacts_reports.md#artifactsreportscodequality)を宣言します。

[ドキュメント化されたRuff GitLab CI/CD統合](https://docs.astral.sh/ruff/integrations/#gitlab-cicd)を使用または調整してスキャンを実行し、その出力をCode Qualityと統合することもできます。

#### golangci-lint

CI/CDパイプラインにすでに[`golangci-lint`](https://golangci-lint.run/)ジョブがある場合は、その出力をCode Qualityに送信するためのレポートを追加する必要があります。出力を統合するには、以下を実行します。

1. golangci-lintの実行に使用するコマンドに引数`--out-format code-climate:gl-code-quality-report.json,line-number`を追加します。
1. レポートファイルの場所を指す[`codequality`レポートアーティファクト](../yaml/artifacts_reports.md#artifactsreportscodequality)を宣言します。

[golangci-lint CI/CDコンポーネント](https://gitlab.com/explore/catalog/components/code-quality-oss/codequality-os-scanners-integration)を使用または調整してスキャンを実行し、その出力をCode Qualityと統合することもできます。

#### PMD Copy/Paste Detector

[PMD Copy/Paste Detector (CPD)](https://pmd.github.io/pmd/pmd_userdocs_cpd.html)は、デフォルトの出力が必須の形式に準拠していないため、追加の設定が必要です。

[PMD CI/CDコンポーネント](https://gitlab.com/explore/catalog/components/code-quality-oss/codequality-os-scanners-integration)を使用または調整してスキャンを実行し、その出力をCode Qualityと統合できます。

#### SwiftLint

[SwiftLint](https://realm.github.io/SwiftLint/)を使用する場合は、デフォルトの出力が必須の形式に準拠していないため、追加の設定が必要です。

[Swiftlint CI/CDコンポーネント](https://gitlab.com/explore/catalog/components/code-quality-oss/codequality-os-scanners-integration)を使用または調整してスキャンを実行し、その出力をCode Qualityと統合できます。

#### RuboCop

[RuboCop](https://rubocop.org/) を使用するには、デフォルトの出力が必要な形式に準拠していないため、追加の設定が必要です。

[RuboCop CI/CDコンポーネント](https://gitlab.com/explore/catalog/components/code-quality-oss/codequality-os-scanners-integration)を使用または調整してスキャンを実行し、その出力をCode Qualityと統合できます。

#### Roslynator

[Roslynator](https://josefpihrt.github.io/docs/roslynator/)を使用する場合は、デフォルトの出力が必須の形式に準拠していないため、追加の設定が必要です。

[Roslynator CI/CDコンポーネント](https://gitlab.com/explore/catalog/components/code-quality-oss/codequality-os-scanners-integration)を使用または調整してスキャンを実行し、その出力をCode Qualityと統合できます。

### ドキュメントスキャンツール

Code Qualityを使用すると、コードだけでなく、リポジトリに保存されている任意のファイルをスキャンできます。

#### Vale

CI/CDパイプラインにすでに[Vale](https://vale.sh/)ジョブがある場合は、その出力をCode Qualityに送信するためのレポートを追加する必要があります。出力を統合するには、以下を実行します。

1. 必要な形式を定義するValeテンプレートファイルをリポジトリに作成します。
   - [GitLabドキュメントのチェックに使用するオープンソースのテンプレート](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/.vale/vale-json.tmpl)をコピーできます。
   - コミュニティの[`gitlab-ci-utils`Valeプロジェクト](https://gitlab.com/gitlab-ci-utils/container-images/vale/-/blob/main/vale/vale-glcq.tmpl)で使用されているものなど、別のオープンソースバリアントを使用することもできます。このコミュニティプロジェクトでは、同じテンプレートを含む[事前に作成されたコンテナイメージ](https://gitlab.com/gitlab-ci-utils/container-images/vale)も提供され、パイプラインで直接使用することができます。
1. Valeの実行に使用するコマンドに、引数`--output="$VALE_TEMPLATE_PATH" --no-exit`を追加します。
1. `vale`コマンドを変更して、その出力をファイルに送信します。
1. レポートファイルの場所を指す[`codequality`レポートアーティファクト](../yaml/artifacts_reports.md#artifactsreportscodequality)を宣言します。

たとえば、オープンソースのジョブ定義を使用してスキャンを実行し、その出力をCode Qualityと統合することもできます。

- GitLabドキュメントのチェックに使用される[Vale Lintの手順](https://gitlab.com/gitlab-org/gitlab/-/blob/94f870b8e4b965a41dd2ad576d50f7eeb271f117/.gitlab/ci/docs.gitlab-ci.yml#L71-87)。
- コミュニティの[`gitlab-ci-utils`Valeプロジェクト](https://gitlab.com/gitlab-ci-utils/container-images/vale#usage)。

#### markdownlint-cli2

CI/CDパイプラインにすでに[markdownlint-cli2](https://github.com/DavidAnson/markdownlint-cli2)ジョブがある場合は、その出力をCode Qualityに送信するためのレポートを追加する必要があります。出力を統合するには、以下を実行します。

1. [`markdownlint-cli2-formatter-codequality`](https://www.npmjs.com/package/markdownlint-cli2-formatter-codequality)を、開発時依存関係としてプロジェクトに追加します。
1. まだジョブがない場合は、リポジトリの最上位に`.markdownlint-cli2.jsonc`ファイルを作成します。
1. `outputFormatters`ディレクティブを`.markdownlint-cli2.jsonc`に追加します。

   ```json
   {
     "outputFormatters": [
       [ "markdownlint-cli2-formatter-codequality" ]
     ]
   }
   ```

1. レポートファイルの場所を指す[`codequality`レポートアーティファクト](../yaml/artifacts_reports.md#artifactsreportscodequality)を宣言します。デフォルトでは、レポートファイルの名前は`markdownlint-cli2-codequality.json`です。
   1. 推奨。レポートのファイル名をリポジトリの`.gitignore`ファイルに追加します。

詳細およびCI/CDジョブ定義の例については、[`markdownlint-cli2-formatter-codequality`のドキュメント](https://www.npmjs.com/package/markdownlint-cli2-formatter-codequality)を参照してください。
