---
stage: Verify
group: Runner
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Job logs
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

Job logs are sent by a runner while it's processing a job. You can see
logs in places like job pages, pipelines, and email notifications.

## Data flow

In general, there are two states for job logs: `log` and `archived log`.
In the following table you can see the phases a log goes through:

| Phase          | State        | Condition               | Data flow                                | Stored path |
| -------------- | ------------ | ----------------------- | -----------------------------------------| ----------- |
| 1: patching    | log          | When a job is running   | Runner => Puma => file storage | `#{ROOT_PATH}/gitlab-ci/builds/#{YYYY_mm}/#{project_id}/#{job_id}.log` |
| 2: archiving   | archived log | After a job is finished | Sidekiq moves log to artifacts folder    | `#{ROOT_PATH}/gitlab-rails/shared/artifacts/#{disk_hash}/#{YYYY_mm_dd}/#{job_id}/#{job_artifact_id}/job.log` |
| 3: uploading   | archived log | After a log is archived | Sidekiq moves archived log to [object storage](#uploading-logs-to-object-storage) (if configured) | `#{bucket_name}/#{disk_hash}/#{YYYY_mm_dd}/#{job_id}/#{job_artifact_id}/job.log` |

The `ROOT_PATH` varies per environment:

- For the Linux package it's `/var/opt/gitlab`.
- For self-compiled installations it's `/home/git/gitlab`.

## Changing the job logs local location

NOTE:
For Docker installations, you can change the path where your data is mounted.
For the Helm chart, use object storage.

To change the location where the job logs are stored:

::Tabs

:::TabTitle Linux package (Omnibus)

1. Optional. If you have existing job logs, pause continuous integration data
   processing by temporarily stopping Sidekiq:

   ```shell
   sudo gitlab-ctl stop sidekiq
   ```

1. Set the new storage location in `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_ci['builds_directory'] = '/mnt/gitlab-ci/builds'
   ```

1. Save the file and reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. Use `rsync` to move job logs from the current location to the new location:

   ```shell
   sudo rsync -avzh --remove-source-files --ignore-existing --progress /var/opt/gitlab/gitlab-ci/builds/ /mnt/gitlab-ci/builds/
   ```

   Use `--ignore-existing` so you don't override new job logs with older versions of the same log.

1. If you opted to pause the continuous integration data processing, you can
   start Sidekiq again:

   ```shell
   sudo gitlab-ctl start sidekiq
   ```

1. Remove the old job logs storage location:

   ```shell
   sudo rm -rf /var/opt/gitlab/gitlab-ci/builds
   ```

:::TabTitle Self-compiled (source)

1. Optional. If you have existing job logs, pause continuous integration data
   processing by temporarily stopping Sidekiq:

   ```shell
   # For systems running systemd
   sudo systemctl stop gitlab-sidekiq

   # For systems running SysV init
   sudo service gitlab stop
   ```

1. Edit `/home/git/gitlab/config/gitlab.yml` to set the new storage location:

   ```yaml
   production: &base
     gitlab_ci:
       builds_path: /mnt/gitlab-ci/builds
   ```

1. Save the file and restart GitLab:

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

1. Use `rsync` to move job logs from the current location to the new location:

   ```shell
   sudo rsync -avzh --remove-source-files --ignore-existing --progress /home/git/gitlab/builds/ /mnt/gitlab-ci/builds/
   ```

   Use `--ignore-existing` so you don't override new job logs with older versions of the same log.

1. If you opted to pause the continuous integration data processing, you can
   start Sidekiq again:

   ```shell
   # For systems running systemd
   sudo systemctl start gitlab-sidekiq

   # For systems running SysV init
   sudo service gitlab start
   ```

1. Remove the old job logs storage location:

   ```shell
   sudo rm -rf /home/git/gitlab/builds
   ```

::EndTabs

## Uploading logs to object storage

Archived logs are considered as [job artifacts](job_artifacts.md).
Therefore, when you [set up the object storage integration](job_artifacts.md#using-object-storage),
job logs are automatically migrated to it along with the other job artifacts.

See "Phase 3: uploading" in [Data flow](#data-flow) to learn about the process.

## Maximum log file size

The job log file size limit in GitLab is 100 megabytes by default.
Any job that exceeds the limit is marked as failed, and dropped by the runner.
For more details, see [Maximum file size for job logs](../instance_limits.md#maximum-file-size-for-job-logs).

## Prevent local disk usage

If you want to avoid any local disk usage for job logs,
you can do so using one of the following options:

- Enable the [incremental logging](#incremental-logging-architecture) feature.
- Set the [job logs location](#changing-the-job-logs-local-location)
  to an NFS drive.

## How to remove job logs

There isn't a way to automatically expire old job logs. However, it's safe to remove
them if they're taking up too much space. If you remove the logs manually, the
job output in the UI is empty.

For details on how to delete job logs by using GitLab CLI,
see [Delete job logs](../../user/storage_management_automation.md#delete-job-logs).

Alternatively, you can delete job logs with shell commands. For example, to delete all job logs older than 60 days, run the following
command from a shell in your GitLab instance.

NOTE:
For the Helm chart, use the storage management tools provided with your object
storage.

WARNING:
The following command permanently deletes the log files and is irreversible.

::Tabs

:::TabTitle Linux package (Omnibus)

```shell
find /var/opt/gitlab/gitlab-rails/shared/artifacts -name "job.log" -mtime +60 -delete
```

:::TabTitle Docker

Assuming you mounted `/var/opt/gitlab` to `/srv/gitlab`:

```shell
find /srv/gitlab/gitlab-rails/shared/artifacts -name "job.log" -mtime +60 -delete
```

:::TabTitle Self-compiled (source)

```shell
find /home/git/gitlab/shared/artifacts -name "job.log" -mtime +60 -delete
```

::EndTabs

After the logs are deleted, you can find any broken file references by running
the Rake task that checks the
[integrity of the uploaded files](../raketasks/check.md#uploaded-files-integrity).
For more information, see how to
[delete references to missing artifacts](../raketasks/check.md#delete-references-to-missing-artifacts).

## Incremental logging architecture

> - To use in your instance, ask a GitLab administrator to [enable it](#enable-or-disable-incremental-logging).

By default, job logs are sent from the GitLab Runner in chunks and cached
temporarily on disk. After the job completes, a background job archives the job
log. The log is moved to the artifacts directory by default, or to object
storage if configured.

In a [scaled-out architecture](../reference_architectures/_index.md) with Rails and
Sidekiq running on more than one server, these two locations on the file system
have to be shared using NFS, which is not recommended. Instead:

1. Configure [object storage](job_artifacts.md#using-object-storage) for storing archived job logs.
1. [Enable the incremental logging feature](#enable-or-disable-incremental-logging), which uses Redis instead of disk space for temporary caching of job logs.

### Enable or disable incremental logging

Before you enable the feature flag:

- See [known issues](#known-issues).
- [Enable object storage](job_artifacts.md#using-object-storage).

To enable incremental logging:

1. Open a [Rails console](../operations/rails_console.md#starting-a-rails-console-session).
1. Enable the feature flag:

   ```ruby
   Feature.enable(:ci_enable_live_trace)
   ```

   Running jobs' logs continue to be written to disk, but new jobs use
   incremental logging.

To disable incremental logging:

1. Open a [Rails console](../operations/rails_console.md#starting-a-rails-console-session).
1. Disable the feature flag:

   ```ruby
   Feature.disable(:ci_enable_live_trace)
   ```

   Running jobs continue to use incremental logging, but new jobs write to the disk.

### Technical details

The data flow is the same as described in the [data flow section](#data-flow)
with one change: _the stored path of the first two phases is different_. This incremental
log architecture stores chunks of logs in Redis and a persistent store (object storage or database) instead of
file storage. Redis is used as first-class storage, and it stores up-to 128 KB
of data. After the full chunk is sent, it is flushed to a persistent store, either object storage (temporary directory) or database.
After a while, the data in Redis and a persistent store is archived to [object storage](#uploading-logs-to-object-storage).

The data are stored in the following Redis namespace: `Gitlab::Redis::TraceChunks`.

Here is the detailed data flow:

1. The runner picks a job from GitLab
1. The runner sends a piece of log to GitLab
1. GitLab appends the data to Redis
1. After the data in Redis reaches 128 KB, the data is flushed to a persistent store (object storage or the database).
1. The above steps are repeated until the job is finished.
1. After the job is finished, GitLab schedules a Sidekiq worker to archive the log.
1. The Sidekiq worker archives the log to object storage and cleans up the log
   in Redis and a persistent store (object storage or the database).

### Known issues

- [Redis Cluster is not supported](https://gitlab.com/gitlab-org/gitlab/-/issues/224171).
- You must configure [object storage for CI/CD artifacts, logs, and builds](job_artifacts.md#using-object-storage)
  before you enable the feature flag. After the flag is enabled, files cannot be written
  to disk, and there is no protection against misconfiguration.

For more information, see [epic 3791](https://gitlab.com/groups/gitlab-org/-/epics/3791).
