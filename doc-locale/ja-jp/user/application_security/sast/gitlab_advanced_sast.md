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
- GitLab 18.6でC/C++のサポートが[追加](https://gitlab.com/groups/gitlab-org/-/epics/14271)されました。

{{< /history >}}

GitLab高度なSASTは、クロスファンクション、クロスファイルのテイント解析を実行して脆弱性を検出するように設計された静的アプリケーションセキュリティテスト（SAST）アナライザーです。

GitLab高度なSASTは、オプトイン機能です。有効にすると、GitLab高度なSASTのアナライザーは、GitLabの高度なSASTの定義済みルールセットを使用して、サポートされている言語のすべてのファイルをスキャンします。Semgrepアナライザーはこれらのファイルをスキャンしません。

GitLab高度なSASTのアナライザーによって識別されたすべての脆弱性が報告されます。これには、以前にSemgrepベースのアナライザーによって報告された脆弱性も含まれます。自動[移行プロセス](#transitioning-from-semgrep-to-gitlab-advanced-sast)では、GitLab高度なSASTがSemgrepベースのアナライザーと同じ場所で同じタイプの脆弱性を見つけた場合、発見が重複排除されます。

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i> GitLab高度なSASTの概要とその仕組みについては、[GitLab Advanced SAST: Accelerating Vulnerability Resolution](https://youtu.be/xDa1MHOcyn8)（GitLab高度なSAST: 脆弱性の修正を加速する）を参照してください。

製品ツアーについては、[GitLab高度なSAST製品ツアー](https://gitlab.navattic.com/advanced-sast)をご覧ください。

## 機能比較 {#feature-comparison}

| 機能                                                                      | SAST                                                                                                                                      | 高度なSAST                                                                                                                               |
|------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------|
| 分析の深さ                                                            | 複雑な脆弱性を検出する機能が制限されています。分析は単一のファイル、および単一の関数（限定的な例外はあります）に限定されます。 | クロスファイル、クロスファンクションのテイント解析を使用して、複雑な脆弱性を検出します。                                                            |
| 精度                                                                     | コンテキストが限られているため、誤検出の結果が生じる可能性が高くなります。                                                                      | クロスファイル、クロスファンクションのテイント解析を使用して、真に悪用可能な脆弱性に焦点を当てることで、誤検出の結果を減らします。      |
| 修正ガイダンス                                                         | 脆弱性の検出結果は行番号で識別されます。                                                                                     | 詳細な[コードフロービュー](#vulnerability-code-flow)は、脆弱性がプログラム全体にどのように流れるかを示し、迅速な修正を可能にします。 |
| GitLab Duo脆弱性の説明と脆弱性の修正に対応 | はい。                                                                                                                                      | はい。                                                                                                                                        |
| 言語カバレッジ                                                            | [より広範にカバーします](_index.md#supported-languages-and-frameworks)。                                                                            | [より限定的です](#supported-languages)。                                                                                                       |

## 脆弱性が報告されるタイミング {#when-vulnerabilities-are-reported}

GitLab高度なSASTは、テイント解析によるクロスファイル、クロスファンクションスキャンを使用して、ユーザー入力のプログラムへの流れを追跡します。アナライザーは、ユーザー入力が流れるパスを追跡し、信頼できないデータが安全でない方法でアプリケーションの実行に影響を与える可能性のある、潜在的なポイントを識別します。これにより、SQLインジェクションやクロスサイトスクリプティング（XSS）といったインジェクションの脆弱性が複数の関数やファイルにまたがって存在していても、確実に検出できます。

ノイズを最小限に抑えるために、GitLab高度なSASTは、信頼できないユーザー入力ソースを機密性の高いシンクに持ち込む検証可能なフローが存在する場合にのみ、テイントベースの脆弱性を報告します。他の製品の場合、検証が甘い脆弱性が報告される場合があります。

GitLab高度なSASTは、HTTPリクエストから取得された値など、信頼境界を越える入力に重点を置いて調整されています。信頼できない入力ソースのセットには、コマンドライン引数、環境変数、またはプログラムを操作するユーザーによって通常提供されるその他の入力は含まれません。

GitLabの高度な静的アプリケーションセキュリティテストが検出する脆弱性の種類の詳細については、[GitLab高度なSASTのCWEカバレッジ](advanced_sast_coverage.md)を参照してください。

## SemgrepからGitLab高度なSASTへの移行 {#transitioning-from-semgrep-to-gitlab-advanced-sast}

SemgrepからGitLab高度なSASTに移行すると、自動移行プロセスにより、脆弱性が重複排除されます。このプロセスでは、以前に検出されたSemgrepの脆弱性を対応するGitLab高度なSASTの発見にリンクし、一致するものが見つかった場合に置き換えます。

### 脆弱性の移行の仕組み {#how-vulnerability-transition-works}

**デフォルトブランチ**で高度なSASTスキャンを有効にした後（[GitLab高度なSASTスキャンを有効にする](#enable-gitlab-advanced-sast-scanning)を参照）、スキャンが実行されて脆弱性が検出されると、次の条件に基づいて、既存のSemgrepの脆弱性を置き換える必要があるかどうかがチェックされます。

#### 重複排除の条件 {#conditions-for-deduplication}

1. **Matching Identifier**（識別子の照合）:
   - GitLab高度なSASTの少なくとも1つの脆弱性識別子（CWEとOWASPを除く）が、既存のSemgrep脆弱性の**primary identifier**（プライマリ識別子）と一致する必要があります。
   - プライマリ識別子は、[SASTレポート](_index.md#download-a-sast-report)内にある脆弱性の識別子配列の最初の識別子です。
   - たとえば、GitLab高度なSASTの脆弱性に`bandit.B506`などの識別子があり、Semgrepの脆弱性のプライマリ識別子も`bandit.B506`である場合、この条件は満たされます。

1. **Matching Location**（場所の照合）:
   - 脆弱性は、コード内の**same location**（同じ場所）に関連付けられている必要があります。これは、[SASTレポート](_index.md#download-a-sast-report)内にある脆弱性の次のいずれかのフィールドを使用して判別されます:
     - 追跡フィールド（存在する場合）
     - 場所フィールド（追跡フィールドが存在しない場合）

### 脆弱性の変更 {#changes-to-the-vulnerability}

条件が満たされると、Semgrepの既存の脆弱性はGitLab高度なSASTの脆弱性に変換されます。この更新された脆弱性は、次の変更を加えて[脆弱性レポート](../vulnerability_report/_index.md)に表示されます:

- スキャナーの種類がSemgrepからGitLab高度なSASTに更新されます。
- GitLab高度なSASTの脆弱性に存在する追加の識別子が、既存の脆弱性に追加されます。
- 脆弱性のそれ以外の詳細は変更されません。

### 重複した脆弱性の処理 {#handling-duplicated-vulnerabilities}

[重複排除の条件](#conditions-for-deduplication)が満たされない場合、Semgrepの脆弱性が重複としてそのまま表示されることがあります。[脆弱性レポート](../vulnerability_report/_index.md)でこれを解決するには、次の手順に従います:

1. 高度なSASTスキャナーで[脆弱性をフィルタリング](../vulnerability_report/_index.md#filtering-vulnerabilities)し、[結果をCSV形式でエクスポート](../vulnerability_report/_index.md#export-details)します。
1. Semgrepスキャナーで[脆弱性をフィルタリング](../vulnerability_report/_index.md#filtering-vulnerabilities)します。これらは、重複排除されなかった脆弱性である可能性があります。
1. Semgrepの脆弱性ごとに、エクスポートされた高度なSASTの結果に対応する一致があるかどうかを確認します。
1. 重複が存在する場合は、Semgrepの脆弱性を適切に解決します。

## コードカバレッジ {#code-coverage}

デフォルトでは、GitLab高度なSASTは、サポートされている言語のすべてのソースコードを解析します。

GitLab高度なSASTの差分ベーススキャンオプションを有効にすると、マージリクエストパイプラインでのスキャンの時間を短縮できます。

### サポートされている言語 {#supported-languages}

{{< history >}}

- GitLab 18.6でC# バージョンのサポートが[10.0から13.0に増加](https://gitlab.com/gitlab-org/gitlab/-/issues/570499)しました。

{{< /history >}}

GitLab高度なSASTは、クロスファンクション、クロスファイルのテイント解析で次の言語をサポートしています:

- C# (最大13.0まで)
- C/C++<sup>1</sup>
- Go
- Java（Java Server Pages（JSP）を含む）
- JavaScript、TypeScript
- PHP
- Python
- Ruby

**Footnotes**（脚注）: 

1. C/C++のサポートは現在ベータ版であり、GitLab高度なSASTで使用するには、追加の設定（コンパイルデータベースなど）が必要です。詳細については、[C/C++ の設定](cpp_advanced_sast.md)を参照してください。GitLab高度なSAST CPPは、C/C++プロジェクトのSemgrepを除外しません。両方のアナライザーは、異なるルールセットで並行して実行されます。

### PHPの既知の問題 {#php-known-issues}

PHPコードの分析時、GitLab高度なSASTには次の制限があります:

- **Dynamic file inclusion**（動的なファイルインクルード）: ファイルパスに変数を使用する動的なファイルインクルードステートメント(`include`、`include_once`、`require`、`require_once`)は、このリリースではサポートされていません。クロスファイル分析では、静的なファイルインクルードパスのみがサポートされます。[イシュー527341](https://gitlab.com/gitlab-org/gitlab/-/issues/527341)を参照してください。
- **Case sensitivity**（大文字と小文字の区別）: 関数名、クラス名、およびメソッド名について大文字と小文字を区別しないPHPの特性は、クロスファイル分析では完全にはサポートされていません。[イシュー526528](https://gitlab.com/gitlab-org/gitlab/-/issues/526528)を参照してください。

### マージリクエストの差分ベーススキャン {#diff-based-scanning-in-merge-requests}

{{< history >}}

- GitLab 18.5で、`vulnerability_partial_scans`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/groups/gitlab-org/-/epics/16790)されました。デフォルトでは無効になっています。
- GitLab 18.5の[GitLab.comで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/552051)になりました。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

{{< /alert >}}

差分ベーススキャンでは、マージリクエストで変更されたファイルと、それらに依存するファイルのみが解析されます。この対象を絞ったアプローチにより、スキャン時間が短縮され、開発中に迅速なフィードバックが得られます。

カバレッジを完全にするため、マージリクエストがマージされた後、デフォルトブランチでフルスキャンが実行されます。

差分ベーススキャンが有効になっている場合:

- マージリクエストで変更または追加されたファイルと、それらに依存するファイルのみが、マージリクエストパイプラインでスキャンされます。
- 有効になっている場合、ジョブジョブログに次のように出力されます: `Running differential scan`無効になっている場合は、`Running full scan`と出力されます
- **merge request security widget**（マージリクエストセキュリティウィジェット）の専用の**差分ベース**タブに関連するスキャン結果が表示されます。
- **Pipeline Security**（パイプラインセキュリティ）タブでは、**Partial SAST report**（部分的なSASTレポート）というラベルの付いたアラートは、部分的な結果のみが含まれていることを示します。

#### 前提要件 {#prerequisites}

GitLab高度なSASTは、[マージリクエストパイプライン](../detect/security_configuration.md#use-security-scanning-tools-with-merge-request-pipelines)で実行するように設定されています。

#### 差分ベーススキャンの設定 {#configure-diff-based-scanning}

マージリクエストパイプラインで差分ベーススキャンを有効にするには、プロジェクトのCI/CD設定ファイル、またはスキャン実行ポリシーまたはパイプライン実行ポリシーのいずれかで、これらのCI/CD変数を設定します。

| 変数                     | 値          | 説明 |
|------------------------------|----------------|-------------|
| `ADVANCED_SAST_PARTIAL_SCAN` | `differential` | 差分ベーススキャンモードを有効にします |

#### 依存ファイル {#dependent-files}

変更されたファイルを超えてクロスファイルの脆弱性を見逃さないように、差分ベーススキャンには、直接の依存関係にあるファイルが含まれます。これにより、高速スキャンを維持しながら、誤検出が減りますが、詳細を[以下](#false-negatives-and-positives)で説明するように、より深い依存チェーンでは不正確な結果が生じる可能性があります。

次のファイルがスキャンに含まれます:

- 変更されたファイル（マージリクエストで変更または追加されたファイル）
- 依存ファイル（変更されたファイルをインポートするファイル）

この設計は、変更された関数からそれをインポートする呼び出し元に、汚染されたデータが移動するなど、クロスファイルのデータフローを検出するのに役立ちます。

変更されたファイルによってインポートされたファイルは、通常、変更されたコードの動作やデータフローに影響を与えないため、スキャンされません。

たとえば、ファイルBを変更するマージリクエストについて考えてみます:

- ファイルAがファイルBをインポートする場合、ファイルAとファイルBがスキャンされます。
- ファイルBがファイルCをインポートする場合、ファイルBのみがスキャンされます。

#### 制限事項 {#restrictions}

##### 偽陰性と偽陽性 {#false-negatives-and-positives}

差分ベーススキャンでは、スキャンされたファイル内の完全なコールグラフをキャプチャできないため、脆弱性（偽陰性）が見逃されたり、解決されたものが再浮上したりする可能性があります（偽陽性）。このトレードオフにより、スキャン時間が短縮され、開発中に迅速なフィードバックが得られます。カバレッジを完全にするため、フルスキャンは常にデフォルトブランチで実行されます。

##### 修正された脆弱性はレポートされません {#fixed-vulnerabilities-not-reported}

誤解を招く結果を避けるため、修正された脆弱性は差分ベーススキャンでは除外されます。ファイルのごく一部のみが解析されるため、完全なコールグラフは利用できず、脆弱性が修正されたかどうかを確認することができません。

フルスキャンは、マージ後、常にデフォルトブランチで実行され、そこで修正された脆弱性がレポートされます。

## 設定 {#configuration}

クロスファンクションおよびクロスファイルのテイント解析を実行して、アプリケーションの脆弱性を検出するには、GitLab高度なSASTのアナライザーを有効にします。その後、CI/CD変数を使用してその動作を調整できます。

### 利用可能なCI/CD変数 {#available-cicd-variables}

次のCI/CD変数を使用してGitLab高度なSASTを設定できます。

| CI/CD変数                          | デフォルト  | 説明                                                                         |
|-----------------------------------------|----------|-------------------------------------------------------------------------------------|
| `GITLAB_ADVANCED_SAST_ENABLED`          | `false`  | CおよびC++を除く、サポートされているすべての言語に対してGitLab高度なSASTスキャンを有効にします。 |
| `GITLAB_ADVANCED_SAST_CPP_ENABLED`      | `false`  | CおよびC++プロジェクトに固有のGitLab高度なSASTスキャンを有効にします。          |
| `GITLAB_ADVANCED_SAST_RULE_TIMEOUT`     | `30`     | ファイルごとのルールごとの秒単位のタイムアウト。タイムアウトを超えると、その解析はスキップされます。      |

### 要件 {#requirements}

GitLabの他のSASTアナライザーと同様、GitLab高度なSASTアナライザーにもRunnerとCI/CDパイプラインが必要です。詳細については、[SASTの要件](_index.md#getting-started)を参照してください。

GitLab Self-Managedでは、GitLab高度なSASTをサポートするGitLabバージョンも使用する必要があります:

- 可能な場合は、GitLab 17.4以降を使用する必要があります。GitLab 17.4には、新しいコードフロービュー、脆弱性の重複排除、およびSAST CI/CDテンプレートの追加更新が含まれています。
- [SAST CI/CDテンプレート](_index.md#stable-vs-latest-sast-templates)は、次のリリースでGitLab高度なSASTを含めるように更新されました:
  - GitLab 17.3以降では、安定版テンプレートにGitLab高度なSASTが含まれています。
  - GitLab 17.2以降では、最新テンプレートにGitLab高度なSASTが含まれています。単一のプロジェクトで[最新テンプレートと安定版テンプレート](../detect/security_configuration.md#template-editions)を混在させないでください。
- GitLab高度なSASTには、最低でもバージョン17.1以降が必要です。

### GitLab高度なSASTスキャンを有効にする {#enable-gitlab-advanced-sast-scanning}

GitLab高度なSASTは標準のGitLab SAST CI/CDテンプレートに含まれています。ただし、デフォルトでは有効になっていません。これを有効にするには、CI/CD変数`GITLAB_ADVANCED_SAST_ENABLED`を`true`に設定します（C/C++プロジェクトの場合は`GITLAB_ADVANCED_SAST_CPP_ENABLED`を`true`に設定します）。CI/CD設定の管理方法に応じて、この変数をさまざまな方法で設定できます。

#### CI/CDパイプライン定義を手動で編集する {#edit-the-cicd-pipeline-definition-manually}

プロジェクトでGitLab SASTスキャンをすでに有効にしている場合は、CI/CD変数を追加してGitLab高度なSASTを有効にします。

この最小限のYAMLファイルには、[安定版SASTテンプレート](_index.md#stable-vs-latest-sast-templates)が含まれており、C/C++以外のプロジェクトでGitLab高度なSASTが有効になっています:

```yaml
include:
  - template: Jobs/SAST.gitlab-ci.yml

variables:
  GITLAB_ADVANCED_SAST_ENABLED: 'true'
```

C/C++プロジェクトの場合は、代わりに`GITLAB_ADVANCED_SAST_CPP_ENABLED`を使用してください。

#### スキャン実行ポリシーで適用する {#enforce-it-in-a-scan-execution-policy}

[スキャン実行ポリシー](../policies/scan_execution_policies.md)でGitLab高度なSASTを有効にするには、ポリシーのスキャンアクションを更新して、CI/CD変数`GITLAB_ADVANCED_SAST_ENABLED`（C/C++プロジェクトの場合は`GITLAB_ADVANCED_SAST_CPP_ENABLED`）を`true`に設定します。この変数は次の方法で設定できます:

- [ポリシーエディタ](../policies/scan_execution_policies.md#scan-execution-policy-editor)のメニューから選択します。
- スキャンアクションで、[`variables`オブジェクト](../policies/scan_execution_policies.md#scan-action-type)に追加します。

#### パイプラインエディタを使用する {#by-using-the-pipeline-editor}

パイプラインエディタを使用してGitLab高度なSASTを有効にするには、次の手順に従います:

1. プロジェクトで、**ビルド** > **パイプラインエディタ**を選択します。
1. `.gitlab-ci.yml`ファイルが存在しない場合は、**パイプラインの設定**を選択し、例のコンテンツを削除します。
1. CI/CD設定を次のように更新します:
   - GitLab管理の[SAST CI/CDテンプレート](_index.md#stable-vs-latest-sast-templates)のいずれかが[まだ含まれていない](_index.md#configure-sast-in-your-cicd-yaml)場合は、それを含めます。
       - GitLab 17.3以降では、安定版テンプレート`Jobs/SAST.gitlab-ci.yml`を使用する必要があります。
       - GitLab 17.2では、GitLab高度なSASTは最新テンプレート`Jobs/SAST.latest.gitlab-ci.yml`でのみ使用できます。単一のプロジェクトで[最新テンプレートと安定版テンプレート](../detect/security_configuration.md#template-editions)を混在させないでください。
       - GitLab 17.1では、GitLab高度なSASTのジョブの内容をCI/CDパイプライン定義に手動でコピーする必要があります。
   - CI/CD変数`GITLAB_ADVANCED_SAST_ENABLED`（C/C++プロジェクトの場合は`GITLAB_ADVANCED_SAST_CPP_ENABLED`）を`true`に設定します。

   [最小限のYAMLの例](#edit-the-cicd-pipeline-definition-manually)を参照してください。
1. **検証**タブを選択し、**パイプラインの検証**を選択します。

   **シミュレーションが正常に完了しました**というメッセージは、ファイルが有効であることを裏付けています。
1. **編集**タブを選択します。
1. フィールドに入力します。**ブランチ**フィールドにデフォルトブランチを使用しないでください。
1. **Start a new merge request with these changes**（これらの変更で新しいマージリクエストを開始）チェックボックスをオンにし、**変更をコミットする**を選択します。
1. 標準のワークフローに従ってフィールドに入力し、**マージリクエストを作成**を選択します。
1. 標準のワークフローに従ってマージリクエストをレビューおよび編集し、**マージ**を選択します。

パイプラインにGitLab高度なSASTジョブが含まれるようになりました。

### GitLab高度なSASTスキャンを無効にする {#disable-gitlab-advanced-sast-scanning}

高度なSASTスキャンはデフォルトでは有効になっていませんが、グループレベルで、または複数のプロジェクトに影響を与える別の方法で有効になっている場合があります。

プロジェクトで高度なSASTスキャンを明示的に無効にするには、CI/CD変数`GITLAB_ADVANCED_SAST_ENABLED`（C/C++プロジェクトの場合は`GITLAB_ADVANCED_SAST_CPP_ENABLED`）を`false`に設定します。この変数は、[高度なSASTスキャンを有効にする](#enable-gitlab-advanced-sast-scanning)のと同じ方法を含め、CI/CD変数を設定できる場所ならどこでも設定できます。

## 脆弱性コードフロー {#vulnerability-code-flow}

{{< history >}}

- GitLab 17.3で、[いくつかの機能フラグ](../../../administration/feature_flags/_index.md)とともに導入されました。デフォルトでは有効になっています。
- GitLab 17.7のGitLab Self-ManagedおよびGitLab Dedicatedで有効になりました。
- GitLab 17.7で一般提供になりました。すべての機能フラグが削除されました。

{{< /history >}}

特定の種類の脆弱性について、GitLab高度なSASTはコードフロー情報を提供します。脆弱性のコードフローとは、データが、すべての割り当て、操作、サニタイズを通じて、ユーザー入力（ソース）から脆弱なコード行（シンク）に至るまでの間でたどるパスです。この情報は、脆弱性のコンテキスト、影響、およびリスクを理解して評価するのに役立ちます。入力をソースからシンクまでトレースすることで検出された脆弱性のコードフロー情報を利用できます。この脆弱性には、以下が含まれます:

- SQLインジェクション
- コマンドインジェクション
- クロスサイトスクリプティング（XSS）
- パストラバーサル

コードフロー情報は**コードフロー**タブに表示され、以下が含まれています:

- ソースからシンクまでのステップ。
- コードスニペットを含む、関連ファイル。

![2つのファイルにまたがるPythonアプリケーションのコードフロー](img/code_flow_view_v17_7.png)

## GitLab高度なSASTをカスタマイズする {#customize-gitlab-advanced-sast}

他のアナライザーと同様に、GitLab高度なSASTルールを無効にしたり、そのメタデータを編集したりできます。詳細については、[ルールセットをカスタマイズする](customize_rulesets.md#disable-predefined-gitlab-advanced-sast-rules)を参照してください。

## GitLab高度なSASTで、LGPLライセンスコンポーネントのソースコードをリクエストする {#request-source-code-of-lgpl-licensed-components-in-gitlab-advanced-sast}

GitLab高度なSASTで、LGPLライセンスコンポーネントのソースコードに関する情報をリクエストするには、[GitLabサポート](https://about.gitlab.com/support/)にお問い合わせください。

迅速な対応を確保するために、リクエストにGitLab高度なSASTアナライザーのバージョンを含めてください。

この機能はUltimateプランでのみ利用できるため、そのレベルのサポート資格を持つ組織と関連している必要があります。

## フィードバック {#feedback}

専用の[イシュー466322](https://gitlab.com/gitlab-org/gitlab/-/issues/466322)にフィードバックをお寄せください。

## トラブルシューティング {#troubleshooting}

GitLab高度なSASTを使用する場合、次の問題が発生する可能性があります。

### 高度なSASTによるスキャンの低速化またはタイムアウト {#slow-scans-or-timeouts-with-advanced-sast}

[高度なSAST](gitlab_advanced_sast.md)ではプログラムを詳細にスキャンするため、特に大規模なリポジトリの場合、スキャンの完了に時間がかかることがあります。パフォーマンスの問題が発生している場合は、ここに記載されている推奨事項に従ってください。

#### ファイルを除外してスキャン時間を短縮する {#reduce-scan-time-by-excluding-files}

各ファイルは適用可能なすべてのルールに照らして分析されるため、スキャンするファイルの数を減らしてスキャン時間を短縮できます。これを行うには、[SAST_EXCLUDED_PATHS](_index.md#vulnerability-filters)変数を使用して、スキャンする必要のないフォルダーを除外します。さまざまな効果的な除外があり、以下が含まれる場合があります:

- データベースの移行
- 単体テスト
- `node_modules/`などの依存関係のディレクトリ
- ビルドディレクトリ

#### マルチコアスキャンによりスキャンを最適化する {#optimize-scans-with-multi-core-scanning}

マルチコアスキャンは、高度なSAST（アナライザーバージョンv1.1.10以降）でデフォルトで有効になっています。Runnerのサイズを大きくして、スキャンに使用できるリソースを増やすことができます。セルフホストRunnerの場合は、[セキュリティスキャナーの設定](_index.md#security-scanner-configuration)で`--multi-core`フラグをカスタマイズする必要がある場合があります。

#### 差分ベーススキャンを使用してパフォーマンスを向上させる {#use-diff-based-scanning-to-improve-performance}

コードベース全体をスキャンする代わりに、マージリクエストで変更されたファイルとその直接の依存関係にあるファイルのみを解析することにより、スキャン時間を短縮するために、マージリクエストで[差分ベーススキャン](#diff-based-scanning-in-merge-requests)を有効にすることを検討してください。

#### サポートを求める場合 {#when-to-seek-support}

これらの最適化手順に従っても、高度なSASTスキャンの実行に予想以上に時間がかかる場合は、次の情報を用意してGitLabサポートにお問い合わせください:

- [GitLab高度なSASTアナライザーのバージョン](#identify-the-gitlab-advanced-sast-analyzer-version)
- リポジトリで使用しているプログラミング言語
- [デバッグログ](../troubleshooting_application_security.md#debug-level-logging)
- [パフォーマンスのデバッグアーティファクト](#generate-a-performance-debugging-artifact)

##### GitLab高度なSASTアナライザーのバージョンを特定する {#identify-the-gitlab-advanced-sast-analyzer-version}

GitLab高度なSASTアナライザーのバージョンを特定するには、次の手順に従ってください:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。[新しいナビゲーションをオンにした](../../interface_redesign.md#turn-new-navigation-on-or-off)場合、このフィールドは上部のバーにあります。
1. **ビルド** > **ジョブ**を選択します。
1. `gitlab-advanced-sast`ジョブを見つけます。
1. ジョブの出力で、文字列`GitLab GitLab Advanced SAST analyzer`を検索します。

その文字列を含む行の末尾にバージョンがあります。次に例を示します:

```plaintext
[INFO] [GitLab Advanced SAST] [2025-01-24T15:51:03Z] ▶ GitLab GitLab Advanced SAST analyzer v1.1.1
```

この例では、バージョンは`1.1.1`です。

##### パフォーマンスのデバッグアーティファクトを生成する {#generate-a-performance-debugging-artifact}

`trace.ctf`アーティファクト（非C/C++プロジェクト）を生成するには、次の`.gitlab-ci.yml`を追加します。

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
