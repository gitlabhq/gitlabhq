---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Sidekiq logging
---

## Worker context

To have some more information about workers in the logs, we add
[metadata to the jobs in the form of an `ApplicationContext`](../logging.md#logging-context-metadata-through-rails-or-grape-requests).
In most cases, when scheduling a job from a request, this context is already
deduced from the request and added to the scheduled job.

When a job runs, the context that was active when it was scheduled
is restored. This causes the context to be propagated to any job
scheduled from within the running job.

All this means that in most cases, to add context to jobs, we don't
need to do anything.

There are however some instances when there would be no context
present when the job is scheduled, or the context that is present is
likely to be incorrect. For these instances, we've added RuboCop rules
to draw attention and avoid incorrect metadata in our logs.

As with most our cops, there are perfectly valid reasons for disabling
them. In this case it could be that the context from the request is
correct. Or maybe you've specified a context already in a way that
isn't picked up by the cops. In any case, leave a code comment
pointing to which context to use when disabling the cops.

When you do provide objects to the context, make sure that the
route for namespaces and projects is pre-loaded. This can be done by using
the `.with_route` scope defined on all `Routable`s.

### Cron workers

The context is automatically cleared for workers in the cronjob queue
(`include CronjobQueue`), even when scheduling them from
requests. We do this to avoid incorrect metadata when other jobs are
scheduled from the cron worker.

Cron workers themselves run instance wide, so they aren't scoped to
users, namespaces, projects, or other resources that should be added to
the context.

However, they often run services or schedule other jobs that _do_ require context.

That is why there needs to be an indication of context somewhere in
the worker. This can be done by using one of the following methods
somewhere within the worker:

1. Wrap the code that schedules jobs in the `with_context` helper:

   ```ruby
     def perform
       deletion_cutoff = Gitlab::CurrentSettings
                           .deletion_adjourned_period.days.ago.to_date
       projects = Project.with_route.with_namespace
                    .aimed_for_deletion(deletion_cutoff)

       projects.find_each(batch_size: 100).with_index do |project, index|
         delay = index * INTERVAL

         with_context(project: project) do
           AdjournedProjectDeletionWorker.perform_in(delay, project.id)
         end
       end
     end
   ```

1. Use the a batch scheduling method that provides context:

   ```ruby
     def schedule_projects_in_batch(projects)
       ProjectImportScheduleWorker.bulk_perform_async_with_contexts(
         projects,
         arguments_proc: -> (project) { project.id },
         context_proc: -> (project) { { project: project } }
       )
     end
   ```

   Or, when scheduling with delays:

   ```ruby
     diffs.each_batch(of: BATCH_SIZE) do |diffs, index|
       DeleteDiffFilesWorker
         .bulk_perform_in_with_contexts(index *  5.minutes,
                                        diffs,
                                        arguments_proc: -> (diff) { diff.id },
                                        context_proc: -> (diff) { { project: diff.merge_request.target_project } })
     end
   ```

### Jobs scheduled in bulk

Often, when scheduling jobs in bulk, these jobs should have a separate
context rather than the overarching context.

If that is the case, `bulk_perform_async` can be replaced by the
`bulk_perform_async_with_context` helper, and instead of
`bulk_perform_in` use `bulk_perform_in_with_context`.

For example:

```ruby
    ProjectImportScheduleWorker.bulk_perform_async_with_contexts(
      projects,
      arguments_proc: -> (project) { project.id },
      context_proc: -> (project) { { project: project } }
    )
```

Each object from the enumerable in the first argument is yielded into 2
blocks:

- The `arguments_proc` which needs to return the list of arguments the
  job needs to be scheduled with.

- The `context_proc` which needs to return a hash with the context
  information for the job.

## Arguments logging

Sidekiq job arguments are logged by default, unless [`SIDEKIQ_LOG_ARGUMENTS`](../../administration/sidekiq/sidekiq_troubleshooting.md#log-arguments-to-sidekiq-jobs)
is disabled.

By default, the only arguments logged are numeric arguments, because
arguments of other types could contain sensitive information. To
override this, use `loggable_arguments` inside a worker with the indexes
of the arguments to be logged. (Numeric arguments do not need to be
specified here.)

For example:

```ruby
class MyWorker
  include ApplicationWorker

  loggable_arguments 1, 3

  # object_id will be logged as it's numeric
  # string_a will be logged due to the loggable_arguments call
  # string_b will be filtered from logs
  # string_c will be logged due to the loggable_arguments call
  def perform(object_id, string_a, string_b, string_c)
  end
end
```
