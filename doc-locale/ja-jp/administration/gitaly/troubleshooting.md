---
stage: Data Access
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Gitalyのトラブルシューティング
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

次のセクションでは、Gitalyエラーに対する考えられる解決策を示します。

[Gitalyタイムアウト](../settings/gitaly_timeouts.md)設定、および[`gitaly/current`ファイルの解析](../logs/log_parsing.md#parsing-gitalycurrent)に関するアドバイスも参照してください。

## スタンドアロンGitalyサーバーを使用する場合は、バージョンを確認してください {#check-versions-when-using-standalone-gitaly-servers}

スタンドアロンGitalyサーバーを使用する場合は、完全な互換性を確保するために、GitLabと同じバージョンであることを確認する必要があります:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **概要** > **Gitalyサーバー**を選択します。
1. すべてのGitalyサーバーが最新であることを示していることを確認します。

## リポジトリストレージリソースの詳細を検索します {#find-storage-resource-details}

Gitalyストレージで使用可能なスペースと使用済みのスペースを判断するには、[Railsコンソール](../operations/rails_console.md#starting-a-rails-console-session)で次のコマンドを実行します:

```ruby
Gitlab::GitalyClient::ServerService.new("default").storage_disk_statistics
# For Gitaly Cluster (Praefect)
Gitlab::GitalyClient::ServerService.new("<storage name>").disk_statistics
```

## `gitaly-debug`を使用する {#use-gitaly-debug}

`gitaly-debug`コマンドは、GitalyおよびGitのパフォーマンスに関する「本番環境デバッグ」ツールを提供します。これは、本番環境のエンジニアとサポートエンジニアがGitalyのパフォーマンスの問題を調査するのに役立つことを目的としています。

サポートされているサブコマンドの一覧については、`gitaly-debug`のヘルプページを参照してください:

```shell
gitaly-debug -h
```

## トラブルシューティングにGitが必要な場合は`gitaly git`を使用してください {#use-gitaly-git-when-git-is-required-for-troubleshooting}

`gitaly git`を使用して、デバッグまたはテストの目的で、Gitalyと同じGit実行環境を使用してGitコマンドを実行します。`gitaly git`は、バージョンの互換性を確保するための推奨される方法です。

`gitaly git`は、すべての引数を基になるGit呼び出しに渡し、Gitがサポートするすべての形式の入力をサポートします。`gitaly git`を使用するには、次を実行します:

```shell
sudo -u git -- /opt/gitlab/embedded/bin/gitaly git <git-command>
```

たとえば、リポジトリの作業ディレクトリ内のLinuxパッケージのインスタンスで、Gitalyを介して`git ls-tree`を実行するには、次のようにします:

```shell
sudo -u git -- /opt/gitlab/embedded/bin/gitaly git ls-tree --name-status HEAD
```

## コミット、プッシュ、およびクローンは401を返します {#commits-pushes-and-clones-return-a-401}

```plaintext
remote: GitLab: 401 Unauthorized
```

`gitlab-secrets.json`ファイルをGitLabアプリケーションノードと同期する必要があります。

## 500エラーと`fetching folder content`エラーがリポジトリページに表示される {#500-and-fetching-folder-content-errors-on-repository-pages}

`Fetching folder content`エラー（場合によっては`500`エラー）は、GitLabとGitaly間の接続の問題を示しています。詳細については、[クライアント側のgRPCログ記録](#client-side-grpc-logs)を参照してください。

## クライアント側のgRPCログ記録 {#client-side-grpc-logs}

Gitalyは、[gRPC](https://grpc.io/) RPCフレームワークを使用します。Ruby gRPCクライアントには独自のログファイルがあり、Gitalyエラーが発生した場合に役立つ情報が含まれている場合があります。`GRPC_LOG_LEVEL`環境変数を使用して、gRPCクライアントのログレベルを制御できます。デフォルトレベルは`WARN`です。

次のコマンドでgRPCトレースを実行できます:

```shell
sudo GRPC_TRACE=all GRPC_VERBOSITY=DEBUG gitlab-rake gitlab:gitaly:check
```

このコマンドが`failed to connect to all addresses`エラーで失敗する場合は、SSLまたはTLSの問題を確認してください:

```shell
/opt/gitlab/embedded/bin/openssl s_client -connect <gitaly-ipaddress>:<port> -verify_return_error
```

`Verify return code`フィールドが[既知のLinuxパッケージインストール設定の問題](https://docs.gitlab.com/omnibus/settings/ssl/)を示しているかどうかを確認します。

`openssl`は成功したが、`gitlab-rake gitlab:gitaly:check`は失敗した場合は、Gitalyの[証明書の要件](tls_support.md#certificate-requirements)を確認してください。

## サーバー側のgRPCログ記録 {#server-side-grpc-logs}

gRPCトレーシングは、`GODEBUG=http2debug`環境変数を使用して、Gitaly自体で有効にすることもできます。Linuxパッケージインストールでこれを設定するには、次のようにします:

1. 次の内容を`gitlab.rb`ファイルに追加します:

   ```ruby
   gitaly['env'] = {
     "GODEBUG=http2debug" => "2"
   }
   ```

1. GitLabを[再構成](../restart_gitlab.md#reconfigure-a-linux-package-installation)します。

## GitプロセスとRPCの関連付け {#correlating-git-processes-with-rpcs}

特定のGitプロセスを作成したGitaly RPCを特定する必要がある場合があります。

これを行う1つの方法は、`DEBUG`ロギングを使用することです。ただし、これを事前に有効にする必要があり、生成されるログは詳細です。

この関連付けを行うための軽量な方法は、Gitプロセスの実行環境（その`PID`を使用）を調べて、`CORRELATION_ID`変数を確認することです:

```shell
PID=<Git process ID>
sudo cat /proc/$PID/environ | tr '\0' '\n' | grep ^CORRELATION_ID=
```

この方法は`git cat-file`プロセスでは信頼性がありません。これは、Gitalyが内部的にそれらをRPC間でプールし、再利用するためです。

## リポジトリの変更が`401 Unauthorized`エラーで失敗する {#repository-changes-fail-with-a-401-unauthorized-error}

Gitalyを独自のサーバーで実行し、次の条件に気付いた場合:

- ユーザーは、SSHとHTTPSの両方を使用して、リポジトリを正常に複製およびフェッチできます。
- ユーザーはリポジトリにプッシュできないか、Web UIで変更を加えようとすると、`401 Unauthorized`メッセージが表示されます。

Gitalyクライアントに認証できないのは、[間違ったシークレットファイル](configure_gitaly.md#configure-gitaly-servers)があるためです。

以下がすべて当てはまることを確認してください:

- ユーザーがこのGitalyサーバー上のリポジトリに対して`git push`プッシュを実行すると、`401 Unauthorized`エラーで失敗します:

  ```shell
  remote: GitLab: 401 Unauthorized
  To <REMOTE_URL>
  ! [remote rejected] branch-name -> branch-name (pre-receive hook declined)
  error: failed to push some refs to '<REMOTE_URL>'
  ```

- ユーザーがGitLab UIを使用してリポジトリからファイルを追加または変更すると、すぐに赤い`401 Unauthorized`バナーが表示されて失敗します。
- 新しいプロジェクトを作成し、[Readmeで初期化](../../user/project/_index.md#create-a-blank-project)すると、プロジェクトは正常に作成されますが、Readmeは作成されません。
- Gitalyクライアントで[ログをテールする](https://docs.gitlab.com/omnibus/settings/logs.html#tail-logs-in-a-console-on-the-server)ときにエラーを再現すると、`/api/v4/internal/allowed`エンドポイントに到達すると`401`エラーが発生します。

  ```shell
  # api_json.log
  {
    "time": "2019-07-18T00:30:14.967Z",
    "severity": "INFO",
    "duration": 0.57,
    "db": 0,
    "view": 0.57,
    "status": 401,
    "method": "POST",
    "path": "\/api\/v4\/internal\/allowed",
    "params": [
      {
        "key": "action",
        "value": "git-receive-pack"
      },
      {
        "key": "changes",
        "value": "REDACTED"
      },
      {
        "key": "gl_repository",
        "value": "REDACTED"
      },
      {
        "key": "project",
        "value": "\/path\/to\/project.git"
      },
      {
        "key": "protocol",
        "value": "web"
      },
      {
        "key": "env",
        "value": "{\"GIT_ALTERNATE_OBJECT_DIRECTORIES\":[],\"GIT_ALTERNATE_OBJECT_DIRECTORIES_RELATIVE\":[],\"GIT_OBJECT_DIRECTORY\":null,\"GIT_OBJECT_DIRECTORY_RELATIVE\":null}"
      },
      {
        "key": "user_id",
        "value": "2"
      },
      {
        "key": "secret_token",
        "value": "[FILTERED]"
      }
    ],
    "host": "gitlab.example.com",
    "ip": "REDACTED",
    "ua": "Ruby",
    "route": "\/api\/:version\/internal\/allowed",
    "queue_duration": 4.24,
    "gitaly_calls": 0,
    "gitaly_duration": 0,
    "correlation_id": "XPUZqTukaP3"
  }

  # nginx_access.log
  [IP] - - [18/Jul/2019:00:30:14 +0000] "POST /api/v4/internal/allowed HTTP/1.1" 401 30 "" "Ruby"
  ```

この問題を解決するには、Gitalyサーバー上の[`gitlab-secrets.json`ファイル](configure_gitaly.md#configure-gitaly-servers)が、Gitalyクライアント上のファイルと一致することを確認します。一致しない場合は、Gitalyサーバー上のシークレットファイルをGitalyクライアントと一致するように更新してから、[設定を再構成](../restart_gitlab.md#reconfigure-a-linux-package-installation)します。

`gitlab-secrets.json`ファイルがすべてのGitalyサーバーとクライアントで同じであることを確認した場合、アプリケーションはこのシークレットを別のファイルからフェッチしている可能性があります。Gitalyサーバーの`config.toml file`は、使用中のシークレットファイルを示しています。

## リポジトリのプッシュが`401 Unauthorized`と`JWT::VerificationError`で失敗する {#repository-pushes-fail-with-401-unauthorized-and-jwtverificationerror}

`git push`を試みるときに、次のことがわかります:

- `401 Unauthorized`エラー。
- サーバーログの次の内容:

  ```json
  {
    ...
    "exception.class":"JWT::VerificationError",
    "exception.message":"Signature verification raised",
    ...
  }
  ```

このエラーの組み合わせは、GitLabサーバーがGitLab 15.5以降にアップグレードされたが、Gitalyがまだアップグレードされていない場合に発生します。

GitLab 15.5以降では、[共有シークレットの代わりにJWTトークンを使用してGitLab Shellで認証します](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/86148)。GitLabサーバーをアップグレードする前に、[外部Gitalyサーバーをアップグレード](../../update/plan_your_upgrade.md#upgrades-for-optional-features)する必要があります。

## リポジトリのプッシュが`deny updating a hidden ref`エラーで失敗する {#repository-pushes-fail-with-a-deny-updating-a-hidden-ref-error}

Gitalyには、ユーザーが更新することを許可されていない、読み取り専用の内部GitLab参照があります。`git push --mirror`で内部参照を更新しようとすると、Gitは拒否エラー`deny updating a hidden ref`を返します。

次の参照は読み取り専用です:

- refs/environments/
- refs/keep-around/
- refs/merge-requests/
- refs/pipelines/

ブランチとタグ付けのみをミラープッシュし、保護されたrefsのミラープッシュを試行しないようにするには、次を実行します:

```shell
git push --force-with-lease origin 'refs/heads/*:refs/heads/*' 'refs/tags/*:refs/tags/*'
```

管理者がプッシュするその他のネームスペースは、追加の[ref仕様](https://git-scm.com/docs/git-push#_options)を介してそこにも含めることができます。

## コマンドラインツールがGitalyに接続できない {#command-line-tools-cannot-connect-to-gitaly}

次の場合、gRPCはGitalyサーバーに到達できません:

- コマンドラインツールを使用してGitalyサーバーに接続できません。
- 特定のアクションを実行すると、`14: Connect Failed`エラーメッセージが表示されます。

TCPを使用してGitalyに到達できることを確認します:

```shell
sudo gitlab-rake gitlab:tcp_check[GITALY_SERVER_IP,GITALY_LISTEN_PORT]
```

TCP接続の場合:

- 失敗した場合は、ネットワーク設定とファイアウォールルールを確認してください。
- 成功した場合は、ネットワーキングとファイアウォールルールは正しいです。

Bashなどのコマンドライン環境でプロキシサーバーを使用している場合、これらがgRPCトラフィックに干渉する可能性があります。

Bashまたは互換性のあるコマンドライン環境を使用している場合は、次のコマンドを実行して、プロキシサーバーが設定されているかどうかを判断します:

```shell
echo $http_proxy
echo $https_proxy
```

これらの変数のいずれかに値がある場合、Gitaly CLI接続は、Gitalyに接続できないプロキシを介してルーティングされている可能性があります。

プロキシ設定を削除するには、次のコマンドを実行します（どの変数に値があるかによって異なります）:

```shell
unset http_proxy
unset https_proxy
```

## リポジトリへのアクセス時にGitalyログまたはPraefectログに表示されるアクセス許可拒否エラー {#permission-denied-errors-appearing-in-gitaly-or-praefect-logs-when-accessing-repositories}

GitalyログおよびPraefectログに次の内容が表示される場合があります:

```shell
{
  ...
  "error":"rpc error: code = PermissionDenied desc = permission denied: token has expired",
  "grpc.code":"PermissionDenied",
  "grpc.meta.client_name":"gitlab-web",
  "grpc.request.fullMethod":"/gitaly.ServerService/ServerInfo",
  "level":"warning",
  "msg":"finished unary call with code PermissionDenied",
  ...
}
```

ログ内のこの情報は、gRPC呼び出しの[エラー応答コード](https://grpc.github.io/grpc/core/md_doc_statuscodes.html)です。

このエラーが発生した場合（[Gitaly認証トークンが正しくセットアップされている](praefect/troubleshooting.md#praefect-errors-in-logs)場合でも）、Gitalyサーバーで[クロックドリフト](https://en.wikipedia.org/wiki/Clock_drift)が発生している可能性があります。Gitalyに送信される認証トークンにはタイムスタンプが含まれています。有効と見なされるには、Gitalyは、そのタイムスタンプがGitalyサーバー時間の60秒以内であることを要求します。

Gitalyクライアントとサーバーが同期されていることを確認し、ネットワークタイムプロトコル（NTP）タイムサーバーを使用してそれらを同期された状態に保ちます。

## 設定を再構成した後、Gitalyが新しいアドレスをリッスンしない {#gitaly-not-listening-on-new-address-after-reconfiguring}

`gitaly['configuration'][:listen_addr]`または`gitaly['configuration'][:prometheus_listen_addr]`の値を更新すると、`sudo gitlab-ctl reconfigure`の後でも、Gitalyは古いアドレスでリッスンし続ける場合があります。

これが発生した場合は、`sudo gitlab-ctl restart`を実行して問題を解決します。[この問題](https://gitlab.com/gitlab-org/gitaly/-/issues/2521)は解決されているため、これは不要になっているはずです。

## ヘルスチェックの警告 {#health-check-warnings}

`/var/log/gitlab/praefect/current`の次の警告は無視できます。

```plaintext
"error":"full method name not found: /grpc.health.v1.Health/Check",
"msg":"error when looking up method info"
```

## ファイルが見つからないエラー {#file-not-found-errors}

`/var/log/gitlab/gitaly/current`の次のエラーは無視できます。これらは、GitLab Railsアプリケーションが、リポジトリに存在しない特定のファイルを確認することによって発生します。

```plaintext
"error":"not found: .gitlab/route-map.yml"
"error":"not found: Dockerfile"
"error":"not found: .gitlab-ci.yml"
```

## Dynatraceが有効になっていると、Gitのプッシュが遅くなる {#git-pushes-are-slow-when-dynatrace-is-enabled}

Dynatraceは、`sudo -u git -- /opt/gitlab/embedded/bin/gitaly-hooks`参照トランザクションフックを起動およびシャットダウンするのに数秒かかるようにする可能性があります。`gitaly-hooks`は、ユーザーがプッシュするときに2回実行されるため、大幅な遅延が発生します。

Dynatraceが有効になっているときにGitのプッシュが遅すぎる場合は、Dynatraceを無効にします。

## `gitaly check`が`401`ステータスコードで失敗する {#gitaly-check-fails-with-401-status-code}

Gitalyが内部GitLab APIにアクセスできない場合、`gitaly check`が`401`ステータスコードで失敗する可能性があります。

これを解決する1つの方法は、`gitlab_rails['internal_api_url']`で`gitlab.rb`に設定されているGitLab内部API API URLのエントリが正しいことを確認することです。

## Gitaly TLSを使用している場合、新しいマージリクエストの変更（差分）が読み込まれない {#changes-diffs-dont-load-for-new-merge-requests-when-using-gitaly-tls}

[TLSを使用したGitaly](tls_support.md)を有効にした後、新しいマージリクエストの変更（差分）が生成されず、GitLabに次のメッセージが表示されます:

```plaintext
Building your merge request... This page will update when the build is complete
```

Gitalyは、一部の操作を完了するために、それ自体に接続できる必要があります。GitalyサーバーがGitaly証明書を信頼していない場合、マージリクエストの差分は生成できません。

Gitalyがそれ自体に接続できない場合は、次のメッセージのような[Gitalyログ](../logs/_index.md#gitaly-logs)にメッセージが表示されます:

```json
{
   "level":"warning",
   "msg":"[core] [Channel #16 SubChannel #17] grpc: addrConn.createTransport failed to connect to {Addr: \"ext-gitaly.example.com:9999\", ServerName: \"ext-gitaly.example.com:9999\", }. Err: connection error: desc = \"transport: authentication handshake failed: tls: failed to verify certificate: x509: certificate signed by unknown authority\"",
   "pid":820,
   "system":"system",
   "time":"2023-11-06T05:40:04.169Z"
}
{
   "level":"info",
   "msg":"[core] [Server #3] grpc: Server.Serve failed to create ServerTransport: connection error: desc = \"ServerHandshake(\\\"x.x.x.x:x\\\") failed: wrapped server handshake: remote error: tls: bad certificate\"",
   "pid":820,
   "system":"system",
   "time":"2023-11-06T05:40:04.169Z"
}
```

問題を解決するには、Gitaly証明書をGitalyサーバーの`/etc/gitlab/trusted-certs`フォルダーに追加したことを確認してください:

1. 証明書がシンボリックリンクされるように[GitLabを再構成](../restart_gitlab.md#reconfigure-a-linux-package-installation)する
1. Gitalyプロセスによって証明書が読み込まれるように、手動で`sudo gitlab-ctl restart gitaly`を再起動します。

## Gitalyが`noexec`ファイルシステムに保存されているプロセスをフォークできない {#gitaly-fails-to-fork-processes-stored-on-noexec-file-systems}

`noexec`オプションをマウントポイント（たとえば、`/var`）に適用すると、Gitalyがプロセスのフォークに関連する`permission denied`エラーをスローします。例: 

```shell
fork/exec /var/opt/gitlab/gitaly/run/gitaly-2057/gitaly-git2go: permission denied
```

この問題を解決するには、ファイルシステムマウントから`noexec`オプションを削除します。別の方法として、Gitalyのランタイムディレクトリを変更することもできます:

1. `/etc/gitlab/gitlab.rb`に`gitaly['runtime_dir'] = '<PATH_WITH_EXEC_PERM>'`を追加し、`noexec`が設定されていない場所を指定します。
1. `sudo gitlab-ctl reconfigure`を実行します。

## コミットの署名が`invalid argument`または`invalid data`で失敗する {#commit-signing-fails-with-invalid-argument-or-invalid-data}

コミットの署名が次のいずれかのエラーで失敗した場合:

- `invalid argument: signing key is encrypted`
- `invalid data: tag byte does not have MSB set`

このエラーが発生するのは、Gitalyのコミット署名がヘッドレスであり、特定のユーザーに関連付けられていないためです。GPG署名キーは、パスフレーズなしで作成するか、エクスポートする前にパスフレーズを削除する必要があります。

## Gitalyログに`info`メッセージのエラーが表示される {#gitaly-logs-show-errors-in-info-messages}

GitLab 16.3で[導入](https://gitlab.com/gitlab-org/gitaly/-/merge_requests/6201)されたバグにより、追加のエントリが[Gitalyログ](../logs/_index.md#gitaly-logs)に書き込まれました。これらのログエントリには`"level":"info"`が含まれていましたが、`msg`文字列にエラーが含まれているように見えました。

例: 

```json
{"level":"info","msg":"[core] [Server #3] grpc: Server.Serve failed to create ServerTransport: connection error: desc = \"ServerHandshake(\\\"x.x.x.x:x\\\") failed: wrapped server handshake: EOF\"","pid":6145,"system":"system","time":"2023-12-14T21:20:39.999Z"}
```

このログエントリの理由は、基盤となるgRPCライブラリが詳細な転送ログを出力することがあるためです。これらのログエントリはエラーのように見えますが、一般的には無視してもかまいません。

このバグは、GitLab 16.4.5、16.5.5、および16.6.0で[修正](https://gitlab.com/gitlab-org/gitaly/-/merge_requests/6513/)され、これらの種類のメッセージがGitalyログに書き込まれないようになっています。

## Gitalyのプロファイリング {#profiling-gitaly}

Gitalyは、Prometheusリスンポートで、いくつかのGo組み込みパフォーマンスプロファイリングツールを公開します。たとえば、PrometheusがGitLabサーバーのポート`9236`をリッスンしている場合:

- 実行中の`goroutines`のリストとそのバックトレースを取得します:

  ```shell
  curl --output goroutines.txt "http://<gitaly_server>:9236/debug/pprof/goroutine?debug=2"
  ```

- 30秒間、CPUプロファイルを呼び出すします:

  ```shell
  curl --output cpu.bin "http://<gitaly_server>:9236/debug/pprof/profile"
  ```

- ヒープメモリ使用量をプロファイルします:

  ```shell
  curl --output heap.bin "http://<gitaly_server>:9236/debug/pprof/heap"
  ```

- 5秒間の実行トレースを記録します。これは、実行中のGitalyのパフォーマンスに影響を与えます:

  ```shell
  curl --output trace.bin "http://<gitaly_server>:9236/debug/pprof/trace?seconds=5"
  ```

`go`がインストールされているホストでは、CPUプロファイルとヒーププロファイルをブラウザで表示できます:

```shell
go tool pprof -http=:8001 cpu.bin
go tool pprof -http=:8001 heap.bin
```

実行トレースは、次を実行して表示できます:

```shell
go tool trace heap.bin
```

### Git操作のプロファイル {#profile-git-operations}

{{< history >}}

- GitLab 16.9で`log_git_traces`[フラグ](../feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitaly/-/issues/5700)されました。デフォルトでは無効になっています。

{{< /history >}}

{{< alert type="flag" >}}

GitLab Self-Managedでは、デフォルトでこの機能は使用できません。管理者が`log_git_traces`という名前の[機能フラグを有効にする](../feature_flags/_index.md)と、この機能を使用できるようになります。GitLab.comでは、この機能は使用できますが、GitLab.comの管理者のみが設定できます。GitLab Dedicatedでは、この機能は利用できません。

{{< /alert >}}

Git操作に関する追加情報をGitalyログに送信することで、Gitalyが実行するGit操作をプロファイルできます。この情報により、ユーザーはパフォーマンス最適化、デバッグ、および一般的なテレメトリ収集に関するインサイトをより深く得ることができます。詳細については、[Git Trace2 APIリファレンス](https://git-scm.com/docs/api-trace2)を参照してください。

システムオーバーロードを防ぐため、追加の情報ロギングはレート制限されています。レート制限を超過すると、トレースはスキップされます。ただし、レートが正常な状態に戻ると、トレースは自動的に再度処理されます。レート制限により、システムの安定性が維持され、過剰なトレース処理による悪影響が回避されます。

## GitLabの復元後、リポジトリが空として表示される {#repositories-are-shown-as-empty-after-a-gitlab-restore}

セキュリティを強化するために`fapolicyd`を使用すると、GitLabのバックアップファイルからの復元が成功したとGitLabからレポートされる場合がありますが、次のような状態になることがあります:

- リポジトリが空として表示される。
- 新しいファイルを作成すると、次のようなエラーが発生する:

  ```plaintext
  13:commit: commit: starting process [/var/opt/gitlab/gitaly/run/gitaly-5428/gitaly-git2go -log-format json -log-level -correlation-id
  01GP1383JV6JD6MQJBH2E1RT03 -enabled-feature-flags -disabled-feature-flags commit]: fork/exec /var/opt/gitlab/gitaly/run/gitaly-5428/gitaly-git2go: operation not permitted.
  ```

- Gitalyログに次のようなエラーが含まれている可能性がある:

  ```plaintext
   "error": "exit status 128, stderr: \"fatal: cannot exec '/var/opt/gitlab/gitaly/run/gitaly-5428/hooks-1277154941.d/reference-transaction':

    Operation not permitted\\nfatal: cannot exec '/var/opt/gitlab/gitaly/run/gitaly-5428/hooks-1277154941.d/reference-transaction': Operation
    not permitted\\nfatal: ref updates aborted by hook\\n\"",
   "grpc.code": "Internal",
   "grpc.meta.deadline_type": "none",
   "grpc.meta.method_type": "client_stream",
   "grpc.method": "FetchBundle",
   "grpc.request.fullMethod": "/gitaly.RepositoryService/FetchBundle",
  ...
  ```

[デバッグモード](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/security_hardening/assembly_blocking-and-allowing-applications-using-fapolicyd_security-hardening#ref_troubleshooting-problems-related-to-fapolicyd_assembly_blocking-and-allowing-applications-using-fapolicyd)を使用すると、`fapolicyd`が現在のルールに基づいて実行を拒否しているかどうかを判断できます。

`fapolicyd`が実行を拒否していることが判明した場合は、以下を検討してください:

1. `/var/opt/gitlab/gitaly`設定で、`fapolicyd`内のすべての実行可能ファイルを許可します:

   ```plaintext
   allow perm=any all : ftype=application/x-executable dir=/var/opt/gitlab/gitaly/
   ```

1. サービスを再起動します:

   ```shell
   sudo systemctl restart fapolicyd

   sudo gitlab-ctl restart gitaly
   ```

## `Pre-receive hook declined`が有効なRHELインスタンスへのプッシュ時に発生する`fapolicyd` {#pre-receive-hook-declined-error-when-pushing-to-rhel-instance-with-fapolicyd-enabled}

`fapolicyd`が有効なRHELベースのインスタンスにプッシュすると、`Pre-receive hook declined`エラーが発生する場合があります。このエラーは、`fapolicyd`がGitalyバイナリの実行をブロックできるために発生する可能性があります。この問題を解決するには、次のいずれかの方法を実行します:

- `fapolicyd`を無効にします。
- `fapolicyd`ルールを作成して、`fapolicyd`が有効な場合にGitalyバイナリの実行を許可します。

Gitalyバイナリの実行を許可するルールを作成するには:

1. `/etc/fapolicyd/rules.d/89-gitlab.rules`ファイルを作成します。
1. 次に示すコードをファイルに入力します:

   ```plaintext
   allow perm=any all : ftype=application/x-executable dir=/var/opt/gitlab/gitaly/
   ```

1. サービスを再起動します:

   ```shell
   systemctl restart fapolicyd
   ```

新しいルールは、デーモンの復元後に有効になります。

## 重複パスを持つストレージを削除した後に、リポジトリを更新する {#update-repositories-after-removing-a-storage-with-a-duplicate-path}

{{< history >}}

- Rakeタスク`gitlab:gitaly:update_removed_storage_projects`は、GitLab 17.1で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/153008)。

{{< /history >}}

GitLab 17.0では、重複パスを持つストレージの設定のサポートが[削除されました](https://gitlab.com/gitlab-org/gitaly/-/issues/5598)。これは、`gitaly`設定から重複するストレージの設定を削除する必要があることを意味する場合があります。

{{< alert type="warning" >}}

新旧のストレージが同じGitalyサーバー上の同じディスクパスを共有している場合にのみ、このRakeタスクを使用してください。他の状況でこのRakeタスクを使用すると、リポジトリが使用できなくなります。他のすべての状況でストレージ間でプロジェクトを転送するには、[プロジェクトリポジトリストレージの移動API](../../api/project_repository_storage_moves.md)を使用します。

{{< /alert >}}

別のストレージと同じパスを使用したストレージをGitaly設定から削除する場合、古いストレージに関連付けられているプロジェクトを新しいストレージに再割り当てする必要があります。

たとえば、次のような設定になっている場合があります:

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

`duplicate-path`を設定から削除する場合、割り当てられているプロジェクトを代わりに`default`に関連付けるには、次のRakeタスクを実行します:

{{< tabs >}}

{{< tab title="Linuxパッケージインストール" >}}

```shell
sudo gitlab-rake "gitlab:gitaly:update_removed_storage_projects[duplicate-path, default]"
```

{{< /tab >}}

{{< tab title="セルフコンパイルインストール" >}}

```shell
sudo -u git -H bundle exec rake "gitlab:gitaly:update_removed_storage_projects[duplicate-path, default]" RAILS_ENV=production
```

{{< /tab >}}

{{< /tabs >}}

## エラー: `fatal: deflate error (0)\n` (ZIPファイルとしてリポジトリをダウンロードする場合) {#error-fatal-deflate-error-0n-when-downloading-repository-as-zip-file}

Gitバージョン2.51で修正されたGitバグ ([issue 575](https://gitlab.com/gitlab-org/git/-/issues/575)) が原因で、場合によっては、リポジトリをZIPアーカイブとしてダウンロードすると、不完全なZIPファイルになることがあります。この場合、Gitalyログに次のエラーが表示されます:

```plaintext
  "msg": "fatal: deflate error (0)\n",
```

この問題を解決するには、修正されたバージョンのGitを使用するバージョンのGitLabおよびGitalyにアップグレードします。アップグレードできない場合は、次の手順に従って問題を回避してください:

{{< tabs >}}

{{< tab title="Linuxパッケージインストール" >}}

1. [`git-sizer`](https://github.com/github/git-sizer#getting-started)を使用して、blobのサイズを確認します。
1. `core.bigFileThreshold`が最大のblobのサイズより大きくなるように設定します ( `50m`がデフォルトです):

   ```ruby
     gitaly['configuration'] = {
      # ... your existing configuration ...
      git: {
        config: [
          # ... any existing git config entries ...
          {
            key: 'core.bigFileThreshold',
            value: '500m'
          }
        ]
      }
    }
   ```

1. `gitlab-ctl reconfigure`を実行します。

{{< /tab >}}

{{< tab title="Helmチャート（Kubernetes）" >}}

1. [`git-sizer`](https://github.com/github/git-sizer#getting-started)を使用して、blobのサイズを確認します。
1. `core.bigFileThreshold`を`values.yml`ファイルで設定します:

   ```yaml
   git:
     config:
       - key: "core.bigFileThreshold"
         value: "500m"
   ```

1. 設定を更新するには、`helm upgrade <gitlab_release> gitlab/gitlab -f values.yaml`を実行します。

{{< /tab >}}

{{< tab title="セルフコンパイルインストール" >}}

1. [`git-sizer`](https://github.com/github/git-sizer#getting-started)を使用して、blobのサイズを確認します。
1. `core.bigFileThreshold`を`/home/git/gitaly/config.toml`で次のように設定します:

   ```toml
   # [[git.config]]
   # key = core.bigFileThreshold
   # value = 500m
   ```

{{< /tab >}}

{{< /tabs >}}
