---
stage: Systems
group: Cloud Connector
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Web exporter（専用メトリクスサーバー）
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

メインアプリケーションサーバーとは別にメトリクスを収集することで、GitLabモニタリングの信頼性とパフォーマンスを向上させます。専用のメトリクスサーバーは、ユーザーリクエストからモニタリングトラフィックを分離し、メトリクスの収集がアプリケーションのパフォーマンスに影響を与えないようにします。

中規模から大規模なインストールの場合、この分離により、ピーク時の使用時に、より一貫性のあるデータ収集が可能になり、負荷の高い期間中に重要なメトリクスが見逃されるリスクを軽減できます。

## GitLabメトリクス収集の仕組み {#how-gitlab-metrics-collection-works}

PrometheusでGitLabをモニタリングすると、GitLabは、使用状況、負荷、およびパフォーマンスに関連するデータをアプリケーションからサンプリングするさまざまなコレクターを実行します。GitLabは、1つまたは複数のPrometheus exporterを実行することにより、このデータをPrometheusスクレイプで使用できるようにします。Prometheus exporterは、Prometheusスクレイプが理解できる形式にメトリクスデータをシリアル化するHTTPサーバーです。

{{< alert type="note" >}}

このページは、Webアプリケーションメトリクスに関するものです。バックグラウンドジョブメトリクスをエクスポートするには、[Sidekiqメトリクスサーバーの設定](../../sidekiq/_index.md#configure-the-sidekiq-metrics-server)方法について説明します。

{{< /alert >}}

Webアプリケーションメトリクスをエクスポートするための2つのメカニズムを提供します:

- main Railsアプリケーションを使用します。これは、Pumaというアプリケーションサーバーが、独自の`/-/metrics`エンドポイントを介してメトリクスデータを使用できるようにすることを意味します。これはデフォルトであり、GitLabメトリクスで説明されています。収集されるメトリクスの量が少ない小規模なGitLabインストールでは、このデフォルトを使用する必要があります。
- 専用メトリクスサーバーを使用します。このサーバーを有効にすると、Pumaはメトリクスの提供のみを目的とする追加のプロセスを起動します。このアプローチは、非常に大規模なGitLabインストールで、より優れたフォールトアイソレーションとパフォーマンスをもたらしますが、追加のメモリを使用します。高いパフォーマンスと可用性を求める中規模から大規模のGitLabインストールでは、このアプローチをお勧めします。

専用サーバーとRailsの`/-/metrics`エンドポイントはどちらも同じデータを提供するので、機能的に同等であり、パフォーマンス特性が異なるだけです。

専用サーバーを有効にするには:

1. [Prometheusを有効にします](_index.md#configuring-prometheus)。
1. `/etc/gitlab/gitlab.rb`を編集して、次の行を追加するか、検索してコメントを解除してください。`puma['exporter_enabled']`が`true`に設定されていることを確認してください:

   ```ruby
   puma['exporter_enabled'] = true
   puma['exporter_address'] = "127.0.0.1"
   puma['exporter_port'] = 8083
   ```

1. Prometheusスクレイプを設定します:
   - GitLabバンドルのPrometheusを使用している場合は、[`scrape_config`が`localhost:8083/metrics`を指していることを確認してください](_index.md#adding-custom-scrape-configurations)。
   - 外部Prometheusサーバーを使用している場合は、[新しいエンドポイントをスクレイプするようにその外部サーバーを設定します](_index.md#using-an-external-prometheus-server)。
1. ファイルを保存して、[GitLabを再設定](../../restart_gitlab.md#reconfigure-a-linux-package-installation)し、変更を有効にします。

メトリクスは、`localhost:8083/metrics`から提供およびスクレイプできるようになりました。

## HTTPSの有効化 {#enable-https}

{{< history >}}

- GitLab 15.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/364771)されました。

{{< /history >}}

HTTPの代わりにHTTPSでメトリクスを提供するには、exporter設定でTLSを有効にします:

1. `/etc/gitlab/gitlab.rb`を編集して、次の行を追加するか、検索してコメントを解除してください:

   ```ruby
   puma['exporter_tls_enabled'] = true
   puma['exporter_tls_cert_path'] = "/path/to/certificate.pem"
   puma['exporter_tls_key_path'] = "/path/to/private-key.pem"
   ```

1. ファイルを保存して、[GitLabを再設定](../../restart_gitlab.md#reconfigure-a-linux-package-installation)し、変更を有効にします。

TLSを有効にすると、前に説明したように同じ`port`と`address`が使用されます。メトリクスサーバーは、HTTPとHTTPSを同時に提供することはできません。

## 関連トピック {#related-topics}

- [GitLab Dockerインストール](../../../install/docker/_index.md)
- [Prometheusを使用したGitLabのモニタリング](_index.md)
- [GitLab](_index.md#gitlab-metrics)メトリクス
- [Pumaの操作](../../operations/puma.md)

## トラブルシューティング {#troubleshooting}

### Dockerコンテナの容量不足 {#docker-container-runs-out-of-space}

DockerでGitLabを実行すると、コンテナの容量が不足する可能性があります。これは、Web exporterなど、容量消費量を増やす特定の機能を有効にした場合に発生する可能性があります。

この問題を回避するには、[`shm-size`を更新します](../../../install/docker/troubleshooting.md#devshm-mount-not-having-enough-space-in-docker-container)。
