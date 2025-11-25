---
stage: Data access
group: Durability
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Sidekiqのトラブルシューティング
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

Sidekiqは、GitLabがタスクを非同期的に実行するために使用するバックグラウンドジョブプロセッサーです。問題が発生した場合、トラブルシューティングが困難になることがあります。これらの状況は、本番環境システムのジョブキューがいっぱいになる可能性があるため、プレッシャーが高くなる傾向があります。新しいブランチが表示されなかったり、マージリクエストが更新されなかったりするため、ユーザーはこれが発生したことに気付きます。以下は、ボトルネックを診断するのに役立つトラブルシューティングの手順です。

GitLabの管理者/ユーザーは、これらのデバッグ手順をGitLabサポートと連携して行うことを検討してください。これにより、バックトレースを弊社のチームが分析できます。GitLabのバグや必要な改善点が明らかになる場合があります。

バックトレースのいずれかにおいて、すべてのスレッドがデータベース、Redis、またはミューテックスの取得を待機していると思われる場合は、注意してください。これは、たとえばデータベースで競合が発生している**may**（可能性）がありますが、残りのスレッドとは異なる1つのスレッドを探してください。この別のスレッドは、使用可能なすべてのCPUを使用しているか、Rubyグローバルインタープリターロックを持っている可能性があり、他のスレッドが続行できなくなっています。

## Sidekiqジョブへの引数のログ {#log-arguments-to-sidekiq-jobs}

Sidekiqジョブに渡される一部の引数は、デフォルトでログに記録されます。機密情報（たとえば、パスワードリセットトークン）のログ記録を回避するために、GitLabは、すべてのワーカーに対して数値引数をログに記録し、引数が機密情報でない特定のワーカーに対してオーバーライドします。

ログ出力の例:

```json
{"severity":"INFO","time":"2020-06-08T14:37:37.892Z","class":"AdminEmailsWorker","args":["[FILTERED]","[FILTERED]","[FILTERED]"],"retry":3,"queue":"admin_emails","backtrace":true,"jid":"9e35e2674ac7b12d123e13cc","created_at":"2020-06-08T14:37:37.373Z","meta.user":"root","meta.caller_id":"Admin::EmailsController#create","correlation_id":"37D3lArJmT1","uber-trace-id":"2d942cc98cc1b561:6dc94409cfdd4d77:9fbe19bdee865293:1","enqueued_at":"2020-06-08T14:37:37.410Z","pid":65011,"message":"AdminEmailsWorker JID-9e35e2674ac7b12d123e13cc: done: 0.48085 sec","job_status":"done","scheduling_latency_s":0.001012,"redis_calls":9,"redis_duration_s":0.004608,"redis_read_bytes":696,"redis_write_bytes":6141,"duration_s":0.48085,"cpu_s":0.308849,"completed_at":"2020-06-08T14:37:37.892Z","db_duration_s":0.010742}
{"severity":"INFO","time":"2020-06-08T14:37:37.894Z","class":"ActiveJob::QueueAdapters::SidekiqAdapter::JobWrapper","wrapped":"ActionMailer::MailDeliveryJob","queue":"mailers","args":["[FILTERED]"],"retry":3,"backtrace":true,"jid":"e47a4f6793d475378432e3c8","created_at":"2020-06-08T14:37:37.884Z","meta.user":"root","meta.caller_id":"AdminEmailsWorker","correlation_id":"37D3lArJmT1","uber-trace-id":"2d942cc98cc1b561:29344de0f966446d:5c3b0e0e1bef987b:1","enqueued_at":"2020-06-08T14:37:37.885Z","pid":65011,"message":"ActiveJob::QueueAdapters::SidekiqAdapter::JobWrapper JID-e47a4f6793d475378432e3c8: start","job_status":"start","scheduling_latency_s":0.009473}
{"severity":"INFO","time":"2020-06-08T14:39:50.648Z","class":"NewIssueWorker","args":["455","1"],"retry":3,"queue":"new_issue","backtrace":true,"jid":"a24af71f96fd129ec47f5d1e","created_at":"2020-06-08T14:39:50.643Z","meta.user":"root","meta.project":"h5bp/html5-boilerplate","meta.root_namespace":"h5bp","meta.caller_id":"Projects::IssuesController#create","correlation_id":"f9UCZHqhuP7","uber-trace-id":"28f65730f99f55a3:a5d2b62dec38dffc:48ddd092707fa1b7:1","enqueued_at":"2020-06-08T14:39:50.646Z","pid":65011,"message":"NewIssueWorker JID-a24af71f96fd129ec47f5d1e: start","job_status":"start","scheduling_latency_s":0.001144}
```

