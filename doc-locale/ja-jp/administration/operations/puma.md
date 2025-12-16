---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLabパッケージのバンドルされたPumaインスタンスを設定する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

Pumaは、Rubyアプリケーション向けの高速、マルチスレッド、高度な並行処理が可能なHTTP 1.1サーバーです。これは、GitLabのユーザー向け機能を提供するコアRailsアプリケーションを実行します。

## メモリ使用量の削減 {#reducing-memory-use}

メモリ使用量を削減するために、Pumaはワーカープロセスをフォークします。ワーカーが作成されるたびに、プライマリプロセスとメモリ使用量を共有します。ワーカーは、メモリ使用量ページを変更または追加する場合にのみ、追加のメモリ使用量を使用します。これにより、ワーカーが追加のWebリクエストを処理するにつれて、Pumaワーカーが時間の経過とともにより多くの物理メモリ使用量を使用する可能性があります。時間の経過とともに使用されるメモリ使用量は、GitLabの使用状況によって異なります。GitLabユーザーが使用する機能が多いほど、時間の経過とともに予想されるメモリ使用量が高くなります。

制御されないメモリ使用量の増加を止めるため、GitLab Railsアプリケーションは、特定の時間に対して、指定された常駐セットサイズ（RSS）のしきい値を超えた場合、ワーカーを自動的に再起動する監視スレッドを実行します。

GitLabは、メモリ使用量制限のデフォルトを`1200Mb`に設定します。デフォルト値をオーバーライドするには、`per_worker_max_memory_mb`を新しいRSS制限（MB単位）に設定します:

1. `/etc/gitlab/gitlab.rb`を編集します: 

   ```ruby
   puma['per_worker_max_memory_mb'] = 1024 # 1 GB
   ```

1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

ワーカーを再起動すると、GitLabを実行する能力が短時間低下します。ワーカーの交換頻度が高すぎる場合は、`per_worker_max_memory_mb`をより高い値に設定します。

ワーカー数は、CPUコアに基づいて計算されます。4〜8個のワーカーを持つ小規模なGitLabデプロイでは、ワーカーの再起動頻度が高すぎる場合（1分間に1回以上）、パフォーマンスの問題が発生する可能性があります。

サーバーに空きメモリ使用量がある場合、`1200`以上の値を大きくすると効果がある可能性があります。

## データベース接続の計画 {#plan-the-database-connections}

Pumaのワーカーまたはスレッドを増やす前に、PostgreSQLの`max_connections`設定に対するデータベース接続の影響を考慮してください。

詳細な接続計画と計算については、[PostgreSQLのチューニング](../postgresql/tune.md)ページを参照してください。

### ワーカーの再起動を監視する {#monitor-worker-restarts}

メモリ使用量が多いことが原因でワーカーが再起動された場合、GitLabはログイベントを生成します。

以下は、`/var/log/gitlab/gitlab-rails/application_json.log`のこれらのログイベントの1つの例です:

```json
{
  "severity": "WARN",
  "time": "2023-01-04T09:45:16.173Z",
  "correlation_id": null,
  "pid": 2725,
  "worker_id": "puma_0",
  "memwd_handler_class": "Gitlab::Memory::Watchdog::PumaHandler",
  "memwd_sleep_time_s": 5,
  "memwd_rss_bytes": 1077682176,
  "memwd_max_rss_bytes": 629145600,
  "memwd_max_strikes": 5,
  "memwd_cur_strikes": 6,
  "message": "rss memory limit exceeded"
}
```

`memwd_rss_bytes`は実際に消費されたメモリ使用量であり、`memwd_max_rss_bytes`は`per_worker_max_memory_mb`を介して設定されたRSS制限です。

## ワーカータイムアウトを変更する {#change-the-worker-timeout}

デフォルトのPuma [タイムアウトは60秒](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/initializers/rack_timeout.rb)です。

{{< alert type="note" >}}

