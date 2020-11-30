---
stage: none
group: Style Guide
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
description: What to include in GitLab documentation pages.
---

# Documentation structure and template

Use these standards to contribute content to the GitLab documentation.

Before getting started, familiarize yourself with [GitLab's Documentation guidelines](index.md)
and the [Documentation Style Guide](styleguide/index.md).

## Components of a documentation page

Most pages are dedicated to a specific GitLab feature or to a use case that
involves one or more features, potentially in conjunction with third-party tools.

In general, each topic should include the following content, in this sequence:

- *Metadata*: Information about the stage, group, and how to find the technical
  writer for the topic. This information isn't visible in the published help.
- *Title*: A top-level heading with the feature or use case name. Choose a term
  that defines the functionality and use the same term in all the resources
  where the feature is mentioned.
- *Introduction*: In a few sentences beneath the title, describe what the
  feature or topic is, what it does, and in what context it should be used.
- *Use cases*: Describe real user scenarios.
- *Prerequisites*: Describe the software, configuration, account, permissions,
  or knowledge required to use this functionality.
- *Tasks*: Present detailed step-by-step instructions on how to use the feature.
- *Troubleshooting*: List errors and how to address them. Recommended but not
  required.

You can include additional subsections, as appropriate, such as *How it Works*,
or *Architecture*. You can also include other logical divisions, such as
pre-deployment and post-deployment tasks.

## Template for new docs

Follow the [folder structure and file name guidelines](styleguide/index.md#folder-structure-overview)
and create a new topic by using this template:

```markdown
<!--Follow the Style Guide when working on this document.
https://docs.gitlab.com/ee/development/documentation/styleguide.html
When done, remove all of this commented-out text, except a commented-out
Troubleshooting section, which, if empty, can be left in place to encourage future use.-->
---
description: "Short document description." # Up to ~200 chars long. This information is displayed
in Google Search snippets. It may help to write the page intro first, and then reuse it here.
stage: Add the stage name here
group: Add the group name here
info: To determine the technical writer assigned to the Stage/Group associated with this page,
see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Feature or Use Case Name **[TIER]** (1)
<!--If you are writing about a use case, start with a verb,
for example, "Configure", "Implement", + the goal/scenario-->

<!--For pages on newly-introduced features, add the following line.
If only some aspects of the feature have been introduced, specify which parts of the feature.-->
> [Introduced](link_to_issue_or_mr) in GitLab (Tier) X.Y (2).

Write a description of the feature or use case. This introduction should answer
these questions:

- What is this feature or use case?
- Who is it for?
- What is the context in which it is used and are there any prerequisites or
  requirements?
- What can the audience do with this? (Be sure to consider all applicable
  audiences, such as GitLab admin and developer-user.)
- What are the benefits of using this over any existing alternatives?

You can reuse this content, or part of it, for the front matter's `description`
at the top of this file.

## Use cases

Describe common use cases, typically in bulleted form. Include real-life examples
for each.

If the page itself is dedicated to a use case, this section usually includes more
specific scenarios for use (for example, variations on the main use case), but if
that's not applicable, you can omit this section.

Examples of use cases on feature pages:

- CE and EE: [Issues](../../user/project/issues/index.md#use-cases)
- CE and EE: [Merge Requests](../../user/project/merge_requests/index.md)
- EE-only: [Geo](../../administration/geo/index.md)
- EE-only: [Jenkins integration](../../integration/jenkins.md)

## Prerequisites

State any prerequisites for using the feature. These might include:

- Technical prereqs (for example, an account on a third-party service, an amount
  of storage space, or prior configuration of another feature)
- Prerequisite knowledge (for example, familiarity with certain GitLab features
  or other products and technologies).

Link each one to an appropriate place for more information.

## Tasks

Each topic should help users accomplish a specific task.

The heading should:

- Describe the task and start with a verb. For example, `Create a package` or
  `Configure a pipeline`.
- Be short and descriptive (up to ~50 chars).
- Start from an `h2` (`##`), then go over `h3`, `h4`, `h5`, and `h6` as needed.
  Never skip a hierarchy level (like `h2` > `h4`). It breaks the table of
  contents and can affect the breadcrumbs.

Bigger tasks can have subsections that explain specific phases of the process.

Include example code or configurations when needed. Use Markdown to wrap code
blocks with [syntax highlighting](../../user/markdown.md#colored-code-and-syntax-highlighting).

Example topic:

## Create a teddy bear

Create a teddy bear when you need something to hug. (Include the reason why you
might do the task.)

To create a teddy bear:

1. Go to **Settings > CI/CD**.
1. Expand **This** and click **This**.
1. Do another step.

The teddy bear is now in the kitchen, in the cupboard above the sink. _(This is the result.)_

You can retrieve the teddy bear and put it on the couch with the other animals. _(These are next steps.)_

Screenshots are not necessary. They are difficult to keep up-to-date and can
clutter the page.

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand
what issues one might have when setting this up, or when something is changed,
or on upgrading, it's important to describe those, too. Think of things that may
go wrong and include them here. This is important to minimize requests for
Support, and to avoid documentation comments with questions that you know
someone might ask.

Each scenario can be a third-level heading, for example, `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place but
commented out to help encourage others to add to it in the future. -->

---

Notes:

- (1): Apply the [tier badges](styleguide/index.md#product-badges) accordingly.
- (2): Apply the correct format for the
       [GitLab version that introduces the feature](styleguide/index.md#gitlab-versions-and-tiers).
```

## Help and feedback section

This section ([introduced](https://gitlab.com/gitlab-org/gitlab-docs/-/merge_requests/319) in GitLab 11.4)
is displayed at the end of each document and can be omitted by adding a key into
the front matter:

```yaml
---
feedback: false
---
```

The default is to leave it there. If you want to omit it from a document, you
must check with a technical writer before doing so.

### Disqus

We also have integrated the docs site with Disqus (introduced by
[!151](https://gitlab.com/gitlab-org/gitlab-docs/-/merge_requests/151)),
allowing our users to post comments.

To omit only the comments from the feedback section, use the following key in
the front matter:

```yaml
---
comments: false
---
```

We're hiding comments only in main index pages, such as [the main documentation index](../../README.md),
since its content is too broad to comment on. Before omitting Disqus, you must
check with a technical writer.

Note that after adding `feedback: false` to the front matter, it will omit
Disqus, therefore, don't add both keys to the same document.

The click events in the feedback section are tracked with Google Tag Manager.
The conversions can be viewed on Google Analytics by navigating to
**Behavior > Events > Top events > docs**.

## Guidelines for good practices

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/36576/) in GitLab 13.2 as GitLab Development documentation.

*Good practice* examples demonstrate encouraged ways of writing code while
comparing with examples of practices to avoid. These examples are labeled as
*Bad* or *Good*. In GitLab development guidelines, when presenting the cases,
it's recommended to follow a *first-bad-then-good* strategy. First demonstrate
the *Bad* practice (how things *could* be done, which is often still working
code), and then how things *should* be done better, using a *Good* example. This
is typically an improved example of the same code.

Consider the following guidelines when offering examples:

- First, offer the *Bad* example, and then the *Good* one.
- When only one bad case and one good case is given, use the same code block.
- When more than one bad case or one good case is offered, use separated code
  blocks for each. With many examples being presented, a clear separation helps
  the reader to go directly to the good part. Consider offering an explanation
  (for example, a comment, or a link to a resource) on why something is bad
  practice.
- Better and best cases can be considered part of the good case(s) code block.
  In the same code block, precede each with comments: `# Better` and `# Best`.

Although the bad-then-good approach is acceptable for the GitLab development
guidelines, do not use it for user documentation. For user documentation, use
*Do* and *Don't*. For examples, see the [Pajamas Design System](https://design.gitlab.com/content/punctuation/).
