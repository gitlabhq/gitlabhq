---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Geoバックグラウンドジョブ
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

Geoは、すべての同期と検証のインテントをGeoトラッキングデータベースのレジストリテーブルに永続化し、Sidekiqジョブ引数には永続化しません。ジョブが終了した場合、レジストリレコードはそのステータスを保持し、cronベースのスケジューラが作業を再キューイングします。この設計により、Geoは基本的にクラッシュセーフになります。

## レジストリ同期状態 {#registry-sync-states}

すべてのレプリケート可能なデータタイプには、セカンダリサイトに同期ステータスを追跡するレジストリレコードがあります:

| ステータス | 説明 |
|-------|-------------|
| `pending` | 同期が必要です。同期スケジューラcronによってピックアップされます。 |
| `started` | 同期処理中です。ワーカーが終了した場合、レコードはこのステータスのままになります。 |
| `synced` | 正常にレプリケートされました。 |
| `failed` | 同期に失敗しました。指数バックオフ再試行のための`retry_at`タイムスタンプがあります。 |

同期ジョブが強制終了された場合、レジストリは`started`のままになります。10分ごとに実行される`Geo::SyncTimeoutCronWorker`は、同期ジョブの状態を検出し、再試行バックオフ付きでレジストリを`failed`とマークします。その後、同期スケジューラcronワーカーは同期のためにレジストリを再キューイングします。

## リカバリーメカニズム {#recovery-mechanisms}

