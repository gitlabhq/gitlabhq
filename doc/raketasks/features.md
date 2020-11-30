---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Namespaces **(CORE ONLY)**

This Rake task enables [namespaces](../user/group/index.md#namespaces) for projects.

## Enable usernames and namespaces for user projects

This command enables the namespaces feature introduced in GitLab 4.0. It moves every project in its namespace folder.

Note:

- The **repository location changes as part of this task**, so you must **update all your Git URLs** to
  point to the new location.
- The username can be changed at **Profile > Account**.

For example:

- Old path: `git@example.org:myrepo.git`.
- New path: `git@example.org:username/myrepo.git` or `git@example.org:groupname/myrepo.git`.

```shell
bundle exec rake gitlab:enable_namespaces RAILS_ENV=production
```
