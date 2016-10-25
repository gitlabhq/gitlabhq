# Sidekiq Style Guide

This document outlines various guidelines that should be followed when adding or
modifying Sidekiq workers.

## Default Queue

Use of the "default" queue is not allowed. Every worker should use a queue that
matches the worker's purpose the closest. For example, workers that are to be
executed periodically should use the "cronjob" queue.

A list of all available queues can be found in `config/sidekiq_queues.yml`.

## Dedicated Queues

Most workers should use their own queue. To ease this process a worker can
include the `DedicatedSidekiqQueue` concern as follows:

```ruby
class ProcessSomethingWorker
  include Sidekiq::Worker
  include DedicatedSidekiqQueue
end
```

This will set the queue name based on the class' name, minus the `Worker`
suffix. In the above example this would lead to the queue being
`process_something`.

In some cases multiple workers do use the same queue. For example, the various
workers for updating CI pipelines all use the `pipeline` queue. Adding workers
to existing queues should be done with care, as adding more workers can lead to
slow jobs blocking work (even for different jobs) on the shared queue.

## Tests

Each Sidekiq worker must be tested using RSpec, just like any other class. These
tests should be placed in `spec/workers`.
