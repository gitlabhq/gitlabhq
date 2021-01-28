---
stage: Enablement
group: Memory
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Changing application settings cache expiry interval **(FREE SELF)**

Application settings are cached for 60 seconds by default which should work
for most installations. A higher value would mean a greater delay between
changing an application setting and noticing that change come into effect.
A value of `0` would result in the `application_settings` table being
loaded for every request causing extra load on Redis and/or PostgreSQL.
It is therefore recommended to keep the value above zero.

## Change the application settings cache expiry

To change the expiry value:

**For Omnibus installations**

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['application_settings_cache_seconds'] = 60
   ```

1. Save the file, and reconfigure and restart GitLab for the changes to take effect:

   ```shell
   gitlab-ctl reconfigure
   gitlab-ctl restart
   ```

---

**For installations from source**

1. Edit `config/gitlab.yml`:

   ```yaml
   gitlab:
     application_settings_cache_seconds: 60
   ```

1. Save the file and [restart](restart_gitlab.md#installations-from-source)
   GitLab for the changes to take effect.
