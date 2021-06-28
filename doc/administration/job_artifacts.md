---
stage: Verify
group: Testing
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference, howto
---

# Jobs artifacts administration **(FREE SELF)**

This is the administration documentation. For the user guide see [pipelines/job_artifacts](../ci/pipelines/job_artifacts.md).

Artifacts is a list of files and directories which are attached to a job after it
finishes. This feature is enabled by default in all GitLab installations. Keep reading
if you want to know how to disable it.

## Disabling job artifacts

To disable artifacts site-wide, follow the steps below.

**In Omnibus installations:**

1. Edit `/etc/gitlab/gitlab.rb` and add the following line:

   ```ruby
   gitlab_rails['artifacts_enabled'] = false
   ```

1. Save the file and [reconfigure GitLab](restart_gitlab.md#omnibus-gitlab-reconfigure) for the changes to take effect.

**In installations from source:**

1. Edit `/home/git/gitlab/config/gitlab.yml` and add or amend the following lines:

   ```yaml
   artifacts:
     enabled: false
   ```

1. Save the file and [restart GitLab](restart_gitlab.md#installations-from-source) for the changes to take effect.

## Storing job artifacts

GitLab Runner can upload an archive containing the job artifacts to GitLab. By default,
this is done when the job succeeds, but can also be done on failure, or always, via the
[`artifacts:when`](../ci/yaml/index.md#artifactswhen) parameter.

Most artifacts are compressed by GitLab Runner before being sent to the coordinator. The exception to this is
[reports artifacts](../ci/yaml/index.md#artifactsreports), which are compressed after uploading.

### Using local storage

To change the location where the artifacts are stored locally, follow the steps
below.

**In Omnibus installations:**

_The artifacts are stored by default in
`/var/opt/gitlab/gitlab-rails/shared/artifacts`._

1. To change the storage path for example to `/mnt/storage/artifacts`, edit
   `/etc/gitlab/gitlab.rb` and add the following line:

   ```ruby
   gitlab_rails['artifacts_path'] = "/mnt/storage/artifacts"
   ```

1. Save the file and [reconfigure GitLab](restart_gitlab.md#omnibus-gitlab-reconfigure) for the changes to take effect.

**In installations from source:**

_The artifacts are stored by default in
`/home/git/gitlab/shared/artifacts`._

1. To change the storage path for example to `/mnt/storage/artifacts`, edit
   `/home/git/gitlab/config/gitlab.yml` and add or amend the following lines:

   ```yaml
   artifacts:
     enabled: true
     path: /mnt/storage/artifacts
   ```

1. Save the file and [restart GitLab](restart_gitlab.md#installations-from-source) for the changes to take effect.

### Using object storage

> Introduced in GitLab 11.0: Support for `direct_upload` to S3.

If you don't want to use the local disk where GitLab is installed to store the
artifacts, you can use an object storage like AWS S3 instead.
This configuration relies on valid AWS credentials to be configured already.
Use an object storage option like AWS S3 to store job artifacts.

If you configure GitLab to store artifacts on object storage, you may also want to
[eliminate local disk usage for job logs](job_logs.md#prevent-local-disk-usage).
In both cases, job logs are archived and moved to object storage when the job completes.

WARNING:
In a multi-server setup you must use one of the options to
[eliminate local disk usage for job logs](job_logs.md#prevent-local-disk-usage), or job logs could be lost.

[Read more about using object storage with GitLab](object_storage.md).

#### Object Storage Settings

NOTE:
In GitLab 13.2 and later, we recommend using the
[consolidated object storage settings](object_storage.md#consolidated-object-storage-configuration).
This section describes the earlier configuration format.

For source installations the following settings are nested under `artifacts:` and then `object_store:`. On Omnibus GitLab installs they are prefixed by `artifacts_object_store_`.

| Setting             | Default | Description |
|---------------------|---------|-------------|
| `enabled`           | `false` | Enable or disable object storage. |
| `remote_directory`  |         | The bucket name where Artifacts are stored. Use the name only, do not include the path. |
| `direct_upload`     | `false` | Set to `true` to enable direct upload of Artifacts without the need of local shared storage. Option may be removed once we decide to support only single storage for all files. |
| `background_upload` | `true`  | Set to `false` to disable automatic upload. Option may be removed once upload is direct to S3. |
| `proxy_download`    | `false` | Set to `true` to enable proxying all files served. Option allows to reduce egress traffic as this allows clients to download directly from remote storage instead of proxying all data. |
| `connection`        |         | Various connection options described below. |

#### Connection settings

See [the available connection settings for different providers](object_storage.md#connection-settings).

**In Omnibus installations:**

_The artifacts are stored by default in
`/var/opt/gitlab/gitlab-rails/shared/artifacts`._

1. Edit `/etc/gitlab/gitlab.rb` and add the following lines, substituting
   the values you want:

   ```ruby
   gitlab_rails['artifacts_enabled'] = true
   gitlab_rails['artifacts_object_store_enabled'] = true
   gitlab_rails['artifacts_object_store_remote_directory'] = "artifacts"
   gitlab_rails['artifacts_object_store_connection'] = {
     'provider' => 'AWS',
     'region' => 'eu-central-1',
     'aws_access_key_id' => 'AWS_ACCESS_KEY_ID',
     'aws_secret_access_key' => 'AWS_SECRET_ACCESS_KEY'
   }
   ```

   NOTE: For GitLab 9.4+, if you're using AWS IAM profiles, be sure to omit the
   AWS access key and secret access key/value pairs. For example:

   ```ruby
   gitlab_rails['artifacts_object_store_connection'] = {
     'provider' => 'AWS',
     'region' => 'eu-central-1',
     'use_iam_profile' => true
   }
   ```

1. Save the file and [reconfigure GitLab](restart_gitlab.md#omnibus-gitlab-reconfigure) for the changes to take effect.
1. Migrate any existing local artifacts to the object storage:

   ```shell
   gitlab-rake gitlab:artifacts:migrate
   ```

1. Optional: Verify all files migrated properly.
   From [PostgreSQL console](https://docs.gitlab.com/omnibus/settings/database.html#connecting-to-the-bundled-postgresql-database)
   (`sudo gitlab-psql -d gitlabhq_production`) verify `objectstg` below (where `file_store=2`) has count of all artifacts:

   ```shell
   gitlabhq_production=# SELECT count(*) AS total, sum(case when file_store = '1' then 1 else 0 end) AS filesystem, sum(case when file_store = '2' then 1 else 0 end) AS objectstg FROM ci_job_artifacts;

   total | filesystem | objectstg
   ------+------------+-----------
    2409 |          0 |      2409
   ```

   Verify no files on disk in `artifacts` folder:

   ```shell
   sudo find /var/opt/gitlab/gitlab-rails/shared/artifacts -type f | grep -v tmp/cache | wc -l
   ```

   In some cases, you may need to run the [orphan artifact file cleanup Rake task](../raketasks/cleanup.md#remove-orphan-artifact-files)
   to clean up orphaned artifacts.

WARNING:
JUnit test report artifact (`junit.xml.gz`) migration
[was not supported until GitLab 12.8](https://gitlab.com/gitlab-org/gitlab/-/issues/27698#note_317190991)
by the `gitlab:artifacts:migrate` script.

**In installations from source:**

_The artifacts are stored by default in
`/home/git/gitlab/shared/artifacts`._

1. Edit `/home/git/gitlab/config/gitlab.yml` and add or amend the following
   lines:

   ```yaml
   artifacts:
     enabled: true
     object_store:
       enabled: true
       remote_directory: "artifacts"  # The bucket name
       connection:
         provider: AWS  # Only AWS supported at the moment
         aws_access_key_id: AWS_ACCESS_KEY_ID
         aws_secret_access_key: AWS_SECRET_ACCESS_KEY
         region: eu-central-1
   ```

1. Save the file and [restart GitLab](restart_gitlab.md#installations-from-source) for the changes to take effect.
1. Migrate any existing local artifacts to the object storage:

   ```shell
   sudo -u git -H bundle exec rake gitlab:artifacts:migrate RAILS_ENV=production
   ```

1. Optional: Verify all files migrated properly.
   From PostgreSQL console (`sudo -u git -H psql -d gitlabhq_production`) verify `objectstg` below (where `file_store=2`) has count of all artifacts:

   ```shell
   gitlabhq_production=# SELECT count(*) AS total, sum(case when file_store = '1' then 1 else 0 end) AS filesystem, sum(case when file_store = '2' then 1 else 0 end) AS objectstg FROM ci_job_artifacts;

   total | filesystem | objectstg
   ------+------------+-----------
    2409 |          0 |      2409
   ```

   Verify no files on disk in `artifacts` folder:

   ```shell
   sudo find /var/opt/gitlab/gitlab-rails/shared/artifacts -type f | grep -v tmp/cache | wc -l
   ```

   In some cases, you may need to run the [orphan artifact file cleanup Rake task](../raketasks/cleanup.md#remove-orphan-artifact-files)
   to clean up orphaned artifacts.

WARNING:
JUnit test report artifact (`junit.xml.gz`) migration
[was not supported until GitLab 12.8](https://gitlab.com/gitlab-org/gitlab/-/issues/27698#note_317190991)
by the `gitlab:artifacts:migrate` script.

### OpenStack example

See [the available connection settings for OpenStack](object_storage.md#openstack-compatible-connection-settings).

**In Omnibus installations:**

_The uploads are stored by default in
`/var/opt/gitlab/gitlab-rails/shared/artifacts`._

1. Edit `/etc/gitlab/gitlab.rb` and add the following lines, substituting
   the values you want:

   ```ruby
   gitlab_rails['artifacts_enabled'] = true
   gitlab_rails['artifacts_object_store_enabled'] = true
   gitlab_rails['artifacts_object_store_remote_directory'] = "artifacts"
   gitlab_rails['artifacts_object_store_connection'] = {
    'provider' => 'OpenStack',
    'openstack_username' => 'OS_USERNAME',
    'openstack_api_key' => 'OS_PASSWORD',
    'openstack_temp_url_key' => 'OS_TEMP_URL_KEY',
    'openstack_auth_url' => 'https://auth.cloud.ovh.net',
    'openstack_region' => 'GRA',
    'openstack_tenant_id' => 'OS_TENANT_ID',
   }
   ```

1. Save the file and [reconfigure GitLab](restart_gitlab.md#omnibus-gitlab-reconfigure) for the changes to take effect.
1. Migrate any existing local artifacts to the object storage:

   ```shell
   gitlab-rake gitlab:artifacts:migrate
   ```

---

**In installations from source:**

_The uploads are stored by default in
`/home/git/gitlab/shared/artifacts`._

1. Edit `/home/git/gitlab/config/gitlab.yml` and add or amend the following
   lines:

   ```yaml
   uploads:
     object_store:
       enabled: true
       direct_upload: false
       background_upload: true
       proxy_download: false
       remote_directory: "artifacts"
       connection:
         provider: OpenStack
         openstack_username: OS_USERNAME
         openstack_api_key: OS_PASSWORD
         openstack_temp_url_key: OS_TEMP_URL_KEY
         openstack_auth_url: 'https://auth.cloud.ovh.net'
         openstack_region: GRA
         openstack_tenant_id: OS_TENANT_ID
   ```

1. Save the file and [restart GitLab](restart_gitlab.md#installations-from-source) for the changes to take effect.
1. Migrate any existing local artifacts to the object storage:

   ```shell
   sudo -u git -H bundle exec rake gitlab:artifacts:migrate RAILS_ENV=production
   ```

### Migrating from object storage to local storage

**In Omnibus installations:**

To migrate back to local storage:

1. Set both `direct_upload` and `background_upload` to `false` in `gitlab.rb`, under the artifacts object storage settings.
1. [Reconfigure GitLab](restart_gitlab.md#omnibus-gitlab-reconfigure).
1. Run `gitlab-rake gitlab:artifacts:migrate_to_local`.
1. Disable object_storage for artifacts in `gitlab.rb`:
   - Set `gitlab_rails['artifacts_object_store_enabled'] = false`.
   - Comment out all other `artifacts_object_store` settings, including the entire
     `artifacts_object_store_connection` section, including the closing `}`.
1. [Reconfigure GitLab](restart_gitlab.md#omnibus-gitlab-reconfigure).

## Expiring artifacts

If [`artifacts:expire_in`](../ci/yaml/index.md#artifactsexpire_in) is used to set
an expiry for the artifacts, they are marked for deletion right after that date passes.
Otherwise, they expire per the [default artifacts expiration setting](../user/admin_area/settings/continuous_integration.md).

Artifacts are cleaned up by the `expire_build_artifacts_worker` cron job which Sidekiq
runs every 7 minutes (`*/7 * * * *`).

To change the default schedule on which the artifacts are expired, follow the
steps below.

**In Omnibus installations:**

1. Edit `/etc/gitlab/gitlab.rb` and add the following line (or uncomment it if it already exists and is commented out), substituting
   your schedule in cron syntax:

   ```ruby
   gitlab_rails['expire_build_artifacts_worker_cron'] = "*/7 * * * *"
   ```

1. Save the file and [reconfigure GitLab](restart_gitlab.md#omnibus-gitlab-reconfigure) for the changes to take effect.

**In installations from source:**

1. Edit `/home/git/gitlab/config/gitlab.yml` and add or amend the following
   lines:

   ```yaml
   expire_build_artifacts_worker:
     cron: "*/7 * * * *"
   ```

1. Save the file and [restart GitLab](restart_gitlab.md#installations-from-source) for the changes to take effect.

If the `expire` directive is not set explicitly in your pipeline, artifacts expire per the
default artifacts expiration setting, which you can find in the [CI/CD Administration settings](../user/admin_area/settings/continuous_integration.md).

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

When clicking on a specific file, [GitLab Workhorse](https://gitlab.com/gitlab-org/gitlab-workhorse) extracts it
from the archive and the download begins. This implementation saves space,
memory and disk I/O.

## Troubleshooting

### Job artifacts using too much disk space

Job artifacts can fill up your disk space quicker than expected. Some possible
reasons are:

- Users have configured job artifacts expiration to be longer than necessary.
- The number of jobs run, and hence artifacts generated, is higher than expected.
- Job logs are larger than expected, and have accumulated over time.

In these and other cases, identify the projects most responsible
for disk space usage, figure out what types of artifacts are using the most
space, and in some cases, manually delete job artifacts to reclaim disk space.

One possible first step is to [clean up _orphaned_ artifact files](../raketasks/cleanup.md#remove-orphan-artifact-files).

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

#### Delete job artifacts from jobs completed before a specific date

WARNING:
These commands remove data permanently from the database and from disk. We
highly recommend running them only under the guidance of a Support Engineer, or
running them in a test environment with a backup of the instance ready to be
restored, just in case.

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
   ["keep"](../ci/pipelines/job_artifacts.md#download-job-artifacts).

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

   `erase_erasable_artifacts!` is a synchronous method, and upon execution, the artifacts are removed immediately.
   They are not scheduled via some background queue.

#### Delete job artifacts and logs from jobs completed before a specific date

WARNING:
These commands remove data permanently from the database and from disk. We
highly recommend running them only under the guidance of a Support Engineer, or
running them in a test environment with a backup of the instance ready to be
restored, just in case.

If you need to manually remove **all** job artifacts associated with multiple jobs,
**including job logs**, this can be done from the Rails console (`sudo gitlab-rails console`):

1. Select jobs to be deleted:

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

1. Erase job artifacts and logs older than a specific date:

   ```ruby
   builds_to_clear = builds_with_artifacts.where("finished_at < ?", 1.week.ago)
   builds_to_clear.find_each do |build|
     print "Ci::Build ID #{build.id}... "

     if build.erasable?
       build.erase(erased_by: admin_user)
       puts "Erased"
     else
       puts "Skipped (Nothing to erase or not erasable)"
     end
   end
   ```

   `1.week.ago` is a Rails `ActiveSupport::Duration` method which calculates a new
   date or time in the past. Other valid examples are:

   - `7.days.ago`
   - `3.months.ago`
   - `1.year.ago`

### Error `Downloading artifacts from coordinator... not found`

When a job tries to download artifacts from an earlier job, you might receive an error similar to:

```plaintext
Downloading artifacts from coordinator... not found  id=12345678 responseStatus=404 Not Found
```

This might be caused by a `gitlab.rb` file with the following configuration:

```ruby
gitlab_rails['artifacts_object_store_background_upload'] = false
gitlab_rails['artifacts_object_store_direct_upload'] = true
```

To prevent this, comment out or remove those lines, or switch to their [default values](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-config-template/gitlab.rb.template),
then run `sudo gitlab-ctl reconfigure`.

### Job artifact upload fails with error 500

If you are using object storage for artifacts and a job artifact fails to upload,
you can check:

- The job log for an error similar to:

  ```plaintext
  WARNING: Uploading artifacts as "archive" to coordinator... failed id=12345 responseStatus=500 Internal Server Error status=500 token=abcd1234
  ```

- The [workhorse log](logs.md#workhorse-logs) for an error similar to:

  ```json
  {"error":"MissingRegion: could not find region configuration","level":"error","msg":"error uploading S3 session","time":"2021-03-16T22:10:55-04:00"}
  ```

In both cases, you might need to add `region` to the job artifact [object storage configuration](#connection-settings).
