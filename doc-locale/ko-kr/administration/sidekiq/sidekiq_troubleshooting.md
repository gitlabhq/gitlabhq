---
stage: Tenant Scale
group: Tenant Services
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Sidekiq 문제 해결
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

Sidekiq는 GitLab이 작업을 비동기적으로 실행하기 위해 사용하는 백그라운드 작업 프로세서입니다. 문제가 발생하면 문제를 해결하기 어려울 수 있습니다. 프로덕션 시스템의 작업 큐가 가득 찼을 수 있기 때문에 이러한 상황들은 높은 압박감을 유발하는 경향이 있습니다. 사용자는 새로운 브랜치가 표시되지 않고 머지 리퀘스트가 업데이트되지 않을 때 이를 알아챕니다. 다음은 병목 현상을 진단하는 데 도움이 되는 문제 해결 단계입니다.

GitLab 관리자/사용자는 백트레이스를 분석할 수 있도록 GitLab 지원팀과 함께 이 디버그 단계를 진행하는 것을 고려해야 합니다. 이는 GitLab의 버그나 필요한 개선 사항을 드러낼 수 있습니다.

백트레이스에서 모든 스레드가 데이터베이스, Redis 또는 뮤텍스 획득을 기다리고 있는 것처럼 보이는 경우를 의심할 때 주의하세요. 이는 예를 들어 데이터베이스에 경합이 있음을 **may** 수 있지만, 다른 스레드 중 하나를 찾아보세요. 이 다른 스레드는 사용 가능한 모든 CPU를 사용하거나 Ruby 글로벌 인터프리터 락을 가지고 있어 다른 스레드가 계속 실행되지 않도록 방지할 수 있습니다.

## Sidekiq 작업에 인수 기록 {#log-arguments-to-sidekiq-jobs}

Sidekiq 작업에 전달된 일부 인수는 기본적으로 기록됩니다. 민감한 정보(예: 비밀번호 재설정 토큰) 기록을 피하기 위해 GitLab은 모든 워커에 대해 숫자 인수를 기록하며, 일부 특정 워커의 경우 인수가 민감하지 않은 경우 재정의합니다.

예시 로그 출력:

```json
{"severity":"INFO","time":"2020-06-08T14:37:37.892Z","class":"AdminEmailsWorker","args":["[FILTERED]","[FILTERED]","[FILTERED]"],"retry":3,"queue":"admin_emails","backtrace":true,"jid":"9e35e2674ac7b12d123e13cc","created_at":"2020-06-08T14:37:37.373Z","meta.user":"root","meta.caller_id":"Admin::EmailsController#create","correlation_id":"37D3lArJmT1","uber-trace-id":"2d942cc98cc1b561:6dc94409cfdd4d77:9fbe19bdee865293:1","enqueued_at":"2020-06-08T14:37:37.410Z","pid":65011,"message":"AdminEmailsWorker JID-9e35e2674ac7b12d123e13cc: done: 0.48085 sec","job_status":"done","scheduling_latency_s":0.001012,"redis_calls":9,"redis_duration_s":0.004608,"redis_read_bytes":696,"redis_write_bytes":6141,"duration_s":0.48085,"cpu_s":0.308849,"completed_at":"2020-06-08T14:37:37.892Z","db_duration_s":0.010742}
{"severity":"INFO","time":"2020-06-08T14:37:37.894Z","class":"ActiveJob::QueueAdapters::SidekiqAdapter::JobWrapper","wrapped":"ActionMailer::MailDeliveryJob","queue":"mailers","args":["[FILTERED]"],"retry":3,"backtrace":true,"jid":"e47a4f6793d475378432e3c8","created_at":"2020-06-08T14:37:37.884Z","meta.user":"root","meta.caller_id":"AdminEmailsWorker","correlation_id":"37D3lArJmT1","uber-trace-id":"2d942cc98cc1b561:29344de0f966446d:5c3b0e0e1bef987b:1","enqueued_at":"2020-06-08T14:37:37.885Z","pid":65011,"message":"ActiveJob::QueueAdapters::SidekiqAdapter::JobWrapper JID-e47a4f6793d475378432e3c8: start","job_status":"start","scheduling_latency_s":0.009473}
{"severity":"INFO","time":"2020-06-08T14:39:50.648Z","class":"NewIssueWorker","args":["455","1"],"retry":3,"queue":"new_issue","backtrace":true,"jid":"a24af71f96fd129ec47f5d1e","created_at":"2020-06-08T14:39:50.643Z","meta.user":"root","meta.project":"h5bp/html5-boilerplate","meta.root_namespace":"h5bp","meta.caller_id":"Projects::IssuesController#create","correlation_id":"f9UCZHqhuP7","uber-trace-id":"28f65730f99f55a3:a5d2b62dec38dffc:48ddd092707fa1b7:1","enqueued_at":"2020-06-08T14:39:50.646Z","pid":65011,"message":"NewIssueWorker JID-a24af71f96fd129ec47f5d1e: start","job_status":"start","scheduling_latency_s":0.001144}
```

