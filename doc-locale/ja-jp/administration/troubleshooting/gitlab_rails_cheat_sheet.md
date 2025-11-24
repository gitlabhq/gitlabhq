---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Railsコンソールチートシート
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

これは、GitLabサポートチームがトラブルシューティングで使用するために収集したGitLab Railsコンソールに関する情報です。ほとんどのコンテンツが機能固有のトラブルシューティングページとセクションに移動されたため、後世のためにここにリストされています。エピック[&8147](https://gitlab.com/groups/gitlab-org/-/epics/8147#tree)を参照してください。必要に応じて、ブックマークを更新してください。

現在GitLabに問題が発生している場合は、ここから示された情報を使用する前に、まず[Railsコンソール](../operations/rails_console.md)および[サポートオプション](https://about.gitlab.com/support/)に関するガイドを確認することを強くお勧めします。

{{< alert type="warning" >}}

これらのスクリプトの一部は、正しく実行されない場合、または適切な条件下で実行されない場合に、損害を与える可能性があります。万が一の場合に備えて、サポートエンジニアの指導の下で実行するか、インスタンスのバックアップを復元する準備ができているテスト環境で実行することを強くお勧めします。

{{< /alert >}}

{{< alert type="warning" >}}

GitLabが変更されると、コードの変更は避けられず、一部のスクリプトは以前のように機能しなくなる可能性があります。これらのスクリプト/コマンドは、発見/必要に応じて追加されたため、最新の状態に保たれていません。前述のように、これらのスクリプトは、必要に応じて、スクリプトが引き続き正常に動作することを確認し、最新バージョンのGitLabに合わせてスクリプトを更新できるサポートエンジニアの監督の下で実行することをお勧めします。{{< /alert >}}

## ミラーリング {#mirrors}

### 「bad復号化する」エラーが発生したミラーを検索します {#find-mirrors-with-bad-decrypt-errors}

このコンテンツはRakeタスクに変換されました。[現在のシークレットを使用してデータベース値を復号化できることを確認する](../raketasks/check.md#verify-database-values-can-be-decrypted-using-the-current-secrets)を参照してください。

### 単一のサービスアカウントにミラーユーザーとトークンを転送します {#transfer-mirror-users-and-tokens-to-a-single-service-account}

このコンテンツは、[リポジトリミラーリングのトラブルシューティング](../../user/project/repository/mirror/troubleshooting.md#transfer-mirror-users-and-tokens-to-a-single-service-account)に移動されました。

## マージリクエスト {#merge-requests}

## CI {#ci}

このコンテンツは[/CDメンテナンス](../cicd/maintenance.md)に移動されました。

## ライセンス {#license}

このコンテンツは[ライセンスファイルまたはキーを使用してGitLab EEをアクティブ化する](../license_file.md)に移動されました。

## レジストリ {#registry}

### プロジェクトごとのレジストリディスク容量使用量 {#registry-disk-space-usage-by-project}

コンテナレジストリ内のプロジェクトごとのストレージ領域を表示するには、[プロジェクト別のレジストリディスク領域の使用状況](../packages/container_registry.md#registry-disk-space-usage-by-project)を参照してください。

### クリーンアップポリシーを実行する {#run-the-cleanup-policy}

コンテナレジストリ内のストレージ領域を削減するには、[クリーンアップポリシーの実行](../packages/container_registry.md#run-the-cleanup-policy)を参照してください。

## Sidekiq {#sidekiq}

このコンテンツは[Sidekiqのトラブルシューティング](../sidekiq/sidekiq_troubleshooting.md)に移動されました。

## Geo {#geo}

### すべてのアップロード（または検証済みのSSFデータ型）を再検証します {#reverify-all-uploads-or-any-ssf-data-type-which-is-verified}

[GitLab Geoレプリケーションのトラブルシューティング](../geo/replication/troubleshooting/synchronization_verification.md#resync-and-reverify-multiple-components)に移動されました。

### アーティファクト {#artifacts}

[GitLab Geoレプリケーションのトラブルシューティング](../geo/replication/troubleshooting/synchronization_verification.md#manually-retry-replication-or-verification)に移動されました。

### リポジトリ検証の失敗 {#repository-verification-failures}

[GitLab Geoレプリケーションのトラブルシューティング](../geo/replication/troubleshooting/synchronization_verification.md#manually-retry-replication-or-verification)に移動されました。

### リポジトリの再同期 {#resync-repositories}

[GitLab Geoレプリケーションのトラブルシューティング - リポジトリタイプの再同期](../geo/replication/troubleshooting/synchronization_verification.md#manually-retry-replication-or-verification)に移動されました。

[GitLab Geoレプリケーションのトラブルシューティング - プロジェクトとプロジェクトWikiリポジトリの再同期](../geo/replication/troubleshooting/synchronization_verification.md#manually-retry-replication-or-verification)に移動されました。

### Blobタイプ {#blob-types}

[GitLab Geoレプリケーションのトラブルシューティング](../geo/replication/troubleshooting/synchronization_verification.md#manually-retry-replication-or-verification)に移動されました。

## Service Pingを生成 {#generate-service-ping}

このコンテンツは、GitLab開発ドキュメントのService Pingのトラブルシューティングに移動されました。
