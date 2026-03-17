---
stage: Tenant Scale
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Praefect Rake tasks
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

Rake tasks are available for projects that have been created on Praefect storage. See the
[Praefect documentation](../gitaly/praefect/_index.md) for information on configuring Praefect.

## Replica checksums

`gitlab:praefect:replicas` prints out checksums of the repository on:

- The primary Gitaly node.
- Secondary internal Gitaly nodes.

You can check replicas for a specific project or for all projects.

Run this Rake task on the node that GitLab is installed and not on the node that Praefect is installed.

### Check replicas for a specific project

- Linux package installations:

  ```shell
  sudo gitlab-rake "gitlab:praefect:replicas[project_id]"
  ```

- Self-compiled installations:

  ```shell
  sudo -u git -H bundle exec rake "gitlab:praefect:replicas[project_id]" RAILS_ENV=production
  ```

### Check replicas for all projects

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/219120) in GitLab 18.10.

{{< /history >}}

Checking replicas for all projects can be resource-intensive on large GitLab instances with thousands of projects because each project requires external calls to Gitaly services.
Consider running this task during off-peak hours or on a schedule that doesn't impact production performance.

- Linux package installations:

  ```shell
  sudo gitlab-rake gitlab:praefect:replicas
  ```

- Self-compiled installations:

  ```shell
  sudo -u git -H bundle exec rake gitlab:praefect:replicas RAILS_ENV=production
  ```
