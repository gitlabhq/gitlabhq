# Job traces (logs)

Job traces are sent by GitLab Runner while it's processing a job. You can see
traces in job pages, pipelines, email notifications, etc.

## Data flow

In general, there are two states in job traces: "live trace" and "archived trace".
In the following table you can see the phases a trace goes through.

| Phase          | State          | Condition                 | Data flow                                       |  Stored path |
| -----          | -----          | ---------                 | ---------                                       |  ----------- |
| 1: patching    | Live trace     | When a job is running     | GitLab Runner => Unicorn => file storage        |`#{ROOT_PATH}/builds/#{YYYY_mm}/#{project_id}/#{job_id}.log`|
| 2: overwriting | Live trace     | When a job is finished    | GitLab Runner => Unicorn => file storage        |`#{ROOT_PATH}/builds/#{YYYY_mm}/#{project_id}/#{job_id}.log`|
| 3: archiving   | Archived trace | After a job is finished   | Sidekiq moves live trace to artifacts folder    |`#{ROOT_PATH}/shared/artifacts/#{disk_hash}/#{YYYY_mm_dd}/#{job_id}/#{job_artifact_id}/job.log`|
| 4: uploading   | Archived trace | After a trace is archived | Sidekiq moves archived trace to [object storage](#uploading-traces-to-object-storage) (if configured)  |`#{bucket_name}/#{disk_hash}/#{YYYY_mm_dd}/#{job_id}/#{job_artifact_id}/job.log`|

The `ROOT_PATH` varies per your environment. For Omnibus GitLab it
would be `/var/opt/gitlab/gitlab-ci`, whereas for installations from source
it would be `/home/git/gitlab`.

## Changing the job traces local location

To change the location where the job logs will be stored, follow the steps below.

**In Omnibus installations:**

1.  Edit `/etc/gitlab/gitlab.rb` and add or amend the following line:

    ```
    gitlab_ci['builds_directory'] = '/mnt/to/gitlab-ci/builds'
    ```

1. Save the file and [reconfigure GitLab][] for the changes to take effect.

---

**In installations from source:**

1. Edit `/home/git/gitlab/config/gitlab.yml` and add or amend the following lines:

    ```yaml
    gitlab_ci:
      # The location where build traces are stored (default: builds/).
      # Relative paths are relative to Rails.root.
      builds_path: path/to/builds/
    ```

1. Save the file and [restart GitLab][] for the changes to take effect.

[reconfigure gitlab]: restart_gitlab.md#omnibus-gitlab-reconfigure "How to reconfigure Omnibus GitLab"
[restart gitlab]: restart_gitlab.md#installations-from-source "How to restart GitLab"

## Uploading traces to object storage

Archived traces are considered as [job artifacts](job_artifacts.md).
Therefore, when you [set up the object storage integration](job_artifacts.md#object-storage-settings),
job traces are automatically migrated to it along with the other job artifacts.

See "Phase 4: uploading" in [Data flow](#data-flow) to learn about the process.

## How to archive legacy job trace files

Legacy job traces, which were created before GitLab 10.5, were not archived regularly.
It's the same state with the "2: overwriting" in the above [Data flow](#data-flow).
To archive those legacy job traces, please follow the instruction below.

1. Execute the following command

    ```bash
    gitlab-rake gitlab:traces:archive
    ```

    After you executed this task, GitLab instance queues up Sidekiq jobs (asynchronous processes)
    for migrating job trace files from local storage to object storage. 
    It could take time to complete the all migration jobs. You can check the progress by the following command

    ```bash
    sudo gitlab-rails console
    ```

    ```bash
    [1] pry(main)> Sidekiq::Stats.new.queues['pipeline_background:archive_trace']
    => 100
    ```

    If the count becomes zero, the archiving processes are done

## How to migrate archived job traces to object storage

> [Introduced][ce-21193] in GitLab 11.3.

If job traces have already been archived into local storage, and you want to migrate those traces to object storage, please follow the instruction below.

1. Ensure [Object storage integration for Job Artifacts](job_artifacts.md#object-storage-settings) is enabled
1. Execute the following command

    ```bash
    gitlab-rake gitlab:traces:migrate
    ```

## How to remove job traces

There isn't a way to automatically expire old job logs, but it's safe to remove
them if they're taking up too much space. If you remove the logs manually, the
job output in the UI will be empty.

## New live trace architecture

> [Introduced][ce-18169] in GitLab 10.4.
> [Announced as General availability][ce-46097] in GitLab 11.0.

NOTE: **Note:**
This feature is off by default. Check below how to [enable/disable](#enabling-live-trace) it.

By combining the process with object storage settings, we can completely bypass
the local file storage. This is a useful option if GitLab is installed as
cloud-native, for example on Kubernetes.

The data flow is the same as described in the [data flow section](#data-flow)
with one change: _the stored path of the first two phases is different_. This new live
trace architecture stores chunks of traces in Redis and a persistent store (object storage or database) instead of
file storage. Redis is used as first-class storage, and it stores up-to 128KB
of data. Once the full chunk is sent, it is flushed to a persistent store, either object storage(temporary directory) or database.
After a while, the data in Redis and a persitent store will be archived to [object storage](#uploading-traces-to-object-storage).

The data are stored in the following Redis namespace: `Gitlab::Redis::SharedState`.

Here is the detailed data flow:

1. GitLab Runner picks a job from GitLab
1. GitLab Runner sends a piece of trace to GitLab
1. GitLab appends the data to Redis
1. Once the data in Redis reach 128KB, the data is flushed to a persistent store (object storage or the database).
1. The above steps are repeated until the job is finished.
1. Once the job is finished, GitLab schedules a Sidekiq worker to archive the trace.
1. The Sidekiq worker archives the trace to object storage and cleans up the trace
   in Redis and a persistent store (object storage or the database).

### Test reports with gitlab.com scale instance

We've already tested this feature on gitlab.com, and concluded that this feature works stably even if it's the gitlab.com scale.
You can see the detailed report on [this issue][infra-4667]

### Potential implications

In some cases, having data stored on Redis could incur data loss:

1. **Case 1: When all data in Redis are accidentally flushed**
   - On going live traces could be recovered by re-sending traces (this is
     supported by all versions of the GitLab Runner).
   - Finished jobs which have not archived live traces will lose the last part
     (~128KB) of trace data.

[ce-18169]: https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/18169
[ce-21193]: https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/21193
[ce-46097]: https://gitlab.com/gitlab-org/gitlab-ce/issues/46097
[infra-4667]: https://gitlab.com/gitlab-com/gl-infra/infrastructure/issues/4667
