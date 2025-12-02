---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Sidekiq configuration for imports
description: Optimize Sidekiq configuration for importing or migrating to GitLab.
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

Importers rely heavily on Sidekiq jobs to handle the import and export of groups and projects.
Some of these jobs might consume significant resources (CPU and memory) and
take a long time to complete, which might affect the execution of other jobs.

To resolve this issue, you should route importer jobs to a dedicated Sidekiq queue and
assign a dedicated Sidekiq process to handle that queue.

For example, you can use the following configuration:

```conf
sidekiq['concurrency'] = 20

sidekiq['routing_rules'] = [
  # Route import and export jobs to the importer queue
  ['feature_category=importers', 'importers'],

  # Route all other jobs to the default queue by using wildcard matching
  ['*', 'default']
]

sidekiq['queue_groups'] = [
  # Run a dedicated process for the importer queue
  'importers',

  # Run a separate process for the default and mailer queues
  'default,mailers'
]
```

In this setup:

- A dedicated Sidekiq process handles import and export jobs through the importer queue.
- Another Sidekiq process handles all other jobs (the default and mailer queues).
- Both Sidekiq processes are configured to run with 20 concurrent threads by default.
  For memory-constrained environments, you might want to reduce this number.

## Configure additional processes

If your instance has enough resources to support more concurrent jobs,
you can configure additional Sidekiq processes to speed up migrations.

For the maximum number of Sidekiq processes, keep the following in mind:

- The number of processes should not exceed the number of available CPU cores.
- Each process can use up to 2 GB of memory, so ensure the instance
  has enough memory for any additional processes.
- Each process adds one database connection per thread
  as defined in `sidekiq['concurrency']`.

For example:

```conf
sidekiq['queue_groups'] = [
  # Run three processes for importer jobs
  'importers',
  'importers',
  'importers',

  # Run a separate process for the default and mailer queues
  'default,mailers'
]
```

With this setup, multiple Sidekiq processes handle import and export jobs concurrently,
which speeds up migration as long as the instance has sufficient resources.

## Related topics

- [Import and migrate to GitLab](../../user/import/_index.md).
- [Import and export settings](../settings/import_and_export_settings.md).
- [Running multiple Sidekiq processes](extra_sidekiq_processes.md).
- [Processing specific job classes](processing_specific_job_classes.md).
