---
description: Learn the process of shipping documentation for GitLab.
---

# Documentation process at GitLab

At GitLab, developers contribute new or updated documentation along with their code, but product managers and technical writers also have essential roles in the process.

- Product Managers (PMs): in the issue for all new and updated features,
PMs include specific documentation requirements that the developer who is
writing or updating the docs must meet, along with feature descriptions
and use cases. They call out any specific areas where collaborating with
a technical writer is recommended, and usually act as the first reviewer
of the docs.
- Developers: author documentation and merge it on time (up to a week after
the feature freeze).
- Technical Writers: review each issue to ensure PM's requirements are complete,
help developers with any questions throughout the process, and act as the final
reviewer of all new and updated docs content before it's merged.

## Requirements

Documentation must be delivered whenever:

- A new feature is shipped
- There are changes to the UI
- A process, workflow, or previously documented feature is changed

Documentation is not required when a feature is changed on the backend
only and does not directly affect the way that any regular user or
administrator would interact with GitLab.

NOTE: **Note:**
When refactoring documentation in needed, it should be submitted it in its own MR.
**Do not** join new features' MRs with refactoring existing docs, as they might have
different priorities.

NOTE: **Note:**
[Smaller MRs are better](https://gitlab.com/gitlab-com/blog-posts/issues/185#note_4401010)! Do not mix subjects, and ship the smallest MR possible.

### Documentation review process

The docs shipped by the developer should be reviewed by the PM (for accuracy) and a Technical Writer (for clarity and structure).

#### Documentation updates that require Technical Writer review

Every documentation change that meets the criteria below must be reviewed by a Technical Writer
to ensure clarity and discoverability, and avoid redundancy, bad file locations, typos, broken links, etc.
Within the GitLab issue or MR, ping the relevant technical writer for the subject area. If you're not sure who that is,
ping any of them or all of them (`@gl\-docsteam`).

A Technical Writer must review documentation updates that involve:

- Docs introducing new features
- Changing documentation location
- Refactoring existing documentation
- Creating new documentation files

If you need any help to choose the correct place for a doc, discuss a documentation
idea or outline, or request any other help, ping a Technical Writer on your issue, MR,
or on Slack in `#docs`.

#### Skip the PM's review

When there's a non-significant change to the docs, you can skip the review
of the PM. Add the same labels as you would for a regular doc change and
assign the correct milestone. In these cases, assign a Technical Writer
for approval/merge, or mention `@gl\-docsteam` in case you don't know
which Tech Writer to assign for.

#### Skip the entire review

When the MR only contains corrections to the content (typos, grammar,
broken links, etc), it can be merged without the PM's and Tech Writer's review.

## Documentation structure

Read through the [documentation structure](structure.md) docs for an overview.

## Documentation workflow

To follow a consistent workflow every month, documentation changes
involve the Product Managers, the developer who shipped the feature,
and the Technical Writing team. Each role is described below.

### 1. Product Manager's role in the documentation process

The Product Manager (PM) should add to the feature issue:

- Feature name, overview/description, and use cases, for the [documentation blurb](structure.md#documentation-blurb)
- The documentation requirements for the developer working on the docs
  - What new page, new subsection of an existing page, or other update to an existing page/subsection is needed.
  - Just one page/section/update or multiple (perhaps there's an end user and admin change needing docs, or we need to update a previously recommended workflow, or we want to link the new feature from various places; consider and mention all ways documentation should be affected
  - Suggested title of any page or subsection, if applicable
- Label the issue with `Documentation`, `Deliverable`, `docs:P1`, and assign
  the correct milestone

### 2. Developer's role in the documentation process

As a developer, or as a community contributor, you should ship the documentation
with the feature, as in GitLab the documentation is part of the product.

The docs can either be shipped along with the MR introducing the code, or,
alternatively, created from a follow-up issue and MR.

The docs should be shipped **by the feature freeze date**. Justified
exceptions are accepted, as long as the [following process](#documentation-shipped-late)
and the missed-deliverable due date (the 14th of each month) are both respected.

#### Documentation shipped in the feature MR

The developer should add to the feature MR the documentation containing:

- The [documentation blurb](structure.md#documentation-blurb): copy the
feature name, overview/description, and use cases from the feature issue
- Instructions: write how to use the feature, step by step, with no gaps.
- [Crosslink for discoverability](structure.md#discoverability): link with
internal docs and external resources (if applicable)
- Index: link the new doc or the new heading from the higher-level index
for [discoverability](#discoverability)
- [Screenshots](styleguide.md#images): when necessary, add screenshots for:
  - Illustrating a step of the process
  - Indicating the location of a navigation menu
- Label the MR with `Documentation`, `Deliverable`, `docs-P1`, and assign
the correct milestone
- Assign the PM for review
- When done, mention the `@gl\-docsteam` in the MR asking for review
- **Due date**: feature freeze date and time

#### Documentation shipped in a follow-up MR

If the docs aren't being shipped within the feature MR:

- Create a new issue mentioning "docs" or "documentation" in the title (use the Documentation issue description template)
- Label the issue with: `Documentation`, `Deliverable`, `docs-P1`, `<product-label>`
(product label == CI/CD, Pages, Prometheus, etc)
- Add the correct milestone
- Create a new MR for shipping the docs changes and follow the same
process [described above](#documentation-shipped-in-the-feature-mr)
- Use the MR description template called "Documentation"
- Add the same labels and milestone as you did for the issue
- Assign the PM for review
- When done, mention the `@gl\-docsteam` in the MR asking for review
- **Due date**: feature freeze date and time

#### Documentation shipped late

Shipping late means that you are affecting the whole feature workflow
as well as other teams' priorities (PMs, tech writers, release managers,
release post reviewers), so every effort should be made to avoid this.

If you did not ship the docs within the feature freeze, proceed as
[described above](#documentation-shipped-in-a-follow-up-mr) and,
besides the regular labels, include the labels `Pick into X.Y` and
`missed-deliverable` in the issue and the MR, and assign them the correct
milestone.

The **due date** for **merging** `missed-deliverable` MRs is on the
**14th** of each month.

### 3. Technical Writer's role in the documentation process

- **Planning**
  - Once an issue contains a Documentation label and the current milestone, a
technical writer reviews the Product Manager's documentation requirements
  - Once the documentation requirements are approved, the technical writer can
work with the developer to discuss any documentation questions and plans/outlines, as needed.

- **Review** - A technical writer must review the documentation for:
  - Clarity
  - Relevance (make sure the content is appropriate given the impact of the feature)
  - Location (make sure the doc is in the correct dir and has the correct name)
  - Syntax, typos, and broken links
  - Improvements to the content
  - Accordance to the [docs style guide](styleguide.md)

<!-- TBA: issue and MR description templates as part of the process -->

<!--
## New features vs feature updates

- TBA:
  - Describe the difference between new features and feature updates
  - Creating a new doc vs updating an existing doc
-->

