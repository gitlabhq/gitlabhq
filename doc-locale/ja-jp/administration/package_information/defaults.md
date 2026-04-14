---
stage: GitLab Delivery
group: Build
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: パッケージのデフォルト
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

`/etc/gitlab/gitlab.rb`ファイルで設定が指定されていない限り、パッケージは以下のデフォルトを想定します。

## ポート {#ports}

以下の表で、Linuxパッケージがデフォルトで割り当てるポートのリストを確認してください:

| コンポーネント                 | デフォルトで有効 | 通信手段 | 代替   | 接続ポート |
|:-------------------------:|:-------------:|:----------------:|:-------------:|:----------------|
| GitLab Rails              | はい           | ポート             |               | `80`または`443`   |
| GitLab Shell              | はい           | ポート             |               | `22`            |
| PostgreSQL                | はい           | ソケット           | ポート（`5432`） |                 |
| Redis                     | はい           | ソケット           | ポート（`6379`） |                 |
| Puma                      | はい           | ソケット           | ポート（`8080`） |                 |
| GitLab Workhorse          | はい           | ソケット           | ポート（`8181`） |                 |
| NGINXステータス              | はい           | ポート             |               | `8060`          |
| Prometheus                | はい           | ポート             |               | `9090`          |
| ノードexporter             | はい           | ポート             |               | `9100`          |
| Redis exporter            | はい           | ポート             |               | `9121`          |
| PostgreSQL exporter       | はい           | ポート             |               | `9187`          |
| PgBouncer exporter        | いいえ            | ポート             |               | `9188`          |
| GitLab Exporter           | はい           | ポート             |               | `9168`          |
| Sidekiq exporter          | はい           | ポート             |               | `8082`          |
| Sidekiqヘルスチェック      | はい           | ポート             |               | `8092` <sup>1</sup> |
| Web exporter              | いいえ            | ポート             |               | `8083`          |
| Geo PostgreSQL            | いいえ            | ソケット           | ポート（`5431`） |                 |
| Redis Sentinel            | いいえ            | ポート             |               | `26379`         |
| 受信メール            | いいえ            | ポート             |               | `143`           |
| Elasticsearch            | いいえ            | ポート             |               | `9200`          |
| GitLab Pages              | いいえ            | ポート             |               | `80`または`443`   |
| GitLabレジストリ           | いいえ*           | ポート             |               | `80`、`443`、または`5050` |
| GitLabレジストリ           | いいえ            | ポート             |               | `5000`          |
| LDAP                      | いいえ            | ポート             |               | コンポーネントの設定によって異なります |
| Kerberos                  | いいえ            | ポート             |               | `8443`または`8088` |
| OmniAuth                  | はい           | ポート             |               | コンポーネントの設定によって異なります |
| SMTP                      | いいえ            | ポート             |               | `465`           |
| リモートsyslog             | いいえ            | ポート             |               | `514`           |
| Mattermost                | いいえ            | ポート             |               | `8065`          |
| Mattermost                | いいえ            | ポート             |               | `80`または`443`   |
| PgBouncer                 | いいえ            | ポート             |               | `6432`          |
| Consul                    | いいえ            | ポート             |               | `8300`、`8301`（TCPおよびUDP）、`8500`、`8600` <sup>2</sup> |
| Patroni                   | いいえ            | ポート             |               | `8008`          |
| GitLab KAS                | はい           | ポート             |               | `8150`          |
| Gitaly                    | はい           | ソケット           | ポート（`8075`） | `8075`または`9999`（TLS） |
| Gitaly exporter           | はい           | ポート             |               | `9236`          |
| Praefect                  | いいえ            | ポート             |               | `2305`または`3305`（TLS） |
| GitLab Workhorse exporter | はい           | ポート             |               | `9229`          |
| レジストリexporter         | いいえ            | ポート             |               | `5001`          |

**脚注**: 

1. Sidekiqヘルスチェックの設定がされていない場合、Sidekiqメトリクスexporterの設定がデフォルトとなります。このデフォルトは非推奨であり、[GitLab 15.0](https://gitlab.com/gitlab-org/gitlab/-/issues/347509)で削除される予定です。
1. 追加のConsul機能を使用する場合、さらに多くのポートを開く必要がある場合があります。リストについては、[公式ドキュメント](https://developer.hashicorp.com/consul/docs/install/ports#ports-table)を参照してください。

凡例:

- `Component` - コンポーネントの名前。
- `On by default` - コンポーネントはデフォルトで実行されています。
- `Communicates via` - コンポーネントが他のコンポーネントと通信する方法。
- `Alternative` - コンポーネントを別の種類の通信を使用するように設定できるかどうか。その場合は、使用されるデフォルトのポートと共にタイプがリストされます。
- `Connection port` - コンポーネントが通信するポート。

GitLabは、Gitリポジトリやその他のさまざまなファイルシステムの保存のために、ファイルシステムが準備されていることを期待しています。

NFS（Networkファイルシステム）を使用している場合、実装によってはポート`111`と`2049`の開放が必要となるネットワーク経由でファイルが転送されます。

> [!note]
> 
> 場合によっては、GitLabレジストリはデフォルトで自動的に有効になります。詳細については、[GitLabコンテナレジストリ管理](../packages/container_registry.md)を参照してください。
