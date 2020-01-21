# Switching to Puma

## Puma

GitLab plans to use [Puma](https://github.com/puma/puma) to replace
[Unicorn](https://bogomips.org/unicorn/).

## Why switch to Puma?

Puma has a multi-thread architecture which uses less memory than a multi-process
application server like Unicorn.

Most Rails applications requests normally include a proportion of I/O wait time.
During I/O wait time MRI Ruby will release the GVL (Global VM Lock) to other threads.
Multi-threaded Puma can therefore still serve more requests than a single process.

## Performance caveat when using Puma with Rugged

For deployments where NFS is used to store Git repository, we allow GitLab to use
[Direct Git Access](../gitaly/#direct-git-access-in-gitlab-rails) to improve performance via usage of [Rugged](https://github.com/libgit2/rugged).

Rugged usage is automatically enabled if Direct Git Access is present, unless it
is disabled by [feature flags](../../development/gitaly.md#legacy-rugged-code).

MRI Ruby uses a GVL. This allows MRI Ruby to be multi-threaded, but running at
most on a single core. Since Rugged can use a thread for long periods of
time (due to intensive I/O operations of Git access), this can starve other threads
that might be processing requests. This is not a case for Unicorn or Puma running
in a single thread mode, as concurrently at most one request is being processed.

We are actively working on removing Rugged usage. Even though performance without Rugged
is acceptable today, in some cases it might be still beneficial to run with it.

Given the caveat of running Rugged with multi-threaded Puma, and acceptable
performance of Gitaly, we are disabling Rugged usage if Puma multi-threaded is
used (when Puma is configured to run with more than one thread).

This default behavior may not be the optimal configuration in some situations. If Rugged
plays an important role in your deployment, we suggest you benchmark to find the
optimal configuration:

- The safest option is to start with single-threaded Puma. When working with
Rugged, single-threaded Puma does work the same as Unicorn.

- To force Rugged auto detect with multi-threaded Puma, you can use [feature
flags](../../development/gitaly.md#legacy-rugged-code).
