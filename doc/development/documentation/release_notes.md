---
stage: none
group: unassigned
info: For assistance with this Style Guide page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments-to-other-projects-and-subjects>.
title: Release notes
---

In GitLab 19.0, a new process exists for monthly release posts.

For this month, we will use a single Markdown file. We can adjust the process
based on feedback and the user experience during this release.

## How to add a feature release note

To update the release notes for 19.0:

1. Open the [`gitlab-19-0-released.md`](../../releases/19/gitlab-19-0-released.md) file
   in the `gitlab-org/gitlab` project.
1. Copy the commented-out text at the top of the page. It's an `H3` heading, comment for the category, details, and a block of text.
1. Paste the text into the section that makes the most sense: primary feature, or one of the three groups.

   Agentic Core includes:

   - `ai-powered`
   - `modelops`

   Unified DevOps and Security includes:

   - `create`
   - `plan`
   - `verify`
   - `deploy`
   - `package`
   - `application_security_testing`
   - `security_risk_management`
   - `software_supply_chain_security`
   - `analytics`

   Scale and Deployments includes:

   - `fulfillment`
   - `growth`
   - `foundations`
   - `tenant_scale`
   - `gitlab_delivery`
   - `gitlab_dedicated`
   - `production_engineering`
   - `data_access`
   - unlisted or unknown

1. Add a `>` to the end of the category comment so it's properly formatted HTML: (`<!-- categories: <name value from categories.yml> -->`).
   Add values that match the [categories.yml](https://gitlab.com/gitlab-com/www-gitlab-com/-/blob/master/data/categories.yml) file.
   The value is case-sensitive.
   Use comma separation for multiple values.
1. Edit the text to reflect your feature announcement.
   - Use 125 words or fewer, and no images or videos.
   - Documentation links are allowed and must be relative.
   - Ensure work item links are not confidential.
   - Links to other resources are also allowed.
1. Open a merge request:
   - Use the Release Notes Item template to populate the description and to track progress.
   - Assign the merge request to an Engineering Manager and Technical Writer for review.

> [!note]
> All release notes should be merged by 00:00 (midnight) UTC on the Friday before the release day to be included in the appropriate release.

If your item is primary, review the instructions for What's new.

## Technical Writer review

To review a release note merge request:

1. Review the tiers, offerings, documentation link, issue link, and content.
   Ensure the links have been changed from the examples, and that the work item isn't confidential.
1. Start an automatic rebase with `/rebase` in an empty comment, then set it to auto-merge when the pipeline completes.

While it is preferable for the writer to merge, any Maintainer can merge.
The priority is for the item to be merged before the release.

## Technical Writer release day process

On release day, the writer assigned to the upcoming release creates two merge requests: one for the `gitlab` repo and one for `docs-gitlab-com`.
You can create these merge requests a few days before the release.

> [!warning]
> Do not merge the changes until the release manager confirms that the packages are publicly
> available, usually around 14:00 UTC.

### Update content to reflect today's release

Open the file for the release, for example `doc/releases/19/gitlab-19-0-released.md`, and update the following content.

1. In the metadata, after the `group`, add the release date. For example:

   ```markdown
   date: 2026-05-21
   ```

   This addition will make the pipeline fail until the date of release.
   This is expected.

1. Change the `description` metadata from:

   ```markdown
   Summary of features included in <version>
   ```

   To:

   ```markdown
   GitLab <version> released with <top feature title>
   ```

1. Change the `title` from:

   ```markdown
   title: GitLab <version> - not yet released
   ```

   To:

   ```markdown
   title: GitLab <version>
   ```

1. Change the intro text from:

   ```markdown
   The following features are being delivered for GitLab 19.0.
   These features are now available on GitLab.com.
   ```

   To:

   ```markdown
   On <April 16, 2026>, <GitLab 18.11> was released with the following features.
   ```

   Replace the date and version with the version that's being released.

### Create content for next release

Now create a file for the next version.

1. In the `/doc/releases/` folder, create a Markdown file for the next release. For example, `19/gitlab-19-1-released.md`.
1. Populate the file with the [template](#new-release-notes-file-template).
1. Add a `>` to the end of the category comment so it's properly formatted HTML: `<!-- categories: <name value from categories.yml> -->`
1. In the metadata and intro text, change the version number to the next version number.

### Update the index file

Now update the index file to point to the new file.

1. Open `/doc/releases/19/_index.md`.
1. Add the upcoming version, for example, if 19.0 is shipping, add 19.1:

   ```markdown
   {{</* cards */>}}

   - [GitLab 19.0](gitlab-19-0-released.md)
   - [GitLab 19.1](gitlab-19-1-released.md)

   {{</* /cards */>}}
   ```

### Update the redirect file

1. Open `doc/releases/upcoming.md`.
1. Update the text and metadata to reflect the next release.

You can now push your commit. This merge request is complete.

### Update the left navigation

Now go to the `docs-gitlab-com` repository and update `navigation.yaml` to
add the next version's page to the left navigation.

For example, add 19.1:

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

## New release notes file template

```markdown
---
stage: Release Notes
group: Monthly Release
title: "GitLab 19.0 release notes - not yet released"
description: "Summary of features included in 19.0"
---

The following features are being delivered for GitLab 19.0.
These features are now available on GitLab.com.

<!-- Copy this template, and paste it into the doc section where it belongs:

Primary feature, Agentic Core, Scale and Deployments, or Unified DevOps and Security.

Update all the information as needed.

### Feature explanation here

<!-- categories: <name value from categories.yml> --

{{</* details */>}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../ci/yaml/_index.md), [Related issue](https://gitlab.com/groups/gitlab-org/-/work_items/17754)

{{</* /details */>}}

Now write 125 words or fewer to explain the value of this improvement.
Use phrases that start with, "In previous versions of GitLab, you couldn't... Now you can..."

Use present tense, and speak about "you" instead of "the user."
-->

<!-- ## Primary features

The first person to add a feature in this area, please make the title visible and delete this comment -->

<!-- ## Agentic Core

The first person to add a feature in this area, please make the title visible and delete this comment -->

<!-- ## Scale and Deployments

The first person to add a feature in this area, please make the title visible and delete this comment -->

<!-- ## Unified DevOps and Security

The first person to add a feature in this area, please make the title visible and delete this comment -->
```
