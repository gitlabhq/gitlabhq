---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 継続的コンテナスキャン
description: CI/CDパイプラインの外部で、GitLabがイメージの依存関係の新しい脆弱性を検出する方法。
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- 継続的コンテナスキャンはGitLab 16.8で[導入され](https://gitlab.com/gitlab-org/gitlab/-/issues/435435)、[フラグ](../../../../administration/feature_flags/_index.md) `container_scanning_continuous_vulnerability_scans`という名前が付けられました。デフォルトでは無効になっています。
- 継続的コンテナスキャンはGitLab 16.10で[GitLab Self-Managed、およびGitLab Dedicatedで有効になりました](https://gitlab.com/gitlab-org/gitlab/-/issues/437162)。
- GitLab 17.0で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/443712)になりました。機能フラグ`container_scanning_continuous_vulnerability_scans`は削除されました。

{{< /history >}}

継続的脆弱性スキャン（CVS）は、コンテナスキャンにおいて、新しいパイプラインの実行を必要とせずに、最新の[セキュリティアドバイザリー](#security-advisories)の情報とプロジェクトのイメージ依存関係のコンポーネント名およびバージョンを比較することで、セキュリティ脆弱性を探します。CVSは、プロジェクトがどのコンポーネントを使用しているかを把握するために、デフォルトブランチに保存されているCycloneDX SBOMレポートに依存します。このSBOMを作成するには、コンテナスキャンのジョブがデフォルトブランチで少なくとも1回実行される必要があります。その後、CVSは、それらのコンポーネントに対する新しく公開されたアドバイザリーを自動的に検出し、それ以上のパイプラインの実行は不要です。イメージのコンテンツが変更された場合、CVSが更新されたコンポーネントセットを評価できるように、SBOMを更新するために、デフォルトブランチで新しいパイプラインを実行する必要があります。ほとんどのプロジェクトでは、依存関係の変更には通常、すでにパイプラインをトリガーするコードの変更が伴うため、これは通常のワークフローの一部として発生します。

[新しい脆弱性が発生する](#checking-new-vulnerabilities)のは、継続的脆弱性スキャンが[サポートされているパッケージタイプ](#supported-package-types)を持つコンポーネントを含むすべてのプロジェクトでスキャンをトリガーする場合です。

コンテナスキャン用の継続的脆弱性スキャンによって作成された脆弱性は、スキャナー名として`GitLab SBoM Vulnerability Scanner`を、脆弱性タイプとして`Container Scanning`を使用します。

CI/CDベースのセキュリティスキャンとは対照的に、継続的脆弱性スキャンは、CI/CDパイプラインではなくバックグラウンドジョブ（Sidekiq）を通じて実行され、セキュリティレポートアーティファクトは生成されません。

## 前提条件 {#prerequisites}

- [CycloneDX SBOMレポート](#how-to-generate-a-cyclonedx-sbom-report)。
- GitLabインスタンスに同期された[セキュリティアドバイザリー](#security-advisories)。

## サポートされているパッケージタイプ {#supported-package-types}

継続的脆弱性スキャンは、以下の[PURLタイプ](https://github.com/package-url/purl-spec/blob/346589846130317464b677bc4eab30bf5040183a/PURL-TYPES.rst)を持つコンポーネントをサポートします:

- `apk`
- `deb`
- `rpm`

既知の制限事項:

- 先頭にゼロを含むAPKバージョンはサポートされていません。これらのバージョンをサポートする作業は、[イシュー471509](https://gitlab.com/gitlab-org/gitlab/-/issues/471509)で追跡されています。
- `^`を含むRPMバージョンはサポートされていません。これらのバージョンをサポートする作業は、[イシュー459969](https://gitlab.com/gitlab-org/gitlab/-/issues/459969)で追跡されています。
- Red HatディストリビューションのRPMパッケージはサポートされていません。このユースケースをサポートする作業は、[エピック12980](https://gitlab.com/groups/gitlab-org/-/epics/12980)で追跡されています。

## CycloneDX SBOMレポートを生成する方法 {#how-to-generate-a-cyclonedx-sbom-report}

[CycloneDX SBOMレポート](../../../../ci/yaml/artifacts_reports.md#artifactsreportscyclonedx)を使用して、プロジェクトのコンポーネントをGitLabに登録します。

CycloneDXレポートは以下に準拠する必要があります:

- [CycloneDX仕様](https://github.com/CycloneDX/specification)バージョン`1.4`、`1.5`、または`1.6`。
- [GitLabコンテナスキャン用CycloneDXプロパティタクソノミー](../../../../development/sec/cyclonedx_property_taxonomy.md#gitlabcontainer_scanning-namespace-taxonomy)。

GitLabは、GitLabと互換性のあるレポートを生成できるセキュリティアナライザーを提供しています:

- [コンテナスキャン](../_index.md#getting-started)
- [レジストリ用コンテナスキャン](../_index.md#container-scanning-for-registry)

## 新しい脆弱性の確認 {#checking-new-vulnerabilities}

継続的脆弱性スキャンによって検出された新しい脆弱性は、[脆弱性レポート](../../vulnerability_report/_index.md)で確認できます。しかし、それらは影響を受けたSBOMコンポーネントが検出されたパイプラインにはリストされません。

[セキュリティアドバイザリー](#security-advisories)が追加または更新された後に脆弱性が作成されますが、コードベースが変更されていない限り、対応する脆弱性がプロジェクトに追加されるまでに数時間かかる場合があります。過去14日以内に公開されたアドバイザリーのみが、継続的脆弱性スキャンの対象となります。

## 脆弱性が検出されなくなった場合 {#when-vulnerabilities-are-no-longer-detected}

継続的脆弱性スキャンは、新しいアドバイザリーが公開されると自動的に脆弱性を作成しますが、プロジェクトに脆弱性が存在しなくなった時期を判断することはできません。そのために、GitLabでは依然として、デフォルトブランチのパイプラインで[コンテナスキャン](../_index.md)のスキャンを実行し、最新情報を含む対応するセキュリティレポートアーティファクトを生成する必要があります。これらのレポートが処理され、特定の脆弱性を含まなくなった場合、それらは継続的脆弱性スキャンによって作成されたものであっても、そのようにフラグが付けられます。

> [!warning]
> レジストリ用コンテナスキャンによって検出された脆弱性は、この方法では解決できず、イメージで修正した後も表示されたままになります。これは、レジストリ用コンテナスキャンが脆弱性を解決済みとしてマークするために必要なセキュリティレポートではなく、SBOMのみを生成するためです。

## セキュリティアドバイザリー {#security-advisories}

継続的脆弱性スキャンは、GitLabによって管理されるサービスであるパッケージメタデータデータベースを使用します。このデータベースは、ライセンスとセキュリティアドバイザリーデータを集約し、GitLab.comおよびGitLab Self-Managedインスタンスで使用される更新を定期的に公開します。

GitLab.comでは、同期はGitLabによって管理され、すべてのプロジェクトで利用可能です。

GitLab Self-Managedでは、GitLabインスタンスの**管理者**エリアで[パッケージレジストリメタデータを同期するように選択](../../../../administration/settings/security_and_compliance.md#choose-package-registry-metadata-to-sync)できます。

### データソース {#data-sources}

セキュリティアドバイザリーの現在のデータソースには以下が含まれます:

- Aqua securityの[`vuln-list repository`](https://github.com/aquasecurity/vuln-list)から構築された[Trivy DB](https://github.com/aquasecurity/trivy-db)

### 脆弱性データベースにコントリビュートする {#contributing-to-the-vulnerability-database}

脆弱性を見つけるには、rawデータを含むAqua securityの[`vuln-list repository`](https://github.com/aquasecurity/vuln-list)を検索できます。Trivy-DBに[コントリビュートする](https://github.com/aquasecurity/vuln-list-update/blob/main/CONTRIBUTING.md)こともできます。
