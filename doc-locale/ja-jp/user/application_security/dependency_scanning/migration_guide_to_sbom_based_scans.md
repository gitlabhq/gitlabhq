---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: SBOMを使用した依存関係スキャンに移行する
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- 依存関係スキャン機能は、Gemnasiumアナライザーに基づいており、GitLab 17.9で非推奨になり、GitLab 20.0で削除が提案されています。ただし、削除タイムラインは確定しておらず、必要に応じてGemnasiumを引き続き使用できます。

{{< /history >}}

依存関係スキャン機能は、GitLab SBOM脆弱性スキャナーにアップグレードされます。この変更の一環として、[SBOMを使用した依存関係スキャン](dependency_scanning_sbom/_index.md)機能と[新しい依存関係スキャンアナライザー](https://gitlab.com/gitlab-org/security-products/analyzers/dependency-scanning)が、[Gemnasiumアナライザー](https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium)に基づく従来の依存関係スキャン機能を置き換えます。しかし、この移行によって導入された大幅な変更のため、既存のプロジェクトは自動的に移行されません。

GitLab依存関係スキャンを使用しており、以下のいずれかの条件が当てはまる場合は、この移行ガイドに従ってください:

- 依存関係スキャンCI/CDジョブは、依存関係スキャンCI/CDテンプレートのいずれかを含めることによって設定されます。

  ```yaml
    include:
      - template: Jobs/Dependency-Scanning.gitlab-ci.yml
      - template: Jobs/Dependency-Scanning.latest.gitlab-ci.yml
  ```

- 依存関係スキャンCI/CDジョブは、[スキャン実行ポリシー](../policies/scan_execution_policies.md)を使用して設定されます。
- 依存関係スキャンCI/CDジョブは、[パイプライン実行ポリシー](../policies/pipeline_execution_policies.md)を使用して設定されます。

## 移行の準備 {#prepare-for-migration}

移行の労力を評価し、移行パスを特定し、前提条件を確認し、影響を受けるプロジェクトを決定します。

### 移行作業の見積もり {#estimate-migration-effort}

[Dependency Scanning migration evaluator](https://dependency-scanning-migration-evaluator-cb84d1.gitlab.io/)は、プロジェクトでの依存関係スキャンの設定方法に基づいて、カスタマイズされた移行チェックリストを生成します。それは、イネーブルメントパス、言語エコシステム、CI/CDのカスタマイズ、および（Self-Managedインスタンスの場合）パッケージメタデータデータベースの同期ステータスについて尋ねます。評価ツールは以下を生成します:

- 作業の見積もり（最小、中程度、重要、または複雑）。
- お客様のセットアップに適用される移行手順のチェックリストで、このガイドの関連セクションへの直接リンク付きです。
- 特に注意が必要な状況（例えば、スキャン実行ポリシーからパイプライン実行ポリシーへ移行する必要があるプロジェクトなど）を示すフラグ。

評価ツールは完全にブラウザで実行され、データをどこにも送信しません。

### 移行パスの特定 {#identify-your-migration-path}

既存の設定は自動的に移行されません。新しい機能を採用するには、設定を更新する必要があります。

お客様に適用される移行パスを見つけるには、以下のリストを使用してください:

- 安定したテンプレート（`Jobs/Dependency-Scanning.gitlab-ci.yml`）: [一般的な移行手順](#migrate-to-dependency-scanning-using-sbom)に従って`v2`テンプレートに切り替え、プロジェクトで使用されているエコシステムに合わせて[言語固有の指示](#language-specific-instructions)を適用します。
- 最新テンプレート（`Jobs/Dependency-Scanning.latest.gitlab-ci.yml`）: 安定版テンプレートと同じです。[一般的な移行手順](#migrate-to-dependency-scanning-using-sbom)に従って`v2`テンプレートに切り替え、[言語固有の指示](#language-specific-instructions)を適用します。
- CI/CDコンポーネント: [main component](https://gitlab.com/components/dependency-scanning/-/tree/main/templates/main)はすでに新しいアナライザーを使用していますが、古いバージョン（v0とv1）はアナライザーのバージョンおよびサポートされている入力に関してラグがあります。includeを`v2`バージョンに引き上げ、[言語固有の指示](#language-specific-instructions)を適用します。特定のAndroid、Rust、Swift、またはCocoaPodsコンポーネントを使用している場合は、メインコンポーネントに移行してください。
- スキャン実行ポリシー（SEP）またはパイプライン実行ポリシー（PEP）: ポリシーを編集して`v2`テンプレートを参照し、[一般的な移行手順](#migrate-to-dependency-scanning-using-sbom)と、スコープ内のプロジェクトに適用される[言語固有の指示](#language-specific-instructions)に従ってください。SEPとPEPはCI/CDテンプレートの上に構築されているため、SEPが更新された後、テンプレートの変更はスコープ内のすべてのプロジェクトに自動的に伝播されます。PEPの場合、ポリシーのCI/CD設定を直接更新して、`v2`テンプレートを参照します。

### 前提条件の確認: パッケージメタデータデータベースの同期 {#verify-prerequisites-package-metadata-database-synchronization}

新しい依存関係スキャンアナライザーは、プロジェクトで使用されるパッケージタイプ用に[Package Metadata Database（PMDB）](../../../administration/settings/security_and_compliance.md#package-metadata-database-synchronization)が同期されている必要があります。GitLab.comでは、インスタンスはすでにサポートされているすべてのパッケージタイプについてデータを同期しています。GitLab Self-ManagedとGitLab Dedicatedでは、管理者が同期を設定します。

移行する前に、管理者は次のことを行う必要があります:

- PMDB同期が有効になっており、プロジェクトで利用するパッケージタイプが選択されていることを確認してください。詳細については、[choose package registry metadata to sync](../../../administration/settings/security_and_compliance.md#choose-package-registry-metadata-to-sync)を参照してください。
- オフラインまたはファイアウォールで保護されたインスタンスの場合、[enabling the Package Metadata Database](../../../topics/offline/quick_start_guide.md#enabling-the-package-metadata-database)に従ってください。

プロジェクトで利用するパッケージタイプに対してPMDB同期が完了していない場合、新しいアナライザーは対応するコンポーネントに対する勧告を解決できず、移行後にセキュリティの検出結果が欠落する可能性があります。

### 影響を受けるプロジェクトを特定する {#identify-affected-projects}

レガシー依存関係スキャン機能を使用しているプロジェクトを特定します。[セキュリティインベントリ](../security_inventory/_index.md)は、グループおよびプロジェクト全体のスキャナーのカバレッジの表示レベルを提供します。このステップが推奨される開始点です。

また、CI/CD設定でレガシーな使用箇所を見つけることもできます:

- レガシーテンプレートの`Jobs/Dependency-Scanning.gitlab-ci.yml`または`Jobs/Dependency-Scanning.latest.gitlab-ci.yml`を`.gitlab-ci.yml`ファイルに含める。
- スキャン実行ポリシーおよびパイプライン実行ポリシーにおける同じテンプレートへの参照。
- レガシーアナライザーのジョブ名（`gemnasium-dependency_scanning`、`gemnasium-maven-dependency_scanning`、`gemnasium-python-dependency_scanning`）が`.gitlab-ci.yml`ファイル、ポリシーYAML、または`needs:`もしくは`dependencies:`でそれらを使用するダウンストリームジョブに含まれている場合。

## 変更点を理解する {#understand-the-changes}

Gemnasiumアナライザーから新しい依存関係スキャンアナライザーへの移行は、技術的に大きな進化です。ほとんどのプロジェクトでは、[migrate to dependency scanning using SBOM](#migrate-to-dependency-scanning-using-sbom)に記載されているCI/CD設定のスイッチ以外に変更は必要ありません。このセクションで説明されている変更は、一部のプロジェクト（特にGradle、Maven、およびロックファイルを持たないPython）で追加のステップが必要な理由を理解するのに役立ちます。

主な変更点:

- 言語サポートとファイルのカバレッジの増加: 新しいアナライザーは、GemnasiumアナライザーがサポートするPythonおよびJavaのバージョンに制約されず、[ファイルカバレッジ](https://gitlab.com/gitlab-org/security-products/analyzers/dependency-scanning#supported-files)の増加の恩恵を受けます。
- パフォーマンスの向上: 新しいアナライザーは、既存のロックファイルや依存関係グラフのエクスポートを優先し、それらを持たないプロジェクトに対してのみエコシステム固有の[resolution jobs](dependency_scanning_sbom/_index.md#dependency-resolution)を実行します。
- より小さなアタックサーフェスとより柔軟な設定: アナライザーイメージはロックファイルとグラフのエクスポートのみを解析します。エコシステム固有の設定（プライベートレジストリ、カスタムCAバンドル、JVMオプション）は、関連する依存解決ジョブにのみ適用されます。解決イメージをビルド環境に合わせて上書きできます。

### セキュリティスキャンの新しいアプローチ {#a-new-approach-to-security-scanning}

レガシーの依存関係スキャン機能を使用する場合、すべてのスキャン作業はCI/CDパイプラインで実行されます。スキャンを実行すると、Gemnasiumアナライザーは2つの重要なタスクを同時に処理します。それは、プロジェクトの依存を識別し、GitLabアドバイザリデータベースのローカルコピーとその特定のセキュリティスキャンエンジンを使用して、それらの依存のセキュリティ分析を即座に実行します。その後、結果をさまざまなレポート（CycloneDX SBOMおよび依存関係スキャンセキュリティレポート）に出力します。

一方、SBOMを使用する依存関係スキャン機能は、静的到達可能性や脆弱性スキャンなどの他の分析から依存関係の検出を分離する、分解された依存関係分析アプローチに依存しています。これらのタスクは同じCI/CDジョブで実行されますが、分離された再利用可能なコンポーネントとして機能します。例えば、脆弱性スキャン分析は、統合されたエンジンであるGitLabSBOM脆弱性スキャナーを再利用し、GitLab継続的脆弱性スキャン機能もサポートします。これにより、将来のインテグレーションポイントの機会も開かれ、より柔軟な脆弱性スキャンワークフローが可能になります。

SBOMを使用する依存関係スキャンがどのように[scans an application](dependency_scanning_sbom/_index.md#how-it-scans-an-application)するかについて詳しくは、こちらをお読みください。

### Gradle、Maven、およびPythonの依存関係検出 {#dependency-detection-for-gradle-maven-and-python}

新しいアナライザーは、Gradle、Maven、およびPythonプロジェクトの依存関係がどのように検出されるかを変更します。依存関係を特定するためにアプリケーションをビルドする代わりに、アナライザーは「精度はダイヤルである」という原則に従う多層検出モデルを使用します:

1. ロックファイルまたは依存関係グラフのエクスポート: サポートされているファイルがリポジトリにコミットされた場合、またはジョブアーティファクトとして渡された場合（`maven.graph.json`、`dependencies.lock`、`requirements.txt`、`Pipfile.lock`など）、アナライザーはそれを直接使用します。これが最も正確なオプションです。
1. [依存関係解決](dependency_scanning_sbom/_index.md#dependency-resolution): Maven、Gradle、またはPythonプロジェクトでサポートされているファイルが存在しない場合、アナライザーは自動的にファイルを生成しようとします。解決ジョブは、最小限のエコシステムイメージとネイティブコマンド（`mvn dependency:tree`、`pip-compile`、`gradle dependencies`など）を使用して`.pre`ステージで実行されます。`dependency-scanning`ジョブは生成されたアーティファクトを使用します。
1. [マニフェストフォールバック](dependency_scanning_sbom/_index.md#manifest-fallback): ロックファイルまたは依存関係グラフファイルが存在しない場合、アナライザーはサポートされているマニフェストファイル（`pom.xml`、`requirements.txt`、`build.gradle`、`build.gradle.kts`など）を解析して、直接の依存関係のみを抽出します。推移的依存関係は検出されず、正確な解決済みバージョンを特定することはできません。

GitLab 19.0以降では、依存解決とマニフェストフォールバックがデフォルトで有効になっています。

最も正確な結果を得るには、ロックファイルまたは依存関係グラフのエクスポートをリポジトリにコミットするか、プロジェクトの実際のビルド環境を使用して、先行するCI/CDジョブで生成してください。以下のセクションでは、各言語およびパッケージマネージャーで利用可能なオプションについて説明します。

### スキャン結果へのアクセス {#accessing-scan-results}

`v2`テンプレートは、レガシーテンプレートと同じ[`gl-dependency-scanning-report.json`](../../../ci/yaml/artifacts_reports.md#artifactsreportsdependency_scanning)ジョブアーティファクトを生成します。このアーティファクトを利用するダウンストリームジョブ（`needs:`または`dependencies:`を使用）は、移行後も引き続き機能しますが、生成するジョブ名は`gemnasium-dependency_scanning`（およびそのMavenおよびPythonバリアント）から`dependency-scanning`に変更されます。

## SBOMを使用した依存関係スキャンへの移行 {#migrate-to-dependency-scanning-using-sbom}

移行方法は、プロジェクトで依存関係スキャンがどのように有効になっているかによって異なります。各サブセクションでは、削除するカスタマイズ、更新する参照、および最小限の変更前後の例について説明します。

あなたに該当するサブセクションを見つけるには、[identify your migration path](#identify-your-migration-path)を参照してください。多言語プロジェクトの場合は、[language-specific instructions](#language-specific-instructions)の各言語の手順を完了してください。

### 安定版CI/CDテンプレートを使用した移行 {#migrate-using-the-stable-cicd-template}

既存のパイプラインへの影響を避けるため、安定版テンプレート（`Jobs/Dependency-Scanning.gitlab-ci.yml`）はレガシーGemnasiumアナライザーを実行し、新しいアナライザーを使用するように更新されません。新しいアナライザーを導入するには、`include`を`v2`テンプレート（`Jobs/Dependency-Scanning.v2.gitlab-ci.yml`）に切り替えてください。

安定版テンプレートと比較して、`v2`テンプレートは次の通りです:

- レガシーの`gemnasium-dependency_scanning`、`gemnasium-maven-dependency_scanning`、`gemnasium-python-dependency_scanning`ジョブの代わりに、新しい`dependency-scanning`ジョブを実行します。
- レガシージョブ名は事前定義されません。`gemnasium-*`ジョブを上書きするカスタマイズ（たとえば、`.gitlab-ci.yml`でそれらを拡張することによって）は、もはや適用されず、削除または書き換えが必要です。
- `gl-dependency-scanning-report.json`[ジョブアーティファクト](../../../ci/yaml/artifacts_reports.md#artifactsreportsdependency_scanning)を生成し続けます。`needs:`または`dependencies:`を介してこのアーティファクトを使用するダウンストリームジョブは、移行後も引き続き機能しますが、レガシーの`gemnasium-*`ジョブ名ではなく、新しい`dependency-scanning`ジョブ名を参照する必要があります。
- [Changes to CI/CD variables](#changes-to-cicd-variables)に記載されているいくつかの変更点を除き、同じCI/CD変数を受け入れます。

前提条件: 

- プロジェクトのデベロッパー、メンテナー、またはオーナーロール。

安定版CI/CDテンプレートを使用して移行するには:

1. `.gitlab-ci.yml`または含まれているファイルでレガシーの`gemnasium-*`ジョブを上書きするカスタマイズを削除します。`v2`テンプレートはこれらのジョブ名を定義しないため、オーバーライドによって無効なCI/CD設定のためにパイプラインが失敗する可能性があります。
1. `include`ステートメントを更新して、`v2`テンプレートを参照します。
1. `needs:`または`dependencies:`でレガシージョブ名を参照するダウンストリームジョブを、代わりに`dependency-scanning`を使用するように更新します。
1. プロジェクト内のエコシステムについて、[language-specific instructions](#language-specific-instructions)にある言語固有の指示を適用します。

変更前:

```yaml
include:
  - template: Jobs/Dependency-Scanning.gitlab-ci.yml

# Customization that targets the legacy job name.
gemnasium-dependency_scanning:
  variables:
    SECURE_LOG_LEVEL: debug

# Downstream job that consumes the legacy report.
export-security-report:
  stage: deploy
  needs:
    - job: gemnasium-dependency_scanning
      artifacts: true
  script:
    - ./publish.sh gl-dependency-scanning-report.json
```

変更後:

```yaml
include:
  - template: Jobs/Dependency-Scanning.v2.gitlab-ci.yml
    inputs:
      analyzer_log_level: debug

export-security-report:
  stage: deploy
  needs:
    - job: dependency-scanning
      artifacts: true
  script:
    - ./publish.sh gl-dependency-scanning-report.json
```

依存解決の前にカスタムジョブを実行する必要があるパイプラインの場合（たとえば、プライベートレジストリに認証するため、またはビルドキャッシュを準備するため）は、[adjust resolution job ordering](#adjust-resolution-job-ordering)を参照してください。

### 最新のCI/CDテンプレートを使用した移行 {#migrate-using-the-latest-cicd-template}

最新のテンプレート（`Jobs/Dependency-Scanning.latest.gitlab-ci.yml`）は、デフォルトでレガシーGemnasiumアナライザーを実行します。移行ステップとして、`DS_ENFORCE_NEW_ANALYZER`CI/CD変数を介して新しいアナライザーへのオプトインをサポートしていますが、新しいアナライザーのバージョン`v1`のみであり、[依存関係解決](dependency_scanning_sbom/_index.md#dependency-resolution)ジョブはありません。

前提条件: 

- プロジェクトのデベロッパー、メンテナー、またはオーナーロール。

Maven、Gradle、およびPythonプロジェクトの場合、次のいずれかを実行する必要があります:

- ロックファイルまたは[依存関係グラフエクスポート](dependency_scanning_sbom/_index.md#supported-languages-and-files)をリポジトリにコミットするか、先行するCI/CDジョブによって生成します。
- [マニフェストフォールバック](dependency_scanning_sbom/_index.md#manifest-fallback)を有効にします。

`v2`テンプレート（`v2`アナライザー、依存解決、マニフェストフォールバック）との完全な同等性のために、[stable template steps](#migrate-using-the-stable-cicd-template)に従って`v2`テンプレートに切り替えてください。移行作業は同じです。レガシーの`gemnasium-*`ジョブを対象とするカスタマイズを削除し、`include`ステートメントを更新し、ダウンストリームジョブを更新します。

すでに`DS_ENFORCE_NEW_ANALYZER`を介して新しいDSアナライザーを使用することにオプトインしている場合は、移行はより簡単です。移行を最終決定する前に、新しいテンプレートが導入する変更点を確認してください。

依存解決の前にカスタムジョブを実行する必要があるパイプラインの場合（たとえば、プライベートレジストリに認証するため、またはビルドキャッシュを準備するため）は、[adjust resolution job ordering](#adjust-resolution-job-ordering)を参照してください。

### CI/CDコンポーネントを使用した移行 {#migrate-using-the-cicd-component}

> [!note]
> GitLab Self-Managedでは、GitLab.comCI/CDコンポーネントを使用する際の[current limitations](../../../ci/components/_index.md#use-a-gitlabcom-component-on-gitlab-self-managed)を確認してください。

[main dependency scanning CI/CD component](https://gitlab.com/components/dependency-scanning/-/tree/main/templates/main)の`v2`リリースは、`v2`テンプレートと同等性があります。新しいアナライザーをその`v2`バージョンで実行し、同じ入力をサポートします。以前のリリース（`v0`と`v1`）は、アナライザーのバージョンとサポートされる機能で遅れているため、`v0`または`v1`を含むプロジェクトはインクルードを`v2`に上げる必要があります。

前提条件: 

- プロジェクトのデベロッパー、メンテナー、またはオーナーロール。

CI/CDコンポーネントを使用して移行するには:

1. コンポーネントの`include`ステートメントを更新して、メインコンポーネントのバージョン`2`を参照します。
1. `v2`で名前が変更されたか削除された入力をすべて置き換えます。メインコンポーネントの`v2`リリースは、`v2`CI/CDテンプレートと同じ入力セットを公開します。完全なリストについては、[available spec inputs](dependency_scanning_sbom/_index.md#available-spec-inputs)を参照してください。
1. プロジェクト内のエコシステムについて、[language-specific instructions](#language-specific-instructions)にある言語固有の指示を適用します。

Android、Rust、Swift、またはCocoaPods用の専用コンポーネントを使用している場合は、メインコンポーネントに移行してください。メインコンポーネントは、すべてのサポートされている言語とパッケージマネージャーをカバーしています。専用コンポーネントは不要になりました。

変更前:

```yaml
include:
  - component: $CI_SERVER_FQDN/components/dependency-scanning/main@1
```

変更後:

```yaml
include:
  - component: $CI_SERVER_FQDN/components/dependency-scanning/main@2
```

依存解決の前にカスタムジョブを実行する必要があるパイプラインの場合（たとえば、プライベートレジストリに認証するため、またはビルドキャッシュを準備するため）は、[adjust resolution job ordering](#adjust-resolution-job-ordering)を参照してください。

### スキャン実行ポリシーを使用した移行 {#migrate-using-scan-execution-policies}

スキャン実行ポリシーは、ポリシーの対象となるプロジェクト全体にCI/CDテンプレートを適用します。依存関係スキャンの場合、ポリシーの`template`フィールドは実行されるテンプレートを選択します。新しいアナライザーは`v2`テンプレートエディションを通じて利用できます。

対象となる各プロジェクトにおけるポリシーの動作は、対応するCI/CDテンプレートを直接含むプロジェクトの動作を反映します。ポリシーが`v2`を参照するように更新された後、[the stable CI/CD template](#migrate-using-the-stable-cicd-template)の手順がスコープ内の各プロジェクトに適用されます。レガシーの`gemnasium-*`ジョブを対象とするカスタマイズを削除し、それらを消費するダウンストリームジョブを更新してください。

前提条件: 

- グループのオーナーロール、または`manage_security_policy_link`権限を持つカスタムロール。

スキャン実行ポリシーを使用して移行するには:

1. スキャン実行ポリシーを編集し、`dependency_scanning`アクションに対して`template: v2`を設定します。
1. ポリシーでカバーされる各プロジェクトで、レガシーの`gemnasium-*`ジョブを上書きするカスタマイズを削除し、それらを参照するダウンストリームジョブを更新します。
1. ポリシーでカバーされるプロジェクトのエコシステムについて、[language-specific instructions](#language-specific-instructions)にある言語固有の指示を適用します。

変更前:

```yaml
scan_execution_policy:
  - name: Enforce dependency scanning
    enabled: true
    rules:
      - type: pipeline
        branch_type: all
    actions:
      - scan: dependency_scanning
```

変更後:

```yaml
scan_execution_policy:
  - name: Enforce dependency scanning
    enabled: true
    rules:
      - type: pipeline
        branch_type: all
    actions:
      - scan: dependency_scanning
        template: v2
```

#### 依存解決またはマニフェストフォールバックでカバーされないプロジェクト {#projects-not-covered-by-dependency-resolution-or-manifest-fallback}

スキャン実行ポリシーは、レガシーGemnasiumアナライザーの`build support`機能を使用して、デフォルトのビルド環境を提供します。新しいアナライザーは、コミットされたロックファイルまたは依存関係グラフのエクスポートがないプロジェクトの依存関係を検出するために、[依存関係解決](dependency_scanning_sbom/_index.md#dependency-resolution)または[マニフェストフォールバック](dependency_scanning_sbom/_index.md#manifest-fallback)に依存します。

これらのメカニズムは、以前`build support`に依存していたほとんどのプロジェクトをカバーします。いくつかの状況では、パイプライン実行ポリシーの追加の柔軟性が依然として役立ちます:

- プロジェクトのエコシステムが、依存解決とマニフェストフォールバックの現在のカバレッジの範囲外である（例: Scala/sbt）。
- 依存解決には、利用可能なCI/CD変数を超える設定ステップが必要です（たとえば、非標準の認証情報を使用してプライベートレジストリに対して認証する）。

これらのプロジェクトでは、CI/CDジョブをより自由にカスタマイズし、[create a lockfile or dependency graph export manually](dependency_scanning_sbom/_index.md#create-lockfile-or-dependency-graph-export-manually)できる[パイプライン実行ポリシー](#migrate-using-pipeline-execution-policies)を使用してください。

### パイプライン実行ポリシーを使用した移行 {#migrate-using-pipeline-execution-policies}

パイプライン実行ポリシーは、通常、依存関係スキャンテンプレートまたはCI/CDコンポーネントと、プロジェクト固有のカスタマイズを含む完全なCI/CD設定を適用します。適用される移行手順は、ポリシーのCI/CD設定が何を含むかによって異なります。

前提条件: 

- グループのオーナーロール、または`manage_security_policy_link`権限を持つカスタムロール。

パイプライン実行ポリシーを使用して移行するには:

1. ポリシーが使用するテンプレートまたはコンポーネントを特定します:
   - ポリシーに安定版CI/CDテンプレートが含まれている場合は、[migrate using the stable CI/CD template](#migrate-using-the-stable-cicd-template)に従ってください。
   - ポリシーに最新のCI/CDテンプレートが含まれている場合は、[migrate using the latest CI/CD template](#migrate-using-the-latest-cicd-template)に従ってください。
   - ポリシーにCI/CDコンポーネントが含まれている場合は、[migrate using the CI/CD component](#migrate-using-the-cicd-component)に従ってください。

1. それらの手順をポリシーのCI/CD設定に適用します。
1. ポリシーでカバーされるプロジェクトのエコシステムについて、[language-specific instructions](#language-specific-instructions)にある言語固有の指示を適用します。

プロジェクト、グループ、またはインスタンス用にCI/CD変数（およびポリシー自身の`variables:`ブロックで定義された変数）は、新しい`dependency-scanning`ジョブと、その前に実行される解決ジョブに引き続き適用されます。`v2`で変数のステータスが変更された場合は、[CI/CD変数の変更](#changes-to-cicd-variables)を参照してください。

依存解決の前にカスタムジョブを実行する必要があるパイプラインの場合（たとえば、プライベートレジストリに認証するため、またはビルドキャッシュを準備するため）は、[adjust resolution job ordering](#adjust-resolution-job-ordering)を参照してください。

## その他の考慮事項 {#other-considerations}

以下のカスタマイズは、プロジェクトで依存関係スキャンがどのように有効になっているかに関わらず適用されます。

### 解決ジョブの順序の調整 {#adjust-resolution-job-ordering}

デフォルトでは、依存関係解決ジョブは`.pre`ステージで実行されます。パイプラインに、依存関係スキャンが実行される前に完了する必要があるカスタムジョブがある場合（たとえば、プライベートレジストリに認証する`.pre`ジョブ、またはビルドキャッシュを準備するジョブなど）、解決ジョブはそれらのカスタムジョブと並行して実行され、後に実行されることはありません。解決ジョブは、カスタムジョブが生成するアーティファクトを参照できません。

意図した順序を維持するには、`v2`テンプレートまたはCI/CDコンポーネントで`resolution_jobs_stage`入力を使用して、解決ジョブを後のステージに移動します:

```yaml
stages:
  - .pre
  - prepare
  - test

include:
  - template: Jobs/Dependency-Scanning.v2.gitlab-ci.yml
    inputs:
      resolution_jobs_stage: prepare

private-registry-cache-build:
  stage: .pre
  script:
    - ./scripts/login-private-registry.sh
    - ./scripts/build-dependency-cache.sh
```

その後、解決ジョブは、カスタム`.pre`ジョブが完了した後に`prepare`ステージで実行されます。解決ジョブの動作を制御する入力の完全なリストについては、[利用可能なCI/CDインプット](dependency_scanning_sbom/_index.md#available-spec-inputs)を参照してください。

## 言語固有の指示 {#language-specific-instructions}

新しい依存関係スキャンアナライザーに移行する際には、プロジェクトのプログラミング言語やパッケージマネージャーに基づいて、具体的な調整を行う必要があります。これらの指示は、CI/CDテンプレート、スキャン実行ポリシー、または依存関係スキャンCI/CDコンポーネントのいずれを介して実行するように設定した場合でも、新しい依存関係スキャンアナライザーを使用する際に常に適用されます。以下のセクションでは、サポートされている各言語とパッケージマネージャーに関する詳細な指示が記載されています。各指示には、以下の説明が含まれています:

- 依存関係の検出がどのように変化しているか
- 提供する必要がある特定のファイル
- これらのファイルがまだワークフローの一部でない場合に、どのように生成するか

この[フィードバックイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/523458)で、新しい依存関係スキャンアナライザーに関するご意見をお聞かせください。

### Bundler {#bundler}

**Previous behavior**: Gemnasiumアナライザーに基づいた依存関係スキャンは、`gemnasium-dependency_scanning` CI/CDジョブを使用してBundlerプロジェクトをサポートし、`Gemfile.lock`ファイル（`gems.locked`の代替ファイル名もサポートされています）を解析することでプロジェクトの依存関係を抽出できます。サポートされているBundlerのバージョンと`Gemfile.lock`ファイルの組み合わせについては、[依存関係スキャン（Gemnasiumベース）ドキュメント](legacy_dependency_scanning/_index.md#obtaining-dependency-information-by-parsing-lockfiles)で詳しく説明されています。

**New behavior**: 新しい依存関係スキャンアナライザーは、`Gemfile.lock`ファイル（`gems.locked`の代替ファイル名もサポートされています）を解析することでプロジェクトの依存関係を抽出し、`dependency-scanning` CI/CDジョブによってCycloneDX SBOMレポートアーティファクトを生成します。

#### Bundlerプロジェクトを移行する {#migrate-a-bundler-project}

新しい依存関係スキャンアナライザーを使用するようにBundlerプロジェクトを移行します。

前提条件: 

- すべてのプロジェクトに必要な[一般的な移行手順](#migrate-to-dependency-scanning-using-sbom)を完了してください。
- プロジェクトのデベロッパー、メンテナー、またはオーナーロール。

依存関係スキャンアナライザーを使用するようにBundlerプロジェクトを移行するために、追加の手順は必要ありません。

### CocoaPods {#cocoapods}

**Previous behavior**: Gemnasiumアナライザーに基づいた依存関係スキャンは、CI/CDテンプレートまたはスキャン実行ポリシーを使用する場合、CocoaPodsプロジェクトをサポートしていません。CocoaPodsのサポートは、実験的なCocoaPods CI/CDコンポーネントでのみ利用可能です。

**New behavior**: 新しい依存関係スキャンアナライザーは、`Podfile.lock`ファイルを解析することでプロジェクトの依存関係を抽出し、`dependency-scanning` CI/CDジョブによってCycloneDX SBOMレポートアーティファクトを生成します。

#### CocoaPodsプロジェクトを移行する {#migrate-a-cocoapods-project}

新しい依存関係スキャンアナライザーを使用するようにCocoaPodsプロジェクトを移行します。

前提条件: 

- すべてのプロジェクトに必要な[一般的な移行手順](#migrate-to-dependency-scanning-using-sbom)を完了してください。
- プロジェクトのデベロッパー、メンテナー、またはオーナーロール。

依存関係スキャンアナライザーを使用するようにCocoaPodsプロジェクトを移行するために、追加の手順は必要ありません。

### Composer {#composer}

**Previous behavior**: Gemnasiumアナライザーに基づいた依存関係スキャンは、`gemnasium-dependency_scanning` CI/CDジョブを使用してComposerプロジェクトをサポートし、`composer.lock`ファイルを解析することでプロジェクトの依存関係を抽出できます。サポートされているComposerのバージョンと`composer.lock`ファイルの組み合わせについては、[依存関係スキャン（Gemnasiumベース）ドキュメント](legacy_dependency_scanning/_index.md#obtaining-dependency-information-by-parsing-lockfiles)で詳しく説明されています。

**New behavior**: 新しい依存関係スキャンアナライザーは、`composer.lock`ファイルを解析することでプロジェクトの依存関係を抽出し、`dependency-scanning` CI/CDジョブによってCycloneDX SBOMレポートアーティファクトを生成します。

#### Composerプロジェクトを移行する {#migrate-a-composer-project}

新しい依存関係スキャンアナライザーを使用するようにComposerプロジェクトを移行します。

前提条件: 

- すべてのプロジェクトに必要な[一般的な移行手順](#migrate-to-dependency-scanning-using-sbom)を完了してください。
- プロジェクトのデベロッパー、メンテナー、またはオーナーロール。

依存関係スキャンアナライザーを使用するようにComposerプロジェクトを移行するために、追加の手順は必要ありません。

### Conan {#conan}

**Previous behavior**: Gemnasiumアナライザーに基づいた依存関係スキャンは、`gemnasium-dependency_scanning` CI/CDジョブを使用してConanプロジェクトをサポートし、`conan.lock`ファイルを解析することでプロジェクトの依存関係を抽出できます。サポートされているConanのバージョンと`conan.lock`ファイルの組み合わせについては、[依存関係スキャン（Gemnasiumベース）ドキュメント](legacy_dependency_scanning/_index.md#obtaining-dependency-information-by-parsing-lockfiles)で詳しく説明されています。

**New behavior**: 新しい依存関係スキャンアナライザーは、`conan.lock`ファイルを解析することでプロジェクトの依存関係を抽出し、`dependency-scanning` CI/CDジョブによってCycloneDX SBOMレポートアーティファクトを生成します。

#### Conanプロジェクトを移行する {#migrate-a-conan-project}

新しい依存関係スキャンアナライザーを使用するようにConanプロジェクトを移行します。

前提条件: 

- すべてのプロジェクトに必要な[一般的な移行手順](#migrate-to-dependency-scanning-using-sbom)を完了してください。
- プロジェクトのデベロッパー、メンテナー、またはオーナーロール。

依存関係スキャンアナライザーを使用するようにConanプロジェクトを移行するために、追加の手順は必要ありません。

### Go {#go}

**Previous behavior**: Gemnasiumアナライザーに基づいた依存関係スキャンは、Goプロジェクトを`gemnasium-dependency_scanning` CI/CDジョブを使用してサポートし、`go.mod`および`go.sum`ファイルを使用することでプロジェクトの依存関係を抽出できます。このアナライザーは、検出された依存関係の精度を高めるために`go list`コマンドの実行を試みますが、これには機能するGo環境が必要です。失敗した場合、`go.sum`ファイルの解析にフォールバックします。サポートされているGoのバージョン、`go.mod`、および`go.sum`ファイルの組み合わせについては、[依存関係スキャン（Gemnasiumベース）ドキュメント](legacy_dependency_scanning/_index.md#obtaining-dependency-information-by-parsing-lockfiles)で詳しく説明されています。

**New behavior**: 新しい依存関係スキャンアナライザーは、依存関係を抽出するためにプロジェクトで`go list`コマンドを実行しようとせず、`go.sum`ファイルの解析にフォールバックすることもありません。代わりに、プロジェクトは少なくとも`go.mod`ファイル、そして理想的にはGoツールチェーンの[`go mod graph`コマンド](https://go.dev/ref/mod#go-mod-graph)で生成された`go.graph`ファイルを提供する必要があります。`go.graph`ファイルは、検出されたコンポーネントの精度を高め、[依存関係パス](../dependency_list/_index.md#dependency-paths)のような機能を有効にするために依存関係グラフを生成するために必要です。これらのファイルは、`dependency-scanning` CI/CDジョブによって処理され、CycloneDX SBOMレポートアーティファクトが生成されます。このアプローチは、GitLabがGoの特定のバージョンをサポートすることを必要としません。[依存関係の解決](dependency_scanning_sbom/_index.md#dependency-resolution)はGoプロジェクトではサポートされていません。

#### Goプロジェクトを移行する {#migrate-a-go-project}

新しい依存関係スキャンアナライザーを使用するようにGoプロジェクトを移行します。

前提条件: 

- すべてのプロジェクトに必要な[一般的な移行手順](#migrate-to-dependency-scanning-using-sbom)を完了してください。
- プロジェクトのデベロッパー、メンテナー、またはオーナーロール。

Goプロジェクトを移行するには:

- プロジェクトが`go.mod`ファイルと`go.graph`ファイルを提供していることを確認してください。前のCI/CDジョブ（例: `build`ビルド）で、Goツールチェーンの[`go mod graph`コマンド](https://go.dev/ref/mod#go-mod-graph)を設定して、依存関係スキャンジョブを実行する前に`go.graph`ファイルを動的に生成し、[アーティファクト](../../../ci/jobs/job_artifacts.md)としてエクスポートするようにしてください。

詳細と例については、[Goの有効化手順](dependency_scanning_sbom/_index.md#go)を参照してください。

### Gradle {#gradle}

**Previous behavior**: Gemnasiumアナライザーに基づいた依存関係スキャンは、`gemnasium-maven-dependency_scanning` CI/CDジョブを使用してGradleプロジェクトをサポートし、`build.gradle`および`build.gradle.kts`ファイルからアプリケーションをビルドすることでプロジェクトの依存関係を抽出します。Java、Kotlin、およびGradleのサポートされているバージョンの組み合わせは複雑であり、[依存関係スキャン（Gemnasiumベース）ドキュメント](legacy_dependency_scanning/_index.md#obtaining-dependency-information-by-running-a-package-manager-to-generate-a-parsable-file)で詳しく説明されています。

**New behavior**: 新しい依存関係スキャンアナライザーは、依存関係を抽出するためにプロジェクトをビルドしません。代わりに、多層検出モデルを使用します:

- リポジトリまたはジョブのアーティファクトに[サポートされているロックファイルまたはグラフエクスポート](dependency_scanning_sbom/_index.md#supported-languages-and-files)（例: `gradle.lockfile`）が存在する場合、アナライザーはそれを直接使用します。
- サポートされているロックファイルまたはグラフエクスポートが検出されず、サポートされているビルドファイル（例: `build.gradle`）が存在する場合、[依存関係の解決](dependency_scanning_sbom/_index.md#dependency-resolution)ジョブが`.pre`ステージで実行されます。これは自動的に`gradle dependencies`を実行して、`dependency-scanning`ジョブ用の依存関係グラフをエクスポートするように生成します。
- 依存関係の解決が利用できないか失敗した場合、[マニフェストフォールバック](dependency_scanning_sbom/_index.md#manifest-fallback)は`build.gradle`と`build.gradle.kts`を直接解析することで、直接の依存関係のみを抽出します。マニフェストフォールバックの精度は、`gradle.properties`または`gradle/libs.versions.toml`を介して依存関係を宣言するプロジェクトでは低下します。これは、バージョン変数が常に解決されるわけではないためです。

#### Gradleプロジェクトを移行する {#migrate-a-gradle-project}

新しい依存関係スキャンアナライザーを使用するようにGradleプロジェクトを移行します。

前提条件: 

- すべてのプロジェクトに必要な[一般的な移行手順](#migrate-to-dependency-scanning-using-sbom)を完了してください。
- プロジェクトのデベロッパー、メンテナー、またはオーナーロール。

Gradleプロジェクトを移行するには、以下のいずれかのオプションを選択してください:

- 最も正確な結果を得るには、プロジェクトが依存関係グラフエクスポートファイルを提供していることを確認してください。前のCI/CDジョブ（例: `build`ビルド）で[Gradle dependenciesタスク](https://docs.gradle.org/current/userguide/viewing_debugging_dependencies.html)を設定して、依存関係スキャンジョブを実行する前に`gradle.graph.txt`ファイルを動的に生成し、[アーティファクト](../../../ci/jobs/job_artifacts.md)としてエクスポートするようにしてください。あるいは、別の[サポートされているロックファイルまたはグラフエクスポート](dependency_scanning_sbom/_index.md#supported-languages-and-files)を選択することもできます。ロックファイルまたはグラフエクスポートを動的に生成する場合、`DS_DISABLED_RESOLUTION_JOBS` CI/CD変数の値に`gradle`を追加して、自動的な依存関係の解決を無効にします。
- [依存関係の解決](dependency_scanning_sbom/_index.md#dependency-resolution)に頼って、`gradle.graph.txt`ファイルを自動的に生成します。解決イメージがグラフエクスポートを正常に生成できることを確認してください。
- [マニフェストフォールバック](dependency_scanning_sbom/_index.md#manifest-fallback)を利用して、`build.gradle`または`build.gradle.kts`で宣言された直接の依存関係のベースラインカバレッジを取得します。

詳細と例については、[Gradleの有効化手順](dependency_scanning_sbom/_index.md#gradle)を参照してください。

### Maven {#maven}

**Previous behavior**: Gemnasiumアナライザーに基づいた依存関係スキャンは、`gemnasium-maven-dependency_scanning` CI/CDジョブを使用してMavenプロジェクトをサポートし、`pom.xml`ファイルからアプリケーションをビルドすることでプロジェクトの依存関係を抽出します。Java、Kotlin、およびMavenのサポートされているバージョンの組み合わせは複雑であり、[依存関係スキャン（Gemnasiumベース）ドキュメント](legacy_dependency_scanning/_index.md#obtaining-dependency-information-by-running-a-package-manager-to-generate-a-parsable-file)で詳しく説明されています。

**New behavior**: 新しい依存関係スキャンアナライザーは、依存関係を抽出するためにプロジェクトをビルドしません。代わりに、多層検出モデルを使用します:

- [Maven dependency plugin](https://maven.apache.org/plugins/maven-dependency-plugin/index.html)で生成された`maven.graph.json`グラフエクスポートファイルがリポジトリまたはジョブのアーティファクトに存在する場合、アナライザーはそれを直接使用します。
- グラフエクスポートが検出されず、サポートされている`pom.xml`ファイルが存在する場合、[依存関係の解決](dependency_scanning_sbom/_index.md#dependency-resolution)ジョブが`.pre`ステージで実行されます。これは自動的に`mvn dependency:tree`を実行して、`dependency-scanning`ジョブ用の依存関係グラフをエクスポートするように生成します。
- 依存関係の解決が利用できないか失敗した場合、[マニフェストフォールバック](dependency_scanning_sbom/_index.md#manifest-fallback)は`pom.xml`を直接解析することで、直接の依存関係のみを抽出します。

#### Mavenプロジェクトを移行する {#migrate-a-maven-project}

新しい依存関係スキャンアナライザーを使用するようにMavenプロジェクトを移行します。

前提条件: 

- すべてのプロジェクトに必要な[一般的な移行手順](#migrate-to-dependency-scanning-using-sbom)を完了してください。
- プロジェクトのデベロッパー、メンテナー、またはオーナーロール。

Mavenプロジェクトを移行するには、以下のいずれかのオプションを選択してください:

- 最も正確な結果を得るには、プロジェクトが`maven.graph.json`ファイルを提供していることを確認してください。前のCI/CDジョブ（例: `build`ビルド）で[Maven dependency plugin](https://maven.apache.org/plugins/maven-dependency-plugin/index.html)を設定して、依存関係スキャンジョブを実行する前に`maven.graph.json`ファイルを動的に生成し、[アーティファクト](../../../ci/jobs/job_artifacts.md)としてエクスポートするようにしてください。グラフエクスポートを動的に生成する場合、`DS_DISABLED_RESOLUTION_JOBS` CI/CD変数の値に`maven`を追加して、自動的な依存関係の解決を無効にします。
- [依存関係の解決](dependency_scanning_sbom/_index.md#dependency-resolution)に頼って、`maven.graph.json`ファイルを自動的に生成します。解決イメージがグラフエクスポートを正常に生成できることを確認してください。
- [マニフェストフォールバック](dependency_scanning_sbom/_index.md#manifest-fallback)を利用して、`pom.xml`で宣言された直接の依存関係のベースラインカバレッジを取得します。

詳細と例については、[Mavenの有効化手順](dependency_scanning_sbom/_index.md#maven)を参照してください。

### npm {#npm}

**Previous behavior**: Gemnasiumアナライザーに基づいた依存関係スキャンは、npmプロジェクトを`gemnasium-dependency_scanning` CI/CDジョブを使用してサポートし、`package-lock.json`または`npm-shrinkwrap.json.lock`ファイルを解析することでプロジェクトの依存関係を抽出します。サポートされているnpmのバージョンと`package-lock.json`または`npm-shrinkwrap.json.lock`ファイルの組み合わせについては、[依存関係スキャン（Gemnasiumベース）ドキュメント](legacy_dependency_scanning/_index.md#obtaining-dependency-information-by-parsing-lockfiles)で詳しく説明されています。このアナライザーは、npmプロジェクトに含まれるJavaScriptファイルを`Retire.JS`スキャナーを使用してスキャンする場合があります。

**New behavior**: 新しい依存関係スキャンアナライザーは、`package-lock.json`または`npm-shrinkwrap.json.lock`ファイルを解析することでプロジェクトの依存関係を抽出し、`dependency-scanning` CI/CDジョブによってCycloneDX SBOMレポートアーティファクトを生成します。このアナライザーは、ベンダー提供のJavaScriptファイルをスキャンしません。詳細については、コンテキストと利用可能なアクションについて[JavaScriptベンダーライブラリの依存関係スキャン廃止のお知らせ](../../../update/deprecations.md#dependency-scanning-for-javascript-vendored-libraries)を参照してください。代替機能のサポートは、[エピック7186](https://gitlab.com/groups/gitlab-org/-/epics/7186)で提案されています。

#### npmプロジェクトを移行する {#migrate-an-npm-project}

新しい依存関係スキャンアナライザーを使用するようにnpmプロジェクトを移行します。

前提条件: 

- すべてのプロジェクトに必要な[一般的な移行手順](#migrate-to-dependency-scanning-using-sbom)を完了してください。
- プロジェクトのデベロッパー、メンテナー、またはオーナーロール。

依存関係スキャンアナライザーを使用するようにnpmプロジェクトを移行するために、追加の手順は必要ありません。

### NuGet {#nuget}

**Previous behavior**: Gemnasiumアナライザーに基づいた依存関係スキャンは、`gemnasium-dependency_scanning` CI/CDジョブを使用してNuGetプロジェクトをサポートし、`packages.lock.json`ファイルを解析することでプロジェクトの依存関係を抽出します。サポートされているNuGetのバージョンと`packages.lock.json`ファイルの組み合わせについては、[依存関係スキャン（Gemnasiumベース）ドキュメント](legacy_dependency_scanning/_index.md#obtaining-dependency-information-by-parsing-lockfiles)で詳しく説明されています。

**New behavior**: 新しい依存関係スキャンアナライザーは、`packages.lock.json`ファイルを解析することでプロジェクトの依存関係を抽出し、`dependency-scanning` CI/CDジョブによってCycloneDX SBOMレポートアーティファクトを生成します。

#### NuGetプロジェクトを移行する {#migrate-a-nuget-project}

新しい依存関係スキャンアナライザーを使用するようにNuGetプロジェクトを移行します。

前提条件: 

- すべてのプロジェクトに必要な[一般的な移行手順](#migrate-to-dependency-scanning-using-sbom)を完了してください。
- プロジェクトのデベロッパー、メンテナー、またはオーナーロール。

依存関係スキャンアナライザーを使用するようにNuGetプロジェクトを移行するために、追加の手順は必要ありません。

### pip {#pip}

**Previous behavior**: Gemnasiumアナライザーに基づいた依存関係スキャンは、Pipプロジェクトを`gemnasium-python-dependency_scanning` CI/CDジョブを使用してサポートし、`requirements.txt`ファイル（`requirements.pip`および`requires.txt`の代替ファイル名もサポートされています）からアプリケーションをビルドすることでプロジェクトの依存関係を抽出します。`PIP_REQUIREMENTS_FILE`環境変数を使用して、カスタムファイル名を指定することもできます。PythonとPipのサポートされているバージョンの組み合わせについては、[依存関係スキャン（Gemnasiumベース）ドキュメント](legacy_dependency_scanning/_index.md#obtaining-dependency-information-by-running-a-package-manager-to-generate-a-parsable-file)で詳しく説明されています。

**New behavior**: 新しい依存関係スキャンアナライザーは、依存関係を抽出するためにプロジェクトをビルドしません。代わりに、多層検出モデルを使用します:

- リポジトリまたはジョブのアーティファクトに[サポートされているロックファイルまたはグラフエクスポート](dependency_scanning_sbom/_index.md#supported-languages-and-files)（例: pip-compileで生成された`requirements.txt`）が存在する場合、アナライザーはそれを直接使用します。
- サポートされているロックファイルまたはグラフエクスポートが検出されず、サポートされているビルドファイル（例: `requirements.in`）が存在する場合、[依存関係の解決](dependency_scanning_sbom/_index.md#dependency-resolution)ジョブが`.pre`ステージで実行されます。これは自動的に`pip-compile`を実行して、`dependency-scanning`ジョブ用のロックファイルを生成します。
- 依存関係の解決が利用できないか失敗した場合、[マニフェストフォールバック](dependency_scanning_sbom/_index.md#manifest-fallback)は`requirements.txt`ファイルを直接解析することで、直接の依存関係のみを抽出します。

#### Pipプロジェクトを移行する {#migrate-a-pip-project}

新しい依存関係スキャンアナライザーを使用するようにPipプロジェクトを移行します。

前提条件: 

- すべてのプロジェクトに必要な[一般的な移行手順](#migrate-to-dependency-scanning-using-sbom)を完了してください。
- プロジェクトのデベロッパー、メンテナー、またはオーナーロール。

Pipプロジェクトを移行するには、以下のいずれかのオプションを選択してください:

- 最も正確な結果を得るには、プロジェクトがロックファイルを提供していることを確認してください。プロジェクトで[pip-compileコマンドラインツール](https://pip-tools.readthedocs.io/en/latest/cli/pip-compile/)を設定し、`requirements.txt`ロックファイルをリポジトリにコミットするか、または先行するCI/CDジョブ（例: `build`ビルド）で使用して、依存関係スキャンジョブを実行する前に`requirements.txt`ファイルを動的に生成し、[アーティファクト](../../../ci/jobs/job_artifacts.md)としてエクスポートするようにしてください。あるいは、別の[サポートされているロックファイルまたはグラフエクスポート](dependency_scanning_sbom/_index.md#supported-languages-and-files)を選択することもできます。ロックファイルまたはグラフエクスポートを動的に生成する場合、`DS_DISABLED_RESOLUTION_JOBS` CI/CD変数の値に`python`を追加して、自動的な依存関係の解決を無効にします。
- [依存関係の解決](dependency_scanning_sbom/_index.md#dependency-resolution)に頼って、`pipcompile.lock.txt`ファイルを自動的に生成します。解決イメージがロックファイルを正常に生成できることを確認してください。
- [マニフェストフォールバック](dependency_scanning_sbom/_index.md#manifest-fallback)を利用して、`requirements.txt`で宣言された直接の依存関係のベースラインカバレッジを取得します。

詳細と例については、[Pipの有効化手順](dependency_scanning_sbom/_index.md#pip)を参照してください。

### Pipenv {#pipenv}

**Previous behavior**: Gemnasiumアナライザーに基づいた依存関係スキャンは、`gemnasium-python-dependency_scanning` CI/CDジョブを使用してPipenvプロジェクトをサポートし、`Pipfile`ファイルまたは存在する場合は`Pipfile.lock`ファイルからアプリケーションをビルドすることでプロジェクトの依存関係を抽出します。PythonとPipenvのサポートされているバージョンの組み合わせについては、[依存関係スキャン（Gemnasiumベース）ドキュメント](legacy_dependency_scanning/_index.md#obtaining-dependency-information-by-running-a-package-manager-to-generate-a-parsable-file)で詳しく説明されています。

**New behavior**: 新しい依存関係スキャンアナライザーは、Pipenvプロジェクトをビルドして依存関係を抽出することはありません。代わりに、プロジェクトは少なくとも`Pipfile.lock`ファイル、そして理想的には[`pipenv graph`コマンド](https://pipenv.pypa.io/en/latest/cli.html#graph)によって生成された`pipenv.graph.json`ファイルを提供する必要があります。`pipenv.graph.json`ファイルは、依存関係グラフを生成し、[依存関係パス](../dependency_list/_index.md#dependency-paths)のような機能を有効にするために必要です。これらのファイルは、`dependency-scanning` CI/CDジョブによって処理され、CycloneDX SBOMレポートアーティファクトが生成されます。このアプローチは、GitLabがPythonとPipenvの特定のバージョンをサポートすることを必要としません。[依存関係の解決](dependency_scanning_sbom/_index.md#dependency-resolution)は、`Pipfile`ファイルがあり、`Pipfile.lock`ファイルがないプロジェクトではサポートされていません。

#### Pipenvプロジェクトを移行する {#migrate-a-pipenv-project}

新しい依存関係スキャンアナライザーを使用するようにPipenvプロジェクトを移行します。

前提条件: 

- すべてのプロジェクトに必要な[一般的な移行手順](#migrate-to-dependency-scanning-using-sbom)を完了してください。
- プロジェクトのデベロッパー、メンテナー、またはオーナーロール。

Pipenvプロジェクトを移行するには:

- プロジェクトが`Pipfile.lock`ファイルを提供していることを確認してください。プロジェクトで[`pipenv lock`コマンド](https://pipenv.pypa.io/en/latest/cli.html#graph)を設定し、`Pipfile.lock`ファイルをリポジトリにコミットするか、または先行するCI/CDジョブ（例: `build`ビルド）で使用して、依存関係スキャンジョブを実行する前に`Pipfile.lock`ファイルを動的に生成し、[アーティファクト](../../../ci/jobs/job_artifacts.md)としてエクスポートするようにしてください。あるいは、別の[サポートされているロックファイルまたはグラフエクスポート](dependency_scanning_sbom/_index.md#supported-languages-and-files)を選択することもできます。

### Poetry {#poetry}

**Previous behavior**: Gemnasiumアナライザーに基づいた依存関係スキャンは、`gemnasium-python-dependency_scanning` CI/CDジョブを使用してPoetryプロジェクトをサポートし、`poetry.lock`ファイルを解析することでプロジェクトの依存関係を抽出します。サポートされているPoetryのバージョンと`poetry.lock`ファイルの組み合わせについては、[依存関係スキャン（Gemnasiumベース）ドキュメント](legacy_dependency_scanning/_index.md#obtaining-dependency-information-by-parsing-lockfiles)で詳しく説明されています。

**New behavior**: 新しい依存関係スキャンアナライザーは、`poetry.lock`ファイルを解析することでプロジェクトの依存関係を抽出し、`dependency-scanning` CI/CDジョブによってCycloneDX SBOMレポートアーティファクトを生成します。

#### Poetryプロジェクトを移行する {#migrate-a-poetry-project}

新しい依存関係スキャンアナライザーを使用するようにPoetryプロジェクトを移行します。

前提条件: 

- すべてのプロジェクトに必要な[一般的な移行手順](#migrate-to-dependency-scanning-using-sbom)を完了してください。
- プロジェクトのデベロッパー、メンテナー、またはオーナーロール。

依存関係スキャンアナライザーを使用するようにPoetryプロジェクトを移行するために、追加の手順は必要ありません。

### pnpm {#pnpm}

**Previous behavior**: Gemnasiumアナライザーに基づいた依存関係スキャンは、pnpmプロジェクトを`gemnasium-dependency_scanning` CI/CDジョブを使用してサポートし、`pnpm-lock.yaml`ファイルを解析することでプロジェクトの依存関係を抽出します。サポートされているpnpmのバージョンと`pnpm-lock.yaml`ファイルの組み合わせについては、[依存関係スキャン（Gemnasiumベース）ドキュメント](legacy_dependency_scanning/_index.md#obtaining-dependency-information-by-parsing-lockfiles)で詳しく説明されています。このアナライザーは、npmプロジェクトに含まれるJavaScriptファイルを`Retire.JS`スキャナーを使用してスキャンする場合があります。

**New behavior**: 新しい依存関係スキャンアナライザーは、`pnpm-lock.yaml`ファイルを解析することでプロジェクトの依存関係を抽出し、`dependency-scanning` CI/CDジョブによってCycloneDX SBOMレポートアーティファクトを生成します。このアナライザーは、ベンダー提供のJavaScriptファイルをスキャンしません。詳細については、コンテキストと利用可能なアクションについて[JavaScriptベンダーライブラリの依存関係スキャン廃止のお知らせ](../../../update/deprecations.md#dependency-scanning-for-javascript-vendored-libraries)を参照してください。代替機能のサポートは、[エピック7186](https://gitlab.com/groups/gitlab-org/-/epics/7186)で提案されています。

#### pnpmプロジェクトを移行する {#migrate-a-pnpm-project}

新しい依存関係スキャンアナライザーを使用するようにpnpmプロジェクトを移行します。

前提条件: 

- すべてのプロジェクトに必要な[一般的な移行手順](#migrate-to-dependency-scanning-using-sbom)を完了してください。
- プロジェクトのデベロッパー、メンテナー、またはオーナーロール。

依存関係スキャンアナライザーを使用するようにpnpmプロジェクトを移行するために、追加の手順は必要ありません。

### sbt {#sbt}

**Previous behavior**: Gemnasiumアナライザーに基づいた依存関係スキャンは、`gemnasium-maven-dependency_scanning` CI/CDジョブを使用してsbtプロジェクトをサポートし、`build.sbt`ファイルからアプリケーションをビルドすることでプロジェクトの依存関係を抽出します。Java、Scala、およびsbtのサポートされているバージョンの組み合わせは複雑であり、[依存関係スキャン（Gemnasiumベース）ドキュメント](legacy_dependency_scanning/_index.md#obtaining-dependency-information-by-running-a-package-manager-to-generate-a-parsable-file)で詳しく説明されています。

**New behavior**: 新しい依存関係スキャンアナライザーは、依存関係を抽出するためにプロジェクトをビルドしません。代わりに、プロジェクトは[sbt-dependency-graphプラグイン](https://github.com/sbt/sbt-dependency-graph)（[sbt >= 1.4.0に含まれる](https://www.scala-sbt.org/1.x/docs/sbt-1.4-Release-Notes.html#sbt-dependency-graph+is+in-sourced)）で生成された`dependencies-compile.dot`ファイルを提供する必要があります。このファイルは、`dependency-scanning` CI/CDジョブによって処理され、CycloneDX SBOMレポートアーティファクトが生成されます。このアプローチは、GitLabがJava、Scala、およびsbtの特定のバージョンをサポートすることを必要としません。[依存関係の解決](dependency_scanning_sbom/_index.md#dependency-resolution)はsbtプロジェクトではサポートされていません。

#### sbtプロジェクトを移行する {#migrate-an-sbt-project}

新しい依存関係スキャンアナライザーを使用するようにsbtプロジェクトを移行します。

前提条件: 

- すべてのプロジェクトに必要な[一般的な移行手順](#migrate-to-dependency-scanning-using-sbom)を完了してください。
- プロジェクトのデベロッパー、メンテナー、またはオーナーロール。

sbtプロジェクトを移行するには:

- プロジェクトが`dependencies-compile.dot`ファイルを提供していることを確認してください。前のCI/CDジョブ（例: `build`ビルド）で[sbt-dependency-graphプラグイン](https://github.com/sbt/sbt-dependency-graph)を設定して、依存関係スキャンジョブを実行する前に`dependencies-compile.dot`ファイルを動的に生成し、[アーティファクト](../../../ci/jobs/job_artifacts.md)としてエクスポートするようにしてください。

詳細と例については、[sbtの有効化手順](dependency_scanning_sbom/_index.md#sbt)を参照してください。

### setuptools {#setuptools}

**Previous behavior**: Gemnasiumアナライザーに基づいた依存関係スキャンは、setuptoolsプロジェクトを`gemnasium-python-dependency_scanning` CI/CDジョブを使用してサポートし、`setup.py`ファイルからアプリケーションをビルドすることでプロジェクトの依存関係を抽出します。Pythonとsetuptoolsのサポートされているバージョンの組み合わせについては、[依存関係スキャン（Gemnasiumベース）ドキュメント](legacy_dependency_scanning/_index.md#obtaining-dependency-information-by-running-a-package-manager-to-generate-a-parsable-file)で詳しく説明されています。

**New behavior**: 新しい依存関係スキャンアナライザーは、setuptoolsプロジェクトをビルドして依存関係を抽出することはありません。代わりに、多層検出モデルを使用します:

- リポジトリまたはジョブのアーティファクトに[サポートされているロックファイルまたはグラフエクスポート](dependency_scanning_sbom/_index.md#supported-languages-and-files)（例: pip-compileで生成された`requirements.txt`）が存在する場合、アナライザーはそれを直接使用します。
- サポートされているロックファイルまたはグラフエクスポートが検出されず、サポートされているビルドファイル（例: `setup.py`）が存在する場合、[依存関係の解決](dependency_scanning_sbom/_index.md#dependency-resolution)ジョブが`.pre`ステージで実行されます。これは自動的に`pip-compile`を実行して、`dependency-scanning`ジョブ用のロックファイルを生成します。

#### setuptoolsプロジェクトを移行する {#migrate-a-setuptools-project}

新しい依存関係スキャンアナライザーを使用するようにsetuptoolsプロジェクトを移行します。

前提条件: 

- すべてのプロジェクトに必要な[一般的な移行手順](#migrate-to-dependency-scanning-using-sbom)を完了してください。
- プロジェクトのデベロッパー、メンテナー、またはオーナーロール。

setuptoolsプロジェクトを移行するには、以下のいずれかのオプションを選択してください:

- 最も正確な結果を得るには、プロジェクトが`requirements.txt`ロックファイルを提供していることを確認してください。プロジェクトで[pip-compileコマンドラインツール](https://pip-tools.readthedocs.io/en/latest/cli/pip-compile/)を設定し、以下のいずれかの方法で対応します:
  - コマンドラインツールを開発ワークフローに永続的に統合します。これは、`requirements.txt`ファイルをリポジトリにコミットし、プロジェクトの依存関係に変更を加えるたびに更新することを意味します。
  - コマンドラインツールを`build` CI/CDジョブで使用して、依存関係スキャンジョブを実行する前に`requirements.txt`ファイルを動的に生成し、[アーティファクト](../../../ci/jobs/job_artifacts.md)としてエクスポートするようにしてください。
- [依存関係の解決](dependency_scanning_sbom/_index.md#dependency-resolution)を有効にして、マニフェストファイルから`requirements.txt`ロックファイルを自動的に生成します。

詳細と例については、[Pipの有効化手順](dependency_scanning_sbom/_index.md#pip)を参照してください。

### Swift {#swift}

**Previous behavior**: Gemnasiumアナライザーに基づいた依存関係スキャンは、CI/CDテンプレートまたはスキャン実行ポリシーを使用する場合、Swiftプロジェクトをサポートしていません。Swiftのサポートは、実験的なSwift CI/CDコンポーネントでのみ利用可能です。

**New behavior**: 新しい依存関係スキャンアナライザーは、`Package.resolved`ファイルを解析することでプロジェクトの依存関係を抽出し、`dependency-scanning` CI/CDジョブによってCycloneDX SBOMレポートアーティファクトを生成します。

#### Swiftプロジェクトを移行する {#migrate-a-swift-project}

新しい依存関係スキャンアナライザーを使用するようにSwiftプロジェクトを移行します。

前提条件: 

- すべてのプロジェクトに必要な[一般的な移行手順](#migrate-to-dependency-scanning-using-sbom)を完了してください。
- プロジェクトのデベロッパー、メンテナー、またはオーナーロール。

依存関係スキャンアナライザーを使用するようにSwiftプロジェクトを移行するために、追加の手順は必要ありません。

### uv {#uv}

**Previous behavior**: Gemnasiumアナライザーに基づいた依存関係スキャンは、uvプロジェクトを`gemnasium-dependency_scanning` CI/CDジョブを使用してサポートし、`uv.lock`ファイルを解析することでプロジェクトの依存関係を抽出します。サポートされているuvのバージョンと`uv.lock`ファイルの組み合わせについては、[依存関係スキャン（Gemnasiumベース）ドキュメント](legacy_dependency_scanning/_index.md#obtaining-dependency-information-by-parsing-lockfiles)で詳しく説明されています。

**New behavior**: 新しい依存関係スキャンアナライザーは、`uv.lock`ファイルを解析することでプロジェクトの依存関係を抽出し、`dependency-scanning` CI/CDジョブによってCycloneDX SBOMレポートアーティファクトを生成します。

#### uvプロジェクトを移行する {#migrate-a-uv-project}

新しい依存関係スキャンアナライザーを使用するようにuvプロジェクトを移行します。

前提条件: 

- すべてのプロジェクトに必要な[一般的な移行手順](#migrate-to-dependency-scanning-using-sbom)を完了してください。
- プロジェクトのデベロッパー、メンテナー、またはオーナーロール。

依存関係スキャンアナライザーを使用するようにuvプロジェクトを移行するために、追加の手順は必要ありません。

### Yarn {#yarn}

**Previous behavior**: Gemnasiumアナライザーに基づいた依存関係スキャンは、`gemnasium-dependency_scanning` CI/CDジョブを使用してYarnプロジェクトをサポートし、`yarn.lock`ファイルを解析することでプロジェクトの依存関係を抽出します。サポートされているYarnのバージョンと`yarn.lock`ファイルの組み合わせについては、[依存関係スキャン（Gemnasiumベース）ドキュメント](legacy_dependency_scanning/_index.md#obtaining-dependency-information-by-parsing-lockfiles)で詳しく説明されています。このアナライザーは、Yarnの依存関係に対する[マージリクエストによる脆弱性の解決](../vulnerabilities/_index.md#resolve-a-vulnerability)のために修正データを提供する場合があります。このアナライザーは、Yarnプロジェクトに含まれるJavaScriptファイルを`Retire.JS`スキャナーを使用してスキャンする場合があります。

**New behavior**: 新しい依存関係スキャンアナライザーは、`yarn.lock`ファイルを解析することでプロジェクトの依存関係を抽出し、`dependency-scanning` CI/CDジョブによってCycloneDX SBOMレポートアーティファクトを生成します。このアナライザーは、Yarnの依存関係に対する修正データを提供しません。詳細については、[Yarnプロジェクトの依存関係スキャンにおける脆弱性の解決廃止のお知らせ](../../../update/deprecations.md#resolve-a-vulnerability-for-dependency-scanning-on-yarn-projects)を参照してください。代替機能のサポートは、[エピック759](https://gitlab.com/groups/gitlab-org/-/epics/759)で提案されています。このアナライザーは、ベンダー提供のJavaScriptファイルをスキャンしません。詳細については、コンテキストと利用可能なアクションについて[JavaScriptベンダーライブラリの依存関係スキャン廃止のお知らせ](../../../update/deprecations.md#dependency-scanning-for-javascript-vendored-libraries)を参照してください。代替機能のサポートは、[エピック7186](https://gitlab.com/groups/gitlab-org/-/epics/7186)で提案されています。

#### Yarnプロジェクトを移行する {#migrate-a-yarn-project}

新しい依存関係スキャンアナライザーを使用するようにYarnプロジェクトを移行します。

前提条件: 

- すべてのプロジェクトに必要な[一般的な移行手順](#migrate-to-dependency-scanning-using-sbom)を完了してください。
- プロジェクトのデベロッパー、メンテナー、またはオーナーロール。

依存関係スキャンアナライザーを使用するようにYarnプロジェクトを移行するために、追加の手順は必要ありません。以前にマージリクエストを介した脆弱性の解決機能や、ベンダー提供のJavaScriptスキャンに頼っていた場合は、コンテキストと利用可能なアクションについて、上記の**New behavior**にリンクされている廃止のお知らせを参照してください。

## CI/CD変数の変更 {#changes-to-cicd-variables}

以下の表は、以前にGemnasiumアナライザーに基づいた従来の依存関係スキャン機能で使用されていたCI/CD変数と、新しい依存関係スキャンアナライザーでのそれらのステータスを示しています:

| 従来の変数                  | 新しいアナライザーでのステータス                                                                                    |
| -------------------------------- | --------------------------------------------------------------------------------------------------------------- |
| `ADDITIONAL_CA_CERT_BUNDLE`      | 維持されます。`additional_ca_cert_bundle`入力を推奨します。                                                            |
| `AST_ENABLE_MR_PIPELINES`        | 維持されます。                                                                                                           |
| `DEPENDENCY_SCANNING_DISABLED`   | 維持されます。                                                                                                           |
| `DS_ANALYZER_IMAGE`              | 維持されます。                                                                                                           |
| `DS_EXCLUDED_ANALYZERS`          | 削除されました。                                                                                                        |
| `DS_EXCLUDED_PATHS`              | 維持されます。`excluded_paths`入力を推奨します。                                                                       |
| `DS_GRADLE_RESOLUTION_POLICY`    | 削除されました。                                                                                                        |
| `DS_IMAGE_SUFFIX`                | 削除されました。                                                                                                        |
| `DS_INCLUDE_DEV_DEPENDENCIES`    | 維持されます。`include_dev_dependencies`入力を推奨します。                                                             |
| `DS_JAVA_VERSION`                | 削除されました。                                                                                                        |
| `DS_MAX_DEPTH`                   | 維持されます。`max_scan_depth`入力を推奨します。                                                                       |
| `DS_PIP_DEPENDENCY_PATH`         | 維持されます。[Python依存関係解決](dependency_scanning_sbom/_index.md#dependency-resolution)にのみ適用されます。 |
| `DS_PIP_VERSION`                 | 削除されました。                                                                                                        |
| `DS_REMEDIATE`                   | 削除されました。                                                                                                        |
| `DS_REMEDIATE_TIMEOUT`           | 削除されました。                                                                                                        |
| `GEMNASIUM_DB_LOCAL_PATH`        | 削除されました。                                                                                                        |
| `GEMNASIUM_DB_REF_NAME`          | 削除されました。                                                                                                        |
| `GEMNASIUM_DB_REMOTE_URL`        | 削除されました。                                                                                                        |
| `GEMNASIUM_DB_UPDATE_DISABLED`   | 削除されました。                                                                                                        |
| `GEMNASIUM_IGNORED_SCOPES`       | 削除されました。                                                                                                        |
| `GEMNASIUM_LIBRARY_SCAN_ENABLED` | 削除されました。                                                                                                        |
| `GOARCH`                         | 削除されました。                                                                                                        |
| `GOFLAGS`                        | 削除されました。                                                                                                        |
| `GOOS`                           | 削除されました。                                                                                                        |
| `GOPRIVATE`                      | 削除されました。                                                                                                        |
| `GRADLE_CLI_OPTS`                | 維持されます。[Gradle依存関係解決](dependency_scanning_sbom/_index.md#dependency-resolution)にのみ適用されます。 |
| `GRADLE_PLUGIN_INIT_PATH`        | 削除されました。                                                                                                        |
| `MAVEN_CLI_OPTS`                 | `MAVEN_ARGS`に置き換えられました。                                                                                       |
| `PIP_EXTRA_INDEX_URL`            | 維持されます。[Python依存関係解決](dependency_scanning_sbom/_index.md#dependency-resolution)にのみ適用されます。 |
| `PIP_INDEX_URL`                  | 維持されます。[Python依存関係解決](dependency_scanning_sbom/_index.md#dependency-resolution)にのみ適用されます。 |
| `PIP_REQUIREMENTS_FILE`          | `DS_PIP_MANIFEST_FILE_NAME_PATTERN`に置き換えられました。                                                                |
| `PIPENV_PYPI_MIRROR`             | 削除されました。                                                                                                        |
| `SBT_CLI_OPTS`                   | 削除されました。                                                                                                        |
| `SEARCH_IGNORE_HIDDEN_DIRS`      | 維持されます。                                                                                                           |
| `SECURE_ANALYZERS_PREFIX`        | 維持されます。`analyzer_image_prefix`入力を推奨します。                                                                |
| `SECURE_LOG_LEVEL`               | 維持されます。`analyzer_log_level`入力を推奨します。                                                                   |

**削除しました**とマークされた変数は、新しいアナライザーによって無視されます。他のジョブでも使用されない限り、CI/CD設定からそれらを削除してください。

**Replaced by `<new-name>`** とマークされた変数は引き続き機能しますが、非推奨です。これらはGitLabの次のメジャーバージョンで削除される予定です。新しい変数名を使用するようにCI/CD設定を更新してください。

**Kept**とマークされた変数は、新しいアナライザーに受け入れられ、[利用可能なCI/CD変数の参照](dependency_scanning_sbom/_index.md#available-cicd-variables)に記載されているとおりに動作します。一部の保持された変数は、現在依存関係解決ジョブにのみ適用され、その旨が表に記載されています。

既存ユーザーの設定（スキャン実行ポリシーなど）への移行をスムーズにするため、`v2`テンプレートはこれらのCI/CD変数と後方互換性があります。これらが設定されている場合、この新しいテンプレートで導入された対応する`spec:inputs` specインプットよりも優先されます。

`v2` CI/CDテンプレートを`.gitlab-ci.yml`で直接使用する場合、アナライザーを設定するには、CI/CD変数よりも[specインプット](dependency_scanning_sbom/_index.md#available-spec-inputs)を優先してください。Specインプットは、パイプライン作成時に検証され、より明確なエラーメッセージを提供し、テンプレートインクルードにスコープされます。CI/CD変数は、スキャン実行ポリシーまたはセキュリティ設定プロファイルを通じて依存関係スキャンを設定する場合にspecインプットがまだ利用できない場合に使用してください。

### v2テンプレートで導入された新しいCI/CD変数 {#new-cicd-variables-introduced-with-the-v2-template}

`v2`テンプレートは、以下の変数を追加します。詳細については、[利用可能なspecインプットの参照](dependency_scanning_sbom/_index.md#available-spec-inputs)と[利用可能なCI/CD変数の参照](dependency_scanning_sbom/_index.md#available-cicd-variables)を参照してください。

| 変数                                   | Specインプットの同等物                   | 目的                                                                                                                                                  |
| ------------------------------------------ | --------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `ANALYZER_ARTIFACT_DIR`                    | _（なし）_                                | CycloneDX SBOMレポートが保存されるディレクトリ。                                                                                                        |
| `DS_API_SCAN_DOWNLOAD_DELAY`               | `api_scan_download_delay`               | 脆弱性スキャン結果をダウンロードする前の初期遅延。                                                                                             |
| `DS_API_TIMEOUT`                           | `api_timeout`                           | 依存関係スキャンSBOMスキャンAPIのタイムアウト。                                                                                                       |
| `DS_DISABLED_RESOLUTION_JOBS`              | `disabled_resolution_jobs`              | 無効にする[依存関係解決](dependency_scanning_sbom/_index.md#dependency-resolution)ジョブのコンマ区切りリスト（`maven`、`gradle`、`python`）。 |
| `DS_ENABLE_MANIFEST_FALLBACK`              | `enable_manifest_fallback`              | ロックファイルまたは依存関係グラフのエクスポートが利用できない場合に、[マニフェストフォールバック](dependency_scanning_sbom/_index.md#manifest-fallback)を有効にします。               |
| `DS_ENABLE_VULNERABILITY_SCAN`             | `enable_vulnerability_scan`             | 生成されたSBOMの脆弱性スキャンを切り替えます。                                                                                                        |
| `DS_FF_LINK_COMPONENTS_TO_GIT_FILES`       | _（なし）_                                | （ベータ）依存関係リスト内のコンポーネントを、動的に生成されたファイルではなく、リポジトリにコミットされたファイルにリンクします。                               |
| `DS_GRADLE_RESOLUTION_IMAGE`               | `gradle_resolution_image`               | Gradle依存関係解決ジョブで使用されるイメージ。                                                                                                      |
| `DS_MAVEN_RESOLUTION_IMAGE`                | `maven_resolution_image`                | Maven依存関係解決ジョブで使用されるイメージ。                                                                                                       |
| `DS_MAVEN_DEPENDENCY_PLUGIN_VERSION`       | `maven_dependency_plugin_version`       | Maven依存関係解決中に使用される`maven-dependency-plugin`のバージョン。                                                                        |
| `DS_PIP_MANIFEST_FILE_NAME_PATTERN`        | `pip_manifest_file_name_pattern`        | PipマニフェストファイルのGlobパターン。                                                                                                                     |
| `DS_PIPCOMPILE_LOCKFILE_FILE_NAME_PATTERN` | `pipcompile_lockfile_file_name_pattern` | `pip-compile`ロックファイルのGlobパターン。                                                                                                                |
| `DS_PYTHON_RESOLUTION_IMAGE`               | `python_resolution_image`               | Python依存関係解決ジョブで使用されるイメージ。                                                                                                      |
| `DS_STATIC_REACHABILITY_ENABLED`           | `enable_static_reachability`            | [静的到達可能性](static_reachability.md)を有効にします。                                                                                                    |