[Sidekiq JSON 로깅](../logs/_index.md#sidekiqlog)을 사용할 때 인수 로그는 최대 10킬로바이트의 텍스트로 제한됩니다. 이 제한을 초과하는 모든 인수는 삭제되고 `"..."` 문자열을 포함하는 단일 인수로 바뀝니다.

`SIDEKIQ_LOG_ARGUMENTS` [환경 변수](https://docs.gitlab.com/omnibus/settings/environment-variables/)를 `0`(거짓)로 설정하여 인수 로깅을 비활성화할 수 있습니다.

예시:

```ruby
gitlab_rails['env'] = {"SIDEKIQ_LOG_ARGUMENTS" => "0"}
```

## Sidekiq 큐 백로그 또는 느린 성능 조사 {#investigating-sidekiq-queue-backlogs-or-slow-performance}

느린 Sidekiq 성능의 증상에는 머지 리퀘스트 상태 업데이트 문제 및 CI 파이프라인 시작 전 지연이 포함됩니다.

잠재적 원인은 다음을 포함합니다:

- GitLab 인스턴스에 더 많은 Sidekiq 워커가 필요할 수 있습니다. 기본적으로 단일 노드 Linux 패키지 설치는 하나의 워커를 실행하여 Sidekiq 작업 실행을 최대 1개 CPU 코어로 제한합니다. [여러 Sidekiq 워커 실행에 대해 자세히 읽기](extra_sidekiq_processes.md).

- 인스턴스는 더 많은 Sidekiq 워커로 구성되어 있지만 대부분의 추가 워커는 대기 중인 작업을 실행하도록 구성되지 않았습니다. 이는 인스턴스가 바쁠 때, 워커가 구성된 이후 수개월 또는 수년 동안 워크로드가 변경된 경우, 또는 GitLab 제품 변경의 결과로 작업 백로그를 야기할 수 있습니다.

다음 Ruby 스크립트를 사용하여 Sidekiq 워커의 상태에 대한 데이터를 수집합니다.

1. 스크립트를 생성합니다:

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

1. 실행 및 출력 캡처:

   ```shell
   sudo gitlab-rails runner /var/opt/gitlab/sidekiqcheck.rb > /tmp/sidekiqcheck_$(date '+%Y%m%d-%H:%M').out
   ```

   성능 이슈가 간헐적인 경우:

   - 5분마다 cron 작업에서 실행합니다. 파일을 충분한 공간이 있는 위치에 작성합니다. 파일당 최소 500KB를 허용합니다.

     ```shell
     cat > /etc/cron.d/sidekiqcheck <<EOF
     */5 * * * *  root  /opt/gitlab/bin/gitlab-rails runner /var/opt/gitlab/sidekiqcheck.rb > /tmp/sidekiqcheck_$(date '+\%Y\%m\%d-\%H:\%M').out 2>&1
     EOF
     ```

   - 데이터를 다시 참고하여 문제점을 확인하세요.

1. 출력을 분석합니다. 다음 명령어는 출력 파일의 디렉토리가 있다고 가정합니다.

   1. `grep 'Busy: ' *`은 실행 중인 작업의 개수를 표시합니다. `grep 'Enqueued: ' *`는 그 시점의 작업 백로그를 표시합니다.

   1. Sidekiq 부하 상태의 샘플에서 워커 전체의 바쁜 스레드 수를 확인합니다:

      ```shell
      ls | while read f ; do if grep -q 'Enqueued: 0' $f; then :
        else echo $f; egrep 'Busy:|Enqueued:|---- Processes' $f
        grep 'Threads:' $f ; fi
      done | more
      ```

      예시 출력:

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

      - 이 출력 파일에서 47개 스레드가 바빴고 363개 작업의 백로그가 있었습니다.
      - 13개 워커 프로세스 중 2개만 바빴습니다.
      - 이는 다른 워커들이 너무 구체적으로 구성되었음을 나타냅니다.
      - 전체 출력을 보고 바빴던 워커를 파악합니다. `sidekiq_queues` 구성과 `gitlab.rb`를 연관 지으세요.
      - 과부하 단일 워커 환경은 다음과 같을 수 있습니다:

        ```plaintext
        sidekiqcheck_20221024-14:00.out
               Busy: 25
           Enqueued: 363
        ---- Processes (1) ----
          Threads: 25 (25 busy)
        ```

   1. 출력 파일의 `---- Queues (xxx) ----` 섹션을 보고 그 시점에 대기 중인 작업을 확인합니다.

   1. 파일에는 그 시점의 Sidekiq 상태에 대한 저수준 세부 사항도 포함됩니다. 이는 워크로드 스파이크가 어디서 오는지 식별하는 데 유용할 수 있습니다.

      - `----------- workers -----------` 섹션은 요약의 `Busy` 수를 구성하는 작업을 자세히 설명합니다.
      - `----------- Queued Jobs -----------` 섹션은 `Enqueued`인 작업에 대한 세부 정보를 제공합니다.

## 스레드 덤프 {#thread-dump}

Sidekiq 프로세스 ID에 `TTIN` 신호를 보내 로그 파일에 스레드 백트레이스를 출력합니다.

```shell
kill -TTIN <sidekiq_pid>
```

`/var/log/gitlab/sidekiq/current` 또는 `$GITLAB_HOME/log/sidekiq.log`에서 백트레이스 출력을 확인합니다. 백트레이스는 길며 일반적으로 여러 `WARN` 수준 메시지로 시작합니다. 다음은 단일 스레드의 백트레이스 예시입니다:

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

경우에 따라 Sidekiq가 중단될 수 있으며 `TTIN` 신호에 응답할 수 없습니다. 이 경우 다른 문제 해결 방법으로 진행하세요.

## `rbspy`을(를) 사용한 Ruby 프로파일링 {#ruby-profiling-with-rbspy}

[rbspy](https://rbspy.github.io)는 사용하기 쉽고 오버헤드가 적은 Ruby 프로파일러로 Ruby 프로세스의 CPU 사용량을 나타내는 flamegraph 스타일 다이어그램을 생성할 수 있습니다.

GitLab을 변경할 필요가 없으며 종속성이 없습니다. 설치하려면:

1. [`rbspy` 릴리스 페이지](https://github.com/rbspy/rbspy/releases)에서 바이너리를 다운로드합니다.
1. 바이너리를 실행 가능하게 만듭니다.

Sidekiq 워커를 1분 동안 프로파일링하려면 다음을 실행합니다:

```shell
sudo ./rbspy record --pid <sidekiq_pid> --duration 60 --file /tmp/sidekiq_profile.svg
```

![rbspy flamegraph 예시](img/sidekiq_flamegraph_v14_6.png)

`rbspy`에서 생성된 flamegraph의 이 예시에서 Sidekiq 프로세스의 거의 모든 시간이 Rugged의 기본 C 함수인 `rev_parse`에 소비됩니다. 스택에서 `rev_parse`이(가) `ExpirePipelineCacheWorker`에 의해 호출되고 있음을 볼 수 있습니다.

`rbspy`은(는) [기능](https://man7.org/linux/man-pages/man7/capabilities.7.html) 이 [컨테이너화된 환경](https://rbspy.github.io/using-rbspy/index.html#containers)에서 필요합니다. 최소한 `SYS_PTRACE` 기능이 필요하며, 그렇지 않으면 `permission denied` 오류로 종료됩니다.

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

## `perf`을(를) 사용한 프로세스 프로파일링 {#process-profiling-with-perf}

Linux에는 프로세스 프로파일링 도구인 `perf`이(가) 있어서 많은 CPU를 사용하는 특정 프로세스를 찾을 때 유용합니다. 높은 CPU 사용량을 보고 Sidekiq가 `TTIN` 신호에 응답하지 않으면 다음 단계로 진행하는 것이 좋습니다.

`perf`이(가) 시스템에 설치되지 않은 경우 `apt-get` 또는 `yum`을(를) 사용하여 설치합니다:

```shell
# Debian
sudo apt-get install linux-tools

# Ubuntu (may require these additional Kernel packages)
sudo apt-get install linux-tools-common linux-tools-generic linux-tools-`uname -r`

# Red Hat/CentOS
sudo yum install perf
```

Sidekiq PID에 대해 `perf`을(를) 실행합니다:

```shell
sudo perf record -p <sidekiq_pid>
```

30-60초 동안 실행한 후 <kbd>Control</kbd>-<kbd>C</kbd>를 누릅니다. 그런 다음 `perf` 보고서를 확인합니다:

```shell
$ sudo perf report

# Sample output
Samples: 348K of event 'cycles', Event count (approx.): 280908431073
 97.69%            ruby  nokogiri.so         [.] xmlXPathNodeSetMergeAndClear
  0.18%            ruby  libruby.so.2.1.0    [.] objspace_malloc_increase
  0.12%            ruby  libc-2.12.so        [.] _int_malloc
  0.10%            ruby  libc-2.12.so        [.] _int_free
```

`perf` 보고서의 샘플 출력은 CPU의 97%가 Nokogiri 및 `xmlXPathNodeSetMergeAndClear` 내에서 소비되고 있음을 보여줍니다. 이처럼 명확한 경우 GitLab에서 Nokogiri 및 XPath를 사용할 작업을 조사해야 합니다. `TTIN` 또는 `gdb` 출력과 함께 이를 결합하여 발생 중인 해당 Ruby 코드를 보여줍니다.

## GNU 프로젝트 디버거(`gdb`) {#the-gnu-project-debugger-gdb}

`gdb`은(는) Sidekiq 디버깅을 위한 또 다른 효과적인 도구입니다. 각 스레드를 더 상호작용적으로 보고 문제를 유발하는 원인을 파악할 수 있는 방법을 제공합니다.

`gdb`를 사용하여 프로세스에 연결하면 프로세스의 표준 작동이 중지됩니다(Sidekiq가 `gdb`를 연결하는 동안 작업을 처리하지 않음).

Sidekiq PID에 연결하여 시작합니다:

```shell
gdb -p <sidekiq_pid>
```

그런 다음 모든 스레드에 대한 정보를 수집합니다:

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

예시의 Nokogiri 같은 의심스러운 스레드가 보이면 더 많은 정보를 얻을 수 있습니다:

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

모든 스레드에서 한 번에 백트레이스를 출력합니다:

```plaintext
set pagination off
thread apply all bt
```

`gdb`으로 디버깅을 완료한 후 프로세스에서 분리하고 종료해야 합니다:

```plaintext
detach
exit
```

## Sidekiq 종료 신호 {#sidekiq-kill-signals}

TTIN은 이전에 로깅을 위한 백트레이스를 인쇄하는 신호로 설명되었지만 Sidekiq는 다른 신호에도 응답합니다. 예를 들어, TSTP와 TERM은 Sidekiq을 정상적으로 종료하는 데 사용할 수 있으며, [Sidekiq Signals 문서](https://github.com/mperham/sidekiq/wiki/Signals#ttin)를 참조합니다.

## 차단 쿼리 확인 {#check-for-blocking-queries}

경우에 따라 Sidekiq이 작업을 처리하는 속도가 빨라서 데이터베이스 경합을 야기할 수 있습니다. 많은 스레드가 데이터베이스 어댑터에 갇혀 있음을 보여주는 이전에 문서화된 백트레이스가 있을 때 차단 쿼리를 확인합니다.

PostgreSQL wiki에는 차단 쿼리를 확인할 수 있는 쿼리에 대한 세부 정보가 있습니다. 쿼리는 PostgreSQL 버전에 따라 다릅니다. 쿼리 세부 정보는 [Lock Monitoring](https://wiki.postgresql.org/wiki/Lock_Monitoring)을(를) 참조합니다.

## Sidekiq 큐 관리 {#managing-sidekiq-queues}

[Sidekiq API](https://github.com/mperham/sidekiq/wiki/API)를 사용하여 Sidekiq에서 여러 문제 해결 단계를 수행할 수 있습니다.

이는 관리 명령어이며 현재 관리 인터페이스가 설치 규모로 인해 적합하지 않은 경우에만 사용해야 합니다.

모든 이 명령어는 `gitlab-rails console`을(를) 사용하여 실행해야 합니다.

### 큐 크기 보기 {#view-the-queue-size}

```ruby
Sidekiq::Queue.new("pipeline_processing:build_queue").size
```

### 모든 대기 중인 작업 나열 {#enumerate-all-enqueued-jobs}

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

### 현재 실행 중인 작업 나열 {#enumerate-currently-running-jobs}

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

### 주어진 매개변수에 대해 Sidekiq 작업 제거(파괴적) {#remove-sidekiq-jobs-for-given-parameters-destructive}

작업을 조건부로 종료하는 일반적인 방법은 대기 중이지만 시작되지 않은 작업을 제거하는 다음 명령어입니다. 실행 중인 작업은 종료할 수 없습니다.

```ruby
queue = Sidekiq::Queue.new('<queue name>')
queue.each { |job| job.delete if <condition>}
```

실행 중인 작업 취소에 대한 아래 섹션을 참조하세요.

이전에 문서화된 방법에서 `<queue-name>`은(는) 삭제하려는 작업을 포함하는 큐의 이름이고 `<condition>`는 삭제할 작업을 결정합니다.

일반적으로 `<condition>`은(는) 작업 인수를 참조하며, 이는 질문의 작업 유형에 따라 다릅니다. 특정 큐에 대한 인수를 찾으려면 관련 워커 파일의 `perform` 함수를 살펴볼 수 있으며, 일반적으로 `/app/workers/<queue-name>_worker.rb`에 있습니다.

예를 들어 `repository_import`은(는) `project_id`를 작업 인수로 갖고 있고, `update_merge_requests`은(는) `project_id, user_id, oldrev, newrev, ref`를 갖고 있습니다.

인수는 `job.args[<id>]`을(를) 사용하여 시퀀스 ID로 참조해야 합니다. `job.args`은(는) Sidekiq 작업에 제공되는 모든 인수의 목록이기 때문입니다.

몇 가지 예를 들면:

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

### 특정 작업 ID 제거(파괴적) {#remove-specific-job-id-destructive}

```ruby
queue = Sidekiq::Queue.new('repository_import')
queue.each do |job|
  job.delete if job.jid == 'my-job-id'
end
```

### 특정 워커에 대해 Sidekiq 작업 제거(파괴적) {#remove-sidekiq-jobs-for-a-specific-worker-destructive}

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

## 실행 중인 작업 취소(파괴적) {#canceling-running-jobs-destructive}

이는 매우 위험한 작업이므로 마지막 수단으로 사용합니다. 작업이 실행 중에 중단되고 거래의 적절한 롤백이 구현되었다는 보장이 없으므로 이렇게 하면 데이터 손상이 발생할 수 있습니다.

```ruby
Gitlab::SidekiqDaemon::Monitor.cancel_job('job-id')
```

이는 `SIDEKIQ_MONITOR_WORKER=1` 환경 변수로 Sidekiq을 실행해야 합니다.

인터럽트 수행을 위해 `Thread.raise`을(를) 사용합니다. 이는 [Ruby의 Timeout이 위험한 이유(및 `Thread.raise`이(가) 무서운 이유)](https://jvns.ca/blog/2015/11/27/why-rubys-timeout-is-dangerous-and-thread-dot-raise-is-terrifying/#timeout-how-it-works-and-why-thread-raise-is-terrifying)에 언급된 대로 여러 단점이 있습니다.

## cron 작업 수동 트리거 {#manually-trigger-a-cron-job}

`/admin/background_jobs`를 방문하면 인스턴스에서 예약/실행/대기 중인 작업을 확인할 수 있습니다.

"Enqueue Now" 버튼을 선택하여 UI에서 cron 작업을 트리거할 수 있습니다. cron 작업을 프로그래밍 방식으로 트리거하려면 먼저 [Rails 콘솔](../operations/rails_console.md)을 엽니다.

테스트할 cron 작업을 찾습니다:

```ruby
job = Sidekiq::Cron::Job.find('job-name')

# get status of job:
job.status

# enqueue job right now!
job.enque!
```

예를 들어 리포지토리 미러를 업데이트하는 `update_all_mirrors_worker` cron 작업을 트리거하려면:

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

사용 가능한 작업의 목록은 [워커](https://gitlab.com/gitlab-org/gitlab/-/tree/master/app/workers) 디렉토리에서 찾을 수 있습니다.

Sidekiq 작업에 대한 자세한 정보는 [Sidekiq-cron](https://github.com/sidekiq-cron/sidekiq-cron#work-with-job) 문서를 참조합니다.

## cron 작업 비활성화 {#disabling-cron-jobs}

[**운영자** 영역의 모니터링 섹션](../admin_area.md#monitoring-section)을 방문하여 모든 Sidekiq cron 작업을 비활성화할 수 있습니다. 명령줄 및 [Rails Runner](../operations/rails_console.md#using-the-rails-runner)을 사용하여 같은 작업을 수행할 수도 있습니다.

모든 cron 작업을 비활성화합니다:

```shell
sudo gitlab-rails runner 'Sidekiq::Cron::Job.all.map(&:disable!)'
```

모든 cron 작업을 활성화합니다:

```shell
sudo gitlab-rails runner 'Sidekiq::Cron::Job.all.map(&:enable!)'
```

한 번에 작업의 부분집합만 활성화하려면 이름 일치를 사용할 수 있습니다. 예를 들어 이름에 `geo`이(가) 있는 작업만 활성화합니다:

```shell
 sudo gitlab-rails runner 'Sidekiq::Cron::Job.all.select{ |j| j.name.match("geo") }.map(&:disable!)'
```

## Sidekiq 작업 중복 제거 멱등성 키 지우기 {#clearing-a-sidekiq-job-deduplication-idempotency-key}

때때로 실행될 것으로 예상되는 작업(예: cron 작업)이 전혀 실행되지 않는 것으로 관찰됩니다. 로그를 확인할 때 `"job_status": "deduplicated"`을(를) 사용하여 작업이 실행되지 않는 인스턴스가 있을 수 있습니다.

이는 작업이 실패하고 멱등성 키가 제대로 지워지지 않았을 때 발생할 수 있습니다. 예를 들어 [Sidekiq 중지는 25초 후 남은 작업을 모두 종료합니다](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/4918).

[기본적으로 키는 6시간 후 만료됩니다](https://gitlab.com/gitlab-org/gitlab/-/blob/87c92f06eb92716a26679cd339f3787ae7edbdc3/lib/gitlab/sidekiq_middleware/duplicate_jobs/duplicate_job.rb#L23). 그러나 멱등성 키를 즉시 지우려면 다음 단계를 따릅니다(`Geo::VerificationBatchWorker`에 대해 제공된 예시):

1. Sidekiq 로그에서 작업의 워커 클래스 및 `args`을(를) 찾습니다:

   ```plaintext
   { ... "class":"Geo::VerificationBatchWorker","args":["container_repository"] ... }
   ```

1. [Rails 콘솔 세션](../operations/rails_console.md#starting-a-rails-console-session)을 시작합니다.
1. 다음 스니펫을 실행합니다:

   ```ruby
   worker_class = Geo::VerificationBatchWorker
   args = ["container_repository"]
   dj = Gitlab::SidekiqMiddleware::DuplicateJobs::DuplicateJob.new({ 'class' => worker_class.name, 'args' => args }, worker_class.queue)
   dj.send(:idempotency_key)
   dj.delete!
   ```

## Sidekiq BRPOP 호출로 인한 Redis의 CPU 포화 {#cpu-saturation-in-redis-caused-by-sidekiq-brpop-calls}

Sidekiq `BROP` 호출은 Redis의 CPU 사용량을 증가시킬 수 있습니다. [`SIDEKIQ_SEMI_RELIABLE_FETCH_TIMEOUT` 환경 변수](../environment_variables.md)를 늘려 Redis의 CPU 사용량을 개선합니다.

## 오류: `OpenSSL::Cipher::CipherError` {#error-opensslcipherciphererror}

다음과 같은 오류 메시지가 나타나면:

```plaintext
"OpenSSL::Cipher::CipherError","exception.message":"","exception.backtrace":["encryptor (3.0.0) lib/encryptor.rb:98:in `final'","encryptor (3.0.0) lib/encryptor.rb:98:in `crypt'","encryptor (3.0.0) lib/encryptor.rb:49:in `decrypt'"
```

이 오류는 프로세스가 GitLab 데이터베이스에 저장된 암호화된 데이터를 해독할 수 없음을 의미합니다. 이는 `/etc/gitlab/gitlab-secrets.json` 파일에 문제가 있음을 나타냅니다. 주 GitLab 노드에서 Sidekiq 노드로 파일을 복사했는지 확인하세요.

## 관련 항목 {#related-topics}

- [Elasticsearch 워커가 Sidekiq을 과부하합니다](../../integration/elasticsearch/troubleshooting/migrations.md#elasticsearch-workers-overload-sidekiq).
