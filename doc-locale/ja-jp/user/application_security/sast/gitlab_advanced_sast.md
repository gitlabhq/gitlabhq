---
stage: Application Security Testing
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: GitLab高度なSASTは、クロスファイル、クロスファンクションのテイント解析を使用して、複雑な脆弱性を高い精度で検出します。
title: GitLab高度なSAST
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 17.1でPythonの[実験的機能](../../../policy/development_stages_support.md)として導入されました。
- 17.2でGoとJavaのサポートが追加されました。
- GitLab 17.2で実験的機能版からベータ版に[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/461859)されました。
- 17.3でJavaScript、TypeScript、C#のサポートが追加されました。
- GitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/474094)になりました。
- GitLab 17.4でJava Server Pages（JSP）のサポートが追加されました。
- GitLab 18.1でPHPのサポートが[追加](https://gitlab.com/groups/gitlab-org/-/epics/14273)されました。
- GitLab 18.6では、C/C++のサポートが[追加](https://gitlab.com/groups/gitlab-org/-/epics/14271)されました。

{{< /history >}}

高度なSASTは、従来のSASTよりも誤検出が少なく、クロスファンクションおよびクロスファイルのテイント解析を使用して複雑な脆弱性を検出する、静的アプリケーションセキュリティテスト（SAST）アナライザーです。

GitLab高度なSASTは、オプトイン機能です。有効にすると、高度なSASTは、定義済みのルールセットを使用して、サポートされているすべての言語ファイルをスキャンします。Semgrepアナライザーは、これらのファイルをスキャンしません。自動化された[移行プロセス](#transitioning-from-semgrep-to-gitlab-advanced-sast)により、両方のアナライザーが同じ脆弱性を検出した場合に、重複する検出結果が削除されます。

<i class="fa-youtube-play" aria-hidden="true"></i> GitLab高度なSASTの概要とその仕組みについては、[GitLab Advanced SAST: Accelerating Vulnerability Resolution](https://youtu.be/xDa1MHOcyn8)（GitLab高度なSAST: 脆弱性の修正を加速する）を参照してください。

製品ツアーについては、[GitLab高度なSAST製品ツアー](https://gitlab.navattic.com/advanced-sast)をご覧ください。

## 機能 {#features}

| 機能                                                                      | SAST                                                                                                                                      | 高度なSAST                                                                                                                               |
|------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------|
| 分析の深さ                                                            | 複雑な脆弱性を検出する機能が制限されています。分析は単一のファイル、および単一の関数（限定的な例外はあります）に限定されます。 | クロスファイル、クロスファンクションのテイント解析を使用して、複雑な脆弱性を検出します。                                                            |
| 精度                                                                     | コンテキストが限られているため、誤検出の結果が生じる可能性が高くなります。                                                                      | クロスファイル、クロスファンクションのテイント解析を使用して、真に悪用可能な脆弱性に焦点を当てることで、誤検出の結果を減らします。      |
| 修正ガイダンス                                                         | 脆弱性の検出結果は行番号で識別されます。                                                                                     | 詳細な[コードフロービュー](#code-flow)は、脆弱性がプログラム全体にどのように流れるかを示し、迅速な修正を可能にします。 |
| GitLab Duo脆弱性の説明と脆弱性の修正に対応 | はい。                                                                                                                                      | はい。                                                                                                                                        |
| 言語カバレッジ                                                            | [より広範にカバーします](_index.md#supported-languages-and-frameworks)。                                                                           | [より限定的です](#supported-languages)。                                                                                                       |

## はじめに {#getting-started}

高度なSASTを初めて使用する場合は、パイプラインエディタを使用して、プロジェクトで有効にします。

前提条件: 

- 標準のSASTアナライザーを有効にします。詳細については、[SASTの前提条件](_index.md#getting-started)を参照してください。
- GitLab Self-Managedの場合は、サポートされているGitLabバージョンを使用してください: 
  - 最小バージョン: GitLab 17.1以降
  - 推奨バージョン: GitLab 17.4以降（コードフロービュー、脆弱性の重複排除、更新されたテンプレートが含まれます）
  - テンプレートの互換性: 
    - 安定版テンプレート: GitLab 17.3以降
    - 最新テンプレート: GitLab 17.2以降
    - 同じプロジェクトで[安定版テンプレートと最新テンプレート](../detect/security_configuration.md#template-editions)を混在させないでください

高度なSASTを有効にするには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **ビルド** > **パイプライン**エディターに移動します。
1. `.gitlab-ci.yml`ファイルを作成または編集します。
1. 適切な変数を追加して、高度なSASTを有効にします:

   - C/C++以外のサポートされているすべての言語の場合: `GITLAB_ADVANCED_SAST_ENABLED: 'true'`

   - C/C++の場合: `GITLAB_ADVANCED_SAST_CPP_ENABLED: 'true'`

1. **検証**タブを選択し、**パイプラインの検証**を選択します。

   **シミュレーションが正常に完了しました**というメッセージは、ファイルが有効であることを裏付けています。
1. **編集**タブを選択します。
1. フィールドに入力します。
1. **これらの変更で新しいマージリクエストを開始**チェックボックスをオンにし、**変更をコミットする**を選択します。
1. 標準のワークフローに従ってフィールドに入力し、**マージリクエストの作成**を選択します。
1. 標準のワークフローに従ってマージリクエストをレビューおよび編集し、**マージ**を選択します。

この時点で、GitLab高度なSASTがパイプラインで有効になっています。サポートされているソースコードは、パイプラインの実行時に脆弱性がスキャンされます。対応するジョブがパイプラインの`test`ステージに表示されます。

これらのステップを完了すると、次のことができるようになります。

- [脆弱性の結果](#vulnerability-results)を評価する方法の詳細をご覧ください。
- [最適化のヒント](#optimization)を確認する。
- [幅広いプロジェクトへのロールアウト](#roll-out)を計画する。

## 脆弱性の結果 {#vulnerability-results}

GitLab高度なSASTの脆弱性には、セキュリティの問題を評価および修正するのに役立つ詳細情報が含まれています。各脆弱性には、以下が表示されます:

- 説明: 脆弱性の原因、潜在的な影響、推奨される修正手順について説明しています。
- ステータス: 脆弱性がトリアージされたか、解決されたかを示します。
- 重大度: 影響に基づいて6つのレベルに分類されます。[重大度レベルの詳細はこちらをご覧ください](../vulnerabilities/severities.md)。
- 場所: 問題が検出されたファイル名と行番号を示します。ファイルパスを選択すると、対応する行がコードビューで開きます。
- コードフロー: ユーザー入力（ソース）から脆弱性のあるコード行までのデータのパス。
- スキャナー: 脆弱性を検出したアナライザーを示します。
- 識別子: CWE識別子など、脆弱性を分類するために使用される参照と、それを検出したルールのIDのリスト。

SASTの脆弱性には、検出された脆弱性の主要なCWE識別子に従って名前が付けられています。SASTカバレッジの詳細については、[SASTルール](rules.md)を参照してください。

### 結果の表示 {#view-results}

パイプラインで脆弱性を表示するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 左側のサイドバーで、**ビルド** > **パイプライン**を選択します。
1. パイプラインを選択します。
1. **セキュリティ**タブを選択します。
1. 結果をダウンロードするか、脆弱性を選択して詳細を表示します（Ultimateのみ）。

#### コードフロー {#code-flow}

{{< history >}}

- GitLab 17.3で、[いくつかの機能フラグ](../../../administration/feature_flags/_index.md)とともに導入されました。デフォルトでは有効になっています。
- GitLab 17.7のGitLab Self-ManagedおよびGitLab Dedicatedで有効になりました。
- GitLab 17.7で一般提供になりました。すべての機能フラグが削除されました。

{{< /history >}}

特定の種類の脆弱性について、GitLab高度なSASTはコードフロー情報を提供します。脆弱性のコードフローとは、データが、すべての割り当て、操作、サニタイズを通じて、ユーザー入力（ソース）から脆弱なコード行（シンク）に至るまでの間でたどるパスです。この情報は、脆弱性のコンテキスト、影響、およびリスクを理解して評価するのに役立ちます。入力をソースからシンクまでトレースすることで検出された脆弱性のコードフロー情報を利用できます。この脆弱性には、以下が含まれます。

- SQLインジェクション
- コマンドインジェクション
- クロスサイトスクリプティング（XSS）
- パストラバーサル

コードフロー情報は**コードフロー**タブに表示され、以下が含まれています。

- ソースからシンクまでのステップ。
- コードスニペットを含む、関連ファイル。

![2つのファイルにまたがるPythonアプリケーションのコードフロー](img/code_flow_view_v17_7.png)

## 最適化 {#optimization}

GitLab高度なSASTを最適化するには、次のいずれかの方法を使用します:

- パスの除外
- マルチコアスキャン
- 差分ベーススキャン

スキャンが予想以上に長く実行される場合は、[トラブルシューティング](#troubleshooting)を参照してください。

### パスの除外 {#exclude-paths}

パフォーマンスを最適化し、関連するリポジトリコンテンツに焦点を当てるために、パスを除外します。

[`SAST_EXCLUDED_PATHS`](_index.md#vulnerability-filters) CI/CD変数に除外されたパスを一覧表示します。

パスを除外する場合は、脆弱性を隠さないように選択的に行ってください。一般的な候補は次のとおりです:

- データベースマイグレーション
- 単体テスト
- `node_modules/`などの依存関係のディレクトリ
- ビルドディレクトリ

### マルチコアスキャンの使用 {#use-multi-core-scanning}

マルチコアスキャンは、GitLab高度なSAST（アナライザーバージョンv1.1.10以降）でデフォルトで有効になっています。Runnerのサイズを大きくして、スキャンに使用できるリソースを増やすことができます。セルフマネージドRunnerの場合は、[セキュリティスキャナーの設定](_index.md#security-scanner-configuration)で`--multi-core`フラグをカスタマイズする必要があります。

### 差分ベーススキャン {#diff-based-scanning}

{{< history >}}

- GitLab 18.5で`vulnerability_partial_scans`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/groups/gitlab-org/-/epics/16790)されました。デフォルトでは無効になっています。
- GitLab 18.5では、[GitLab.com、GitLab Self-Managed、GitLab Dedicatedで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/552051)。
- GitLab 18.6で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/552051)になりました。機能フラグ`vulnerability_partial_scans`は削除されました。

{{< /history >}}

差分ベーススキャンは、マージリクエストで変更されたファイルとその依存ファイルのみを分析します。この対象を絞ったアプローチにより、スキャン時間が短縮され、開発中に迅速なフィードバックが得られます。

完全なカバレッジを確保するために、マージリクエストがマージされた後、デフォルトブランチでフルスキャンが実行されます。

差分ベーススキャンが有効になっている場合:

- マージリクエストで変更または追加されたファイルと、その依存ファイルのみがスキャンされます。
- 有効にすると、ジョブログに次の内容が出力されます: `Running differential scan`無効になっている場合は、次の内容が出力されます: `Running full scan`
- **merge request security widget**では、専用の**差分ベース**タブに関連するスキャン結果が表示されます。
- **Pipeline Security**タブでは、**Partial SAST report**というラベルの付いたアラートは、部分的な検出結果のみが含まれていることを示します。

#### 差分ベーススキャンを使用してパフォーマンスを向上させる {#use-diff-based-scanning-to-improve-performance}

マージリクエストパイプラインで差分ベーススキャンを有効にするには、このCI/CD変数をプロジェクトのCI/CD設定ファイル、またはスキャン実行ポリシーかパイプライン実行ポリシーのいずれかに設定します。

| 変数                     | 値          | 説明 |
|------------------------------|----------------|-------------|
| `ADVANCED_SAST_PARTIAL_SCAN` | `differential` | 差分ベーススキャンモードを有効にします |

#### パイプラインのサポートと動作 {#pipeline-support-and-behavior}

差分ベーススキャンは、次の条件でマージリクエストパイプラインとブランチパイプラインの両方でサポートされています。

##### マージリクエストパイプライン {#merge-request-pipelines}

差分ベーススキャンは、[マージリクエストパイプライン](../detect/security_configuration.md#use-security-scanning-tools-with-merge-request-pipelines)で実行するようにGitLab高度なSASTが設定されている場合に発生します。

##### ブランチパイプライン {#branch-pipelines}

差分ベーススキャンは、ブランチに関連付けられているオープンマージリクエストが1つだけ存在する場合に発生します。存在しない場合、または複数存在する場合、ブランチをどのコミットと比較すればよいかを判断できないため、スキャンはフルスキャンにフォールバックします。

#### 依存ファイル {#dependent-files}

変更されたファイルを超えてクロスファイルの脆弱性を見逃さないようにするために、差分ベーススキャンには、それらの直接的な依存関係が含まれます。これにより、偽陰性が減少し、高速スキャンが維持されますが、詳細については[下記](#false-negatives-and-positives)で説明するように、より深い依存関係チェーンでは不正確な結果が生じる可能性があります。

次のファイルがスキャンに含まれています:

- 変更されたファイル（マージリクエストで変更または追加されたファイル）
- 依存ファイル（変更されたファイルをインポートするファイル）

この設計は、変更された関数からそれをインポートする呼び出し元にテイント解析されたデータが移動するなど、クロスファイルデータフローの検出に役立ちます。

変更されたファイルによってインポートされたファイルは、通常、変更されたコード行の動作やデータフローに影響を与えないため、スキャンされません。

たとえば、ファイルBを変更するマージリクエストについて考えてみましょう:

- ファイルAがファイルBをインポートする場合、ファイルAとファイルBがスキャンされます。
- ファイルBがファイルCをインポートする場合、ファイルBのみがスキャンされます。

#### 制限事項 {#restrictions}

##### 偽陽性と偽陰性 {#false-negatives-and-positives}

差分ベーススキャンでは、スキャンされたファイル内の完全な呼び出しグラフがキャプチャされない場合があり、脆弱性（偽陰性）を見逃したり、解決済みの脆弱性が再浮上したりする可能性があります（偽陽性）。このトレードオフにより、スキャン時間が短縮され、開発中に迅速なフィードバックが得られます。包括的なカバレッジのために、デフォルトブランチでは常にフルスキャンが実行されます。

##### C/C++ヘッダーファイルのカバレッジ {#cc-header-file-coverage}

差分ベーススキャンは、C/C++ヘッダーファイルを完全にサポートしていません。ヘッダーファイルとソースファイルの両方にまたがる脆弱性は検出できますが、ヘッダーファイルにのみ存在する脆弱性は検出されない場合があります。

##### 修正された脆弱性は報告されません {#fixed-vulnerabilities-not-reported}

誤解を招く結果を回避するために、差分ベーススキャンでは修正された脆弱性が除外されます。ファイルのサブセットのみが分析されるため、完全な呼び出しグラフは利用できず、脆弱性が修正されたかどうかを確認することはできません。

フルスキャンは、マージ後にデフォルトブランチで常に実行され、修正された脆弱性が報告されます。

## ロールアウトする {#roll-out}

1つのプロジェクトでGitLab高度なSASTの結果に自信を持ったら、追加のプロジェクトとグループに拡張します。GitLab高度なSASTを含む共有CI/CD設定を作成し、目的のグループとプロジェクト全体に適用する必要があります。

詳細については、[セキュリティ設定](../detect/security_configuration.md)を参照してください。

## 脆弱性検出基準 {#vulnerability-detection-criteria}

GitLab高度なSASTは、テイント解析によるクロスファイル、クロスファンクションスキャンを使用して、ユーザー入力のプログラムへの流れを追跡します。これにより、SQLインジェクションやクロスサイトスクリプティング（XSS）などのインジェクション脆弱性が、複数の関数やファイルにまたがる場合でも検出されるようになります。

アナライザーは、信頼できないユーザー入力をソースから、信頼できないデータがセキュリティ脆弱性を引き起こす可能性のあるポイントに導く、検証可能なフローがある場合にのみ、テイント解析ベースの脆弱性を報告します。このアプローチは、検証が不十分な脆弱性を報告する可能性のある他の製品と比較して、ノイズを最小限に抑えます。

検出では、HTTPリクエストからソースされる値など、信頼境界を越える入力が重視されますが、コマンドラインの引数、環境変数、またはプログラムを操作するユーザーが通常提供するその他の入力は除外されます。

GitLabの高度な静的アプリケーションセキュリティテストが検出する脆弱性の種類の詳細については、[GitLab高度なSASTのCWEカバレッジ](advanced_sast_coverage.md)を参照してください。

## SemgrepからGitLab高度なSASTへの移行 {#transitioning-from-semgrep-to-gitlab-advanced-sast}

SemgrepからGitLab高度なSASTに移行すると、自動移行プロセスにより、脆弱性が重複排除されます。このプロセスでは、以前に検出されたSemgrepの脆弱性を対応するGitLab高度なSASTの発見にリンクし、一致するものが見つかった場合に置き換えます。

スキャンが実行され、脆弱性が検出されたときに、デフォルトブランチで高度なSASTスキャンを有効にした後、それらのいずれかが次の条件に基づいて既存のSemgrep脆弱性を置き換える必要があるかどうかを確認します。

### 重複排除の条件 {#conditions-for-deduplication}

1. **識別子の照合**:
   - GitLab高度なSASTの少なくとも1つの脆弱性識別子（CWEとOWASPを除く）が、既存のSemgrep脆弱性の**プライマリ識別子**と一致する必要があります。
   - プライマリ識別子は、[SASTレポート](_index.md#download-a-sast-report)内にある脆弱性の識別子配列の最初の識別子です。
   - たとえば、GitLab高度なSASTの脆弱性に`bandit.B506`などの識別子があり、Semgrepの脆弱性のプライマリ識別子も`bandit.B506`である場合、この条件は満たされます。

1. **場所の照合**:
   - 脆弱性は、コード内の**同じ場所**に関連付けられている必要があります。これは、[SASTレポート](_index.md#download-a-sast-report)内にある脆弱性の次のいずれかのフィールドを使用して判別されます。
     - 追跡フィールド（存在する場合）
     - 場所フィールド（追跡フィールドが存在しない場合）

### 脆弱性の変更 {#vulnerability-changes}

条件が満たされると、Semgrepの既存の脆弱性はGitLab高度なSASTの脆弱性に変換されます。この更新された脆弱性は、次の変更を加えて[脆弱性レポート](../vulnerability_report/_index.md)に表示されます。

- スキャナーの種類がSemgrepからGitLab高度なSASTに更新されます。
- GitLab高度なSASTの脆弱性に存在する追加の識別子が、既存の脆弱性に追加されます。
- 脆弱性のそれ以外の詳細は変更されません。

### 重複する脆弱性の解決 {#resolve-duplicate-vulnerabilities}

[重複排除の条件](#conditions-for-deduplication)が満たされない場合、Semgrepの脆弱性が重複としてそのまま表示されることがあります。[脆弱性レポート](../vulnerability_report/_index.md)でこれを解決するには、次の手順に従います。

1. 高度なSASTスキャナーで[脆弱性をフィルタリング](../vulnerability_report/_index.md#filtering-vulnerabilities)し、[結果をCSV形式でエクスポート](../vulnerability_report/_index.md#export-details)します。
1. Semgrepスキャナーで[脆弱性をフィルタリング](../vulnerability_report/_index.md#filtering-vulnerabilities)します。これらは、重複排除されなかった脆弱性である可能性があります。
1. Semgrepの脆弱性ごとに、エクスポートされた高度なSASTの結果に対応する一致があるかどうかを確認します。
1. 重複が存在する場合は、Semgrepの脆弱性を適切に解決します。

## コードカバレッジ {#code-coverage}

デフォルトでは、GitLab高度なSASTは、サポートされている言語のすべてのソースコードを分析します。差分ベーススキャンが有効になっている場合は、マージリクエストでの変更のみがスキャンされます。

### サポートされている言語 {#supported-languages}

{{< history >}}

- GitLab 18.6でC#バージョンのサポートが[10.0から13.0に増加](https://gitlab.com/gitlab-org/gitlab/-/issues/570499)しました。

{{< /history >}}

GitLab高度なSASTは、クロスファンクション、クロスファイルのテイント解析で次の言語をサポートしています。

- C#（13.0まで）
- C/C++<sup>1</sup>
- Go
- Java（Java Server Pages（JSP）を含む）
- JavaScript、TypeScript
- PHP
- Python
- Ruby

**脚注**: 

1. GitLab高度なSASTで使用するには、GitLab高度なSAST CPPには追加の設定（コンパイルデータベースなど）が必要です。詳細については、[C/C++設定](cpp_advanced_sast.md)を参照してください。GitLab高度なSAST CPPは、C/C++プロジェクトのSemgrepを除外しません。両方のアナライザーが異なるルールセットで並行して実行されます。

### PHPの既知の問題 {#php-known-issues}

PHPコードの分析時、GitLab高度なSASTには次の制限があります。

- **動的なファイルインクルード**: ファイルパスに変数を使用する動的なファイルインクルードステートメント(`include`、`include_once`、`require`、`require_once`)は、このリリースではサポートされていません。クロスファイル分析では、静的なファイルインクルードパスのみがサポートされます。[イシュー527341](https://gitlab.com/gitlab-org/gitlab/-/issues/527341)を参照してください。
- **大文字と小文字の区別**: 関数名、クラス名、およびメソッド名について大文字と小文字を区別しないPHPの特性は、クロスファイル分析では完全にはサポートされていません。[イシュー526528](https://gitlab.com/gitlab-org/gitlab/-/issues/526528)を参照してください。

## 設定 {#configuration}

次の変数を使用して、GitLab高度なSASTの動作を調整できます:

| CI/CD変数                          | デフォルト  | 説明                                                                         |
|-----------------------------------------|----------|-------------------------------------------------------------------------------------|
| `GITLAB_ADVANCED_SAST_ENABLED`          | `false`  | CおよびC++を除く、サポートされているすべての言語に対して、GitLab高度なSASTスキャンを有効にします。 |
| `GITLAB_ADVANCED_SAST_CPP_ENABLED`      | `false`  | 特にCおよびC++プロジェクトに対して、GitLab高度なSASTスキャンを有効にします。          |
| `GITLAB_ADVANCED_SAST_RULE_TIMEOUT`     | `30`     | ファイルごとのルールごとのタイムアウト（秒単位）。超過すると、その分析はスキップされます。      |

高度なSASTスキャンはデフォルトで無効になっています。より高いレベル（グループレベルなど）で有効になっている場合に明示的に無効にするには、`GITLAB_ADVANCED_SAST_ENABLED`（C/C++プロジェクトの場合は`GITLAB_ADVANCED_SAST_CPP_ENABLED`）を`false`に設定します。

## GitLab高度なSASTをカスタマイズする {#customize-gitlab-advanced-sast}

他のアナライザーと同様に、GitLab高度なSASTルールを無効にしたり、そのメタデータを編集したりできます。詳細については、[ルールセットのカスタマイズ](customize_rulesets.md#replace-or-add-to-the-default-rules)を参照してください。

## GitLab高度なSASTで、LGPLライセンスコンポーネントのソースコードをリクエストする {#request-source-code-of-lgpl-licensed-components-in-gitlab-advanced-sast}

GitLab高度なSASTで、LGPLライセンスコンポーネントのソースコードに関する情報をリクエストするには、[GitLabサポート](https://about.gitlab.com/support/)にお問い合わせください。

迅速な対応を確保するために、リクエストにGitLab高度なSASTアナライザーのバージョンを含めてください。

この機能はUltimateプランでのみ利用できるため、そのレベルのサポート資格を持つ組織と関連している必要があります。

## フィードバック {#feedback}

専用の[イシュー466322](https://gitlab.com/gitlab-org/gitlab/-/issues/466322)にフィードバックをお寄せください。

## トラブルシューティング {#troubleshooting}

GitLab高度なSASTを使用する場合、次の問題が発生する可能性があります。

### 高度なSASTスキャンの実行時間が予想より長い {#advanced-sast-scan-running-longer-than-expected}

最適化の手順に従っても、高度なSASTスキャンの実行時間が予想より長い場合は、次の情報とともにGitLabサポートにお問い合わせください:

- [GitLab高度なSASTアナライザーのバージョン](#identify-the-gitlab-advanced-sast-analyzer-version)
- リポジトリで使用しているプログラミング言語
- [デバッグログ](../troubleshooting_application_security.md#debug-level-logging)
- [パフォーマンスのデバッグアーティファクト](#generate-a-performance-debugging-artifact)

#### GitLab高度なSASTアナライザーのバージョンを特定する {#identify-the-gitlab-advanced-sast-analyzer-version}

GitLab高度なSASTアナライザーのバージョンを特定するには、次の手順に従ってください。

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **ビルド** > **ジョブ**を選択します。
1. `gitlab-advanced-sast`ジョブを見つけます。
1. ジョブの出力で、文字列`GitLab GitLab Advanced SAST analyzer`を検索します。

その文字列を含む行の末尾にバージョンがあります。例: 

```plaintext
[INFO] [GitLab Advanced SAST] [2025-01-24T15:51:03Z] ▶ GitLab GitLab Advanced SAST analyzer v1.1.1
```

この例では、バージョンは`1.1.1`です。

#### パフォーマンスのデバッグアーティファクトを生成する {#generate-a-performance-debugging-artifact}

`trace.ctf`アーティファクト（非C/C++プロジェクトの場合）を生成するには、`.gitlab-ci.yml`に以下を追加します。

アーティファクトをアップロードする時間を確保するために、`RUNNER_SCRIPT_TIMEOUT`を、`timeout`よりも少なくとも10分短く設定します。

```yaml
include:
  - template: Jobs/SAST.gitlab-ci.yml

variables:
  GITLAB_ADVANCED_SAST_ENABLED: 'true'
  MEMTRACE: 'trace.ctf'
  DISABLE_MULTI_CORE: true # Disable multi core when collecting memtrace

gitlab-advanced-sast:
  artifacts:
    paths:
      - '**/trace.ctf'  # Collects all trace.ctf files generated by this job
    expire_in: 1 week   # Sets retention for artifacts
    when: always        # Ensures artifact export even if the job fails
  variables:
    RUNNER_SCRIPT_TIMEOUT: 50m
  timeout: 1h
```
