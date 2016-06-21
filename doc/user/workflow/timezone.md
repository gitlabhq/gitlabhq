# Changing your time zone

The global time zone configuration parameter can be changed in `config/gitlab.yml`:
```
    # time_zone: 'UTC'
```

Uncomment and customize if you want to change the default time zone of GitLab application.

To see all available time zones, run `bundle exec rake time:zones:all`.


## Changing time zone in omnibus installations

GitLab defaults its time zone to UTC. It has a global timezone configuration parameter in `/etc/gitlab/gitlab.rb`.

To update, add the time zone that best applies to your location. Here are two examples:
```
gitlab_rails['time_zone'] = 'America/New_York'
```
or
```
gitlab_rails['time_zone'] = 'Europe/Brussels'
```

After you added this field, reconfigure and restart:
```
gitlab-ctl reconfigure
gitlab-ctl restart
```
