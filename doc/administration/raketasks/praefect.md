---
stage: Systems
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Praefect Rake tasks
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

Rake tasks are available for projects that have been created on Praefect storage. See the
[Praefect documentation](../gitaly/praefect.md) for information on configuring Praefect.

## Replica checksums

`gitlab:praefect:replicas` prints out checksums of the repository of a given `project_id` on:

- The primary Gitaly node.
- Secondary internal Gitaly nodes.

Run this Rake task on the node that GitLab is installed and not on the node that Praefect is installed.

- Linux package installations:

  ```shell
  sudo gitlab-rake "gitlab:praefect:replicas[project_id]"
  ```

- Self-compiled installations:

  ```shell
  sudo -u git -H bundle exec rake "gitlab:praefect:replicas[project_id]" RAILS_ENV=production
  ```