[Sidekiq JSONロギング](../logs/_index.md#sidekiqlog)を使用する場合、引数ログは最大10キロバイトのテキストに制限されます。この制限を超えると、引数は破棄され、文字列`"..."`を含む単一の引数に置き換えられます。

引数のログ記録を無効にするには、`SIDEKIQ_LOG_ARGUMENTS` [環境変数](https://docs.gitlab.com/omnibus/settings/environment-variables.html)を`0`（false）に設定できます。

例: 

```ruby
gitlab_rails['env'] = {"SIDEKIQ_LOG_ARGUMENTS" => "0"}
```

## Sidekiqキューのバックログまたはパフォーマンスの低下の調査 {#investigating-sidekiq-queue-backlogs-or-slow-performance}

Sidekiqのパフォーマンス低下の兆候としては、マージリクエストステータスの更新に関する問題や、CIパイプラインの実行開始前の遅延などがあります。

考えられる原因は次のとおりです:

- GitLabインスタンスには、より多くのSidekiqワーカーが必要な場合があります。デフォルトでは、シングルノードLinuxパッケージのインストールでは1つのワーカーが実行され、Sidekiqジョブの実行が最大1つのCPUコアに制限されます。[複数のSidekiqワーカーの実行の詳細については、こちらをご覧ください](extra_sidekiq_processes.md)。

- インスタンスはより多くのSidekiqワーカーで構成されていますが、ほとんどの追加ワーカーはキューに入れられたジョブを実行するように構成されていません。これにより、ワーカーが構成されてから数か月または数年でワークロードが変更された場合、またはGitLab製品の変更の結果として、インスタンスがビジー状態の場合に、ジョブのバックログが発生する可能性があります。

次のRubyスクリプトを使用して、Sidekiqワーカーの状態に関するデータを収集します。

1. スクリプトを作成します:

   ```ruby
   cat > /var/opt/gitlab/sidekiqcheck.rb <<EOF
   require 'sidekiq/monitor'
   Sidekiq::Monitor::Status.new.display('overview')
   Sidekiq::Monitor::Status.new.display('processes'); nil
   Sidekiq::Monitor::Status.new.display('queues'); nil
   puts "----------- workers ----------- "
   workers = Sidekiq::Workers.new
   workers.each do |_process_id, _thread_id, work|
     pp work
   end
   puts "----------- Queued Jobs ----------- "
   Sidekiq::Queue.all.each do |queue|
     queue.each do |job|
       pp job
     end
   end ;nil
   puts "----------- done! ----------- "
   EOF
   ```

1. 実行可能ファイルを実行して出力をキャプチャします:

   ```shell
   sudo gitlab-rails runner /var/opt/gitlab/sidekiqcheck.rb > /tmp/sidekiqcheck_$(date '+%Y%m%d-%H:%M').out
   ```

   パフォーマンスの問題が断続的な場合:

   - これをcronジョブで5分ごとに実行します。ファイルを十分なスペースのある場所に書き込みます。ファイルあたり少なくとも500 KBを許可します。

     ```shell
     cat > /etc/cron.d/sidekiqcheck <<EOF
     */5 * * * *  root  /opt/gitlab/bin/gitlab-rails runner /var/opt/gitlab/sidekiqcheck.rb > /tmp/sidekiqcheck_$(date '+\%Y\%m\%d-\%H:\%M').out 2>&1
     EOF
     ```

   - データに戻って、何が問題だったかを確認します。

1. 出力を分析します。次のコマンドは、出力ファイルのディレクトリがあることを前提としています。

   1. `grep 'Busy: ' *`は、実行されているジョブの数を示しています。`grep 'Enqueued: ' *`は、その時点でのワークロードのバックログを示しています。

   1. Sidekiqが負荷状態にあるサンプルで、ワーカー全体のビジースレッドの数を確認します:

      ```shell
      ls | while read f ; do if grep -q 'Enqueued: 0' $f; then :
        else echo $f; egrep 'Busy:|Enqueued:|---- Processes' $f
        grep 'Threads:' $f ; fi
      done | more
      ```

      出力例: 

      ```plaintext
      sidekiqcheck_20221024-14:00.out
             Busy: 47
         Enqueued: 363
      ---- Processes (13) ----
        Threads: 30 (0 busy)
        Threads: 30 (0 busy)
        Threads: 30 (0 busy)
        Threads: 30 (0 busy)
        Threads: 23 (0 busy)
        Threads: 30 (0 busy)
        Threads: 30 (0 busy)
        Threads: 30 (0 busy)
        Threads: 30 (0 busy)
        Threads: 30 (0 busy)
        Threads: 30 (0 busy)
        Threads: 30 (24 busy)
        Threads: 30 (23 busy)
      ```

      - この出力ファイルでは、47個のスレッドがビジー状態であり、363個のジョブのバックログがありました。
      - 13個のワーカープロセスの中で、ビジー状態だったのは2つだけでした。
      - これは、他のワーカーが過度に具体的に構成されていることを示しています。
      - どのワーカーがビジー状態だったかを把握するために、完全な出力を見てください。`gitlab.rb`の`sidekiq_queues`構成と関連付けます。
      - オーバーロードされたシングルワーカー環境は、次のようになっている可能性があります:

        ```plaintext
        sidekiqcheck_20221024-14:00.out
               Busy: 25
           Enqueued: 363
        ---- Processes (1) ----
          Threads: 25 (25 busy)
        ```

   1. 出力ファイルの`---- Queues (xxx) ----`セクションを見て、その時点でどのジョブがキューに登録されていたかを判断します。

   1. ファイルには、その時点でのSidekiqの状態に関する低レベルの詳細も含まれています。これは、ワークロードのスパイクがどこから来ているかを特定するのに役立ちます。

      - `----------- workers -----------`セクションでは、サマリーの`Busy`カウントを構成するジョブについて詳しく説明します。
      - `----------- Queued Jobs -----------`セクションでは、`Enqueued`であるジョブの詳細について説明します。

## スレッドダンプ {#thread-dump}

ログファイルにスレッドのバックトレースを出力するには、SidekiqプロセスIDに`TTIN`シグナルを送信します。

```shell
kill -TTIN <sidekiq_pid>
```

バックトレースの出力については、`/var/log/gitlab/sidekiq/current`または`$GITLAB_HOME/log/sidekiq.log`で確認してください。バックトレースは長文で、通常はいくつかの`WARN`レベルのメッセージから始まります。単一のスレッドのバックトレースの例を次に示します:

```plaintext
2016-04-13T06:21:20.022Z 31517 TID-orn4urby0 WARN: ActiveRecord::RecordNotFound: Couldn't find Note with 'id'=3375386
2016-04-13T06:21:20.022Z 31517 TID-orn4urby0 WARN: /opt/gitlab/embedded/service/gem/ruby/2.1.0/gems/activerecord-4.2.5.2/lib/active_record/core.rb:155:in `find'
/opt/gitlab/embedded/service/gitlab-rails/app/workers/new_note_worker.rb:7:in `perform'
/opt/gitlab/embedded/service/gem/ruby/2.1.0/gems/sidekiq-4.0.1/lib/sidekiq/processor.rb:150:in `execute_job'
/opt/gitlab/embedded/service/gem/ruby/2.1.0/gems/sidekiq-4.0.1/lib/sidekiq/processor.rb:132:in `block (2 levels) in process'
/opt/gitlab/embedded/service/gem/ruby/2.1.0/gems/sidekiq-4.0.1/lib/sidekiq/middleware/chain.rb:127:in `block in invoke'
/opt/gitlab/embedded/service/gitlab-rails/lib/gitlab/sidekiq_middleware/memory_killer.rb:17:in `call'
/opt/gitlab/embedded/service/gem/ruby/2.1.0/gems/sidekiq-4.0.1/lib/sidekiq/middleware/chain.rb:129:in `block in invoke'
/opt/gitlab/embedded/service/gitlab-rails/lib/gitlab/sidekiq_middleware/arguments_logger.rb:6:in `call'
...
```

場合によっては、Sidekiqがハングアップし、`TTIN`シグナルに応答できないことがあります。これが発生した場合は、他のトラブルシューティング方法に進んでください。

## Rubyは`rbspy`でプロファイリング {#ruby-profiling-with-rbspy}

[rbspy](https://rbspy.github.io)は使いやすく、オーバーヘッドの少ないRubyプロファイラーであり、RubyプロセスによるCPU使用率のフレイムグラフスタイルの図を作成するために使用できます。

使用するためにGitLabを変更する必要はなく、依存関係もありません。インストールするには:

1. [`rbspy`リリースページ](https://github.com/rbspy/rbspy/releases)からバイナリをダウンロードします。
1. バイナリを実行可能にします。

Sidekiqワーカーを1分間プロファイリングするには、次を実行します:

```shell
sudo ./rbspy record --pid <sidekiq_pid> --duration 60 --file /tmp/sidekiq_profile.svg
```

![rbspyフレイムグラフの例](img/sidekiq_flamegraph_v14_6.png)

`rbspy`によって生成されたフレイムグラフのこの例では、Sidekiqプロセスの時間のほとんどすべてが、RuggedのネイティブC関数である`rev_parse`で費やされています。スタックでは、`rev_parse`が`ExpirePipelineCacheWorker`によって呼び出されていることがわかります。

`rbspy`には、[コンテナ化された環境](https://rbspy.github.io/using-rbspy/index.html#containers)で追加の[機能](https://man7.org/linux/man-pages/man7/capabilities.7.html)が必要です。少なくとも`SYS_PTRACE`機能が必要です。そうでない場合、`permission denied`エラーで終了します。

{{< tabs >}}

{{< tab title="Kubernetes" >}}

```yaml
securityContext:
  capabilities:
    add:
      - SYS_PTRACE
```

{{< /tab >}}

{{< tab title="Docker" >}}

```shell
docker run --cap-add SYS_PTRACE [...]
```

{{< /tab >}}

{{< tab title="Docker Compose" >}}

```yaml
services:
  ruby_container_name:
    # ...
    cap_add:
      - SYS_PTRACE
```

{{< /tab >}}

{{< /tabs >}}

## `perf`によるプロセスプロファイリング {#process-profiling-with-perf}

Linuxには、特定のプロセスが大量のCPUを消費している場合に役立つ`perf`というプロセスプロファイリングツールがあります。CPU使用率が高く、Sidekiqが`TTIN`シグナルに応答しない場合は、次の手順に進むことをお勧めします。

`perf`がシステムにインストールされていない場合は、`apt-get`または`yum`でインストールします:

```shell
# Debian
sudo apt-get install linux-tools

# Ubuntu (may require these additional Kernel packages)
sudo apt-get install linux-tools-common linux-tools-generic linux-tools-`uname -r`

# Red Hat/CentOS
sudo yum install perf
```

Sidekiq IDに対して`perf`を実行します:

```shell
sudo perf record -p <sidekiq_pid>
```

これを30〜60秒間実行してから、<kbd>Control</kbd>-<kbd>C</kbd>を押します。次に、`perf`レポートを表示します:

```shell
$ sudo perf report

# Sample output
Samples: 348K of event 'cycles', Event count (approx.): 280908431073
 97.69%            ruby  nokogiri.so         [.] xmlXPathNodeSetMergeAndClear
  0.18%            ruby  libruby.so.2.1.0    [.] objspace_malloc_increase
  0.12%            ruby  libc-2.12.so        [.] _int_malloc
  0.10%            ruby  libc-2.12.so        [.] _int_free
```

`perf`レポートからのサンプル出力は、CPUの97％がNokogiriと`xmlXPathNodeSetMergeAndClear`内で費やされていることを示しています。これほど明白な場合は、次にGitLabのどのジョブがNokogiriとXPathを使用するかを調査する必要があります。`TTIN`または`gdb`出力と組み合わせて、これが発生している対応するRubyコードを表示します。

## GNUプロジェクトデバッガ（`gdb`） {#the-gnu-project-debugger-gdb}

`gdb`は、Sidekiqをデバッグするためのもう1つの効果的なツールになる可能性があります。これにより、各スレッドを調べて何が問題を引き起こしているかをよりインタラクティブに確認できます。

`gdb`を使用してプロセスにアタッチすると、プロセスの標準操作が中断されます（`gdb`がアタッチされている間、Sidekiqはジョブを処理しません）。

まず、Sidekiq IDにアタッチします:

```shell
gdb -p <sidekiq_pid>
```

次に、すべてのスレッドに関する情報を収集します:

```plaintext
info threads

# Example output
30 Thread 0x7fe5fbd63700 (LWP 26060) 0x0000003f7cadf113 in poll () from /lib64/libc.so.6
29 Thread 0x7fe5f2b3b700 (LWP 26533) 0x0000003f7ce0b68c in pthread_cond_wait@@GLIBC_2.3.2 () from /lib64/libpthread.so.0
28 Thread 0x7fe5f2a3a700 (LWP 26534) 0x0000003f7ce0ba5e in pthread_cond_timedwait@@GLIBC_2.3.2 () from /lib64/libpthread.so.0
27 Thread 0x7fe5f2939700 (LWP 26535) 0x0000003f7ce0b68c in pthread_cond_wait@@GLIBC_2.3.2 () from /lib64/libpthread.so.0
26 Thread 0x7fe5f2838700 (LWP 26537) 0x0000003f7ce0b68c in pthread_cond_wait@@GLIBC_2.3.2 () from /lib64/libpthread.so.0
25 Thread 0x7fe5f2737700 (LWP 26538) 0x0000003f7ce0b68c in pthread_cond_wait@@GLIBC_2.3.2 () from /lib64/libpthread.so.0
24 Thread 0x7fe5f2535700 (LWP 26540) 0x0000003f7ce0b68c in pthread_cond_wait@@GLIBC_2.3.2 () from /lib64/libpthread.so.0
23 Thread 0x7fe5f2434700 (LWP 26541) 0x0000003f7ce0b68c in pthread_cond_wait@@GLIBC_2.3.2 () from /lib64/libpthread.so.0
22 Thread 0x7fe5f2232700 (LWP 26543) 0x0000003f7ce0b68c in pthread_cond_wait@@GLIBC_2.3.2 () from /lib64/libpthread.so.0
21 Thread 0x7fe5f2131700 (LWP 26544) 0x00007fe5f7b570f0 in xmlXPathNodeSetMergeAndClear ()
from /opt/gitlab/embedded/service/gem/ruby/2.1.0/gems/nokogiri-1.6.7.2/lib/nokogiri/nokogiri.so
...
```

例のNokogiriのように疑わしいスレッドが表示された場合は、詳細情報を取得することをお勧めします:

```plaintext
thread 21
bt

# Example output
#0  0x00007ff0d6afe111 in xmlXPathNodeSetMergeAndClear () from /opt/gitlab/embedded/service/gem/ruby/2.1.0/gems/nokogiri-1.6.7.2/lib/nokogiri/nokogiri.so
#1  0x00007ff0d6b0b836 in xmlXPathNodeCollectAndTest () from /opt/gitlab/embedded/service/gem/ruby/2.1.0/gems/nokogiri-1.6.7.2/lib/nokogiri/nokogiri.so
#2  0x00007ff0d6b09037 in xmlXPathCompOpEval () from /opt/gitlab/embedded/service/gem/ruby/2.1.0/gems/nokogiri-1.6.7.2/lib/nokogiri/nokogiri.so
#3  0x00007ff0d6b09017 in xmlXPathCompOpEval () from /opt/gitlab/embedded/service/gem/ruby/2.1.0/gems/nokogiri-1.6.7.2/lib/nokogiri/nokogiri.so
#4  0x00007ff0d6b092e0 in xmlXPathCompOpEval () from /opt/gitlab/embedded/service/gem/ruby/2.1.0/gems/nokogiri-1.6.7.2/lib/nokogiri/nokogiri.so
#5  0x00007ff0d6b0bc37 in xmlXPathRunEval () from /opt/gitlab/embedded/service/gem/ruby/2.1.0/gems/nokogiri-1.6.7.2/lib/nokogiri/nokogiri.so
#6  0x00007ff0d6b0be5f in xmlXPathEvalExpression () from /opt/gitlab/embedded/service/gem/ruby/2.1.0/gems/nokogiri-1.6.7.2/lib/nokogiri/nokogiri.so
#7  0x00007ff0d6a97dc3 in evaluate (argc=2, argv=0x1022d058, self=<value optimized out>) at xml_xpath_context.c:221
#8  0x00007ff0daeab0ea in vm_call_cfunc_with_frame (th=0x1022a4f0, reg_cfp=0x1032b810, ci=<value optimized out>) at vm_insnhelper.c:1510
```

すべてのスレッドから一度にバックトレースを出力するには:

```plaintext
set pagination off
thread apply all bt
```

`gdb`を使用したデバッグが完了したら、必ずプロセスからデタッチして終了してください:

```plaintext
detach
exit
```

## Sidekiqキルシグナル {#sidekiq-kill-signals}

TTINは、以前はログ記録のためにバックトレースを印刷するシグナルとして説明されていましたが、Sidekiqは他のシグナルにも応答します。たとえば、TSTPおよびTERMを使用してSidekiqを正常にシャットダウンできます。[Sidekiqシグナルのドキュメント](https://github.com/mperham/sidekiq/wiki/Signals#ttin)を参照してください。

## ブロッキングクエリの確認 {#check-for-blocking-queries}

Sidekiqがジョブを処理する速度が非常に速いため、データベースの競合が発生する可能性があります。以前に文書化されたバックトレースで、多くのスレッドがデータベースアダプターでスタックしていることが示されている場合は、ブロッキングクエリを確認してください。

PostgreSQL Wikiには、ブロッキングクエリを確認するために実行できるクエリの詳細が記載されています。クエリはPostgreSQLのバージョンによって異なります。クエリの詳細については、[ロックのモニタリング](https://wiki.postgresql.org/wiki/Lock_Monitoring)を参照してください。

## Sidekiqキューの管理 {#managing-sidekiq-queues}

[Sidekiq API](https://github.com/mperham/sidekiq/wiki/API)を使用して、Sidekiqでいくつかのトラブルシューティング手順を実行できます。

これらは管理者コマンドであり、インストールの規模のために現在の管理者インターフェースが適切でない場合にのみ使用する必要があります。

これらのコマンドはすべて、`gitlab-rails console`を使用して実行する必要があります。

### キューサイズの表示 {#view-the-queue-size}

```ruby
Sidekiq::Queue.new("pipeline_processing:build_queue").size
```

### エンキューされたすべてのジョブの列挙 {#enumerate-all-enqueued-jobs}

```ruby
queue = Sidekiq::Queue.new("chaos:chaos_sleep")
queue.each do |job|
  # job.klass # => 'MyWorker'
  # job.args # => [1, 2, 3]
  # job.jid # => jid
  # job.queue # => chaos:chaos_sleep
  # job["retry"] # => 3
  # job.item # => {
  #   "class"=>"Chaos::SleepWorker",
  #   "args"=>[1000],
  #   "retry"=>3,
  #   "queue"=>"chaos:chaos_sleep",
  #   "backtrace"=>true,
  #   "queue_namespace"=>"chaos",
  #   "jid"=>"39bc482b823cceaf07213523",
  #   "created_at"=>1566317076.266069,
  #   "correlation_id"=>"c323b832-a857-4858-b695-672de6f0e1af",
  #   "enqueued_at"=>1566317076.26761},
  # }

  # job.delete if job.jid == 'abcdef1234567890'
end
```

### 現在実行中のジョブの列挙 {#enumerate-currently-running-jobs}

```ruby
workers = Sidekiq::Workers.new
workers.each do |process_id, thread_id, work|
  # process_id is a unique identifier per Sidekiq process
  # thread_id is a unique identifier per thread
  # work is a Hash which looks like:
  # {"queue"=>"chaos:chaos_sleep",
  #  "payload"=>
  #  { "class"=>"Chaos::SleepWorker",
  #    "args"=>[1000],
  #    "retry"=>3,
  #    "queue"=>"chaos:chaos_sleep",
  #    "backtrace"=>true,
  #    "queue_namespace"=>"chaos",
  #    "jid"=>"b2a31e3eac7b1a99ff235869",
  #    "created_at"=>1566316974.9215662,
  #    "correlation_id"=>"e484fb26-7576-45f9-bf21-b99389e1c53c",
  #    "enqueued_at"=>1566316974.9229589},
  #  "run_at"=>1566316974}],
end
```

### 指定されたパラメータのSidekiqジョブの削除（破壊的） {#remove-sidekiq-jobs-for-given-parameters-destructive}

ジョブを条件付きで強制終了する一般的な方法は、次のコマンドです。これにより、キューに登録されているが開始されていないジョブが削除されます。実行中のジョブは強制終了できません。

```ruby
queue = Sidekiq::Queue.new('<queue name>')
queue.each { |job| job.delete if <condition>}
```

実行中のジョブのキャンセルについては、以下のセクションをご覧ください。

以前に文書化された方法では、`<queue-name>`は削除するジョブを含むキューの名前であり、`<condition>`は削除するジョブを決定します。

通常、`<condition>`はジョブの引数を参照します。これらは、問題のジョブのタイプによって異なります。特定のキューの引数を見つけるには、関連するワーカーファイルの`perform`関数をご覧ください。通常、`/app/workers/<queue-name>_worker.rb`にあります。

たとえば、`repository_import`には`project_id`がジョブの引数としてあり、`update_merge_requests`には`project_id, user_id, oldrev, newrev, ref`があります。

`job.args`はSidekiqジョブに提供されるすべての引数のリストであるため、引数は`job.args[<id>]`を使用してシーケンスIDで参照する必要があります。

次に例を示します:

```ruby
queue = Sidekiq::Queue.new('update_merge_requests')
# In this example, we want to remove any update_merge_requests jobs
# for the Project with ID 125 and ref `ref/heads/my_branch`
queue.each { |job| job.delete if job.args[0] == 125 and job.args[4] == 'ref/heads/my_branch' }
```

```ruby
# Canceling jobs like: `RepositoryImportWorker.new.perform_async(100)`
id_list = [100]

queue = Sidekiq::Queue.new('repository_import')
queue.each do |job|
  job.delete if id_list.include?(job.args[0])
end
```

### 特定のジョブIDの削除（破壊的） {#remove-specific-job-id-destructive}

```ruby
queue = Sidekiq::Queue.new('repository_import')
queue.each do |job|
  job.delete if job.jid == 'my-job-id'
end
```

### 特定のワーカーのSidekiqジョブの削除（破壊的） {#remove-sidekiq-jobs-for-a-specific-worker-destructive}

```ruby
queue = Sidekiq::Queue.new("default")

queue.each do |job|
  if job.klass == "TodosDestroyer::PrivateFeaturesWorker"
    # Uncomment the line below to actually delete jobs
    #job.delete
    puts "Deleted job ID #{job.jid}"
  end
end
```

## 実行中のジョブのキャンセル（破壊的） {#canceling-running-jobs-destructive}

これは非常に危険な操作であり、最後の手段として使用してください。これを行うと、ジョブが実行中に中断され、トランザクションの適切なロールバックが実装されることが保証されないため、データが破損する可能性があります。

```ruby
Gitlab::SidekiqDaemon::Monitor.cancel_job('job-id')
```

これには、`SIDEKIQ_MONITOR_WORKER=1`環境変数を使用してSidekiqを実行する必要があります。

割り込みの実行には`Thread.raise`を使用します。これには、[Rubyのタイムアウトが危険な理由（および`Thread.raise`が恐ろしい理由）](https://jvns.ca/blog/2015/11/27/why-rubys-timeout-is-dangerous-and-thread-dot-raise-is-terrifying/#timeout-how-it-works-and-why-thread-raise-is-terrifying)で説明されているように、多くの欠点があります。

## cronジョブの手動トリガー {#manually-trigger-a-cron-job}

`/admin/background_jobs`にアクセスすると、インスタンスでスケジュール/実行/保留されているジョブを調べることができます。

UIから「Enqueue Now」ボタンを選択して、cronジョブをトリガーできます。cronジョブをプログラムでトリガーするには、まず[Railsコンソール](../operations/rails_console.md)を開きます。

テストするcronジョブを見つけるには:

```ruby
job = Sidekiq::Cron::Job.find('job-name')

# get status of job:
job.status

# enqueue job right now!
job.enque!
```

たとえば、リポジトリミラーを更新する`update_all_mirrors_worker` cronジョブをトリガーするには、次のようにします:

```ruby
irb(main):001:0> job = Sidekiq::Cron::Job.find('update_all_mirrors_worker')
=>
#<Sidekiq::Cron::Job:0x00007f147f84a1d0
...
irb(main):002:0> job.status
=> "enabled"
irb(main):003:0> job.enque!
=> 257
```

使用可能なジョブのリストは、[workers](https://gitlab.com/gitlab-org/gitlab/-/tree/master/app/workers)ディレクトリにあります。

Sidekiqジョブの詳細については、[Sidekiq-cron](https://github.com/sidekiq-cron/sidekiq-cron#work-with-job)のドキュメントを参照してください。

## cronジョブの無効化 {#disabling-cron-jobs}

[**管理者**エリア](../admin_area.md#monitoring-section)のモニタリングセクションにアクセスして、Sidekiqcronジョブを無効にすることができます。コマンドラインと[Rails Runner](../operations/rails_console.md#using-the-rails-runner)を使用して、同じアクションを実行することもできます。

すべてのcronジョブを無効にするには:

```shell
sudo gitlab-rails runner 'Sidekiq::Cron::Job.all.map(&:disable!)'
```

すべてのcronジョブを有効にするには:

```shell
sudo gitlab-rails runner 'Sidekiq::Cron::Job.all.map(&:enable!)'
```

一度にジョブのサブセットのみを有効にする場合は、名前照合を使用できます。たとえば、名前に`geo`が含まれるジョブのみを有効にするには、次のようにします:

```shell
 sudo gitlab-rails runner 'Sidekiq::Cron::Job.all.select{ |j| j.name.match("geo") }.map(&:disable!)'
```

## Sidekiqジョブの重複排除冪等キーのクリア {#clearing-a-sidekiq-job-deduplication-idempotency-key}

場合によっては、（たとえば、cronジョブ）実行されることが予想されるジョブがまったく実行されないことが観察されます。ログを確認すると、`"job_status": "deduplicated"`でジョブが実行されていないことが確認されるインスタンスがある可能性があります。

これは、ジョブが失敗し、冪等キーが適切にクリアされなかった場合に発生する可能性があります。たとえば、[Sidekiqを停止すると、残りのジョブは25秒後に強制終了されます](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/4918)。

[デフォルトでは、キーは6時間後に期限切れになります](https://gitlab.com/gitlab-org/gitlab/-/blob/87c92f06eb92716a26679cd339f3787ae7edbdc3/lib/gitlab/sidekiq_middleware/duplicate_jobs/duplicate_job.rb#L23)が、冪等キーをすぐにクリアする場合は、次の手順に従ってください（提供される例は`Geo::VerificationBatchWorker`のものです）:

1. Sidekiqログで、ワーカークラスとジョブの`args`を見つけます:

   ```plaintext
   { ... "class":"Geo::VerificationBatchWorker","args":["container_repository"] ... }
   ```

1. [Railsコンソールセッション](../operations/rails_console.md#starting-a-rails-console-session)を開始します。
1. 次のスニペットを実行します:

   ```ruby
   worker_class = Geo::VerificationBatchWorker
   args = ["container_repository"]
   dj = Gitlab::SidekiqMiddleware::DuplicateJobs::DuplicateJob.new({ 'class' => worker_class.name, 'args' => args }, worker_class.queue)
   dj.send(:idempotency_key)
   dj.delete!
   ```

## Sidekiq BRPOP呼び出しによって引き起こされるRedisのCPU飽和 {#cpu-saturation-in-redis-caused-by-sidekiq-brpop-calls}

Sidekiq `BROP`呼び出しにより、RedisでのCPU使用率が増加する可能性があります。RedisでのCPU使用率を向上させるには、[`SIDEKIQ_SEMI_RELIABLE_FETCH_TIMEOUT`環境変数](../environment_variables.md)を増やします。

## エラー: `OpenSSL::Cipher::CipherError` {#error-opensslcipherciphererror}

次のようなエラーメッセージが表示された場合:

```plaintext
"OpenSSL::Cipher::CipherError","exception.message":"","exception.backtrace":["encryptor (3.0.0) lib/encryptor.rb:98:in `final'","encryptor (3.0.0) lib/encryptor.rb:98:in `crypt'","encryptor (3.0.0) lib/encryptor.rb:49:in `decrypt'"
```

このエラーは、プロセスが暗号化されたGitLabデータベースに保存されている暗号化されたデータを復号化することができないことを意味します。これは、`/etc/gitlab/gitlab-secrets.json`ファイルに問題があることを示しています。メインのGitLabノードからSidekiqノードにファイルをコピーしたことを確認してください。

## 関連トピック {#related-topics}

- [ElasticsearchワーカーがSidekiqにオーバーロードをかける](../../integration/elasticsearch/troubleshooting/migrations.md#elasticsearch-workers-overload-sidekiq)。
