---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: パッケージメタデータデータベース
description: パッケージメタデータデータベースに含まれる内容、GitLabによる同期方法、および各GitLabバージョンが読み取るデータ形式バージョンについて説明します。
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

パッケージメタデータデータベース（PMDB）は、GitLabが管理する、オープンソースパッケージのライセンスおよびセキュリティアドバイザリデータの集合です。GitLabはこれをインスタンスのデータベースに同期し、次の機能がそれを読み取ります:

- [レジストリ用のコンテナスキャン](../container_scanning/_index.md#container-scanning-for-registry)
- [継続的脆弱性スキャン](../continuous_vulnerability_scanning/_index.md)
- [依存関係スキャン](../dependency_scanning/_index.md)
- [CycloneDXファイルのライセンススキャン](../../compliance/license_scanning_of_cyclonedx_files/_index.md)

パッケージメタデータデータベースは[EEライセンス](https://storage.googleapis.com/prod-export-license-bucket-1a6c642fc4de57d4/LICENSE)の下でライセンスされています。

## データセット {#datasets}

パッケージメタデータデータベースには4つのデータセットが保持されています:

| データセット            | 内容                                              | 使用元 |
|--------------------|-------------------------------------------------------|---------|
| ライセンス           | パッケージバージョンのライセンスデータ。                    | ライセンススキャン |
| アドバイザリ         | パッケージバージョンのセキュリティアドバイザリ。             | 依存関係スキャン、継続的脆弱性スキャン、レジストリ用のコンテナスキャン |
| CVEエンリッチメント     | 脆弱性のEPSSスコアおよびKEVステータス。     | [脆弱性リスク評価データ](../vulnerabilities/risk_assessment_data.md) |
| マルウェアアドバイザリ | パッケージレジストリで見つかった既知の悪意のあるパッケージ。 | [GitLabマルウェアアドバイザリ](../gitlab_advisory_database/_index.md#gitlab-malware-advisories) |

デフォルトでは、GitLabはすべてのパッケージレジストリタイプのデータを同期します。同期するデータを減らすには、[管理設定](../../../administration/settings/security_and_compliance.md#choose-package-registry-metadata-to-sync)で使用しないパッケージレジストリタイプをクリアしてください。

## データ形式バージョン {#data-format-versions}

各データセットは、v2またはv3のいずれかのデータ形式バージョンで公開されます。これらはデータ形式のバージョンであり、GitLabのバージョンではありません。

| フォーマットバージョン | データセット | 配布元 |
|----------------|----------|------------------|
| v2             | GitLab 19.3以前のライセンス、アドバイザリ、CVEエンリッチメント。 | 認証情報なしで読み取れる、パブリックなGoogle Cloud Storageバケット。 |
| v3             | GitLab 19.4以降のライセンスおよびマルウェアアドバイザリ。 | パッケージメタデータデータベース配布サービス（認証済みのGitLabサービス）。 |

v3のライセンスデータには、単一のライセンス識別子ではなく、Software Package Data Exchange（SPDX）のライセンス表現が含まれます。例: `MIT OR Apache-2.0`。

形式バージョンを選択することはできません。お使いのGitLabバージョンによって、読み取られる形式が決まります:

| GitLabのバージョン   | ライセンス | アドバイザリ | CVEエンリッチメント | マルウェアアドバイザリ |
|------------------|----------|------------|----------------|--------------------|
| 19.2以前 | v2       | v2         | v2             | 利用不可      |
| 19.3             | v2       | v2         | v2             | v3                 |
| 19.4以降   | v3       | v2         | v2             | v3                 |

機能フラグはv3のライセンスデータとマルウェアアドバイザリを制御しており、どちらもデフォルトで有効になっています。マルウェアアドバイザリはベータ版です。

## 同期 {#synchronization}

Sidekiqのcronジョブが、各データセットをインスタンスのデータベースに同期します。各実行は前回の実行で記録されたチェックポイントから再開するため、インスタンスがすでに保持しているデータよりも新しいデータのみをインポートします。

### インターネットアクセスのあるインスタンス {#instances-with-internet-access}

インターネットアクセスのあるインスタンスは、パブリックバケットからv2データを、配布サービスからv3データをダウンロードします。v2データをダウンロードするには、インスタンスが`storage.googleapis.com`への送信ネットワークアクセスを必要とします。

### オフラインインスタンス {#offline-instances}

オフラインインスタンスは、自身でデータをダウンロードできません。代わりに、インターネットアクセスのあるマシン上でダウンロードし、オフラインインスタンスの`vendor/package_metadata`ディレクトリにコピーします。v3データのダウンロードには、オフラインライセンスが必要です。

データセット用のディレクトリが`vendor/package_metadata`配下に存在する場合、GitLabはデータをダウンロードする代わりにそのディレクトリを読み取ります。ネットワークへのフォールバックはないため、古いデータを保持しているディレクトリは古いデータを提供し、エラーも報告しません。

各データセットのダウンロード手順と機能フラグの詳細については、[オフラインインスタンス向けパッケージメタデータデータベース](../../../topics/offline/package-metadata-database.md)を参照してください。

## 関連トピック {#related-topics}

- [オフライン環境](../offline_deployments/_index.md)
