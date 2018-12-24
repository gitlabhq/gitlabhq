---
description: How to add docs for new or enhanced GitLab features.
---

# Documentation process at GitLab

At GitLab, developers contribute new or updated documentation along with their code, but product managers and technical writers also have essential roles in the process.

- **Product Managers** (PMs): in the issue for all new and updated features,
PMs include specific documentation requirements for the developer, and, for new features,
they also include feature descriptions and use cases. They can bring in a technical
writer for discussion or help, and can be called upon themselves as a doc reviewer.
- **Developers**: author documentation and merge it by the feature freeze, leaving
time for a doc review performed by the cross-functional team's assigned technical writer.
- **Technical Writers**: review PM requirements in issues, help developers with any
questions throughout the authoring/editing process, and review all new and
updated docs content before it's merged.

Any of the above roles, or others in the GitLab community, can author documentation
improvements that are not associated with a new/changed feature, and must also typically
assign such changes to a technical writer for review.

## When documentation is required

Documentation must be delivered whenever:

- A new feature is shipped
- There are changes to the UI or API
- A process, workflow, or previously documented feature is changed
- A feature is deprecated or removed

Documentation is not required when a feature is changed on the backend
only and does not directly affect the way that any user or
administrator would interact with GitLab. For example, a UI restyling that offers
no difference in functionality may require documentation updates if screenshots
are now needed, or need to be updated.

NOTE: **Note:**
When refactoring documentation, it should be submitted in its own MR.
**Do not** join new features' MRs with those refactoring existing docs, as they
might have different priorities.

NOTE: **Note:**
[Smaller MRs are better](https://gitlab.com/gitlab-com/blog-posts/issues/185#note_4401010)! Do not mix subjects (e.g. multiple unrelated pages), and ship the smallest MR possible.

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

#### Including documentation in a separate MR

If the docs aren't being shipped within the feature MR, but are still being shipped on time (by the feature freeze):

- Create a new issue with the Documentation template and mention "docs" or "documentation" in the title, plus the feature name. 
- Label the issue with: `Documentation`, `Deliverable`, `docs-P1`, `<product-label>`.
(product label == CI/CD, Pages, etc).
- Add the milestone matching that of the feature issue.
- Create a new MR for shipping the docs changes and follow the same
process [described above](#including-documentation-in-the-feautre-mr-typical).
- Use the MR description template named "Documentation".
- Add the same labels and milestone as you did for the issue.
- Assign the technical writer for review.
- When done, mention the team's technical writer in the MR asking for review (or `@gl\-docsteam` if you are not sure who that is).
- **Due date**: feature freeze date and time.

#### Shipping documentation after the freeze (rare)

Typically, if the documentation is not ready, this will block the feature
for the current GitLab release.

Shipping documentation after the freeze is rare and requires approval of the PM, technical writer, and dev.
Every effort should be made to avoid this, as it risks a poor user experience and affects the whole feature workflow, along with
other teams' priorities (PMs, tech writers, release managers, release post reviewers). 

If the aforementioned approval is given:
1. Use the instructions above for [Documentation shipped in a separate MR](#including-documentation-in-a-separate-mr) and,
in addition to the usual labels and correct milestone, include the labels `Pick into X.Y` on the MR (where X.Y is the GitLab version) and
`missed-deliverable` in the issue and the MR.
2. Obtain a review, as usual.
3. Ensure that the MR is merged by the 14th of the month.

### 3. Technical Writer's role

**Planning**
  - Once an issue contains a Documentation label and an upcoming milestone, a
technical writer reviews the Product Manager's documentation requirements
  - Once the documentation requirements are approved, the technical writer can
work with the developer to discuss any documentation questions and plans/outlines, if needed.

**Review**
- Every documentation change beyond minor clarifications and corrections requires a Technical Writer review, with greater exceptions in place for GitLab Support.<!--TODO: link-->
This should apply to docs for every new or changed feature. The technical writer will ensure that the doc is clear, grammatically correct,
and discoverable, while avoiding redundancy, bad file locations, typos, broken links, etc. The technical writer must review the documentation for:
  - Clarity
  - Relevance (make sure the content is appropriate given the impact of the feature)
  - Location (make sure the doc is in the correct dir and has the correct name)
  - Syntax, typos, and broken links
  - Improvements to the content
  - Accordance to the [docs style guide](styleguide.md)

<!-- TODO: Clarify differences for completely new features vs. feature enhancemeents. May belong in structure doc. -->
