---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# GitLab 17 changes

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** Self-managed

This page contains upgrade information for minor and patch versions of GitLab 17.
Ensure you review these instructions for:

- Your installation type.
- All versions between your current version and your target version.

For more information about upgrading GitLab Helm Chart, see [the release notes for 7.0](https://docs.gitlab.com/charts/releases/7_0.html).

## 17.0.0

- You should [migrate to the new runner registration workflow](../../ci/runners/new_creation_workflow.md) before upgrading to GitLab 17.0.

  In GitLab 16.0, we introduced a new runner creation workflow that uses runner authentication tokens to register runners.
  The legacy workflow that uses registration tokens is now disabled by default in GitLab 17.0 and will be removed in GitLab 18.0.
  If registration tokens are still being used, upgrading to GitLab 17.0 will cause runner registration to fail.
