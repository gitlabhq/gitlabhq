---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Maintenance Rake tasks
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

GitLab provides Rake tasks for managing passwords.

## Reset passwords

To reset a password using a Rake task, see [reset user passwords](../../security/reset_user_password.md#use-a-rake-task).

## Check password salt length

Starting with GitLab 17.11, the salts of password hashes on FIPS instances
are increased when a user signs in.

You can check how many users need this migration:

```shell
# omnibus-gitlab
sudo gitlab-rake gitlab:password:fips_check_salts:[true]

# installation from source
bundle exec rake gitlab:password:fips_check_salts:[true] RAILS_ENV=production
```
