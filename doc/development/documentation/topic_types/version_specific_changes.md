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

For each major version of GitLab:

1. Create a new section in `doc/update/upgrade_paths.md`.
   Replace `X` with the major version:

   ```markdown
   ### Required GitLab X upgrade stops

   Required upgrade stops occur at versions `X.2`, `X.5`, `X.8`, and `X.11`.

   You must upgrade to those versions of GitLab X before upgrading to later versions. For each version you upgrade to,
   see the [upgrade notes for GitLab X](versions/gitlab_X_changes.md). If a version is not
   in the upgrade notes, then there's nothing specific about that version to be aware of.

   Find the patch releases in the GitLab package repository. For example, to search for the latest
   GitLab X.2 Enterprise Edition version, go to <https://packages.gitlab.com/app/gitlab/gitlab-ee/search?q=X.2>.
   ```

1. Create a page in `doc/update/versions/gitlab_X_changes.md` with the following format:

   ```markdown
   ---
   stage: GitLab Delivery
   group: Operate
   info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
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
   [the Helm chart X.0 upgrade notes](https://docs.gitlab.com/charts/releases/X_0/).

   ## Required upgrade stops

   To provide a predictable upgrade schedule for instance administrators,
   required upgrade stops occur at versions:

   - `X.2`
   - `X.5`
   - `X.8`
   - `X.11`

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
