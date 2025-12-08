---
stage: Data access
group: Durability
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: スケールのためのRedisの設定
description: スケールのためにRedisを設定します。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

インフラストラクチャのセットアップとGitLabのインストール方法に基づいて、Redisを設定する方法は複数あります。

RedisとSentinelを自分でインストールして管理したり、ホストされているクラウドソリューションを使用したり、Linuxパッケージにバンドルされているものを使用して設定に集中したりできます。ニーズに合ったものを選択してください。

## Linuxパッケージを使用したRedisのレプリケーションとフェイルオーバー {#redis-replication-and-failover-using-the-linux-package}

この設定は、[Linux **Enterprise Edition**（EE）パッケージ](https://about.gitlab.com/install/?version=ee)を使用してGitLabをインストールした場合のものです。

RedisとSentinelは両方ともパッケージにバンドルされているため、それを使用してRedisインフラストラクチャ全体（プライマリ、レプリカ、センチネル）をセットアップできます。

詳細については、[LinuxパッケージでのRedisのレプリケーションとフェイルオーバー](replication_and_failover.md)を参照してください。

## バンドルされていないRedisを使用したRedisのレプリケーションとフェイルオーバー {#redis-replication-and-failover-using-the-non-bundled-redis}

この設定は、[Linuxパッケージ](https://about.gitlab.com/install/)インストールまたは[セルフコンパイルインストール](../../install/self_compiled/_index.md)のいずれかがある場合に、独自の外部RedisおよびSentinelサーバーを使用する場合のものです。

詳細については、[独自のインスタンスを提供するRedisのレプリケーションとフェイルオーバー](replication_and_failover_external.md)を参照してください。

## Linuxパッケージを使用したスタンドアロンRedis {#standalone-redis-using-the-linux-package}

この設定は、[Linux **Community Edition**（CE）パッケージ](https://about.gitlab.com/install/?version=ce)をインストールしてバンドルされたRedisを使用する場合、つまりRedisサービスのみが有効になっているパッケージを使用できるようにする場合のものです。

詳細については、[Linuxパッケージを使用したスタンドアロンRedis](standalone.md)を参照してください。
