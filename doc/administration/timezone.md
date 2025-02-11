---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Change your time zone
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

NOTE:
Users can set their [time zone in their profile](../user/profile/_index.md#set-your-time-zone).
New users do not have a default time zone and must
explicitly set it before it displays on their profile.
On GitLab.com, the default time zone is UTC.

The default time zone in GitLab is UTC, but you can change it to your liking.

To update the time zone of your GitLab instance:

1. The specified time zone must be in
   [tz format](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones).
   You can use the `timedatectl` command to see the available time zones:

   ```shell
   timedatectl list-timezones
   ```

1. Change the time zone, for example to `America/New_York`.

::Tabs

:::TabTitle Linux package (Omnibus)

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['time_zone'] = 'America/New_York'
   ```

1. Save the file, then reconfigure and restart GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   sudo gitlab-ctl restart
   ```

:::TabTitle Helm chart (Kubernetes)

1. Export the Helm values:

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. Edit `gitlab_values.yaml`:

   ```yaml
   global:
     time_zone: 'America/New_York'
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
           gitlab_rails['time_zone'] = 'America/New_York'
   ```

1. Save the file and restart GitLab:

   ```shell
   docker compose up -d
   ```

:::TabTitle Self-compiled (source)

1. Edit `/home/git/gitlab/config/gitlab.yml`:

   ```yaml
   production: &base
     gitlab:
       time_zone: 'America/New_York'
   ```

1. Save the file and restart GitLab:

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

::EndTabs
