---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: CycloneDXファイルのライセンススキャン
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- 従来のライセンスコンプライアンスアナライザー（`License-Scanning.gitlab-ci.yml`）はGitLab 17.0で[削除](https://gitlab.com/gitlab-org/gitlab/-/issues/439162)されました。
- GitLab 17.5では、ライセンス情報のデータソースとしてCycloneDXレポートアーティファクトを使用するサポートが導入されました。この機能は、機能フラグ`license_scanning_with_sbom_licenses`の背後でリリースされ、デフォルトで無効になっています。
- GitLab 17.6では、ライセンス情報のデータソースとしてCycloneDXレポートアーティファクトを使用することがデフォルトで有効になりました。機能フラグ`license_scanning_with_sbom_licenses`は、必要に応じてその機能を無効にするために、引き続き存在しています。
- GitLab 17.8で機能フラグ`license_scanning_with_sbom_licenses`は削除されました。

{{< /history >}}

使用中のライセンスを検出するために、ライセンスコンプライアンスは、[依存関係スキャンジョブ](../../application_security/dependency_scanning/_index.md)の実行と、それらのジョブによって生成される[CycloneDX](https://cyclonedx.org/)ソフトウェア部品表 (SBOM) の解析に依存しています。このスキャン方法は、[SPDXリスト](https://spdx.org/licenses/)で定義されているように、600種類以上の異なるライセンスタイプを解析および識別できます。サードパーティのスキャナーは、[サポート言語](#supported-languages-and-package-managers)向けのCycloneDXレポートアーティファクトを生成し、GitLab CycloneDXのプロパティ分類に従う限り、依存関係のリストを生成するために使用できます。他のライセンスを提供する機能は、[エピック10861](https://gitlab.com/groups/gitlab-org/-/epics/10861)で追跡されています。

> [!note]
> ライセンススキャン機能は、外部データベースで収集され、GitLabインスタンスと自動的に同期される公開パッケージメタデータに依存しています。このデータベースは、米国でホストされているマルチリージョンのGoogle Cloud Storageバケットです。スキャンはGitLabインスタンス内でのみ実行されます。コンテキスト情報（例: プロジェクトの依存関係のリスト）は、外部サービスには送信されません。

## 設定 {#configuration}

CycloneDXファイルのライセンススキャンを有効にするには、次の手順を実行します:

- 依存関係スキャンテンプレートを使用する
  - [依存関係スキャン](../../application_security/dependency_scanning/dependency_scanning_sbom/_index.md#turn-on-dependency-scanning)を有効にし、その前提条件が満たされていることを確認します。
  - GitLab Self-Managedでは、GitLabインスタンスの**管理者**エリアで[パッケージレジストリメタデータを同期するように選択](../../../administration/settings/security_and_compliance.md#choose-package-registry-metadata-to-sync)できます。このデータ同期を機能させるには、GitLabインスタンスからドメイン`storage.googleapis.com`への送信ネットワークトラフィックを許可する必要があります。ネットワーク接続が制限されているか、まったくない場合の詳細なガイダンスについては、ドキュメントセクションの[オフライン環境で実行する](#running-in-an-offline-environment)を参照してください。
- または、該当するパッケージレジストリには[CI/CDコンポーネント](../../../ci/components/_index.md)を使用します。

## サポートされている言語とパッケージマネージャー {#supported-languages-and-package-managers}

{{< history >}}

- SwiftのサポートはGitLab 17.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/506756)されました。
- DartのサポートはGitLab 18.10で[導入](https://gitlab.com/groups/gitlab-org/-/epics/18351)されました。

{{< /history >}}

ライセンススキャンは、以下の言語とパッケージマネージャーでサポートされています:

<!-- markdownlint-disable MD044 -->
<table class="supported-languages">
  <thead>
    <tr>
      <th>言語</th>
      <th>パッケージマネージャー</th>
      <th>依存関係スキャンテンプレート</th>
      <th>CI/CDコンポーネント</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>.NET</td>
      <td rowspan="2"><a href="https://www.nuget.org/">NuGet</a></td>
      <td>はい</td>
      <td>いいえ</td>
    </tr>
    <tr>
      <td>C#</td>
      <td>はい</td>
      <td>いいえ</td>
    </tr>
    <tr>
      <td>C</td>
      <td rowspan="2"><a href="https://conan.io/">Conan</a></td>
      <td>はい</td>
      <td>いいえ</td>
    </tr>
    <tr>
      <td>C++</td>
      <td>はい</td>
      <td>いいえ</td>
    </tr>
    <tr>
      <td>Dart</td>
      <td><a href="https://pub.dev/">pub</a></td>
      <td>はい</td>
      <td>いいえ</td>
    </tr>
    <tr>
      <td>Go<sup>1</sup></td>
      <td><a href="https://go.dev/">Go</a></td>
      <td>はい</td>
      <td>いいえ</td>
    </tr>
    <tr>
      <td rowspan="3">Java</td>
      <td><a href="https://gradle.org/">Gradle</a></td>
      <td>はい</td>
      <td>いいえ</td>
    </tr>
    <tr>
      <td><a href="https://maven.apache.org/">Maven</a></td>
      <td>はい</td>
      <td>いいえ</td>
    </tr>
    <tr>
      <td><a href="https://developer.android.com/">Android</a></td>
      <td>はい</td>
      <td><a href="https://gitlab.com/components/android-dependency-scanning">はい</a></td>
    </tr>
    <tr>
      <td rowspan="3">JavaScriptとTypeScript</td>
      <td><a href="https://www.npmjs.com/">npm</a></td>
      <td>はい</td>
      <td>いいえ</td>
    </tr>
    <tr>
      <td><a href="https://pnpm.io/">pnpm</a></td>
      <td>はい</td>
      <td>いいえ</td>
    </tr>
    <tr>
      <td><a href="https://classic.yarnpkg.com/en/">yarn</a></td>
      <td>はい</td>
      <td>いいえ</td>
    </tr>
    <tr>
      <td>PHP</td>
      <td><a href="https://getcomposer.org/">Composer</a></td>
      <td>はい</td>
      <td>いいえ</td>
    </tr>
    <tr>
      <td rowspan="4">Python</td>
      <td><a href="https://setuptools.readthedocs.io/en/latest/">setuptools</a></td>
      <td>はい</td>
      <td>いいえ</td>
    </tr>
    <tr>
      <td><a href="https://pip.pypa.io/en/stable/">pip</a></td>
      <td>はい</td>
      <td>いいえ</td>
    </tr>
    <tr>
      <td><a href="https://pipenv.pypa.io/en/latest/">Pipenv</a></td>
      <td>はい</td>
      <td>いいえ</td>
    </tr>
    <tr>
      <td><a href="https://python-poetry.org/">Poetry</a></td>
      <td>はい</td>
      <td>いいえ</td>
    </tr>
    <tr>
      <td>Ruby</td>
      <td><a href="https://bundler.io/">Bundler</a></td>
      <td>はい</td>
      <td>いいえ</td>
    </tr>
    <tr>
      <td>Rust</td>
      <td><a href="https://doc.rust-lang.org/cargo/">cargo</a></td>
      <td>いいえ</td>
      <td><a href="https://gitlab.com/components/dependency-scanning#generating-cargo-sboms">はい</a></td>
    </tr>
    <tr>
      <td>Scala</td>
      <td><a href="https://www.scala-sbt.org/">sbt</a></td>
      <td>はい</td>
      <td>いいえ</td>
    </tr>
    <tr>
      <td>Swift</td>
      <td><a href="https://developer.apple.com/swift/">sbt</a></td>
      <td>はい</td>
      <td>いいえ</td>
    </tr>
  </tbody>
</table>
<!-- markdownlint-enable MD044 -->

**脚注**: 

1. Goの標準ライブラリ（`stdlib`など）はサポートされておらず、`unknown`のライセンスとして表示されます。これらに対するサポートは、[イシュー480305](https://gitlab.com/gitlab-org/gitlab/-/issues/480305)で追跡されています。

サポートされているファイルとバージョンは、[依存関係スキャン](../../application_security/dependency_scanning/dependency_scanning_sbom/_index.md#supported-languages-and-files)によってサポートされているものです。

## データソース {#data-sources}

サポートされているパッケージのライセンス情報は、以下のソースから取得されます。GitLabは元のデータに追加の処理を行います。これには、バリエーションを標準的なライセンス名にマッピングすることが含まれます。

| パッケージマネージャー | ソース                                                           |
|-----------------|------------------------------------------------------------------|
| Cargo           | <https://deps.dev/>                                              |
| Conan           | <https://github.com/conan-io/conan-center-index>                 |
| Go              | <https://index.golang.org/>                                      |
| Maven           | <https://storage.googleapis.com/maven-central>                   |
| npm             | <https://deps.dev/>                                              |
| NuGet           | <https://api.nuget.org/v3/catalog0/index.json>                   |
| Packagist       | <https://packagist.org/packages/list.json>                       |
| pub             | <https://pub.dev/>                                               |
| PyPI            | <https://warehouse.pypa.io/api-reference/bigquery-datasets.html> |
| RubyGems        | <https://rubygems.org/versions>                                  |

## ライセンス式 {#license-expressions}

{{< history >}}

- SBOMにおけるSPDXライセンス表現のサポートがGitLab 19.3で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/work_items/606225)。

{{< /history >}}

GitLabは、カスタムの非SPDXライセンス用の`LicenseRef-[NAME]`構文を含め、CycloneDX SBOMの`expression`フィールドからSPDXの[ライセンス表現](https://spdx.github.io/spdx-spec/v2-draft/SPDX-license-expressions/)を読み取ります。コンポーネントのSBOMエントリに`expression`が含まれている場合、GitLabは完全な表現を保存および評価します。以前は、ライセンス表現を持つコンポーネントは`unknown`ライセンスとして表示されていました。

ライセンス表現は[ライセンス承認ポリシー](../license_approval_policies.md)でサポートされています。ポリシーがコンポーネントの表現の用語として表示されるライセンスをターゲットとする場合、ポリシーは完全な表現に対して正しく評価されます。

## 検出されたライセンスに基づいてマージリクエストをブロックする {#blocking-merge-requests-based-on-detected-licenses}

ユーザーは、検出されたライセンスに基づいてマージリクエストに対する承認を、[ライセンス承認ポリシー](../license_approval_policies.md)を構成することで要求できます。

## オフライン環境で実行する {#running-in-an-offline-environment}

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

インターネット経由で外部リソースへのアクセスが制限されている、または不安定な環境にあるインスタンスでは、ライセンスのCycloneDXレポートを正常にスキャンするためにいくつかの調整が必要です。詳細については、オフラインの[クイックスタートガイド](../../../topics/offline/quick_start_guide.md#enabling-the-package-metadata-database)を参照してください。

## CycloneDXレポートをライセンス情報のソースとして使用する {#use-cyclonedx-report-as-a-source-of-license-information}

{{< history >}}

- GitLab 17.5で、`license_scanning_with_sbom_licenses`という名前の[機能フラグ](../../../administration/feature_flags/_index.md)とともに導入されました。デフォルトでは無効になっています。
- GitLab 17.6のGitLab.com、GitLab Self-Managed、およびGitLab Dedicatedで有効になりました。
- GitLab 17.8で一般公開されました。機能フラグ`license_scanning_with_sbom_licenses`は削除されました。
- SPDXライセンス表現のサポートがGitLab 19.3で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/work_items/606225)。

{{< /history >}}

ライセンススキャンは、利用可能な場合にCycloneDX JSON SBOMの[ライセンス](https://cyclonedx.org/use-cases/#license-compliance)フィールドを使用します。ライセンス情報が利用できない場合は、外部ライセンスデータベースからインポートされたライセンス情報が使用されます。ライセンス情報は、有効なSPDX識別子、ライセンス名、またはSPDXライセンス表現を使用して提供できます。ライセンスフィールドのフォーマットに関する詳細情報は、[CycloneDX](https://cyclonedx.org/use-cases/#license-compliance)仕様にあります。

ライセンスフィールドを提供する互換性のあるCycloneDX SBOMジェネレーターは、[CycloneDX Tool Center](https://cyclonedx.org/tool-center/)にあります。

### ライセンス情報元を構成する {#configure-license-information-source}

{{< history >}}

- GitLab 18.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/501662)されました。

{{< /history >}}

どちらも利用可能な場合に、使用するライセンス情報元を選択します。

プロジェクトの推奨されるライセンス情報元を構成するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 左側のサイドバーで、**セキュリティ** > **セキュリティ設定**を選択します。
1. **ライセンス情報元**セクションで、いずれかを選択します:
   - **SBOM**（デフォルト）- CycloneDXレポートからライセンス情報を使用します。
     - スキャナーは、`/gl-sbom-*.cdx.json`にあるプロジェクト内のレポートからライセンス情報を読み取ります。
     - ライセンスを上書きするには、このファイル内のライセンスデータを直接更新してください。
   - **PMDB** \- 外部ライセンスデータベースからライセンス情報を使用します。

### CycloneDXファイルのライセンススキャンを有効または無効にする {#enable-or-disable-license-scanning-for-cyclonedx-files}

{{< history >}}

- GitLab 19.0で`license_scanning_for_cyclonedx_setting`[機能フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/500716)されました。デフォルトでは無効になっています。
- GitLab 19.2で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/241413)になりました。機能フラグ`license_scanning_for_cyclonedx_setting`は削除されました。

{{< /history >}}

ライセンススキャンは、インジェストされたすべてのCycloneDX SBOMファイルに対して、デフォルトで実行されます。プロジェクトごとにライセンススキャンを無効にするには、セキュリティ設定ページから行えます。無効にすると、SBOMの取り込みからのライセンスは、依存関係リストに`unknown`と表示されます。

前提条件: 

- プロジェクトのメンテナー、オーナー、またはセキュリティマネージャーロールが必要です。

CycloneDXファイルのライセンススキャンを有効または無効にするには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 左側のサイドバーで、**セキュリティ** > **セキュリティ設定**を選択します。
1. **CycloneDXのライセンススキャン**セクションで、切替をオンまたはオフにします。

## トラブルシューティング {#troubleshooting}

### CycloneDXファイルがスキャンされておらず、結果を提供していないように見える {#a-cyclonedx-file-is-not-being-scanned-and-appears-to-provide-no-results}

CycloneDXファイルが[CycloneDX JSON仕様](https://cyclonedx.org/docs/1.7/json/)に準拠していることを確認してください。この仕様は[重複するエントリを許可しません](https://cyclonedx.org/docs/1.7/json/#components)。複数のSBOMファイルを含むプロジェクトは、各SBOMファイルを個別のCIレポートアーティファクトとしてレポートするか、SBOMがCIパイプラインの一部としてマージされる場合に重複が削除されるようにする必要があります。

CycloneDX SBOMファイルを`CycloneDX JSON specification`に対して次のように検証できます:

```shell
$ docker run -it --rm -v "$PWD:/my-cyclonedx-sboms" -w /my-cyclonedx-sboms cyclonedx/cyclonedx-cli:latest cyclonedx validate --input-version v1_4 --input-file gl-sbom-all.cdx.json

Validating JSON BOM...
BOM validated successfully.
```

JSON BOMが検証に失敗した場合（例えば、重複するコンポーネントがあるため）:

```shell
Validation failed: Found duplicates at the following index pairs: "(A, B), (C, D)"
#/properties/components/uniqueItems
```

重複するコンポーネントを生成するジョブ定義を上書きして、`gl-sbom-*.cdx.json`レポートから重複するコンポーネントを削除するために[jq](https://jqlang.github.io/jq/)を使用するようCIテンプレートを更新することで、この問題を修正できます。例えば、次のように、`gemnasium-dependency_scanning`ジョブによって生成された`gl-sbom-gem-bundler.cdx.json`レポートファイルから重複するコンポーネントを削除します:

```yaml
include:
  - template: Jobs/Dependency-Scanning.gitlab-ci.yml

gemnasium-dependency_scanning:
  after_script:
    - apk update && apk add jq
    - jq '.components |= unique' gl-sbom-gem-bundler.cdx.json > tmp.json && mv tmp.json gl-sbom-gem-bundler.cdx.json
```

### 未使用のライセンスデータを削除する {#remove-unused-license-data}

ライセンススキャンの変更（GitLab 15.9でリリース）により、インスタンスでかなりの量の追加ディスク容量が必要になりました。このイシューは、GitLab 16.3で[オンディスクフットプリントのパッケージメタデータテーブルを削減する](https://gitlab.com/groups/gitlab-org/-/epics/10415)エピックによって解決されました。しかし、GitLab 15.9から16.3の間にライセンススキャンを実行していたインスタンスの場合、不要なデータを削除した方がよいでしょう。

不要なデータを削除するには:

1. [`package_metadata_synchronization`](https://about.gitlab.com/releases/2023/02/22/gitlab-15-9-released/#new-license-compliance-scanner)機能フラグが現在有効になっているか、以前に有効になっていたかを確認し、そうであれば無効にします。[Railsコンソール](../../../administration/operations/rails_console.md)を使用して次のコマンドを実行します。

   ```ruby
   Feature.enabled?(:package_metadata_synchronization) && Feature.disable(:package_metadata_synchronization)
   ```

1. データベースに非推奨のデータがあるか確認します:

   ```ruby
   PackageMetadata::PackageVersionLicense.count
   PackageMetadata::PackageVersion.count
   ```

1. データベースに非推奨のデータがある場合は、次のコマンドを順番に実行して削除します:

   ```ruby
   ActiveRecord::Base.connection.execute('SET statement_timeout TO 0')
   PackageMetadata::PackageVersionLicense.delete_all
   PackageMetadata::PackageVersion.delete_all
   ```

### CycloneDX SBOMの脆弱性スキャンで結果が生成されない {#vulnerability-scanning-produces-no-results-for-a-cyclonedx-sbom}

CycloneDXファイルがライセンスに対してスキャンされているにもかかわらず、脆弱性スキャンで結果が生成されない場合は、[カスタムまたはマージされたCycloneDX SBOMの脆弱性スキャンで結果が生成されない](../../application_security/dependency_scanning/legacy_dependency_scanning/troubleshooting_dependency_scanning.md#vulnerability-scanning-produces-no-results-for-custom-or-merged-cyclonedx-sboms)を参照してください。

### 依存ライセンスが不明 {#dependency-licenses-are-unknown}

オープンソースのライセンス情報はデータベースに保存され、プロジェクトの依存関係のライセンスを解決するために使用されます。ライセンス情報が存在しない場合、またはそのデータがまだデータベースで利用できない場合、依存関係のライセンスは`unknown`と表示される場合があります。

依存関係のライセンスの検索はパイプライン完了時に行われるため、その時点でこのデータが利用できなかった場合、`unknown`ライセンスが記録されます。このライセンスは、その後のパイプラインが実行され、その時点で別のライセンス検索が行われるまで表示されます。検索によって依存関係のライセンスが変更されたことが確認された場合、この時点で新しいライセンスが表示されます。
