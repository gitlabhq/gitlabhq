---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab 17の変更点
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 製品: GitLab Self-Managed

{{< /details >}}

このページでは、GitLab 17のマイナーバージョンとパッチバージョンのアップグレード情報を提供します。以下の手順を確認してください。

- インストールタイプ。
- 現在のバージョンと移行先バージョン間のすべてのバージョン。

GitLab Helmチャートのアップグレードの詳細については、[8.0のリリースノート](https://docs.gitlab.com/charts/releases/8_0.html)を参照してください。

## 16.11からのアップグレード時に注意すべき問題

- バックグラウンド移行`AlterWebhookDeletedAuditEvent: audit_events`の完了に数時間かかることがあります。詳細については、[マージリクエスト161320](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/161320)を参照してください。

- GitLab 17.0以降にアップグレードする前に、[非推奨になったバンドルGrafana](../deprecations.md#bundled-grafana-deprecated-and-disabled)キーへの参照を`gitlab.rb`から削除する必要があります。アップグレード後、`gitlab.rb`にあるキーを参照すると、`gitlab-ctl reconfigure`が失敗します。

- GitLab 17.0にアップグレードする前に、[新しいRunner登録ワークフローに移行](../../ci/runners/new_creation_workflow.md)する必要があります。

  GitLab 16.0では、Runner認証トークンを使用してRunnerを登録する新しいRunner作成ワークフローが導入されました。登録トークンを使用する従来のワークフローは、GitLab 17.0ではデフォルトで無効になり、GitLab 18.0で削除されます。登録トークンがまだ使用されている場合、GitLab 17.0にアップグレードすると、Runnerの登録が失敗します。

- Gitalyストレージは、この例のように同じパスを共有できなくなりました。

  ```ruby
  gitaly['configuration'] = {
    storage: [
      {
         name: 'default',
         path: '/var/opt/gitlab/git-data/repositories',
      },
      {
         name: 'duplicate-path',
         path: '/var/opt/gitlab/git-data/repositories',
      },
    ],
  }
  ```

  この例では、`duplicate-path`ストレージを削除するか、新しいパスに再配置する必要があります。複数のGitalyノードがある場合は、そのノードの`gitlab.rb`ファイルに、そのノードに対応するストレージのみがリストされていることを確認する必要があります。

  ストレージがノードの`gitlab.rb`ファイルから削除された場合、それに関連付けられているすべてのプロジェクトは、GitLabデータベースでストレージを更新する必要があります。Railsコンソールを使用してストレージを更新できます。次に例を示します。

  ```shell
  $ sudo gitlab-rails console
  Project.where(repository_storage: 'duplicate-path').update_all(repository_storage: 'default')
  ```

- GitLab 16.xからGitLab 17.1.0または17.1.1に直接アップグレードする際に移行が失敗します。このバグはGitLab 17.1.2で修正されました。GitLab 16.xから17.1.2に直接アップグレードしても、これらの問題は発生しません。

  バックグラウンドジョブの完了が正しく適用されないGitLab 17.1.0および17.1.1のバグにより、GitLab 17.1.0および17.1.1に直接アップグレードすると、エラーが発生する可能性があります。アップグレードの移行中のエラーは、次のようになります。

  ```shell
  main: == [advisory_lock_connection] object_id: 55460, pg_backend_pid: 8714
  main: == 20240531173207 ValidateNotNullCheckConstraintOnEpicsIssueId: migrating =====
  main: -- execute("SET statement_timeout TO 0")
  main:    -> 0.0004s
  main: -- execute("ALTER TABLE epics VALIDATE CONSTRAINT check_450724d1bb;")
  main: -- execute("RESET statement_timeout")
  main: == [advisory_lock_connection] object_id: 55460, pg_backend_pid: 8714
  STDERR:
  ```

  アップグレードするには、次のいずれかを行います。

  - GitLab 17.0にアップグレードし、すべてのバックグラウンド移行が完了するまで待ちます。
  - GitLab 17.1にアップグレードし、次のコマンドを実行してバックグラウンドジョブと移行を手動で実行します。

    ```shell
    sudo gitlab-rake gitlab:background_migrations:finalize[BackfillEpicBasicFieldsToWorkItemRecord,epics,id,'[null]']
    ```

  これで、GitLab 17.1での移行を完了し、アップグレードを完了できるはずです。

- GitLab 17.0.xおよびGitLab 17.1.xに同梱されているGitバージョンにおける[既知の問題](https://gitlab.com/gitlab-org/gitlab/-/issues/476542)により、負荷が高い場合にCPU使用率が著しく増加します。このリグレッションの主な原因は、GitLab 17.2に同梱されているGitバージョンで解決されたため、ピーク負荷が高いシステムの場合は、GitLab 17.2にアップグレードする必要があります。

### Linuxパッケージのインストール

Linuxパッケージのインストールには、次の特定の情報が適用されます。

- PostgreSQL 13のバイナリが削除されました。

  アップグレードする前に、インストールで[PostgreSQL 14](https://docs.gitlab.com/omnibus/settings/database.html#upgrade-packaged-postgresql-server)が使用されていることを確認してください。

- Ubuntu 18.04のパッケージは作成されなくなりました。

  GitLabをアップグレードする前に、オペレーティングシステムがUbuntu 20.04以降にアップグレードされていることを確認してください。

### 有効期限切れのないアクセストークン

有効期限のないアクセストークンは無期限に有効であるため、アクセストークンが漏洩した場合、セキュリティリスクとなります。

GitLab 16.0以降にアップグレードすると、有効期限のない[個人](../../user/profile/personal_access_tokens.md)、[プロジェクト](../../user/project/settings/project_access_tokens.md)、または[グループ](../../user/group/settings/group_access_tokens.md)のアクセストークンには、アップグレード日から1年後の有効期限が自動的に設定されます。

この自動有効期限が適用される前に、混乱を最小限に抑えるため、次の手順を実行してください。

1. [有効期限のないアクセストークンを特定](../../security/tokens/token_troubleshooting.md#find-tokens-with-no-expiration-date)します。
1. [それらのトークンに有効期限を付与](../../security/tokens/token_troubleshooting.md#extend-token-lifetime)します。

詳細については、以下を参照してください。

- [非推奨と削除に関するドキュメント](../deprecations.md#non-expiring-access-tokens)。
- [非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/369122)。

## 17.1以前からのアップグレード時に注意すべき問題

- お客様がGitLab Duoを使用しており、GitLab 17.2.3以前にアップグレードする場合は、次の両方を実行する必要があります。
  - ライセンスを再同期します。
  - アップグレード後にサーバーを再起動します。
- お客様がGitLab Duoを使用しており、GitLab 17.2.4以降にアップグレードする場合は、次のいずれかを実行する必要があります。
  - ライセンスを再同期します。
  - 24時間ごとに実行される次のスケジュールされたライセンス同期まで待ちます。

お客様がGitLab 17.2.4以降にアップグレードした後、これらの手順は今後のアップグレードでは不要になります。

詳細については、[イシュー480328](https://gitlab.com/gitlab-org/gitlab/-/issues/480328)を参照してください。

## 17.3からのアップグレード時に注意すべき問題

- GitLab 17.3からアップグレードする際に移行が失敗します。

  17.3から17.4にアップグレードする場合、エラーが発生する可能性がわずかにあります。移行プロセス中に、次のようなエラーメッセージが表示されることがあります。

  ```shell
  main: == [advisory_lock_connection] object_id: 127900, pg_backend_pid: 76263
  main: == 20240812040748 AddUniqueConstraintToRemoteDevelopmentAgentConfigs: migrating
  main: -- transaction_open?(nil)
  main:    -> 0.0000s
  main: -- view_exists?(:postgres_partitions)
  main:    -> 0.0181s
  main: -- index_exists?(:remote_development_agent_configs, :cluster_agent_id, {:name=>"index_remote_development_agent_configs_on_unique_agent_id", :unique=>true, :algorithm=>:concurrently})
  main:    -> 0.0026s
  main: -- execute("SET statement_timeout TO 0")
  main:    -> 0.0004s
  main: -- add_index(:remote_development_agent_configs, :cluster_agent_id, {:name=>"index_remote_development_agent_configs_on_unique_agent_id", :unique=>true, :algorithm=>:concurrently})
  main: -- execute("RESET statement_timeout")
  main:    -> 0.0002s
  main: == [advisory_lock_connection] object_id: 127900, pg_backend_pid: 76263
  rake aborted!
  StandardError: An error has occurred, all later migrations canceled:

  PG::UniqueViolation: ERROR:  could not create unique index "index_remote_development_agent_configs_on_unique_agent_id"
  DETAIL:  Key (cluster_agent_id)=(1000141) is duplicated.
  ```

  このエラーは、移行によって`remote_development_agent_configs`テーブルの`cluster_agent_id`列に一意の制約が追加されますが、重複エントリがまだ存在するために発生します。以前の移行ではこれらの重複を削除することになっていますが、まれに、2つの移行の間に新しい重複が挿入されることがあります。

  この問題を安全に解決するには、次の手順を実行します。

  1. 移行が実行されているRailsコンソールを開きます。
  1. 以下のスクリプトをコピーしてコンソールに貼り付け、実行します。
  1. 移行を再実行すると、正常に完了するはずです。

   ```Ruby
   # Get the IDs to keep for each cluster_agent_id; if there are duplicates, only the row with the latest updated_at will be kept.
   latest_ids = ::RemoteDevelopment::RemoteDevelopmentAgentConfig.select("DISTINCT ON (cluster_agent_id) id")
     .order("cluster_agent_id, updated_at DESC")
     .map(&:id)

   # Get the list of remote_development_agent_configs to be removed.
   agent_configs_to_remove = ::RemoteDevelopment::RemoteDevelopmentAgentConfig.where.not(id: latest_ids)

   # Delete all duplicated agent_configs.
   agent_configs_to_remove.delete_all
   ```

## 17.4からのアップグレード時に注意すべき問題

- 17.4から17.5にアップグレードする際にバックグラウンドジョブの移行が失敗します。

  17.4から17.5にアップグレードすると、削除されたバックグラウンドデータ移行に関連するSidekiqジョブでエラーが発生することがあります。エラーメッセージは次のようになります: `uninitialized constant Gitlab::BackgroundMigration::SetProjectVulnerabilityCount`。

  このエラーは最終的には自然に消えますが、Railsコンソールで次のスクリプトを実行して、エラーが表示されないようにすることもできます。

  ```ruby
  Gitlab::Database::BackgroundMigration::BatchedMigration.for_configuration(
    :gitlab_main, 'SetProjectVulnerabilityCount', :project_settings, :project_id, []
  ).delete_all
  ```

## 17.5からのアップグレード時に注意すべき問題

- GitLab 17.5からアップグレードする際に移行が失敗します。

  17.5から17.6にアップグレードする場合、エラーが発生する可能性がわずかにあります。移行プロセス中に、次のようなエラーメッセージが表示されることがあります。

  ```shell
  rake aborted!
  StandardError: An error has occurred, all later migrations canceled:

  PG::CheckViolation: ERROR: new row for relation "ci_deleted_objects" violates check constraint "check_98f90d6c53"
  ```

  このエラーは、移行が`ci_deleted_objects`テーブルからいくつかの行を更新して処理しようとしますが、必要なチェック制約の値が欠落している古いレコードであるために発生します。

  この問題を安全に解決するには、次の手順を実行します。

  1. 次の移行のみを実行して、チェック制約の影響を受けるレコードを修正します。
  1. 移行を再実行すると、正常に完了するはずです。

   ```shell
   gitlab-rake db:migrate:up:ci VERSION=20241028085044
   ```

## 17.8にアップグレード時に注意すべき問題

- GitLab 17.8にアップグレードする際に移行が失敗します。

  17.8にアップグレードする場合、エラーが発生する可能性がわずかにあります。移行プロセス中に、次のようなエラーメッセージが表示されることがあります。

  ```shell
  ERROR:  duplicate key value violates unique constraint "work_item_types_pkey"
  DETAIL:  Key (id)=(1) already exists.
  ```

  エラーが発生する移行は、`db/post_migrate/20241218223002_fix_work_item_types_id_column_values.rb`になります。

  このエラーは、場合によっては、`work_item_types`テーブルのレコードが、アプリケーションに追加されたときと同じ順序でデータベースに作成されなかったために発生します。

  この問題を安全に解決するには、次の手順を実行します。

  1. **17.8へのアップグレードを試行したときにこのエラーが発生した場合にのみ、この手順を実行してください。**`gitlab_main`データベースで次のSQLクエリを実行します。

      ```sql
      UPDATE work_item_types set id = (id * 10);
      ```

  1. 失敗した移行の実行を再試行します。これで成功するはずです。

## 17.8.0

- GitLab 17.8.0では、Kubernetes向けGitLabエージェントサーバー（KAS）は、GitLab Linuxパッケージ（Omnibus）およびDockerインストールでデフォルト設定では起動しません。この問題を解決するには、`/etc/gitlab/gitlab.rb`を編集します。

  ```ruby
  gitlab_kas['env'] = { 'OWN_PRIVATE_API_URL' => 'grpc://127.0.0.1:8155' }
  ```

  複数のノードインストールでは、[ドキュメント](../../administration/clusters/kas.md)に記載されている設定を使用する必要があります。

- WorkhorseのS3オブジェクトストレージアップロードでは、[Go向けAWS SDK v2](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/164597)のみが使用されるようになりました。`workhorse_use_aws_sdk_v2`機能フラグが削除されました。AWS SDK v2は[`Accept-Encoding: identity`を設定し、署名付きヘッダーとして含めます](https://github.com/aws/aws-sdk-go-v2/issues/2848)。ただし、Cloudflareなど一部のプロキシサービスでは、[このヘッダーが変更され、署名不一致エラーが発生します](https://gitlab.com/gitlab-org/gitlab/-/issues/492973#note_2312726631)。[SignatureDoesNotMatchエラー](https://repost.aws/knowledge-center/s3-presigned-url-signature-mismatch)が表示された場合は、プロキシサーバーが署名付きHTTPヘッダーを変更または削除しないことを確認してください。

## 17.7.0

- Gitalyでは、Git 2.47.0以降が必須です。ソースからインストールする場合は、[Gitalyが提供するGitバージョン](../../install/installation.md#git)を使用する必要があります。
- AmazonLinux 2のFIPS Linuxパッケージを除き、FIPS LinuxパッケージはシステムLibgcryptを使用するようになりました。以前のバージョンのFIPS Linuxパッケージは、通常のLinuxパッケージで使用されているのと同じLibgcryptを使用していましたが、これはバグでした。詳細については、[FIPSドキュメント](../../development/fips_gitlab.md#system-libgcrypt)を参照してください。
- Linux`gitlab-runner`パッケージでは、`gitlab-runner-helper-images`が新しい必須の依存関係として分割されました。アップグレードのために`gitlab-runner`パッケージを手動でインストールする場合は、[ヘルパーイメージを手動でダウンロード](https://docs.gitlab.com/runner/install/linux-manually/#download)することも忘れないでください。

### OpenSSL 3のアップグレード

{{< alert type="note" >}}

GitLab 17.7にアップグレードする前に、[OpenSSL 3ガイド](https://docs.gitlab.com/omnibus/settings/ssl/openssl_3.html)を使用して、外部インテグレーションの互換性を特定して評価します。

{{< /alert >}}

- Linuxパッケージは、OpenSSLをv1.1.1wからv3.0.0にアップグレードします。
- クラウドネイティブGitLab（CNG）は、GitLab16.7.0ですでにOpenSSL 3にアップグレードされています。クラウドネイティブGitLabを使用している場合は、アクションは必要ありません。ただし、[クラウドネイティブハイブリッド](../../administration/reference_architectures/_index.md#recommended-cloud-providers-and-services)インストールでは、GitalyなどのステートフルコンポーネントにLinuxパッケージを使用することに注意してください。これらのコンポーネントでは、以下で説明するセキュリティレベルの変更で使用されるTLSバージョン、暗号、および証明書が機能することを確認する必要があります。

OpenSSL 3へのアップグレードでは:

- GitLabでは、すべての発信および受信TLS接続にTLS 1.2以降が必要です。
- TLS/SSL証明書は、少なくとも112ビットのセキュリティを持っている必要があります。2048ビット未満のRSA、DSA、DHキー、および224ビット未満のECCキーは禁止されています。

LDAPやWebhookサーバーなどの古いサービスでは、TLS 1.1がまだ使用されている場合がありますが、TLS 1.0および1.1はサポートが終了しており、セキュアではありません。GitLabは、`no protocols available`エラーメッセージでTLS 1.0または1.1を使用するサービスへの接続に失敗します。

さらに、OpenSSL 3では、[デフォルトのセキュリティレベルがレベル1から2に引き上げられ](https://docs.openssl.org/3.0/man3/SSL_CTX_set_security_level/#default-callback-behaviour)、最小セキュリティビット数が80から112に引き上げられました。その結果、2048ビット未満のRSAおよびDSAキーと、224ビット未満のECCキーで署名された証明書は禁止されます。

GitLabは、ビット数が不十分な署名付き証明書を使用するサービスへの接続に失敗し、`certificate key too weak`エラーメッセージを返します。詳細については、[証明書の要件](../../security/tls_support.md#certificate-requirements)を参照してください。

Linuxパッケージに同梱されているすべてのコンポーネントは、OpenSSL 3と互換性があります。したがって、GitLabパッケージに含まれていない、[「外部」](https://docs.gitlab.com/omnibus/settings/ssl/openssl_3.html#identifying-external-integrations)のサービスとインテグレーションのみを確認する必要があります。

SSH鍵はこのアップグレードの影響を受けません。OpenSSLは、SSHではなく、TLSのセキュリティ要件を設定します。[OpenSSH](https://www.openssh.com/)と[`gitlab-sshd`](../../administration/operations/gitlab_sshd.md)には、許可されている暗号学的アルゴリズム独自の構成設定があります。

詳細については、[インストールを保護するためのGitLabドキュメント](../../security/_index.md)を確認してください。

## 17.5.0

{{< alert type="note" >}}

OpenSSL 3のアップグレードは、GitLab 17.7.0に延期されました。

{{< /alert >}}

- GitLab Runner分散キャッシュのS3オブジェクトストレージアクセスは、MinIOクライアントではなく、[Go向けAWS SDK v2](https://gitlab.com/gitlab-org/gitlab-runner/-/merge_requests/4987)で処理されるようになりました。`FF_USE_LEGACY_S3_CACHE_ADAPTER` [GitLab Runner機能フラグ](https://docs.gitlab.com/runner/configuration/feature-flags.html)を`true`に設定することで、MinIOクライアントを再度有効にできます。
- GitLabとの認証に使用されるGitalyのトークンが[独自の設定](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/8688)になりました。これは、GitalyがGitLab RailsおよびShellレシピを実行して、Shellディレクトリ内のデフォルトのシークレットファイルを作成する必要がなく、独自のシークレットファイルを持つことができることを意味します。一部のカスタマイズされた環境では、シークレットの不一致を回避するために[認証設定を更新](../../administration/gitaly/configure_gitaly.md#configure-authentication)する必要がある場合があります。

## 17.4.0

- GitLab 17.4以降、新しいGitLabインストールでは、ID列に関するデータベーススキーマが異なります。
  - 以前のすべての整数（32ビット）ID列（たとえば、`id`、`%_id`、`%_ids`のような列）は、`bigint`（64ビット）として作成されるようになりました。
  - 既存のインストールでは、後のリリースで提供されるデータベース移行によって、32ビットから64ビットの整数に移行します。
  - アップグレードをテストするために新しいGitLab環境を構築する場合は、GitLab 17.3以前をインストールして、既存の環境と同じ整数型を取得します。それから、後のリリースにアップグレードして、既存の環境と同じデータベース移行を実行できます。データベースの復元により、既存のデータベーススキーマ定義が削除され、バックアップの一部として保存されている定義が使用されるため、バックアップから新しい環境に復元する場合は、これは必要ありません。
- Gitalyでは、Git 2.46.0以降が必須です。ソースからインストールする場合は、[Gitalyが提供するGitバージョン](../../install/installation.md#git)を使用する必要があります。
- WorkhorseのS3オブジェクトストレージアップロードは、デフォルトで[Go向けAWS SDK v2](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/164597)を使用して処理されるようになりました。S3オブジェクトストレージのアップロードで問題が発生した場合は、`workhorse_use_aws_sdk_v2`[機能フラグ](../../administration/feature_flags.md#enable-or-disable-the-feature)を無効にして、v1にダウングレードできます。
- GitLab 17.4にアップグレードすると、Web IDE用のOAuthアプリケーションが生成されます。`GitLab.rb`ファイルでGitLabサーバーの外部URL設定に大文字が含まれている場合、Web IDEの読み込みに失敗する可能性があります。この問題を解決するには、[OAuthコールバックURLの更新](../../user/project/web_ide/_index.md#update-the-oauth-callback-url)を参照してください。
- [RFC 7540](https://datatracker.ietf.org/doc/html/rfc7540#section-3.3)に従い、GitalyとPraefectはALPNをサポートしていないTLS接続を拒否します。TLSが有効になっているPraefectの前にロードバランサーを使用する場合は、ALPNが使用されていない場合、`FAIL: 14:connections to all backends failing`エラーが発生する可能性があります。Praefect環境で`GRPC_ENFORCE_ALPN_ENABLED=false`を設定すると、この適用を無効にできます。Linuxパッケージを使用する場合は、`/etc/gitlab/gitlab.rb`を編集します。

    ```ruby
    praefect['env'] = { 'GRPC_ENFORCE_ALPN_ENABLED' => 'false' }
    ```

  次に、`gitlab-ctl reconfigure`を実行します。

  ALPN適用は、[GitLab 17.5.5およびその他のバージョン](../../administration/gitaly/praefect.md#alpn-enforcement)で再び無効になっています。これらのいずれかのバージョンにアップグレードすると、`GRPC_ENFORCE_ALPN_ENABLED`を設定する必要がなくなります。

## 17.3.0

- Gitalyでは、Git 2.45.0以降が必須です。ソースからインストールする場合は、[Gitalyが提供するGitバージョン](../../install/installation.md#git)を使用する必要があります。

### Geoインストール17.3.0

- Geoレプリケーションが機能している場合でも、セカンダリサイトのGeoレプリケーション詳細ページが空に見えます。[イシュー468509](https://gitlab.com/gitlab-org/gitlab/-/issues/468509)を参照してください。既知の回避策はありません。このバグはGitLab 17.4で修正されました。

  **影響を受けたリリース**:

  | マイナーリリース | パッチリリース | 修正リリース |
  | ----------------------- | ----------------------- | -------- |
  | 16.11                   |  16.11.5 - 16.11.10     | なし     |
  | 17.0                    |  すべて                    | 17.0.7   |
  | 17.1                    |  すべて                    | 17.1.7   |
  | 17.2                    |  すべて                    | 17.2.5   |
  | 17.3                    |  すべて                    | 17.3.1   |

## 17.2.1

- GitLab 17.2.1へのアップグレードは、[データベース内の不明なシーケンス](https://gitlab.com/gitlab-org/gitlab/-/issues/474293)が原因で失敗する可能性があります。この問題はGitLab 17.2.2で修正されました。

- [GitLab 17.2.1へのアップグレードが次のエラーで失敗する](https://gitlab.com/gitlab-org/gitlab/-/issues/473337)ことがあります。

  ```plaintext
  PG::DependentObjectsStillExist: ERROR: cannot drop desired object(s) because other objects depend on them
  ```

  [このイシューで説明されている](https://gitlab.com/gitlab-org/gitlab/-/issues/474525#note_2045274993)ように、このデータベースシーケンスの所有権の問題はGitLab 17.2.1で修正されました。ただし、17.2.0の移行が完了しなかった場合に、この問題が発生する可能性があります。これは、不正な形式のJSONファイルが原因で、Linuxパッケージが17.2.1以降へのアップグレードを妨げるためです。たとえば、次のエラーが表示されることがあります。

  ```plaintext
  Malformed configuration JSON file found at /opt/gitlab/embedded/nodes/gitlab.example.com.json.
  This usually happens when your last run of `gitlab-ctl reconfigure` didn't complete successfully.
  This file is used to check if any of the unsupported configurations are enabled,
  and hence require a working reconfigure before upgrading.
  Please run `sudo gitlab-ctl reconfigure` to fix it and try again.
  ```

  現在の回避策は次のとおりです。

  1. `/opt/gitlab/embedded/nodes`のJSONファイルを削除します。

     ```shell
     rm /opt/gitlab/embedded/nodes/*.json
     ```

  1. GitLab 17.2.1以降にアップグレードします。

### Geoインストール17.2.1

- GitLab 16.11からGitLab 17.2までのバージョンでは、PostgreSQLインデックスが欠落していると、CPU使用率が高くなったり、ジョブアーティファクトの検証の進行が遅くなったり、Geoメトリクスのステータスアップデートが遅延したり、タイムアウトしたりする可能性があります。インデックスは GitLab 17.3で追加されました。インデックスを手動で追加するには、[Geoトラブルシューティング - ジョブアーティファクトの検証中にプライマリでCPU使用率が高くなる](../../administration/geo/replication/troubleshooting/common.md#high-cpu-usage-on-primary-during-object-verification)を参照してください。

  **影響を受けたリリース**:

  | マイナーリリース | パッチリリース | 修正リリース |
  | ----------------------- | ----------------------- | -------- |
  | 16.11                   |  すべて                    | なし     |
  | 17.0                    |  すべて                    | 17.0.7   |
  | 17.1                    |  すべて                    | 17.1.7   |
  | 17.2                    |  すべて                    | 17.2.5   |

- Geoレプリケーションが機能している場合でも、セカンダリサイトのGeoレプリケーション詳細ページが空に見えます。[イシュー468509](https://gitlab.com/gitlab-org/gitlab/-/issues/468509)を参照してください。既知の回避策はありません。このバグはGitLab 17.4で修正されました。

  **影響を受けたリリース**:

  | マイナーリリース | パッチリリース | 修正リリース |
  | ----------------------- | ----------------------- | -------- |
  | 16.11                   |  16.11.5 - 16.11.10     | なし     |
  | 17.0                    |  すべて                    | 17.0.7   |
  | 17.1                    |  すべて                    | 17.1.7   |
  | 17.2                    |  すべて                    | 17.2.5   |
  | 17.3                    |  すべて                    | 17.3.1   |

## 17.1.0

- 信頼できない`extern_uid`を持つBitbucket IDが削除されます。詳細については、[イシュー452426](https://gitlab.com/gitlab-org/gitlab/-/issues/452426)を参照してください。
- デフォルトの[変更履歴](../../user/project/changelogs.md)テンプレートは、GitLab固有の参照ではなく、完全なURLとしてリンクを生成します。詳細については、[マージリクエスト155806](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/155806)を参照してください。
- Gitalyでは、Git 2.44.0以降が必須です。自己コンパイルされたインストールでは、[Gitalyが提供するGitバージョン](../../install/installation.md#git)を使用する必要があります。
- GitLab 17.1.0または17.1.1へのアップグレード、またはGitLab 17.0からの未完了のバックグラウンド移行があると、移行の実行時に失敗する可能性があります。これはバグが原因です。[イシュー468875](https://gitlab.com/gitlab-org/gitlab/-/issues/468875)はGitLab 17.1.2で修正されました。

### 長時間実行パイプラインメッセージのデータ変更

GitLab 17.1は、`ci_pipeline_messages`テーブルに多数のレコードを持つ大規模なGitLabインスタンスに必要な経由地点です。

データ変更は、大規模なGitLabインスタンスで完了するまでに数時間かかる場合があり、1時間あたり150 万～200万件のレコードが処理されます。インスタンスが影響を受ける場合:

1. 17.1にアップグレードします。
1. [すべてのバッチ移行が正常に完了したことを確認します](../background_migrations.md#batched-background-migrations)。
1. 17.2または17.3にアップグレードします。

影響を受けているかどうかを確認するには:

1. [データベースコンソール](../../administration/troubleshooting/postgresql.md#start-a-database-console)を起動します
1. 以下を実行します。

   ```sql
   SELECT relname as table,n_live_tup as rows FROM pg_stat_user_tables
   WHERE relname='ci_pipeline_messages' and n_live_tup>1500000;
   ```

1. クエリが`ci_pipeline_messages`のカウントを含む出力を返す場合、インスタンスはこの必須経由地点のしきい値を満たしています。`0 rows`を報告するインスタンスは、17.1へのアップグレード経由をスキップできます。

GitLab 17.1では、[バッチバックグラウンド移行](../background_migrations.md#batched-background-migrations)が導入され、`ci_pipeline_messages`テーブル内のすべてのレコードが[正しいパーティションキー](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/153391)を持つようにします。CIテーブルをパーティション分割すると、大量のCIデータを持つインスタンスのパフォーマンスが向上することが期待されます。

GitLab 17.2へのアップグレードでは、`Finalize`移行が実行され、17.1 のバックグラウンド移行が確実に完了するようにします。必要な場合は、アップグレード中に17.1の変更を同期的に実行します。

GitLab 17.2では、[外部キーデータベース制約も追加](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/158065)され、パーティション分割キーが入力されている必要があります。制約はGitLab 17.3へのアップグレードの一環として[検証されます](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/159571)。

17.1がアップグレードパスから省略された場合 (または17.1の移行が完了していない場合):

- アップグレードが完了するまで、影響を受けるインスタンスのダウンタイムが長くなります。
- 前方修正は安全です。
- 環境をより早く利用できるようにするために、Rakeタスクを使用して移行を実行できます。

  ```shell
  sudo gitlab-rake gitlab:background_migrations:finalize[BackfillPartitionIdCiPipelineMessage,ci_pipeline_messages,id,'[]']
  ```

すべてのデータベース移行が完了するまで、GitLabは使用できなくなる可能性が高く、部分的にアップグレードされたデータベーススキーマと実行中のSidekiqおよびPumaプロセス間の非互換性により、`500`エラーが生成されます。

Linuxパッケージ (Omnibus) またはDockerのアップグレードは、1時間後にタイムアウトして失敗する可能性があります。

```plaintext
FATAL: Mixlib::ShellOut::CommandTimeout: rails_migration[gitlab-rails]
[..]
Mixlib::ShellOut::CommandTimeout: Command timed out after 3600s:
```

これを修正するには:

1. 上記のRakeタスクを実行して、バッチ移行を完了します。
1. [タイムアウトした操作の残りを完了します](../package/package_troubleshooting.md#mixlibshelloutcommandtimeout-rails_migrationgitlab-rails--command-timed-out-after-3600s)。このプロセスの最後に、SidekiqとPumaが再起動すると、`500`エラーが修正されます。

アップグレードパスのこの条件付き経由に関するフィードバックは、[イシューで](https://gitlab.com/gitlab-org/gitlab/-/issues/503891)提供できます。

### Geoインストール17.1.0

- GitLab 16.11からGitLab 17.2までのバージョンでは、PostgreSQLインデックスが欠落していると、CPU使用率が高くなったり、ジョブアーティファクトの検証の進行が遅くなったり、Geoメトリクスのステータスアップデートが遅延したり、タイムアウトしたりする可能性があります。インデックスは GitLab 17.3で追加されました。インデックスを手動で追加するには、[Geoトラブルシューティング - ジョブアーティファクトの検証中にプライマリでCPU使用率が高くなる](../../administration/geo/replication/troubleshooting/common.md#high-cpu-usage-on-primary-during-object-verification)を参照してください。

  **影響を受けたリリース**:

  | マイナーリリース | パッチリリース | 修正リリース |
  | ----------------------- | ----------------------- | -------- |
  | 16.11                   |  すべて                    | なし     |
  | 17.0                    |  すべて                    | 17.0.7   |
  | 17.1                    |  すべて                    | 17.1.7   |
  | 17.2                    |  すべて                    | 17.2.5   |

- Geoレプリケーションが機能している場合でも、セカンダリサイトのGeoレプリケーション詳細ページが空に見えます。[イシュー468509](https://gitlab.com/gitlab-org/gitlab/-/issues/468509)を参照してください。既知の回避策はありません。このバグはGitLab 17.4で修正されました。

  **影響を受けたリリース**:

  | マイナーリリース | パッチリリース | 修正リリース |
  | ----------------------- | ----------------------- | -------- |
  | 16.11                   |  16.11.5 - 16.11.10     | なし     |
  | 17.0                    |  すべて                    | 17.0.7   |
  | 17.1                    |  すべて                    | 17.1.7   |
  | 17.2                    |  すべて                    | 17.2.5   |
  | 17.3                    |  すべて                    | 17.3.1   |

## 17.0.0

### Geoインストール17.0.0

- GitLab 16.11からGitLab 17.2までのバージョンでは、PostgreSQLインデックスが欠落していると、CPU使用率が高くなったり、ジョブアーティファクトの検証の進行が遅くなったり、Geoメトリクスのステータスアップデートが遅延したり、タイムアウトしたりする可能性があります。インデックスは GitLab 17.3で追加されました。インデックスを手動で追加するには、[Geoトラブルシューティング - ジョブアーティファクトの検証中にプライマリでCPU使用率が高くなる](../../administration/geo/replication/troubleshooting/common.md#high-cpu-usage-on-primary-during-object-verification)を参照してください。

  **影響を受けたリリース**:

  | マイナーリリース | パッチリリース | 修正リリース |
  | ----------------------- | ----------------------- | -------- |
  | 16.11                   |  すべて                    | なし     |
  | 17.0                    |  すべて                    | 17.0.7   |
  | 17.1                    |  すべて                    | 17.1.7   |
  | 17.2                    |  すべて                    | 17.2.5   |

- Geoレプリケーションが機能している場合でも、セカンダリサイトのGeoレプリケーション詳細ページが空に見えます。[イシュー468509](https://gitlab.com/gitlab-org/gitlab/-/issues/468509)を参照してください。既知の回避策はありません。このバグはGitLab 17.4で修正されました。

  **影響を受けたリリース**:

  | マイナーリリース | パッチリリース | 修正リリース |
  | ----------------------- | ----------------------- | -------- |
  | 16.11                   |  16.11.5 - 16.11.10     | なし     |
  | 17.0                    |  すべて                    | 17.0.7   |
  | 17.1                    |  すべて                    | 17.1.7   |
  | 17.2                    |  すべて                    | 17.2.5   |
  | 17.3                    |  すべて                    | 17.3.1   |
