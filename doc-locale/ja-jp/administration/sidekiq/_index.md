---
stage: Data access
group: Durability
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 外部Sidekiqインスタンスを設定
description: 外部Sidekiqインスタンスを設定します。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLabパッケージにバンドルされているSidekiqを使用して、外部Sidekiqインスタンスを設定できます。Sidekiqには、Redis、PostgreSQL、およびGitalyのインスタンスへの接続が必要です。

## GitLabインスタンスでPostgreSQL、Gitaly、RedisのTCPアクセスを設定します {#configure-tcp-access-for-postgresql-gitaly-and-redis-on-the-gitlab-instance}

デフォルトでは、GitLabはUNIXソケットを使用しており、TCP経由で通信するように設定されていません。これを変更するには:

1. SidekiqサーバーのIPアドレスを`postgresql['md5_auth_cidr_addresses']`に追加して、[パッケージ化されたPostgreSQLサーバーがTCP/IPでリッスンするように設定](https://docs.gitlab.com/omnibus/settings/database.html#configure-packaged-postgresql-server-to-listen-on-tcpip)
1. [バンドルされたRedisをTCP経由で到達可能にする](https://docs.gitlab.com/omnibus/settings/redis.html#making-the-bundled-redis-reachable-via-tcp)
1. GitLabインスタンスの`/etc/gitlab/gitlab.rb`ファイルを編集し、以下を追加します:

   ```ruby
   ## Gitaly
   gitaly['configuration'] = {
      # ...
      #
      # Make Gitaly accept connections on all network interfaces
      listen_addr: '0.0.0.0:8075',
      auth: {
         ## Set up the Gitaly token as a form of authentication because you are accessing Gitaly over the network
         ## https://docs.gitlab.com/ee/administration/gitaly/configure_gitaly.html#about-the-gitaly-token
         token: 'abc123secret',
      },
   }

   gitlab_rails['gitaly_token'] = 'abc123secret'

   # Password to Authenticate Redis
   gitlab_rails['redis_password'] = 'redis-password-goes-here'
   ```

1. `reconfigure`を実行します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. `PostgreSQL`サーバーを再起動します:

   ```shell
   sudo gitlab-ctl restart postgresql
   ```

## Sidekiqインスタンスをセットアップします {#set-up-sidekiq-instance}

[リファレンスアーキテクチャ](../reference_architectures/_index.md#available-reference-architectures)を検索し、Sidekiqインスタンスのセットアップの詳細に従ってください。

## 共有ストレージを持つ複数のSidekiqノードを設定する {#configure-multiple-sidekiq-nodes-with-shared-storage}

NFSなどの共有ファイルシステムを使用する複数のSidekiqノードを実行する場合は、サーバー間で一致するようにUIDとGIDを指定する必要があります。UIDとGIDを指定すると、ファイルシステムでの権限の問題を防ぐことができます。このアドバイスは、[Geoセットアップに関するアドバイス](../geo/replication/multiple_servers.md#step-4-configure-the-frontend-application-nodes-on-the-geo-secondary-site)と同様です。

複数のSidekiqノードをセットアップするには:

1. `/etc/gitlab/gitlab.rb`を編集します: 

   ```ruby
   user['uid'] = 9000
   user['gid'] = 9000
   web_server['uid'] = 9001
   web_server['gid'] = 9001
   registry['uid'] = 9002
   registry['gid'] = 9002
   ```

1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## 外部Sidekiqを使用する場合のコンテナレジストリを設定する {#configure-the-container-registry-when-using-an-external-sidekiq}

コンテナレジストリを使用しており、Sidekiqとは異なるノードで実行されている場合は、以下の手順に従ってください。

1. `/etc/gitlab/gitlab.rb`を編集し、レジストリのURLを設定します:

   ```ruby
   gitlab_rails['registry_api_url'] = "https://registry.example.com"
   ```

1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. コンテナレジストリがホストされているインスタンスで、`registry.key`ファイルをSidekiqノードにコピーします。

## Sidekiqメトリクスサーバーを設定する {#configure-the-sidekiq-metrics-server}

Sidekiqメトリクスを収集する場合は、Sidekiqメトリクスサーバーを有効にします。`localhost:8082/metrics`からメトリクスを利用できるようにするには:

メトリクスサーバーを設定するには:

1. `/etc/gitlab/gitlab.rb`を編集します: 

   ```ruby
   sidekiq['metrics_enabled'] = true
   sidekiq['listen_address'] = "localhost"
   sidekiq['listen_port'] = 8082

   # Optionally log all the metrics server logs to log/sidekiq_exporter.log
   sidekiq['exporter_log_enabled'] = true
   ```

1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

### HTTPSを有効にする {#enable-https}

{{< history >}}

- GitLab 15.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/364771)されました。

{{< /history >}}

HTTPの代わりにHTTPS経由でメトリクスを提供するには、exporterの設定でTLSを有効にします:

1. `/etc/gitlab/gitlab.rb`を編集し、次の行を追加するか、検索してコメント化を解除してください:

   ```ruby
   sidekiq['exporter_tls_enabled'] = true
   sidekiq['exporter_tls_cert_path'] = "/path/to/certificate.pem"
   sidekiq['exporter_tls_key_path'] = "/path/to/private-key.pem"
   ```

1. ファイルを保存して、[GitLabを再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)し、変更を有効にします。

TLSが有効になっている場合、前に説明したように同じ`port`と`address`が使用されます。メトリクスサーバーは、HTTPとHTTPSを同時に提供できません。

## ヘルスチェックを設定する {#configure-health-checks}

ヘルスチェックプローブを使用してSidekiqを監視する場合は、Sidekiqヘルスチェックサーバーを有効にします。`localhost:8092`からヘルスチェックを利用できるようにするには:

1. `/etc/gitlab/gitlab.rb`を編集します: 

   ```ruby
   sidekiq['health_checks_enabled'] = true
   sidekiq['health_checks_listen_address'] = "localhost"
   sidekiq['health_checks_listen_port'] = 8092
   ```

1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

ヘルスチェックの詳細については、[Sidekiqヘルスチェックページ](sidekiq_health_check.md)を参照してください。

## LDAPとユーザーまたはグループの同期を設定する {#configure-ldap-and-user-or-group-synchronization}

ユーザーとグループの管理にLDAPを使用する場合は、LDAPの設定をSidekiqノードとLDAPの同期ワーカーにも追加する必要があります。LDAPの設定とLDAPの同期ワーカーがSidekiqノードに適用されていない場合、ユーザーとグループは自動的に同期されません。

GitLabのLDAPを設定する方法の詳細については、以下を参照してください:

- [GitLabのLDAP設定ドキュメント](../auth/ldap/_index.md#configure-ldap)
- [LDAPの同期ドキュメント](../auth/ldap/ldap_synchronization.md#adjust-ldap-sync-schedule)

Sidekiqの同期ワーカーでLDAPを有効にするには:

1. `/etc/gitlab/gitlab.rb`を編集します: 

   ```ruby
   gitlab_rails['ldap_enabled'] = true
   gitlab_rails['prevent_ldap_sign_in'] = false
   gitlab_rails['ldap_servers'] = {
   'main' => {
   'label' => 'LDAP',
   'host' => 'ldap.mydomain.com',
   'port' => 389,
   'uid' => 'sAMAccountName',
   'encryption' => 'simple_tls',
   'verify_certificates' => true,
   'bind_dn' => '_the_full_dn_of_the_user_you_will_bind_with',
   'password' => '_the_password_of_the_bind_user',
   'tls_options' => {
      'ca_file' => '',
      'ssl_version' => '',
      'ciphers' => '',
      'cert' => '',
      'key' => ''
   },
   'timeout' => 10,
   'active_directory' => true,
   'allow_username_or_email_login' => false,
   'block_auto_created_users' => false,
   'base' => 'dc=example,dc=com',
   'user_filter' => '',
   'attributes' => {
      'username' => ['uid', 'userid', 'sAMAccountName'],
      'email' => ['mail', 'email', 'userPrincipalName'],
      'name' => 'cn',
      'first_name' => 'givenName',
      'last_name' => 'sn'
   },
   'lowercase_usernames' => false,

   # Enterprise Edition only
   # https://docs.gitlab.com/ee/administration/auth/ldap/ldap_synchronization.html
   'group_base' => '',
   'admin_group' => '',
   'external_groups' => [],
   'sync_ssh_keys' => false
   }
   }
   gitlab_rails['ldap_sync_worker_cron'] = "0 */12 * * *"
   ```

1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## SAMLグループ同期のSAMLグループを設定する {#configure-saml-groups-for-saml-group-sync}

[SAMLグループ同期](../../user/group/saml_sso/group_sync.md)を使用する場合は、すべてのSidekiqノードで[SAMLグループ](../../integration/saml.md#configure-users-based-on-saml-group-membership)を設定する必要があります。

## 関連トピック {#related-topics}

- [追加のSidekiqプロセス](extra_sidekiq_processes.md)
- [特定のジョブクラスの処理](processing_specific_job_classes.md)
- [Sidekiqヘルスチェック](sidekiq_health_check.md)
- [-Sidekiqチャートの使用](https://docs.gitlab.com/charts/charts/gitlab/sidekiq/)

## トラブルシューティング {#troubleshooting}

[Sidekiqのトラブルシューティングに関する管理者ガイド](sidekiq_troubleshooting.md)をご覧ください。
