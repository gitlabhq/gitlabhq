# Understanding Unicorn and unicorn-worker-killer

## Unicorn

GitLab uses [Unicorn](http://unicorn.bogomips.org/), a pre-forking Ruby web
server, to handle web requests (web browsers and Git HTTP clients). Unicorn is
a daemon written in Ruby and C that can load and run a Ruby on Rails
application; in our case the Rails application is GitLab Community Edition or
GitLab Enterprise Edition.

Unicorn has a multi-process architecture to make better use of available CPU
cores (processes can run on different cores) and to have stronger fault
tolerance (most failures stay isolated in only one process and cannot take down
GitLab entirely). On startup, the Unicorn 'master' process loads a clean Ruby
environment with the GitLab application code, and then spawns 'workers' which
inherit this clean initial environment. The 'master' never handles any
requests, that is left to the workers. The operating system network stack
queues incoming requests and distributes them among the workers.

In a perfect world, the master would spawn its pool of workers once, and then
the workers handle incoming web requests one after another until the end of
time. In reality, worker processes can crash or time out: if the master notices
that a worker takes too long to handle a request it will terminate the worker
process with SIGKILL ('kill -9'). No matter how the worker process ended, the
master process will replace it with a new 'clean' process again. Unicorn is
designed to be able to replace 'crashed' workers without dropping user
requests.

This is what a Unicorn worker timeout looks like in `unicorn_stderr.log`. The
master process has PID 56227 below.

```
[2015-06-05T10:58:08.660325 #56227] ERROR -- : worker=10 PID:53009 timeout (61s > 60s), killing
[2015-06-05T10:58:08.699360 #56227] ERROR -- : reaped #<Process::Status: pid 53009 SIGKILL (signal 9)> worker=10
[2015-06-05T10:58:08.708141 #62538]  INFO -- : worker=10 spawned pid=62538
[2015-06-05T10:58:08.708824 #62538]  INFO -- : worker=10 ready
```

### Tunables

The main tunables for Unicorn are the number of worker processes and the
request timeout after which the Unicorn master terminates a worker process.
See the [omnibus-gitlab Unicorn settings
documentation](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/doc/settings/unicorn.md)
if you want to adjust these settings.

## unicorn-worker-killer

GitLab has memory leaks. These memory leaks manifest themselves in long-running
processes, such as Unicorn workers. (The Unicorn master process is not known to
leak memory, probably because it does not handle user requests.)

To make these memory leaks manageable, GitLab comes with the
[unicorn-worker-killer gem](https://github.com/kzk/unicorn-worker-killer). This
gem [monkey-patches](https://en.wikipedia.org/wiki/Monkey_patch) the Unicorn
workers to do a memory self-check after every 16 requests. If the memory of the
Unicorn worker exceeds a pre-set limit then the worker process exits. The
Unicorn master then automatically replaces the worker process.

This is a robust way to handle memory leaks: Unicorn is designed to handle
workers that 'crash' so no user requests will be dropped. The
unicorn-worker-killer gem is designed to only terminate a worker process _in
between requests_, so no user requests are affected.

This is what a Unicorn worker memory restart looks like in unicorn_stderr.log.
You see that worker 4 (PID 125918) is inspecting itself and decides to exit.
The threshold memory value was 254802235 bytes, about 250MB. With GitLab this
threshold is a random value between 200 and 250 MB.  The master process (PID
117565) then reaps the worker process and spawns a new 'worker 4' with PID
127549.

```
[2015-06-05T12:07:41.828374 #125918]  WARN -- : #<Unicorn::HttpServer:0x00000002734770>: worker (pid: 125918) exceeds memory limit (256413696 bytes > 254802235 bytes)
[2015-06-05T12:07:41.828472 #125918]  WARN -- : Unicorn::WorkerKiller send SIGQUIT (pid: 125918) alive: 23 sec (trial 1)
[2015-06-05T12:07:42.025916 #117565]  INFO -- : reaped #<Process::Status: pid 125918 exit 0> worker=4
[2015-06-05T12:07:42.034527 #127549]  INFO -- : worker=4 spawned pid=127549
[2015-06-05T12:07:42.035217 #127549]  INFO -- : worker=4 ready
```

One other thing that stands out in the log snippet above, taken from
GitLab.com, is that 'worker 4' was serving requests for only 23 seconds. This
is a normal value for our current GitLab.com setup and traffic.

The high frequency of Unicorn memory restarts on some GitLab sites can be a
source of confusion for administrators. Usually they are a [red
herring](https://en.wikipedia.org/wiki/Red_herring).
