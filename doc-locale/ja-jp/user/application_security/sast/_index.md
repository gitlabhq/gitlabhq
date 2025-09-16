---
stage: Application Security Testing
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 静的アプリケーションセキュリティテスト（SAST）
description: スキャン、設定、アナライザー、脆弱性、レポート作成、カスタマイズ、インテグレーション
---

<style>
table.sast-table tr:nth-child(even) {
    background-color: transparent;
}

table.sast-table td {
    border-left: 1px solid #dbdbdb;
    border-right: 1px solid #dbdbdb;
    border-bottom: 1px solid #dbdbdb;
}

table.sast-table tr td:first-child {
    border-left: 0;
}

table.sast-table tr td:last-child {
    border-right: 0;
}

table.sast-table ul {
    font-size: 1em;
    list-style-type: none;
    padding-left: 0px;
    margin-bottom: 0px;
}

table.no-vertical-table-lines td {
    border-left: none;
    border-right: none;
    border-bottom: 1px solid #f0f0f0;
}

table.no-vertical-table-lines tr {
    border-top: none;
}
</style>

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

静的アプリケーションセキュリティテスト（SAST）では、本番環境に移行する前にソースコードの脆弱性を検出します。CI/CDパイプラインに直接統合されたSASTは、修正が最も簡単で費用対効果の高い開発中にセキュリティ上の問題を特定します。

開発の後期段階でセキュリティの脆弱性が発見されると、コストのかかる遅延や潜在的なセキュリティ侵害が発生する可能性があります。SASTスキャンはコミットごとに自動的に実行されるため、ワークフローを中断することなく、すぐにフィードバックを得られます。

## 機能 {#features}

次の表に、各機能が利用可能なGitLabのプランを示します。

