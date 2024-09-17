---
info: For assistance with this Style Guide page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments-to-other-projects-and-subjects.
stage: none
group: unassigned
description: 'Learn how to document version-specific changes'
---

# Version-specific changes

A version-specific page contains upgrade notes a GitLab administrator
should follow when upgrading their self-managed instance.

It contains information like:

- Important bugs, bug fixes, and workarounds from one version to another.
- Long-running database migrations administrators should be aware of.
- Breaking changes in configuration files.

## Major version

For each major version of GitLab, create a page in `doc/update/versions/gitlab_X_changes.md`.

The version-specific changes page should use the following format:

```markdown
# GitLab X changes

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** Self-managed

This page contains upgrade information for minor and patch versions of GitLab X.
Ensure you review these instructions for:

- Your installation type.
- All versions between your current version and your target version.

For more information about upgrading GitLab Helm Chart, see [the release notes for X.0](https://docs.gitlab.com/charts/releases/X_0.html).

## Issues to be aware of when upgrading from <last minor version of last major>

- General upgrade notes and issues.

## X.Y.1 (add the latest version at the top of the page)

- General upgrade notes and issues.
- ...

### Linux package installations

- Information specific to Linux package installations.
- ...

### Self-compiled installations

- Information specific to self-compiled installations.
- ...

### Geo installations

 - Information specific to Geo.
 - ...

## X.Y.0

 ...
```
