---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Performance Guidelines
---

This document describes various guidelines to ensure good and consistent performance of GitLab.

## Performance Documentation

- General:
  - [Solving performance issues](#workflow)
  - [Handbook performance page](https://handbook.gitlab.com/handbook/engineering/performance/)
  - [Merge request performance guidelines](merge_request_concepts/performance.md)
- Backend:
  - [Tooling](#tooling)
  - Database:
    - [Query performance guidelines](database/query_performance.md)
    - [Pagination performance guidelines](database/pagination_performance_guidelines.md)
    - [Keyset pagination performance](database/keyset_pagination.md#performance)
  - [Troubleshooting import/export performance issues](../user/project/settings/import_export_troubleshooting.md#troubleshooting-performance-issues)
  - [Pipelines performance in the `gitlab` project](pipelines/performance.md)
- Frontend:
  - [Performance guidelines and monitoring](fe_guide/performance.md)
  - [Browser performance testing guidelines](../ci/testing/browser_performance_testing.md)
  - [`gdk measure` and `gdk measure-workflow`](https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/gdk_commands.md#measure-performance)
- QA:
  - [Load performance testing](../ci/testing/load_performance_testing.md)
  - [GitLab Performance Tool project](https://gitlab.com/gitlab-org/quality/performance)
  - [Review apps performance metrics](testing_guide/review_apps.md#performance-metrics)
- Monitoring & Overview:
  - [GitLab performance monitoring](../administration/monitoring/performance/_index.md)
  - [Development department performance indicators](https://handbook.gitlab.com/handbook/engineering/development/performance-indicators/)
  - [Service measurement](service_measurement.md)
- Self-managed administration and customer-focused:
  - [File system performance benchmarking](../administration/operations/filesystem_benchmarking.md)
  - [Sidekiq performance troubleshooting](../administration/sidekiq/sidekiq_troubleshooting.md)

## Workflow

The process of solving performance problems is roughly as follows:

1. Make sure there's an issue open somewhere (for example, on the GitLab CE issue
   tracker), and create one if there is not. See [#15607](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/15607) for an example.
1. Measure the performance of the code in a production environment such as
   GitLab.com (see the [Tooling](#tooling) section below). Performance should be
   measured over a period of _at least_ 24 hours.
1. Add your findings based on the measurement period (screenshots of graphs,
   timings, etc) to the issue mentioned in step 1.
1. Solve the problem.
1. Create a merge request, assign the "Performance" label and follow the [performance review process](merge_request_concepts/performance.md).
1. Once a change has been deployed make sure to _again_ measure for at least 24
   hours to see if your changes have any impact on the production environment.
1. Repeat until you're done.

When providing timings make sure to provide:

- The 95th percentile
- The 99th percentile
- The mean

When providing screenshots of graphs, make sure that both the X and Y axes and
the legend are clearly visible. If you happen to have access to GitLab.com's own
monitoring tools you should also provide a link to any relevant
graphs/dashboards.

## Tooling

GitLab provides built-in tools to help improve performance and availability:

- [Profiling](profiling.md).
- [Distributed Tracing](distributed_tracing.md)
- [GitLab Performance Monitoring](../administration/monitoring/performance/_index.md).
- [QueryRecoder](database/query_recorder.md) for preventing `N+1` regressions.
- [Chaos endpoints](chaos_endpoints.md) for testing failure scenarios. Intended mainly for testing availability.
- [Service measurement](service_measurement.md) for measuring and logging service execution.

GitLab team members can use [GitLab.com's performance monitoring systems](https://handbook.gitlab.com/handbook/engineering/monitoring/) located at
[`dashboards.gitlab.net`](https://dashboards.gitlab.net), this requires you to sign in using your
`@gitlab.com` email address. Non-GitLab team-members are advised to set up their
own Prometheus and Grafana stack.

## Benchmarks

Benchmarks are almost always useless. Benchmarks usually only test small bits of
code in isolation and often only measure the best case scenario. On top of that,
benchmarks for libraries (such as a Gem) tend to be biased in favour of the
library. After all there's little benefit to an author publishing a benchmark
that shows they perform worse than their competitors.

Benchmarks are only really useful when you need a rough (emphasis on "rough")
understanding of the impact of your changes. For example, if a certain method is
slow a benchmark can be used to see if the changes you're making have any impact
on the method's performance. However, even when a benchmark shows your changes
improve performance there's no guarantee the performance also improves in a
production environment.

When writing benchmarks you should almost always use
[benchmark-ips](https://github.com/evanphx/benchmark-ips). Ruby's `Benchmark`
module that comes with the standard library is rarely useful as it runs either a
single iteration (when using `Benchmark.bm`) or two iterations (when using
`Benchmark.bmbm`). Running this few iterations means external factors, such as a
video streaming in the background, can very easily skew the benchmark
statistics.

Another problem with the `Benchmark` module is that it displays timings, not
iterations. This means that if a piece of code completes in a very short period
of time it can be very difficult to compare the timings before and after a
certain change. This in turn leads to patterns such as the following:

```ruby
Benchmark.bmbm(10) do |bench|
  bench.report 'do something' do
    100.times do
      ... work here ...
    end
  end
end
```

This however leads to the question: how many iterations should we run to get
meaningful statistics?

The [`benchmark-ips`](https://github.com/evanphx/benchmark-ips)
gem takes care of all this and much more. You should therefore use it instead of the `Benchmark`
module.

The GitLab Gemfile also contains the [`benchmark-memory`](https://github.com/michaelherold/benchmark-memory)
gem, which works similarly to the `benchmark` and `benchmark-ips` gems. However, `benchmark-memory`
instead returns the memory size, objects, and strings allocated and retained during the benchmark.

In short:

- Don't trust benchmarks you find on the internet.
- Never make claims based on just benchmarks, always measure in production to
  confirm your findings.
- X being N times faster than Y is meaningless if you don't know what impact it
  has on your production environment.
- A production environment is the _only_ benchmark that always tells the truth
  (unless your performance monitoring systems are not set up correctly).
- If you must write a benchmark use the benchmark-ips Gem instead of Ruby's
  `Benchmark` module.

## Profiling with Stackprof

By collecting snapshots of process state at regular intervals, profiling allows
you to see where time is spent in a process. The
[Stackprof](https://github.com/tmm1/stackprof) gem is included in GitLab,
allowing you to profile which code is running on CPU in detail.

It's important to note that profiling an application *alters its performance*.
Different profiling strategies have different overheads. Stackprof is a sampling
profiler. It samples stack traces from running threads at a configurable
frequency (for example, 100 hz, that is 100 stacks per second). This type of profiling
has quite a low (albeit non-zero) overhead and is generally considered to be
safe for production.

A profiler can be a very useful tool during development, even if it does run *in
an unrepresentative environment*. In particular, a method is not necessarily
troublesome just because it's executed many times, or takes a long time to
execute. Profiles are tools you can use to better understand what is happening
in an application - using that information wisely is up to you!

There are multiple ways to create a profile with Stackprof.

### Wrapping a code block

To profile a specific code block, you can wrap that block in a `Stackprof.run` call:

```ruby
StackProf.run(mode: :wall, out: 'tmp/stackprof-profiling.dump') do
  #...
end
```

This creates a `.dump` file that you can [read](#reading-a-stackprof-profile).
For all available options, see the [Stackprof documentation](https://github.com/tmm1/stackprof#all-options).

### Performance bar

With the [Performance bar](../administration/monitoring/performance/performance_bar.md),
you have the option to profile a request using Stackprof and immediately output the results to a
[Speedscope flamegraph](profiling.md#speedscope-flamegraphs).

### RSpec profiling with Stackprof

To create a profile from a spec, identify (or create) a spec that
exercises the troublesome code path, then run it using the `bin/rspec-stackprof`
helper, for example:

```shell
$ LIMIT=10 bin/rspec-stackprof spec/policies/project_policy_spec.rb

8/8 |====== 100 ======>| Time: 00:00:18

Finished in 18.19 seconds (files took 4.8 seconds to load)
8 examples, 0 failures

==================================
 Mode: wall(1000)
 Samples: 17033 (5.59% miss rate)
 GC: 1901 (11.16%)
==================================
    TOTAL    (pct)     SAMPLES    (pct)     FRAME
     6000  (35.2%)        2566  (15.1%)     Sprockets::Cache::FileStore#get
     2018  (11.8%)         888   (5.2%)     ActiveRecord::ConnectionAdapters::PostgreSQLAdapter#exec_no_cache
     1338   (7.9%)         640   (3.8%)     ActiveRecord::ConnectionAdapters::PostgreSQL::DatabaseStatements#execute
     3125  (18.3%)         394   (2.3%)     Sprockets::Cache::FileStore#safe_open
      913   (5.4%)         301   (1.8%)     ActiveRecord::ConnectionAdapters::PostgreSQLAdapter#exec_cache
      288   (1.7%)         288   (1.7%)     ActiveRecord::Attribute#initialize
      246   (1.4%)         246   (1.4%)     Sprockets::Cache::FileStore#safe_stat
      295   (1.7%)         193   (1.1%)     block (2 levels) in class_attribute
      187   (1.1%)         187   (1.1%)     block (4 levels) in class_attribute
```

You can limit the specs that are run by passing any arguments `RSpec` would
usually take.

### Using Stackprof in production

Stackprof can also be used to profile production workloads.

In order to enable production profiling for Ruby processes, you can set the `STACKPROF_ENABLED` environment variable to `true`.

The following configuration options can be configured:

- `STACKPROF_ENABLED`: Enables Stackprof signal handler on SIGUSR2 signal.
  Defaults to `false`.
- `STACKPROF_MODE`: See [sampling modes](https://github.com/tmm1/stackprof#sampling).
  Defaults to `cpu`.
- `STACKPROF_INTERVAL`: Sampling interval. Unit semantics depend on `STACKPROF_MODE`.
  For `object` mode this is a per-event interval (every `nth` event is sampled)
  and defaults to `100`.
  For other modes such as `cpu` this is a frequency interval and defaults to `10100` μs (99 hz).
- `STACKPROF_FILE_PREFIX`: File path prefix where profiles are stored. Defaults
  to `$TMPDIR` (often corresponds to `/tmp`).
- `STACKPROF_TIMEOUT_S`: Profiling timeout in seconds. Profiling will
  automatically stop after this time has elapsed. Defaults to `30`.
- `STACKPROF_RAW`: Whether to collect raw samples or only aggregates. Raw
  samples are needed to generate flame graphs, but they do have a higher memory
  and disk overhead. Defaults to `true`.

Once enabled, profiling can be triggered by sending a `SIGUSR2` signal to the
Ruby process. The process begins sampling stacks. Profiling can be stopped
by sending another `SIGUSR2`. Alternatively, it stops automatically after
the timeout.

Once profiling stops, the profile is written out to disk at
`$STACKPROF_FILE_PREFIX/stackprof.$PID.$RAND.profile`. It can then be inspected
further through the `stackprof` command-line tool, as described in the
[Reading a Stackprof profile section](#reading-a-stackprof-profile).

Currently supported profiling targets are:

- Puma worker
- Sidekiq

NOTE:
The Puma master process is not supported.
Sending SIGUSR2 to it triggers restarts. In the case of Puma,
take care to only send the signal to Puma workers.

This can be done via `pkill -USR2 puma:`. The `:` distinguishes between `puma
4.3.3.gitlab.2 ...` (the master process) from `puma: cluster worker 0: ...` (the
worker processes), selecting the latter.

For Sidekiq, the signal can be sent to the `sidekiq-cluster` process with
`pkill -USR2 bin/sidekiq-cluster` which forwards the signal to all Sidekiq
children. Alternatively, you can also select a specific PID of interest.

### Reading a Stackprof profile

The output is sorted by the `Samples` column by default. This is the number of samples taken where
the method is the one currently executed. The `Total` column shows the number of samples taken where
the method (or any of the methods it calls) is executed.

To create a graphical view of the call stack:

```shell
stackprof tmp/project_policy_spec.rb.dump --graphviz > project_policy_spec.dot
dot -Tsvg project_policy_spec.dot > project_policy_spec.svg
```

To load the profile in [KCachegrind](https://kcachegrind.github.io/):

```shell
stackprof tmp/project_policy_spec.rb.dump --callgrind > project_policy_spec.callgrind
kcachegrind project_policy_spec.callgrind # Linux
qcachegrind project_policy_spec.callgrind # Mac
```

You can also generate and view the resultant flame graph. To view a flame graph that
`bin/rspec-stackprof` creates, you must set the `RAW` environment variable to `true` when running
`bin/rspec-stackprof`.

It might take a while to generate based on the output file size:

```shell
# Generate
stackprof --flamegraph tmp/group_member_policy_spec.rb.dump > group_member_policy_spec.flame

# View
stackprof --flamegraph-viewer=group_member_policy_spec.flame
```

To export the flame graph to an SVG file, use [Brendan Gregg's FlameGraph tool](https://github.com/brendangregg/FlameGraph):

```shell
stackprof --stackcollapse  /tmp/group_member_policy_spec.rb.dump | flamegraph.pl > flamegraph.svg
```

It's also possible to view flame graphs through [Speedscope](https://github.com/jlfwong/speedscope).
You can do this when using the [performance bar](profiling.md#speedscope-flamegraphs)
and when [profiling code blocks](https://github.com/jlfwong/speedscope/wiki/Importing-from-stackprof-(ruby)).
This option isn't supported by `bin/rspec-stackprof`.

You can profile specific methods by using `--method method_name`:

```shell
$ stackprof tmp/project_policy_spec.rb.dump --method access_allowed_to

ProjectPolicy#access_allowed_to? (/Users/royzwambag/work/gitlab-development-kit/gitlab/app/policies/project_policy.rb:793)
  samples:     0 self (0.0%)  /    578 total (0.7%)
  callers:
     397  (   68.7%)  block (2 levels) in <class:ProjectPolicy>
      95  (   16.4%)  block in <class:ProjectPolicy>
      86  (   14.9%)  block in <class:ProjectPolicy>
  callees (578 total):
     399  (   69.0%)  ProjectPolicy#team_access_level
     141  (   24.4%)  Project::GeneratedAssociationMethods#project_feature
      30  (    5.2%)  DeclarativePolicy::Base#can?
       8  (    1.4%)  Featurable#access_level
  code:
                                  |   793  |   def access_allowed_to?(feature)
  141    (0.2%)                   |   794  |     return false unless project.project_feature
                                  |   795  |
    8    (0.0%)                   |   796  |     case project.project_feature.access_level(feature)
                                  |   797  |     when ProjectFeature::DISABLED
                                  |   798  |       false
                                  |   799  |     when ProjectFeature::PRIVATE
  429    (0.5%)                   |   800  |       can?(:read_all_resources) || team_access_level >= ProjectFeature.required_minimum_access_level(feature)
                                  |   801  |     else
```

When using Stackprof to profile specs, the profile includes the work done by the test suite and the
application code. You can therefore use these profiles to investigate slow tests as well. However,
for smaller runs (like this example), this means that the cost of setting up the test suite tends to
dominate.

## RSpec profiling

The GitLab development environment also includes the
[`rspec_profiling`](https://github.com/foraker/rspec_profiling) gem, which is used
to collect data on spec execution times. This is useful for analyzing the
performance of the test suite itself, or seeing how the performance of a spec
may have changed over time.

To activate profiling in your local environment, run the following:

```shell
export RSPEC_PROFILING=yes
rake rspec_profiling:install
```

This creates an SQLite3 database in `tmp/rspec_profiling`, into which statistics
are saved every time you run specs with the `RSPEC_PROFILING` environment
variable set.

Ad-hoc investigation of the collected results can be performed in an interactive
shell:

```shell
$ rake rspec_profiling:console

irb(main):001:0> results.count
=> 231
irb(main):002:0> results.last.attributes.keys
=> ["id", "commit", "date", "file", "line_number", "description", "time", "status", "exception", "query_count", "query_time", "request_count", "request_time", "created_at", "updated_at"]
irb(main):003:0> results.where(status: "passed").average(:time).to_s
=> "0.211340155844156"
```

These results can also be placed into a PostgreSQL database by setting the
`RSPEC_PROFILING_POSTGRES_URL` variable. This is used to profile the test suite
when running in the CI environment.

We store these results also when running nightly scheduled CI jobs on the
default branch on `gitlab.com`. Statistics of these profiling data are
[available online](https://gitlab-org.gitlab.io/rspec_profiling_stats/). For
example, you can find which tests take longest to run or which execute the most
queries. Use this to optimize our tests or identify performance
issues in our code.

## Memory optimization

We can use a set of different techniques, often in combination, to track down memory issues:

- Leaving the code intact and wrapping a profiler around it.
- Use memory allocation counters for requests and services.
- Monitor memory usage of the process while disabling/enabling different parts of the code we suspect could be problematic.

### Memory allocations

Ruby shipped with GitLab includes a special patch to allow [tracing memory allocations](https://gitlab.com/gitlab-org/gitlab/-/issues/296530).
This patch is available by default for
[Omnibus](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/4948),
[CNG](https://gitlab.com/gitlab-org/build/CNG/-/merge_requests/591),
[GitLab CI](https://gitlab.com/gitlab-org/gitlab-build-images/-/merge_requests/355),
[GCK](https://gitlab.com/gitlab-org/gitlab-compose-kit/-/merge_requests/149)
and can additionally be enabled for [GDK](https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/advanced.md#apply-custom-patches-for-ruby).

This patch provides the following metrics that make it easier to understand efficiency of memory use for a given code path:

- `mem_total_bytes`: the number of bytes consumed both due to new objects being allocated into existing object slots
                     plus additional memory allocated for large objects (that is, `mem_bytes + slot_size * mem_objects`).
- `mem_bytes`: the number of bytes allocated by `malloc` for objects that did not fit into an existing object slot.
- `mem_objects`: the number of objects allocated.
- `mem_mallocs`: the number of `malloc` calls.

The number of objects and bytes allocated impact how often GC cycles happen.
Fewer object allocations result in a significantly more responsive application.

It is advised that web server requests do not allocate more than `100k mem_objects`
and `100M mem_bytes`. You can view the current usage on [GitLab.com](https://log.gprd.gitlab.net/goto/3a9678bb595e3f89a0c7b5c61bcc47b9).

#### Checking memory pressure of own code

There are two ways of measuring your own code:

1. Review `api_json.log`, `development_json.log`, `sidekiq.log` that includes memory allocation counters.
1. Use `Gitlab::Memory::Instrumentation.with_memory_allocations` for a given code block and log it.
1. Use [Measuring module](service_measurement.md)

```json
{"time":"2021-02-15T11:20:40.821Z","severity":"INFO","duration_s":0.27412,"db_duration_s":0.05755,"view_duration_s":0.21657,"status":201,"method":"POST","path":"/api/v4/projects/user/1","mem_objects":86705,"mem_bytes":4277179,"mem_mallocs":22693,"correlation_id":"...}
```

#### Different types of allocations

The `mem_*` values represent different aspects of how objects and memory are allocated in Ruby:

- The following example will create around of `1000` of `mem_objects` since strings
  can be frozen, and while the underlying string object remains the same, we still need to allocate 1000 references to this string:

  ```ruby
  Gitlab::Memory::Instrumentation.with_memory_allocations do
    1_000.times { '0123456789' }
  end

  => {:mem_objects=>1001, :mem_bytes=>0, :mem_mallocs=>0}
  ```

- The following example will create around of `1000` of `mem_objects`, as strings are created dynamically.
  Each of them will not allocate additional memory, as they fit into Ruby slot of 40 bytes:

  ```ruby
  Gitlab::Memory::Instrumentation.with_memory_allocations do
    s = '0'
    1_000.times { s * 23 }
  end

  => {:mem_objects=>1002, :mem_bytes=>0, :mem_mallocs=>0}
  ```

- The following example will create around of `1000` of `mem_objects`, as strings are created dynamically.
  Each of them will allocate additional memory as strings are larger than Ruby slot of 40 bytes:

  ```ruby
  Gitlab::Memory::Instrumentation.with_memory_allocations do
    s = '0'
    1_000.times { s * 24 }
  end

  => {:mem_objects=>1002, :mem_bytes=>32000, :mem_mallocs=>1000}
  ```

- The following example will allocate over 40 kB of data, and perform only a single memory allocation.
  The existing object will be reallocated/resized on subsequent iterations:

  ```ruby
  Gitlab::Memory::Instrumentation.with_memory_allocations do
    str = ''
    append = '0123456789012345678901234567890123456789' # 40 bytes
    1_000.times { str.concat(append) }
  end
  => {:mem_objects=>3, :mem_bytes=>49152, :mem_mallocs=>1}
  ```

- The following example will create over 1k of objects, perform over 1k of allocations, each time mutating the object.
  This does result in copying a lot of data and perform a lot of memory allocations
  (as represented by `mem_bytes` counter) indicating very inefficient method of appending string:

  ```ruby
  Gitlab::Memory::Instrumentation.with_memory_allocations do
    str = ''
    append = '0123456789012345678901234567890123456789' # 40 bytes
    1_000.times { str += append }
  end
  => {:mem_objects=>1003, :mem_bytes=>21968752, :mem_mallocs=>1000}
  ```

### Using Memory Profiler

We can use `memory_profiler` for profiling.

The [`memory_profiler`](https://github.com/SamSaffron/memory_profiler)
gem is already present in the GitLab `Gemfile`. It's also available in the [performance bar](../administration/monitoring/performance/performance_bar.md)
for the current URL.

To use the memory profiler directly in your code, use `require` to add it:

```ruby
require 'memory_profiler'

report = MemoryProfiler.report do
  # Code you want to profile
end

output = File.open('/tmp/profile.txt','w')
report.pretty_print(output)
```

The report shows the retained and allocated memory grouped by gem, file, location, and class. The
memory profiler also performs a string analysis that shows how often a string is allocated and
retained.

#### Retained versus allocated

- Retained memory: long-lived memory use and object count retained due to the execution of the code
  block. This has a direct impact on memory and the garbage collector.
- Allocated memory: all object allocation and memory allocation during the code block. This might
  have minimal impact on memory, but substantial impact on performance. The more objects you
  allocate, the more work is being done and the slower the application is.

As a general rule, **retained** is always smaller than or equal to **allocated**.

The actual RSS cost is always slightly higher as MRI heaps are not squashed to size and memory fragments.

### Rbtrace

One of the reasons of the increased memory footprint could be Ruby memory fragmentation.

To diagnose it, you can visualize Ruby heap as described in [this post by Aaron Patterson](https://tenderlovemaking.com/2017/09/27/visualizing-your-ruby-heap/).

To start, you want to dump the heap of the process you're investigating to a JSON file.

You need to run the command inside the process you're exploring, you may do that with `rbtrace`.
`rbtrace` is already present in GitLab `Gemfile`, you just need to require it.
It could be achieved running webserver or Sidekiq with the environment variable set to `ENABLE_RBTRACE=1`.

To get the heap dump:

```ruby
bundle exec rbtrace -p <PID> -e 'File.open("heap.json", "wb") { |t| ObjectSpace.dump_all(output: t) }'
```

Having the JSON, you finally could render a picture using the script [provided by Aaron](https://gist.github.com/tenderlove/f28373d56fdd03d8b514af7191611b88) or similar:

```shell
ruby heapviz.rb heap.json
```

Fragmented Ruby heap snapshot could look like this:

![Ruby heap fragmentation](img/memory_ruby_heap_fragmentation_v12_3.png)

Memory fragmentation could be reduced by tuning GC parameters [as described in this post](https://www.speedshop.co/2017/12/04/malloc-doubles-ruby-memory.html). This should be considered as a tradeoff, as it may affect overall performance of memory allocation and GC cycles.

### Derailed Benchmarks

`derailed_benchmarks` is a [gem](https://github.com/zombocom/derailed_benchmarks)
described as "A series of things you can use to benchmark a Rails or Ruby app."
We include `derailed_benchmarks` in our `Gemfile`.

We run `derailed exec perf:mem` in every pipeline with a `test` stage, in a job
called `memory-on-boot`. ([Read an example job.](https://gitlab.com/gitlab-org/gitlab/-/jobs/2144695684).)
You may find the results:

- On the merge request **Overview** tab, in the merge request reports area, in the
  **Metrics Reports** [dropdown list](../ci/testing/metrics_reports.md).
- In the `memory-on-boot` artifacts for a full report and a dependency breakdown.

`derailed_benchmarks` also provides other methods to investigate memory. For more information, see
the [gem documentation](https://github.com/zombocom/derailed_benchmarks#running-derailed-exec).
Most of the methods (`derailed exec perf:*`) attempt to boot your Rails app in a
`production` environment and run benchmarks against it.
It is possible both in GDK and GCK:

- For GDK, follow the
  [the instructions](https://github.com/zombocom/derailed_benchmarks#running-in-production-locally)
  on the gem page. You must do similar for Redis configurations to avoid errors.
- GCK includes `production` configuration sections
  [out of the box](https://gitlab.com/gitlab-org/gitlab-compose-kit#running-production-like).

## Importance of Changes

When working on performance improvements, it's important to always ask yourself
the question "How important is it to improve the performance of this piece of
code?". Not every piece of code is equally important and it would be a waste to
spend a week trying to improve something that only impacts a tiny fraction of
our users. For example, spending a week trying to squeeze 10 milliseconds out of
a method is a waste of time when you could have spent a week squeezing out 10
seconds elsewhere.

There is no clear set of steps that you can follow to determine if a certain
piece of code is worth optimizing. The only two things you can do are:

1. Think about what the code does, how it's used, how many times it's called and
   how much time is spent in it relative to the total execution time (for example, the
   total time spent in a web request).
1. Ask others (preferably in the form of an issue).

Some examples of changes that are not really important/worth the effort:

- Replacing double quotes with single quotes.
- Replacing usage of Array with Set when the list of values is very small.
- Replacing library A with library B when both only take up 0.1% of the total
  execution time.
- Calling `freeze` on every string (see [String Freezing](#string-freezing)).

## Slow Operations & Sidekiq

Slow operations, like merging branches, or operations that are prone to errors
(using external APIs) should be performed in a Sidekiq worker instead of
directly in a web request as much as possible. This has numerous benefits such
as:

1. An error doesn't prevent the request from completing.
1. The process being slow doesn't affect the loading time of a page.
1. In case of a failure you can retry the process (Sidekiq takes care of
   this automatically).
1. By isolating the code from a web request it should be easier to test
   and maintain.

It's especially important to use Sidekiq as much as possible when dealing with
Git operations as these operations can take quite some time to complete
depending on the performance of the underlying storage system.

## Git Operations

Care should be taken to not run unnecessary Git operations. For example,
retrieving the list of branch names using `Repository#branch_names` can be done
without an explicit check if a repository exists or not. In other words, instead
of this:

```ruby
if repository.exists?
  repository.branch_names.each do |name|
    ...
  end
end
```

You can just write:

```ruby
repository.branch_names.each do |name|
  ...
end
```

## Caching

Operations that often return the same result should be cached using Redis,
in particular Git operations. When caching data in Redis, make sure the cache is
flushed whenever needed. For example, a cache for the list of tags should be
flushed whenever a new tag is pushed or a tag is removed.

When adding cache expiration code for repositories, this code should be placed
in one of the before/after hooks residing in the Repository class. For example,
if a cache should be flushed after importing a repository this code should be
added to `Repository#after_import`. This ensures the cache logic stays within
the Repository class instead of leaking into other classes.

When caching data, make sure to also memoize the result in an instance variable.
While retrieving data from Redis is much faster than raw Git operations, it still
has overhead. By caching the result in an instance variable, repeated calls to
the same method don't retrieve data from Redis upon every call. When
memoizing cached data in an instance variable, make sure to also reset the
instance variable when flushing the cache. An example:

```ruby
def first_branch
  @first_branch ||= cache.fetch(:first_branch) { branches.first }
end

def expire_first_branch_cache
  cache.expire(:first_branch)
  @first_branch = nil
end
```

## String Freezing

In recent Ruby versions calling `.freeze` on a String leads to it being allocated
only once and re-used. For example, on Ruby 2.3 or later this only allocates the
"foo" String once:

```ruby
10.times do
  'foo'.freeze
end
```

Depending on the size of the String and how frequently it would be allocated
(before the `.freeze` call was added), this _may_ make things faster, but
this isn't guaranteed.

Freezing strings saves memory, as every allocated string uses at least one `RVALUE_SIZE` bytes (40
bytes on x64) of memory.

You can use the [memory profiler](#using-memory-profiler)
to see which strings are allocated often and could potentially benefit from a `.freeze`.

Strings are frozen by default in Ruby 3.0. To prepare our codebase for
this eventuality, we are adding the following header to all Ruby files:

```ruby
# frozen_string_literal: true
```

This may cause test failures in the code that expects to be able to manipulate
strings. Instead of using `dup`, use the unary plus to get an unfrozen string:

```ruby
test = +"hello"
test += " world"
```

When adding new Ruby files, check that you can add the above header,
as omitting it may lead to style check failures.

## Banzai pipelines and filters

When writing or updating [Banzai filters and pipelines](https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/banzai),
it can be difficult to understand what the performance of the filter is, and what effect it might
have on the overall pipeline performance.

To perform benchmarks run:

```shell
bin/rake benchmark:banzai
```

This command generates output like this:

```plaintext
--> Benchmarking Full, Wiki, and Plain pipelines
Calculating -------------------------------------
       Full pipeline     1.000  i/100ms
       Wiki pipeline     1.000  i/100ms
      Plain pipeline     1.000  i/100ms
-------------------------------------------------
       Full pipeline      3.357  (±29.8%) i/s -     31.000
       Wiki pipeline      2.893  (±34.6%) i/s -     25.000  in  10.677014s
      Plain pipeline     15.447  (±32.4%) i/s -    119.000

Comparison:
      Plain pipeline:       15.4 i/s
       Full pipeline:        3.4 i/s - 4.60x slower
       Wiki pipeline:        2.9 i/s - 5.34x slower

.
--> Benchmarking FullPipeline filters
Calculating -------------------------------------
            Markdown    24.000  i/100ms
            Plantuml     8.000  i/100ms
          SpacedLink    22.000  i/100ms

...

            TaskList    49.000  i/100ms
          InlineDiff     9.000  i/100ms
        SetDirection   369.000  i/100ms
-------------------------------------------------
            Markdown    237.796  (±16.4%) i/s -      2.304k
            Plantuml     80.415  (±36.1%) i/s -    520.000
          SpacedLink    168.188  (±10.1%) i/s -      1.672k

...

            TaskList    101.145  (± 6.9%) i/s -      1.029k
          InlineDiff     52.925  (±15.1%) i/s -    522.000
        SetDirection      3.728k (±17.2%) i/s -     34.317k in  10.617882s

Comparison:
          Suggestion:   739616.9 i/s
               Kroki:   306449.0 i/s - 2.41x slower
InlineGrafanaMetrics:   156535.6 i/s - 4.72x slower
        SetDirection:     3728.3 i/s - 198.38x slower

...

       UserReference:        2.1 i/s - 360365.80x slower
        ExternalLink:        1.6 i/s - 470400.67x slower
    ProjectReference:        0.7 i/s - 1128756.09x slower

.
--> Benchmarking PlainMarkdownPipeline filters
Calculating -------------------------------------
            Markdown    19.000  i/100ms
-------------------------------------------------
            Markdown    241.476  (±15.3%) i/s -      2.356k

```

This can give you an idea how various filters perform, and which ones might be performing the slowest.

The test data has a lot to do with how well a filter performs. If there is nothing in the test data
that specifically triggers the filter, it might look like it's running incredibly fast.
Make sure that you have relevant test data for your filter in the
[`spec/fixtures/markdown.md.erb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/spec/fixtures/markdown.md.erb)
file.

### Benchmarking specific filters

A specific filter can be benchmarked by specifying the filter name as an environment variable.
For example, to benchmark the `MarkdownFilter` use

```plaintext
FILTER=MarkdownFilter bin/rake benchmark:banzai
```

which generates the output

```plaintext
--> Benchmarking MarkdownFilter for FullPipeline
Warming up --------------------------------------
            Markdown   271.000  i/100ms
Calculating -------------------------------------
            Markdown      2.584k (±16.5%) i/s -     23.848k in  10.042503s
```

## Reading from files and other data sources

Ruby offers several convenience functions that deal with file contents specifically
or I/O streams in general. Functions such as `IO.read` and `IO.readlines` make
it easy to read data into memory, but they can be inefficient when the
data grows large. Because these functions read the entire contents of a data
source into memory, memory use grows by _at least_ the size of the data source.
In the case of `readlines`, it grows even further, due to extra bookkeeping
the Ruby VM has to perform to represent each line.

Consider the following program, which reads a text file that is 750 MB on disk:

```ruby
File.readlines('large_file.txt').each do |line|
  puts line
end
```

Here is a process memory reading from while the program was running, showing
how we indeed kept the entire file in memory (RSS reported in kilobytes):

```shell
$ ps -o rss -p <pid>

RSS
783436
```

And here is an excerpt of what the garbage collector was doing:

```ruby
pp GC.stat

{
 :heap_live_slots=>2346848,
 :malloc_increase_bytes=>30895288,
 ...
}
```

We can see that `heap_live_slots` (the number of reachable objects) jumped to ~2.3M,
which is roughly two orders of magnitude more compared to reading the file line by
line instead. It was not just the raw memory usage that increased, but also how the garbage collector (GC)
responded to this change in anticipation of future memory use. We can see that `malloc_increase_bytes` jumped
to ~30 MB, which compares to just ~4 kB for a "fresh" Ruby program. This figure specifies how
much additional heap space the Ruby GC claims from the operating system next time it runs out of memory.
Not only did we occupy more memory, we also changed the behavior of the application
to increase memory use at a faster rate.

The `IO.read` function exhibits similar behavior, with the difference that no extra memory is
allocated for each line object.

### Recommendations

Instead of reading data sources into memory in full, it is better to read them line by line
instead. This is not always an option, for instance when you need to convert a YAML file
into a Ruby `Hash`, but whenever you have data where each row represents some entity that
can be processed and then discarded, you can use the following approaches.

First, replace calls to `readlines.each` with either `each` or `each_line`.
The `each_line` and `each` functions read the data source line by line without keeping
already visited lines in memory:

```ruby
File.new('file').each { |line| puts line }
```

Alternatively, you can read individual lines explicitly using `IO.readline` or `IO.gets` functions:

```ruby
while line = file.readline
   # process line
end
```

This might be preferable if there is a condition that allows exiting the loop early, saving not
just memory but also unnecessary time spent in CPU and I/O for processing lines you're not interested in.

## Anti-Patterns

This is a collection of [anti-patterns](https://en.wikipedia.org/wiki/Anti-pattern) that should be avoided
unless these changes have a measurable, significant, and positive impact on
production environments.

### Moving Allocations to Constants

Storing an object as a constant so you only allocate it once _may_ improve
performance, but this is not guaranteed. Looking up constants has an
impact on runtime performance, and as such, using a constant instead of
referencing an object directly may even slow code down. For example:

```ruby
SOME_CONSTANT = 'foo'.freeze

9000.times do
  SOME_CONSTANT
end
```

The only reason you should be doing this is to prevent somebody from mutating
the global String. However, since you can just re-assign constants in Ruby
there's nothing stopping somebody from doing this elsewhere in the code:

```ruby
SOME_CONSTANT = 'bar'
```

## How to seed a database with millions of rows

You might want millions of project rows in your local database, for example,
to compare relative query performance, or to reproduce a bug. You could
do this by hand with SQL commands or using [Mass Inserting Rails Models](mass_insert.md) functionality.

Assuming you are working with ActiveRecord models, you might also find these links helpful:

- [Insert records in batches](database/insert_into_tables_in_batches.md)
- [BulkInsert gem](https://github.com/jamis/bulk_insert)
- [ActiveRecord::PgGenerateSeries gem](https://github.com/ryu39/active_record-pg_generate_series)

### Examples

You may find some useful examples in [this snippet](https://gitlab.com/gitlab-org/gitlab-foss/-/snippets/33946).

## ExclusiveLease

`Gitlab::ExclusiveLease` is a Redis-based locking mechanism that lets developers achieve mutual exclusion across distributed servers. There are several wrappers available for developers to make use of:

1. The `Gitlab::ExclusiveLeaseHelpers` module provides a helper method to block the process or thread until the lease can be expired.
1. The `ExclusiveLease::Guard` module helps get an exclusive lease for a running block of code.

You should not use `ExclusiveLease` in a database transaction because any slow Redis I/O could increase idle transaction duration. The `.try_obtain` method checks if the lease attempt is within any database transactions, and tracks an exception in Sentry and the `log/exceptions_json.log`.

In a test or development environment, any lease attempts in database transactions will raise a `Gitlab::ExclusiveLease::LeaseWithinTransactionError` unless performed within a `Gitlab::ExclusiveLease.skipping_transaction_check` block. You should only use the skip functionality in specs where possible, and placed as close to the lease as possible for ease of understanding. To keep the specs DRY, there are two parts of the codebase where the transaction check skips are re-used:

1. `Users::Internal` is patched to skip transaction checks for bot creation in `let_it_be`.
1. `FactoryBot` factory for `:deploy_key` skips transaction during the `DeployKey` model creation.

Any use of `Gitlab::ExclusiveLease.skipping_transaction_check` in non-spec or non-fixture files should include links to an infradev issue for plans to remove it.