| 機能                                                                                  | FreeおよびPremium                    | Ultimate |
|:-----------------------------------------------------------------------------------------|:-------------------------------------|:------------|
| [オープンソースアナライザー](#supported-languages-and-frameworks)による基本的なスキャン         | {{< icon name="check-circle" >}} 対応 | {{< icon name="check-circle" >}} 対応 |
| ダウンロード可能な[SAST JSONレポート](#download-a-sast-report)                                 | {{< icon name="check-circle" >}} 対応 | {{< icon name="check-circle" >}} 対応 |
| [GitLab高度なSAST](gitlab_advanced_sast.md)によるクロスファイルスキャン、クロスファンクションスキャン | {{< icon name="dotted-circle" >}} 非対応 | {{< icon name="check-circle" >}} 対応 |
| [マージリクエストウィジェット](#merge-request-widget)での新しい発見                            | {{< icon name="dotted-circle" >}} 非対応 | {{< icon name="check-circle" >}} 対応 |
| [マージリクエストの変更ビュー](#merge-request-changes-view)での新しい発見                | {{< icon name="dotted-circle" >}} 非対応 | {{< icon name="check-circle" >}} 対応 |
| [脆弱性管理](../vulnerabilities/_index.md)                                 | {{< icon name="dotted-circle" >}} 非対応 | {{< icon name="check-circle" >}} 対応 |
| [UIベースのスキャナー設定](#configure-sast-by-using-the-ui)                        | {{< icon name="dotted-circle" >}} 非対応 | {{< icon name="check-circle" >}} 対応 |
| [ルールセットのカスタマイズ](customize_rulesets.md)                                           | {{< icon name="dotted-circle" >}} 非対応 | {{< icon name="check-circle" >}} 対応 |
| [高度な脆弱性追跡](#advanced-vulnerability-tracking)                      | {{< icon name="dotted-circle" >}} 非対応 | {{< icon name="check-circle" >}} 対応 |

## はじめに {#getting-started}

SASTを初めて使用する場合は、次の手順に従ってプロジェクトのSASTを有効にする方法を確認してください。

前提要件:

- [`docker`](https://docs.gitlab.com/runner/executors/docker.html)または[`kubernetes`](https://docs.gitlab.com/runner/install/kubernetes.html) executorを備えたLinuxベースのGitLab Runner。GitLab.comのためにホストされたRunnerを使用している場合は、デフォルトで有効になっています。
  - Windows Runnerはサポートされていません。
  - amd64以外のCPUアーキテクチャはサポートされていません。
- GitLab CI/CD設定（`.gitlab-ci.yml`）には、`test`ステージを含める必要がありますが、これはデフォルトで含まれています。`.gitlab-ci.yml`ファイルでステージを再定義する場合は、`test`ステージが必要です。

SASTを有効にするには、次の手順に従います。

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. プロジェクトにまだ`.gitlab-ci.yml`ファイルがない場合は、ルートディレクトリに作成します。
1. `.gitlab-ci.yml`ファイルの先頭に、次のいずれかの行を追加します。

テンプレートを使用:

```yaml
include:
  - template: Jobs/SAST.gitlab-ci.yml
```

または、CIコンポーネントを使用:

```yaml
include:
  - component: gitlab.com/components/sast/sast@main
```

この時点で、SASTがパイプラインで有効になります。サポートされているソースコードが存在する場合、パイプラインの実行時に、適切なアナライザーとデフォルトルールにより、脆弱性のスキャンが自動的に行われます。対応するジョブは、パイプラインの`test`ステージの下に表示されます。

{{< alert type="note" >}}

動作例は、[SASTサンプルプロジェクト](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/semgrep/sast-getting-started)で確認できます。

{{< /alert >}}

これらのステップを完了すると、次のことができるようになります。

- [結果の把握](#understanding-the-results)方法について詳しく理解する。
- [最適化のヒント](#optimization)を確認する。
- [幅広いプロジェクトへの展開](#roll-out)を計画する。

その他の設定方法の詳細については、[設定](#configuration)を参照してください。

## 結果を把握する {#understanding-the-results}

パイプラインの脆弱性を確認できます。

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 左側のサイドバーで、**ビルド > パイプライン**を選択します。
1. パイプラインを選択します。
1. **セキュリティ**タブを選択します。
1. 結果をダウンロードするか、詳細を表示する脆弱性を選択します（Ultimateのみ）。詳細には以下の内容が含まれます。
   - 説明: 脆弱性の原因、潜在的な影響、推奨される修正手順について説明しています。
   - ステータス: 脆弱性がトリアージされたか、解決されたかを示します。
   - 重大度: 影響に基づいて6つのレベルに分類されます。[重大度レベルの詳細はこちらをご覧ください](../vulnerabilities/severities.md)。
   - 場所: 問題が検出されたファイル名と行番号を示します。ファイルパスを選択すると、対応する行がコードビューで開きます。
   - スキャナー: 脆弱性を検出したアナライザーを示します。
   - 識別子: CWEの識別子やそれを検出したルールのIDなど、脆弱性の分類に使用される参照の一覧です。

SASTの脆弱性には、検出された脆弱性の主要なCWE識別子に従って名前が付けられています。スキャナーが検出した特定の問題の詳細については、各脆弱性の発見の説明をお読みください。SASTカバレッジの詳細については、[SASTルール](rules.md)を参照してください。

Ultimateでは、セキュリティスキャンの結果をダウンロードすることもできます。

- パイプラインの**セキュリティ**タブで、**結果をダウンロード**を選択します。

詳細については、[パイプラインセキュリティレポート](../detect/security_scanning_results.md)を参照してください。

{{< alert type="note" >}}

発見がフィーチャーブランチ上に生成されます。その発見がデフォルトブランチにマージされると、脆弱性になります。この区別は、セキュリティ対策状況を評価する上で重要です。

{{< /alert >}}

SASTの結果を確認するその他の方法:

- [マージリクエストウィジェット](#merge-request-widget): 新しく導入された、または解決された発見を示します。
- [マージリクエストの変更ビュー](#merge-request-changes-view): 変更された行のインライン注釈を示します。
- [脆弱性レポート](../vulnerability_report/_index.md): デフォルトブランチで確認された脆弱性を示します。

パイプラインは、SASTやDASTスキャンを含む複数のジョブで構成されています。何らかの理由でジョブが完了しなかった場合、セキュリティダッシュボードにSASTスキャナーの出力は表示されません。たとえば、SASTジョブは完了したがDASTジョブが失敗した場合、セキュリティダッシュボードにSASTの結果は表示されません。失敗すると、アナライザーは終了コードを出力します。

### マージリクエストウィジェット {#merge-request-widget}

{{< details >}}

- プラン: Ultimate

{{< /details >}}

ターゲットブランチからのレポートを比較できる場合、SASTの結果がマージリクエストウィジェット領域に表示されます。マージリクエストウィジェットには以下が表示されます。

- MRによって導入された新しいSASTの発見
- MRによって解決された既存の発見

利用可能な場合は常に、[高度な脆弱性追跡](#advanced-vulnerability-tracking)を使用して結果が比較されます。

![セキュリティマージリクエストウィジェット](img/sast_mr_widget_v16_7.png)

### マージリクエストの変更ビュー {#merge-request-changes-view}

{{< details >}}

- プラン: Ultimate

{{< /details >}}

{{< history >}}

- GitLab 16.6で`sast_reports_in_inline_diff`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/groups/gitlab-org/-/epics/10959)されました。デフォルトでは無効になっています。
- GitLab 16.8でデフォルトで有効になりました。
- GitLab 16.9で[機能フラグは削除](https://gitlab.com/gitlab-org/gitlab/-/issues/410191)されました。

{{< /history >}}

SASTの結果は、マージリクエストの**変更**ビューに表示されます。SASTのイシューを含む行は、ガターの横に記号でマークされます。記号を選択してイシューのリストを表示し、イシューを選択して詳細を表示します。

![SASTインラインインジケーター](img/sast_inline_indicator_v16_7.png)

## 最適化 {#optimization}

要件に応じてSASTを最適化するには、次の操作を実行します。

- ルールを無効にする。
- ファイルまたはパスをスキャンから除外する。

### ルールを無効にする {#disable-a-rule}

たとえば、誤検出が多すぎるためにルールを無効にするには、次の手順に従います。

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. `.gitlab/sast-ruleset.toml`ファイルがまだ存在しない場合は、プロジェクトのルートに作成します。
1. 脆弱性の詳細で、発見をトリガーしたルールのIDを探します。
1. ルールIDを使用して、ルールを無効にします。たとえば、`gosec.G107-1`を無効にするには、`.gitlab/sast-ruleset.toml`に以下を追加します。

   ```yaml
   [semgrep]
     [[semgrep.ruleset]]
       disable = true
       [semgrep.ruleset.identifier]
         type = "semgrep_id"
         value = "gosec.G107-1"
   ```

ルールセットのカスタマイズの詳細については、[ルールセットをカスタマイズする](customize_rulesets.md)を参照してください。

### ファイルまたはパスをスキャンから除外する {#exclude-files-or-paths-from-being-scanned}

テストコードや一時コードなどのファイルまたはパスをスキャンから除外するには、`SAST_EXCLUDED_PATHS`変数を設定します。たとえば、`rule-template-injection.go`をスキップするには、`.gitlab-ci.yml`に以下を追加します。

```yaml
variables:
  SAST_EXCLUDED_PATHS: "rule-template-injection.go"
```

設定オプションの詳細については、[利用可能なCI/CD変数](#available-cicd-variables)を参照してください。

## 展開する {#roll-out}

単一のプロジェクトのSASTの結果に確信が持てたら、その実装を他のプロジェクトに拡張できます。

- [スキャン実行の強制](../detect/security_configuration.md#create-a-shared-configuration)を使用して、グループ全体にSAST設定を適用します。
- [リモート設定ファイルを指定](customize_rulesets.md#specify-a-remote-configuration-file)して、中央ルールセットを共有および再利用します。
- 固有の要件がある場合、SASTは[オフライン環境](#running-sast-in-an-offline-environment)で、または[SELinux](#running-sast-in-selinux)の制約下で実行できます。

## サポートされている言語とフレームワーク {#supported-languages-and-frameworks}

GitLab SASTは、次の言語とフレームワークのスキャンをサポートしています。

利用可能なスキャンオプションは、GitLabのプランによって異なります。

- Ultimateでは、[GitLab高度なSAST](gitlab_advanced_sast.md)のほうがより正確な結果が得られます。サポート対象の言語には、これを使用することをおすすめします。
- 全プランで、オープンソーススキャナーを基にしたGitLab提供のアナライザーを使用して、コードをスキャンできます。

SASTでの言語サポートの計画の詳細については、[カテゴリの方向性に関するページ](https://about.gitlab.com/direction/application_security_testing/static-analysis/sast/#language-support)を参照してください。

| 言語                                             | [GitLab高度なSAST](gitlab_advanced_sast.md)でサポート（Ultimateのみ）                                      | 別の[アナライザー](analyzers.md)でサポート（全プラン） |
|------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------|
| Apex（Salesforce）                                    | {{< icon name="dotted-circle" >}} 非対応                                                                              | {{< icon name="check-circle" >}} 対応: [PMD-Apex](https://gitlab.com/gitlab-org/security-products/analyzers/pmd-apex) |
| C                                                    | {{< icon name="dotted-circle" >}} 非対応。[エピック14271](https://gitlab.com/groups/gitlab-org/-/epics/14271)で追跡 | {{< icon name="check-circle" >}} 対応: [Semgrep](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep)（[GitLab管理ルール](rules.md#semgrep-based-analyzer)を使用） |
| C++                                                  | {{< icon name="dotted-circle" >}} 非対応。[エピック14271](https://gitlab.com/groups/gitlab-org/-/epics/14271)で追跡 | {{< icon name="check-circle" >}} 対応: [Semgrep](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep)（[GitLab管理ルール](rules.md#semgrep-based-analyzer)を使用） |
| C#                                                   | {{< icon name="check-circle" >}} 対応                                                                              | {{< icon name="check-circle" >}} 対応: [Semgrep](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep)（[GitLab管理ルール](rules.md#semgrep-based-analyzer)を使用） |
| Elixir（Phoenix）                                     | {{< icon name="dotted-circle" >}} 非対応                                                                              | {{< icon name="check-circle" >}} 対応: [Sobelow](https://gitlab.com/gitlab-org/security-products/analyzers/sobelow) |
| Go                                                   | {{< icon name="check-circle" >}} 対応                                                                              | {{< icon name="check-circle" >}} 対応: [Semgrep](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep)（[GitLab管理ルール](rules.md#semgrep-based-analyzer)を使用） |
| Groovy                                               | {{< icon name="dotted-circle" >}} 非対応                                                                              | {{< icon name="check-circle" >}} 対応: [SpotBugs](https://gitlab.com/gitlab-org/security-products/analyzers/spotbugs)（find-sec-bugsプラグイン<sup><b><a href="#spotbugs-footnote">1</a></b></sup>を使用） |
| Java                                                 | {{< icon name="check-circle" >}} 対応（Java Server Pages（JSP）を含む）                                           | {{< icon name="check-circle" >}} 対応: [Semgrep](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep)（[GitLab管理ルール](rules.md#semgrep-based-analyzer)を使用）（Androidを含む） |
| JavaScript（Node.js、Reactを含む）              | {{< icon name="check-circle" >}} 対応                                                                              | {{< icon name="check-circle" >}} 対応: [Semgrep](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep)（[GitLab管理ルール](rules.md#semgrep-based-analyzer)を使用） |
| Kotlin                                               | {{< icon name="dotted-circle" >}} 非対応。[エピック15173](https://gitlab.com/groups/gitlab-org/-/epics/15173)で追跡 | {{< icon name="check-circle" >}} 対応: [Semgrep](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep)（[GitLab管理ルール](rules.md#semgrep-based-analyzer)を使用）（Androidを含む） |
| Objective-C（iOS）                                    | {{< icon name="dotted-circle" >}} 非対応                                                                              | {{< icon name="check-circle" >}} 対応: [Semgrep](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep)（[GitLab管理ルール](rules.md#semgrep-based-analyzer)を使用） |
| PHP                                                  | {{< icon name="dotted-circle" >}} 非対応。[エピック14273](https://gitlab.com/groups/gitlab-org/-/epics/14273)で追跡 | {{< icon name="check-circle" >}} 対応: [Semgrep](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep)（[GitLab管理ルール](rules.md#semgrep-based-analyzer)を使用） |
| Python                                               | {{< icon name="check-circle" >}} 対応                                                                              | {{< icon name="check-circle" >}} 対応: [Semgrep](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep)（[GitLab管理ルール](rules.md#semgrep-based-analyzer)を使用） |
| Ruby（Ruby on Railsを含む）                        | {{< icon name="check-circle" >}} 対応                                                                              | {{< icon name="check-circle" >}} 対応: [Semgrep](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep)（[GitLab管理ルール](rules.md#semgrep-based-analyzer)を使用） |
| Scala                                                | {{< icon name="dotted-circle" >}} 非対応。[エピック15174](https://gitlab.com/groups/gitlab-org/-/epics/15174)で追跡 | {{< icon name="check-circle" >}} 対応: [Semgrep](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep)（[GitLab管理ルール](rules.md#semgrep-based-analyzer)を使用） |
| Swift（iOS）                                          | {{< icon name="dotted-circle" >}} 非対応                                                                              | {{< icon name="check-circle" >}} 対応: [Semgrep](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep)（[GitLab管理ルール](rules.md#semgrep-based-analyzer)を使用） |
| TypeScript                                           | {{< icon name="check-circle" >}} 対応                                                                              | {{< icon name="check-circle" >}} 対応: [Semgrep](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep)（[GitLab管理ルール](rules.md#semgrep-based-analyzer)を使用） |
| YAML<sup><b><a href="#yaml-footnote">2</a></b></sup> | {{< icon name="check-circle" >}} 対応                                                                              | {{< icon name="check-circle" >}} 対応: [Semgrep](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep)（[GitLab管理ルール](rules.md#semgrep-based-analyzer)を使用） |
| Java Properties                                      | {{< icon name="check-circle" >}} 対応                                                                              | {{< icon name="check-circle" >}} 対応: [Semgrep](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep)（[GitLab管理ルール](rules.md#semgrep-based-analyzer)を使用） |

**脚注**:

1. <a id="spotbugs-footnote"></a>SpotBugsベースのアナライザーは、[Gradle](https://gradle.org/)、[Maven](https://maven.apache.org/)、[SBT](https://www.scala-sbt.org/)をサポートしています。また、[Gradleラッパー](https://docs.gradle.org/current/userguide/gradle_wrapper.html)、[Grails](https://grails.org/)、[Mavenラッパー](https://github.com/takari/maven-wrapper)などのバリアントでも使用できます。ただし、SpotBugsには、[Ant](https://ant.apache.org/)ベースのプロジェクトで使用する場合、[制限事項](https://gitlab.com/gitlab-org/gitlab/-/issues/350801)があります。AntベースのJavaまたはScalaプロジェクトには、GitLab高度なSASTまたはSemgrepベースのアナライザーを使用する必要があります。
1. <a id="yaml-footnote"></a>`YAML`のサポートは、次のファイルパターンに制限されています。

   - `application*.yml`
   - `application*.yaml`
   - `bootstrap*.yml`
   - `bootstrap*.yaml`

SAST CI/CDテンプレートには、Kubernetes manifestとHelmチャートをスキャンできるアナライザージョブも含まれています。このジョブはデフォルトでオフになっています。[Kubesecアナライザーを有効にする](#enabling-kubesec-analyzer)を参照するか、代わりに、追加のプラットフォームをサポートする[IaCスキャン](../iac_scanning/_index.md)をご検討ください。

サポートされなくなったSASTアナライザーの詳細については、[サポートが終了したアナライザー](analyzers.md#analyzers-that-have-reached-end-of-support)を参照してください。

## 高度な脆弱性追跡 {#advanced-vulnerability-tracking}

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

ソースコードは頻繁に変更されるものです。デベロッパーが変更を加えると、ソースコードがファイル内またはファイル間で移動する可能性があります。セキュリティアナライザーは、[脆弱性レポート](../vulnerability_report/_index.md)で追跡されている脆弱性をすでに報告している可能性があります。これらの脆弱性は、見つけ出して修正できるように、特定の問題のあるコードフラグメントにリンクされています。しかし、コードフラグメントが移動した際に正確に追跡されない場合、同じ脆弱性が再度報告される可能性があるため、脆弱性管理がより困難になります。

GitLab SASTは、高度な脆弱性追跡アルゴリズムを使用して、同じ脆弱性がリファクタリングまたは無関係な変更によってファイル内で移動した場合、より正確に特定します。

高度な脆弱性追跡は、[サポートされている言語](#supported-languages-and-frameworks)と[アナライザー](analyzers.md)の一部で使用できます。

- C（Semgrepベースのみ）
- C++（Semgrepベースのみ）
- C#（GitLab高度なSASTとSemgrepベースのアナライザー）
- Go（GitLab高度なSASTとSemgrepベースのアナライザー）
- Java（GitLab高度なSASTとSemgrepベースのアナライザー）
- JavaScript（GitLab高度なSASTとSemgrepベースのアナライザー）
- PHP（Semgrepベースのアナライザーのみ）
- Python（GitLab高度なSASTとSemgrepベースのアナライザー）
- Ruby（Semgrepベースのアナライザーのみ）

より多くの言語とアナライザーのサポートが、[このエピック](https://gitlab.com/groups/gitlab-org/-/epics/5144)で追跡されています。

詳細については、機密プロジェクト（`https://gitlab.com/gitlab-org/security-products/post-analyzers/tracking-calculator`）を参照してください。このプロジェクトの内容は、GitLabチームメンバーのみが利用できます。

## 脆弱性の自動修正 {#automatic-vulnerability-resolution}

{{< history >}}

- GitLab 15.9でプロジェクトレベルの`sec_mark_dropped_findings_as_resolved`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/368284)されました。
- GitLab 15.10でデフォルトで有効になりました。GitLab.comでプロジェクトのフラグを無効にする必要がある場合は、[サポートにお問い合わせください](https://about.gitlab.com/support/)。
- GitLab 16.2で[機能フラグは削除](https://gitlab.com/gitlab-org/gitlab/-/issues/375128)されました。

{{< /history >}}

関連性の高い脆弱性に集中できるように、GitLab SASTは次の場合に脆弱性を自動的に[解決](../vulnerabilities/_index.md#vulnerability-status-values)します。

- [定義済みルールを無効にする](customize_rulesets.md#disable-predefined-rules)場合
- デフォルトのルールセットからルールを削除する場合

自動解決は、[Semgrepベースのアナライザー](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep)による発見にのみ使用できます。自動的に解決された脆弱性には、脆弱性管理システムがコメントを追加するため、脆弱性の履歴記録が保持されます。

後でルールを再度有効にすると、トリアージのために発見が再度オープンされます。

## サポートされているディストリビューション {#supported-distributions}

デフォルトのスキャナーイメージは、サイズと保守性の観点からAlpineイメージをベースに構築されています。

### FIPS対応イメージ {#fips-enabled-images}

GitLabは、[Red Hat UBI](https://www.redhat.com/en/blog/introducing-red-hat-universal-base-image)ベースイメージに基づき、FIPS 140検証済みの暗号学的モジュールを使用する別バージョンのイメージを提供しています。FIPS対応イメージを使用するには、次のいずれかを実行します。

- `SAST_IMAGE_SUFFIX`を`-fips`に設定します。
- デフォルトのイメージ名に`-fips`拡張子を追加します。

次に例を示します。

```yaml
variables:
  SAST_IMAGE_SUFFIX: '-fips'

include:
  - template: Jobs/SAST.gitlab-ci.yml
```

FIPS準拠のイメージは、GitLab高度なSASTとSemgrepベースのアナライザーでのみ使用できます。

{{< alert type="warning" >}}

FIPS準拠の方法でSASTを使用するには、[他のアナライザーが実行されないように除外](analyzers.md#customize-analyzers)する必要があります。FIPS対応イメージを使用して、[非rootユーザーでRunner](https://docs.gitlab.com/runner/install/kubernetes_helm_chart_configuration.html#run-with-non-root-user)上で高度なSASTまたはSemgrepを実行する場合、`runners.kubernetes.pod_security_context`の`run_as_user`属性を、[イメージによって作成](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep/-/blob/a5d822401014f400b24450c92df93467d5bbc6fd/Dockerfile.fips#L58)される`gitlab`ユーザーのID（`1000`）を使用するように更新する必要があります。

{{< /alert >}}

## SASTレポートをダウンロードする {#download-a-sast-report}

各SASTアナライザーは、ジョブアーティファクトとしてJSONレポートを出力します。このファイルには、検出されたすべての脆弱性の詳細が含まれています。ファイルを[ダウンロード](../../../ci/jobs/job_artifacts.md#download-job-artifacts)して、GitLabの外部で処理できます。

詳細については、以下を参照してください。

- [SASTレポートファイルスキーマ](https://gitlab.com/gitlab-org/security-products/security-report-schemas/-/blob/master/dist/sast-report-format.json)
- [SASTレポートファイルの例](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep/-/blob/main/qa/expect/js/default/gl-sast-report.json)

## 設定 {#configuration}

SASTスキャンは、CI/CDパイプラインで実行されます。GitLab管理のCI/CDテンプレートをパイプラインに追加すると、適切な[SASTアナライザー](analyzers.md)が自動的にコードをスキャンし、結果を[SASTレポートアーティファクト](../../../ci/yaml/artifacts_reports.md#artifactsreportssast)として保存します。

プロジェクトのSASTを設定するには、次のいずれかの方法があります。

- [Auto DevOps](../../../topics/autodevops/_index.md)によって提供される[自動SAST](../../../topics/autodevops/stages.md#auto-sast)を使用する。
- [CI/CD YAMLでSASTを設定](#configure-sast-in-your-cicd-yaml)する。
- [UIを使用してSASTを設定](#configure-sast-by-using-the-ui)する。

[スキャン実行を強制](../detect/security_configuration.md#create-a-shared-configuration)することで、多くのプロジェクトにわたってSASTを有効にできます。

高度なSAST（GitLab Ultimateでのみ利用可能）を設定するには、この[手順](gitlab_advanced_sast.md#configuration)に従ってください。

必要に応じて、[設定変数を変更](_index.md#available-cicd-variables)したり、[検出ルールをカスタマイズ](customize_rulesets.md)したりできますが、GitLab SASTはデフォルト設定で使用するように設計されています。

### CI/CD YAMLでSASTを設定する {#configure-sast-in-your-cicd-yaml}

SASTを有効にするには、[`SAST.gitlab-ci.yml`テンプレート](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/SAST.gitlab-ci.yml)を[含めます](../../../ci/yaml/_index.md#includetemplate)。このテンプレートは、GitLabインストールの一部として提供されます。

次の内容をコピーして、`.gitlab-ci.yml`ファイルの末尾に貼り付けます。`include`行がすでに存在する場合は、その下に`template`行のみを追加します。

```yaml
include:
  - template: Jobs/SAST.gitlab-ci.yml
```

ここで含めたテンプレートは、CI/CDパイプラインにSASTジョブを作成し、プロジェクトのソースコードをスキャンして潜在的な脆弱性を検出します。

結果は[SASTレポートアーティファクト](../../../ci/yaml/artifacts_reports.md#artifactsreportssast)として保存され、後でダウンロードして分析することができます。ダウンロードすると、常に最新のSASTアーティファクトを入手できます。

### 安定版と最新版のSASTテンプレート {#stable-vs-latest-sast-templates}

SASTには、セキュリティテストをCI/CDパイプラインに組み込むためのテンプレートが2つ用意されています。

- [`SAST.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/SAST.gitlab-ci.yml)（推奨）

  安定版テンプレートは、信頼性が高く一貫性のあるSASTエクスペリエンスを提供します。CI/CDパイプラインで安定性と予測可能な動作を必要とするほとんどのユーザーおよびプロジェクトでは、安定版テンプレートを使用する必要があります。

- [`SAST.latest.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/SAST.latest.gitlab-ci.yml)

  このテンプレートは、最先端の機能にアクセスしてテストしたい方を対象としています。安定版とは見なされておらず、次のメジャーリリースで計画されている破壊的な変更が含まれている可能性があります。このテンプレートを使用すると、安定版リリースに組み込まれる前に新機能やアップデートを試すことができるため、潜在的な不安定さをいとわず、新機能に関するフィードバックを積極的に提供したい方に最適です。

### UIを使用してSASTを設定する {#configure-sast-by-using-the-ui}

UIを使用してSASTを有効化および設定できます。設定はデフォルトのままにすることも、カスタマイズすることも可能です。使用できる方法は、GitLabのライセンスプランによって異なります。

#### カスタマイズしてSASTを設定する {#configure-sast-with-customizations}

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 16.2で、UIから個々のSASTアナライザーの設定オプションを[削除](https://gitlab.com/gitlab-org/gitlab/-/issues/410013)しました。

{{< /history >}}

{{< alert type="note" >}}

この設定ツールは、`.gitlab-ci.yml`ファイルが存在しない場合、または最小限の設定ファイルしかない場合に最適です。複雑なGitLab設定ファイルがある場合は、正常に解析されず、エラーが発生する可能性があります。

{{< /alert >}}

カスタマイズしてSASTを有効化および設定するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **セキュリティ > セキュリティ設定**を選択します。
1. プロジェクトのデフォルトブランチに対する最新のパイプラインが完了し、有効な`SAST`アーティファクトが生成された場合は、**SASTを設定**を選択します。それ以外の場合は、静的アプリケーションセキュリティテスト（SAST）行で**SASTを有効にする**を選択します。
1. SASTのカスタム値を入力します。

   カスタム値は`.gitlab-ci.yml`ファイルに保存されます。SASTの設定ページに表示されていないCI/CD変数については、GitLab SASTテンプレートから値が継承されます。
1. **マージリクエストの作成**を選択します。
1. マージリクエストをレビューしてマージします。

これで、パイプラインにSASTジョブが含まれます。

#### デフォルト設定のみでSASTを設定する {#configure-sast-with-default-settings-only}

{{< alert type="note" >}}

この設定ツールは、`.gitlab-ci.yml`ファイルが存在しない場合、または最小限の設定ファイルしかない場合に最適です。複雑なGitLab設定ファイルがある場合は、正常に解析されず、エラーが発生する可能性があります。

{{< /alert >}}

デフォルト設定でSASTを有効化および設定するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **セキュリティ > セキュリティ設定**を選択します。
1. SASTセクションで**マージリクエスト経由で設定**を選択します。
1. マージリクエストをレビューしてマージし、SASTを有効にします。

これで、パイプラインにSASTジョブが含まれます。

### SASTジョブをオーバーライドする {#overriding-sast-jobs}

ジョブ定義をオーバーライドする（`variables`、`dependencies`、[`rules`](../../../ci/yaml/_index.md#rules)のようなプロパティを変更する場合など）には、オーバーライドするSASTジョブと同じ名前でジョブを宣言します。テンプレートの挿入後にこの新しいジョブを配置し、その下に追加のキーを指定します。たとえば、次の設定により、`spotbugs`アナライザーに対して`FAIL_NEVER`を有効にすることができます。

```yaml
include:
  - template: Jobs/SAST.gitlab-ci.yml

spotbugs-sast:
  variables:
    FAIL_NEVER: 1
```

### マイナーイメージバージョンにピン留めする {#pinning-to-minor-image-version}

GitLab管理のCI/CDテンプレートは、メジャーバージョンを指定し、そのメジャーバージョン内の最新のアナライザーリリースを自動的にプルします。

場合によっては、特定のバージョンを使用しなければならないことがあります。たとえば、後のリリースで発生したリグレッションを回避する必要がある場合などです。

自動更新の動作をオーバーライドするには、[`SAST.gitlab-ci.yml`テンプレート](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/SAST.gitlab-ci.yml)を含めた後、CI/CD設定ファイルで`SAST_ANALYZER_IMAGE_TAG` CI/CD変数を設定します。

この変数は、特定のジョブ内でのみ設定してください。[トップレベル](../../../ci/variables/_index.md#define-a-cicd-variable-in-the-gitlab-ciyml-file)で設定すると、設定したバージョンが他のSASTアナライザーにも使用されます。

タグには次のいずれかを設定できます。

- メジャーバージョン（例: `3`）: パイプラインは、このメジャーバージョン内でリリースされるマイナーまたはパッチアップデートを使用します。
- マイナーバージョン（例: `3.7`）: パイプラインは、このマイナーバージョン内でリリースされるパッチアップデートを使用します。
- パッチバージョン（例: `3.7.0`）: パイプラインはアップデートを受け取りません。

次の例では、`semgrep`アナライザーの特定のマイナーバージョンと、`brakeman`アナライザーの特定のパッチバージョンを使用します。

```yaml
include:
  - template: Jobs/SAST.gitlab-ci.yml

semgrep-sast:
  variables:
    SAST_ANALYZER_IMAGE_TAG: "3.7"

brakeman-sast:
  variables:
    SAST_ANALYZER_IMAGE_TAG: "3.1.1"
```

### CI/CD変数を使用してプライベートリポジトリの認証情報を渡す {#using-cicd-variables-to-pass-credentials-for-private-repositories}

一部のアナライザーでは、分析を実行するためにプロジェクトの依存関係をダウンロードする必要があります。一方、そのような依存関係はプライベートGitリポジトリに存在する可能性があり、ダウンロードするにはユーザー名やパスワードなどの認証情報が必要になります。アナライザーによっては、[カスタムCI/CD変数](#custom-cicd-variables)を介してそのような認証情報を渡すことができます。

#### CI/CD変数を使用してプライベートMavenリポジトリにユーザー名とパスワードを渡す {#using-a-cicd-variable-to-pass-username-and-password-to-a-private-maven-repository}

プライベートMavenリポジトリにログイン認証情報が必要な場合は、`MAVEN_CLI_OPTS` CI/CD変数を使用できます。

詳細については、[プライベートMavenリポジトリの使用方法](../dependency_scanning/_index.md#authenticate-with-a-private-maven-repository)を参照してください。

### Kubesecアナライザーを有効にする {#enabling-kubesec-analyzer}

Kubesecアナライザーを有効にするには、`SCAN_KUBERNETES_MANIFESTS`を`"true"`に設定する必要があります。`.gitlab-ci.yml`で、次のように定義します。

```yaml
include:
  - template: Jobs/SAST.gitlab-ci.yml

variables:
  SCAN_KUBERNETES_MANIFESTS: "true"
```

### Semgrepベースのアナライザーで他の言語をスキャンする {#scan-other-languages-with-the-semgrep-based-analyzer}

[Semgrepベースのアナライザー](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep)をカスタマイズして、GitLab管理のルールセットで[サポート](#supported-languages-and-frameworks)されていない言語をスキャンできます。ただし、GitLabではこれらの他の言語に対するルールセットを提供していないため、対応するには[カスタムルールセット](customize_rulesets.md#build-a-custom-configuration)を用意する必要があります。また、関連ファイルが変更されたときにジョブが実行されるように、`semgrep-sast` CI/CDジョブの`rules`も変更する必要もあります。

#### Rustアプリケーションをスキャンする {#scan-a-rust-application}

たとえば、Rustアプリケーションをスキャンするには、次の手順を実行する必要があります。

1. Rust用のカスタムルールセットを提供します。リポジトリのルートにある`.gitlab/`ディレクトリに、`sast-ruleset.toml`という名前のファイルを作成します。次の例では、SemgrepレジストリのRust用デフォルトルールセットを使用しています。

   ```toml
   [semgrep]
     description = "Rust ruleset for Semgrep"
     targetdir = "/sgrules"
     timeout = 60

     [[semgrep.passthrough]]
       type  = "url"
       value = "https://semgrep.dev/c/p/rust"
       target = "rust.yml"
   ```

   詳細については、[ルールセットをカスタマイズする](customize_rulesets.md#build-a-custom-configuration)を参照してください。

1. `semgrep-sast`ジョブをオーバーライドして、Rust（`.rs`）ファイルを検出するルールを追加します。`.gitlab-ci.yml`ファイルで次のように定義します。

   ```yaml
   include:
     - template: Jobs/SAST.gitlab-ci.yml

   semgrep-sast:
     rules:
       - if: $CI_COMMIT_BRANCH
         exists:
           - '**/*.rs'
           # include any other file extensions you need to scan from the semgrep-sast template: Jobs/SAST.gitlab-ci.yml
   ```

### SpotBugsアナライザーのJDK21サポート {#jdk21-support-for-spotbugs-analyzer}

SpotBugsアナライザーのバージョン`6`では、JDK21のサポートが追加され、JDK11のサポートが削除されます。デフォルトのバージョンは、[イシュー517169](https://gitlab.com/gitlab-org/gitlab/-/issues/517169)で説明されているように、引き続きバージョン`5`です。バージョン`6`を使用するには、[マイナーイメージバージョンにピン留めする](#pinning-to-minor-image-version)の手順に従って、手動でバージョンをピン留めします。

```yaml
spotbugs-sast:
  variables:
    SAST_ANALYZER_IMAGE_TAG: "6"
```

### SpotBugsアナライザーでプリコンパイルを使用する {#using-pre-compilation-with-spotbugs-analyzer}

SpotBugsベースのアナライザーは、`Groovy`プロジェクト用にコンパイルされたバイトコードをスキャンします。デフォルトでは、依存関係のフェッチとコードのコンパイルを自動的に試行し、スキャンできるようにします。自動コンパイルは、以下の場合に失敗する可能性があります。

- プロジェクトにカスタムビルド設定が必要な場合
- アナライザーに組み込まれていない言語バージョンを使用している場合

これらの問題を解決するには、アナライザーのコンパイル手順をスキップし、代わりにパイプラインの以前のステージからアーティファクトを直接提供する必要があります。この戦略は、_プリコンパイル_と呼ばれます。

#### プリコンパイルされたアーティファクトを共有する {#sharing-pre-compiled-artifacts}

1. コンパイルジョブ（通常は`build`という名前）を使用してプロジェクトをコンパイルし、[`artifacts: paths`](../../../ci/yaml/_index.md#artifactspaths)を使用して、コンパイルされた出力を`job artifact`として保存します。

   - `Maven`プロジェクトの場合、出力フォルダーは通常、`target`ディレクトリです
   - `Gradle`プロジェクトの場合、出力フォルダーは通常、`build`ディレクトリです
   - プロジェクトでカスタムの出力先を使用する場合は、それに応じてアーティファクトのパスを設定します

1. `spotbugs-sast`ジョブで`COMPILE: "false"` CI/CD変数を設定して、自動コンパイルを無効にします。

1. `dependencies`キーワードを設定して、`spotbugs-sast`ジョブがコンパイルジョブに依存するようにします。これにより、`spotbugs-sast`ジョブは、コンパイルジョブで作成されたアーティファクトをダウンロードして使用できるようになります。

次の例では、Gradleプロジェクトをプリコンパイルし、コンパイルされたバイトコードをアナライザーに提供します。

```yaml
stages:
  - build
  - test

include:
  - template: Jobs/SAST.gitlab-ci.yml

build:
  image: gradle:7.6-jdk8
  stage: build
  script:
    - gradle build
  artifacts:
    paths:
      - build/

spotbugs-sast:
  dependencies:
    - build
  variables:
    COMPILE: "false"
    SECURE_LOG_LEVEL: debug
```

#### 依存関係を指定する（Mavenのみ） {#specifying-dependencies-maven-only}

プロジェクトで、アナライザーによって外部依存関係が認識される必要があり、Mavenを使用している場合は、`MAVEN_REPO_PATH`変数を使用してローカルリポジトリの場所を指定することができます。

依存関係の指定は、Mavenベースのプロジェクトでのみサポートされています。他のビルドツール（Gradleなど）には、依存関係を指定するための同等のメカニズムはありません。その場合は、コンパイルされたアーティファクトに必要なすべての依存関係が含まれていることを確認してください。

次の例では、Mavenプロジェクトをプリコンパイルし、コンパイルされたバイトコードを依存関係とともにアナライザーに提供します。

```yaml
stages:
  - build
  - test

include:
  - template: Jobs/SAST.gitlab-ci.yml

build:
  image: maven:3.6-jdk-8-slim
  stage: build
  script:
    - mvn package -Dmaven.repo.local=./.m2/repository
  artifacts:
    paths:
      - .m2/
      - target/

spotbugs-sast:
  dependencies:
    - build
  variables:
    MAVEN_REPO_PATH: $CI_PROJECT_DIR/.m2/repository
    COMPILE: "false"
    SECURE_LOG_LEVEL: debug
```

### マージリクエストパイプラインでジョブを実行する {#running-jobs-in-merge-request-pipelines}

[マージリクエストパイプラインでセキュリティスキャンツールを使用する](../detect/security_configuration.md#use-security-scanning-tools-with-merge-request-pipelines)を参照してください。

### 利用可能なCI/CD変数 {#available-cicd-variables}

SASTは、`.gitlab-ci.yml`の[`variables`](../../../ci/yaml/_index.md#variables)パラメータを使用して設定できます。

{{< alert type="warning" >}}

GitLabセキュリティスキャンツールのすべてのカスタマイズは、これらの変更をデフォルトブランチにマージする前に、マージリクエストでテストする必要があります。そうしないと、誤検出が多数発生するなど、予期しない結果が生じる可能性があります。

{{< /alert >}}

次の例では、すべてのジョブで`SEARCH_MAX_DEPTH`変数を`10`にオーバーライドするために、SASTテンプレートを含めています。テンプレートはパイプライン設定の[前に評価](../../../ci/yaml/_index.md#include)されるため、変数の最後の記述が優先されます。

```yaml
include:
  - template: Jobs/SAST.gitlab-ci.yml

variables:
  SEARCH_MAX_DEPTH: 10
```

#### カスタム認証局 {#custom-certificate-authority}

カスタム認証局を信頼するには、SAST環境で信頼するCA証明書のバンドルを`ADDITIONAL_CA_CERT_BUNDLE`変数に設定します。`ADDITIONAL_CA_CERT_BUNDLE`の値には、[X.509 PEM公開鍵証明書のテキスト表現](https://www.rfc-editor.org/rfc/rfc7468#section-5.1)が含まれている必要があります。たとえば、`.gitlab-ci.yml`ファイルでこの値を設定するには、以下のように記述します。

```yaml
variables:
  ADDITIONAL_CA_CERT_BUNDLE: |
      -----BEGIN CERTIFICATE-----
      MIIGqTCCBJGgAwIBAgIQI7AVxxVwg2kch4d56XNdDjANBgkqhkiG9w0BAQsFADCB
      ...
      jWgmPqF3vUbZE0EyScetPJquRFRKIesyJuBFMAs=
      -----END CERTIFICATE-----
```

`ADDITIONAL_CA_CERT_BUNDLE`の値は、[UIでカスタム変数](../../../ci/variables/_index.md#for-a-project)として設定することもできます。`file`として設定する場合は証明書のパスを、変数として設定する場合は証明書のテキスト表現を指定します。

#### Dockerイメージ {#docker-images}

以下は、Dockerイメージ関連のCI/CD変数です。

| CI/CD変数            | 説明 |
|---------------------------|-------------|
| `SECURE_ANALYZERS_PREFIX` | デフォルトイメージを提供するDockerレジストリ（プロキシ）の名前をオーバーライドします。詳細については、[アナライザーをカスタマイズする](analyzers.md)を参照してください。 |
| `SAST_EXCLUDED_ANALYZERS` | 実行すべきではないデフォルトイメージの名前。詳細については、[アナライザーをカスタマイズする](analyzers.md)を参照してください。 |
| `SAST_ANALYZER_IMAGE_TAG` | アナライザーイメージのデフォルトバージョンをオーバーライドします。詳細については、[アナライザーイメージバージョンにピン留めする](#pinning-to-minor-image-version)を参照してください。 |
| `SAST_IMAGE_SUFFIX`       | イメージ名に追加されるサフィックス。`-fips`を設定すると、`FIPS-enabled`イメージがスキャンに使用されます。詳細については、[FIPS対応イメージ](#fips-enabled-images)を参照してください。 |

#### 脆弱性フィルター {#vulnerability-filters}

<table class="sast-table">
  <thead>
    <tr>
      <th>CI/CD変数</th>
      <th>説明</th>
      <th>デフォルト値</th>
      <th>アナライザー</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td rowspan="3">
        <code>SAST_EXCLUDED_PATHS</code>
      </td>
      <td rowspan="3">
        脆弱性を除外するためのパスのカンマ区切りリスト。この変数の正確な処理は、使用するアナライザーによって異なります。<sup><b><a href="#sast-excluded-paths-description">1</a></b></sup>
      </td>
      <td rowspan="3">
        <code><a href="https://gitlab.com/gitlab-org/gitlab/blob/v17.3.0-ee/lib/gitlab/ci/templates/Jobs/SAST.gitlab-ci.yml#L13">spec、test、tests、tmp</a></code>
      </td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/semgrep">Semgrep</a><sup><b><a href="#sast-excluded-paths-semgrep">2</a></b>、</sup><sup><b><a href="#sast-excluded-paths-all-other-sast-analyzers">3</a></b></sup>
      </td>
    </tr>
    <tr>
      <td>
        <a href="gitlab_advanced_sast.md">GitLab高度なSAST</a><sup><b><a href="#sast-excluded-paths-semgrep">2</a></b>、</sup><sup><b><a href="#sast-excluded-paths-all-other-sast-analyzers">3</a></b></sup>
      </td>
    </tr>
    <tr>
      <td>
        その他すべてのSASTアナライザー<sup><b><a href="#sast-excluded-paths-all-other-sast-analyzers">3</a></b></sup>
      </td>
    </tr>
    <tr>
      <td>
        <!-- markdownlint-disable MD044 --><code>SAST_SPOTBUGS_EXCLUDED_BUILD_PATHS</code><!-- markdownlint-enable MD044 -->
      </td>
      <td>
        ビルドとスキャンからディレクトリを除外するためのパスのカンマ区切りリスト。
      </td>
      <td>なし</td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/spotbugs">SpotBugs</a><sup><b><a href="#sast-spotbugs-excluded-build-paths-description">4</a></b></sup>
      </td>
    </tr>
    <tr>
      <td rowspan="3">
        <code>SEARCH_MAX_DEPTH</code>
      </td>
      <td rowspan="3">
        スキャン対象となる一致ファイルを検索する際に、アナライザーが探索するディレクトリ階層の数。<sup><b><a href="#search-max-depth-description">5</a></b></sup>
      </td>
      <td rowspan="2">
        <code><a href="https://gitlab.com/gitlab-org/gitlab/-/blob/v17.3.0-ee/lib/gitlab/ci/templates/Jobs/SAST.gitlab-ci.yml#L54">20</a></code>
      </td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/semgrep">Semgrep</a>
      </td>
    </tr>
    <tr>
      <td>
        <a href="gitlab_advanced_sast.md">GitLab高度なSAST</a>
      </td>
    </tr>
    <tr>
      <td>
        <code><a href="https://gitlab.com/gitlab-org/gitlab/blob/v17.3.0-ee/lib/gitlab/ci/templates/Jobs/SAST.gitlab-ci.yml#L26">4</a></code>
      </td>
      <td>
        その他すべてのSASTアナライザー
      </td>
    </tr>
  </tbody>
</table>

**脚注**:

1. <a id="sast-excluded-paths-description"></a>ビルドツールで使用される一時ディレクトリは、誤検出を引き起こす可能性があるため、除外しなければならない場合があります。パスを除外するには、デフォルトの除外パスをコピーして貼り付け、除外する独自のパスを**追加**します。デフォルトの除外パスを指定しない場合、デフォルト設定がオーバーライドされ、指定したパスのみがSASTスキャンから除外されます。

1. <a id="sast-excluded-paths-semgrep"></a>これらのアナライザーでは、`SAST_EXCLUDED_PATHS`が**プリフィルター**として実装されており、スキャンの実行前に適用されます。

   アナライザーは、パスがカンマ区切りのパターンのいずれかに一致するファイルまたはディレクトリをスキップします。

   たとえば、`SAST_EXCLUDED_PATHS`が`*.py,tests`に設定されている場合:

   - `*.py`は以下を無視します。
      - `foo.py`
      - `src/foo.py`
      - `foo.py/bar.sh`
   - `tests`は以下を無視します。
      - `tests/foo.py`
      - `a/b/tests/c/foo.py`

   各パターンは、[gitignore](https://git-scm.com/docs/gitignore#_pattern_format)と同じ構文を使用するglobスタイルのパターンです。

1. <a id="sast-excluded-paths-all-other-sast-analyzers"></a>これらのアナライザーでは、`SAST_EXCLUDED_PATHS`が**ポストフィルター**として実装されており、スキャンの実行後に適用されます。

   パターンには、glob（サポートされているパターンについては[`doublestar.Match`](https://pkg.go.dev/github.com/bmatcuk/doublestar/v4@v4.0.2#Match)を参照）、またはファイルパスやフォルダーパス（`doc,spec`など）を使用できます。親ディレクトリもパターンに一致します。

   `SAST_EXCLUDED_PATHS`のポストフィルターとしての実装は、すべてのSASTアナライザーで使用できます。[上付き文字`2`](#sast-excluded-paths-semgrep)が付いたものなど、一部のSASTアナライザーでは、`SAST_EXCLUDED_PATHS`がプリフィルターとポストフィルターの両方として実装されています。スキャン対象のファイル数を減らせるため、プリフィルターのほうが効率的です。

   `SAST_EXCLUDED_PATHS`をプリフィルターとポストフィルターの両方としてサポートするアナライザーでは、最初にプリフィルターが適用され、次に、残りの脆弱性に対してポストフィルターが適用されます。

1. <a id="sast-spotbugs-excluded-build-paths-description"></a>この変数では、パスパターンとしてglobを使用できます（サポートされているパターンについては、[`doublestar.Match`](https://pkg.go.dev/github.com/bmatcuk/doublestar/v4@v4.0.2#Match)を参照してください）。パスパターンが、以下に示すサポート対象ビルドファイルと一致する場合、そのディレクトリはビルドプロセスから除外されます。

   - `build.sbt`
   - `grailsw`
   - `gradlew`
   - `build.gradle`
   - `mvnw`
   - `pom.xml`
   - `build.xml`

   たとえば、`project/subdir/pom.xml`というパスのビルドファイルを含む`maven`プロジェクトのビルドとスキャンを除外するには、`project/*/*.xml`や`**/*.xml`など、そのビルドファイルに明示的に一致するglobパターン、または`project/subdir/pom.xml`のような完全一致のパターンを渡します。

   `project`や`project/subdir`など、パターンの親ディレクトリを渡しても、そのディレクトリはビルドから除外されません。この場合、ビルドファイルがパターンに明示的に一致していないためです。

1. <a id="search-max-depth-description"></a>[SAST CI/CDテンプレート](https://gitlab.com/gitlab-org/gitlab/blob/v17.4.1-ee/lib/gitlab/ci/templates/Jobs/SAST.gitlab-ci.yml)は、リポジトリを検索して使用されているプログラミング言語を検出し、一致するアナライザーを選択します。次に、各アナライザーがコードベースを検索し、スキャンする必要がある特定のファイルまたはディレクトリを見つけます。アナライザーの検索フェーズで、検索対象とするディレクトリ階層の数を指定するには、`SEARCH_MAX_DEPTH`の値を設定します。

#### アナライザーの設定 {#analyzer-settings}

一部のアナライザーは、CI/CD変数を使用してカスタマイズできます。

| CI/CD変数                      | アナライザー             | デフォルト                                         | 説明 |
|-------------------------------------|----------------------|-------------------------------------------------|-------------|
| `GITLAB_ADVANCED_SAST_ENABLED`      | GitLab高度なSAST | `false`                                         | [GitLab高度なSAST](gitlab_advanced_sast.md)スキャンを有効にするには、`true`に設定します（GitLab Ultimateでのみ使用可能）。 |
| `SCAN_KUBERNETES_MANIFESTS`         | Kubesec              | `"false"`                                       | Kubernetes manifestをスキャンするには、`"true"`に設定します。 |
| `KUBESEC_HELM_CHARTS_PATH`          | Kubesec              |                                                 | `helm`がKubernetes manifestを生成する際に使用するHelmチャートのパス（オプション）。生成されたmanifestは、`kubesec`によってスキャンされます。依存関係が定義されている場合、必要な依存関係をフェッチするために、`helm dependency build`を`before_script`で実行する必要があります。 |
| `KUBESEC_HELM_OPTIONS`              | Kubesec              |                                                 | `helm`実行可能ファイルに渡す追加の引数。 |
| `COMPILE`                           | SpotBugs             | `true`                                          | プロジェクトのコンパイルと依存関係のフェッチを無効にするには、`false`に設定します。 |
| `ANT_HOME`                          | SpotBugs             |                                                 | `ANT_HOME`変数。 |
| `ANT_PATH`                          | SpotBugs             | `ant`                                           | `ant`実行可能ファイルのパス。 |
| `GRADLE_PATH`                       | SpotBugs             | `gradle`                                        | `gradle`実行可能ファイルのパス。 |
| `JAVA_OPTS`                         | SpotBugs             | `-XX:MaxRAMPercentage=80`                       | `java`実行可能ファイルに渡す追加の引数。 |
| `JAVA_PATH`                         | SpotBugs             | `java`                                          | `java`実行可能ファイルのパス。 |
| `SAST_JAVA_VERSION`                 | SpotBugs             | GitLab 15より前の場合は`8` </br> GitLab 15以降の場合は`17` | 使用するJavaのバージョン。[GitLab 15.0以降では](https://gitlab.com/gitlab-org/gitlab/-/issues/352549)、サポートされているバージョンは`11`および`17`です。GitLab 15.0より前では、サポートされているバージョンは`8`および`11`です。 |
| `MAVEN_CLI_OPTS`                    | SpotBugs             | `--batch-mode -DskipTests=true`                 | `mvn`または`mvnw`実行可能ファイルに渡す追加の引数。 |
| `MAVEN_PATH`                        | SpotBugs             | `mvn`                                           | `mvn`実行可能ファイルのパス。 |
| `MAVEN_REPO_PATH`                   | SpotBugs             | `$HOME/.m2/repository`                          | Mavenローカルリポジトリのパス（`maven.repo.local`プロパティのショートカット）。 |
| `SBT_PATH`                          | SpotBugs             | `sbt`                                           | `sbt`実行可能ファイルのパス。 |
| `FAIL_NEVER`                        | SpotBugs             | `false`                                         | コンパイルの失敗を無視するには、`true`または`1`に設定します。 |
| `SAST_SEMGREP_METRICS`              | Semgrep              | `true`                                          | 匿名化されたスキャンメトリクスを[r2c](https://semgrep.dev)に送信しないようにするには、`false`に設定します。 |
| `SAST_SCANNER_ALLOWED_CLI_OPTS`     | Semgrep              | `--max-target-bytes=1000000 --timeout=5`        | スキャン操作の実行時に、基盤となるセキュリティスキャナーに渡されるコマンドラインインターフェース（CLI）オプション（値を伴う引数、またはフラグ）。受け入れ可能な[オプション](#security-scanner-configuration)は限られています。コマンドラインインターフェースオプションとその値は、空白または等号（`=`）記号で区切ります。例: `name1 value1`または`name1=value1`。複数のオプションは空白で区切る必要があります。例: `name1 value1 name2 value2`。GitLab 15.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/368565)されました。 |
| `SAST_RULESET_GIT_REFERENCE`        | すべて                  |                                                 | カスタムルールセット設定のパスを定義します。プロジェクトに`.gitlab/sast-ruleset.toml`ファイルがコミットされている場合、そのローカル設定が優先され、`SAST_RULESET_GIT_REFERENCE`で指定されたファイルは使用されません。この変数は、Ultimateプランでのみ使用できます。 |
| `SECURE_ENABLE_LOCAL_CONFIGURATION` | すべて                  | `false`                                         | カスタムルールセット設定を使用するオプションを有効にします。`SECURE_ENABLE_LOCAL_CONFIGURATION`が`false`に設定されている場合、`.gitlab/sast-ruleset.toml`にあるプロジェクトのカスタムルールセット設定ファイルは無視され、`SAST_RULESET_GIT_REFERENCE`で指定されたファイル、またはデフォルト設定が優先されます。 |

#### セキュリティスキャナーの設定 {#security-scanner-configuration}

SASTアナライザーは、内部的にOSSのセキュリティスキャナーを使用して分析を実行します。これらのセキュリティスキャナーについては、推奨される設定をあらかじめ適用しているため、調整について心配する必要はありません。ただし、まれですが、デフォルトのスキャナー設定が要件に合わない場合があります。

スキャナーの動作をある程度カスタマイズできるようにするには、基になるスキャナーに制限付きのフラグセットを追加します。`SAST_SCANNER_ALLOWED_CLI_OPTS` CI/CD変数でフラグを指定します。指定されたフラグは、スキャナーのコマンドラインインターフェースオプションに追加されます。

<table class="sast-table">
  <thead>
    <tr>
      <th>アナライザー</th>
      <th>CLIオプション</th>
      <th>説明</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td rowspan="2">
        GitLab高度なSAST
      </td>
      <td>
        <code>--include-propagator-files</code>
      </td>
      <td>
        警告: このフラグを使用すると、パフォーマンスが大幅に低下する可能性があります。<br> このオプションを使用すると、ソースファイルとシンクファイルを接続する中間ファイルもスキャン対象に含めることができます。ただし、これらの中間ファイル自体にはソースやシンクは含まれていません。小規模なリポジトリでは包括的な分析に役立ちますが、大規模なリポジトリでこの機能を有効にすると、パフォーマンスに大きな影響を与えます。
      </td>
    </tr>
    <tr>
      <td>
        <code>--multi-core</code>
      </td>
      <td>
        マルチコアスキャンはデフォルトで有効になっており、コンテナ情報に基づいて使用可能なCPUコアを自動的に検出して利用します。セルフホストRunnerでは、使用できるコアの最大数は4に制限されています。<code>--multi-core</code>に特定の値を明示的に設定することで、自動的に検出されたコア数をオーバーライドできます。マルチコア実行では、シングルコア実行と比べて、必要なメモリ量がコア数に比例して増加します。マルチコアスキャンを無効にするには、環境変数<code>DISABLE_MULTI_CORE</code>を設定します。利用可能なコアまたはメモリリソースを超えると、リソースの競合が発生し、パフォーマンスが十分に発揮されなくなる可能性があります。
      </td>
    </tr>
    <tr>
      <td rowspan="3">
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/semgrep">Semgrep</a>
      </td>
      <td>
        <code>--max-memory</code>
      </td>
      <td>
        1つのファイルに対してルールセットを実行する際に使用する、最大システムメモリ（MB単位）を設定します。
      </td>
    </tr>
    <tr>
      <td>
        <code>--max-target-bytes</code>
      </td>
      <td>
        <p>
          スキャン対象ファイルの最大サイズ。これを超えるサイズのインプットプログラムは無視されます。このフィルターを無効にするには、<code>0</code>または負の値を設定します。バイト数は、単位付きでも単位なしでも指定できます。例: <code>12.5kb</code>、<code>1.5MB</code>、<code>123</code>。デフォルトは<code>1000000</code>バイトです。
        </p>
        <p>
          <b>注:</b> このフラグはデフォルト値のままにしておく必要があります。また、このフラグを変更して縮小されたJavaScriptをスキャンすることは避けてください。うまく動作しない可能性があります。バイナリファイルはスキャンされないため、<code>DLL</code>、<code>JAR</code>、またはその他のバイナリファイルのスキャンも避けてください。
        </p>
      </td>
    </tr>
    <tr>
      <td>
        <code>--timeout</code>
      </td>
      <td>
        1つのファイルに対してルールを実行するために費やす最大時間（秒）。時間制限を設けない場合は、<code>0</code>に設定します。タイムアウト値は整数で指定する必要があります。例: <code>10</code>または<code>15</code>。デフォルトは<code>5</code>です。
      </td>
    </tr>
    <tr>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/spotbugs">SpotBugs</a>
      </td>
      <td>
        <code>-effort</code>
      </td>
      <td>
        分析の労力レベルを設定します。有効な値は、精度と脆弱性検出能力の低い順に、<code>min</code>、<code>less</code>、<code>more</code>、<code>max</code>です。デフォルト値は<code>max</code>に設定されています。プロジェクトの規模によっては、スキャンを完了するためにより多くのメモリと時間が必要になる場合があります。メモリやパフォーマンスの問題が発生した場合は、分析の労力レベルの値を下げることができます。例: <code>-effort less</code>。
      </td>
    </tr>
  </tbody>
</table>

#### カスタムCI/CD変数 {#custom-cicd-variables}

前述のSAST設定のCI/CD変数だけでなく、[SASTベンダーテンプレート](#configuration)を使用している場合、すべての[カスタム変数](../../../ci/variables/_index.md#define-a-cicd-variable-in-the-ui)が基盤となるSASTアナライザーイメージに伝播されます。

### 分析対象からコードを除外する {#exclude-code-from-analysis}

コードの特定の行やブロックにマークを付けて、脆弱性の分析から除外できます。発見ごとにコメント注釈を追加する方法を使用する前に、すべての脆弱性を脆弱性管理で管理するか、`SAST_EXCLUDED_PATHS`を使用してスキャン対象のファイルパスを調整する必要があります。

Semgrepベースのアナライザーを使用する場合、次のオプションも使用できます。

- コードの1行を無視する - 行の末尾に`// nosemgrep:`コメントを追加します（コメントのプレフィックスは開発言語によって異なります）。

  Javaの例:

  ```java
  vuln_func(); // nosemgrep
  ```

  Pythonの例:

  ```python
  vuln_func(); # nosemgrep
  ```

- 特定のルールに対してコードの1行を無視する - 行の末尾に`// nosemgrep: RULE_ID`コメントを追加します（コメントのプレフィックスは開発言語によって異なります）。

- ファイルまたはディレクトリを無視する - リポジトリのルートディレクトリまたはプロジェクトの作業ディレクトリに`.semgrepignore`ファイルを作成し、ファイルやフォルダーのパターンを記述します。GitLab Semgrepアナライザーは、このカスタム`.semgrepignore`ファイルを[GitLab組み込みの無視パターン](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep/-/blob/abcea7419961320f9718a2f24fe438cc1a7f8e08/semgrepignore)と自動的にマージします。

{{< alert type="note" >}}

Semgrepアナライザーは、`.gitignore`ファイルを考慮しません。`.gitignore`に記載されているファイルでも、`.semgrepignore`または`SAST_EXCLUDED_PATHS`を使用して明示的に除外されない限り、分析対象となります。

{{< /alert >}}

詳細については、[Semgrepのドキュメント](https://semgrep.dev/docs/ignoring-files-folders-code)を参照してください。

## オフライン環境でSASTを実行する {#running-sast-in-an-offline-environment}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

インターネット経由で外部リソースへのアクセスが制限されている、または不安定な環境にあるインスタンスでは、SASTジョブを正常に実行するためにいくつかの調整が必要です。詳細については、[オフライン環境](../offline_deployments/_index.md)を参照してください。

### オフラインSASTの要件 {#requirements-for-offline-sast}

オフライン環境でSASTを使用するには、以下が必要です。

- [`docker`](https://docs.gitlab.com/runner/executors/docker.html)または[`kubernetes`](https://docs.gitlab.com/runner/install/kubernetes.html) executorを備えたGitLab Runner。詳細については、[前提要件](#getting-started)を参照してください。
- SAST[アナライザー](https://gitlab.com/gitlab-org/security-products/analyzers)イメージのコピーをローカルに保持しているDockerコンテナレジストリ。
- パッケージの証明書チェックの設定（オプション）。

GitLab Runnerでは、[デフォルトで`pull_policy`が`always`](https://docs.gitlab.com/runner/executors/docker.html#using-the-always-pull-policy)になっています。つまり、ローカルコピーが利用可能な場合でも、RunnerはGitLabコンテナレジストリからDockerイメージをプルしようとします。オフライン環境ではローカルで利用可能なDockerイメージのみを使用する場合は、GitLab Runnerの[`pull_policy`を`if-not-present`に設定できます](https://docs.gitlab.com/runner/executors/docker.html#using-the-if-not-present-pull-policy)。ただし、オフライン環境でない場合は、プルポリシーの設定を`always`のままにしておくことをおすすめします。これにより、CI/CDパイプラインで常に最新のスキャナーを使用できるようになります。

### Dockerレジストリ内でGitLab SASTアナライザーイメージを利用できるようにする {#make-gitlab-sast-analyzer-images-available-inside-your-docker-registry}

すべての[サポート対象言語とフレームワーク](#supported-languages-and-frameworks)でSASTを使用するには、次のデフォルトのSASTアナライザーイメージを`registry.gitlab.com`から[ローカルのDockerコンテナレジストリ](../../packages/container_registry/_index.md)にインポートします。

```plaintext
registry.gitlab.com/security-products/gitlab-advanced-sast:1
registry.gitlab.com/security-products/kubesec:5
registry.gitlab.com/security-products/pmd-apex:5
registry.gitlab.com/security-products/semgrep:5
registry.gitlab.com/security-products/sobelow:5
registry.gitlab.com/security-products/spotbugs:5
```

DockerイメージをローカルのオフラインDockerレジストリにインポートするプロセスは、**ネットワークのセキュリティポリシー**によって異なります。IT部門に相談して、外部リソースをインポートまたは一時的にアクセスするための承認済みプロセスを確認してください。これらのスキャナーは新しい定義で[定期的に更新](../detect/vulnerability_scanner_maintenance.md)されています。また、自分で随時更新できる場合もあります。

Dockerイメージをファイルとして保存および転送する方法の詳細については、[`docker save`](https://docs.docker.com/reference/cli/docker/image/save/)、[`docker load`](https://docs.docker.com/reference/cli/docker/image/load/)、[`docker export`](https://docs.docker.com/reference/cli/docker/container/export/)、[`docker import`](https://docs.docker.com/reference/cli/docker/image/import/)に関するDockerのドキュメントを参照してください。

#### カスタム認証局のサポートが必要な場合 {#if-support-for-custom-certificate-authorities-are-needed}

次のバージョンで、カスタム認証局のサポートが導入されました。

| アナライザー   | バージョン |
|------------|---------|
| `kubesec`  | [v2.1.0](https://gitlab.com/gitlab-org/security-products/analyzers/kubesec/-/releases/v2.1.0) |
| `pmd-apex` | [v2.1.0](https://gitlab.com/gitlab-org/security-products/analyzers/pmd-apex/-/releases/v2.1.0) |
| `semgrep`  | [v0.0.1](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep/-/releases/v0.0.1) |
| `sobelow`  | [v2.2.0](https://gitlab.com/gitlab-org/security-products/analyzers/sobelow/-/releases/v2.2.0) |
| `spotbugs` | [v2.7.1](https://gitlab.com/gitlab-org/security-products/analyzers/spotbugs/-/releases/v2.7.1) |

### ローカルのSASTアナライザーを使用するようにSAST CI/CD変数を設定する {#set-sast-cicd-variables-to-use-local-sast-analyzers}

次の設定を`.gitlab-ci.yml`ファイルに追加します。ローカルのDockerコンテナレジストリを参照するように、`SECURE_ANALYZERS_PREFIX`を置き換える必要があります。

```yaml
include:
  - template: Jobs/SAST.gitlab-ci.yml

variables:
  SECURE_ANALYZERS_PREFIX: "localhost:5000/analyzers"
```

この設定により、SASTジョブは、インターネットアクセスを必要とせずに、SASTアナライザーのローカルコピーを使用してコードをスキャンし、セキュリティレポートを生成できるようになります。

### パッケージの証明書チェックを設定する {#configure-certificate-checking-of-packages}

SASTジョブがパッケージ管理システムを実行する場合は、その証明書の検証を設定する必要があります。オフライン環境では、外部ソースを使用して証明書を検証することはできません。自己署名証明書を使用するか、証明書の検証を無効にします。手順については、パッケージ管理システムのドキュメントを参照してください。

## SELinuxでSASTを実行する {#running-sast-in-selinux}

デフォルトで、SASTアナライザーは、SELinuxでホストされているGitLabインスタンスでサポートされています。ただし、[オーバーライドされたSASTジョブ](#overriding-sast-jobs)に`before_script`を追加すると、SELinuxでホストされているRunnerの権限が制限されているため、動作しない場合があります。
