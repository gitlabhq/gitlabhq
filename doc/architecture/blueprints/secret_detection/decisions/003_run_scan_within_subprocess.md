---
owning-stage: "~devops::secure"
description: "GitLab Secret Detection ADR 003: Run scan within subprocess"
---

# GitLab Secret Detection ADR 003: Run scan within subprocesses

## Context

During the [spike](https://gitlab.com/gitlab-org/gitlab/-/issues/422574#note_1582015771) conducted for evaluating regex for Pre-receive Secret Detection, Ruby using RE2 library came out on the top of the list. Although Ruby has an acceptable regex performance, its language limitations have certain pitfalls like more memory consumption and lack of parallelism despite the language supporting multi-threading and Ractors (3.1+) as they are suitable for running I/O-bound operations in parallel but not CPU-bound operations.

One of the concerns running the Pre-receive Secret Detection feature in the critical path is memory consumption, especially by the regex operations involved in the scan. In a scan with 300+ regex-based rule patterns running on every line of the commit blobs, the memory could go up to ~2-3x the size of the commit blobs[1](https://gitlab.com/gitlab-org/gitlab/-/issues/422574#note_1582015771). The occupied memory is not released despite scan operation being complete, until the Garbage Collector triggers. Eventually, the servers might choke on the memory.

The [original discussion issue](https://gitlab.com/gitlab-org/gitlab/-/issues/430160) covers many of these concerns and more background.

### Approach

We can tackle the memory consumption problem to an extent by running the scan within a separate process forked from the main process. Once the scan is complete, we kill the spawned process such that the occupied memory releases to the OS immediately instead of waiting for Ruby to trigger GC.

## Technical Solution

There are several scenarios to consider while managing a process's lifecycle. Failing to do so would lead to an orphan process having no control over it, defeating the whole purpose of conserving memory. We offload this burden over a Ruby library called [`Parallel`](https://github.com/grosser/parallel) that provides the ability to run operations via subprocesses. Its simple interface for communication b/w parent and child processes, handling exit signals, and easy capping of no. of processes makes it a suitable solution for achieving our needs. It additionally supports parallelism (spawning and running multiple subprocesses simultaneously) that solves another problem not covered in this document.

### Scope of the operation within Subprocess

It is crucial to determine which operation runs within the subprocess because spawning a new process comes with an additional latency overhead from the OS (copying file descriptors, etc). For example, running the scan on each blob inside a new subprocess is `~2.5x` slower than when the scan runs on the main process. On the contrary, dedicating one subprocess for each commit request isn't feasible either as the scan on all the blobs runs within a single process and we wouldn't be able to release memory quickly until all the scans are complete, taking us back to square one.

*Bucket Approach*: A compromise between the two extremes would be when we group all the blobs whose cumulative size is at least a fixed chunk size ([`2MiB` in our case](https://gitlab.com/gitlab-org/gitlab/-/blob/5dfcf7431bfff25519c05a7e66c0cbb8d7b362be/gems/gitlab-secret_detection/lib/gitlab/secret_detection/scan.rb#L32)) and then run each group within a separate sub-process as illustrated below.

![Bucketed Subprocesses](../img/003_subprocess.jpg "Bucketed Subprocess by Fixed Chunk size")

### Addendum

- Running operations within a subprocess isn't a silver bullet to the above mentioned problems. We could say it *delays* our servers from getting choked by releasing the memory *faster* than the usual process via GC. Even this approach can fail when the burst of requests is too huge to handle^.

- There's always a latency overhead on the process creation of the lifecycle. For the smaller commits^, the latency of the scan operation *might* be slower than when run on the main process.

- The parallelism factor or the no. of processes forked per request is currently capped to [`5` processes](https://gitlab.com/gitlab-org/gitlab/-/blob/5dfcf7431bfff25519c05a7e66c0cbb8d7b362be/gems/gitlab-secret_detection/lib/gitlab/secret_detection/scan.rb#L29), beyond which pending requests wait in the queue to avoid over-forking processes which would also lead to resource exhaustion.

_^Threshold numbers will be added here soon for reference._
