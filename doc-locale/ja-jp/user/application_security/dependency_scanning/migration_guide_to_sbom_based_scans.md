---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: SBOMを使用した依存関係スキャンに移行する
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- 従来の[Gemnasiumアナライザーに基づく依存関係スキャン機能](_index.md)は、GitLab 17.9で[非推奨](../../../update/deprecations.md#dependency-scanning-upgrades-to-the-gitlab-sbom-vulnerability-scanner)となり、GitLab 19.0で削除される予定です。

{{< /history >}}

依存関係スキャン機能は、GitLab SBOM脆弱性スキャナーにアップグレードされます。この変更の一環として、[SBOMを使用した依存関係スキャン](dependency_scanning_sbom/_index.md)機能と[新しい依存関係スキャンアナライザー](https://gitlab.com/gitlab-org/security-products/analyzers/dependency-scanning)により、Gemnasiumアナライザーに基づく従来の依存関係スキャン機能が置き換えられます。ただし、今回の移行によって導入される大幅な変更により、自動的には実装されません。このドキュメントは、移行ガイドとして提供されます。

GitLab依存関係スキャンを使用しており、次のいずれかの条件に該当する場合は、この移行ガイドに従ってください:

- 依存関係スキャンCI/CDジョブが、依存関係スキャンCI/CDテンプレートを含めることによって構成されている。

  ```yaml
    include:
      - template: Jobs/Dependency-Scanning.gitlab-ci.yml
      - template: Jobs/Dependency-Scanning.latest.gitlab-ci.yml
  ```

- 依存関係スキャンCI/CDジョブが、[スキャン実行ポリシー](../policies/scan_execution_policies.md)を使用して構成されている。
- 依存関係スキャンCI/CDジョブが、[パイプライン実行ポリシー](../policies/pipeline_execution_policies.md)を使用して構成されている。

## 変更点の理解 {#understand-the-changes}

SBOMを使用した依存関係スキャンにプロジェクトを移行する前に、導入される基本的な変更を理解しておく必要があります。今回の移行は、技術的な進化、GitLabにおける依存関係スキャンの動作方法に対する新しいアプローチ、ユーザーエクスペリエンスに対するさまざまな改善を表しています。その一部を以下に示します:

- サポート対象言語の増加。非推奨のGemnasiumアナライザーは、PythonとJavaの限られたサブセットのバージョンに制限されています。新しいアナライザーにより、組織は、これらのツールチェーンの古いバージョンを古いプロジェクトで使用したり、アナライザーのイメージに対するメジャーアップデートを待たずに、新しいバージョンを試したりするために必要な柔軟性を得ることができます。さらに、新しいアナライザーは、[ファイルカバレッジ](https://gitlab.com/gitlab-org/security-products/analyzers/dependency-scanning#supported-files)の向上というメリットがあります。
- パフォーマンスの向上。アプリケーションによっては、Gemnasiumアナライザーによって実行されるビルドが1時間近くかかる場合があり、重複した作業になることがあります。新しいアナライザーは、ビルドシステムを直接実行しなくなりました。代わりに、以前に定義されたビルドジョブを再利用して、全体的なスキャンパフォーマンスを向上させます。
- より小さなアタックサーフェス。ビルド機能をサポートするために、Gemnasiumアナライザーには、さまざまな依存関係がプリロードされています。新しいアナライザーは、これらの依存関係の大部分を削除し、より小さなアタックサーフェスを実現します。
- よりシンプルな設定。非推奨のGemnasiumアナライザーでは、正常に機能するために、プロキシ、認証局（CA）証明書バンドル、およびその他のさまざまなユーティリティの設定が頻繁に必要になります。新しいソリューションでは、これらの要件の多くが削除され、設定がより簡単な堅牢なツールが実現します。

### セキュリティスキャンに対する新しいアプローチ {#a-new-approach-to-security-scanning}

従来の依存関係スキャン機能を使用する場合、すべてのスキャン作業はCI/CDパイプライン内で行われます。スキャンを実行すると、Gemnasiumアナライザーは2つの重要なタスクを同時に処理します。プロジェクトの依存関係を特定し、GitLab Advisory Databaseのローカルコピーと特定のセキュリティスキャンエンジンを使用して、それらの依存関係のセキュリティ分析を直ちに実行します。次に、結果をさまざまなレポート（CycloneDX SBOMおよび依存関係スキャンセキュリティレポート）に出力します。

一方、SBOMを使用した依存関係スキャン機能は、依存関係の検出を、静的到達可能性または脆弱性スキャンなどの他の分析から分離する、分解された依存関係分析アプローチに依存しています。これらのタスクは引き続き同じCIジョブ内で実行されますが、切り離された再利用可能なコンポーネントとして機能します。たとえば、脆弱性スキャン分析では、GitLab継続的脆弱性スキャン機能もサポートする、統合エンジンであるGitLab SBOM脆弱性スキャナーが再利用されます。これにより、将来のインテグレーションポイントの機会も開かれ、より柔軟な脆弱性スキャンワークフローが可能になります。

SBOMを使用した依存関係スキャンが[アプリケーションをどのようにスキャンするか](dependency_scanning_sbom/_index.md#how-it-scans-an-application)について、詳細をお読みください。

### CI/CD設定 {#cicd-configuration}

CI/CDパイプラインの中断を防ぐため、新しいアプローチは、安定版の依存関係スキャンCI/CDテンプレート（`Dependency-Scanning.gitlab-ci.yml`）には適用されません。GitLab 18.5以降では、有効にするには、`v2`テンプレート（`Dependency-Scanning.v2.gitlab-ci.yml`）を使用する必要があります。この機能が成熟するにつれて、他の移行パスも検討される可能性があります。

[スキャン実行ポリシー](../policies/scan_execution_policies.md)を使用している場合、これらの変更はCI/CDテンプレートに基づいてビルドされるため、同じように適用されます。

[メインの依存関係スキャンCI/CDコンポーネント](https://gitlab.com/components/dependency-scanning/-/tree/main/templates/main)を使用している場合、新しいアナライザーがすでに使用されているため、変更は表示されません。ただし、Android、Rust、Swift、Cocoapods用の特殊化されたコンポーネントを使用している場合は、現在サポートされているすべての言語とパッケージマネージャーをカバーするメインコンポーネントに移行する必要があります。

### JavaおよびPythonのビルドサポート {#build-support-for-java-and-python}

1つの重要な変更は、依存関係がどのように検出されるか（特にJavaおよびPythonプロジェクトの場合）に影響します。新しいアナライザーは、アプリケーションをビルドして依存関係を判別する代わりに、ロックファイルまたは依存関係グラフファイルを介して、明示的な依存関係情報を必要とする、異なるアプローチを取ります。この変更は、これらのファイルが、リポジトリにコミットするか、CI/CDパイプライン中に動的に生成することにより、使用可能であることを確認する必要があることを意味します。これには初期セットアップが必要ですが、さまざまな環境で、より信頼性が高く一貫性のある結果が得られます。以下のセクションでは、必要に応じて、プロジェクトをこの新しいアプローチに適応させるために必要な具体的な手順について説明します。

### スキャン結果へのアクセス {#accessing-scan-results}

ユーザーは、`Dependency-Scanning.v2.gitlab-ci.yml`を使用すると、ジョブアーティファクト（`gl-dependency-scanning-report.json`）として依存関係スキャン結果を表示できます。

#### ベータ版の動作 {#beta-behavior}

この機能のベータ版のリリース後のお客様からのフィードバックに基づいて、一般リリース用の依存関係スキャンレポートアーティファクトの生成を復活させることにしました。ベータ版の動作は、透明性と履歴上の理由から、ここに記載されていますが、一般的に利用可能な機能では正式にサポートされなくなり、製品から削除される可能性があります。

<details>
  <summary>脆弱性スキャンの結果へのアクセス方法の変更点の詳細については、このセクションを展開してください。</summary>

  SBOMを使用した依存関係スキャンに移行すると、セキュリティスキャンの結果の処理方法に基本的な変更があることに気付くでしょう。新しいアプローチでは、セキュリティ分析がCI/CDパイプラインからGitLabプラットフォームに移行され、結果へのアクセス方法と操作方法が変更されます。従来の依存関係スキャン機能では、Gemnasiumアナライザーを使用するCI/CDジョブは、スキャン結果を含む[依存関係スキャンレポートアーティファクト](../../../ci/yaml/artifacts_reports.md#artifactsreportsdependency_scanning)を生成し、プラットフォームにアップロードします。これらの結果には、ジョブアーティファクトに提供されるすべての可能な方法でアクセスできます。つまり、結果がGitLabプラットフォームに到達する前に、CI/CDパイプライン内で結果を処理または変更できます。SBOMアプローチを使用した依存関係スキャンは、異なる動作をします。セキュリティ分析は、組み込みのGitLab SBOM脆弱性スキャナーを使用してGitLabプラットフォーム内で実行されるため、ジョブアーティファクトにスキャン結果は表示されなくなります。代わりに、GitLabは[CycloneDX SBOMレポートアーティファクト](../../../ci/yaml/artifacts_reports.md#artifactsreportscyclonedx)を分析します。これは、CI/CDパイプラインが生成し、セキュリティに関する発見事項をGitLabプラットフォームに直接作成します。移行をスムーズに行うために、GitLabはいくつかの下位互換性を維持します。Gemnasiumアナライザーを使用している間は、スキャン結果を含む標準アーティファクト（`artifacts:paths`を使用）を取得できます。つまり、これらの結果を必要とする後続のCI/CDジョブがある場合、それらにアクセスできます。ただし、GitLab SBOM脆弱性スキャナーが進化および改善されるにつれて、これらのアーティファクトベースの結果は、最新の機能強化を反映しなくなることに注意してください。新しい依存関係スキャンアナライザーに完全に移行する準備ができたら、プログラムでスキャン結果にアクセスする方法を調整する必要があります。ジョブアーティファクトを読み取りする代わりに、GitLab GraphQL API（特に（[`Pipeline.securityReportFindings`リソース](../../../api/graphql/reference/_index.md#pipelinesecurityreportfindings)））を使用します。
</details>

### コンプライアンスフレームワークに関する考慮事項 {#compliance-framework-considerations}

SBOMベースの依存関係スキャンに移行する場合は、コンプライアンスフレームワークへの潜在的な影響に注意してください:

- SBOMベースのスキャンを使用すると、「依存関係スキャンの実行」コンプライアンス制御が、従来の`gl-dependency-scanning-report.json`アーティファクトを予期するため、GitLab Self-Managedインスタンス（18.4以降）で失敗する可能性があります。
- このイシューは、GitLab.com (SaaS) インスタンスには影響しません。
- 組織が依存関係スキャン制御でコンプライアンスフレームワークを使用している場合は、最初に本番環境以外の環境で移行をテストしてください。

詳細については、[コンプライアンスフレームワークの互換性](dependency_scanning_sbom/_index.md#compliance-framework-compatibility)を参照してください。

## 影響を受けるプロジェクトの特定 {#identify-affected-projects}

この移行でどのプロジェクトに注意が必要かを理解することは、最初の重要なステップです。JavaおよびPythonプロジェクトでは、依存関係の処理方法が根本的に変化するため、最も大きな影響があります。影響を受けるプロジェクトの特定を支援するために、GitLabは[依存関係スキャンビルドサポート検出ヘルパー](https://gitlab.com/security-products/tooling/build-support-detection-helper)ツールを提供します。このツールは、GitLabグループまたはGitLab Self-Managedインスタンスを調べ、現在、`gemnasium-maven-dependency_scanning`または`gemnasium-python-dependency_scanning` CI/CDジョブで依存関係スキャン機能を使用しているプロジェクトを特定します。このツールを実行すると、移行中に注意が必要なプロジェクトの包括的なレポートが作成されます。この情報を早期に把握すると、特に組織全体で複数のプロジェクトを管理している場合に、移行戦略を効果的に計画するのに役立ちます。

## SBOMを使用した依存関係スキャンに移行する {#migrate-to-dependency-scanning-using-sbom}

SBOM方式を使用した依存関係スキャンに移行するには、プロジェクトごとに次の手順を実行します:

1. Gemnasiumアナライザーに基づく依存関係スキャンの既存のカスタマイズを削除します。
   - `gemnasium-dependency_scanning`、`gemnasium-maven-dependency_scanning`、または`gemnasium-python-dependency_scanning` CI/CDジョブを手動でオーバーライドして、プロジェクトの`.gitlab-ci.yml`またはパイプライン実行ポリシーのCI/CD設定でそれらをカスタマイズした場合は、それらを削除します。
   - [影響を受けるCI/CD変数](#changes-to-cicd-variables)を設定した場合は、それに応じて設定を調整してください。
1. 次のいずれかのオプションを使用して、SBOM機能を使用した依存関係スキャンを有効にします:
   - **おすすめ**: `v2`依存関係スキャンCI/CDテンプレート`Dependency-Scanning.v2.gitlab-ci.yml`を使用して、新しい依存関係スキャンアナライザーを実行します:
     1. `.gitlab-ci.yml` CI/CD設定に、`v2`依存関係スキャンCI/CDテンプレートが含まれていることを確認します。
     1. 必要に応じて、以下の言語固有の手順に従って、プロジェクトとCI/CD設定を調整します。
   - [スキャン実行ポリシー](dependency_scanning_sbom/_index.md#scan-execution-policies)を使用して、新しい依存関係スキャンアナライザーを実行します:
     1. 依存関係スキャン用に設定されたスキャン実行ポリシーを編集し、`v2`テンプレートを使用していることを確認します。
     1. 必要に応じて、以下の言語固有の手順に従って、プロジェクトとCI/CD設定を調整します。
   - [パイプライン実行ポリシー](dependency_scanning_sbom/_index.md#pipeline-execution-policies)を使用して、新しい依存関係スキャンアナライザーを実行します:
     1. 設定されたパイプライン実行ポリシーを編集し、`v2`テンプレートを使用していることを確認します。
     1. 必要に応じて、以下の言語固有の手順に従って、プロジェクトとCI/CD設定を調整します。
   - [依存関係スキャンCI/CDコンポーネント](https://gitlab.com/explore/catalog/components/dependency-scanning)を使用して、新しい依存関係スキャンアナライザーを実行します:
     1. 依存関係スキャンCI/CDテンプレートの`include`ステートメントを、`.gitlab-ci.yml` CI/CD設定の依存関係スキャンCI/CDコンポーネントに置き換えます。
     1. 必要に応じて、以下の言語固有の手順に従って、プロジェクトとCI/CD設定を調整します。

多言語プロジェクトの場合は、関連するすべての言語固有の移行手順を完了します。

{{< alert type="note" >}}

CI/CDテンプレートからCI/CDコンポーネントへの移行を決定した場合は、GitLab Self-Managedインスタンスの[現在の制限事項](../../../ci/components/_index.md#use-a-gitlabcom-component-on-gitlab-self-managed)を確認してください。

{{< /alert >}}

## 言語固有の手順 {#language-specific-instructions}

新しい依存関係スキャンアナライザーに移行する際には、プロジェクトのプログラミング言語とパッケージマネージャーに基づいて、特定の調整を行う必要があります。これらの手順は、CI/CDテンプレート、スキャン実行ポリシー、または依存関係スキャンCI/CDコンポーネントのいずれを使用して、実行するように設定したかに関係なく、新しい依存関係スキャンアナライザーを使用する場合は常に適用されます。以下のセクションでは、サポートされている各言語とパッケージマネージャーの詳細な手順について説明します。それぞれについて、以下を説明します:

- 依存関係検出がどのように変化しているか
- 提供する必要がある特定のファイル
- ワークフローにまだ含まれていない場合に、これらのファイルを生成する方法

この[フィードバックイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/523458)で、新しい依存関係スキャンアナライザーに関するフィードバックを共有してください。

### Bundler {#bundler}

**Previous behavior**（以前の動作）: Gemnasiumアナライザーに基づく依存関係スキャンは、`gemnasium-dependency_scanning` CI/CDジョブと、`Gemfile.lock`ファイル（`gems.locked`代替ファイル名もサポートされています）を解析することにより、プロジェクトの依存関係を抽出する機能を備えたBundlerプロジェクトをサポートします。サポートされているBundlerのバージョンと`Gemfile.lock`ファイルの組み合わせは、[依存関係スキャン（Gemnasiumベース）のドキュメント](_index.md#obtaining-dependency-information-by-parsing-lockfiles)で詳しく説明されています。

**New behavior**（新しい動作）: 新しい依存関係スキャンアナライザーは、`Gemfile.lock`ファイル（`gems.locked`代替ファイル名もサポートされています）を解析することによって、プロジェクトの依存関係を抽出し、`dependency-scanning` CI/CDジョブでCycloneDX SBOMレポートアーティファクトを生成します。

#### Bundlerプロジェクトの移行 {#migrate-a-bundler-project}

新しい依存関係スキャンアナライザーを使用するようにBundlerプロジェクトを移行します。

前提要件: 

- すべてのプロジェクトに必要な[一般的な移行手順](#migrate-to-dependency-scanning-using-sbom)を完了します。

依存関係スキャンアナライザーを使用するようにBundlerプロジェクトを移行するために必要な追加の手順はありません。

### CocoaPods {#cocoapods}

**Previous behavior**（以前の動作）: Gemnasiumアナライザーに基づく依存関係スキャンは、CI/CDテンプレートまたはスキャン実行ポリシーを使用する場合、CocoaPodsプロジェクトをサポートしません。CocoaPodsのサポートは、試験的なCocoapods CI/CDコンポーネントでのみ使用できます。

**New behavior**（新しい動作）: 新しい依存関係スキャンアナライザーは、`Podfile.lock`ファイルを解析してプロジェクトの依存関係を抽出し、`dependency-scanning` CI/CDジョブでCycloneDXソフトウェア部品表レポートアーティファクトを生成します。

#### CocoaPodsプロジェクトを移行する {#migrate-a-cocoapods-project}

新しい依存関係スキャンアナライザーを使用するために、CocoaPodsプロジェクトを移行します。

前提要件: 

- すべてのプロジェクトに必要な[一般的な移行手順](#migrate-to-dependency-scanning-using-sbom)を完了します。

新しい依存関係スキャンアナライザーを使用するために、CocoaPodsプロジェクトを移行するために必要な追加の手順はありません。

### Composer {#composer}

**Previous behavior**（以前の動作）: Gemnasiumアナライザーに基づく依存関係スキャンは、`gemnasium-dependency_scanning` CI/CDジョブとその`composer.lock`ファイルを解析してプロジェクトの依存関係を抽出する機能を使い、Composerプロジェクトをサポートします。サポートされているComposerのバージョンと`composer.lock`ファイルの組み合わせについては、[依存関係スキャン（Gemnasiumベース）ドキュメント](_index.md#obtaining-dependency-information-by-parsing-lockfiles)に詳しく記載されています。

**New behavior**（新しい動作）: 新しい依存関係スキャンアナライザーは、`composer.lock`ファイルを解析してプロジェクトの依存関係を抽出し、`dependency-scanning` CI/CDジョブでCycloneDXソフトウェア部品表レポートアーティファクトを生成します。

#### Composerプロジェクトを移行する {#migrate-a-composer-project}

新しい依存関係スキャンアナライザーを使用するために、Composerプロジェクトを移行します。

前提要件: 

- すべてのプロジェクトに必要な[一般的な移行手順](#migrate-to-dependency-scanning-using-sbom)を完了します。

新しい依存関係スキャンアナライザーを使用するために、Composerプロジェクトを移行するために必要な追加の手順はありません。

### Conan {#conan}

**Previous behavior**（以前の動作）: Gemnasiumアナライザーに基づく依存関係スキャンは、`gemnasium-dependency_scanning` CI/CDジョブとその`conan.lock`ファイルを解析してプロジェクトの依存関係を抽出する機能を使い、Conanプロジェクトをサポートします。サポートされているConanのバージョンと`conan.lock`ファイルの組み合わせについては、[依存関係スキャン（Gemnasiumベース）ドキュメント](_index.md#obtaining-dependency-information-by-parsing-lockfiles)に詳しく記載されています。

**New behavior**（新しい動作）: 新しい依存関係スキャンアナライザーは、`conan.lock`ファイルを解析してプロジェクトの依存関係を抽出し、`dependency-scanning` CI/CDジョブでCycloneDXソフトウェア部品表レポートアーティファクトを生成します。

#### Conanプロジェクトを移行する {#migrate-a-conan-project}

新しい依存関係スキャンアナライザーを使用するために、Conanプロジェクトを移行します。

前提要件: 

- すべてのプロジェクトに必要な[一般的な移行手順](#migrate-to-dependency-scanning-using-sbom)を完了します。

新しい依存関係スキャンアナライザーを使用するために、Conanプロジェクトを移行するために必要な追加の手順はありません。

### Go {#go}

**Previous behavior**（以前の動作）: Gemnasiumアナライザーに基づく依存関係スキャンは、`gemnasium-dependency_scanning` CI/CDジョブとその`go.mod`ファイルと`go.sum`ファイルを使用することによって、Go言語プロジェクトをサポートします。このアナライザーは、検出された依存関係の精度を高めるために`go list`コマンドを実行しようとします。これには、機能的なGo言語環境が必要です。失敗した場合、`go.sum`ファイルの解析にフォールバックします。サポートされているGo言語のバージョン、`go.mod`、`go.sum`ファイルの組み合わせについては、[依存関係スキャン（Gemnasiumベース）ドキュメント](_index.md#obtaining-dependency-information-by-parsing-lockfiles)に詳しく記載されています。

**New behavior**（新しい動作）: 新しい依存関係スキャンアナライザーは、依存関係を抽出するためにプロジェクトで`go list`コマンドを実行しようとせず、`go.sum`ファイルの解析にフォールバックしなくなりました。代わりに、プロジェクトは少なくとも`go.mod`ファイルと、[`go mod graph`コマンド](https://go.dev/ref/mod#go-mod-graph)（Go言語ツールチェーン）で生成された`go.graph`ファイルを提供する必要があります。`go.graph`ファイルは、検出されたコンポーネントの精度を高め、依存関係グラフを生成して、[依存関係パスの可視化](../dependency_list/_index.md#dependency-paths)のような機能をイネーブルメントするために必要です。これらのファイルは、`dependency-scanning` CI/CDジョブによって処理され、CycloneDXソフトウェア部品表レポートアーティファクトを生成します。このアプローチでは、GitLabが特定のGo言語のバージョンをサポートする必要はありません。

#### Go言語プロジェクトを移行する {#migrate-a-go-project}

新しい依存関係スキャンアナライザーを使用するために、Go言語プロジェクトを移行します。

前提要件: 

- すべてのプロジェクトに必要な[一般的な移行手順](#migrate-to-dependency-scanning-using-sbom)を完了します。

Go言語プロジェクトを移行するには:

- プロジェクトが`go.mod`ファイルと`go.graph`ファイルを提供していることを確認します。依存関係スキャンジョブを実行する前に、前のCI/CDジョブ（例: `build`）でGo言語ツールチェーンから[`go mod graph`コマンド](https://go.dev/ref/mod#go-mod-graph)を設定して、`dependencies.lock`ファイルを動的に生成し、[アーティファクト](../../../ci/jobs/job_artifacts.md)としてエクスポートします。

詳細と例については、[Go言語のイネーブルメント手順](dependency_scanning_sbom/_index.md#go)を参照してください。

### Gradle {#gradle}

**Previous behavior**（以前の動作）: Gemnasiumアナライザーに基づく依存関係スキャンは、`gemnasium-maven-dependency_scanning` CI/CDジョブを使用して、`build.gradle`ファイルと`build.gradle.kts`ファイルからアプリケーションをビルドすることによって、プロジェクトの依存関係を抽出するGradleプロジェクトをサポートします。Java、Kotlin、Gradleでサポートされているバージョンの組み合わせは複雑であるため、[依存関係スキャン（Gemnasiumベース）ドキュメント](_index.md#obtaining-dependency-information-by-running-a-package-manager-to-generate-a-parsable-file)に詳しく記載されています。

**New behavior**（新しい動作）: 新しい依存関係スキャンアナライザーは、依存関係を抽出するためにプロジェクトをビルドしません。代わりに、プロジェクトは[Gradle依存関係ロックプラグイン](https://github.com/nebula-plugins/gradle-dependency-lock-plugin)で生成された`dependencies.lock`ファイルを提供する必要があります。このファイルは、`dependency-scanning` CI/CDジョブによって処理され、CycloneDXソフトウェア部品表レポートアーティファクトを生成します。このアプローチでは、GitLabが特定のバージョンのJava、Kotlin、およびGradleをサポートする必要はありません。

#### Gradleプロジェクトを移行する {#migrate-a-gradle-project}

新しい依存関係スキャンアナライザーを使用するために、Gradleプロジェクトを移行します。

前提要件: 

- すべてのプロジェクトに必要な[一般的な移行手順](#migrate-to-dependency-scanning-using-sbom)を完了します。

Gradleプロジェクトを移行するには:

- プロジェクトが`dependencies.lock`ファイルを提供していることを確認します。プロジェクトで[Gradle依存関係ロックプラグイン](https://github.com/nebula-plugins/gradle-dependency-lock-plugin)を設定し、以下を実行します:
  - 開発ワークフローにプラグインを永続的に統合します。これは、`dependencies.lock`ファイルをリポジトリにコミットし、プロジェクトの依存関係に変更を加えるときに更新することを意味します。
  - 依存関係スキャンジョブを実行する前に、前のCI/CDジョブ（例: `build`）でコマンドラインを使用し、`dependencies.lock`ファイルを動的に生成して[アーティファクト](../../../ci/jobs/job_artifacts.md)としてエクスポートします。

詳細と例については、[Gradleのイネーブルメント手順](dependency_scanning_sbom/_index.md#gradle)を参照してください。

### Maven {#maven}

**Previous behavior**（以前の動作）: Gemnasiumアナライザーに基づく依存関係スキャンは、`gemnasium-maven-dependency_scanning` CI/CDジョブを使用して、`pom.xml`ファイルからアプリケーションをビルドすることによって、Mavenプロジェクトをサポートします。Java、Kotlin、Mavenでサポートされているバージョンの組み合わせは複雑であるため、[依存関係スキャン（Gemnasiumベース）ドキュメント](_index.md#obtaining-dependency-information-by-running-a-package-manager-to-generate-a-parsable-file)に詳しく記載されています。

**New behavior**（新しい動作）: 新しい依存関係スキャンアナライザーは、依存関係を抽出するためにプロジェクトをビルドしません。代わりに、プロジェクトは[maven依存関係プラグイン](https://maven.apache.org/plugins/maven-dependency-plugin/index.html)で生成された`maven.graph.json`ファイルを提供する必要があります。このファイルは、`dependency-scanning` CI/CDジョブによって処理され、CycloneDXソフトウェア部品表レポートアーティファクトを生成します。このアプローチでは、GitLabが特定のバージョンのJava、Kotlin、およびMavenをサポートする必要はありません。

#### Mavenプロジェクトを移行する {#migrate-a-maven-project}

新しい依存関係スキャンアナライザーを使用するために、Mavenプロジェクトを移行します。

前提要件: 

- すべてのプロジェクトに必要な[一般的な移行手順](#migrate-to-dependency-scanning-using-sbom)を完了します。

Mavenプロジェクトを移行するには:

- プロジェクトが`maven.graph.json`ファイルを提供していることを確認します。依存関係スキャンジョブを実行する前に、前のCI/CDジョブ（例: `build`）で[maven依存関係プラグイン](https://maven.apache.org/plugins/maven-dependency-plugin/index.html)を設定して、`maven.graph.json`ファイルを動的に生成し、[アーティファクト](../../../ci/jobs/job_artifacts.md)としてエクスポートします。

詳細と例については、[Mavenのイネーブルメント手順](dependency_scanning_sbom/_index.md#maven)を参照してください。

### npm {#npm}

**Previous behavior**（以前の動作）: Gemnasiumアナライザーに基づく依存関係スキャンは、`gemnasium-dependency_scanning` CI/CDジョブとその`package-lock.json`ファイルまたは`npm-shrinkwrap.json.lock`ファイルを解析してプロジェクトの依存関係を抽出する機能を使い、npmプロジェクトをサポートします。サポートされているnpmのバージョンと`package-lock.json`ファイルまたは`npm-shrinkwrap.json.lock`ファイルの組み合わせについては、[依存関係スキャン（Gemnasiumベース）ドキュメント](_index.md#obtaining-dependency-information-by-parsing-lockfiles)に詳しく記載されています。このアナライザーは、`Retire.JS`スキャナーを使用して、npmプロジェクトにベンダーされたJavaScriptファイルをスキャンする場合があります。

**New behavior**（新しい動作）: 新しい依存関係スキャンアナライザーは、`package-lock.json`ファイルまたは`npm-shrinkwrap.json.lock`ファイルを解析してプロジェクトの依存関係を抽出し、`dependency-scanning` CI/CDジョブでCycloneDXソフトウェア部品表レポートアーティファクトを生成します。このアナライザーは、販売されているJavaScriptファイルをスキャンしません。代替機能のサポートは、[エピック7186](https://gitlab.com/groups/gitlab-org/-/epics/7186)で提案されています。

#### npmプロジェクトを移行する {#migrate-an-npm-project}

新しい依存関係スキャンアナライザーを使用するために、npmプロジェクトを移行します。

前提要件: 

- すべてのプロジェクトに必要な[一般的な移行手順](#migrate-to-dependency-scanning-using-sbom)を完了します。

新しい依存関係スキャンアナライザーを使用するために、npmプロジェクトを移行するために必要な追加の手順はありません。

### NuGet {#nuget}

**Previous behavior**（以前の動作）: Gemnasiumアナライザーに基づく依存関係スキャンは、`gemnasium-dependency_scanning` CI/CDジョブとその`packages.lock.json`ファイルを解析してプロジェクトの依存関係を抽出する機能を使い、NuGetプロジェクトをサポートします。サポートされているNuGetのバージョンと`packages.lock.json`ファイルの組み合わせについては、[依存関係スキャン（Gemnasiumベース）ドキュメント](_index.md#obtaining-dependency-information-by-parsing-lockfiles)に詳しく記載されています。

**New behavior**（新しい動作）: 新しい依存関係スキャンアナライザーは、`packages.lock.json`ファイルを解析してプロジェクトの依存関係を抽出し、`dependency-scanning` CI/CDジョブでCycloneDXソフトウェア部品表レポートアーティファクトを生成します。

#### NuGetプロジェクトを移行する {#migrate-a-nuget-project}

新しい依存関係スキャンアナライザーを使用するために、NuGetプロジェクトを移行します。

前提要件: 

- すべてのプロジェクトに必要な[一般的な移行手順](#migrate-to-dependency-scanning-using-sbom)を完了します。

新しい依存関係スキャンアナライザーを使用するために、NuGetプロジェクトを移行するために必要な追加の手順はありません。

### pip {#pip}

**Previous behavior**（以前の動作）: Gemnasiumアナライザーに基づく依存関係スキャンは、`gemnasium-python-dependency_scanning` CI/CDジョブを使用して、`requirements.txt`ファイル（`requirements.pip`ファイルと`requires.txt`ファイルは代替ファイル名としてもサポートされています）からアプリケーションをビルドすることによって、pipプロジェクトをサポートします。`PIP_REQUIREMENTS_FILE`環境変数を使用して、カスタムファイル名を指定することもできます。Pythonとpipでサポートされているバージョンの組み合わせについては、[依存関係スキャン（Gemnasiumベース）ドキュメント](_index.md#obtaining-dependency-information-by-running-a-package-manager-to-generate-a-parsable-file)に詳しく記載されています。

**New behavior**（新しい動作）: 新しい依存関係スキャンアナライザーは、依存関係を抽出するためにプロジェクトをビルドしません。代わりに、プロジェクトは[pip-compileコマンドラインツール](https://pip-tools.readthedocs.io/en/latest/cli/pip-compile/)によって生成された`requirements.txt`ロックファイルを提供する必要があります。このファイルは、`dependency-scanning` CI/CDジョブによって処理され、CycloneDXソフトウェア部品表レポートアーティファクトを生成します。このアプローチでは、GitLabが特定のバージョンのPythonとpipをサポートする必要はありません。`pipcompile_requirements_file_name_pattern`仕様の入力または`DS_PIPCOMPILE_REQUIREMENTS_FILE_NAME_PATTERN`変数を使用して、pip-compileロックファイルのカスタムファイル名を指定することもできます。

または、プロジェクトは[pipdeptreeコマンドラインユーティリティ](https://pypi.org/project/pipdeptree/)で生成された`pipdeptree.json`ファイルを提供できます。

#### pipプロジェクトを移行する {#migrate-a-pip-project}

新しい依存関係スキャンアナライザーを使用するために、pipプロジェクトを移行します。

前提要件: 

- すべてのプロジェクトに必要な[一般的な移行手順](#migrate-to-dependency-scanning-using-sbom)を完了します。

pipプロジェクトを移行するには:

- プロジェクトが`requirements.txt`ロックファイルを提供していることを確認します。プロジェクトで[pip-compileコマンドラインツール](https://pip-tools.readthedocs.io/en/latest/cli/pip-compile/)を設定し、以下を実行します:
  - コマンドラインツールを開発ワークフローに永続的に統合します。これは、`requirements.txt`ファイルをリポジトリにコミットし、プロジェクトの依存関係に変更を加えるときに更新することを意味します。
  - 依存関係スキャンジョブを実行する前に、前のCI/CDジョブ（例: `build`）でコマンドラインツールを使用し、`requirements.txt`ファイルを動的に生成して[アーティファクト](../../../ci/jobs/job_artifacts.md)としてエクスポートします。

または

- プロジェクトが`pipdeptree.json`ロックファイルを提供していることを確認します。依存関係スキャンジョブを実行する前に、前のCI/CDジョブ（例: `build`）で[pipdeptreeコマンドラインユーティリティ](https://pypi.org/project/pipdeptree/)を設定して、`pipdeptree.json`ファイルを動的に生成し、[アーティファクト](../../../ci/jobs/job_artifacts.md)としてエクスポートします。

詳細と例については、[pipのイネーブルメント手順](dependency_scanning_sbom/_index.md#pip)を参照してください。

### Pipenv {#pipenv}

**Previous behavior**（以前の動作）: Gemnasiumアナライザーに基づく依存関係スキャンは、`gemnasium-python-dependency_scanning` CI/CDジョブを使用して、`Pipfile`ファイルまたは存在する場合は`Pipfile.lock`ファイルからアプリケーションをビルドすることによって、Pipenvプロジェクトをサポートします。PythonとPipenvでサポートされているバージョンの組み合わせについては、[依存関係スキャン（Gemnasiumベース）のドキュメント](_index.md#obtaining-dependency-information-by-running-a-package-manager-to-generate-a-parsable-file)で詳しく説明されています。

**New behavior**（新しい動作）: 新しい依存関係スキャンアナライザーは、依存関係を抽出するためにPipenvプロジェクトをビルドしません。代わりに、プロジェクトは少なくとも`Pipfile.lock`ファイルと、理想的には[`pipenv graph`コマンドライン](https://pipenv.pypa.io/en/latest/cli.html#graph)で生成された`pipenv.graph.json`ファイルを提供する必要があります。`pipenv.graph.json`ファイルは、依存関係グラフを生成し、[依存関係パス](../dependency_list/_index.md#dependency-paths)のような機能をイネーブルメントするために必要です。これらのファイルは、`dependency-scanning` CI/CDジョブによって処理され、CycloneDXソフトウェア部品表レポートアーティファクトを生成します。このアプローチでは、GitLabが特定のバージョンのPythonとPipenvをサポートする必要はありません。

#### Pipenvプロジェクトを移行する {#migrate-a-pipenv-project}

新しい依存関係スキャンアナライザーを使用するようにPipenvプロジェクトを移行します。

前提要件: 

- すべてのプロジェクトに必要な[一般的な移行手順](#migrate-to-dependency-scanning-using-sbom)を完了します。

Pipenvプロジェクトを移行するには:

- プロジェクトが`Pipfile.lock`ファイルを提供していることを確認します。プロジェクトで[`pipenv lock`コマンド](https://pipenv.pypa.io/en/latest/cli.html#graph)を設定し、次のいずれかの操作を行います:
  - コマンドを開発ワークフローに永続的に統合します。これは、`Pipfile.lock`ファイルをリポジトリにコミットし、プロジェクトの依存関係に変更を加えるときに更新することを意味します。
  - 依存関係スキャンジョブを実行する前に、前のCI/CDジョブ（例: `build`）でコマンドラインを使用し、`Pipfile.lock`ファイルを動的に生成して[アーティファクト](../../../ci/jobs/job_artifacts.md)としてエクスポートします。

または

- プロジェクトが`pipenv.graph.json`ファイルを提供していることを確認します。依存関係スキャンジョブを実行する前に、先行するCI/CDジョブ（例: `build`）で[`pipenv graph`コマンド](https://pipenv.pypa.io/en/latest/cli.html#graph)を設定し、`pipenv.graph.json`ファイルを動的に生成し、[アーティファクト](../../../ci/jobs/job_artifacts.md)としてエクスポートします。

詳細と例については、[Pipenvのイネーブルメント手順](dependency_scanning_sbom/_index.md#pipenv)を参照してください。

### Poetry {#poetry}

**Previous behavior**（以前の動作）: Gemnasiumアナライザーに基づいた依存関係スキャンは、`gemnasium-python-dependency_scanning`CI/CDジョブとその`poetry.lock`ファイルを解析してプロジェクトの依存関係を抽出する機能を使い、Poetryプロジェクトをサポートします。Poetryと`poetry.lock`ファイルでサポートされているバージョンの組み合わせについては、[依存関係スキャン（Gemnasiumベース）ドキュメント](_index.md#obtaining-dependency-information-by-parsing-lockfiles)で詳しく説明されています。

**New behavior**（新しい動作）: 新しい依存関係スキャンアナライザーは、`poetry.lock`ファイルを解析してプロジェクトの依存関係を抽出し、`dependency-scanning` CI/CDジョブでCycloneDXソフトウェア部品表レポートアーティファクトを生成します。

#### Poetryプロジェクトを移行する {#migrate-a-poetry-project}

新しい依存関係スキャンアナライザーを使用するようにPoetryプロジェクトを移行します。

前提要件: 

- すべてのプロジェクトに必要な[一般的な移行手順](#migrate-to-dependency-scanning-using-sbom)を完了します。

新しい依存関係スキャンアナライザーを使用するようにPoetryプロジェクトを移行するための追加の手順はありません。

### pnpm {#pnpm}

**Previous behavior**（以前の動作）: Gemnasiumアナライザーに基づいた依存関係スキャンは、`gemnasium-dependency_scanning`CI/CDジョブとその`pnpm-lock.yaml`ファイルを解析してプロジェクトの依存関係を抽出する機能を使い、pnpmプロジェクトをサポートします。pnpmと`pnpm-lock.yaml`ファイルでサポートされているバージョンの組み合わせについては、[依存関係スキャン（Gemnasiumベース）ドキュメント](_index.md#obtaining-dependency-information-by-parsing-lockfiles)で詳しく説明されています。このアナライザーは、`Retire.JS`スキャナーを使用して、npmプロジェクトで販売されているJavaScriptファイルをスキャンする場合があります。

**New behavior**（新しい動作）: 新しい依存関係スキャンアナライザーは、`pnpm-lock.yaml`ファイルを解析してプロジェクトの依存関係を抽出し、`dependency-scanning` CI/CDジョブでCycloneDXソフトウェア部品表レポートアーティファクトを生成します。このアナライザーは、販売されているJavaScriptファイルをスキャンしません。代替機能のサポートは、[エピック7186](https://gitlab.com/groups/gitlab-org/-/epics/7186)で提案されています。

#### pnpmプロジェクトを移行する {#migrate-a-pnpm-project}

新しい依存関係スキャンアナライザーを使用するようにpnpmプロジェクトを移行します。

前提要件: 

- すべてのプロジェクトに必要な[一般的な移行手順](#migrate-to-dependency-scanning-using-sbom)を完了します。

新しい依存関係スキャンアナライザーを使用するようにpnpmプロジェクトを移行するための追加の手順はありません。

### sbt {#sbt}

**Previous behavior**（以前の動作）: Gemnasiumアナライザーに基づいた依存関係スキャンは、`gemnasium-maven-dependency_scanning`CI/CDジョブとその`build.sbt`ファイルからアプリケーションをビルドしてプロジェクトの依存関係を抽出する機能を使い、sbtプロジェクトをサポートします。Java、Scala、およびsbtでサポートされているバージョンの組み合わせは複雑であり、[依存関係スキャン（Gemnasiumベース）ドキュメント](_index.md#obtaining-dependency-information-by-running-a-package-manager-to-generate-a-parsable-file)で詳しく説明されています。

**New behavior**（新しい動作）: 新しい依存関係スキャンアナライザーは、依存関係を抽出するためにプロジェクトをビルドしません。代わりに、プロジェクトは[sbt-依存関係グラフプラグイン](https://github.com/sbt/sbt-dependency-graph) （[sbt >= 1.4.0に含まれています](https://www.scala-sbt.org/1.x/docs/sbt-1.4-Release-Notes.html#sbt-dependency-graph+is+in-sourced)）で生成された`dependencies-compile.dot`ファイルを提供する必要があります。このファイルは、`dependency-scanning`CI/CDジョブによって処理され、CycloneDXソフトウェア部品表レポートアーティファクトを生成します。このアプローチでは、GitLabが特定のバージョンのJava、Scala、およびsbtをサポートする必要はありません。

#### sbtプロジェクトを移行する {#migrate-an-sbt-project}

新しい依存関係スキャンアナライザーを使用するようにsbtプロジェクトを移行します。

前提要件: 

- すべてのプロジェクトに必要な[一般的な移行手順](#migrate-to-dependency-scanning-using-sbom)を完了します。

sbtプロジェクトを移行するには:

- プロジェクトが`dependencies-compile.dot`ファイルを提供していることを確認します。依存関係スキャンジョブを実行する前に、先行するCI/CDジョブ（例: `build`）で[sbt-依存関係グラフプラグイン](https://github.com/sbt/sbt-dependency-graph)を設定し、`dependencies-compile.dot`ファイルを動的に生成し、[アーティファクト](../../../ci/jobs/job_artifacts.md)としてエクスポートします。

詳細と例については、[sbtのイネーブルメント手順](dependency_scanning_sbom/_index.md#sbt)を参照してください。

### setuptools {#setuptools}

**Previous behavior**（以前の動作）: Gemnasiumアナライザーに基づいた依存関係スキャンは、`gemnasium-python-dependency_scanning`CI/CDジョブとその`setup.py`ファイルからアプリケーションをビルドしてプロジェクトの依存関係を抽出する機能を使い、setuptoolsプロジェクトをサポートします。Pythonとsetuptoolsでサポートされているバージョンの組み合わせについては、[依存関係スキャン（Gemnasiumベース）ドキュメント](_index.md#obtaining-dependency-information-by-running-a-package-manager-to-generate-a-parsable-file)で詳しく説明されています。

**New behavior**（新しい動作）: 新しい依存関係スキャンアナライザーは、依存関係を抽出するためにsetuptoolプロジェクトをビルドすることをサポートしていません。互換性のある`requirements.txt`ロックファイルを生成するには、[pip-compileコマンドラインツール](https://pip-tools.readthedocs.io/en/latest/cli/pip-compile/)を設定することをお勧めします。または、独自のCycloneDXソフトウェア部品表ドキュメントを提供することもできます。

#### setuptoolsプロジェクトを移行する {#migrate-a-setuptools-project}

新しい依存関係スキャンアナライザーを使用するようにsetuptoolsプロジェクトを移行します。

前提要件: 

- すべてのプロジェクトに必要な[一般的な移行手順](#migrate-to-dependency-scanning-using-sbom)を完了します。

setuptoolsプロジェクトを移行するには:

- プロジェクトが`requirements.txt`ロックファイルを提供していることを確認します。プロジェクトで[pip-compileコマンドラインツール](https://pip-tools.readthedocs.io/en/latest/cli/pip-compile/)を設定し、以下を実行します:
  - コマンドラインツールを開発ワークフローに永続的に統合します。これは、`requirements.txt`ファイルをリポジトリにコミットし、プロジェクトの依存関係に変更を加えるときに更新することを意味します。
  - 依存関係スキャンジョブを実行する前に、`build`CI/CDジョブでコマンドラインツールを使用して`requirements.txt`ファイルを動的に生成し、[アーティファクト](../../../ci/jobs/job_artifacts.md)としてエクスポートします。

詳細と例については、[pipのイネーブルメント手順](dependency_scanning_sbom/_index.md#pip)を参照してください。

### Swift {#swift}

**Previous behavior**（以前の動作）: Gemnasiumアナライザーに基づいた依存関係スキャンは、CI/CDテンプレートまたはスキャン実行ポリシーを使用する場合、Swiftプロジェクトをサポートしていません。Swiftのサポートは、実験的なSwift CI/CDコンポーネントでのみ利用できます。

**New behavior**（新しい動作）: 新しい依存関係スキャンアナライザーは、`Package.resolved`ファイルを解析してプロジェクトの依存関係を抽出し、`dependency-scanning` CI/CDジョブでCycloneDXソフトウェア部品表レポートアーティファクトを生成します。

#### Swiftプロジェクトを移行する {#migrate-a-swift-project}

新しい依存関係スキャンアナライザーを使用するようにSwiftプロジェクトを移行します。

前提要件: 

- すべてのプロジェクトに必要な[一般的な移行手順](#migrate-to-dependency-scanning-using-sbom)を完了します。

新しい依存関係スキャンアナライザーを使用するようにSwiftプロジェクトを移行するための追加の手順はありません。

### uv {#uv}

**Previous behavior**（以前の動作）: Gemnasiumアナライザーに基づいた依存関係スキャンは、`gemnasium-dependency_scanning`CI/CDジョブとその`uv.lock`ファイルを解析してプロジェクトの依存関係を抽出する機能を使い、uvプロジェクトをサポートします。uvと`uv.lock`ファイルでサポートされているバージョンの組み合わせについては、[依存関係スキャン（Gemnasiumベース）ドキュメント](_index.md#obtaining-dependency-information-by-parsing-lockfiles)で詳しく説明されています。

**New behavior**（新しい動作）: 新しい依存関係スキャンアナライザーは、`uv.lock`ファイルを解析してプロジェクトの依存関係を抽出し、`dependency-scanning` CI/CDジョブでCycloneDXソフトウェア部品表レポートアーティファクトを生成します。

#### uvプロジェクトを移行する {#migrate-a-uv-project}

新しい依存関係スキャンアナライザーを使用するようにuvプロジェクトを移行します。

前提要件: 

- すべてのプロジェクトに必要な[一般的な移行手順](#migrate-to-dependency-scanning-using-sbom)を完了します。

新しい依存関係スキャンアナライザーを使用するようにuvプロジェクトを移行するための追加の手順はありません。

### Yarn {#yarn}

**Previous behavior**（以前の動作）: Gemnasiumアナライザーに基づいた依存関係スキャンは、`gemnasium-dependency_scanning`CI/CDジョブとその`yarn.lock`ファイルを解析してプロジェクトの依存関係を抽出する機能を使い、Yarnプロジェクトをサポートします。Yarnと`yarn.lock`ファイルでサポートされているバージョンの組み合わせについては、[依存関係スキャン（Gemnasiumベース）ドキュメント](_index.md#obtaining-dependency-information-by-parsing-lockfiles)で詳しく説明されています。このアナライザーは、Yarnの依存関係に対して、[マージリクエストを介して脆弱性を解決する](../vulnerabilities/_index.md#resolve-a-vulnerability)ための修正データを提供する場合があります。このアナライザーは、`Retire.JS`スキャナーを使用して、Yarnプロジェクトで販売されているJavaScriptファイルをスキャンする場合があります。

**New behavior**（新しい動作）: 新しい依存関係スキャンアナライザーは、`yarn.lock`ファイルを解析してプロジェクトの依存関係を抽出し、`dependency-scanning` CI/CDジョブでCycloneDXソフトウェア部品表レポートアーティファクトを生成します。このアナライザーは、Yarnの依存関係に対する修正データを提供しません。代替機能のサポートは、[エピック759](https://gitlab.com/groups/gitlab-org/-/epics/759)で提案されています。このアナライザーは、販売されているJavaScriptファイルをスキャンしません。代替機能のサポートは、[エピック7186](https://gitlab.com/groups/gitlab-org/-/epics/7186)で提案されています。

#### Yarnプロジェクトを移行する {#migrate-a-yarn-project}

新しい依存関係スキャンアナライザーを使用するようにYarnプロジェクトを移行します。

前提要件: 

- すべてのプロジェクトに必要な[一般的な移行手順](#migrate-to-dependency-scanning-using-sbom)を完了します。

新しい依存関係スキャンアナライザーを使用するようにYarnプロジェクトを移行するための追加の手順はありません。マージリクエスト機能を介して脆弱性を解決する機能を使用する場合は、利用可能なアクションについて[非推奨のお知らせ](../../../update/deprecations.md#resolve-a-vulnerability-for-dependency-scanning-on-yarn-projects)を確認してください。JavaScriptの販売ファイルスキャン機能を使用する場合は、利用可能なアクションについて[非推奨のお知らせ](../../../update/deprecations.md#dependency-scanning-for-javascript-vendored-libraries)を確認してください。

## CI/CD変数の変更 {#changes-to-cicd-variables}

既存のほとんどのCI/CD変数は、新しい依存関係スキャンアナライザーとは関係がなくなったため、その値は無視されます。これらが他のセキュリティアナライザーを設定するためにも使用されていない限り（例: `ADDITIONAL_CA_CERT_BUNDLE`）、CI/CDの設定から削除する必要があります。

CI/CDの設定から次のCI/CD変数を削除します:

- `ADDITIONAL_CA_CERT_BUNDLE`
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

次のCI/CD変数は、新しい依存関係スキャンアナライザーに適用できるため、そのままにしておきます:

- `DS_EXCLUDED_PATHS`
- `DS_INCLUDE_DEV_DEPENDENCIES`
- `DS_MAX_DEPTH`
- `SECURE_ANALYZERS_PREFIX`

{{< alert type="note" >}}

`PIP_REQUIREMENTS_FILE`は、新しい依存関係スキャンアナライザーの`DS_PIPCOMPILE_REQUIREMENTS_FILE_NAME_PATTERN`または`pipcompile_requirements_file_name_pattern`仕様入力に置き換えられました。

{{< /alert >}}

ユーザー設定（特にスキャン実行ポリシー）とのスムーズな移行を実現するために、`v2`テンプレートには、次の設定変数との下位互換性があります（これらの変数は、対応する`spec:inputs`よりも優先されます）。これらの変数は次のとおりです:

- `DS_PIPCOMPILE_REQUIREMENTS_FILE_NAME_PATTERN`
- `DS_MAX_DEPTH`
- `DS_EXCLUDED_PATHS`
- `DS_INCLUDE_DEV_DEPENDENCIES`
- `DS_STATIC_REACHABILITY_ENABLED`
- `SECURE_LOG_LEVEL`

さらに、3つの変数が追加されました。これらは`latest`テンプレートにはなく、脆弱性スキャンAPIの機能を制御します。

- `DS_API_TIMEOUT`
- `DS_API_SCAN_DOWNLOAD_DELAY`
- `DS_ENABLE_VULNERABILITY_SCAN`
