# Troubleshooting Sidekiq

Sidekiq is the background job processor GitLab uses to asynchronously run
tasks. When things go wrong it can be difficult to troubleshoot. These
situations also tend to be high-pressure because a production system job queue
may be filling up. Users will notice when this happens because new branches
may not show up and merge requests may not be updated. The following are some
troubleshooting steps that will help you diagnose the bottleneck.

> **Note:** GitLab administrators/users should consider working through these
debug steps with GitLab Support so the backtraces can be analyzed by our team.
It may reveal a bug or necessary improvement in GitLab.

> **Note:** In any of the backtraces, be weary of suspecting cases where every
  thread appears to be waiting in the database, Redis, or waiting to acquire
  a mutex. This **may** mean there's contention in the database, for example,
  but look for one thread that is different than the rest. This other thread
  may be using all available CPU, or have a Ruby Global Interpreter Lock,
  preventing other threads from continuing.

## Thread dump

Send the Sidekiq process ID the `TTIN` signal and it will output thread
backtraces in the log file.

```
kill -TTIN <sidekiq_pid>
```

Check in `/var/log/gitlab/sidekiq/current` or `$GITLAB_HOME/log/sidekiq.log` for
the backtrace output. The backtraces will be lengthy and generally start with
several `WARN` level messages. Here's an example of a single thread's backtrace:

```
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

In some cases Sidekiq may be hung and unable to respond to the `TTIN` signal.
Move on to other troubleshooting methods if this happens.

## Process profiling with `perf`

Linux has a process profiling tool called `perf` that is helpful when a certain
process is eating up a lot of CPU. If you see high CPU usage and Sidekiq won't
respond to the `TTIN` signal, this is a good next step.

If `perf` is not installed on your system, install it with `apt-get` or `yum`:

```
# Debian
sudo apt-get install linux-tools

# Ubuntu (may require these additional Kernel packages)
sudo apt-get install linux-tools-common linux-tools-generic linux-tools-`uname -r`

# Red Hat/CentOS
sudo yum install perf
```

Run perf against the Sidekiq PID:

```
sudo perf record -p <sidekiq_pid>
```

Let this run for 30-60 seconds and then press Ctrl-C. Then view the perf report:

```
sudo perf report

# Sample output
Samples: 348K of event 'cycles', Event count (approx.): 280908431073
 97.69%            ruby  nokogiri.so         [.] xmlXPathNodeSetMergeAndClear
  0.18%            ruby  libruby.so.2.1.0    [.] objspace_malloc_increase
  0.12%            ruby  libc-2.12.so        [.] _int_malloc
  0.10%            ruby  libc-2.12.so        [.] _int_free
```

Above you see sample output from a perf report. It shows that 97% of the CPU is
being spent inside Nokogiri and `xmlXPathNodeSetMergeAndClear`. For something
this obvious you should then go investigate what job in GitLab would use
Nokogiri and XPath. Combine with `TTIN` or `gdb` output to show the
corresponding Ruby code where this is happening.

## The GNU Project Debugger (gdb)

`gdb` can be another effective tool for debugging Sidekiq. It gives you a little
more interactive way to look at each thread and see what's causing problems.

> **Note:** Attaching to a process with `gdb` will suspends the normal operation
  of the process (Sidekiq will not process jobs while `gdb` is attached).

Start by attaching to the Sidekiq PID:

```
gdb -p <sidekiq_pid>
```

Then gather information on all the threads:

```
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

If you see a suspicious thread, like the Nokogiri one above, you may want
to get more information:

```
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

To output a backtrace from all threads at once:

```
set pagination off
thread apply all bt
```

Once you're done debugging with `gdb`, be sure to detach from the process and
exit:

```
detach
exit
```

## Check for blocking queries

Sometimes the speed at which Sidekiq processes jobs can be so fast that it can
cause database contention. Check for blocking queries when backtraces above
show that many threads are stuck in the database adapter.

The PostgreSQL wiki has details on the query you can run to see blocking
queries. The query is different based on PostgreSQL version. See
[Lock Monitoring](https://wiki.postgresql.org/wiki/Lock_Monitoring) for
the query details.
