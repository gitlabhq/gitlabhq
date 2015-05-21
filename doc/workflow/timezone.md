# Changing your time zone

GitLab defaults its time zone to UTC. It has a global timezone configuration parameter in config/application.rb. 

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