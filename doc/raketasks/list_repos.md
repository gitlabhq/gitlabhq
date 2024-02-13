---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

<!--- start_remove The following content will be removed on remove_date: '2024-05-16' -->

# List repository directories Rake task (deprecated)

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** Self-managed

WARNING:
This feature was [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/384361) in GitLab 16.7 and is planned for removal in 17.0.
[If migrating GitLab, use backup and restore](../administration/operations/moving_repositories.md#recommended-approach-in-all-cases)
instead.

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
time you specify is parsed by the Rails [`TimeZone#parse` function](https://api.rubyonrails.org/classes/ActiveSupport/TimeZone.html#method-i-parse).

```shell
# Omnibus
sudo gitlab-rake gitlab:list_repos SINCE='Sep 1 2015'

# Source
cd /home/git/gitlab
sudo -u git -H bundle exec rake gitlab:list_repos RAILS_ENV=production SINCE='Sep 1 2015'
```

<!--- end_remove -->