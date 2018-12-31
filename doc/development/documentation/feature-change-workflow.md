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
- **Technical Writers**: Review doc requirements in issues, track issues and MRs
that contain docs changes, help with any questions throughout the authoring/editing process,
and review all new and updated docs content after it's merged (unless a pre-merge
review request is made).

Beyond this process, any member of the GitLab community can also author documentation
improvements that are not associated with a new or changed feature. See the [Documentation improvement workflow](improvement-workflow.md).

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
in its own MR (using the [documentation improvement workflow](improvement-workflow.md))
so that we can ensure the more time-sensitive doc updates are merged with code by the freeze.

## Documenting a new or changed feature

To follow a consistent workflow every month, documentation changes
involve the Product Managers, the developer who shipped the feature,
and the Technical Writing team. Each role is described below.

### 1. Product Manager's role

The Product Manager (PM) should confirm or add the following items in the issue:

- New or updated feature name, overview/description, and use cases, all required per the [Documentation structure and template](structure.md).
- The documentation requirements for the developer working on the docs.
  - What new page, new subsection of an existing page, or other update to an existing page/subsection is needed.
  - Just one page/section/update or multiple (perhaps there's an end user and admin change needing docs, or we need to update a previously recommended workflow, or we want to link the new feature from various places; consider and mention all ways documentation should be affected.
  - Suggested title of any page or subsection, if applicable.
- Label the issue with `Documentation` and `docs:P1` in addition to the `Deliverable` label and correct milestone.

Anyone is welcome to draft the items above in the issue, but a product manager must review and update them whenever the issue is assigned a specific milestone. 

### 2. Developer's role

As a developer, you must ship the documentation with the code of the feature that
you are creating or updating. The documentation is an essential part of the product.

- New and edited docs should be included in the MR introducing the code, and planned
in the issue that proposed the feature. However, if the new or changed doc requires
extensive collaboration or conversation, a separate, linked issue can be used for the planning process.
- Use the [Documentation guidelines](index.md), as well as other resources linked from there,
including the [Structure and template](structure.md) page, [Style Guide](styleguide.md), and [Markdown Guide](https://about.gitlab.com/handbook/product/technical-writing/markdown-guide/). 
- If you need any help to choose the correct place for a doc, discuss a documentation
idea or outline, or request any other help, ping the Technical Writer for the relevant
[DevOps stage](https://about.gitlab.com/handbook/product/categories/#devops-stages)
in your issue or MR, or write within `#docs` on the GitLab Slack.
- The docs must be merged with the code **by the feature freeze date**, otherwise
- the feature cannot be included with the release.<!-- TODO: Policy/process for feature-flagged issues -->

Prior to merge, documentation changes commited by the developer must be reviewed by:
* the person reviewing the code and merging the MR.
* optionally: others involved in the work (such as other devs, the PM, or a technical writer), if requested.

After merging, documentation changing are reviewed by:
* a technical writer (for clarity, structure, grammar, etc).
* optionally: by the PM (for accuracy and to ensure it's consistent with the vision for how the product will be used).
Any party can raise the item to the PM for review at any point: the dev, the technical writer, or the PM, who can request/plan a review at the outset.

### 3. Technical Writer's role

**Planning**
- Once an issue contains a Documentation label and an upcoming milestone, a
technical writer reviews the listed documentation requirements, which should have
already been reviewed by the PM. (These are non-blocking reviews; developers should
not wait to work on docs.)
- Monitor the documentation needs of issues assigned to the current and next milestone,
and participate in any needed discussion on docs planning with the dev, PM, and others.

**Review**
- Techncial writers provide non-blocking reviews of all documentation changes,
typically after the change is merged. However, if the docs are ready in the MR while
we are awaiting other work in order to merge, the technical writer's review can commence early.
- The technical writer will confirm that the doc is clear, grammatically correct,
and discoverable, while avoiding redundancy, bad file locations, typos, broken links,
etc. The technical writer will review the documentation for the following, which
the developer and code reviewer should have already made a good-faith effort to ensure:
  - Clarity.
  - Relevance (make sure the content is appropriate given the impact of the feature).
  - Location (make sure the doc is in the correct dir and has the correct name).
  - Syntax, typos, and broken links.
  - Improvements to the content.
  - Accordance to the [Documentation Style Guide](styleguide.md) and [structure/template](structure.md).
