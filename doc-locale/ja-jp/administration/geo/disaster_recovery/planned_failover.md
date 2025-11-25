---
stage: Runtime
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Geoを計画的なフェイルオーバーに使用して、データ損失なしにセカンダリサイトをプロモートするために、最小限のダウンタイムでGitLabを移行します。事前の検証と同期の手順に従ってください。
title: 計画的なフェイルオーバーのためのディザスターリカバリー
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

ディザスターリカバリーの主なユースケースは、計画外の停止が発生した場合の事業継続性を確保することですが、計画的なフェイルオーバーと組み合わせて、拡張されたダウンタイムなしにリージョン間でGitLabインスタンスを移行するために使用できます。

GitLab Geoサイト間のレプリケーションは非同期であるため、計画的なフェイルオーバーには、プライマリサイトへの更新がブロックされるメンテナンス時間が必要です。この期間の長さは、セカンダリサイトをプライマリサイトと完全に同期させるのにかかる時間によって異なります。同期が完了すると、データ損失なしにフェイルオーバーを実行できます。

このドキュメントは、完全に設定され、動作するGeo設定が既にあることを前提としています。続行する前に、このドキュメントと[ディザスターリカバリー](_index.md)のフェイルオーバーに関するドキュメントをよくお読みください。計画的なフェイルオーバーは主要な操作であり、誤って実行すると、データ損失のリスクが高まります。必要な手順に慣れ、正確に実行できると確信できるまで、手順をリハーサルしてください。

## フェイルオーバーに関する推奨事項 {#recommendations-for-failover}

これらの推奨事項に従うことで、スムーズなフェイルオーバープロセスが保証され、データ損失やダウンタイムの長期化のリスクが軽減されます。

### 同期と検証の失敗を解決する {#resolve-sync-and-verification-failures}

