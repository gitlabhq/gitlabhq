---
stage: none
group: unassigned
info: For assistance with this Style Guide page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments-to-other-projects-and-subjects.
description: Writing styles, markup, formatting, and other standards for GitLab Documentation.
title: Product availability details
---

Product availability details provide information about a feature.

- If the details apply to the whole page, place them at the top
  of the page, but after the front matter.
- If they apply to a specific section, place the details under the applicable
  section titles.

Availability details include the tier, offering, status, and history.

The Markdown for availability details should look like the following:

```markdown
title: 'Topic title'
---

{{</* details */>}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Status: Experiment

{{</* /details */>}}

{{</* history */>}}

- [Introduced](https://link-to-issue) in GitLab 16.3.
- Updated in GitLab 16.4.

{{</* /history */>}}
```

## Available options

Use the following text for the tier, offering, add-on, status, and version history.

### Offering

For offering, use any combination of these entries, in this order, separated by commas:

- `GitLab.com`
- `GitLab Self-Managed`
- `GitLab Dedicated`

For example:

- `GitLab.com`
- `GitLab.com, GitLab Self-Managed`
- `GitLab Self-Managed`
- `GitLab Self-Managed, GitLab Dedicated`

{{< alert type="note" >}}

If you have reviewed a page and it specifically doesn't apply to GitLab Dedicated,
[assign metadata](../metadata.md#indicate-gitlab-dedicated-support).

{{< /alert >}}

### Tier

For tier, choose one:

- `Free, Premium, Ultimate`
- `Premium, Ultimate`
- `Ultimate`

{{< alert type="note" >}}

GitLab Dedicated always includes an Ultimate subscription.

{{< /alert >}}

#### Add-ons

For add-ons, the possibilities are:

```markdown
- Add-on: GitLab Duo Pro
- Add-on: GitLab Duo Enterprise
- Add-on: GitLab Duo Pro or Enterprise
- Add-on: GitLab Duo with Amazon Q
```

### Status

For status, choose one:

- `Beta`
- `Experiment`
- `Limited availability`

Generally available features should not have a status.

### History

The documentation site uses [shortcodes](../hugo_migration.md#shortcodes) to render the version history,
for example:

```markdown
{{</* history */>}}

- [Introduced](https://issue-link) in GitLab 16.3.
- [Changed](https://issue-link) in GitLab 16.4.

{{</* /history */>}}
```

In addition:

- Ensure that history notes are listed after the details (if any), and immediately
  after the heading.
- Ensure that the output generates properly.
- Ensure the version history begins with `-`.
- If possible, include a link to the related issue. If there is no related issue, link to a merge request, or epic.
- Do not link to [confidential issues](_index.md#confidential-or-restricted-access-links).
- Do not link to the pricing page. Do not include the subscription tier.

#### Updated features

For features that have changed or been updated, add a new list item.
Start the sentence with the feature name or a gerund.

For example:

```markdown
- [Introduced](https://issue-link) in GitLab 13.1.
- Creating an issue from an issue board [introduced](https://issue-link) in GitLab 14.1.
```

Or:

```markdown
- [Introduced](https://issue-link) in GitLab 13.1.
- Notifications for expiring tokens [introduced](https://issue-link) in GitLab 14.3.
```

#### Moved subscription tiers

For features that move to another subscription tier, use `moved`:

```markdown
- [Moved](https://issue-link) from GitLab Ultimate to GitLab Premium in 11.8.
- [Moved](https://issue-link) from GitLab Premium to GitLab Free in 12.0.
```

#### Changed feature status

For a feature status change from experiment to beta, use `changed`:

```markdown
- [Introduced](https://issue-link) as an [experiment](../../policy/development_stages_support.md) in GitLab 15.7.
- [Changed](https://issue-link) from experiment to beta in GitLab 16.0.
```

For a feature status change from beta to limited availability, use `changed`:

```markdown
- [Changed](https://issue-link) from experiment to beta in GitLab 16.0.
- [Changed](https://issue-link) from beta to limited availability in GitLab 16.3.
```

For a change to generally available, use:

```markdown
- [Generally available](https://issue-link) in GitLab 16.10.
```

#### Features made available as part of a program

For features made available to users as part of a program, add a new list item and link to the program.

```markdown
- [Introduced](https://issue-link) in GitLab 15.1.
- Merged results pipelines [added](https://issue-link) to the [Registration Features Program](https://page-link) in GitLab 16.7.
```

#### Features behind feature flags

For features introduced behind feature flags, add details about the feature flag. For more information, see [Document features deployed behind feature flags](../feature_flags.md).

#### Removing versions

Remove history items and inline text that refer to unsupported versions.

GitLab supports the current major version and two previous major versions.
For example, if 18.0 is the current major version, all major and minor releases of
GitLab 18.0, 17.0, and 16.0 are supported.

For the list of current supported versions, see [Version support](https://about.gitlab.com/support/statement-of-support/#version-support).

Remove information about [features behind feature flags](../feature_flags.md)
only if all events related to the feature flag happened in unsupported versions.
If the flag hasn't been removed, readers should know when it was introduced.

#### Timing version removals

When a new major version is about to be released, create merge
requests to remove mentions of the last unsupported version. Only merge
them during the milestone of the new major release.

For example, if GitLab 19.0 is the next major upcoming release:

- The supported versions are 18, 17, and 16.
- When GitLab 19.0 is released, GitLab 16 is no longer supported.

Create merge requests to remove mentions of GitLab 16, but only
merge them during the 19.0 milestone, after 18.11 is released.

## When to add availability details

Assign availability details under:

- Most H1 topic titles, except the pages under `doc/development/*` and `doc/solutions/*`.
- Topic titles for features that have different availability details than the H1 title.

The H1 availability details should be the details that apply to the widest availability
for the features on the page. For example:

- If some sections apply to Premium and Ultimate, and others apply to just Ultimate,
  the H1 `Tier:` should be `Premium, Ultimate`.
- If some sections apply to all instances, and others apply to only `GitLab Self-Managed`,
  the `Offering:` should be `GitLab.com, GitLab Self-Managed, GitLab Dedicated`.
- If some sections are beta, and others are experiment, the H1 `Status:` should be `Beta`.
  If some sections are beta, and others are generally available, then there should
  be no `Status:` for the H1.

## When not to add availability details

Do not assign availability details to the following pages:

- Tutorials.
- Pages that compare features from different tiers.
- Pages in the `/development` folder. These pages are automatically assigned a `Contribute` badge.
- Pages in the `/solutions` folder. These pages are automatically assigned a `Solutions` badge.

Also, do not assign them when a feature does not have one obvious subscription tier or offering.
For example, if a feature applies to one tier for GitLab.com and a different availability for GitLab Self-Managed.

In this case, do any or all of the following:

- Use [metadata](../metadata.md#indicate-lack-of-product-availability-details)
  to indicate that the page has been reviewed and does not need availability details.
- Use a [`type="note"`](_index.md#note) alert box to describe the availability details.
- Add availability details under other topic titles where this information makes more sense.
- Do not add availability details under the H1.

### Duplicating tier, offering, or status on subheadings

If a subheading has the same tier, offering, or status as its parent
topic, you don't need to repeat the information in the subheading's
badge.

For example, subheadings that have `Tier: Premium, Ultimate` and `Offering: GitLab.com`
don't need to duplicate the details if the page details match:

```markdown
title: My title
---

{{</* details */>}}

- Tier: Premium, Ultimate
- Offering: GitLab.com

{{</* /details */>}}
```

Any lower-level heading that applies to a different tier but same offering would be:

```markdown
## My title

{{</* details */>}}

- Tier: Ultimate

{{</* /details */>}}
```

## Inline availability details

Generally, you should not add availability details inline with other text.
The single source of truth for a feature should be the topic where the
functionality is described.

If you do need to mention an availability details inline, write it in plain text.
For example, for an API topic:

```markdown
IDs of the users to assign the issue to. Ultimate only.
```

For more examples, see the [REST API style guide](../restful_api_styleguide.md).

## Inline history text

If you're adding content to an existing topic, add historical information
inline with the existing text. If possible, include a link to the related issue,
merge request, or epic. For example:

```markdown
The voting strategy [in GitLab 13.4 and later](https://issue-link) requires the primary and secondary
voters to agree.
```

## Administrator documentation for availability details

Topics that are only for instance administrators should have the `GitLab Self-Managed` tier.
Instance administrator documentation often includes sections that mention:

- Changing the `gitlab.rb` or `gitlab.yml` files.
- Accessing the rails console or running Rake tasks.
- Doing things in the **Admin** area.

These pages should also mention if the tasks can only be accomplished by an
instance administrator.
