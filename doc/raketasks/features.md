---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Namespaces **(FREE SELF)**

This Rake task enables [namespaces](../user/group/index.md#namespaces) for projects.

## Enable usernames and namespaces for user projects

This command enables the namespaces feature introduced in GitLab 4.0. It moves every project in its namespace folder.

The **repository location changes as part of this task**, so you must **update all your Git URLs** to
point to the new location.

To change your username:

1. In the top-right corner, select your avatar.
1. Select **Edit profile**.
1. In the left sidebar, select **Account**.
1. In the **Change username** section, type the new username.
1. Select **Update username**.

For example:

- Old path: `git@example.org:myrepo.git`.
- New path: `git@example.org:username/myrepo.git` or `git@example.org:groupname/myrepo.git`.

```shell
bundle exec rake gitlab:enable_namespaces RAILS_ENV=production
```
