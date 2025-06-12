---
stage: None
group: Unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Application cache interval
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

By default, GitLab caches application settings for 60 seconds. Occasionally,
you may need to increase that interval to have more delay between application
setting changes and when users notice those changes in the application.

We recommend you set this value to greater than `0` seconds. Setting it to `0`
causes the `application_settings` table to load for every request. This causes
extra load for Redis and PostgreSQL.

## Change the expiration interval for application cache

To change the expiry value:

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['application_settings_cache_seconds'] = 60
   ```

1. Save the file, and then reconfigure and restart GitLab for the changes to
   take effect:

   ```shell
   gitlab-ctl reconfigure
   gitlab-ctl restart
   ```

{{< /tab >}}

{{< tab title="Self-compiled (Source)" >}}

1. Edit `config/gitlab.yml`:

   ```yaml
   gitlab:
     application_settings_cache_seconds: 60
   ```

1. Save the file, and then [restart](restart_gitlab.md#self-compiled-installations)
   GitLab for the changes to take effect.

{{< /tab >}}

{{< /tabs >}}
