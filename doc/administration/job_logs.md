# Job logs

> [Renamed from job traces to job logs](https://gitlab.com/gitlab-org/gitlab/issues/29121) in GitLab 12.5.

Job logs are sent by GitLab Runner while it's processing a job. You can see
logs in job pages, pipelines, email notifications, etc.

## Data flow

In general, there are two states for job logs: `log` and `archived log`.
In the following table you can see the phases a log goes through:

| Phase          | State        | Condition               | Data flow                                | Stored path |
| -------------- | ------------ | ----------------------- | -----------------------------------------| ----------- |
| 1: patching    | log          | When a job is running   | GitLab Runner => Unicorn => file storage | `#{ROOT_PATH}/gitlab-ci/builds/#{YYYY_mm}/#{project_id}/#{job_id}.log` |
| 2: overwriting | log          | When a job is finished  | GitLab Runner => Unicorn => file storage | `#{ROOT_PATH}/gitlab-ci/builds/#{YYYY_mm}/#{project_id}/#{job_id}.log` |
| 3: archiving   | archived log | After a job is finished | Sidekiq moves log to artifacts folder    | `#{ROOT_PATH}/gitlab-rails/shared/artifacts/#{disk_hash}/#{YYYY_mm_dd}/#{job_id}/#{job_artifact_id}/job.log` |
| 4: uploading   | archived log | After a log is archived | Sidekiq moves archived log to [object storage](#uploading-logs-to-object-storage) (if configured) | `#{bucket_name}/#{disk_hash}/#{YYYY_mm_dd}/#{job_id}/#{job_artifact_id}/job.log` |

The `ROOT_PATH` varies per environment. For Omnibus GitLab it
would be `/var/opt/gitlab`, and for installations from source
it would be `/home/git/gitlab`.

## Changing the job logs local location

To change the location where the job logs will be stored, follow the steps below.

**In Omnibus installations:**

1. Edit `/etc/gitlab/gitlab.rb` and add or amend the following line:

   ```ruby
   gitlab_ci['builds_directory'] = '/mnt/to/gitlab-ci/builds'
   ```

1. Save the file and [reconfigure GitLab](restart_gitlab.md#omnibus-gitlab-reconfigure) for the
   changes to take effect.

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

## How to remove job logs

There isn't a way to automatically expire old job logs, but it's safe to remove
them if they're taking up too much space. If you remove the logs manually, the
job output in the UI will be empty.

## New incremental logging architecture

> - [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/18169) in GitLab 10.4.
> - [Announced as generally available](https://gitlab.com/gitlab-org/gitlab-foss/issues/46097) in GitLab 11.0.

NOTE: **Note:**
This feature is off by default. See below for how to [enable or disable](#enabling-incremental-logging) it.

By combining the process with object storage settings, we can completely bypass
the local file storage. This is a useful option if GitLab is installed as
cloud-native, for example on Kubernetes.

The data flow is the same as described in the [data flow section](#data-flow)
with one change: _the stored path of the first two phases is different_. This incremental
log architecture stores chunks of logs in Redis and a persistent store (object storage or database) instead of
file storage. Redis is used as first-class storage, and it stores up-to 128KB
of data. Once the full chunk is sent, it is flushed to a persistent store, either object storage (temporary directory) or database.
After a while, the data in Redis and a persistent store will be archived to [object storage](#uploading-logs-to-object-storage).

The data are stored in the following Redis namespace: `Gitlab::Redis::SharedState`.

Here is the detailed data flow:

1. GitLab Runner picks a job from GitLab
1. GitLab Runner sends a piece of log to GitLab
1. GitLab appends the data to Redis
1. Once the data in Redis reach 128KB, the data is flushed to a persistent store (object storage or the database).
1. The above steps are repeated until the job is finished.
1. Once the job is finished, GitLab schedules a Sidekiq worker to archive the log.
1. The Sidekiq worker archives the log to object storage and cleans up the log
   in Redis and a persistent store (object storage or the database).

### Enabling incremental logging

The following commands are to be issued in a Rails console:

```sh
# Omnibus GitLab
gitlab-rails console

# Installation from source
cd /home/git/gitlab
sudo -u git -H bin/rails console RAILS_ENV=production
```

**To check if incremental logging (trace) is enabled:**

```ruby
Feature.enabled?('ci_enable_live_trace')
```

**To enable incremental logging (trace):**

```ruby
Feature.enable('ci_enable_live_trace')
```

NOTE: **Note:**
The transition period will be handled gracefully. Upcoming logs will be
generated with the incremental architecture, and on-going logs will stay with the
legacy architecture, which means that on-going logs won't be forcibly
re-generated with the incremental architecture.

**To disable incremental logging (trace):**

```ruby
Feature.disable('ci_enable_live_trace')
```

NOTE: **Note:**
The transition period will be handled gracefully. Upcoming logs will be generated
with the legacy architecture, and on-going incremental logs will stay with the incremental
architecture, which means that on-going incremental logs won't be forcibly re-generated
with the legacy architecture.

### Potential implications

In some cases, having data stored on Redis could incur data loss:

1. **Case 1: When all data in Redis are accidentally flushed**
   - On going incremental logs could be recovered by re-sending logs (this is
     supported by all versions of the GitLab Runner).
   - Finished jobs which have not archived incremental logs will lose the last part
     (~128KB) of log data.

1. **Case 2: When Sidekiq workers fail to archive (e.g., there was a bug that
   prevents archiving process, Sidekiq inconsistency, etc.)**
   - Currently all log data in Redis will be deleted after one week. If the
     Sidekiq workers can't finish by the expiry date, the part of log data will be lost.

Another issue that might arise is that it could consume all memory on the Redis
instance. If the number of jobs is 1000, 128MB (128KB * 1000) is consumed.

Also, it could pressure the database replication lag. `INSERT`s are generated to
indicate that we have log chunk. `UPDATE`s with 128KB of data is issued once we
receive multiple chunks.
