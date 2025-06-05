---
stage: Application Security Testing
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 静的アプリケーションセキュリティテスト（SAST）
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

開発の後半でセキュリティの脆弱性が見つかると、コストのかかる遅延や潜在的な漏えいが発生する可能性があります。SASTスキャンはコミットごとに自動的に実行されるため、ワークフローを中断することなく、すぐにフィードバックを得ることができます。

## 機能

次の表に、各機能を利用可能なGitLabプランを示します。

| 機能                                                                                  | FreeおよびPremium      | Ultimate            |
|:-----------------------------------------------------------------------------------------|:-----------------------|:-----------------------|
| [オープンソースアナライザー](#supported-languages-and-frameworks)を使用した基本的なスキャン         | {{< icon name="check-circle" >}} 可 | {{< icon name="check-circle" >}} 可 |
| ダウンロード可能な[SAST JSONレポート](#download-a-sast-report)                                 | {{< icon name="check-circle" >}} 可 | {{< icon name="check-circle" >}} 可 |
| [GitLab高度なSAST](gitlab_advanced_sast.md)によるクロスファイルスキャン、クロスファンクションスキャン | {{< icon name="dotted-circle" >}} 不可 | {{< icon name="check-circle" >}} 可 |
| [マージリクエストウィジェット](#merge-request-widget)での新しい発見                            | {{< icon name="dotted-circle" >}} 不可 | {{< icon name="check-circle" >}} 可 |
| [マージリクエストの変更ビュー](#merge-request-changes-view)での新しい発見                | {{< icon name="dotted-circle" >}} 不可 | {{< icon name="check-circle" >}} 可 |
| [脆弱性管理](../vulnerabilities/_index.md)                                 | {{< icon name="dotted-circle" >}} 不可 | {{< icon name="check-circle" >}} 可 |
| [UIベースのスキャナー設定](#configure-sast-by-using-the-ui)                        | {{< icon name="dotted-circle" >}} 不可 | {{< icon name="check-circle" >}} 可 |
| [ルールセットのカスタマイズ](customize_rulesets.md)                                           | {{< icon name="dotted-circle" >}} 不可 | {{< icon name="check-circle" >}} 可 |
| [高度な脆弱性追跡](#advanced-vulnerability-tracking)                      | {{< icon name="dotted-circle" >}} 不可 | {{< icon name="check-circle" >}} 可 |

## 要件

インスタンスでSASTアナライザーを実行する前に、以下があることを確認してください。

- [`docker`](https://docs.gitlab.com/runner/executors/docker.html)または[`kubernetes`](https://docs.gitlab.com/runner/install/kubernetes.html)executorを備えたLinuxベースのGitLab RunnerGitLab.comのためにホストされたRunnerを使用している場合は、デフォルトで有効になっています。
  - Windows Runnerはサポートされていません。
  - amd64以外のCPUアーキテクチャはサポートされていません。
- GitLab CI/CD設定ファイル（`.gitlab-ci.yml`）には、`test`ステージを含める必要がありますが、これはデフォルトで含まれています。`.gitlab-ci.yml`ファイルでステージを再定義する場合は、`test`ステージが必要です。

## サポートされている言語とフレームワーク

GitLab SASTは、次の言語とフレームワークのスキャンをサポートしています。

利用可能なスキャンオプションは、GitLabのプランによって異なります。

- Ultimateでは、[GitLab高度なSAST](gitlab_advanced_sast.md)のほうがより正確な結果が得られます。サポートされている言語で使用する必要があります。
- 全プランで、オープンソーススキャナーに基づいてGitLabが提供するアナライザーを使用してコードをスキャンできます。

SASTでの言語サポートの計画の詳細については、[カテゴリの方向性](https://about.gitlab.com/direction/application_security_testing/static-analysis/sast/#language-support)ページを参照してください。

| 言語                                | [GitLab高度なSAST](gitlab_advanced_sast.md)でサポート（Ultimate のみ）                        | 別の[アナライザー](analyzers.md)でサポート（全プラン）                                                                                                     |
|-----------------------------------------|-----------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Apex（Salesforce）                       | {{< icon name="dotted-circle" >}} 不可                                                                              | {{< icon name="check-circle" >}}可: [PMD-Apex](https://gitlab.com/gitlab-org/security-products/analyzers/pmd-apex)                                                                                |
| C                                       | {{< icon name="dotted-circle" >}}不可。[エピック14271](https://gitlab.com/groups/gitlab-org/-/epics/14271)で追跡 | {{< icon name="check-circle" >}}可: [Semgrep](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep)（[GitLab管理ルール](rules.md#semgrep-based-analyzer)を使用）                     |
| C++                                     | {{< icon name="dotted-circle" >}}不可。[エピック14271](https://gitlab.com/groups/gitlab-org/-/epics/14271)で追跡 | {{< icon name="check-circle" >}}可: [Semgrep](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep)（[GitLab管理ルール](rules.md#semgrep-based-analyzer)を使用）                     |
| C#                                      | {{< icon name="check-circle" >}} 可                                                                              | {{< icon name="check-circle" >}}可: [Semgrep](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep)（[GitLab管理ルール](rules.md#semgrep-based-analyzer)を使用）                     |
| Elixir（Phoenix）                        | {{< icon name="dotted-circle" >}} 不可                                                                              | {{< icon name="check-circle" >}}可: [Sobelow](https://gitlab.com/gitlab-org/security-products/analyzers/sobelow)                                                                                  |
| Go                                      | {{< icon name="check-circle" >}} 可                                                                              | {{< icon name="check-circle" >}}可: [Semgrep](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep)（[GitLab管理ルール](rules.md#semgrep-based-analyzer)を使用）                     |
| Groovy                                  | {{< icon name="dotted-circle" >}} 不可                                                                              | {{< icon name="check-circle" >}}可: [SpotBugs](https://gitlab.com/gitlab-org/security-products/analyzers/spotbugs)（find-sec-bugsプラグイン<sup><b><a href="#spotbugs-footnote">1</a></b></sup>を使用）                               |
| Java                                    | {{< icon name="check-circle" >}}可。Java Server Pages（JSP）を含む                                           | {{< icon name="check-circle" >}}可: [Semgrep](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep)（[GitLab管理ルール](rules.md#semgrep-based-analyzer)を使用）（Androidを含む） |
| JavaScript（Node.js、Reactを含む） | {{< icon name="check-circle" >}} 可                                                                              | {{< icon name="check-circle" >}}可: [Semgrep](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep)（[GitLab管理ルール](rules.md#semgrep-based-analyzer)を使用）                     |
| Kotlin                                  | {{< icon name="dotted-circle" >}}不可。[エピック15173](https://gitlab.com/groups/gitlab-org/-/epics/15173)で追跡 | {{< icon name="check-circle" >}}可: [Semgrep](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep)（[GitLab管理ルール](rules.md#semgrep-based-analyzer)を使用）（Androidを含む） |
| Objective-C（iOS）                       | {{< icon name="dotted-circle" >}} 不可                                                                              | {{< icon name="check-circle" >}}可: [Semgrep](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep)（[GitLab管理ルール](rules.md#semgrep-based-analyzer)を使用）                     |
| PHP                                     | {{< icon name="dotted-circle" >}}不可。[エピック14273](https://gitlab.com/groups/gitlab-org/-/epics/14273)で追跡 | {{< icon name="check-circle" >}}可: [Semgrep](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep)（[GitLab管理ルール](rules.md#semgrep-based-analyzer)を使用）                     |
| Python                                  | {{< icon name="check-circle" >}} 可                                                                              | {{< icon name="check-circle" >}}可: [Semgrep](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep)（[GitLab管理ルール](rules.md#semgrep-based-analyzer)を使用）                     |
| Ruby（Ruby on Railsを含む）           | {{< icon name="check-circle" >}} 可                                                                              | {{< icon name="check-circle" >}}可: [Semgrep](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep)（[GitLab管理ルール](rules.md#semgrep-based-analyzer)を使用）                     |
| Scala                                   | {{< icon name="dotted-circle" >}}不可。[エピック15174](https://gitlab.com/groups/gitlab-org/-/epics/15174)で追跡 | {{< icon name="check-circle" >}}可: [Semgrep](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep)（[GitLab管理ルール](rules.md#semgrep-based-analyzer)を使用）                     |
| Swift（iOS）                             | {{< icon name="dotted-circle" >}} 不可                                                                              | {{< icon name="check-circle" >}}可: [Semgrep](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep)（[GitLab管理ルール](rules.md#semgrep-based-analyzer)を使用）                     |
| TypeScript                              | {{< icon name="check-circle" >}} 可                                                                              | {{< icon name="check-circle" >}}可: [Semgrep](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep)（[GitLab管理ルール](rules.md#semgrep-based-analyzer)を使用）                     |
| YAML<sup><b><a href="#yaml-footnote">2</a></b></sup>                        | {{< icon name="check-circle" >}} 可                                                                              | {{< icon name="check-circle" >}}可: [Semgrep](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep)（[GitLab管理ルール](rules.md#semgrep-based-analyzer)を使用）                     |
| Java Properties                         | {{< icon name="check-circle" >}} 可                                                                              | {{< icon name="check-circle" >}}可: [Semgrep](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep)（[GitLab管理ルール](rules.md#semgrep-based-analyzer)を使用）                     |

**脚注:**

1. <a id="spotbugs-footnote"></a>SpotBugsベースのアナライザーは、[Gradle](https://gradle.org/)、[Maven](https://maven.apache.org/)、[SBT](https://www.scala-sbt.org/)をサポートしています。また、[Gradleラッパー](https://docs.gradle.org/current/userguide/gradle_wrapper.html)、[Grails](https://grails.org/)、[Mavenラッパー](https://github.com/takari/maven-wrapper)などのバリアントでも使用できます。ただし、SpotBugsには、[Ant](https://ant.apache.org/)ベースのプロジェクトで使用する場合、[制限事項](https://gitlab.com/gitlab-org/gitlab/-/issues/350801)があります。AntベースのJavaまたはScalaプロジェクトには、GitLab高度なSASTまたはSemgrepベースのアナライザーを使用する必要があります。
1. <a id="yaml-footnote"></a>`YAML`のサポートは、次のファイルパターンに制限されています。

   - `application*.yml`
   - `application*.yaml`
   - `bootstrap*.yml`
   - `bootstrap*.yaml`

SAST CI/CDテンプレートには、KubernetesマニフェストとHelmチャートをスキャンできるアナライザージョブも含まれています。このジョブはデフォルトでオフになっています。「[Kubesecアナライザーを有効にする](#enabling-kubesec-analyzer)」を参照するか、代わりに、追加のプラットフォームをサポートする[IaCスキャン](../iac_scanning/_index.md)をご検討ください。

サポートされなくなったSASTアナライザーの詳細については、「[サポートが終了したアナライザー](analyzers.md#analyzers-that-have-reached-end-of-support)」を参照してください。

## 高度な脆弱性追跡

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

ソースコードは不安定です。デベロッパーが変更を加えると、ソースコードがファイル内またはファイル間で移動する可能性があります。セキュリティアナライザーは、[脆弱性レポート](../vulnerability_report/_index.md)で追跡されている脆弱性をすでに報告している可能性があります。これらの脆弱性は、見つけ出して修正できるように、特定の問題のあるコードフラグメントにリンクされています。コードフラグメントが移動する際の追跡が確実でない場合、同じ脆弱性が再度報告される可能性があるため、脆弱性管理がより困難になります。

GitLab SASTは、高度な脆弱性追跡アルゴリズムを使用して、同じ脆弱性がリファクタリングまたは無関係な変更によってファイル内で移動した場合、より正確に特定します。

高度な脆弱性追跡は、[サポートされている言語](#supported-languages-and-frameworks)と[アナライザー](analyzers.md)のサブセットで使用できます。

- C（Semgrepベースのみ）
- C++（Semgrepベースのみ）
- C#（GitLab高度なSASTとSemgrepベースのアナライザー）
- Go（GitLab高度なSASTとSemgrepベースのアナライザー）
- Java（GitLab高度なSASTとSemgrepベースのアナライザー）
- JavaScript（GitLab高度なSASTとSemgrepベースのアナライザー）
- PHP（Semgrepベースのアナライザーのみ）
- Python（GitLab高度なSASTとSemgrepベースのアナライザー）
- Ruby（Semgrepベースのアナライザーのみ）

より多くの言語とアナライザーのサポートが[このエピック](https://gitlab.com/groups/gitlab-org/-/epics/5144)で追跡されます。

詳細については、機密プロジェクト（`https://gitlab.com/gitlab-org/security-products/post-analyzers/tracking-calculator`）を参照してください。このプロジェクトのコンテンツは、GitLabチームメンバーのみが利用できます。

## 脆弱性の自動修正

{{< history >}}

- GitLab 15.9で、`sec_mark_dropped_findings_as_resolved`という名前の[プロジェクトレベルのフラグ](../../../administration/feature_flags.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/368284)されました。
- GitLab 15.10で、デフォルトで有効になりました。GitLab.comでプロジェクトのフラグを無効にする必要がある場合は、[サポートにお問い合わせください](https://about.gitlab.com/support/)。
- GitLab 16.2で、[機能フラグが削除](https://gitlab.com/gitlab-org/gitlab/-/issues/375128)されました。

{{< /history >}}

関連性の高い脆弱性に集中できるように、GitLab SASTは次の場合に脆弱性を自動的に[解決](../vulnerabilities/_index.md#vulnerability-status-values)します。

- [定義済みのルールを無効する](customize_rulesets.md#disable-predefined-rules)場合
- デフォルトのルールセットからルールを削除する場合

自動解決は、[Semgrepベースのアナライザー](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep)からの検出結果にのみ使用できます。脆弱性管理システムは、自動的に解決された脆弱性にコメントを残すため、脆弱性の履歴記録が残ります。

後でルールを再度有効にすると、トリアージのために検出結果がもう一度開きます。

## サポートされているディストリビューション

デフォルトのスキャナーイメージは、サイズと保守性のためにベースのAlpineイメージ上にビルドされています。

### FIPS対応イメージ

GitLabは、[Red Hat UBI](https://www.redhat.com/en/blog/introducing-red-hat-universal-base-image)ベースのイメージに基づいて、FIPS 140検証済みの暗号学的モジュールを使用するイメージバージョンを提供しています。FIPS対応イメージを使用するには、次のいずれかを実行します。

- `SAST_IMAGE_SUFFIX`を`-fips`に設定します。
- `-fips`拡張子をデフォルトのイメージ名に追加します。

次に例を示します。

```yaml
variables:
  SAST_IMAGE_SUFFIX: '-fips'

include:
  - template: Jobs/SAST.gitlab-ci.yml
```

FIPS準拠イメージは、GitLab高度なSASTとSemgrepベースのアナライザーでのみ使用できます。

{{< alert type="warning" >}}

FIPS準拠の方法でSASTを使用するには、[他のアナライザーの実行を除外](analyzers.md#customize-analyzers)する必要があります。FIPS対応イメージを使用して、[非rootユーザーのRunner](https://docs.gitlab.com/runner/install/kubernetes_helm_chart_configuration.html#run-with-non-root-user)で高度なSASTまたはSemgrepを実行する場合は、`runners.kubernetes.pod_security_context`の下で`run_as_user`属性を更新して、[イメージによって作成される](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep/-/blob/a5d822401014f400b24450c92df93467d5bbc6fd/Dockerfile.fips#L58)`gitlab`ユーザーのID（`1000`）を使用する必要があります。

{{< /alert >}}

## 脆弱性の詳細

SASTの脆弱性には、検出された脆弱性の主要なCommon Weakness Enumeration（CWE）識別子に従って名前が付けられています。スキャナーが検出した特定の問題の詳細については、各脆弱性の検出結果の説明をお読みください。

SASTカバレッジの詳細については、「[SASTルール](rules.md)」を参照してください。

## SASTレポートのダウンロード

各SASTアナライザーは、ジョブアーティファクトとしてJSONレポートを出力します。ファイルには、検出されたすべての脆弱性の詳細が含まれています。ファイルを[ダウンロード](../../../ci/jobs/job_artifacts.md#download-job-artifacts)して、GitLabの外部で処理できます。

詳細については、以下を参照してください。

- [SASTレポートファイルスキーマ](https://gitlab.com/gitlab-org/security-products/security-report-schemas/-/blob/master/dist/sast-report-format.json)
- [SASTレポートファイルの例](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep/-/blob/main/qa/expect/js/default/gl-sast-report.json)

## SASTの結果を表示する

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

Ultimateでは、[SASTレポートファイル](#download-a-sast-report)はGitLabによって処理され、詳細は以下のUIに表示されます。

- [マージリクエストウィジェット](#merge-request-widget)
- [マージリクエストの変更ビュー](#merge-request-changes-view)
- [脆弱性レポート](../vulnerability_report/_index.md)
- [パイプラインセキュリティレポート](../vulnerability_report/pipeline.md)

パイプラインは、SASTやDASTスキャンを含む複数のジョブで構成されています。何らかの理由でジョブが完了しなかった場合、セキュリティダッシュボードにSASTスキャナーの出力は表示されません。たとえば、SASTジョブは完了したがDASTジョブが失敗した場合、セキュリティダッシュボードにSASTの結果は表示されません。失敗した場合、アナライザーは[終了コード](../../../development/integrations/secure.md#exit-code)を出力します。

### マージリクエストウィジェット

ターゲットブランチからのレポートを比較できる場合、SASTの結果がマージリクエストウィジェット領域に表示されます。マージリクエストウィジェットには以下が表示されます。

- MRによって導入された新しいSASTの検出結果
- MRによって解決された既存の検出結果

利用可能な場合は常に、[高度な脆弱性追跡](#advanced-vulnerability-tracking)を使用して結果が比較されます。

![セキュリティマージリクエストウィジェット](img/sast_mr_widget_v16_7.png)

### マージリクエストの変更ビュー

{{< history >}}

- GitLab 16.6で、`sast_reports_in_inline_diff`という名前の[フラグ](../../../administration/feature_flags.md)とともに[導入](https://gitlab.com/groups/gitlab-org/-/epics/10959)されました。デフォルトでは無効になっています。
- GitLab 16.8で、デフォルトで有効になりました。
- GitLab 16.9で、[機能フラグが削除](https://gitlab.com/gitlab-org/gitlab/-/issues/410191)されました。

{{< /history >}}

SASTの結果は、マージリクエストの**変更**ビューに表示されます。SASTの問題を含む行は、ガターの横に記号でマークされます。記号を選択して問題のリストを表示し、問題を選択して詳細を表示します。

![SASTインラインインジケーター](img/sast_inline_indicator_v16_7.png)

## スキャナーをコントリビュートする

[セキュリティスキャナーのインテグレーション](../../../development/integrations/secure.md)に関するドキュメントでは、他のセキュリティスキャナーをGitLabに統合する方法について説明しています。

## 設定

SASTスキャンは、CI/CDパイプラインで実行されます。GitLab管理のCI/CDテンプレートをパイプラインに追加すると、適切な[SASTアナライザー](analyzers.md)が自動的にコードをスキャンし、結果を[SASTレポートアーティファクト](../../../ci/yaml/artifacts_reports.md#artifactsreportssast)として保存します。

プロジェクトのSASTを設定するには、次の手順を実行します。

- [Auto DevOps](../../../topics/autodevops/_index.md)によって提供される[自動SAST](../../../topics/autodevops/stages.md#auto-sast)を使用します。
- [CI/CD YAMLでSASTを設定](#configure-sast-in-your-cicd-yaml)します。
- [UIを使用してSASTを設定](#configure-sast-by-using-the-ui)します。

[スキャン実行を適用](../_index.md#enforce-scan-execution)することで、多くのプロジェクトでSASTを有効にできます。

高度なSAST（GitLab Ultimateでのみ利用可能）を設定するには、この[手順](gitlab_advanced_sast.md#configuration)に従ってください。

必要に応じて、[設定変数を変更](_index.md#available-cicd-variables)したり、[検出ルールをカスタマイズ](customize_rulesets.md)したりできますが、GitLab SASTはデフォルト設定で使用するように設計されています。

### CI/CD YAMLでSASTを設定する

SASTを有効にするには、[`SAST.gitlab-ci.yml`テンプレート](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/SAST.gitlab-ci.yml)を[含めます](../../../ci/yaml/_index.md#includetemplate)。このテンプレートは、GitLabインストールの一部として提供されます。

次の内容をコピーして、`.gitlab-ci.yml`ファイルの末尾に貼り付けます。`include`行がすでに存在する場合は、その下に`template`行のみを追加します。

```yaml
include:
  - template: Jobs/SAST.gitlab-ci.yml
```

含まれているテンプレートは、CI/CDパイプラインにSASTジョブを作成し、プロジェクトのソースコードで潜在的な脆弱性をスキャンします。

結果は、後でダウンロードして分析できる[SASTレポートアーティファクト](../../../ci/yaml/artifacts_reports.md#artifactsreportssast)として保存されます。ダウンロードすると、常に利用可能な最新のSASTアーティファクトを受け取ります。

### 安定版と最新版のSASTテンプレート

SASTには、セキュリティテストをCI/CDパイプラインに組み込むための2つのテンプレートが用意されています。

- [`SAST.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/SAST.gitlab-ci.yml)（推奨）

  安定版テンプレートは、信頼性が高く一貫性のあるSASTエクスペリエンスを提供します。CI/CDパイプラインで安定性と予測可能な動作を必要とするほとんどのユーザーおよびプロジェクトでは、安定したテンプレートを使用する必要があります。

- [`SAST.latest.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/SAST.latest.gitlab-ci.yml)

  このテンプレートは、最先端の機能にアクセスしてテストしたい人を対象としています。安定しているとは見なされておらず、次のメジャーリリースで計画されている破壊的な変更が含まれている可能性があります。このテンプレートを使用すると、新しい機能やアップデートが安定版リリースの一部になる前に試すことができるため、潜在的な不安定さをいとわず、新しい機能に関するフィードバックを提供することに意欲的なユーザーに最適です。

### UIを使用してSASTを設定する

UIを使用してSASTを有効化および設定できます。設定はデフォルトのままにすることも、カスタマイズすることも可能です。使用できる方法は、GitLabのライセンスプランによって異なります。

#### カスタマイズしてSASTを設定する

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

> GitLab 16.2で、UIから個々のSASTアナライザーの設定オプションを[削除](https://gitlab.com/gitlab-org/gitlab/-/issues/410013)しました。

{{< alert type="note" >}}

この設定ツールは、既存の`.gitlab-ci.yml`ファイルがない場合、または設定ファイルが最小限しかない場合に最もうまく機能します。複雑なGitLab設定ファイルがある場合は、正常に解析されず、エラーが発生する可能性があります。

{{< /alert >}}

カスタマイズしてSASTを有効化および設定するには:

1. 左側のサイドバーで、**検索または移動先**を選択し、プロジェクトを検索します。
1. **セキュリティ>セキュリティ設定**を選択します。
1. プロジェクトのデフォルトブランチの最新のパイプラインが完了し、有効な`SAST`アーティファクトが生成された場合は、**SASTの設定**を選択し、それ以外の場合は静的アプリケーションセキュリティテスト（SAST）行の**SASTの有効化**を選択します。
1. SASTのカスタム値を入力します。

   カスタム値は`.gitlab-ci.yml`ファイルに保存されます。SASTの設定ページにないCI/CD変数については、それらの値はGitLab SASTテンプレートから継承されます。
1. **マージリクエストの作成**を選択します。
1. マージリクエストをレビューしてマージします。

これで、パイプラインにSASTジョブが含まれます。

#### デフォルト設定のみでSASTを設定する

{{< alert type="note" >}}

この設定ツールは、既存の`.gitlab-ci.yml`ファイルがない場合、または設定ファイルが最小限しかない場合に最もうまく機能します。複雑なGitLab設定ファイルがある場合は、正常に解析されず、エラーが発生する可能性があります。

{{< /alert >}}

デフォルト設定でSASTを有効化および設定するには:

1. 左側のサイドバーで、**検索または移動先**を選択し、プロジェクトを検索します。
1. **セキュリティ>セキュリティ設定**を選択します。
1. SASTセクションで**マージリクエスト経由で設定**を選択します。
1. マージリクエストをレビューしてマージし、SASTを有効にします。

これで、パイプラインにSASTジョブが含まれます。

### SASTジョブをオーバーライドする

ジョブ定義をオーバーライドする（`variables`、`dependencies`、または[`rules`](../../../ci/yaml/_index.md#rules)のようなプロパティを変更する場合など）には、オーバーライドするSASTジョブと同じ名前でジョブを宣言します。テンプレートの挿入後にこの新しいジョブを配置し、その下に追加のキーを指定します。たとえば、これにより`spotbugs`アナライザーの`FAIL_NEVER`が有効になります。

```yaml
include:
  - template: Jobs/SAST.gitlab-ci.yml

spotbugs-sast:
  variables:
    FAIL_NEVER: 1
```

### マイナーイメージバージョンにピン留めする

GitLab管理のCI/CDテンプレートは、メジャーバージョンを指定し、そのメジャーバージョン内の最新のアナライザーリリースを自動的にプルします。

場合によっては、特定のバージョンを使用しなければならない場合があります。たとえば、以降のリリースでリグレッションを回避しなければならない場合があります。

自動更新の動作をオーバーライドするには、[`SAST.gitlab-ci.yml`テンプレート](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/SAST.gitlab-ci.yml)を含めた後、CI/CD設定ファイルで`SAST_ANALYZER_IMAGE_TAG` CI/CD変数を設定します。

この変数は、特定のジョブ内でのみ設定してください。[トップレベル](../../../ci/variables/_index.md#define-a-cicd-variable-in-the-gitlab-ciyml-file)で設定すると、設定したバージョンが他のSASTアナライザーに使用されます。

タグは次のように設定できます。

- `3`のようなメジャーバージョン: パイプラインは、このメジャーバージョン内でリリースされるマイナーまたはパッチアップデートを使用します。
- `3.7`のようなマイナーバージョン: パイプラインは、このマイナーバージョン内でリリースされるパッチアップデートを使用します。
- `3.7.0`のようなパッチバージョン: パイプラインはアップデートを受け取りません。

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

### CI/CD変数を使用してプライベートリポジトリの認証情報を渡す

一部のアナライザーでは、分析を実行するためにプロジェクトの依存関係をダウンロードする必要があります。一方、そのような依存関係はプライベートGitリポジトリに存在する可能性があり、ダウンロードするにはユーザー名やパスワードなどの認証情報が必要になります。アナライザーによっては、[カスタムCI/CD変数](#custom-cicd-variables)を介してそのような認証情報をアナライザーに提供できます。

#### CI/CD変数を使用してプライベートMavenリポジトリにユーザー名とパスワードを渡す

プライベートMavenリポジトリにログイン認証情報が必要な場合は、`MAVEN_CLI_OPTS` CI/CD変数を使用できます。

詳細については、[プライベートMavenリポジトリの使用方法](../dependency_scanning/_index.md#authenticate-with-a-private-maven-repository)を参照してください。

### Kubesecアナライザーを有効にする

Kubesecアナライザーを有効にするには、`SCAN_KUBERNETES_MANIFESTS`を`"true"`に設定する必要があります。`.gitlab-ci.yml`で、次のように定義します。

```yaml
include:
  - template: Jobs/SAST.gitlab-ci.yml

variables:
  SCAN_KUBERNETES_MANIFESTS: "true"
```

### Semgrepベースのアナライザーで他の言語をスキャンする

[Semgrepベースのアナライザー](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep)をカスタマイズして、GitLab管理のルールセットで[サポート](#supported-languages-and-frameworks)されていない言語をスキャンできます。ただし、GitLabではこれらの他の言語のルールセットを提供していなため、それらをカバーするには[カスタムルールセット](customize_rulesets.md#build-a-custom-configuration)を提供する必要があります。また、関連ファイルが変更されたときにジョブが実行されるように、`semgrep-sast` CI/CD ジョブの`rules`を変更する必要もあります。

#### Rustアプリケーションをスキャンする

たとえば、Rustアプリケーションをスキャンするには、次の手順を実行する必要があります。

1. Rustのカスタムルールセットを提供します。リポジトリのルートにある`.gitlab/`ディレクトリに`sast-ruleset.toml`という名前のファイルを作成します。次の例では、SemgrepレジストリのRustのデフォルトルールセットを使用します。

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

   詳細については、[ルールセットのカスタマイズ](customize_rulesets.md#build-a-custom-configuration)を参照してください。

1. `semgrep-sast`ジョブをオーバーライドして、Rust（`.rs`）ファイルを検出するルールを追加します。`.gitlab-ci.yml`ファイルで以下を定義します。

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

### プリコンパイル

ほとんどのGitLab SASTアナライザーは、最初にコンパイルせずにソースコードを直接スキャンします。ただし、技術的な理由により、SpotBugsベースのアナライザーはコンパイルされたバイトコードをスキャンします。

デフォルトでは、SpotBugsベースのアナライザーが依存関係のフェッチとコードのコンパイルを自動的に試行し、スキャンできるようにします。自動コンパイルは、以下の場合に失敗する可能性があります。

- プロジェクトにカスタムビルド設定が必要な場合
- アナライザーに組み込まれていない言語バージョンを使用している場合

これらの問題を解決するには、アナライザーのコンパイル手順をスキップし、代わりにパイプラインの以前の段階からアーティファクトを直接提供する必要があります。この戦略は、_プリコンパイル_と呼ばれます。

プリコンパイルを使用するには:

1. プロジェクトの依存関係をプロジェクトの作業ディレクトリ内のディレクトリに出力し、[`artifacts: paths`構成を設定](../../../ci/yaml/_index.md#artifactspaths)することにより、そのディレクトリをアーティファクトとして保存します。
1. `COMPILE: "false"` CI/CD変数をアナライザージョブに提供して、自動コンパイルを無効にします。
1. compilationステージをアナライザージョブの依存関係として追加します。

アナライザーがコンパイルされたアーティファクトを認識できるようにするには、ベンダーディレクトリへのパスを明示的に指定する必要があります。この設定は、プロジェクトのセットアップ方法によって異なる場合があります。Mavenプロジェクトの場合は、`MAVEN_REPO_PATH`を使用できます。利用可能なオプションの完全なリストについては、「[アナライザーの設定](#analyzer-settings)」を参照してください。

次の例では、Mavenプロジェクトをプリコンパイルし、SpotBugsベースのSASTアナライザーに提供します。

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
  artifacts:
    reports:
      sast: gl-sast-report.json
```

### マージリクエストパイプラインでジョブを実行する

「[マージリクエストパイプラインでセキュリティスキャンツールを使用する](../detect/roll_out_security_scanning.md#use-security-scanning-tools-with-merge-request-pipelines)」を参照してください。

### 利用可能なCI/CD変数

SASTは、`.gitlab-ci.yml`の[`variables`](../../../ci/yaml/_index.md#variables)パラメーターを使用して設定できます。

{{< alert type="warning" >}}

これらの変更をデフォルトブランチにマージする前に、GitLabセキュリティスキャンツールのすべてのカスタマイズをマージリクエストでテストする必要があります。そうしないと、誤検出が多数発生するなど、予期しない結果が生じる可能性があります。

{{< /alert >}}

次の例では、SASTテンプレートを含めて、すべてのジョブで`SEARCH_MAX_DEPTH`変数を`10`にオーバーライドします。テンプレートはパイプライン設定の[前に評価](../../../ci/yaml/_index.md#include)されるため、変数の最後の記述が優先されます。

```yaml
include:
  - template: Jobs/SAST.gitlab-ci.yml

variables:
  SEARCH_MAX_DEPTH: 10
```

#### カスタム公開認証局（CA）

カスタム公開認証局（CA）を信頼するには、SAST環境で信頼するCA証明書のバンドルに`ADDITIONAL_CA_CERT_BUNDLE`変数を設定します。`ADDITIONAL_CA_CERT_BUNDLE`値には、[X.509 PEM公開鍵証明書のテキスト表現](https://www.rfc-editor.org/rfc/rfc7468#section-5.1)が含まれている必要があります。たとえば、`.gitlab-ci.yml`ファイルでこの値を設定するには、以下を実行します。

```yaml
variables:
  ADDITIONAL_CA_CERT_BUNDLE: |
      -----BEGIN CERTIFICATE-----
      MIIGqTCCBJGgAwIBAgIQI7AVxxVwg2kch4d56XNdDjANBgkqhkiG9w0BAQsFADCB
      ...
      jWgmPqF3vUbZE0EyScetPJquRFRKIesyJuBFMAs=
      -----END CERTIFICATE-----
```

`ADDITIONAL_CA_CERT_BUNDLE`値は、[UIのカスタム変数](../../../ci/variables/_index.md#for-a-project)として設定することもできます。`file`として設定する場合は、証明書のパスが必要です。変数として設定する場合は、証明書のテキスト表現が必要です。

#### Dockerイメージ

以下は、Dockerイメージ関連のCI/CD変数です。

| CI/CD変数            | 説明                                                                                                                           |
|---------------------------|---------------------------------------------------------------------------------------------------------------------------------------|
| `SECURE_ANALYZERS_PREFIX` | デフォルトイメージを提供するDockerレジストリ（プロキシ）の名前をオーバーライドします。詳細については、[アナライザーのカスタマイズ](analyzers.md)を参照してください。 |
| `SAST_EXCLUDED_ANALYZERS` | 実行すべきではないデフォルトイメージの名前。詳細については、[アナライザーのカスタマイズ](analyzers.md)を参照してください。                                 |
| `SAST_ANALYZER_IMAGE_TAG` | アナライザーイメージのデフォルトバージョンをオーバーライドします。詳細については、[アナライザーイメージバージョンのピン留め](#pinning-to-minor-image-version)を参照してください。                                 |
| `SAST_IMAGE_SUFFIX`       | イメージ名に追加されたサフィックス`-fips`に設定すると、`FIPS-enabled`イメージがスキャンに使用されます。詳細については、「[FIPS対応イメージ](#fips-enabled-images)」を参照してください。 |

#### 脆弱性フィルター

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
        スキャンする一致ファイルを検索する際に、アナライザーが下降するディレクトリレベルの数。<sup><b><a href="#search-max-depth-description">5</a></b></sup>
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

**脚注:**

1. <a id="sast-excluded-paths-description"></a>ビルドツールで使用される一時ディレクトリは、誤検出を生成する可能性があるため、除外しなければならない場合があります。パスを除外するには、デフォルトの除外パスをコピーして貼り付け、除外する独自のパスを**追加**します。デフォルトの除外パスを指定しない場合、デフォルトはオーバーライドされ、指定したパス_のみ_がSASTスキャンから除外されます。

1. <a id="sast-excluded-paths-semgrep"></a>これらのアナライザーでは、`SAST_EXCLUDED_PATHS`が**プリフィルター**として実装されており、スキャンの実行_前_に適用されます。

   アナライザーは、パスがコンマ区切りのパターンのいずれかに一致するファイルまたはディレクトリをスキップします。

   たとえば、`SAST_EXCLUDED_PATHS`が`*.py,tests`に設定されている場合:

   - `*.py`は以下を無視します。
      - `foo.py`
      - `src/foo.py`
      - `foo.py/bar.sh`
   - `tests`は以下を無視します。
      - `tests/foo.py`
      - `a/b/tests/c/foo.py`

   各パターンは、[gitignore](https://git-scm.com/docs/gitignore#_pattern_format)と同じ構文を使用するglobスタイルのパターンです。

1. <a id="sast-excluded-paths-all-other-sast-analyzers"></a>これらのアナライザーで、`SAST_EXCLUDED_PATHS`は**ポストフィルター**として実装され、スキャンが実行された_後_に適用されます。

   パターンには、glob（サポートされているパターンについては[`doublestar.Match`](https://pkg.go.dev/github.com/bmatcuk/doublestar/v4@v4.0.2#Match)を参照）、またはファイルパスやフォルダパス（`doc,spec`など）を使用できます。親ディレクトリもパターンに一致します。

   `SAST_EXCLUDED_PATHS`のポストフィルター実装は、すべてのSASTアナライザーで使用できます。上付き文字**[2](#sast-excluded-paths-semgrep)**が付いたものなど、一部のSASTアナライザーは、`SAST_EXCLUDED_PATHS`をプリフィルターとポストフィルターの両方として実装します。プリフィルターは、スキャン対象のファイル数を減らすため、効率が向上します。

   `SAST_EXCLUDED_PATHS`をプリフィルターとポストフィルターの両方としてサポートするアナライザーの場合、最初にプリフィルターが適用され、次にポストフィルターが残りの脆弱性に適用されます。

1. <a id="sast-spotbugs-excluded-build-paths-description"></a>この変数では、パスパターンにはglob（サポートされているパターンについては[`doublestar.Match`](https://pkg.go.dev/github.com/bmatcuk/doublestar/v4@v4.0.2#Match)を参照）を使用できます。パスパターンがサポートされているビルドファイルと一致する場合、ディレクトリはビルドプロセスから除外されます。

   - `build.sbt`
   - `grailsw`
   - `gradlew`
   - `build.gradle`
   - `mvnw`
   - `pom.xml`
   - `build.xml`

   たとえば、パス`project/subdir/pom.xml`を持つビルドファイルを含む`maven`プロジェクトのビルドとスキャンを除外するには、`project/*/*.xml`や`**/*.xml`など、ビルドファイルに明示的に一致するglobパターン、または`project/subdir/pom.xml`のような完全一致を渡します。

   `project`や`project/subdir`など、パターンの親ディレクトリを渡しても、この場合、ビルドファイルはパターンによって明示的に一致_しない_ため、ディレクトリはビルドから除外_されません_。

1. <a id="search-max-depth-description"></a>[SAST CI/CDテンプレート](https://gitlab.com/gitlab-org/gitlab/blob/v17.4.1-ee/lib/gitlab/ci/templates/Jobs/SAST.gitlab-ci.yml)は、リポジトリを検索して使用されているプログラミング言語を検出し、一致するアナライザーを選択します。次に、各アナライザーはコードベースを検索し、スキャンする必要がある特定のファイルまたはディレクトリを見つけます。アナライザーの検索フェーズが対象とすべきディレクトリレベルの数を指定するには、`SEARCH_MAX_DEPTH`の値を設定します。

#### アナライザーの設定

一部のアナライザーは、CI/CD変数を使用してカスタマイズできます。

| CI/CD変数              | アナライザー   | 説明                                                                                                                                                                                                                        |
|-----------------------------|------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `GITLAB_ADVANCED_SAST_ENABLED` | GitLab高度なSAST | `true`に設定して、[GitLab高度なSAST](gitlab_advanced_sast.md)スキャンを有効にします（GitLab Ultimateでのみ使用可能）。デフォルト: `false`。 |
| `SCAN_KUBERNETES_MANIFESTS` | Kubesec    | `"true"`に設定して、Kubernetes manifestをスキャンします。                                                                                                                                                                                      |
| `KUBESEC_HELM_CHARTS_PATH`  | Kubesec    | `helm`が`kubesec`がスキャンするKubernetes manifestを生成するために使用するHelmチャートへのオプションのパス。依存関係が定義されている場合、必要な依存関係をフェッチするために、`helm dependency build`を`before_script`で実行する必要があります。 |
| `KUBESEC_HELM_OPTIONS`      | Kubesec    | `helm`実行可能ファイルの追加引数。                                                                                                                                                                                    |
| `COMPILE`                   | SpotBugs   | プロジェクトのコンパイルと依存関係のフェッチを無効にするには、`false`に設定します。                                                                                                                                                                                                        |
| `ANT_HOME`                  | SpotBugs   | `ANT_HOME`変数。                                                                                                                                                                                                        |
| `ANT_PATH`                  | SpotBugs   | `ant`実行可能ファイルへのパス。                                                                                                                                                                                                     |
| `GRADLE_PATH`               | SpotBugs   | `gradle`実行可能ファイルへのパス。                                                                                                                                                                                                   |
| `JAVA_OPTS`                 | SpotBugs   | `java`実行可能ファイルの追加引数。                                                                                                                                                                                    |
| `JAVA_PATH`                 | SpotBugs   | `java`実行可能ファイルへのパス。                                                                                                                                                                                                     |
| `SAST_JAVA_VERSION`         | SpotBugs   | 使用するJavaのバージョン。[GitLab 15.0以降](https://gitlab.com/gitlab-org/gitlab/-/issues/352549)、サポートされているバージョンは`11`と`17`（デフォルト）です。GitLab 15.0より前、サポートされているバージョンは、`8`（デフォルト）と`11`です。     |
| `MAVEN_CLI_OPTS`            | SpotBugs   | `mvn`または`mvnw`実行可能ファイルの追加引数。                                                                                                                                                                           |
| `MAVEN_PATH`                | SpotBugs   | `mvn`実行可能ファイルへのパス。                                                                                                                                                                                                      |
| `MAVEN_REPO_PATH`           | SpotBugs   | Mavenローカルリポジトリへのパス（`maven.repo.local`プロパティのショートカット）。                                                                                                                                                 |
| `SBT_PATH`                  | SpotBugs   | `sbt`実行可能ファイルへのパス。                                                                                                                                                                                                      |
| `FAIL_NEVER`                | SpotBugs   | コンパイルの失敗を無視するには、`1`に設定します。                                                                                                                                                                                          |
| `SAST_SEMGREP_METRICS` | Semgrep | 匿名化されたスキャンメトリクスを[r2c](https://semgrep.dev)に送信しないようにするには、`"false"`に設定します。デフォルト: `true`。 |
| `SAST_SCANNER_ALLOWED_CLI_OPTS`        | Semgrep | スキャン操作の実行時に、基盤となるセキュリティスキャナーに渡されるコマンドラインインターフェース（CLI）オプション（値、またはフラグを持つ引数）。限られた[オプション](#security-scanner-configuration)セットのみが受け入れられます。CLIオプションとその値は、空白または等号（`=`）文字を使用して区切ります。例: `name1 value1`または`name1=value1`。複数のオプションは空白で区切る必要があります。例: `name1 value1 name2 value2`。GitLab 15.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/368565)されました。 |
| `SAST_RULESET_GIT_REFERENCE` | すべて     | カスタムルールセット設定へのパスを定義します。プロジェクトに`.gitlab/sast-ruleset.toml`ファイルがコミットされている場合、そのローカル設定が優先され、`SAST_RULESET_GIT_REFERENCE`のファイルは使用されません。この変数は、Ultimateプランでのみ使用できます。|
| `SECURE_ENABLE_LOCAL_CONFIGURATION` | すべて     | カスタムルールセット設定を使用するオプションを有効にします。`SECURE_ENABLE_LOCAL_CONFIGURATION`が`false`に設定されている場合、`.gitlab/sast-ruleset.toml`にあるプロジェクトのカスタムルールセット設定ファイルは無視され、`SAST_RULESET_GIT_REFERENCE`のファイルまたはデフォルト設定が優先されます。 |

#### セキュリティスキャナーの設定

SASTアナライザーは、内部的にOSSセキュリティスキャナーを使用して分析を実行します。セキュリティスキャナーに推奨される設定を行っているため、調整について心配する必要はありません。ただし、まれですが、デフォルトのスキャナー設定が要件に適合しない場合があります。

スキャナーの動作をある程度カスタマイズできるようにするには、基になるスキャナーに制限付きのフラグセットを追加します。`SAST_SCANNER_ALLOWED_CLI_OPTS` CI/CD変数でフラグを指定します。これらのフラグは、スキャナーのCLIオプションに追加されます。

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
      <td rowspan="1">
        GitLab高度なSAST
      </td>
      <td>
        <code>--multi-core</code>
      </td>
      <td>
        マルチコアスキャンはデフォルトで有効になっており、コンテナ情報に基づいて利用可能なCPUコアを自動的に検出して利用します。セルフホストRunnerでは、コアの最大数は4に制限されています。<code>--multi-core</code>を特定の値に明示的に設定することで、自動コア検出をオーバーライドできます。マルチコア実行では、シングルコア実行と比較したとき、必要なメモリが比例的に増加します。マルチコアスキャンを無効にするには、環境変数<code>DISABLE_MULTI_CORE</code>を設定します。利用可能なコアまたはメモリリソースを超えると、リソースの競合が発生し、パフォーマンスが最適でなくなる可能性があることに注意してください。
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
        1つのファイルでルールを実行する際に使用する、最大システムメモリ（MB単位）を設定します。
      </td>
    </tr>
    <tr>
      <td>
        <code>--max-target-bytes</code>
      </td>
      <td>
        <p>
          スキャン対象ファイルの最大サイズ。これを超えるサイズのインプットプログラムは無視されます。このフィルターを無効にするには、<code>0</code>または負の値を設定します。バイト数は、測定単位の有無にかかわらず指定できます。例:<code>12.5kb</code>、<code>1.5MB</code>、または<code>123</code>。デフォルトは<code>1000000</code>バイトです。
        </p>
        <p>
          <b>注: </b>このフラグはデフォルト値に設定したままにする必要があります。また、このフラグを変更して縮小されたJavaScriptをスキャンすることは避けてください。うまく動作しない可能性があります。バイナリファイルはスキャンされないため、<code>DLL</code>、<code>JAR</code>、またはその他のバイナリファイルのスキャンも避けてください。
        </p>
      </td>
    </tr>
    <tr>
      <td>
        <code>--timeout</code>
      </td>
      <td>
        1つのファイルに対してルールを実行するために費やす最大時間（秒）。時間制限を設けない場合は、<code>0</code>に設定します。タイムアウト値は整数にする必要があります。例: <code>10</code>または<code>15</code>。デフォルトは<code>5</code>です。
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
        分析の労力レベルを設定します。有効な値は、精度とより多くの脆弱性を検出する能力の昇順で、<code>min</code>、<code>less</code>、<code>more</code>、<code>max</code>となります。デフォルト値は<code>max</code>に設定されています。プロジェクトのサイズによっては、スキャンを完了するためにより多くのメモリと時間が必要になる場合があります。メモリやパフォーマンスの問題が発生した場合は、分析の労力レベルの値を低くできます。例: <code>-effort less</code>。
      </td>
    </tr>
  </tbody>
</table>

#### カスタムCI/CD変数

前述のSAST設定CI/CD変数だけでなく、[SASTベンダーテンプレート](#configuration)を使用している場合、すべての[カスタム変数](../../../ci/variables/_index.md#define-a-cicd-variable-in-the-ui)が基盤となるSASTアナライザーイメージに伝播されます。

### 分析からコードを除外する

脆弱性の分析から除外するコードの個々の行またはブロックをマークできます。すべての脆弱性を脆弱性管理で管理するか、検出結果ごとにコメント注釈を追加する方法を使用する前に、`SAST_EXCLUDED_PATHS`を使用してスキャンされたファイルパスを調整する必要があります。

Semgrepベースのアナライザーを使用する場合、次のオプションも使用できます。

- コード行を無視する - 行の末尾に`// nosemgrep:`コメントを追加します（プレフィックスは開発言語に従います）。

  Javaの例:

  ```java
  vuln_func(); // nosemgrep
  ```

  Pythonの例:

  ```python
  vuln_func(); # nosemgrep
  ```

- 特定のルールに対してコード行を無視する - 行の末尾に`// nosemgrep: RULE_ID`コメントを追加します（プレフィックスは開発言語に従います）。

- ファイルまたはディレクトリを無視する - リポジトリのルートディレクトリまたはプロジェクトの作業ディレクトリに`.semgrepignore`ファイルを作成し、そこにファイルとフォルダーのパターンを追加します。

詳細については、[Semgrepのドキュメント](https://semgrep.dev/docs/ignoring-files-folders-code)を参照してください。

## オフライン環境でSASTを実行する

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

インターネット経由での外部リソースへのアクセスが制限されている環境やアクセスが断続的な環境のインスタンスでは、SASTジョブを正常に実行するためにいくつかの調整が必要です。詳細については、「[オフライン環境](../offline_deployments/_index.md)」を参照してください。

### オフラインSASTの要件

オフライン環境でSASTを使用するには、以下が必要です。

- [`docker`または`kubernetes`executor](#requirements)を備えたGitLab Runner
- ローカルで利用可能なSAST[アナライザー](https://gitlab.com/gitlab-org/security-products/analyzers)イメージのコピーを含むDockerコンテナレジストリ
- パッケージの証明書チェックの設定（オプション）

GitLab Runnerでは、[デフォルトで`pull_policy`が`always`](https://docs.gitlab.com/runner/executors/docker.html#using-the-always-pull-policy)になっています。つまり、ローカルコピーが利用可能な場合でも、RunnerはGitLabコンテナレジストリからDockerイメージをプルしようとします。ローカルで利用可能なDockerイメージのみを使用する場合は、オフライン環境でGitLab Runnerの[`pull_policy`を`if-not-present`に設定できます](https://docs.gitlab.com/runner/executors/docker.html#using-the-if-not-present-pull-policy)。ただし、オフライン環境でない場合は、プルポリシーの設定を`always`のままにしておくことをおすすめします。これにより、CI/CDパイプラインで更新されたスキャナーを使用できるようになります。

### Dockerレジストリ内でGitLab SASTアナライザーイメージを利用できるようにする

すべての[サポートされている言語とフレームワーク](#supported-languages-and-frameworks)に対応したSASTの場合、`registry.gitlab.com`から次のデフォルトSASTアナライザーイメージを[ローカルのDockerコンテナレジストリ](../../packages/container_registry/_index.md)にインポートします。

```plaintext
registry.gitlab.com/security-products/gitlab-advanced-sast:1
registry.gitlab.com/security-products/kubesec:5
registry.gitlab.com/security-products/pmd-apex:5
registry.gitlab.com/security-products/semgrep:5
registry.gitlab.com/security-products/sobelow:5
registry.gitlab.com/security-products/spotbugs:5
```

DockerイメージをローカルのオフラインDockerレジストリにインポートするプロセスは、**ネットワークのセキュリティポリシー**によって異なります。IT部門に相談して、外部リソースをインポートまたは一時的にアクセスするための承認済みプロセスを確認してください。これらのスキャナーは新しい定義で[定期的に更新](../_index.md#vulnerability-scanner-maintenance)されています。また、自分で随時更新できる場合もあります。

Dockerイメージをファイルとして保存および転送する方法の詳細については、[`docker save`](https://docs.docker.com/reference/cli/docker/image/save/)、[`docker load`](https://docs.docker.com/reference/cli/docker/image/load/)、[`docker export`](https://docs.docker.com/reference/cli/docker/container/export/)、[`docker import`](https://docs.docker.com/reference/cli/docker/image/import/)に関するDockerドキュメントを参照してください。

#### カスタム公開認証局（CA）のサポートが必要な場合

次のバージョンで、カスタム公開認証局（CA）のサポートが導入されました。

| アナライザー               | バージョン                                                                                                    |
| --------               | -------                                                                                                    |
| `kubesec`              | [v2.1.0](https://gitlab.com/gitlab-org/security-products/analyzers/kubesec/-/releases/v2.1.0)              |
| `pmd-apex`             | [v2.1.0](https://gitlab.com/gitlab-org/security-products/analyzers/pmd-apex/-/releases/v2.1.0)             |
| `semgrep`              | [v0.0.1](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep/-/releases/v0.0.1)              |
| `sobelow`              | [v2.2.0](https://gitlab.com/gitlab-org/security-products/analyzers/sobelow/-/releases/v2.2.0)              |
| `spotbugs`             | [v2.7.1](https://gitlab.com/gitlab-org/security-products/analyzers/spotbugs/-/releases/v2.7.1)             |

### ローカルのSASTアナライザーを使用するようにSAST CI/CD変数を設定する

次の設定を`.gitlab-ci.yml`ファイルに追加します。ローカルのDockerコンテナレジストリを参照するように、`SECURE_ANALYZERS_PREFIX`を置き換える必要があります。

```yaml
include:
  - template: Jobs/SAST.gitlab-ci.yml

variables:
  SECURE_ANALYZERS_PREFIX: "localhost:5000/analyzers"
```

SASTジョブは、インターネットアクセスを必要とせずに、SASTアナライザーのローカルコピーを使用してコードをスキャンし、セキュリティレポートを生成するようになりました。

### パッケージの証明書チェックを設定する

SASTジョブがパッケージマネージャーを呼び出す場合は、その証明書の検証を設定する必要があります。オフライン環境では、外部ソースを使用して証明書を検証することはできません。自己署名証明書を使用するか、証明書の検証を無効にします。手順については、パッケージマネージャーのドキュメントを参照してください。

## SELinuxでSASTを実行する

デフォルトで、SASTアナライザーは、SELinuxでホストされているGitLabインスタンスでサポートされています。[オーバーライドされたSASTジョブ](#overriding-sast-jobs)に`before_script`を追加すると、SELinuxでホストされているRunnerの権限が制限されているため、動作しない場合があります。
