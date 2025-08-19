---
stage: none
group: unassigned
info: For assistance with this Style Guide page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments-to-other-projects-and-subjects.
description: Learn how to document upgrade notes
title: Version-specific changes
---

A version-specific page contains upgrade notes a GitLab administrator
should follow when upgrading their GitLab Self-Managed instance.

It contains information like:

- Important bugs, bug fixes, and workarounds from one version to another.
- Long-running database migrations administrators should be aware of.
- Breaking changes in configuration files.

## Major version

For each major version of GitLab, create a page in `doc/update/versions/gitlab_X_changes.md`.

The version-specific upgrade notes page should use the following format:

```markdown
title: GitLab X upgrade notes
---

{{</* details */>}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{</* /details */>}}

This page contains upgrade information for minor and patch versions of GitLab X.
Ensure you review these instructions for:

- Your installation type.
- All versions between your current version and your target version.

For additional information for Helm chart installations, see
[the Helm chart x.0 upgrade notes](https://docs.gitlab.com/charts/releases/x_0.html).

## Issues to be aware of when upgrading from <last minor version of last major>

- General upgrade notes and issues.

## X.Y.1 (add the latest version at the top of the page)

- General upgrade notes and issues.
- ...

### Linux package installations X.Y.1

- Information specific to Linux package installations.
- ...

### Self-compiled installations X.Y.1

- Information specific to self-compiled installations.
- ...

### Geo installations X.Y.1

 - Information specific to Geo.
 - ...

## X.Y.0

 ...
```