[プレフライトチェック](#preflight-checks)（手動検証、または`gitlab-ctl promotion-preflight-checks`の実行時）中に**失敗**または**キューに入っています**項目がある場合、これらが次のいずれかになるまで、フェイルオーバーはブロックされます:

- 解決済み: 正常に同期された(必要に応じてセカンダリに手動でコピーすることによって)および検証された。
- 許容できるものとしてドキュメント化: 次のような明確な正当性がある:
  - 特定のエラーについて、手動チェックサム比較が合格する。
  - リポジトリは非推奨であり、除外できます。
  - アイテムは重要でないものとして識別され、フェイルオーバー後にコピーできます。

同期と検証の失敗の診断については、[Geoの同期および検証エラーのトラブルシューティング](../replication/troubleshooting/synchronization_verification.md)を参照してください。

### データ整合性の解決を計画する {#plan-for-data-integrity-resolution}

最初にGeoレプリケーションを設定した後に表面化する、一般的なデータ整合性の問題を解決するには、フェイルオーバーの完了までに4〜6週間かかります。これらには、孤立したデータベースレコードまたは一貫性のないファイル参照が含まれる可能性があります。ガイダンスについては、[一般的なGeoエラーのトラブルシューティング](../replication/troubleshooting/common.md)を参照してください。

メンテナンス期間中の難しい判断を避けるために、早期に同期の問題に対処を開始します:

1. 4〜6週間前: 未解決の同期の問題を特定して解決を開始します。
1. 1週間前: 残りのすべての同期の問題の解決またはドキュメント化を目標にします。
1. 1〜2日前: 新しい失敗を解決します。
1. 数時間前: 新しい失敗の最後の確認。

成功を確実にするために、未解決の同期エラーが原因でフェイルオーバーを中断する場合の明確な基準を作成します。

### Geo環境でのバックアップタイミングのテスト {#test-backup-timing-in-geo-environments}

{{< alert type="warning" >}}

Geoレプリカデータベースからのバックアップは、アクティブなデータベーストランザクション中にキャンセルされる場合があります。

{{< /alert >}}

事前にバックアップ手順をテストし、次の戦略を検討してください:

- プライマリサイトから直接バックアップを取得します。これはパフォーマンスに影響を与える可能性があります。
- バックアップ中にレプリケーションから分離できる、専用の読み取りレプリカを使用します。
- アクティビティーの少ない期間中にバックアップをスケジュールします。

### 包括的なフォールバック手順を準備する {#prepare-comprehensive-fallback-procedures}

{{< alert type="warning" >}}

プロモートが完了する前にロールバックの決定ポイントを計画してください。その後、フォールバックすると、データが失われる可能性があります。

{{< /alert >}}

元のプライマリに戻すための特定の手順をドキュメント化します。これには以下が含まれます:

- フェイルオーバーを中断する場合の決定基準。
- DNS復帰手順。
- 元のプライマリを再度有効にするプロセス。[降格されたプライマリサイトをオンラインに戻す](bring_primary_back.md)を参照してください。
- ユーザーコミュニケーション計画。

### ステージング環境でフェイルオーバー手順書を開発する {#develop-a-failover-runbook-in-a-staging-environment}

成功を確実にするために、この高度に手動のタスクを詳細に練習してドキュメント化します:

1. 本番環境のような環境をプロビジョニングします(まだお持ちでない場合)。
1. スモークテストたとえば、グループを追加し、プロジェクトを追加し、Runnerを追加し、`git push`を使用し、イシューにイメージを追加します。
1. セカンダリサイトにフェイルオーバーします。
1. スモークテストを実行します。問題を探します。
1. これらの手順では、実行されたすべてのアクション、アクター、予想される結果、リソースへのリンクを書き留めます。
1. 手順書とスクリプトを改良するために必要に応じて繰り返します。

## すべてのデータが自動的にレプリケートされるわけではありません {#not-all-data-is-automatically-replicated}

GeoがサポートしていないGitLab機能を使用している場合は、セカンダリサイトにその機能に関連付けられたすべてのデータの最新コピーがあることを確認するために、別途プロビジョニングする必要があります。これにより、メンテナンス期間が大幅に長くなる可能性があります。Geoでサポートされている機能の一覧については、[レプリケートされたデータ型テーブル](../replication/datatypes.md#replicated-data-types)を参照してください。

ファイルに保存されているこの期間を可能な限り短く保つための一般的な戦略は、`rsync`を使用してデータを転送することです。初期`rsync`は、メンテナンス期間よりも前に実行できます。メンテナンス期間内の最終転送を含む、後の`rsync`手順では、プライマリサイトとセカンダリサイト間の変更のみが転送されます。

`rsync`を効果的に使用するためのGitリポジトリ中心の戦略については、[リポジトリの移動](../../operations/moving_repositories.md)を参照してください。これらの戦略は、他のファイルベースのデータで使用するために適合させることができます。

### コンテナレジストリ {#container-registry}

デフォルトでは、コンテナレジストリはセカンダリサイトに自動的にレプリケートされません。これは手動で設定する必要があります。詳細については、[セカンダリサイトのコンテナレジストリ](../replication/container_registry.md)を参照してください。

現在のプライマリサイトのローカルストレージをコンテナレジストリに使用している場合は、`rsync`コンテナレジストリオブジェクトをフェイルオーバーしようとしているセカンダリサイトに移動できます:

```shell
# Run from the secondary site
rsync --archive --perms --delete root@<geo-primary>:/var/opt/gitlab/gitlab-rails/shared/registry/. /var/opt/gitlab/gitlab-rails/shared/registry
```

または、プライマリサイトのコンテナレジストリを[バックアップする](../../backup_restore/_index.md#back-up-gitlab)し、それをセカンダリサイトに復元するします:

1. プライマリサイトで、レジストリのみをバックアップし、[バックアップから特定のディレクトリを除外する](../../backup_restore/backup_gitlab.md#excluding-specific-data-from-the-backup):

   ```shell
   # Create a backup in the /var/opt/gitlab/backups folder
   sudo gitlab-backup create SKIP=db,uploads,builds,artifacts,lfs,terraform_state,pages,repositories,packages
   ```

1. プライマリサイトから生成されたバックアップのtarballをセカンダリサイトの`/var/opt/gitlab/backups`フォルダーにコピーします。

1. セカンダリサイトで、[GitLabを復元するする](../../backup_restore/_index.md#restore-gitlab)ドキュメントに従ってレジストリを復元するします。

### 高度な検索のデータをリカバリーする {#recover-data-for-advanced-search}

高度な検索は、ElasticsearchまたはOpenSearchによって強化されています。高度な検索のデータは、セカンダリサイトに自動的にレプリケートされません。

新しくプロモートされたプライマリサイトで高度な検索のデータをリカバリーするには:

{{< tabs >}}

{{< tab title="GitLab 17.2以降" >}}

1. Elasticsearchを使用した検索を無効にします:

   ```shell
   sudo gitlab-rake gitlab:elastic:disable_search_with_elasticsearch
   ```

1. [インスタンス全体をインデックス作成する](../../../integration/advanced_search/elasticsearch.md#index-the-instance)。
1. [インデックス作成状態を確認します](../../../integration/advanced_search/elasticsearch.md#check-indexing-status)。
1. [バックグラウンドジョブの状態をモニタリングする](../../../integration/advanced_search/elasticsearch.md#monitor-the-status-of-background-jobs)。
1. Elasticsearchを使用した検索を有効にします:

   ```shell
   sudo gitlab-rake gitlab:elastic:enable_search_with_elasticsearch
   ```

{{< /tab >}}

{{< tab title="GitLab 17.1以前" >}}

1. Elasticsearchを使用した検索を無効にします:

   ```shell
   sudo gitlab-rake gitlab:elastic:disable_search_with_elasticsearch
   ```

1. インデックス作成を一時停止し、進行中のタスクが完了するまで5分間待ちます:

   ```shell
   sudo gitlab-rake gitlab:elastic:pause_indexing
   ```

1. インスタンスを最初からインデックス作成します:

   ```shell
   sudo gitlab-rake gitlab:elastic:index
   ```

1. インデックス作成を再開する:

   ```shell
   sudo gitlab-rake gitlab:elastic:resume_indexing
   ```

1. [インデックス作成状態を確認します](../../../integration/advanced_search/elasticsearch.md#check-indexing-status)。
1. [バックグラウンドジョブの状態をモニタリングする](../../../integration/advanced_search/elasticsearch.md#monitor-the-status-of-background-jobs)。
1. Elasticsearchを使用した検索を有効にします:

   ```shell
   sudo gitlab-rake gitlab:elastic:enable_search_with_elasticsearch
   ```

{{< /tab >}}

{{< /tabs >}}

## プレフライトチェック {#preflight-checks}

計画的なフェイルオーバーをスケジュールする前に、これらの[プレフライトチェック検証して、プロセスがスムーズに進むようにします。各手順については、以下で詳しく説明します。

実際のフェイルオーバープロセス中に、プライマリサイトがダウンした後、このコマンドを実行して、セカンダリをプロモートする前に最終的な検証チェックを実行します:

```shell
gitlab-ctl promotion-preflight-checks
```

`gitlab-ctl promotion-preflight-checks`コマンドはフェイルオーバープロセスの一部であり、プライマリサイトがダウンしている必要があります。プライマリがまだ実行されている間は、メンテナンス前の検証ツールとして使用することはできません。このコマンドを実行すると、プライマリサイトがダウンしているかどうかを尋ねるプロンプトが表示されます。`No`と答えると、次のエラーが表示されます: `ERROR: primary node must be down`。

プライマリがまだ稼働している間のメンテナンス前の検証については、以下の手動チェックを使用してください。

### DNS TTL {#dns-ttl}

[プライマリドメインDNSレコードを更新する](_index.md#step-4-optional-updating-the-primary-domain-dns-record)ことを計画している場合は、DNS変更の迅速な伝播を保証するために、低いTTL(Time-To-Live)を設定することを検討してください。

### オブジェクトストレージ {#object-storage}

大規模なGitLabインストールがある場合、またはダウンタイムを許容できない場合は、計画的なフェイルオーバーをスケジュールする前に、[オブジェクトストレージへの移行を検討してください](../replication/object_storage.md)。そうすることで、メンテナンス期間の長さと、計画的なフェイルオーバーの実行が不十分な場合にデータが失われるリスクの両方が軽減されます。

GitLabにセカンダリサイトのオブジェクトストレージのレプリケーションを管理させる場合は、[オブジェクトストレージのレプリケーション](../replication/object_storage.md)を参照してください。

### 各セカンダリサイトの設定をレビューする {#review-the-configuration-of-each-secondary-site}

データベース設定は、セカンダリサイトに自動的にレプリケートされます。ただし、`/etc/gitlab/gitlab.rb`ファイルをキーを手動で設定する必要があります。これは、サイトによって異なります。Mattermost、OAuth、LDAPインテグレーションなどの機能がプライマリサイトで有効になっているが、セカンダリサイトでは有効になっていない場合、フェイルオーバー中に失われます。

両方のサイトの`/etc/gitlab/gitlab.rb`ファイルをレビューします。計画的なフェイルオーバーをスケジュールする前に、セカンダリサイトがプライマリサイトと同じものをすべてサポートしていることを確認してください。[GitLab Geoロール](https://docs.gitlab.com/omnibus/roles/#gitlab-geo-roles)が正しく設定されていることを確認してください。

### システムチェックを実行する {#run-system-checks}

プライマリサイトとセカンダリサイトの両方で以下を実行します:

```shell
gitlab-rake gitlab:check
gitlab-rake gitlab:geo:check
```

いずれかのサイトが失敗をレポートした場合は、計画的なフェイルオーバーをスケジュールする前に、それらを解決します。

### シークレットとSSHホストキーがノード間で一致することを確認する {#check-that-secrets-and-ssh-host-keys-match-between-nodes}

SSHホストキーと`/etc/gitlab/gitlab-secrets.json`ファイルは、すべてのノードで同一である必要があります。これを確認するには、すべてのノードで以下を実行し、出力を比較します:

```shell
sudo sha256sum /etc/ssh/sshhost /etc/gitlab/gitlab-secrets.json
```

ファイルが異なる場合は、必要に応じて[GitLabのシークレットを手動でレプリケートする](../replication/configuration.md#step-1-manually-replicate-secret-gitlab-values)と[SSHホストキーをレプリケートする](../replication/configuration.md#step-2-manually-replicate-the-primary-sites-ssh-host-keys)をセカンダリサイトに手動でレプリケートします。

### HTTPS用に正しい証明書がインストールされていることを確認する {#check-that-the-correct-certificates-are-installed-for-https}

プライマリサイトと、プライマリサイトがアクセスするすべての外部サイトが、公開された認証局発行の証明書を使用する場合、この手順は安全にスキップできます。

次のいずれかに該当する場合は、セカンダリサイトに正しい証明書をインストールする必要があります:

- プライマリサイトは、カスタムまたは自己署名TLS証明書を使用して、受信接続を保護します。
- プライマリサイトは、カスタムまたは自己署名証明書を使用する外部サービスに接続します。

詳細については、[カスタム証明書の使用](../replication/configuration.md#step-4-optional-using-custom-certificates)をセカンダリサイトと共にご覧ください。

### Geoレプリケーションが最新であることを確認する {#ensure-geo-replication-is-up-to-date}

メンテナンス期間は、Geoレプリケーションと検証が完全に終了するまで終了しません。期間を可能な限り短く保つためには、アクティブな使用中にこれらのプロセスが可能な限り100%に近づいていることを確認する必要があります。

セカンダリサイトの場合:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **Geo** > **サイト**を選択します。レプリケートされたオブジェクト(緑色で表示)は100%に近く、失敗(赤色で表示)がないはずです。大量のオブジェクトがまだレプリケートされていない場合(灰色で表示)、サイトに完了するまでの時間を増やすことを検討してください:

   ![セカンダリサイトの同期ステータスを表示するGeo管理者ダッシュボード](img/geo_dashboard_v14_0.png)

オブジェクトのレプリケートに失敗した場合は、メンテナンス期間をスケジュールする前に調査してください。レプリケートに失敗したオブジェクトは、計画的なフェイルオーバー後に失われます。

レプリケーションの失敗の一般的な原因は、プライマリサイトにデータがないことです。これらの失敗を解決するには、次のいずれかを行います:

- バックアップからデータを復元する。
- 見つからないデータへの参照を削除します。

### レプリケートされたデータの整合性を検証する {#verify-the-integrity-of-replicated-data}

フェイルオーバーに進む前に、検証が完了していることを確認してください。検証に失敗した破損データは、フェイルオーバー中に失われる可能性があります。

詳細については、[自動バックグラウンド検証](background_verification.md)を参照してください。

### スケジュールされたメンテナンスをユーザーに通知する {#notify-users-of-scheduled-maintenance}

プライマリサイトで次の手順に従います:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **メッセージ**を選択します。
1. メンテナンス期間についてユーザーに通知するメッセージを追加します。同期の完了に必要な時間を概算するには、**Geo** > **サイト**に移動します。
1. **ブロードキャストメッセージを追加**を選択します。

### フェイルオーバー中のRunner接続 {#runner-connectivity-during-failover}

インスタンスのURLの設定方法によっては、フェイルオーバー後にRunnerフリートを100%に維持するための追加の手順が必要になる場合があります。

Runnerの登録に使用されるトークンは、プライマリまたはセカンダリインスタンスで機能するはずです。フェイルオーバー後に接続に関するイシューが発生した場合、[セカンダリ](../setup/two_single_node_sites.md#manually-replicate-secret-gitlab-values)中にシークレットがコピーされなかった可能性があります。[Runnerトークンをリセットする](../../backup_restore/troubleshooting_backup_gitlab.md#reset-runner-registration-tokens)ことができますが、シークレットが同期されていない場合、Runnerとは関係のない他のイシューが発生する可能性があることに注意してください。

RunnerがGitLabインスタンスに繰り返し接続できない場合、一定期間接続を試行しなくなります。デフォルトでは、この期間は1時間です。これを回避するには、GitLabインスタンスに到達できるようになるまで、Runnerをシャットダウンします。[`check_interval`ドキュメント](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#how-check_interval-works)、および`unhealthy_requests_limit`と`unhealthy_interval`設定オプションを参照してください。

- GitLabの**Location aware URL**（ロケーションアウェアURL）を使用する場合: 古いプライマリがDNS設定から削除されると、Runnerは自動的に次に近いインスタンスに接続されます。
- 個別のURLを使用する場合: 現在のプライマリに接続されているRunnerは、プロモートされたら、新しいプライマリに接続するように更新する必要があります。
- 現在のセカンダリに接続されているRunnerがある場合: フェイルオーバー中の[セカンダリRunnerの処理方法](../secondary_proxy/runners.md#handling-a-planned-failover-with-secondary-runners)を参照してください。

## プライマリサイトへの更新を防止 {#prevent-updates-to-the-primary-site}

すべてのデータがセカンダリサイトにレプリケートされるようにするには、プライマリサイトでの更新（書き込みリクエスト）を無効にして、セカンダリサイトが追いつく時間を確保します:

1. プライマリサイトで[メンテナンスモード](../../maintenance_mode/_index.md)を有効にします。
1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **モニタリング** > **バックグラウンドジョブ**を選択します。
1. Sidekiqダッシュボードで、**Cron**を選択します。
1. Geo以外の定期的なバックグラウンドジョブを無効にするには、`Disable All`を選択します。
1. これらのcronジョブに対して`Enable`を選択します:

   - `geo_metrics_update_worker`
   - `geo_prune_event_log_worker`
   - `geo_verification_cron_worker`
   - `repository_check_worker`

   これらのcronジョブを再度有効にすることは、計画されたフェイルオーバーを正常に完了するために不可欠です。

## すべてのデータのレプリケーションと検証を完了 {#finish-replicating-and-verifying-all-data}

1. Geoで管理されていないデータを手動でレプリケートする場合は、今すぐ最終的なレプリケーションプロセスをトリガーします。
1. プライマリサイトで次の手順に従います:
   1. 左側のサイドバーの下部で、**管理者**を選択します。
   1. 左側のサイドバーで、**モニタリング** > **バックグラウンドジョブ**を選択します。
   1. Sidekiqダッシュボードで、**Queues**を選択します。名前が`geo`のものを除くすべてのキューが0になるまで待ちます。これらのキューには、ユーザーから送信された作業が含まれています。キューが空になる前にフェイルオーバーすると、作業が失われます。
   1. 左側のサイドバーで、**Geo** > **サイト**を選択します。フェイルオーバー先のセカンダリサイトについて、次の条件が満たされるまで待ちます:

      - すべてのレプリケーションメーターが100％レプリケートされ、0％の失敗になるまで待ちます。
      - すべての検証メーターが100％検証され、0％の失敗になるまで待ちます。
      - データベースレプリケーションのラグは0ミリ秒です。
      - Geoログカーソルが最新の状態である（0イベント遅延）。

1. セカンダリサイトの場合:
   1. 左側のサイドバーの下部で、**管理者**を選択します。
   1. 左側のサイドバーで、**モニタリング** > **バックグラウンドジョブ**を選択します。
   1. Sidekiqダッシュボードで、**Queues**を選択します。すべての`geo`キューが0キューおよび0実行ジョブにドロップするまで待ちます。
   1. [整合性チェックを実行](../../raketasks/check.md)して、CIアーティファクト、LFSオブジェクト、およびファイルストレージ内のアップロードの整合性を確認します。

この時点で、セカンダリサイトにはプライマリサイトのすべての最新コピーが含まれており、フェイルオーバー時にデータが失われることはありません。

## セカンダリサイトをプロモートする {#promote-the-secondary-site}

レプリケーションが完了したら、[セカンダリサイトをプライマリサイトにプロモートする](_index.md)。このプロセスにより、セカンダリサイトで短時間の停止が発生し、ユーザーは再度サインインする必要がある場合があります。手順に正しく従うと、古いプライマリGeoサイトが無効になり、ユーザートラフィックが新しくプロモートされたサイトに代わりに流れます。

プロモートが完了すると、メンテナンス期間が終了し、新しいプライマリサイトが古いサイトから分岐し始めます。この時点で問題が発生した場合、古いプライマリサイトへの[フェイルバック](bring_primary_back.md)は可能ですが、その間に新しいプライマリにアップロードされたデータが失われる可能性があります。

フェイルオーバーが完了したら、ブロードキャストメッセージを削除することを忘れないでください。

最後に、[古いサイトをセカンダリとして戻します](bring_primary_back.md#configure-the-former-primary-site-to-be-a-secondary-site)。
