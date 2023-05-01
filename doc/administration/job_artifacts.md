---
stage: Verify
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Jobs artifacts administration **(FREE SELF)**

This is the administration documentation. To learn how to use job artifacts in your GitLab CI/CD pipeline,
see the [job artifacts configuration documentation](../ci/jobs/job_artifacts.md).

An artifact is a list of files and directories attached to a job after it
finishes. This feature is enabled by default in all GitLab installations.

## Disabling job artifacts

To disable artifacts site-wide:

::Tabs

:::TabTitle Linux package (Omnibus)

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['artifacts_enabled'] = false
   ```

1. Save the file and reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

:::TabTitle Helm chart (Kubernetes)

1. Export the Helm values:

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. Edit `gitlab_values.yaml`:

   ```yaml
   global:
     appConfig:
       artifacts:
         enabled: false
   ```

1. Save the file and apply the new values:

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

:::TabTitle Docker

1. Edit `docker-compose.yml`:

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['artifacts_enabled'] = false
   ```

1. Save the file and restart GitLab:

   ```shell
   docker compose up -d
   ```

:::TabTitle Self-compiled (source)

1. Edit `/home/git/gitlab/config/gitlab.yml`:

   ```yaml
   production: &base
     artifacts:
       enabled: false
   ```

1. Save the file and restart GitLab:

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

::EndTabs

## Storing job artifacts

