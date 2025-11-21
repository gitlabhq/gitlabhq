---
stage: Data access
group: Durability
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 複数のSidekiqプロセスを実行する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLabでは、複数のSidekiqプロセスを開始して、単一インスタンスでバックグラウンドジョブをより高速に処理できます。デフォルトでは、Sidekiqは1つのワーカープロセスを開始し、単一のコアのみを使用します。

{{< alert type="note" >}}

このページの情報は、Linuxパッケージのデプロイのみに適用されます。

{{< /alert >}}

## 複数のプロセスを開始する {#start-multiple-processes}

複数のプロセスを開始する場合、プロセスの数は、Sidekiqに割り当てるCPUコア数以下にする必要があります（超えることは**できません**）。Sidekiqワーカープロセスは、1つ以下のCPUコアを使用します。

複数のプロセスを開始するには、`sidekiq['queue_groups']`配列設定を使用して、`sidekiq-cluster`を使用して作成するプロセスの数と、それらが処理するキューを指定します。配列内の各項目は、追加のSidekiqプロセスと同等であり、各項目の値によって、それが動作するキューが決まります。ほとんどの場合、すべてのプロセスはすべてのキューをリッスンする必要があります（詳細については、[特定のジョブクラスの処理](processing_specific_job_classes.md)を参照してください）。

たとえば、4つのSidekiqプロセスを作成し、それぞれが利用可能なすべてのキューをリッスンするようにするには、次の手順に従います:

1. `/etc/gitlab/gitlab.rb`を編集します: 

   ```ruby
   sidekiq['queue_groups'] = ['*'] * 4
   ```

1. ファイルを保存して、GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

GitLabでSidekiqプロセスを表示するには:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. 左側のサイドバーの下部にある**モニタリング**を選択し、次に**バックグラウンドジョブ**を選択します。

## 並行処理 {#concurrency}

デフォルトでは、`sidekiq`で定義された各プロセスは、キューの数に等しい数のスレッドと、最大50までの1つのスペアスレッドで開始します。たとえば、すべてのキューを処理するプロセスは、デフォルトで50個のスレッドを使用します。

これらのスレッドは単一のRubyプロセス内で実行され、各プロセスは単一のCPUコアのみを使用できます。スレッドの有用性は、データベースクエリやHTTPリクエストなど、待機する外部依存関係があるワークロードに依存します。ほとんどのSidekiqデプロイメントは、このスレッドから恩恵を受けます。

## データベース接続計画 {#database-connection-planning}

Sidekiqプロセスまたは並行処理を増やす前に、PostgreSQLの`max_connections`設定に対するデータベース接続の影響を考慮してください。

詳細な接続計画と計算については、[PostgreSQLの調整](../postgresql/tune.md)ページを参照してください。

### スレッド数を明示的に管理する {#manage-thread-counts-explicitly}

適切な最大のスレッド数（並行処理とも呼ばれます）は、ワークロードによって異なります。一般的な値の範囲は、CPUバウンドの高いタスクの場合は`5`から、混合された優先度の低いワークロードの場合は`15`以上です。妥当な開始範囲は、特殊化されていないデプロイメントの場合、`15`〜`25`です。

値は、Sidekiqの特定のデプロイメントが行うワークロードによって異なります。特定のキュー専用のプロセスを使用する他の特殊なデプロイメントでは、並行処理を次のように調整する必要があります:

- プロセスの各タイプのCPU使用率。
- 達成されたスループット。

各スレッドにはRedis接続が必要なため、スレッドを追加すると、Redisレイテンシーが増加し、クライアントタイムアウトが発生する可能性があります。詳細については、[Redisに関するSidekiqドキュメント](https://github.com/mperham/sidekiq/wiki/Using-Redis)を参照してください。

#### 並行処理フィールドでスレッド数を管理する {#manage-thread-counts-with-concurrency-field}

{{< history >}}

- GitLab 16.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/439687)されました。

{{< /history >}}

GitLab 16.9以降では、`concurrency`を設定することで並行処理を設定できます。この値は、この量の並行処理で各プロセスを明示的に設定します。

たとえば、並行処理を`20`に設定するには:

