---
stage: Tenant Scale
group: Tenant Services
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 複数のSidekiqプロセスを実行する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLabは、単一のインスタンスで複数のSidekiqプロセスを開始し、バックグラウンドジョブをより高いレートで処理できます。デフォルトでは、Sidekiqは1つのワーカープロセスを開始し、1つのコアのみを使用します。

> [!note]
> 
> このページの情報は、Linuxパッケージインストールにのみ適用されます。

## 複数のプロセスを開始する {#start-multiple-processes}

複数のプロセスを開始する場合、プロセスの数は、Sidekiqに割り当てるCPUコアの数と最大で等しく（そして**not**超える）なければなりません。Sidekiqワーカープロセスは、CPUコアを1つしか使用しません。

複数のプロセスを開始するには、`sidekiq-cluster`を使用して作成するプロセスの数と、それらが処理するキューを指定するために、`sidekiq['queue_groups']`配列設定を使用します。配列内の各項目は、追加のSidekiqプロセス1つに相当し、各項目内の値は、それが動作するキューを決定します。ほとんどの場合、すべてのプロセスはすべてのキューをリッスンする必要があります（詳細については、[特定のジョブクラスの処理](processing_specific_job_classes.md)を参照してください）。

たとえば、利用可能なすべてのキューをリッスンする4つのSidekiqプロセスを作成するには、次の手順を実行します:

1. `/etc/gitlab/gitlab.rb`を編集します:

   ```ruby
   sidekiq['queue_groups'] = ['*'] * 4
   ```

1. ファイルを保存して、GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

GitLabでSidekiqプロセスを表示するには:

1. 右上隅で、**管理者**を選択します。
1. **モニタリング** > **バックグラウンドジョブ**を選択します。

## 並行処理 {#concurrency}

デフォルトでは、`sidekiq`の下で定義された各プロセスは、キューの数に1つの予備のスレッドを加えた数のスレッドで起動し、最大50までです。たとえば、すべてのキューを処理するプロセスは、デフォルトで50のスレッドを使用します。

これらのスレッドは単一のRubyプロセス内で実行され、各プロセスは単一のCPUコアのみを使用できます。スレッドの有用性は、データベースクエリやHTTPリクエストなど、待機する外部依存関係があるワークロードに依存します。ほとんどのSidekiqデプロイは、このスレッド化の恩恵を受けます。

## データベース接続の計画 {#database-connection-planning}

Sidekiqプロセスまたは並行処理を増やす前に、PostgreSQLの`max_connections`設定に対するデータベース接続の影響を考慮してください。

詳細な接続計画と計算については、[PostgreSQLのチューニング](../postgresql/tune.md)ページを参照してください。

### スレッド数を明示的に管理する {#manage-thread-counts-explicitly}

正しい最大スレッド数（並行処理とも呼ばれます）は、ワークロードによって異なります。一般的な値は、CPUバウンドの高いタスクの場合は`5`から、混合された低優先度のワークロードの場合は`15`以上です。非専門的なデプロイの場合、妥当な開始範囲は`15`から`25`です。

値は、Sidekiqの特定のデプロイが行うワークロードによって異なります。特定のキュー専用のプロセスを持つその他の専門的なデプロイは、並行処理を次のように調整する必要があります:

- 各種類のプロセスのCPU使用率。
- 達成されたスループット。

各スレッドはRedis接続を必要とするため、スレッドを追加するとRedisのレイテンシーが増加し、クライアントのタイムアウトを引き起こす可能性があります。詳細については、[Redisに関するSidekiqドキュメント](https://github.com/mperham/sidekiq/wiki/Using-Redis)を参照してください。

#### 並行処理フィールドでスレッド数を管理する {#manage-thread-counts-with-concurrency-field}

{{< history >}}

- GitLab 16.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/439687)されました。

{{< /history >}}

GitLab 16.9以降では、`concurrency`を設定することで並行処理を設定できます。この値は、各プロセスにこの量の並行処理を明示的に設定します。

たとえば、並行処理を`20`に設定するには、次の手順を実行します:

