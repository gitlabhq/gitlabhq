---
stage: Create
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference
---

# Praefect Rake tasks **(CORE ONLY)**

> [Introduced]( https://gitlab.com/gitlab-org/gitlab/-/merge_requests/28369) in GitLab 12.10.

Rake tasks are available for projects that have been created on Praefect storage. See the
[Praefect documentation](../gitaly/praefect.md) for information on configuring Praefect.

## Replica checksums

`gitlab:praefect:replicas` prints out checksums of the repository of a given `project_id` on:

- The primary Gitaly node.
- Secondary internal Gitaly nodes.

**Omnibus Installation**

```shell
sudo gitlab-rake "gitlab:praefect:replicas[project_id]"
```

**Source Installation**

```shell
sudo -u git -H bundle exec rake "gitlab:praefect:replicas[project_id]" RAILS_ENV=production
```
