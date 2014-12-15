# Sidekiq MemoryKiller

The GitLab Rails application code suffers from memory leaks. For web requests
this problem is made manageable using
[unicorn-worker-killer](https://github.com/kzk/unicorn-worker-killer) which
restarts Unicorn worker processes in between requests when needed. The Sidekiq
MemoryKiller applies the same approach to the Sidekiq processes used by GitLab
to process background jobs.


