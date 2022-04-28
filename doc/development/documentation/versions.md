---
info: For assistance with this Style Guide page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments-to-other-projects-and-subjects.
stage: none
group: unassigned
description: 'Writing styles, markup, formatting, and other standards for GitLab Documentation.'
---

# Documenting product versions

GitLab product documentation pages (not including [Contributor and Development](../../index.md)
pages in the `/development` directory) can include version information to help
users be aware of recent improvements or additions.

The GitLab Technical Writing team determines which versions of
documentation to display on this site based on the GitLab
[Statement of Support](https://about.gitlab.com/support/statement-of-support.html#version-support).

## View older GitLab documentation versions

Older versions of GitLab may no longer have documentation available from `docs.gitlab.com`.
If documentation for your version is no longer available from `docs.gitlab.com`, you can still view a
tagged and released set of documentation for your installed version:

- In the [documentation archives](https://docs.gitlab.com/archives/).
- At the `/help` URL of your GitLab instance.
- In the documentation repository based on the respective branch (for example,
  the [13.2 branch](https://gitlab.com/gitlab-org/gitlab/-/tree/13-2-stable-ee/doc)).

## Where to put version text

When a feature is added or updated, you can include its version information
either as a **Version history** item or as an inline text reference.

### Version text in the **Version History**

If all content in a section is related, add version text after the header for
the section. The version information must:

- Be surrounded by blank lines.
- Start with `>`. If there are multiple bullets, each line must start with `> -`.
- The string must include these words in this order (capitalization doesn't matter):
  - `introduced`, `enabled`, `deprecated`, `changed`, `moved`, `recommended` (as in the
    [feature flag documentation](feature_flags.md)), `removed`, or `renamed`
  - `in` or `to`
  - `GitLab`
- Whenever possible, include a link to the completed issue, merge request, or epic
  that introduced the feature. An issue is preferred over a merge request, and
  a merge request is preferred over an epic.
- Do not include information about the tier, unless documenting a tier change
  (for example, `Feature X [moved](issue-link) to Premium in GitLab 19.2`).
- Do not link to the pricing page.
  The tier is provided by the [product badge](styleguide/index.md#product-tier-badges) on the heading.

```markdown
## Feature name

> [Introduced](<link-to-issue>) in GitLab 11.3.

This feature does something.

## Feature name 2

> - [Introduced](<link-to-issue>) in GitLab 11.3.
> - [Enabled by default](<link-to-issue>) in GitLab 11.4.

This feature does something else.
```

If you're documenting elements of a feature, start with the feature name or a gerund:

```markdown
> - Notifications for expiring tokens [introduced](<link-to-issue>) in GitLab 11.3.
> - Creating an issue from an issue board [introduced](<link-to-issue>) in GitLab 13.1.
```

If a feature is moved to another tier:

```markdown
> - [Moved](<link-to-issue>) from GitLab Ultimate to GitLab Premium in 11.8.
> - [Moved](<link-to-issue>) from GitLab Premium to GitLab Free in 12.0.
```

### Inline version text

If you're adding content to an existing topic, you can add version information
inline with the existing text.

In this case, add `([introduced/deprecated](<link-to-issue>) in GitLab X.X)`.

Including the issue link is encouraged, but isn't a requirement. For example:

```markdown
The voting strategy in GitLab 13.4 and later requires the primary and secondary
voters to agree.
```

### Deprecated features

When a feature is deprecated, add `(DEPRECATED)` to the page title or to
the heading of the section documenting the feature, immediately before
the tier badge:

```markdown
<!-- Page title example: -->
# Feature A (DEPRECATED) **(ALL TIERS)**

<!-- Doc section example: -->
## Feature B (DEPRECATED) **(PREMIUM SELF)**
```

Add the deprecation to the version history note (you can include a link
to a replacement when available):

```markdown
> - [Deprecated](<link-to-issue>) in GitLab 11.3. Replaced by [meaningful text](<link-to-appropriate-documentation>).
```

You can also describe the replacement in surrounding text, if available. If the
deprecation isn't obvious in existing text, you may want to include a warning:

```markdown
WARNING:
This feature was [deprecated](link-to-issue) in GitLab 12.3 and replaced by
[Feature name](link-to-feature-documentation).
```

If you add `(DEPRECATED)` to the page's title and the document is linked from the docs
navigation, either remove the page from the nav or update the nav item to include the
same text before the feature name:

```yaml
 - doc_title: (DEPRECATED) Feature A
```

In the first major GitLab version after the feature was deprecated, be sure to
remove information about that deprecated feature.

### End-of-life for features or products

When a feature or product enters its end-of-life, indicate its status by
creating a [warning alert](styleguide/index.md#alert-boxes) directly after its relevant header.
If possible, link to its deprecation and removal issues.

For example:

```markdown
WARNING:
This feature is in its end-of-life process. It is [deprecated](link-to-issue)
in GitLab X.X, and is planned for [removal](link-to-issue) in GitLab X.X.
```

After the feature or product is officially deprecated and removed, remove
its information from the GitLab documentation.

## Versions in the past or future

When describing functionality available in past or future versions, use:

- Earlier, and not older or before.
- Later, and not newer or after.

For example:

- Available in GitLab 13.1 and earlier.
- Available in GitLab 12.4 and later.
- In GitLab 12.2 and earlier, ...
- In GitLab 11.6 and later, ...

## Promising features in future versions

Do not promise to deliver features in a future release. For example, avoid phrases like,
"Support for this feature is planned."

We cannot guarantee future feature work, and promises
like these can raise legal issues. Instead, say that an issue exists.
For example:

- Support for improvements is tracked `[in this issue](LINK)`.
- You cannot do this thing, but `[an issue exists](LINK)` to change this behavior.

You can say that we plan to remove a feature.

### Legal disclaimer for future features

If you **must** write about features we have not yet delivered, put this exact disclaimer near the content it applies to.

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

If all of the content on the page is not available, use the disclaimer once at the top of the page.

If the content in a topic is not ready, use the disclaimer in the topic.

## Removing versions after each major release

When a major GitLab release occurs, we remove all references
to now-unsupported versions. This removal includes version-specific instructions. For example,
if GitLab version 12.1 and later are supported,
instructions for users of GitLab 11 should be removed.

[View the list of supported versions](https://about.gitlab.com/support/statement-of-support.html#version-support).

To view historical information about a feature, review GitLab
[release posts](https://about.gitlab.com/releases/), or search for the issue or
merge request where the work was done.
