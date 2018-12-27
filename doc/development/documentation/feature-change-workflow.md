---
description: How to add docs for new or enhanced GitLab features.
---

# Documentation process at GitLab

At GitLab, developers contribute new or updated documentation along with their code, but product managers and technical writers also have essential roles in the process.

- **Developers**: Author/update documentation in the same MR as their code, and
merge it by the feature freeze for the assigned milestone. Request technical writer
assistance if needed.
- **Product Managers** (PMs): In the issue for all new and enhanced features,
confirm the documentation requirements, plus the mentioned feature description
and use cases, which can be reused in docs. They can bring in a technical
writer for discussion or help, and can be called upon themselves as a doc reviewer.
- **Technical Writers**: review doc requirements in issues, track issues and MRs
that contain docs changes, help with any questions throughout the authoring/editing process,
and review all new and updated docs content after it's merged (unless a pre-merge
review request is made).

Any of the above roles, or others in the GitLab community, can also author documentation
improvements that are not associated with a new/changed feature.

## When documentation is required

Documentation must be delivered whenever:

- A new or enhanced feature is shipped that impacts the user/admin experience
- There are changes to the UI or API
- A process, workflow, or previously documented feature is changed
- A feature is deprecated or removed

Documentation is not required when a feature is changed on the backend
only and does not directly affect the way that any user or
administrator would interact with GitLab. For example, a UI restyling that offers
no difference in functionality may require documentation updates if screenshots
are now needed, or need to be updated.

NOTE: **Note:**
When revamping documentation, if unrelated to the feature change, this should be submitted
in its own MR, so that we can ensure the essential doc updates are merged with code by the freeze.

## Documenting a new or changed feature

To follow a consistent workflow every month, documentation changes
involve the Product Managers, the developer who shipped the feature,
and the Technical Writing team. Each role is described below.

### 1. Product Manager's role

The Product Manager (PM) should add to the feature issue:

- New or updated feature name, overview/description, and use cases, for the feature's [documentation blurb](structure.md#documentation-blurb)
- The documentation requirements for the developer working on the docs
  - What new page, new subsection of an existing page, or other update to an existing page/subsection is needed.
  - Just one page/section/update or multiple (perhaps there's an end user and admin change needing docs, or we need to update a previously recommended workflow, or we want to link the new feature from various places; consider and mention all ways documentation should be affected
  - Suggested title of any page or subsection, if applicable <--!TODO: Add this and previous bullets in some form to issue/MR templates-->
- Label the issue with `Documentation` and `docs:P1` in addition to the `Deliverable` label and correct milestone.

Anyone is welcome to draft the items above in the issue, but a product manager must review and update them whenever the issue is assigned a specific milestone. 

### 2. Developer's role

As a developer, or as a community contributor, you should ship the documentation
with the feature; the documentation is an essential part of the product.

New and edited docs should be shipped along with the MR introducing the code.
However, if the new or changed doc requires extensive collaboration or conversation,
a separate, linked issue and MR can be used.

For guidance, see the documentation [Structure](structure.md) guide, [Style Guide](styleguide.md), the [main page](index.md) of this section, and additional writing tips in the [Technical Writing handbook section](https://about.gitlab.com/handbook/product/technical-writing/).

If you need any help to choose the correct place for a doc, discuss a documentation
idea or outline, or request any other help, ping the Technical Writer for the relevant
[DevOps stage](https://about.gitlab.com/handbook/product/categories/#devops-stages) in your issue or MR, or write in `#docs` on the GitLab Slack.

The docs must be shipped **by the feature freeze date**, otherwise the feature cannot be included with the release.
In rare exceptions with the approval of the PM, dev, and technical writer, documentation can be
merged through the 14th of the month if the [following process](#documentation-shipped-late) is followed. <!-- TODO: Policy/process for feature-floagged issues-->

Documentation changes commited by the developer should be reviewed by:
* a technical writer (for clarity, structure, and confirming requirements are met)
* optionally: by the PM (for accuracy and to ensure it's consistent with the vision for how the product will be used).
Any party can raise the item to the PM for review at any point: the dev, the technical writer, or the PM, who can request this at the outset.

#### Including documentation in the feature MR (typical)

The developer should add to the feature MR changes to the documentation, typically containing the following for new features:

- The [name, description, and use cases](structure.md#documentation-blurb): copy these from the feature issue
where were provided or reviewed by the product manager.
- Instructions: write how to use the feature, step by step, with no gaps.
- [Crosslink for discoverability](structure.md#discoverability): link with
internal docs and external resources (if applicable).
- Index: link the new doc or the new heading from the higher-level index
for [discoverability](#discoverability).
- [Screenshots](styleguide.md#images): when necessary, add screenshots for:
  - Illustrating a step of the process.
  - Indicating the location of a navigation menu.
- Label the MR with `Documentation`, `Deliverable`, `docs-P1`, and assign
the correct milestone.
- Assign the PM for review.
- When done, mention the team's technical writer in the MR asking for review (or `@gl\-docsteam` if you are not sure who that is).
- **Due date**: feature freeze date and time.

### 3. Technical Writer's role

**Planning**
  - Once an issue contains a Documentation label and an upcoming milestone, a
technical writer reviews the listed documentation requirements, which should have
already been reviewed by the PM. (These are non-blocking reviews; developers should
not wait to work on docs.)
  - Participate in any needed discussion on docs (with dev, PM, et al.).

**Review**
- Techncial writers provide non-blocking reviews of all documentation changes,
typically after the change is merged. However, if the docs are ready in the MR while
awaiting other code review, etc., the technical writer review can commence early.

- The technical writer will confirm that the doc is clear, grammatically correct,
and discoverable, while avoiding redundancy, bad file locations, typos, broken links,
etc. The technical writer will review the documentation for the following, which
the developer and code reviewer should have already made a good-faith effort to ensure:
  - Clarity
  - Relevance (make sure the content is appropriate given the impact of the feature)
  - Location (make sure the doc is in the correct dir and has the correct name)
  - Syntax, typos, and broken links
  - Improvements to the content
  - Accordance to the [docs style guide](styleguide.md)

<!-- TODO: Clarify differences for completely new features vs. feature enhancemeents. May belong in structure doc. -->
