# Job traces (logs)

By default, all job traces (logs) are saved to `/var/opt/gitlab/gitlab-ci/builds`
and `/home/git/gitlab/builds` for Omnibus packages and installations from source
respectively. The job logs are organized by year and month (for example, `2017_03`),
and then by project ID.

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

## New live trace architecture

> [Introduced][ce-18169] in GitLab 10.4.

> **Notes**:
- This feature is still Beta, which could impact GitLab.com/on-premises instances, and in the worst case scenario, traces will be lost.
- This feature is still being discussed in [an issue](https://gitlab.com/gitlab-org/gitlab-ce/issues/46097) for the performance improvements.
- This feature is off by default. Please check below how to enable/disable this featrue.

**What is "live trace"?**

It's job traces exists while job is being processed by Gitlab-Runner. You can see the progress in job pages(GUI).
In contrast, all traces will be archived after job is finished, that's called "archived trace".

**What is new architecture?**

So far, when GitLab-Runner sends a job trace to GitLab-Rails, traces have been saved to File Storage as text files.
This was a problem on [Cloud Native-compatible GitLab application](https://gitlab.com/gitlab-com/migration/issues/23) that
GitLab-Rails had to rely on File Storage.

This new live trace architecture stores traces to Redis and Database instead of File Storage.
Redis is used as first-class trace storage, it stores each trace upto 128KB. Once the data is fulfileld, it's flushed to Database. Afterwhile, the data in Redis and Database will be archived to ObjectStorage.

Here is the detailed data flow.

1. GitLab-Runner picks a job from GitLab-Rails
1. GitLab-Runner sends a piece of trace to GitLab-Rails
1. GitLab-Rails appends the data to Redis
1. If the data in Redis is fulfilled 128KB, the data is flushed to Database.
1. 2.~4. is continued until the job is finished
1. Once the job is finished, GitLab-Rails schedules a sidekiq worker to archive the trace
1. The sidekiq worker archives the trace to Object Storage, and cleanup the trace in Redis and Database

**How to check if it's on or off**

```ruby
Feature.enabled?('ci_enable_live_trace')
```

**How to enable**

```ruby
Feature.enable('ci_enable_live_trace')
```

>**Note:**
The transition period will be handled gracefully. Upcoming traces will be generated with the new architecture, and on-going live traces will stay with the legacy architecture (i.e. on-going live traces won't be re-generated forcibly with the new architecture).

**How to disable**

```ruby
Feature.disable('ci_enable_live_trace')
```

>**Note:**
The transition period will be handled gracefully. Upcoming traces will be generated with the legacy architecture, and on-going live traces will stay with the new architecture (i.e. on-going live traces won't be re-generated forcibly with the legacy architecture).

**Redis namespace**

`Gitlab::Redis::SharedState`

**Potential impact**

- This feature could incur data loss
  - Case 1: When all data in Redis are accidentally flushed.
    - On-going live traces could be recovered by re-sending traces (This is supported by all versions of GitLab-Runner)
    - Finished jobs which has not archived live traces will lose the last part(~128KB) of trace data.
  - Case 2: When sidekiq workers failed to archive (e.g. There was a bug that prevents archiving process, Sidekiq inconsistancy, etc)
    - Currently all trace data in Redis will be deleted after one week. If the sidekiq workers can't finish by the expiry date, the part of trace data will be lost.
- This feature could consume all memeory on Redis instance. If the number of jobs is 1000, 128KB * 1000 = 128MB is consumed.
- This feature could pressure Database instance. `INSERT` is queried per 128KB per a job. `UPDATE` is queried with the same condition, but only if the total size of the trace exceeds 128KB.
- and so on

**How to test**

We're currently evaluating this feature on dev.gitalb.org or staging.gitlab.com to verify this features. Here is the list of tests/measurements.

- Features
  - Live traces should be visible on job pages
  - Archived traces should be visible on job pages
  - Live traces should be archived to Object storage
  - Live traces should be cleaned up after archived
  - etc
- Performance
  - Schedule 1000~10000 jobs and let GitLab-runners process concurrently. Measure memoery presssure, IO load, etc.
  - etc
- Failover
  - Simulate Redis outage
  - etc

**How to verify the correctnesss**
 
 - TBD

[ce-44935]: https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/18169
