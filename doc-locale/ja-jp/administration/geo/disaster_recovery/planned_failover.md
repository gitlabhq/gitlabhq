---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: データ損失なしにセカンダリサイトをプロモートするための予備チェックと同期手順に従うことで、最小限のダウンタイムでGitLabを移行するために計画的なフェイルオーバーにGeoを使用します。
title: 計画的なフェイルオーバーのためのディザスターリカバリー
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

ディザスターリカバリーの主要なユースケースは、予期せぬ停止が発生した場合の事業継続を保証することですが、計画的なフェイルオーバーと組み合わせて、延長されたダウンタイムなしに複数のリージョン間でGitLabインスタンスを移行するために使用できます。

Geoサイト間のレプリケーションは非同期であるため、計画的なフェイルオーバーには、プライマリサイトへの更新がブロックされるメンテナンス期間が必要です。この期間の長さは、セカンダリサイトをプライマリサイトと完全に同期するのにかかる時間によって異なります。同期が完了すると、データ損失なしにフェイルオーバーを実行できます。

このドキュメントでは、完全に設定され、機能しているGeoセットアップがすでにあることを前提としています。進む前に、このドキュメントと[ディザスターリカバリー](_index.md)フェイルオーバードキュメントをすべてお読みください。計画的なフェイルオーバーは主要な操作であり、誤って実行された場合、データ損失の高いリスクがあります。必要な手順に慣れるまで手順を練習し、それらを正確に実行できるという高い確信が持てるまで練習してください。

## フェイルオーバーの推奨事項 {#recommendations-for-failover}

これらの推奨事項に従うことで、スムーズなフェイルオーバープロセスを確実にし、データ損失や延長されたダウンタイムのリスクを軽減できます。

### 同期および検証の失敗を解決する {#resolve-sync-and-verification-failures}

