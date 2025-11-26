---
stage: Runtime
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
gitlab_dedicated: no
title: Geoを調整する
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

サイトがバックグラウンドで実行できる並行処理の数を制限できます。

## 同期/検証並行処理の値を変更する {#changing-the-syncverification-concurrency-values}

**プライマリ**サイトで:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **Geo** > **サイト**を選択します。
1. 調整するセカンダリサイトの**編集**を選択します。
1. **設定のチューニング**には、Geoのパフォーマンスを向上させるために調整できるいくつかの変数があります:

   - リポジトリ同期並行処理の制限
   - ファイル同期並行処理制限
   - コンテナリポジトリ同期並行処理制限
   - 検証並行処理制限

並行処理の値を大きくすると、スケジュールされるジョブの数が増えます。ただし、利用可能なSidekiqスレッドの数も増やさない限り、これにより、より多くのダウンロードが並行して行われるとは限りません。たとえば、リポジトリ同期並行処理が25から50に増加した場合、Sidekiqスレッドの数も25から50に増やすことをお勧めします。詳細については、[Sidekiq concurrency documentation](../../sidekiq/extra_sidekiq_processes.md#concurrency)を参照してください。

## デフォルトの設定を低く調整する {#tuning-low-default-settings}

新しいGeoサイトをセットアップする際の過度の負荷を回避するために、GitLab 18.0以降、Geoの並行処理設定は、ほとんどの環境で低いデフォルトに設定されています。これらの設定を増やすには、次の手順を実行します:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **Geo** > **サイト**を選択します。
1. 進行が遅すぎるデータの種類を決定します。
1. プライマリサイトとセカンダリサイトの負荷メトリクスを監視します。
1. 並行処理制限を10ずつ増やして、控えめにします。
1. 少なくとも3分間、進行状況と負荷メトリクスの変化を監視します。
1. 負荷メトリクスが目的の最大値に達するか、同期と検証が目的どおりに迅速に進むまで、制限の引き上げを繰り返します。

## リポジトリの再検証 {#repository-re-verification}

[自動バックグラウンド検証](../disaster_recovery/background_verification.md)を参照してください。
