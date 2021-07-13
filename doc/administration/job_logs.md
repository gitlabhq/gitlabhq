---
stage: Verify
group: Runner
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference
---

# Job logs **(FREE SELF)**

> [Renamed from job traces to job logs](https://gitlab.com/gitlab-org/gitlab/-/issues/29121) in GitLab 12.5.

Job logs are sent by a runner while it's processing a job. You can see
logs in job pages, pipelines, email notifications, and so on.

## Data flow

In general, there are two states for job logs: `log` and `archived log`.
In the following table you can see the phases a log goes through:

| Phase          | State        | Condition               | Data flow                                | Stored path |
| -------------- | ------------ | ----------------------- | -----------------------------------------| ----------- |
| 1: patching    | log          | When a job is running   | Runner => Puma => file storage | `#{ROOT_PATH}/gitlab-ci/builds/#{YYYY_mm}/#{project_id}/#{job_id}.log` |
| 2: archiving   | archived log | After a job is finished | Sidekiq moves log to artifacts folder    | `#{ROOT_PATH}/gitlab-rails/shared/artifacts/#{disk_hash}/#{YYYY_mm_dd}/#{job_id}/#{job_artifact_id}/job.log` |
| 3: uploading   | archived log | After a log is archived | Sidekiq moves archived log to [object storage](#uploading-logs-to-object-storage) (if configured) | `#{bucket_name}/#{disk_hash}/#{YYYY_mm_dd}/#{job_id}/#{job_artifact_id}/job.log` |

The `ROOT_PATH` varies per environment. For Omnibus GitLab it
would be `/var/opt/gitlab`, and for installations from source
it would be `/home/git/gitlab`.

## Changing the job logs local location

To change the location where the job logs are stored, follow the steps below.

**In Omnibus installations:**

1. Edit `/etc/gitlab/gitlab.rb` and add or amend the following line:

   ```ruby
   gitlab_ci['builds_directory'] = '/mnt/to/gitlab-ci/builds'
   ```

1. Save the file and [reconfigure GitLab](restart_gitlab.md#omnibus-gitlab-reconfigure) for the
   changes to take effect.

Alternatively, if you have existing job logs you can follow
these steps to move the logs to a new location without losing any data.

1. Pause continuous integration data processing by updating this setting in `/etc/gitlab/gitlab.rb`.
   Jobs in progress are not affected, based on how [data flow](#data-flow) works.

   ```ruby
   sidekiq['queue_selector'] = true
   sidekiq['queue_groups'] = [
     "feature_category!=continuous_integration"
   ]
   ```

1. Save the file and [reconfigure GitLab](restart_gitlab.md#omnibus-gitlab-reconfigure) for the
   changes to take effect.
1. Set the new storage location in `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_ci['builds_directory'] = '/mnt/to/gitlab-ci/builds'
   ```

1. Save the file and [reconfigure GitLab](restart_gitlab.md#omnibus-gitlab-reconfigure) for the
   changes to take effect.
1. Use `rsync` to move job logs from the current location to the new location:

   ```shell
   sudo rsync -avzh --remove-source-files --ignore-existing --progress /var/opt/gitlab/gitlab-ci/builds/ /mnt/to/gitlab-ci/builds`
   ```

   Use `--ignore-existing` so you don't override new job logs with older versions of the same log.
1. Resume continuous integration data processing by editing `/etc/gitlab/gitlab.rb` and removing the `sidekiq` setting you updated earlier.
1. Save the file and [reconfigure GitLab](restart_gitlab.md#omnibus-gitlab-reconfigure) for the
   changes to take effect.
1. Remove the old job logs storage location:

   ```shell
   sudo rm -rf /var/opt/gitlab/gitlab-ci/builds`
   ```

**In installations from source:**

1. Edit `/home/git/gitlab/config/gitlab.yml` and add or amend the following lines:

   ```yaml
   gitlab_ci:
     # The location where build logs are stored (default: builds/).
     # Relative paths are relative to Rails.root.
     builds_path: path/to/builds/
   ```

1. Save the file and [restart GitLab](restart_gitlab.md#installations-from-source) for the changes
   to take effect.

## Uploading logs to object storage

Archived logs are considered as [job artifacts](job_artifacts.md).
Therefore, when you [set up the object storage integration](job_artifacts.md#object-storage-settings),
job logs are automatically migrated to it along with the other job artifacts.

See "Phase 4: uploading" in [Data flow](#data-flow) to learn about the process.

## Prevent local disk usage

If you want to avoid any local disk usage for job logs,
you can do so using one of the following options:

- Enable the [incremental logging](#incremental-logging-architecture) feature.
- Set the [job logs location](#changing-the-job-logs-local-location)
  to an NFS drive.

## How to remove job logs

There isn't a way to automatically expire old job logs, but it's safe to remove
them if they're taking up too much space. If you remove the logs manually, the
job output in the UI is empty.

For example, to delete all job logs older than 60 days, run the following from a shell in your GitLab instance:

WARNING:
This command permanently deletes the log files and is irreversible.

```shell
find /var/opt/gitlab/gitlab-rails/shared/artifacts -name "job.log" -mtime +60 -delete
```

NOTE:
After execution, broken file references can be reported when running
[`sudo gitlab-rake gitlab:artifacts:check`](raketasks/check.md#uploaded-files-integrity).
For more information, see [delete references to missing artifacts](raketasks/check.md#delete-references-to-missing-artifacts).

## Incremental logging architecture

> - [Deployed behind a feature flag](../user/feature_flags.md), disabled by default.
> - Enabled on GitLab.com.
> - [Recommended for production use](https://gitlab.com/groups/gitlab-org/-/epics/4275) in GitLab 13.6.
> - [Recommended for production use with AWS S3](https://gitlab.com/gitlab-org/gitlab/-/issues/273498) in GitLab 13.7.
> - To use in GitLab self-managed instances, ask a GitLab administrator to [enable it](#enable-or-disable-incremental-logging). **(FREE SELF)**

By default job logs are sent from the GitLab Runner in chunks and cached temporarily on disk
in `/var/opt/gitlab/gitlab-ci/builds` by Omnibus GitLab. After the job completes,
a background job archives the job log. The log is moved to `/var/opt/gitlab/gitlab-rails/shared/artifacts/`
by default, or to object storage if configured.

In a [scaled-out architecture](reference_architectures/index.md) with Rails and Sidekiq running on more than one
server, these two locations on the filesystem have to be shared using NFS.

To eliminate both filesystem requirements:

- [Enable the incremental logging feature](#enable-or-disable-incremental-logging), which uses Redis instead of disk space for temporary caching of job logs.
- Configure [object storage](job_artifacts.md#object-storage-settings) for storing archived job logs.

### Technical details

The data flow is the same as described in the [data flow section](#data-flow)
with one change: _the stored path of the first two phases is different_. This incremental
log architecture stores chunks of logs in Redis and a persistent store (object storage or database) instead of
file storage. Redis is used as first-class storage, and it stores up-to 128KB
of data. After the full chunk is sent, it is flushed to a persistent store, either object storage (temporary directory) or database.
After a while, the data in Redis and a persistent store is archived to [object storage](#uploading-logs-to-object-storage).

The data are stored in the following Redis namespace: `Gitlab::Redis::TraceChunks`.

Here is the detailed data flow:

1. The runner picks a job from GitLab
1. The runner sends a piece of log to GitLab
1. GitLab appends the data to Redis
1. After the data in Redis reaches 128KB, the data is flushed to a persistent store (object storage or the database).
1. The above steps are repeated until the job is finished.
1. After the job is finished, GitLab schedules a Sidekiq worker to archive the log.
1. The Sidekiq worker archives the log to object storage and cleans up the log
   in Redis and a persistent store (object storage or the database).

### Limitations

- [Redis cluster is not supported](https://gitlab.com/gitlab-org/gitlab/-/issues/224171).
- You must configure [object storage for CI/CD artifacts, logs, and builds](job_artifacts.md#object-storage-settings)
  before you enable the feature flag. After the flag is enabled, files cannot be written
  to disk, and there is no protection against misconfiguration.
- There is [an epic tracking other potential limitations and improvements](https://gitlab.com/groups/gitlab-org/-/epics/3791).

### Enable or disable incremental logging **(FREE SELF)**

Incremental logging is under development, but [ready for production use as of GitLab 13.6](https://gitlab.com/groups/gitlab-org/-/epics/4275). It is
deployed behind a feature flag that is **disabled by default**.
[GitLab administrators with access to the GitLab Rails console](feature_flags.md)
can enable it.

Before you enable the feature flag:

- Review [the limitations of incremental logging](#limitations).
- [Enable object storage](job_artifacts.md#object-storage-settings).

To enable incremental logging:

```ruby
Feature.enable(:ci_enable_live_trace)
```

Running jobs' logs continue to be written to disk, but new jobs use
incremental logging.

To disable incremental logging:

```ruby
Feature.disable(:ci_enable_live_trace)
```

Running jobs continue to use incremental logging, but new jobs write to the disk.
