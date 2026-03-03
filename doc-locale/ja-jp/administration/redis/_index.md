---
stage: Tenant Scale
group: Tenant Services
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: スケーリングのためのRedisの設定
description: スケーリングのためにRedisを設定します。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

インフラストラクチャのセットアップとGitLabのインストール方法に基づいて、Redisを設定する方法は複数あります。

RedisとSentinelを自分でインストールして管理することも、ホストされているクラウドソリューションを使用することも、Linuxパッケージにバンドルされているものを使用して設定に集中することもできます。ニーズに合ったものを選択してください。

## Redisの代わりにValkeyを使用する {#use-valkey-instead-of-redis}

{{< details >}}

- ステータス: ベータ版

{{< /details >}}

{{< history >}}

- GitLab 18.9で[ベータ版](../../policy/development_stages_support.md#beta)として[導入](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/9113)されました。

{{< /history >}}

[Valkey](https://valkey.io/)は、Redisと完全に互換性のあるオープンソースの高性能キー/キー値データストアです。GitLabは、Redisのオプションの代替としてValkeyをサポートしています。

Redisの代わりにValkeyを使用することは、[ベータ](../../policy/development_stages_support.md#beta)機能です。

有効にすると、ValkeyはデフォルトでRedisと同じユーザー、グループ、データディレクトリ、およびログディレクトリの規則を使用します。

RedisノードでValkeyに切り替えるには、以下を`/etc/gitlab/gitlab.rb`に追加します:

```ruby
redis['backend'] = 'valkey'
```

### 既知の問題 {#known-issues}

- 既知の[イシュー589642](https://gitlab.com/gitlab-org/gitlab/-/issues/589642)が原因で、管理者エリアはValkeyのバージョンを誤ってレポートします。このイシューは、インストールされているValkeyのバージョンやその機能には影響しません。

## Linuxパッケージを使用したRedisレプリケーションとフェイルオーバー {#redis-replication-and-failover-using-the-linux-package}

このセットアップは、[Linux **Enterprise Edition**（EE）パッケージ](https://about.gitlab.com/install/?version=ee)を使用してGitLabをインストールした場合を対象としています。

RedisとSentinelは両方ともパッケージにバンドルされているため、それを使用してRedisインフラストラクチャ全体（プライマリ、レプリカ、センチネル）をセットアップできます。

詳細については、[Linuxパッケージを使用したRedisレプリケーションとフェイルオーバー](replication_and_failover.md)を参照してください。

## バンドルされていないRedisを使用したRedisレプリケーションとフェイルオーバー {#redis-replication-and-failover-using-the-non-bundled-redis}

このセットアップは、[Linuxパッケージ](https://about.gitlab.com/install/)インストールまたは[セルフコンパイルインストール](../../install/self_compiled/_index.md)がある場合に、独自の外部RedisサーバーとSentinelサーバーを使用する場合のものです。

詳細については、[独自のインスタンスを提供するRedisレプリケーションとフェイルオーバー](replication_and_failover_external.md)を参照してください。

## Linuxパッケージを使用したスタンドアロンRedis {#standalone-redis-using-the-linux-package}

このセットアップは、バンドルされたRedisを使用するために[Linux **Community Edition**（CE）パッケージ](https://about.gitlab.com/install/?version=ce)をインストールした場合のものです。したがって、Redisサービスのみが有効になっているパッケージを使用できます。

詳細については、[Linuxパッケージを使用したスタンドアロンRedis](standalone.md)を参照してください。
