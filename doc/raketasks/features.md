# Namespaces

This Rake task enables [namespaces](../user/group/index.md#namespaces) for projects.

## Enable usernames and namespaces for user projects

This command will enable the namespaces feature introduced in GitLab 4.0. It will move every project in its namespace folder.

Note:

- The **repository location will change**, so you will need to **update all your Git URLs** to
  point to the new location.
- The username can be changed at **Profile > Account**.

For example:

- Old path: `git@example.org:myrepo.git`.
- New path: `git@example.org:username/myrepo.git` or `git@example.org:groupname/myrepo.git`.

```shell
bundle exec rake gitlab:enable_namespaces RAILS_ENV=production
```
