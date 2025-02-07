---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Jobs artifacts administration
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

This is the administration documentation. To learn how to use job artifacts in your GitLab CI/CD pipeline,
see the [job artifacts configuration documentation](../../ci/jobs/job_artifacts.md).

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
[`artifacts:when`](../../ci/yaml/_index.md#artifactswhen) parameter.

Most artifacts are compressed by GitLab Runner before being sent to the coordinator. The exception to this is
[reports artifacts](../../ci/yaml/_index.md#artifactsreports), which are compressed after uploading.

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

You should use the [consolidated object storage settings](../object_storage.md#configure-a-single-storage-connection-for-all-object-types-consolidated-form).

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

1. If [Geo](../geo/_index.md) is enabled, [reverify all job artifacts](../geo/replication/troubleshooting/synchronization_verification.md#reverify-all-components-or-any-ssf-data-type-which-supports-verification).

In some cases, you need to run the [orphan artifact file cleanup Rake task](../../raketasks/cleanup.md#remove-orphan-artifact-files)
to clean up orphaned artifacts.

### Migrating from object storage to local storage

To migrate artifacts back to local storage:

1. Run `gitlab-rake gitlab:artifacts:migrate_to_local`.
1. [Selectively disable the artifacts' storage](../object_storage.md#disable-object-storage-for-specific-features) in `gitlab.rb`.
1. [Reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation).

## Expiring artifacts

If [`artifacts:expire_in`](../../ci/yaml/_index.md#artifactsexpire_in) is used to set
an expiry for the artifacts, they are marked for deletion right after that date passes.
Otherwise, they expire per the [default artifacts expiration setting](../settings/continuous_integration.md#default-artifacts-expiration).

Artifacts are deleted by the `expire_build_artifacts_worker` cron job which Sidekiq
runs every 7 minutes (`*/7 * * * *` in [Cron](../../topics/cron/_index.md) syntax).

To change the default schedule on which expired artifacts are deleted:

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
artifacts through the [**Admin** area settings](../settings/continuous_integration.md#maximum-artifacts-size).

## Storage statistics

You can see the total storage used for job artifacts for groups and projects in:

- The **Admin** area
- The [groups](../../api/groups.md) and [projects](../../api/projects.md) APIs

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
