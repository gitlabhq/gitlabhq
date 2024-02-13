---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Changing your time zone

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** Self-managed

The global time zone configuration parameter can be changed in `config/gitlab.yml`:

```plaintext
# time_zone: 'UTC'
```

Uncomment and customize if you want to change the default time zone of the GitLab application.

## Viewing available time zones

To see all available time zones, run `bundle exec rake time:zones:all`.

For Linux package installations, run `gitlab-rake time:zones:all`.

NOTE:
This Rake task does not list time zones in TZInfo format required by a Linux package installation during a reconfigure. For more information,
see [issue 27209](https://gitlab.com/gitlab-org/gitlab/-/issues/27209).

## Changing time zone in Linux package installations

GitLab defaults its time zone to UTC. It has a global time zone configuration parameter in `/etc/gitlab/gitlab.rb`.

To obtain a list of time zones, sign in to your GitLab application server and run a command that generates a list of time zones in TZInfo format for the server. For example, install `timedatectl` and run `timedatectl list-timezones`.

To update, add the time zone that best applies to your location. For example:

```ruby
gitlab_rails['time_zone'] = 'America/New_York'
```

After adding the configuration parameter, reconfigure and restart your GitLab instance:

```shell
gitlab-ctl reconfigure
gitlab-ctl restart
```

## Changing time zone per user

> - [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/57654) in GitLab 11.11, disabled by default behind `user_time_settings` [feature flag](feature_flags.md).
> - [Enabled by default](https://gitlab.com/gitlab-org/gitlab/-/issues/29669) in GitLab 13.9.
> - [Feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/issues/29669) in GitLab 14.1.

Users can set their time zone in their profile. On GitLab.com, the default time zone is UTC.

New users do not have a default time zone in [GitLab 14.4 and later](https://gitlab.com/gitlab-org/gitlab/-/issues/340795). New users must
explicitly set their time zone before it displays on their profile.

In GitLab 14.3 and earlier, users with no configured time zone default to the time zone
[configured at the instance level](#changing-your-time-zone).

For more information, see [Set your time zone](../user/profile/index.md#set-your-time-zone).