[予備チェック](#preflight-checks)（手動検証または`gitlab-ctl promotion-preflight-checks`の実行時）中に**失敗**または**キューに入っています**のアイテムがある場合、フェイルオーバーは、それらが以下のいずれかになるまでブロックされます:

- 解決済み: 正常に同期され（必要に応じてセカンダリに手動でコピーして）、検証済みです。
- 受け入れ可能としてドキュメント化済み: 以下のような明確な理由がある場合:
  - これらの特定の失敗に対して手動のチェックサム比較が通過します。
  - リポジトリは非推奨であり、除外できます。
  - アイテムは重要ではないと判断され、フェイルオーバー後にコピーできます。

同期と検証の失敗の診断については、[トラブルシューティングGeo同期および検証エラー](../replication/troubleshooting/synchronization_verification.md)を参照してください。

### データ整合性の解決計画 {#plan-for-data-integrity-resolution}

初めてGeoレプリケーションを設定した後に一般的に発生するデータ整合性の問題を解決するために、フェイルオーバー完了の4～6週間前を確保してください。これらには、孤立したデータベースレコードや不整合なファイル参照が含まれる場合があります。ガイダンスについては、[一般的なGeoエラーのトラブルシューティング](../replication/troubleshooting/common.md)を参照してください。

メンテナンス期間中の難しい決定を避けるため、同期の問題に早期に対処し始めてください:

1. 4～6週間前: 未解決の同期問題を特定し、解決を開始します。
1. 1週間前: 残りのすべての同期問題の解決またはドキュメント化を目標とします。
1. 1～2日前: 新しい失敗を解決する。
1. 数時間前: 新しい失敗がないか最終確認します。

成功を確実にするには、未解決の同期エラーが原因でフェイルオーバーを中止するタイミングの明確な基準を作成します。

### Geo環境でのバックアップのタイミングをテストする {#test-backup-timing-in-geo-environments}

> [!warning]
> 
> Geoレプリカデータベースからのバックアップは、アクティブなデータベーストランザクション中にキャンセルされる場合があります。

事前にバックアップ手順をテストし、以下の戦略を検討してください:

- プライマリサイトから直接バックアップを取得します。これによりパフォーマンスに影響する可能性があります。
- バックアップ中にレプリケーションから隔離できる専用の読み取りレプリカを使用します。
- 活動が少ない期間にバックアップをスケジュールします。

### 包括的なフォールバック手順を準備する {#prepare-comprehensive-fallback-procedures}

> [!warning]
> 
> プロモーションが完了する前にロールバックの決定ポイントを計画してください。完了後にフォールバックするとデータ損失が発生する可能性があります。

元のプライマリに戻すための具体的な手順をドキュメント化します。以下を含みます:

- フェイルオーバーを中止するタイミングの決定基準。
- DNSの復元手順。
- 元のプライマリを再有効化するプロセス。[降格されたプライマリサイトをオンラインに戻す](bring_primary_back.md)を参照してください。
- ユーザーコミュニケーション計画。

### ステージング環境でフェイルオーバー手順書を開発する {#develop-a-failover-runbook-in-a-staging-environment}

成功を確実にするため、この非常に手動のタスクを詳細に練習し、ドキュメント化してください:

1. まだお持ちでない場合は、本番環境のような環境をプロビジョニングする。
1. スモークテスト。たとえば、グループを追加し、プロジェクトを追加し、Runnerを追加し、`git push`を使用し、イシューに画像を追加します。
1. セカンダリサイトにフェイルオーバーします。
1. スモークテストを実行します。問題を探します。
1. これらの手順中に、実行されたすべてのアクション、実行者、期待される結果、リソースへのリンクを書き留めます。
1. 手順書とスクリプトを改善するために必要に応じて繰り返します。

## すべてのデータが自動的にレプリケートされるわけではありません {#not-all-data-is-automatically-replicated}

GeoがサポートしていないGitLabの機能を使用している場合、セカンダリサイトがその機能に関連するすべてのデータの最新コピーを持っていることを確実にするために、別途プロビジョニングを行う必要があります。これによりメンテナンス期間が大幅に延長される可能性があります。Geoでサポートされている機能のリストについては、[レプリケートされたデータ型テーブル](../replication/datatypes.md#replicated-data-types)を参照してください。

ファイルに保存されているデータのこの期間をできるだけ短くするための一般的な戦略は、`rsync`を使用してデータを転送することです。メンテナンス期間の前に最初の`rsync`を実行できます。その後の`rsync`手順（メンテナンス期間内の最終転送を含む）は、プライマリサイトとセカンダリサイト間の変更のみを転送します。

`rsync`を効果的に使用するためのGitリポジトリ中心の戦略については、[リポジトリの移動](../../operations/moving_repositories.md)を参照してください。これらの戦略は、他のすべてのファイルベースのデータでも使用できるように適応できます。

### コンテナレジストリ {#container-registry}

デフォルトでは、コンテナレジストリはセカンダリサイトに自動的にレプリケートされません。これは手動で設定する必要があります。詳細については、[セカンダリサイト用のコンテナレジストリ](../replication/container_registry.md)を参照してください。

現在のプライマリサイトでコンテナレジストリにローカルストレージを使用している場合、`rsync`を使用して、フェイルオーバーするセカンダリサイトにコンテナレジストリオブジェクトを転送できます:

```shell
# Run from the secondary site
rsync --archive --perms --delete root@<geo-primary>:/var/opt/gitlab/gitlab-rails/shared/registry/. /var/opt/gitlab/gitlab-rails/shared/registry
```

または、[バックアップ](../../backup_restore/_index.md#back-up-gitlab)し、プライマリサイトのコンテナレジストリをセカンダリサイトに復元することができます:

1. プライマリサイトで、レジストリのみをバックアップし、[バックアップから特定のディレクトリを除外する](../../backup_restore/backup_gitlab.md#excluding-specific-data-from-the-backup):

   ```shell
   # Create a backup in the /var/opt/gitlab/backups folder
   sudo gitlab-backup create SKIP=db,uploads,builds,artifacts,lfs,terraform_state,pages,repositories,packages
   ```

1. プライマリサイトから生成されたバックアップtarballを、セカンダリサイトの`/var/opt/gitlab/backups`フォルダーにコピーします。

1. セカンダリサイトで、[GitLabを復元する](../../backup_restore/_index.md#restore-gitlab)ドキュメントに従ってレジストリを復元するます。

### 高度な検索のデータを回復する {#recover-data-for-advanced-search}

高度な検索はElasticsearchまたはOpenSearchによって駆動されます。高度な検索のデータは、セカンダリサイトに自動的にレプリケートされません。

新しくプロモートされたプライマリサイトで高度な検索のデータを回復するには:

{{< tabs >}}

{{< tab title="GitLab 17.2以降" >}}

1. Elasticsearchで検索を無効にします:

   ```shell
   sudo gitlab-rake gitlab:elastic:disable_search_with_elasticsearch
   ```

1. [インスタンス全体を再インデックスします](../../../integration/advanced_search/elasticsearch.md#index-the-instance)。
1. [インデックス作成状態を確認します](../../../integration/advanced_search/elasticsearch.md#check-indexing-status)。
1. [バックグラウンドジョブのステータスをモニタリングします](../../../integration/advanced_search/elasticsearch.md#monitor-the-status-of-background-jobs)。
1. Elasticsearchで検索を有効にします:

   ```shell
   sudo gitlab-rake gitlab:elastic:enable_search_with_elasticsearch
   ```

{{< /tab >}}

{{< tab title="GitLab 17.1以前" >}}

1. Elasticsearchで検索を無効にします:

   ```shell
   sudo gitlab-rake gitlab:elastic:disable_search_with_elasticsearch
   ```

1. インデックス作成を一時停止し、進行中のタスクが完了するまで5分間待ちます:

   ```shell
   sudo gitlab-rake gitlab:elastic:pause_indexing
   ```

1. インスタンスを最初から再インデックスします:

   ```shell
   sudo gitlab-rake gitlab:elastic:index
   ```

1. インデックス作成を再開します:

   ```shell
   sudo gitlab-rake gitlab:elastic:resume_indexing
   ```

1. [インデックス作成状態を確認します](../../../integration/advanced_search/elasticsearch.md#check-indexing-status)。
1. [バックグラウンドジョブのステータスをモニタリングします](../../../integration/advanced_search/elasticsearch.md#monitor-the-status-of-background-jobs)。
1. Elasticsearchで検索を有効にします:

   ```shell
   sudo gitlab-rake gitlab:elastic:enable_search_with_elasticsearch
   ```

{{< /tab >}}

{{< /tabs >}}

## 予備チェック {#preflight-checks}

計画的なフェイルオーバーをスケジュールする前に、これらの予備チェックを検証して、プロセスがスムーズに進むことを確認してください。各ステップの詳細は以下で説明します。

実際のフェイルオーバープロセス中、プライマリサイトがダウンした後、セカンダリをプロモートする前に、最終的な検証チェックを実行するためにこのコマンドを実行します:

```shell
gitlab-ctl promotion-preflight-checks
```

`gitlab-ctl promotion-preflight-checks`コマンドはフェイルオーバープロセスの一部であり、プライマリサイトがダウンしている必要があります。プライマリがまだ実行されている間は、これをメンテナンス前の検証ツールとして使用することはできません。このコマンドを実行すると、プライマリサイトがダウンしているかどうかを尋ねるプロンプトが表示されます。`No`と回答した場合、`ERROR: primary node must be down`というエラーが表示されます。

プライマリがまだ稼働中のメンテナンス前の検証には、以下の手動チェックを使用してください。

### DNS TTL {#dns-ttl}

[プライマリドメインDNSレコードを更新する](_index.md#optional-updating-the-primary-domain-dns-record)予定がある場合は、DNS変更の迅速な伝播を確実にするために、低いTTL（time-to-live）を設定することを検討してください。

### オブジェクトストレージ {#object-storage}

大規模なGitLabインストールをお持ちの場合、またはダウンタイムを許容できない場合は、計画的なフェイルオーバーをスケジュールする前に、[オブジェクトストレージへ移行する](../replication/object_storage.md)ことを検討してください。そうすることで、メンテナンス期間の長さと、不適切に実行された計画的なフェイルオーバーによるデータ損失のリスクの両方が軽減されます。

GitLabにセカンダリサイトのオブジェクトストレージのレプリケーションを管理させたい場合は、[オブジェクトストレージレプリケーション](../replication/object_storage.md)を参照してください。

### 各セカンダリサイトの設定を確認する {#review-the-configuration-of-each-secondary-site}

データベースの設定は自動的にセカンダリサイトにレプリケートされます。ただし、`/etc/gitlab/gitlab.rb`ファイルを個別に手動でセットアップする必要があり、サイト間で異なります。Mattermost、OAuth、LDAPインテグレーションなどの機能がプライマリサイトで有効になっているが、セカンダリサイトでは有効になっていない場合、それらはフェイルオーバー中に失われます。

両サイトの`/etc/gitlab/gitlab.rb`ファイルを確認します。計画的なフェイルオーバーをスケジュールする前に、セカンダリサイトがプライマリサイトが提供するすべての機能をサポートしていることを確認してください。[GitLab Geoロール](https://docs.gitlab.com/omnibus/roles/#gitlab-geo-roles)が正しく設定されていることを確認してください。

### システムチェックを実行する {#run-system-checks}

プライマリとセカンダリサイトの両方で以下を実行します:

```shell
gitlab-rake gitlab:check
gitlab-rake gitlab:geo:check
```

いずれかのサイトで失敗が報告された場合は、計画的なフェイルオーバーをスケジュールする前にそれらを解決するてください。

### シークレットとSSHホストキーがノード間で一致していることを確認する {#check-that-secrets-and-ssh-host-keys-match-between-nodes}

SSHホストキーと`/etc/gitlab/gitlab-secrets.json`ファイルは、すべてのノードで同一である必要があります。すべてのノードで以下を実行し、出力を比較することでこれを確認します:

```shell
sudo sha256sum /etc/ssh/sshhost /etc/gitlab/gitlab-secrets.json
```

いずれかのファイルが異なる場合は、必要に応じて[手動でGitLabシークレットをレプリケートする](../replication/configuration.md#step-1-manually-replicate-secret-gitlab-values)し、[SSHホストキーをレプリケートする](../replication/configuration.md#step-2-manually-replicate-the-primary-sites-ssh-host-keys)をセカンダリサイトにレプリケートするしてください。

### HTTPSに正しい証明書がインストールされていることを確認する {#check-that-the-correct-certificates-are-installed-for-https}

プライマリサイトおよびプライマリサイトからアクセスされるすべての外部サイトが、公開CAが発行した証明書を使用している場合は、このステップを安全にスキップできます。

以下のいずれかに該当する場合は、セカンダリサイトに正しい証明書をインストールする必要があります:

- プライマリサイトが受信接続を保護するためにカスタムまたは自己署名TLS証明書を使用している場合。
- プライマリサイトが、カスタムまたは自己署名証明書を使用する外部サービスに接続している場合。

詳細については、セカンダリサイトでの[カスタム証明書の使用](../replication/configuration.md#step-4-optional-using-custom-certificates)を参照してください。

### Geoレプリケーションが最新であることを確認する {#ensure-geo-replication-is-up-to-date}

メンテナンス期間は、Geoレプリケーションと検証が完全に終了するまで終わりません。期間をできるだけ短く保つために、アクティブな使用中にこれらのプロセスが可能な限り100%に近いことを確認する必要があります。

セカンダリサイトで:

1. 右上隅で、**管理者**を選択します。
1. 右上隅で、**Geo** > **サイト**を選択します。レプリケートされたオブジェクト（緑色で表示）は100%に近く、失敗（赤色で表示）がないはずです。多数のオブジェクトがまだレプリケートされていない場合（灰色で表示）、サイトが完了するまでさらに時間を与えることを検討してください:

   ![Geo管理者ダッシュボード（セカンダリサイトの同期ステータスを表示）](img/geo_dashboard_v14_0.png)

オブジェクトがレプリケートに失敗した場合は、メンテナンス期間をスケジュールする前に調査してください。レプリケートに失敗したオブジェクトは、計画的なフェイルオーバー後に失われます。

レプリケーション失敗の一般的な原因は、プライマリサイトでのデータ不足です。これらの失敗を解決するには、以下のいずれかを実行します:

- バックアップからデータを復元する。
- 欠落しているデータへの参照を削除します。

### レプリケートされたデータの整合性を検証する {#verify-the-integrity-of-replicated-data}

フェイルオーバーに進む前に、検証が完了していることを確認してください。検証に失敗した破損データは、フェイルオーバー中に失われる可能性があります。

詳細については、[自動バックグラウンド検証](background_verification.md)を参照してください。

### スケジュールされたメンテナンスをユーザーに通知する {#notify-users-of-scheduled-maintenance}

プライマリサイトで次の手順に従います。

1. 右上隅で、**管理者**を選択します。
1. **メッセージ**を選択します。
1. メンテナンス期間についてユーザーに通知するメッセージを追加します。同期が完了するまでに必要な時間を推定するには、**Geo** > **サイト**に移動します。
1. **ブロードキャストメッセージを追加**を選択します。

### フェイルオーバー中のRunner接続 {#runner-connectivity-during-failover}

インスタンスURLの設定方法によっては、フェイルオーバー後にRunnerフリートを100%に保つための追加手順が必要になる場合があります。

Runnerを登録するために使用されるトークンは、プライマリまたはセカンダリインスタンスで機能するはずです。フェイルオーバー後に接続の問題が発生した場合、[セカンダリ設定](../setup/two_single_node_sites.md#manually-replicate-secret-gitlab-values)中にシークレットがコピーされなかった可能性があります。[Runnerトークンをリセット](../../backup_restore/troubleshooting_backup_gitlab.md#reset-runner-registration-tokens)できますが、シークレットが同期されていない場合、Runnerとは関係のない他の問題が発生する可能性があることに注意してください。

RunnerがGitLabインスタンスに繰り返し接続できない場合、一定期間接続を試行しなくなります。デフォルトでは、この期間は1時間です。これを避けるには、GitLabインスタンスに到達可能になるまでRunnerをシャットダウンします。[`check_interval`ドキュメント](https://docs.gitlab.com/runner/configuration/advanced-configuration/#how-check_interval-works)、および設定オプション`unhealthy_requests_limit`と`unhealthy_interval`を参照してください。

- **Location aware URL**を使用する場合: 古いプライマリがDNS設定から削除された後、Runnerは自動的に次に近いインスタンスに接続するはずです。
- 別々のURLを使用する場合: 現在のプライマリに接続されているRunnerは、新しいプライマリがプロモートされたら、それに接続するように更新する必要があります。
- 現在のセカンダリに接続されているRunnerがある場合: フェイルオーバー中の[セカンダリRunnerの処理方法](../secondary_proxy/runners.md#handling-a-planned-failover-with-secondary-runners)を参照してください。

## プライマリサイトへの更新を防止する {#prevent-updates-to-the-primary-site}

すべてのデータがセカンダリサイトにレプリケートされることを確実にするために、プライマリサイトでの更新（書き込みリクエスト）を無効にし、セカンダリサイトが追いつくための時間を与えます:

1. プライマリサイトで[メンテナンスモード](../../maintenance_mode/_index.md)を有効にします。
1. 右上隅で、**管理者**を選択します。
1. **モニタリング** > **バックグラウンドジョブ**を選択します。
1. Sidekiqダッシュボードで、**Cron**を選択します。
1. 非Geo定期バックグラウンドジョブを無効にするには、`Disable All`を選択します。
1. これらのcronジョブに対して`Enable`を選択します:

   - `geo_metrics_update_worker`
   - `geo_prune_event_log_worker`
   - `geo_verification_cron_worker`
   - `repository_check_worker`

   これらのcronジョブを再有効化することは、計画的なフェイルオーバーを正常に完了させるために不可欠です。

## すべてのデータをレプリケートおよび検証を完了する {#finish-replicating-and-verifying-all-data}

1. Geoによって管理されていないデータを手動でレプリケートしている場合は、今すぐ最終レプリケーションプロセスをトリガーするします。
1. プライマリサイトで次の手順に従います。
   1. 右上隅で、**管理者**を選択します。
   1. 左サイドバーで、**モニタリング** > **バックグラウンドジョブ**を選択します。
   1. Sidekiqダッシュボードで、**Queues**を選択します。名前に`geo`を含むキューを除くすべてのキューが0になるまで待ちます。これらのキューには、ユーザーが送信した作業が含まれています。キューが空になる前にフェイルオーバーすると、作業が失われます。
   1. 左サイドバーで、**Geo** > **サイト**を選択します。フェイルオーバー先のセカンダリサイトで以下の条件が満たされるまで待ちます:

      - すべてのレプリケーションメーターが100%レプリケートされ、失敗が0%になること。
      - すべての検証メーターが100%検証済みされ、失敗が0%になること。
      - データベースレプリケーションラグが0ミリ秒であること。
      - Geoログカーソルが最新であること（0イベント遅延）。

1. セカンダリサイトで:
   1. 右上隅で、**管理者**を選択します。
   1. 左サイドバーで、**モニタリング** > **バックグラウンドジョブ**を選択します。
   1. Sidekiqダッシュボードで、**Queues**を選択します。`geo`キューのすべてが、キューに0個、実行中のジョブが0個になるまで待ちます。
   1. [整合性チェックを実行する](../../raketasks/check.md)と、CIアーティファクト、LFSオブジェクト、ファイルストレージ内のアップロードの整合性を検証します。

この時点で、セカンダリサイトにはプライマリサイトのすべての最新コピーが含まれており、フェイルオーバー時にデータ損失がないことを保証します。

## セカンダリサイトをプロモートする {#promote-the-secondary-site}

レプリケーションが完了したら、[セカンダリサイトをプライマリサイトにプロモートする](_index.md)。このプロセスはセカンダリサイトで一時的な停止を引き起こし、ユーザーは再度サインインする必要がある場合があります。手順を正しく実行した場合、古いプライマリGeoサイトは無効になり、ユーザートラフィックは新しくプロモートされたサイトに流れます。

プロモーションが完了すると、メンテナンス期間は終了し、新しいプライマリサイトは古いサイトから分岐し始めます。

フェイルオーバーが完了したら、ブロードキャストメッセージを削除することを忘れないでください。

すべてが期待どおりに機能している場合は、[古いサイトをセカンダリとして戻す](bring_primary_back.md#configure-the-former-primary-site-to-be-a-secondary-site)ことができます。

### 古いプライマリへのフォールバック {#fall-back-to-the-old-primary}

新しくプロモートされたプライマリサイトに問題がある場合、[古いサイトへのフォールバック](bring_primary_back.md)は可能ですが、新しいプライマリサイトで行われたすべての変更は失われます。