1. `/etc/gitlab/gitlab.rb`を編集します: 

   ```ruby
   sidekiq['concurrency'] = 20
   ```

1. ファイルを保存して、GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## チェック間隔を変更する {#modify-the-check-interval}

追加のSidekiqプロセスのSidekiqヘルスチェック間隔を変更するには:

1. `/etc/gitlab/gitlab.rb`を編集します: 

   ```ruby
   sidekiq['interval'] = 5
   ```

   値は、任意の整数数（秒単位）にすることができます。

1. ファイルを保存して、GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## コマンドラインを使用して問題を解決する {#troubleshoot-using-the-cli}

{{< alert type="warning" >}}

Sidekiqプロセスを構成するには、`/etc/gitlab/gitlab.rb`を使用することをお勧めします。問題が発生した場合は、GitLabサポートにお問い合わせください。ご自身の責任でコマンドラインを使用してください。

{{< /alert >}}

デバッグの目的で、`/opt/gitlab/embedded/service/gitlab-rails/bin/sidekiq-cluster`コマンドを使用して、追加のSidekiqプロセスを開始できます。このコマンドは、次の構文を使用して引数を取ります:

```shell
/opt/gitlab/embedded/service/gitlab-rails/bin/sidekiq-cluster [QUEUE,QUEUE,...] [QUEUE, ...]
```

`--dryrun`引数を使用すると、実際に開始せずに実行されるコマンドを表示できます。

個別の引数はそれぞれ、Sidekiqプロセスによって処理される必要があるキューのグループを示します。スペースではなくカンマで区切ることで、同じプロセスで複数のキューを処理できます。

キューの代わりに、キューネームスペースを指定して、そのネームスペース内のすべてのキュー名を明示的にリストしなくても、プロセスがそのネームスペース内のすべてのキューを自動的にリッスンするようにすることもできます。キューネームスペースの詳細については、GitLab開発ドキュメントのSidekiq開発パートの関連セクションを参照してください。

### `sidekiq-cluster`コマンドを監視する {#monitor-the-sidekiq-cluster-command}

`sidekiq-cluster`コマンドは、必要な数のSidekiqプロセスを開始すると、終了しません。代わりに、プロセスは引き続き実行され、すべてシグナルを子プロセスに転送します。これにより、個々のプロセスにシグナルを送信する代わりに、`sidekiq-cluster`プロセスにシグナルを送信すると、すべてのSidekiqプロセスを停止できます。

`sidekiq-cluster`プロセスがクラッシュするか、`SIGKILL`を受信すると、子プロセスは数秒後に自動的に終了します。これにより、Sidekiqのゾンビプロセスが発生することがなくなります。

これにより、`sidekiq-cluster`をお好みのスーパーバイザー（たとえば、runit）に接続して、プロセスを監視できます。

子プロセスが停止した場合、`sidekiq-cluster`コマンドは、残りのすべてのプロセスに終了を通知し、その後、それ自体を終了します。これにより、`sidekiq-cluster`が複雑なプロセスの監視/再起動codeを再実装する必要がなくなります。代わりに、必要な場合はいつでも、スーパーバイザーが`sidekiq-cluster`プロセスを再起動するようにしてください。

### PIDファイル {#pid-files}

`sidekiq-cluster`コマンドは、そのPIDをファイルに保存できます。デフォルトでは、PIDファイルは書き込まれませんが、`--pidfile`オプションを`sidekiq-cluster`に渡すことでこれを変更できます。例: 

```shell
/opt/gitlab/embedded/service/gitlab-rails/bin/sidekiq-cluster --pidfile /var/run/gitlab/sidekiq_cluster.pid process_commit
```

PIDファイルには、開始されたSidekiqプロセスのPIDではなく、`sidekiq-cluster`コマンドのPIDが含まれていることに注意してください。

### 環境 {#environment}

Rails環境は、`--environment`フラグを`sidekiq-cluster`コマンドに渡すか、`RAILS_ENV`を空でない値に設定することで設定できます。デフォルト値は、`/opt/gitlab/etc/gitlab-rails/env/RAILS_ENV`にあります。
