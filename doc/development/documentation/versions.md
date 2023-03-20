---
info: For assistance with this Style Guide page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments-to-other-projects-and-subjects.
stage: none
group: unassigned
description: 'Writing styles, markup, formatting, and other standards for GitLab Documentation.'
---

# Documenting product versions

The GitLab product documentation includes version-specific information,
including when features were introduced and when they were updated or removed.

## View older documentation versions

Previous versions of the documentation are available on `docs.gitlab.com`.
To view a previous version, in the upper-right corner, select **Versions**.

To view versions that are not available on `docs.gitlab.com`:

- View the [documentation archives](https://docs.gitlab.com/archives/).
- Go to the GitLab repository and select the version-specific branch. For example,
  the [13.2 branch](https://gitlab.com/gitlab-org/gitlab/-/tree/13-2-stable-ee/doc) has the
  documentation for GitLab 13.2.

## Documenting version-specific features

When a feature is added or updated, you can include its version information
either as a **Version history** list item or as an inline text reference.

You do not need to add version information on the pages in the `/development` directory.

### Add a **Version history** item

If all content in a topic is related, add a version history item after the topic title.
For example:

```markdown
## Feature name

> [Introduced](<link-to-issue>) in GitLab 11.3.

This feature does something.
```

The item text must include these words in order. Capitalization doesn't matter.

- `introduced`, `enabled`, `deprecated`, `changed`, `moved`, `recommended`, `removed`, or `renamed`
- `in` or `to`
- `GitLab` (or, for external projects, the name of the project)

If possible, include a link to the related issue, merge request, or epic.
Do not link to the pricing page. Do not include the subscription tier.

#### Introducing a new feature

If you use `introduced`, start the sentence with the feature name or a gerund:

```markdown
> - Notifications for expiring tokens [introduced](<link-to-issue>) in GitLab 11.3.
> - Creating an issue from an issue board [introduced](<link-to-issue>) in GitLab 13.1.
```

#### Moving subscription tiers

If a feature is moved to another subscription tier, use `moved`:

```markdown
> - [Moved](<link-to-issue>) from GitLab Ultimate to GitLab Premium in 11.8.
> - [Moved](<link-to-issue>) from GitLab Premium to GitLab Free in 12.0.
```

#### Features introduced behind feature flags

When features are introduced behind feature flags, you must add details about the feature flag to the documentation.
For more information, see [Document features deployed behind feature flags](feature_flags.md).

### Inline version text

If you're adding content to an existing topic, you can add version information
inline with the existing text. If possible, include a link to the related issue,
merge request, or epic. For example:

```markdown
The voting strategy [in GitLab 13.4 and later](<link-to-issue>) requires the primary and secondary
voters to agree.
```

## Deprecations and removals

When features are deprecated and removed, update the related documentation.

NOTE:
A separate process exists for [GraphQL docs](../api_graphql_styleguide.md#deprecating-schema-items)
and [REST API docs](restful_api_styleguide.md#deprecations).

### Deprecate a page or topic

To deprecate a page or topic:

1. Add `(deprecated)` after the title. Use a warning to explain when it was deprecated,
   when it will be removed, and the replacement feature.

   ```markdown
   ## Title (deprecated) **(ULTIMATE SELF)**

   WARNING:
   This feature was [deprecated](<link-to-issue>) in GitLab 14.8
   and is planned for removal in 15.4. Use [feature X](<link-to-issue>) instead.
   ```

   If you're not sure when the feature will be removed or no
   replacement feature exists, you don't need to add this information.

1. If the deprecation is a breaking change, add this text:

   ```markdown
   This change is a breaking change.
   ```

   You can add any additional context-specific details that might help users.

1. Add the following HTML comments above and below the content.
   For the `remove_date`, set a date three months after the release where it
   was deprecated.

   ```markdown
   <!--- start_remove The following content will be removed on remove_date: 'YYYY-MM-DD' -->

   ## Title (deprecated) **(ULTIMATE SELF)**

   WARNING:
   This feature was [deprecated](<link-to-issue>) in GitLab 14.8
   and is planned for removal in 15.4. Use [feature X](<link-to-issue>) instead.

   <!--- end_remove -->
   ```

1. Open a merge request to add the word `(deprecated)` to the left nav, after the page title.

### Remove a page

Mark content as removed during the release the feature was removed.
The title and a removed indicator remains until three months after the removal.

To remove a page:

1. Leave the page title. Remove all other content, including the version history items and the word `WARNING:`.
1. After the title, change `(deprecated)` to `(removed)`.
1. Update the YAML metadata:
   - For `remove_date`, set the value to a date three months after
     the release when the feature was removed.
   - For the `redirect_to`, set a path to a file that makes sense. If no obvious
     page exists, use the docs home page.

   ```markdown
   ---
   stage: Data Stores
   group: Global Search
   info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
   remove_date: '2022-08-02'
   redirect_to: '../newpath/to/file/index.md'
   ---

   # Title (removed) **(ULTIMATE SELF)**

   This feature was [deprecated](<link-to-issue>) in GitLab X.Y
   and [removed](<link-to-issue>) in X.Y.
   Use [feature X](<link-to-issue>) instead.
   ```

1. Remove the page's entry from the global navigation by editing [`navigation.yaml`](https://gitlab.com/gitlab-org/gitlab-docs/blob/main/content/_data/navigation.yaml) in `gitlab-docs`.

This content is removed from the documentation as part of the Technical Writing team's
[regularly scheduled tasks](https://about.gitlab.com/handbook/product/ux/technical-writing/#regularly-scheduled-tasks).

### Remove a topic

To remove a topic:

1. Leave the title and the details of the deprecation and removal. Remove all other content,
   including the version history items and the word `WARNING:`.
1. Add `(removed)` after the title.
1. Add the following HTML comments above and below the topic.
   For the `remove_date`, set a date three months after the release where it was removed.

   ```markdown
   <!--- start_remove The following content will be removed on remove_date: 'YYYY-MM-DD' -->

   ## Title (removed) **(ULTIMATE SELF)**

   This feature was [deprecated](<link-to-issue>) in GitLab X.Y
   and [removed](<link-to-issue>) in X.Y.
   Use [feature X](<link-to-issue>) instead.

   <!--- end_remove -->
   ```

This content is removed from the documentation as part of the Technical Writing team's
[regularly scheduled tasks](https://about.gitlab.com/handbook/product/ux/technical-writing/#regularly-scheduled-tasks).

## Which versions are removed

GitLab supports the current major version and two previous major versions.
For example, if 15.0 is the current major version, all major and minor releases of
GitLab 15.0, 14.0, and 13.0 are supported.

[View the list of supported versions](https://about.gitlab.com/support/statement-of-support/#version-support).

If you see version history items or inline text that refers to unsupported versions, you can remove it.

Historical feature information is available in [release posts](https://about.gitlab.com/releases/)
or by searching for the issue or merge request where the work was done.

## Promising features in future versions

Do not promise to deliver features in a future release. For example, avoid phrases like,
"Support for this feature is planned."

We cannot guarantee future feature work, and promises
like these can raise legal issues. Instead, say that an issue exists.
For example:

- Support for improvements is proposed in `[issue <issue_number>](LINK-TO-ISSUE)`.
- You cannot do this thing, but `[issue 12345](LINK-TO-ISSUE)` proposes to change this behavior.

You can say that we plan to remove a feature.

### Legal disclaimer for future features

If you **must** write about features we have not yet delivered, put this exact disclaimer about forward-looking statements near the content it applies to.

```markdown
DISCLAIMER:
This page contains information related to upcoming products, features, and functionality.
It is important to note that the information presented is for informational purposes only.
Please do not rely on this information for purchasing or planning purposes.
As with all projects, the items mentioned on this page are subject to change or delay.
The development, release, and timing of any products, features, or functionality remain at the
sole discretion of GitLab Inc.
```

It renders on the GitLab documentation site as:

DISCLAIMER:
This page contains information related to upcoming products, features, and functionality.
It is important to note that the information presented is for informational purposes only.
Please do not rely on this information for purchasing or planning purposes.
As with all projects, the items mentioned on this page are subject to change or delay.
The development, release, and timing of any products, features, or functionality remain at the
sole discretion of GitLab Inc.

If all of the content on the page is not available, use the disclaimer about forward-looking statements once at the top of the page.

If the content in a topic is not ready, use the disclaimer in the topic.
