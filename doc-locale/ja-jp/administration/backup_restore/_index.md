---
stage: Systems
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: バックアップと復元の概要
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 製品: GitLab Self-Managed

{{< /details >}}

GitLabインスタンスには、ソフトウェア開発や組織にとって重要なデータが含まれています。以下を目的とした定期バックアップを含む、ディザスタリカバリプランを立てることが重要です。

- **データ保護**: ハードウェアの故障、ソフトウェアのバグ、誤削除によるデータ損失に対して保護します。
- **ディザスタリカバリ**: 不測の事態が発生した場合に、GitLabインスタンスとデータを復元します。
- **バージョン管理**: 以前の状態にロールバックできる過去のスナップショットを提供します。
- **コンプライアンス**: 特定の業界の規制要件を満たします。
- **移行**: GitLabを新しいサーバーや環境に容易に移動できるようにします。
- **テストと開発**: 本番環境のデータに影響を与えることなく、アップグレードや新機能をテストするためのコピーを作成します。

{{< alert type="note" >}}

このドキュメントは、GitLab CommunityエディションおよびEnterpriseエディションに適用されます。GitLab.comではデータのセキュリティは確保されていますが、それらの方法を使用してGitLab.comからデータをエクスポートしたりバックアップを作成したりすることはできません。

{{< /alert >}}

## GitLabのバックアップ

GitLabインスタンスのバックアップ手順は、デプロイ固有の設定や使用状況によって異なります。データの種類、ストレージの場所、ボリュームなどの要因によって、バックアップ方法、ストレージオプション、復元プロセスが決まります。詳細については、[GitLabをバックアップする](backup_gitlab.md)を参照してください。

## GitLabを復元する

GitLabインスタンスのバックアップ手順は、デプロイ固有の設定や使用状況によって異なります。データの種類、ストレージの場所、ボリュームなどの要因によって、復元プロセスが決まります。

詳細については、[GitLabを復元する](restore_gitlab.md)を参照してください。

## 新しいサーバーに移行する

GitLabのバックアップと復元機能を使用して、インスタンスを新しいサーバーに移行します。GitLab Geoをデプロイしている場合は、[計画フェイルオーバーにおけるGeoのディザスタリカバリの利用](../geo/disaster_recovery/planned_failover.md)をご検討ください。詳細については、[新しいサーバーに移行する](migrate_to_new_server.md)を参照してください。

## 大規模リファレンスアーキテクチャーをバックアップおよび復元する

大規模リファレンスアーキテクチャーを定期的にバックアップおよび復元することが重要です。オブジェクトストレージデータ、PostgreSQLデータ、Gitリポジトリのバックアップを設定および復元する方法については、[大規模リファレンスアーキテクチャーのバックアップと復元](backup_large_reference_architectures.md)を参照してください。

## バックアップアーカイブプロセス

データの保全とシステムの整合性を確保するため、GitLabはバックアップアーカイブを作成します。GitLabがこのアーカイブを作成する方法の詳細については、[バックアップアーカイブプロセス](backup_archive_process.md)を参照してください。

## 関連トピック

- [Geo](../geo/_index.md)
- [ディザスタリカバリ（Geo）](../geo/disaster_recovery/_index.md)
- [GitLabグループを移行する](../../user/group/import/_index.md)
- [プロジェクトをインポートおよび移行する](../../user/project/import/_index.md)
- [GitLab Linuxパッケージ（Omnibus）- バックアップと復元](https://docs.gitlab.com/omnibus/settings/backups.html)
- [GitLab Helmチャート - バックアップと復元](https://docs.gitlab.com/charts/backup-restore/)
- [GitLab Operator - バックアップと復元](https://docs.gitlab.com/operator/backup_and_restore.html)
