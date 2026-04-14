---
stage: Tenant Scale
group: Tenant Services
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Linuxパッケージを使用したスタンドアロンRedis
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

Linuxパッケージを使用して、スタンドアロンRedisサーバーを設定できます。この設定では、Redisはスケールされず、単一障害点となります。しかし、スケールされた環境では、より多くのユーザーを処理したり、スループットを向上させることが目的です。Redis自体は一般的に安定しており、多くのリクエストを処理できるため、単一のインスタンスのみとすることは許容できるトレードオフです。GitLabのスケーリングオプションの概要については、[リファレンスアーキテクチャ](../reference_architectures/_index.md)ページを参照してください。

## スタンドアロンのRedisインスタンスをセットアップする {#set-up-the-standalone-redis-instance}

LinuxパッケージでRedisサーバーを設定するには、以下の手順が最低限必要です。

1. RedisサーバーにSSHで接続します。
1. GitLabダウンロードページから、[ダウンロードしてインストール](https://about.gitlab.com/install/)したいLinuxパッケージを**steps 1 and 2**を使用して入手します。ダウンロードページの他の手順は完了しないでください。

1. `/etc/gitlab/gitlab.rb`を編集し、次の内容を追加します。

   ```ruby
   ## Enable Redis and disable all other services
   ## https://docs.gitlab.com/omnibus/roles/
   roles ['redis_master_role']

   ## Redis configuration
   redis['bind'] = '0.0.0.0'
   redis['port'] = 6379
   redis['password'] = '<redis_password>'

   ## Disable automatic database migrations
   ## Only the primary GitLab application server should handle migrations
   gitlab_rails['auto_migrate'] = false
   ```

1. 変更を有効にするため、[GitLabを再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)します。
1. RedisノードのIPアドレスまたはホスト名、ポート、およびRedisパスワードをメモしておきます。これらは、[GitLabアプリケーションサーバーを設定する](#set-up-the-gitlab-rails-application-instance)際に必要です。

[高度な設定オプション](https://docs.gitlab.com/omnibus/settings/redis/)がサポートされており、必要に応じて追加できます。

## GitLab Railsアプリケーションインスタンスをセットアップする {#set-up-the-gitlab-rails-application-instance}

GitLabがインストールされているインスタンスで:

1. `/etc/gitlab/gitlab.rb`ファイルを編集し、以下の内容を追加します:

   ```ruby
   ## Disable Redis
   redis['enable'] = false

   gitlab_rails['redis_host'] = 'redis.example.com'
   gitlab_rails['redis_port'] = 6379

   ## Required if Redis authentication is configured on the Redis node
   gitlab_rails['redis_password'] = '<redis_password>'
   ```

1. 変更内容を`/etc/gitlab/gitlab.rb`に保存します。

1. 変更を有効にするため、[GitLabを再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)します。

## Redisの代わりにValkeyを使用する {#use-valkey-instead-of-redis}

{{< details >}}

- ステータス: ベータ版

{{< /details >}}

{{< history >}}

- GitLab 18.9で[ベータ版](../../policy/development_stages_support.md#beta)として[導入](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/9113)されました。

{{< /history >}}

[Valkey](https://valkey.io/)をRedisのドロップイン代替として使用できます。ValkeyはRedisと同じ設定オプションを使用します。

Redisの代わりにValkeyを使用することは、[ベータ](../../policy/development_stages_support.md#beta)機能です。

スタンドアロンノードでRedisの代わりにValkeyを使用するには:

1. `/etc/gitlab/gitlab.rb`を編集し、次の内容を追加します。

   ```ruby
   ## Enable Redis and disable all other services
   ## https://docs.gitlab.com/omnibus/roles/
   roles ['redis_master_role']

   ## Switch to Valkey
   redis['backend'] = 'valkey'

   ## Redis configuration
   redis['bind'] = '0.0.0.0'
   redis['port'] = 6379
   redis['password'] = '<redis_password>'

   ## Disable automatic database migrations
   gitlab_rails['auto_migrate'] = false
   ```

1. 変更を有効にするため、[GitLabを再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)します。

GitLab Railsアプリケーションの設定は同じままです。`gitlab_rails['redis_host']`、`gitlab_rails['redis_port']`、および`gitlab_rails['redis_password']`はRedisの場合と同様に設定します。

### 既知の問題 {#known-issues}

- 既知の[イシュー589642](https://gitlab.com/gitlab-org/gitlab/-/issues/589642)が原因で、管理者エリアはValkeyのバージョンを誤ってレポートします。このイシューは、インストールされているValkeyのバージョンやその機能には影響しません。

## トラブルシューティング {#troubleshooting}

[Redisのトラブルシューティングガイド](troubleshooting.md)を参照してください。
