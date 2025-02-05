---
info: For assistance with this Style Guide page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments-to-other-projects-and-subjects.
stage: none
group: unassigned
description: 'Guidelines for deprecations and page removals'
title: Deprecations and removals
---

When GitLab deprecates or removes a feature, use the following process to update the documentation.
This process requires temporarily changing content to be "deprecated" or "removed" before it's deleted.

If a feature is not generally available, you can delete the content outright instead of following these instructions.

NOTE:
REST API docs [have a separate deprecation style](../restful_api_styleguide.md#deprecations).
The GraphQL API [has a separate deprecation process](../../../api/graphql/_index.md#deprecation-and-removal-process),
and [style for the deprecation reason](../../api_graphql_styleguide.md#deprecation-reason-style-guide).

## Features not actively being developed

When a feature is no longer actively developed, but not deprecated, add the following note under
the topic title and version history:

```markdown
NOTE:
This feature is not under active development, but
[community contributions](https://about.gitlab.com/community/contribute/) are welcome.
```

## Deprecate a page or topic

To deprecate a page or topic:

1. Add `(deprecated)` after the title. Use a warning to explain when it was deprecated,
   when it will be removed, and the replacement feature.

   ```markdown
   ## Title (deprecated)

   DETAILS:
   **Tier:** Premium, Ultimate
   **Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

   WARNING:
   This feature was [deprecated](https://issue-link) in GitLab 14.8
   and is planned for removal in 15.4. Use [feature X](link-to-docs.md) instead.
   ```

   If you're not sure when the feature will be removed or no
   replacement feature exists, you don't need to add this information.

1. If the deprecation is a [breaking change](../../../update/terminology.md#breaking-change), add this text:

   ```markdown
   This change is a breaking change.
   ```

   You can add any additional context-specific details that might help users.

1. Add the following HTML comments above and below the content. For `remove_date`,
   set a date three months after the [release where it will be removed](https://about.gitlab.com/releases/).

   ```markdown
   <!--- start_remove The following content will be removed on remove_date: 'YYYY-MM-DD' -->

   ## Title (deprecated)

   DETAILS:
   **Tier:** Premium, Ultimate
   **Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

   WARNING:
   This feature was [deprecated](https://issue-link) in GitLab 14.8
   and is planned for removal in 15.4. Use [feature X](link-to-docs.md) instead.

   <!--- end_remove -->
   ```

1. Open a merge request to add the word `(deprecated)` to the left nav, after the page title.

## Remove a page

Mark content as removed during the release the feature was removed.
The title and a removed indicator remains until three months after the removal.

To remove a page:

1. Leave the page title. Remove all other content, including the history items and the word `WARNING:`.
1. After the title, change `(deprecated)` to `(removed)`.
1. Update the YAML metadata:
   - For `remove_date`, set the value to a date three months after
     the release when the feature was removed.
   - For the `redirect_to`, set a path to a file that makes sense. If no obvious
     page exists, use the docs home page.

   ```markdown
   ---
   stage: Foundations
   group: Global Search
   info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
   remove_date: '2022-08-02'
   redirect_to: '../newpath/to/file/index.md'
   ---

   # Title (removed)

   DETAILS:
   **Tier:** Premium, Ultimate
   **Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

   This feature was [deprecated](https://issue-link) in GitLab X.Y
   and [removed](https://issue-link) in X.Y.
   Use [feature X](link-to-docs.md) instead.
   ```

1. Edit the [`navigation.yaml`](https://gitlab.com/gitlab-org/gitlab-docs/blob/main/content/_data/navigation.yaml) in `gitlab-docs`
   to remove the page's entry from the global navigation.
1. Search the [Deprecations and Removals](../../../update/deprecations.md) page for
   links to the removed page. These are full URLs like: `https://docs.gitlab.com/ee/user/deprecated_page.html`.
   If you find any links, update the relevant [YAML files](https://gitlab.com/gitlab-org/gitlab/-/tree/master/data/deprecations):

   - In the `body:` section, remove links to the removed page.
   - In the `documentation_url:` section, if the entry links to the page, delete the link.
   - Run the Rake task to update the documentation:

     ```shell
     bin/rake gitlab:docs:compile_deprecations
     ```

This content is removed from the documentation as part of the Technical Writing team's
[regularly scheduled tasks](https://handbook.gitlab.com/handbook/product/ux/technical-writing/#regularly-scheduled-tasks).

## Remove a topic

To remove a topic:

1. Leave the title and the details of the deprecation and removal. Remove all other content,
   including the history items and the word `WARNING:`.
1. Add `(removed)` after the title.
1. Add the following HTML comments above and below the topic.
   For `remove_date`, set a date three months after the release where it was removed.

   ```markdown
   <!--- start_remove The following content will be removed on remove_date: 'YYYY-MM-DD' -->

   ## Title (removed)

   DETAILS:
   **Tier:** Premium, Ultimate
   **Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

   This feature was [deprecated](https://issue-link) in GitLab X.Y
   and [removed](https://issue-link) in X.Y.
   Use [feature X](link-to-docs.md) instead.

   <!--- end_remove -->
   ```

1. Search the [Deprecations and Removals](../../../update/deprecations.md) page for
   links to the removed page. These are full URLs like: `https://docs.gitlab.com/ee/user/deprecated_page.html`.
   If you find any links, update the relevant [YAML files](https://gitlab.com/gitlab-org/gitlab/-/tree/master/data/deprecations):

   - In the `body:` section, remove links to the removed page.
   - In the `documentation_url:` section, if the entry links to the page, delete the link.
   - Run the Rake task to update the documentation:

     ```shell
     bin/rake gitlab:docs:compile_deprecations
     ```

This content is removed from the documentation as part of the Technical Writing team's
[regularly scheduled tasks](https://handbook.gitlab.com/handbook/product/ux/technical-writing/#regularly-scheduled-tasks).

## Removing version-specific upgrade pages

Version-specific upgrade pages are in the `doc/update/versions/` directory.

We don't remove version-specific upgrade pages immediately for a major milestone. This gives
users time to upgrade from older versions.

For example, `doc/update/versions/14_changes.md` should
be removed during the `.3` milestone. Therefore `14_changes.md` are
removed in GitLab 17.3.

Instead of removing the unsupported page:

- [Add a note](#remove-a-topic) with a date three months
in the future to ensure the page is removed during the
[monthly maintenance task](https://handbook.gitlab.com/handbook/product/ux/technical-writing/#regularly-scheduled-tasks).
- Do not add `Removed` to the title.

If the `X_changes.md` page contains relative links to other sections
that are removed as part of the versions cleanup, the `docs-lint links`
job might fail. You can replace those relative links with an [archived version](https://archives.docs.gitlab.com).
Choose the latest minor version of the unsupported version to be removed.
