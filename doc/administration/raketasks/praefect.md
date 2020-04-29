# Praefect Rake Tasks **(CORE ONLY)**

> [Introduced]( https://gitlab.com/gitlab-org/gitlab/-/merge_requests/28369) in GitLab 12.10.

## Replica checksums

Prints out checksums of the repository of a given project_id on the primary as well as secondary internal Gitaly nodes.

NOTE: **Note:**
This only is relevant and works for projects that have been created on a praefect storage. See the [Praefect Documentation](../gitaly/praefect.md) for configuring Praefect.

**Omnibus Installation**

```shell
sudo gitlab-rake "gitlab:praefect:replicas[project_id]"
```

**Source Installation**

```shell
sudo -u git -H bundle exec rake "gitlab:praefect:replicas[project_id]" RAILS_ENV=production
```
