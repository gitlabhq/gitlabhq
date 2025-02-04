---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Sidekiq Compatibility across Updates
---

The arguments for a Sidekiq job are stored in a queue while it is
scheduled for execution. During a online update, this could lead to
several possible situations:

1. An older version of the application publishes a job, which is executed by an
   upgraded Sidekiq node.
1. A job is queued before an upgrade, but executed after an upgrade.
1. A job is queued by a node running the newer version of the application, but
   executed on a node running an older version of the application.

## Adding new workers

On GitLab.com, we
[do not currently have a Sidekiq deployment in the canary stage](https://gitlab.com/gitlab-org/gitlab/-/issues/19239).
This means that a new worker than can be scheduled from an HTTP endpoint may
be scheduled from canary but not run on Sidekiq until the full
production deployment is complete. This can be several hours later than
scheduling the job. For some workers, this will not be a problem. For
others - particularly [latency-sensitive jobs](worker_attributes.md#latency-sensitive-jobs) -
this will result in a poor user experience.

This only applies to new worker classes when they are first introduced.
As we recommend [using feature flags](../feature_flags/_index.md) as a general
development process, it's best to control the entire change (including
scheduling of the new Sidekiq worker) with a feature flag.

## Changing the arguments for a worker

Jobs need to be backward and forward compatible between consecutive versions
of the application. Adding or removing an argument may cause problems
during deployment before all Rails and Sidekiq nodes have the updated code.

### Deprecate and remove an argument

**Before you remove arguments from the `perform_async` and `perform` methods.**, deprecate them. The
following example deprecates and then removes `arg2` from the `perform_async` method:

1. Provide a default value (usually `nil`) and use a comment to mark the
   argument as deprecated in the coming minor release. (Release M)

   ```ruby
   class ExampleWorker
     # Keep arg2 parameter for backwards compatibility.
     def perform(object_id, arg1, arg2 = nil)
       # ...
     end
   end
   ```

1. One minor release later, stop using the argument in `perform_async`. (Release M+1)

   ```ruby
   ExampleWorker.perform_async(object_id, arg1)
   ```

1. At the next major release, remove the value from the worker class. (Next major release)

   ```ruby
   class ExampleWorker
     def perform(object_id, arg1)
       # ...
     end
   end
   ```

### Add an argument

There are two options for safely adding new arguments to Sidekiq workers:

1. Set up a [multi-step deployment](#multi-step-deployment) in which the new argument is first added to the worker.
1. Use a [parameter hash](#parameter-hash) for additional arguments. This is perhaps the most flexible option.

#### Multi-step deployment

This approach requires multiple releases.

1. Add the argument to the worker with a default value (Release M).

   ```ruby
   class ExampleWorker
     def perform(object_id, new_arg = nil)
       # ...
     end
   end
   ```

1. Add the new argument to all the invocations of the worker (Release M+1).

   ```ruby
   ExampleWorker.perform_async(object_id, new_arg)
   ```

1. Remove the default value (Release M+2).

   ```ruby
   class ExampleWorker
     def perform(object_id, new_arg)
       # ...
     end
   end
   ```

#### Parameter hash

This approach doesn't require multiple releases if an existing worker already
uses a parameter hash.

1. Use a parameter hash in the worker to allow future flexibility.

   ```ruby
   class ExampleWorker
     def perform(object_id, params = {})
       # ...
     end
   end
   ```

## Removing worker classes

To remove a worker class, follow these steps over three minor releases:

### In the minor release M

1. Remove any code that enqueues the jobs.

   For example, if there is a UI component or an API endpoint that a user can interact with that results in the worker instance getting enqueued, make sure those surface areas are either removed or updated in a way that the worker instance is no longer enqueued.

   This ensures that instances related to the worker class are no longer being enqueued.

1. Ensure both the frontend and backend code no longer relies on any of the work that used to be done by the worker.
1. In the relevant worker classes, replace the contents of the `perform` method with a no-op, while keeping any arguments in tact.

   For example, if you're working with the following `ExampleWorker`:

   ```ruby
     class ExampleWorker
       def perform(object_id)
         SomeService.run!(object_id)
       end
     end
   ```

   Implementing the no-op might look like this:

   ```ruby
     class ExampleWorker
       def perform(object_id); end
     end
   ```

   By implementing this no-op, you can avoid unnecessary cycles once any deprecated jobs that are still enqueued eventually get processed.

### In the M+1 release

Add a migration (not a post-deployment migration) that uses `sidekiq_remove_jobs`:

   ```ruby
   class RemoveMyDeprecatedWorkersJobInstances < Gitlab::Database::Migration[2.1]
     DEPRECATED_JOB_CLASSES = %w[
       MyDeprecatedWorkerOne
       MyDeprecatedWorkerTwo
     ]
     # Always use `disable_ddl_transaction!` while using the `sidekiq_remove_jobs` method, as we had multiple production incidents due to `idle-in-transaction` timeout.
     disable_ddl_transaction!
     def up
       # If the job has been scheduled via `sidekiq-cron`, we must also remove
       # it from the scheduled worker set using the key used to define the cron
       # schedule in config/initializers/1_settings.rb.
       job_to_remove = Sidekiq::Cron::Job.find('my_deprecated_worker')
       # The job may be removed entirely:
       job_to_remove.destroy if job_to_remove
       # The job may be disabled:
       job_to_remove.disable! if job_to_remove

       # Removes scheduled instances from Sidekiq queues
       sidekiq_remove_jobs(job_klasses: DEPRECATED_JOB_CLASSES)
     end

     def down
       # This migration removes any instances of deprecated workers and cannot be undone.
     end
   end
   ```

### In the M+2 release

Delete the worker class file and follow the guidance in our [Sidekiq queues documentation](../sidekiq/_index.md#sidekiq-queues) around running Rake tasks to regenerate/update related files.

## Renaming queues

For the same reasons that removing workers is dangerous, care should be taken
when renaming queues.

When renaming queues, use the `sidekiq_queue_migrate` helper migration method
in a **post-deployment migration**:

```ruby
class MigrateTheRenamedSidekiqQueue < Gitlab::Database::Migration[2.1]
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  disable_ddl_transaction!

  def up
    sidekiq_queue_migrate 'old_queue_name', to: 'new_queue_name'
  end

  def down
    sidekiq_queue_migrate 'new_queue_name', to: 'old_queue_name'
  end
end

```

You must rename the queue in a post-deployment migration not in a standard
migration. Otherwise, it runs too early, before all the workers that
schedule these jobs have stopped running. See also [other examples](../database/post_deployment_migrations.md#use-cases).

## Renaming worker classes

We should treat this similar to adding a new worker. That means we only start scheduling the newly-named worker after the Sidekiq deployment finishes.

To ensure backward and forward compatibility between consecutive versions
of the application, follow these steps over three minor releases:

1. Create the newly named worker, and have the old worker call the new worker's `#perform` method. Introduce a feature flag to control when we start scheduling the new worker. (Release M)

   Any old worker jobs that are still in the queue will delegate to the new worker. When this version is deployed, it is no longer relevant which version of the job is scheduled or which Sidekiq handles it, an old-Sidekiq will use the old worker's full implementation, a new-Sidekiq will delegate to the new worker.

1. Enable the feature flag for GitLab.com, and after that prepare an MR to enable it by default. (Release M+1)
1. Remove the old worker class and the feature flag. (Release M+2)
