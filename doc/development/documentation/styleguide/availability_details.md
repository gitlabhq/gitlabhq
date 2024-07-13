---
info: For assistance with this Style Guide page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments-to-other-projects-and-subjects.
stage: none
group: unassigned
description: 'Writing styles, markup, formatting, and other standards for GitLab Documentation.'
---

# Product availability details

Product availability details provide information about a feature and are displayed under the topic title.

Availability details include the tier, offering, status, and history.

The Markdown for availability details should look like the following:

```markdown
# Topic title

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated
**Status:** Experiment

> - [Introduced](https://link-to-issue) in GitLab 16.3.
> - Updated in GitLab 16.4.
```

## Available options

Use the following text for the tier, offering, and status.

### Offering

For offering, use any combination of these words, in this order, separated by commas:

- `GitLab.com`
- `Self-managed`
- `GitLab Dedicated`

For example:

- `GitLab.com`
- `GitLab.com, Self-managed`
- `Self-managed`
- `Self-managed, GitLab Dedicated`

### Tier

For tier, choose one:

- `Free, Premium, Ultimate`
- `Premium, Ultimate`
- `Ultimate`

### Status

For status, choose one:

- `Beta`
- `Experiment`

Generally available features should not have a status.

### GitLab Duo Pro or Enterprise add-on

The add-ons belong with other subscription tiers. Document them by using the phrase `with` and the add-on.
For example, `with GitLab Duo Pro`.
For example:

```markdown
**Tier:** Premium or Ultimate with GitLab Duo Pro
```

## When to add availability details

Assign availability details under:

- Most H1 topic titles, except the pages under `doc/development/*` and `doc/solutions/*`.
- Topic titles for features that have different availability details than the H1 title.

The H1 availability details should be the details that apply to the widest availability
for the features on the page. For example:

- If some sections apply to Premium and Ultimate, and others apply to just Ultimate,
  the H1 `Tier:` should be `Premium, Ultimate`.
- If some sections apply to all instances, and others apply to only `Self-managed`,
  the `Offering:` should be `GitLab.com, Self-managed, GitLab Dedicated`.
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
For example, if a feature applies to one tier for GitLab.com and a different availability for self-managed.

In this case, do any or all of the following:

- Use a [`NOTE`](index.md#note) alert box to describe the availability details.
- Add availability details under other topic titles where this information makes more sense.
- Do not add availability details under the H1.

### Duplicating tier, offering, or status on subheadings

If a subheading has the same tier, offering, or status as its parent
topic, you don't need to repeat the information in the subheading's
badge.

For example, if the H1 heading is:

```markdown
# My title

DETAILS:
**Offering:** GitLab.com
**Tier:** Premium, Ultimate
```

Any lower-level heading that applies to a different tier but same offering would be:

```markdown
## My title

DETAILS:
**Tier:** Ultimate
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

## Administrator documentation for availability details

Topics that are only for instance administrators should have the `Self-managed` tier.
Instance administrator documentation often includes sections that mention:

- Changing the `gitlab.rb` or `gitlab.yml` files.
- Accessing the rails console or running Rake tasks.
- Doing things in the Admin area.

These pages should also mention if the tasks can only be accomplished by an
instance administrator.
