---
stage: none
group: unassigned
info: For assistance with this Style Guide page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments-to-other-projects-and-subjects>.
title: Release notes
---

GitLab release notes are stored in the `gitlab` repository.

Release notes are organized into one directory for each release with an `index.md` file and individual
files for each feature. For example, the structure is similar to:

```plaintext
doc/
└─ releases/
   └─ 19/
     └─ gitlab-19-0-released/
     │  ├── index.md
     │  └── featureA-Beta.md
     └─ gitlab-19-1-released/
        ├── index.md
        ├── featureB.md
        └── featureA-GA.md
```

For each release, the product manager is responsible for creating the MR and files for the feature release note.
The Technical writing team is responsible for creating all other directories and files.

## Create a feature release note

To create a feature release note:

1. Identify the directory for the associated release. It should be something similar to `/doc/releases/19/gitlab-19-1-released/`.
1. In this directory, create a Markdown file for the feature release note. Although the name doesn't matter, it's
   helpful to name it so it's identifiable later.
1. Paste the [template](#feature-release-note) from below into the Markdown file.
1. Adjust the [metadata](#feature-release-note-metadata) to match your specific needs.
   - Documentation links must be relative.
   - Make sure work item links are not confidential.
1. After the metadata, define the release note text.
   - Use 125 words or fewer, and no images or videos.
   - Documentation links are allowed, but must be relative.
   - Links to other resources are also allowed.
1. Create a merge request:
   - Use the `Release Notes Item` template to populate the description and track progress.
   - Assign the merge request to an Engineering Manager and Technical Writer for review.

> [!note]
> All release notes should be merged by 23:59 UTC on the Friday before the release day to be included in the appropriate release.

## Edit or remove a feature release note

If you need to update or entirely remove a feature release note, make a merge request with the requested changes,
and assign to a Technical Writer for review.

To remove a feature release note, you only need to delete the associated file. No other files need to be adjusted.

### Skip category validation

When a merge request changes a release note, the `docs-lint release-note-categories` CI/CD job validates the
`categories` values against `categories.yml`.
Categories are sometimes renamed or removed, so an older release note might use a category that no longer exists,
which causes the job to fail.

To skip this validation, add the `pipeline:skip-release-note-categories` label to your merge request.

## Add a notable contributor

Developer Relations creates a merge request for each release that adds a few sentences about the notable contributor.
This information needs to be added to the minor release index file.
For example, `doc/releases/19/gitlab-19-1-released/index.md`.

Use the following template after the existing introductory text:

```markdown
## Notable contributor

We are excited to recognize [Name](https://gitlab.com/<username>)
as this month's [Notable Contributor](https://contributors.gitlab.com/notable-contributors)! ...
```

This merge request can be merged at any point before the release, though
you can check with the author to confirm.

## Review a feature release note

After the merge request is created, a Technical Writer must review the [metadata](#feature-release-note-metadata) and body
text. This process is similar to other documentation changes.

## Publish release notes

On release day, the Technical Writer assigned to the upcoming release creates three merge requests:

1. [Update content for the current release](#update-content-for-current-release) and
   [create content for the upcoming release](#create-content-for-upcoming-release) in `gitlab`.
   Can be done before release day.
1. [Add current release to navigation](#add-current-release-to-navigation) in `docs-gitlab-com`.
   Can be done before release day.
1. [Backport the release notes](#backport-final-release-notes) to the most recent stable branch.
   For example, if you are releasing 19.1, the stable branch is `19-1-stable-ee`.
   Must be done on release day.

> [!warning]
> Do not merge the changes until the release manager confirms that the packages are publicly
> available, usually around 14:00 UTC. Release managers add a note in the
> `#release-post` channel when it's time to publish.

### Update content for current release

As part of the publishing process, you must update the minor release index file.

To update the content for the current release:

1. Open the minor release index file. For example `doc/releases/19/gitlab-19-0-released/index.md`.
1. In the metadata, after the `group`, add the release date. For example:

   ```markdown
   date: 2026-05-21
   ```

   This addition makes the pipeline fail until the date of release.
   This failure is expected.

1. Update the `description` metadata:

   ```markdown
   # Original
   description: Summary of features included in <version>

   # New
   description: GitLab <version> released with <top feature title>
   ```

   Replace the version and top feature title with the relevant information.

1. Update the `title` metadata:

   ```markdown
   # Original
   title: GitLab <version> (Upcoming release)

   # New
   title: GitLab <version>
   ```

1. Update the introductory text:

   ```markdown
   # Original
   The following features are being delivered for GitLab <version>.
   These features are now available on GitLab.com.

   # New
   On <release date>, GitLab <version> was released with the following features.
   ```

   Replace the date and version with the relevant information.

### Create content for upcoming release

As part of the publishing process, you must create the directory and content for the next release.
For example, when publishing 19.1, you would create the directory and index file for 19.2.

To create content for the upcoming release:

1. Identify the major version directory in `/doc/releases/`. For example `/doc/releases/19/`.
1. Create content for the upcoming version:
   1. Create a new directory for the upcoming release. For example, `19/gitlab-19-1-released/`.
   1. In the new directory, create an `index.md` file for the upcoming release.
      For example, `19/gitlab-19-1-released/index.md`.
   1. Paste the [template](#minor-release-index) and update the version number.
1. Add the file to the major version index page.
   1. Go to the major version directory in `/doc/releases/`. For example `/doc/releases/19/`.
   1. In `_index.md`, update the cards shortcode to reference the upcoming release file. For example:

   ```markdown
   {{</* cards */>}}

   - [GitLab 19.0](gitlab-19-0-released/index.md)
   - [GitLab 19.1](gitlab-19-1-released/index.md)

   {{</* /cards */>}}
   ```

1. Update the upcoming redirect page to reference the upcoming release.
   1. In `doc/releases/upcoming.md`, update the redirect metadata to point to the upcoming release file. For example:

      ```markdown
      ---
      redirect_to: '19/gitlab-19-1-released/index.md'
      ---
      ```

1. Create a merge request and assign to a Technical Writer for review.

### Add current release to navigation

In the `docs-gitlab-com` repository, add the current release to `data/en-us/navigation.yaml`.
For example:

```yaml
        - title: GitLab 19
          url: 'releases/19/'
          submenu:
            - title: GitLab 19.0
              url: 'releases/19/gitlab-19-0-released/'
            - title: GitLab 19.1
              url: 'releases/19/gitlab-19-1-released/'
```

You can now push your commit. This merge request is complete.

### Backport final release notes

After the release notes are published, you must backport them. You must do this work on release day and not before.

The final cutoff for the `gitlab` repository happens the Friday before the release.
If a user selects the version from the upper-right corner of the documentation site, they cannot get the final notes.
Backporting makes the notes visible and up-to-date when users select the newly released version.

1. Check out the "stable branch." For example, if you are releasing 19.1, check out `19-1-stable-ee`.
1. Open the latest release notes from the `gitlab` repository and copy the file contents.
1. Paste the contents over the local version of the release notes.
1. Open a merge request and select the **Stable branch** template to populate the description.
   Change the target branch to the stable branch (`19-1-stable-ee`).
1. Have a maintainer review and merge. (It can be another Technical Writer.)
   If the branch is still locked, ask for assistance in the `#release-post` channel,
   or wait a few hours until the branch is available to merge.
1. After merge, [create a new pipeline](https://gitlab.com/gitlab-org/technical-writing/docs-gitlab-com/-/pipelines/new).
   For **Run for branch name or tag**, select the version to deploy. In this example, choose `19.1`,
   then select **New pipeline**.

### Update content after a release

To update, add, or remove a release note after the release deadline:

1. Update the `gitlab` repository.
   1. Open a merge request to update the Markdown file in the `gitlab` repository.
   1. Make your changes.
   1. Have a Technical Writer review and merge.
1. Backport the changes.
   1. Check out the stable branch. For example, if you are updating 19.0, check out `19-0-stable-ee`.
   1. Make your change in this branch.
   1. Open a merge request and set the target branch to the stable branch (`19-0-stable-ee`).
   1. Have a maintainer review and merge. It can be another Technical Writer.
   1. After merge, a technical writer must run a new [pipeline](https://gitlab.com/gitlab-org/technical-writing/docs-gitlab-com/-/pipelines/new) for the relevant stable branch in `docs-gitlab-com`.
      For **Run for branch name or tag**, select the version to deploy. In this example, choose `19.0`,
      then select **New pipeline**.
1. On <https://docs.gitlab.com>, select the version in the upper-right corner and verify the notes
   were updated successfully.

## Organization

In the release post, each feature release note is grouped into a section based on the `stage`
metadata defined in the feature release note. Each [stage](https://gitlab.com/gitlab-org/technical-writing/docs-gitlab-com/-/blob/main/data/release_post_groupings.yaml)
maps to one of the following sections:

| Section                     | Stages |
| --------------------------- | ------ |
| Primary features            | -      |
| Agentic Core                | `ai_platform`, `ai_coding`, `agent_foundations`, `ai_clients`, `modelops` |
| Unified DevOps and Security | `analytics`, `application_security_testing`, `create`, `deploy`, `knowledge_graph`, `package`, `plan`, `security_risk_management`, `software_supply_chain_security`, `verify` |
| Scale and Deployments       | `data_access`, `database_excellence`, `developer_experience`, `foundations`, `fulfillment`, `gitlab_dedicated`, `gitlab_delivery`, `growth`, `production_engineering`, `tenant_scale`, `unlisted/unknown` |

Sections appear in the order listed in the table, with `Primary features` first. Any stage that
isn't mapped appears in the `Scale and Deployments` section. To add features to the `Primary features` section,
use the [`level`](#feature-release-note-metadata) metadata.

In each section, feature release notes are listed alphabetically by title. To override this order, define a value
for the `weight` metadata, where lower numbers go first.

Generally, use multiples of 10 (such as `10`, `20`, `30`) to leave room for future insertions, and avoid single-digit
values unless a note must absolutely appear first.

## Metadata

### Minor release index metadata

| Metadata      | Format                                                                                                                         | Description |
| ------------- | ------------------------------------------------------------------------------------------------------------------------------ | ----------- |
| `title`       | Pre-release: `GitLab <version> (Upcoming release)`<br>Post-release: `GitLab <version>`                                         | Page title. Uses the first format before release, and the second on release day. |
| `description` | Pre-release: `Summary of features included in <version>`<br>Post-release: `GitLab <version> released with <top feature title>` | Short summary displayed on cards for the index page. |
| `group`       | `Monthly Release`, `Patch Release`                                                                                             | Used for analytics and feedback. Always uses `Monthly Release`; patch releases are created through a different process. |
| `stage`       | `Release Notes`                                                                                                                | Used for analytics and feedback. Always uses `Release Notes`. |

### Feature release note metadata

| Metadata             | Format                                                                                                 | Description |
| -------------------- | ------------------------------------------------------------------------------------------------------ | ----------- |
| `title`              | string                                                                                                 | Feature title. Displayed as a section heading. Ideally seven words or fewer. |
| `tier`               | array, formatted like `[ Free, Premium, Ultimate ]`                                                    | Feature tier. Requires at least one. Always follow this order. |
| `offering`           | array, formatted like `[ gitlab_com, self_managed, gitlab_dedicated, gitlab_dedicated_for_government ]` | Feature offerings. Formatting matters. Requires at least one. Always follow this order. |
| `documentation_link` | relative URL                                                                                           | Link to the feature documentation. Don't use `https://`-style links, and omit `_index.md` or the `.md` extension. |
| `work_item`          | absolute URL                                                                                           | Link to the related work item. Must not be confidential. |
| `categories`         | array                                                                                                  | An array with the `Name` value of one or more [categories](https://gitlab.com/gitlab-com/www-gitlab-com/-/blob/master/data/categories.yml). Values are case-sensitive, separate multiple values with commas. If a related category doesn't exist, make another merge request to add it. |
| `stage`              | string                                                                                                 | Name of the stage that created the feature. Used to [organize](#organization) the section the release note appears in. |
| `level`              | One of: `primary` or `secondary`                                                                       | Optional. Controls placement in the `Primary features` section. If undefined, defaults to `secondary`. |
| `weight`             | number                                                                                                 | Optional. Controls ordering in each [section](#organization). Lower numbers go first. To force a feature release note first in a section, use a lower number such as 10. To avoid sorting issues with other feature release notes, avoid using single-digit numbers unless the note must absolutely appear first. |

## Templates

### Minor release index

```markdown
---
title: "GitLab <version> (Upcoming release)"
description: "Summary of features included in <version>"
group: Monthly Release
stage: Release Notes
---

The following features are being delivered for GitLab <version>.
These features are now available on GitLab.com.

## Notable contributor
```

### Feature release note

```markdown
---
title:
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated, gitlab_dedicated_for_government ]
stage: application_security_testing
documentation_link: "../../../user/permissions/#groups"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/<work-item-number>
categories: [ System Access, Permissions ]
level: primary or secondary
weight: 50
---

The text of the feature release note.

Explain the value of this improvement with 125 words or fewer.
Use phrases that start with, "In previous versions of GitLab, you couldn't... Now you can..."
```