次のcronワーカーは自動リカバリーを提供します。スケジュールは[`ee/config/schedule.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/config/schedule.yml)で定義されており、設定可能です。

cronジョブ名は、[**管理者**エリア](../../admin_area.md#background-jobs)のSidekiqダッシュボードの**Cron**タブに表示される名前と一致します。

| メカニズム | ワーカー | cronジョブ名 | デフォルトスケジュール | 目的 |
|-----------|--------|---------------|------------------|---------|
| 同期タイムアウトリカバリー | `Geo::SyncTimeoutCronWorker` | `geo_sync_timeout_cron_worker` | 10分ごと（セカンダリ） | `started`状態のレジストリを、再試行バックオフ付きで`failed`とマークします。 |
| blob同期スケジューラ | `Geo::RegistrySyncWorker` | `geo_registry_sync_worker` | 1分ごと（セカンダリ） | `pending`および`failed` blobレジストリをポーリングし、`Geo::SyncWorker`をキューに入れます。 |
| リポジトリ同期スケジューラ | `Geo::RepositoryRegistrySyncWorker` | `geo_repository_registry_sync_worker` | 1分ごと（セカンダリ） | `pending`および`failed`リポジトリレジストリをポーリングし、`Geo::SyncWorker`をキューに入れます。 |
| レジストリの一貫性 | `Geo::Secondary::RegistryConsistencyWorker` | `geo_secondary_registry_consistency_worker` | 1分ごと（セカンダリ） | 追跡されていないレプリケート可能なものに対して、不足しているレジストリレコードを作成します。孤立したレジストリを検出します。 |
| 検証タイムアウト | `Geo::VerificationTimeoutWorker` | `geo_verification_cron_worker`によってトリガーされます。 | 1分ごと（プライマリおよびセカンダリ） | `verification_started`で停止している検証を`verification_failed`とマークします。 |
| 検証スケジューラ | `Geo::VerificationCronWorker` | `geo_verification_cron_worker` | 1分ごと（プライマリおよびセカンダリ） | 検証バッチ、タイムアウト、再検証、ステータスバックフィルワーカーをトリガーします。 |

## キューの安全性の参照 {#queue-safety-reference}

次のセクションでは、Geo Sidekiqキューに関するワーカーごとの安全性情報を提供します。

### Cronワーカー {#cron-workers}

cronワーカーは自動的にスケジュールされ、キューがクリアされた場合、次のcronティックで再実行されます。すべてのcronワーカーキューはクリアしても安全です。

| ワーカー | 機能 | キューをクリアしても安全 | クリアした場合の悪影響 | リカバリーメカニズム |
|--------|-------------|:-------------------:|-----------------------------------|-------------------|
| `Geo::RegistrySyncWorker` | ペンディングおよび失敗したblobレジストリをポーリングします。`Geo::SyncWorker`をキューに入れます。 | はい | 同期は次のcronティックまで遅延します。 | 1分ごとに再実行されます。 |
| `Geo::RepositoryRegistrySyncWorker` | ペンディングおよび失敗したリポジトリレジストリをポーリングします。`Geo::SyncWorker`をキューに入れます。 | はい | 同期は次のcronティックまで遅延します。 | 1分ごとに再実行されます。 |
| `Geo::SyncTimeoutCronWorker` | `started`状態のレジストリを検出します。それらを再試行バックオフ付きで`failed`とマークします。 | はい | `started`で停止しているレジストリは、次のティックまで`failed`に移行されません。同期は次のティック後に再開されます。 | 10分ごとに再実行されます。 |
| `Geo::Secondary::RegistryConsistencyWorker` | すべてのレジストリタイプをスキャンします。不足しているレジストリを作成します。孤立したレジストリを検出し、`Geo::DestroyWorker`をキューに入れます。 | はい | 不足しているレジストリは作成されず、孤立したレジストリは次のティックまでクリーンアップされません。 | 1分ごとに再実行されます。 |
| `Geo::VerificationCronWorker` | すべての検証サブワーカーをトリガーします。 | はい | 検証は次のcronティックまで遅延します。 | 1分ごとに再実行されます。 |
| `Geo::VerificationTimeoutWorker` | `verification_started`で停止しているレコードをリカバリーします。 | はい | `verification_started`で停止しているレコードは、次のティックまで移行されません。 | 1分ごとに再実行されます。 |
| `Geo::PruneEventLogWorker` | すべてのセカンダリが消費した古いイベントログエントリを削除します（プライマリのみ）。 | はい | ワーカーが再び実行されるまで、イベントログは増加します。データ損失なし。 | 5分ごとに再実行されます。 |
| `Geo::MetricsUpdateWorker` | ノードステータスを計算し、Prometheusゲージを更新し、ステータスをプライマリに送信します。 | はい | ワーカーが再び実行されるまで、メトリクスは古くなります。 | 1分ごとに再実行されます。 |
| `Geo::SidekiqCronConfigWorker` | ノードタイプ（プライマリまたはセカンダリ）に基づいてcronジョブを有効/無効にします。 | はい | ワーカーが再び実行されるまで、cronジョブの設定が正しくない場合があります。 | 1分ごとに再実行されます。 |

### 同期ワーカー（セカンダリ） {#sync-workers-secondary}

| ワーカー | 機能 | キューをクリアしても安全 | クリアした場合の悪影響 | リカバリーメカニズム |
|--------|-------------|:-------------------:|-----------------------------------|-------------------|
| `Geo::SyncWorker` | 単一のblobをダウンロードするか、プライマリサイトから単一のリポジトリをフェッチします。 | はい | 実行中のジョブのレジストリは`started`のままになります。同期はリカバリーまで遅延します。 | `SyncTimeoutCronWorker`は、停止しているレジストリを`failed`に移行させます。同期スケジューラが再キューイングします。 |
| `Geo::ContainerRepositorySyncWorker` | プライマリサイトから単一のコンテナリポジトリを同期します。 | はい | レジストリはそのステータスを保持します。同期はリカバリーまで遅延します。 | 同期スケジューラが再キューイングします。 |
| `Geo::BulkRegistryResyncWorker` | レジストリクラスの一括再同期をトリガーします。 | はい | 一括再同期は開始されません。個々のレジストリはそのステータスを保持します。 | 呼び出し元が再キューイングします。 |

### イベントワーカー（プライマリおよびセカンダリ） {#event-workers-primary-and-secondary}

> [!warning]
> イベントワーカーキューをクリアすると、キュー内のイベントが失われる可能性があります。イベントが失われると、セカンダリサイトのデータが一時的に最新ではなくなる可能性があります。

| ワーカー | 機能 | キューをクリアしても安全 | クリアした場合の悪影響 | リカバリーメカニズム |
|--------|-------------|:-------------------:|-----------------------------------|-------------------|
| `Geo::EventWorker` | セカンダリサイトでGeoレプリケーションイベント（`created`、`updated`、`deleted`）を処理します。 | 注意して使用してください。 | `updated`イベントが失われると、リソースが再検証または次回の更新イベントまで最新ではない状態になる可能性があります。`deleted`イベントが失われると、セカンダリサイトに孤立したファイルが残る可能性があります（ディスク容量の無駄、データ損失なし）。`created`イベントが失われても、永続的な影響はありません。Sidekiqの再試行は3回です。 | すべての再試行が失敗しても、レジストリレコードは存在し、同期スケジューラが再エンキューします。`RegistryConsistencyWorker`も孤立したレジストリを検出します。 |
| `Geo::BatchEventCreateWorker` | プライマリサイトでGeoイベントを一括挿入します。 | 注意して使用してください。 | キュー内のイベントは、クリアされた場合失われます。セカンダリサイトは、再検証まで変更を認識しない場合があります。 | セカンダリサイトの`RegistryConsistencyWorker`は、最終的に欠落しているレジストリを検出します（1分ごと）。 |
| `Geo::CreateRepositoryUpdatedEventWorker` | プライマリサイトでリポジトリが更新されたときにGeoイベントを作成します。 | 注意して使用してください。 | `Geo::BatchEventCreateWorker`と同じです。 | `Geo::BatchEventCreateWorker`と同じです。 |

### 検証ワーカー（プライマリおよびセカンダリ） {#verification-workers-primary-and-secondary}

| ワーカー | 機能 | キューをクリアしても安全 | クリアした場合の悪影響 | リカバリーメカニズム |
|--------|-------------|:-------------------:|-----------------------------------|-------------------|
| `Geo::VerificationBatchWorker` | レコードのチェックサムをバッチ単位で計算します。 | はい | 検証が遅延します。 | Cronが再エンキューします。`VerificationTimeoutWorker`が停止しているレコードを捕捉します。 |
| `Geo::ReverificationBatchWorker` | 定期的な再検証のために、すでに検証済みのレコードをマークします。 | はい | 再検証が遅延します。 | cronが再キューイングします。 |
| `Geo::VerificationStateBackfillWorker` | レプリケート可能なタイプについて、検証ステータステーブルをバックフィルします。 | はい | バックフィルが遅延します。排他的リースは30分で期限切れになります。 | それ自体を再キューイングします。 |
| `Geo::BulkPrimaryVerificationWorker` | プライマリサイトでモデルクラスの一括検証をトリガーします。 | はい | 一括検証は開始されません。 | 呼び出し元が再キューイングします。 |
| `Geo::BulkRegistryReverificationWorker` | セカンダリサイトでレジストリクラスの一括再検証をトリガーします。 | はい | 一括再検証は開始されません。 | 呼び出し元が再キューイングします。 |

### 削除ワーカー（セカンダリ） {#destroy-workers-secondary}

> [!warning]
> 削除ワーカーキューをクリアすると、失われたジョブがセカンダリサイトに孤立したファイルやリポジトリを残す可能性があります。

| ワーカー | 機能 | キューをクリアしても安全 | クリアした場合の悪影響 | リカバリーメカニズム |
|--------|-------------|:-------------------:|-----------------------------------|-------------------|
| `Geo::DestroyWorker` | プライマリサイトでの削除後、セカンダリサイトのレプリケートされたファイルまたはリポジトリを削除します。 | 注意して使用してください。 | 孤立したファイルまたはリポジトリがセカンダリサイトに残り、ディスク領域が無駄になります。データ損失なし。Sidekiqの再試行は3回です。 | `RegistryConsistencyWorker`は孤立したレジストリを検出し、`DestroyWorker`を再エンキューします。 |