1. `/etc/gitlab/gitlab.rb`を編集します:

   ```ruby
   sidekiq['concurrency'] = 20
   ```

1. ファイルを保存して、GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## チェック間隔の変更 {#modify-the-check-interval}

追加のSidekiqプロセスのSidekiqヘルスチェック間隔を変更するには:

1. `/etc/gitlab/gitlab.rb`を編集します:

   ```ruby
   sidekiq['interval'] = 5
   ```

   値は任意の整数秒数にできます。

1. ファイルを保存して、GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## CLIを使用したトラブルシューティングを行う {#troubleshoot-using-the-cli}

> [!warning]
> 
> Sidekiqプロセスを設定するには、`/etc/gitlab/gitlab.rb`を使用することをお勧めします。問題が発生した場合は、GitLabサポートにお問い合わせください。コマンドラインの使用は自己責任で行ってください。

デバッグのため、`/opt/gitlab/embedded/service/gitlab-rails/bin/sidekiq-cluster`コマンドを使用して追加のSidekiqプロセスを開始できます。このコマンドは、次の構文を使用して引数を取ります:

```shell
/opt/gitlab/embedded/service/gitlab-rails/bin/sidekiq-cluster [QUEUE,QUEUE,...] [QUEUE, ...]
```

`--dryrun`引数を使用すると、実際にコマンドを開始することなく実行されるコマンドを表示できます。

それぞれの引数は、Sidekiqプロセスによって処理されるキューのグループを示します。複数のキューは、スペースではなくカンマで区切ることで、同じプロセスによって処理できます。

キューの代わりに、キューネームスペースも指定でき、これにより、すべてのキュー名を明示的にリストすることなく、そのネームスペース内のすべてのキューをプロセスが自動的にリッスンできます。キューネームスペースの詳細については、GitLab開発ドキュメントのSidekiq開発パートの関連セクションを参照してください。

### `sidekiq-cluster`コマンドをモニタリングする {#monitor-the-sidekiq-cluster-command}

`sidekiq-cluster`コマンドは、必要な量のSidekiqプロセスを開始した後も終了しません。代わりに、プロセスは実行を続け、すべてのシグナルを子プロセスに転送します。これにより、個々のプロセスにシグナルを送信する代わりに、`sidekiq-cluster`プロセスにシグナルを送信することで、すべてのSidekiqプロセスを停止できます。

`sidekiq-cluster`プロセスがクラッシュするか、`SIGKILL`を受信した場合、子プロセスは数秒後に自己を終了します。これにより、ゾンビSidekiqプロセスが発生しないようにします。

これにより、`sidekiq-cluster`を選択したスーパーバイザー（たとえばrunit）に接続することで、プロセスをモニタリングできます。

子プロセスが終了した場合、`sidekiq-cluster`コマンドは残りのすべてのプロセスに終了を通知し、その後自己を終了します。これにより、`sidekiq-cluster`が複雑なプロセスのモニタリング/再起動コードを再実装する必要がなくなります。代わりに、スーパーバイザーが`sidekiq-cluster`プロセスを必要に応じて再起動するようにする必要があります。

### PIDファイル {#pid-files}

`sidekiq-cluster`コマンドは、そのPIDをファイルに保存できます。デフォルトではPIDファイルは書き込まれませんが、`sidekiq-cluster`に`--pidfile`オプションを渡すことでこれを変更できます。例: 

```shell
/opt/gitlab/embedded/service/gitlab-rails/bin/sidekiq-cluster --pidfile /var/run/gitlab/sidekiq_cluster.pid process_commit
```

PIDファイルには、`sidekiq-cluster`コマンドのPIDが含まれており、開始されたSidekiqプロセスのPIDではないことに注意してください。

### 環境 {#environment}

Rails環境は、`sidekiq-cluster`コマンドに`--environment`フラグを渡すか、`RAILS_ENV`を空ではない値に設定することで設定できます。デフォルト値は`/opt/gitlab/etc/gitlab-rails/env/RAILS_ENV`にあります。
