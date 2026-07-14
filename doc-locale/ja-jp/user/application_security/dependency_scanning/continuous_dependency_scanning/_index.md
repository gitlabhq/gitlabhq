---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 継続的依存関係スキャン
description: GitLabがCI/CDパイプラインの外で、アプリケーションの依存関係の新たな脆弱性を検出する方法。
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- 依存関係スキャンのための継続的脆弱性スキャンは、[導入され](https://gitlab.com/gitlab-org/gitlab/-/issues/371063)、[機能フラグ](../../../../administration/feature_flags/_index.md) `dependency_scanning_on_advisory_ingestion`および`package_metadata_advisory_scans`がデフォルトで有効化されました。
- GitLab 16.10で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/425753)になりました。機能フラグ`dependency_scanning_on_advisory_ingestion`および`package_metadata_advisory_scans`は削除されました。

{{< /history >}}

依存関係スキャンのための継続的脆弱性スキャン（CVS）は、新しいパイプラインの実行を必要とせずに、プロジェクトの依存関係にある脆弱性を、最新の[セキュリティアドバイザリー](#security-advisories)の情報とコンポーネント名およびバージョンを比較することで検索します。パイプラインは、CycloneDX SBOMを介してプロジェクトのコンポーネントを登録するために、デフォルトブランチで少なくとも1回実行される必要があります。その後、CVSは、アドバイザリーが公開されると、それ以上のパイプライン実行なしに、依存関係が変更されるまで実行されます。

[新しい脆弱性が発生する](#checking-new-vulnerabilities)のは、継続的脆弱性スキャンが[サポートされているパッケージタイプ](#supported-package-types)を持つコンポーネントを含むすべてのプロジェクトでスキャンをトリガーする場合です。

依存関係スキャンのための継続的脆弱性スキャンによって作成された脆弱性は、`GitLab SBoM Vulnerability Scanner`をスキャナー名として、`Dependency Scanning`を脆弱性タイプとして使用します。

CI/CDベースのセキュリティスキャンとは対照的に、継続的脆弱性スキャンは、CI/CDパイプラインではなくバックグラウンドジョブ（Sidekiq）を通じて実行され、セキュリティレポートアーティファクトは生成されません。

## 前提条件 {#prerequisites}

- [CycloneDX SBOMレポート](#how-to-generate-a-cyclonedx-sbom-report)。
- GitLabインスタンスに同期された[セキュリティアドバイザリー](#security-advisories)。

## サポートされているパッケージタイプ {#supported-package-types}

継続的脆弱性スキャンは、依存関係スキャンのために、以下の[PURLタイプ](https://github.com/package-url/purl-spec/blob/346589846130317464b677bc4eab30bf5040183a/PURL-TYPES.rst)を持つコンポーネントをサポートしています:

- `cargo`
- `conan`
- `go`
- `maven`
- `npm`
- `nuget`
- `packagist`
- `pub`
- `pypi`
- `rubygem`
- `swift`

Go疑似バージョンはサポートされていません。Go疑似バージョンを参照するプロジェクトの依存関係は、誤検出につながる可能性があるため、影響を受けるとはみなされません。

## CycloneDX SBOMレポートを生成する方法 {#how-to-generate-a-cyclonedx-sbom-report}

[CycloneDX SBOMレポート](../../../../ci/yaml/artifacts_reports.md#artifactsreportscyclonedx)を使用して、プロジェクトのコンポーネントをGitLabに登録します。

CycloneDXレポートは以下に準拠する必要があります:

- [CycloneDX仕様](https://github.com/CycloneDX/specification)バージョン`1.4`、`1.5`、または`1.6`。
- [GitLab CycloneDXの依存関係スキャン用プロパティ分類](../../../../development/sec/cyclonedx_property_taxonomy.md#gitlabdependency_scanning-namespace-taxonomy)。

GitLabは、GitLabと互換性のあるレポートを生成できるセキュリティアナライザーを提供しています:

- [依存関係スキャンアナライザー](../dependency_scanning_sbom/_index.md#turn-on-dependency-scanning)
- [Gemnasiumアナライザー（非推奨）](../legacy_dependency_scanning/_index.md)

## 新しい脆弱性の確認 {#checking-new-vulnerabilities}

継続的脆弱性スキャンによって検出された新しい脆弱性は、[脆弱性レポート](../../vulnerability_report/_index.md)で確認できます。しかし、それらは影響を受けたSBOMコンポーネントが検出されたパイプラインにはリストされません。

[セキュリティアドバイザリー](#security-advisories)が追加または更新された後に脆弱性が作成されますが、コードベースが変更されていない限り、対応する脆弱性がプロジェクトに追加されるまでに数時間かかる場合があります。過去14日以内に公開されたアドバイザリーのみが、継続的脆弱性スキャンの対象となります。

## 脆弱性が検出されなくなった場合 {#when-vulnerabilities-are-no-longer-detected}

継続的脆弱性スキャンは、新しいアドバイザリーが公開されると自動的に脆弱性を作成しますが、プロジェクトに脆弱性が存在しなくなった時期を判断することはできません。そのためには、GitLabでは引き続き、デフォルトブランチのパイプラインで[依存関係スキャン](../_index.md)が実行され、最新の情報を含む対応するセキュリティレポートアーティファクトが生成される必要があります。これらのレポートが処理され、特定の脆弱性を含まなくなった場合、それらは継続的脆弱性スキャンによって作成されたものであっても、そのようにフラグが付けられます。

## セキュリティアドバイザリー {#security-advisories}

継続的脆弱性スキャンは、GitLabによって管理されるサービスであるパッケージメタデータデータベースを使用します。このデータベースは、ライセンスとセキュリティアドバイザリーデータを集約し、GitLab.comおよびGitLab Self-Managedインスタンスで使用される更新を定期的に公開します。

GitLab.comでは、同期はGitLabによって管理され、すべてのプロジェクトで利用可能です。

GitLab Self-Managedでは、GitLabインスタンスの**管理者**エリアで[パッケージレジストリメタデータを同期するように選択](../../../../administration/settings/security_and_compliance.md#choose-package-registry-metadata-to-sync)できます。

### データソース {#data-sources}

セキュリティアドバイザリーの現在のデータソースには以下が含まれます:

- [GitLabアドバイザリーデータベース](https://advisories.gitlab.com/)（[`gemnasium-db`](https://gitlab.com/gitlab-org/security-products/gemnasium-db)リポジトリでホストされています。これはレガシー名です。）

### 脆弱性データベースにコントリビュートする {#contributing-to-the-vulnerability-database}

脆弱性を検索するには、[`GitLab advisory database`](https://advisories.gitlab.com/)を検索します。[新しい脆弱性を送信](https://gitlab.com/gitlab-org/security-products/gemnasium-db/blob/master/CONTRIBUTING.md)することもできます。
