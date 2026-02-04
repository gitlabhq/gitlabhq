---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: インポートのSidekiq設定
description: GitLabにインポートまたは移行するためのSidekiq設定を最適化します。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

インポーターは、グループとプロジェクトのインポートおよびエクスポートを処理するために、Sidekiqジョブに大きく依存しています。これらのジョブの中には、大量のリソース（CPUとメモリ）を消費し、完了までに長い時間がかかるものがあり、他のジョブの実行に影響を与える可能性があります。

このイシューを解決するには、インポータージョブを専任のSidekiqキューにルーティングし、そのキューを処理するために専任のSidekiqプロセスを割り当てる必要があります。

たとえば、次の設定を使用できます:

```conf
sidekiq['concurrency'] = 20

sidekiq['routing_rules'] = [
  # Route import and export jobs to the importer queue
  ['feature_category=importers', 'importers'],

  # Route all other jobs to the default queue by using wildcard matching
  ['*', 'default']
]

sidekiq['queue_groups'] = [
  # Run a dedicated process for the importer queue
  'importers',

  # Run a separate process for the default and mailer queues
  'default,mailers'
]
```

この設定では、次のようになります:

- 専任のSidekiqプロセスは、インポーターキューを介してインポートおよびエクスポートジョブを処理します。
- 別のSidekiqプロセスは、他のすべてのジョブ（デフォルトキューとメーラーキュー）を処理します。
- 両方のSidekiqプロセスは、デフォルトで20スレッドの同時実行をするように設定されています。メモリが制約された環境では、この数値を減らすことをお勧めします。

## 追加の処理を設定する {#configure-additional-processes}

インスタンスに、より多くの同時ジョブをサポートするのに十分なリソースがある場合は、追加のSidekiqプロセスを設定して、移行を高速化できます。

Sidekiqプロセスの最大数については、次の点に注意してください:

- プロセスの数は、使用可能なCPUコアの数を超えないようにする必要があります。
- 各プロセスは最大2 GBのメモリを使用する可能性があるため、インスタンスに追加のプロセスに対応できる十分なメモリがあることを確認してください。
- 各プロセスは、`sidekiq['concurrency']`で定義されているように、スレッドごとに1つのデータベース接続を追加します。

例: 

```conf
sidekiq['queue_groups'] = [
  # Run three processes for importer jobs
  'importers',
  'importers',
  'importers',

  # Run a separate process for the default and mailer queues
  'default,mailers'
]
```

この設定では、複数のSidekiqプロセスがインポートおよびエクスポートジョブを同時に処理するため、インスタンスに十分なリソースがある限り、移行が高速化されます。

## 関連トピック {#related-topics}

- [GitLabへのインポートと移行](../../user/import/_index.md)。
- [インポートおよびエクスポート設定](../settings/import_and_export_settings.md)。
- [複数のSidekiq処理の実行](extra_sidekiq_processes.md)。
- [特定のジョブクラスの処理](processing_specific_job_classes.md)。
