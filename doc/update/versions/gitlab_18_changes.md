---
stage: GitLab Delivery
group: Self Managed
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab 18 changes
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

This page contains upgrade information for minor and patch versions of GitLab 18.
Ensure you review these instructions for:

- Your installation type.
- All versions between your current version and your target version.

For more information about upgrading GitLab Helm Chart, see [the release notes for 9.0](https://docs.gitlab.com/charts/releases/9_0/).

## 18.0.0

### Geo installations 18.0.0

- If you deployed GitLab Enterprise Edition and then reverted to GitLab Community Edition,
  your database schema may deviate from the schema that the GitLab application expects,
  leading to migration errors. Four particular errors can be encountered on upgrade to 18.0.0
  because a migration was added in that version which changes the defaults of those columns.

  The errors are:

  - `No such column: geo_nodes.verification_max_capacity`
  - `No such column: geo_nodes.minimum_reverification_interval`
  - `No such column: geo_nodes.repos_max_capacity`
  - `No such column: geo_nodes.container_repositories_max_capacity`

  This migration was patched in GitLab 18.0.2 to add those columns if they are missing.
  See [issue #543146](https://gitlab.com/gitlab-org/gitlab/-/issues/543146).

  **Affected releases**:

  | Affected minor releases | Affected patch releases | Fixed in |
  | ----------------------- | ----------------------- | -------- |
  | 18.0                    |  18.0.0 - 18.0.1        | 18.0.2   |
