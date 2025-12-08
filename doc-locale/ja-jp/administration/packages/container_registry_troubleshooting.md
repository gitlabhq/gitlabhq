---
stage: Package
group: Container Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: コンテナレジストリのトラブルシューティング
description: GitLabコンテナレジストリに関する一般的な問題をトラブルシューティングします。
---

特定の問題を調査する前に、次のトラブルシューティングの手順を試してください:

1. DockerクライアントとGitLabサーバーのシステムクロックが同期していることを確認します（NTPなど）。

1. S3でバックアップされたレジストリの場合は、IAMの権限とS3の認証情報（リージョンを含む）が正しいことを確認してください。詳細については、[IAMポリシーのサンプル](https://distribution.github.io/distribution/storage-drivers/s3/)を参照してください。

1. レジストリのログファイル（`/var/log/gitlab/registry/current`など）とGitLabの本番環境ログファイル（`/var/log/gitlab/gitlab-rails/production.log`など）のエラーを確認してください。

1. コンテナレジストリのNGINX設定ファイル（`/var/opt/gitlab/nginx/conf/gitlab-registry.conf`など）を確認して、どのポートがリクエストを受信しているかを確認します。

1. リクエストがコンテナレジストリに正しく転送されていることを検証します:

   ```shell
   curl --verbose --noproxy "*" https://<hostname>:<port>/v2/_catalog
   ```

   応答には、`Www-Authenticate: Bearer`と`service="container_registry"`を含む行が含まれている必要があります。次に例を示します:

   ```plaintext
   < HTTP/1.1 401 Unauthorized
   < Server: nginx
   < Date: Fri, 07 Mar 2025 08:24:43 GMT
   < Content-Type: application/json
   < Content-Length: 162
   < Connection: keep-alive
   < Docker-Distribution-Api-Version: registry/2.0
   < Www-Authenticate: Bearer realm="https://<hostname>/jwt/auth",service="container_registry",scope="registry:catalog:*"
   < X-Content-Type-Options: nosniff
   <
   {"errors":[{"code":"UNAUTHORIZED","message":"authentication required","detail":
   [{"Type":"registry","Class":"","Name":"catalog","ProjectPath":"","Action":"*"}]}]}
   * Connection #0 to host <hostname> left intact
   ```

## コンテナレジストリでの自己署名証明書の使用 {#using-self-signed-certificates-with-container-registry}

コンテナレジストリで自己署名証明書を使用している場合、次のようなCIジョブ中に問題が発生する可能性があります:

```plaintext
Error response from daemon: Get registry.example.com/v1/users/: x509: certificate signed by unknown authority
```

コマンドを実行するDockerデーモンは、認識された認証局によって署名された証明書を予期するため、上記のエラーが発生します。

GitLabは、すぐに使える自己署名証明書とコンテナレジストリの使用をサポートしていませんが、[自己署名証明書を信頼するようにDockerデーモンに指示](https://distribution.github.io/distribution/about/insecure/#use-self-signed-certificates)し、Dockerデーモンをマウントして、GitLab Runnerの`config.toml`ファイルで`privileged = false`を設定することで、それを機能させることができます。`privileged = true`の設定は、Dockerデーモンよりも優先されます:

```toml
  [runners.docker]
    image = "ruby:2.6"
    privileged = false
    volumes = ["/var/run/docker.sock:/var/run/docker.sock", "/cache"]
```

これに関する追加情報: [イシュー18239](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/18239)。

## Dockerログインの試行が次のエラーで失敗:「信頼されていないキーで署名されたトークン」 {#docker-login-attempt-fails-with-token-signed-by-untrusted-key}

[レジストリはGitLabに依存して認証情報を検証します](container_registry.md#container-registry-architecture)。レジストリが有効なログイン試行の認証に失敗すると、次のエラーメッセージが表示されます:

```shell
# docker login gitlab.company.com:4567
Username: user
Password:
Error response from daemon: login attempt to https://gitlab.company.com:4567/v2/ failed with status: 401 Unauthorized
```

さらに具体的には、これは`/var/log/gitlab/registry/current`ログファイルに表示されます:

```plaintext
level=info
msg="token signed by untrusted key with ID: "TOKE:NL6Q:7PW6:EXAM:PLET:OKEN:BG27:RCIB:D2S3:EXAM:PLET:OKEN""
level=warning msg="error authorizing context: invalid token" go.version=go1.12.7 http.request.host="gitlab.company.com:4567"
http.request.id=74613829-2655-4f96-8991-1c9fe33869b8 http.request.method=GET http.request.remoteaddr=10.72.11.20
http.request.uri="/v2/" http.request.useragent="docker/19.03.2 go/go1.12.8 git-commit/6a30dfc
kernel/3.10.0-693.2.2.el7.x86_64 os/linux arch/amd64 UpstreamClient(Docker-Client/19.03.2 \(linux\))"
```

（読みやすくするために改行を追加しました。）

GitLabは、レジストリの認証トークンを暗号化するために、証明書キーペアの2つの側のコンテンツを使用します。このメッセージは、それらのコンテンツが一致していないことを意味します。

使用中のファイルをチェックします:

- `grep -A6 'auth:' /var/opt/gitlab/registry/config.yml`

  ```yaml
  ## Container registry certificate
     auth:
       token:
         realm: https://gitlab.my.net/jwt/auth
         service: container_registry
         issuer: omnibus-gitlab-issuer
    -->  rootcertbundle: /var/opt/gitlab/registry/gitlab-registry.crt
         autoredirect: false
  ```

- `grep -A9 'Container Registry' /var/opt/gitlab/gitlab-rails/etc/gitlab.yml`

  ```yaml
  ## Container registry key
     registry:
       enabled: true
       host: gitlab.company.com
       port: 4567
       api_url: http://127.0.0.1:5000 # internal address to the registry, is used by GitLab to directly communicate with API
       path: /var/opt/gitlab/gitlab-rails/shared/registry
  -->  key: /var/opt/gitlab/gitlab-rails/etc/gitlab-registry.key
       issuer: omnibus-gitlab-issuer
       notification_secret:
  ```

これらの`openssl`コマンドの出力は、証明書-キーペアが一致することを証明するために一致する必要があります:

```shell
/opt/gitlab/embedded/bin/openssl x509 -noout -modulus -in /var/opt/gitlab/registry/gitlab-registry.crt | /opt/gitlab/embedded/bin/openssl sha256
/opt/gitlab/embedded/bin/openssl rsa -noout -modulus -in /var/opt/gitlab/gitlab-rails/etc/gitlab-registry.key | /opt/gitlab/embedded/bin/openssl sha256
```

2つの証明書が一致しない場合は、ファイルを削除して`gitlab-ctl reconfigure`を実行し、ペアを再生成します。ペアは、存在する場合、`/etc/gitlab/gitlab-secrets.json`の既存の値を使用して再作成されます。新しいペアを生成するには、`gitlab-ctl reconfigure`を実行する前に、`/etc/gitlab/gitlab-secrets.json`の`registry`セクションを削除します。

自動的に生成された自己署名ペアを独自の証明書でオーバーライドし、それらのコンテンツが一致していることを確認した場合は、`/etc/gitlab/gitlab-secrets.json`の「レジストリ」セクションを削除して、`gitlab-ctl reconfigure`を実行できます。

## 大きなイメージをプッシュするときのGitLabレジストリエラーを使用したAWS S3 {#aws-s3-with-the-gitlab-registry-error-when-pushing-large-images}

GitLabレジストリでAWS S3を使用している場合、大きなイメージをプッシュするときにエラーが発生する可能性があります。次のエラーについては、レジストリログファイルを参照してください:

```plaintext
level=error msg="response completed with error" err.code=unknown err.detail="unexpected EOF" err.message="unknown error"
```

エラーを解決するには、レジストリの設定で`chunksize`値を指定します。`25000000`（25 MB）から`50000000`（50 MB）の間の値から始めます。

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. `/etc/gitlab/gitlab.rb`を編集します: 

   ```ruby
   registry['storage'] = {
     's3' => {
       'accesskey' => 'AKIAKIAKI',
       'secretkey' => 'secret123',
       'bucket'    => 'gitlab-registry-bucket-AKIAKIAKI',
       'chunksize' => 25000000
     }
   }
   ```

1. ファイルを保存して、[GitLabを再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)し、変更を有効にします。

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

1. `config/gitlab.yml`を編集します: 

   ```yaml
   storage:
     s3:
       accesskey: 'AKIAKIAKI'
       secretkey: 'secret123'
       bucket: 'gitlab-registry-bucket-AKIAKIAKI'
       chunksize: 25000000
   ```

1. ファイルを保存して、[GitLabを再起動](../restart_gitlab.md#self-compiled-installations)し、変更を有効にします。

{{< /tab >}}

{{< /tabs >}}

## 古いDockerクライアントのサポート {#supporting-older-docker-clients}

GitLabに同梱されているDockerコンテナレジストリは、デフォルトでschema1マニフェストを無効にします。古いDockerクライアント（1.9以前）をまだ使用している場合は、イメージのプッシュ中にエラーが発生する可能性があります。詳細については、[issue 4145](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/4145)を参照してください。

下位互換性のために設定オプションを追加できます。

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. `/etc/gitlab/gitlab.rb`を編集します: 

   ```ruby
   registry['compatibility_schema1_enabled'] = true
   ```

1. ファイルを保存して、[GitLabを再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)し、変更を有効にします。

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

1. レジストリをデプロイしたときに作成したYAML設定ファイルを編集します。次のスニペットを追加します:

   ```yaml
   compatibility:
       schema1:
           enabled: true
   ```

1. 変更を反映するには、レジストリを再起動します。

{{< /tab >}}

{{< /tabs >}}

## Docker接続エラー {#docker-connection-error}

グループ名、プロジェクト名、またはブランチ名のいずれかに特殊文字が含まれている場合、Docker接続エラーが発生する可能性があります。特殊文字には次のものがあります:

- 先頭のアンダースコア
- 末尾のハイフン/ダッシュ
- 二重ハイフン/ダッシュ

これを回避するには、[グループパスを変更](../../user/group/manage.md#change-a-groups-path)するか、[プロジェクトパスを変更](../../user/project/working_with_projects.md#rename-a-repository)するか、ブランチ名を変更します。別のオプションとして、インスタンス全体でこのエラーを防ぐために[プッシュルール](../../user/project/repository/push_rules.md)を作成できます。

## イメージプッシュエラー {#image-push-errors}

`docker login`が成功した場合でも、Dockerイメージをプッシュするときに、再試行ループでスタックする可能性があります。

この問題は、通常、SSLがサードパーティのリバースプロキシにオフロードされるカスタムセットアップで、NGINXがヘッダーをレジストリに適切に転送していない場合に発生します。

詳細については、[NGINXプロキシ経由のDockerプッシュが32Bレイヤーの送信に失敗しました#970](https://github.com/docker/distribution/issues/970)を参照してください。

この問題を解決するには、レジストリで相対URLを有効にするようにNGINX設定を更新します:

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. `/etc/gitlab/gitlab.rb`を編集します: 

   ```ruby
   registry['env'] = {
     "REGISTRY_HTTP_RELATIVEURLS" => true
   }
   ```

1. ファイルを保存して、[GitLabを再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)し、変更を有効にします。

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

1. レジストリをデプロイしたときに作成したYAML設定ファイルを編集します。次のスニペットを追加します:

   ```yaml
   http:
       relativeurls: true
   ```

1. ファイルを保存して、[GitLabを再起動](../restart_gitlab.md#self-compiled-installations)し、変更を有効にします。

{{< /tab >}}

{{< tab title="Docker Compose" >}}

1. `docker-compose.yaml`ファイルを編集します:

   ```yaml
   GITLAB_OMNIBUS_CONFIG: |
     registry['env'] = {
       "REGISTRY_HTTP_RELATIVEURLS" => true
     }
   ```

1. 問題が解決しない場合は、両方のURLがHTTPSを使用していることを確認してください:

   ```yaml
   GITLAB_OMNIBUS_CONFIG: |
     external_url 'https://git.example.com'
     registry_external_url 'https://git.example.com:5050'
   ```

1. ファイルを保存して、コンテナを再起動します:

   ```shell
   sudo docker restart gitlab
   ```

{{< /tab >}}

{{< /tabs >}}

## レジストリデバッグサーバーの有効化 {#enable-the-registry-debug-server}

コンテナレジストリデバッグサーバーを使用して、問題を診断できます。デバッグエンドポイントは、メトリクスとヘルスを監視し、プロファイリングを実行できます。

{{< alert type="warning" >}}

デバッグエンドポイントから機密情報が利用できる場合があります。本番環境では、デバッグエンドポイントへのアクセスをロックダウンする必要があります。

{{< /alert >}}

オプションのデバッグサーバーは、`gitlab.rb`設定でレジストリデバッグアドレスを設定することで有効にできます。

```ruby
registry['debug_addr'] = "localhost:5001"
```

設定を追加したら、[GitLabを再設定する](../restart_gitlab.md#reconfigure-a-linux-package-installation)して変更を適用します。

cURLを使用して、デバッグサーバーからデバッグ出力をリクエストします:

```shell
curl "localhost:5001/debug/health"
curl "localhost:5001/debug/vars"
```

## レジストリデバッグログの有効化 {#enable-registry-debug-logs}

コンテナレジストリの問題のトラブルシューティングに役立つように、デバッグログを有効にできます。

{{< alert type="warning" >}}

デバッグログには、認証の詳細、トークン、リポジトリ情報などの機密情報が含まれている場合があります。デバッグログは必要な場合にのみ有効にし、トラブルシューティングが完了したら無効にします。

{{< /alert >}}

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. `/var/opt/gitlab/registry/config.yml`を編集します: 

   ```yaml
   level: debug
   ```

1. ファイルを保存して、レジストリを再起動します:

   ```shell
   sudo gitlab-ctl restart registry
   ```

この設定は一時的なものであり、`gitlab-ctl reconfigure`を実行すると破棄されます。

{{< /tab >}}

{{< tab title="Helmチャート（Kubernetes）" >}}

1. Helmの値をエクスポートします: 

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. `gitlab_values.yaml`を編集します: 

   ```yaml
   registry:
     log:
       level: debug
   ```

1. ファイルを保存して、新しい値を適用します: 

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab --namespace <namespace>
   ```

{{< /tab >}}

{{< /tabs >}}

### レジストリPrometheusメトリクスの有効化 {#enable-registry-prometheus-metrics}

デバッグサーバーが有効になっている場合は、Prometheusメトリクスを有効にすることもできます。このエンドポイントは、ほぼすべてのレジストリ操作に関連する非常に詳細なテレメトリを公開します。

```ruby
registry['debug'] = {
  'prometheus' => {
    'enabled' => true,
    'path' => '/metrics'
  }
}
```

cURLを使用して、Prometheusからデバッグ出力をリクエストします:

```shell
curl "localhost:5001/debug/metrics"
```

## 名前が空のタグ {#tags-with-an-empty-name}

[AWS DataSync](https://aws.amazon.com/datasync/)を使用してレジストリデータをS3バケットとの間でコピーする場合、空のメタデータオブジェクトが宛先バケット内の各コンテナリポジトリのルートパスに作成されます。これにより、レジストリは、そのようなファイルをGitLab UIとAPIに名前なしで表示されるタグとして解釈します。詳細については、[this issue](https://gitlab.com/gitlab-org/container-registry/-/issues/341)を参照してください。

これを修正するには、次の2つの方法があります:

- AWS CLI [`rm`コマンド](https://awscli.amazonaws.com/v2/documentation/api/latest/reference/s3/rm.html)を使用して、影響を受ける各リポジトリのルートから空のオブジェクトを削除します。末尾の`/`に特に注意し、`--recursive`オプションを使用しないようにしてください:

  ```shell
  aws s3 rm s3://<bucket>/docker/registry/v2/repositories/<path to repository>/
  ```

- AWS CLI [`sync`コマンド](https://awscli.amazonaws.com/v2/documentation/api/latest/reference/s3/sync.html)を使用して、レジストリデータを新しいバケットにコピーし、それを使用するようにレジストリを設定します。これにより、空のオブジェクトが残ります。

## 高度なトラブルシューティング {#advanced-troubleshooting}

具体的な例を使用して、S3セットアップの問題を診断する方法を説明します。

### クリーンアップポリシーの調査 {#investigate-a-cleanup-policy}

クリーンアップポリシーがタグを削除した理由または削除しなかった理由が不明な場合は、[Railsコンソール](../operations/rails_console.md)から以下のスクリプトを実行して、ポリシー行を1行ずつ実行します。これは、ポリシーの問題を診断するのに役立ちます。

```ruby
repo = ContainerRepository.find(<repository_id>)
policy = repo.project.container_expiration_policy

tags = repo.tags
tags.map(&:name)

tags.reject!(&:latest?)
tags.map(&:name)

regex_delete = ::Gitlab::UntrustedRegexp.new("\\A#{policy.name_regex}\\z")
regex_retain = ::Gitlab::UntrustedRegexp.new("\\A#{policy.name_regex_keep}\\z")

tags.select! { |tag| regex_delete.match?(tag.name) && !regex_retain.match?(tag.name) }

tags.map(&:name)

now = DateTime.current
tags.sort_by! { |tag| tag.created_at || now }.reverse! # Lengthy operation

tags = tags.drop(policy.keep_n)
tags.map(&:name)

older_than_timestamp = ChronicDuration.parse(policy.older_than).seconds.ago

tags.select! { |tag| tag.created_at && tag.created_at < older_than_timestamp }

tags.map(&:name)
```

- スクリプトは、削除するタグのリスト（`tags`）を作成します。
- `tags.map(&:name)`は、削除するタグのリストを印刷します。これは時間がかかる操作になる可能性があります。
- 各フィルターの後で、`tags`のリストをチェックして、破棄するタグが含まれているかどうかを確認します。

### プッシュ中の予期しない403エラー {#unexpected-403-error-during-push}

ユーザーがS3でバックアップされたレジストリを有効にしようとしました。`docker login`の手順はうまくいきました。ただし、イメージをプッシュすると、出力は次のようになります:

```plaintext
The push refers to a repository [s3-testing.myregistry.com:5050/root/docker-test/docker-image]
dc5e59c14160: Pushing [==================================================>] 14.85 kB
03c20c1a019a: Pushing [==================================================>] 2.048 kB
a08f14ef632e: Pushing [==================================================>] 2.048 kB
228950524c88: Pushing 2.048 kB
6a8ecde4cc03: Pushing [==>                                                ] 9.901 MB/205.7 MB
5f70bf18a086: Pushing 1.024 kB
737f40e80b7f: Waiting
82b57dbc5385: Waiting
19429b698a22: Waiting
9436069b92a3: Waiting
error parsing HTTP 403 response body: unexpected end of JSON input: ""
```

このエラーは、403がGitLab Railsアプリケーション、Dockerレジストリ、またはその他の場所から発生しているのかが不明確であるため、あいまいです。この場合、ログインが成功したことがわかっているため、クライアントとレジストリ間の通信を確認する必要があると考えられます。

Dockerクライアントとレジストリ間のREST APIは、[Dockerドキュメント](https://distribution.github.io/distribution/spec/api/)に記載されています。通常、Wiresharkまたはtcpdumpを使用してトラフィックをキャプチャし、何が間違っているかを確認します。ただし、Dockerクライアントとサーバー間のすべての通信がHTTPS経由で行われるため、秘密キーを知っていても、トラフィックをすばやく復号化するのは少し困難です。代わりに何ができますか？

1つの方法は、[安全でないレジストリ](https://distribution.github.io/distribution/about/insecure/)をセットアップしてHTTPSを無効にすることです。これにより、セキュリティホールが発生する可能性があり、ローカルテストでのみ推奨されます。本番環境があり、これを行うことができない、またはしたくない場合は、別の方法があります。Man-in-the-Middleプロキシを表すmitmproxyを使用します。

### mitmproxy {#mitmproxy}

[mitmproxy](https://mitmproxy.org/)を使用すると、クライアントとサーバーの間にプロキシを配置して、すべてのトラフィックを検査できます。1つの問題は、システムがこれを機能させるためにmitmproxy SSL証明書を信頼する必要があることです。

以下のインストール手順では、Ubuntuを実行していることを前提としています:

1. [mitmproxyをインストール](https://docs.mitmproxy.org/stable/overview-installation/)します。
1. `mitmproxy --port 9000`を実行して、証明書を生成します。<kbd>Control</kbd>-<kbd>C</kbd>を入力して終了します。
1. `~/.mitmproxy`から証明書をシステムにインストールします:

   ```shell
   sudo cp ~/.mitmproxy/mitmproxy-ca-cert.pem /usr/local/share/ca-certificates/mitmproxy-ca-cert.crt
   sudo update-ca-certificates
   ```

成功すると、証明書が追加されたことを示す出力が表示されます:

```shell
Updating certificates in /etc/ssl/certs... 1 added, 0 removed; done.
Running hooks in /etc/ca-certificates/update.d....done.
```

証明書が正しくインストールされていることを検証するには、次を実行します:

```shell
mitmproxy --listen-port 9000
```

このコマンドは、ポート`9000`でmitmproxyを実行します。別のウィンドウで、次を実行します:

```shell
curl --proxy "http://localhost:9000" "https://httpbin.org/status/200"
```

すべてが正しく設定されている場合、情報はmitmproxyウィンドウに表示され、cURLコマンドによってエラーは生成されません。

### プロキシを使用したDockerデーモンの実行 {#running-the-docker-daemon-with-a-proxy}

Dockerがプロキシを介して接続するには、適切な環境変数を使用してDockerデーモンを起動する必要があります。最も簡単な方法は、Dockerをシャットダウンし（たとえば`sudo initctl stop docker`）、Dockerを手動で実行することです。rootとして、次を実行します:

```shell
export HTTP_PROXY="http://localhost:9000"
export HTTPS_PROXY="http://localhost:9000"
docker daemon --debug # or dockerd --debug
```

このコマンドは、Dockerデーモンを起動し、すべての接続をmitmproxy経由でプロキシします。

### Dockerクライアントの実行 {#running-the-docker-client}

mitmproxyとDockerが実行されたので、サインインしてコンテナイメージをプッシュすることができます。これを行うには、rootとして実行する必要がある場合があります。次に例を示します:

```shell
docker login example.s3.amazonaws.com:5050
docker push example.s3.amazonaws.com:5050/root/docker-test/docker-image
```

前の例では、mitmproxyウィンドウに次のトレースが表示されます:

```plaintext
PUT https://example.s3.amazonaws.com:4567/v2/root/docker-test/blobs/uploads/(UUID)/(QUERYSTRING)
    ← 201 text/plain [no content] 661ms
HEAD https://example.s3.amazonaws.com:4567/v2/root/docker-test/blobs/sha256:(SHA)
    ← 307 application/octet-stream [no content] 93ms
HEAD https://example.s3.amazonaws.com:4567/v2/root/docker-test/blobs/sha256:(SHA)
    ← 307 application/octet-stream [no content] 101ms
HEAD https://example.s3.amazonaws.com:4567/v2/root/docker-test/blobs/sha256:(SHA)
    ← 307 application/octet-stream [no content] 87ms
HEAD https://amazonaws.example.com/docker/registry/vs/blobs/sha256/dd/(UUID)/data(QUERYSTRING)
    ← 403 application/xml [no content] 80ms
HEAD https://amazonaws.example.com/docker/registry/vs/blobs/sha256/dd/(UUID)/data(QUERYSTRING)
    ← 403 application/xml [no content] 62ms
```

この出力は以下を示しています:

- 最初のPUTリクエストは、`201`ステータスコードで正常に完了しました。
- `201`は、クライアントをAmazon S3バケットにリダイレクトしました。
- AWSバケットへのHEADリクエストは、`403 Unauthorized`をレポートしました。

これはどういう意味ですか？これは、S3ユーザーが[HEADリクエストを実行するための適切な権限](https://docs.aws.amazon.com/AmazonS3/latest/API/API_HeadObject.html)を持っていないことを強く示唆しています。解決策: [IAM権限をもう一度確認](https://distribution.github.io/distribution/storage-drivers/s3/)してください。適切な権限が設定されると、エラーは解消されました。

## 不足している`gitlab-registry.key`はコンテナリポジトリの削除を妨げます {#missing-gitlab-registrykey-prevents-container-repository-deletion}

GitLabインスタンスのコンテナレジストリを無効にし、コンテナリポジトリがあるプロジェクトを削除しようとすると、次のエラーが発生します:

```plaintext
Errno::ENOENT: No such file or directory @ rb_sysopen - /var/opt/gitlab/gitlab-rails/etc/gitlab-registry.key
```

この場合は、次の手順に従ってください:

1. `gitlab.rb`で、コンテナレジストリのインスタンス全体の設定を一時的に有効にします:

   ```ruby
   gitlab_rails['registry_enabled'] = true
   ```

1. ファイルを保存して、[GitLabを再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)し、変更を有効にします。
1. 削除をもう一度試してください。

一般的な方法を使用してもリポジトリの削除ができない場合は、[GitLab Railsコンソール](../operations/rails_console.md)を使用して、プロジェクトを強制的に削除できます:

```ruby
# Path to the project you'd like to remove
prj = Project.find_by_full_path(<project_path>)

# The following will delete the project's container registry, so be sure to double-check the path beforehand!
if prj.has_container_registry_tags?
  prj.container_repositories.each { |p| p.destroy }
end
```

## レジストリサービスがIPv4ではなくIPv6アドレスをリッスンする {#registry-service-listens-on-ipv6-address-instead-of-ipv4}

GitLabサーバーの`localhost`ホスト名がIPv6ループバックアドレス（`::1`）に解決され、GitLabがレジストリサービスがIPv4ループバックアドレス（`127.0.0.1`）で使用可能になることを予期している場合、次のエラーが表示されることがあります:

```plaintext
request: "GET /v2/ HTTP/1.1", upstream: "http://[::1]:5000/v2/", host: "registry.example.com:5005"
[error] 1201#0: *13442797 connect() failed (111: Connection refused) while connecting to upstream, client: x.x.x.x, server: registry.example.com, request: "GET /v2/<path> HTTP/1.1", upstream: "http://[::1]:5000/v2/<path>", host: "registry.example.com:5005"
```

エラーを修正するには、`/etc/gitlab/gitlab.rb`の`registry['registry_http_addr']`をIPv4アドレスに変更します。次に例を示します:

```ruby
registry['registry_http_addr'] = "127.0.0.1:5000"
```

詳細については、[issue 5449](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/5449)を参照してください。

## Google Cloud Storage（GCS）でのプッシュの失敗と高いCPU使用率 {#push-failures-and-high-cpu-usage-with-google-cloud-storage-gcs}

バックエンドとしてGCSを使用するレジストリにコンテナイメージをプッシュすると、`502 Bad Gateway`エラーが発生する可能性があります。レジストリでは、大きなイメージをプッシュするときにCPU使用率が急上昇することもあります。

この問題は、レジストリがHTTP/2プロトコルを使用してGCSと通信するときに発生します。

回避策は、`GODEBUG`環境変数を`http2client=0`に設定して、レジストリデプロイメントでHTTP/2を無効にすることです。

詳細については、[issue 1425](https://gitlab.com/gitlab-org/container-registry/-/issues/1425)を参照してください。
