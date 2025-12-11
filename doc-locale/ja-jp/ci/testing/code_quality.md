---
stage: Application Security Testing
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Code Quality
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

Code Qualityは、技術的負債になる前に保守性の問題を特定します。コードレビュー中に自動的に行われるフィードバックにより、チームはより良いコードを書くことができます。検出結果はマージリクエストに直接表示されるため、最もコスト効率よく修正できるタイミングで問題を把握できます。

Code Qualityは複数のプログラミング言語に対応しており、一般的なLinter、スタイルチェッカー、複雑性アナライザーと統合できます。既存のツールをCode Qualityワークフローに組み込むことで、結果の表示方法を標準化しながら、チーム独自の設定を維持できます。

## プランごとの機能 {#features-per-tier}

次の表に示すように、利用できる機能は[GitLabのプラン](https://about.gitlab.com/pricing/)によって異なります:

| 機能                                                                                     | Free                              | Premium                           | Ultimate |
|:--------------------------------------------------------------------------------------------|:-------------------------------------|:-------------------------------------|:------------|
| [CI/CDジョブからCode Qualityの結果をインポートする](#import-code-quality-results-from-a-cicd-job) | {{< icon name="check-circle" >}}はい | {{< icon name="check-circle" >}}はい | {{< icon name="check-circle" >}}はい |
| [CodeClimateベースのスキャンを使用する](#use-the-built-in-code-quality-cicd-template-deprecated)   | {{< icon name="check-circle" >}}はい | {{< icon name="check-circle" >}}はい | {{< icon name="check-circle" >}}はい |
| [マージリクエストウィジェットで検出結果を確認する](#merge-request-widget)                             | {{< icon name="check-circle" >}}はい | {{< icon name="check-circle" >}}はい | {{< icon name="check-circle" >}}はい |
| [パイプラインレポートで検出結果を確認する](#pipeline-details-view)                                 | {{< icon name="dotted-circle" >}}いいえ | {{< icon name="check-circle" >}}はい | {{< icon name="check-circle" >}}はい |
| [マージリクエストの変更ビューで検出結果を確認する](#merge-request-changes-view)               | {{< icon name="dotted-circle" >}}いいえ | {{< icon name="dotted-circle" >}}いいえ | {{< icon name="check-circle" >}}はい |
| [プロジェクトの品質サマリービューで全体的な健全性を分析する](#project-quality-view)           | {{< icon name="dotted-circle" >}}いいえ | {{< icon name="dotted-circle" >}}いいえ | {{< icon name="check-circle" >}}はい |

## コードをスキャンして品質違反を検出する {#scan-code-for-quality-violations}

Code Qualityは、多くのスキャンツールからの結果のインポートをサポートするオープンシステムです。違反を見つけて表示するには、以下の手順を実行します:

- スキャンツールを直接使用して、[結果をインポート](#import-code-quality-results-from-a-cicd-job)する。_（推奨）_
- [組み込みのCI/CDテンプレートを使用](#use-the-built-in-code-quality-cicd-template-deprecated)してスキャンを有効にする。このテンプレートでは、一般的なオープンソースツールをラップするCodeClimateエンジンを使用しています。_（非推奨）_

1つのパイプラインで、複数のツールから結果をキャプチャできます。たとえば、コードをスキャンするコードLinterと、ドキュメントをスキャンする言語Linterを一緒に実行したり、スタンドアロンツールとCodeClimateベースのスキャンを組み合わせて使用したりできます。Code Qualityはすべてのレポートを統合するため、[結果を表示](#view-code-quality-results)する際にすべてのレポートを確認できます。

### CI/CDジョブからCode Qualityの結果をインポートする {#import-code-quality-results-from-a-cicd-job}

多くの開発チームではすでに、Linter、スタイルチェッカー、その他のツールをCI/CDパイプラインで使用し、コーディング標準の違反を自動的に検出しています。これらのツールをCode Qualityと統合することで、検出結果を簡単に確認して修正できるようになります。

お使いのツールにドキュメント化された統合が存在するかを確認するには、[一般的なツールをCode Qualityと統合する](#integrate-common-tools-with-code-quality)を参照してください。

別のツールをCode Qualityと統合するには、以下を実行します:

1. CI/CDパイプラインにツールを追加します。
1. レポートをファイルとして出力するようにツールを設定します。
   - このファイルは[特定のJSON形式](#code-quality-report-format)を使用する必要があります。
   - 多くのツールはこの出力形式をネイティブにサポートしています。これらのツールでは、この形式を「CodeClimateレポート」や「GitLab Code Qualityレポート」、または類似の名称で呼ぶことがあります。
   - 他のツールでは、カスタムJSON形式またはテンプレートを使用してJSON出力を生成できることがあります。[レポート形式](#code-quality-report-format)の必須フィールドは少ないため、この出力タイプを使用してCode Quality向けのレポートを作成できる場合があります。
1. このファイルに対応する[`codequality`レポートアーティファクト](../yaml/artifacts_reports.md#artifactsreportscodequality)を宣言します。

これで、パイプラインを実行すると、品質ツールの結果が[処理および表示](#view-code-quality-results)されます。

### 組み込みのCode Quality CI/CDテンプレートを使用する（非推奨） {#use-the-built-in-code-quality-cicd-template-deprecated}

{{< alert type="warning" >}}

この機能は、GitLab 17.3で[非推奨](../../update/deprecations.md#codeclimate-based-code-quality-scanning-will-be-removed)となり、19.0で削除される予定です。代わりに、[サポートされているツールの結果を直接統合](#import-code-quality-results-from-a-cicd-job)してください。

{{< /alert >}}

Code Qualityには、組み込みのCI/CDテンプレート`Code-Quality.gitlab-ci.yaml`も含まれています。このテンプレートは、オープンソースのCodeClimateスキャンエンジンに基づいてスキャンを実行します。

CodeClimateエンジンは以下を実行します:

- [サポート対象の言語セット](https://docs.codeclimate.com/docs/supported-languages-for-maintainability)の基本的な保守性チェック。
- ソースコードを分析するための、オープンソーススキャナーをラップした設定可能な[プラグイン](https://docs.codeclimate.com/docs/list-of-engines)のセット。

詳細については、[CodeClimateベースのCode Qualityスキャンを設定する](code_quality_codeclimate_scanning.md)を参照してください。

#### CodeClimateベースのスキャンから移行する {#migrate-from-codeclimate-based-scanning}

CodeClimateエンジンは、カスタマイズ可能な[分析プラグイン](code_quality_codeclimate_scanning.md#configure-codeclimate-analysis-plugins)のセットを使用します。一部はデフォルトで有効になっていますが、それ以外は明示的に有効にする必要があります。組み込みのプラグインを置き換えるために、次の統合を利用できます:

| プラグイン       | デフォルトで有効                                              | 置換 |
|--------------|------------------------------------------------------------|-------------|
| Duplication  | {{< icon name="check-circle" >}}はい                       | [PMD Copy/Paste Detectorを統合します](#pmd-copypaste-detector)。 |
| ESLint       | {{< icon name="check-circle" >}}はい                       | [ESLintを統合します](#eslint)。 |
| gofmt        | {{< icon name="dotted-circle" >}}いいえ                       | [golangci-lintを統合](#golangci-lint)し、[gofmt Linter](https://golangci-lint.run/usage/linters#gofmt)を有効にします。 |
| golint       | {{< icon name="dotted-circle" >}}いいえ                       | [golangci-lintを統合](#golangci-lint)し、golintを置き換える付属のLinterのいずれかを有効にします。golintは[非推奨となり凍結](https://github.com/golang/go/issues/38968)されました。 |
| govet        | {{< icon name="dotted-circle" >}}いいえ                       | [golangci-lintを統合](#golangci-lint)します。golangci-lintには、[デフォルトでgovetが含まれます](https://golangci-lint.run/usage/linters#enabled-by-default)。 |
| markdownlint | {{< icon name="dotted-circle" >}}いいえ（コミュニティサポート型） | [markdownlint-cli2](#markdownlint-cli2)を統合します。 |
| pep8         | {{< icon name="dotted-circle" >}}いいえ                       | [Flake8](#flake8) 、[Pylint](#pylint) 、[Ruff](#ruff)などの代替Python Linterを統合します。 |
| RuboCop      | {{< icon name="dotted-circle" >}}はい                      | [RuboCopを統合します](#rubocop)。 |
| SonarPython  | {{< icon name="dotted-circle" >}}いいえ                       | [Flake8](#flake8) 、[Pylint](#pylint) 、[Ruff](#ruff)などの代替Python Linterを統合します。 |
| Stylelint    | {{< icon name="dotted-circle" >}}いいえ（コミュニティサポート型） | [Stylelintを統合します](#stylelint)。 |
| SwiftLint    | {{< icon name="dotted-circle" >}}いいえ                       | [SwiftLintを統合します](#swiftlint)。 |

## Code Qualityの結果を表示する {#view-code-quality-results}

Code Qualityの結果は次の場所に表示されます:

- [マージリクエストウィジェット](#merge-request-widget)
- [マージリクエストの変更ビュー](#merge-request-changes-view)
- [パイプラインの詳細ビュー](#pipeline-details-view)
- [プロジェクトの品質ビュー](#project-quality-view)

### マージリクエストウィジェット {#merge-request-widget}

ターゲットブランチに比較用のレポートがある場合、Code Qualityの分析結果がマージリクエストウィジェット領域に表示されます。マージリクエストウィジェットには、マージリクエストで行われた変更によって発生したCode Qualityの検出結果と解決事項が表示されます。同一のフィンガープリントを持つ複数のCode Qualityの検出結果は、マージリクエストのウィジェットでは単一のエントリとして表示されます。個々の検出結果は、**パイプライン**の詳細ビューで参照できる完全なレポートで確認できます。

![マージリクエスト内のコード品質に関する問題のリストが重大度の高い順に並べられている](img/code_quality_merge_request_widget_v18_2.png)

### マージリクエストの変更ビュー {#merge-request-changes-view}

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

Code Qualityの結果は、マージリクエストの**変更**ビューに表示されます。Code Qualityの問題を含む行は、ガターの横に記号でマークされます。記号を選択すると問題のリストが表示され、問題を選択するとその詳細が表示されます。

![マージリクエストの変更タブで、コード品質の問題を示す記号が付いた行](img/code_quality_changes_view_v18_2.png)

### パイプラインの詳細ビュー {#pipeline-details-view}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

パイプラインによって生成されたCode Qualityの違反の完全なリストは、パイプラインの詳細ページの**Code Quality**タブに表示されます。パイプラインの詳細ビューには、パイプラインが実行されたブランチで検出されたすべてのCode Qualityの検出結果が表示されます。

![ブランチ内のすべての問題のリストが重大度の高い順に並べられている](img/code_quality_pipeline_details_view_v18_2.png)

### プロジェクトの品質ビュー {#project-quality-view}

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed
- ステータス: ベータ

{{< /details >}}

{{< history >}}

- GitLab 14.5で`project_quality_summary_page`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/72724)されました。この機能は[ベータ版](../../policy/development_stages_support.md)です。デフォルトでは無効になっています。

{{< /history >}}

プロジェクトの品質ビューに、コード品質の検出結果の概要が表示されます。このビューは**分析** > **CI/CD分析**で確認できます。また、特定のプロジェクトに対して[`project_quality_summary_page`](../../administration/feature_flags/_index.md)機能フラグを有効にする必要があります。

![検出結果に、違反と呼ばれる問題の総数と、重大度ごとの問題の数が示されている](img/code_quality_summary_v15_9.png)

## Code Qualityのレポート形式 {#code-quality-report-format}

次の形式でレポートを出力できる任意のツールから、[Code Qualityの結果をインポート](#import-code-quality-results-from-a-cicd-job)できます。この形式は、[CodeClimateレポート形式](https://github.com/codeclimate/platform/blob/master/spec/analyzers/SPEC.md#data-types)の一種で、フィールド数が少なくなっています。

[Code Qualityレポートアーティファクト](../yaml/artifacts_reports.md#artifactsreportscodequality)として提供するファイルには、単一のJSON配列を含める必要があります。その配列内の各オブジェクトには、少なくとも次のプロパティが必要です:

| 名前                                                      | 型    | 説明 |
|-----------------------------------------------------------|---------|-------------|
| `description`                                             | 文字列  | コード品質違反について、人間が読める形式で記載された説明。 |
| `check_name`                                              | 文字列  | この違反に関連するチェックやルールを表す一意の名前。 |
| `fingerprint`                                             | 文字列  | 特定のコード品質違反を識別するための一意のフィンガープリント（その違反内容のハッシュなど）。 |
| `location.path`                                           | 文字列  | リポジトリ内の相対パスで表した、コード品質違反を含むファイル。`./`を先頭に付けないでください。 |
| `location.lines.begin`または`location.positions.begin.line` | 整数 | コード品質違反が発生した行。 |
| `severity`                                                | 文字列  | 違反の重大度。`info`、`minor`、`major`、`critical`、`blocker`のいずれかになります。 |

この形式は、次の点で[CodeClimateレポート形式](https://github.com/codeclimate/platform/blob/master/spec/analyzers/SPEC.md#data-types)と異なります:

- [CodeClimateレポート形式](https://github.com/codeclimate/platform/blob/master/spec/analyzers/SPEC.md#data-types)は、より多くのプロパティをサポートしていますが、Code Qualityは前述のフィールドのみを処理します。
- GitLabパーサーは、先頭に[バイトオーダーマーク（BOM）](https://en.wikipedia.org/wiki/Byte_order_mark)があるファイルを処理できません。

以下に、準拠した形式のレポートの例を示します:

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

## 一般的なツールをCode Qualityと統合する {#integrate-common-tools-with-code-quality}

多くのツールは、結果をCode Qualityと統合するために必要な[レポート形式](#code-quality-report-format)をネイティブにサポートしています。これらのツールでは、この形式を「CodeClimateレポート」や「GitLab Code Qualityレポート」、または類似の名称で呼ぶことがあります。

その他のツールは、カスタムテンプレートまたは形式の仕様を指定することで、JSON出力を生成するように設定できます。[レポート形式](#code-quality-report-format)の必須フィールドは少ないため、この出力タイプを使用してCode Quality向けのレポートを作成できる場合があります。

CI/CDパイプラインですでにツールを使用している場合は、既存のジョブを調整してCode Qualityレポートを追加することが推奨されます。既存のジョブを調整することで、デベロッパーを混乱させたり、パイプラインの実行時間を長くしたりする可能性のある別のジョブを実行せずに済みます。

ツールをまだ使用していない場合は、CI/CDジョブを一から作成するか、[CI/CDカタログ](../components/_index.md#cicd-catalog)のコンポーネントを使用してツールを導入できます。

### コードスキャンツール {#code-scanning-tools}

#### ESLint {#eslint}

CI/CDパイプラインにすでに[ESLint](https://eslint.org/)ジョブがある場合は、その出力をCode Qualityに送信するためにレポートを追加する必要があります。出力を統合するには、以下を実行します:

1. プロジェクトに開発依存関係として[`eslint-formatter-gitlab`](https://www.npmjs.com/package/eslint-formatter-gitlab)を追加します。
1. ESLintの実行に使用するコマンドに`--format gitlab`オプションを追加します。
1. レポートファイルの場所を指す[`codequality`レポートアーティファクト](../yaml/artifacts_reports.md#artifactsreportscodequality)を宣言します。
   - デフォルトでは、フォーマッターはCI/CD設定を読み取り、レポートを保存するファイル名を推測します。フォーマッターがアーティファクトの宣言で使用したファイル名を推測できない場合は、CI/CD変数`ESLINT_CODE_QUALITY_REPORT`に、アーティファクトに指定したファイル名（`gl-code-quality-report.json`など）を指定します。

[ESLint CI/CDコンポーネント](https://gitlab.com/explore/catalog/components/code-quality-oss/codequality-os-scanners-integration)を使用または調整してスキャンを実行し、その出力をCode Qualityと統合することもできます。

#### Stylelint {#stylelint}

CI/CDパイプラインにすでに[Stylelint](https://stylelint.io/)ジョブがある場合は、その出力をCode Qualityに送信するためにレポートを追加する必要があります。出力を統合するには、以下を実行します:

1. プロジェクトに開発依存関係として[`@studiometa/stylelint-formatter-gitlab`](https://www.npmjs.com/package/@studiometa/stylelint-formatter-gitlab)を追加します。
1. Stylelintの実行に使用するコマンドに`--custom-formatter=@studiometa/stylelint-formatter-gitlab`オプションを追加します。
1. レポートファイルの場所を指す[`codequality`レポートアーティファクト](../yaml/artifacts_reports.md#artifactsreportscodequality)を宣言します。
   - デフォルトでは、フォーマッターはCI/CD設定を読み取り、レポートを保存するファイル名を推測します。フォーマッターがアーティファクトの宣言で使用したファイル名を推測できない場合は、CI/CD変数`STYLELINT_CODE_QUALITY_REPORT`に、アーティファクトに指定したファイル名（`gl-code-quality-report.json`など）を指定します。

詳細およびCI/CDジョブ定義の例については、[`@studiometa/stylelint-formatter-gitlab`のドキュメント](https://www.npmjs.com/package/@studiometa/stylelint-formatter-gitlab#usage)を参照してください。

#### MyPy {#mypy}

CI/CDパイプラインにすでに[MyPy](https://mypy-lang.org/)ジョブがある場合は、その出力をCode Qualityに送信するためにレポートを追加する必要があります。出力を統合するには、以下を実行します:

1. プロジェクトに依存関係として[`mypy-gitlab-code-quality`](https://pypi.org/project/mypy-gitlab-code-quality/)をインストールします。
1. `mypy`コマンドを変更して、その出力をファイルに送信します。
1. ジョブ`script`にステップを追加し、`mypy-gitlab-code-quality`を使用してファイルを必要な形式に再処理します。例:

   ```yaml
   - mypy $(find -type f -name "*.py" ! -path "**/.venv/**") --no-error-summary > mypy-out.txt || true  # "|| true" is used for preventing job failure when mypy find errors
   - mypy-gitlab-code-quality < mypy-out.txt > gl-code-quality-report.json
   ```

1. レポートファイルの場所を指す[`codequality`レポートアーティファクト](../yaml/artifacts_reports.md#artifactsreportscodequality)を宣言します。

[MyPy CI/CDコンポーネント](https://gitlab.com/explore/catalog/components/code-quality-oss/codequality-os-scanners-integration)を使用または調整してスキャンを実行し、その出力をCode Qualityと統合することもできます。

#### Flake8 {#flake8}

CI/CDパイプラインにすでに[Flake8](https://flake8.pycqa.org/)ジョブがある場合は、その出力をCode Qualityに送信するためにレポートを追加する必要があります。出力を統合するには、以下を実行します:

1. プロジェクトに依存関係として[`flake8-gl-codeclimate`](https://github.com/awelzel/flake8-gl-codeclimate)をインストールします。
1. Flake8の実行に使用するコマンドに引数`--format gl-codeclimate --output-file gl-code-quality-report.json`を追加します。
1. レポートファイルの場所を指す[`codequality`レポートアーティファクト](../yaml/artifacts_reports.md#artifactsreportscodequality)を宣言します。

[Flake8 CI/CDコンポーネント](https://gitlab.com/explore/catalog/components/code-quality-oss/codequality-os-scanners-integration)を使用または調整してスキャンを実行し、その出力をCode Qualityと統合することもできます。

#### Pylint {#pylint}

CI/CDパイプラインにすでに[Pylint](https://pypi.org/project/pylint/)ジョブがある場合は、その出力をCode Qualityに送信するためにレポートを追加する必要があります。出力を統合するには、以下を実行します:

1. プロジェクトに依存関係として[`pylint-gitlab`](https://pypi.org/project/pylint-gitlab/)をインストールします。
1. Pylintの実行に使用するコマンドに引数`--output-format=pylint_gitlab.GitlabCodeClimateReporter`を追加します。
1. `pylint`コマンドを変更して、その出力をファイルに送信します。
1. レポートファイルの場所を指す[`codequality`レポートアーティファクト](../yaml/artifacts_reports.md#artifactsreportscodequality)を宣言します。

[Pylint CI/CDコンポーネント](https://gitlab.com/explore/catalog/components/code-quality-oss/codequality-os-scanners-integration)を使用または調整してスキャンを実行し、その出力をCode Qualityと統合することもできます。

#### Ruff {#ruff}

CI/CDパイプラインにすでに[Ruff](https://docs.astral.sh/ruff/)ジョブがある場合は、その出力をCode Qualityに送信するためにレポートを追加する必要があります。出力を統合するには、以下を実行します:

1. Ruffの実行に使用するコマンドに引数`--output-format=gitlab`を追加します。
1. `ruff check`コマンドを変更して、その出力をファイルに送信します。
1. レポートファイルの場所を指す[`codequality`レポートアーティファクト](../yaml/artifacts_reports.md#artifactsreportscodequality)を宣言します。

[ドキュメント化されたRuff GitLab CI/CDインテグレーション](https://docs.astral.sh/ruff/integrations/#gitlab-cicd)を使用または調整してスキャンを実行し、その出力をCode Qualityと統合することもできます。

#### golangci-lint {#golangci-lint}

CI/CDパイプラインにすでに[`golangci-lint`](https://golangci-lint.run/)ジョブがある場合は、その出力をCode Qualityに送信するためにレポートを追加する必要があります。出力を統合するには、以下を実行します:

1. `golangci-lint`の実行に使用するコマンドに引数を追加します。

   - v1の場合は、`--out-format code-climate:gl-code-quality-report.json,line-number`を追加します。
   - v2の場合は、`--output.code-climate.path=gl-code-quality-report.json`を追加します。

1. レポートファイルの場所を指す[`codequality`レポートアーティファクト](../yaml/artifacts_reports.md#artifactsreportscodequality)を宣言します。

[golangci-lint CI/CDコンポーネント](https://gitlab.com/explore/catalog/components/code-quality-oss/codequality-os-scanners-integration)を使用または調整してスキャンを実行し、その出力をCode Qualityと統合することもできます。

#### PMD Copy/Paste Detector {#pmd-copypaste-detector}

[PMD Copy/Paste Detector（CPD）](https://pmd.github.io/pmd/pmd_userdocs_cpd.html)は、デフォルトの出力が必要な形式に準拠していないため、追加の設定が必要です。

[PMD CI/CDコンポーネント](https://gitlab.com/explore/catalog/components/code-quality-oss/codequality-os-scanners-integration)を使用または調整してスキャンを実行し、その出力をCode Qualityと統合できます。

#### SwiftLint {#swiftlint}

[SwiftLint](https://realm.github.io/SwiftLint/)を使用する場合は、デフォルトの出力が必要な形式に準拠していないため、追加の設定が必要です。

[Swiftlint CI/CDコンポーネント](https://gitlab.com/explore/catalog/components/code-quality-oss/codequality-os-scanners-integration)を使用または調整してスキャンを実行し、その出力をCode Qualityと統合できます。

#### RuboCop {#rubocop}

[RuboCop](https://rubocop.org/)を使用するには、デフォルトの出力が必要な形式に準拠していないため、追加の設定が必要です。

[RuboCop CI/CDコンポーネント](https://gitlab.com/explore/catalog/components/code-quality-oss/codequality-os-scanners-integration)を使用または調整してスキャンを実行し、その出力をCode Qualityと統合できます。

#### Roslynator {#roslynator}

[Roslynator](https://josefpihrt.github.io/docs/roslynator/)を使用する場合は、デフォルトの出力が必要な形式に準拠していないため、追加の設定が必要です。

[Roslynator CI/CDコンポーネント](https://gitlab.com/explore/catalog/components/code-quality-oss/codequality-os-scanners-integration)を使用または調整してスキャンを実行し、その出力をCode Qualityと統合できます。

### ドキュメントスキャンツール {#documentation-scanning-tools}

Code Qualityを使用すると、コード以外でも、リポジトリに保存されている任意のファイルをスキャンできます。

#### Vale {#vale}

CI/CDパイプラインにすでに[Vale](https://vale.sh/)ジョブがある場合は、その出力をCode Qualityに送信するためにレポートを追加する必要があります。出力を統合するには、以下を実行します:

1. 必要な形式を定義するValeテンプレートファイルをリポジトリ内に作成します。
   - [GitLabドキュメントのチェックに使用するオープンソースのテンプレート](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/.vale/vale-json.tmpl)をコピーできます。
   - コミュニティの[`gitlab-ci-utils` Valeプロジェクト](https://gitlab.com/gitlab-ci-utils/container-images/vale/-/blob/main/vale/vale-glcq.tmpl)で使用されているものなど、別のオープンソースバリアントを使用することもできます。このコミュニティプロジェクトでは、同じテンプレートを含む[事前に作成されたコンテナイメージ](https://gitlab.com/gitlab-ci-utils/container-images/vale)も提供しているため、パイプラインで直接使用できます。
1. Valeの実行に使用するコマンドに引数`--output="$VALE_TEMPLATE_PATH" --no-exit`を追加します。
1. `vale`コマンドを変更して、その出力をファイルに送信します。
1. レポートファイルの場所を指す[`codequality`レポートアーティファクト](../yaml/artifacts_reports.md#artifactsreportscodequality)を宣言します。

オープンソースのジョブ定義を使用または調整してスキャンを実行し、その出力をCode Qualityと統合することもできます。たとえば、次のようなジョブ定義があります:

- GitLabドキュメントのチェックに使用される[Vale Lintのステップ](https://gitlab.com/gitlab-org/gitlab/-/blob/94f870b8e4b965a41dd2ad576d50f7eeb271f117/.gitlab/ci/docs.gitlab-ci.yml#L71-87)。
- コミュニティの[`gitlab-ci-utils` Valeプロジェクト](https://gitlab.com/gitlab-ci-utils/container-images/vale#usage)。

#### markdownlint-cli2 {#markdownlint-cli2}

CI/CDパイプラインにすでに[markdownlint-cli2](https://github.com/DavidAnson/markdownlint-cli2)ジョブがある場合は、その出力をCode Qualityに送信するためにレポートを追加する必要があります。出力を統合するには、以下を実行します:

1. プロジェクトに開発依存関係として[`markdownlint-cli2-formatter-codequality`](https://www.npmjs.com/package/markdownlint-cli2-formatter-codequality)を追加します。
1. まだない場合は、リポジトリの最上位に`.markdownlint-cli2.jsonc`ファイルを作成します。
1. `outputFormatters`ディレクティブを`.markdownlint-cli2.jsonc`に追加します:

   ```json
   {
     "outputFormatters": [
       [ "markdownlint-cli2-formatter-codequality" ]
     ]
   }
   ```

1. レポートファイルの場所を指す[`codequality`レポートアーティファクト](../yaml/artifacts_reports.md#artifactsreportscodequality)を宣言します。デフォルトでは、レポートファイル名は`markdownlint-cli2-codequality.json`です。
   1. （推奨）レポートファイル名をリポジトリの`.gitignore`ファイルに追加します。

詳細およびCI/CDジョブ定義の例については、[`markdownlint-cli2-formatter-codequality`のドキュメント](https://www.npmjs.com/package/markdownlint-cli2-formatter-codequality)を参照してください。
