---
stage: none
group: unassigned
info: For assistance with this Style Guide page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments-to-other-projects-and-subjects>
description: Learn how to document upgrade notes.
title: Upgrade notes
---

An [upgrade notes](../../../update/versions/_index.md) page contains information
a GitLab administrator should follow when upgrading their GitLab Self-Managed instance.

It contains information like:

- Important bugs, bug fixes, and workarounds from one version to another.
- Long-running database migrations administrators should be aware of.
- Breaking changes in configuration files.
- Security fixes that change behavior.

## Page format

One page exists per major version: `doc/update/versions/gitlab_X_changes.md`.

Each page has two main parts:

- Version indexes at the top: lightweight lists of links, one per minor
  version, that admins scan to find what affects their upgrade.
- Upgrade notes at the bottom: the actual content for each item, each
  with its own heading and stable anchor.

The complete page layout, top to bottom:

```markdown
---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Review the GitLab X upgrade notes.
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

## Upgrade notes reference

The following is a reference list of upgrade notes for each minor GitLab version.
Each list item points to a specific section that holds more information.

Items marked with an installation method, like `(Geo)` or `(Linux package)`,
apply only to that method. All other items apply to all installation methods.

### Upgrade to X.Y

Before upgrading to GitLab X.Y, review the following:

- [X.Y.0] - [Item title](#item-title)

## Upgrade notes

Specific upgrade notes for GitLab X.

### Item title

- Affects: All installation methods
- Affected versions: X.Y.0

Description of the item.

### Geo item title

{{</* details */>}}

- Tier: Premium, Ultimate

{{</* /details */>}}

- Affects: Geo
- Affected versions: X.0.0

Description of the item.
```

When it's time for a new major version (replace `X` with the major version
number):

1. Use the previous template and create a new page under `doc/update/versions/gitlab_X_changes.md`.
1. Create a matching section in `doc/update/upgrade_paths.md`:

   ```markdown
   ### Required GitLab X upgrade stops

   Required upgrade stops occur at versions `X.2`, `X.5`, `X.8`, and `X.11`.

   You must upgrade to those versions of GitLab X before upgrading to later
   versions. For each version you upgrade to, see the
   [upgrade notes for GitLab X](versions/gitlab_X_changes.md). If a version
   is not in the upgrade notes, then there's nothing specific about that
   version to be aware of.

   Find the patch releases in the GitLab package repository. For example,
   to search for the latest GitLab X.2 Enterprise Edition version, go to
   <https://packages.gitlab.com/app/gitlab/gitlab-ee/search?q=X.2>.
   ```

