---
stage: Tenant Scale
group: Tenant Services
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: メモリ使用量の削減
---

Sidekiqメモリキラーは、過剰なメモリを消費するバックグラウンドジョブプロセスを自動的に管理します。この機能は、Linuxメモリキラーが介入する前にワーカープロセスを監視して再起動し、バックグラウンドジョブが正常に完了してから正常にシャットダウンできるようにします。これらのイベントをログに記録することで、高いメモリ使用量につながるジョブを特定しやすくなります。

## Sidekiqのメモリを監視する方法 {#how-we-monitor-sidekiq-memory}

GitLabは、デフォルトではLinuxパッケージまたはDockerインストールの場合にのみ、利用可能なRSS制限を監視します。その理由は、GitLabはメモリが原因でシャットダウンした後、Sidekiqを再起動するためにrunitに依存しており、自己コンパイルおよびHelmチャートインストールではrunitまたは同等のツールを使用しないためです。

デフォルトの設定では、Sidekiqの再起動は15分に1回以下であり、再起動によって受信バックグラウンドジョブの遅延が約1分発生します。

一部のバックグラウンドジョブは、長時間実行される外部プロセスに依存しています。Sidekiqが再起動されたときにこれらが確実に正常に終了するように、各Sidekiqプロセスはプロセスグループリーダーとして実行する必要があります（たとえば、`chpst -P`を使用）。Linuxパッケージインストール、または`bin/background_jobs`スクリプトを`runit`とともに使用している場合は、これは自動的に処理されます。

## 制限を構成する {#configuring-the-limits}

Sidekiqのメモリ制限は、[環境変数](https://docs.gitlab.com/omnibus/settings/environment-variables/#setting-custom-environment-variables)を使用して制御されます。

- `SIDEKIQ_MEMORY_KILLER_MAX_RSS`（KB）: 許可されるRSSのSidekiqプロセスのソフトリミットを定義します。SidekiqプロセスのRSS（キロバイトで表現）が`SIDEKIQ_MEMORY_KILLER_MAX_RSS`を超え、`SIDEKIQ_MEMORY_KILLER_GRACE_TIME`より長くなった場合、正常な再起動がトリガーされます。`SIDEKIQ_MEMORY_KILLER_MAX_RSS`が設定されていないか、その値が0に設定されている場合、ソフトリミットは監視されません。`SIDEKIQ_MEMORY_KILLER_MAX_RSS`は`2000000`にデフォルトで設定されます。
- `SIDEKIQ_MEMORY_KILLER_GRACE_TIME`: Sidekiqプロセスが許可されたRSSソフトリミットを超えて実行できる猶予期間（秒単位）を定義します。Sidekiqプロセスが`SIDEKIQ_MEMORY_KILLER_GRACE_TIME`以内に許可されたRSS（ソフトリミット）を下回った場合、再起動は中断されます。デフォルト値は900秒（15分）です。
- `SIDEKIQ_MEMORY_KILLER_HARD_LIMIT_RSS`（KB）: 許可されるRSSのSidekiqプロセスのハード制限を定義します。SidekiqプロセスのRSS（キロバイトで表現）が`SIDEKIQ_MEMORY_KILLER_HARD_LIMIT_RSS`を超えた場合、Sidekiqの即時かつ正常な再起動がトリガーされます。この値が設定されていないか、0に設定されている場合、ハード制限は監視されません。

- `SIDEKIQ_MEMORY_KILLER_CHECK_INTERVAL`: プロセスRSSをチェックする頻度を定義します。デフォルトは3秒です。
- `SIDEKIQ_MEMORY_KILLER_SHUTDOWN_WAIT`: すべてのSidekiqジョブが完了するまでに許容される最大時間を定義します。その間、新しいジョブは受け入れられません。デフォルトは30秒です。

  プロセスの再起動がSidekiqによって実行されない場合、Sidekiqプロセスは[Sidekiqシャットダウンタイムアウト](https://github.com/mperham/sidekiq/wiki/Signals#term)（デフォルトは25秒）+2秒後に強制的に終了されます。その間にジョブが完了しない場合、現在実行中のすべてのジョブは、Sidekiqプロセスに送信された`SIGTERM`シグナルによって中断されます。

- `GITLAB_MEMORY_WATCHDOG_ENABLED`: デフォルトで有効になっています。Watchdogの実行を無効にするには、`GITLAB_MEMORY_WATCHDOG_ENABLED`をfalseに設定します。

### ワーカーの再起動を監視する {#monitor-worker-restarts}

GitLabは、高いメモリ使用量が原因でワーカーが再起動された場合に、ログイベントを出力します。

以下は、`/var/log/gitlab/gitlab-rails/sidekiq_client.log`におけるこれらのログイベントの1つの例です:

```json
{
  "severity": "WARN",
  "time": "2023-02-04T09:45:16.173Z",
  "correlation_id": null,
  "pid": 2725,
  "worker_id": "sidekiq_1",
  "memwd_handler_class": "Gitlab::Memory::Watchdog::SidekiqHandler",
  "memwd_sleep_time_s": 3,
  "memwd_rss_bytes": 1079683247,
  "memwd_max_rss_bytes": 629145600,
  "memwd_max_strikes": 5,
  "memwd_cur_strikes": 6,
  "message": "rss memory limit exceeded",
  "running_jobs": [
    {
      jid: "83efb701c59547ee42ff7068",
      worker_class: "Ci::DeleteObjectsWorker"
    },
    {
      jid: "c3a74503dc2637f8f9445dd3",
      worker_class: "Ci::ArchiveTraceWorker"
    }
  ]
}
```

各項目の説明は以下のとおりです: 

- `memwd_rss_bytes`は、消費された実際のメモリ量です。
- `memwd_max_rss_bytes`は、`per_worker_max_memory_mb`を通じて設定されたRSS制限です。
- `running jobs`は、プロセスがRSS制限を超過し、正常な再起動を開始した時点で実行されていたジョブをリストします。