`puma['worker_timeout']`設定は、最大リクエスト時間を設定するものではありません。

{{< /alert >}}

ワーカータイムアウトを600秒に変更するには:

1. `/etc/gitlab/gitlab.rb`を編集します: 

   ```ruby
   gitlab_rails['env'] = {
      'GITLAB_RAILS_RACK_TIMEOUT' => 600
    }
   ```

1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## メモリ使用量が制限された環境でPumaクラスタ化モードを無効にする {#disable-puma-clustered-mode-in-memory-constrained-environments}

{{< alert type="warning" >}}

これは[実験的機能](../../policy/development_stages_support.md#experiment)であり、予告なく変更される場合があります。この機能は本番環境での使用には対応していません。この機能を使用する場合は、まず本番環境以外でテストする必要があります。詳細については、[既知の問題](#puma-single-mode-known-issues)を参照してください。

{{< /alert >}}

メモリ使用量が制限された環境で、使用可能なRAMが4 GB未満の場合は、Pumaの[クラスタ化モード](https://github.com/puma/puma#clustered-mode)を無効にすることを検討してください。

`workers`の数を`0`に設定して、数百MB単位でメモリ使用量を削減します:

1. `/etc/gitlab/gitlab.rb`を編集します: 

   ```ruby
   puma['worker_processes'] = 0
   ```

1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

デフォルトでセットアップされているクラスタ化モードとは異なり、単一のPumaプロセスのみがアプリケーションを提供します。Pumaのワーカーとスレッドの設定の詳細については、[Pumaの要件](../../install/requirements.md#puma)を参照してください。

この設定でPumaを実行することの短所は、スループットが低下することです。これは、メモリ使用量が制限された環境では公平なトレードオフと見なすことができます。

メモリ使用量不足（OOM）状態を回避するために、十分なスワップを確保してください。詳細については、[メモリ使用量の要件](../../install/requirements.md#memory)をご覧ください。

### Pumaシングルモードの既知の問題 {#puma-single-mode-known-issues}

シングルモードでPumaを実行する場合、一部の機能はサポートされていません:

- [段階的な再起動](https://gitlab.com/gitlab-org/gitlab/-/issues/300665)
- [メモリキラー](#reducing-memory-use)

詳細については、[エピック5303](https://gitlab.com/groups/gitlab-org/-/epics/5303)を参照してください。

## SSL経由でリッスンするようにPumaを設定する {#configuring-puma-to-listen-over-ssl}

Linuxパッケージのインストールでデプロイすると、PumaはデフォルトでUnixソケットを介してリッスンします。代わりにHTTPSポートを介してリッスンするようにPumaを設定するには、以下の手順に従ってください:

1. PumaがリッスンするアドレスのSSL証明書キーペアを生成します。以下の例では、これは`127.0.0.1`です。

   {{< alert type="note" >}}

   カスタム認証局からの自己署名証明書を使用している場合は、他のGitLabコンポーネントから信頼されるように、[ドキュメント](https://docs.gitlab.com/omnibus/settings/ssl/#install-custom-public-certificates)に従ってください。

   {{< /alert >}}

1. `/etc/gitlab/gitlab.rb`を編集します: 

   ```ruby
   puma['ssl_listen'] = '127.0.0.1'
   puma['ssl_port'] = 9111
   puma['ssl_certificate'] = '<path_to_certificate>'
   puma['ssl_certificate_key'] = '<path_to_key>'

   # Disable UNIX socket
   puma['socket'] = ""
   ```

1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< alert type="note" >}}

Unixソケットに加えて、PumaはPrometheusによってスクレイプされるメトリクスを提供するために、ポート8080でHTTPを介してリッスンします。PrometheusにHTTPS経由でそれらをスクレイプさせることはできず、それに対するサポートが[このイシューで](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/6811)議論されています。したがって、Prometheusメトリクスを失うことなく、このHTTPリスナーをオフにすることは技術的に不可能です。

{{< /alert >}}

### 暗号化されたSSLキーの使用 {#using-an-encrypted-ssl-key}

{{< history >}}

- GitLab 16.1で[導入](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/7799)されました。

{{< /history >}}

Pumaは、ランタイム時に復号化することができる、暗号化されたプライベートSSLキーの使用をサポートしています。以下の手順は、これを行う方法を示しています:

1. キーがまだ暗号化されていない場合は、パスワードで暗号化します:

   ```shell
   openssl rsa -aes256 -in /path/to/ssl-key.pem -out /path/to/encrypted-ssl-key.pem
   ```

   暗号化されたファイルを書き込むには、パスワードを2回入力します。この例では、`some-password-here`を使用します。

1. パスワードを出力するスクリプトまたは実行可能ファイルを作成します。たとえば、パスワードをエコーする`/var/opt/gitlab/gitlab-rails/etc/puma-ssl-key-password`に基本的なスクリプトを作成します:

   ```shell
   #!/bin/sh
   echo some-password-here
   ```

   パスワードをディスクに保存することは避け、Vaultなどのパスワード取得ための安全なメカニズムを使用してください。たとえば、スクリプトは次のようになります:

   ```shell
   #!/bin/sh
   export VAULT_ADDR=http://vault-password-distribution-point:8200
   export VAULT_TOKEN=<some token>

   echo "$(vault kv get -mount=secret puma-ssl-password)"
   ```

1. Pumaプロセスに、スクリプトを実行し、暗号化されたキーを読み取りるための十分な権限があることを確認します:

   ```shell
   chown git:git /var/opt/gitlab/gitlab-rails/etc/puma-ssl-key-password
   chmod 770 /var/opt/gitlab/gitlab-rails/etc/puma-ssl-key-password
   chmod 660 /path/to/encrypted-ssl-key.pem
   ```

1. `/etc/gitlab/gitlab.rb`を編集し、`puma['ssl_certificate_key']`を暗号化されたキーに置き換え、`puma['ssl_key_password_command]`を指定します:

   ```ruby
   puma['ssl_certificate_key'] = '/path/to/encrypted-ssl-key.pem'
   puma['ssl_key_password_command'] = '/var/opt/gitlab/gitlab-rails/etc/puma-ssl-key-password'
   ```

1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. GitLabが正常に起動した場合は、GitLabインスタンスに保存されている暗号化されていないSSLキーを削除できるはずです。

## UnicornからPumaへのスイッチ {#switch-from-unicorn-to-puma}

{{< alert type="note" >}}

Helmベースのデプロイについては、[`webservice`チャートドキュメント](https://docs.gitlab.com/charts/charts/gitlab/webservice/)を参照してください。

{{< /alert >}}

PumaはデフォルトのWebサーバーであり、Unicornはサポートされなくなりました。

Pumaは、Unicornのようなマルチプロセスアプリケーションサーバーよりも少ないメモリ使用量を使用するマルチスレッドアーキテクチャを備えています。GitLab.comでは、メモリ使用量が40％削減されました。ほとんどのRailsアプリケーションリクエストには、通常、I/O待機時間の割合が含まれています。

I/O待機時間中、MRI RubyはGVLを他のスレッドにリリースします。したがって、マルチスレッドPumaは、単一のプロセスよりも多くのリクエストを処理できます。

Pumaにスイッチする場合、2つのアプリケーションサーバーの違いにより、Unicornサーバーの設定が自動的に引き継がれることはありません。

UnicornからPumaにスイッチするには:

1. 適切なPuma[ワーカーとスレッドの設定](../../install/requirements.md#puma)を決定します。
1. `/etc/gitlab/gitlab.rb`で、カスタムUnicorn設定をPumaに変換します。

   以下の表は、Linuxパッケージを使用する場合、どのUnicorn設定キーがPumaのキーに対応し、対応するキーがないかを示しています。

   | Unicorn                              | Puma                               |
   | ------------------------------------ | ---------------------------------- |
   | `unicorn['enable']`                  | `puma['enable']`                   |
   | `unicorn['worker_timeout']`          | `puma['worker_timeout']`           |
   | `unicorn['worker_processes']`        | `puma['worker_processes']`         |
   | 該当なし                       | `puma['ha']`                       |
   | 該当なし                       | `puma['min_threads']`              |
   | 該当なし                       | `puma['max_threads']`              |
   | `unicorn['listen']`                  | `puma['listen']`                   |
   | `unicorn['port']`                    | `puma['port']`                     |
   | `unicorn['socket']`                  | `puma['socket']`                   |
   | `unicorn['pidfile']`                 | `puma['pidfile']`                  |
   | `unicorn['tcp_nopush']`              | 該当なし                     |
   | `unicorn['backlog_socket']`          | 該当なし                     |
   | `unicorn['somaxconn']`               | `puma['somaxconn']`                |
   | 該当なし                       | `puma['state_path']`               |
   | `unicorn['log_directory']`           | `puma['log_directory']`            |
   | `unicorn['worker_memory_limit_min']` | 該当なし                     |
   | `unicorn['worker_memory_limit_max']` | `puma['per_worker_max_memory_mb']` |
   | `unicorn['exporter_enabled']`        | `puma['exporter_enabled']`         |
   | `unicorn['exporter_address']`        | `puma['exporter_address']`         |
   | `unicorn['exporter_port']`           | `puma['exporter_port']`            |

1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. オプション。マルチノードデプロイの場合は、[読み取りチェック](../load_balancer.md#readiness-check)を使用するようにロードバランサーを設定します。

## トラブルシューティングPuma {#troubleshooting-puma}

### Pumaが100％CPUでスピンした後の502 Gatewayタイムアウト {#502-gateway-timeout-after-puma-spins-at-100-cpu}

このエラーは、Webサーバーがタイムアウトした場合に発生します（デフォルト: Pumaワーカーからの応答がない場合は60秒）。これが進行中にCPUが100％までスピンする場合、何かが必要以上に時間がかかっている可能性があります。

この問題を修正するには、まず何が起こっているかを把握する必要があります。以下のヒントは、ユーザーがダウンタイムの影響を受けてもかまわない場合にのみお勧めします。それ以外の場合は、次のセクションに進みます。

1. 問題のあるURLを読み込む
1. `sudo gdb -p <PID>`を実行して、Pumaプロセスにアタッチします。
1. GDBウィンドウで、次のように入力します:

   ```plaintext
   call (void) rb_backtrace()
   ```

1. これにより、プロセスはRubyバックトレースを強制的に生成します。バックトレースについては、`/var/log/gitlab/puma/puma_stderr.log`を確認してください。たとえば、次のものが表示される場合があります:

   ```plaintext
   from /opt/gitlab/embedded/service/gitlab-rails/lib/gitlab/metrics/sampler.rb:33:in `block in start'
   from /opt/gitlab/embedded/service/gitlab-rails/lib/gitlab/metrics/sampler.rb:33:in `loop'
   from /opt/gitlab/embedded/service/gitlab-rails/lib/gitlab/metrics/sampler.rb:36:in `block (2 levels) in start'
   from /opt/gitlab/embedded/service/gitlab-rails/lib/gitlab/metrics/sampler.rb:44:in `sample'
   from /opt/gitlab/embedded/service/gitlab-rails/lib/gitlab/metrics/sampler.rb:68:in `sample_objects'
   from /opt/gitlab/embedded/service/gitlab-rails/lib/gitlab/metrics/sampler.rb:68:in `each_with_object'
   from /opt/gitlab/embedded/service/gitlab-rails/lib/gitlab/metrics/sampler.rb:68:in `each'
   from /opt/gitlab/embedded/service/gitlab-rails/lib/gitlab/metrics/sampler.rb:69:in `block in sample_objects'
   from /opt/gitlab/embedded/service/gitlab-rails/lib/gitlab/metrics/sampler.rb:69:in `name'
   ```

1. 現在のスレッドを表示するには、次を実行します:

   ```plaintext
   thread apply all bt
   ```

1. `gdb`を使用したデバッグが完了したら、必ずプロセスからデタッチして終了してください:

   ```plaintext
   detach
   exit
   ```

これらのコマンドを実行する前にPumaプロセスが終了すると、GDBはエラーをレポートします。時間を稼ぐために、Pumaワーカータイムアウトを常に上げることができます。Linuxパッケージインストールユーザーの場合は、`/etc/gitlab/gitlab.rb`を編集し、60秒から600秒に増やすことができます:

```ruby
gitlab_rails['env'] = {
        'GITLAB_RAILS_RACK_TIMEOUT' => 600
}
```

セルフコンパイルインストールの場合は、環境変数を設定します。[Pumaワーカータイムアウト](puma.md#change-the-worker-timeout)を参照してください。

変更を有効にするには、[GitLabを再構成します](../restart_gitlab.md#reconfigure-a-linux-package-installation)。

#### 他のユーザーに影響を与えずにトラブルシューティングを行う {#troubleshooting-without-affecting-other-users}

前のセクションは実行中のPumaプロセスにアタッチされており、この期間中にGitLabにアクセスしようとしているユーザーに望ましくない影響を与える可能性があります。本番環境システムで他のユーザーに影響を与えることを懸念している場合は、別のRailsプロセスを実行して問題をデバッグできます:

1. GitLabアカウントにサインインします。
1. 問題を引き起こしているURLをコピーします（たとえば、`https://gitlab.com/ABC`）。
1. ユーザーのパーソナルアクセストークンを作成します（ユーザー設定 -> アクセストークン）。
1. [GitLab Railsコンソール](rails_console.md#starting-a-rails-console-session)を起動します。
1. Railsコンソールで、次を実行します:

   ```ruby
   app.get '<URL FROM STEP 2>/?private_token=<TOKEN FROM STEP 3>'
   ```

   例: 

   ```ruby
   app.get 'https://gitlab.com/gitlab-org/gitlab-foss/-/issues/1?private_token=123456'
   ```

1. 新しいウィンドウで、`top`を実行します。このRubyプロセスが100％のCPUを使用していることが表示されます。PIDを書き留めます。
1. GDBの使用に関する前のセクションの手順2に従います。

### GitLab: APIにアクセスできません {#gitlab-api-is-not-accessible}

これは、GitLab Shellが内部API（たとえば、`http://localhost:8080/api/v4/internal/allowed`）を介して認可をリクエストしようとしたときに、チェックで何かが失敗した場合によく発生します。この問題は、次の理由で発生する可能性があります:

1. データベース（たとえば、PostgreSQLまたはRedis）への接続タイムアウト
1. Gitフックまたはプッシュルールのエラー
1. リポジトリへのアクセスエラー（たとえば、古いNFSハンドル）

この問題を診断するには、問題を再現してみて、`top`を介してスピンしているPumaワーカーがあるかどうかを確認します。以前にドキュメント化された`gdb`手法を使用してみてください。さらに、`strace`を使用すると、問題を特定するのに役立つ場合があります:

```shell
strace -ttTfyyy -s 1024 -p <PID of puma worker> -o /tmp/puma.txt
```

どのPumaワーカーが問題であるかを特定できない場合は、すべてのPumaワーカーで`strace`を実行して、`/internal/allowed`エンドポイントがどこでスタックするかを確認してみてください:

```shell
ps auwx | grep puma | awk '{ print " -p " $2}' | xargs  strace -ttTfyyy -s 1024 -o /tmp/puma.txt
```

`/tmp/puma.txt`の出力は、根本原因の診断に役立つ場合があります。

## 関連トピック {#related-topics}

- [専用のメトリクスサーバーを使用してWebメトリクスをエクスポートする](../monitoring/prometheus/web_exporter.md)
