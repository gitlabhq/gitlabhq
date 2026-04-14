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

- Gemnasiumアナライザーをベースとした依存関係スキャン機能は、GitLab 17.9で非推奨となり、GitLab 20.0で削除される予定です。ただし、削除のタイムラインは確定しておらず、必要に応じてGemnasiumを引き続き使用できます。

{{< /history >}}

依存関係スキャン機能は、GitLab SBOM脆弱性スキャナーにアップグレードしています。この変更の一環として、[依存関係スキャン（SBOMを使用）](dependency_scanning_sbom/_index.md)機能と[新しい依存関係スキャンアナライザー](https://gitlab.com/gitlab-org/security-products/analyzers/dependency-scanning)が、Gemnasiumアナライザーに基づく従来の依存関係スキャン機能に置き換わります。ただし、この移行によって大きな変更が導入されるため、自動的に実装されるわけではなく、このドキュメントは移行ガイドとして機能します。

GitLab依存関係スキャンを使用しており、以下のいずれかの条件が当てはまる場合は、この移行ガイドに従ってください:

- The依存関係スキャンCI/CDジョブare configured by including a依存関係スキャンCI/CD templates.

  ```yaml
    include:
      - template: Jobs/Dependency-Scanning.gitlab-ci.yml
      - template: Jobs/Dependency-Scanning.latest.gitlab-ci.yml
  ```

- The依存関係スキャンCI/CDジョブare configured by using [スキャン実行ポリシー](../policies/scan_execution_policies.md).
- The依存関係スキャンCI/CDジョブare configured by using [パイプライン実行ポリシー](../policies/pipeline_execution_policies.md).

## 変更点を理解する {#understand-the-changes}

SBOMを使用した依存関係スキャンにプロジェクトを移行する前に、導入される根本的な変更点を理解しておく必要があります。この移行は、技術的な進化、GitLabでの依存関係スキャンの新しいアプローチ、そしてUXに対する様々な改善を表しており、これには以下が含まれますが、これらに限定されません:

- 言語サポートの強化。非推奨のGemnasiumアナライザーは、PythonとJavaのごく一部のバージョンに限定されています。新しいアナライザーは、組織が古いツールチェーンの古いプロジェクトで以前のバージョンを使用する柔軟性を提供し、アナライザーのイメージに対する大規模なアップデートを待つことなく、新しいバージョンを試すオプションも提供します。さらに、新しいアナライザーは、[ファイルのカバレッジ](https://gitlab.com/gitlab-org/security-products/analyzers/dependency-scanning#supported-files)が向上しています。
- パフォーマンスの向上。アプリケーションによっては、Gemnasiumアナライザーによってビルドされたビルドは1時間近くかかり、重複した作業になる可能性があります。新しいアナライザーは、ビルドシステムを直接実行することはありません。代わりに、以前に定義されたビルドジョブを再利用して、全体的なスキャンパフォーマンスを向上させます。
- より小さいアタックサーフェス。そのビルド機能をサポートするために、Gemnasiumアナライザーには様々な依存関係があらかじめロードされています。新しいアナライザーは、これらの依存関係の多くを削除し、結果としてより小さなアタックサーフェスを実現します。
- よりシンプルな設定。非推奨のGemnasiumアナライザーは、正しく機能するために、プロキシの設定、認証局（CA）CA証明書のバンドル、およびその他の様々なユーティリティを頻繁に必要とします。この新しいソリューションは、これらの要件の多くを削除し、結果としてより簡単に設定できる堅牢なツールをもたらします。

### セキュリティスキャンへの新しいアプローチ {#a-new-approach-to-security-scanning}

従来の依存関係スキャン機能を使用する場合、すべてのスキャン作業はCI/CDパイプラインで実行されます。スキャンを実行する際、Gemnasiumアナライザーは2つの重要なタスクを同時に処理します。それは、プロジェクトの依存関係を特定し、GitLabアドバイザリデータベースのローカルコピーとその特定のセキュリティスキャンエンジンを使用して、それらの依存関係のセキュリティ分析を直ちに実行することです。その後、様々なレポート（CycloneDX SBOMおよび依存関係スキャンセキュリティレポート）に結果を出力します。

一方、SBOMを使用した依存関係スキャン機能は、静的到達可能性や脆弱性スキャンなどの他の分析から依存関係の検出を分離する、分解された依存関係分析アプローチに依存しています。これらのタスクは依然として同じCI/CDジョブで実行されますが、切り離された再利用可能なコンポーネントとして機能します。例えば、脆弱性スキャン分析は、GitLabの継続的な脆弱性スキャン機能もサポートする、統一されたエンジンであるGitLab SBOM脆弱性スキャナーを再利用します。これにより、将来のインテグレーションポイントの機会も開かれ、より柔軟な脆弱性スキャンワークフローが可能になります。

SBOMを使用した依存関係スキャンがどのように[アプリケーションをスキャンするか](dependency_scanning_sbom/_index.md#how-it-scans-an-application)の詳細については、こちらをご覧ください。

### CI/CDの設定 {#cicd-configuration}

CI/CDパイプラインの中断を防ぐため、この新しいアプローチは安定版の依存関係スキャンCI/CDテンプレート（`Dependency-Scanning.gitlab-ci.yml`）には適用されず、GitLab 18.5以降では、有効にするために`v2`テンプレート（`Dependency-Scanning.v2.gitlab-ci.yml`）を使用する必要があります。この機能が成熟するにつれて、他の移行パスも検討される可能性があります。

[スキャン実行ポリシー](../policies/scan_execution_policies.md)を使用している場合、これらの変更はCI/CDテンプレートに基づいているため、同様に適用されます。

[メインの依存関係スキャンCI/CDコンポーネント](https://gitlab.com/components/dependency-scanning/-/tree/main/templates/main)を使用している場合は、すでに新しいアナライザーを採用しているため、変更はありません。ただし、Android、Rust、Swift、またはCocoaPods用の専用コンポーネントを使用している場合は、すべてのサポートされている言語とパッケージマネージャーをカバーするメインコンポーネントに移行する必要があります。

### JavaとPythonのビルドサポート {#build-support-for-java-and-python}

重要な変更の1つは、特にJavaとPythonのプロジェクトで依存関係がどのように検出されるかに影響します。新しいアナライザーは異なるアプローチを採用しています。アプリケーションをビルドすることで依存関係を特定するのではなく、ロックファイルまたは依存関係グラフファイルを通じて明示的な依存関係情報が必要です。この変更は、これらのファイルをリポジトリにコミットするか、CI/CDパイプライン中に動的に生成するかのいずれかの方法で、ファイルが利用可能であることを確認する必要があることを意味します。これにはいくつかの初期設定が必要ですが、異なる環境間でより信頼性が高く一貫した結果を提供します。必要に応じて、以下のセクションで、この新しいアプローチにプロジェクトを適応させるために必要な具体的なステップを案内します。

### スキャン結果へのアクセス {#accessing-scan-results}

`Dependency-Scanning.v2.gitlab-ci.yml`を使用している場合、ユーザーは依存関係スキャンの結果をジョブアーティファクト（`gl-dependency-scanning-report.json`）として表示できます。

#### ベータ版の動作 {#beta-behavior}

依存関係スキャンレポートアーティファクトは、GA（一般提供）リリースに含まれています。ベータ版の動作は、履歴的な参照のために以下にドキュメント化されていますが、もはや公式にはサポートされておらず、製品から削除される可能性があります。

<details>
  <summary>脆弱性スキャン結果へのアクセス方法の変更点に関する詳細については、このセクションを展開してください。</summary>

  SBOMを使用した依存関係スキャンに移行すると、セキュリティスキャン結果の処理方法に根本的な変更があることに気付くでしょう。新しいアプローチでは、セキュリティ分析がCI/CDパイプラインからGitLabプラットフォームへ移動するため、結果へのアクセス方法と操作方法が変わります。従来の依存関係スキャン機能では、Gemnasiumアナライザーを使用するCI/CDジョブがスキャン結果を含む[依存関係スキャンレポートアーティファクト](../../../ci/yaml/artifacts_reports.md#artifactsreportsdependency_scanning)を生成し、プラットフォームにアップロードします。これらの結果には、ジョブアーティファクトが提供するあらゆる方法でアクセスできます。これは、GitLabプラットフォームに到達する前に、CI/CDパイプライン内で結果を処理または変更できることを意味します。SBOMを使用した依存関係スキャンのアプローチは異なります。セキュリティ分析は、組み込みのGitLab SBOM脆弱性スキャナーを使用してGitLabプラットフォーム内で実行されるため、スキャン結果をジョブアーティファクトで確認することはもうありません。代わりに、GitLabはCI/CDパイプラインが生成する[CycloneDX SBOMレポートアーティファクト](../../../ci/yaml/artifacts_reports.md#artifactsreportscyclonedx)を分析し、セキュリティ所見を直接GitLabプラットフォームに作成します。移行をスムーズにするために、GitLabはいくつかの後方互換性を維持しています。Gemnasiumアナライザーを使用している間は、スキャン結果を含む標準のアーティファクト（`artifacts:paths`を使用）を依然として取得できます。これは、これらの結果を必要とする後続のCI/CDジョブがある場合でも、それらにアクセスできることを意味します。ただし、GitLab SBOM脆弱性スキャナーが進化改善するにつれて、これらのアーティファクトベースの結果には最新の機能強化が反映されないことに留意してください。新しい依存関係スキャンアナライザーに完全に移行する準備ができたら、スキャン結果へのプログラムによるアクセス方法を調整する必要があります。ジョブアーティファクトを読み取る代わりに、GitLab GraphQL API、特に（[`Pipeline.securityReportFindings`リソース](../../../api/graphql/reference/_index.md#pipelinesecurityreportfindings)）を使用します。
</details>

### コンプライアンスフレームワークに関する考慮事項 {#compliance-framework-considerations}

SBOMベースの依存関係スキャンに移行する際は、コンプライアンスフレームワークへの潜在的な影響に注意してください:

- SBOMベースのスキャンを使用する場合、"Dependency scanning running" コンプライアンスコントロールは、従来の`gl-dependency-scanning-report.json`アーティファクトを期待するため、GitLab Self-Managedインスタンス（18.4以降）で失敗する可能性があります。
- この問題はGitLab.com（SaaS）インスタンスには影響しません。
- 組織で依存関係スキャンコントロールを備えたコンプライアンスフレームワークを使用している場合は、まず非本番環境で移行をテストしてください。

詳細については、[コンプライアンスフレームワークの互換性](dependency_scanning_sbom/_index.md#compliance-framework-compatibility)を参照してください。

## 影響を受けるプロジェクトの特定 {#identify-affected-projects}

この移行に関してどのプロジェクトに注意が必要かを理解することが、重要な最初のステップです。最も大きな影響を受けるのは、JavaおよびPythonのプロジェクトです。これらのプロジェクトでの依存関係の処理方法が根本的に変更されるためです。影響を受けるプロジェクトを特定するために、GitLabは[依存関係スキャンビルドサポート検出ヘルパー](https://gitlab.com/security-products/tooling/build-support-detection-helper)ツールを提供しています。このツールは、GitLabグループまたはGitLab Self-Managedインスタンスを調査し、現在`gemnasium-maven-dependency_scanning`または`gemnasium-python-dependency_scanning`のCI/CDジョブで依存関係スキャン機能を使用しているプロジェクトを特定します。このツールを実行すると、移行中に注意が必要となるプロジェクトの包括的なレポートが作成されます。この情報を早期に把握することで、特に組織全体で複数のプロジェクトを管理している場合に、移行戦略を効果的に計画するのに役立ちます。

## SBOMを使用した依存関係スキャンへの移行 {#migrate-to-dependency-scanning-using-sbom}

前提条件: 

- `.gitlab-ci.yml`ファイルを編集するか、CI/CDコンポーネントを使用するには: プロジェクトのデベロッパー、メンテナー、またはオーナーロール。
- スキャン実行ポリシーまたはパイプライン実行ポリシーを編集するには: グループのオーナーロール、または`manage_security_policy_link`権限を持つカスタムロール。

SBOMを使用した依存関係スキャンメソッドに移行するには、プロジェクトごとに以下の手順を実行します:

1. Gemnasiumアナライザーに基づいた依存関係スキャンの既存のカスタマイズを削除します。
   - プロジェクトの`.gitlab-ci.yml`またはパイプライン実行ポリシーのCI/CD設定で、`gemnasium-dependency_scanning`、`gemnasium-maven-dependency_scanning`、または`gemnasium-python-dependency_scanning`のCI/CDジョブを手動でオーバーライドしてカスタマイズした場合は、それらを削除します。
   - [影響を受けるCI/CD変数](#changes-to-cicd-variables)を設定している場合は、それに応じて設定を調整してください。
1. 以下のいずれかのオプションで、SBOMを使用した依存関係スキャン機能を有効にします:
   - **おすすめ**: `v2`依存関係スキャンCI/CDテンプレート`Dependency-Scanning.v2.gitlab-ci.yml`を使用して、新しい依存関係スキャンアナライザーを実行します:
     1. プロジェクトの`.gitlab-ci.yml` CI/CD設定に`v2`依存関係スキャンCI/CDテンプレートが含まれていることを確認してください。
     1. 必要に応じて、以下の言語固有の手順に従って、プロジェクトとCI/CD設定を調整してください。
   - 新しい依存関係スキャンアナライザーを実行するために[スキャン実行ポリシー](dependency_scanning_sbom/_index.md#enforce-scanning-on-multiple-projects)を使用します:
     1. 依存関係スキャン用に設定されたスキャン実行ポリシーを編集し、`v2`テンプレートを使用していることを確認します。
     1. 必要に応じて、以下の言語固有の手順に従って、プロジェクトとCI/CD設定を調整してください。
   - 新しい依存関係スキャンアナライザーを実行するために[パイプライン実行ポリシー](dependency_scanning_sbom/_index.md#enforce-scanning-on-multiple-projects)を使用します:
     1. 設定されたパイプライン実行ポリシーを編集し、`v2`テンプレートを使用していることを確認します。
     1. 必要に応じて、以下の言語固有の手順に従って、プロジェクトとCI/CD設定を調整してください。
   - 新しい依存関係スキャンアナライザーを実行するために[依存関係スキャンCI/CDコンポーネント](https://gitlab.com/explore/catalog/components/dependency-scanning)を使用します:
     1. プロジェクトの`.gitlab-ci.yml` CI/CD設定にある依存関係スキャンCI/CDテンプレートの`include`ステートメントを依存関係スキャンCI/CDコンポーネントに置き換えます。
     1. 必要に応じて、以下の言語固有の手順に従って、プロジェクトとCI/CD設定を調整してください。

複数の言語を使用するプロジェクトの場合、関連するすべての言語固有の移行ステップを完了してください。

> [!note]
> CI/CDテンプレートからCI/CDコンポーネントへ移行することを決定した場合は、GitLab Self-Managedの[現在の制限](../../../ci/components/_index.md#use-a-gitlabcom-component-on-gitlab-self-managed)を確認してください。

## 言語固有の手順 {#language-specific-instructions}

新しい依存関係スキャンアナライザーに移行する際、プロジェクトのプログラミング言語やパッケージマネージャーに基づいて具体的な調整を行う必要があります。これらの手順は、CI/CDテンプレート、スキャン実行ポリシー、または依存関係スキャンCI/CDコンポーネントのいずれを通じて実行するように設定したかにかかわらず、新しい依存関係スキャンアナライザーを使用するたびに適用されます。以下のセクションでは、サポートされている各言語およびパッケージマネージャーに関する詳細な手順を記載しています。各手順には以下の説明が含まれます:

- 依存関係検出の変更点
- 提供する必要がある特定のファイル
- これらのファイルがまだワークフローの一部ではない場合に、それらを生成する方法

この[フィードバックイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/523458)で、新しい依存関係スキャンアナライザーに関するご意見をお聞かせください。

### Bundler {#bundler}

**Previous behavior**: Gemnasiumアナライザーをベースとした依存関係スキャンは、`gemnasium-dependency_scanning` CI/CDジョブを使用してBundlerプロジェクトをサポートし、`Gemfile.lock`ファイル（`gems.locked`も代替ファイル名としてサポートされています）を解析することでプロジェクトの依存関係を抽出できます。Bundlerのサポートされているバージョンと`Gemfile.lock`ファイルの組み合わせは、[依存関係スキャン（Gemnasiumベース）のドキュメント](_index.md#obtaining-dependency-information-by-parsing-lockfiles)に詳細が記載されています。

**New behavior**: 新しい依存関係スキャンアナライザーは、`Gemfile.lock`ファイル（`gems.locked`も代替ファイル名としてサポートされています）を解析することでプロジェクトの依存関係を抽出し、`dependency-scanning` CI/CDジョブでCycloneDX SBOMレポートアーティファクトを生成します。

#### Bundlerプロジェクトの移行 {#migrate-a-bundler-project}

Bundlerプロジェクトを、新しい依存関係スキャンアナライザーを使用するように移行します。

前提条件: 

- すべてのプロジェクトに必要な[一般的な移行ステップ](#migrate-to-dependency-scanning-using-sbom)を完了します。
- プロジェクトのデベロッパー、メンテナー、またはオーナーロール。

Bundlerプロジェクトを依存関係スキャンアナライザーを使用するように移行するために必要な追加手順はありません。

### CocoaPods {#cocoapods}

**Previous behavior**: Gemnasiumアナライザーをベースとした依存関係スキャンは、CI/CDテンプレートまたはスキャン実行ポリシーを使用する場合、CocoaPodsプロジェクトをサポートしていません。CocoaPodsのサポートは、実験的なCocoaPods CI/CDコンポーネントでのみ利用可能です。

**New behavior**: 新しい依存関係スキャンアナライザーは、`Podfile.lock`ファイルを解析することでプロジェクトの依存関係を抽出し、`dependency-scanning` CI/CDジョブでCycloneDX SBOMレポートアーティファクトを生成します。

#### CocoaPodsプロジェクトの移行 {#migrate-a-cocoapods-project}

CocoaPodsプロジェクトを、新しい依存関係スキャンアナライザーを使用するように移行します。

前提条件: 

- すべてのプロジェクトに必要な[一般的な移行ステップ](#migrate-to-dependency-scanning-using-sbom)を完了します。
- プロジェクトのデベロッパー、メンテナー、またはオーナーロール。

CocoaPodsプロジェクトを依存関係スキャンアナライザーを使用するように移行するために必要な追加手順はありません。

### Composer {#composer}

**Previous behavior**: Gemnasiumアナライザーをベースとした依存関係スキャンは、`gemnasium-dependency_scanning` CI/CDジョブを使用してComposerプロジェクトをサポートし、`composer.lock`ファイルを解析することでプロジェクトの依存関係を抽出できます。Composerのサポートされているバージョンと`composer.lock`ファイルの組み合わせは、[依存関係スキャン（Gemnasiumベース）のドキュメント](_index.md#obtaining-dependency-information-by-parsing-lockfiles)に詳細が記載されています。

**New behavior**: 新しい依存関係スキャンアナライザーは、`composer.lock`ファイルを解析することでプロジェクトの依存関係を抽出し、`dependency-scanning` CI/CDジョブでCycloneDX SBOMレポートアーティファクトを生成します。

#### Composerプロジェクトの移行 {#migrate-a-composer-project}

Composerプロジェクトを、新しい依存関係スキャンアナライザーを使用するように移行します。

前提条件: 

- すべてのプロジェクトに必要な[一般的な移行ステップ](#migrate-to-dependency-scanning-using-sbom)を完了します。
- プロジェクトのデベロッパー、メンテナー、またはオーナーロール。

Composerプロジェクトを依存関係スキャンアナライザーを使用するように移行するために必要な追加手順はありません。

### Conan {#conan}

**Previous behavior**: Gemnasiumアナライザーをベースとした依存関係スキャンは、`gemnasium-dependency_scanning` CI/CDジョブを使用してConanプロジェクトをサポートし、`conan.lock`ファイルを解析することでプロジェクトの依存関係を抽出できます。Conanのサポートされているバージョンと`conan.lock`ファイルの組み合わせは、[依存関係スキャン（Gemnasiumベース）のドキュメント](_index.md#obtaining-dependency-information-by-parsing-lockfiles)に詳細が記載されています。

**New behavior**: 新しい依存関係スキャンアナライザーは、`conan.lock`ファイルを解析することでプロジェクトの依存関係を抽出し、`dependency-scanning` CI/CDジョブでCycloneDX SBOMレポートアーティファクトを生成します。

#### Conanプロジェクトの移行 {#migrate-a-conan-project}

Conanプロジェクトを、新しい依存関係スキャンアナライザーを使用するように移行します。

前提条件: 

- すべてのプロジェクトに必要な[一般的な移行ステップ](#migrate-to-dependency-scanning-using-sbom)を完了します。
- プロジェクトのデベロッパー、メンテナー、またはオーナーロール。

Conanプロジェクトを依存関係スキャンアナライザーを使用するように移行するために必要な追加手順はありません。

### Go {#go}

**Previous behavior**: Gemnasiumアナライザーをベースとした依存関係スキャンは、`gemnasium-dependency_scanning` CI/CDジョブを使用してGo言語プロジェクトをサポートし、`go.mod`と`go.sum`ファイルを使用することでプロジェクトの依存関係を抽出できます。このアナライザーは、検出された依存関係の精度を高めるために`go list`コマンドを実行するしようとしますが、これには機能するGo環境が必要です。失敗した場合、`go.sum`ファイルの解析にフォールバックします。Go言語のサポートされているバージョン、`go.mod`、および`go.sum`ファイルの組み合わせは、[依存関係スキャン（Gemnasiumベース）のドキュメント](_index.md#obtaining-dependency-information-by-parsing-lockfiles)に詳細が記載されています。

**New behavior**: 新しい依存関係スキャンアナライザーは、プロジェクト内の`go list`コマンドを実行することで依存関係を抽出しようとはせず、`go.sum`ファイルの解析にフォールバックすることもありません。代わりに、プロジェクトは少なくとも`go.mod`ファイルと、理想的にはGoツールチェーンの[`go mod graph`コマンド](https://go.dev/ref/mod#go-mod-graph)で生成された`go.graph`ファイルを提供する必要があります。検出されたコンポーネントの精度を高め、[依存関係パス](../dependency_list/_index.md#dependency-paths)などの機能を有効にするための依存関係グラフを生成するには、`go.graph`ファイルが必要です。これらのファイルは、`dependency-scanning` CI/CDジョブによって処理され、CycloneDX SBOMレポートアーティファクトを生成します。このアプローチでは、GitLabが特定のGo言語のバージョンをサポートする必要はありません。

#### Go言語プロジェクトの移行 {#migrate-a-go-project}

Go言語プロジェクトを、新しい依存関係スキャンアナライザーを使用するように移行します。

前提条件: 

- すべてのプロジェクトに必要な[一般的な移行ステップ](#migrate-to-dependency-scanning-using-sbom)を完了します。
- プロジェクトのデベロッパー、メンテナー、またはオーナーロール。

Go言語プロジェクトを移行するには:

- プロジェクトが`go.mod`と`go.graph`ファイルを提供していることを確認します。Go言語ツールチェーンからの[`go mod graph`コマンド](https://go.dev/ref/mod#go-mod-graph)を先行するCI/CDジョブ（例: `build`）で設定し、依存関係スキャンジョブを実行する前に`dependencies.lock`ファイルを動的に生成し、[アーティファクト](../../../ci/jobs/job_artifacts.md)としてエクスポートします。

詳細と例については、[Go言語の有効化手順](dependency_scanning_sbom/_index.md#go)を参照してください。

### Gradle {#gradle}

**Previous behavior**: Gemnasiumアナライザーをベースとした依存関係スキャンは、`gemnasium-maven-dependency_scanning` CI/CDジョブを使用してGradleプロジェクトをサポートし、`build.gradle`および`build.gradle.kts`ファイルからアプリケーションをビルドすることでプロジェクトの依存関係を抽出できます。Java、Kotlin、およびGradleのサポートされているバージョンの組み合わせは複雑であり、[依存関係スキャン（Gemnasiumベース）のドキュメント](_index.md#obtaining-dependency-information-by-running-a-package-manager-to-generate-a-parsable-file)に詳細が記載されています。

**New behavior**: 新しい依存関係スキャンアナライザーは、依存関係を抽出するためにプロジェクトをビルドすることはありません。代わりに、プロジェクトは[Gradle Dependency Lockプラグイン](https://github.com/nebula-plugins/gradle-dependency-lock-plugin)で生成された`dependencies.lock`ファイルを提供する必要があります。このファイルは、`dependency-scanning` CI/CDジョブによって処理され、CycloneDX SBOMレポートアーティファクトを生成します。このアプローチでは、GitLabがJava、Kotlin、およびGradleの特定のバージョンをサポートする必要はありません。

#### Gradleプロジェクトの移行 {#migrate-a-gradle-project}

Gradleプロジェクトを、新しい依存関係スキャンアナライザーを使用するように移行します。

前提条件: 

- すべてのプロジェクトに必要な[一般的な移行ステップ](#migrate-to-dependency-scanning-using-sbom)を完了します。
- プロジェクトのデベロッパー、メンテナー、またはオーナーロール。

Gradleプロジェクトを移行するには:

- プロジェクトが`dependencies.lock`ファイルを提供していることを確認します。プロジェクトに[Gradle Dependency Lockプラグイン](https://github.com/nebula-plugins/gradle-dependency-lock-plugin)を設定し、以下のいずれかの方法で実行します:
  - プラグインを開発ワークフローに永続的に統合する。これは、`dependencies.lock`ファイルをリポジトリにコミットし、プロジェクトの依存関係に変更を加える際にそれを更新することを意味します。
  - 先行するCI/CDジョブ（例: `build`）でコマンドを使用し、依存関係スキャンジョブを実行する前に`dependencies.lock`ファイルを動的に生成し、[アーティファクト](../../../ci/jobs/job_artifacts.md)としてエクスポートします。

詳細と例については、[Gradleの有効化手順](dependency_scanning_sbom/_index.md#gradle)を参照してください。

### Maven {#maven}

**Previous behavior**: Gemnasiumアナライザーをベースとした依存関係スキャンは、`gemnasium-maven-dependency_scanning` CI/CDジョブを使用してMavenプロジェクトをサポートし、`pom.xml`ファイルからアプリケーションをビルドすることでプロジェクトの依存関係を抽出できます。Java、Kotlin、およびMavenのサポートされているバージョンの組み合わせは複雑であり、[依存関係スキャン（Gemnasiumベース）のドキュメント](_index.md#obtaining-dependency-information-by-running-a-package-manager-to-generate-a-parsable-file)に詳細が記載されています。

**New behavior**: 新しい依存関係スキャンアナライザーは、依存関係を抽出するためにプロジェクトをビルドすることはありません。代わりに、プロジェクトは[maven依存プラグイン](https://maven.apache.org/plugins/maven-dependency-plugin/index.html)で生成された`maven.graph.json`ファイルを提供する必要があります。このファイルは、`dependency-scanning` CI/CDジョブによって処理され、CycloneDX SBOMレポートアーティファクトを生成します。このアプローチでは、GitLabがJava、Kotlin、およびMavenの特定のバージョンをサポートする必要はありません。

#### Mavenプロジェクトの移行 {#migrate-a-maven-project}

Mavenプロジェクトを、新しい依存関係スキャンアナライザーを使用するように移行します。

前提条件: 

- すべてのプロジェクトに必要な[一般的な移行ステップ](#migrate-to-dependency-scanning-using-sbom)を完了します。
- プロジェクトのデベロッパー、メンテナー、またはオーナーロール。

Mavenプロジェクトを移行するには:

- プロジェクトが`maven.graph.json`ファイルを提供していることを確認します。先行するCI/CDジョブ（例: `build`）で[maven依存プラグイン](https://maven.apache.org/plugins/maven-dependency-plugin/index.html)を設定し、依存関係スキャンジョブを実行する前に`maven.graph.json`ファイルを動的に生成し、[アーティファクト](../../../ci/jobs/job_artifacts.md)としてエクスポートします。

詳細と例については、[Mavenの有効化手順](dependency_scanning_sbom/_index.md#maven)を参照してください。

### npm {#npm}

**Previous behavior**: Gemnasiumアナライザーをベースとした依存関係スキャンは、`gemnasium-dependency_scanning` CI/CDジョブを使用してnpmプロジェクトをサポートし、`package-lock.json`または`npm-shrinkwrap.json.lock`ファイルを解析することでプロジェクトの依存関係を抽出できます。npmのサポートされているバージョンと`package-lock.json`または`npm-shrinkwrap.json.lock`ファイルの組み合わせは、[依存関係スキャン（Gemnasiumベース）のドキュメント](_index.md#obtaining-dependency-information-by-parsing-lockfiles)に詳細が記載されています。このアナライザーは、`Retire.JS`スキャナーを使用してnpmプロジェクトにベンダー提供されたJavaScriptファイルをスキャンする場合があります。

**New behavior**: 新しい依存関係スキャンアナライザーは、`package-lock.json`または`npm-shrinkwrap.json.lock`ファイルを解析することでプロジェクトの依存関係を抽出し、`dependency-scanning` CI/CDジョブでCycloneDX SBOMレポートアーティファクトを生成します。このアナライザーは、ベンダー提供されたJavaScriptファイルをスキャンしません。代替機能のサポートは、[エピック7186](https://gitlab.com/groups/gitlab-org/-/epics/7186)で提案されています。

#### npmプロジェクトの移行 {#migrate-an-npm-project}

npmプロジェクトを、新しい依存関係スキャンアナライザーを使用するように移行します。

前提条件: 

- すべてのプロジェクトに必要な[一般的な移行ステップ](#migrate-to-dependency-scanning-using-sbom)を完了します。
- プロジェクトのデベロッパー、メンテナー、またはオーナーロール。

npmプロジェクトを依存関係スキャンアナライザーを使用するように移行するために必要な追加手順はありません。

### NuGet {#nuget}

**Previous behavior**: Gemnasiumアナライザーをベースとした依存関係スキャンは、`gemnasium-dependency_scanning` CI/CDジョブを使用してNuGetプロジェクトをサポートし、`packages.lock.json`ファイルを解析することでプロジェクトの依存関係を抽出できます。NuGetのサポートされているバージョンと`packages.lock.json`ファイルの組み合わせは、[依存関係スキャン（Gemnasiumベース）のドキュメント](_index.md#obtaining-dependency-information-by-parsing-lockfiles)に詳細が記載されています。

**New behavior**: 新しい依存関係スキャンアナライザーは、`packages.lock.json`ファイルを解析することでプロジェクトの依存関係を抽出し、`dependency-scanning` CI/CDジョブでCycloneDX SBOMレポートアーティファクトを生成します。

#### NuGetプロジェクトの移行 {#migrate-a-nuget-project}

NuGetプロジェクトを、新しい依存関係スキャンアナライザーを使用するように移行します。

前提条件: 

- すべてのプロジェクトに必要な[一般的な移行ステップ](#migrate-to-dependency-scanning-using-sbom)を完了します。
- プロジェクトのデベロッパー、メンテナー、またはオーナーロール。

NuGetプロジェクトを依存関係スキャンアナライザーを使用するように移行するために必要な追加手順はありません。

### pip {#pip}

**Previous behavior**: Gemnasiumアナライザーをベースとした依存関係スキャンは、`gemnasium-python-dependency_scanning` CI/CDジョブを使用してpipプロジェクトをサポートし、`requirements.txt`ファイル（`requirements.pip`および`requires.txt`も代替ファイル名としてサポートされています）からアプリケーションをビルドすることでプロジェクトの依存関係を抽出できます。The `PIP_REQUIREMENTS_FILE`環境変数can also be used to specify a custom filename.Pythonとpipのサポートされているバージョンの組み合わせは、[依存関係スキャン（Gemnasiumベース）のドキュメント](_index.md#obtaining-dependency-information-by-running-a-package-manager-to-generate-a-parsable-file)に詳細が記載されています。

**New behavior**: 新しい依存関係スキャンアナライザーは、依存関係を抽出するためにプロジェクトをビルドすることはありません。代わりに、プロジェクトは[pip-compileコマンドラインツール](https://pip-tools.readthedocs.io/en/latest/cli/pip-compile/)によって生成された`requirements.txt`ロックファイルを提供する必要があります。このファイルは、`dependency-scanning` CI/CDジョブによって処理され、CycloneDX SBOMレポートアーティファクトを生成します。このアプローチでは、GitLabがPythonとpipの特定のバージョンをサポートする必要はありません。`pipcompile_requirements_file_name_pattern` spec入力または`DS_PIPCOMPILE_REQUIREMENTS_FILE_NAME_PATTERN`変数を使用して、pip-compileロックファイルのカスタムファイル名を指定することもできます。

あるいは、プロジェクトは[pipdeptreeコマンドラインユーティリティ](https://pypi.org/project/pipdeptree/)で生成された`pipdeptree.json`ファイルを提供できます。

#### Pipプロジェクトを移行する {#migrate-a-pip-project}

新しい依存関係スキャンアナライザーを使用するようにPipプロジェクトを移行します。

前提条件: 

- すべてのプロジェクトに必要な[一般的な移行ステップ](#migrate-to-dependency-scanning-using-sbom)を完了します。
- プロジェクトのデベロッパー、メンテナー、またはオーナーロール。

Pipプロジェクトを移行するには:

- あなたのプロジェクトが`requirements.txt`ロックファイルを提供していることを確認してください。プロジェクトで[pip-compileコマンドラインツール](https://pip-tools.readthedocs.io/en/latest/cli/pip-compile/)を設定し、以下のいずれかを実行します:
  - コマンドラインツールを開発ワークフローに永続的に統合します。これは、`requirements.txt`ファイルをリポジトリにコミットし、プロジェクトの依存関係に変更を加える際にそれを更新することを意味します。
  - 以前のCI/CDジョブ（例: `build`）でコマンドラインツールを使用し、`requirements.txt`ファイルを動的に生成して、依存関係スキャンジョブを実行する前に[アーティファクト](../../../ci/jobs/job_artifacts.md)としてエクスポートします。

または

- あなたのプロジェクトが`pipdeptree.json`ロックファイルを提供していることを確認してください。以前のCI/CDジョブ（例: `build`）で[pipdeptreeコマンドラインユーティリティ](https://pypi.org/project/pipdeptree/)を設定し、`pipdeptree.json`ファイルを動的に生成して、依存関係スキャンジョブを実行する前に[アーティファクト](../../../ci/jobs/job_artifacts.md)としてエクスポートします。

詳細と使用例については、[Pipのイネーブルメント手順](dependency_scanning_sbom/_index.md#pip)を参照してください。

### Pipenv {#pipenv}

**Previous behavior**: Gemnasiumアナライザーに基づく依存関係スキャンは、`Pipfile`ファイル、または`Pipfile.lock`ファイルが存在する場合はそれらのファイルからアプリケーションをビルドすることでプロジェクトの依存関係を抽出するために、`gemnasium-python-dependency_scanning` CI/CDジョブを使用するPipenvプロジェクトをサポートします。PythonとPipenvでサポートされているバージョンの組み合わせは、[Gemnasiumベースの依存関係スキャンドキュメント](_index.md#obtaining-dependency-information-by-running-a-package-manager-to-generate-a-parsable-file)に詳述されています。

**New behavior**: 新しい依存関係スキャンアナライザーは、依存関係を抽出するためにPipenvプロジェクトをビルドすることはありません。代わりに、プロジェクトは少なくとも`Pipfile.lock`ファイル、および理想的には[`pipenv graph`コマンド](https://pipenv.pypa.io/en/latest/cli.html#graph)によって生成される`pipenv.graph.json`ファイルを提供する必要があります。`pipenv.graph.json`ファイルは依存関係グラフを生成し、[依存関係パスの可視化](../dependency_list/_index.md#dependency-paths)のような機能を有効にするために必要です。これらのファイルは、`dependency-scanning` CI/CDジョブによって処理され、CycloneDX SBOMレポートアーティファクトを生成します。このアプローチでは、GitLabがPythonとPipenvの特定のバージョンをサポートする必要はありません。

#### Pipenvプロジェクトを移行する {#migrate-a-pipenv-project}

新しい依存関係スキャンアナライザーを使用するようにPipenvプロジェクトを移行します。

前提条件: 

- すべてのプロジェクトに必要な[一般的な移行ステップ](#migrate-to-dependency-scanning-using-sbom)を完了します。
- プロジェクトのデベロッパー、メンテナー、またはオーナーロール。

Pipenvプロジェクトを移行するには:

- プロジェクトが`Pipfile.lock`ファイルを提供していることを確認します。プロジェクトで[`pipenv lock`コマンド](https://pipenv.pypa.io/en/latest/cli.html#graph)を設定し、以下のいずれかを実行します:
  - コマンドを開発ワークフローに永続的に統合します。これは、`Pipfile.lock`ファイルをリポジトリにコミットし、プロジェクトの依存関係に変更を加える際にそれを更新することを意味します。
  - 先行するCI/CDジョブ（例: `build`）でコマンドを使用し、依存関係スキャンジョブを実行する前に`Pipfile.lock`ファイルを動的に生成し、[アーティファクト](../../../ci/jobs/job_artifacts.md)としてエクスポートします。

または

- プロジェクトが`pipenv.graph.json`ファイルを提供していることを確認します。以前のCI/CDジョブ（例: `build`）で[`pipenv graph`コマンド](https://pipenv.pypa.io/en/latest/cli.html#graph)を設定し、`pipenv.graph.json`ファイルを動的に生成して、依存関係スキャンジョブを実行する前に[アーティファクト](../../../ci/jobs/job_artifacts.md)としてエクスポートします。

詳細と使用例については、[Pipenvのイネーブルメント手順](dependency_scanning_sbom/_index.md#pipenv)を参照してください。

### Poetry {#poetry}

**Previous behavior**: Gemnasiumアナライザーに基づく依存関係スキャンは、`poetry.lock`ファイルを解析することによってプロジェクトの依存関係を抽出するために、`gemnasium-python-dependency_scanning` CI/CDジョブを使用するPoetryプロジェクトをサポートします。Poetryと`poetry.lock`ファイルでサポートされているバージョンの組み合わせは、[Gemnasiumベースの依存関係スキャンドキュメント](_index.md#obtaining-dependency-information-by-parsing-lockfiles)に詳述されています。

**New behavior**: 新しい依存関係スキャンアナライザーは、`poetry.lock`ファイルを解析することでプロジェクトの依存関係を抽出し、`dependency-scanning` CI/CDジョブでCycloneDX SBOMレポートアーティファクトを生成します。

#### Poetryプロジェクトを移行する {#migrate-a-poetry-project}

新しい依存関係スキャンアナライザーを使用するようにPoetryプロジェクトを移行します。

前提条件: 

- すべてのプロジェクトに必要な[一般的な移行ステップ](#migrate-to-dependency-scanning-using-sbom)を完了します。
- プロジェクトのデベロッパー、メンテナー、またはオーナーロール。

Poetryプロジェクトを新しい依存関係スキャンアナライザーを使用するように移行するために、追加のステップはありません。

### pnpm {#pnpm}

**Previous behavior**: Gemnasiumアナライザーに基づく依存関係スキャンは、`pnpm-lock.yaml`ファイルを解析することによってプロジェクトの依存関係を抽出するために、`gemnasium-dependency_scanning` CI/CDジョブを使用するpnpmプロジェクトをサポートします。pnpmと`pnpm-lock.yaml`ファイルでサポートされているバージョンの組み合わせは、[Gemnasiumベースの依存関係スキャンドキュメント](_index.md#obtaining-dependency-information-by-parsing-lockfiles)に詳述されています。このアナライザーは、`Retire.JS`スキャナーを使用してnpmプロジェクトにベンダー提供されたJavaScriptファイルをスキャンする場合があります。

**New behavior**: 新しい依存関係スキャンアナライザーは、`pnpm-lock.yaml`ファイルを解析することでプロジェクトの依存関係を抽出し、`dependency-scanning` CI/CDジョブでCycloneDX SBOMレポートアーティファクトを生成します。このアナライザーは、ベンダー提供されたJavaScriptファイルをスキャンしません。代替機能のサポートは、[エピック7186](https://gitlab.com/groups/gitlab-org/-/epics/7186)で提案されています。

#### pnpmプロジェクトを移行する {#migrate-a-pnpm-project}

新しい依存関係スキャンアナライザーを使用するようにpnpmプロジェクトを移行します。

前提条件: 

- すべてのプロジェクトに必要な[一般的な移行ステップ](#migrate-to-dependency-scanning-using-sbom)を完了します。
- プロジェクトのデベロッパー、メンテナー、またはオーナーロール。

pnpmプロジェクトを新しい依存関係スキャンアナライザーを使用するように移行するために、追加のステップはありません。

### sbt {#sbt}

**Previous behavior**: Gemnasiumアナライザーに基づく依存関係スキャンは、`build.sbt`ファイルからアプリケーションをビルドすることによってプロジェクトの依存関係を抽出するために、`gemnasium-maven-dependency_scanning` CI/CDジョブを使用するsbtプロジェクトをサポートします。Java、Scala、およびsbtでサポートされているバージョンの組み合わせは、[Gemnasiumベースの依存関係スキャンドキュメント](_index.md#obtaining-dependency-information-by-running-a-package-manager-to-generate-a-parsable-file)に詳述されています。

**New behavior**: 新しい依存関係スキャンアナライザーは、依存関係を抽出するためにプロジェクトをビルドすることはありません。代わりに、プロジェクトは[sbt-dependency-graphプラグイン](https://github.com/sbt/sbt-dependency-graph) （[sbt >= 1.4.0に含まれる](https://www.scala-sbt.org/1.x/docs/sbt-1.4-Release-Notes.html#sbt-dependency-graph+is+in-sourced)）で生成された`dependencies-compile.dot`ファイルを提供する必要があります。このファイルは、`dependency-scanning` CI/CDジョブによって処理され、CycloneDX SBOMレポートアーティファクトを生成します。このアプローチでは、GitLabがJava、Scala、およびsbtの特定のバージョンをサポートする必要はありません。

#### sbtプロジェクトを移行する {#migrate-an-sbt-project}

新しい依存関係スキャンアナライザーを使用するようにsbtプロジェクトを移行します。

前提条件: 

- すべてのプロジェクトに必要な[一般的な移行ステップ](#migrate-to-dependency-scanning-using-sbom)を完了します。
- プロジェクトのデベロッパー、メンテナー、またはオーナーロール。

sbtプロジェクトを移行するには:

- プロジェクトが`dependencies-compile.dot`ファイルを提供していることを確認します。以前のCI/CDジョブ（例: `build`）で[sbt-dependency-graphプラグイン](https://github.com/sbt/sbt-dependency-graph)を設定し、`dependencies-compile.dot`ファイルを動的に生成して、依存関係スキャンジョブを実行する前に[アーティファクト](../../../ci/jobs/job_artifacts.md)としてエクスポートします。

詳細と使用例については、[sbtのイネーブルメント手順](dependency_scanning_sbom/_index.md#sbt)を参照してください。

### setuptools {#setuptools}

**Previous behavior**: Gemnasiumアナライザーに基づく依存関係スキャンは、`setup.py`ファイルからアプリケーションをビルドすることによってプロジェクトの依存関係を抽出するために、`gemnasium-python-dependency_scanning` CI/CDジョブを使用するsetuptoolsプロジェクトをサポートします。Pythonとsetuptoolsでサポートされているバージョンの組み合わせは、[Gemnasiumベースの依存関係スキャンドキュメント](_index.md#obtaining-dependency-information-by-running-a-package-manager-to-generate-a-parsable-file)に詳述されています。

**New behavior**: 新しい依存関係スキャンアナライザーは、依存関係を抽出するためのsetuptoolsプロジェクトのビルドをサポートしていません。互換性のある`requirements.txt`ロックファイルを生成するように[pip-compileコマンドラインツール](https://pip-tools.readthedocs.io/en/latest/cli/pip-compile/)を設定します。あるいは、独自のCycloneDX SBOMドキュメントを提供することもできます。

#### setuptoolsプロジェクトを移行する {#migrate-a-setuptools-project}

新しい依存関係スキャンアナライザーを使用するようにsetuptoolsプロジェクトを移行します。

前提条件: 

- すべてのプロジェクトに必要な[一般的な移行ステップ](#migrate-to-dependency-scanning-using-sbom)を完了します。
- プロジェクトのデベロッパー、メンテナー、またはオーナーロール。

setuptoolsプロジェクトを移行するには:

- あなたのプロジェクトが`requirements.txt`ロックファイルを提供していることを確認してください。プロジェクトで[pip-compileコマンドラインツール](https://pip-tools.readthedocs.io/en/latest/cli/pip-compile/)を設定し、以下のいずれかを実行します:
  - コマンドラインツールを開発ワークフローに永続的に統合します。これは、`requirements.txt`ファイルをリポジトリにコミットし、プロジェクトの依存関係に変更を加える際にそれを更新することを意味します。
  - `build` CI/CDジョブでコマンドラインツールを使用し、`requirements.txt`ファイルを動的に生成して、依存関係スキャンジョブを実行する前に[アーティファクト](../../../ci/jobs/job_artifacts.md)としてエクスポートします。

詳細と使用例については、[Pipのイネーブルメント手順](dependency_scanning_sbom/_index.md#pip)を参照してください。

### Swift {#swift}

**Previous behavior**: Gemnasiumアナライザーに基づく依存関係スキャンは、CI/CDテンプレートまたはスキャン実行ポリシーを使用する場合、Swiftプロジェクトをサポートしません。Swiftのサポートは、実験的なSwift CI/CDコンポーネントでのみ利用可能です。

**New behavior**: 新しい依存関係スキャンアナライザーは、`Package.resolved`ファイルを解析することでプロジェクトの依存関係を抽出し、`dependency-scanning` CI/CDジョブでCycloneDX SBOMレポートアーティファクトを生成します。

#### Swiftプロジェクトを移行する {#migrate-a-swift-project}

新しい依存関係スキャンアナライザーを使用するようにSwiftプロジェクトを移行します。

前提条件: 

- すべてのプロジェクトに必要な[一般的な移行ステップ](#migrate-to-dependency-scanning-using-sbom)を完了します。
- プロジェクトのデベロッパー、メンテナー、またはオーナーロール。

Swiftプロジェクトを新しい依存関係スキャンアナライザーを使用するように移行するために、追加のステップはありません。

### uv {#uv}

**Previous behavior**: Gemnasiumアナライザーに基づく依存関係スキャンは、`uv.lock`ファイルを解析することによってプロジェクトの依存関係を抽出するために、`gemnasium-dependency_scanning` CI/CDジョブを使用するuvプロジェクトをサポートします。uvと`uv.lock`ファイルでサポートされているバージョンの組み合わせは、[Gemnasiumベースの依存関係スキャンドキュメント](_index.md#obtaining-dependency-information-by-parsing-lockfiles)に詳述されています。

**New behavior**: 新しい依存関係スキャンアナライザーは、`uv.lock`ファイルを解析することでプロジェクトの依存関係を抽出し、`dependency-scanning` CI/CDジョブでCycloneDX SBOMレポートアーティファクトを生成します。

#### uvプロジェクトを移行する {#migrate-a-uv-project}

新しい依存関係スキャンアナライザーを使用するようにuvプロジェクトを移行します。

前提条件: 

- すべてのプロジェクトに必要な[一般的な移行ステップ](#migrate-to-dependency-scanning-using-sbom)を完了します。
- プロジェクトのデベロッパー、メンテナー、またはオーナーロール。

uvプロジェクトを新しい依存関係スキャンアナライザーを使用するように移行するために、追加のステップはありません。

### Yarn {#yarn}

**Previous behavior**: Gemnasiumアナライザーに基づく依存関係スキャンは、`yarn.lock`ファイルを解析することによってプロジェクトの依存関係を抽出するために、`gemnasium-dependency_scanning` CI/CDジョブを使用するYarnプロジェクトをサポートします。Yarnと`yarn.lock`ファイルでサポートされているバージョンの組み合わせは、[Gemnasiumベースの依存関係スキャンドキュメント](_index.md#obtaining-dependency-information-by-parsing-lockfiles)に詳述されています。このアナライザーは、Yarn依存関係の[脆弱性をマージリクエストを介して解決する](../vulnerabilities/_index.md#resolve-a-vulnerability)ための修正データを提供する場合があります。このアナライザーは、`Retire.JS`スキャナーを使用してYarnプロジェクトにバンドルされたJavaScriptファイルをスキャンする場合があります。

**New behavior**: 新しい依存関係スキャンアナライザーは、`yarn.lock`ファイルを解析することでプロジェクトの依存関係を抽出し、`dependency-scanning` CI/CDジョブでCycloneDX SBOMレポートアーティファクトを生成します。このアナライザーは、Yarn依存関係の修正データを提供しません。代替機能のサポートは、[エピック](https://gitlab.com/groups/gitlab-org/-/epics/759) 759で提案されています。このアナライザーは、ベンダー提供されたJavaScriptファイルをスキャンしません。代替機能のサポートは、[エピック7186](https://gitlab.com/groups/gitlab-org/-/epics/7186)で提案されています。

#### Yarnプロジェクトを移行する {#migrate-a-yarn-project}

新しい依存関係スキャンアナライザーを使用するようにYarnプロジェクトを移行します。

前提条件: 

- すべてのプロジェクトに必要な[一般的な移行ステップ](#migrate-to-dependency-scanning-using-sbom)を完了します。
- プロジェクトのデベロッパー、メンテナー、またはオーナーロール。

Yarnプロジェクトを新しい依存関係スキャンアナライザーを使用するように移行するために、追加のステップはありません。マージリクエストを介して脆弱性を解決する機能を使用している場合は、利用可能なアクションについて[非推奨のお知らせ](../../../update/deprecations.md#resolve-a-vulnerability-for-dependency-scanning-on-yarn-projects)を確認してください。JavaScriptのバンドルされたファイルスキャン機能を使用している場合は、利用可能なアクションについて[非推奨のお知らせ](../../../update/deprecations.md#dependency-scanning-for-javascript-vendored-libraries)を確認してください。

## CI/CD変数の変更 {#changes-to-cicd-variables}

既存のCI/CD変数のほとんどは、新しい依存関係スキャンアナライザーでは関連性がなくなり、それらの値は無視されます。これらが他のセキュリティアナライザーの設定にも使用されている場合を除き、CI/CD設定から削除する必要があります。

以下のCI/CD変数をCI/CD 設定から削除します:

- `DS_GRADLE_RESOLUTION_POLICY`
- `DS_IMAGE_SUFFIX`
- `DS_JAVA_VERSION`
- `DS_PIP_DEPENDENCY_PATH`
- `DS_PIP_VERSION`
- `DS_REMEDIATE_TIMEOUT`
- `DS_REMEDIATE`
- `GEMNASIUM_DB_LOCAL_PATH`
- `GEMNASIUM_DB_REF_NAME`
- `GEMNASIUM_DB_REMOTE_URL`
- `GEMNASIUM_DB_UPDATE_DISABLED`
- `GEMNASIUM_IGNORED_SCOPES`
- `GEMNASIUM_LIBRARY_SCAN_ENABLED`
- `GOARCH`
- `GOFLAGS`
- `GOOS`
- `GOPRIVATE`
- `GRADLE_CLI_OPTS`
- `GRADLE_PLUGIN_INIT_PATH`
- `MAVEN_CLI_OPTS`
- `PIP_EXTRA_INDEX_URL`
- `PIP_INDEX_URL`
- `PIP_REQUIREMENTS_FILE`
- `PIPENV_PYPI_MIRROR`
- `SBT_CLI_OPTS`

以下のCI/CD変数は新しい依存関係スキャンアナライザーに適用されるため、保持してください:

- `DS_EXCLUDED_PATHS`
- `DS_INCLUDE_DEV_DEPENDENCIES`
- `DS_MAX_DEPTH`
- `SECURE_ANALYZERS_PREFIX`

> [!note]
> `PIP_REQUIREMENTS_FILE`は、新しい依存関係スキャンアナライザーでは`DS_PIPCOMPILE_REQUIREMENTS_FILE_NAME_PATTERN`または`pipcompile_requirements_file_name_pattern` spec入力に置き換えられます。

ユーザー設定（特にスキャン実行ポリシー）とのよりスムーズな移行を実現するため、`v2`テンプレートは以下の設定変数と下位互換性があります（これらの変数は対応する`spec:inputs`よりも優先されます）。これらの変数は次のとおりです:

- `DS_PIPCOMPILE_REQUIREMENTS_FILE_NAME_PATTERN`
- `DS_MAX_DEPTH`
- `DS_EXCLUDED_PATHS`
- `DS_INCLUDE_DEV_DEPENDENCIES`
- `DS_STATIC_REACHABILITY_ENABLED`
- `SECURE_LOG_LEVEL`

さらに、3つの変数が追加されています。これらは`latest`テンプレートには含まれておらず、脆弱性スキャンAPIの機能を制御します。

- `DS_API_TIMEOUT`
- `DS_API_SCAN_DOWNLOAD_DELAY`
- `DS_ENABLE_VULNERABILITY_SCAN`
