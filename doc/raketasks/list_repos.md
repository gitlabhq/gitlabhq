---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Listing repository directories **(FREE SELF)**

You can print a list of all Git repositories on disk managed by GitLab.

To print a list, run the following command:

```shell
# Omnibus
sudo gitlab-rake gitlab:list_repos

# Source
cd /home/git/gitlab
sudo -u git -H bundle exec rake gitlab:list_repos RAILS_ENV=production
```

The results use the default ordering of the GitLab Rails application.

## Limit search results

To list only projects with recent activity, pass a date with the `SINCE` environment variable. The
time you specify is parsed by the Rails [TimeZone#parse function](https://api.rubyonrails.org/classes/ActiveSupport/TimeZone.html#method-i-parse).

```shell
# Omnibus
sudo gitlab-rake gitlab:list_repos SINCE='Sep 1 2015'

# Source
cd /home/git/gitlab
sudo -u git -H bundle exec rake gitlab:list_repos RAILS_ENV=production SINCE='Sep 1 2015'
```