1. Add a link to the new page under `doc/update/versions/_index.md`.
1. Add a [navigation entry](../site_architecture/global_nav.md#add-a-navigation-entry).

## Version indexes

Version indexes are the entry point for administrators.
They contain a list of links to relevant upgrade notes.

- Create a heading `### Upgrade to X.Y` for each minor version. Do not create separate
  headings for patch releases. List minor versions in descending order (latest at the top).
- Start each index line with the patch version in parentheses
  and link to the upgrade note. List items in descending patch order (latest patch at the top).
  For example, an administrator on 18.2.1 upgrading to 18.2.3 scans for `[18.2.3]` and `[18.2.2]` items.
- If an item applies only to specific installation methods,
  add the installation types in parentheses. Use one, or a combination
  of the following:
  - Linux package
  - Helm chart
  - Docker
  - Self-compiled
  - Operator
  - Geo
- When an item affects multiple minor versions, it appears in each
  relevant version index linking to the same anchor. Each index line uses
  the patch version relevant to that specific branch.
- If a specific patch release is a required upgrade stop,
  add a note in the version index. Some required stops are conditional. Include the
  condition and a way for administrators to check if they are affected.
- When an issue spans two major versions (for example, 17.11 and 18.0):
  1. Document the full details on the newer major version page
     (for example, `gitlab_18_changes.md`). When the older page is eventually
     archived, the content remains accessible.
  1. Link from the older page to the newer page.

  If the issue affects many versions on both pages and the cross-page
  linking becomes confusing, duplicate the item on both pages.

Example template for all the above:

```markdown
### Upgrade to 18.8

Before upgrading to GitLab 18.8, review the following:

- [18.8.2] - [Deploy keys for blocked users invalidated](#deploy-keys-for-blocked-users-invalidated)

### Upgrade to 18.7

Before upgrading to GitLab 18.7, review the following:

- [18.7.2] - [Deploy keys for blocked users invalidated](#deploy-keys-for-blocked-users-invalidated)

### Upgrade to 18.2

Before upgrading to GitLab 18.2, review the following:

- [18.2.3] - [Deploy token rotation issue](#deploy-token-rotation-issue)
- [18.2.3] - [Background migration correction](#background-migration-correction)
- [18.2.1] - [New security fix](#new-security-fix)
- [18.2.0] - [Some migration change](#some-migration-change)
- [18.2.0] - [Geo verification fix](#geo-verification-fix) (Geo)
- [18.2.0] - [Gitaly configuration change](#gitaly-configuration-change) (Linux package)

### Upgrade to 18.1

> [!note]
> Version 18.1.3 is a required upgrade stop for instances with
> large `ci_pipeline_messages` tables (more than 1.5 million rows).
> See [long-running pipeline messages data change](#long-running-pipeline-messages-data-change)
> for how to check if you are affected.

- [18.1.3] - [Long-running pipeline messages data change](#long-running-pipeline-messages-data-change)

### Upgrade to 17.11

- [17.11.0] - [Brief description](gitlab_18_changes.md#descriptive-anchor)
```

## Upgrade notes

Upgrade notes are the individual items that describe a change, bug, or
migration. Add each item as an H3 heading with a stable, descriptive
anchor. All items must be added in the `## Upgrade notes` section, regardless
of whether they affect one version or many, and regardless of their
length.

For each item:

- Use a descriptive title (headings must be unique across the page).
  Do not include version numbers in the heading.
- Add a list directly after the heading that lists the affected installation
  types first, and then the affected patch versions.
  For the installation types line, use one of:
  - `All installation methods`
  - A comma-separated list of the affected installation methods,
    for example: `Linux package, Helm chart, Geo`
- When an item affects two or more minor versions, under the
  `Affected versions` item include an affected versions table. This
  pattern also applies to security fixes backported to multiple branches. Each
  affected version index links to this single item.
- For Geo items, include a details block for the tier information before the
  affected versions list. Only use the details block for tier.
- Items that need extensive reference material (SQL queries, data
  descriptions, configuration options) can use H4 sub-headings for
  internal structure. Other upgrade notes link to them by anchor.

```markdown
### Item with Geo tier details

{{</* details */>}}

- Tier: Premium, Ultimate

{{</* /details */>}}

- Affects: Geo
- Affected versions: 18.7.0

Description of the item.

### Item with H4 headings

- Affects: All installation methods
- Affected versions: 18.2.3

Description of the item.

#### SQL query

Use the following SQL query to speed things up.

...

### Item with multiple versions, no fixed patch level

- Affects: All installation methods
- Affected versions:

  | Release | Affected patch levels | Fixed patch level        |
  |---------|-----------------------|--------------------------|
  | 18.8    | 18.8.2 and later      | N/A (intentional change) |
  | 18.7    | 18.7.2 and later      | N/A (intentional change) |
  | 18.6    | 18.6.4 and later      | N/A (intentional change) |

Description of the item.

## Item with multiple versions, fixed patch level

- Affects: All installation methods
- Affected versions:

  | Release | Affected patch releases | Fixed patch level |
  | ------- | ----------------------- | ----------------- |
  | 17.8    |  17.8.0 - 17.8.6        | 17.8.7            |
  | 17.10   |  17.10.0 - 17.10.4      | 17.10.5           |
  | 17.9    |  17.9.0 - 17.9.4        | 17.9.5            |

Description of the item.
```
