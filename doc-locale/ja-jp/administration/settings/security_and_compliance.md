---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
gitlab_dedicated: yes
title: 管理者エリアの設定 > セキュリティとコンプライアンスの管理者エリア設定
description: セキュリティとコンプライアンスの管理設定を構成します。これには、同期するパッケージリポジトリが含まれます。
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

パッケージメタデータの同期の設定は、[**管理者**エリア](_index.md)にあります。

## パッケージレジストリメタデータの同期を選択します {#choose-package-registry-metadata-to-sync}

[ライセンスコンプライアンス](../../user/compliance/license_scanning_of_cyclonedx_files/_index.md)および[継続的な脆弱性スキャン](../../user/application_security/continuous_vulnerability_scanning/_index.md)のために、GitLabパッケージメタデータデータベースと同期するパッケージを選択するには:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **セキュリティとコンプライアンス**を選択します。
1. **ライセンスコンプライアンス**を展開します。
1. **同期するパッケージレジストリメタデータ**で、同期するパッケージレジストリのチェックボックスを選択またはクリアします。
1. **変更を保存**を選択します。

このデータの同期を機能させるには、GitLabインスタンスからドメイン`storage.googleapis.com`への送信ネットワークトラフィックを許可する必要があります。[パッケージメタデータデータベースの有効化](../../topics/offline/quick_start_guide.md#enabling-the-package-metadata-database)に記載されているオフラインセットアップ手順も参照してください。
