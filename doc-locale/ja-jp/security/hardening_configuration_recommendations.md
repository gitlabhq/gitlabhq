---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 強化 - 設定の推奨事項
---

一般的な強化のガイドラインは、[メインの強化ドキュメント](hardening.md)に概説されています。

GitLabのインスタンスに関するいくつかの強化の推奨事項には、追加サービスや設定ファイルによる制御が含まれます。リマインダーとして、設定ファイルに変更を加える際は常に、編集する前にバックアップコピーを作成してください。さらに、多くの変更を加える場合は、すべての変更を一度に行わず、すべてが機能することを確認するために各変更後にテストすることをお勧めします。

## NGINX {#nginx}

NGINXは、GitLabインスタンスにアクセスするために使用されるWebインターフェースを提供するために使用されます。NGINXはGitLabに制御され統合されているため、調整には`/etc/gitlab/gitlab.rb`ファイルを変更します。以下は、NGINX自体のセキュリティ向上に役立ついくつかの推奨事項です:

1. [Diffie-Hellmanキー](https://nginx.org/en/docs/http/ngx_http_ssl_module.html#ssl_dhparam)を作成します:

   ```shell
   sudo openssl dhparam -out /etc/gitlab/ssl/dhparam.pem 4096
   ```

1. `/etc/gitlab/gitlab.rb`を編集し、以下を追加します:

   ```ruby
   #
   # Only strong ciphers are used
   #
   nginx['ssl_ciphers'] = "ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:TLS_AES_256_GCM_SHA384:TLS_AES_128_GCM_SHA256"
   #
   # Follow preferred ciphers and the order listed as preference
   #
   nginx['ssl_prefer_server_ciphers'] = "on"
   #
   # Only allow TLSv1.2 and TLSv1.3
   #
   nginx['ssl_protocols'] = "TLSv1.2 TLSv1.3"

   ##! **Recommended in: https://nginx.org/en/docs/http/ngx_http_ssl_module.html**
   nginx['ssl_session_cache'] = "builtin:1000 shared:SSL:10m"

   ##! **Default according to https://nginx.org/en/docs/http/ngx_http_ssl_module.html**
   nginx['ssl_session_timeout'] = "5m"

   # Should prevent logjam attack etc
   nginx['ssl_dhparam'] = "/etc/gitlab/ssl/dhparam.pem" # changed from nil

   # Turn off session ticket reuse
   nginx['ssl_session_tickets'] = "off"
   # Pick our own curve instead of what openssl hands us
   nginx['ssl_ecdh_curve'] = "secp384r1"
   ```

1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## Consul {#consul}

ConsulはGitLab環境に統合でき、大規模なデプロイ向けです。一般的に、ユーザーが1000人未満のセルフマネージドおよびスタンドアロンのデプロイでは、Consulは不要な場合があります。必要に応じて、まず[Consulに関するドキュメント](../administration/consul.md)を確認し、さらに重要なこととして、通信中に暗号化が使用されていることを確認してください。Consulに関するより詳細な情報については、[HashiCorpのウェブサイト](https://developer.hashicorp.com/consul/docs)にアクセスしてその仕組みを理解し、[暗号化セキュリティ](https://developer.hashicorp.com/consul/docs/security/encryption)に関する情報を確認してください。

## 環境変数 {#environment-variables}

セルフマネージドシステムでは、複数の[環境変数](https://docs.gitlab.com/omnibus/settings/environment-variables/)をカスタマイズできます。セキュリティの観点から活用すべき主な環境変数は、インストールプロセス中の`GITLAB_ROOT_PASSWORD`です。インターネットに公開されたIPアドレスを持つセルフマネージドシステムをインストールする場合は、パスワードが強力なものに設定されていることを確認してください。歴史的に見ると、GitLabであろうと他のアプリケーションであろうと、あらゆる種類の公開サービスを設定すると、システムが発見され次第、日和見的な攻撃が発生することが示されています。そのため、強化プロセスはインストール中に開始する必要があります。

[オペレーティングシステムの推奨事項](hardening_operating_system_recommendations.md)に記載されているように、理想的にはGitLabのインストールが開始される前にファイアウォールルールがすでに設定されているべきですが、インストール前に`GITLAB_ROOT_PASSWORD`を通じて安全なパスワードを設定する必要があります。

## Gitプロトコル {#git-protocols}

認証されたユーザーのみがGitアクセスにSSHを使用するようにするには、`/etc/ssh/sshd_config`ファイルに以下を追加します:

```shell
# Ensure only authorized users are using Git
AcceptEnv GIT_PROTOCOL
```

これにより、ユーザーはSSH経由で`git`操作を実行できる有効なGitLabアカウントを持っていない限り、SSHを使用してプロジェクトをプルダウンできないようになります。詳細については、[Gitプロトコルの設定](../administration/git_protocol.md)を参照してください。

## 受信メール {#incoming-email}

GitLabセルフマネージドを設定して、GitLabインスタンスに登録されたユーザーがコメントやイシュー、マージリクエストを作成するために受信メールを使用できるようにすることができます。強化された環境では、外部からの情報送信を伴うため、この機能を設定すべきではありません。

この機能が必要な場合は、最大のセキュリティを確保するために、[受信メールドキュメント](../administration/incoming_email.md)の指示に従い、以下の推奨事項を考慮してください:

- インスタンスへの受信メール専用のメールアドレスを割り当ててください。
- [メールサブアドレス](../administration/incoming_email.md)を使用します。
- ユーザーがメールを送信するために使用するメールアカウントでは、多要素認証（MFA）が必須であり、有効になっている必要があります。
- 特にPostfixの場合、[Postfixの受信メールドキュメントのセットアップ](../administration/reply_by_email_postfix_setup.md)に従ってください。

## Redisレプリケーションとフェイルオーバー {#redis-replication-and-failover}

RedisはLinuxパッケージのインストールにおいてレプリケーションとフェイルオーバーに使用され、スケーリングにその機能が必要な場合に設定できます。これにより、Redis用にTCPポート`6379`、Sentinel用に`26379`が開かれることに留意してください。[レプリケーションとフェイルオーバーのドキュメント](../administration/redis/replication_and_failover.md)に従って、すべてのノードのIPアドレスをメモし、他のノードがこれらの特定のポートにのみアクセスを許可するファイアウォールルールをノード間に設定してください。

## Sidekiq設定 {#sidekiq-configuration}

[外部Sidekiqの設定に関する指示](../administration/sidekiq/_index.md)には、IP範囲を設定するための多くの参照があります。[HTTPSを設定](../administration/sidekiq/_index.md#enable-https)し、それらのIPアドレスをSidekiqが通信する特定のシステムに制限することを検討する必要があります。オペレーティングシステムレベルでファイアウォールルールを調整する必要がある場合もあります。

## メールのS/MIME署名 {#smime-signing-of-email}

GitLabインスタンスがユーザーへのメール通知送信用に設定されている場合、受信者がメールが正当であることを確認できるよう、S/MIME署名を設定します。[送信メールの署名](../administration/smime_signing_email.md)に関する指示に従ってください。

## コンテナレジストリ {#container-registry}

Lets Encryptが設定されている場合、コンテナレジストリはデフォルトで有効になります。これにより、プロジェクトは独自のDockerイメージを保存できます。[コンテナレジストリ](../administration/packages/container_registry.md)の設定に関する指示に従い、新規プロジェクトでの自動有効化の制限や、コンテナレジストリ全体の無効化などの操作を実行できます。アクセスを許可するためにファイアウォールルールを調整する必要がある場合があります。完全にスタンドアロンのシステムの場合は、コンテナレジストリへのアクセスをlocalhostのみに制限する必要があります。使用されるポートとその設定の具体的な例もドキュメントに含まれています。
