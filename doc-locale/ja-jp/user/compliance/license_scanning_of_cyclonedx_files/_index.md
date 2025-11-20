---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: CycloneDXファイルのライセンススキャン
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 15.9でGitLab SaaS向けに、`license_scanning_sbom_scanner`および`package_metadata_synchronization`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/384932)されました。どちらの機能フラグも、デフォルトで無効になっています。
- GitLab 16.4で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/385176)になりました。機能フラグ`license_scanning_sbom_scanner`および`package_metadata_synchronization`は削除されました。
- レガシーライセンスコンプライアンスアナライザー（`License-Scanning.gitlab-ci.yml`）は、GitLab 17.0で[削除](https://gitlab.com/gitlab-org/gitlab/-/issues/439162)されました。
- GitLab 17.5では、機能フラグ`license_scanning_with_sbom_licenses`の背後にあるライセンス情報のデータソースとして、CycloneDXレポートアーティファクトを使用する機能が導入されました（デフォルトでは無効）。
- GitLab 17.6では、CycloneDXレポートアーティファクトをライセンス情報のデータソースとして使用する機能が、デフォルトで有効になりました。機能フラグ`license_scanning_with_sbom_licenses`は、必要に応じて機能を無効にするために、まだ存在します。
- GitLab 17.8では、機能フラグ`license_scanning_with_sbom_licenses`が削除されました。

{{< /history >}}

使用中のライセンスを検出するために、ライセンスコンプライアンスは、[依存関係スキャンCI/CDジョブ](../../application_security/dependency_scanning/_index.md)を実行し、これらのジョブによって生成された[CycloneDX](https://cyclonedx.org/)ソフトウェア部品表（SBOM）を解析することに依存します。このスキャン方法は、[SPDXリスト](https://spdx.org/licenses/)で定義されているように、600種類以上のライセンスを解析して識別できます。サードパーティのスキャナーを使用して、[サポートされている言語](#supported-languages-and-package-managers)のいずれかのCycloneDXレポートアーティファクトを作成し、GitLab CycloneDXプロパティ分類に従う限り、依存関係のリストを生成できます。他のライセンスを提供する機能は、[エピック10861](https://gitlab.com/groups/gitlab-org/-/epics/10861)で追跡されています。

{{< alert type="note" >}}

ライセンススキャン機能は、外部データベースに収集され、GitLabインスタンスと自動的に同期される、公開されているパッケージメタデータに依存しています。このデータベースは、米国でホストされているマルチリージョンGoogle Cloud Storageバケットです。このスキャンは、GitLabインスタンス内でのみ実行されます。コンテキスト情報（たとえば、プロジェクトの依存関係のリスト）は、外部サービスに送信されません。

{{< /alert >}}

## 設定 {#configuration}

CycloneDXファイルのライセンススキャンを有効にするには、次のようにします:

- 依存関係スキャンテンプレートの使用
  - [依存関係スキャン](../../application_security/dependency_scanning/_index.md#getting-started)を有効にし、その前提条件が満たされていることを確認します。
  - GitLab Self-Managedでは、GitLabインスタンスの**管理者**エリアで[同期するパッケージレジストリメタデータを選択](../../../administration/settings/security_and_compliance.md#choose-package-registry-metadata-to-sync)できます。このデータ同期を機能させるには、GitLabインスタンスからドメイン`storage.googleapis.com`への送信ネットワークトラフィックを許可する必要があります。ネットワーク接続が制限されているか、まったくない場合は、ドキュメントセクション[オフライン環境での実行](#running-in-an-offline-environment)を参照して、詳細なガイダンスを入手してください。
- または、該当するパッケージレジストリの[CI/CDコンポーネント](../../../ci/components/_index.md)を使用します。

## サポートされている言語とパッケージマネージャー {#supported-languages-and-package-managers}

ライセンススキャンは、次の言語とパッケージマネージャーでサポートされています:

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
      <td><a href="https://doc.rust-lang.org/cargo/">Cargo</a></td>
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

**Footnotes**（脚注）: 

1. `stdlib`などのGo言語標準ライブラリはサポートされておらず、`unknown`ライセンスで表示されます。これらのサポートは、[イシュー480305](https://gitlab.com/gitlab-org/gitlab/-/issues/480305)で追跡されています。
<!-- markdownlint-disable MD044 -->

サポートされているファイルとバージョンは、[依存関係スキャン](../../application_security/dependency_scanning/_index.md#supported-languages-and-package-managers)でサポートされているものです。

## データソース {#data-sources}

サポートされているパッケージのライセンス情報は、以下のソースから取得されます。GitLabは元のデータに対して追加の処理を行います。これには、バリエーションを標準的なライセンス名にマッピングすることが含まれます。

| パッケージマネージャー | ソース                                                           |
|-----------------|------------------------------------------------------------------|
| Cargo           | <https://deps.dev/>                                              |
| Conan           | <https://github.com/conan-io/conan-center-index>                 |
| Go              | <https://index.golang.org/>                                      |
| Maven           | <https://storage.googleapis.com/maven-central>                   |
| npm             | <https://deps.dev/>                                              |
| NuGet           | <https://api.nuget.org/v3/catalog0/index.json>                   |
| Packagist       | <https://packagist.org/packages/list.json>                       |
| PyPI            | <https://warehouse.pypa.io/api-reference/bigquery-datasets.html> |
| RubyGems        | <https://rubygems.org/versions>                                  |

## ライセンス式 {#license-expressions}

CycloneDXファイルのライセンススキャンは、[複合ライセンス](https://spdx.github.io/spdx-spec/v2-draft/SPDX-license-expressions/)をサポートしていません。この機能の追加は、[イシュー336878](https://gitlab.com/gitlab-org/gitlab/-/issues/336878)で追跡されています。

## 検出されたライセンスに基づいてマージリクエストをブロックする {#blocking-merge-requests-based-on-detected-licenses}

ユーザーは、[ライセンス承認ポリシー](../license_approval_policies.md)を構成することにより、検出されたライセンスに基づいてマージリクエストの承認を要求できます。

## オフライン環境での実行 {#running-in-an-offline-environment}

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

インターネット経由で外部リソースへのアクセスが制限されている、または断続的なアクセスであるインスタンスでは、ライセンスについてCycloneDXレポートを正常にスキャンするために、いくつかの調整が必要です。詳細については、オフライン[クイックスタートガイド](../../../topics/offline/quick_start_guide.md#enabling-the-package-metadata-database)を参照してください。

## ライセンス情報のソースとしてCycloneDXレポートを使用する {#use-cyclonedx-report-as-a-source-of-license-information}

{{< history >}}

- GitLab 17.5で`license_scanning_with_sbom_licenses`[フラグ](../../../administration/feature_flags/_index.md)とともに導入されました。デフォルトでは無効になっています。
- GitLab 17.6のGitLab.com、GitLab Self-Managed、GitLab Dedicatedで有効になりました。
- 一般提供は、GitLab 17.8で一般提供となりました。機能フラグ`license_scanning_with_sbom_licenses`は削除されました。

{{< /history >}}

ライセンススキャンは、利用可能な場合、CycloneDX JSON SBOMの[licenses](https://cyclonedx.org/use-cases/#license-compliance)フィールドを使用します。ライセンス情報が利用できない場合、外部ライセンスデータベースからインポートされたライセンス情報が使用されます（現在の動作）。ライセンス情報は、有効なSPDX識別子またはライセンス名を使用して提供できます。ただし、SPDXライセンス式を使用したライセンスの提供はサポートされていません。ライセンスフィールド形式の詳細については、[CycloneDX](https://cyclonedx.org/use-cases/#license-compliance)仕様を参照してください。

ライセンスフィールドを提供する互換性のあるCycloneDX SBOMジェネレーターは、[CycloneDXツールセンター](https://cyclonedx.org/tool-center/)にあります。

SPDX識別子を提供するライセンスのみが現在サポートされています。この機能をSDPXライセンスを超えて拡張することは、[イシュー505677](https://gitlab.com/gitlab-org/gitlab/-/issues/505677)で追跡されています。

### ライセンス情報ソースの構成 {#configure-license-information-source}

{{< history >}}

- GitLab 18.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/501662)されました。

{{< /history >}}

両方が利用可能な場合に使用するライセンス情報ソースを選択します。

プロジェクトの優先ライセンス情報ソースを構成するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **セキュリティ** > **セキュリティ設定**を選択します。
1. **ライセンス情報元**セクションで、次のいずれかを選択します:
   - **SBOM**（デフォルト）- CycloneDXレポートからライセンス情報を使用します。
     - スキャナーは、`/gl-sbom-*.cdx.json`のプロジェクトにあるレポートからライセンス情報を読み取ります。
     - ライセンスを上書きするには、このファイルでライセンスデータを直接更新します。
   - **PMDB** \- 外部ライセンスデータベースからのライセンス情報を使用します。

## トラブルシューティング {#troubleshooting}

### CycloneDXファイルがスキャンされず、結果が表示されないようです {#a-cyclonedx-file-is-not-being-scanned-and-appears-to-provide-no-results}

CycloneDXファイルが[CycloneDX JSON仕様](https://cyclonedx.org/docs/latest/json)に準拠していることを確認してください。この仕様は、[重複エントリを許可しません](https://cyclonedx.org/docs/latest/json/#components)。複数のSBOMファイルを含むプロジェクトは、各SBOMファイルを個別のCIレポートアーティファクトとして報告するか、CIパイプラインの一部としてSBOMがマージする場合に重複が削除されていることを確認する必要があります。

`CycloneDX JSON specification`に対して、次のようにCycloneDX SBOMファイルを検証することができます:

```shell
$ docker run -it --rm -v "$PWD:/my-cyclonedx-sboms" -w /my-cyclonedx-sboms cyclonedx/cyclonedx-cli:latest cyclonedx validate --input-version v1_4 --input-file gl-sbom-all.cdx.json

Validating JSON BOM...
BOM validated successfully.
```

JSON BOMの検証が失敗した場合（たとえば、重複するコンポーネントがある場合）:

```shell
Validation failed: Found duplicates at the following index pairs: "(A, B), (C, D)"
#/properties/components/uniqueItems
```

このイシューは、CIテンプレートを更新して[jq](https://jqlang.github.io/jq/)を使用して、重複するコンポーネントを生成するジョブ定義をオーバーライドすることにより、`gl-sbom-*.cdx.json`レポートから重複するコンポーネントを削除することで修正できます。たとえば、次は、`gemnasium-dependency_scanning`ジョブによって生成された`gl-sbom-gem-bundler.cdx.json`レポートファイルから重複するコンポーネントを削除します:

```yaml
include:
  - template: Jobs/Dependency-Scanning.gitlab-ci.yml

gemnasium-dependency_scanning:
  after_script:
    - apk update && apk add jq
    - jq '.components |= unique' gl-sbom-gem-bundler.cdx.json > tmp.json && mv tmp.json gl-sbom-gem-bundler.cdx.json
```

### 未使用のライセンスデータの削除 {#remove-unused-license-data}

ライセンススキャンの変更（GitLab 15.9でリリース）では、インスタンスで使用できる追加のディスク容量が大幅に必要でした。このイシューは、GitLab 16.3で[ディスク上のパッケージメタデータテーブルのフットプリントを削減する](https://gitlab.com/groups/gitlab-org/-/epics/10415)エピックによって解決されました。ただし、GitLab 15.9と16.3の間でライセンススキャンを実行していたインスタンスでは、不要なデータを削除することをお勧めします。

不要なデータを削除するには:

1. [package_metadata_synchronization](https://about.gitlab.com/releases/2023/02/22/gitlab-15-9-released/#new-license-compliance-scanner)機能フラグが現在有効になっているか、以前に有効になっていたかどうかを確認し、有効になっている場合は無効にします。[Railsコンソール](../../../administration/operations/rails_console.md)を使用して、次のコマンドを実行します。

   ```ruby
   Feature.enabled?(:package_metadata_synchronization) && Feature.disable(:package_metadata_synchronization)
   ```

1. データベースに非推奨データがあるかどうかを確認します:

   ```ruby
   PackageMetadata::PackageVersionLicense.count
   PackageMetadata::PackageVersion.count
   ```

1. データベースに非推奨データがある場合は、次のコマンドを順番に実行して削除します:

   ```ruby
   ActiveRecord::Base.connection.execute('SET statement_timeout TO 0')
   PackageMetadata::PackageVersionLicense.delete_all
   PackageMetadata::PackageVersion.delete_all
   ```

### 依存関係ライセンスが不明です {#dependency-licenses-are-unknown}

オープンソースライセンス情報はデータベースに保存され、プロジェクトの依存関係のライセンスを解決するために使用されます。ライセンス情報が存在しない場合、またはそのデータがまだデータベースで使用できない場合、依存関係のライセンスは`unknown`と表示される場合があります。

依存関係のライセンスのルックアップはパイプラインの完了時に行われるため、その時点でこのデータが利用できない場合、`unknown`ライセンスが記録されます。このライセンスは、後続のパイプラインが実行され、別のライセンスルックアップが作成されるまで表示されます。ルックアップが依存関係のライセンスが変更されたことを確認した場合、この時点で新しいライセンスが表示されます。