GitLab Runner can upload an archive containing the job artifacts to GitLab. By default,
this is done when the job succeeds, but can also be done on failure, or always, with the
[`artifacts:when`](../ci/yaml/index.md#artifactswhen) parameter.

Most artifacts are compressed by GitLab Runner before being sent to the coordinator. The exception to this is
[reports artifacts](../ci/yaml/index.md#artifactsreports), which are compressed after uploading.

### Using local storage

If you're using the Linux package or have a self-compiled installation, you
can change the location where the artifacts are stored locally.

NOTE:
For Docker installations, you can change the path where your data is mounted.
For the Helm chart, use
[object storage](https://docs.gitlab.com/charts/advanced/external-object-storage/).

::Tabs

:::TabTitle Linux package (Omnibus)

The artifacts are stored by default in `/var/opt/gitlab/gitlab-rails/shared/artifacts`.

1. To change the storage path, for example to `/mnt/storage/artifacts`, edit
   `/etc/gitlab/gitlab.rb` and add the following line:

   ```ruby
   gitlab_rails['artifacts_path'] = "/mnt/storage/artifacts"
   ```

1. Save the file and reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

:::TabTitle Self-compiled (source)

The artifacts are stored by default in `/home/git/gitlab/shared/artifacts`.

1. To change the storage path, for example to `/mnt/storage/artifacts`, edit
   `/home/git/gitlab/config/gitlab.yml` and add or amend the following lines:

   ```yaml
   production: &base
     artifacts:
       enabled: true
       path: /mnt/storage/artifacts
   ```

1. Save the file and restart GitLab:

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

::EndTabs

### Using object storage

If you don't want to use the local disk where GitLab is installed to store the
artifacts, you can use an object storage like AWS S3 instead.

If you configure GitLab to store artifacts on object storage, you may also want to
[eliminate local disk usage for job logs](job_logs.md#prevent-local-disk-usage).
In both cases, job logs are archived and moved to object storage when the job completes.

WARNING:
In a multi-server setup you must use one of the options to
[eliminate local disk usage for job logs](job_logs.md#prevent-local-disk-usage), or job logs could be lost.

In GitLab 13.2 and later, you should use the
[consolidated object storage settings](object_storage.md#configure-a-single-storage-connection-for-all-object-types-consolidated-form).

### Migrating to object storage

You can migrate the job artifacts from local storage to object storage. The
processing is done in a background worker and requires **no downtime**.

1. [Configure the object storage](#using-object-storage).
1. Migrate the artifacts:

   ::Tabs

   :::TabTitle Linux package (Omnibus)

   ```shell
   sudo gitlab-rake gitlab:artifacts:migrate
   ```

   :::TabTitle Docker

   ```shell
   sudo docker exec -t <container name> gitlab-rake gitlab:artifacts:migrate
   ```

   :::TabTitle Self-compiled (source)

   ```shell
   sudo -u git -H bundle exec rake gitlab:artifacts:migrate RAILS_ENV=production
   ```

   ::EndTabs

1. Optional. Track the progress and verify that all job artifacts migrated
   successfully using the PostgreSQL console.
   1. Open a PostgreSQL console:

      ::Tabs

      :::TabTitle Linux package (Omnibus)

      ```shell
      sudo gitlab-psql
      ```

      :::TabTitle Docker

      ```shell
      sudo docker exec -it <container_name> /bin/bash
      gitlab-psql
      ```

      :::TabTitle Self-compiled (source)

      ```shell
      sudo -u git -H psql -d gitlabhq_production
      ```

      ::EndTabs

   1. Verify that all artifacts migrated to object storage with the following
      SQL query. The number of `objectstg` should be the same as `total`:

      ```shell
      gitlabhq_production=# SELECT count(*) AS total, sum(case when file_store = '1' then 1 else 0 end) AS filesystem, sum(case when file_store = '2' then 1 else 0 end) AS objectstg FROM ci_job_artifacts;

      total | filesystem | objectstg
      ------+------------+-----------
         19 |          0 |        19
      ```

1. Verify that there are no files on disk in the `artifacts` directory:

   ::Tabs

   :::TabTitle Linux package (Omnibus)

   ```shell
   sudo find /var/opt/gitlab/gitlab-rails/shared/artifacts -type f | grep -v tmp | wc -l
   ```

   :::TabTitle Docker

   Assuming you mounted `/var/opt/gitlab` to `/srv/gitlab`:

   ```shell
   sudo find /srv/gitlab/gitlab-rails/shared/artifacts -type f | grep -v tmp | wc -l
   ```

   :::TabTitle Self-compiled (source)

   ```shell
   sudo find /home/git/gitlab/shared/artifacts -type f | grep -v tmp | wc -l
   ```

   ::EndTabs

In some cases, you need to run the [orphan artifact file cleanup Rake task](../raketasks/cleanup.md#remove-orphan-artifact-files)
to clean up orphaned artifacts.

### Migrating from object storage to local storage

To migrate back to local storage, you must
[selectively disable the artifacts storage](object_storage.md#disable-object-storage-for-specific-features).

## Expiring artifacts

If [`artifacts:expire_in`](../ci/yaml/index.md#artifactsexpire_in) is used to set
an expiry for the artifacts, they are marked for deletion right after that date passes.
Otherwise, they expire per the [default artifacts expiration setting](../user/admin_area/settings/continuous_integration.md).

Artifacts are cleaned up by the `expire_build_artifacts_worker` cron job which Sidekiq
runs every 7 minutes (`*/7 * * * *` in [Cron](../topics/cron/index.md) syntax).

To change the default schedule on which the artifacts are expired:

::Tabs

:::TabTitle Linux package (Omnibus)

1. Edit `/etc/gitlab/gitlab.rb` and add the following line (or uncomment it if
   it already exists and is commented out), substituting your schedule in cron
   syntax:

   ```ruby
   gitlab_rails['expire_build_artifacts_worker_cron'] = "*/7 * * * *"
   ```

1. Save the file and reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

:::TabTitle Helm chart (Kubernetes)

1. Export the Helm values:

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. Edit `gitlab_values.yaml`:

   ```yaml
   global:
     appConfig:
       cron_jobs:
         expire_build_artifacts_worker:
           cron: "*/7 * * * *"
   ```

1. Save the file and apply the new values:

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

:::TabTitle Docker

1. Edit `docker-compose.yml`:

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['expire_build_artifacts_worker_cron'] = "*/7 * * * *"
   ```

1. Save the file and restart GitLab:

   ```shell
   docker compose up -d
   ```

:::TabTitle Self-compiled (source)

1. Edit `/home/git/gitlab/config/gitlab.yml`:

   ```yaml
   production: &base
     cron_jobs:
       expire_build_artifacts_worker:
         cron: "*/7 * * * *"
   ```

1. Save the file and restart GitLab:

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

::EndTabs

## Set the maximum file size of the artifacts

If artifacts are enabled, you can change the maximum file size of the
artifacts through the [Admin Area settings](../user/admin_area/settings/continuous_integration.md#maximum-artifacts-size).

## Storage statistics

You can see the total storage used for job artifacts on groups and projects
in the administration area, as well as through the [groups](../api/groups.md)
and [projects APIs](../api/projects.md).

## Implementation details

When GitLab receives an artifacts archive, an archive metadata file is also
generated by [GitLab Workhorse](https://gitlab.com/gitlab-org/gitlab-workhorse). This metadata file describes all the entries
that are located in the artifacts archive itself.
The metadata file is in a binary format, with additional Gzip compression.

GitLab doesn't extract the artifacts archive to save space, memory, and disk
I/O. It instead inspects the metadata file which contains all the relevant
information. This is especially important when there is a lot of artifacts, or
an archive is a very large file.

When selecting a specific file, [GitLab Workhorse](https://gitlab.com/gitlab-org/gitlab-workhorse) extracts it
from the archive and the download begins. This implementation saves space,
memory and disk I/O.

## Troubleshooting

### Job artifacts using too much disk space

Job artifacts can fill up your disk space quicker than expected. Some possible
reasons are:

- Users have configured job artifacts expiration to be longer than necessary.
- The number of jobs run, and hence artifacts generated, is higher than expected.
- Job logs are larger than expected, and have accumulated over time.
- The file system might run out of inodes because
  [empty directories are left behind by artifact housekeeping](https://gitlab.com/gitlab-org/gitlab/-/issues/17465).
  [The Rake task for _orphaned_ artifact files](../raketasks/cleanup.md#remove-orphan-artifact-files)
  removes these.
- Artifact files might be left on disk and not deleted by housekeeping. Run the
  [Rake task for _orphaned_ artifact files](../raketasks/cleanup.md#remove-orphan-artifact-files)
  to remove these. This script should always find work to do, as it also removes empty directories (see above).
- [Artifact housekeeping was changed significantly](#artifacts-housekeeping-disabled-in-gitlab-146-to-152),
  and you might need to enable a feature flag to used the updated system.
- The [keep latest artifacts from most recent success jobs](../ci/jobs/job_artifacts.md#keep-artifacts-from-most-recent-successful-jobs)
  feature is enabled.

In these and other cases, identify the projects most responsible
for disk space usage, figure out what types of artifacts are using the most
space, and in some cases, manually delete job artifacts to reclaim disk space.

#### Artifacts housekeeping disabled in GitLab 14.6 to 15.2

Artifact housekeeping was significantly changed in GitLab 14.10, and the changes
were back ported to GitLab 14.6 and later. The updated housekeeping must be
enabled with feature flags [until GitLab 15.3](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/92931).

To check if the feature flags are enabled:

1. Start a [Rails console](operations/rails_console.md#starting-a-rails-console-session).

1. Check if the feature flags are enabled.

   - GitLab 14.10 and earlier:

     ```ruby
     Feature.enabled?(:ci_detect_wrongly_expired_artifacts, default_enabled: :yaml)
     Feature.enabled?(:ci_update_unlocked_job_artifacts, default_enabled: :yaml)
     Feature.enabled?(:ci_destroy_unlocked_job_artifacts, default_enabled: :yaml)
     ```

   - GitLab 15.00 and later:

     ```ruby
     Feature.enabled?(:ci_detect_wrongly_expired_artifacts)
     Feature.enabled?(:ci_update_unlocked_job_artifacts)
     Feature.enabled?(:ci_destroy_unlocked_job_artifacts)
     ```

1. If any of the feature flags are disabled, enable them:

   ```ruby
   Feature.enable(:ci_detect_wrongly_expired_artifacts)
   Feature.enable(:ci_update_unlocked_job_artifacts)
   Feature.enable(:ci_destroy_unlocked_job_artifacts)
   ```

These changes include switching artifacts from `unlocked` to `locked` if
they [should be retained](../ci/jobs/job_artifacts.md#keep-artifacts-from-most-recent-successful-jobs).

Artifacts created before this feature was introduced have a status of `unknown`. After they expire,
these artifacts are not processed by the new housekeeping jobs.

You can check the database to confirm if your instance has artifacts with the `unknown` status:

1. Start a database console:

   ::Tabs

   :::TabTitle Linux package (Omnibus)

   ```shell
   sudo gitlab-psql
   ```

   :::TabTitle Helm chart (Kubernetes)

   ```shell
   # Find the toolbox pod
   kubectl --namespace <namespace> get pods -lapp=toolbox
   # Connect to the PostgreSQL console
   kubectl exec -it <toolbox-pod-name> -- /srv/gitlab/bin/rails dbconsole --include-password --database main
   ```

   :::TabTitle Docker

   ```shell
   sudo docker exec -it <container_name> /bin/bash
   gitlab-psql
   ```

   :::TabTitle Self-compiled (source)

   ```shell
   sudo -u git -H psql -d gitlabhq_production
   ```

   ::EndTabs

1. Run the following query:

   ```sql
   select expire_at, file_type, locked, count(*) from ci_job_artifacts
   where expire_at is not null and
   file_type != 3
   group by expire_at, file_type, locked having count(*) > 1;
   ```

If records are returned, then there are artifacts which the housekeeping job
is unable to process. For example:

```plaintext
           expire_at           | file_type | locked | count
-------------------------------+-----------+--------+--------
 2021-06-21 22:00:00+00        |         1 |      2 |  73614
 2021-06-21 22:00:00+00        |         2 |      2 |  73614
 2021-06-21 22:00:00+00        |         4 |      2 |   3522
 2021-06-21 22:00:00+00        |         9 |      2 |     32
 2021-06-21 22:00:00+00        |        12 |      2 |    163
```

Artifacts with locked status `2` are `unknown`. Check
[issue #346261](https://gitlab.com/gitlab-org/gitlab/-/issues/346261#note_1028871458)
for more details.

The Sidekiq worker that processes all `unknown` artifacts is enabled by default in
GitLab 15.3 and later. It analyzes the artifacts returned by the above database query and
determines which should be `locked` or `unlocked`. Artifacts are then deleted
by that worker if needed.

The worker can be enabled on self-managed instances running GitLab 14.10 and later:

1. Start a [Rails console](operations/rails_console.md#starting-a-rails-console-session).

1. Check if the feature is enabled.

   - GitLab 14.10:

     ```ruby
     Feature.enabled?(:ci_job_artifacts_backlog_work, default_enabled: :yaml)
     ```

   - GitLab 15.0 and later:

     ```ruby
     Feature.enabled?(:ci_job_artifacts_backlog_work)
     ```

1. Enable the feature, if needed:

   ```ruby
   Feature.enable(:ci_job_artifacts_backlog_work)
   ```

The worker processes 10,000 `unknown` artifacts every seven minutes, or roughly two million
in 24 hours.

There is a related `ci_job_artifacts_backlog_large_loop_limit` feature flag
which causes the worker to process `unknown` artifacts
[in batches that are five times larger](https://gitlab.com/gitlab-org/gitlab/-/issues/356319).
This flag is not recommended for use on self-managed instances.

#### List projects and builds with artifacts with a specific expiration (or no expiration)

Using a [Rails console](operations/rails_console.md), you can find projects that have job artifacts with either:

- No expiration date.
- An expiration date more than 7 days in the future.

Similar to [deleting artifacts](#delete-job-artifacts-from-jobs-completed-before-a-specific-date), use the following example time frames
and alter them as needed:

- `7.days.from_now`
- `10.days.from_now`
- `2.weeks.from_now`
- `3.months.from_now`

Each of the following scripts also limits the search to 50 results with `.limit(50)`, but this number can also be changed as needed:

```ruby
# Find builds & projects with artifacts that never expire
builds_with_artifacts_that_never_expire = Ci::Build.with_downloadable_artifacts.where(artifacts_expire_at: nil).limit(50)
builds_with_artifacts_that_never_expire.find_each do |build|
  puts "Build with id #{build.id} has artifacts that don't expire and belongs to project #{build.project.full_path}"
end

# Find builds & projects with artifacts that expire after 7 days from today
builds_with_artifacts_that_expire_in_a_week = Ci::Build.with_downloadable_artifacts.where('artifacts_expire_at > ?', 7.days.from_now).limit(50)
builds_with_artifacts_that_expire_in_a_week.find_each do |build|
  puts "Build with id #{build.id} has artifacts that expire at #{build.artifacts_expire_at} and belongs to project #{build.project.full_path}"
end
```

#### List projects by total size of job artifacts stored

List the top 20 projects, sorted by the total size of job artifacts stored, by
running the following code in the Rails console (`sudo gitlab-rails console`):

```ruby
include ActionView::Helpers::NumberHelper
ProjectStatistics.order(build_artifacts_size: :desc).limit(20).each do |s|
  puts "#{number_to_human_size(s.build_artifacts_size)} \t #{s.project.full_path}"
end
```

You can change the number of projects listed by modifying `.limit(20)` to the
number you want.

#### List largest artifacts in a single project

List the 50 largest job artifacts in a single project by running the following
code in the Rails console (`sudo gitlab-rails console`):

```ruby
include ActionView::Helpers::NumberHelper
project = Project.find_by_full_path('path/to/project')
Ci::JobArtifact.where(project: project).order(size: :desc).limit(50).map { |a| puts "ID: #{a.id} - #{a.file_type}: #{number_to_human_size(a.size)}" }
```

You can change the number of job artifacts listed by modifying `.limit(50)` to
the number you want.

#### List artifacts in a single project

List the artifacts for a single project, sorted by artifact size. The output includes the:

- ID of the job that created the artifact
- artifact size
- artifact file type
- artifact creation date
- on-disk location of the artifact

```ruby
p = Project.find_by_id(<project_id>)
arts = Ci::JobArtifact.where(project: p)

list = arts.order(size: :desc).limit(50).each do |art|
    puts "Job ID: #{art.job_id} - Size: #{art.size}b - Type: #{art.file_type} - Created: #{art.created_at} - File loc: #{art.file}"
end
```

To change the number of job artifacts listed, change the number in `limit(50)`.

#### Delete job artifacts from jobs completed before a specific date

WARNING:
These commands remove data permanently from both the database and from disk. Before running them, we highly recommend seeking guidance from a Support Engineer, or running them in a test environment with a backup of the instance ready to be restored, just in case.

If you need to manually remove job artifacts associated with multiple jobs while
**retaining their job logs**, this can be done from the Rails console (`sudo gitlab-rails console`):

1. Select jobs to be deleted:

   To select all jobs with artifacts for a single project:

   ```ruby
   project = Project.find_by_full_path('path/to/project')
   builds_with_artifacts =  project.builds.with_downloadable_artifacts
   ```

   To select all jobs with artifacts across the entire GitLab instance:

   ```ruby
   builds_with_artifacts = Ci::Build.with_downloadable_artifacts
   ```

1. Delete job artifacts older than a specific date:

   NOTE:
   This step also erases artifacts that users have chosen to
   ["keep"](../ci/jobs/job_artifacts.md#download-job-artifacts).

   ```ruby
   builds_to_clear = builds_with_artifacts.where("finished_at < ?", 1.week.ago)
   builds_to_clear.find_each do |build|
     Ci::JobArtifacts::DeleteService.new(build).execute
     build.update!(artifacts_expire_at: Time.now)
   end
   ```

   In [GitLab 15.3 and earlier](https://gitlab.com/gitlab-org/gitlab/-/issues/372537), use the following instead:

   ```ruby
   builds_to_clear = builds_with_artifacts.where("finished_at < ?", 1.week.ago)
   builds_to_clear.find_each do |build|
     build.artifacts_expire_at = Time.now
     build.erase_erasable_artifacts!
   end
   ```

   `1.week.ago` is a Rails `ActiveSupport::Duration` method which calculates a new
   date or time in the past. Other valid examples are:

   - `7.days.ago`
   - `3.months.ago`
   - `1.year.ago`

   `erase_erasable_artifacts!` is a synchronous method, and upon execution the artifacts are immediately removed;
   they are not scheduled by a background queue.

#### Delete job artifacts and logs from jobs completed before a specific date

WARNING:
These commands remove data permanently from both the database and from disk. Before running them, we highly recommend seeking guidance from a Support Engineer, or running them in a test environment with a backup of the instance ready to be restored, just in case.

If you need to manually remove **all** job artifacts associated with multiple jobs,
**including job logs**, this can be done from the Rails console (`sudo gitlab-rails console`):

1. Select the jobs to be deleted:

   To select jobs with artifacts for a single project:

   ```ruby
   project = Project.find_by_full_path('path/to/project')
   builds_with_artifacts =  project.builds.with_existing_job_artifacts(Ci::JobArtifact.trace)
   ```

   To select jobs with artifacts across the entire GitLab instance:

   ```ruby
   builds_with_artifacts = Ci::Build.with_existing_job_artifacts(Ci::JobArtifact.trace)
   ```

1. Select the user which is mentioned in the web UI as erasing the job:

   ```ruby
   admin_user = User.find_by(username: 'username')
   ```

1. Erase the job artifacts and logs older than a specific date:

   ```ruby
   builds_to_clear = builds_with_artifacts.where("finished_at < ?", 1.week.ago)
   builds_to_clear.find_each do |build|
     print "Ci::Build ID #{build.id}... "

     if build.erasable?
       Ci::BuildEraseService.new(build, admin_user).execute
       puts "Erased"
     else
       puts "Skipped (Nothing to erase or not erasable)"
     end
   end
   ```

   In [GitLab 15.3 and earlier](https://gitlab.com/gitlab-org/gitlab/-/issues/369132), replace
   `Ci::BuildEraseService.new(build, admin_user).execute` with `build.erase(erased_by: admin_user)`.

   `1.week.ago` is a Rails `ActiveSupport::Duration` method which calculates a new
   date or time in the past. Other valid examples are:

   - `7.days.ago`
   - `3.months.ago`
   - `1.year.ago`

### Job artifact upload fails with error 500

If you are using object storage for artifacts and a job artifact fails to upload,
review:

- The job log for an error message similar to:

  ```plaintext
  WARNING: Uploading artifacts as "archive" to coordinator... failed id=12345 responseStatus=500 Internal Server Error status=500 token=abcd1234
  ```

- The [workhorse log](logs/index.md#workhorse-logs) for an error message similar to:

  ```json
  {"error":"MissingRegion: could not find region configuration","level":"error","msg":"error uploading S3 session","time":"2021-03-16T22:10:55-04:00"}
  ```

In both cases, you might need to add `region` to the job artifact [object storage configuration](object_storage.md).

### Job artifact upload fails with `500 Internal Server Error (Missing file)`

Bucket names that include folder paths are not supported with [consolidated object storage](object_storage.md#configure-a-single-storage-connection-for-all-object-types-consolidated-form).
For example, `bucket/path`. If a bucket name has a path in it, you might receive an error similar to:

```plaintext
WARNING: Uploading artifacts as "archive" to coordinator... POST https://gitlab.example.com/api/v4/jobs/job_id/artifacts?artifact_format=zip&artifact_type=archive&expire_in=1+day: 500 Internal Server Error (Missing file)
FATAL: invalid argument
```

If a job artifact fails to upload with the above error when using consolidated object storage, make sure you are [using separate buckets](object_storage.md#use-separate-buckets) for each data type.

### Job artifacts fail to upload with `FATAL: invalid argument` when using Windows mount

If you are using a Windows mount with CIFS for job artifacts, you may see an
`invalid argument` error when the runner attempts to upload artifacts:

```plaintext
WARNING: Uploading artifacts as "dotenv" to coordinator... POST https://<your-gitlab-instance>/api/v4/jobs/<JOB_ID>/artifacts: 500 Internal Server Error  id=1296 responseStatus=500 Internal Server Error status=500 token=*****
FATAL: invalid argument
```

To work around this issue, you can try:

- Switching to an ext4 mount instead of CIFS.
- Upgrading to at least Linux kernel 5.15 which contains a number of important bug fixes
  relating to CIFS file leases.
- For older kernels, using the `nolease` mount option to disable file leasing.

For more information, [see the investigation details](https://gitlab.com/gitlab-org/gitlab/-/issues/389995).

### Usage quota shows incorrect artifact storage usage

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/238536) in GitLab 14.10.

Sometimes the [artifacts storage usage](../user/usage_quotas.md) displays an incorrect
value for the total storage space used by artifacts. To recalculate the artifact
usage statistics for all projects in the instance, you can run this background script:

```shell
bin/rake 'gitlab:refresh_project_statistics_build_artifacts_size[file.csv]'
```

The artifact usage value can fluctuate to `0` while the script is running. After
recalculation, usage should display as expected again.
