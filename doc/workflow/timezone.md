# Changing your time zone

The global time zone configuration parameter can be changed in `config/gitlab.yml`:

```text
# time_zone: 'UTC'
```

Uncomment and customize if you want to change the default time zone of the GitLab application.

## Viewing available timezones

To see all available time zones, run `bundle exec rake time:zones:all`.

For Omnibus installations, run `gitlab-rake time:zones:all`.

NOTE: **Note:**
Currently, this rake task does not list timezones in TZInfo format required by GitLab Omnibus during a reconfigure: [#58672](https://gitlab.com/gitlab-org/gitlab-ce/issues/58672).

## Changing time zone in Omnibus installations

GitLab defaults its time zone to UTC. It has a global timezone configuration parameter in `/etc/gitlab/gitlab.rb`.

To obtain a list of timezones, log in to your GitLab application server and run a command that generates a list of timezones in TZInfo format for the server. For example, install `timedatectl` and run `timedatectl list-timezones`.

To update, add the timezone that best applies to your location. For example:

```ruby
gitlab_rails['time_zone'] = 'America/New_York'
```

After adding the configuration parameter, reconfigure and restart your GitLab instance:

```sh
gitlab-ctl reconfigure
gitlab-ctl restart
```
