# Job traces (logs)

Job traces are sent by gitlab-runner while it's processing a job. You can see traces in job pages, pipelines, email notifications, etc.
Basically, there are two states in job traces. One is "Live trace", and another one is "Archived trace";

|state|condition|step|data flow|stored path|
|---|---|---|---|---|
|Live trace|when a job is running|1: patching| gitlab-runner => gitlab-unicorn => file storage|`#{ROOT_PATH}/builds/#{YYYY_mm}/#{project_id}/#{job_id}.log`|
|Live trace|when a job is finished|2: overwtiring| gitlab-runner => gitlab-unicorn => file storage |`#{ROOT_PATH}/builds/#{YYYY_mm}/#{project_id}/#{job_id}.log`|
|Archived trace|After a job is finished|3: archiving| sidekiq moves live trace to artifacts folder |`#{ROOT_PATH}/shared/artifacts/#{disk_hash}/#{YYYY_mm_dd}/#{job_id}/#{job_artifact_id}/trace.log`|

The `ROOT_PATH` varies per your enviroment. For example, if you used omnibus packages, it would be `/var/opt/gitlab/gitlab-ci`,
whereas if you used source instlation, it would be `/home/git/gitlab`.

There isn't a way to automatically expire old job logs, but it's safe to remove
them if they're taking up too much space. If you remove the logs manually, the
job output in the UI will be empty.

## Changing the job traces location

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

## Upload traces to object storage

Archived trace is one of [job artifacts](job_artifacts.md).
If you set up [object storage settings](https://docs.gitlab.com/ce/administration/job_artifacts.html#object-storage-settings),
job traces are automatically migrated to object storage as well as other job artifacts.

Here is the data flow;

|state|condition|step|data flow|stored path|
|---|---|---|---|---|
|Live trace|when a job is running|1: patching| gitlab-runner => gitlab-unicorn => file storage|`#{ROOT_PATH}/builds/#{YYYY_mm}/#{project_id}/#{job_id}.log`|
|Live trace|when a job is finished|2: overwtiring| gitlab-runner => gitlab-unicorn => file storage |`#{ROOT_PATH}/builds/#{YYYY_mm}/#{project_id}/#{job_id}.log`|
|Archived trace|After a job is finished|3: archiving| sidekiq moves live trace to artifacts folder |`#{ROOT_PATH}/shared/artifacts/#{disk_hash}/#{YYYY_mm_dd}/#{job_id}/#{job_artifact_id}/trace.log`|
|Archived trace|After a trace is archived|4: uploading| sidekiq moves archived trace to object storage |`#{bucket_name}/#{disk_hash}/#{YYYY_mm_dd}/#{job_id}/#{job_artifact_id}/trace.log`|

## New live trace architecture

> [Introduced][ce-18169] in GitLab 10.4.  
> [Announced as General availability][ce-46097] in GitLab 11.0.

> **Notes**:
- Performance improvements are scheduled in [11.1](https://gitlab.com/gitlab-org/gitlab-ce/issues/47125).
- This feature is off by default. Please check below how to enable/disable this featrue.

**For cloud-native compatible application**

By combining the process with object storage settings, we can completely bypass file storage. This is useful option in cloud-native GitLab installtion.

Here is the data flow;

|state|condition|step|data flow|stored path|
|---|---|---|---|---|
|Live trace|when a job is running|1: patching| gitlab-runner => gitlab-unicorn => redis and database|- (Stored in Redis and Database, instead)|
|Live trace|when a job is finished|2: overwtiring| gitlab-runner => gitlab-unicorn => redis and database |- (Stored in Redis and Database, instead)|
|Archived trace|After a job is finished|3: archiving| sidekiq moves live trace to artifacts folder |`#{ROOT_PATH}/shared/artifacts/#{disk_hash}/#{YYYY_mm_dd}/#{job_id}/#{job_artifact_id}/trace.log`|
|Archived trace|After a trace is archived|4: uploading| sidekiq moves archived trace to object storage |`#{bucket_name}/#{disk_hash}/#{YYYY_mm_dd}/#{job_id}/#{job_artifact_id}/trace.log`|

(Step 3 is scheduled to be improved in https://gitlab.com/gitlab-org/gitlab-ce/issues/44663)

**The detailed mechanizm**

This new live trace architecture stores chunks of traces in Redis and database instead of file storage.
Redis is used as first-class storage, and it stores up-to 128kB. Once the full chunk is sent it will be flushed to database. Afterwhile, the data in Redis and database will be archived to ObjectStorage.

Here is the detailed data flow.

1. GitLab Runner picks a job from GitLab-Rails
1. GitLab Runner sends a piece of trace to GitLab-Rails
1. GitLab-Rails appends the data to Redis
1. If the data in Redis is fulfilled 128kB, the data is flushed to Database.
1. 2.~4. is continued until the job is finished
1. Once the job is finished, GitLab-Rails schedules a sidekiq worker to archive the trace
1. The sidekiq worker archives the trace to Object Storage, and cleanup the trace in Redis and Database

**How to check if it's on or off?**

```ruby
Feature.enabled?('ci_enable_live_trace')
```

**How to enable?**

```ruby
Feature.enable('ci_enable_live_trace')
```

>**Note:**
The transition period will be handled gracefully. Upcoming traces will be generated with the new architecture, and on-going live traces will stay with the legacy architecture (i.e. on-going live traces won't be re-generated forcibly with the new architecture).

**How to disable?**

```ruby
Feature.disable('ci_enable_live_trace')
```

>**Note:**
The transition period will be handled gracefully. Upcoming traces will be generated with the legacy architecture, and on-going live traces will stay with the new architecture (i.e. on-going live traces won't be re-generated forcibly with the legacy architecture).

**Redis namespace:**

`Gitlab::Redis::SharedState`

**Potential impact:**

- This feature could incur data loss:
  - Case 1: When all data in Redis are accidentally flushed.
    - On-going live traces could be recovered by re-sending traces (This is supported by all versions of GitLab Runner)
    - Finished jobs which has not archived live traces will lose the last part (~128kB) of trace data.
  - Case 2: When sidekiq workers failed to archive (e.g. There was a bug that prevents archiving process, Sidekiq inconsistancy, etc):
    - Currently all trace data in Redis will be deleted after one week. If the sidekiq workers can't finish by the expiry date, the part of trace data will be lost.
- This feature could consume all memory on Redis instance. If the number of jobs is 1000, 128MB (128kB * 1000) is consumed.
- This feature could pressure Database replication lag. `INSERT` are generated to indicate that we have trace chunk. `UPDATE` with 128kB of data is issued once we receive multiple chunks.
- and so on

**How to test?**

We're currently evaluating this feature on dev.gitalb.org or staging.gitlab.com to verify this features. Here is the list of tests/measurements.

- Features:
  - Live traces should be visible on job pages
  - Archived traces should be visible on job pages
  - Live traces should be archived to Object storage
  - Live traces should be cleaned up after archived
  - etc
- Performance:
  - Schedule 1000~10000 jobs and let GitLab-runners process concurrently. Measure memoery presssure, IO load, etc.
  - etc
- Failover:
  - Simulate Redis outage
  - etc

**How to verify the correctnesss?**

- TBD

[ce-18169]: https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/18169
[ce-46097]: https://gitlab.com/gitlab-org/gitlab-ce/issues/46097
