---
stage: Shared responsibility based on functional area
group: Shared responsibility based on functional area
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Redis exporter
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

[Redis exporter](https://github.com/oliver006/redis_exporter)を使用すると、さまざまな[Redis](https://redis.io)メトリクスを測定できます。何がエクスポートされるかの詳細については、[アップストリームドキュメントをお読みください](https://github.com/oliver006/redis_exporter/blob/master/README.md#whats-exported)。

自己コンパイルによるインストール環境では、ユーザー自身がPrometheusをインストールして設定する必要があります。

Redisエクスポーターを有効にするには、次の手順に従います:

1. [Prometheusを有効にします](_index.md#configuring-prometheus)。
1. `/etc/gitlab/gitlab.rb`を編集します。
1. 次の行を追加（または検索してコメント解除）し、`true`に設定されていることを確認してください:

   ```ruby
   redis_exporter['enable'] = true
   ```

1. ファイルを保存して、[GitLabを再設定](../../restart_gitlab.md#reconfigure-a-linux-package-installation)し、変更を有効にします。

Prometheusは、`localhost:9121`で公開されているRedisエクスポーターからパフォーマンスデータの収集を開始します。

## Redisエクスポーターの設定フラグを構成します {#configure-the-redis-exporter-flags}

\`redis_exporter['flags']\` `redis_exporter['flags']`設定を使用して、[コマンドラインフラグ](https://github.com/oliver006/redis_exporter/blob/master/README.md#command-line-flags)を渡し、モニタリング要件に応じてRedisエクスポーターの動作をカスタマイズできます。

{{< alert type="note" >}}

`redis.addr`は、`gitlab_rails[redis_*]`（`gitlab_rails[redis_host]`など）の値によって構成されるため、使用できません。

{{< /alert >}}

Redisエクスポーターフラグを構成するには、次の手順に従います:

1. `/etc/gitlab/gitlab.rb`を編集し、いくつかのフラグを追加します（例）:

   ```ruby
   redis_exporter['flags'] = {
     'redis.password' => 'your-redis-password',
     'namespace' => 'redis',
     'web.listen-address' => ':9121',
     'web.telemetry-path' => '/metrics'
   }
   ```

1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```
