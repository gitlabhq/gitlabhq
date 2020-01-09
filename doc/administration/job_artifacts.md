# Jobs artifacts administration

> - Introduced in GitLab 8.2 and GitLab Runner 0.7.0.
> - Starting with GitLab 8.4 and GitLab Runner 1.0, the artifacts archive format changed to `ZIP`.
> - Starting with GitLab 8.17, builds are renamed to jobs.
> - This is the administration documentation. For the user guide see [pipelines/job_artifacts](../user/project/pipelines/job_artifacts.md).

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

1. Save the file and [reconfigure GitLab][] for the changes to take effect.

**In installations from source:**

1. Edit `/home/git/gitlab/config/gitlab.yml` and add or amend the following lines:

   ```yaml
   artifacts:
     enabled: false
   ```

1. Save the file and [restart GitLab][] for the changes to take effect.

## Storing job artifacts

GitLab Runner can upload an archive containing the job artifacts to GitLab. By default,
this is done when the job succeeds, but can also be done on failure, or always, via the
[`artifacts:when`](../ci/yaml/README.md#artifactswhen) parameter.

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

1. Save the file and [reconfigure GitLab][] for the changes to take effect.

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

1. Save the file and [restart GitLab][] for the changes to take effect.

### Using object storage

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/merge_requests/1762) in
>   [GitLab Premium](https://about.gitlab.com/pricing/) 9.4.
> - Since version 9.5, artifacts are [browsable](../user/project/pipelines/job_artifacts.md#browsing-artifacts),
>   when object storage is enabled. 9.4 lacks this feature.
> - Since version 10.6, available in [GitLab Core](https://about.gitlab.com/pricing/)
> - Since version 11.0, we support `direct_upload` to S3.

If you don't want to use the local disk where GitLab is installed to store the
artifacts, you can use an object storage like AWS S3 instead.
This configuration relies on valid AWS credentials to be configured already.
Use an object storage option like AWS S3 to store job artifacts.

DANGER: **Danger:**
If you're enabling S3 in [GitLab HA](high_availability/README.md), you will need to have an [NFS mount set up for CI logs and artifacts](high_availability/nfs.md#a-single-nfs-mount) or enable [incremental logging](job_logs.md#new-incremental-logging-architecture). If these settings are not set, you will risk job logs disappearing or not being saved.

#### Object Storage Settings

For source installations the following settings are nested under `artifacts:` and then `object_store:`. On Omnibus GitLab installs they are prefixed by `artifacts_object_store_`.

| Setting | Description | Default |
|---------|-------------|---------|
| `enabled` | Enable/disable object storage | `false` |
| `remote_directory` | The bucket name where Artifacts will be stored| |
| `direct_upload` | Set to true to enable direct upload of Artifacts without the need of local shared storage. Option may be removed once we decide to support only single storage for all files. | `false` |
| `background_upload` | Set to false to disable automatic upload. Option may be removed once upload is direct to S3 | `true` |
| `proxy_download` | Set to true to enable proxying all files served. Option allows to reduce egress traffic as this allows clients to download directly from remote storage instead of proxying all data | `false` |
| `connection` | Various connection options described below | |

##### S3 compatible connection settings

The connection settings match those provided by [Fog](https://github.com/fog), and are as follows:

| Setting | Description | Default |
|---------|-------------|---------|
| `provider` | Always `AWS` for compatible hosts | AWS |
| `aws_access_key_id` | AWS credentials, or compatible | |
| `aws_secret_access_key` | AWS credentials, or compatible | |
| `aws_signature_version` | AWS signature version to use. 2 or 4 are valid options. Digital Ocean Spaces and other providers may need 2. | 4 |
| `enable_signature_v4_streaming` | Set to true to enable HTTP chunked transfers with [AWS v4 signatures](https://docs.aws.amazon.com/AmazonS3/latest/API/sigv4-streaming.html). Oracle Cloud S3 needs this to be false | true |
| `region` | AWS region | us-east-1 |
| `host` | S3 compatible host for when not using AWS, e.g. `localhost` or `storage.example.com` | s3.amazonaws.com |
| `endpoint` | Can be used when configuring an S3 compatible service such as [MinIO](https://min.io), by entering a URL such as `http://127.0.0.1:9000` | (optional) |
| `path_style` | Set to true to use `host/bucket_name/object` style paths instead of `bucket_name.host/object`. Leave as false for AWS S3 | false |
| `use_iam_profile` | Set to true to use IAM profile instead of access keys | false

**In Omnibus installations:**

_The artifacts are stored by default in
`/var/opt/gitlab/gitlab-rails/shared/artifacts`._

1. Edit `/etc/gitlab/gitlab.rb` and add the following lines by replacing with
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

   NOTE: For GitLab 9.4+, if you are using AWS IAM profiles, be sure to omit the
   AWS access key and secret access key/value pairs. For example:

   ```ruby
   gitlab_rails['artifacts_object_store_connection'] = {
     'provider' => 'AWS',
     'region' => 'eu-central-1',
     'use_iam_profile' => true
   }
   ```

1. Save the file and [reconfigure GitLab][] for the changes to take effect.
1. Migrate any existing local artifacts to the object storage:

   ```bash
   gitlab-rake gitlab:artifacts:migrate
   ```

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
       remote_directory: "artifacts" # The bucket name
       connection:
         provider: AWS # Only AWS supported at the moment
         aws_access_key_id: AWS_ACCESS_KEY_ID
         aws_secret_access_key: AWS_SECRET_ACCESS_KEY
         region: eu-central-1
   ```

1. Save the file and [restart GitLab][] for the changes to take effect.
1. Migrate any existing local artifacts to the object storage:

   ```bash
   sudo -u git -H bundle exec rake gitlab:artifacts:migrate RAILS_ENV=production
   ```

### Migrating from object storage to local storage

In order to migrate back to local storage:

1. Set both `direct_upload` and `background_upload` to false under the artifacts object storage settings. Don't forget to restart GitLab.
1. Run `rake gitlab:artifacts:migrate_to_local` on your console.
1. Disable `object_storage` for artifacts in `gitlab.rb`. Remember to restart GitLab afterwards.

## Expiring artifacts

If an expiry date is used for the artifacts, they are marked for deletion
right after that date passes. Artifacts are cleaned up by the
`expire_build_artifacts_worker` cron job which is run by Sidekiq every hour at
50 minutes (`50 * * * *`).

To change the default schedule on which the artifacts are expired, follow the
steps below.

**In Omnibus installations:**

1. Edit `/etc/gitlab/gitlab.rb` and comment out or add the following line

   ```ruby
   gitlab_rails['expire_build_artifacts_worker_cron'] = "50 * * * *"
   ```

1. Save the file and [reconfigure GitLab][] for the changes to take effect.

**In installations from source:**

1. Edit `/home/git/gitlab/config/gitlab.yml` and add or amend the following
   lines:

   ```yaml
   expire_build_artifacts_worker:
     cron: "50 * * * *"
   ```

1. Save the file and [restart GitLab][] for the changes to take effect.

## Validation for dependencies

> Introduced in GitLab 10.3.

To disable [the dependencies validation](../ci/yaml/README.md#when-a-dependent-job-will-fail),
you can flip the feature flag from a Rails console.

**In Omnibus installations:**

1. Enter the Rails console:

   ```sh
   sudo gitlab-rails console
   ```

1. Flip the switch and disable it:

   ```ruby
   Feature.enable('ci_disable_validates_dependencies')
   ```

**In installations from source:**

1. Enter the Rails console:

   ```sh
   cd /home/git/gitlab
   RAILS_ENV=production sudo -u git -H bundle exec rails console
   ```

1. Flip the switch and disable it:

   ```ruby
   Feature.enable('ci_disable_validates_dependencies')
   ```

## Set the maximum file size of the artifacts

Provided the artifacts are enabled, you can change the maximum file size of the
artifacts through the [Admin Area settings](../user/admin_area/settings/continuous_integration.md#maximum-artifacts-size-core-only).

## Storage statistics

You can see the total storage used for job artifacts on groups and projects
in the administration area, as well as through the [groups](../api/groups.md)
and [projects APIs](../api/projects.md).

## Implementation details

When GitLab receives an artifacts archive, an archive metadata file is also
generated by [GitLab Workhorse]. This metadata file describes all the entries
that are located in the artifacts archive itself.
The metadata file is in a binary format, with additional GZIP compression.

GitLab does not extract the artifacts archive in order to save space, memory
and disk I/O. It instead inspects the metadata file which contains all the
relevant information. This is especially important when there is a lot of
artifacts, or an archive is a very large file.

When clicking on a specific file, [GitLab Workhorse] extracts it
from the archive and the download begins. This implementation saves space,
memory and disk I/O.

[reconfigure gitlab]: restart_gitlab.md#omnibus-gitlab-reconfigure "How to reconfigure Omnibus GitLab"
[restart gitlab]: restart_gitlab.md#installations-from-source "How to restart GitLab"
[gitlab workhorse]: https://gitlab.com/gitlab-org/gitlab-workhorse "GitLab Workhorse repository"

## Troubleshooting

### Job artifacts using too much disk space

Job artifacts can fill up your disk space quicker than expected. Some possible
reasons are:

- Users have configured job artifacts expiration to be longer than necessary.
- The number of jobs run, and hence artifacts generated, is higher than expected.
- Job logs are larger than expected, and have accumulated over time.

In these and other cases, you'll need to identify the projects most responsible
for disk space usage, figure out what types of artifacts are using the most
space, and in some cases, manually delete job artifacts to reclaim disk space.

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

CAUTION: **CAUTION:**
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
   builds_with_artifacts =  project.builds.with_artifacts_archive
   ```

   To select all jobs with artifacts across the entire GitLab instance:

   ```ruby
   builds_with_artifacts = Ci::Build.with_artifacts_archive
   ```

1. Delete job artifacts older than a specific date:

   NOTE: **NOTE:**
   This step will also erase artifacts that users have chosen to
   ["keep"](../user/project/pipelines/job_artifacts.html#browsing-artifacts).

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

#### Delete job artifacts and logs from jobs completed before a specific date

CAUTION: **CAUTION:**
These commands remove data permanently from the database and from disk. We
highly recommend running them only under the guidance of a Support Engineer, or
running them in a test environment with a backup of the instance ready to be
restored, just in case.

If you need to manually remove ALL job artifacts associated with multiple jobs,
**including job logs**, this can be done from the Rails console (`sudo gitlab-rails console`):

1. Select jobs to be deleted:

   To select jobs with artifacts for a single project:

   ```ruby
   project = Project.find_by_full_path('path/to/project')
   builds_with_artifacts =  project.builds.with_existing_job_artifacts
   ```

   To select jobs with artifacts across the entire GitLab instance:

   ```ruby
   builds_with_artifacts = Ci::Build.with_existing_job_artifacts
   ```

1. Select the user which will be mentioned in the web UI as erasing the job:

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
