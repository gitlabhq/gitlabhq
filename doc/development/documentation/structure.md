---
description: What to include in GitLab documentation pages.
---

# Documentation structure and template

This document will help you determine how to structure a page within GitLab's
documentation and what content to include. These standards help ensure consistency
and completeness throughout the documentation, and they make it easier to contribute.

Before getting started, familiarize yourself with [GitLab's Documentation guidelines](index.md)
and the section on Content in the [Style Guide](styleguide.md).

## Components of a documentation page

Most pages will be dedicated to a specifig GitLab feature or to a use case that involves
one or more features and/or third-party tools.

Every feature or use case document should include the following content in the following sequence.:

- **Title**: Top-level heading with the feature name, or a use case name, which would start with
a verb, like Configuring, Enabling, etc.
- **Introduction**: A couple sentences about the subject matter and what's to be found on this page.
- **Overview** Describe what it is, what it does, and in what context it should be used.
- **Use cases**: describes real use case scenarios for that feature/configuration.
- **Requirements**: describes what software and/or configuration is required to be able to
  use the feature and, if applicable, prerequisite knowledge for being able to follow/implement the tutorial.
  For example, familiarity with GitLab CI/CD, an account on a third-party service, dependencies installed, etc.
  Link each one to its most relevant resource; i.e., where the reader can go to begin to fullfil that requirement.
  (Another doc page, a third party application's site, etc.)
- **Instructions**: clearly describes the steps to follow, leaving no gaps.
- **Troubleshooting** guide (recommended but not required): if you know beforehand what issues
  one might have when setting it up, or when something is changed, or on upgrading, it's
  important to describe those too. Think of things that may go wrong and include them in the
  docs. This is important to minimize requests for support, and to avoid doc comments with
  questions that you know someone might ask. Answering them beforehand only makes your
  document better and more approachable.

For additional details, see the subsections below, as well as the [Documentation template for new docs](#Documentation-template-for-new-docs).

### Feature overview and use cases

Every major feature (regardless if present in GitLab Community or Enterprise editions)
should present, at the beginning of the document, two main sections: **overview** and
**use cases**. Every GitLab EE-only feature should also contain these sections.

**Overview**: as the name suggests, the goal here is to provide an overview of the feature.
Describe what it is, what it does, why it is important/cool/nice-to-have,
what problem it solves, and what you can do with this feature that you couldn't
do before.

**Use cases**: provide at least two, ideally three, use cases for every major feature.
You should answer this question: what can you do with this feature/change? Use cases
are examples of how this feature or change can be used in real life.

Examples:

- CE and EE: [Issues](../../user/project/issues/index.md#use-cases)
- CE and EE: [Merge Requests](../../user/project/merge_requests/index.md)
- EE-only: [Geo](https://docs.gitlab.com/ee/administration/geo/replication/index.html)
- EE-only: [Jenkins integration](https://docs.gitlab.com/ee/integration/jenkins.html)

Note that if you don't have anything to add between the doc title (`<h1>`) and
the header `## Overview`, you can omit the header, but keep the content of the
overview there.

> **Overview** and **use cases** are required to **every** Enterprise Edition feature,
and for every **major** feature present in Community Edition.

### Discoverability

Your new document will be discoverable by the user only if:

- Crosslinked from the higher-level index (e.g., Issue Boards docs
  should be linked from Issues; Prometheus docs should be linked from
  Monitoring; CI/CD tutorials should be linked from CI/CD examples).
  - When referencing other GitLab products and features, link to their
  respective docs; when referencing third-party products or technologies,
  link out to their external sites, documentation, and resources.
- The headings are clear. E.g., "App testing" is a bad heading, "Testing
  an application with GitLab CI/CD" is much better. Think of something
  someone will search for and use these keywords in the headings.

## Documentation template for new docs

To start a new document, respect the file tree and file name guidelines,
as well as the style guidelines. Use the following template:

```md
<!--Follow the Style Guide when working on this document. https://docs.gitlab.com/ee/development/documentation/styleguide.html
When done, remove all of this commented-out text, except a commented-out Troubleshooting section,
which, if empty, can be left in place to encourage future use.-->
---
description: "Short document description." # Up to ~200 chars long. They will be displayed in Google Search snippets. It may help to write the page intro first, and then reuse it here.
---

# Feature Name or Use Case Name **[TIER]** (1)
<!--If writing about a use case, drop the tier, and start with a verb, e.g. 'Configuring', 'Implementing', + the goal/scenario-->

<!--For pages on newly introduced features, add the following line. If only some aspects of the feature have been introduced, specify what parts of the feature.-->
> [Introduced](link_to_issue_or_mr) in GitLab (Tier) X.Y (2).

An introduction -- without its own additional header -- goes here.
Offer a short description of the feature or use case, and what to expect on this page.
(You can reuse this content, or part of it, for the front matter's `description` at the top of this file).

## Overview

The feature overview should answer the following questions:

- What is this feature or use case?
- Who is it for?
- What is the context in which it is used and are there any prerequisites/requirements?
- What can the audience do with this? (Be sure to consider all applicable audiences, like GitLab admin and developer-user.)
- What are the benefits to using this over any alternatives?

## Use cases

Describe some use cases, typically in bulleted form. Include real-life examples for each.

If the page itself is dedicated to a use case, this section can usually include more specific scenarios
for use, but if that's not applicable, the section can be omitted.

## Requirements

State any requirements for using the feature and/or following along with the instructions.

These can include both:
- technical requirements (e.g. an account on a third party service, an amount of storage space, prior configuration of another feature)
- prerequisite knowledge (e.g. familiarity with certain GitLab features, cloud technologies)

Link each one to an appropriate place for more information.

## Instructions

"Instructions" is usually not the name of the heading.
This is the part of the document where you can include one or more sets of instructions, each to accomplish a specific task.
Headers should describe the task the reader will achieve by following the instructions within, typically starting with a verb.
Larger instruction sets may have subsections covering specific phases of the process. 

- Write a step-by-step guide, with no gaps between the steps.
- Start with an h2 (`##`), break complex steps into small steps using
subheadings h3 > h4 > h5 > h6. _Never skip a hierarchy level, such
as h2 > h4_, as it will break the TOC and may affect the breadcrumbs.
- Use short and descriptive headings (up to ~50 chars). You can use one
single heading like `## Configuring X` for instructions when the feature
is simple and the document is short.

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee.
Each scenario can be a third-level heading, e.g. ### Getting error message X
If you have none to add when creating a doc, leave this section in place
but commented out, to help encourage others to add to it in the future. -->

---

Notes:

- (1): Apply the [tier badges](https://docs.gitlab.com/ee/development/documentation/styleguide.html#product-badges) accordingly
- (2): Apply the correct format for the [GitLab version introducing the feature](https://docs.gitlab.com/ee/development/documentation/styleguide.html#gitlab-versions-and-tiers)
```

## Help and feedback section

The "help and feedback" section (introduced by [!319](https://gitlab.com/gitlab-com/gitlab-docs/merge_requests/319)) displayed at the end of each document
can be omitted from the doc by adding a key into the its frontmatter:

```yaml
---
feedback: false
---
```

The default is to leave it there. If you want to omit it from a document,
you must check with a technical writer before doing so.

### Disqus

We also have integrated the docs site with Disqus (introduced by
[!151](https://gitlab.com/gitlab-com/gitlab-docs/merge_requests/151)),
allowing our users to post comments.

To omit only the comments from the feedback section, use the following
key on the frontmatter:

```yaml
---
comments: false
---
```

We are only hiding comments in main index pages, such as [the main documentation index](../../README.md), since its content is too broad to comment on. Before omitting Disqus,
you must check with a technical writer.

Note that once `feedback: false` is added to the frontmatter, it will automatically omit
Disqus, therefore, don't add both keys to the same document.

The click events in the feedback section are tracked with Google Tag Manager. The
conversions can be viewed on Google Analytics by navigating to **Behavior > Events > Top events > docs**.
