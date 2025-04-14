---
stage: Verify
group: Runner
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Job logs
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

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

{{< alert type="note" >}}

For Docker installations, you can change the path where your data is mounted.
For the Helm chart, use object storage.

{{< /alert >}}

To change the location where the job logs are stored:

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

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

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

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

{{< /tab >}}

{{< /tabs >}}

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

- Turn on [incremental logging](#incremental-logging).
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

{{< alert type="note" >}}

For the Helm chart, use the storage management tools provided with your object
storage.

{{< /alert >}}

{{< alert type="warning" >}}

The following command permanently deletes the log files and is irreversible.

{{< /alert >}}

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

```shell
find /var/opt/gitlab/gitlab-rails/shared/artifacts -name "job.log" -mtime +60 -delete
```

{{< /tab >}}

{{< tab title="Docker" >}}

Assuming you mounted `/var/opt/gitlab` to `/srv/gitlab`:

```shell
find /srv/gitlab/gitlab-rails/shared/artifacts -name "job.log" -mtime +60 -delete
```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

```shell
find /home/git/gitlab/shared/artifacts -name "job.log" -mtime +60 -delete
```

{{< /tab >}}

{{< /tabs >}}

After the logs are deleted, you can find any broken file references by running
the Rake task that checks the
[integrity of the uploaded files](../raketasks/check.md#uploaded-files-integrity).
For more information, see how to
[delete references to missing artifacts](../raketasks/check.md#delete-references-to-missing-artifacts).

## Incremental logging

Incremental logging changes how job logs are processed and stored, improving performance in scaled-out deployments.

By default, job logs are sent from GitLab Runner in chunks and cached temporarily on disk. After the job completes, a background job archives the log to the artifacts directory or to object storage if configured.

With incremental logging, logs are stored in Redis and a persistent store instead of file storage. This approach:

- Prevents local disk usage for job logs.
- Eliminates the need for NFS sharing between Rails and Sidekiq servers.
- Improves performance in multi-node installations.

The incremental logging process uses Redis as temporary storage and follows this flow:

1. The runner picks a job from GitLab.
1. The runner sends a piece of log to GitLab.
1. GitLab appends the data to Redis in the `Gitlab::Redis::TraceChunks` namespace.
1. After the data in Redis reaches 128 KB, the data is flushed to a persistent store.
1. The above steps repeat until the job is finished.
1. After the job is finished, GitLab schedules a Sidekiq worker to archive the log.
1. The Sidekiq worker archives the log to object storage and cleans up temporary data.

Redis Cluster is not supported with incremental logging.
For more information, see [issue 224171](https://gitlab.com/gitlab-org/gitlab/-/issues/224171).

### Configure incremental logging

Before you turn on incremental logging, you must [configure object storage](job_artifacts.md#using-object-storage) for CI/CD artifacts, logs, and builds. After incremental logging is turned on, files cannot be written to disk, and there is no protection against misconfiguration.

When you turn on incremental logging, running jobs' logs continue to be written to disk, but new jobs use incremental logging.

When you turn off incremental logging, running jobs continue to use incremental logging, but new jobs write to the disk.

To configure incremental logging:

- Use the setting in the [Admin area](../settings/continuous_integration.md#incremental-logging) or the [Settings API](../../api/settings.md).
